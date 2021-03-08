CREATE TABLE mch_status
(
    patient_id                  INT,
    mch_emr_id                  VARCHAR(25),
    enrollment_location         VARCHAR(25),
    encounter_location_name     VARCHAR(25),
    start_date                  DATE,
    end_date                    DATE,
    outcome                     VARCHAR(100),
    antenatal_visit             VARCHAR(5),
    estimated_delivery_date     DATE,
    history_hiv                 VARCHAR(5),
    high_risk_factor_hiv        VARCHAR(5),
    arv_status                  VARCHAR(5),
    patient_disposition         VARCHAR(100),
    transfer                    VARCHAR(100),
    index_asc                   INT,
    index_desc                  INT
);