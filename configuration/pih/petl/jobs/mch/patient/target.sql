CREATE TABLE mch_patient
(
    patient_id                      INT,
    pih_emr_id                      VARCHAR(25),
    first_encounter_type            VARCHAR(150),
    latest_encounter_type           VARCHAR(150),
    first_encounter_date            DATETIME,
    latest_encounter_date           DATETIME,
    initial_health_center           VARCHAR(150),
    current_reporting_health_center VARCHAR(150),
    first_name                      VARCHAR(100),
    last_name                       VARCHAR(100),
    nickname                        VARCHAR(100),
    marital_status                  VARCHAR(100),
    gender                          VARCHAR(5),
    dob                             DATE,
    age_unknown                     VARCHAR(5),
    age                             FLOAT,
    age_cat_1                       VARCHAR(10),
    locality                        VARCHAR(100),
    antenatal_visit                 BIT,
    estimated_delivery_date         DATE,
    pregnant                        BIT
);