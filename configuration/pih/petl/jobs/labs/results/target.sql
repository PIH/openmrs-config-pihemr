CREATE TABLE lab_results
(
    patient_id                  INT,
    encounter_id                INT,
    specimen_collection_date    DATE,
    sample_taken_date_estimated VARCHAR(11),
    test_result_date            DATE,
    test_related_to             VARCHAR(25),
    test_type                   VARCHAR(255),
    test_status                 VARCHAR(255),
    reason_test_not_perform     VARCHAR(255),
    test_result_text            VARCHAR(255),
    test_result_numeric         FLOAT,
    index_asc                   INT,
    index_desc                  INT,
    date_created                DATETIME
);