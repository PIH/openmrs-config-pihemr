DROP TABLE IF EXISTS temp_patient_program;

CREATE TABLE temp_patient_program
(
  patient_program_id int(11),
  patient_id int(11),
  date_enrolled date,
  date_completed date,
  location_id int,
  location varchar(255),
  outcome_concept_id int,
  outcome varchar(255)
);

INSERT into temp_patient_program (patient_program_id, patient_id, date_enrolled, date_completed, location_id,outcome_concept_id)
select patient_program_id, patient_id, date_enrolled, date_completed,location_id,outcome_concept_id from patient_program where voided=0;

update temp_patient_program
set location = location_name(location_id),
    outcome = concept_name(outcome_concept_id, 'en');

select patient_program_id, patient_id, date_enrolled, date_completed, location, outcome from temp_patient_program;

