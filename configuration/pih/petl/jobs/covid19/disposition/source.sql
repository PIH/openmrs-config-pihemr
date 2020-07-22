### This report is a row per encounter report.
### It returns dispositions recorded per encounter

-- Delete temporary admission encounter table if exists
DROP TEMPORARY TABLE IF EXISTS temp_covid_dispositon;


-- create temporary tale temp_covid_dispositon
CREATE TEMPORARY TABLE temp_covid_dispositon
(
	encounter_id 			        INT PRIMARY KEY,
	encounter_type_id			INT,
	patient_id 				INT,
	encounter_date	 			DATE,
	encounter_type				VARCHAR(255),
	location				TEXT,
	disposition				VARCHAR(255),
	discharge_condition			VARCHAR(255)
);

-- insert into temp_covid_dispositon
INSERT INTO temp_covid_dispositon
(
	encounter_id,
	encounter_type_id,
	patient_id,
	encounter_date,
	location
)
SELECT
	encounter_id,
	encounter_type,
	patient_id,
	DATE(encounter_datetime),
	encounter_location_name(encounter_id)
FROM
	encounter
WHERE
	voided = 0
	AND encounter_type IN (encounter_type('COVID-19 Admission'), encounter_type('COVID-19 Progress'), encounter_type('COVID-19 Discharge'));

-- encounter type
UPDATE temp_covid_dispositon tc LEFT JOIN encounter_type et ON tc.encounter_type_id = et.encounter_type_id
SET encounter_type = et.name;

-- Delete test patients
DELETE FROM temp_covid_dispositon
WHERE
patient_id IN (SELECT
							 a.person_id
							 FROM
							 person_attribute a
								 INNER JOIN
								 person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
							 WHERE
							 a.value = 'true'
							 AND t.name = 'Test Patient');

-- Disposition
UPDATE temp_covid_dispositon SET disposition = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', 'Hum Disposition categories', 'en');

-- Discharge conditions
UPDATE temp_covid_dispositon SET discharge_condition = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '159640', 'en');

SELECT
	patient_id,
	encounter_id,
	encounter_type,
	location,
	encounter_date,
	disposition,				
	discharge_condition			
FROM temp_covid_dispositon ORDER BY patient_id, encounter_type, encounter_date ASC;
