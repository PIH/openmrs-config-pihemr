SET sql_safe_updates = 0;
SET @mch_patient_program_id = (SELECT program_id FROM program WHERE uuid = '41a2715e-8a14-11e8-9a94-a6cf71072f73');
SET @mch_encounter = (SELECT encounter_type_id FROM encounter_type WHERE uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d');
SET @delivery = (SELECT encounter_type_id FROM encounter_type WHERE uuid = '00e5ebb2-90ec-11e8-9eb6-529269fb1459');


DROP TEMPORARY TABLE IF EXISTS temp_od_encounters;
CREATE TEMPORARY TABLE temp_od_encounters
(
patient_id              INT(11),
patient_program_id      INT(11),
mch_emr_id              VARCHAR(15),
enrollment_location     VARCHAR(255)
);

INSERT INTO temp_od_encounters(patient_id, enrollment_location)
SELECT DISTINCT(patient_id), LOCATION_NAME(location_id)
FROM encounter WHERE voided = 0 AND encounter_type IN (@mch_encounter, @delivery);

UPDATE temp_od_encounters SET mch_emr_id = ZLEMR(patient_id);
#update temp_od_encounters set enrollment_location = LOCATION_NAME(location_id);

DROP TEMPORARY TABLE IF EXISTS temp_mch_prg;
CREATE TEMPORARY TABLE temp_mch_prg
(
patient_id              INT(11),
patient_program_id      INT(11),
mch_emr_id              VARCHAR(15),
enrollment_location     VARCHAR(255)
);

# patient in the mch program who may not have obgyn filled
INSERT INTO temp_mch_prg(patient_id, enrollment_location)
SELECT DISTINCT(patient_id), LOCATION_NAME(location_id) FROM patient_program WHERE program_id =  @mch_patient_program_id AND patient_id NOT IN (
SELECT patient_id FROM temp_od_encounters);

UPDATE temp_mch_prg SET mch_emr_id = ZLEMR(patient_id);
#update temp_mch_prg set enrollment_location = LOCATION_NAME(location_id);

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
    patient_id              INT(11),
    patient_program_id      INT(11),
    mch_emr_id              VARCHAR(15),
    given_name              VARCHAR(50),
    family_name             VARCHAR(50),
    nick_name               VARCHAR(50),
    gender                  VARCHAR(2),
    birthdate               DATE,
    birthdate_estimated     BIT,
    marital_status          VARCHAR(50),
    locality                VARCHAR(100),
    age                     DOUBLE,
    age_cat_1               VARCHAR(10),
    age_cat_2               VARCHAR(10),
    antenatal_visit         BIT,
    estimated_delivery_date DATE,
    pregnant                BIT,
    enrollment_location     VARCHAR(255),
    encounter_location_name VARCHAR(255),
    latest_encounter_date 	DATE
);

INSERT INTO temp_mch_patient(patient_id, mch_emr_id, enrollment_location)
SELECT patient_id, mch_emr_id, enrollment_location FROM temp_final_mch;

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

# pregnancy
DROP TEMPORARY TABLE IF EXISTS temp_mch_pregnacy;
CREATE TEMPORARY TABLE IF NOT EXISTS temp_mch_pregnacy
(
    encounter_id            INT,
    patient_id              INT,
    encounter_date          DATE,
    antenatal_visit         BIT,
    estimated_delivery_date DATE,
    encounter_location_name VARCHAR(255)
);

INSERT INTO temp_mch_pregnacy(encounter_id, patient_id)
SELECT MAX(encounter_id), person_id FROM obs WHERE voided = 0 AND encounter_id IN (SELECT encounter_id FROM 
encounter WHERE encounter_type = @mch_encounter) GROUP BY person_id;

UPDATE temp_mch_pregnacy t JOIN encounter e ON t.encounter_id = e.encounter_id AND e.voided = 0
SET t.encounter_date = DATE(e.encounter_datetime);

UPDATE temp_mch_pregnacy te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Type of HUM visit')
AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'ANC VISIT') AND o.voided = 0
SET antenatal_visit = 1; -- yes

-- estimated_delivery_date
UPDATE temp_mch_pregnacy te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'ESTIMATED DATE OF CONFINEMENT') AND o.voided = 0
SET estimated_delivery_date = DATE(value_datetime);

UPDATE temp_mch_patient tv JOIN temp_mch_pregnacy t ON t.patient_id = tv.patient_id
SET tv.antenatal_visit = t.antenatal_visit,
	tv.estimated_delivery_date = t.estimated_delivery_date,
	tv.pregnant = IF(t.antenatal_visit IS NULL, 0, 1),
	tv.latest_encounter_date = t.encounter_date;

-- encounter_location_name
UPDATE temp_mch_pregnacy te JOIN encounter e ON te.encounter_id = e.encounter_id
SET te.encounter_location_name = ENCOUNTER_LOCATION_NAME(e.encounter_id);

UPDATE temp_mch_patient tv JOIN temp_mch_pregnacy t ON t.patient_id = tv.patient_id
SET tv.encounter_location_name = t.encounter_location_name;

### Final query
SELECT
    patient_id,
    mch_emr_id                  pih_emr_id,
    given_name 					first_name,
    family_name 				last_name,
    nick_name 					nickname,
    gender,
    IF(birthdate IS NULL, 1, NULL) age_unknown,
    birthdate 					dob,
    age,
    encounter_location_name     current_reporting_health_center,
    enrollment_location 		initital_health_center,
    locality,
    marital_status,
    age_cat_1,
    latest_encounter_date,
    IF(antenatal_visit IS NULL, 0, 1),
    estimated_delivery_date,
    pregnant
FROM temp_mch_patient;