#### This report returns a row per encounter
#### for the lab tests

## sql updates
SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

-- Delete temporary covid lab table if exists
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_test;

-- create temporary tale temp_covid_encounters
CREATE TEMPORARY TABLE temp_covid_lab_test
(
	encounter_id        INT PRIMARY KEY,
	encounter_type_id   INT,
	patient_id          INT,
	encounter_date      DATE,
	encounter_type      VARCHAR(255),
	location            TEXT,
	specimen_date1      DATE,
	specimens_type1     VARCHAR(255),
	antibody_result1    VARCHAR(255),
	antigen_result1     VARCHAR(255),
	pcr_result1         VARCHAR(255),
	genexpert_result1   VARCHAR(255),
	specimen_date2      DATE,
	specimens_type2	    VARCHAR(255),
	antibody_result2    VARCHAR(255),
	antigen_result2     VARCHAR(255),
	pcr_result2         VARCHAR(255),
	genexpert_result2   VARCHAR(255),
	specimen_date3      DATE,
	specimens_type3     VARCHAR(255),
	antibody_result3    VARCHAR(255),
	antigen_result3     VARCHAR(255),
	pcr_result3         VARCHAR(255),
	genexpert_result3   VARCHAR(255)
);

-- insert into temp_covid_lab_test
INSERT INTO temp_covid_lab_test
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
	AND encounter_type IN (ENCOUNTER_TYPE('COVID-19 Admission'), ENCOUNTER_TYPE('COVID-19 Progress'));

UPDATE temp_covid_lab_test tc LEFT JOIN encounter_type et ON tc.encounter_type_id = et.encounter_type_id
SET encounter_type = et.name;

-- Delete test patients
DELETE FROM temp_covid_lab_test
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

### Labs
## Sputum collection date1
UPDATE temp_covid_lab_test SET specimen_date1 = OBS_FROM_GROUP_ID_VALUE_DATETIME(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '159951');

## specimen types 1
UPDATE temp_covid_lab_test SET specimens_type1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '159959', 'en');

## Results 1
UPDATE temp_covid_lab_test SET antibody_result1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '165853', 'en');
UPDATE temp_covid_lab_test SET antigen_result1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '165852', 'en');
UPDATE temp_covid_lab_test SET pcr_result1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '165840', 'en');
UPDATE temp_covid_lab_test SET genexpert_result1 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 0), 'CIEL', '165865', 'en');

## Sputum collection date2
UPDATE temp_covid_lab_test SET specimen_date2 = OBS_FROM_GROUP_ID_VALUE_DATETIME(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '159951');

## specimen types 2
UPDATE temp_covid_lab_test SET specimens_type2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '159959', 'en');

## Results 2
UPDATE temp_covid_lab_test SET antibody_result2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '165853', 'en');
UPDATE temp_covid_lab_test SET antigen_result2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '165852', 'en');
UPDATE temp_covid_lab_test SET pcr_result2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '165840', 'en');
UPDATE temp_covid_lab_test SET genexpert_result2 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 1), 'CIEL', '165865', 'en');

## Sputum collection date3
UPDATE temp_covid_lab_test SET specimen_date3 = OBS_FROM_GROUP_ID_VALUE_DATETIME(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '159951');

## specimen types 3
UPDATE temp_covid_lab_test SET specimens_type3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH','12973',2), 'CIEL', '159959', 'en');

## Results 3
UPDATE temp_covid_lab_test SET antibody_result3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '165853', 'en');
UPDATE temp_covid_lab_test SET antigen_result3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '165852', 'en');
UPDATE temp_covid_lab_test SET pcr_result3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '165840', 'en');
UPDATE temp_covid_lab_test SET genexpert_result3 = OBS_FROM_GROUP_ID_VALUE_CODED_LIST(OBS_ID(encounter_id, 'PIH' , '12973', 2), 'CIEL', '165865', 'en');

### Final Query
SELECT
      encounter_id,
      patient_id,
      encounter_date,
      encounter_type,
      location,
      specimen_date1,
      specimens_type1,
      antibody_result1,
      antigen_result1,
      pcr_result1,
      genexpert_result1,
      specimen_date2,
      specimens_type2,
      antibody_result2,
      antigen_result2,
      pcr_result2,
      genexpert_result2,
      specimen_date3,
      specimens_type3,
      antibody_result3,
      antigen_result3,
      pcr_result3,
      genexpert_result3
FROM
      temp_covid_lab_test order by patient_id;