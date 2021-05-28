CREATE TABLE mch_birth
(
patient_id      INT,
mother_emr_id   VARCHAR(25),
encounter_date  DATE,
birth_number    INT,
multiples       INT,
birth_apgar     VARCHAR(10),
birth_outcome   VARCHAR(100),
birth_weight    DOUBLE,
birth_neonatal_resuscitation    VARCHAR(10),
birth_macerated_fetus           VARCHAR(10)
);