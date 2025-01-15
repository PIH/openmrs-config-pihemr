-- variables 
select encounter_type_id  into @regEncounterType from encounter_type et where uuid='873f968a-73a8-4f9c-ac78-9f4778b751b6';

-- create temp table to load
DROP TEMPORARY TABLE IF EXISTS temp_patients;
CREATE TEMPORARY TABLE  temp_patients
(patient_id                        int,           
mothers_first_name                VARCHAR(255),  
registration_encounter_id         int(11),       
address_level_1                   VARCHAR(255),  
address_level_4                          VARCHAR(255),  
address_level_2                          VARCHAR(255),  
address_level_5                           VARCHAR(255),  
address_level_3                           VARCHAR(255),  
telephone_number                  VARCHAR(255),  
reg_location                      varchar(50),   
reg_location_id                   int(11),       
registration_date                 date,          
registration_entry_date           datetime,      
creator                           int(11),       
user_entered                      varchar(50),   
first_encounter_date              date,          
last_encounter_date               date,          
name                              varchar(50),   
family_name                       varchar(50),   
dob                               date,          
gender                            varchar(2)    
);

-- load all patients
insert into temp_patients (patient_id) 
select patient_id from patient p where p.voided = 0;
create index temp_patients_pi on temp_patients(patient_id);

-- person info
update temp_patients t
inner join person p on p.person_id = t.patient_id
set t.gender = p.gender,
	t.dob = p.birthdate;

-- name info
update temp_patients t
inner join person_name n on n.person_name_id =
	(select n2.person_name_id from person_name n2
	where n2.person_id = t.patient_id
	order by preferred desc, date_created desc limit 1)
set t.name = n.given_name,
	t.family_name = n.family_name;

-- address info
update temp_patients t
inner join person_address a on a.person_address_id =
	(select a2.person_address_id from person_address a2
	where a2.person_id = t.patient_id
	order by preferred desc, date_created desc limit 1)
set t.address_level_1 = a.country,
	t.address_level_2 = a.state_province,
	t.address_level_3 = a.city_village,
	t.address_level_4 = a.county_district ,
	t.address_level_5 = a.address1;

-- person attributes
select person_attribute_type_id into @telephone from person_attribute_type where name = 'Telephone Number' ;
select person_attribute_type_id into @motherName from person_attribute_type where name = 'First Name of Mother' ;
update temp_patients t set telephone_number = person_attribute_value(patient_id,'Telephone Number');
update temp_patients t set mothers_first_name = person_attribute_value(patient_id,'First Name of Mother');

-- registration encounter
update temp_patients t set registration_encounter_id = latestEnc(patient_id,'Patient Registration',null);
create index temp_patients_pri on temp_patients(registration_encounter_id); 

-- registration encounter fields
update temp_patients t 
inner join encounter e on e.encounter_id = t.registration_encounter_id
set t.reg_location_id = e.location_id,
	t.registration_entry_date = e.date_created,
	t.registration_date = e.encounter_datetime,
	t.creator = e.creator;
update temp_patients t set reg_location = location_name(reg_location_id);
update temp_patients t set user_entered = person_name_of_user(creator);

-- start checking for dupes -----------------------------------
DROP TEMPORARY TABLE IF EXISTS temp_dup_info;
CREATE TEMPORARY TABLE  temp_dup_info
(group_id int(11)  NOT NULL AUTO_INCREMENT,           
mothers_first_name                VARCHAR(255),  
address_level_1                   VARCHAR(255),  
address_level_4                   VARCHAR(255),  
address_level_2                          VARCHAR(255),  
address_level_5                           VARCHAR(255),  
address_level_3                           VARCHAR(255),  
telephone_number                  VARCHAR(255),  
reg_location                      varchar(50),   
registration_date                 date,          
registration_entry_date           datetime,      
creator                           int(11),       
user_entered                      varchar(50),   
name                              varchar(50),   
family_name                       varchar(50),   
dob                               date,          
gender                            varchar(2),    
PRIMARY KEY (group_id)
);

-- load table with registration info of all the duplicates, using group_id to tie together the groups of dups 
INSERT INTO temp_dup_info(name, family_name, dob, gender, mothers_first_name, telephone_number, address_level_1, address_level_2, address_level_3, address_level_4, address_level_5, reg_location, registration_date, registration_entry_date, user_entered)
 select name, family_name, dob, gender, mothers_first_name, telephone_number, address_level_1, address_level_2, address_level_3, address_level_4, address_level_5, reg_location, registration_date, DATE(registration_entry_date), user_entered
 from temp_patients
 group by name, family_name, dob, gender, mothers_first_name, telephone_number, address_level_1, address_level_2, address_level_3, address_level_4, address_level_5, reg_location, registration_date, DATE(registration_entry_date), user_entered
 having count(*) > 1
 ;

-- join together the dup information with the entire list of patients
-- to create a list of patients with patient_ids grouped together
DROP TEMPORARY TABLE IF EXISTS temp_potential_dups;
CREATE TEMPORARY TABLE  temp_potential_dups
select d.group_id, p.* from temp_patients p
inner join temp_dup_info d
on d.name <=> p.name -- -- note '<=>' will compare nulls properly
and d.family_name <=> p.family_name
and d.dob <=> p.dob
and d.gender <=> p.gender
and d.mothers_first_name <=> p.mothers_first_name
and d.telephone_number <=> p.telephone_number
and d.address_level_1 <=> p.address_level_1
and d.address_level_2 <=> p.address_level_2
and d.address_level_3 <=> p.address_level_3
and d.address_level_4 <=> p.address_level_4
and d.address_level_5 <=> p.address_level_5
and d.reg_location <=> p.reg_location
and d.registration_date <=> p.registration_date
and date(d.registration_entry_date) <=> date(p.registration_entry_date)
and d.user_entered <=> p.user_entered;

DROP TEMPORARY TABLE IF EXISTS temp_potential_dups_patient_ids;
CREATE TEMPORARY TABLE  temp_potential_dups_patient_ids
select group_id, patient_id from temp_potential_dups;

-- create final list of patients to void by selecting the patients perviously chosen who:
-- do not have any encounters but where the other patients in that group have encounters (excluding registration)   
DROP TEMPORARY TABLE IF EXISTS temp_dups_to_void;
CREATE TEMPORARY TABLE  temp_dups_to_void
select patient_id from temp_potential_dups d 
where not exists
 (select 1 from encounter e where  e.patient_id = d.patient_id and e.encounter_type <> @regEncounterType)
and exists 
 (select 1 from encounter e2 where e2.patient_id in
 	(select patient_id from temp_potential_dups_patient_ids d2 where d2.group_id = d.group_id)
 	and e2.encounter_type <> @regEncounterType
 );

-- void patients on the list
update patient p 
inner join temp_dups_to_void t on t.patient_id = p.patient_id 
set voided = 1,
	voided_by = 1,
	date_voided = now(),
	void_reason = 'SL-816 voiding duplicate registrations';

-- void other applicable table rows based on voided patients
update person
set voided = 1,
	voided_by = 1,
	date_voided = now(),
	void_reason = 'SL-816 voiding duplicate registrations'
where person_id in 
	(select patient_id from patient where void_reason = 'SL-816 voiding duplicate registrations');

update person_address 
set voided = 1,
	voided_by = 1,
	date_voided = now(),
	void_reason = 'SL-816 voiding duplicate registrations'
where person_id in 
	(select patient_id from patient where void_reason = 'SL-816 voiding duplicate registrations');

update person_attribute 
set voided = 1,
	voided_by = 1,
	date_voided = now(),
	void_reason = 'SL-816 voiding duplicate registrations'
where person_id in 
	(select patient_id from patient where void_reason = 'SL-816 voiding duplicate registrations');

update person_name
set voided = 1,
	voided_by = 1,
	date_voided = now(),
	void_reason = 'SL-816 voiding duplicate registrations'
where person_id in 
	(select patient_id from patient where void_reason = 'SL-816 voiding duplicate registrations');

update patient_identifier
set voided = 1,
	voided_by = 1,
	date_voided = now(),
	void_reason = 'SL-816 voiding duplicate registrations'
where patient_id in 
	(select patient_id from patient where void_reason = 'SL-816 voiding duplicate registrations');
