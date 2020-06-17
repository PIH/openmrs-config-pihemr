## THIS IS A ROW-PER-ENCOUNTER EXPORT
## THIS WILL RETURN A ROW FOR EACH COVID19 ENCOUNTER - ADMISSION, DAILY PROGRESS, AND DISCHARGE
## THE COLLECTED OBSERVATIONS ARE AVAILABLE AS COLUMNS
## FOR EFFICIENCY, THIS USES TEMPORARY TABLES TO LOAD DATA IN FROM OBS GROUPS AS APPROPRIATE

## THIS EXPECTS A startDate AND endDate PARAMETER IN ORDER TO RESTRICT BY ENCOUNTERS WITHIN A GIVEN DATE RANGE
## THE EVALUATOR WILL INSERT THESE AS BELOW WHEN EXECUTING.  YOU CAN UNCOMMENT THE BELOW LINES FOR MANUAL TESTING:

# set @startDate='2020-05-01';
# set @endDate='2020-05-31';

## sql updates
set sql_safe_updates = 0;

## CREATE SCHEMA FOR DATA EXPORT

drop temporary table if exists temp_encounter;
create temporary table temp_encounter
(
    encounter_id        int primary key,
    patient_id          int,
    dossier_num         varchar(50),
    zlemr_id            varchar(50),
    gender              char(1),
    birthdate           date,
    address             varchar(500),
    phone_number        varchar(50),
    encounter_type      varchar(50),
    encounter_location  varchar(255),
    encounter_datetime  datetime,
    encounter_provider  varchar(100),
    health_care_worker  varchar(11),
    pregnant            varchar(11),
    last_menstruation_date  datetime,
    estimated_delivery_date datetime,
    postpartum_state varchar(255),
    outcome varchar(100),
    postpartum_state_1 varchar(255),
    outcome_1 varchar(100),
    date_of_delivery datetime,
    home_medications text,
    allergies text,
    symptom_start_date datetime,
    symptoms text,
    other_symptoms text,
    comorbidities varchar(11),
    available_comorbidities text,
    other_comorbidities text,
    mental_health text,
    smoker varchar(11),
    transfer varchar(11),
	transfer_facility varchar(255),
	covid_case_contact varchar(11),
    case_condition varchar(50),
	temp double,
	heart_rate double,
	respiratory_rate double,
	bp_systolic double,
	bp_diastolic double,
    SpO2 double,
    room_air varchar(11),
    cap_refill varchar(50),
    cap_refill_time double,
	pain varchar(50),
    general_exam varchar(11),
    general_findings text,
    heent varchar(11),
    heent_findings text,
    neck varchar(11),
    neck_findings text,
    chest varchar(11),
    chest_findings text,
    cardiac varchar(11),
    cardiac_findings text,
    abdominal varchar(11),
    abdominal_findings text,
    urogenital varchar(11),
    urogenital_findings text,
    rectal varchar(11),
    rectal_findings text,
    musculoskeletal varchar(11),
    musculoskeletal_findings text,
    lymph varchar(11),
    lymph_findings text,
    skin varchar(11),
    skin_findings text,
    neuro varchar(11),
    neuro_findings text,
    avpu varchar(255),
    other_findings text,
    medications varchar(255),
    medication_comments text,
    supportive_care varchar(255),
	o2therapy double,
    analgesic_specified varchar(255)
);

## POPULATE WITH BASE DATA FROM ENCOUNTER, PATIENT, AND PERSON
## EXCLUDING VOIDED, AND INCLUDING ONLY THE RELEVANT ENCOUNTER TYPES

insert into temp_encounter (
    encounter_id,
    patient_id,
    gender,
    birthdate,
    encounter_type,
    encounter_datetime
)
select
    e.encounter_id,
    e.patient_id,
    pr.gender,
    pr.birthdate,
    et.name,
    e.encounter_datetime
from
    encounter e
        inner join patient p on p.patient_id = e.patient_id
        inner join person pr on pr.person_id = e.patient_id
        left join encounter_type et on et.encounter_type_id = e.encounter_type
where
    pr.voided = 0 and
    p.voided = 0 and
    e.voided = 0 and
    et.name in ('COVID-19 Admission', 'COVID-19 Progress', 'COVID-19 Discharge');

## REMOVE TEST PATIENTS

delete
from temp_encounter
where patient_id in
      (
          select a.person_id
          from person_attribute a
                   inner join person_attribute_type t on a.person_attribute_type_id = t.person_attribute_type_id
          where a.value = 'true'
            and t.name = 'Test Patient'
      );

# ADD DETAILS FOR PATIENT

update temp_encounter set dossier_num = dosId(patient_id);
update temp_encounter set zlemr_id = zlemr(patient_id);
update temp_encounter set address = person_address(patient_id);
update temp_encounter set phone_number = person_attribute_value(patient_id, 'Telephone Number');

# ADD DETAILS FOR ENCOUNTER

update temp_encounter set encounter_provider = provider(encounter_id);
update temp_encounter set encounter_location = encounter_location_name(encounter_id);

# ADD OBSERVATIONS

###DEMOGRAPHICS
##ADMISSION FORM

## Health Care Worker
update temp_encounter set health_care_worker = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '5619',
    'fr'
);

## Pregnancy
####Pregnant
update temp_encounter set pregnant = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '5272',
    'fr'
);

-- last menstruation date
update temp_encounter te left join obs o
on  o.concept_id = concept_from_mapping('CIEL', '1427')
and o.person_id = te.patient_id 
and o.encounter_id = te.encounter_id 
and o.voided = 0 
set te.last_menstruation_date = o.value_datetime;

-- estimated delivery date
update temp_encounter te left join obs o
on  o.concept_id = concept_from_mapping('CIEL', '5596')
and o.person_id = te.patient_id 
and o.encounter_id = te.encounter_id 
and o.voided = 0 
set te.estimated_delivery_date = o.value_datetime;

-- postpartum state 

update temp_encounter set postpartum_state = obs_single_value_coded(
     encounter_id,
	'CIEL', 
	'162747',
	'CIEL', 
	'129317'
); 

-- outcome
update temp_encounter set outcome = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '161033',
    'fr'
);

-- date of delivery
update temp_encounter te left join obs o
on  o.concept_id = concept_from_mapping('CIEL', '5599')
and o.person_id = te.patient_id 
and o.encounter_id = te.encounter_id 
and o.voided = 0 
set te.date_of_delivery = o.value_datetime;

### HOME MEDICATION
update temp_encounter set home_medications = obs_value_text(
     encounter_id,
    'CIEL',
    '162165'
);

### ALLERGIES
update temp_encounter set allergies = obs_value_text(
     encounter_id,
    'CIEL',
    '162141'
);

## SIGNS AND SYMPTOMS
-- start date
update temp_encounter te left join obs o
on  o.concept_id = concept_from_mapping('CIEL', '1730')
and o.person_id = te.patient_id 
and o.encounter_id = te.encounter_id 
and o.voided = 0 
set te.symptom_start_date = o.value_datetime;

-- symptoms
update temp_encounter set symptoms = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '1727', #1728
    'fr'
);

-- other symptoms
update temp_encounter set other_symptoms = obs_value_text(
     encounter_id,
    'CIEL',
    '165996'
);

### COMORBIDITIES
-- comorbidities
update temp_encounter set comorbidities = obs_value_coded_list(
     encounter_id,
    'PIH',
    '12976',
    'fr'
);

-- comorbidities
update temp_encounter set available_comorbidities = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '162747',
    'fr'
);

-- other comorbidities
update temp_encounter te
left join obs o 
on  o.person_id = te.patient_id 
and o.encounter_id = te.encounter_id
and o.voided = 0
and o.concept_id = concept_from_mapping('CIEL', '162747')
and o.value_coded = concept_from_mapping('CIEL','5622')
set other_comorbidities = o.comments;

update temp_encounter set mental_health = obs_value_text(
	 encounter_id,
    'CIEL',
    '163044'
);

-- smoker
update temp_encounter set smoker = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '163731',
    'fr'
);

#### ADMISSION
-- transfer
update temp_encounter set transfer = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '160563',
    'fr'
);

update temp_encounter set transfer_facility = obs_value_text(
     encounter_id,
    'CIEL',
    '161550'
);

update temp_encounter set covid_case_contact = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '162633',
    'fr'
);

update temp_encounter set case_condition = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '159640',
    'fr'
);

### ViTALS
update temp_encounter set temp = obs_value_numeric(
     encounter_id,
    'CIEL',
    '5088'
);

update temp_encounter set heart_rate = obs_value_numeric(
     encounter_id,
    'CIEL',
    '5087'
);

update temp_encounter set respiratory_rate = obs_value_numeric(
     encounter_id,
    'CIEL',
    '5242'
);

update temp_encounter set bp_systolic = obs_value_numeric(
     encounter_id,
    'CIEL',
    '5085'
);

update temp_encounter set bp_diastolic = obs_value_numeric(
     encounter_id,
    'CIEL',
    '5086'
);

update temp_encounter set SpO2 = obs_value_numeric(
     encounter_id,
    'CIEL',
    '5092'
);

-- room air
update temp_encounter set room_air = obs_single_value_coded(
     encounter_id,
    'CIEL',
    '162739',
    'CIEL',
    '162735'
);

-- Cap refill and Cap refill time
update temp_encounter set cap_refill = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '165890',
    'en'
);

update temp_encounter set cap_refill_time = obs_value_numeric(
     encounter_id,
    'CIEL',
    '162513'
);

-- Pain
update temp_encounter set pain = obs_value_coded_list(
     encounter_id,
    'CIEL',
    '166000',
    'fr'
);

#### PHYSICAL EXAM
-- General
update temp_encounter set general_exam = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1119',
    'fr'
);
update temp_encounter set general_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '163042'
);
-- HEENT
update temp_encounter set heent = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1122',
    'fr'
);
update temp_encounter set heent_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '163045'
);
-- Neck
update temp_encounter set neck = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '163388',
    'fr'
);
update temp_encounter set neck_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '165983'
);
-- chest
update temp_encounter set chest = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1123',
    'fr'
);
update temp_encounter set chest_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '160689'
);
-- cardiac
update temp_encounter set cardiac = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1124',
    'fr'
);
update temp_encounter set cardiac_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '163046'
);
-- abdominal
update temp_encounter set abdominal = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1125',
    'fr'
);
update temp_encounter set abdominal_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '160947'
);
-- urogenital
update temp_encounter set urogenital = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1126',
    'fr'
);
update temp_encounter set urogenital_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '163047'
);
-- rectal
update temp_encounter set rectal = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '163746',
    'fr'
);
update temp_encounter set rectal_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '160961'
);
-- musculoskeletal
update temp_encounter set musculoskeletal = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1128',
    'fr'
);
update temp_encounter set musculoskeletal_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '163048'
);
-- lymph
update temp_encounter set lymph = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1121',
    'fr'
);
update temp_encounter set lymph_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '166005'
);
-- skin
update temp_encounter set skin = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1120',
    'fr'
);
update temp_encounter set skin_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '160981'
);
-- neuro
update temp_encounter set neuro = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '1129',
    'fr'
);
update temp_encounter set neuro_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '163109'
);
-- avpu
update temp_encounter set avpu = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '162643',
    'fr'
);
-- other
update temp_encounter set other_findings = obs_value_text(
	encounter_id,
    'CIEL',
    '163042'
);

## TREATMENT
-- Medications
update temp_encounter set medications = obs_value_coded_list(
	encounter_id,
    'PIH',
    '1282',
    'fr'
);
update temp_encounter set medication_comments = obs_value_text(
	encounter_id,
    'PIH',
    'Medication comments (text)'
);

-- supportive care
update temp_encounter set supportive_care = obs_value_coded_list(
	encounter_id,
    'CIEL',
    '165995',
    'fr'
);
-- o2therapy value
update temp_encounter set o2therapy = obs_value_numeric(
	encounter_id,
    'CIEL',
    '165986'
);
-- analgesic comments/description
update temp_encounter set analgesic_specified = obs_value_text(
	encounter_id,
    'CIEL',
    '163206'
);
-- IV fluid details
drop table if exists temp_stage1_ivf;
create table temp_stage1_ivf(
select 	person_id, 
		encounter_id,
		obs_id, 
        concept_id, 
        obs_group_id, 
        concept_name(value_coded, 'fr') ivf_values,
        value_numeric
from obs where 
		concept_id in (concept_from_mapping('CIEL', '161911'), concept_from_mapping('CIEL', '165987'), concept_from_mapping('CIEL', '166006')) 
        and voided = 0 and encounter_id in (select encounter_id from encounter where encounter_type in (select encounter_type_id from encounter_type et where
        et.name in ('COVID-19 Admission', 'COVID-19 Progress', 'COVID-19 Discharge'))));
         
drop temporary table if exists temp_stage2_ivf;
create temporary table temp_stage2_ivf(
select person_id, encounter_id, obs_group_id, group_concat(ivf_values separator " | ") ivf_value_coded from temp_stage_ivf
group by obs_group_id, person_id);

alter table temp_stage2_ivf
add column ivf_value_numeric double after ivf_value_coded;

drop temporary table if exists temp_stage2_ivf_numeric;
create temporary table temp_stage2_ivf_numeric
(select person_id, encounter_id, obs_group_id, value_numeric from temp_stage1_ivf where value_numeric is not null);

update temp_stage2_ivf ts2 
left join temp_stage2_ivf_numeric ts1 on  ts2.person_id = ts1.person_id and ts2.encounter_id = ts1.encounter_id and ts2.obs_group_id = ts1.obs_group_id
set ivf_value_numeric = ts1.value_numeric;

drop temporary table if exists temp_final1_ivf;
create temporary table temp_final1_ivf(
	person_id int(11), 
	encounter_id int(11),
    obs_group_id1 int(11),
    obs_group_id2 int(11),
    obs_group_id3 int(11),
    ivf1 text,
    ivf2 text,
    ivf3 text
);
insert into temp_final1_ivf (person_id, encounter_id, obs_group_id1)
( 
select person_id, encounter_id, max(obs_group_id) from temp_stage2_ivf group by encounter_id
);

update temp_final1_ivf tf left join temp_stage2_ivf ts on tf.obs_group_id1 = ts.obs_group_id 
set ivf1 = concat(if(ivf_value_coded is null, '', ivf_value_coded), " | ", if(ivf_value_numeric is null, '', ivf_value_numeric));

drop temporary table if exists temp_stage_final1_ivf;
create temporary table temp_stage_final1_ivf
(
	encounter_id int(11),
	obsgid2 int(11),
	ivf_value_coded2 text, 
	ivf_value_numeric2 text
); 

insert into temp_stage_final1_ivf(encounter_id, obsgid2)
(select encounter_id, max(obs_group_id) obsgid2 from temp_stage2_ivf ts where ts.obs_group_id not in (select obs_group_id1 from temp_final1_ivf) group by encounter_id);

update temp_final1_ivf tf left join temp_stage_final1_ivf tsf on tf.encounter_id = tsf.encounter_id
set obs_group_id2 = obsgid2;

update temp_stage_final1_ivf tf left join temp_stage2_ivf tsf on tf.obsgid2 = tsf.obs_group_id
set ivf_value_coded2 = ivf_value_coded;
 
update temp_stage_final1_ivf tf left join temp_stage2_ivf tsf on tf.obsgid2 = tsf.obs_group_id 
set ivf_value_numeric2 = ivf_value_numeric;

update temp_final1_ivf tf left join temp_stage_final1_ivf ts on tf.obs_group_id2 = ts.obsgid2 
set ivf2 = concat(if(ivf_value_coded2 is null, '', ivf_value_coded2), " | ", if(ivf_value_numeric2 is null, '', ivf_value_numeric2));

drop temporary table if exists temp_stage_final2_ivf;
create temporary table temp_stage_final2_ivf
(
	encounter_id int(11),
	obsgid3 int(11),
	ivf_value_coded3 text, 
	ivf_value_numeric3 text
); 

insert into temp_stage_final2_ivf(encounter_id, obsgid3)
(select encounter_id, obs_group_id obsgid3 from temp_stage2_ivf ts where ts.obs_group_id not in (select obs_group_id1 from temp_final1_ivf) 
and obs_group_id not in (select obsgid2 from temp_stage_final1_ivf)
group by encounter_id);

update temp_final1_ivf tf left join temp_stage_final2_ivf tsf on tf.encounter_id = tsf.encounter_id
set obs_group_id3 = obsgid3;

update temp_stage_final2_ivf tf left join temp_stage2_ivf tsf on tf.obsgid3 = tsf.obs_group_id
set ivf_value_coded3 = ivf_value_coded;
    
update temp_stage_final2_ivf tf left join temp_stage2_ivf tsf on tf.obsgid3 = tsf.obs_group_id 
set ivf_value_numeric3 = ivf_value_numeric;

update temp_final1_ivf tf left join temp_stage_final2_ivf ts on tf.obs_group_id3 = ts.obsgid3 
set ivf3 = concat(if(ivf_value_coded3 is null, '', ivf_value_coded3), " | ", if(ivf_value_numeric3 is null, '', ivf_value_numeric3));

# EXECUTE SELECT TO EXPORT TABLE CONTENTS

SELECT e.encounter_id,
       e.patient_id,
       e.dossier_num       as dossierId,
       e.zlemr_id          as zlemr,
       e.gender,
       e.birthdate,
       e.address,
       e.phone_number,
       e.encounter_type,
       e.encounter_location,
       e.encounter_datetime,
       e.encounter_provider,
       e.health_care_worker,
       e.pregnant,
       e.last_menstruation_date,
       e.estimated_delivery_date,
       e.postpartum_state,
       e.outcome,
       e.date_of_delivery,
       e.home_medications,
       e.allergies,
       e.symptom_start_date,
       e.symptoms,
       e.other_symptoms,
       e.comorbidities,
       e.available_comorbidities,
       e.other_comorbidities,
       e.mental_health,
       e.smoker,
       e.transfer,
	   e.transfer_facility,
       e.covid_case_contact,
       e.case_condition,
	   e.temp,
	   e.heart_rate,
	   e.respiratory_rate,	
	   e.bp_systolic,
	   e.bp_diastolic,
       e.SpO2 ,
       e.room_air,
       e.cap_refill,
	   e.cap_refill_time,
       e.pain,
       e.general_exam,
       e.general_findings,
	   e.heent,
       e.heent_findings,
	   e.neck,
       e.neck_findings,
	   e.chest,
       e.chest_findings,
	   e.cardiac,
       e.cardiac_findings,
       e.abdominal,
       e.abdominal_findings,
       e.urogenital,
       e.urogenital_findings,
       e.rectal,
       e.rectal_findings,
       e.musculoskeletal,
       e.musculoskeletal_findings,
       e.lymph,
       e.lymph_findings, 
       e.skin,
       e.skin_findings,
       e.neuro,
       e.neuro_findings,
       e.avpu,
       e.other_findings,
       e.medications,
       e.medication_comments,
       e.supportive_care,
       e.o2therapy,
       e.analgesic_specified,
       tf.ivf1,
       tf.ivf2,
       tf.ivf3
FROM temp_encounter e left join temp_final1_ivf tf on e.encounter_id = tf.encounter_id;
