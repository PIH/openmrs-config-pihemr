## THIS REPORT RETURNS EVERY INSTANCE OF A PATIENT WHO HAS EVER BEEN IN THE UMI WARD OR COVID-19 ISOLATION
## IF A PATIENT HAS BEEN ADMITTED MULTIPLE TIMES, THEY WILL APPEAR MULTIPLE TIMES ON THIS REPORT
##
## THE COLLECTED OBSERVATIONS ARE AVAILABLE AS COLUMNS
## FOR EFFICIENCY, THIS USES TEMPORARY TABLES TO LOAD DATA IN FROM OBS GROUPS AS APPROPRIATE

## CREATE SCHEMA FOR DATA EXPORT

drop temporary table if exists temp_report;
create temporary table temp_report
(
    patient_id                  int,
    admission_encounter_id      int,
    last_progress_encounter_id  int,
    discharge_encounter_id      int,
    latest_encounter_id         int,
    current_ward                varchar(255),
    date_of_admission           datetime,
    zlemr_id                    varchar(50),
    age_at_admission            int,
    patient_name                varchar(200),
    gender                      char(1),
    transfer_facility_name      varchar(255),
    comorbidities               varchar(500),
    symptoms                    varchar(1000),
    covid19_diagnosis_status    varchar(100),
    other_diagnoses             varchar(1000),
    covid19_classification      varchar(100),
    supporting_care             varchar(500),
    clinical_plan               varchar(1000),
    nursing_notes               varchar(1000),
    date_of_discharge           datetime,
    discharge_disposition       varchar(100),
    discharge_comments          varchar(1000)
);

## THIS REPORT SHOULD BE BASED OFF OF COVID-19 ADMISSION ENCOUNTERS.  START OUT WITH ROWS OF THESE ENCOUNTERS

insert into temp_report (
    patient_id,
    admission_encounter_id,
    date_of_admission
)
select
    e.patient_id,
    e.encounter_id,
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
    et.name = 'COVID-19 Admission';

## REMOVE TEST PATIENTS

delete
from temp_report
where patient_id in
      (
          select a.person_id
          from person_attribute a
          inner join person_attribute_type t on a.person_attribute_type_id = t.person_attribute_type_id
          where a.value = 'true'
          and t.name = 'Test Patient'
      );

# DETERMINE THE DISCHARGE ENCOUNTER TO ASSOCIATE WITH THIS, IF ANY, BASED ON THE ADMISSION DATE

update temp_report set discharge_encounter_id = firstEnc(patient_id, 'COVID-19 Discharge', date_of_admission);
update temp_report set date_of_discharge = encounter_date(discharge_encounter_id);

# DETERMINE THE MOST RECENT PROGRESS AND OVERALL ENCOUNTERS FOR THE VISIT, TO USE FOR PULLING LATEST OBSERVATIONS

update temp_report set last_progress_encounter_id = latestEncBetweenDates(
    patient_id,
    'COVID-19 Progress',
    date_of_admission,
    date_of_discharge
);

update temp_report set latest_encounter_id = coalesce(discharge_encounter_id, last_progress_encounter_id, admission_encounter_id);

# If patient is not discharged, set their current ward to the location of their latest encounter during the admission
update temp_report set current_ward = encounter_location_name(latest_encounter_id) where discharge_encounter_id is null;

# Pull in patient demographics and identifiers
update temp_report set zlemr_id = zlemr(patient_id);
update temp_report set age_at_admission = age_at_enc(patient_id, admission_encounter_id);
update temp_report set patient_name = person_name(patient_id);
update temp_report set gender = gender(patient_id);

# Add in observations that are specific to the admission encounter

update temp_report set transfer_facility_name = obs_value_text(
    admission_encounter_id,
    'CIEL',
    '161550'
);

update temp_report set comorbidities = obs_value_coded_list(
    admission_encounter_id,
    'CIEL',
    '162747',
    'fr'
);

# Add in observations that are found on the admission and progress encounters

update temp_report set symptoms = obs_value_coded_list(
    coalesce(last_progress_encounter_id, admission_encounter_id),
    'CIEL',
    '1728',
    'fr'
);

update temp_report set covid19_diagnosis_status = obs_value_coded_list(
    latest_encounter_id,
    'CIEL',
    '165793',
    'fr'
);

update temp_report set other_diagnoses = obs_value_coded_list(
    latest_encounter_id,
    'CIEL',
    '1284',
    'fr'
);

update temp_report set covid19_classification = obs_value_coded_list(
    latest_encounter_id,
    'CIEL',
    '159640',
    'fr'
);

update temp_report set supporting_care = obs_value_coded_list(
    coalesce(last_progress_encounter_id, admission_encounter_id),
    'CIEL',
    '165995',
    'fr'
);

update temp_report set clinical_plan = obs_value_text(
    latest_encounter_id,
    'CIEL',
    '162749'
);

update temp_report set nursing_notes = obs_value_text(
    coalesce(last_progress_encounter_id, admission_encounter_id),
    'CIEL',
    '162879'
);

update temp_report set discharge_disposition = obs_value_coded_list(
    discharge_encounter_id,
    'PIH',
    '8620',
    'fr'
);

update temp_report set discharge_comments = obs_value_text(
    discharge_encounter_id,
    'CIEL',
    '161011'
);

# EXECUTE SELECT TO EXPORT TABLE CONTENTS

SELECT
    current_ward,
    date_of_admission,
    zlemr_id,
    age_at_admission,
    patient_name,
    gender,
    transfer_facility_name,
    comorbidities,
    symptoms,
    covid19_diagnosis_status,
    other_diagnoses,
    covid19_classification,
    supporting_care,
    clinical_plan,
    nursing_notes,
    date_of_discharge,
    discharge_disposition,
    discharge_comments
FROM temp_report
;
