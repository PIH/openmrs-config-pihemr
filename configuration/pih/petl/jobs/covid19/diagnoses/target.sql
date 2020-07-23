CREATE TABLE covid_diagnoses
(
  patient_id              INT,
  encounter_id            INT,
  encounter_type          VARCHAR(255),
  location                TEXT,
  encounter_date          DATE,
  diagnosis_order         TEXT,
  diagnosis               TEXT,
  diagnosis_confirmation  TEXT,
  covid19_diagnosis       VARCHAR(255)
);
