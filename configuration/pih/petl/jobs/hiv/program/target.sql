create table hiv_patient_program
(
    patient_program_id      INT PRIMARY KEY,
    patient_id              INT,
    date_enrolled           DATE,
    date_completed          DATE,
    location                VARCHAR(255),
    outcome                 VARCHAR(255)
);
