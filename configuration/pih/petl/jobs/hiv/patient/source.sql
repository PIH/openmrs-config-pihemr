SET sql_safe_updates = 0;

DROP TABLE IF EXISTS temp_patient;

CREATE TABLE temp_patient
(
    patient_id                  INT(11),
    given_name                  VARCHAR(50),
    family_name                 VARCHAR(50),
    gender                      VARCHAR(50),
    birthdate                   DATE,
    dead                        VARCHAR(1),
    death_date                  DATE,
    cause_of_death              VARCHAR(255),
    cause_of_death_non_coded    VARCHAR(255),
    patient_msm                 VARCHAR(11),
    patient_sw                  VARCHAR(11),
    patient_pris                VARCHAR(11),
    patient_trans               VARCHAR(11),
    patient_idu                 VARCHAR(11)
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

# key populations
DROP TEMPORARY TABLE IF EXISTS temp_key_popn_encounter;
CREATE TEMPORARY TABLE temp_key_popn_encounter
(
patient_id      INT,
encounter_id    INT,
encounter_date  DATE,
concept_id      INT,
value_coded     INT
);

INSERT INTO  temp_key_popn_encounter (patient_id, encounter_id, encounter_date, concept_id, value_coded)
SELECT patient_id, e.encounter_id, DATE(encounter_datetime), concept_id, value_coded
FROM encounter e
INNER JOIN obs o
	ON e.voided = 0
	AND o.voided = 0
	AND encounter_type = ENCOUNTER_TYPE('ZL VIH Données de Base')
    AND o.concept_id IN (concept_from_mapping("CIEL", "160578"), concept_from_mapping("CIEL","160579"), concept_from_mapping("CIEL","156761"), concept_from_mapping("PIH","11561"), concept_from_mapping("CIEL","105"))
	AND e.encounter_id = o.encounter_id;

## create a staging table to hold the maximum encounter_dates per patient
##
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_msm;
CREATE TEMPORARY TABLE temp_stage_key_popn_msm
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_msm     VARCHAR(11)
);

INSERT INTO temp_stage_key_popn_msm(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id from temp_key_popn_encounter WHERE concept_id = concept_from_mapping("CIEL", "160578") group by patient_id;

UPDATE temp_stage_key_popn_msm msm INNER JOIN temp_key_popn_encounter tkpe ON msm.patient_id = tkpe.patient_id AND msm.encounter_date = tkpe.encounter_date AND tkpe.concept_id = concept_from_mapping("CIEL", "160578")
SET patient_msm = concept_name(value_coded, 'en');

##
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_sw;
CREATE TEMPORARY TABLE temp_stage_key_popn_sw
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_sw      VARCHAR(11)
);

INSERT INTO temp_stage_key_popn_sw(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id from temp_key_popn_encounter WHERE concept_id = concept_from_mapping("CIEL","160579") group by patient_id;

UPDATE temp_stage_key_popn_sw sw INNER JOIN temp_key_popn_encounter tkpe ON sw.patient_id = tkpe.patient_id AND sw.encounter_date = tkpe.encounter_date AND tkpe.concept_id = concept_from_mapping("CIEL","160579")
SET patient_sw = concept_name(value_coded, 'en');

##
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_pris;
CREATE TEMPORARY TABLE temp_stage_key_popn_pris
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_pris    VARCHAR(11)
);

INSERT INTO temp_stage_key_popn_pris(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id from temp_key_popn_encounter WHERE concept_id = concept_from_mapping("CIEL","156761") group by patient_id;

UPDATE temp_stage_key_popn_pris pris INNER JOIN temp_key_popn_encounter tkpe ON pris.patient_id = tkpe.patient_id AND pris.encounter_date = tkpe.encounter_date AND tkpe.concept_id = concept_from_mapping("CIEL","156761")
SET patient_pris = concept_name(value_coded, 'en');

####
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_trans;
CREATE TEMPORARY TABLE temp_stage_key_popn_trans
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_trans   VARCHAR(11)
);

INSERT INTO temp_stage_key_popn_trans(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id from temp_key_popn_encounter WHERE concept_id = concept_from_mapping("PIH","11561") group by patient_id;

UPDATE temp_stage_key_popn_trans trans INNER JOIN temp_key_popn_encounter tkpe ON trans.patient_id = tkpe.patient_id AND trans.encounter_date = tkpe.encounter_date AND tkpe.concept_id = concept_from_mapping("PIH","11561")
SET patient_trans = concept_name(value_coded, 'en');

###
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_iv;
CREATE TEMPORARY TABLE temp_stage_key_popn_iv
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_idu     VARCHAR(11)
);

INSERT INTO temp_stage_key_popn_iv(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id from temp_key_popn_encounter WHERE concept_id = concept_from_mapping("CIEL", "105") group by patient_id;

UPDATE temp_stage_key_popn_iv iv INNER JOIN temp_key_popn_encounter tkpe ON iv.patient_id = tkpe.patient_id AND iv.encounter_date = tkpe.encounter_date AND tkpe.concept_id = concept_from_mapping("CIEL", "105")
SET patient_idu = concept_name(value_coded, 'en');

## key population final table with the latest data
DROP TEMPORARY TABLE IF EXISTS temp_key_popn;
CREATE TEMPORARY TABLE temp_key_popn(
    patient_id      INT,
    patient_msm     VARCHAR(11),
    patient_sw      VARCHAR(11),
    patient_pris    VARCHAR(11),
    patient_trans   VARCHAR(11),
    patient_idu     VARCHAR(11)
);

INSERT INTO temp_key_popn (patient_id , patient_msm, patient_sw, patient_pris, patient_trans, patient_idu )
SELECT DISTINCT(tkpe.patient_id), patient_msm, patient_sw, patient_pris, patient_trans, patient_idu
FROM temp_key_popn_encounter tkpe
LEFT JOIN temp_stage_key_popn_msm 	msm ON tkpe.patient_id = msm.patient_id
LEFT JOIN temp_stage_key_popn_sw 	sw ON tkpe.patient_id = sw.patient_id
LEFT JOIN temp_stage_key_popn_pris 	pris ON tkpe.patient_id = pris.patient_id
LEFT JOIN temp_stage_key_popn_trans trans ON tkpe.patient_id = trans.patient_id
LEFT JOIN temp_stage_key_popn_iv iv ON tkpe.patient_id = iv.patient_id;

UPDATE temp_patient tp INNER JOIN temp_key_popn tkp ON tp.patient_id = tkp.patient_id
SET tp.patient_msm = tkp.patient_msm,
	tp.patient_sw = tkp.patient_sw,
	tp.patient_pris = tkp.patient_pris,
	tp.patient_trans = tkp.patient_trans,
	tp.patient_idu = tkp.patient_idu;

# Dead
UPDATE temp_patient tp INNER JOIN person p ON tp.patient_id = p.person_id
SET tp.dead = IF(p.dead = 1, "Y", NULL);

# Date of death
UPDATE temp_patient tp INNER JOIN person p ON tp.patient_id = p.person_id AND p.dead = 1
SET tp.death_date = DATE(p.death_date);

# Cause of death
UPDATE temp_patient tp INNER JOIN person p ON tp.patient_id = p.person_id and p.dead = 1
SET tp.cause_of_death = concept_name(p.cause_of_death, 'en');

# Cause of death non coded
UPDATE temp_patient tp INNER JOIN person p ON tp.patient_id = p.person_id and p.dead = 1
SET tp.cause_of_death_non_coded = p.cause_of_death_non_coded;

### Final Query
SELECT * FROM temp_patient;