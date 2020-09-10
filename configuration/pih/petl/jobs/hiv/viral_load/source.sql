SET sql_safe_updates = 0;

DROP TABLE IF EXISTS temp_hiv_constructs;
DROP TABLE IF EXISTS temp_viral_load;
DROP TABLE IF EXISTS temp_vl_sample_taken_date;
DROP TABLE IF EXISTS temp_days_since_vl;

-- hiv constructs table
CREATE TEMPORARY TABLE temp_hiv_constructs
(
patient_id 				INT,
encounter_id 			INT
);

INSERT INTO temp_hiv_constructs (patient_id, encounter_id)
SELECT person_id, encounter_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING("PIH", "HIV viral load construct") AND encounter_id IN (SELECT encounter_id FROM encounter
WHERE encounter_type =(SELECT encounter_type_id FROM encounter_type WHERE name = "Laboratory Results"));

-- specimen cpllection date table
CREATE TEMPORARY TABLE temp_vl_sample_taken_date
(
encounter_id 			INT,
vl_sample_taken_date	DATE
);

INSERT INTO temp_vl_sample_taken_date(encounter_id, vl_sample_taken_date)
SELECT encounter_id, DATE(encounter_datetime) FROM encounter WHERE encounter_id IN (SELECT encounter_id FROM temp_hiv_constructs);

-- viral load details table
CREATE TABLE temp_viral_load
(
patient_id						INT,
encounter_id					INT,
vl_sample_taken_date_estimated 	VARCHAR(11),
vl_result_date					DATE,
vl_test_outcome					VARCHAR(255),
vl_result_detectable			VARCHAR(255),
viral_load						INT,
vl_type							VARCHAR(50)
);

INSERT INTO temp_viral_load (patient_id, encounter_id)
(SELECT patient_id, encounter_id FROM temp_hiv_constructs);

UPDATE temp_viral_load SET vl_sample_taken_date_estimated =  OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '11781', 'en'); 

UPDATE temp_viral_load SET vl_result_date =  OBS_VALUE_DATETIME(encounter_id, 'PIH', 'DATE OF LABORATORY TEST');

UPDATE temp_viral_load SET vl_result_detectable =  OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1305', 'en');

UPDATE temp_viral_load SET viral_load =  OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '856');

-- days since last viral load table
CREATE TEMPORARY TABLE temp_days_since_vl
(
patient_id		INT,
result_date		DATE
);

INSERT INTO temp_days_since_vl(patient_id, result_date)
SELECT patient_id, MAX(vl_result_date) FROM temp_viral_load GROUP BY patient_id;

-- index ascending
DROP TEMPORARY TABLE IF EXISTS temp_index_asc;
CREATE TEMPORARY TABLE temp_index_asc
(
			SELECT  
            patient_id,
			encounter_id,
			index_asc
FROM (SELECT  
             @r:= IF(@u = patient_id, @r + 1,1) index_asc,
             encounter_id,
             patient_id,
			 @u:= patient_id
            FROM temp_viral_load,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_id ASC
        ) index_ascending );
  
-- index descending
DROP TEMPORARY TABLE IF EXISTS temp_index_desc;
CREATE TEMPORARY TABLE temp_index_desc
(
			SELECT  
            patient_id,
			encounter_id,
			index_desc 
FROM (SELECT  
             @r:= IF(@u = patient_id, @r + 1,1) index_desc,
             encounter_id,
             patient_id,
			 @u:= patient_id
            FROM temp_viral_load,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_id DESC
        ) index_descending );



### Final query
SELECT 
		tvl.patient_id,
        tvl.encounter_id,
        vl_sample_taken_date,
        vl_sample_taken_date_estimated,
        vl_result_date,
        vl_test_outcome,
        vl_result_detectable,
        viral_load,
        vl_type,
        DATEDIFF(NOW(), result_date) days_since_last_vl,
        index_desc,
        index_asc
FROM temp_viral_load tvl
-- speciment collection date 
JOIN temp_vl_sample_taken_date tvld ON tvld.encounter_id = tvl.encounter_id 
-- days since last viral load
LEFT JOIN temp_days_since_vl tdl ON tvl.patient_id = tdl.patient_id AND tdl.result_date = tvl.vl_result_date
-- index ascending
LEFT JOIN temp_index_asc ON tvl.encounter_id = temp_index_asc.encounter_id
-- index descending
LEFT JOIN temp_index_desc ON tvl.encounter_id = temp_index_desc.encounter_id
ORDER BY tvl.patient_id;