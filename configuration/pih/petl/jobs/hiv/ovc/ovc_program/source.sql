### This report is a row per encounter report.
### if there is an ovc encounter, this this encounter is withing a program then this is will show up in the report
### If there is an ovc encounter but no program, this won't show up in the report.
### This is could be caused when you fill out an ovc followup form bu not initial form

SET sql_safe_updates = 0;
SET @ovc_followup_encounter_type = ENCOUNTER_TYPE('OVC Follow-up');
SET @ovc_initial_encounter_type = ENCOUNTER_TYPE('OVC Intake');

## temp tables
DROP TEMPORARY TABLE IF EXISTS ovc_encounters;
DROP TABLE IF EXISTS temp_ovc_patient_program;

## patient program table
CREATE TABLE temp_ovc_patient_program
(
    patient_id                      INT,
    patient_program_id              INT,
    encounter_id                    INT,
    encounter_date                  DATE,
    date_enrolled                   DATE,
    date_completed                  DATE,
    hiv_status                      VARCHAR(255),
    hiv_test_date                   DATE,
    services                        TEXT,
    other_services                  VARCHAR(255),
    location_id                     INT,
    outcome_concept_id              INT,
    program_outcome                 VARCHAR(255),
    state                           INT,
    program_status                  VARCHAR(255),
    patient_state_id                INT,
    program_status_start_date       DATE,
    program_status_end_date         DATE,
    program_date_created            DATETIME,
    index_asc_hiv_status            INT,
    index_desc_hiv_status           INT,
    index_asc_program_status        INT,
    index_desc_program_status       INT,
    index_asc_enrollment            INT,
    index_desc_enrollment           INT
);

INSERT INTO temp_ovc_patient_program (patient_id, patient_program_id, location_id, date_enrolled, date_completed, outcome_concept_id, program_outcome, program_date_created)
SELECT patient_id, patient_program_id, location_id, date_enrolled, date_completed, outcome_concept_id, CONCEPT_NAME(outcome_concept_id, 'en'), date_created
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

##### ovc encounters
CREATE TEMPORARY TABLE ovc_encounters
(
    person_id                       INT,
    patient_program_id              INT,
    encounter_id                    INT,
    encounter_date                  DATE,
    ovc_program_enrollment_date     DATE,
    ovc_program_completion_date     DATE,
    hiv_status                      VARCHAR(255),
    hiv_test_date                   DATE,
    services                        TEXT,
    other_services                  VARCHAR(255),
    location_id                     INT,
    outcome_concept_id              INT,
    program_outcome                 VARCHAR(255),
    state                           INT,
    program_status                  VARCHAR(255),
    patient_state_id                INT,
    program_status_start_date       DATE,
    program_status_end_date         DATE,
    program_date_created            DATETIME,
    index_asc_hiv_status            INT,
    index_desc_hiv_status           INT,
    index_asc_program_status        INT,
    index_desc_program_status       INT,
    index_asc_enrollment            INT,
    index_desc_enrollment           INT
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

# join encounters and completed ovc programs
UPDATE ovc_encounters e INNER JOIN temp_ovc_patient_program tp ON person_id = patient_id AND e.encounter_date BETWEEN tp.date_enrolled AND tp.date_completed
SET e.patient_program_id = tp.patient_program_id,
	e.ovc_program_enrollment_date = tp.date_enrolled,
    e.ovc_program_completion_date = tp.date_completed,
    e.location_id = tp.location_id,
    e.program_outcome = CONCEPT_NAME(tp.outcome_concept_id, 'en');

# join ovc encounters and active ovc programs
UPDATE ovc_encounters e INNER JOIN temp_ovc_patient_program tp ON person_id = patient_id AND e.encounter_date >= tp.date_enrolled AND tp.date_completed IS NULL AND e.ovc_program_enrollment_date IS NULL
SET e.patient_program_id = tp.patient_program_id,
	e.ovc_program_enrollment_date = tp.date_enrolled,
    e.location_id = tp.location_id;

###### program status
DROP TEMPORARY TABLE IF EXISTS temp_ovc_program_status;
CREATE TEMPORARY TABLE temp_ovc_program_status
(
    patient_id                      INT,
    patient_program_id              INT,
    encounter_id                    INT,
    encounter_date                  DATE,
    date_enrolled                   DATE,
    date_completed                  DATE,
    hiv_status                      VARCHAR(255),
    hiv_test_date                   DATE,
    services                        TEXT,
    other_services                  VARCHAR(255),
    location_id                     INT,
    outcome_concept_id              INT,
    program_outcome                 VARCHAR(255),
    state                           INT,
    program_status                  VARCHAR(255),
    patient_state_id                INT,
    program_status_start_date       DATE,
    program_status_end_date         DATE,
    program_date_created            DATETIME,
    index_asc_hiv_status            INT,
    index_desc_hiv_status           INT,
    index_asc_program_status        INT,
    index_desc_program_status       INT,
    index_asc_enrollment            INT,
    index_desc_enrollment           INT
);

INSERT INTO temp_ovc_program_status (patient_program_id, state, patient_state_id, program_status_start_date, program_status_end_date)
SELECT patient_program_id, state, patient_state_id, start_date, end_date FROM patient_state WHERE patient_program_id IN (SELECT patient_program_id FROM temp_ovc_patient_program) AND voided = 0;

# patient_id
UPDATE temp_ovc_program_status top INNER JOIN patient_program pp ON pp.patient_program_id = top.patient_program_id
SET top.patient_id =  pp.patient_id;

## status changes
UPDATE temp_ovc_program_status top INNER JOIN program_workflow_state pws ON pws.program_workflow_state_id = top.state
SET top.program_status =  CONCEPT_NAME(pws.concept_id, 'en') ;

#location
UPDATE temp_ovc_program_status o INNER JOIN temp_ovc_patient_program tp ON o.patient_program_id = tp.patient_program_id
SET o.location_id = tp.location_id;

###### programs with no program statuses
drop temporary table if exists temp_program_no_statuses;
create temporary table temp_program_no_statuses
select
	patient_id,
    patient_program_id,
    encounter_id,
    encounter_date,
    date_enrolled,
    date_completed,
    hiv_status,
    hiv_test_date,
    services,
    other_services,
    location_id,
    outcome_concept_id,
    program_outcome,
    state,
    program_status,
    patient_state_id,
    program_status_start_date,
    program_status_end_date,
    program_date_created,
    index_asc_hiv_status,
    index_desc_hiv_status,
    index_asc_program_status,
    index_desc_program_status,
    index_asc_enrollment,
    index_desc_enrollment
from temp_ovc_patient_program where patient_program_id not in (select patient_program_id from temp_ovc_program_status);

drop temporary table if exists stage_temp_program_no_statuses;
create temporary table stage_temp_program_no_statuses
SELECT patient_program_id FROM temp_program_no_statuses WHERE patient_program_id  IN (
SELECT a.a_ppid FROM (
SELECT tp.patient_program_id a_ppid from ovc_encounters tp
) a );

########## indexes
# program indexes (note this is done on the temp_ovc_patient_program table since its a 1 row per patient program id)
### ascending
DROP TEMPORARY TABLE IF EXISTS temp_ovc_program_index_asc;
CREATE TEMPORARY TABLE temp_ovc_program_index_asc
(
    SELECT
            patient_program_id,
            date_enrolled,
            date_completed,
            patient_id,
            program_date_created,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            patient_program_id,
            date_enrolled,
            date_completed,
            program_date_created,
            patient_id,
            @u:= patient_id
      FROM temp_ovc_patient_program,
        (SELECT @r:= 1) AS r,
        (SELECT @u:= 0) AS u
      ORDER BY patient_id, date_enrolled ASC, patient_program_id ASC, program_date_created ASC
        ) index_ascending );

## descending
DROP TEMPORARY TABLE IF EXISTS temp_ovc_program_index_desc;
CREATE TEMPORARY TABLE temp_ovc_program_index_desc
(
    SELECT
            patient_program_id,
            date_enrolled,
            patient_id,
            program_date_created,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            patient_program_id,
            date_enrolled,
            program_date_created,
            patient_id,
            @u:= patient_id
      FROM temp_ovc_patient_program,
            (SELECT @r:= 1) AS r,
            (SELECT @u:= 0) AS u
      ORDER BY patient_id, date_enrolled DESC, patient_program_id DESC, program_date_created DESC
        ) index_descending );

## adding the above indexes into the ovc_encounters table
UPDATE ovc_encounters o INNER JOIN temp_ovc_program_index_asc top ON o.patient_program_id = top.patient_program_id
SET o.index_asc_enrollment = top.index_asc;

UPDATE ovc_encounters o INNER JOIN temp_ovc_program_index_desc top ON o.patient_program_id = top.patient_program_id
SET o.index_desc_enrollment = top.index_desc;

###### for the below indexes, we have to remove null values since they lead to index miscalcs
# non null hiv status table
DROP TEMPORARY TABLE IF EXISTS temp_non_null_hiv_status;
CREATE TEMPORARY TABLE temp_non_null_hiv_status
SELECT * FROM ovc_encounters WHERE hiv_status IS NOT NULL AND ovc_program_enrollment_date IS NOT NULL AND encounter_date IS NOT NULL;

# ascending
DROP TEMPORARY TABLE IF EXISTS temp_hiv_index_asc;
CREATE TEMPORARY TABLE temp_hiv_index_asc
(
    SELECT
			person_id,
			patient_program_id,
			encounter_id,
			encounter_date,
			ovc_program_enrollment_date,
			ovc_program_completion_date,
			hiv_status,
			state,
			patient_state_id,
			program_status_start_date,
			program_status_end_date,
            index_asc_hiv
    FROM (SELECT
            @v:= IF(@x <> patient_program_id, @v:=1, IF(@w <> hiv_status, @v + 1, @v)) index_asc_hiv,
            person_id,
			patient_program_id,
			encounter_id,
			encounter_date,
			ovc_program_enrollment_date,
			ovc_program_completion_date,
			hiv_status,
			state,
			patient_state_id,
			program_status_start_date,
			program_status_end_date,
            @w:= IFNULL(hiv_status, @w),
            @x:= patient_program_id
      FROM temp_non_null_hiv_status,
            (SELECT @w:= ' ') AS w,
            (SELECT @x:= 0) AS x,
            (SELECT @v:= 0) AS v
      ORDER BY person_id, patient_program_id ASC, encounter_date ASC
        ) index_ascending);

## descending
DROP TEMPORARY TABLE IF EXISTS temp_hiv_index_desc;
CREATE TEMPORARY TABLE temp_hiv_index_desc
(
    SELECT
            person_id,
            patient_program_id,
            encounter_id,
            encounter_date,
            ovc_program_enrollment_date,
            ovc_program_completion_date,
            hiv_status,
            state,
            patient_state_id,
            program_status_start_date,
            program_status_end_date,
            index_desc_hiv
FROM (SELECT
            @v:= IF(@x <> patient_program_id, @v:=1, IF(@w <> hiv_status, @v + 1, @v)) index_desc_hiv,
            person_id,
            patient_program_id,
            encounter_id,
            encounter_date,
            ovc_program_enrollment_date,
            ovc_program_completion_date,
            hiv_status,
            state,
            patient_state_id,
            program_status_start_date,
            program_status_end_date,
            @w:= IFNULL(hiv_status, @w),
            @x:= patient_program_id
      FROM temp_non_null_hiv_status,
            (SELECT @w:= ' ') AS w,
            (SELECT @x:= 0) AS x,
            (SELECT @v:= 0) AS v
      ORDER BY person_id, patient_program_id DESC, encounter_date DESC
        ) index_descending);

## adding the above indexes into the ovc_encounters table
UPDATE ovc_encounters o INNER JOIN temp_hiv_index_asc th ON o.encounter_id = th.encounter_id
SET o.index_asc_hiv_status = th.index_asc_hiv;

UPDATE ovc_encounters o INNER JOIN temp_hiv_index_desc th ON o.encounter_id = th.encounter_id
SET o.index_desc_hiv_status = th.index_desc_hiv;

######## program status indexes
# ascending
DROP TEMPORARY TABLE IF EXISTS temp_program_status_index_asc;
CREATE TEMPORARY TABLE temp_program_status_index_asc
(
    SELECT
            patient_id,
            patient_program_id,
            encounter_id,
            encounter_date,
            hiv_status,
            state,
            patient_state_id,
            program_status_start_date,
            program_status_end_date,
            program_date_created,
            index_prog_status_asc
    FROM (SELECT
            @m:= IF(@l <> patient_program_id , @m:=1, IF(@n <> state, @m + 1, @m)) index_prog_status_asc,
            patient_id,
            patient_program_id,
            encounter_id,
            encounter_date,
            hiv_status,
            state,
            patient_state_id,
            program_status_start_date,
            program_status_end_date,
            program_date_created,
            @n:= state,
            @l:= patient_program_id
      FROM temp_ovc_program_status,
            (SELECT @m:= 1) AS m,
            (SELECT @n:= 0) AS n,
            (SELECT @l:= 0) AS l
      ORDER BY patient_id, patient_program_id ASC, program_status_start_date ASC, program_date_created ASC
        ) index_ascending );

# descending
DROP TEMPORARY TABLE IF EXISTS temp_program_status_index_desc;
CREATE TEMPORARY TABLE temp_program_status_index_desc
(
    SELECT
            patient_id,
            patient_program_id,
            encounter_id,
            encounter_date,
            hiv_status,
            state,
            patient_state_id,
            program_status_start_date,
            program_status_end_date,
            program_date_created,
            index_prog_status_desc
    FROM (SELECT
            @m:= IF(@l <> patient_program_id , @m:=1, IF(@n <> state, @m + 1, @m)) index_prog_status_desc,
            patient_id,
            patient_program_id,
            encounter_id,
            encounter_date,
            hiv_status,
            state,
            patient_state_id,
            program_status_start_date,
            program_status_end_date,
            program_date_created,
            @n:= state,
            @l:= patient_program_id
      FROM temp_ovc_program_status,
            (SELECT @m:= 1) AS m,
            (SELECT @n:= 0) AS n,
            (SELECT @l:= 0) AS l
      ORDER BY patient_id, patient_program_id DESC, program_status_start_date DESC, program_date_created DESC
        ) index_descending );

## adding the above indexes into the program status table
UPDATE temp_ovc_program_status o INNER JOIN temp_program_status_index_desc tn ON o.patient_state_id = tn.patient_state_id
SET o.index_desc_program_status = tn.index_prog_status_desc;

UPDATE temp_ovc_program_status o INNER JOIN temp_program_status_index_asc tn ON o.patient_state_id = tn.patient_state_id
SET o.index_asc_program_status = tn.index_prog_status_asc;

UPDATE temp_ovc_program_status o INNER JOIN temp_ovc_program_index_asc top ON o.patient_program_id = top.patient_program_id
SET o.index_asc_enrollment = top.index_asc,
	o.date_enrolled = top.date_enrolled,
    o.date_completed = top.date_completed;

UPDATE temp_ovc_program_status o INNER JOIN temp_ovc_program_index_desc top ON o.patient_program_id = top.patient_program_id
SET o.index_desc_enrollment = top.index_desc;

# indexes for temp_program_no_statuses_encounters table
UPDATE temp_program_no_statuses o INNER JOIN temp_ovc_program_index_asc top ON o.patient_program_id = top.patient_program_id
SET o.index_asc_enrollment = top.index_asc;

UPDATE temp_program_no_statuses o INNER JOIN temp_ovc_program_index_desc top ON o.patient_program_id = top.patient_program_id
SET o.index_desc_enrollment = top.index_desc;

######
# remove duplicates 
drop temporary table if exists temp_program_no_statuses_encounters;
create temporary table temp_program_no_statuses_encounters
select 
	o.patient_id,
    o.patient_program_id,
    o.encounter_id,
    o.encounter_date,
    o.date_enrolled,
    o.date_completed,
    o.hiv_status,
    o.hiv_test_date,
    o.services,
    o.other_services,
    o.location_id,
    o.outcome_concept_id,
    o.program_outcome,
    o.state,
    o.program_status,
    o.patient_state_id,
    o.program_status_start_date,
    o.program_status_end_date,
    o.program_date_created,
    o.index_asc_hiv_status,
    o.index_desc_hiv_status,
    o.index_asc_program_status,
    o.index_desc_program_status,
    o.index_asc_enrollment,
    o.index_desc_enrollment
from temp_program_no_statuses o where patient_program_id not in (select patient_program_id from stage_temp_program_no_statuses);

### final table
### Join encounters and program statuses and programs with no encounters or statuses
drop temporary table if exists temp_ovc_program_status_encounters;
create temporary table temp_ovc_program_status_encounters
select * from ovc_encounters
union all 
select * from temp_ovc_program_status
union all
select * from temp_program_no_statuses_encounters;

###### Final query #######
SELECT
    person_id,
	ZLEMR(person_id),
	patient_program_id,
	LOCATION_NAME(location_id),
	encounter_id,
	encounter_date,
	ovc_program_enrollment_date,
	ovc_program_completion_date,
	program_status_start_date,
	program_status_end_date,
	program_status,
	program_outcome,
	hiv_test_date,
	hiv_status,
	services,
	other_services,
	index_asc_hiv_status,
	index_desc_hiv_status,
	index_asc_program_status,
	index_desc_program_status,
	index_asc_enrollment,
	index_desc_enrollment
 FROM temp_ovc_program_status_encounters ORDER BY person_id, patient_program_id, state, encounter_date;