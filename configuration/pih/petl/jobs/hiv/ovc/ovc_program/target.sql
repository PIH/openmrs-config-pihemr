CREATE TABLE ovc_program
(
    patient_program_id  INT,
    zlemr_id            VARCHAR(50),
    patient_id          INT,
    date_enrolled       DATE,
    date_completed      DATE,
    location            VARCHAR(255),
    program_status      VARCHAR(255),
    outcome             VARCHAR(255),
    index_asc           INT,
    index_desc          INT
);