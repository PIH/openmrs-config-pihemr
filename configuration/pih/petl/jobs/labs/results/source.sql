SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_tb_smear_results;
DROP TEMPORARY TABLE IF EXISTS temp_tb_culture_results;
DROP TEMPORARY TABLE IF EXISTS temp_tb_genxpert_results;
DROP TEMPORARY TABLE IF EXISTS temp_tb_skin_results;

# SMEAR
CREATE TEMPORARY TABLE temp_tb_smear_results
(
patient_id                  INT(11),
encounter_id                INT(11),
specimen_collection_date    DATE,
sample_taken_date_estimated VARCHAR(11),
test_result_date            DATE,
test_related_to             VARCHAR(25),
test_type                   VARCHAR(255),
test_result_status          VARCHAR(255),
test_result_status_numeric  DOUBLE
);

# patient and encounter IDs
INSERT INTO temp_tb_smear_results (patient_id, encounter_id, test_related_to, test_type)
SELECT person_id, encounter_id, 'tb', 'smear' FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT");

# sample taken date
UPDATE temp_tb_smear_results tbs INNER JOIN encounter e ON e.voided = 0 AND tbs.encounter_id=e.encounter_id
SET tbs.specimen_collection_date = DATE(e.encounter_datetime);

# specimen collection date estimated
UPDATE temp_tb_smear_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND concept_id = concept_from_mapping('PIH', '11781')
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT"))
SET tbs.sample_taken_date_estimated =  concept_name(o.value_coded , 'en');

# test result status
UPDATE temp_tb_smear_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT")
SET tbs.test_result_status = CONCEPT_NAME(o.value_coded, 'en');

# test result date
UPDATE temp_tb_smear_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "DATE OF LABORATORY TEST")
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS SMEAR RESULT"))
SET tbs.test_result_date = DATE(o.value_datetime);

### Culture
CREATE TEMPORARY TABLE temp_tb_culture_results
(
patient_id                  INT(11),
encounter_id                INT(11),
specimen_collection_date    DATE,
sample_taken_date_estimated VARCHAR(11),
test_result_date            DATE,
test_related_to             VARCHAR(25),
test_type                   VARCHAR(255),
test_result_status          VARCHAR(255),
test_result_status_numeric  DOUBLE
);

# patient and encounter IDs
INSERT INTO temp_tb_culture_results (patient_id, encounter_id, test_related_to, test_type)
SELECT person_id, encounter_id, 'tb', 'culture' FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT");

# sample taken date
UPDATE temp_tb_culture_results tbs INNER JOIN encounter e ON e.voided = 0 AND tbs.encounter_id=e.encounter_id
SET tbs.specimen_collection_date = DATE(e.encounter_datetime);

# specimen collection date estimated
UPDATE temp_tb_culture_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND concept_id = concept_from_mapping('PIH', '11781')
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT"))
SET tbs.sample_taken_date_estimated =  concept_name(o.value_coded , 'en');

# test result status
UPDATE temp_tb_culture_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT")
SET tbs.test_result_status = CONCEPT_NAME(o.value_coded, 'en');

# test result date
UPDATE temp_tb_culture_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "DATE OF LABORATORY TEST")
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULOSIS CULTURE RESULT"))
SET tbs.test_result_date = DATE(o.value_datetime);

### genXpert
CREATE TEMPORARY TABLE temp_tb_genxpert_results
(
patient_id                  INT(11),
encounter_id                INT(11),
specimen_collection_date    DATE,
sample_taken_date_estimated VARCHAR(11),
test_result_date            DATE,
test_related_to             VARCHAR(25),
test_type                   VARCHAR(255),
test_result_status          VARCHAR(255),
test_result_status_numeric  DOUBLE
);

# patient and encounter IDs
INSERT INTO temp_tb_genxpert_results (patient_id, encounter_id, test_related_to, test_type)
SELECT person_id, encounter_id, 'tb', 'genXpert' FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202");

# sample taken date
UPDATE temp_tb_genxpert_results tbs INNER JOIN encounter e ON e.voided = 0 AND tbs.encounter_id=e.encounter_id
SET tbs.specimen_collection_date = DATE(e.encounter_datetime);

# specimen collection date estimated
UPDATE temp_tb_genxpert_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND concept_id = concept_from_mapping('PIH', '11781')
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202"))
SET tbs.sample_taken_date_estimated =  concept_name(o.value_coded , 'en');

# test result status
UPDATE temp_tb_genxpert_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202")
SET tbs.test_result_status = CONCEPT_NAME(o.value_coded, 'en');

# test result date
UPDATE temp_tb_genxpert_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "DATE OF LABORATORY TEST")
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("CIEL", "162202"))
SET tbs.test_result_date = DATE(o.value_datetime);

## tb skin test
CREATE TEMPORARY TABLE temp_tb_skin_results
(
patient_id                  INT(11),
encounter_id                INT(11),
specimen_collection_date    DATE,
sample_taken_date_estimated VARCHAR(11),
test_result_date            DATE,
test_related_to             VARCHAR(25),
test_type                   VARCHAR(255),
test_result_status          VARCHAR(255),
test_result_status_numeric  DOUBLE
);

# patient and encounter IDs
INSERT INTO temp_tb_skin_results (patient_id, encounter_id, test_related_to, test_type)
SELECT person_id, encounter_id, 'tb', 'skin test' FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULIN SKIN TEST");

# sample taken date
UPDATE temp_tb_skin_results tbs INNER JOIN encounter e ON e.voided = 0 AND tbs.encounter_id=e.encounter_id
SET tbs.specimen_collection_date = DATE(e.encounter_datetime);

# specimen collection date estimated
UPDATE temp_tb_skin_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND concept_id = concept_from_mapping('PIH', '11781')
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULIN SKIN TEST"))
SET tbs.sample_taken_date_estimated =  concept_name(o.value_coded , 'en');

# test result status
UPDATE temp_tb_skin_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id=o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULIN SKIN TEST")
SET tbs.test_result_status_numeric = o.value_numeric;

# test result date
UPDATE temp_tb_skin_results tbs INNER JOIN obs o ON o.voided = 0 AND tbs.encounter_id = o.encounter_id AND o.person_id = tbs.patient_id AND concept_id = CONCEPT_FROM_MAPPING("PIH", "DATE OF LABORATORY TEST")
AND o.encounter_id IN (SELECT encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "TUBERCULIN SKIN TEST"))
SET tbs.test_result_date = DATE(o.value_datetime);

## Final query
SELECT * FROM temp_tb_smear_results
UNION ALL
SELECT * FROM temp_tb_culture_results
UNION ALL
SELECT * FROM temp_tb_genxpert_results
UNION ALL
SELECT * FROM temp_tb_skin_results order by patient_id, encounter_id;