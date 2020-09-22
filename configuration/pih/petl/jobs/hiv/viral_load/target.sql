CREATE TABLE hiv_viral_load(
        hiv_patient_id                      INT,
        encounter_id                        INT,
        vl_sample_taken_date                DATE,
        vl_sample_taken_date_estimated      VARCHAR(255),
        vl_result_date                      DATE,
        specimen_number                     VARCHAR(255),
        vl_test_outcome                     VARCHAR(255),
        viral_load                          INT,
        detected_lower_limit                INT,
        vl_type                             VARCHAR(255),
        days_since_vl                       INT,
        order_desc                          INT,
        order_asc                           INT
);
