SET sql_safe_updates = 0;

SET @obgyn_encounter = (SELECT encounter_type_id FROM encounter_type WHERE uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d');
SET @visit_diagnosis_concept_id = CONCEPT_FROM_MAPPING('PIH', 'Visit Diagnoses');
SET @diagnosis_order = CONCEPT_FROM_MAPPING('PIH', 'Diagnosis order');
SET @primary_diagnosis = CONCEPT_FROM_MAPPING('PIH', 'primary');
SET @secondary_diagnosis = CONCEPT_FROM_MAPPING('PIH', 'secondary');
SET @diagnosis = CONCEPT_FROM_MAPPING('PIH', 'DIAGNOSIS');

DROP TEMPORARY TABLE IF EXISTS temp_obgyn_visit;
CREATE TEMPORARY TABLE temp_obgyn_visit
(
    patient_id      INT,
    encounter_id    INT,
    emr_id          VARCHAR(25),
    visit_date      DATE,
    visit_site      VARCHAR(100),
    age_at_visit    DOUBLE,
    entry_date      DATETIME,
    entered_by_id   INT,
    entered_by      VARCHAR(100),
    consultation_type  	 VARCHAR (30), 
    consultation_type_fp VARCHAR(30),
    pregnant        BIT,
    breastfeeding   VARCHAR(5),
    pregnant_lmp    DATE,
    pregnant_edd    DATE,
    next_visit_date DATE,
    triage_level    VARCHAR(11),
    referral_type   VARCHAR(255),
    referral_type_other         VARCHAR(255),
    implant_inserted            BIT,
    IUD_inserted                BIT,
    tubal_ligation_completed    BIT,
    abortion_completed          BIT,
    reason_for_visit            VARCHAR(255),
    visit_type                  VARCHAR(255),
    referring_service           VARCHAR(255),
    other_service               VARCHAR(255),
    triage_color                VARCHAR(255),
    bcg_1              DATE,
    polio_0            DATE,
    polio_1            DATE,
    polio_2            DATE,
    polio_3            DATE,
    polio_booster_1    DATE,
    polio_booster_2    DATE,
    pentavalent_1      DATE,
    pentavalent_2      DATE,
    pentavalent_3      DATE,
    rotavirus_1        DATE,
    rotavirus_2        DATE,
    mmr_1              DATE,
    tetanus_0          DATE,
    tetanus_1          DATE,
    tetanus_2          DATE,
    tetanus_3          DATE,
    tetanus_booster_1  DATE,
    tetanus_booster_2  DATE,
    gyno_exam          BIT,
    wh_exam            BIT,
    previous_history   TEXT,
    cervical_cancer_screening_date DATE,
    cervical_cancer_screening_result BIT,
    risk_factors       TEXT,
    risk_factors_other TEXT,
    examining_doctor   VARCHAR(100),
    hiv_test_admin		BIT,
	medication_order TEXT,
    primary_diagnosis TEXT,
    secondary_diagnosis TEXT,
    diagnosis_non_coded TEXT,
    procedures TEXT,
    procedures_other TEXT,
    family_planning_use VARCHAR(5), 
    family_planning_method VARCHAR(255), 
    fp_counseling_received VARCHAR(255),
    index_asc          INT,
    index_desc         INT
);

CREATE INDEX temp_obgyn_visit_patient_id ON temp_obgyn_visit (patient_id);
CREATE INDEX temp_obgyn_visit_encounter_id ON temp_obgyn_visit (encounter_id);

INSERT INTO temp_obgyn_visit(patient_id, encounter_id, visit_date, visit_site, entry_date, entered_by_id)
SELECT patient_id, encounter_id, DATE(encounter_datetime), LOCATION_NAME(location_id), date_created, creator FROM encounter WHERE voided = 0 AND encounter_type = @obgyn_encounter;

UPDATE temp_obgyn_visit t 
SET 
    examining_doctor = PROVIDER(t.encounter_id);

UPDATE temp_obgyn_visit t
        JOIN
    users u ON u.retired = 0
        AND u.user_id = t.entered_by_id
        JOIN
    person_name p ON p.voided = 0
        AND p.person_id = u.person_id 
SET 
    entered_by = CONCAT(p.given_name, ' ', p.family_name);

DELETE FROM temp_obgyn_visit 
WHERE
    patient_id IN (SELECT 
        a.person_id
    FROM
        person_attribute a
            JOIN
        person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
            AND a.value = 'true'
            AND t.name = 'Test Patient');

UPDATE temp_obgyn_visit t 
SET 
    previous_history = (SELECT 
            GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en')
                    SEPARATOR ' | ')
        FROM
            obs o
        WHERE
            o.voided = 0
                AND t.encounter_id = o.encounter_id
                AND o.value_coded <> 1
                AND obs_group_id IN (SELECT 
                    obs_id
                FROM
                    obs
                WHERE
                    concept_id = CONCEPT_FROM_MAPPING('CIEL', '1633')));

UPDATE temp_obgyn_visit t JOIN obs o ON o.encounter_id = t.encounter_id AND o.voided = 0 AND o.concept_id = CONCEPT_FROM_MAPPING('PIH','Type of HUM visit')
SET consultation_type = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_obgyn_visit t JOIN obs o ON o.encounter_id = t.encounter_id AND o.voided = 0 AND o.concept_id = CONCEPT_FROM_MAPPING('PIH','REASON FOR VISIT')
SET consultation_type_fp = CONCEPT_NAME(value_coded, 'en');


# pregnancy
CREATE INDEX temp_obgyn_pregnacy_patient_id ON temp_obgyn_pregnacy (patient_id);
CREATE INDEX temp_obgyn_pregnacy_encounter_id ON temp_obgyn_pregnacy (encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obgyn_pregnacy;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_obgyn_pregnacy
(
encounter_id INT,
patient_id INT,
antenatal_visit VARCHAR(20),
estimated_delivery_date DATE
);

INSERT INTO temp_obgyn_pregnacy(encounter_id, patient_id)
SELECT encounter_id, patient_id FROM temp_obgyn_visit;

UPDATE temp_obgyn_pregnacy te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', '8879')
        AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'ANC VISIT')
        AND o.voided = 0 
SET 
    antenatal_visit = 'Yes';-- yes

UPDATE temp_obgyn_pregnacy te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'ESTIMATED DATE OF CONFINEMENT')
        AND o.voided = 0 
SET 
    estimated_delivery_date = DATE(value_datetime);

UPDATE temp_obgyn_visit tv
        JOIN
    temp_obgyn_pregnacy t ON t.encounter_id = tv.encounter_id 
SET 
    pregnant = IF(antenatal_visit IS NULL, NULL, 1);

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'METHOD OF FAMILY PLANNING')
        AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '136163')
        AND o.voided = 0 
SET 
    breastfeeding = 'Yes';-- yes

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'DATE OF LAST MENSTRUAL PERIOD') 
SET 
    pregnant_lmp = DATE(o.value_datetime);

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'ESTIMATED DATE OF CONFINEMENT') 
SET 
    pregnant_edd = DATE(o.value_datetime);

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'RETURN VISIT DATE') 
SET 
    next_visit_date = DATE(o.value_datetime);

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'Triage color classification') 
SET 
    triage_level = CONCEPT_NAME(o.value_coded, 'en');

UPDATE temp_obgyn_visit te 
SET 
    referral_type = OBS_VALUE_CODED_LIST(te.encounter_id,
            'PIH',
            'Type of referring service',
            'en');
UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'Type of referring service')
        AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'OTHER') 
SET 
    referral_type_other = o.comments;

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'METHOD OF FAMILY PLANNING')
        AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '1873')
        AND o.voided = 0 
SET 
    implant_inserted = 1;-- yes

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'METHOD OF FAMILY PLANNING')
        AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'INTRAUTERINE DEVICE')
        AND o.voided = 0 
SET 
    IUD_inserted = 1;-- yes

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'METHOD OF FAMILY PLANNING')
        AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'TUBAL LIGATION')
        AND o.voided = 0 
SET 
    tubal_ligation_completed = 1; -- yes

#abortion_completed

### vaccinations
# polio
## START BUILDING VACCINATION TABLE
CREATE INDEX temp_vaccinations_person_id ON temp_vaccinations (person_id);
CREATE INDEX temp_vaccinations_encounter_id ON temp_vaccinations (encounter_id);
CREATE INDEX temp_vaccinations_obs_group_id ON temp_vaccinations (obs_group_id);
CREATE INDEX temp_vaccinations_concept_id ON temp_vaccinations (concept_id);
CREATE INDEX temp_vaccinations_dose_number ON temp_vaccinations (dose_number);

DROP TEMPORARY TABLE IF EXISTS temp_vaccinations;
CREATE TEMPORARY TABLE temp_vaccinations
(
    obs_group_id INT PRIMARY KEY,
    person_id INT,
    encounter_id INT,
    concept_id INT,
    vaccine      CHAR(38),
    dose_number  INT,
    vaccine_date DATE
);

INSERT INTO temp_vaccinations (obs_group_id, person_id, encounter_id, concept_id, vaccine)
SELECT o.obs_group_id, o.person_id, o.encounter_id, o.concept_id, a.uuid
FROM obs o,
     concept c,
     concept a
WHERE o.concept_id = c.concept_id
  AND o.value_coded = a.concept_id
  AND c.uuid = '2dc6c690-a5fe-4cc4-97cc-32c70200a2eb' # Vaccinations
  AND o.voided = 0;

INSERT INTO temp_vaccinations (obs_group_id, dose_number)
SELECT o.obs_group_id, o.value_numeric
FROM obs o,
     concept c
WHERE o.concept_id = c.concept_id
  AND c.uuid = 'ef6b45b4-525e-4d74-bf81-a65a41f3feb9' # Vaccination Sequence Number
  AND o.voided = 0
ON DUPLICATE KEY UPDATE dose_number = o.value_numeric;

INSERT INTO temp_vaccinations (obs_group_id, vaccine_date)
SELECT o.obs_group_id, DATE(o.value_datetime)
FROM obs o,
     concept c
WHERE o.concept_id = c.concept_id
  AND c.uuid = '1410AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' # Vaccine Date
  AND o.voided = 0
ON DUPLICATE KEY UPDATE vaccine_date = o.value_datetime;

UPDATE temp_obgyn_visit te
        JOIN
    temp_vaccinations o ON te.encounter_id = o.encounter_id
        AND o.vaccine = '3cd4e004-26fe-102b-80cb-0017a47871b2' 
SET 
    te.bcg_1 = o.vaccine_date;


UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 0 
SET 
    e.polio_0 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 1 
SET 
    e.polio_1 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 2 
SET 
    e.polio_2 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 3 
SET 
    e.polio_3 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 11 
SET 
    e.polio_booster_1 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 12 
SET 
    e.polio_booster_2 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '1423AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        AND v.dose_number = 1 
SET 
    e.pentavalent_1 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '1423AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        AND v.dose_number = 2 
SET 
    e.pentavalent_2 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '1423AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        AND v.dose_number = 3 
SET 
    e.pentavalent_3 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '83531AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        AND v.dose_number = 1 
SET 
    e.rotavirus_1 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '83531AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        AND v.dose_number = 2 
SET 
    e.rotavirus_2 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '162586AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
        AND v.dose_number = 1 
SET 
    e.mmr_1 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 0 
SET 
    e.tetanus_0 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 1 
SET 
    e.tetanus_1 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 2 
SET 
    e.tetanus_2 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 3 
SET 
    e.tetanus_3 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 11 
SET 
    e.tetanus_booster_1 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    temp_vaccinations v ON e.encounter_id = v.encounter_id
        AND v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2'
        AND v.dose_number = 12 
SET 
    e.tetanus_booster_2 = v.vaccine_date;

UPDATE temp_obgyn_visit e
        JOIN
    obs o ON e.encounter_id = o.encounter_id
        AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '13229')
        AND o.voided = 0 
SET 
    gyno_exam = 1;

UPDATE temp_obgyn_visit e
        JOIN
    obs o ON e.encounter_id = o.encounter_id
        AND o.concept_id IN (CONCEPT_FROM_MAPPING('CIEL', '1439') , CONCEPT_FROM_MAPPING('CIEL', '160090'),
        CONCEPT_FROM_MAPPING('CIEL', '163749'),
        CONCEPT_FROM_MAPPING('CIEL', '1440'),
        CONCEPT_FROM_MAPPING('CIEL', '163750'),
        CONCEPT_FROM_MAPPING('CIEL', '160968'))
        AND o.concept_id IS NOT NULL
        AND o.voided = 0 
SET 
    wh_exam = 1;

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '165429') 
SET 
    cervical_cancer_screening_date = DATE(o.value_datetime);

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '163560')
        AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '151185')
        AND o.voided = 0 
SET 
    cervical_cancer_screening_result = 1;

UPDATE temp_obgyn_visit t 
SET 
    risk_factors = (SELECT 
            GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en')
                    SEPARATOR ' | ')
        FROM
            obs o
        WHERE
            o.voided = 0
                AND t.encounter_id = o.encounter_id
                AND o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '160079'));

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '160079')
        AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'OTHER') 
SET 
    risk_factors_other = o.comments;

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('CIEL', '164181') 
SET 
    visit_type = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_obgyn_visit te 
SET 
    age_at_visit = AGE_AT_ENC(te.patient_id, te.encounter_id);

### indexes
-- index ascending
DROP TEMPORARY TABLE IF EXISTS temp_mch_visit_index_asc;
CREATE TEMPORARY TABLE temp_mch_visit_index_asc
(
		SELECT
			patient_id,
			encounter_id,
			visit_date,
			index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            encounter_id,
            patient_id,
            visit_date,
            @u:= patient_id
      FROM temp_obgyn_visit,
            (SELECT @r:= 1) AS r,
            (SELECT @u:= 0) AS u
      ORDER BY patient_id, visit_date ASC, encounter_id ASC
        ) index_ascending );

-- index descending
DROP TEMPORARY TABLE IF EXISTS temp_mch_visit_index_desc;
CREATE TEMPORARY TABLE temp_mch_visit_index_desc
(
	    SELECT
	        patient_id,
	        encounter_id,
	        visit_date,
	        index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            encounter_id,
            patient_id,
            visit_date,
            @u:= patient_id
        FROM temp_obgyn_visit,
                (SELECT @r:= 1) AS r,
                (SELECT @u:= 0) AS u
        ORDER BY patient_id, visit_date DESC, encounter_id DESC
        ) index_descending );

CREATE INDEX mch_visit_index_asc ON temp_mch_visit_index_asc(patient_id, index_asc, encounter_id);
CREATE INDEX mch_visit_index_desc ON temp_mch_visit_index_desc(patient_id, index_desc, encounter_id);

UPDATE temp_obgyn_visit o
        JOIN
    temp_mch_visit_index_asc top ON o.encounter_id = top.encounter_id 
SET 
    o.index_asc = top.index_asc;

UPDATE temp_obgyn_visit o
        JOIN
    temp_mch_visit_index_desc top ON o.encounter_id = top.encounter_id 
SET 
    o.index_desc = top.index_desc;

UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'HIV test done') 
SET 
    hiv_test_admin = value_coded;

UPDATE temp_obgyn_visit te 
SET 
    medication_order = (SELECT 
            (GROUP_CONCAT(CONCEPT_NAME(concept_id, 'en')
                    SEPARATOR ' | '))
        FROM
            orders o
        WHERE
            te.encounter_id = o.encounter_id
                AND te.patient_id = o.patient_id
                AND o.voided = 0);

-- all mch diagnosis
DROP TEMPORARY TABLE IF EXISTS temp_diagnosis_obs_id;
CREATE TEMPORARY TABLE temp_diagnosis_obs_id
(
encounter_id INT,
obs_id INT
);

CREATE INDEX temp_diagnosis_obs_id_encounter_id ON temp_diagnosis_obs_id (encounter_id);
CREATE INDEX temp_diagnosis_obs_id_obs_id ON temp_diagnosis_obs_id (obs_id);

INSERT INTO temp_diagnosis_obs_id(encounter_id, obs_id)
SELECT
                        encounter_id, obs_id
                    FROM
                        obs
                    WHERE
                        concept_id = @visit_diagnosis_concept_id
AND voided = 0
                    AND encounter_id IN (SELECT encounter_id temp_obgyn_visit);

-- return only mch primary diagnosis
DROP TEMPORARY TABLE IF EXISTS temp_primary_diagnosis_obs_group_id;
CREATE TEMPORARY TABLE temp_primary_diagnosis_obs_group_id
(
encounter_id INT,
obs_id INT,
obs_group_id INT
);

CREATE INDEX temp_primary_diagnosis_obs_group_id_encounter_id ON temp_primary_diagnosis_obs_group_id (encounter_id);
CREATE INDEX temp_primary_diagnosis_obs_group_id_obs_id ON temp_primary_diagnosis_obs_group_id (obs_id);
CREATE INDEX temp_primary_diagnosis_obs_group_id_obs_group_id ON temp_primary_diagnosis_obs_group_id (obs_group_id);

INSERT INTO temp_primary_diagnosis_obs_group_id(encounter_id, obs_id, obs_group_id)
SELECT
encounter_id, obs_id, obs_group_id
                    FROM
                        obs
                    WHERE
                        concept_id = @diagnosis_order
                            AND voided = 0
                            AND value_coded = @primary_diagnosis
                            AND encounter_id IN (SELECT encounter_id FROM temp_diagnosis_obs_id);

DROP TEMPORARY TABLE IF EXISTS temp_primary_diagnosis_stage;
CREATE TEMPORARY TABLE temp_primary_diagnosis_stage
(
encounter_id INT,
value_coded INT,
diagnosis VARCHAR(255)
);

CREATE INDEX temp_primary_diagnosis_stage_encounter_id ON temp_primary_diagnosis_stage (encounter_id);
CREATE INDEX temp_primary_diagnosis_stage_value_coded ON temp_primary_diagnosis_stage (value_coded);

INSERT INTO temp_primary_diagnosis_stage (encounter_id, value_coded)
SELECT
encounter_id, value_coded
                    FROM
                        obs
                    WHERE
                        concept_id = @diagnosis
                            AND voided = 0
                            AND obs_group_id IN (SELECT obs_group_id FROM temp_primary_diagnosis_obs_group_id);

DROP TEMPORARY TABLE IF EXISTS temp_primary_diagnosis_stage_names;
CREATE TEMPORARY TABLE temp_primary_diagnosis_stage_names
AS SELECT encounter_id, CONCEPT_NAME(value_coded, 'en') primary_diagnosis FROM temp_primary_diagnosis_stage;

DROP TEMPORARY TABLE IF EXISTS temp_primary_diagnosis;
CREATE TEMPORARY TABLE temp_primary_diagnosis
AS
SELECT
encounter_id, GROUP_CONCAT(t.primary_diagnosis SEPARATOR ' | ') primary_diagnosis
                    FROM
                        temp_primary_diagnosis_stage_names t
                    GROUP BY t.encounter_id;

UPDATE temp_obgyn_visit t JOIN temp_primary_diagnosis tp ON tp.encounter_id = t.encounter_id
SET t.primary_diagnosis = tp.primary_diagnosis;

-- return only mch secondary diagnosis
DROP TEMPORARY TABLE IF EXISTS temp_secondary_diagnosis_obs_group_id;
CREATE TEMPORARY TABLE temp_secondary_diagnosis_obs_group_id
(
encounter_id INT,
obs_id INT,
obs_group_id INT
);

CREATE INDEX temp_secondary_diagnosis_obs_group_id_encounter_id ON temp_secondary_diagnosis_obs_group_id (encounter_id);
CREATE INDEX temp_secondary_diagnosis_obs_group_id_obs_id ON temp_secondary_diagnosis_obs_group_id (obs_id);
CREATE INDEX temp_secondary_diagnosis_obs_group_id_obs_group_id ON temp_secondary_diagnosis_obs_group_id (obs_group_id);

INSERT INTO temp_secondary_diagnosis_obs_group_id(encounter_id, obs_id, obs_group_id)
SELECT
encounter_id, obs_id, obs_group_id
                    FROM
                        obs
                    WHERE
                        concept_id = @diagnosis_order
                            AND voided = 0
                            AND value_coded = @secondary_diagnosis
                            AND encounter_id IN (SELECT encounter_id FROM temp_diagnosis_obs_id);

DROP TEMPORARY TABLE IF EXISTS temp_secondary_diagnosis_stage;
CREATE TEMPORARY TABLE temp_secondary_diagnosis_stage
(
encounter_id INT,
value_coded INT,
diagnosis VARCHAR(255)
);

CREATE INDEX temp_secondary_diagnosis_stage_encounter_id ON temp_secondary_diagnosis_stage (encounter_id);
CREATE INDEX temp_secondary_diagnosis_stage_value_coded ON temp_secondary_diagnosis_stage (value_coded);

INSERT INTO temp_secondary_diagnosis_stage (encounter_id, value_coded)
SELECT
encounter_id, value_coded
                    FROM
                        obs
                    WHERE
                        concept_id = @diagnosis
                            AND voided = 0
                            AND obs_group_id IN (SELECT obs_group_id FROM temp_secondary_diagnosis_obs_group_id);

DROP TEMPORARY TABLE IF EXISTS temp_secondary_diagnosis_stage_names;
CREATE TEMPORARY TABLE temp_secondary_diagnosis_stage_names
AS SELECT encounter_id, CONCEPT_NAME(value_coded, 'en') secondary_diagnosis FROM temp_secondary_diagnosis_stage;

DROP TEMPORARY TABLE IF EXISTS temp_secondary_diagnosis;
CREATE TEMPORARY TABLE temp_secondary_diagnosis
AS
SELECT
encounter_id, GROUP_CONCAT(t.secondary_diagnosis SEPARATOR ' | ') secondary_diagnosis
                    FROM
                        temp_secondary_diagnosis_stage_names t
                    GROUP BY t.encounter_id;

UPDATE temp_obgyn_visit t JOIN temp_secondary_diagnosis tp ON tp.encounter_id = t.encounter_id
SET t.secondary_diagnosis = tp.secondary_diagnosis;

-- non coded diagnosis    
UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'Diagnosis or problem, non-coded') 
SET 
    diagnosis_non_coded = value_text;

UPDATE temp_obgyn_visit te 
SET 
    procedures = OBS_VALUE_CODED_LIST(te.encounter_id, 'CIEL', '1651', 'en');

UPDATE temp_obgyn_visit te 
SET 
    procedures_other = OBS_VALUE_TEXT(te.encounter_id, 'CIEL', '165264');

UPDATE temp_obgyn_visit te 
SET 
    family_planning_use = OBS_VALUE_CODED_LIST(te.encounter_id, 'CIEL', '965', 'en');
    
UPDATE temp_obgyn_visit te
        JOIN
    obs o ON te.encounter_id = o.encounter_id
        AND o.voided = 0
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'METHOD OF FAMILY PLANNING')
        AND o.obs_group_id IN (SELECT 
            obs_id
        FROM
            obs
        WHERE
            voided = 0
                AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Family planning construct')) 
SET 
    family_planning_method = CONCEPT_NAME(value_coded, 'en');
 
UPDATE temp_obgyn_visit te 
SET 
    fp_counseling_received = OBS_VALUE_CODED_LIST(te.encounter_id, 'CIEL', '165309', 'en');
   
SELECT 
    patient_id,
    ZLEMR(patient_id),
    encounter_id,
    visit_date,
    visit_site,
    visit_type,
    consultation_type,
    consultation_type_fp,
    age_at_visit,
    entry_date,
    entered_by,
    examining_doctor,
    pregnant,
    breastfeeding,
    pregnant_lmp,
    pregnant_edd,
    next_visit_date,
    triage_level,
    referral_type,
    referral_type_other,
    implant_inserted,
    IUD_inserted,
    tubal_ligation_completed,
    abortion_completed,
    bcg_1,
    polio_0,
    polio_1,
    polio_2,
    polio_3,
    polio_booster_1,
    polio_booster_2,
    pentavalent_1,
    pentavalent_2,
    pentavalent_3,
    rotavirus_1,
    rotavirus_2,
    mmr_1,
    tetanus_0,
    tetanus_1,
    tetanus_2,
    tetanus_3,
    tetanus_booster_1,
    tetanus_booster_2,
    gyno_exam,
    wh_exam,
    previous_history,
    hiv_test_admin,
    cervical_cancer_screening_date,
    cervical_cancer_screening_result,
    primary_diagnosis,
    secondary_diagnosis,
    diagnosis_non_coded,
    procedures,
    procedures_other,
    medication_order,
    IF(family_planning_use LIKE '%Yes%', 1, NULL),
    family_planning_method,
    IF(fp_counseling_received LIKE '%Family planning counseling%', 1, NULL),
    risk_factors,
    index_asc,
    index_desc
FROM
    temp_obgyn_visit
ORDER BY patient_id , index_asc;