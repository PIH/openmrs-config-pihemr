SET sql_safe_updates = 0;

SET @mch_emr_id = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE uuid = 'a541af1e-105c-40bf-b345-ba1fd6a59b85');
SET @mch_patient_program_id = (SELECT program_id FROM program WHERE uuid = '41a2715e-8a14-11e8-9a94-a6cf71072f73');
SET @obgyn_encounter = (SELECT encounter_type_id FROM encounter_type WHERE uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d');

## patient
DROP TABLE IF EXISTS temp_mch_status;
CREATE TABLE temp_mch_status
(
    patient_id                  INT(11),
    patient_program_id          INT(11),
    mch_emr_id                  VARCHAR(15),
    enrollment_location         VARCHAR(15),
    start_date                  DATE,
    end_date                    DATE,
    outcome_concept_id          INT(11),
    outcome                     VARCHAR(255),
    encounter_location_name     VARCHAR(255),
    antenatal_visit             VARCHAR(5),
    estimated_delivery_date     DATE,
    history_hiv                 VARCHAR(5),
    high_risk_factor_hiv        VARCHAR(5),
    arv_status                  VARCHAR(5),
    patient_disposition         VARCHAR(100),
    transfer                    VARCHAR(100),
    index_asc                   INT(11),
    index_desc                  INT(11)
);

INSERT INTO temp_mch_status (patient_id, patient_program_id, enrollment_location, start_date, end_date, outcome)
SELECT patient_id, patient_program_id, LOCATION_NAME(location_id), DATE(date_enrolled), DATE(date_completed), CONCEPT_NAME(outcome_concept_id, 'en')
FROM patient_program WHERE voided=0 AND program_id = @mch_patient_program_id;

CREATE INDEX mch_patient_id ON temp_mch_status(patient_id);

## Delete test patients
DELETE FROM temp_mch_status WHERE
patient_id IN (
               SELECT
                      a.person_id
                      FROM person_attribute a
                      INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
                      AND a.value = 'true' AND t.name = 'Test Patient'
               );

-- ZL EMR ID
UPDATE temp_mch_status t
INNER JOIN
   (SELECT patient_id, GROUP_CONCAT(identifier) 'ids'
    FROM patient_identifier pid
    WHERE pid.voided = 0
    AND pid.identifier_type = @mch_emr_id
    GROUP BY patient_id
   ) ids ON ids.patient_id = t.patient_id
SET t.mch_emr_id = ids.ids;

######### index count
########## indexes
# program indexes (note this is done on the temp_mch_status_program table since its a 1 row per patient program id)
### ascending
DROP TEMPORARY TABLE IF EXISTS temp_mch_program_index_asc;
CREATE TEMPORARY TABLE temp_mch_program_index_asc
(
    SELECT
            patient_program_id,
            start_date,
            end_date,
            patient_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            patient_program_id,
            start_date,
            end_date,
            patient_id,
            @u:= patient_id
      FROM temp_mch_status,
        (SELECT @r:= 1) AS r,
        (SELECT @u:= 0) AS u
      ORDER BY patient_id, start_date ASC, patient_program_id ASC
        ) index_ascending );

CREATE INDEX mch_index_asc ON temp_mch_program_index_asc(patient_id, index_asc, patient_program_id);

## descending
DROP TEMPORARY TABLE IF EXISTS temp_mch_program_index_desc;
CREATE TEMPORARY TABLE temp_mch_program_index_desc
(
    SELECT
            patient_program_id,
            start_date,
            patient_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            patient_program_id,
            start_date,
            patient_id,
            @u:= patient_id
      FROM temp_mch_status,
            (SELECT @r:= 1) AS r,
            (SELECT @u:= 0) AS u
      ORDER BY patient_id, start_date DESC, patient_program_id DESC
        ) index_descending );

CREATE INDEX mch_index_desc ON temp_mch_program_index_desc(patient_id, index_desc, patient_program_id);

## adding the above indexes into the ovc_encounters table
UPDATE temp_mch_status o JOIN temp_mch_program_index_asc top ON o.patient_program_id = top.patient_program_id
SET o.index_asc = top.index_asc;

UPDATE temp_mch_status o JOIN temp_mch_program_index_desc top ON o.patient_program_id = top.patient_program_id
SET o.index_desc = top.index_desc;

## all mch encounters
DROP TEMPORARY TABLE IF EXISTS temp_mch_all_encounters;
CREATE TEMPORARY TABLE temp_mch_all_encounters
(
encounter_id    INT(11),
patient_id      INT(11)
);
INSERT INTO temp_mch_all_encounters(encounter_id, patient_id)
SELECT encounter_id, patient_id FROM encounter WHERE voided = 0 AND encounter_type = @obgyn_encounter;

CREATE INDEX temp_mch_indexes ON temp_mch_all_encounters(encounter_id, patient_id);

-- latest mch encounters
DROP TEMPORARY TABLE IF EXISTS temp_mch_encounters;
CREATE TEMPORARY TABLE temp_mch_encounters
(
    encounter_id                INT(11),
    patient_id                  INT(11),
    encounter_date              DATE,
    encounter_location_name     VARCHAR(255),
    visit                       VARCHAR(255),
    antenatal_visit             VARCHAR(5),
    estimated_delivery_date     DATE,
    history_hiv                 VARCHAR(5),
    high_risk_factor_hiv        VARCHAR(5),
    arv_status                  VARCHAR(5),
    patient_disposition         VARCHAR(100),
    admission_ward_location     VARCHAR(100),
    transfer_within_location    VARCHAR(100),
    transfer_out_location       VARCHAR(30)
);

INSERT INTO temp_mch_encounters(encounter_id, patient_id)
SELECT MAX(encounter_id), patient_id FROM temp_mch_all_encounters GROUP BY patient_id;

CREATE INDEX tmp_mch_indexes ON temp_mch_encounters(encounter_id, patient_id);

-- encounter_date
UPDATE temp_mch_encounters te JOIN encounter e ON te.encounter_id = e.encounter_id
SET encounter_date = DATE(encounter_datetime);

-- encounter_location_name
UPDATE temp_mch_encounters te JOIN encounter e ON te.encounter_id = e.encounter_id
SET te.encounter_location_name = ENCOUNTER_LOCATION_NAME(e.encounter_id);

-- pregnancy_status
-- if antenatal visit is checked
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Type of HUM visit')
AND value_coded = CONCEPT_FROM_MAPPING('PIH', 'ANC VISIT') AND o.voided = 0
SET antenatal_visit = 'Yes'; -- yes

-- estimated_delivery_date
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'ESTIMATED DATE OF CONFINEMENT') AND o.voided = 0
SET estimated_delivery_date = DATE(value_datetime);

-- hiv status
-- history
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '1628')
AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '138405') AND o.voided = 0
SET history_hiv = 'Yes'; -- yes
-- risk factor
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '160079')
AND value_coded = CONCEPT_FROM_MAPPING('CIEL', '138405') AND o.voided = 0
SET high_risk_factor_hiv = 'Yes'; -- yes

-- arv status
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '160119')
AND o.voided = 0
SET arv_status = CONCEPT_NAME(value_coded, 'en');

-- patient disposition
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'HUM Disposition categories')
AND o.voided = 0
SET patient_disposition = CONCEPT_NAME(value_coded, 'en');

-- admission ward location
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Admission location in hospital')
AND o.voided = 0
SET admission_ward_location = LOCATION_NAME(value_text);

-- transfer out location
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Transfer out location')
AND o.voided = 0
SET transfer_out_location = CONCEPT_NAME(value_coded, 'en');

-- transfer in location
UPDATE temp_mch_encounters te JOIN obs o ON te.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Arrival location within hospital')
AND o.voided = 0
SET transfer_within_location = LOCATION_NAME(value_text);

####
UPDATE temp_mch_status tmp JOIN temp_mch_encounters tme ON tmp.patient_id = tme.patient_id AND tmp.index_desc = 1
SET tmp.encounter_location_name	= tme.encounter_location_name,
    tmp.antenatal_visit = tme.antenatal_visit,
    tmp.estimated_delivery_date = tme.estimated_delivery_date,
    tmp.history_hiv = tme.history_hiv,
    tmp.high_risk_factor_hiv = tme.high_risk_factor_hiv,
    tmp.arv_status = tme.arv_status,
    tmp.patient_disposition = tme.patient_disposition,
    tmp.transfer = COALESCE(admission_ward_location, transfer_within_location, transfer_out_location);

### Final Query
SELECT
    patient_id,
    mch_emr_id,
    enrollment_location,
    encounter_location_name,
    start_date,
    end_date,
    outcome,
    antenatal_visit,
    estimated_delivery_date,
    history_hiv,
    high_risk_factor_hiv,
    arv_status,
    patient_disposition,
    transfer,
    index_asc,
    index_desc
FROM temp_mch_status order by patient_id;