#### This report returns lab tests and their results.
### The encounters are collected from the lab results app, covid admission and coivd progess forms

## sql updates
SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

-- Delete temporary covid lab table if exists
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_encounters;
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_results_app_encounter;
DROP TEMPORARY TABLE IF EXISTS temp_final_covid_lab_encounters;
DROP TABLE IF EXISTS temp_covid_lab_app_result;

-- create temporary tale temp_covid_lab_encounters
-- encounters from covid forms
CREATE TEMPORARY TABLE temp_covid_lab_encounters
(
	encounter_id        INT,
	encounter_type_id   INT,
	patient_id          INT,
	encounter_date      DATE,
	encounter_type      VARCHAR(255),
	location            TEXT,
	specimen_source     VARCHAR(255),
	concept_id			INT,
	value_coded		    INT,
	obs_id				INT
);
INSERT INTO temp_covid_lab_encounters
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

-- encounters from lab results app
CREATE TEMPORARY TABLE temp_covid_lab_results_app_encounter
(
	encounter_id        INT,
	encounter_type_id   INT,
	patient_id          INT,
	encounter_date      DATE,
	encounter_type      VARCHAR(255),
	location            TEXT,
	specimen_source     VARCHAR(255),
	concept_id			INT,
	value_coded			INT,
	obs_id				INT
);
INSERT INTO temp_covid_lab_results_app_encounter(
	encounter_id,
    encounter_type_id,
    patient_id,
    encounter_date,
    location,
    concept_id,
    value_coded,
    obs_id
)
SELECT
	e.encounter_id,
    encounter_type,
    patient_id,
    DATE(encounter_datetime),
    ENCOUNTER_LOCATION_NAME(e.encounter_id),
    concept_id,
    value_coded,
    obs_id
FROM encounter e INNER JOIN obs o ON e.encounter_id = o.encounter_id AND e.patient_id = o.person_id AND o.voided = 0 AND e.voided = 0 WHERE encounter_type = ENCOUNTER_TYPE('Laboratory Results')
AND concept_id IN (CONCEPT_FROM_MAPPING("CIEL", "165853"), CONCEPT_FROM_MAPPING("CIEL", "165852"), CONCEPT_FROM_MAPPING("CIEL", "165840"), CONCEPT_FROM_MAPPING("CIEL", "165865"));

CREATE TEMPORARY TABLE temp_final_covid_lab_encounters AS
SELECT * FROM temp_covid_lab_encounters
UNION ALL
SELECT * FROM temp_covid_lab_results_app_encounter
;

-- Delete test patients
DELETE FROM temp_final_covid_lab_encounters
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


UPDATE temp_final_covid_lab_encounters tc LEFT JOIN encounter_type et ON tc.encounter_type_id = et.encounter_type_id
SET encounter_type = et.name;

### lab set(specimen set) -- parent obs
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_specimen_set;
CREATE TEMPORARY TABLE temp_covid_lab_specimen_set (
SELECT obs_id, person_id, encounter_id, obs_datetime,
location_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING('PIH', '12973') AND encounter_id IN (SELECT encounter_id FROM temp_final_covid_lab_encounters)
);

### specimen source
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_specimen_source;
CREATE TEMPORARY TABLE temp_covid_lab_specimen_source
(
SELECT
    person_id,
    encounter_id,
    obs_id,
    obs_group_id,
    concept_id,
    CONCEPT_NAME(concept_id, 'en'),
    GROUP_CONCAT(value_coded),
    GROUP_CONCAT(CONCEPT_NAME(value_coded, 'en') SEPARATOR " | ") specimen_source
FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING('CIEL', '159959') AND obs_group_id IN (SELECT DISTINCT(obs_id) FROM obs)
GROUP BY obs_group_id
ORDER BY person_id
);

## specimen collection date
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_specimen_date;
CREATE TEMPORARY TABLE temp_covid_lab_specimen_date
(
SELECT
	person_id,
    encounter_id,
    obs_id,
    obs_group_id,
    concept_id,
    CONCEPT_NAME(concept_id, 'en'),
    value_datetime
FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING('PIH', 'SPUTUM COLLECTION DATE') AND obs_group_id IN (SELECT DISTINCT(obs_id) FROM obs) ORDER BY person_id
);

### Antibody results
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_antibody;
CREATE TEMPORARY TABLE temp_covid_lab_antibody
(
SELECT
	person_id,
    encounter_id,
    obs_id,
    obs_group_id,
    concept_id,
    value_coded,
    CONCEPT_NAME(concept_id, 'en'),
    CONCEPT_NAME(value_coded, 'en')
FROM obs
WHERE voided = 0
AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '165853') AND obs_group_id IN (SELECT DISTINCT(obs_id) FROM obs) ORDER BY person_id
);

### Antigen results
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_antigen;
CREATE TEMPORARY TABLE temp_covid_lab_antigen
(
SELECT
	person_id,
    encounter_id,
    obs_id,
    obs_group_id,
    concept_id,
    value_coded,
    CONCEPT_NAME(concept_id, 'en'),
    CONCEPT_NAME(value_coded, 'en')
FROM obs
WHERE voided = 0
AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '165852') AND obs_group_id IN (SELECT DISTINCT(obs_id) FROM obs) ORDER BY person_id
);

### RT PCR
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_pcr;
CREATE TEMPORARY TABLE temp_covid_lab_pcr
(
SELECT
	person_id,
    encounter_id,
    obs_id,
    obs_group_id,
    concept_id,
    value_coded,
    CONCEPT_NAME(concept_id, 'en'),
    CONCEPT_NAME(value_coded, 'en')
FROM obs
WHERE voided = 0
AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '165840') AND obs_group_id IN (SELECT DISTINCT(obs_id) FROM obs) ORDER BY person_id
);

### Gene Expert
DROP TEMPORARY TABLE IF EXISTS temp_covid_gene_expert;
CREATE TEMPORARY TABLE temp_covid_gene_expert
(
SELECT
	person_id,
    encounter_id,
    obs_id,
    obs_group_id,
    concept_id,
    value_coded,
    CONCEPT_NAME(concept_id, 'en'),
    CONCEPT_NAME(value_coded, 'en')
FROM obs
WHERE voided = 0
AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '165865') AND obs_group_id IN (SELECT DISTINCT(obs_id) FROM obs) ORDER BY person_id
);

## Lab test ordered
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_test_ordered;
CREATE TEMPORARY TABLE temp_covid_lab_test_ordered
(
SELECT
	person_id,
    encounter_id,
    obs_id,
    obs_group_id,
    concept_id,
    value_coded,
    CONCEPT_NAME(concept_id, 'en'),
    CONCEPT_NAME(value_coded, 'en')
FROM obs
WHERE voided = 0
AND concept_id = CONCEPT_FROM_MAPPING('PIH', 'Lab test ordered coded')
AND obs_group_id IN (SELECT DISTINCT(obs_id) FROM obs) ORDER BY person_id
);

### final table for the lab results
DROP TEMPORARY TABLE IF EXISTS temp_covid_specimen_results;
CREATE TEMPORARY TABLE temp_covid_specimen_results
SELECT
		lt.person_id,
		lt.obs_group_id,
        lt.encounter_id,
		MAX(IF(lt.value_coded = CONCEPT_FROM_MAPPING('CIEL', '165853'), 'Yes', NULL)) antibody,
        CONCEPT_NAME(la.value_coded, 'en') antibody_results,
		MAX(IF(lt.value_coded = CONCEPT_FROM_MAPPING('CIEL', '165852'), 'Yes', NULL)) antigen,
        CONCEPT_NAME(lan.value_coded, 'en') antigen_results,
		MAX(IF(lt.value_coded = CONCEPT_FROM_MAPPING('CIEL', '165840'), 'Yes', NULL)) pcr,
        CONCEPT_NAME(lp.value_coded, 'en') pcr_results,
		MAX(IF(lt.value_coded = CONCEPT_FROM_MAPPING('CIEL', '165865'), 'Yes', NULL)) genexpert,
        CONCEPT_NAME(lg.value_coded, 'en') genexpert_results
FROM
	temp_covid_lab_test_ordered lt
LEFT OUTER JOIN
	temp_covid_lab_antigen lan ON lt.obs_group_id = lan.obs_group_id
LEFT OUTER JOIN
	temp_covid_lab_antibody la ON lt.obs_group_id = la.obs_group_id
LEFT OUTER JOIN
	temp_covid_lab_pcr lp ON lt.obs_group_id = lp.obs_group_id
 LEFT OUTER JOIN
	 temp_covid_gene_expert lg ON lt.obs_group_id = lg.obs_group_id
 GROUP BY lt.obs_group_id;

#### Lab results app section
CREATE TEMPORARY TABLE temp_covid_lab_app_result
(
    patient_id          INT,
    encounter_id        INT,
    obs_id              INT,
    encounter_date      DATE,
    location            VARCHAR(255),
    encounter_type      VARCHAR(255),
    specimen_date       DATE,
    date_for_reporting  DATE,
    specimen_source     VARCHAR(255),
    antibody            VARCHAR(255),
    antibody_results    VARCHAR(255),
    antigen             VARCHAR(255),
    antigen_results     VARCHAR(255),
    pcr                 VARCHAR(255),
    pcr_results         VARCHAR(255),
    genexpert           VARCHAR(255),
    genexpert_results   VARCHAR(255)
);

INSERT INTO temp_covid_lab_app_result(encounter_id, encounter_date, encounter_type, location)
SELECT DISTINCT(encounter_id), encounter_date, encounter_type, location FROM temp_final_covid_lab_encounters WHERE encounter_type_id = ENCOUNTER_TYPE('Laboratory Results');

UPDATE temp_covid_lab_app_result tcl INNER JOIN temp_final_covid_lab_encounters tfcl ON tcl.encounter_id = tfcl.encounter_id
SET tcl.patient_id = tfcl.patient_id,
	tcl.specimen_date = tfcl.encounter_date,
    tcl.date_for_reporting = tfcl.encounter_date;

### Antibody lab results app
UPDATE temp_covid_lab_app_result tcl INNER JOIN temp_final_covid_lab_encounters tfc ON tcl.encounter_id = tfc.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '165853')
SET antibody_results = CONCEPT_NAME(value_coded, 'en'),
    tcl.obs_id = tfc.obs_id;

### Antigen lab results app
UPDATE temp_covid_lab_app_result tcl INNER JOIN temp_final_covid_lab_encounters tfc ON tcl.encounter_id = tfc.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '165852')
SET antigen_results = CONCEPT_NAME(value_coded, 'en');

### RT PCR lab results app
UPDATE temp_covid_lab_app_result tcl INNER JOIN temp_final_covid_lab_encounters tfc ON tcl.encounter_id = tfc.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '165840')
SET pcr_results = CONCEPT_NAME(value_coded, 'en');

### Gene expert lab results app
UPDATE temp_covid_lab_app_result tcl INNER JOIN temp_final_covid_lab_encounters tfc ON tcl.encounter_id = tfc.encounter_id AND concept_id = CONCEPT_FROM_MAPPING('CIEL', '165865')
SET genexpert_results = CONCEPT_NAME(value_coded, 'en');

### Final query
DROP TEMPORARY TABLE IF EXISTS temp_final_query;
CREATE TEMPORARY TABLE temp_final_query AS
SELECT
		ls.person_id patient_id,
        ls.encounter_id encounter_id,
        ls.obs_id,
        e.encounter_date,
        e.location,
        e.encounter_type,
		DATE(lspd.value_datetime) specimen_date,
        COALESCE(DATE(lspd.value_datetime), e.encounter_date) date_for_reporting,
        lss.specimen_source,
		lsr.antibody,
        antibody_results,
        antigen,
        antigen_results,
        pcr,
        pcr_results,
        genexpert,
        genexpert_results
FROM
	temp_covid_lab_specimen_set ls
LEFT OUTER JOIN
	temp_final_covid_lab_encounters e ON e.encounter_id = ls.encounter_id
LEFT OUTER JOIN
	temp_covid_lab_specimen_date lspd ON ls.obs_id = lspd.obs_group_id
LEFT OUTER JOIN
temp_covid_specimen_results lsr ON ls.obs_id = lsr.obs_group_id
LEFT OUTER JOIN
temp_covid_lab_specimen_source lss ON ls.obs_id = lss.obs_group_id
ORDER BY ls.person_id, ls.encounter_id, lspd.value_datetime;

SELECT * FROM temp_final_query
UNION ALL
SELECT * FROM temp_covid_lab_app_result;