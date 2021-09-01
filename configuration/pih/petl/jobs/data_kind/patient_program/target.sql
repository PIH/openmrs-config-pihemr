CREATE TABLE datakind_patient_program
(
    patient_id      INT,
    pp.name         VARCHAR(100),
    date_enrolled   DATETIME,
    date_completed  DATETIME,
    outcome         VARCHAR(100),
    p.date_created  DATETIME,
    p.date_changed  DATETIME
);