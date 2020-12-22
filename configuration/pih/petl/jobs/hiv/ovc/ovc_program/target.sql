CREATE TABLE ovc_program
(
    person_id                   INT,
    patient_program_id          INT,
    zlemr_id                    VARCHAR(50),
    encounter_id                INT,
    encounter_date              DATE,
    date_enrolled               DATE,
    date_completed              DATE,
    program_status              VARCHAR(255),
    outcome                     VARCHAR(255),
    location                    VARCHAR(255),
    hiv_test_date               DATE,
    hiv_status                  VARCHAR(255),
    services                    TEXT,
    other_services              TEXT,
    index_asc_hiv_status        INT,
    index_desc_hiv_status       INT,
    index_asc_program_status    INT,
    index_desc_program_status   INT,
    index_asc_enrollment        INT,
    index_desc_enrollment       INT
);