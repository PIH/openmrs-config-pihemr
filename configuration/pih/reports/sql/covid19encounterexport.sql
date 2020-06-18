## THIS IS A ROW-PER-ENCOUNTER EXPORT
## THIS WILL RETURN A ROW FOR EACH COVID19 ENCOUNTER - ADMISSION, DAILY PROGRESS, AND DISCHARGE
## THE COLLECTED OBSERVATIONS ARE AVAILABLE AS COLUMNS
## FOR EFFICIENCY, THIS USES TEMPORARY TABLES TO LOAD DATA IN FROM OBS GROUPS AS APPROPRIATE

## THIS EXPECTS A startDate AND endDate PARAMETER IN ORDER TO RESTRICT BY ENCOUNTERS WITHIN A GIVEN DATE RANGE
## THE EVALUATOR WILL INSERT THESE AS BELOW WHEN EXECUTING.  YOU CAN UNCOMMENT THE BELOW LINES FOR MANUAL TESTING:

#SET @startDate= '2020-04-01';
#SET @endDate= '2020-06-17';

## sql updates
SET sql_safe_updates = 0;
SET @covid_admission_encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE name = 'COVID-19 Admission');

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
    smoker                  VARCHAR(11),
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
    supportive_care         VARCHAR(255),
	  o2therapy               DOUBLE,
    analgesic_specified     VARCHAR(255),
    convid19                VARCHAR(255),
    diagnosis               TEXT,
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
    chest_xray              VARCHAR(11),
    chest_xray_findings     TEXT,
    cardioUS                VARCHAR(11),
    cardioUS_findings       TEXT,
    abUS                    VARCHAR(11),
    abUS_findings           TEXT,
    radiology_other         VARCHAR(255),
    radiology_other_comments TEXT,
    disposition             VARCHAR(255),
    admission_ward          VARCHAR(255),
    clinical_management_plan TEXT,
    nursing_note            TEXT,
    mh_referral             VARCHAR(11),
    mh_note                 TEXT,
    transfer_out_location   VARCHAR(255),
    new_signs_symptoms      TEXT,
    improved_symptoms       TEXT,
    no_change               TEXT,
    worse_symptoms          TEXT,
    oxygen_therapy          VARCHAR(11),
    non_inv_ventilation     VARCHAR(11),
    vasopressors            VARCHAR(11),
    antibiotics             VARCHAR(11),
    other_intervention      VARCHAR(11),
    icu                     VARCHAR(11),
    days_in_icu             INT(11),
    icu_admission_date      DATETIME,
    icu_discharge_date      DATETIME,
    discharge_meds          TEXT,
    other_antibiotics       TEXT,
    other_discharge_meds    TEXT,
    discharge_condition     VARCHAR(255),
    followup_plan           TEXT,
    discharge_comments      TEXT
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

UPDATE temp_encounter 
SET 
    dossier_num = DOSID(patient_id);
UPDATE temp_encounter 
SET 
    zlemr_id = ZLEMR(patient_id);
UPDATE temp_encounter 
SET 
    address = PERSON_ADDRESS(patient_id);
UPDATE temp_encounter 
SET 
    phone_number = PERSON_ATTRIBUTE_VALUE(patient_id, 'Telephone Number');

UPDATE temp_encounter 
SET 
    encounter_provider = PROVIDER(encounter_id);
UPDATE temp_encounter 
SET 
    encounter_location = ENCOUNTER_LOCATION_NAME(encounter_id);

UPDATE temp_encounter 
SET 
    health_care_worker = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '5619', 'fr');

UPDATE temp_encounter 
SET 
    pregnant = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '5272', 'fr');

-- last menstruation date
UPDATE temp_encounter te
        LEFT JOIN
    obs o ON o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '1427')
        AND o.person_id = te.patient_id
        AND o.encounter_id = te.encounter_id
        AND o.voided = 0 
SET 
    te.last_menstruation_date = o.value_datetime;

-- estimated delivery date
UPDATE temp_encounter te
        LEFT JOIN
    obs o ON o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '5596')
        AND o.person_id = te.patient_id
        AND o.encounter_id = te.encounter_id
        AND o.voided = 0 
SET 
    te.estimated_delivery_date = o.value_datetime;

-- postpartum state
UPDATE temp_encounter 
SET 
    postpartum_state = OBS_SINGLE_VALUE_CODED(encounter_id,
            'CIEL',
            '162747',
            'CIEL',
            '129317');

-- outcome
UPDATE temp_encounter 
SET 
    outcome = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '161033', 'fr');

-- date of delivery
UPDATE temp_encounter te
        LEFT JOIN
    obs o ON o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '5599')
        AND o.person_id = te.patient_id
        AND o.encounter_id = te.encounter_id
        AND o.voided = 0 
SET 
    te.date_of_delivery = o.value_datetime;

-- Infant
UPDATE temp_encounter SET gestational_outcome = OBS_VALUE_CODED_LIST(
	encounter_id,
    'CIEL',
    '161033',
    'fr'
);
UPDATE temp_encounter SET breast_feed = OBS_VALUE_CODED_LIST(
	encounter_id,
    'CIEL',
    '5632',
    'fr'
);
UPDATE temp_encounter SET vaccination_up_todate = OBS_VALUE_CODED_LIST(
	encounter_id,
    'CIEL',
    '5585',
    'fr'
);

-- home medication
UPDATE temp_encounter 
SET 
    home_medications = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162165');

UPDATE temp_encounter 
SET 
    allergies = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162141');

UPDATE temp_encounter te
        LEFT JOIN
    obs o ON o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '1730')
        AND o.person_id = te.patient_id
        AND o.encounter_id = te.encounter_id
        AND o.voided = 0 
SET 
    te.symptom_start_date = o.value_datetime;

-- symptoms
UPDATE temp_encounter 
SET 
    symptoms = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1727', 'fr');

-- other symptoms
UPDATE temp_encounter 
SET 
    other_symptoms = OBS_VALUE_TEXT(encounter_id, 'CIEL', '165996');

UPDATE temp_encounter 
SET 
    comorbidities = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '12976', 'fr');

-- comorbidities
UPDATE temp_encounter 
SET 
    available_comorbidities = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162747', 'fr');

-- other comorbidities
UPDATE temp_encounter te
        LEFT JOIN
    obs o ON o.person_id = te.patient_id
        AND o.encounter_id = te.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '162747')
        AND o.value_coded = CONCEPT_FROM_MAPPING('CIEL', '5622') 
SET 
    other_comorbidities = o.comments;

-- mh
UPDATE temp_encounter 
SET 
    mental_health = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163044');

-- smoker
UPDATE temp_encounter 
SET 
    smoker = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163731', 'fr');

-- transfer
UPDATE temp_encounter 
SET 
    transfer = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '160563', 'fr');

UPDATE temp_encounter 
SET 
    transfer_facility = OBS_VALUE_TEXT(encounter_id, 'CIEL', '161550');

-- covid case contact
UPDATE temp_encounter 
SET 
    covid_case_contact = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162633', 'fr');

-- case condition
UPDATE temp_encounter 
SET 
    case_condition = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '159640', 'fr');

-- vitals
UPDATE temp_encounter 
SET 
    temp = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5088');

UPDATE temp_encounter 
SET 
    heart_rate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5087');

UPDATE temp_encounter 
SET 
    respiratory_rate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5242');

UPDATE temp_encounter 
SET 
    bp_systolic = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5085');

UPDATE temp_encounter 
SET 
    bp_diastolic = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5086');

UPDATE temp_encounter 
SET 
    SpO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5092');

-- room air
UPDATE temp_encounter 
SET 
    room_air = OBS_SINGLE_VALUE_CODED(encounter_id,
            'CIEL',
            '162739',
            'CIEL',
            '162735');

-- Cap refill and Cap refill time
UPDATE temp_encounter 
SET 
    cap_refill = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165890', 'en');

UPDATE temp_encounter 
SET 
    cap_refill_time = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '162513');

-- Pain
UPDATE temp_encounter 
SET 
    pain = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '166000', 'fr');

########## Phyical Exams
UPDATE temp_encounter 
SET 
    general_exam = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1119', 'fr');
UPDATE temp_encounter 
SET 
    general_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163042');

-- HEENT
UPDATE temp_encounter 
SET 
    heent = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1122', 'fr');

UPDATE temp_encounter
SET 
    heent_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163045');

-- Neck
UPDATE temp_encounter 
SET 
    neck = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163388', 'fr');

UPDATE temp_encounter
SET 
    neck_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '165983');

-- chest
UPDATE temp_encounter 
SET 
    chest = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1123', 'fr');

UPDATE temp_encounter
SET 
    chest_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160689');

-- cardiac
UPDATE temp_encounter 
SET 
    cardiac = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1124', 'fr');

UPDATE temp_encounter
SET 
    cardiac_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163046');

-- abdominal
UPDATE temp_encounter 
SET 
    abdominal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1125', 'fr');

UPDATE temp_encounter
SET 
    abdominal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160947');

-- urogenital
UPDATE temp_encounter 
SET 
    urogenital = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1126', 'fr');

UPDATE temp_encounter
SET 
    urogenital_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163047');

-- rectal
UPDATE temp_encounter 
SET 
    rectal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163746', 'fr');
UPDATE temp_encounter 
SET 
    rectal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160961');

-- musculoskeletal
UPDATE temp_encounter 
SET 
    musculoskeletal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1128', 'fr');

UPDATE temp_encounter
SET 
    musculoskeletal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163048');

-- lymph
UPDATE temp_encounter 
SET 
    lymph = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1121', 'fr');

UPDATE temp_encounter
SET 
    lymph_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '166005');

-- skin
UPDATE temp_encounter 
SET 
    skin = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1120', 'fr');

UPDATE temp_encounter
SET 
    skin_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160981');

-- neuro
UPDATE temp_encounter 
SET 
    neuro = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1129', 'fr');

UPDATE temp_encounter
SET 
    neuro_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163109');

-- avpu
UPDATE temp_encounter 
SET 
    avpu = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162643', 'fr');

-- other
UPDATE temp_encounter 
SET 
    other_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163042');

UPDATE temp_encounter 
SET 
    medications = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '1282', 'fr');

UPDATE temp_encounter
SET 
    medication_comments = OBS_VALUE_TEXT(encounter_id,
            'PIH',
            'Medication comments (text)');

-- supportive care
UPDATE temp_encounter 
SET 
    supportive_care = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165995', 'fr');

-- o2therapy value
UPDATE temp_encounter 
SET 
    o2therapy = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165986');

-- analgesic comments/description
UPDATE temp_encounter 
SET 
    analgesic_specified = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163206');

##### IVF
-- IV fluid details
DROP TABLE IF EXISTS temp_stage1_ivf;
CREATE TABLE temp_stage1_ivf (SELECT person_id,
    encounter_id,
    obs_id,
    concept_id,
    obs_group_id,
    CONCEPT_NAME(value_coded, 'fr') ivf_values,
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
SELECT person_id, encounter_id, obs_group_id, GROUP_CONCAT(ivf_values SEPARATOR " | ") ivf_value_coded FROM temp_stage_ivf
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

UPDATE temp_encounter 
SET 
    convid19 = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165793', 'fr');

-- diagnosis to be changed (using obs_gid_function)
UPDATE temp_encounter 
SET 
    diagnosis = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1284', 'fr');

### Labs (to be added using obs_gid_function)

##### Lab Results
UPDATE temp_encounter
SET 
    hemoglobin = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '21');

UPDATE temp_encounter
SET 
    hematocrit = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1015');

UPDATE temp_encounter
SET 
    wbc = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '678');

UPDATE temp_encounter
SET 
    platelets = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '729');

UPDATE temp_encounter
SET 
    lymphocyte = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '952');

UPDATE temp_encounter
SET 
    neutrophil = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1330');

UPDATE temp_encounter
SET 
    crp = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '161500');

UPDATE temp_encounter
SET 
    sodium = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1132');

UPDATE temp_encounter
SET 
    potassium = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1133');

UPDATE temp_encounter
SET 
    urea = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '857');

UPDATE temp_encounter
SET 
    creatinine = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '790');

UPDATE temp_encounter
SET 
    glucose = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '887');

UPDATE temp_encounter
SET 
    bilirubin = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '655');

UPDATE temp_encounter
SET 
    sgpt = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '654');

UPDATE temp_encounter
SET 
    sgot = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '653');

UPDATE temp_encounter
SET 
    pH = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165984');

UPDATE temp_encounter
SET 
    pcO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163595');


UPDATE temp_encounter
SET 
    pO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163598');

UPDATE temp_encounter
SET 
    tcO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '166002');

UPDATE temp_encounter
SET 
    hcO3 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163596');

UPDATE temp_encounter
SET 
    be = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163599');

UPDATE temp_encounter
SET 
    sO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163597');
UPDATE temp_encounter 
SET 
    lactate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165997');

#######Radiology
UPDATE temp_encounter 
SET 
    chest_xray = OBS_SINGLE_VALUE_CODED(encounter_id,
            'PIH',
            'Radiology procedure performed',
            'CIEL',
            '165152');

UPDATE temp_encounter e
        LEFT JOIN
    (SELECT 
        encounter_id, person_id, obs_group_id, value_text
    FROM
        obs
    WHERE
        obs_group_id IN (SELECT 
                obs_group_id
            FROM
                obs o
            WHERE
                voided = 0
                    AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology procedure performed')
                    AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '165152')
                    AND encounter_id IN (SELECT 
                        encounter_id
                    FROM
                        encounter
                    WHERE
                        encounter_type = @covid_admission_encounter_type))
            AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology report comments')
            AND voided = 0) o1 ON e.patient_id = o1.person_id
        AND e.encounter_id = o1.encounter_id 
SET 
    chest_xray_findings = o1.value_text;

UPDATE temp_encounter 
SET 
    cardioUS = OBS_SINGLE_VALUE_CODED(encounter_id,
            'PIH',
            'Radiology procedure performed',
            'CIEL',
            '163041');

UPDATE temp_encounter e
        LEFT JOIN
    (SELECT 
        encounter_id, person_id, obs_group_id, value_text
    FROM
        obs
    WHERE
        obs_group_id IN (SELECT 
                obs_group_id
            FROM
                obs o
            WHERE
                voided = 0
                    AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology procedure performed')
                    AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '163041')
                    AND encounter_id IN (SELECT 
                        encounter_id
                    FROM
                        encounter
                    WHERE
                        encounter_type = @covid_admission_encounter_type))
            AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology report comments')
            AND voided = 0) o1 ON e.patient_id = o1.person_id
        AND e.encounter_id = o1.encounter_id 
SET 
    cardioUS_findings = o1.value_text;

UPDATE temp_encounter 
SET 
    abUS = OBS_SINGLE_VALUE_CODED(encounter_id,
            'PIH',
            'Radiology procedure performed',
            'CIEL',
            '845');
UPDATE temp_encounter e
        LEFT JOIN
    (SELECT 
        encounter_id, person_id, obs_group_id, value_text
    FROM
        obs
    WHERE
        obs_group_id IN (SELECT 
                obs_group_id
            FROM
                obs o
            WHERE
                voided = 0
                    AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology procedure performed')
                    AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '845')
                    AND encounter_id IN (SELECT 
                        encounter_id
                    FROM
                        encounter
                    WHERE
                        encounter_type = @covid_admission_encounter_type))
            AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology report comments')
            AND voided = 0) o1 ON e.patient_id = o1.person_id
        AND e.encounter_id = o1.encounter_id 
SET 
    abUS_findings = o1.value_text;

-- Other finding
UPDATE temp_encounter e
        LEFT JOIN
    (SELECT 
        encounter_id, person_id, obs_group_id, value_coded
    FROM
        obs
    WHERE
        obs_group_id IN (SELECT 
                obs_group_id
            FROM
                obs o
            WHERE
                voided = 0
                    AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology procedure performed')
                    AND value_coded NOT IN (CONCEPT_FROM_MAPPING('CIEL', '165152') , CONCEPT_FROM_MAPPING('CIEL', '163041'), CONCEPT_FROM_MAPPING('CIEL', '845'))
                    AND encounter_id IN (SELECT 
                        encounter_id
                    FROM
                        encounter
                    WHERE
                        encounter_type = @covid_admission_encounter_type))
            AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology procedure performed')
            AND voided = 0) o1 ON e.patient_id = o1.person_id
        AND e.encounter_id = o1.encounter_id 
SET 
    radiology_other = CONCEPT_NAME(o1.value_coded, 'fr');

UPDATE temp_encounter e
        LEFT JOIN
    (SELECT 
        encounter_id, person_id, obs_group_id, value_text
    FROM
        obs
    WHERE
        obs_group_id IN (SELECT 
                obs_group_id
            FROM
                obs o
            WHERE
                voided = 0
                    AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology procedure performed')
                    AND value_coded NOT IN (CONCEPT_FROM_MAPPING('CIEL', '165152') , CONCEPT_FROM_MAPPING('CIEL', '163041'), CONCEPT_FROM_MAPPING('CIEL', '845'))
                    AND encounter_id IN (SELECT 
                        encounter_id
                    FROM
                        encounter
                    WHERE
                        encounter_type = @covid_admission_encounter_type))
            AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Radiology report comments')
            AND voided = 0) o1 ON e.patient_id = o1.person_id
        AND e.encounter_id = o1.encounter_id 
SET 
    radiology_other_comments = o1.value_text;

UPDATE temp_encounter 
SET 
    disposition = OBS_VALUE_CODED_LIST(encounter_id,
            'PIH',
            'Hum Disposition categories',
            'fr');
UPDATE temp_encounter 
SET 
    admission_ward = (SELECT 
            name
        FROM
            location
        WHERE
            location_id = OBS_VALUE_TEXT(encounter_id,
                    'PIH',
                    'Admission location in hospital'));

UPDATE temp_encounter
SET 
    transfer_out_location = OBS_VALUE_CODED_LIST(encounter_id,
            'PIH',
            'Transfer out location',
            'en');

UPDATE temp_encounter
SET 
    clinical_management_plan = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162749');

UPDATE temp_encounter
SET 
    nursing_note = OBS_VALUE_TEXT(encounter_id, 'CIEL', '166021');

UPDATE temp_encounter
SET 
    mh_referral = OBS_SINGLE_VALUE_CODED(encounter_id,
            'CIEL',
            '1272',
            'PIH',
            '5489');

UPDATE temp_encounter 
SET 
    mh_note = OBS_VALUE_TEXT(encounter_id, 'CIEL', '161011');

### COVID 19 Progress FORM
-- new symptom
UPDATE temp_encounter te LEFT JOIN 
(SELECT encounter_id, GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en') SEPARATOR " | ") new_symptom_names FROM obs WHERE obs_group_id IN
(SELECT obs_group_id FROM obs WHERE concept_id = CONCEPT_FROM_MAPPING('CIEL','162676') AND value_coded = CONCEPT_FROM_MAPPING('PIH', '6964') AND voided = 0)
AND concept_id = CONCEPT_FROM_MAPPING('CIEL','1728') AND voided = 0) o ON te.encounter_id = o.encounter_id
SET new_signs_symptoms = o.new_symptom_names;

-- improved symptoms
UPDATE temp_encounter te LEFT JOIN 
(SELECT encounter_id, GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en') SEPARATOR " | ") improved_symptom_names FROM obs WHERE obs_group_id IN
(SELECT obs_group_id FROM obs WHERE concept_id = CONCEPT_FROM_MAPPING('CIEL','162676') AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '162677') AND voided = 0)
AND concept_id = CONCEPT_FROM_MAPPING('CIEL','1728') AND voided = 0) o ON te.encounter_id = o.encounter_id
SET improved_symptoms = o.improved_symptom_names;

-- no change
UPDATE temp_encounter te LEFT JOIN 
(SELECT encounter_id, GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en') SEPARATOR " | ") no_change_symptom_names FROM obs WHERE obs_group_id IN
(SELECT obs_group_id FROM obs WHERE concept_id = CONCEPT_FROM_MAPPING('CIEL','162676') AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '162679') AND voided = 0)
AND concept_id = CONCEPT_FROM_MAPPING('CIEL','1728') AND voided = 0) o ON te.encounter_id = o.encounter_id
SET no_change = o.no_change_symptom_names;

-- worse symptoms
UPDATE temp_encounter te LEFT JOIN 
(SELECT encounter_id, GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en') SEPARATOR " | ") worsen_symptom_names FROM obs WHERE obs_group_id IN
(SELECT obs_group_id FROM obs WHERE concept_id = CONCEPT_FROM_MAPPING('CIEL','162676') AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '162678') AND voided = 0)
AND concept_id = CONCEPT_FROM_MAPPING('CIEL','1728') AND voided = 0) o ON te.encounter_id = o.encounter_id
SET worse_symptoms = o.worsen_symptom_names;

### COVID 19 DISCHARGE
## Therapy

-- oxygen therapy
UPDATE temp_encounter SET oxygen_therapy = OBS_VALUE_CODED_LIST(
	encounter_id,
    'CIEL',
    '165864',
    'fr'
);

-- non-invasive ventilation (BiPAP, CPAP)
UPDATE temp_encounter SET non_inv_ventilation = OBS_VALUE_CODED_LIST(
	encounter_id,
    'CIEL',
    '165945',
    'fr'
);

-- vasopressors
UPDATE temp_encounter SET vasopressors = OBS_VALUE_CODED_LIST(
	encounter_id,
    'CIEL',
    '165926',
    'fr'
);

-- antibiotics
UPDATE temp_encounter SET antibiotics = OBS_VALUE_CODED_LIST(
	encounter_id,
    'CIEL',
    '165991',
    'fr'
);

-- other interventions
UPDATE temp_encounter SET other_intervention = OBS_VALUE_TEXT(
	encounter_id,
    'CIEL',
    '165264'
);

## ICU
UPDATE temp_encounter SET icu = OBS_SINGLE_VALUE_CODED(
	encounter_id,
    'CIEL',
    '165644',
    'CIEL',
    '1065'
); 

-- Days in ICU
UPDATE temp_encounter SET days_in_icu = OBS_VALUE_NUMERIC(
	encounter_id,
    'CIEL',
    '163204'
);

-- ICU Admission date
UPDATE temp_encounter SET icu_admission_date = OBS_VALUE_DATETIME(
	encounter_id, 
    'CIEL', 
    '165992'
);

-- ICU Discharge date
UPDATE temp_encounter SET icu_discharge_date = OBS_VALUE_DATETIME(
	encounter_id, 
    'CIEL', 
    '165993'
);

### Medication
UPDATE temp_encounter SET discharge_meds = OBS_VALUE_CODED_LIST(
	encounter_id,
    'PIH',
    '1282',
    'fr'
);

-- other antibiotic
UPDATE temp_encounter te LEFT JOIN obs o ON
te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', '1282') AND value_coded = CONCEPT_FROM_MAPPING('PIH','12974')
SET other_antibiotics = o.comments;

-- other meds
UPDATE temp_encounter SET other_discharge_meds = OBS_VALUE_TEXT(
	encounter_id,
    'PIH',
    'Medication comments (text)'
);

-- Discharge conditions
UPDATE temp_encounter SET discharge_condition = OBS_VALUE_CODED_LIST(
	encounter_id,
    'CIEL',
    '159640',
    'fr'
);
-- followup plan
UPDATE temp_encounter SET followup_plan = OBS_VALUE_TEXT(
	encounter_id,
    'CIEL',
    '162749'
);

-- Discharge comments
UPDATE temp_encounter SET discharge_comments = OBS_VALUE_TEXT(
	encounter_id,
    'CIEL',
    '161011'
);

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
    e.o2therapy,
    e.analgesic_specified,
    tf.ivf1,
    tf.ivf2,
    tf.ivf3,
    e.convid19,
    e.diagnosis,
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
    e.chest_xray,
    e.chest_xray_findings,
    e.cardioUS,
    e.cardioUS_findings,
    e.abUS,
    e.abUS_findings,
    e.radiology_other,
    e.radiology_other_comments,
    #### PROGRESS FORM
    e.new_signs_symptoms,
    e.improved_symptoms,
    e.no_change,
    e.worse_symptoms,
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
    e.discharge_meds,
    e.other_antibiotics,
    e.other_discharge_meds,
    e.discharge_condition,
    e.followup_plan,
    e.discharge_comments,
    e.disposition,
    e.admission_ward,
    e.clinical_management_plan,
    e.nursing_note,
    e.mh_referral,
    e.mh_note,
    e.transfer_out_location
FROM
    temp_encounter e
        LEFT JOIN
    temp_final1_ivf tf ON e.encounter_id = tf.encounter_id;