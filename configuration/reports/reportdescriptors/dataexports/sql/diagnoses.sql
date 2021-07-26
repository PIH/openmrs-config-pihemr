-- set @startDate = '2021-05-01';
-- set @endDate = '2021-06-01';

SET @locale =   if(@startDate is null, 'en', GLOBAL_PROPERTY_VALUE('default_locale', 'en'));


DROP TEMPORARY TABLE IF EXISTS temp_diagnoses;
CREATE TEMPORARY TABLE temp_diagnoses
(
    patient_id                      int(11),
    dossierId                       varchar(50),
    patient_primary_id              varchar(50),
    loc_registered                  varchar(255),
    unknown_patient					varchar(50),
    gender							varchar(50),
    age_at_encounter				int(3),
    department						varchar(255),
	commune							varchar(255),
	section							varchar(255),	
	locality						varchar(255),
	street_landmark					varchar(255),
	encounter_id					int(11),
	encounter_location				varchar(255),
	obs_id							int(11),
	obs_datetime					datetime,
	entered_by						varchar(255),
	provider						varchar(255),
	diagnosis_entered				text,
	dx_order						varchar(255),
	certainty						varchar(255),
	coded							varchar(255),
	diagnosis_concept				int(11),
	diagnosis_coded_fr				varchar(255),
	icd10_code						varchar(255),
	notifiable						int(1),
	urgent							int(1),
	santeFamn						int(1),
	psychological					int(1),
	pediatric						int(1),
	outpatient						int(1),
	ncd								int(1),
	non_diagnosis					int(1),	
	ed								int(1),	
	age_restricted					int(1),
	oncology						int(1),
	date_created					datetime,
	retrospective					int(1),
	visit_id						int(11),
	birthdate						datetime,
	birthdate_estimated				boolean,
	encounter_type					varchar(255),
	section_communale_CDC_ID		varchar(11)	
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

-- encounter and demo info
update temp_diagnoses set patient_primary_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_diagnoses set dossierid = dosid(patient_id);
update temp_diagnoses set loc_registered = loc_registered(patient_id);
update temp_diagnoses set encounter_location = encounter_location_name(encounter_id);
update temp_diagnoses set provider = provider(encounter_id);
update temp_diagnoses set unknown_patient = unknown_patient(patient_id);
update temp_diagnoses set gender = gender(patient_id);
update temp_diagnoses set age_at_encounter = age_at_enc(patient_id, encounter_id);

update temp_diagnoses t
inner join person p on p.person_id  = t.patient_id
set t.birthdate = p.birthdate,
	t.birthdate_estimated = t.birthdate_estimated
;

update temp_diagnoses set department = person_address_state_province(patient_id);
update temp_diagnoses set commune = person_address_city_village(patient_id);
update temp_diagnoses set section = person_address_three(patient_id);
update temp_diagnoses set locality = person_address_one(patient_id);
update temp_diagnoses set street_landmark = person_address_two(patient_id);
update temp_diagnoses set section_communale_CDC_ID = cdc_id(patient_id);


update temp_diagnoses t
inner join encounter e on e.encounter_id  = t.encounter_id
inner join users u on u.user_id = e.creator 
set t.entered_by = person_name(u.person_id),
	t.visit_id = e.visit_id,
	t.encounter_type = encounterName(e.encounter_type);

update temp_diagnoses t
set t.retrospective =
 IF(TIME_TO_SEC(date_created) - TIME_TO_SEC(obs_datetime) > 1800,
        1,0);
       
 -- diagnosis info
 update temp_diagnoses t
 left outer join obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping('PIH','DIAGNOSIS')
 left outer join obs o_non on o_non.obs_group_id = t.obs_id and o_non.concept_id = concept_from_mapping('PIH','Diagnosis or problem, non-coded') 
 left outer join concept_name cn on cn.concept_name_id  = o.value_coded_name_id 
 set t.diagnosis_entered = IFNULL(cn.name,IFNULL( concept_name(o.value_coded,'en'),o_non.value_text)), 
 	 t.diagnosis_concept = o.value_coded,
     t.diagnosis_coded_fr = concept_name(o.value_coded,'fr'),
     t.coded = IF(o.value_coded is null, 0,1);

update temp_diagnoses set dx_order = obs_from_group_id_value_coded_list(obs_id, 'PIH','7537',@locale);
update temp_diagnoses set certainty = obs_from_group_id_value_coded_list(obs_id, 'PIH','1379',@locale);

update temp_diagnoses set icd10_code = retrieveICD10(diagnosis_concept);
    
select concept_id into @non_diagnoses from concept where uuid = 'a2d2124b-fc2e-4aa2-ac87-792d4205dd8d';    
update temp_diagnoses set notifiable = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','8612'));
update temp_diagnoses set santeFamn = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7957'));
update temp_diagnoses set urgent = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7679'));
update temp_diagnoses set psychological = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7942'));
update temp_diagnoses set pediatric = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7933'));
update temp_diagnoses set outpatient = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7936'));
update temp_diagnoses set ncd = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7935'));
update temp_diagnoses set non_diagnosis = concept_in_set(diagnosis_concept, @non_diagnoses);
update temp_diagnoses set ed = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7934'));
update temp_diagnoses set age_restricted = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7677'));
update temp_diagnoses set oncology = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','8934'));
    
-- select final output
select * from temp_diagnoses;
