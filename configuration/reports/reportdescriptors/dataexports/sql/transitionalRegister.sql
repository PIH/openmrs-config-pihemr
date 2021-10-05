CALL initialize_global_metadata();

SET @hiv_identifier = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE uuid = '3B954DB1-0D41-498E-A3F9-1E20CCC47323');
SET @hiv_program = (SELECT program_id from program where uuid = "b1cb1fc1-5190-4f7a-af08-48870975dafc");
SET @eid_program = (SELECT program_id from program where uuid = "7e06bf82-9f1a-4218-b68f-823082ef519b");

DROP temporary table temp_non_hiv_eid_patient;
CREATE temporary table temp_non_hiv_eid_patient AS
select patient_id, ZLEMR(p.patient_id) zlemr from patient p where p.voided = 0 and
p.patient_id not in (select patient_id from patient_program pp where pp.voided = 0 and pp.program_id in (@hiv_program, @eid_program));

SELECT
p.patient_id,
zlemr,
identifier hiv_emr,
DATE(e.encounter_datetime) patient_registration_date,
LOCATION_NAME(e.location_id) patient_registration_location
FROM temp_non_hiv_eid_patient p
INNER JOIN encounter e ON p.patient_id = e.patient_id AND e.voided = 0 AND encounter_type = @regEnc
LEFT JOIN patient_identifier pi ON pi.patient_id = p.patient_id AND pi.identifier_type = @hiv_identifier;