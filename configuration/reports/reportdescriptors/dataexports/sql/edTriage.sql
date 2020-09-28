CALL initialize_global_metadata();

-- set @startDate = '2019-07-01';
-- set @endDate = '2020-12-31';

SELECT encounter_type_id into @EDTriageEnc from encounter_type where uuid = '74cef0a6-2801-11e6-b67b-9e71128cae77';
SELECT encounter_type_id into @consEnc from encounter_type where uuid = '92fd09b4-5335-4f7e-9f63-b2a663fd09a6';
SELECT name into @consEncName from encounter_type where uuid = '92fd09b4-5335-4f7e-9f63-b2a663fd09a6';
select form_id into @consForm from form where uuid = 'a3fc5c38-eb32-11e2-981f-96c0fcb18276';
select form_id into @edNoteForm from form where uuid = '793915d6-f8d9-11e2-8ff2-fd54ab5fdb2a';

set @locale = global_property_value('default_locale', @locale);

drop temporary table if exists temp_ED_Triage;
create temporary table temp_ED_Triage
(
patient_id int(11), 
encounter_id int(11),
visit_id int(11),
zlemr_id varchar(255), 
dossier_id varchar(255), 
loc_registered varchar(255), 
unknown_patient varchar(255), 
gender varchar(255), 
age_at_enc int, 
address varchar(255),
ED_Visit_Start_Datetime datetime,
Triage_datetime datetime, 
encounter_location varchar(255),
provider varchar(255),
Triage_queue_status varchar(255),
Triage_Color varchar(255),
Triage_Score int,
Chief_Complaint text,
Weight_KG double ,
Mobility varchar(255),
Respiratory_Rate double,
Blood_Oxygen_Saturation double,
Pulse double,
Systolic_Blood_Pressure double,
Diastolic_Blood_Pressure double,
Temperature_C double ,
Response varchar(255),
Trauma_Present varchar(255),
Neurological varchar(255),
Burn varchar(255),
Glucose varchar(255),
Trauma_type varchar(255),
Digestive varchar(255),
Pregnancy varchar(255),
Respiratory varchar(255),
Pain varchar(255),
Other_Symptom varchar(255),
Clinical_Impression text,
Pregnancy_Test varchar(255),
Glucose_Value double,
Paracetamol_dose double,
Treatment_Administered  varchar(255),
Wait_Minutes double,
EDNote_encounter_id int(11),
EDNote_Datetime datetime,
EDNote_Disposition  varchar(255),
ED_Diagnosis1 varchar(255),
ED_Diagnosis2 varchar(255),
ED_Diagnosis3 varchar(255),
ED_Diagnosis_noncoded varchar(255),
Consult_encounter_id int(11),
Consult_Datetime datetime,
Consult_Disposition varchar(255),
Cons_Diagnosis1 varchar(255),
Cons_Diagnosis2 varchar(255),
Cons_Diagnosis3 varchar(255),
Cons_Diagnosis_noncoded varchar(255)
);

insert into temp_ED_Triage (patient_id, encounter_id, visit_id, Triage_datetime)
select e.patient_id, e.encounter_id, e.visit_id,e.encounter_datetime
from encounter e
where e.encounter_type = @EDTriageEnc and e.voided = 0
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
;

-- Dossier number
UPDATE temp_ED_Triage SET dossier_id = DOSID(patient_id);

-- zlemr_id
UPDATE temp_ED_Triage SET zlemr_id = ZLEMR(patient_id);

-- person address
UPDATE temp_ED_Triage SET address = PERSON_ADDRESS(patient_id);

-- Provider
UPDATE temp_ED_Triage SET provider = PROVIDER(encounter_id);

-- encounter location
UPDATE temp_ED_Triage SET encounter_location = ENCOUNTER_LOCATION_NAME(encounter_id);

-- gender
UPDATE temp_ED_Triage SET gender = GENDER(patient_id);

-- age at encounter
UPDATE temp_ED_Triage SET age_at_enc = age_at_enc(patient_id,encounter_id);

-- unknown patient
UPDATE temp_ED_Triage SET unknown_patient = unknown_patient(patient_id);

-- location registered
UPDATE temp_ED_Triage SET loc_registered = loc_registered(patient_id);

-- ED Visit Start Datetime
UPDATE temp_ED_Triage t
inner join visit v on t.visit_id = v.visit_id
set t.ED_Visit_Start_Datetime = v.date_started;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','Triage queue status')
set t.Triage_queue_status = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','Triage color classification')
set t.Triage_Color = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','Triage score')
set t.Triage_Score = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('CIEL','160531')
set t.Chief_Complaint = o.value_text;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','WEIGHT (KG)')
set t.Weight_KG = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','Mobility')
set t.Mobility = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','RESPIRATORY RATE')
set t.Respiratory_Rate = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','BLOOD OXYGEN SATURATION')
set t.Blood_Oxygen_Saturation = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','PULSE')
set t.Pulse = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','SYSTOLIC BLOOD PRESSURE')
set t.Systolic_Blood_Pressure = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','DIASTOLIC BLOOD PRESSURE')
set t.Diastolic_Blood_Pressure = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','TEMPERATURE (C)')
set t.Temperature_C = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Response triage symptom')
set t.Response = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
  and o.value_coded = concept_from_mapping('PIH','Traumatic Injury')
set t.Trauma_Present = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Neurological triage symptom')
set t.Neurological = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Burn triage symptom')
set t.Burn = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Glucose triage symptom')
set t.Glucose = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Trauma triage symptom')
set t.Trauma_type = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Digestive triage symptom')
set t.Digestive = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','10721')
set t.Pregnancy = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Respiratory triage symptom')
set t.Respiratory = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Pain triage symptom')
set t.Pain = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
  and o.concept_id =concept_from_mapping('PIH','Triage diagnosis')
inner join concept_set cs on cs.concept_id = o.value_coded and cs.concept_set = concept_from_mapping('PIH','Other triage symptom')
set t.Other_Symptom = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','CLINICAL IMPRESSION COMMENTS')
set t.Clinical_Impression = o.value_text;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','B-HCG')
set t.Pregnancy_Test = concept_name(o.value_coded,@locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','SERUM GLUCOSE')
set t.Glucose_Value = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','Paracetamol dose (mg)')
set t.Paracetamol_dose = o.value_numeric;

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','3077')
set t.Wait_Minutes = round(o.value_numeric/60,0);

-- since treatment administered will be a list of obs potentially, 
-- this is done with a grouped subquery 
update temp_ED_Triage t
inner join 
  (select o.encounter_id, group_concat(concept_name(o.value_coded,@locale) separator ',') "treatments"
   from obs o
   where o.voided =0
   and o.concept_id =concept_from_mapping('PIH','Emergency treatment')
   group by o.encounter_id) et on et.encounter_id = t.encounter_id 
set t.Treatment_Administered = et.treatments
;

-- The following statements gather information on the last consult (non-ED note) from the ED triage visit
update temp_ED_Triage t
set Consult_encounter_id = latestEncForminVisit(patient_id, @consEncName,visit_id, @consForm,null);

update temp_ED_Triage t
set Consult_Datetime = encounter_date(Consult_encounter_id);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.Consult_encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','HUM Disposition categories')
set t.Consult_Disposition = concept_name(o.value_coded,@locale);


update temp_ED_Triage 
set Cons_Diagnosis1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(Consult_encounter_id, 'PIH', 'Visit Diagnoses', 0), 'CIEL', '1284', @locale);
update temp_ED_Triage 
set Cons_Diagnosis2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(Consult_encounter_id, 'PIH', 'Visit Diagnoses', 1), 'CIEL', '1284', @locale);
update temp_ED_Triage 
set Cons_Diagnosis3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(Consult_encounter_id, 'PIH', 'Visit Diagnoses', 2), 'CIEL', '1284', @locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.Consult_encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','Diagnosis or problem, non-coded')
set t.ED_Diagnosis_noncoded = o.value_text;



-- The following statements gather information on the last ED note from the ED triage visit
update temp_ED_Triage t
set EDNote_encounter_id = latestEncForminVisit(patient_id, @consEncName,visit_id, @edNoteForm,null);

update temp_ED_Triage t
set EDNote_Datetime = encounter_date(EDNote_encounter_id);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.EDNote_encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','HUM Disposition categories')
set t.EDNote_Disposition = concept_name(o.value_coded,@locale);


update temp_ED_Triage 
set ED_Diagnosis1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(EDNote_encounter_id, 'PIH', 'Visit Diagnoses', 0), 'CIEL', '1284', @locale);
update temp_ED_Triage 
set ED_Diagnosis2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(EDNote_encounter_id, 'PIH', 'Visit Diagnoses', 1), 'CIEL', '1284', @locale);
update temp_ED_Triage 
set ED_Diagnosis3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(EDNote_encounter_id, 'PIH', 'Visit Diagnoses', 2), 'CIEL', '1284', @locale);

update temp_ED_Triage t
inner join obs o on o.encounter_id = t.EDNote_encounter_id and o.voided =0
and o.concept_id =concept_from_mapping('PIH','Diagnosis or problem, non-coded')
set t.ED_Diagnosis_noncoded = o.value_text;

-- final output of data
Select
patient_id,
encounter_id,
visit_id,
zlemr_id,
dossier_id,
loc_registered,
unknown_patient,
gender,
age_at_enc,
address,
ED_Visit_Start_Datetime,
Triage_datetime,
encounter_location,
provider,
encounter_id,
Triage_queue_status,
Triage_Color,
Triage_Score,
Chief_Complaint,
Weight_KG,
Mobility,
Respiratory_Rate,
Blood_Oxygen_Saturation,
Pulse,
Systolic_Blood_Pressure,
Diastolic_Blood_Pressure,
Temperature_C,
Response,
Trauma_Present,
Neurological,
Burn,
Glucose,
Trauma_type,
Digestive,
Pregnancy,
Respiratory,
Pain,
Other_Symptom,
Clinical_Impression,
Pregnancy_Test,
Glucose_Value,
Paracetamol_dose,
Treatment_Administered,
Wait_Minutes,
EDNote_Datetime,
EDNote_Disposition,
ED_Diagnosis1,
ED_Diagnosis2,
ED_Diagnosis3,
ED_Diagnosis_noncoded,
Consult_Datetime,
Consult_Disposition,
Cons_Diagnosis1,
Cons_Diagnosis2,
Cons_Diagnosis3,
Cons_Diagnosis_noncoded
from temp_ED_Triage;
