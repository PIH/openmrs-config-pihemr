SET sql_safe_updates = 0;
SET @delivery_encounter_type = (SELECT encounter_type_id FROM encounter_type WHERE uuid = "00e5ebb2-90ec-11e8-9eb6-529269fb1459");

DROP TEMPORARY TABLE IF EXISTS temp_mch_birth;
CREATE TEMPORARY TABLE temp_mch_birth
(
patient_id INT,
encounter_id INT,
encounter_date DATE
);

INSERT INTO temp_mch_birth(patient_id, encounter_id, encounter_date)
SELECT patient_id, encounter_id, DATE(encounter_datetime)
FROM encounter WHERE voided = 0 AND encounter_type = @delivery_encounter_type;

DROP TEMPORARY TABLE IF EXISTS temp_mch_birth1;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_mch_birth1(
patient_id INT,
mother_emr_id VARCHAR(25),
encounter_id INT,
encounter_date DATE,
birth_number INT,
multiples INT,
birth_apgar VARCHAR(255),
birth_outcome VARCHAR(255),
birth_weight DOUBLE,
birth_neonatal_resuscitation VARCHAR(255),
birth_macerated_fetus VARCHAR(255)
);

INSERT INTO temp_mch_birth1(patient_id, encounter_id, encounter_date)
SELECT patient_id, encounter_id, encounter_date FROM temp_mch_birth;
UPDATE temp_mch_birth1 SET birth_number = 1;
UPDATE temp_mch_birth1 SET birth_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 0),'CIEL','161033',@locale);
UPDATE temp_mch_birth1 SET birth_weight = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(encounter_id,'CIEL','1585', 0),'CIEL','5916');
UPDATE temp_mch_birth1 SET birth_apgar = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(encounter_id,'CIEL','1585', 0),'CIEL','1504');
UPDATE temp_mch_birth1 SET birth_neonatal_resuscitation = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 0),'CIEL','162131',@locale);
UPDATE temp_mch_birth1 SET birth_macerated_fetus = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 0),'CIEL','135437',@locale);

DROP TEMPORARY TABLE IF EXISTS temp_mch_birth2;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_mch_birth2(
patient_id INT,
mother_emr_id VARCHAR(25),
encounter_id INT,
encounter_date DATE,
birth_number INT,
multiples INT,
birth_apgar VARCHAR(255),
birth_outcome VARCHAR(255),
birth_weight DOUBLE,
birth_neonatal_resuscitation VARCHAR(255),
birth_macerated_fetus VARCHAR(255)
);

INSERT INTO temp_mch_birth2(patient_id, encounter_id, encounter_date)
SELECT patient_id, encounter_id, encounter_date FROM temp_mch_birth;
UPDATE temp_mch_birth2 SET birth_number = 2;
UPDATE temp_mch_birth2 SET birth_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 1),'CIEL','161033',@locale);
UPDATE temp_mch_birth2 SET birth_weight = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(encounter_id,'CIEL','1585', 1),'CIEL','5916');
UPDATE temp_mch_birth2 SET birth_apgar = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(encounter_id,'CIEL','1585', 1),'CIEL','1504');
UPDATE temp_mch_birth2 SET birth_neonatal_resuscitation = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 1),'CIEL','162131',@locale);
UPDATE temp_mch_birth2 SET birth_macerated_fetus = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 1),'CIEL','135437',@locale);

DROP TEMPORARY TABLE IF EXISTS temp_mch_birth3;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_mch_birth3(
patient_id INT,
mother_emr_id VARCHAR(25),
encounter_id INT,
encounter_date DATE,
birth_number INT,
multiples INT,
birth_apgar VARCHAR(255),
birth_outcome VARCHAR(255),
birth_weight DOUBLE,
birth_neonatal_resuscitation VARCHAR(255),
birth_macerated_fetus VARCHAR(255)
);
INSERT INTO temp_mch_birth3(patient_id, encounter_id, encounter_date)
SELECT patient_id, encounter_id, encounter_date FROM temp_mch_birth;
UPDATE temp_mch_birth3 SET birth_number = 3;
UPDATE temp_mch_birth3 SET birth_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 2),'CIEL','161033',@locale);
UPDATE temp_mch_birth3 SET birth_weight = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(encounter_id,'CIEL','1585', 2),'CIEL','5916');
UPDATE temp_mch_birth3 SET birth_apgar = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(encounter_id,'CIEL','1585', 2),'CIEL','1504');
UPDATE temp_mch_birth3 SET birth_neonatal_resuscitation = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 2),'CIEL','162131',@locale);
UPDATE temp_mch_birth3 SET birth_macerated_fetus = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 2),'CIEL','135437',@locale);

DROP TEMPORARY TABLE IF EXISTS temp_mch_birth4;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_mch_birth4(
patient_id INT,
mother_emr_id VARCHAR(25),
encounter_id INT,
encounter_date DATE,
birth_number INT,
multiples INT,
birth_apgar VARCHAR(255),
birth_outcome VARCHAR(255),
birth_weight DOUBLE,
birth_neonatal_resuscitation VARCHAR(255),
birth_macerated_fetus VARCHAR(255)
);

INSERT INTO temp_mch_birth4(patient_id, encounter_id, encounter_date)
SELECT patient_id, encounter_id, encounter_date FROM temp_mch_birth;
UPDATE temp_mch_birth4 SET birth_number = 4;
UPDATE temp_mch_birth4 SET birth_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 3),'CIEL','161033',@locale);
UPDATE temp_mch_birth4 SET birth_weight = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(encounter_id,'CIEL','1585', 3),'CIEL','5916');
UPDATE temp_mch_birth4 SET birth_apgar = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(encounter_id,'CIEL','1585', 3),'CIEL','1504');
UPDATE temp_mch_birth4 SET birth_neonatal_resuscitation = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 3),'CIEL','162131',@locale);
UPDATE temp_mch_birth4 SET birth_macerated_fetus = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id,'CIEL','1585', 3),'CIEL','135437',@locale);

DROP TEMPORARY TABLE IF EXISTS temp_mch_birth_stage;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_mch_birth_stage AS
SELECT * FROM temp_mch_birth1 WHERE birth_outcome IS NOT NULL
UNION ALL
SELECT * FROM temp_mch_birth2 WHERE birth_outcome IS NOT NULL
UNION ALL
SELECT * FROM temp_mch_birth3 WHERE birth_outcome IS NOT NULL
UNION ALL
SELECT * FROM temp_mch_birth4 WHERE birth_outcome IS NOT NULL;

DROP TEMPORARY TABLE IF EXISTS temp_mch_birth_final;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_mch_birth_final AS
SELECT * FROM temp_mch_birth_stage;

UPDATE temp_mch_birth_final SET mother_emr_id = ZLEMR(patient_id);
UPDATE temp_mch_birth_final tf SET multiples = (SELECT COUNT(patient_id) FROM temp_mch_birth_stage ts WHERE tf.encounter_id = ts.encounter_id GROUP BY ts.encounter_id);

SELECT
patient_id,
mother_emr_id,
encounter_date,
birth_number,
multiples,
birth_apgar,
birth_outcome,
birth_weight,
birth_neonatal_resuscitation,
birth_macerated_fetus
FROM temp_mch_birth_final ORDER BY patient_id, encounter_id;