CREATE TABLE all_lab_orders
(
        patient_id	                        INT,
        emr_id                              VARCHAR(50),
        loc_registered                      VARCHAR(255),
        unknown_patient                     VARCHAR(11),
        gender                              VARCHAR(50),
        age_at_enc                          FLOAT,
        patient_address                     TEXT,
        order_number                        VARCHAR(50),
        Lab_ID                              VARCHAR(50),
        orderable                           VARCHAR(50),
        status                              VARCHAR(50),
        orderer                             VARCHAR(255),
        orderer_provider_type               VARCHAR(50),
        order_datetime                      DATETIME,
        ordering_location                   TEXT,
        urgency                             VARCHAR(50),
        specimen_collection_datetime        DATETIME,
        collection_date_estimated           VARCHAR(11),
        test_location                       VARCHAR(225),
        result_date                         DATETIME
);