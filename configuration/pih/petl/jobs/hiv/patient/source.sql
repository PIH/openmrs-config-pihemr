SET sql_safe_updates = 0;

DROP TABLE IF EXISTS temp_patient;

CREATE TABLE temp_patient
(
    patient_id                  INT(11),
    given_name                  VARCHAR(50),
    family_name                 VARCHAR(50),
    gender                      VARCHAR(50),
    birthdate                   DATE,
    cause_of_death              VARCHAR(255),
    cause_of_death_non_coded    VARCHAR(255)
);

INSERT INTO temp_patient (patient_id)
SELECT patient_id FROM patient WHERE voided=0;

## Delete test patients
DELETE FROM temp_patient WHERE
patient_id IN (
               SELECT
                      a.person_id
                      FROM person_attribute a
                      INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
                      AND a.value = 'true' AND t.name = 'Test Patient'
               );

UPDATE temp_patient
SET gender = GENDER(patient_id),
    birthdate = BIRTHDATE(patient_id),
    given_name = PERSON_GIVEN_NAME(patient_id),
    family_name = PERSON_FAMILY_NAME(patient_id);

# Cause of death
UPDATE temp_patient tp INNER JOIN person p ON tp.patient_id = p.person_id and p.dead = concept_from_mapping("PIH","YES")
SET tp.cause_of_death = concept_from_mapping(p.cause_of_death, 'en');

# Cause of death non coded
UPDATE temp_patient tp INNER JOIN person p ON tp.patient_id = p.person_id and p.dead = concept_from_mapping("PIH","YES")
SET tp.cause_of_death_non_coded = concept_from_mapping(p.cause_of_death_non_coded, 'en');

### Final Query
SELECT * FROM temp_patient;