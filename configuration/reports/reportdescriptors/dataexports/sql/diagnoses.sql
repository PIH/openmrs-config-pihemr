-- set @startDate = '2021-01-01';
-- set @endDate = '2021-01-31';

SET @locale =   if(@startDate is null, 'en', GLOBAL_PROPERTY_VALUE('default_locale', 'en'));

DROP TEMPORARY TABLE IF EXISTS temp_diagnoses;
CREATE TEMPORARY TABLE temp_diagnoses
(
    	patient_id                      int(11),
 	encounter_id			int(11),
	obs_id				int(11),
	obs_datetime			datetime,
	diagnosis_entered		text,
	dx_order			varchar(255),
	certainty			varchar(255),
	coded				varchar(255),
	diagnosis_concept		int(11),
	diagnosis_coded_fr		varchar(255),
 	date_created			datetime
    );

insert into temp_diagnoses (
patient_id,
encounter_id,
obs_id,
obs_datetime,
date_created 
)
select 
o.person_id,
o.encounter_id,
o.obs_id,
o.obs_datetime,
o.date_created 
from obs o 
where concept_id = concept_from_mapping('PIH','Visit Diagnoses')
AND o.voided = 0
AND ((date(o.obs_datetime) >=@startDate) or @startDate is null)
AND ((date(o.obs_datetime) <=@endDate)  or @endDate is null)
;


create index temp_diagnoses_e on temp_diagnoses(encounter_id);
create index temp_diagnoses_p on temp_diagnoses(patient_id);

-- patient level info
DROP TEMPORARY TABLE IF EXISTS temp_dx_patient;
CREATE TEMPORARY TABLE temp_dx_patient
(
patient_id                      int(11),
dossierId                       varchar(50),
patient_primary_id              varchar(50),
loc_registered                  varchar(255),
unknown_patient			varchar(50),
gender				varchar(50),
department			varchar(255),
commune				varchar(255),
section				varchar(255),	
locality			varchar(255),
street_landmark			varchar(255),
birthdate			datetime,
birthdate_estimated		boolean,
section_communale_CDC_ID	varchar(11)	
    );
   
insert into temp_dx_patient(patient_id)
select distinct patient_id from temp_diagnoses;

create index temp_dx_patient_pi on temp_dx_patient(patient_id);

update temp_dx_patient set patient_primary_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_dx_patient set dossierid = dosid(patient_id);
update temp_dx_patient set loc_registered = loc_registered(patient_id);
update temp_dx_patient set unknown_patient = unknown_patient(patient_id);
update temp_dx_patient set gender = gender(patient_id);

update temp_dx_patient t
inner join person p on p.person_id  = t.patient_id
set t.birthdate = p.birthdate,
	t.birthdate_estimated = t.birthdate_estimated
;

update temp_dx_patient set department = person_address_state_province(patient_id);
update temp_dx_patient set commune = person_address_city_village(patient_id);
update temp_dx_patient set section = person_address_three(patient_id);
update temp_dx_patient set locality = person_address_one(patient_id);
update temp_dx_patient set street_landmark = person_address_two(patient_id);
update temp_dx_patient set section_communale_CDC_ID = cdc_id(patient_id);

-- encounter level information
DROP TEMPORARY TABLE IF EXISTS temp_dx_encounter;
CREATE TEMPORARY TABLE temp_dx_encounter
(
    	patient_id					int(11),
	encounter_id					int(11),
	encounter_location				varchar(255),
    	age_at_encounter				int(3),
	entered_by					varchar(255),
	provider					varchar(255),
	date_created					datetime,
	retrospective					int(1),
	visit_id					int(11),
	birthdate					datetime,
	birthdate_estimated				boolean,
	encounter_type					varchar(255)
    );
   
insert into temp_dx_encounter(patient_id,encounter_id)
select distinct patient_id, encounter_id from temp_diagnoses;

create index temp_dx_encounter_ei on temp_dx_encounter(encounter_id);

update temp_dx_encounter set encounter_location = encounter_location_name(encounter_id);
update temp_dx_encounter set provider = provider(encounter_id);
update temp_dx_encounter set age_at_encounter = age_at_enc(patient_id, encounter_id);


update temp_dx_encounter t
inner join encounter e on e.encounter_id  = t.encounter_id
inner join users u on u.user_id = e.creator 
set t.entered_by = person_name(u.person_id),
	t.visit_id = e.visit_id,
	t.encounter_type = encounterName(e.encounter_type);


       
 -- diagnosis info
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.value_coded_name_id ,o.comments 
from obs o
inner join temp_diagnoses t on t.obs_id = o.obs_group_id
where o.voided = 0;

create index temp_obs_concept_id on temp_obs(concept_id);
create index temp_obs_ogi on temp_obs(obs_group_id);
create index temp_obs_ci1 on temp_obs(obs_group_id, concept_id);

       
 update temp_diagnoses t
 left outer join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping('PIH','DIAGNOSIS')
 left outer join obs o_non on o_non.obs_group_id = t.obs_id and o_non.concept_id = concept_from_mapping('PIH','Diagnosis or problem, non-coded') 
 left outer join concept_name cn on cn.concept_name_id  = o.value_coded_name_id 
 set t.diagnosis_entered = IFNULL(cn.name,IFNULL( concept_name(o.value_coded,'en'),o_non.value_text)), 
 	 t.diagnosis_concept = o.value_coded,
     t.diagnosis_coded_fr = concept_name(o.value_coded,'fr'),
     t.coded = IF(o.value_coded is null, 0,1);

update temp_diagnoses t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','7537')
set t.dx_order = concept_name(o.value_coded, @locale);

update temp_diagnoses t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','1379')
set t.certainty = concept_name(o.value_coded, @locale);

-- diagnosis concept-level info
DROP TEMPORARY TABLE IF EXISTS temp_dx_concept;
CREATE TEMPORARY TABLE temp_dx_concept
(
	diagnosis_concept				int(11),				
	icd10_code					varchar(255),
	notifiable					int(1),
	urgent						int(1),
	santeFamn					int(1),
	psychological					int(1),
	pediatric					int(1),
	outpatient					int(1),
	ncd						int(1),
	non_diagnosis					int(1),	
	ed						int(1),	
	age_restricted					int(1),
	oncology					int(1)
    );
   
insert into temp_dx_concept(diagnosis_concept)
select distinct diagnosis_concept from temp_diagnoses;

create index temp_dx_patient_dc on temp_dx_concept(diagnosis_concept);


update temp_dx_concept set icd10_code = retrieveICD10(diagnosis_concept);
    
select concept_id into @non_diagnoses from concept where uuid = 'a2d2124b-fc2e-4aa2-ac87-792d4205dd8d';    
update temp_dx_concept set notifiable = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','8612'));
update temp_dx_concept set santeFamn = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7957'));
update temp_dx_concept set urgent = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7679'));
update temp_dx_concept set psychological = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7942'));
update temp_dx_concept set pediatric = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7933'));
update temp_dx_concept set outpatient = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7936'));
update temp_dx_concept set ncd = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7935'));
update temp_dx_concept set non_diagnosis = concept_in_set(diagnosis_concept, @non_diagnoses);
update temp_dx_concept set ed = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7934'));
update temp_dx_concept set age_restricted = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7677'));
update temp_dx_concept set oncology = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','8934'));
    
-- select final output
select 
p.patient_id,
p.dossierId,
p.patient_primary_id,
p.loc_registered,
p.unknown_patient,
p.gender,
e.age_at_encounter,
p.department,
p.commune,
p.section,
p.locality,
p.street_landmark,
e.encounter_id,
e.encounter_location,
d.obs_id,
d.obs_datetime,
e.entered_by,
e.provider,
d.diagnosis_entered,
d.dx_order,
d.certainty,
d.coded,
d.diagnosis_concept,
d.diagnosis_coded_fr,
dc.icd10_code,
dc.notifiable,
dc.urgent,
dc.santeFamn,
dc.psychological,
dc.pediatric,
dc.outpatient,
dc.ncd,
dc.non_diagnosis,
dc.ed,
dc.age_restricted,
dc.oncology,
e.date_created,
IF(TIME_TO_SEC(e.date_created) - TIME_TO_SEC(d.obs_datetime) > 1800,1,0) "retrospective",
e.visit_id,
p.birthdate,
p.birthdate_estimated,
e.encounter_type,
p.section_communale_CDC_ID
from temp_diagnoses d
inner join temp_dx_patient p on p.patient_id = d.patient_id
inner join temp_dx_encounter e on e.encounter_id = d.encounter_id
inner join temp_dx_concept dc on dc.diagnosis_concept = d.diagnosis_concept
;
