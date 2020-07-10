CREATE TABLE covid_disposition
(
  encounter_id          INT PRIMARY KEY,
  encounter_type_id     INT,
  patient_id 						INT,
  encounter_date        DATE,
  encounter_type				VARCHAR(255),
  location						  TEXT,
  disposition						VARCHAR(255),
  discharge_condition		VARCHAR(255)
);