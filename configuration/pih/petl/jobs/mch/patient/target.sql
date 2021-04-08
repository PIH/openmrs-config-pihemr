CREATE TABLE mch_patient
(
    patient_id                      INT,
    pih_emr_id                      VARCHAR(25),
    first_name                      VARCHAR(100),
    last_name                       VARCHAR(100),
    nickname                        VARCHAR(100),
    gender                          VARCHAR(5),
    age_unknown                     VARCHAR(5),
    DOB                             DATE,
    age                             FLOAT,
    current_reporting_health_center VARCHAR(100),
    initital_health_center          VARCHAR(100),
    locality                        VARCHAR(100),
    marital_status                  VARCHAR(100),
    age_cat_1                       VARCHAR(10),
    latest_encounter_date           DATE,
    antenatal_visit                 BIT,
    estimated_delivery_date         DATE,
    patient_pregnant                BIT
);