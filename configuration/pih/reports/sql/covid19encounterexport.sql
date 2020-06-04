## THIS IS A ROW-PER-ENCOUNTER EXPORT
## THIS WILL RETURN A ROW FOR EACH COVID19 ENCOUNTER - ADMISSION, DAILY PROGRESS, AND DISCHARGE
## THE COLLECTED OBSERVATIONS ARE AVAILABLE AS COLUMNS
## FOR EFFICIENCY, THIS USES TEMPORARY TABLES TO LOAD DATA IN FROM OBS GROUPS AS APPROPRIATE

## THIS EXPECTS A startDate AND endDate PARAMETER IN ORDER TO RESTRICT BY ENCOUNTERS WITHIN A GIVEN DATE RANGE
## THE EVALUATOR WILL INSERT THESE AS BELOW WHEN EXECUTING.  YOU CAN UNCOMMENT THE BELOW LINES FOR MANUAL TESTING:

## set @startDate='2020-05-01';
## set @endDate='2020-05-31';

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
    encounter_provider  varchar(100)
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
## TODO

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
       e.encounter_provider
FROM temp_encounter e
;
