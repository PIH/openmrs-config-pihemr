#### This report returns a row per encounter for the
#### discharge encounter_type

## sql updates
SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

-- Delete temporary covid encounter table if exists
DROP TEMPORARY TABLE IF EXISTS temp_covid_discharge;

-- create temporary tale temp_covid_encounters
CREATE TEMPORARY TABLE temp_covid_discharge
(
	encounter_id 			          INT PRIMARY KEY,
	encounter_type_id			      INT,
	patient_id 				          INT,
	encounter_date	 			      DATE,
	encounter_type				      VARCHAR(255),
	location				            TEXT,
	oxygen_therapy				      VARCHAR(11),
  non_inv_ventilation 	      VARCHAR(11),
	vasopressors 				        VARCHAR(11),
	antibiotics					        VARCHAR(11),
	other_intervention 		      TEXT,
	icu							            VARCHAR(11),
	amoxicillin 				        VARCHAR(11),
	doxycycline					        VARCHAR(11),
	other_antibiotics			      VARCHAR(11),
	other_antibiotics_specified TEXT,
	corticosteroids				      VARCHAR(11),
	antifungal_agent 			      VARCHAR(11),
	paracetamol					        VARCHAR(11),
	other_medications			      TEXT
);
-- insert into temp_covid_encounters
INSERT INTO temp_covid_discharge
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
	ENCOUNTER_LOCATION_NAME(encounter_id)
FROM
	encounter
WHERE
	voided = 0
	AND encounter_type IN (ENCOUNTER_TYPE('COVID-19 Discharge'));

UPDATE temp_covid_discharge tc LEFT JOIN encounter_type et ON tc.encounter_type_id = et.encounter_type_id
SET encounter_type = et.name;

## Delet test patients
DELETE FROM temp_covid_discharge
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

## Therapy
-- oxygen therapy
UPDATE temp_covid_discharge SET oxygen_therapy = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165864', 'en');

-- non-invasive ventilation (BiPAP, CPAP)
UPDATE temp_covid_discharge  SET non_inv_ventilation = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165945', 'en');

-- vasopressors
UPDATE temp_covid_discharge  SET vasopressors = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165926', 'en');

-- antibiotics
UPDATE temp_covid_discharge  SET antibiotics = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165991', 'en');

-- other interventions
UPDATE temp_covid_discharge SET other_intervention = OBS_VALUE_TEXT(encounter_id, 'CIEL', '165264');

-- ICU
UPDATE temp_covid_discharge SET icu = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165644', 'CIEL', '1065');

-- amoxicillin
UPDATE temp_covid_discharge SET amoxicillin = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'MEDICATION ORDERS', 'PIH', 'AMOXICILLIN');

-- doxycycline
UPDATE temp_covid_discharge SET doxycycline = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'MEDICATION ORDERS', 'PIH', 'DOXYCYCLINE');

-- other antibiotic
UPDATE temp_covid_discharge SET other_antibiotics = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'MEDICATION ORDERS', 'PIH', '12974');

-- other antibiotic specify
UPDATE temp_covid_discharge SET  other_antibiotics_specified = OBS_COMMENTS(encounter_id, 'PIH', 'MEDICATION ORDERS', 'PIH', '12974');

-- corticosteroids
UPDATE temp_covid_discharge SET corticosteroids = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'MEDICATION ORDERS', 'CIEL', '165948');

-- antifungal agent
UPDATE temp_covid_discharge SET antifungal_agent = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'MEDICATION ORDERS', 'PIH', '918');

-- paracetamol
UPDATE temp_covid_discharge SET paracetamol = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'MEDICATION ORDERS', 'PIH', 'Paracetamol');

-- other meds
UPDATE temp_covid_discharge SET other_medications = OBS_VALUE_TEXT(encounter_id, 'PIH', 'Medication comments (text)');

### Final query
SELECT
      encounter_id,
      encounter_type_id,
      patient_id,
      encounter_date,
      encounter_type,
      location,
      oxygen_therapy,
      non_inv_ventilation,
      vasopressors,
      antibiotics,
      other_intervention,
      IF(icu like "%Yes%", 1, NULL)					icu,
      IF(amoxicillin like "%Yes%", 1, NULL)			amoxicillin,
      IF(doxycycline like "%Yes%", 1, NULL)			doxycycline,
      IF(other_antibiotics like "%Yes%", 1, NULL)		other_antibiotics,
      other_antibiotics_specified,
      IF(corticosteroids like "%Yes%", 1, NULL)		corticosteroids,
      IF(antifungal_agent like "%Yes%", 1, NULL)		antifungal_agent,
      IF(paracetamol like "%Yes%", 1, NULL)			paracetamol,
      other_medications
from temp_covid_discharge order by patient_id;