### This report is a row per encounter report.
### Admission covid encounters

-- Delete temporary admission encounter table if exists
DROP TEMPORARY TABLE IF EXISTS temp_covid_admission_encounter;

-- create temporary admission encounter table
CREATE TEMPORARY TABLE temp_covid_admission_encounter
(
	encounter_id				INT PRIMARY KEY,
	patient_id				INT,
	encounter_datetime			DATE,
	health_care_worker			VARCHAR(11),
	home_medications			TEXT,
  	allergies				TEXT,
  	symptom_start_date			DATE,
  	comorbidities				VARCHAR(11),
 	diabetes_type1				VARCHAR(11),
  	diabetes_type2				VARCHAR(11),
	hypertension				VARCHAR(11),
	epilepsy				VARCHAR(11),
	sickle_cell_anemia			VARCHAR(11),
	rheumatic_heart_disease			VARCHAR(11),
	hiv_disease				VARCHAR(11),
	chronic_kidney_disease			VARCHAR(11),
	asthma					VARCHAR(11),
	copd					VARCHAR(11),
	tuberculosis				VARCHAR(11),
	cardiomyopathy				VARCHAR(11),
	stroke					VARCHAR(11),
	malnutrition				VARCHAR(11),
	psychosis				VARCHAR(11),
	substance_abuse				VARCHAR(11),
	other_comorbidity			VARCHAR(11),
	other_comorbidity_specified		TEXT,
	other_mental_health			TEXT,
	tobacco					VARCHAR(255),
	transfer_from_other_facility		VARCHAR(11),
	transfer_facility_name			TEXT,
	contact_case_14d			VARCHAR(11)
);

-- insert into temp_covid_admission_encounter
INSERT INTO temp_covid_admission_encounter
(
	encounter_id,
	patient_id,
	encounter_datetime
)
SELECT
	encounter_id,
	patient_id,
	DATE(encounter_datetime)
FROM
	encounter
WHERE
	voided = 0
	AND encounter_type in (encounter_type('COVID-19 Admission'));

-- Delete test patients
DELETE FROM temp_covid_admission_encounter
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

-- Health Care Worker
UPDATE temp_covid_admission_encounter SET health_care_worker = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '5619', 'en');

-- Home medication
UPDATE temp_covid_admission_encounter SET home_medications = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162165');

-- Allergies
UPDATE temp_covid_admission_encounter SET allergies = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162141');

-- Symptom start date
UPDATE temp_covid_admission_encounter SET symptom_start_date = OBS_VALUE_DATETIME(encounter_id, 'CIEL', '1730');

-- Comorbidities
-- Comorbidities(yes/no)
UPDATE temp_covid_admission_encounter SET comorbidities = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '12976', 'en');

-- Type 1 DM
UPDATE temp_covid_admission_encounter SET diabetes_type1 = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '142474');

-- Type 2 DM
UPDATE temp_covid_admission_encounter SET diabetes_type2 = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '142473');

-- Hypertension
UPDATE temp_covid_admission_encounter SET hypertension = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '117399');

-- Epilepsy
UPDATE temp_covid_admission_encounter SET epilepsy = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '155');

-- Sickle-cell anemia
UPDATE temp_covid_admission_encounter SET sickle_cell_anemia = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '117703');

-- Rheumatic heart disease
UPDATE temp_covid_admission_encounter SET rheumatic_heart_disease = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '113227');

-- Hiv disease
UPDATE temp_covid_admission_encounter SET hiv_disease = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '138405');

-- Chronic kidney disease
UPDATE temp_covid_admission_encounter SET chronic_kidney_disease = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '145438');

-- asthma
UPDATE temp_covid_admission_encounter SET asthma = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '121375');

-- copd
UPDATE temp_covid_admission_encounter SET copd = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '1295');

-- Tuberculosis
UPDATE temp_covid_admission_encounter SET tuberculosis = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '112141');

-- Cardiomyopathy
UPDATE temp_covid_admission_encounter SET cardiomyopathy = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '5016');

-- Stroke
UPDATE temp_covid_admission_encounter SET stroke = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '111103');

-- Malnutrition
UPDATE temp_covid_admission_encounter SET malnutrition = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '115122');

-- Psychosis
UPDATE temp_covid_admission_encounter SET psychosis = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '113517');

-- Substance abuse
UPDATE temp_covid_admission_encounter SET substance_abuse = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '112603');

-- Other comorbidity
UPDATE temp_covid_admission_encounter SET other_comorbidity = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162747', 'CIEL', '5622');

-- Other comorbidity specify
UPDATE temp_covid_admission_encounter SET other_comorbidity_specified = OBS_COMMENTS(encounter_id, 'CIEL', '162747', 'PIH', 'OTHER');

-- Other mental health
UPDATE temp_covid_admission_encounter SET other_mental_health = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163044');

-- tobacco
UPDATE temp_covid_admission_encounter SET tobacco = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163731', 'en');

-- transfer_from_other_facility
UPDATE temp_covid_admission_encounter SET transfer_from_other_facility = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '160563', 'en');

-- transfer_facility_name
UPDATE temp_covid_admission_encounter SET transfer_facility_name = OBS_VALUE_TEXT(encounter_id, 'CIEL', '161550');

-- contact_case_14d
UPDATE temp_covid_admission_encounter SET contact_case_14d = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162633', 'en');

## EXECUTE FINAL SELECTION
SELECT
	encounter_id,
	patient_id,
	encounter_datetime,
	IF(health_care_worker like "%Yes%", 1, NULL)			health_care_worker,
	home_medications,
	allergies,
	symptom_start_date,
	home_medications,
	allergies,
	symptom_start_date,
	comorbidities,
	IF(diabetes_type1 like "%Yes%", 1, NULL)			diabetes_type1,
	IF(diabetes_type2 like "%Yes%", 1, NULL)			diabetes_type2,
	IF(hypertension like "%Yes%", 1, NULL)				hypertension,
	IF(epilepsy like "%Yes%", 1, NULL)				epilepsy,
	IF(sickle_cell_anemia like "%Yes%", 1, NULL)			sickle_cell_anemia,
	IF(rheumatic_heart_disease like "%Yes%", 1, NULL)		rheumatic_heart_disease,
	IF(hiv_disease like "%Yes%", 1, NULL)				hiv_disease,
	IF(chronic_kidney_disease like "%Yes%", 1, NULL)		chronic_kidney_disease,
	IF(asthma like "%Yes%", 1, NULL)				asthma,
	IF(copd like "%Yes%", 1, NULL)					copd,
	IF(tuberculosis like "%Yes%", 1, NULL)				tuberculosis,
	IF(cardiomyopathy like "%Yes%", 1, NULL)			cardiomyopathy,
	IF(stroke like "%Yes%", 1, NULL)				stroke,
	IF(malnutrition like "%Yes%", 1, NULL)				malnutrition,
	IF(psychosis like "%Yes%", 1, NULL)				psychosis,
	IF(substance_abuse like "%Yes%", 1, NULL)			substance_abuse,
	IF(other_comorbidity like "%Yes%", 1, NULL)			other_comorbidity,
	other_comorbidity_specified,
	other_mental_health,
	tobacco,
	transfer_from_other_facility,
	transfer_facility_name,
	contact_case_14d
FROM temp_covid_admission_encounter ORDER BY patient_id;