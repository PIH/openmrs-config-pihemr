create table vaccinations_anc
(
    patient_id         INT,
    dossier_num        VARCHAR(50),
    zlemr_id           VARCHAR(50),
    loc_registered     VARCHAR(50),
    encounter_datetime DATETIME,
    encounter_location VARCHAR(50),
    encounter_type     VARCHAR(50),
    provider           VARCHAR(500),
    bcg_1              DATETIME,
    polio_0            DATETIME,
    polio_1            DATETIME,
    polio_2            DATETIME,
    polio_3            DATETIME,
    polio_booster_1    DATETIME,
    polio_booster_2    DATETIME,
    pentavalent_1      DATETIME,
    pentavalent_2      DATETIME,
    pentavalent_3      DATETIME,
    rotavirus_1        DATETIME,
    rotavirus_2        DATETIME,
    mmr_1              DATETIME,
    tetanus_0          DATETIME,
    tetanus_1          DATETIME,
    tetanus_2          DATETIME,
    tetanus_3          DATETIME,
    tetanus_booster_1  DATETIME,
    tetanus_booster_2  DATETIME
);


