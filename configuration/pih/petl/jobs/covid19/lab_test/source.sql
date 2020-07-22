#### This report returns lab tests and their results

## sql updates
SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

-- Delete temporary covid lab table if exists
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_encounters;

-- create temporary tale temp_covid_lab_encounters
CREATE TEMPORARY TABLE temp_covid_lab_encounters
(
	encounter_id        INT PRIMARY KEY,
	encounter_type_id   INT,
	patient_id          INT,
	encounter_date      DATE,
	encounter_type      VARCHAR(255),
	location            TEXT,
  specimen_source     VARCHAR(255)
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

UPDATE temp_covid_lab_encounters tc LEFT JOIN encounter_type et ON tc.encounter_type_id = et.encounter_type_id
SET encounter_type = et.name;

-- Delete test patients
DELETE FROM temp_covid_lab_encounters
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

### lab set(specimen set) -- parent obs
DROP TEMPORARY TABLE IF EXISTS temp_covid_lab_specimen_set;
CREATE TEMPORARY TABLE temp_covid_lab_specimen_set (
select obs_id, person_id, encounter_id, obs_datetime, 
location_id from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '12973') and encounter_id in (select encounter_id from temp_covid_lab_encounters)
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
    group_concat(value_coded),
    group_concat(CONCEPT_NAME(value_coded, 'en') separator " | ") specimen_source
FROM obs WHERE voided = 0 AND
concept_id = CONCEPT_FROM_MAPPING('CIEL', '159959') AND obs_group_id IN (SELECT DISTINCT(obs_id) FROM obs) 
group by obs_group_id
ORDER BY person_id
);
 
## speciment collection date
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

### RT PCR
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
DROP temporary table if exists temp_covid_specimen_results;
CREATE temporary table temp_covid_specimen_results
SELECT
		lt.person_id,
		lt.obs_group_id,
    lt.encounter_id,
		MAX(IF(lt.value_coded = CONCEPT_FROM_MAPPING('CIEL', '165853'), 'Yes', NULL)) antibody, 
    concept_name(la.value_coded, 'en') antibody_results,
		MAX(IF(lt.value_coded = CONCEPT_FROM_MAPPING('CIEL', '165852'), 'Yes', NULL)) antigen, 
    concept_name(lan.value_coded, 'en') antigen_results,
		MAX(IF(lt.value_coded = CONCEPT_FROM_MAPPING('CIEL', '165840'), 'Yes', NULL)) pcr,
    concept_name(lp.value_coded, 'en') pcr_results,
		MAX(IF(lt.value_coded = CONCEPT_FROM_MAPPING('CIEL', '165865'), 'Yes', NULL)) genexpert, 
    concept_name(lg.value_coded, 'en') genexpert_results
FROM
	temp_covid_lab_test_ordered lt
left outer join 
	temp_covid_lab_antigen lan on lt.obs_group_id = lan.obs_group_id 
left outer join 
	temp_covid_lab_antibody la on lt.obs_group_id = la.obs_group_id 
left outer join
	temp_covid_lab_pcr lp on lt.obs_group_id = lp.obs_group_id
 left outer join
	 temp_covid_gene_expert lg on lt.obs_group_id = lg.obs_group_id
 group by lt.obs_group_id;

### Final query
select  
		ls.person_id patient_id,
        ls.encounter_id encounter_id,
        ls.obs_id,
        e.encounter_date,
        e.location,
        e.encounter_type,
		    DATE(lspd.value_datetime) specimen_date,
        lss.specimen_source,
		    lsr.antibody,
        antibody_results,
        antigen,
        antigen_results,
        pcr,
        pcr_results,
        genexpert,
        genexpert_results
from 
	temp_covid_lab_specimen_set ls
left outer join
	temp_covid_lab_encounters e on e.encounter_id = ls.encounter_id
left outer join
	temp_covid_lab_specimen_date lspd on ls.obs_id = lspd.obs_group_id
left outer join 
temp_covid_specimen_results lsr on ls.obs_id = lsr.obs_group_id
left outer join 
temp_covid_lab_specimen_source lss on ls.obs_id = lss.obs_group_id
order by ls.person_id, ls.encounter_id, lspd.value_datetime;