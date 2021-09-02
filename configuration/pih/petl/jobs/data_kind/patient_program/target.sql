CREATE TABLE datakind_patient_program
(
    patient_id      INT,
    program_name            VARCHAR(100),
    date_enrolled   DATETIME,
    date_completed  DATETIME,
    outcome         VARCHAR(100),
    date_created    DATETIME,
    date_changed    DATETIME
);