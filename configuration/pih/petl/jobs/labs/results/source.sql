### This query returns tb lab results
### Row per result
### To do add HPV results in the future
### note result no performed duplicates. But its rare to have result not performed
### for culture, smear and genexpert all at once (but if they are in same encounter it will duplicate)

SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_tb_smear_results;
DROP TEMPORARY TABLE IF EXISTS temp_tb_culture_results;
DROP TEMPORARY TABLE IF EXISTS temp_tb_genxpert_results;
DROP TEMPORARY TABLE IF EXISTS temp_tb_skin_results;
DROP TEMPORARY TABLE IF EXISTS temp_reason_no_smear;
DROP TEMPORARY TABLE IF EXISTS temp_reason_no_culture;
DROP TEMPORARY TABLE IF EXISTS temp_reason_no_genxpert;

# SMEAR
CREATE TEMPORARY TABLE temp_tb_smear_results
(
    patient_id                  INT(11),
    encounter_id                INT(11),
    order_id                    INT(11),
    order_number                VARCHAR(50),
    specimen_collection_date    DATE,
    sample_taken_date_estimated VARCHAR(11),
    test_result_date            DATE,
    test_related_to             VARCHAR(25),
    test_type                   VARCHAR(255),
    test_status					VARCHAR(255),
    reason_test_not_perform     VARCHAR(255),
    test_result_text            VARCHAR(255),
    test_result_numeric         DOUBLE,
    date_created                DATETIME,
    index_asc                   INT(11),
    index_desc                  INT(11)
);

# patient and encounter IDs
INSERT INTO temp_tb_smear_results (patient_id, encounter_id, specimen_collection_date, test_related_to, test_type, test_status, date_created)
SELECT person_id, encounter_id, DATE(obs_datetime), 'tb', 'smear', 'performed', date_created FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT");

# specimen collection date estimated
UPDATE temp_tb_smear_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', '11781')
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT"))
SET tbs.sample_taken_date_estimated =  CONCEPT_NAME(o.value_coded , 'en');

# test result status
UPDATE temp_tb_smear_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT")
SET tbs.test_result_text = CONCEPT_NAME(o.value_coded, 'en');

# test result date
UPDATE temp_tb_smear_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND o.person_id = tbs.patient_id
AND concept_id IN (CONCEPT_FROM_MAPPING("PIH", "DATE OF LABORATORY TEST"), CONCEPT_FROM_MAPPING("PIH", "Date of test results"))
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT"))
SET tbs.test_result_date = DATE(o.value_datetime);

### Culture
CREATE TEMPORARY TABLE temp_tb_culture_results
(
    patient_id                  INT(11),
    encounter_id                INT(11),
    order_id                    INT(11),
    order_number                VARCHAR(50),
    specimen_collection_date    DATE,
    sample_taken_date_estimated VARCHAR(11),
    test_result_date            DATE,
    test_related_to             VARCHAR(25),
    test_type                   VARCHAR(255),
    test_status					VARCHAR(255),
    reason_test_not_perform     VARCHAR(255),
    test_result_text            VARCHAR(255),
    test_result_numeric         DOUBLE,
    date_created                DATETIME,
    index_asc                   INT(11),
    index_desc                  INT(11)
);

# patient and encounter IDs
INSERT INTO temp_tb_culture_results (patient_id, encounter_id, specimen_collection_date, test_related_to, test_type, test_status, date_created)
SELECT person_id, encounter_id, DATE(obs_datetime), 'tb', 'culture', 'performed', date_created FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT");

# specimen collection date estimated
UPDATE temp_tb_culture_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', '11781')
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT"))
SET tbs.sample_taken_date_estimated =  CONCEPT_NAME(o.value_coded , 'en');

# test result status
UPDATE temp_tb_culture_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT")
SET tbs.test_result_text = CONCEPT_NAME(o.value_coded, 'en');

# test result date
UPDATE temp_tb_culture_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND o.person_id = tbs.patient_id
AND concept_id IN (CONCEPT_FROM_MAPPING("PIH", "DATE OF LABORATORY TEST"), CONCEPT_FROM_MAPPING("PIH", "Date of test results"))
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT"))
SET tbs.test_result_date = DATE(o.value_datetime);

### genXpert
CREATE TEMPORARY TABLE temp_tb_genxpert_results
(
    patient_id                  INT(11),
    encounter_id                INT(11),
    order_id                    INT(11),
    order_number                VARCHAR(50),
    specimen_collection_date    DATE,
    sample_taken_date_estimated VARCHAR(11),
    test_result_date            DATE,
    test_related_to             VARCHAR(25),
    test_type                   VARCHAR(255),
    test_status					VARCHAR(255),
    reason_test_not_perform     VARCHAR(255),
    test_result_text            VARCHAR(255),
    test_result_numeric         DOUBLE,
    date_created                DATETIME,
    index_asc                   INT(11),
    index_desc                  INT(11)
);

# patient and encounter IDs
INSERT INTO temp_tb_genxpert_results (patient_id, encounter_id, specimen_collection_date, test_related_to, test_type, test_status, date_created)
SELECT person_id, encounter_id, DATE(obs_datetime), 'tb', 'genxpert', 'performed', date_created FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202");

# sample taken date
UPDATE temp_tb_genxpert_results tbs INNER JOIN encounter e ON e.voided = 0 AND tbs.encounter_id=e.encounter_id
SET tbs.specimen_collection_date = DATE(e.encounter_datetime);

# specimen collection date estimated
UPDATE temp_tb_genxpert_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', '11781')
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202"))
SET tbs.sample_taken_date_estimated =  CONCEPT_NAME(o.value_coded , 'en');

# test result status
UPDATE temp_tb_genxpert_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202")
SET tbs.test_result_text = CONCEPT_NAME(o.value_coded, 'en');

# test result date
UPDATE temp_tb_genxpert_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND o.person_id = tbs.patient_id
AND concept_id IN (CONCEPT_FROM_MAPPING("PIH", "DATE OF LABORATORY TEST"), CONCEPT_FROM_MAPPING("PIH", "Date of test results"))
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202"))
SET tbs.test_result_date = DATE(o.value_datetime);

## tb skin test
CREATE TEMPORARY TABLE temp_tb_skin_results
(
    patient_id                  INT(11),
    encounter_id                INT(11),
    order_id                    INT(11),
    order_number                VARCHAR(50),
    specimen_collection_date    DATE,
    sample_taken_date_estimated VARCHAR(11),
    test_result_date            DATE,
    test_related_to             VARCHAR(25),
    test_type                   VARCHAR(255),
    test_status					VARCHAR(255),
    reason_test_not_perform     VARCHAR(255),
    test_result_text            VARCHAR(255),
    test_result_numeric         DOUBLE,
    date_created                DATETIME,
    index_asc                   INT(11),
    index_desc                  INT(11)
);

# patient and encounter IDs
INSERT INTO temp_tb_skin_results (patient_id, encounter_id, specimen_collection_date, test_related_to, test_type, test_status, date_created)
SELECT person_id, encounter_id, DATE(obs_datetime), 'tb', 'skin test', 'performed', date_created FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULIN SKIN TEST");

# specimen collection date estimated
UPDATE temp_tb_skin_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', '11781')
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULIN SKIN TEST"))
SET tbs.sample_taken_date_estimated =  CONCEPT_NAME(o.value_coded , 'en');

# test result status
UPDATE temp_tb_skin_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "PPD qualitative")
SET tbs.test_result_text = CONCEPT_NAME(o.value_coded, 'en');

# test result status
UPDATE temp_tb_skin_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULIN SKIN TEST")
SET tbs.test_result_numeric = o.value_numeric;

# test result date
UPDATE temp_tb_skin_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND o.person_id = tbs.patient_id
AND concept_id IN (CONCEPT_FROM_MAPPING("PIH", "DATE OF LABORATORY TEST"), CONCEPT_FROM_MAPPING("PIH", "Date of test results"))
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULIN SKIN TEST"))
SET tbs.test_result_date = DATE(o.value_datetime);

### Test not performed. Entered via the lab order/results app
### smear
CREATE TEMPORARY TABLE temp_reason_no_smear
(
    patient_id                  INT(11),
    encounter_id                INT(11),
    order_id                    INT(11),
    order_number                VARCHAR(50),
    specimen_collection_date    DATE,
    sample_taken_date_estimated VARCHAR(11),
    test_result_date            DATE,
    test_related_to             VARCHAR(25),
    test_type                   VARCHAR(255),
    test_status					VARCHAR(255),
    reason_test_not_perform     VARCHAR(255),
    test_result_text            VARCHAR(255),
    test_result_numeric         DOUBLE,
    date_created                DATETIME,
    index_asc                   INT(11),
    index_desc                  INT(11)
);

INSERT INTO temp_reason_no_smear(patient_id, encounter_id, specimen_collection_date, order_id, order_number, test_related_to, test_type, test_status, reason_test_not_perform , date_created)
SELECT person_id, o.encounter_id, DATE(obs_datetime), ord.order_id, ord.order_number, 'tb', 'smear', 'not performed', CONCEPT_NAME(value_coded, 'en'), o.date_created  FROM obs o INNER JOIN orders ord on o.order_id = ord.order_id WHERE o.voided = 0 AND
ord.voided = 0 AND o.concept_id = CONCEPT_FROM_MAPPING("CIEL", "165182") AND ord.fulfiller_status LIKE "%EXCEPTION%" AND ord.concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT");

UPDATE temp_reason_no_smear trs INNER JOIN obs o ON o.voided = 0 AND trs.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "Date of test results")
SET test_result_date = DATE(o.value_datetime);

### culture
CREATE TEMPORARY TABLE temp_reason_no_culture
(
    patient_id                  INT(11),
    encounter_id                INT(11),
    order_id                    INT(11),
    order_number                VARCHAR(50),
    specimen_collection_date    DATE,
    sample_taken_date_estimated VARCHAR(11),
    test_result_date            DATE,
    test_related_to             VARCHAR(25),
    test_type                   VARCHAR(255),
    test_status					VARCHAR(255),
    reason_test_not_perform     VARCHAR(255),
    test_result_text            VARCHAR(255),
    test_result_numeric         DOUBLE,
    date_created                DATETIME,
    index_asc                   INT(11),
    index_desc                  INT(11)
);

INSERT INTO temp_reason_no_culture(patient_id, encounter_id, specimen_collection_date, order_id, order_number, test_related_to, test_type, test_status, reason_test_not_perform , date_created)
SELECT person_id, o.encounter_id, DATE(obs_datetime), ord.order_id, ord.order_number, 'tb', 'culture', 'not performed', CONCEPT_NAME(value_coded, 'en'), o.date_created  FROM obs o INNER JOIN orders ord on o.order_id = ord.order_id WHERE o.voided = 0 AND
ord.voided = 0 AND o.concept_id = CONCEPT_FROM_MAPPING("CIEL", "165182") AND ord.fulfiller_status LIKE "%EXCEPTION%" AND ord.concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT");

UPDATE temp_reason_no_culture trs INNER JOIN obs o ON o.voided = 0 AND trs.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "Date of test results")
SET test_result_date = DATE(o.value_datetime);

### genxpert
CREATE TEMPORARY TABLE temp_reason_no_genxpert
(
    patient_id                  INT(11),
    encounter_id                INT(11),
    order_id                    INT(11),
    order_number                VARCHAR(50),
    specimen_collection_date    DATE,
    sample_taken_date_estimated VARCHAR(11),
    test_result_date            DATE,
    test_related_to             VARCHAR(25),
    test_type                   VARCHAR(255),
    test_status					VARCHAR(255),
    reason_test_not_perform     VARCHAR(255),
    test_result_text            VARCHAR(255),
    test_result_numeric         DOUBLE,
    date_created                DATETIME,
    index_asc                   INT(11),
    index_desc                  INT(11)
);

INSERT INTO temp_reason_no_genxpert(patient_id, encounter_id, specimen_collection_date, order_id, order_number, test_related_to, test_type, test_status, reason_test_not_perform , date_created)
SELECT person_id, o.encounter_id, DATE(obs_datetime), ord.order_id, ord.order_number, 'tb', 'genxpert', 'not performed', CONCEPT_NAME(value_coded, 'en'), o.date_created  FROM obs o INNER JOIN orders ord on o.order_id = ord.order_id WHERE o.voided = 0 AND
ord.voided = 0 AND o.concept_id = CONCEPT_FROM_MAPPING("CIEL", "165182") AND ord.fulfiller_status LIKE "%EXCEPTION%" AND ord.concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202");

UPDATE temp_reason_no_genxpert trs INNER JOIN encounter e ON e.voided = 0 AND trs.encounter_id = e.encounter_id
SET specimen_collection_date = DATE(e.encounter_datetime);

UPDATE temp_reason_no_genxpert trs INNER JOIN obs o ON o.voided = 0 AND trs.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "Date of test results")
SET test_result_date = DATE(o.value_datetime);


## Final query section
DROP TEMPORARY TABLE IF EXISTS temp_tb_final_query;
CREATE TEMPORARY TABLE temp_tb_final_query
SELECT * FROM temp_tb_smear_results
UNION ALL
SELECT * FROM temp_tb_culture_results
UNION ALL
SELECT * FROM temp_tb_genxpert_results
UNION ALL
SELECT * FROM temp_tb_skin_results
UNION ALL
SELECT * FROM temp_reason_no_smear
UNION ALL
SELECT * FROM temp_reason_no_culture
UNION ALL
SELECT * FROM temp_reason_no_genxpert
ORDER BY patient_id, encounter_id;


-- The indexes are calculated using the specimen collection date
### index ascending
DROP TEMPORARY TABLE IF EXISTS temp_tb_index_asc;
CREATE TEMPORARY TABLE temp_tb_index_asc
(
    SELECT
            patient_id,
            specimen_collection_date,
            date_created,
            encounter_id,
            test_type,
            order_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            specimen_collection_date,
            date_created,
            encounter_id,
            patient_id,
            test_type,
            order_id,
            @u:= patient_id
      FROM temp_tb_final_query,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id ASC, encounter_id ASC, specimen_collection_date ASC, date_created ASC, test_type ASC
        ) index_ascending );

### index descending
DROP TEMPORARY TABLE IF EXISTS temp_tb_index_desc;
CREATE TEMPORARY TABLE temp_tb_index_desc
(
    SELECT
            patient_id,
            specimen_collection_date,
            date_created,
            encounter_id,
            test_type,
            order_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            specimen_collection_date,
            date_created,
            encounter_id,
            patient_id,
            test_type,
            order_id,
            @u:= patient_id
      FROM temp_tb_final_query,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id DESC, encounter_id DESC, specimen_collection_date DESC, date_created DESC, test_type DESC
        ) index_descending );

UPDATE temp_tb_final_query tbf INNER JOIN temp_tb_index_asc tbia ON tbf.encounter_id = tbia.encounter_id AND tbf.test_type = tbia.test_type AND tbf.date_created = tbia.date_created
SET tbf.index_asc = tbia.index_asc;

UPDATE temp_tb_final_query tbf INNER JOIN temp_tb_index_desc tbid ON tbf.encounter_id = tbid.encounter_id AND tbf.test_type = tbid.test_type AND tbf.date_created = tbid.date_created
SET tbf.index_desc = tbid.index_desc;

## Final query
SELECT
        patient_id,
        zlemr(patient_id),
        dosId(patient_id),
        encounter_id,
        specimen_collection_date,
        sample_taken_date_estimated,
        test_result_date,
        test_related_to,
        test_type,
        test_status,
        reason_test_not_perform,
        test_result_text,
        test_result_numeric,
        index_asc,
        index_desc,
        date_created
FROM temp_tb_final_query tf
ORDER BY patient_id, index_asc;