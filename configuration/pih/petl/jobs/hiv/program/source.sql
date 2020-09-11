DROP TABLE IF EXISTS temp_hiv_patient_program;

CREATE TABLE temp_hiv_patient_program
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

INSERT into temp_hiv_patient_program (patient_program_id, patient_id, date_enrolled, date_completed, location_id,outcome_concept_id)
select patient_program_id, patient_id, date_enrolled, date_completed,location_id,outcome_concept_id
    from patient_program
    where voided=0
    and program_id = (select program_id from program where uuid='b1cb1fc1-5190-4f7a-af08-48870975dafc');

## Delete test patients
DELETE FROM temp_hiv_patient_program WHERE
patient_id IN (
               SELECT
                      a.person_id
                      FROM person_attribute a
                      INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
                      AND a.value = 'true' AND t.name = 'Test Patient'
               );

update temp_hiv_patient_program
set location = location_name(location_id),
    outcome = concept_name(outcome_concept_id, 'en');

select patient_program_id, patient_id, date_enrolled, date_completed, location, outcome from temp_hiv_patient_program;

