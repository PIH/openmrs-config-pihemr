CREATE TABLE datakind_encounter
(
    patient_id          INT,
    encounter_id        INT,
    encounter_type      VARCHAR(255),
    encounter_location  TEXT,
    encounter_datetime  DATETIME,
    provider            VARCHAR(255),
    data_entry_clerk    VARCHAR(255),
    date_entered        DATETIME,
    date_changed        DATETIME
);