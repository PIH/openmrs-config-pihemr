-- set @startDate = '2021-01-01';
-- set @endDate = '2021-01-31';

SET @locale =   if(@startDate is null, 'en', GLOBAL_PROPERTY_VALUE('default_locale', 'en'));

DROP TEMPORARY TABLE IF EXISTS temp_diagnoses;
CREATE TEMPORARY TABLE temp_diagnoses
(
 patient_id               int(11),       
 dossierId                varchar(50),    
 patient_primary_id       varchar(50),    
 loc_registered           varchar(255),   
 unknown_patient          varchar(50),    
 gender                   varchar(50),    
 department               varchar(255),   
 commune                  varchar(255),   
 section                  varchar(255),   
 locality                 varchar(255),   
 street_landmark          varchar(255),   
 birthdate                datetime,       
 birthdate_estimated      boolean,        
 section_communale_CDC_ID varchar(11),   
 encounter_id             int(11),        
 age_at_encounter         int(3),        
 encounter_location       varchar(255),  
 encounter_type           varchar(255),  
 entered_by               varchar(1000), 
 provider                 varchar(1000), 
 visit_id                 int(11),       
 obs_id                   int(11),        
 obs_group_id             int(11),       
 obs_datetime             datetime,       
 diagnosis_entered        text,           
 dx_order                 varchar(255),   
 certainty                varchar(255),   
 coded                    varchar(255),   
 diagnosis_concept        int(11),        
 diagnosis_coded_fr       varchar(255),   
 date_created             datetime,      
 icd10_code               varchar(255),   
 notifiable               int(1),         
 urgent                   int(1),         
 santeFamn                int(1),         
 psychological            int(1),         
 pediatric                int(1),         
 outpatient               int(1),         
 ncd                      int(1),         
 non_diagnosis            int(1),         
 ed                       int(1),         
 age_restricted           int(1),         
 oncology                 int(1),
 retrospective            boolean
 );

-- insert diagnoses obs groups for coded dxs
insert into temp_diagnoses (
patient_id,
encounter_id,
obs_id,
obs_group_id,
obs_datetime,
date_created, 
diagnosis_concept,
coded
)
select 
o.person_id,
o.encounter_id,
obs_id,
o.obs_group_id,
o.obs_datetime,
o.date_created,
o.value_coded, 
1 
from obs o 
where concept_id = concept_from_mapping('PIH','3064')
AND o.voided = 0
AND ((date(o.obs_datetime) >=@startDate) or @startDate is null)
AND ((date(o.obs_datetime) <=@endDate)  or @endDate is null)
;
create index temp_diagnoses_e on temp_diagnoses(encounter_id);
create index temp_diagnoses_p on temp_diagnoses(patient_id);
create index temp_diagnoses_o on temp_diagnoses(obs_id);
create index temp_diagnoses_og on temp_diagnoses(obs_group_id);
create index temp_diagnoses_dc on temp_diagnoses(diagnosis_concept);

 -- diagnosis info
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.value_coded_name_id ,o.comments 
from obs o
inner join temp_diagnoses t on (t.obs_group_id = o.obs_group_id or t.obs_id = o.obs_id)
where o.voided = 0;

create index temp_obs_concept_id on temp_obs(concept_id);
create index temp_obs_ogi on temp_obs(obs_group_id);
create index temp_obs_ci1 on temp_obs(obs_group_id, concept_id);

 -- details for coded diagnoses
update temp_diagnoses t set t.diagnosis_entered = concept_name(diagnosis_concept,'en');
update temp_diagnoses t set t.diagnosis_coded_fr = concept_name(diagnosis_concept,'fr');

update temp_diagnoses t
inner join temp_obs o on o.obs_group_id = t.obs_group_id and o.concept_id = concept_from_mapping( 'PIH','7537')
set t.dx_order = concept_name(o.value_coded, @locale);

update temp_diagnoses t
inner join temp_obs o on o.obs_group_id = t.obs_group_id and o.concept_id = concept_from_mapping( 'PIH','1379')
set t.certainty = concept_name(o.value_coded, @locale);

-- diagnosis concept-level info
DROP TEMPORARY TABLE IF EXISTS temp_dx_concept;
CREATE TEMPORARY TABLE temp_dx_concept
(
 diagnosis_concept int(11),       
 icd10_code        varchar(255), 
 notifiable        int(1),       
 urgent            int(1),       
 santeFamn         int(1),       
 psychological     int(1),       
 pediatric         int(1),       
 outpatient        int(1),       
 ncd               int(1),       
 non_diagnosis     int(1),        
 ed                int(1),        
 age_restricted    int(1),       
 oncology          int(1)        
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

update temp_diagnoses d
inner join temp_dx_concept dc on dc.diagnosis_concept = d.diagnosis_concept
set d.icd10_code = dc.icd10_code,
	d.notifiable = dc.notifiable,
	d.urgent = dc.urgent,
	d.santeFamn = dc.santeFamn,
	d.psychological = dc.psychological,
	d.pediatric = dc.pediatric,
	d.outpatient = dc.outpatient,
	d.ncd = dc.ncd,
	d.non_diagnosis = dc.non_diagnosis,
	d.ed = dc.ed,
	d.age_restricted = dc.age_restricted,
	d.oncology = dc.oncology;

-- non coded dxs
insert into temp_diagnoses (
patient_id,
encounter_id,
obs_id,
obs_datetime,
date_created,
diagnosis_entered,
coded
)
select 
o.person_id,
o.encounter_id,
o.obs_id,
o.obs_datetime,
o.date_created,
o.value_text,
0
from obs o 
where concept_id = concept_from_mapping('PIH','Diagnosis or problem, non-coded')
AND o.voided = 0
AND ((date(o.obs_datetime) >=@startDate) or @startDate is null)
AND ((date(o.obs_datetime) <=@endDate)  or @endDate is null)
;

-- patient level info
DROP TEMPORARY TABLE IF EXISTS temp_dx_patient;
CREATE TEMPORARY TABLE temp_dx_patient
(
patient_id               int(11),      
dossierId                varchar(50),  
patient_primary_id       varchar(50),  
loc_registered           varchar(255), 
unknown_patient          varchar(50),  
gender                   varchar(50),  
department               varchar(255), 
commune                  varchar(255), 
section                  varchar(255),  
locality                 varchar(255), 
street_landmark          varchar(255), 
birthdate                datetime,     
birthdate_estimated      boolean,      
section_communale_CDC_ID varchar(11)    
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
	t.birthdate_estimated = t.birthdate_estimated;

update temp_dx_patient t
inner join person_address a on a.person_address_id =
	(select a2.person_address_id from person_address a2
	where a2.person_id = t.patient_id
	order by preferred desc, date_created desc limit 1)
set 	t.department = a.state_province,
	t.commune = a.city_village,
	t.section = a.address3,
	t.locality = a.address1,
	t.street_landmark = a.address2;

update temp_dx_patient set section_communale_CDC_ID = cdc_id(patient_id);

update temp_diagnoses t
inner join temp_dx_patient p on t.patient_id = p.patient_id
set t.dossierId = p.dossierId,
	t.patient_primary_id = p.patient_primary_id,
	t.loc_registered = p.loc_registered,
	t.unknown_patient = p.unknown_patient,
	t.gender = p.gender,
	t.department = p.department,
	t.commune = p.commune,
	t.section = p.section,
	t.locality = p.locality,
	t.street_landmark = p.street_landmark,
	t.birthdate = p.birthdate,
	t.birthdate_estimated = p.birthdate_estimated,
	t.section_communale_CDC_ID = p.section_communale_CDC_ID;

-- encounter level information
DROP TEMPORARY TABLE IF EXISTS temp_dx_encounter;
CREATE TEMPORARY TABLE temp_dx_encounter
(
 patient_id          int(11),      
 encounter_id        int(11),   
 encounter_location_id int(11),
 encounter_location  varchar(255),
 encounter_type_id   int(11),
 encounter_type      varchar(255),
 age_at_encounter    int(3),
 entered_by_user_id  int(11),
 entered_by          varchar(255), 
 provider            varchar(255), 
 date_created        datetime,     
 visit_id            int(11),      
 birthdate           datetime,     
 birthdate_estimated boolean     
);

insert into temp_dx_encounter(encounter_id)
select distinct encounter_id from temp_diagnoses;

create index temp_dx_encounter_ei on temp_dx_encounter(encounter_id);   

update temp_dx_encounter t
inner join encounter e on e.encounter_id  = t.encounter_id
set t.entered_by_user_id = e.creator,
	t.visit_id = e.visit_id,
	t.encounter_type_id = e.encounter_type,
	t.patient_id = e.patient_id,
	t.encounter_location_id = e.location_id,
	t.date_created = e.date_created 
;

update temp_dx_encounter set encounter_location = location_name(encounter_location_id);
update temp_dx_encounter set entered_by = person_name_of_user(entered_by_user_id);
update temp_dx_encounter set encounter_type = encounter_type_name_from_id(encounter_type_id);

update temp_dx_encounter set provider = provider(encounter_id);
update temp_dx_encounter set age_at_encounter = age_at_enc(patient_id, encounter_id);

update temp_diagnoses t
inner join temp_dx_encounter e on e.encounter_id = t.encounter_id
set t.age_at_encounter = e.age_at_encounter,
	t.date_created = e.date_created,
	t.encounter_id = e.encounter_id,
	t.encounter_location = e.encounter_location,
	t.encounter_type = e.encounter_type,
	t.entered_by = e.entered_by,
	t.provider = e.provider,
	t.visit_id = e.visit_id;

update temp_diagnoses t 
set t.retrospective = IF(TIME_TO_SEC(date_created) - TIME_TO_SEC(obs_datetime) > 1800,1,0) ;

-- select final output
select 
d.patient_id,
d.dossierId,
d.patient_primary_id,
d.loc_registered,
d.unknown_patient,
d.gender,
d.age_at_encounter,
d.department,
d.commune,
d.section,
d.locality,
d.street_landmark,
d.encounter_id,
d.encounter_location,
d.obs_id,
d.obs_datetime,
d.entered_by,
d.provider,
d.diagnosis_entered,
d.dx_order,
d.certainty,
d.coded,
d.diagnosis_concept,
d.diagnosis_coded_fr,
d.icd10_code,
d.notifiable,
d.urgent,
d.santeFamn,
d.psychological,
d.pediatric,
d.outpatient,
d.ncd,
d.non_diagnosis,
d.ed,
d.age_restricted,
d.oncology,
d.date_created,
d.retrospective,
d.visit_id,
d.birthdate,
d.birthdate_estimated,
d.encounter_type,
d.section_communale_CDC_ID
from temp_diagnoses d
;
