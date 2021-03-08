CREATE TABLE mch_patient
(
    patient_id                      INT,
    pih_emr_id                      VARCHAR(15),
    first_name                      VARCHAR(50),
    last_name                       VARCHAR(50),
    nickname                        VARCHAR(50),
    gender                          CHAR(1),
    age_unknown                     BIT,
    DOB                             DATE,
    age                             DOUBLE,
    current_reporting_health_center VARCHAR(30),
    initital_health_center          VARCHAR(30),
    locality                        VARCHAR(30),
    marital_status                  VARCHAR(20),
    age_cat_1                       VARCHAR(10),
    -- age_cat_2
    antenatal_visit                 BIT,
    estimated_delivery_date         DATE,
    patient_pregnant                BIT
);