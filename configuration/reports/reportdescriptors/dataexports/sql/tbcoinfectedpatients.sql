SET sql_safe_updates = 0;
CALL initialize_global_metadata();

# Any of the answers below
# Yes
# treatment already started
# anti-TB treatment ongoing
# anti-TB treatment changed
# anti-TB treatment started
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs
(
person_id INT(11),
tb_treatment_start_date DATE,
drug_start_date DATE,
drug_stop_date DATE
);

INSERT INTO temp_hiv_tb_patients_obs(person_id)
SELECT
    person_id
FROM
    obs
WHERE
    concept_id = CONCEPT_FROM_MAPPING('PIH', '1559')
        AND voided = 0
        AND value_coded IN
        (
        CONCEPT_FROM_MAPPING('PIH', 'CURRENTLY IN TREATMENT'),
        CONCEPT_FROM_MAPPING('PIH', 'YES'),
        CONCEPT_FROM_MAPPING('CIEL', '160017'), #Anti-TB treatment started
        CONCEPT_FROM_MAPPING('CIEL', '981'), #dosing change
        CONCEPT_FROM_MAPPING('CIEL', '163057') #Continue treatment
        )
GROUP BY person_id;

## TB start date
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_tr_start_date;
CREATE TEMPORARY TABLE temp_hiv_tb_tr_start_date
(
person_id INT(11),
tb_treatment_start_date DATE,
drug_start_date DATE,
drug_stop_date DATE
);

INSERT INTO temp_hiv_tb_tr_start_date (person_id, tb_treatment_start_date)
SELECT
    person_id, MIN(DATE(value_datetime))
FROM
    obs
WHERE
    concept_id = CONCEPT_FROM_MAPPING('CIEL', '1113')
        AND voided = 0
GROUP BY person_id;

# join the tb tables above into one table
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_obs_tr_start_date;
CREATE TEMPORARY TABLE temp_hiv_tb_obs_tr_start_date
(
person_id INT(11),
tb_treatment_start_date DATE,
drug_start_date DATE,
drug_stop_date DATE
);

INSERT INTO temp_hiv_tb_obs_tr_start_date(person_id, tb_treatment_start_date)
SELECT
    a.person_id, a.tb_treatment_start_date
FROM
    temp_hiv_tb_tr_start_date a
        LEFT JOIN
	temp_hiv_tb_patients_obs b ON a.person_id = b.person_id;

## patients that may have remained in temp_hiv_tb_patients_obs
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_one;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_one
AS
SELECT * FROM temp_hiv_tb_patients_obs WHERE person_id
NOT IN (SELECT person_id FROM temp_hiv_tb_obs_tr_start_date);

## join the two tables above
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_two;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_two
AS
SELECT * FROM temp_hiv_tb_patients_obs_stage_one
UNION ALL
SELECT * FROM temp_hiv_tb_obs_tr_start_date;

## patients that may have remained in temp_hiv_tb_patients_obs
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_three;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_three
AS
SELECT * FROM temp_hiv_tb_tr_start_date WHERE person_id
NOT IN (SELECT person_id FROM temp_hiv_tb_patients_obs_stage_two);

## join the two tables above
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_four;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_four
AS
SELECT * FROM temp_hiv_tb_patients_obs_stage_three
UNION ALL
SELECT * FROM temp_hiv_tb_patients_obs_stage_two;

##################################
#################
## tb drug start date
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_start_date;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_start_date
(
patient_id INT(11),
tb_treatment_start_date DATE,
drug_start_date DATE,
drug_stop_date DATE
);

INSERT INTO temp_hiv_tb_patients_start_date(patient_id, drug_start_date)
SELECT
    patient_id, MIN(DATE(date_activated))
FROM
    orders
WHERE
    voided = 0
        AND order_reason = CONCEPT_FROM_MAPPING('CIEL', '112141')
GROUP BY patient_id;

UPDATE temp_hiv_tb_patients_start_date a SET tb_treatment_start_date = (SELECT tb_treatment_start_date FROM temp_hiv_tb_patients_obs_stage_four b WHERE a.patient_id = b.person_id);

## tb drug stop date
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_stop_date;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_stop_date
(
patient_id INT(11),
tb_treatment_start_date DATE,
drug_start_date DATE,
drug_stop_date DATE
);

INSERT INTO temp_hiv_tb_patients_stop_date(patient_id, drug_stop_date)
SELECT
    patient_id, MAX(DATE(date_stopped))
FROM
    orders
WHERE
    voided = 0
        AND order_reason = CONCEPT_FROM_MAPPING('CIEL', '112141')
GROUP BY patient_id;

UPDATE temp_hiv_tb_patients_stop_date a SET tb_treatment_start_date = (SELECT tb_treatment_start_date FROM temp_hiv_tb_patients_obs_stage_four b WHERE a.patient_id = b.person_id
AND a.tb_treatment_start_date IS NULL);

####
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_drug_dates;
CREATE TEMPORARY TABLE temp_hiv_tb_drug_dates
AS
SELECT a.patient_id, a.tb_treatment_start_date, a.drug_start_date, b.drug_stop_date FROM temp_hiv_tb_patients_start_date a
LEFT JOIN
temp_hiv_tb_patients_stop_date b ON a.patient_id = b.patient_id;

# ensure that all patients from temp_hiv_tb_patients_start_date are included
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_five;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_five
AS
SELECT * FROM temp_hiv_tb_patients_start_date WHERE patient_id
NOT IN (SELECT patient_id FROM temp_hiv_tb_drug_dates);

# join the 2 tables above
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_six;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_six
AS
SELECT * FROM temp_hiv_tb_patients_obs_stage_five
UNION ALL
SELECT * FROM temp_hiv_tb_drug_dates;

# ensure that all patients from temp_hiv_tb_patients_stop_date are included
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_seven;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_seven
AS
SELECT * FROM temp_hiv_tb_patients_stop_date WHERE patient_id
NOT IN (SELECT patient_id FROM temp_hiv_tb_patients_obs_stage_six);

# join the 2 tables above
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_eight;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_eight
AS
SELECT * FROM temp_hiv_tb_patients_obs_stage_seven
UNION ALL
SELECT * FROM temp_hiv_tb_patients_obs_stage_six;

#### final tables
DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_obs_stage_nine;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_obs_stage_nine
AS
SELECT * FROM temp_hiv_tb_patients_obs_stage_four WHERE person_id
NOT IN (SELECT patient_id FROM temp_hiv_tb_patients_obs_stage_eight);

DROP TEMPORARY TABLE IF EXISTS temp_hiv_tb_patients_final;
CREATE TEMPORARY TABLE temp_hiv_tb_patients_final
AS
SELECT * FROM temp_hiv_tb_patients_obs_stage_eight
UNION ALL
SELECT * FROM temp_hiv_tb_patients_obs_stage_nine;

# Final query
SELECT 	tf.patient_id, 
		ZLEMR(tf.patient_id) patient_id, 
        identifier hivemr_v1, 
        COALESCE(tb_treatment_start_date, drug_start_date) "tb_treatment_start_date", 
        drug_start_date, 
        drug_stop_date FROM temp_hiv_tb_patients_final tf
        LEFT JOIN patient_identifier pi ON tf.patient_id = pi.patient_id AND pi.voided = 0 AND pi.identifier_type = @hivId;