## THIS IS A ROW-PER-ENCOUNTER EXPORT
## THIS WILL RETURN A ROW FOR EACH COVID19 ENCOUNTER - ADMISSION, DAILY PROGRESS, AND DISCHARGE
## THE COLLECTED OBSERVATIONS ARE AVAILABLE AS COLUMNS
## FOR EFFICIENCY, THIS USES TEMPORARY TABLES TO LOAD DATA IN FROM OBS GROUPS AS APPROPRIATE

## THIS EXPECTS A startDate AND endDate PARAMETER IN ORDER TO RESTRICT BY ENCOUNTERS WITHIN A GIVEN DATE RANGE
## THE EVALUATOR WILL INSERT THESE AS BELOW WHEN EXECUTING.  YOU CAN UNCOMMENT THE BELOW LINES FOR MANUAL TESTING:

## sql updates
SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

## CREATE SCHEMA FOR DATA EXPORT
DROP TEMPORARY TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter
(
encounter_id            INT PRIMARY KEY,
patient_id              INT,
dossier_num             VARCHAR(50),
zlemr_id                VARCHAR(50),
gender                  CHAR(1),
birthdate               DATE,
address                 VARCHAR(500),
phone_number            VARCHAR(50),
encounter_type          VARCHAR(50),
encounter_location      VARCHAR(255),
encounter_datetime      DATETIME,
encounter_provider      VARCHAR(100),
health_care_worker      VARCHAR(11),
hcw_type 				VARCHAR(50),
pregnant                VARCHAR(11),
last_menstruation_date  DATETIME,
estimated_delivery_date DATETIME,
gestational_outcome     VARCHAR(255),
breast_feed             VARCHAR(255),
vaccination_up_todate   VARCHAR(255),
postpartum_state        VARCHAR(255),
outcome                 VARCHAR(100),
postpartum_state_1      VARCHAR(255),
outcome_1               VARCHAR(100),
date_of_delivery        DATETIME,
home_medications        TEXT,
allergies               TEXT,
symptom_start_date      DATETIME,
symptoms                TEXT,
other_symptoms          TEXT,
comorbidities           VARCHAR(11),
available_comorbidities TEXT,
other_comorbidities     TEXT,
mental_health           TEXT,
smoker                  VARCHAR(255),
transfer                VARCHAR(11),
transfer_facility       VARCHAR(255),
covid_case_contact      VARCHAR(11),
case_condition          VARCHAR(50),
temp                    DOUBLE,
heart_rate              DOUBLE,
respiratory_rate        DOUBLE,
bp_systolic             DOUBLE,
bp_diastolic            DOUBLE,
SpO2                    DOUBLE,
room_air                VARCHAR(11),
cap_refill              VARCHAR(50),
cap_refill_time         DOUBLE,
pain                    VARCHAR(50),
general_exam            VARCHAR(11),
general_findings        TEXT,
heent                   VARCHAR(11),
heent_findings          TEXT,
neck                    VARCHAR(11),
neck_findings           TEXT,
chest                   VARCHAR(11),
chest_findings          TEXT,
cardiac                 VARCHAR(11),
cardiac_findings        TEXT,
abdominal               VARCHAR(11),
abdominal_findings      TEXT,
urogenital              VARCHAR(11),
urogenital_findings     TEXT,
rectal                  VARCHAR(11),
rectal_findings         TEXT,
musculoskeletal         VARCHAR(11),
musculoskeletal_findings TEXT,
lymph                   VARCHAR(11),
lymph_findings          TEXT,
skin                    VARCHAR(11),
skin_findings           TEXT,
neuro                   VARCHAR(11),
neuro_findings          TEXT,
avpu                    VARCHAR(255),
other_findings          TEXT,
medications             VARCHAR(255),
medication_comments     TEXT,
supportive_care         TEXT,
o2therapy_value			DOUBLE,
analgesic_specified     VARCHAR(255),
covid19                VARCHAR(255),
diagnosis_order1		VARCHAR(255),
diagnosis1				TEXT,
diagnosis_certainity1 	VARCHAR(255),
diagnosis_order2		VARCHAR(255),
diagnosis2				TEXT,
diagnosis_certainity2 	VARCHAR(255),
diagnosis_order3		VARCHAR(255),
diagnosis3				TEXT,
diagnosis_certainity3 	VARCHAR(255),
diagnosis_order4		VARCHAR(255),
diagnosis4				TEXT,
diagnosis_certainity4 	VARCHAR(255),
diagnosis_order5		VARCHAR(255),
diagnosis5				TEXT,
diagnosis_certainity5 	VARCHAR(255),
specimen_date1          DATETIME,
specimens_type1         VARCHAR(255),
specimens_ordered1		TEXT,
antibody_result1        VARCHAR(255),
antigen_result1         VARCHAR(255),
pcr_result1             VARCHAR(255),
genexpert_result1       VARCHAR(255),
specimen_date2          DATETIME,
specimens_type2         VARCHAR(255),
specimens_ordered2		TEXT,
antibody_result2        VARCHAR(255),
antigen_result2         VARCHAR(255),
pcr_result2             VARCHAR(255),
genexpert_result2       VARCHAR(255),
specimen_date3          DATETIME,
specimens_type3         VARCHAR(255),
specimens_ordered3		TEXT,
antibody_result3        VARCHAR(255),
antigen_result3         VARCHAR(255),
pcr_result3             VARCHAR(255),
genexpert_result3       VARCHAR(255),
hemoglobin              DOUBLE,
hematocrit              DOUBLE,
wbc                     DOUBLE,
platelets               DOUBLE,
lymphocyte              DOUBLE,
neutrophil              DOUBLE,
crp                     DOUBLE,
sodium                  DOUBLE,
potassium               DOUBLE,
urea                    DOUBLE,
creatinine              DOUBLE,
glucose                 DOUBLE,
bilirubin               DOUBLE,
sgpt                    DOUBLE,
sgot                    DOUBLE,
pH                      DOUBLE,
pcO2                    DOUBLE,
pO2                     DOUBLE,
tcO2                    DOUBLE,
hcO3                    DOUBLE,
be                      DOUBLE,
sO2                     DOUBLE,
lactate                 DOUBLE,
radiology_order1        VARCHAR(255),
radiology_findings1     TEXT,
radiology_order2        VARCHAR(255),
radiology_findings2     TEXT,
radiology_order3        VARCHAR(255),
radiology_findings3     TEXT,
radiology_order4        VARCHAR(255),
radiology_findings4     TEXT,
radiology_other         VARCHAR(255),
radiology_other_comments TEXT,
disposition             VARCHAR(255),
admission_ward          VARCHAR(255),
clinical_management_plan TEXT,
nursing_note            TEXT,
mh_referral             VARCHAR(11),
mh_note                 TEXT,
transfer_out_location   VARCHAR(255),
overall_condition       VARCHAR(255),
symptom_names1          TEXT,
oxygen_therapy          VARCHAR(11),
non_inv_ventilation     VARCHAR(11),
vasopressors            VARCHAR(11),
antibiotics             VARCHAR(11),
other_intervention      TEXT,
icu                     VARCHAR(11),
days_in_icu             INT(11),
icu_admission_date      DATETIME,
icu_discharge_date      DATETIME,
-- medications          TEXT,
other_antibiotics       TEXT,
-- other_medications    TEXT,
discharge_condition     VARCHAR(255),
-- followup_plan           TEXT,
discharge_comments      TEXT,
return_visit_date       DATETIME
);

## POPULATE WITH BASE DATA FROM ENCOUNTER, PATIENT, AND PERSON
## EXCLUDING VOIDED, AND INCLUDING ONLY THE RELEVANT ENCOUNTER TYPES

INSERT INTO temp_encounter (
encounter_id,
patient_id,
gender,
birthdate,
encounter_type,
encounter_datetime
)
SELECT
e.encounter_id,
e.patient_id,
pr.gender,
pr.birthdate,
et.name,
DATE(e.encounter_datetime)
FROM
encounter e
INNER JOIN patient p ON p.patient_id = e.patient_id
INNER JOIN person pr ON pr.person_id = e.patient_id
LEFT JOIN encounter_type et ON et.encounter_type_id = e.encounter_type
WHERE
DATE(e.encounter_datetime) >=  @startDate AND
DATE(e.encounter_datetime) <=  @endDate AND
pr.voided = 0 AND
p.voided = 0 AND
e.voided = 0 AND
et.name IN ('COVID-19 Admission', 'COVID-19 Progress', 'COVID-19 Discharge');

-- Test patient
DELETE FROM temp_encounter
WHERE
patient_id IN (SELECT
a.person_id
FROM
person_attribute a
INNER JOIN
person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id

WHERE
a.value = 'true'
AND t.name = 'Test Patient');

-- Dossier number
UPDATE temp_encounter SET dossier_num = DOSID(patient_id);

-- zlemr_id
UPDATE temp_encounter SET zlemr_id = ZLEMR(patient_id);

-- person address
UPDATE temp_encounter SET address = PERSON_ADDRESS(patient_id);

-- Phone number
UPDATE temp_encounter SET phone_number = PERSON_ATTRIBUTE_VALUE(patient_id, 'Telephone Number');

-- Provider
UPDATE temp_encounter SET encounter_provider = PROVIDER(encounter_id);

-- encounter location
UPDATE temp_encounter SET encounter_location = ENCOUNTER_LOCATION_NAME(encounter_id);

-- Health care worker
UPDATE temp_encounter SET health_care_worker = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '5619', 'en');

-- Health care worker type
UPDATE temp_encounter SET hcw_type = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '166014', 'en');

UPDATE temp_encounter SET pregnant = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '5272', 'en');

-- last menstruation date
UPDATE temp_encounter SET last_menstruation_date = OBS_VALUE_DATETIME(encounter_id, 'CIEL', '1427');

-- estimated delivery date
UPDATE temp_encounter SET estimated_delivery_date = OBS_VALUE_DATETIME(encounter_id, 'CIEL', '5596');

-- postpartum state
UPDATE temp_encounter SET postpartum_state = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '129317');

-- outcome
UPDATE temp_encounter SET outcome = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '161033', 'en');

-- date of delivery
UPDATE temp_encounter SET date_of_delivery = OBS_VALUE_DATETIME(encounter_id, 'CIEL', '5599');

-- Infant
UPDATE temp_encounter SET gestational_outcome = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '161033', 'en');

-- Breast feeding
UPDATE temp_encounter SET breast_feed = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL','5632', 'en');

-- Vaccination
UPDATE temp_encounter SET vaccination_up_todate = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '5585', 'en');

-- home medication
UPDATE temp_encounter SET home_medications = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162165');

UPDATE temp_encounter SET allergies = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162141');

-- Symptom start date
UPDATE temp_encounter SET symptom_start_date = OBS_VALUE_DATETIME(encounter_id, 'CIEL', '1730');

-- Symptoms
UPDATE temp_encounter SET symptoms = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1728', 'en');

-- other symptoms
UPDATE temp_encounter SET other_symptoms = OBS_VALUE_TEXT(encounter_id, 'CIEL', '165996');

-- Comorbidities
UPDATE temp_encounter SET comorbidities = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '12976', 'en');

-- available comorbidities
UPDATE temp_encounter SET available_comorbidities = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162747', 'en');

-- other comorbidities
UPDATE temp_encounter te SET  other_comorbidities = OBS_COMMENTS(encounter_id, 'CIEL', '162747', 'PIH', 'OTHER');

-- mental health comment
-- note for this, to retrieve the mental health comment, you need to find the referral construct for the encounter, ensure it is a mental health referral and then update based on that obs_group
UPDATE temp_encounter t
INNER JOIN obs o_c ON o_c.obs_id = OBS_ID(t.encounter_id, 'PIH','12837',0) AND OBS_FROM_GROUP_ID_VALUE_CODED_LIST(o_c.obs_id,'CIEL','1272','en') = CONCEPT_NAME( CONCEPT_FROM_MAPPING('PIH','5489'),'en')
SET mental_health = OBS_FROM_GROUP_ID_VALUE_TEXT(o_c.obs_id,'CIEL','161011');

-- smoker
UPDATE temp_encounter SET smoker = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163731', 'en');

-- transfer
UPDATE temp_encounter SET transfer = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '160563', 'en');
UPDATE temp_encounter SET transfer_facility = OBS_VALUE_TEXT(encounter_id, 'CIEL', '161550');

-- covid case contact
UPDATE temp_encounter SET covid_case_contact = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162633', 'en');

-- case condition
UPDATE temp_encounter SET case_condition = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '159640', 'en');

##VITALS
-- vitals
UPDATE temp_encounter SET temp = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5088');

UPDATE temp_encounter SET heart_rate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5087');

UPDATE temp_encounter SET respiratory_rate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5242');

UPDATE temp_encounter SET bp_systolic = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5085');

UPDATE temp_encounter SET bp_diastolic = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5086');

UPDATE temp_encounter SET SpO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5092');

-- room air
UPDATE temp_encounter SET room_air = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162739', 'CIEL', '162735');

-- Cap refill and Cap refill time
UPDATE temp_encounter SET cap_refill = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165890', 'en');

UPDATE temp_encounter SET cap_refill_time = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '162513');

-- Pain
UPDATE temp_encounter SET pain = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '166000', 'en');

########## Phyical Exams
UPDATE temp_encounter SET general_exam = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1119', 'en');
UPDATE temp_encounter SET general_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163042');

-- HEENT
UPDATE temp_encounter SET heent = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1122', 'en');
UPDATE temp_encounter SET heent_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163045');

-- Neck
UPDATE temp_encounter SET neck = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163388', 'en');
UPDATE temp_encounter SET neck_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '165983');

-- chest
UPDATE temp_encounter SET chest = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1123', 'en');
UPDATE temp_encounter SET chest_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160689');

-- cardiac
UPDATE temp_encounter SET cardiac = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1124', 'en');
UPDATE temp_encounter SET cardiac_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163046');

-- abdominal
UPDATE temp_encounter SET abdominal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1125', 'en');
UPDATE temp_encounter SET abdominal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160947');

-- urogenital
UPDATE temp_encounter SET urogenital = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1126', 'en');
UPDATE temp_encounter SET urogenital_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163047');

-- rectal
UPDATE temp_encounter SET rectal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163746', 'en');
UPDATE temp_encounter SET rectal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160961');

-- musculoskeletal
UPDATE temp_encounter SET musculoskeletal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1128', 'en');
UPDATE temp_encounter SET musculoskeletal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163048');

-- lymph
UPDATE temp_encounter SET lymph = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1121', 'en');
UPDATE temp_encounter SET lymph_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '166005');

-- skin
UPDATE temp_encounter SET skin = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1120', 'en');
UPDATE temp_encounter SET skin_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160981');

-- neuro
UPDATE temp_encounter SET neuro = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1129', 'en');
UPDATE temp_encounter SET neuro_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163109');

-- avpu
UPDATE temp_encounter SET avpu = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162643', 'en');

-- other
UPDATE temp_encounter SET other_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163042');

-- medications
UPDATE temp_encounter SET medications = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '1282', 'en');
UPDATE temp_encounter SET medication_comments = OBS_VALUE_TEXT(encounter_id, 'PIH', 'Medication comments (text)');

-- supportive care
UPDATE temp_encounter SET supportive_care = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165995', 'en');

-- o2therapy_value value
UPDATE temp_encounter SET o2therapy_value = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165986');

-- analgesic comments/description
UPDATE temp_encounter SET analgesic_specified = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163206');

##### IVF
-- This part returns 3 columns and in each column we have " | | "
-- IV fluid details
DROP TEMPORARY TABLE IF EXISTS temp_stage1_ivf;
CREATE TEMPORARY TABLE temp_stage1_ivf (SELECT person_id,
encounter_id,
obs_id,
concept_id,
obs_group_id,
CONCEPT_NAME(value_coded, 'en') ivf_values,
value_numeric FROM
obs
WHERE
concept_id IN (CONCEPT_FROM_MAPPING('CIEL', '161911') , CONCEPT_FROM_MAPPING('CIEL', '165987'),
CONCEPT_FROM_MAPPING('CIEL', '166006'))
AND voided = 0
AND encounter_id IN (SELECT
encounter_id
FROM
encounter
WHERE
encounter_type IN (SELECT
encounter_type_id
FROM
encounter_type et
WHERE
et.name IN ('COVID-19 Admission' , 'COVID-19 Progress',
'COVID-19 Discharge'))));

DROP TEMPORARY TABLE IF EXISTS temp_stage2_ivf;
CREATE TEMPORARY TABLE temp_stage2_ivf(
SELECT person_id, encounter_id, obs_group_id, GROUP_CONCAT(ivf_values SEPARATOR " | ") ivf_value_coded FROM temp_stage1_ivf
GROUP BY obs_group_id, person_id);

ALTER TABLE temp_stage2_ivf
ADD COLUMN ivf_value_numeric DOUBLE AFTER ivf_value_coded;

DROP TEMPORARY TABLE IF EXISTS temp_stage2_ivf_numeric;
CREATE TEMPORARY TABLE temp_stage2_ivf_numeric
(SELECT person_id, encounter_id, obs_group_id, value_numeric FROM temp_stage1_ivf WHERE value_numeric IS NOT NULL);

UPDATE temp_stage2_ivf ts2
LEFT JOIN
temp_stage2_ivf_numeric ts1 ON ts2.person_id = ts1.person_id
AND ts2.encounter_id = ts1.encounter_id
AND ts2.obs_group_id = ts1.obs_group_id
SET
ivf_value_numeric = ts1.value_numeric;

DROP TEMPORARY TABLE IF EXISTS temp_final1_ivf;
CREATE TEMPORARY TABLE temp_final1_ivf(
person_id       INT(11),
encounter_id    INT(11),
obs_group_id1   INT(11),
obs_group_id2   INT(11),
obs_group_id3   INT(11),
ivf1            TEXT,
ivf2            TEXT,
ivf3            TEXT
);
INSERT INTO temp_final1_ivf (person_id, encounter_id, obs_group_id1)
(
SELECT person_id, encounter_id, MAX(obs_group_id) FROM temp_stage2_ivf GROUP BY encounter_id
);

UPDATE temp_final1_ivf tf
LEFT JOIN
temp_stage2_ivf ts ON tf.obs_group_id1 = ts.obs_group_id
SET
ivf1 = CONCAT(IF(ivf_value_coded IS NULL,
'',
ivf_value_coded),
' | ',
IF(ivf_value_numeric IS NULL,
'',
ivf_value_numeric));

DROP TEMPORARY TABLE IF EXISTS temp_stage_final1_ivf;
CREATE TEMPORARY TABLE temp_stage_final1_ivf
(
encounter_id          INT(11),
obsgid2               INT(11),
ivf_value_coded2      TEXT,
ivf_value_numeric2    TEXT
);

INSERT INTO temp_stage_final1_ivf(encounter_id, obsgid2)
(SELECT encounter_id, MAX(obs_group_id) obsgid2 FROM temp_stage2_ivf ts WHERE ts.obs_group_id NOT IN (SELECT obs_group_id1 FROM temp_final1_ivf) GROUP BY encounter_id);

UPDATE temp_final1_ivf tf
LEFT JOIN
temp_stage_final1_ivf tsf ON tf.encounter_id = tsf.encounter_id
SET
obs_group_id2 = obsgid2;

UPDATE temp_stage_final1_ivf tf
LEFT JOIN
temp_stage2_ivf tsf ON tf.obsgid2 = tsf.obs_group_id
SET
ivf_value_coded2 = ivf_value_coded;

UPDATE temp_stage_final1_ivf tf
LEFT JOIN
temp_stage2_ivf tsf ON tf.obsgid2 = tsf.obs_group_id
SET
ivf_value_numeric2 = ivf_value_numeric;

UPDATE temp_final1_ivf tf
LEFT JOIN
temp_stage_final1_ivf ts ON tf.obs_group_id2 = ts.obsgid2
SET
ivf2 = CONCAT(IF(ivf_value_coded2 IS NULL,
'',
ivf_value_coded2),
' | ',
IF(ivf_value_numeric2 IS NULL,
'',
ivf_value_numeric2));

DROP TEMPORARY TABLE IF EXISTS temp_stage_final2_ivf;
CREATE TEMPORARY TABLE temp_stage_final2_ivf
(
encounter_id INT(11),
obsgid3 INT(11),
ivf_value_coded3 TEXT,
ivf_value_numeric3 TEXT
);

INSERT INTO temp_stage_final2_ivf(encounter_id, obsgid3)
(SELECT encounter_id, obs_group_id obsgid3 FROM temp_stage2_ivf ts WHERE ts.obs_group_id NOT IN (SELECT obs_group_id1 FROM temp_final1_ivf)
AND obs_group_id NOT IN (SELECT obsgid2 FROM temp_stage_final1_ivf)
GROUP BY encounter_id);

UPDATE temp_final1_ivf tf
LEFT JOIN
temp_stage_final2_ivf tsf ON tf.encounter_id = tsf.encounter_id
SET
obs_group_id3 = obsgid3;

UPDATE temp_stage_final2_ivf tf
LEFT JOIN
temp_stage2_ivf tsf ON tf.obsgid3 = tsf.obs_group_id
SET
ivf_value_coded3 = ivf_value_coded;

UPDATE temp_stage_final2_ivf tf
LEFT JOIN
temp_stage2_ivf tsf ON tf.obsgid3 = tsf.obs_group_id
SET
ivf_value_numeric3 = ivf_value_numeric;

UPDATE temp_final1_ivf tf
LEFT JOIN
temp_stage_final2_ivf ts ON tf.obs_group_id3 = ts.obsgid3
SET
ivf3 = CONCAT(IF(ivf_value_coded3 IS NULL,
'',
ivf_value_coded3),
' | ',
IF(ivf_value_numeric3 IS NULL,
'',
ivf_value_numeric3));

-- COVID 19
UPDATE temp_encounter SET covid19 = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165793', 'en');

-- Diagnosis
UPDATE temp_encounter SET diagnosis_order1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 0), 'CIEL', '159946', 'en');
UPDATE temp_encounter SET diagnosis1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 0), 'CIEL', '1284', 'en');
UPDATE temp_encounter SET diagnosis_certainity1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 0), 'CIEL', '159394', 'en');

UPDATE temp_encounter SET diagnosis_order2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 1), 'CIEL', '159946', 'en');
UPDATE temp_encounter SET diagnosis2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 1), 'CIEL', '1284', 'en');
UPDATE temp_encounter SET diagnosis_certainity2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 1), 'CIEL', '159394', 'en');

UPDATE temp_encounter SET diagnosis_order3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 2), 'CIEL', '159946', 'en');
UPDATE temp_encounter SET diagnosis3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 2), 'CIEL', '1284', 'en');
UPDATE temp_encounter SET diagnosis_certainity3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 2), 'CIEL', '159394', 'en');

UPDATE temp_encounter SET diagnosis_order4 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 3), 'CIEL', '159946', 'en');
UPDATE temp_encounter SET diagnosis4 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 3), 'CIEL', '1284', 'en');
UPDATE temp_encounter SET diagnosis_certainity4 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 3), 'CIEL', '159394', 'en');

UPDATE temp_encounter SET diagnosis_order5 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 4), 'CIEL', '159946', 'en');
UPDATE temp_encounter SET diagnosis5 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 4), 'CIEL', '1284', 'en');
UPDATE temp_encounter SET diagnosis_certainity5 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH', 'Visit Diagnoses', 4), 'CIEL', '159394', 'en');

### Labs
## Sputum collection date1
UPDATE temp_encounter SET specimen_date1 = OBS_FROM_GROUP_ID_VALUE_DATETIME(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '159951');

## specimen types 1
UPDATE temp_encounter SET specimens_type1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '159959', 'en');

## specimen ordered 1
UPDATE temp_encounter SET specimens_ordered1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'PIH', 'Lab test ordered coded', 'en');

## Results 1
UPDATE temp_encounter SET antibody_result1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '165853', 'en');
UPDATE temp_encounter SET antigen_result1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '165852', 'en');
UPDATE temp_encounter SET pcr_result1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '165840', 'en');
UPDATE temp_encounter SET genexpert_result1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '165865', 'en');

## Sputum collection date2
UPDATE temp_encounter SET specimen_date2 = OBS_FROM_GROUP_ID_VALUE_DATETIME(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '159951');

## specimen types 2
UPDATE temp_encounter SET specimens_type2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '159959', 'en');

## specimen ordered 2
UPDATE temp_encounter SET specimens_ordered2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'PIH', 'Lab test ordered coded', 'en');

## Results 2
UPDATE temp_encounter SET antibody_result2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '165853', 'en');
UPDATE temp_encounter SET antigen_result2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '165852', 'en');
UPDATE temp_encounter SET pcr_result2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '165840', 'en');
UPDATE temp_encounter SET genexpert_result2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '165865', 'en');

## Sputum collection date3
UPDATE temp_encounter SET specimen_date3 = OBS_FROM_GROUP_ID_VALUE_DATETIME(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '159951');

## specimen types 3
UPDATE temp_encounter SET specimens_type3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH','12973',2), 'CIEL', '159959', 'en');

## specimen ordered 3
UPDATE temp_encounter SET specimens_ordered3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'PIH', 'Lab test ordered coded', 'en');

## Results 3
UPDATE temp_encounter SET antibody_result3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '165853', 'en');
UPDATE temp_encounter SET antigen_result3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '165852', 'en');
UPDATE temp_encounter SET pcr_result3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '165840', 'en');
UPDATE temp_encounter SET genexpert_result3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '165865', 'en');

##### Lab Results
UPDATE temp_encounter SET hemoglobin = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '21');

UPDATE temp_encounter SET hematocrit = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1015');

UPDATE temp_encounter SET wbc = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '678');

UPDATE temp_encounter SET platelets = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '729');

UPDATE temp_encounter SET lymphocyte = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '952');

UPDATE temp_encounter SET neutrophil = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1330');

UPDATE temp_encounter SET crp = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '161500');

UPDATE temp_encounter SET sodium = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1132');

UPDATE temp_encounter SET potassium = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1133');

UPDATE temp_encounter SET urea = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '857');

UPDATE temp_encounter SET creatinine = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '790');

UPDATE temp_encounter SET glucose = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '887');

UPDATE temp_encounter SET bilirubin = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '655');

UPDATE temp_encounter SET sgpt = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '654');

UPDATE temp_encounter SET sgot = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '653');

UPDATE temp_encounter SET pH = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165984');

UPDATE temp_encounter SET pcO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163595');

UPDATE temp_encounter SET pO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163598');

UPDATE temp_encounter SET tcO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '166002');

UPDATE temp_encounter SET hcO3 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163596');

UPDATE temp_encounter SET be = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163599');

UPDATE temp_encounter SET sO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163597');

UPDATE temp_encounter SET lactate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165997');

#######Radiology
UPDATE temp_encounter SET radiology_order1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , 'Radiology report construct', 0), 'PIH', 'Radiology procedure performed', 'en');
UPDATE temp_encounter SET radiology_findings1 = OBS_FROM_GROUP_ID_VALUE_TEXT(OBS_ID(encounter_id, 'PIH', 'Radiology report construct',0), 'PIH', 'Radiology report comments');

UPDATE temp_encounter SET radiology_order2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , 'Radiology report construct', 1), 'PIH', 'Radiology procedure performed', 'en');
UPDATE temp_encounter SET radiology_findings2 = OBS_FROM_GROUP_ID_VALUE_TEXT(OBS_ID(encounter_id, 'PIH', 'Radiology report construct',1), 'PIH', 'Radiology report comments');

UPDATE temp_encounter SET radiology_order3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , 'Radiology report construct', 2), 'PIH', 'Radiology procedure performed', 'en');
UPDATE temp_encounter SET radiology_findings3 = OBS_FROM_GROUP_ID_VALUE_TEXT(OBS_ID(encounter_id, 'PIH', 'Radiology report construct',2), 'PIH', 'Radiology report comments');

UPDATE temp_encounter SET radiology_order4 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , 'Radiology report construct', 3), 'PIH', 'Radiology procedure performed', 'en');
UPDATE temp_encounter SET radiology_findings4 = OBS_FROM_GROUP_ID_VALUE_TEXT(OBS_ID(encounter_id, 'PIH', 'Radiology report construct',3), 'PIH', 'Radiology report comments');

-- Disposition
UPDATE temp_encounter SET disposition = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', 'Hum Disposition categories', 'en');

-- Admission ward
UPDATE temp_encounter SET admission_ward = (SELECT name FROM location WHERE location_id = OBS_VALUE_TEXT(encounter_id, 'PIH', 'Admission location in hospital'));

-- Transfer out location
UPDATE temp_encounter SET transfer_out_location = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', 'Transfer out location', 'en');

-- clinical management plan
UPDATE temp_encounter te SET clinical_management_plan = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162749');

-- nursing note
UPDATE temp_encounter SET nursing_note = OBS_VALUE_TEXT(encounter_id, 'CIEL', '166021');

-- mh referral
UPDATE temp_encounter SET mh_referral = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1272', 'PIH', '5489');

-- mh note
UPDATE temp_encounter SET mh_note =  OBS_FROM_GROUP_ID_VALUE_TEXT(OBS_ID(encounter_id,'PIH','12837',0), 'CIEL', '161011');

### COVID 19 Progress FORM
-- overall_condition
UPDATE temp_encounter SET overall_condition = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '159640', 'en');

-- Symptoms Progression and Names
UPDATE temp_encounter te SET symptom_names1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'CIEL' , '1727', 0), 'CIEL', '1728', 'en');

### COVID 19 DISCHARGE
## Therapy

-- oxygen therapy
UPDATE temp_encounter SET oxygen_therapy = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165864', 'en');

-- non-invasive ventilation (BiPAP, CPAP)
UPDATE temp_encounter SET non_inv_ventilation = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165945', 'en');

-- vasopressors
UPDATE temp_encounter SET vasopressors = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165926', 'en');

-- antibiotics
UPDATE temp_encounter SET antibiotics = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165991', 'en');

-- other interventions
UPDATE temp_encounter SET other_intervention = OBS_VALUE_TEXT(encounter_id, 'CIEL', '165264');

## ICU
UPDATE temp_encounter SET icu = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165644', 'CIEL', '1065');

-- Days in ICU
UPDATE temp_encounter SET days_in_icu = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163204');

-- ICU Admission date
UPDATE temp_encounter SET icu_admission_date = OBS_VALUE_DATETIME(encounter_id, 'CIEL', '165992');

-- ICU Discharge date
UPDATE temp_encounter SET icu_discharge_date = OBS_VALUE_DATETIME(encounter_id, 'CIEL', '165993');

### Discharge Medication
-- UPDATE temp_encounter SET medications = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '1282', 'en');

-- other antibiotic
UPDATE temp_encounter te SET  other_antibiotics = OBS_COMMENTS(encounter_id, 'PIH', '1282', 'PIH', '12974');

-- Discharge other meds
-- UPDATE temp_encounter SET other_medications = OBS_VALUE_TEXT(encounter_id, 'PIH', 'Medication comments (text)');

-- Discharge conditions
UPDATE temp_encounter SET discharge_condition = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '159640', 'en');

-- followup plan
-- UPDATE temp_encounter SET followup_plan = OBS_FROM_GROUP_ID_VALUE_TEXT(OBS_ID(encounter_id,'CIEL', '162749',0), 'CIEL', '162749');
-- UPDATE temp_encounter SET followup_plan = OBS_FROM_GROUP_ID_VALUE_TEXT(OBS_ID(encounter_id,'CIEL', '162749',0), 'CIEL', '162749');

-- Discharge comments
UPDATE temp_encounter te SET discharge_comments = OBS_VALUE_TEXT(encounter_id, 'CIEL', '161011') WHERE te.encounter_type = 'COVID-19 Discharge';
                                                                                                         
-- return visit date
UPDATE temp_encounter te SET return_visit_date = obs_value_datetime(encounter_id, 'CIEL','5096');
                                                                                                         
####### EXECUTE SELECT TO EXPORT TABLE CONTENTS
SELECT
e.encounter_id,
e.patient_id,
e.dossier_num AS dossierId,
e.zlemr_id AS zlemr,
e.gender,
e.birthdate,
e.address,
e.phone_number,
e.encounter_type,
e.encounter_location,
e.encounter_datetime,
e.encounter_provider,
e.health_care_worker,
e.hcw_type,
e.pregnant,
e.last_menstruation_date,
e.estimated_delivery_date,
e.postpartum_state,
e.outcome,
e.gestational_outcome,
e.breast_feed,
e.vaccination_up_todate,
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
e.SpO2,
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
e.o2therapy_value,
e.analgesic_specified,
tf.ivf1,
tf.ivf2,
tf.ivf3,
e.covid19 "COVID-19_Diagnosis",
e.diagnosis_order1,
e.diagnosis1,
e.diagnosis_certainity1,
e.diagnosis_order2,
e.diagnosis2,
e.diagnosis_certainity2,
e.diagnosis_order3,
e.diagnosis3,
e.diagnosis_certainity3,
e.diagnosis_order4,
e.diagnosis4,
e.diagnosis_certainity4,
e.diagnosis_order5,
e.diagnosis5,
e.diagnosis_certainity5,
e.specimen_date1,
e.specimens_type1,
e.specimens_ordered1,
e.antibody_result1,
e.antigen_result1,
e.pcr_result1,
e.genexpert_result1,
e.specimen_date2,
e.specimens_type2,
e.specimens_ordered2,
e.antibody_result2,
e.antigen_result2,
e.pcr_result2,
e.genexpert_result2,
e.specimen_date3,
e.specimens_type3,
e.specimens_ordered3,
e.antibody_result3,
e.antigen_result3,
e.pcr_result3,
e.genexpert_result3,
e.hemoglobin,
e.hematocrit,
e.wbc,
e.platelets,
e.lymphocyte,
e.neutrophil,
e.crp,
e.sodium,
e.potassium,
e.urea,
e.creatinine,
e.glucose,
e.bilirubin,
e.sgpt,
e.sgot,
e.pH,
e.pcO2,
e.pO2,
e.tcO2,
e.hcO3,
e.be,
e.sO2,
e.lactate,
e.radiology_order1,
e.radiology_findings1,
e.radiology_order2,
e.radiology_findings2,
e.radiology_order3,
e.radiology_findings3,
e.radiology_order4,
e.radiology_findings4,
#### PROGRESS FORM
e.overall_condition,
e.symptom_names1,
e.disposition,
e.admission_ward,
e.clinical_management_plan,
e.nursing_note,
e.mh_referral,
e.mh_note,
e.transfer_out_location,
### Discharge
e.oxygen_therapy,
e.non_inv_ventilation,
e.vasopressors,
e.antibiotics,
e.other_intervention,
e.icu,
e.days_in_icu,
e.icu_admission_date,
e.icu_discharge_date,
-- e.medications,
e.other_antibiotics,
-- e.other_medications,
e.discharge_condition,
-- e.followup_plan,
e.discharge_comments,
e.return_visit_date
FROM
temp_encounter e
LEFT JOIN
temp_final1_ivf tf ON e.encounter_id = tf.encounter_id;
