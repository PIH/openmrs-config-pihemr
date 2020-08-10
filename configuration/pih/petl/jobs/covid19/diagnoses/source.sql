#### This report returns a row per diagnosis

## sql updates
SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

-- Delete temporary covid encounter table if exists
DROP TEMPORARY TABLE IF EXISTS temp_covid_encounters;

-- create temporary tale temp_covid_encounters
CREATE TEMPORARY TABLE temp_covid_encounters
(
	encounter_id 			    INT,
	encounter_type_id     INT,
	patient_id            INT,
	encounter_date        DATE,
	encounter_type        VARCHAR(255),
	location              TEXT,
	covid19_diagnosis     VARCHAR(255)
);

-- insert into temp_covid_encounters
INSERT INTO temp_covid_encounters
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
	AND encounter_type IN (ENCOUNTER_TYPE('COVID-19 Admission'), ENCOUNTER_TYPE('COVID-19 Progress'), ENCOUNTER_TYPE('COVID-19 Discharge'));

UPDATE temp_covid_encounters tc LEFT JOIN encounter_type et ON tc.encounter_type_id = et.encounter_type_id
SET encounter_type = et.name;

-- Delete test patients
DELETE FROM temp_covid_encounters
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

-- COVID 19
UPDATE temp_covid_encounters SET covid19_diagnosis = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165793', 'en');

## Diagnosis
DROP TEMPORARY TABLE IF EXISTS temp_covid_diagnosis;
CREATE TEMPORARY TABLE temp_covid_diagnosis
(
  person_id     INT,
  encounter_id  INT,
  obs_id        INT,
  obs_group_id  INT,
  concept_id    INT,
  concept_names TEXT,
  value_coded   INT,
  diagnosis     TEXT
);

INSERT INTO temp_covid_diagnosis
(
  person_id,
  encounter_id,
  obs_id,
  obs_group_id,
  concept_id,
  concept_names,
  value_coded,
  diagnosis
)
SELECT
  person_id,
  encounter_id,
  obs_id,
  obs_group_id,
  concept_id,
  CONCEPT_NAME(concept_id, 'en'),
  value_coded,
  IFNULL(CONCEPT_NAME(value_coded, 'en'), value_text)
FROM
  obs
WHERE
    voided = 0
AND concept_id IN (CONCEPT_FROM_MAPPING('PIH', 'DIAGNOSIS'), CONCEPT_FROM_MAPPING('PIH', 'Diagnosis or problem, non-coded'))
AND obs_group_id IN (SELECT
    obs_id
FROM
    obs
WHERE
    voided = 0
AND CONCEPT_FROM_MAPPING('PIH', 'Visit Diagnoses')) AND encounter_id IN (SELECT encounter_id FROM temp_covid_encounters)
ORDER BY person_id;

### Diagnosis confirmation
DROP TEMPORARY TABLE IF EXISTS temp_covid_diagnosis_confirmation;
CREATE TEMPORARY TABLE temp_covid_diagnosis_confirmation
(
  person_id     INT,
  encounter_id  INT,
  obs_id        INT,
  obs_group_id  INT,
  concept_id    INT,
  concept_names TEXT,
  value_coded   INT,
  diagnosis_confirmation TEXT
);

INSERT INTO temp_covid_diagnosis_confirmation
(
  person_id,
  encounter_id,
  obs_id,
  obs_group_id,
  concept_id,
  concept_names,
  value_coded,
  diagnosis_confirmation
)
SELECT
  person_id,
  encounter_id,
  obs_id,
  obs_group_id,
  concept_id,
  CONCEPT_NAME(concept_id, 'en'),
  value_coded,
  CONCEPT_NAME(value_coded, 'en')
FROM
  obs
WHERE
    voided = 0
AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'CLINICAL IMPRESSION DIAGNOSIS CONFIRMED')
AND obs_group_id IN (SELECT obs_id
FROM
  obs
WHERE
  voided = 0
AND CONCEPT_FROM_MAPPING('PIH', 'Visit Diagnoses')) AND encounter_id IN (SELECT encounter_id FROM temp_covid_encounters)
ORDER BY person_id;

# Diagnosis_order
DROP TEMPORARY TABLE IF EXISTS temp_covid_diagnosis_order;
CREATE TEMPORARY TABLE temp_covid_diagnosis_order
(
  person_id       INT,
  encounter_id    INT,
  obs_id          INT,
  obs_group_id    INT,
  concept_id      INT,
  concept_names   TEXT,
  value_coded     INT,
  diagnosis_order TEXT
);

INSERT INTO temp_covid_diagnosis_order
(
  person_id,
  encounter_id,
  obs_id,
  obs_group_id,
  concept_id,
  concept_names,
  value_coded,
  diagnosis_order
)
SELECT
  person_id,
  encounter_id,
  obs_id,
  obs_group_id,
  concept_id,
  CONCEPT_NAME(concept_id, 'en'),
  value_coded,
  CONCEPT_NAME(value_coded, 'en')
FROM
  obs
WHERE
  voided = 0
AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Diagnosis order')
AND obs_group_id IN (SELECT
  obs_id
FROM
  obs
WHERE
  voided = 0
AND CONCEPT_FROM_MAPPING('PIH', 'Visit Diagnoses')) AND encounter_id IN (SELECT encounter_id FROM temp_covid_encounters)
ORDER BY person_id;

##### FINAL QUERY EXECUTION
SELECT
  ce.patient_id,
  ce.encounter_id,
  ce.encounter_type,
  ce.location,
  ce.encounter_date,
  dor.diagnosis_order,
  d.diagnosis,
  dc.diagnosis_confirmation,
  ce.covid19_diagnosis
FROM
temp_covid_encounters ce
LEFT JOIN
  temp_covid_diagnosis d ON ce.encounter_id = d.encounter_id
LEFT JOIN
temp_covid_diagnosis_confirmation dc ON d.obs_group_id = dc.obs_group_id AND d.encounter_id = dc.encounter_id
LEFT JOIN
temp_covid_diagnosis_order dor ON d.obs_group_id = dor.obs_group_id AND d.encounter_id = dor.encounter_id
ORDER BY ce.patient_id;