SET sql_safe_updates = 0;
SET @mch_patient_program_id = (SELECT program_id FROM program WHERE uuid = '41a2715e-8a14-11e8-9a94-a6cf71072f73');
SET @mch_encounter = (SELECT encounter_type_id FROM encounter_type WHERE uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d');
SET @delivery = (SELECT encounter_type_id FROM encounter_type WHERE uuid = '00e5ebb2-90ec-11e8-9eb6-529269fb1459');

DROP TEMPORARY TABLE IF EXISTS temp_od_encounters;
CREATE TEMPORARY TABLE temp_od_encounters
(
patient_id                      INT(11),
first_encounter_date            DATETIME,
last_encounter_date             DATETIME,
first_encounter_id              INT(11),
last_encounter_id               INT,
mch_emr_id                      VARCHAR(15),
initial_enrollment_location     VARCHAR(150),
latest_enrollment_location      VARCHAR(150),
initial_encounter_type_name     VARCHAR(150),
encounter_type_name             VARCHAR(150),
estimated_delivery_date         DATE,
pregnant                        BIT,
antenatal_visit                 BIT,
program_treatment_type          VARCHAR(255)
);

INSERT INTO temp_od_encounters(patient_id, last_encounter_date, mch_emr_id)
SELECT patient_id,  MAX(encounter_datetime), ZLEMR(e.patient_id)
FROM encounter e WHERE e.voided = 0 AND e.encounter_type IN (@mch_encounter, @delivery) GROUP BY e.patient_id;

UPDATE temp_od_encounters t JOIN encounter e ON t.patient_id = e.patient_id AND last_encounter_date = e.encounter_datetime AND e.encounter_type IN (@mch_encounter, @delivery) AND e.voided = 0
SET t.last_encounter_id = e.encounter_id;

UPDATE temp_od_encounters t JOIN encounter e ON t.last_encounter_id = e.encounter_id AND e.voided = 0
SET t.latest_enrollment_location  = LOCATION_NAME(e.location_id);
    
UPDATE temp_od_encounters t
SET t.encounter_type_name = ENCOUNTER_TYPE_NAME(last_encounter_id);

UPDATE temp_od_encounters te JOIN obs o ON te.last_encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Type of HUM visit')
AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'ANC VISIT') AND o.voided = 0
SET antenatal_visit = 1; -- yes

-- estimated_delivery_date
UPDATE temp_od_encounters te JOIN obs o ON te.last_encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'ESTIMATED DATE OF CONFINEMENT') AND o.voided = 0
SET estimated_delivery_date = DATE(value_datetime);

-- this doesnot put into acount if the last visit date was more than
-- 9 months ago.
-- pregnant
UPDATE temp_od_encounters tv SET tv.pregnant = IF(tv.antenatal_visit IS NULL, NULL, 1);

-- first encounter
UPDATE temp_od_encounters t SET first_encounter_date = (SELECT MIN(e.encounter_datetime) FROM encounter e WHERE t.patient_id = e.patient_id AND e.voided = 0 
AND encounter_type IN (@mch_encounter, @delivery) GROUP BY e.patient_id);

UPDATE temp_od_encounters t JOIN encounter e ON t.patient_id = e.patient_id AND first_encounter_date = e.encounter_datetime AND e.encounter_type IN (@mch_encounter, @delivery) AND e.voided = 0
SET t.first_encounter_id = e.encounter_id;

UPDATE temp_od_encounters t SET initial_enrollment_location = (SELECT LOCATION_NAME(location_id) FROM encounter e WHERE t.first_encounter_id = e.encounter_id AND e.voided = 0);

UPDATE temp_od_encounters t
SET t.initial_encounter_type_name = ENCOUNTER_TYPE_NAME(first_encounter_id);

## program
DROP TEMPORARY TABLE IF EXISTS temp_mch_prg;
CREATE TEMPORARY TABLE temp_mch_prg
(
patient_id                      INT(11),
first_encounter_date            DATETIME,
last_encounter_date             DATETIME,
first_encounter_id              INT(11),
last_encounter_id               INT,
mch_emr_id                      VARCHAR(15),
initial_enrollment_location     VARCHAR(150),
latest_enrollment_location      VARCHAR(150),
initial_encounter_type_name     VARCHAR(150),
encounter_type_name             VARCHAR(150),
estimated_delivery_date         DATE,
pregnant                        BIT,
antenatal_visit                 BIT,
program_treatment_type          VARCHAR(255)
);

# patient in the mch program who may not have obgyn filled
INSERT INTO temp_mch_prg(patient_id, initial_enrollment_location)
SELECT DISTINCT(patient_id), LOCATION_NAME(location_id) FROM patient_program WHERE program_id =  @mch_patient_program_id AND date_completed IS NULL AND patient_id NOT IN (
SELECT patient_id FROM temp_od_encounters);

UPDATE temp_mch_prg  SET mch_emr_id = ZLEMR(patient_id);

# combine the above 2 temp tables
DROP TEMPORARY TABLE IF EXISTS temp_final_mch;
CREATE TEMPORARY TABLE temp_final_mch
AS
SELECT * FROM temp_mch_prg
UNION ALL
SELECT * FROM temp_od_encounters;

## patient
DROP TEMPORARY TABLE IF EXISTS temp_mch_patient;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_mch_patient
(
    patient_id                  INT(11),
    patient_program_id          INT(11),
    last_encounter_id           INT(11),
    mch_emr_id                  VARCHAR(15),
    given_name                  VARCHAR(50),
    initial_encounter_type_name VARCHAR(150),
    encounter_type_name         VARCHAR(150),
    family_name                 VARCHAR(50),
    nick_name                   VARCHAR(50),
    gender                      VARCHAR(2),
    birthdate                   DATE,
    birthdate_estimated         BIT,
    marital_status              VARCHAR(50),
    locality                    VARCHAR(100),
    age                         DOUBLE,
    age_cat_1                   VARCHAR(10),
    age_cat_2                   VARCHAR(10),
    antenatal_visit             BIT,
    estimated_delivery_date     DATE,
    pregnant                    BIT,
    initial_enrollment_location VARCHAR(150),
    latest_enrollment_location  VARCHAR(255),
    first_encounter_date        DATETIME,
    latest_encounter_date       DATETIME
);

INSERT INTO temp_mch_patient(patient_id, mch_emr_id, last_encounter_id, initial_enrollment_location, latest_enrollment_location, initial_encounter_type_name, encounter_type_name, 
first_encounter_date, latest_encounter_date, estimated_delivery_date, antenatal_visit, pregnant)
SELECT patient_id, mch_emr_id, last_encounter_id, initial_enrollment_location, latest_enrollment_location, initial_encounter_type_name, encounter_type_name, 
first_encounter_date, last_encounter_date, estimated_delivery_date, antenatal_visit, pregnant
FROM temp_final_mch;

## Delete test patients
DELETE FROM temp_mch_patient WHERE
patient_id IN (
               SELECT
                      a.person_id
                      FROM person_attribute a
                      INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
                      AND a.value = 'true' AND t.name = 'Test Patient'
               );

UPDATE temp_mch_patient tm JOIN current_name_address c ON person_id = patient_id
SET tm.family_name = c.family_name,
	tm.given_name = c.given_name,
	tm.nick_name = c.nick_name,
    tm.gender = c.gender,
    tm.birthdate = c.birthdate,
    tm.birthdate_estimated = c.birthdate_estimated,
    tm.age = TIMESTAMPDIFF(YEAR,c.birthdate, NOW());
    
# civil status
UPDATE temp_mch_patient tm JOIN obs o ON person_id = patient_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'CIVIL STATUS')
SET marital_status = CONCEPT_NAME(value_coded, 'en');

# locality
UPDATE temp_mch_patient tm JOIN person_address o ON person_id = patient_id
SET locality = address1;

## age category
UPDATE temp_mch_patient tm SET age_cat_1 =  CASE WHEN tm.age < 10 THEN "Group 1"
                                                    WHEN tm.age BETWEEN 10 AND 14 THEN "Group 2"
                                                    WHEN tm.age BETWEEN 15 AND 19 THEN "Group 3"
                                                    WHEN tm.age BETWEEN 20 AND 24 THEN "Group 4"
                                                    WHEN tm.age BETWEEN 25 AND 29 THEN "Group 5"
                                                    WHEN tm.age BETWEEN 30 AND 34 THEN "Group 6"
                                                    WHEN tm.age BETWEEN 35 AND 39 THEN "Group 7"
                                                    WHEN tm.age BETWEEN 40 AND 44 THEN "Group 8"
                                                    WHEN tm.age BETWEEN 45 AND 49 THEN "Group 9"
                                                    WHEN tm.age > 49 THEN "Group 10"
                                                    WHEN tm.age IS NULL THEN "Group 10"
                                                    END;
                                                    
### Final query
SELECT
    patient_id,
    mch_emr_id                      pih_emr_id,
    initial_encounter_type_name     first_encounter_type,
    encounter_type_name             last_encounter_type,
    first_encounter_date,
    latest_encounter_date,
    initial_enrollment_location     initial_health_center,
    latest_enrollment_location      current_reporting_health_center,
    given_name                      first_name,
    family_name                     last_name,
    nick_name                       nickname,
    marital_status,
    gender,
    birthdate                       dob,
    IF(birthdate IS NULL, 1, NULL)  age_unknown,
    age,
    age_cat_1,
    locality,
    antenatal_visit,
    estimated_delivery_date,
    pregnant
FROM temp_mch_patient;