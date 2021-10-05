CALL initialize_global_metadata();

DROP TEMPORARY TABLE IF EXISTS temp_non_hiv_eid_patient;
CREATE TEMPORARY TABLE temp_non_hiv_eid_patient AS
SELECT patient_id, ZLEMR(p.patient_id) zlemr FROM patient p WHERE p.voided = 0 AND
p.patient_id NOT IN (SELECT patient_id FROM patient_program pp WHERE pp.voided = 0 AND pp.program_id IN (@hivProgram, @eidProgram));

SELECT 
    p.patient_id,
    zlemr,
    identifier hiv_emr,
    DATE(e.encounter_datetime) patient_registration_date,
    LOCATION_NAME(e.location_id) patient_registration_location
FROM
    temp_non_hiv_eid_patient p
        INNER JOIN
    encounter e ON p.patient_id = e.patient_id
        AND e.voided = 0
        AND encounter_type = @regEnc
        LEFT JOIN
    patient_identifier pi ON pi.patient_id = p.patient_id
        AND pi.identifier_type = @hivDosId;