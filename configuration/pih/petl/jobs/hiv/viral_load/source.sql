#### This query returns a row per encounter (VL construct per encounter)

SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_hiv_construct_encounters;
DROP TEMPORARY TABLE IF EXISTS temp_vl_index_asc;
DROP TEMPORARY TABLE IF EXISTS temp_vl_index_desc;

### hiv constructs table
CREATE TEMPORARY TABLE temp_hiv_construct_encounters
(
    patient_id                      INT,
    encounter_id                    INT,
    vl_sample_taken_date            DATETIME,
    date_created                    DATETIME,
    vl_sample_taken_date_estimated  VARCHAR(11),
    vl_result_date                  DATE,
    specimen_number                 VARCHAR(255),
    vl_test_outcome                 VARCHAR(255),
    viral_load                      INT,
    detected_lower_limit            INT,
    vl_type                         VARCHAR(50)
);

-- patient and encounter IDs
INSERT INTO temp_hiv_construct_encounters (patient_id, encounter_id)
SELECT person_id, encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "HIV viral load construct");

-- specimen collection date
UPDATE temp_hiv_construct_encounters tvl JOIN encounter e ON tvl.encounter_id = e.encounter_id
SET	vl_sample_taken_date = e.encounter_datetime;

-- date encounter was created
UPDATE temp_hiv_construct_encounters tvl JOIN encounter e ON tvl.encounter_id = e.encounter_id
SET	tvl.date_created = e.date_created;

## Delete test patients
DELETE FROM temp_hiv_construct_encounters WHERE
patient_id IN (
               SELECT
                      a.person_id
                      FROM person_attribute a
                      INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
                      AND a.value = 'true' AND t.name = 'Test Patient'
               );

-- is specimen collection date estimated
UPDATE temp_hiv_construct_encounters SET vl_sample_taken_date_estimated =  OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '11781', 'en');

-- lab result date
UPDATE temp_hiv_construct_encounters SET vl_result_date =  OBS_VALUE_DATETIME(encounter_id, 'PIH', 'DATE OF LABORATORY TEST');

-- specimen number
UPDATE temp_hiv_construct_encounters SET specimen_number =  OBS_VALUE_TEXT(encounter_id, 'CIEL', '162086');

-- viral load results (coded)
UPDATE temp_hiv_construct_encounters SET vl_test_outcome =  OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1305', 'en');

-- viral load results (numeric)
UPDATE temp_hiv_construct_encounters SET viral_load =  OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '856');

-- detected lower limit
UPDATE temp_hiv_construct_encounters SET detected_lower_limit =  OBS_VALUE_NUMERIC(encounter_id, 'PIH', '11548');

-- viral load type
UPDATE temp_hiv_construct_encounters SET vl_type =  OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '164126', 'en');

-- The indexes are calculated using the specimen collection date
### index ascending
CREATE TEMPORARY TABLE temp_vl_index_asc
(
    SELECT
            patient_id,
            vl_sample_taken_date,
            date_created,
            encounter_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            vl_sample_taken_date,
            date_created,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_hiv_construct_encounters,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, vl_sample_taken_date ASC, date_created ASC
        ) index_ascending );

### index descending
CREATE TEMPORARY TABLE temp_vl_index_desc
(
    SELECT
            patient_id,
            vl_sample_taken_date,
            date_created,
            encounter_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            vl_sample_taken_date,
            date_created,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_hiv_construct_encounters,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, vl_sample_taken_date DESC, date_created DESC
        ) index_descending );

### Final query
SELECT
        tvl.patient_id,
        tvl.encounter_id,
        DATE(tvl.vl_sample_taken_date) vl_sample_taken_date,
        vl_sample_taken_date_estimated,
        vl_result_date,
        specimen_number,
        vl_test_outcome,
        viral_load,
        detected_lower_limit,
        vl_type,
        DATEDIFF(NOW(), tvl.vl_sample_taken_date) days_since_vl,
        index_desc,
        index_asc
FROM temp_hiv_construct_encounters tvl
-- index descending
JOIN temp_vl_index_desc tid ON tvl.encounter_id = tid.encounter_id
-- index ascending
JOIN temp_vl_index_asc tia ON tvl.encounter_id = tia.encounter_id
ORDER BY tvl.patient_id, index_desc;
