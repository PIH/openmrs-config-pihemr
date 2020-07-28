CREATE TABLE covid_discharge
(
  encounter_id                  INT PRIMARY KEY,
  patient_id                    INT,
  encounter_date                DATE,
  encounter_type                VARCHAR(255),
  location                      TEXT,
  oxygen_therapy                VARCHAR(255),
  non_inv_ventilation           VARCHAR(255),
  vasopressors                  VARCHAR(255),
  antibiotics                   VARCHAR(255),
  other_intervention            TEXT,
  icu                           VARCHAR(11),
  amoxicillin                   VARCHAR(11),
  doxycycline                   VARCHAR(11),
  other_antibiotics             VARCHAR(11),
  other_antibiotics_specified   TEXT,
  corticosteroids               VARCHAR(11),
  antifungal_agent              VARCHAR(11),
  paracetamol                   VARCHAR(11),
  other_medications             TEXT
);