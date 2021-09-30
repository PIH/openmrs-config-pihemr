SET sql_safe_updates = 0;

SELECT encounter_type_id INTO @HIV_adult_intake FROM encounter_type WHERE uuid = 'c31d306a-40c4-11e7-a919-92ebcb67fe33';
SELECT encounter_type_id INTO @HIV_adult_followup FROM encounter_type WHERE uuid = 'c31d3312-40c4-11e7-a919-92ebcb67fe33';
SELECT encounter_type_id INTO @HIV_ped_intake FROM encounter_type WHERE uuid = 'c31d3416-40c4-11e7-a919-92ebcb67fe33';
SELECT encounter_type_id INTO @HIV_ped_followup FROM encounter_type WHERE uuid = 'c31d34f2-40c4-11e7-a919-92ebcb67fe33';
SET @present = CONCEPT_FROM_MAPPING('PIH','11563');
SET @absent = CONCEPT_FROM_MAPPING('PIH','11564');

DROP TEMPORARY TABLE IF EXISTS temp_TB_screening;
CREATE TEMPORARY TABLE temp_TB_screening
(
patient_id INT(11),
encounter_id INT(11),
cough_result_concept INT(11),
fever_result_concept INT(11),
weight_loss_result_concept INT(11),
tb_contact_result_concept INT(11),
lymph_pain_result_concept INT(11),
bloody_cough_result_concept INT(11),
dyspnea_result_concept INT(11),
chest_pain_result_concept INT(11),
tb_screening VARCHAR(30),
tb_screening_bool VARCHAR(5),
tb_screening_date DATETIME,
index_ascending INT(11),
index_descending INT(11)
);

CREATE INDEX temp_TB_screening_patient_id ON temp_TB_screening (patient_id);
CREATE INDEX temp_TB_screening_tb_screening_date ON temp_TB_screening (tb_screening_date);
CREATE INDEX temp_TB_screening_encounter_id ON temp_TB_screening (encounter_id);

-- load temp table with all intake/followup forms with any TB screening answer given
INSERT INTO temp_TB_screening (patient_id, encounter_id,tb_screening_date)
SELECT e.patient_id, e.encounter_id,e.encounter_datetime FROM encounter e
WHERE e.voided =0 
AND e.encounter_type IN (@HIV_adult_intake,@HIV_adult_followup,@HIV_ped_intake,@HIV_ped_followup)
AND EXISTS
  (SELECT 1 FROM obs o WHERE o.encounter_id = e.encounter_id 
   AND o.voided = 0 AND o.concept_id IN (@absent,@present))
;  

-- update answer of each of the screening questions by bringing in the symptom/answer (fever, weight loss etc...)
-- and update the temp table column based on whether the obs question was symptom question was present or absent
UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.value_coded = CONCEPT_FROM_MAPPING('PIH', '11565')
-- set fever_result = if(o.concept_id = @present,'yes',if(o.concept_id = @absent,'no',null))
SET fever_result_concept =o.concept_id;

UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.value_coded = CONCEPT_FROM_MAPPING('PIH', '11566')
SET weight_loss_result_concept =o.concept_id;

UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.value_coded = CONCEPT_FROM_MAPPING('PIH', '11567')
SET cough_result_concept =o.concept_id;

UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.value_coded = CONCEPT_FROM_MAPPING('PIH', '11568')
SET tb_contact_result_concept =o.concept_id;

UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.value_coded = CONCEPT_FROM_MAPPING('PIH', '11569')
SET lymph_pain_result_concept =o.concept_id;

UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.value_coded = CONCEPT_FROM_MAPPING('PIH', '970')
SET bloody_cough_result_concept =o.concept_id;

UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.value_coded = CONCEPT_FROM_MAPPING('PIH', '5960')
SET dyspnea_result_concept =o.concept_id;

UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.value_coded = CONCEPT_FROM_MAPPING('PIH', '136')
SET chest_pain_result_concept =o.concept_id;

UPDATE temp_TB_screening t
INNER JOIN obs o ON t.encounter_id = o.encounter_id AND o.concept_id = CONCEPT_FROM_MAPPING("CIEL", "160108")
SET tb_screening = CONCEPT_NAME(o.value_coded, 'en');

UPDATE temp_TB_screening t SET tb_screening_bool = IF(cough_result_concept = @present,'yes',
  IF(fever_result_concept = @present,'yes',
    IF(weight_loss_result_concept = @present,'yes',
      IF(tb_contact_result_concept = @present,'yes',
        IF(lymph_pain_result_concept = @present,'yes',
          IF(bloody_cough_result_concept = @present,'yes',
            IF(dyspnea_result_concept = @present,'yes',
              IF(chest_pain_result_concept = @present,'yes',
                'no')))))))); 

-- The ascending/descending indexes are calculated ordering on the screening date
-- new temp tables are used to build them and then joined into the main temp table. 
-- index ascending
DROP TEMPORARY TABLE IF EXISTS temp_screening_index_asc;
CREATE TEMPORARY TABLE temp_screening_index_asc
(
    SELECT
            patient_id,
            encounter_id,
            tb_screening_date,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            patient_id,
            encounter_id,
            tb_screening_date,
            @u:= patient_id
      FROM temp_TB_screening,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id ASC, tb_screening_date ASC, encounter_id ASC
        ) index_ascending);

UPDATE temp_TB_screening t
INNER JOIN temp_screening_index_asc tsia ON tsia.encounter_id = t.encounter_id
SET t.index_ascending = tsia.index_asc;

-- index descending
DROP TEMPORARY TABLE IF EXISTS temp_screening_index_desc;
CREATE TEMPORARY TABLE temp_screening_index_desc
(
    SELECT
            patient_id,
            encounter_id,
            tb_screening_date,
            index_DESC
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_DESC,
            patient_id,
            encounter_id,
            tb_screening_date,
            @u:= patient_id
      FROM temp_TB_screening,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id DESC, tb_screening_date DESC, encounter_id DESC
        ) index_DESCending);

UPDATE temp_TB_screening t
INNER JOIN temp_screening_index_desc tsid ON tsid.encounter_id = t.encounter_id
SET t.index_descending = tsid.index_desc;


SELECT
patient_id,
ZLEMR(patient_id) emr_id,
DOSID(patient_id) dossier_id,
encounter_id,
IF(cough_result_concept = @present,'yes',IF(cough_result_concept = @absent,'no',NULL)) "cough_result",
IF(fever_result_concept = @present,'yes',IF(fever_result_concept = @absent,'no',NULL)) "fever_result",
IF(weight_loss_result_concept = @present,'yes',IF(weight_loss_result_concept = @absent,'no',NULL)) "weight_loss",
IF(tb_contact_result_concept = @present,'yes',IF(tb_contact_result_concept = @absent,'no',NULL)) "tb_contact",
IF(lymph_pain_result_concept = @present,'yes',IF(lymph_pain_result_concept = @absent,'no',NULL)) "lymph_pain",
IF(bloody_cough_result_concept = @present,'yes',IF(bloody_cough_result_concept = @absent,'no',NULL)) "bloody_cough",
IF(dyspnea_result_concept = @present,'yes',IF(dyspnea_result_concept = @absent,'no',NULL)) "dyspnea_result",
IF(chest_pain_result_concept = @present,'yes',IF(chest_pain_result_concept = @absent,'no',NULL)) "chest_pain",
COALESCE(tb_screening, tb_screening_bool) "tb_screening_result",
tb_screening_date,
index_ascending,
index_descending
FROM temp_TB_screening
ORDER BY patient_id ASC, tb_screening_date ASC, encounter_id ASC;