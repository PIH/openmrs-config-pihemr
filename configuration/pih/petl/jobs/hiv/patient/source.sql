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

update temp_patient 
set gender = gender(patient_id),
    birthdate = birthdate(patient_id),
    given_name = person_given_name(patient_id),
    family_name = person_family_name(patient_id);

select * from temp_patient;
