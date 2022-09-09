select program_workflow_id into @MCH_treatment from program_workflow pw where uuid = '41a277d0-8a14-11e8-9a94-a6cf71072f73';
select program_id into @matHealthProgram from program where uuid = '41a2715e-8a14-11e8-9a94-a6cf71072f73';
select concept_id into @mothersGroup from concept where uuid = 'c1b2db38-8f72-4290-b6ad-99826734e37e';
select concept_id into @edd from concept where uuid = '3cee56a6-26fe-102b-80cb-0017a47871b2';
select concept_id into @add from concept where uuid = '5599AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
select relationship_type_id into @aParentToB from relationship_type  where uuid = '8d91a210-c2cc-11de-8d13-0010c6dffd0f' ;
select person_attribute_type_id into @tele from person_attribute_type pat where pat.uuid =  '14d4f066-15f5-102d-96e4-000c29c2a5d7';
select encounter_type_id into @obgynEncId from encounter_type et where uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d' ;
select encounter_type_id into @delEncId from encounter_type et  where uuid = '00e5ebb2-90ec-11e8-9eb6-529269fb1459' ;
-- SET @locale = ifnull(@locale, GLOBAL_PROPERTY_VALUE('default_locale', 'en'));

drop TEMPORARY TABLE IF EXISTS temp_J9_patients;
create temporary table temp_J9_patients
(
    patient_id int(11),
    patient_program_id int(11),
    patient_uuid char(38),
    given_name varchar(50),
    family_name varchar(50),
    ZL_identifier varchar(50),
    Dossier_identifier varchar(50),
    J9_group_max_datetime datetime,
    J9_group text,
    J9_program varchar(50),
    telephone varchar(50),
    birthdate date,
    age int(3),
    edd_max_datetime datetime,
    estimated_delivery_date date,
    add_max_datetime datetime,
    actual_delivery_date date,
    mama_dossier varchar(50),
    department varchar(255),
    commune varchar(255),
    section_communal varchar(255),
    locality varchar(255),
    street_landmark varchar(255),
    j9_enrollment_date datetime
)
;

-- load one row per patient in program
insert into temp_J9_patients (patient_id, patient_program_id, j9_enrollment_date)
Select pp.patient_id, pp.patient_program_id ,pp.date_enrolled 
FROM patient_program pp 
WHERE  pp.program_id = @matHealthProgram and pp.voided = 0  and pp.date_completed is NULL;

create index temp_J9_patients_pi on temp_J9_patients(patient_id);

-- load all relevant encounters (for use later to narrow down observations)
drop temporary table if exists temp_obgyn_enc;
create temporary table temp_obgyn_enc
select e.encounter_id  from encounter e
inner join temp_J9_patients t on t.patient_id = e.patient_id 
where e.encounter_type in ( @obgynEncId, @delEncId)
and e.voided = 0;

-- uuid, age,  birthdate
update temp_J9_patients t
inner join person p on p.person_id = t.patient_id
	set patient_uuid = p.uuid,
		t.birthdate = p.birthdate;

update temp_J9_patients t
set t.age = TIMESTAMPDIFF(YEAR,t.birthdate, now());

-- program state
update temp_J9_patients t
set t.J9_program = currentProgramState(t.patient_program_id,@MCH_treatment,'en');

-- telephone number
update temp_J9_patients t
    left outer join person_attribute pa on pa.person_id = t.patient_id and pa.person_attribute_type_id = @tele
        and pa.voided = 0
set t.telephone = pa.value;

-- patient address
update temp_J9_patients t
    left outer join current_name_address cna on cna.person_id = t.patient_id
set t.department = cna.department,
    t.commune = cna.commune,
    t.section_communal = cna.section_communal,
    t.locality = cna.locality,
    t.street_landmark = cna.street_landmark;

   -- identifiers
update temp_J9_patients t
set t.ZL_identifier =  zlEMR(t.patient_id);

update temp_J9_patients t
set t.Dossier_identifier =  dosId(t.patient_id);

-- patient names
update temp_J9_patients t
    left outer join current_name_address cna on cna.person_id = t.patient_id
set t.given_name = cna.given_name,
    t.family_name = cna.family_name;

-- ------------- latest mothers group -------------------------
DROP TEMPORARY TABLE IF EXISTS temp_mg_obs;
create temporary table temp_mg_obs 
select o.obs_id,  o.person_id, o.concept_id, o.value_text,o.obs_datetime 
from obs o
inner join temp_obgyn_enc t on t.encounter_id = o.encounter_id
where o.voided = 0
and o.concept_id = @mothersGroup; 

create index temp_mg_obs_ci on temp_mg_obs(person_id, obs_datetime);

update temp_J9_patients t
inner join obs o on o.obs_id =
	(select o2.obs_id from temp_mg_obs o2
	where o2.person_id = t.patient_id
	order by o2.obs_datetime desc limit 1)
set t.J9_group = o.value_text;

-- ------------- latest expected delivery date -------------------------
DROP TEMPORARY TABLE IF EXISTS temp_edd_obs;
create temporary table temp_edd_obs 
select o.obs_id, o.person_id, o.value_datetime, o.obs_datetime 
from obs o
inner join temp_obgyn_enc t on t.encounter_id = o.encounter_id
where o.voided = 0
and o.concept_id = @edd;

create index temp_edd_obs_ci on temp_edd_obs(person_id, obs_datetime);

update temp_J9_patients t
inner join obs o on o.obs_id =
	(select o2.obs_id from temp_edd_obs o2
	where o2.person_id = t.patient_id
	order by o2.obs_datetime desc limit 1)
set t.estimated_delivery_date = o.obs_datetime;

-- ------------- latest actual delivery date -------------------------
DROP TEMPORARY TABLE IF EXISTS temp_add_obs;
create temporary table temp_add_obs 
select o.obs_id, o.person_id, o.value_datetime, o.obs_datetime 
from obs o
inner join temp_obgyn_enc t on t.encounter_id = o.encounter_id
where o.voided = 0
and o.concept_id = @add;

create index temp_add_obs_ci on temp_add_obs(person_id, obs_datetime);

update temp_J9_patients t
inner join obs o on o.obs_id =
	(select o2.obs_id from temp_add_obs o2
	where o2.person_id = t.patient_id
	order by o2.obs_datetime desc limit 1)
set t.actual_delivery_date = o.obs_datetime;

-- Baby's mother: return dossier id of mother (parent who is female) if the patient is < 1 year
update temp_J9_patients t
    left outer join relationship rm on rm.person_b = t.patient_id and rm.voided = 0 and rm.relationship = @aParentToB
        and gender(rm.person_a) = 'F'
        and  TIMESTAMPDIFF(YEAR,t.birthdate, now()) < 1
-- mother's dossier id
set t.mama_dossier = dosId(rm.person_a);

select
    patient_id,
    patient_uuid,
    given_name,
    family_name,
    ZL_identifier,
    Dossier_identifier,
    J9_group,
    J9_program,
    telephone,
    birthdate,
    age,
    estimated_delivery_date,
    actual_delivery_date,
    mama_dossier,
    department,
    commune,
    section_communal,
    locality,
    street_landmark,
    j9_enrollment_date
from temp_J9_patients;
