## This report is a row per encounter report.
## if there is an ovc encounter, this this encounter is withing a program then this is will show up in the report
## If there is an ovc encounter but no program, this won't show up in the report. This is could be caused when you fill out an ovc followup form bu not initial form


SET @ovc_followup_encounter_type = ENCOUNTER_TYPE('OVC Follow-up');
SET @ovc_initial_encounter_type = ENCOUNTER_TYPE('OVC Intake');

SET sql_safe_updates = 0;
SET @ovc_followup_encounter_type = ENCOUNTER_TYPE('OVC Follow-up');
SET @ovc_initial_encounter_type = ENCOUNTER_TYPE('OVC Intake');

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
  date_created          DATETIME
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
UPDATE  temp_ovc_patient_program pp INNER JOIN patient_state ps ON pp.patient_program_id = ps.patient_program_id AND ps.date_changed IS NULL AND ps.voided = 0
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
DROP TEMPORARY TABLE IF EXISTS temp_final_ovc_patient_program;
CREATE TEMPORARY TABLE temp_final_ovc_patient_program
(
SELECT
    tpp.patient_program_id,
    ZLEMR(tpp.patient_id) zlemr_id,
    tpp.patient_id,
    tpp.date_enrolled,
    date_completed,
    location,
    IF(state_id IN (21, 69) AND date_completed IS NULL, "active_status", IF(state_id = 23 AND date_completed IS NOT NULL, "lost to followup",  IF(state_id IN (22, 71) AND date_completed IS NOT NULL, "completed", 'NULL'))) program_status,
    outcome,
    index_asc index_asc_enrollment,
    index_desc index_desc_enrollment
FROM temp_ovc_patient_program  tpp
INNER JOIN temp_ovc_index_asc tia ON tpp.patient_program_id = tia.patient_program_id
INNER JOIN temp_ovc_index_desc tid ON tpp.patient_program_id = tid.patient_program_id
ORDER BY zlemr_id, tpp.date_enrolled
);

## ovc encounters
DROP TEMPORARY TABLE IF EXISTS ovc_encounters;
CREATE TEMPORARY TABLE ovc_encounters
(
	person_id               INT,
	encounter_id            INT,
	encounter_date          DATE,
	hiv_status              VARCHAR(255),
	hiv_test_date           DATE,
	services                TEXT,
	other_services          VARCHAR(255),
	index_asc_hiv_status    INT,
	index_desc_hiv_status   INT
);

INSERT INTO ovc_encounters (person_id, encounter_id, encounter_date)
(
SELECT person_id, o.encounter_id, DATE(encounter_datetime)
FROM obs o INNER JOIN encounter e ON patient_id = person_id AND o.encounter_id = e.encounter_id AND encounter_type IN (@ovc_initial_encounter_type, @ovc_followup_encounter_type) AND o.voided = 0
AND e.voided = 0 GROUP BY encounter_id
);

# services
UPDATE ovc_encounters ovc SET services = (SELECT GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en')) FROM obs o WHERE
ovc.encounter_id = o.encounter_id AND o. concept_id = CONCEPT_FROM_MAPPING('PIH', 'Service or program') AND o.voided = 0);

# other service or program
UPDATE ovc_encounters ovc JOIN obs o ON ovc.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Service or program non-coded')
AND o.voided = 0
SET other_services = o.value_text;

# HIV STATUS
UPDATE ovc_encounters ovc JOIN obs o ON ovc.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'HIV STATUS')
AND o.voided = 0
SET hiv_status = CONCEPT_NAME(value_coded, 'en');

# Hiv test date
UPDATE ovc_encounters ovc JOIN obs o ON ovc.encounter_id = o.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'HIV TEST DATE')
AND o.voided = 0
SET hiv_test_date = DATE(value_datetime);

##HIV statuses that are not null
DROP TEMPORARY TABLE IF EXISTS temp_non_null_ovc_encounters;
CREATE TEMPORARY TABLE temp_non_null_ovc_encounters
(
SELECT * FROM ovc_encounters WHERE hiv_status IS NOT NULL
);

# HIV status indexes
# asc
DROP TEMPORARY TABLE IF EXISTS index_asc_hivstatus;
CREATE TEMPORARY TABLE index_asc_hivstatus
(
    SELECT
            person_id,
            encounter_id,
            encounter_date,
            hiv_status,
            index_asc
FROM (SELECT
            @v:= IF(@q <> person_id, @v:=1, IF(@w <> hiv_status, @v + 1, @v)) index_asc,
            hiv_status,
            encounter_id,
			encounter_date,
            person_id,
            @w:= IFNULL(hiv_status, @w),
            @q:= person_id
      FROM temp_non_null_ovc_encounters,
                    (SELECT @v:= 0) AS r,
                    (SELECT @w:= ' ') AS u,
                    (SELECT @q:= 0) AS p
            ORDER BY person_id ASC, encounter_date ASC
        ) index_ascending );

# desc
DROP TEMPORARY TABLE IF EXISTS index_desc_hivstatus;
CREATE TEMPORARY TABLE index_desc_hivstatus
(
    SELECT
            person_id,
            encounter_id,
            encounter_date,
            hiv_status,
            index_desc
FROM (SELECT
            @a:= IF(@c <> person_id, @a:=1, IF(@b <> hiv_status, @a + 1, @a)) index_desc,
            hiv_status,
            encounter_id,
			encounter_date,
            person_id,
            @b:= IFNULL(hiv_status, @b),
            @c:= person_id
      FROM temp_non_null_ovc_encounters,
                    (SELECT @a:= 0) AS a,
                    (SELECT @b:= ' ') AS b,
                    (SELECT @c:= 0) AS c
            ORDER BY person_id ASC, encounter_date DESC
        ) index_descending );

#ovc encounters, with programs that are completed
DROP TEMPORARY TABLE IF EXISTS temp_completed_status;
CREATE TEMPORARY TABLE temp_completed_status(
SELECT * FROM ovc_encounters ovc INNER JOIN temp_final_ovc_patient_program tpovc ON ovc.person_id = tpovc.patient_id
AND encounter_date BETWEEN date_enrolled AND date_completed
);

## ovc encounters, with active programs
DROP TEMPORARY TABLE IF EXISTS temp_active_program_status;
CREATE TEMPORARY TABLE temp_active_program_status(
SELECT * FROM ovc_encounters ovc INNER JOIN temp_final_ovc_patient_program tpovc ON ovc.person_id = tpovc.patient_id
AND encounter_date >= date_enrolled AND date_completed IS NULL
);


## Combining Active and non active progrm statusesw

DROP TABLE IF EXISTS stage_table;
CREATE TEMPORARY TABLE stage_table
SELECT * FROM temp_completed_status
UNION ALL
SELECT * FROM temp_active_program_status ORDER BY person_id, patient_program_id;

UPDATE stage_table st INNER JOIN index_asc_hivstatus ind_asc ON st.encounter_id = ind_asc.encounter_id
SET index_asc_hiv_status = index_asc;

UPDATE stage_table st INNER JOIN index_desc_hivstatus ind_desc ON st.encounter_id = ind_desc.encounter_id
SET index_desc_hiv_status = index_desc;

## Including indexes for null hiv status
UPDATE stage_table st SET index_asc_hiv_status =
(SELECT index_asc FROM index_asc_hivstatus ind_asc WHERE ind_asc.encounter_date < st.encounter_date  AND ind_asc.person_id = st.person_id ORDER BY ind_asc.encounter_date DESC LIMIT 1) WHERE st.hiv_status IS NULL ORDER BY st.encounter_date;

UPDATE stage_table st SET index_desc_hiv_status =
(SELECT index_desc FROM index_desc_hivstatus ind_desc WHERE ind_desc.encounter_date < st.encounter_date  AND ind_desc.person_id = st.person_id ORDER BY ind_desc.encounter_date DESC LIMIT 1)
WHERE st.hiv_status IS NULL ORDER BY st.encounter_date;


### Program status indexes
DROP TEMPORARY TABLE IF EXISTS temp_ovc_patient_status;
CREATE TEMPORARY TABLE temp_ovc_patient_status
(
SELECT * FROM temp_ovc_patient_program WHERE state_id IS NOT NULL
);

DROP TEMPORARY TABLE IF EXISTS temp_progstatatus_index_asc;
CREATE TEMPORARY TABLE temp_progstatatus_index_asc
(
    SELECT
            patient_program_id,
            date_enrolled,
            date_completed,
            patient_id,
            date_created,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            date_completed,
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



DROP TEMPORARY TABLE IF EXISTS temp_progstatatus_index_desc;
CREATE TEMPORARY TABLE temp_progstatatus_index_desc
(
    SELECT
            patient_program_id,
            date_enrolled,
            date_completed,
            patient_id,
            date_created,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            date_completed,
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


DROP TEMPORARY TABLE IF EXISTS temp_progstatatus_indexes;
CREATE TEMPORARY TABLE temp_progstatatus_indexes
(
SELECT ti.patient_program_id, ti.patient_id, ti.date_enrolled, ti.date_completed, ti.date_created, index_asc, index_desc FROM temp_progstatatus_index_asc ti JOIN temp_progstatatus_index_desc
td ON ti.patient_id = td.patient_id AND ti.date_enrolled = td.date_enrolled ORDER BY ti.patient_id, ti.date_enrolled
);

## Final query
SELECT
    ft.person_id,
    ft.patient_program_id,
    zlemr_id, ft.encounter_id,
    ft.encounter_date,
    ft.date_enrolled,
    ft.date_completed,
    program_status,
    outcome,
    location,
    hiv_test_date,
    ft.hiv_status,
    services,
    other_services,
    index_asc_hiv_status,
    index_desc_hiv_status,
    tpid.index_asc index_asc_program_status,
    tpid.index_desc index_desc_program_status,
    index_asc_enrollment,
    index_desc_enrollment
FROM stage_table ft
JOIN temp_progstatatus_indexes tpid on ft.person_id = tpid.patient_id and ft.date_completed = tpid.date_completed ORDER BY person_id, encounter_date;
