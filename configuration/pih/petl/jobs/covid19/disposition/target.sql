CREATE TABLE covid_disposition
(
  patient_id            INT,
  encounter_id          INT PRIMARY KEY,
  encounter_type        VARCHAR(255),
  location              TEXT,
  encounter_date        DATE,
  disposition           VARCHAR(255),
  discharge_condition   VARCHAR(255),
  index_asc 		    INT,
  index_desc 		    INT
);