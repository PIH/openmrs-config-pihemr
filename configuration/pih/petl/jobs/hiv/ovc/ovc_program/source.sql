SET sql_safe_updates = 0;
DROP TEMPORARY TABLE IF EXISTS temp_ovc_index_asc;
DROP TEMPORARY TABLE IF EXISTS temp_ovc_index_desc;
DROP TABLE IF EXISTS temp_ovc_patient_program;

CREATE TABLE temp_ovc_patient_program
(
  patient_program_id    INT(11),
  patient_id            INT(11),
  date_enrolled         DATE,
  date_completed        DATE,
  location_id           INT,
  location              VARCHAR(255),
  state_id              INT,
  state_end_date        DATE,
  outcome_concept_id    INT,
  outcome               VARCHAR(255),
  date_created DATETIME
);

INSERT INTO temp_ovc_patient_program (patient_program_id, patient_id, date_enrolled, date_completed, location_id,outcome_concept_id, date_created)
SELECT patient_program_id, patient_id, date_enrolled, date_completed,location_id,outcome_concept_id, date_created
    FROM patient_program
    WHERE voided=0
    AND program_id = (SELECT program_id FROM program WHERE uuid='e1b2f0b5-6d56-4500-8523-0ba71e75d897');

## Delete test patients
DELETE FROM temp_ovc_patient_program WHERE
patient_id IN (
               SELECT
                      a.person_id
                      FROM person_attribute a
                      INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
                      AND a.value = 'true' AND t.name = 'Test Patient'
               );

UPDATE temp_ovc_patient_program
SET location = LOCATION_NAME(location_id),
    outcome = CONCEPT_NAME(outcome_concept_id, 'en');

#patient state
UPDATE  temp_ovc_patient_program pp INNER JOIN patient_state ps ON pp.patient_program_id = ps.patient_program_id AND ps.date_changed IS NULL
SET state_id = ps.state;

-- The indexes are calculated using the patient_program_id, date_enrolled
### index ascending
CREATE TEMPORARY TABLE temp_ovc_index_asc
(
    SELECT
            patient_program_id,
            date_enrolled,
            patient_id,
            date_created,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            patient_program_id,
            date_enrolled,
            date_created,
            patient_id,
            @u:= patient_id
      FROM temp_ovc_patient_program,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, date_enrolled ASC, patient_program_id ASC, date_created ASC
        ) index_ascending );

### index desending
CREATE TEMPORARY TABLE temp_ovc_index_desc
(
    SELECT
            patient_program_id,
            date_enrolled,
            patient_id,
            date_created,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_DESC,
            patient_program_id,
            date_enrolled,
            date_created,
            patient_id,
            @u:= patient_id
      FROM temp_ovc_patient_program,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, date_enrolled DESC, patient_program_id DESC, date_created DESC
        ) index_descending );

# final query
SELECT
    tpp.patient_program_id,
    ZLEMR(tpp.patient_id) zlemr_id,
    tpp.patient_id,
    tpp.date_enrolled,
    date_completed,
    location,
    IF(state_id = 21 AND date_completed IS NULL, "active_status", IF(state_id = 23 AND date_completed IS NOT NULL, "lost to followup",  IF(state_id = 22 AND date_completed IS NOT NULL, "completed", 'NULL'))) program_status,
    outcome,
    index_asc,
    index_desc
FROM temp_ovc_patient_program  tpp
INNER JOIN temp_ovc_index_asc tia ON tpp.patient_program_id = tia.patient_program_id
INNER JOIN temp_ovc_index_desc tid ON tpp.patient_program_id = tid.patient_program_id
ORDER BY zlemr_id, tpp.date_enrolled;