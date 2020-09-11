#### This query returns a row per encounter (VL construct per encounter)

SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_hiv_construct_encounters;
DROP TEMPORARY TABLE IF EXISTS temp_index_asc;
DROP TEMPORARY TABLE IF EXISTS temp_index_desc;

### hiv constructs table
CREATE TEMPORARY TABLE temp_hiv_construct_encounters
(
    patient_id                      INT,
    encounter_id                    INT,
    vl_sample_taken_date            DATETIME,
    vl_sample_taken_date_estimated  VARCHAR(11),
    vl_result_date                  DATE,
    vl_test_outcome                 VARCHAR(255),
    vl_result_detectable            VARCHAR(255),
    viral_load                      INT,
    vl_type                         VARCHAR(50)
);

-- patient and encounter IDs
INSERT INTO temp_hiv_construct_encounters (patient_id, encounter_id)
SELECT person_id, encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "HIV viral load construct");

-- specimen collection date
UPDATE temp_hiv_construct_encounters tvl JOIN encounter e ON tvl.encounter_id = e.encounter_id and e.voided = 0
SET	vl_sample_taken_date = e.encounter_datetime;

-- is specimen collection date estimated
UPDATE temp_hiv_construct_encounters SET vl_sample_taken_date_estimated =  OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '11781', 'en');

-- lab result date
UPDATE temp_hiv_construct_encounters SET vl_result_date =  OBS_VALUE_DATETIME(encounter_id, 'PIH', 'DATE OF LABORATORY TEST');

-- viral load results (detectable)
UPDATE temp_hiv_construct_encounters SET vl_result_detectable =  OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1305', 'en');

-- viral load results (numeric)
UPDATE temp_hiv_construct_encounters SET viral_load =  OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '856');

-- The indexes are calculated using the specimen collection date
### index ascending
CREATE TEMPORARY TABLE temp_index_asc
(
    SELECT
            patient_id,
            vl_sample_taken_date,
            encounter_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            vl_sample_taken_date,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_hiv_construct_encounters,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, vl_sample_taken_date ASC
        ) index_ascending );

### index descending
CREATE TEMPORARY TABLE temp_index_desc
(
    SELECT
            patient_id,
            vl_sample_taken_date,
            encounter_id,
            ## days since last viral load
            DATEDIFF(NOW(), vl_sample_taken_date) days_since_last_vl,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            vl_sample_taken_date,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_hiv_construct_encounters,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, vl_sample_taken_date DESC
        ) index_descending );

### Final query
SELECT
        tvl.patient_id,
        tvl.encounter_id,
        DATE(tvl.vl_sample_taken_date),
        vl_sample_taken_date_estimated,
        vl_result_date,
        vl_test_outcome,
        vl_result_detectable,
        viral_load,
        vl_type,
        IF(index_desc = 1, tid.days_since_last_vl, NULL) days_since_last_vl,
        index_desc,
        index_asc
FROM temp_hiv_construct_encounters tvl
-- index ascending
JOIN temp_index_asc tia ON tvl.encounter_id = tia.encounter_id
-- index descending
JOIN temp_index_desc tid ON tvl.encounter_id = tid.encounter_id
ORDER BY tvl.patient_id, index_desc;