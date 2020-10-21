create table hiv_patient
(
    patient_id                  INT PRIMARY KEY,
    zl_emr_id                   VARCHAR(255),
    hivemr_v1_id                VARCHAR(255),
    hiv_dossier_id              VARCHAR(255),
    given_name                  VARCHAR(50),
    family_name                 VARCHAR(50),
    gender                      VARCHAR(50),
    birthdate                   DATE,
    dead                        VARCHAR(1),
    death_date                  DATE,
    cause_of_death              VARCHAR(255),
    cause_of_death_non_coded    VARCHAR(255),
    patient_msm                 VARCHAR(11),
    patient_sw                  VARCHAR(11),
    patient_pris                VARCHAR(11),
    patient_trans               VARCHAR(11),
    patient_idu                 VARCHAR(11)
);
