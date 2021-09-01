DROP TEMPORARY TABLE IF EXISTS datakind_patient_program;
CREATE TEMPORARY TABLE datakind_patient_program
AS
SELECT
    patient_id,
    program_id,
    date_enrolled,
    date_completed,
    CONCEPT_NAME(outcome_concept_id, 'en') outcome,
    date_created,
    date_changed
FROM
    patient_program pp
    WHERE voided = 0;

SELECT
	patient_id,
    pp.name,
    date_enrolled,
    date_completed,
    outcome,
    p.date_created,
    p.date_changed
FROM
datakind_patient_program p JOIN program pp ON p.program_id = pp.program_id order by patient_id;