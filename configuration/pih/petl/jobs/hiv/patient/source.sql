SET sql_safe_updates = 0;

SELECT patient_identifier_type_id INTO @zl_emr_id FROM patient_identifier_type WHERE uuid = 'a541af1e-105c-40bf-b345-ba1fd6a59b85';
SELECT patient_identifier_type_id INTO @dossier FROM patient_identifier_type WHERE uuid = 'e66645eb-03a8-4991-b4ce-e87318e37566';
SELECT patient_identifier_type_id INTO @hiv_id FROM patient_identifier_type WHERE uuid = '139766e8-15f5-102d-96e4-000c29c2a5d7';

SET @ovc_baseline_encounter_type = ENCOUNTER_TYPE('OVC Intake');
SET @socio_economics_encounter_type = ENCOUNTER_TYPE('Socio-economics');
SET @hiv_initial_encounter_type = ENCOUNTER_TYPE('HIV Intake');
SET @hiv_followup_encounter_type = ENCOUNTER_TYPE('HIV Followup');
SET @hiv_dispensing_encounter = ENCOUNTER_TYPE('HIV drug dispensing');
SET @mothers_first_name = (SELECT person_attribute_type_id FROM person_attribute_type p WHERE p.name = 'First Name of Mother');
SET @telephone_number = (SELECT person_attribute_type_id FROM person_attribute_type p WHERE p.name = 'Telephone Number');

DROP TABLE IF EXISTS temp_patient;
CREATE TABLE temp_patient
(
    patient_id                  INT(11),
    zl_emr_id                   VARCHAR(255),
    hivemr_v1_id                VARCHAR(255),
    hiv_dossier_id              VARCHAR(255),
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
    patient_idu                 VARCHAR(11),
    parent_firstname            VARCHAR(255),
    parent_lastname             VARCHAR(255),
    parent_relationship         VARCHAR(50),
    marital_status              VARCHAR(60),
    occupation                  VARCHAR(100),
    mothers_first_name          VARCHAR(50),
    telephone_number            VARCHAR(100),
    address                     TEXT,
    department                  VARCHAR(100),
    commune                     VARCHAR(100),
    section_communal            VARCHAR(100),
    locality                    VARCHAR(100),
    street_landmark             TEXT,
    age                         DOUBLE
);

CREATE INDEX temp_patient_patient_id ON temp_patient (patient_id);

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

-- ZL EMR ID
UPDATE temp_patient t
INNER JOIN
   (SELECT patient_id, GROUP_CONCAT(identifier) 'ids'
    FROM patient_identifier pid
    WHERE pid.voided = 0
    AND pid.identifier_type = @zl_emr_id
    GROUP BY patient_id
   ) ids ON ids.patient_id = t.patient_id
SET t.zl_emr_id = ids.ids;    

-- HIV EMR V1
UPDATE temp_patient t
INNER JOIN
   (SELECT patient_id, GROUP_CONCAT(identifier) 'ids'
    FROM patient_identifier pid
    WHERE pid.voided = 0
    AND pid.identifier_type = @hiv_id
    GROUP BY patient_id
   ) ids ON ids.patient_id = t.patient_id
SET t.hivemr_v1_id = ids.ids;    

-- DOSSIER ID
UPDATE temp_patient t
INNER JOIN
   (SELECT patient_id, GROUP_CONCAT(identifier) 'ids'
    FROM patient_identifier pid
    WHERE pid.voided = 0
    AND pid.identifier_type = @dossier
    GROUP BY patient_id
   ) ids ON ids.patient_id = t.patient_id
SET t.hiv_dossier_id = ids.ids;    

UPDATE temp_patient
SET gender = GENDER(patient_id),
    birthdate = BIRTHDATE(patient_id),
    given_name = PERSON_GIVEN_NAME(patient_id),
    family_name = PERSON_FAMILY_NAME(patient_id);

UPDATE temp_patient t JOIN current_name_address c ON c.person_id = t.patient_id
SET 
t.department = c.department,
t.commune = c.commune,
t.section_communal = c.section_communal,
t.locality = c.locality,
t.street_landmark = c.street_landmark,
t.age = CAST(CONCAT(TIMESTAMPDIFF(YEAR, c.birthdate, NOW()), '.', MOD(TIMESTAMPDIFF(MONTH, c.birthdate, NOW()), 12) ) AS CHAR);

UPDATE temp_patient t JOIN obs m ON t.patient_id = m.person_id AND 
m.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING('PIH','CIVIL STATUS')
SET marital_status = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_patient t JOIN obs m ON t.patient_id = m.person_id AND 
m.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING('PIH','Occupation')
SET occupation = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_patient t JOIN person_attribute m ON t.patient_id = m.person_id AND 
m.voided = 0 AND  m.person_attribute_type_id = @mothers_first_name
SET mothers_first_name = m.value;

UPDATE temp_patient t JOIN person_attribute m ON t.patient_id = m.person_id AND 
m.voided = 0 AND  m.person_attribute_type_id = @telephone_number
SET telephone_number = m.value;

UPDATE temp_patient t JOIN person_address m ON t.patient_id = m.person_id AND 
m.voided = 0
SET address = address2;

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

CREATE INDEX temp_key_popn_encounter_patient_id ON temp_key_popn_encounter (patient_id);
CREATE INDEX temp_key_popn_encounter_encounter_id ON temp_key_popn_encounter (encounter_id);
CREATE INDEX temp_key_popn_encounter_concept_id ON temp_key_popn_encounter (concept_id);
CREATE INDEX temp_key_popn_encounter_value_coded ON temp_key_popn_encounter (value_coded);

INSERT INTO  temp_key_popn_encounter (patient_id, encounter_id, encounter_date, concept_id, value_coded)
SELECT patient_id, e.encounter_id, DATE(encounter_datetime), concept_id, value_coded
FROM encounter e
INNER JOIN obs o
	ON e.voided = 0
	AND o.voided = 0
	AND encounter_type = ENCOUNTER_TYPE('HIV Intake')
    AND o.concept_id IN (CONCEPT_FROM_MAPPING("CIEL", "160578"), CONCEPT_FROM_MAPPING("CIEL","160579"), CONCEPT_FROM_MAPPING("CIEL","156761"), CONCEPT_FROM_MAPPING("PIH","11561"), CONCEPT_FROM_MAPPING("CIEL","105"))
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

CREATE INDEX temp_stage_key_popn_msm_patient_id ON temp_stage_key_popn_msm (patient_id);
CREATE INDEX temp_stage_key_popn_msm_concept_id ON temp_stage_key_popn_msm (concept_id);

INSERT INTO temp_stage_key_popn_msm(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id FROM temp_key_popn_encounter WHERE concept_id = CONCEPT_FROM_MAPPING("CIEL", "160578") GROUP BY patient_id;

UPDATE temp_stage_key_popn_msm msm INNER JOIN temp_key_popn_encounter tkpe ON msm.patient_id = tkpe.patient_id AND msm.encounter_date = tkpe.encounter_date AND tkpe.concept_id = CONCEPT_FROM_MAPPING("CIEL", "160578")
SET patient_msm = CONCEPT_NAME(value_coded, 'en');

##
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_sw;
CREATE TEMPORARY TABLE temp_stage_key_popn_sw
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_sw      VARCHAR(11)
);

CREATE INDEX temp_stage_key_popn_sw_patient_id ON temp_stage_key_popn_sw (patient_id);
CREATE INDEX temp_stage_key_popn_sw_concept_id ON temp_stage_key_popn_sw (concept_id);

INSERT INTO temp_stage_key_popn_sw(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id FROM temp_key_popn_encounter WHERE concept_id = CONCEPT_FROM_MAPPING("CIEL","160579") GROUP BY patient_id;

UPDATE temp_stage_key_popn_sw sw INNER JOIN temp_key_popn_encounter tkpe ON sw.patient_id = tkpe.patient_id AND sw.encounter_date = tkpe.encounter_date AND tkpe.concept_id = CONCEPT_FROM_MAPPING("CIEL","160579")
SET patient_sw = CONCEPT_NAME(value_coded, 'en');

##
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_pris;
CREATE TEMPORARY TABLE temp_stage_key_popn_pris
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_pris    VARCHAR(11)
);

CREATE INDEX temp_stage_key_popn_pris_patient_id ON temp_stage_key_popn_pris (patient_id);
CREATE INDEX temp_stage_key_popn_pris_concept_id ON temp_stage_key_popn_pris (concept_id);

INSERT INTO temp_stage_key_popn_pris(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id FROM temp_key_popn_encounter WHERE concept_id = CONCEPT_FROM_MAPPING("CIEL","156761") GROUP BY patient_id;

UPDATE temp_stage_key_popn_pris pris INNER JOIN temp_key_popn_encounter tkpe ON pris.patient_id = tkpe.patient_id AND pris.encounter_date = tkpe.encounter_date AND tkpe.concept_id = CONCEPT_FROM_MAPPING("CIEL","156761")
SET patient_pris = CONCEPT_NAME(value_coded, 'en');

####
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_trans;
CREATE TEMPORARY TABLE temp_stage_key_popn_trans
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_trans   VARCHAR(11)
);

CREATE INDEX temp_stage_key_popn_trans_patient_id ON temp_stage_key_popn_trans (patient_id);
CREATE INDEX temp_stage_key_popn_trans_concept_id ON temp_stage_key_popn_trans (concept_id);

INSERT INTO temp_stage_key_popn_trans(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id FROM temp_key_popn_encounter WHERE concept_id = CONCEPT_FROM_MAPPING("PIH","11561") GROUP BY patient_id;

UPDATE temp_stage_key_popn_trans trans INNER JOIN temp_key_popn_encounter tkpe ON trans.patient_id = tkpe.patient_id AND trans.encounter_date = tkpe.encounter_date AND tkpe.concept_id = CONCEPT_FROM_MAPPING("PIH","11561")
SET patient_trans = CONCEPT_NAME(value_coded, 'en');

###
DROP TEMPORARY TABLE IF EXISTS temp_stage_key_popn_iv;
CREATE TEMPORARY TABLE temp_stage_key_popn_iv
(
patient_id      INT,
encounter_date  DATE,
concept_id      INT,
patient_idu     VARCHAR(11)
);

CREATE INDEX temp_stage_key_popn_iv_patient_id ON temp_stage_key_popn_iv (patient_id);
CREATE INDEX temp_stage_key_popn_iv_concept_id ON temp_stage_key_popn_iv (concept_id);

INSERT INTO temp_stage_key_popn_iv(patient_id, encounter_date, concept_id)
SELECT patient_id, MAX(encounter_date), concept_id FROM temp_key_popn_encounter WHERE concept_id = CONCEPT_FROM_MAPPING("CIEL", "105") GROUP BY patient_id;

UPDATE temp_stage_key_popn_iv iv INNER JOIN temp_key_popn_encounter tkpe ON iv.patient_id = tkpe.patient_id AND iv.encounter_date = tkpe.encounter_date AND tkpe.concept_id = CONCEPT_FROM_MAPPING("CIEL", "105")
SET patient_idu = CONCEPT_NAME(value_coded, 'en');

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

CREATE INDEX temp_key_popn_patient_id ON temp_key_popn (patient_id);
CREATE INDEX temp_key_popn_concept_id ON temp_key_popn (concept_id);

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
UPDATE temp_patient tp INNER JOIN person p ON tp.patient_id = p.person_id AND p.dead = 1
SET tp.cause_of_death = CONCEPT_NAME(p.cause_of_death, 'en');

# Cause of death non coded
UPDATE temp_patient tp INNER JOIN person p ON tp.patient_id = p.person_id AND p.dead = 1
SET tp.cause_of_death_non_coded = p.cause_of_death_non_coded;

### ovc parent
DROP TEMPORARY TABLE IF EXISTS temp_ovc_parent;
CREATE TEMPORARY TABLE temp_ovc_parent(
    patient_id                  INT,
    encounter_id                INT,
    contact_construct_obs_id    INT,
    parent_firstname            VARCHAR(255),
    parent_lastname             VARCHAR(255),
    parent_relationship         VARCHAR(50)
);

CREATE INDEX temp_ovc_parent_patient_id ON temp_ovc_parent (patient_id);
CREATE INDEX temp_ovc_parent_encounter_id ON temp_ovc_parent (encounter_id);

INSERT INTO temp_ovc_parent(patient_id, contact_construct_obs_id) 
SELECT person_id, MAX(obs_id) FROM obs WHERE voided = 0
AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Contact construct') 
AND encounter_id IN (SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type = @ovc_baseline_encounter_type)
GROUP BY person_id;

UPDATE temp_ovc_parent tp JOIN obs o ON obs_id = contact_construct_obs_id
SET tp.encounter_id = o.encounter_id;

UPDATE temp_ovc_parent ovc JOIN obs o ON ovc.encounter_id = o.encounter_id AND o.obs_group_id IN (contact_construct_obs_id) 
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'FIRST NAME')
SET parent_firstname = value_text;

UPDATE temp_ovc_parent ovc JOIN obs o ON ovc.encounter_id = o.encounter_id AND o.obs_group_id IN (contact_construct_obs_id) 
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'LAST NAME')
SET parent_lastname = value_text;

UPDATE temp_ovc_parent ovc JOIN obs o ON ovc.encounter_id = o.encounter_id AND o.obs_group_id IN (contact_construct_obs_id)
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', 'RELATIONSHIP OF RELATIVE TO PATIENT')
SET parent_relationship = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_patient tp JOIN temp_ovc_parent o ON tp.patient_id = o.patient_id
SET
    tp.parent_firstname = o.parent_firstname,
    tp.parent_lastname = o.parent_lastname,
    tp.parent_relationship = o.parent_relationship;

DROP TEMPORARY TABLE IF EXISTS temp_socio_economics;
CREATE TEMPORARY TABLE temp_socio_economics(
	patient_id INT,
	emr_id VARCHAR(50),
	encounter_id INT,
	socio_people_in_house INT,
	socio_rooms_in_house INT,
	socio_roof_type VARCHAR(20),
	socio_floor_type VARCHAR(20),
	socio_has_latrine VARCHAR(20),
	socio_has_radio VARCHAR(20),
	socio_years_of_education VARCHAR(50),
	socio_transport_method VARCHAR(50),
	socio_transport_time VARCHAR(50),
	socio_transport_walking_time VARCHAR(50)
);

CREATE INDEX temp_socio_economics_patient_id ON temp_socio_economics (patient_id);
CREATE INDEX temp_socio_economics_encounter_id ON temp_socio_economics (encounter_id);

-- in cases where there are more than one socio economic form
-- return latest
INSERT INTO temp_socio_economics (patient_id, encounter_id)
SELECT patient_id, MAX(encounter_id) FROM encounter WHERE encounter_id IN
(SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type = @socio_economics_encounter_type) 
AND voided = 0;

UPDATE temp_socio_economics t SET emr_id = PATIENT_IDENTIFIER(patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
UPDATE temp_socio_economics t SET socio_people_in_house = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH', 'NUMBER OF PEOPLE WHO LIVE IN HOUSE INCLUDING PATIENT');
UPDATE temp_socio_economics t SET socio_rooms_in_house = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH', 'NUMBER OF ROOMS IN HOUSE');
UPDATE temp_socio_economics t SET socio_roof_type = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', 'ROOF MATERIAL', 'en');
UPDATE temp_socio_economics t SET socio_floor_type = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', '1315', 'en');
UPDATE temp_socio_economics t SET socio_has_latrine = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', 'Latrine', 'en');
UPDATE temp_socio_economics t SET socio_has_radio = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', '1318', 'en');
UPDATE temp_socio_economics t SET socio_years_of_education = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', 'HIGHEST LEVEL OF SCHOOL COMPLETED', 'en');
UPDATE temp_socio_economics t SET socio_transport_method = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', '975', 'en');
UPDATE temp_socio_economics t SET socio_transport_time = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', 'CLINIC TRAVEL TIME', 'en');

DROP TEMPORARY TABLE IF EXISTS temp_socio_hiv_intake;
CREATE TEMPORARY TABLE temp_socio_hiv_intake(
patient_id INT,
emr_id VARCHAR(50),
encounter_id INT,
socio_smoker VARCHAR(50),
socio_smoker_years DOUBLE,
socio_smoker_cigarette_per_day INT,
socio_alcohol VARCHAR(50),
socio_alcohol_type TEXT,
socio_alcohol_drinks_per_day INT,
socio_alcohol_days_per_week INT
);

CREATE INDEX temp_socio_hiv_intake_patient_id ON temp_socio_hiv_intake (patient_id);
CREATE INDEX temp_socio_hiv_intake_encounter_id ON temp_socio_hiv_intake (encounter_id);

INSERT INTO temp_socio_hiv_intake (patient_id, encounter_id)
SELECT patient_id, MAX(encounter_id) FROM encounter WHERE encounter_id IN (SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type 
= @hiv_initial_encounter_type) AND voided = 0 GROUP BY patient_id;

UPDATE temp_socio_economics t SET emr_id = PATIENT_IDENTIFIER(patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
UPDATE temp_socio_hiv_intake t SET socio_smoker  = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', 'HISTORY OF TOBACCO USE', 'en');
UPDATE temp_socio_hiv_intake t SET socio_smoker_years = OBS_VALUE_NUMERIC(t.encounter_id, 'CIEL', '159931');
UPDATE temp_socio_hiv_intake t SET socio_smoker_cigarette_per_day = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH', '11949');
UPDATE temp_socio_hiv_intake t SET socio_alcohol = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', 'HISTORY OF ALCOHOL USE', 'en');
UPDATE temp_socio_hiv_intake t SET socio_alcohol_type = OBS_COMMENTS(t.encounter_id, 'PIH', '3342', 'PIH', 'OTHER');
UPDATE temp_socio_hiv_intake t SET socio_alcohol_drinks_per_day = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH', 'ALCOHOLIC DRINKS PER DAY');
UPDATE temp_socio_hiv_intake t SET socio_alcohol_days_per_week = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH','NUMBER OF DAYS PER WEEK ALCOHOL IS USED');

DROP TEMPORARY TABLE IF EXISTS temp_hiv_vitals_weight;
CREATE TEMPORARY TABLE temp_hiv_vitals_weight (
person_id INT,
encounter_id INT, 
last_weight DOUBLE,
last_weight_date DATE
); 

CREATE INDEX temp_hiv_vitals_weight_patient_id ON temp_hiv_vitals_weight (person_id);
CREATE INDEX temp_hiv_vitals_weight_encounter_id ON temp_hiv_vitals_weight (encounter_id);

INSERT INTO temp_hiv_vitals_weight (person_id, encounter_id)
SELECT person_id, MAX(encounter_id) FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'WEIGHT (KG)') GROUP BY person_id;  	

UPDATE temp_hiv_vitals_weight t SET last_weight = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH', 'WEIGHT (KG)');
UPDATE temp_hiv_vitals_weight t SET last_weight_date = (SELECT DATE(encounter_datetime) FROM encounter e WHERE voided = 0 AND t.encounter_id = e.encounter_id );

DROP TEMPORARY TABLE IF EXISTS temp_hiv_vitals_height;
CREATE TEMPORARY TABLE temp_hiv_vitals_height (
person_id INT,
encounter_id INT, 
last_height DOUBLE,
last_height_date DATE
); 

CREATE INDEX temp_hiv_vitals_height_patient_id ON temp_hiv_vitals_height (person_id);
CREATE INDEX temp_hiv_vitals_height_encounter_id ON temp_hiv_vitals_height (encounter_id);

INSERT INTO temp_hiv_vitals_height (person_id, encounter_id)
SELECT person_id, MAX(encounter_id) FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'HEIGHT (CM)') GROUP BY person_id;  	

UPDATE temp_hiv_vitals_height t SET last_height = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH', 'HEIGHT (CM)');
UPDATE temp_hiv_vitals_height t SET last_height_date = (SELECT DATE(encounter_datetime) FROM encounter e WHERE voided = 0 AND t.encounter_id = e.encounter_id );

-- last_visit_date
### For this section, putting into account restrospective data entry,
### thus using max(encounter_date) instead of max(encounter_id)
DROP TEMPORARY TABLE IF EXISTS temp_hiv_last_visits;
CREATE TEMPORARY TABLE temp_hiv_last_visits (
patient_id INT,
last_visit_date DATETIME
);

CREATE INDEX temp_hiv_last_visits_patient_id ON temp_hiv_last_visits (patient_id);

INSERT INTO temp_hiv_last_visits (patient_id, last_visit_date)
SELECT patient_id, MAX(encounter_datetime) FROM encounter WHERE voided = 0
AND encounter_id IN (SELECT encounter_id FROM encounter WHERE encounter_type IN (@hiv_initial_encounter_type, @hiv_followup_encounter_type) AND voided = 0)
GROUP BY patient_id;

-- viral_load_date
DROP TEMPORARY TABLE IF EXISTS temp_hiv_last_viral_stage;
CREATE TEMPORARY TABLE temp_hiv_last_viral_stage (
person_id INT,
encounter_id INT, 
viral_load_date DATE
);

CREATE INDEX temp_hiv_last_viral_stage_person_id ON temp_hiv_last_viral_stage (person_id);
CREATE INDEX temp_hiv_last_viral_stage_encounter ON temp_hiv_last_viral_stage (encounter_id);

INSERT INTO temp_hiv_last_viral_stage (person_id, encounter_id)
SELECT person_id, encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "HIV viral load construct");

-- specimen collection date, visit id
UPDATE temp_hiv_last_viral_stage tvl INNER JOIN encounter e ON tvl.encounter_id = e.encounter_id
SET	viral_load_date = e.encounter_datetime;

DROP TEMPORARY TABLE IF EXISTS temp_hiv_last_viral;
CREATE TEMPORARY TABLE temp_hiv_last_viral (
person_id INT,
encounter_id INT, 
viral_load_date DATETIME,
last_viral_load_date DATE,
last_viral_load_numeric DOUBLE,
last_viral_load_undetectable DOUBLE,
months_since_last_vl DOUBLE 
);

CREATE INDEX temp_hiv_last_viral_person_id ON temp_hiv_last_viral (person_id);
CREATE INDEX temp_hiv_last_viral_encounter ON temp_hiv_last_viral (encounter_id);

INSERT INTO temp_hiv_last_viral (person_id, viral_load_date)
SELECT person_id, MAX(viral_load_date) FROM temp_hiv_last_viral_stage GROUP BY person_id;

UPDATE temp_hiv_last_viral t SET last_viral_load_date = t.viral_load_date;
UPDATE temp_hiv_last_viral t INNER JOIN temp_hiv_last_viral_stage tm ON tm.person_id = t.person_id AND tm.viral_load_date = t.last_viral_load_date
SET t.encounter_id = tm.encounter_id;
UPDATE temp_hiv_last_viral tvl SET last_viral_load_numeric = OBS_VALUE_NUMERIC(tvl.encounter_id, 'CIEL', '856');
UPDATE temp_hiv_last_viral tvl SET last_viral_load_undetectable = OBS_VALUE_NUMERIC(tvl.encounter_id, 'PIH', '11548');
UPDATE temp_hiv_last_viral t SET months_since_last_vl = TIMESTAMPDIFF(MONTH, last_viral_load_date, NOW());

-- next_visit_date
### For this section, putting into account restrospective data entry, 
### thus using max(encounter_date) instead of max(encounter_id)
DROP TEMPORARY TABLE IF EXISTS temp_hiv_next_visit_date;
CREATE TEMPORARY TABLE temp_hiv_next_visit_date
(
person_id int,
next_visit_date datetime,
days_late_to_visit double
);
insert into temp_hiv_next_visit_date (person_id, next_visit_date)
SELECT person_id, MAX(value_datetime) FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "RETURN VISIT DATE")
AND encounter_id IN (SELECT encounter_id FROM encounter WHERE encounter_type IN (@hiv_initial_encounter_type, @hiv_followup_encounter_type) AND voided = 0) GROUP BY person_id;

update temp_hiv_next_visit_date t set days_late_to_visit =  TIMESTAMPDIFF(DAY, next_visit_date, NOW());

--
DROP TABLE IF EXISTS temp_hiv_diagnosis_date;
CREATE TEMPORARY TABLE temp_hiv_diagnosis_date
(
person_id INT,
encounter_id INT,
hiv_diagnosis_date DATE
);

CREATE INDEX temp_hiv_diagnosis_date_person_id ON temp_hiv_diagnosis_date (person_id);
CREATE INDEX temp_hiv_diagnosis_date_encounter_id ON temp_hiv_diagnosis_date (encounter_id);

INSERT INTO temp_hiv_diagnosis_date (person_id, encounter_id, hiv_diagnosis_date)
SELECT person_id, encounter_id, DATE(MIN(value_datetime)) FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING('CIEL', '164400') GROUP BY person_id;

DROP TABLE IF EXISTS temp_hiv_dispensing;
CREATE TEMPORARY TABLE temp_hiv_dispensing
(
person_id INT,
encounter_id INT,
art_start_date DATE,
months_on_art DOUBLE,
initial_art_regimen VARCHAR(100),
latest_encounter INT,
art_regimen VARCHAR(100),
last_pickup_date DATE,
last_pickup_months_dispensed DOUBLE,
last_pickup_treatment_line VARCHAR(5),
next_pickup_date DATE,
days_late_to_pickup DOUBLE,
agent TEXT
);

CREATE INDEX temp_hiv_dispensing_person_id ON temp_hiv_dispensing (person_id);
CREATE INDEX temp_hiv_dispensing_encounter_id ON temp_hiv_dispensing (encounter_id);
CREATE INDEX temp_hiv_dispensing_latest_encounter ON temp_hiv_dispensing (latest_encounter);

INSERT INTO temp_hiv_dispensing (person_id, art_start_date)
SELECT person_id, MIN(obs_datetime) FROM 
obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING('PIH', '1535') AND encounter_id IN (SELECT encounter_id FROM encounter
WHERE voided = 0 AND encounter_type = @hiv_dispensing_encounter)
AND value_coded IN (CONCEPT_FROM_MAPPING('PIH', '3013') , CONCEPT_FROM_MAPPING('PIH', '2848')) GROUP BY person_id;

UPDATE temp_hiv_dispensing t SET months_on_art = TIMESTAMPDIFF(MONTH, t.art_start_date, NOW());

UPDATE temp_hiv_dispensing t SET encounter_id = (SELECT encounter_id FROM encounter WHERE encounter_type = @hiv_dispensing_encounter
AND DATE(encounter_datetime) = t.art_start_date AND voided = 0 AND t.person_id = patient_id GROUP BY patient_id);

UPDATE temp_hiv_dispensing t SET latest_encounter = (SELECT MAX(encounter_id) FROM encounter WHERE encounter_type = @hiv_dispensing_encounter
AND voided = 0 AND t.person_id = patient_id GROUP BY patient_id);

UPDATE temp_hiv_dispensing t SET initial_art_regimen = (SELECT GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en')) FROM obs o WHERE o.encounter_id = t.encounter_id 
AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'MEDICATION ORDERS'));

UPDATE temp_hiv_dispensing t SET art_regimen = (SELECT GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en')) FROM obs o WHERE o.encounter_id = t.latest_encounter 
AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'MEDICATION ORDERS'));

UPDATE temp_hiv_dispensing t SET last_pickup_date = (SELECT DATE(encounter_datetime) FROM encounter e WHERE voided = 0 AND e.encounter_id = t.latest_encounter);

UPDATE temp_hiv_dispensing t SET last_pickup_months_dispensed =  OBS_VALUE_NUMERIC(t.latest_encounter, 'PIH', '3102');

UPDATE temp_hiv_dispensing t SET last_pickup_treatment_line = OBS_VALUE_CODED_LIST(t.latest_encounter, 'CIEL', '166073', 'en');

UPDATE temp_hiv_dispensing t SET next_pickup_date = (SELECT DATE(value_datetime) FROM obs o WHERE voided = 0 AND o.encounter_id = t.latest_encounter 
AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '5096'));
UPDATE temp_hiv_dispensing t SET days_late_to_pickup = TIMESTAMPDIFF(DAY, next_pickup_date, NOW());

UPDATE temp_hiv_dispensing t SET agent = OBS_VALUE_TEXT(t.latest_encounter, 'CIEL', '164141');

### Final Query
SELECT 
t.patient_id,
t.zl_emr_id,
t.hivemr_v1_id,
t.hiv_dossier_id,
t.given_name,
t.family_name,
t.gender,
t.birthdate,
t.age,
t.marital_status,
t.occupation,
tehd.agent,
t.mothers_first_name,
t.telephone_number,
t.address,
t.department,
t.commune,
t.section_communal,
t.locality,
t.street_landmark,
t.dead,
t.death_date,
t.cause_of_death,
t.cause_of_death_non_coded,
t.patient_msm,
t.patient_sw,
t.patient_pris,
t.patient_trans,
t.patient_idu,
t.parent_firstname,
t.parent_lastname,
t.parent_relationship,
tse.socio_people_in_house,
tse.socio_rooms_in_house,
tse.socio_roof_type,
tse.socio_floor_type,
tse.socio_has_latrine,
tse.socio_has_radio,
tse.socio_years_of_education,
tse.socio_transport_method,
tse.socio_transport_time,
tse.socio_transport_walking_time,
ts.socio_smoker,
ts.socio_smoker_years,
ts.socio_smoker_cigarette_per_day,
ts.socio_alcohol,
ts.socio_alcohol_type,
ts.socio_alcohol_drinks_per_day,
ts.socio_alcohol_days_per_week,
tsw.last_weight,
tsw.last_weight_date,
tsh.last_height,
tsh.last_height_date,
DATE(tsv.last_visit_date),
DATE(tsd.next_visit_date),
IF(tsd.days_late_to_visit > 0, days_late_to_visit, 0) days_late_to_visit, 
DATE(tsl.viral_load_date),
tsl.last_viral_load_date,
tsl.last_viral_load_numeric,
tsl.last_viral_load_undetectable,
tsl.months_since_last_vl,
thd.hiv_diagnosis_date,
tehd.art_start_date,
tehd.months_on_art,
tehd.initial_art_regimen,
tehd.art_regimen,
tehd.last_pickup_date,
tehd.last_pickup_months_dispensed,
tehd.last_pickup_treatment_line,
tehd.next_pickup_date,
IF(tehd.days_late_to_pickup > 0, tehd.days_late_to_pickup, 0) days_late_to_pickup 
FROM temp_patient t 
LEFT JOIN temp_socio_economics tse ON t.patient_id = tse.patient_id
LEFT JOIN temp_socio_hiv_intake ts ON t.patient_id = ts.patient_id
LEFT JOIN temp_hiv_vitals_weight tsw ON t.patient_id = tsw.person_id
LEFT JOIN temp_hiv_vitals_height tsh ON t.patient_id = tsh.person_id
LEFT JOIN temp_hiv_last_visits tsv ON t.patient_id = tsv.patient_id
LEFT JOIN temp_hiv_last_viral tsl ON t.patient_id = tsl.person_id
LEFT JOIN temp_hiv_next_visit_date tsd ON t.patient_id = tsd.person_id
LEFT JOIN temp_hiv_diagnosis_date thd ON t.patient_id = thd.person_id
LEFT JOIN temp_hiv_dispensing tehd ON tehd.person_id = t.patient_id;