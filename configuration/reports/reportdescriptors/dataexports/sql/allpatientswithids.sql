CALL initialize_global_metadata();

DROP TEMPORARY TABLE IF EXISTS temp_patients;
CREATE TEMPORARY TABLE temp_patients
(
	patient_id					int(11),
	family_name					varchar(255),
	given_name					varchar(255),
	patient_address_level_1				varchar(255),
	patient_address_level_2				varchar(255),
	patient_address_level_3				varchar(255),
	patient_address_level_4				varchar(255),
	patient_address_level_5				varchar(255),
	birthdate					datetime,
	birthdate_estimated				char(1),
	age						double,
	gender						char(1),
	patient_primary_id				varchar(50),
	dossier_id					varchar(50),
	telephone_number				varchar(50),
	Section_Communale_CDC_ID			varchar(11),
	last_biometric_date				datetime
	);

insert into temp_patients (patient_id)
select patient_id from patient where voided = 0
;

-- patient name
update temp_patients t set t.family_name = person_family_name(patient_id);
update temp_patients t set t.given_name = person_given_name(patient_id);

-- person table fields
update temp_patients t
inner join person p on p.person_id = t.patient_id
set t.birthdate = p.birthdate,
	t.birthdate_estimated = p.birthdate_estimated,
	t.gender = p.gender,
    t.age = TIMESTAMPDIFF(YEAR, p.birthdate, NOW());

-- primary identifier
update temp_patients set patient_primary_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));

-- dossier id
update temp_patients set dossier_id = patient_identifier(patient_id, 'e66645eb-03a8-4991-b4ce-e87318e37566');

-- telephone number
update temp_patients t set t.telephone_number = phone_number(patient_id);

-- patient address
-- *NOTE* it seems that CDC ID is not working
update temp_patients t
INNER JOIN person_address pa on pa.person_address_id =
	(select person_address_id from person_address pa2
	where pa2.person_id = t.patient_id
	and pa2.voided = 0
	order by preferred desc, date_created desc limit 1)
LEFT OUTER JOIN address_hierarchy_entry ahe_country on ahe_country.level_id = 1 and ahe_country.name = pa.country
LEFT OUTER JOIN address_hierarchy_entry ahe_dept on ahe_dept.level_id = 2 and ahe_dept.parent_id = ahe_country.address_hierarchy_entry_id and ahe_dept.name = pa.state_province
LEFT OUTER JOIN address_hierarchy_entry ahe_commune on ahe_commune.level_id = 3 and ahe_commune.parent_id = ahe_dept.address_hierarchy_entry_id and ahe_commune.name = pa.city_village
LEFT OUTER JOIN address_hierarchy_entry ahe_section on ahe_section.level_id = 4 and ahe_section.parent_id = ahe_commune.address_hierarchy_entry_id and ahe_section.name = pa.address3
set patient_address_level_1 = pa.state_province,
	patient_address_level_2 = pa.city_village,
	patient_address_level_3 = pa.address3,
	patient_address_level_4 = pa.address1,
	patient_address_level_5 = pa.address2,
	Section_Communale_CDC_ID = ahe_section.user_generated_id;

-- commenting out this statement for biometric ID date, because it performs really poorly
/*
update temp_patients t
inner join patient_identifier bio on bio.patient_identifier_id =
    (select patient_identifier_id from patient_identifier bio2
    where t.patient_id = bio2.patient_id
    and bio2.identifier_type = @biometricId
    and bio2.voided = 0
    order by date_created desc limit 1)
set t.last_biometric_date = bio.date_created;
*/


SELECT
       family_name,
       given_name,
       patient_address_level_1,
       patient_address_level_2,
       patient_address_level_3,
       patient_address_level_4,
       patient_address_level_5,
       birthdate,
       birthdate_estimated,
       age,
       gender,
       patient_primary_id,
       dossier_id,
       telephone_number,
       Section_Communale_CDC_ID,
       last_biometric_date
from temp_patients;
