SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

DROP TEMPORARY TABLE IF EXISTS temp_ncd_program;
DROP TEMPORARY TABLE IF EXISTS temp_ncd_last_ncd_enc;
DROP TEMPORARY TABLE IF EXISTS temp_ncd_first_ncd_enc;

SELECT patient_identifier_type_id INTO @zlId FROM patient_identifier_type WHERE name = "ZL EMR ID";
SELECT patient_identifier_type_id INTO @dosId FROM patient_identifier_type WHERE name = "Nimewo Dosye";
SELECT encounter_type_id INTO @NCDInitEnc FROM encounter_type WHERE UUID = "ae06d311-1866-455b-8a64-126a9bd74171";
SELECT encounter_type_id INTO @NCDFollowEnc FROM encounter_type WHERE UUID = "5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c";

-- latest NCD enc table
CREATE TEMPORARY TABLE temp_ncd_last_ncd_enc
(
  encounter_id INT,
  patient_id INT,
  encounter_datetime DATETIME,
  encounter_obs_date DATETIME,
  weight DOUBLE,
  bp_diastolic DOUBLE,
  bp_systolic DOUBLE,
  asthma_diagnosis VARCHAR(255)
);
INSERT INTO temp_ncd_last_ncd_enc(patient_id, encounter_datetime)
  SELECT patient_id, MAX(encounter_datetime) FROM encounter WHERE voided = 0
  AND encounter_type IN (@NCDInitEnc, @NCDFollowEnc) GROUP BY patient_id ORDER BY patient_id;

UPDATE temp_ncd_last_ncd_enc tlne
INNER JOIN encounter e ON tlne.patient_id = e.patient_id AND tlne.encounter_datetime = e.encounter_datetime AND e.encounter_type IN (@NCDInitEnc, @NCDFollowEnc)
SET tlne.encounter_id = e.encounter_id;

-- set the secs to 00:00
UPDATE temp_ncd_last_ncd_enc tlne
SET tlne.encounter_obs_date = DATE(encounter_datetime);

-- weight
DROP TEMPORARY TABLE IF EXISTS temp_table_weight;
CREATE TEMPORARY TABLE temp_table_weight
(SELECT person_id, DATE(obs_datetime) obsdatetime, value_numeric FROM obs WHERE voided = 0 AND concept_id = 
(SELECT concept_id FROM report_mapping rm_syst WHERE rm_syst.source = 'PIH' AND rm_syst.code = 'WEIGHT (KG)'));

UPDATE temp_ncd_last_ncd_enc tlne
LEFT OUTER JOIN temp_table_weight weight ON weight.person_id = tlne.patient_id AND weight.obsdatetime = tlne.encounter_obs_date
SET tlne.weight = weight.value_numeric;

-- Blood Pressure 
DROP TEMPORARY TABLE IF EXISTS temp_table_sys_bp;
CREATE TEMPORARY TABLE temp_table_sys_bp
(SELECT person_id, DATE(obs_datetime) obsdatetime, value_numeric FROM obs WHERE voided = 0 AND concept_id = 
(SELECT concept_id FROM report_mapping rm_syst WHERE rm_syst.source = 'PIH' AND rm_syst.code = 'Systolic Blood Pressure'));

UPDATE temp_ncd_last_ncd_enc tlne
        LEFT OUTER JOIN
    temp_table_sys_bp systolic_bp ON systolic_bp.person_id = tlne.patient_id
        AND systolic_bp.obsdatetime = tlne.encounter_obs_date 
SET 
    tlne.bp_systolic = systolic_bp.value_numeric;

DROP TEMPORARY TABLE IF EXISTS temp_table_dia_bp;
CREATE TEMPORARY TABLE temp_table_dia_bp
(SELECT person_id, DATE(obs_datetime) obsdatetime, value_numeric FROM obs WHERE voided = 0 AND concept_id = 
(SELECT concept_id FROM report_mapping rm_syst WHERE rm_syst.source = 'PIH' AND rm_syst.code = 'Diastolic Blood Pressure'));

UPDATE temp_ncd_last_ncd_enc tlne
        LEFT OUTER JOIN
    temp_table_dia_bp diastolic_bp ON diastolic_bp.person_id = tlne.patient_id
        AND diastolic_bp.obsdatetime = tlne.encounter_obs_date 
SET 
    tlne.bp_diastolic = diastolic_bp.value_numeric;
  
-- initial ncd enc table(ideally it should be ncd initital form only)
CREATE TEMPORARY TABLE temp_ncd_first_ncd_enc
(
  encounter_id INT,
  patient_id INT,
  encounter_datetime DATETIME
);
INSERT INTO temp_ncd_first_ncd_enc(patient_id, encounter_datetime)
  SELECT patient_id, MIN(encounter_datetime) FROM encounter WHERE voided = 0
  AND encounter_type IN (@NCDInitEnc, @NCDFollowEnc) GROUP BY patient_id ORDER BY patient_id;

UPDATE temp_ncd_first_ncd_enc tfne
INNER JOIN encounter e ON tfne.patient_id = e.patient_id AND tfne.encounter_datetime = e.encounter_datetime AND e.encounter_type IN (@NCDInitEnc, @NCDFollowEnc)
SET tfne.encounter_id = e.encounter_id;

-- ncd program
CREATE TEMPORARY TABLE temp_ncd_program(
  patient_program_id INT,
  patient_id INT,
  date_enrolled DATETIME,
  date_completed DATETIME,
  location_id INT,
  outcome_concept_id INT,
  given_name VARCHAR(255),
  family_name VARCHAR(255),
  birthdate DATETIME,
  birthdate_estimated VARCHAR(50),
  gender VARCHAR(50),
  country VARCHAR(255),
  department VARCHAR(255),
  commune VARCHAR(255),
  section_communal VARCHAR(255),
  locality VARCHAR(255),
  street_landmark VARCHAR(255),
  telephone_number VARCHAR(255),
  contact_telephone_number  VARCHAR(255),
  program_state VARCHAR(255),
  program_outcome VARCHAR(255),
  first_ncd_encounter DATETIME,
  last_ncd_encounter DATETIME,
  next_ncd_appointment DATETIME,
  thirty_days_past_app VARCHAR(11),
  disposition VARCHAR(255),
  deceased VARCHAR(255),
  HbA1c_result DOUBLE,
  HbA1c_collection_date DATETIME,
  HbA1c_result_date DATETIME,
  height DOUBLE,
  creatinine_result DOUBLE,
  creatinine_collection_date DATETIME,
  creatinine_result_date DATETIME,
  visit_adherence TEXT,
  recent_hospitalization TEXT,
  hypertension INT,
  diabetes INT,
  heart_Failure INT,
  stroke INT,
  respiratory INT,
  rehab INT,
  anemia INT,
  epilepsy INT,
  other_Category INT
);

INSERT INTO temp_ncd_program (patient_program_id, patient_id, date_enrolled, date_completed, location_id, outcome_concept_id)
  SELECT
  patient_program_id,
  patient_id,
  DATE(date_enrolled),
  DATE(date_completed),
  location_id,
  outcome_concept_id
  FROM patient_program WHERE voided = 0 AND program_id IN (SELECT program_id FROM program WHERE uuid = '515796ec-bf3a-11e7-abc4-cec278b6b50a') -- uuid of the NCD program
  ORDER BY patient_id;

UPDATE temp_ncd_program p INNER JOIN current_name_address d ON d.person_id = p.patient_id
SET p.given_name = d.given_name,
p.family_name = d.family_name,
p.birthdate = d.birthdate,
p.birthdate_estimated = d.birthdate_estimated,
p.gender = d.gender,
p.country = d.country,
p.department = d.department,
p.commune = d.commune,
p.section_communal = d.section_communal,
p.locality = d.locality,
p.street_landmark = d.street_landmark;

-- Telephone number
UPDATE temp_ncd_program p
LEFT OUTER JOIN person_attribute pa ON pa.person_id = p.patient_id AND pa.voided = 0 AND pa.person_attribute_type_id = (SELECT person_attribute_type_id
FROM person_attribute_type WHERE uuid = "14d4f066-15f5-102d-96e4-000c29c2a5d7")
SET p.telephone_number = pa.value;

-- telephone number of contact
UPDATE temp_ncd_program p
LEFT OUTER JOIN obs contact_telephone ON contact_telephone.person_id = p.patient_id AND contact_telephone.voided = 0 AND contact_telephone.concept_id = (SELECT concept_id FROM
report_mapping WHERE source="PIH" AND code="TELEPHONE NUMBER OF CONTACT")
SET p.contact_telephone_number = contact_telephone.value_text;

-- patient state
UPDATE temp_ncd_program p
LEFT OUTER JOIN patient_state ps ON ps.patient_program_id = p.patient_program_id AND ps.end_date IS NULL AND ps.voided = 0
LEFT OUTER JOIN program_workflow_state pws ON pws.program_workflow_state_id = ps.state AND pws.retired = 0
LEFT OUTER JOIN concept_name cn_state ON cn_state.concept_id = pws.concept_id  AND cn_state.locale = 'en' AND cn_state.locale_preferred = '1'  AND cn_state.voided = 0
-- outcome
LEFT OUTER JOIN concept_name cn_out ON cn_out.concept_id = p.outcome_concept_id AND cn_out.locale = 'en' AND cn_out.locale_preferred = '1'  AND cn_out.voided = 0
SET p.program_state = cn_state.name,
p.program_outcome = cn_out.name;

UPDATE temp_ncd_program p
-- first ncd encounter
LEFT OUTER JOIN temp_ncd_first_ncd_enc first_ncd_enc ON first_ncd_enc.patient_id = p.patient_id
SET p.first_ncd_encounter = DATE(first_ncd_enc.encounter_datetime);

UPDATE temp_ncd_program p
-- last visit
LEFT OUTER JOIN temp_ncd_last_ncd_enc last_ncd_enc ON last_ncd_enc.patient_id = p.patient_id
-- next visit (obs)
LEFT OUTER JOIN obs obs_next_appt ON obs_next_appt.encounter_id = last_ncd_enc.encounter_id AND obs_next_appt.concept_id =
(SELECT concept_id FROM report_mapping rm_next WHERE rm_next.source = 'PIH' AND rm_next.code = 'RETURN VISIT DATE')
     AND obs_next_appt.voided = 0
SET p.last_ncd_encounter = DATE(last_ncd_enc.encounter_datetime),
p.next_ncd_appointment = DATE(obs_next_appt.value_datetime),
p.thirty_days_past_app = IF(DATEDIFF(CURDATE(), obs_next_appt.value_datetime) > 30, "Oui", NULL);

UPDATE temp_ncd_program p
LEFT OUTER JOIN temp_ncd_last_ncd_enc ON p.patient_id = temp_ncd_last_ncd_enc.patient_id
-- latest disposition
LEFT OUTER JOIN obs obs_disposition ON obs_disposition.encounter_id = temp_ncd_last_ncd_enc.encounter_id AND obs_disposition.voided = 0 AND obs_disposition.concept_id =
(SELECT concept_id FROM report_mapping rm_dispostion WHERE rm_dispostion.source = 'PIH' AND rm_dispostion.code = '8620')
LEFT OUTER JOIN concept_name cn_disposition ON cn_disposition.concept_id = obs_disposition.value_coded AND cn_disposition.locale = 'fr'
AND cn_disposition.voided = 0 AND cn_disposition.locale_preferred = 1
SET p.disposition = cn_disposition.name,
p.deceased = IF(obs_disposition.value_coded = (SELECT concept_id FROM report_mapping rm_dispostion WHERE rm_dispostion.source = 'PIH' AND rm_dispostion.code = 'DEATH')
OR p.outcome_concept_id = (SELECT concept_id FROM report_mapping rm_dispostion WHERE rm_dispostion.source = 'PIH' AND rm_dispostion.code = 'PATIENT DIED')
, "Oui", NULL
);

UPDATE temp_ncd_program p
-- last collected HbA1c test
LEFT OUTER JOIN
(SELECT person_id, value_numeric, HbA1c_test.encounter_id, DATE(obs_datetime), DATE(edate.encounter_datetime) HbA1c_coll_date FROM obs HbA1c_test JOIN encounter
    edate ON edate.patient_id = HbA1c_test.person_id AND HbA1c_test.encounter_id = edate.encounter_id AND
    HbA1c_test.voided = 0 AND HbA1c_test.concept_id =
    (SELECT concept_id FROM report_mapping rm_HbA1c WHERE rm_HbA1c.source = 'PIH' AND rm_HbA1c.code = 'HbA1c') AND
    obs_datetime IN (SELECT MAX(obs_datetime) FROM obs o2 WHERE o2.voided = 0 AND o2.concept_id = (SELECT concept_id FROM report_mapping rm_HbA1c
    WHERE rm_HbA1c.source = 'PIH' AND rm_HbA1c.code = 'HbA1c')
    GROUP BY o2.person_id)) HbA1c_results ON HbA1c_results.person_id = p.patient_id
LEFT OUTER JOIN obs HbA1c_date ON HbA1c_date.encounter_id = HbA1c_results.encounter_id AND HbA1c_date.voided = 0
AND HbA1c_date.concept_id =
(SELECT concept_id FROM report_mapping rm_HbA1c_date WHERE rm_HbA1c_date.source = 'PIH' AND rm_HbA1c_date.code = 'DATE OF LABORATORY TEST')
SET p.HbA1c_result = HbA1c_results.value_numeric,
p.HbA1c_collection_date = HbA1c_results.HbA1c_coll_date,
p.HbA1c_result_date = DATE(HbA1c_date.value_datetime);

UPDATE temp_ncd_program p
-- last collected Creatinine test
LEFT OUTER JOIN
(SELECT person_id, value_numeric, creat_test.encounter_id, DATE(obs_datetime), DATE(edate.encounter_datetime) creat_coll_date FROM obs creat_test JOIN encounter
    edate ON edate.patient_id = creat_test.person_id AND creat_test.encounter_id = edate.encounter_id AND
    creat_test.voided = 0 AND creat_test.concept_id =
    (SELECT concept_id FROM report_mapping rm_syst WHERE rm_syst.source = 'PIH' AND rm_syst.code = 'Creatinine mg per dL') AND
    obs_datetime IN (SELECT MAX(obs_datetime) FROM obs o2 WHERE o2.voided = 0 AND o2.concept_id = (SELECT concept_id FROM report_mapping rm_syst
    WHERE rm_syst.source = 'PIH' AND rm_syst.code = 'HbA1c')
    GROUP BY o2.person_id)) creat_results ON creat_results.person_id = p.patient_id
LEFT OUTER JOIN obs creat_date ON creat_date.encounter_id = creat_results.encounter_id
AND creat_date.concept_id =
(SELECT concept_id FROM report_mapping rm_creat_date WHERE rm_creat_date.source = 'PIH' AND rm_creat_date.code = 'DATE OF LABORATORY TEST')
   AND creat_date.voided = 0
SET p.creatinine_result = creat_results.value_numeric ,
p.creatinine_collection_date = DATE(creat_results.creat_coll_date),
p.creatinine_result_date = DATE(creat_date.value_datetime);

UPDATE temp_ncd_program p
-- last collected Height
LEFT OUTER JOIN obs height ON height.obs_id =
(SELECT obs_id FROM obs o2 WHERE o2.person_id = p.patient_id
    AND o2.concept_id =
      (SELECT concept_id FROM report_mapping rm_syst WHERE rm_syst.source = 'PIH' AND rm_syst.code = 'HEIGHT (CM)')
    ORDER BY o2.obs_datetime DESC LIMIT 1
    ) AND height.voided = 0   
SET p.height = height.value_numeric;
 
-- Lack of meds
DROP TEMPORARY TABLE IF EXISTS temp_ncd_lack_of_meds;
CREATE TEMPORARY TABLE temp_ncd_lack_of_meds
(
SELECT person_id, concept_id, CONCEPT_NAME(value_coded, 'fr') lack_of_meds, MAX(DATE(obs_datetime)) obsdatetime FROM obs obs_lack_meds WHERE concept_id = (SELECT concept_id FROM report_mapping rm_next WHERE rm_next.source = 'PIH' AND rm_next.code = 'Lack of meds in last 2 days')
AND obs_lack_meds.voided = 0 AND encounter_id IN (SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type IN (@NCDInitEnc, @NCDFollowEnc))
GROUP BY person_id
);

UPDATE temp_ncd_program p
LEFT OUTER JOIN temp_ncd_last_ncd_enc ON p.patient_id = temp_ncd_last_ncd_enc.patient_id
-- visit adherence
LEFT OUTER JOIN obs obs_visit_adherence ON obs_visit_adherence.encounter_id = temp_ncd_last_ncd_enc.encounter_id AND obs_visit_adherence.concept_id =
(SELECT concept_id FROM report_mapping rm_next WHERE rm_next.source = 'PIH' AND rm_next.code = 'Appearance at appointment time')
    AND obs_visit_adherence.voided = 0
LEFT OUTER JOIN concept_name cn_visit_adherence ON cn_visit_adherence.concept_id = obs_visit_adherence.value_coded
AND cn_visit_adherence.locale = 'fr' AND cn_visit_adherence.locale_preferred = 1 AND cn_visit_adherence.voided = 0
SET p.visit_adherence = cn_visit_adherence.name;

UPDATE temp_ncd_program p
LEFT OUTER JOIN temp_ncd_last_ncd_enc ON p.patient_id = temp_ncd_last_ncd_enc.patient_id
-- recent hospitalization
LEFT OUTER JOIN obs obs_recent_hosp ON obs_recent_hosp.encounter_id = temp_ncd_last_ncd_enc.encounter_id AND obs_recent_hosp.concept_id =
(SELECT concept_id FROM report_mapping rm_next WHERE rm_next.source = 'PIH' AND rm_next.code = 'PATIENT HOSPITALIZED SINCE LAST VISIT')
    AND obs_recent_hosp.voided = 0
LEFT OUTER JOIN concept_name cn_recent_hosp ON cn_recent_hosp.concept_id = obs_recent_hosp.value_coded AND cn_recent_hosp.locale = 'fr'
AND cn_recent_hosp.locale_preferred = 1 AND cn_recent_hosp.voided = 0
SET p.recent_hospitalization = cn_recent_hosp.name;

-- ncd meds
DROP TEMPORARY TABLE IF EXISTS temp_stage_ncd_meds;
CREATE TEMPORARY TABLE temp_stage_ncd_meds
(
SELECT person_id, concept_id, CONCEPT_NAME(value_coded, 'en') ncd_meds, obs_datetime FROM obs meds WHERE concept_id IN
(SELECT concept_id FROM report_mapping rm_next WHERE (rm_next.source = 'PIH' AND rm_next.code = 'Medications prescribed at end of visit') OR
(rm_next.source = 'PIH' AND rm_next.code = 'MEDICATION ORDERS')) AND meds.voided = 0
AND meds.encounter_id IN (SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type IN (@NCDInitEnc, @NCDFollowEnc))
);

DROP TEMPORARY TABLE IF EXISTS temp_latest_ncd_meds_date;
CREATE TEMPORARY TABLE temp_latest_ncd_meds_date
(
SELECT person_id, MAX(obs_datetime) latest_date_ncd_meds FROM temp_stage_ncd_meds
GROUP BY person_id ORDER BY person_id
);

DROP TEMPORARY TABLE IF EXISTS temp_baseline_ncd_meds_date;
CREATE TEMPORARY TABLE temp_baseline_ncd_meds_date
(
SELECT person_id, MIN(obs_datetime) baseline_date_ncd_meds FROM temp_stage_ncd_meds
GROUP BY person_id ORDER BY person_id
);

-- baseline ncd meds
DROP TEMPORARY TABLE IF EXISTS temp_baseline_ncd_meds;
CREATE TEMPORARY TABLE temp_baseline_ncd_meds
(
SELECT tsnm.person_id, concept_id, baseline_date_ncd_meds, GROUP_CONCAT(ncd_meds SEPARATOR " | ") baseline_ncd_meds FROM temp_stage_ncd_meds tsnm INNER JOIN temp_baseline_ncd_meds_date tbnmd
ON tsnm.person_id = tbnmd.person_id AND tsnm.obs_datetime = tbnmd.baseline_date_ncd_meds GROUP BY tsnm.person_id
);

-- lastr ncd meds recorded
DROP TEMPORARY TABLE IF EXISTS temp_latest_ncd_meds;
CREATE TEMPORARY TABLE temp_latest_ncd_meds
(
SELECT tsnm.person_id, concept_id, latest_date_ncd_meds, GROUP_CONCAT(ncd_meds SEPARATOR " | ") latest_ncd_meds FROM temp_stage_ncd_meds tsnm INNER JOIN temp_latest_ncd_meds_date tlnmd
ON tsnm.person_id = tlnmd.person_id AND tsnm.obs_datetime = tlnmd.latest_date_ncd_meds GROUP BY tlnmd.person_id
);

UPDATE temp_ncd_program p
LEFT OUTER JOIN temp_ncd_last_ncd_enc ON p.patient_id = temp_ncd_last_ncd_enc.patient_id
-- NCD category
LEFT OUTER JOIN
(SELECT obs_cat.encounter_id,
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'HYPERTENSION' THEN '1' END) 'Hypertension',
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'DIABETES' THEN '1' END) 'Diabetes',
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'HEART FAILURE' THEN '1' END) 'Heart_Failure',
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'Cerebrovascular Accident' THEN '1' END) 'Stroke',
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'Chronic respiratory disease program' THEN '1' END) 'Respiratory',
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'Rehab program' THEN '1' END) 'Rehab',
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'Sickle-Cell Anemia' THEN '1' END) 'Anemia',
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'EPILEPSY' THEN '1' END) 'Epilepsy',
  MAX(CASE WHEN rm_cat.source = 'PIH' AND rm_cat.code = 'OTHER' THEN '1' END) 'Other_Category'
  FROM obs obs_cat
  LEFT OUTER JOIN report_mapping rm_cat ON rm_cat.concept_id = obs_cat.value_coded
  WHERE obs_cat.concept_id =
 (SELECT concept_id FROM report_mapping rm_next WHERE rm_next.source = 'PIH' AND rm_next.code = 'NCD category')
 AND obs_cat.voided = 0
 GROUP BY 1
 ) cats ON cats.encounter_id = temp_ncd_last_ncd_enc.encounter_id
SET p.hypertension = cats.Hypertension,
p.diabetes = cats.Diabetes,
p.heart_Failure = cats.Heart_Failure,
p.stroke = cats.Stroke,
p.respiratory = cats.Respiratory,
p.rehab = cats.Rehab,
p.anemia = cats.Anemia,
p.epilepsy = cats.Epilepsy,
p.other_category = cats.Other_Category;

-- ncd_diagnoses
DROP TEMPORARY TABLE IF EXISTS temp_stage_ncd_diagnoses;
CREATE TEMPORARY TABLE temp_stage_ncd_diagnoses
(
person_id INT(11),
concept_id INT(11),
value_coded INT(11),
obs_datetime DATETIME
);
INSERT INTO temp_stage_ncd_diagnoses (person_id, concept_id, value_coded, obs_datetime)
  SELECT person_id, concept_id, value_coded, DATE(obs_datetime) FROM obs WHERE encounter_id IN (SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type IN (@NCDInitEnc, @NCDFollowEnc))
  AND concept_id = (SELECT concept_id FROM report_mapping WHERE source = 'PIH' AND code = 'DIAGNOSIS') AND voided = 0;

DROP TEMPORARY TABLE IF EXISTS temp_ncd_first_baseline_diagnoses;
CREATE TEMPORARY TABLE temp_ncd_first_baseline_diagnoses
(
person_id_1 INT(11),
concept_id_1 INT(11),
value_coded_1 INT(11),
obs_datetime_1 DATETIME,
baseline_non_coded_diagnosis TEXT
);
INSERT INTO temp_ncd_first_baseline_diagnoses (person_id_1, concept_id_1, value_coded_1, obs_datetime_1)
  SELECT person_id, concept_id, value_coded, MIN(obs_datetime) baseline_date_of_diagnosis FROM temp_stage_ncd_diagnoses tsnld GROUP BY tsnld.person_id ORDER BY tsnld.person_id;
-- baseline 3 diagnoses
UPDATE temp_ncd_first_baseline_diagnoses tnfbd
LEFT JOIN (SELECT person_id, concept_id, DATE(obs_datetime) obsdatetime, value_text
FROM  obs o WHERE o.concept_id = (SELECT concept_id FROM report_mapping WHERE source = 'PIH' AND code = 'Diagnosis or problem, non-coded') AND o.voided = 0 AND
o.encounter_id IN (SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type IN (@NCDInitEnc, @NCDFollowEnc))) ob
  ON ob.person_id = tnfbd.person_id_1 AND tnfbd.obs_datetime_1 = ob.obsdatetime
SET tnfbd.baseline_non_coded_diagnosis = ob.value_text;

DROP TEMPORARY TABLE IF EXISTS temp_ncd_filtered_baseline_diagnoses_2;
CREATE TEMPORARY TABLE temp_ncd_filtered_baseline_diagnoses_2
(
SELECT person_id, concept_id, value_coded, obs_datetime, person_id_1, concept_id_1, value_coded_1, obs_datetime_1 FROM temp_stage_ncd_diagnoses tsnld INNER JOIN
temp_ncd_first_baseline_diagnoses tnfbd ON tsnld.person_id = tnfbd.person_id_1 AND tsnld.obs_datetime = tnfbd.obs_datetime_1
);

DROP TEMPORARY TABLE IF EXISTS temp_ncd_filtered_baseline_diagnoses_3;
CREATE TEMPORARY TABLE temp_ncd_filtered_baseline_diagnoses_3
(
SELECT person_id, concept_id, value_coded, obs_datetime FROM temp_ncd_filtered_baseline_diagnoses_2 tnfbd2 INNER JOIN temp_ncd_first_baseline_diagnoses tnfbd
  ON tnfbd2.person_id = tnfbd.person_id_1 AND tnfbd2.value_coded <> tnfbd.value_coded_1 GROUP BY tnfbd2.person_id
);

DROP TEMPORARY TABLE IF EXISTS temp_ncd_filtered_baseline_diagnoses_4;
CREATE TEMPORARY TABLE temp_ncd_filtered_baseline_diagnoses_4
(
SELECT tnfbd2.person_id, tnfbd2.concept_id, tnfbd2.value_coded, tnfbd2.obs_datetime FROM temp_ncd_filtered_baseline_diagnoses_2 tnfbd2 INNER JOIN temp_ncd_filtered_baseline_diagnoses_3 tnfbd3 ON tnfbd2.person_id = tnfbd3.person_id
AND tnfbd2.obs_datetime = tnfbd3.obs_datetime AND tnfbd2.value_coded NOT IN (tnfbd3.value_coded)
  INNER JOIN temp_ncd_first_baseline_diagnoses tnfbd ON tnfbd2.person_id = tnfbd.person_id_1 AND tnfbd2.obs_datetime = tnfbd.obs_datetime_1
  AND  tnfbd2.value_coded NOT IN (tnfbd.value_coded_1) GROUP BY tnfbd2.person_id
);

-- last 3 diagnoses
DROP TEMPORARY TABLE IF EXISTS temp_ncd_first_latest_diagnoses;
CREATE TEMPORARY TABLE temp_ncd_first_latest_diagnoses
(
person_id_2 INT(11),
concept_id_2 INT(11),
value_coded_2 INT(11),
obs_datetime_2 DATETIME,
latest_non_coded_diagnosis TEXT
);
INSERT INTO temp_ncd_first_latest_diagnoses (person_id_2, concept_id_2, value_coded_2, obs_datetime_2)
  SELECT person_id, concept_id, value_coded, MAX(obs_datetime) latest_date_of_diagnosis FROM temp_stage_ncd_diagnoses tsnld GROUP BY tsnld.person_id ORDER BY tsnld.person_id;

UPDATE temp_ncd_first_latest_diagnoses tnfld
LEFT JOIN (SELECT person_id, concept_id, DATE(obs_datetime) obsdatetime, value_text
FROM  obs o WHERE o.concept_id = (SELECT concept_id FROM report_mapping WHERE source = 'PIH' AND code = 'Diagnosis or problem, non-coded') AND o.voided = 0 AND
o.encounter_id IN (SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type IN (@NCDInitEnc, @NCDFollowEnc))) o1
  ON o1.person_id = tnfld.person_id_2 AND tnfld.obs_datetime_2 = o1.obsdatetime
SET tnfld.latest_non_coded_diagnosis = o1.value_text;

DROP TEMPORARY TABLE IF EXISTS temp_ncd_filtered_latest_diagnoses_2;
CREATE TEMPORARY TABLE temp_ncd_filtered_latest_diagnoses_2
(
SELECT person_id, concept_id, value_coded, obs_datetime, person_id_2, concept_id_2, value_coded_2, obs_datetime_2 FROM temp_stage_ncd_diagnoses tsnld INNER JOIN
temp_ncd_first_latest_diagnoses tnfld ON tsnld.person_id = tnfld.person_id_2 AND tsnld.obs_datetime = tnfld.obs_datetime_2
);

DROP TEMPORARY TABLE IF EXISTS temp_ncd_filtered_latest_diagnoses_3;
CREATE TEMPORARY TABLE temp_ncd_filtered_latest_diagnoses_3
(
SELECT person_id, concept_id, value_coded, obs_datetime FROM temp_ncd_filtered_latest_diagnoses_2 tnfld2 INNER JOIN temp_ncd_first_latest_diagnoses tnfld
  ON tnfld2.person_id = tnfld.person_id_2 AND tnfld2.value_coded <> tnfld.value_coded_2 GROUP BY tnfld2.person_id
);

DROP TEMPORARY TABLE IF EXISTS temp_ncd_filtered_latest_diagnoses_4;
CREATE TEMPORARY TABLE temp_ncd_filtered_latest_diagnoses_4
(
SELECT tnfld2.person_id, tnfld2.concept_id, tnfld2.value_coded, tnfld2.obs_datetime FROM temp_ncd_filtered_latest_diagnoses_2 tnfld2 INNER JOIN temp_ncd_filtered_latest_diagnoses_3 tnfld3 ON tnfld2.person_id = tnfld3.person_id
AND tnfld2.obs_datetime = tnfld3.obs_datetime AND tnfld2.value_coded NOT IN (tnfld3.value_coded)
  INNER JOIN temp_ncd_first_latest_diagnoses tnfld ON tnfld2.person_id = tnfld.person_id_2 AND tnfld2.obs_datetime = tnfld.obs_datetime_2
  AND  tnfld2.value_coded NOT IN (tnfld.value_coded_2) GROUP BY tnfld2.person_id
);

DROP TEMPORARY TABLE IF EXISTS temp_ncd_final_diagnoses;
CREATE TEMPORARY TABLE temp_ncd_final_diagnoses
(
SELECT person_id_1, person_id_2, obs_datetime_1, obs_datetime_2, CONCEPT_NAME(value_coded_1, 'en') baseline_diagnosis_1, 
	   CONCEPT_NAME(tnfbd3.value_coded, 'en') baseline_diagnosis_2, CONCEPT_NAME(tnfbd4.value_coded, 'en') baseline_diagnosis_3, 
	   CONCEPT_NAME(value_coded_2, 'en') latest_diagnosis_1, CONCEPT_NAME(tnfld3.value_coded, 'en') latest_diagnosis_2,
       CONCEPT_NAME(tnfld4.value_coded, 'en') latest_diagnosis_3, baseline_non_coded_diagnosis, latest_non_coded_diagnosis
       FROM temp_ncd_first_baseline_diagnoses tnfbd
  LEFT JOIN
  temp_ncd_filtered_baseline_diagnoses_3 tnfbd3 ON tnfbd.person_id_1 = tnfbd3.person_id
  LEFT JOIN
  temp_ncd_filtered_baseline_diagnoses_4 tnfbd4 ON  tnfbd.person_id_1 = tnfbd4.person_id
  LEFT JOIN
  temp_ncd_first_latest_diagnoses tnfld ON tnfbd.person_id_1 = tnfld.person_id_2
  LEFT JOIN
  temp_ncd_filtered_latest_diagnoses_3 tnfld3 ON tnfbd.person_id_1 = tnfld3.person_id
  LEFT JOIN
  temp_ncd_filtered_latest_diagnoses_4 tnfld4 ON  tnfbd.person_id_1 = tnfld4.person_id
ORDER BY tnfbd.person_id_1
);

-- last NYHA recorded
DROP TEMPORARY TABLE IF EXISTS temp_stage_ncd_nyha;
CREATE TEMPORARY TABLE temp_stage_ncd_nyha
(
SELECT person_id, concept_id, CONCEPT_NAME(value_coded, 'en') nyha, DATE(obs_datetime) obsdatetime FROM obs WHERE concept_id = (SELECT concept_id FROM report_mapping rm_next WHERE rm_next.source = 'PIH' AND rm_next.code = 'NYHA CLASS')
AND voided = 0 AND encounter_id IN (SELECT encounter_id FROM encounter WHERE voided = 0 AND encounter_type IN (@NCDInitEnc, @NCDFollowEnc))
);

DROP TEMPORARY TABLE IF EXISTS temp_final_ncd_nyha;
CREATE TEMPORARY TABLE temp_final_ncd_nyha
(
SELECT person_id, concept_id, GROUP_CONCAT(nyha SEPARATOR " | ") last_nyha_classes, obsdatetime FROM temp_stage_ncd_nyha INNER JOIN
temp_ncd_program ON temp_ncd_program.patient_id = temp_stage_ncd_nyha.person_id AND temp_ncd_program.last_ncd_encounter = temp_stage_ncd_nyha.obsdatetime
GROUP BY temp_stage_ncd_nyha.person_id
);

-- asthma detail recorded during last encounter
UPDATE temp_ncd_last_ncd_enc SET asthma_diagnosis = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', 'Asthma classification', 'fr');


SELECT
p.patient_id "patient_id",
ZLEMR(p.patient_id) zlemr_id,
DOSID(p.patient_id) dossier_id,
given_name,
family_name,
birthdate,
birthdate_estimated,
gender,
country,
department,
commune,
section_communal,
locality,
street_landmark,
telephone_number,
contact_telephone_number,
DATE(date_enrolled) "enrolled_in_program",
program_state,
program_outcome,
disposition,
first_ncd_encounter,
last_ncd_encounter,
next_ncd_appointment,
thirty_days_past_app "30_days_past_app",
deceased,
hypertension,
diabetes,
heart_Failure,
stroke,
respiratory,
rehab,
anemia,
epilepsy,
asthma_diagnosis,
other_category,
tfnn.obsdatetime "date_last_nyha_classes",
last_nyha_classes,
lack_of_meds,
visit_adherence,
recent_hospitalization,
HbA1c_result,
HbA1c_collection_date,
HbA1c_result_date,
bp_diastolic,
bp_systolic,
height,
weight,
creatinine_result,
creatinine_collection_date,
creatinine_result_date,
baseline_date_ncd_meds,
baseline_ncd_meds,
IF(baseline_ncd_meds LIKE '%nsulin%', 'oui', 'non') prescribed_insulin_during_baseline,
latest_date_ncd_meds,
latest_ncd_meds,
IF(latest_ncd_meds LIKE '%nsulin%', 'oui', 'non') prescribed_insulin,
obs_datetime_1 'baseline_diagnosis_date',
baseline_diagnosis_1,
baseline_diagnosis_2,
baseline_diagnosis_3,
baseline_non_coded_diagnosis,
obs_datetime_2 'latest_diagnosis_date',
latest_diagnosis_1,
latest_diagnosis_2,
latest_diagnosis_3,
latest_non_coded_diagnosis
FROM temp_ncd_program p LEFT OUTER JOIN temp_ncd_last_ncd_enc tlne ON p.patient_id = tlne.patient_id
  LEFT OUTER JOIN temp_ncd_final_diagnoses tnfld ON p.patient_id = tnfld.person_id_1
  LEFT OUTER JOIN temp_latest_ncd_meds tlnm ON p.patient_id = tlnm.person_id
  LEFT OUTER JOIN temp_ncd_lack_of_meds tnlom ON p.patient_id = tnlom.person_id
  LEFT OUTER JOIN temp_final_ncd_nyha tfnn ON p.patient_id = tfnn.person_id
  LEFT OUTER JOIN temp_baseline_ncd_meds tbnm ON p.patient_id = tbnm.person_id;