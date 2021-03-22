SET sql_safe_updates = 0;
SET @mch_encounter = (SELECT encounter_type_id FROM encounter_type WHERE uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d');
SET @pregnancy_id:=0;

DROP TEMPORARY TABLE IF EXISTS temp_mch_pregancy;
CREATE TEMPORARY TABLE temp_mch_pregancy(
pregnancy_id                    INT,
encounter_id                    INT,
patient_id                      INT,
emr_id                          VARCHAR(25),
encounter_date                  DATE,
gravidity                       INT,
parity                          INT,
num_abortions                   INT,
num_living_children             INT,
last_period_date                DATE,
expected_delivery_date          DATE,
calculated_gestational_age      DOUBLE,
pregnancy_1_birth_order         INT,
pregnancy_1_delivery_type       VARCHAR(150),
pregnancy_1_outcome             TEXT,
pregnancy_2_birth_order         INT,
pregnancy_2_delivery_type       VARCHAR(150),
pregnancy_2_outcome             TEXT,
pregnancy_3_birth_order         INT,
pregnancy_3_delivery_type       VARCHAR(150),
pregnancy_3_outcome             TEXT,
pregnancy_4_birth_order         INT,
pregnancy_4_delivery_type       VARCHAR(150),
pregnancy_4_outcome             TEXT,
pregnancy_5_birth_order         INT,
pregnancy_5_delivery_type       VARCHAR(150),
pregnancy_5_outcome             TEXT,
pregnancy_6_birth_order         INT,
pregnancy_6_delivery_type       VARCHAR(150),
pregnancy_6_outcome             TEXT,
pregnancy_7_birth_order         INT,
pregnancy_7_delivery_type       VARCHAR(150),
pregnancy_7_outcome             TEXT,
pregnancy_8_birth_order         INT,
pregnancy_8_delivery_type       VARCHAR(150),
pregnancy_8_outcome             TEXT,
pregnancy_9_birth_order         INT,
pregnancy_9_delivery_type       VARCHAR(150),
pregnancy_9_outcome             TEXT,
pregnancy_10_birth_order        INT,
pregnancy_10_delivery_type      VARCHAR(150),
pregnancy_10_outcome            TEXT,
pmtct_club                      VARCHAR(5),
delivery_location_plan          VARCHAR(15)
);

## return latest encounters for antenatal visit
INSERT INTO temp_mch_pregancy (encounter_id, patient_id, emr_id, pregnancy_id)
SELECT encounter_id, person_id, ZLEMR(person_id), @pregnancy_id:=@pregnancy_id + 1 AS pregnacy_id FROM obs o WHERE o.concept_id = 
CONCEPT_FROM_MAPPING('PIH', 'Type of HUM visit') AND o.voided = 0
AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'ANC VISIT') AND o.encounter_id IN 
(SELECT MAX(encounter_id) FROM encounter WHERE encounter_type = @mch_encounter AND 
voided = 0 GROUP BY patient_id);

UPDATE temp_mch_pregancy t SET encounter_date = ENCOUNTER_DATE(t.encounter_id);

UPDATE temp_mch_pregancy t SET gravidity = OBS_VALUE_NUMERIC(encounter_id, 'PIH', 'GRAVIDITY'); 

UPDATE temp_mch_pregancy t SET parity = OBS_VALUE_NUMERIC(encounter_id, 'PIH', 'PARITY'); 

UPDATE temp_mch_pregancy t SET num_abortions = OBS_VALUE_NUMERIC(encounter_id, 'PIH', 'NUMBER OF ABORTIONS');  

UPDATE temp_mch_pregancy t SET num_living_children = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1825'); 

UPDATE temp_mch_pregancy t SET last_period_date = OBS_VALUE_DATETIME(encounter_id, 'PIH', 'DATE OF LAST MENSTRUAL PERIOD'); 

UPDATE temp_mch_pregancy t SET expected_delivery_date = OBS_VALUE_DATETIME(encounter_id, 'PIH', 'ESTIMATED DATE OF CONFINEMENT');

UPDATE temp_mch_pregancy t SET calculated_gestational_age = ROUND(DATEDIFF(t.encounter_date, t.last_period_date)/7, 0);

-- update temp_mch_pregancy t set calculated_expected_delivery_date =  DATE_ADD(t.last_period_date, INTERVAL 280 DAY);

# Pregnancy history construct
UPDATE temp_mch_pregancy t SET pregnancy_1_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',0),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_1_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',0),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_1_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',0),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_2_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',1),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_2_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',1),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_2_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',1),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_3_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',2),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_3_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',2),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_3_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',2),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_4_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',3),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_4_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',3),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_4_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',3),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_5_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',4),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_5_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',4),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_5_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',4),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_6_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',5),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_6_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',5),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_6_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',5),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_7_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',6),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_7_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',6),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_7_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',6),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_8_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',7),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_8_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',7),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_8_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',7),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_9_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',8),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_9_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',8),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_9_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',8),'CIEL','161033', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_10_birth_order = OBS_FROM_GROUP_ID_VALUE_NUMERIC(OBS_ID(t.encounter_id,'CIEL','163588',9),'CIEL','163460');
UPDATE temp_mch_pregancy t SET pregnancy_10_delivery_type = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',9),'PIH','11663', 'en');
UPDATE temp_mch_pregancy t SET pregnancy_10_outcome = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(t.encounter_id,'CIEL','163588',9),'CIEL','161033', 'en');

UPDATE temp_mch_pregancy t SET pmtct_club = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', '13262', 'en');
UPDATE temp_mch_pregancy t SET  delivery_location_plan = OBS_VALUE_CODED_LIST(t.encounter_id, 'CIEL', '159758', 'en');

SELECT * FROM temp_mch_pregancy;