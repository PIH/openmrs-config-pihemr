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
	bp_diastolic double
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
update temp_encounter te left join obs o
on  o.concept_id = concept_from_mapping('CIEL', '162747')
and o.person_id = te.patient_id 
and o.encounter_id = te.encounter_id 
and o.voided = 0 
and o.value_coded = concept_from_mapping('CIEL', '129317')
set te.postpartum_state = concept_name(o.value_coded, 'fr');

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
	   e.bp_diastolic
FROM temp_encounter e;