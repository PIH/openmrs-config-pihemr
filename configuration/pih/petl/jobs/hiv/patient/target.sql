create table hiv_patient
(
    patient_id                  INT PRIMARY KEY,
    given_name                  VARCHAR(50),
    family_name                 VARCHAR(50),
    gender                      VARCHAR(50),
    birthdate                   DATE,
    cause_of_death              VARCHAR(255),
    cause_of_death_non_coded    VARCHAR(255)
);
