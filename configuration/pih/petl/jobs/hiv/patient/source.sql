DROP TABLE IF EXISTS temp_patient;

CREATE TABLE temp_patient
(
    patient_id int(11),
    given_name varchar(50),
    family_name varchar(50),
    gender varchar(50),
    birthdate date
);

INSERT into temp_patient (patient_id)
select patient_id from patient where voided=0;

## Delete test patients
DELETE FROM temp_patient WHERE
patient_id IN (
               SELECT
                      a.person_id
                      FROM person_attribute a
                      INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
                      AND a.value = 'true' AND t.name = 'Test Patient'
               );

update temp_patient 
set gender = gender(patient_id),
    birthdate = birthdate(patient_id),
    given_name = person_given_name(patient_id),
    family_name = person_family_name(patient_id);

select * from temp_patient;
