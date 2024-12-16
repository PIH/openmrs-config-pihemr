DROP TEMPORARY TABLE IF EXISTS temp_mentalhealth_visit;

SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

SET @encounter_type = ENCOUNTER_TYPE('Mental Health Consult');
SET @role_of_referring_person = CONCEPT_FROM_MAPPING('PIH','Role of referring person');
SET @other_referring_person = CONCEPT_FROM_MAPPING('PIH','OTHER');
SET @type_of_referral_role = CONCEPT_FROM_MAPPING('PIH','Type of referral role');
SET @other_referring_role_type = CONCEPT_FROM_MAPPING('PIH','OTHER');
SET @hospitalization = CONCEPT_FROM_MAPPING('CIEL','976');
SET @hospitalization_reason = CONCEPT_FROM_MAPPING('CIEL','162879');
SET @type_of_patient =  CONCEPT_FROM_MAPPING('PIH', 'TYPE OF PATIENT');
SET @inpatient_hospitalization = CONCEPT_FROM_MAPPING('PIH','INPATIENT HOSPITALIZATION');
SET @traumatic_event = CONCEPT_FROM_MAPPING('PIH','12362');
SET @yes =   CONCEPT_FROM_MAPPING('PIH', 'YES');
SET @adherence_to_appt = CONCEPT_FROM_MAPPING('PIH','Appearance at appointment time');
SET @zldsi_score = CONCEPT_FROM_MAPPING('CIEL','163225');
SET @ces_dc = CONCEPT_FROM_MAPPING('CIEL','163228');
SET @psc_35 = CONCEPT_FROM_MAPPING('CIEL','165534');
SET @pcl = CONCEPT_FROM_MAPPING('CIEL','165535');
SET @cgi_s = CONCEPT_FROM_MAPPING('CIEL','163222');
SET @cgi_i = CONCEPT_FROM_MAPPING('CIEL','163223');
SET @cgi_e = CONCEPT_FROM_MAPPING('CIEL','163224');
SET @whodas = CONCEPT_FROM_MAPPING('CIEL','163226');
SET @days_with_difficulties = CONCEPT_FROM_MAPPING('PIH','Days with difficulties in past month');
SET @days_without_usual_activity = CONCEPT_FROM_MAPPING('PIH','Days without usual activity in past month');
SET @days_with_less_activity = CONCEPT_FROM_MAPPING('PIH','Days with less activity in past month');
SET @aims = CONCEPT_FROM_MAPPING('CIEL','163227');
SET @seizure_frequency = CONCEPT_FROM_MAPPING('PIH','Number of seizures in the past month');
SET @past_suicidal_evaluation = CONCEPT_FROM_MAPPING('CIEL','1628');
SET @current_suicidal_evaluation = CONCEPT_FROM_MAPPING('PIH','Mental health diagnosis');
SET @last_suicide_attempt_date = CONCEPT_FROM_MAPPING('CIEL','165530');
SET @suicidal_screen_completed = CONCEPT_FROM_MAPPING('PIH','Suicidal evaluation');
SET @suicidal_screening_result = CONCEPT_FROM_MAPPING('PIH', 'Result of suicide risk evaluation');
SET @security_plan = CONCEPT_FROM_MAPPING('PIH','Security plan');
SET @discuss_patient_with_supervisor = CONCEPT_FROM_MAPPING('CIEL', '165532');
SET @hospitalize_due_to_suicide_risk = CONCEPT_FROM_MAPPING('CIEL', '165533');
SET @mh_diagnosis = CONCEPT_FROM_MAPPING('PIH','Mental health diagnosis');
SET @hum_diagnoses = CONCEPT_FROM_MAPPING('PIH','HUM Psychological diagnoses');
SET @mental_health_intervention = CONCEPT_FROM_MAPPING('PIH','Mental health intervention');
SET @other = CONCEPT_FROM_MAPPING('PIH','OTHER');
SET @medication = CONCEPT_FROM_MAPPING('PIH', 'Mental health medication');
SET @dose =  CONCEPT_FROM_MAPPING('CIEL', '160856 ');
SET @dosing_units =  CONCEPT_FROM_MAPPING('PIH', 'Dosing units coded');
SET @frequency =  CONCEPT_FROM_MAPPING('PIH', 'Drug frequency for HUM');
SET @duration =  CONCEPT_FROM_MAPPING('CIEL', '159368 ');
SET @duration_units =  CONCEPT_FROM_MAPPING('PIH', 'TIME UNITS');
SET @medication_comments = CONCEPT_FROM_MAPPING('PIH', 'Medication comments (text)');
SET @pregnant = CONCEPT_FROM_MAPPING('CIEL', '5272');
SET @last_menstruation_date = CONCEPT_FROM_MAPPING('PIH','DATE OF LAST MENSTRUAL PERIOD');
SET @estimated_delivery_date = CONCEPT_FROM_MAPPING('PIH','ESTIMATED DATE OF CONFINEMENT');
SET @type_of_referral_roles = CONCEPT_FROM_MAPPING('PIH','Role of referral out provider');
SET @type_of_provider = CONCEPT_FROM_MAPPING('PIH','Type of provider');
SET @disposition = CONCEPT_FROM_MAPPING('PIH','HUM Disposition categories');
SET @disposition_comment = CONCEPT_FROM_MAPPING('PIH','PATIENT PLAN COMMENTS');
SET @return_date = CONCEPT_FROM_MAPPING('PIH','RETURN VISIT DATE');
SET @routes = CONCEPT_FROM_MAPPING('PIH', '12651');
SET @oral = CONCEPT_FROM_MAPPING('CIEL', '160240');
SET @intraveneous = CONCEPT_FROM_MAPPING('CIEL', '160242');
SET @intramuscular = CONCEPT_FROM_MAPPING('CIEL', '160243');


CREATE TEMPORARY TABLE temp_mentalhealth_visit
(
patient_id INT,
emr_id VARCHAR(255),
gender VARCHAR(50),
unknown_patient TEXT,
patient_address TEXT,
provider VARCHAR(255),
loc_registered VARCHAR(255),
location_id INT,
enc_location VARCHAR(255),
encounter_id INT,
encounter_date DATETIME,
age_at_enc DOUBLE,
visit_date DATE,
visit_id INT,
referred_from_community_by VARCHAR(255),
other_referring_person VARCHAR(255),
type_of_referral_role VARCHAR(255),
other_referring_role_type VARCHAR(255),
hospitalized_since_last_visit VARCHAR(50),
hospitalization_reason TEXT,
hospitalized_at_time_of_visit VARCHAR(50),
traumatic_event VARCHAR(50),
adherence_to_appt VARCHAR(225),
zldsi_score DOUBLE,
ces_dc DOUBLE,
psc_35 DOUBLE,
pcl DOUBLE,
cgi_s DOUBLE,
cgi_i DOUBLE,
cgi_e DOUBLE,
whodas DOUBLE,
days_with_difficulties DOUBLE,
days_without_usual_activity DOUBLE,
days_with_less_activity DOUBLE,
aims VARCHAR(255),
seizure_frequency DOUBLE,
past_suicidal_evaluation VARCHAR(255),
current_suicidal_evaluation VARCHAR(255),
last_suicide_attempt_date DATE,
suicidal_screen_completed VARCHAR(50),
suicidal_screening_result VARCHAR(255),
high_result_for_suicidal_screening TEXT,
diagnosis TEXT,
psychological_intervention TEXT,
other_psychological_intervention TEXT,
obs_group_id_med1 INT,
medication_1 TEXT,
drug_name_1 TEXT,
quantity_1 DOUBLE,
dosing_units_1 TEXT,
frequency_1 TEXT,
duration_1 DOUBLE,
duration_units_1 TEXT,
route_1 TEXT,
obs_group_id_med2 INT,
medication_2 TEXT,
drug_name_2 TEXT,
quantity_2 DOUBLE,
dosing_units_2 TEXT,
frequency_2 TEXT,
duration_2 DOUBLE,
duration_units_2 TEXT,
route_2 TEXT,
obs_group_id_med3 INT,
medication_3 TEXT,
drug_name_3 TEXT,
quantity_3 DOUBLE,
dosing_units_3 TEXT,
frequency_3 TEXT,
duration_3 DOUBLE,
duration_units_3 TEXT,
route_3 TEXT,
medication_comments TEXT,
pregnant VARCHAR(50),
last_menstruation_date DATE,
estimated_delivery_date DATE,
type_of_provider TEXT,
type_of_referral_roles TEXT,
disposition VARCHAR(255),
disposition_comment TEXT,
return_date DATE
);

INSERT INTO temp_mentalhealth_visit (   patient_id,
                                        gender,
                                        encounter_id,
                                        encounter_date,
                                        age_at_enc,
                                        provider,
                                        patient_address,
                                        -- loc_registered,
                                        location_id,
                                        -- visit_date,
                                        visit_id
                                        )
SELECT patient_id,
       GENDER(patient_id),
       encounter_id,
       encounter_datetime,
       AGE_AT_ENC(patient_id, encounter_id),
       PROVIDER(encounter_id),
       PERSON_ADDRESS(patient_id),
       -- loc_registered(patient_id),
       location_id,
       -- visit_date(patient_id),
       visit_id
 FROM encounter WHERE voided = 0 AND encounter_type = @encounter_type
-- filter by date
 AND DATE(encounter_datetime) >=  date(@startDate)
 AND DATE(encounter_datetime) <=  date(@endDate)
;

-- exclude test patients
DELETE FROM temp_mentalhealth_visit WHERE
patient_id IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = (SELECT
person_attribute_type_id FROM person_attribute_type WHERE name = "Test Patient")
                         AND voided = 0);
-- emr id
update temp_mentalhealth_visit tmhv set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
-- unknown patient
UPDATE temp_mentalhealth_visit tmhv
SET tmhv.unknown_patient = IF(tmhv.patient_id = UNKNOWN_PATIENT(tmhv.patient_id), 'true', NULL);
-- location
UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN location l ON tmhv.location_id = l.location_id
SET tmhv.enc_location = l.name;

-- Role of referring person
UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT encounter_id,  GROUP_CONCAT(name SEPARATOR ' | ') names  FROM obs o JOIN concept_name cn ON cn.concept_id = o.value_coded AND cn.voided = 0
AND o.voided = 0 AND o.concept_id = @role_of_referring_person AND cn.locale = "fr" AND concept_name_type = "FULLY_SPECIFIED"
GROUP BY encounter_id
) o ON o.encounter_id = tmhv.encounter_id
SET tmhv.referred_from_community_by = o.names;

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.other_referring_person = (SELECT comments FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND value_coded = @other_referring_person
AND concept_id = @role_of_referring_person);

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT encounter_id, GROUP_CONCAT(name SEPARATOR ' | ') names FROM obs o JOIN concept_name cn ON cn.concept_id = o.value_coded AND cn.voided = 0
AND o.voided = 0 AND o.concept_id = @type_of_referral_role AND cn.locale = "fr" AND concept_name_type = "FULLY_SPECIFIED"
GROUP BY encounter_id
) o ON o.encounter_id = tmhv.encounter_id
SET tmhv.type_of_referral_role = o.names;

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.other_referring_role_type = (SELECT comments FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND value_coded = @other_referring_role_type
AND concept_id = @type_of_referral_role);

-- hospitalization
UPDATE temp_mentalhealth_visit tmhv
SET tmhv.hospitalized_since_last_visit = (SELECT CONCEPT_NAME(value_coded, 'fr') FROM obs WHERE voided = 0 AND concept_id = @hospitalization AND tmhv.encounter_id = encounter_id);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.hospitalization_reason = (SELECT value_text FROM obs WHERE voided = 0 AND concept_id = @hospitalization_reason AND tmhv.encounter_id = encounter_id);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.hospitalization_reason = (SELECT value_text FROM obs WHERE voided = 0 AND concept_id = @hospitalization_reason AND tmhv.encounter_id = encounter_id);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.hospitalized_at_time_of_visit = IF(@inpatient_hospitalization=(SELECT value_coded FROM obs WHERE voided = 0 AND concept_id = @type_of_patient
AND tmhv.encounter_id = encounter_id), 'Oui', NULL);

-- traumatic event
UPDATE temp_mentalhealth_visit tmhv
SET tmhv.traumatic_event = IF(@yes=(SELECT value_coded FROM obs WHERE voided = 0 AND concept_id = @traumatic_event
AND tmhv.encounter_id = encounter_id), 'Oui', NULL);

-- Adherence to appointment day
UPDATE temp_mentalhealth_visit tmhv
SET tmhv.adherence_to_appt = (SELECT CONCEPT_NAME(value_coded, 'fr') FROM obs WHERE voided = 0 AND concept_id = @adherence_to_appt
AND tmhv.encounter_id = encounter_id);

-- scores
UPDATE temp_mentalhealth_visit tmhv
SET tmhv.zldsi_score = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @zldsi_score);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.ces_dc = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @ces_dc);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.psc_35 = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @psc_35);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.pcl = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @pcl);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.cgi_s = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @cgi_s);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.cgi_i = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @cgi_i);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.cgi_e = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @cgi_e);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.whodas = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @whodas);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.days_with_difficulties = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @days_with_difficulties);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.days_without_usual_activity = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @days_without_usual_activity);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.days_with_less_activity = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @days_with_less_activity);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.aims = (SELECT CONCEPT_NAME(value_coded, 'fr') FROM obs WHERE voided = 0 AND concept_id = @aims AND tmhv.encounter_id = encounter_id);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.seizure_frequency = (SELECT value_numeric FROM obs WHERE voided = 0 AND encounter_id = tmhv.encounter_id AND concept_id = @seizure_frequency);

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT GROUP_CONCAT(cn.name SEPARATOR ' | ') names, encounter_id FROM concept_name cn JOIN obs o ON o.voided = 0 AND cn.voided = 0 AND
value_coded = cn.concept_id AND locale='fr' AND concept_name_type = "FULLY_SPECIFIED" AND o.concept_id = @past_suicidal_evaluation GROUP BY encounter_id) o
ON tmhv.encounter_id = o.encounter_id
SET tmhv.past_suicidal_evaluation  = o.names;

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT GROUP_CONCAT(cn.name SEPARATOR ' | ') names, encounter_id FROM concept_name cn JOIN obs o ON o.voided = 0 AND cn.voided = 0 AND
value_coded = cn.concept_id AND locale='fr' AND concept_name_type = "FULLY_SPECIFIED" AND o.concept_id = @current_suicidal_evaluation GROUP BY encounter_id) o
ON tmhv.encounter_id = o.encounter_id
SET tmhv.current_suicidal_evaluation  = o.names;

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.last_suicide_attempt_date = (SELECT DATE(value_datetime) FROM obs WHERE concept_id = @last_suicide_attempt_date AND voided = 0 AND tmhv.encounter_id = obs.encounter_id);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.suicidal_screen_completed = IF(1=(SELECT value_coded FROM obs WHERE concept_id = @suicidal_screen_completed AND voided = 0 AND tmhv.encounter_id = obs.encounter_id),'Oui', NULL);

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.suicidal_screening_result = (SELECT CONCEPT_NAME(value_coded, 'fr') FROM obs WHERE voided = 0 AND concept_id = @suicidal_screening_result AND tmhv.encounter_id = obs.encounter_id);

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT GROUP_CONCAT(cn.name SEPARATOR ' | ') names, encounter_id FROM concept_name cn JOIN obs o ON o.voided = 0 AND cn.voided = 0 AND
value_coded = cn.concept_id AND locale='fr' AND concept_name_type = "FULLY_SPECIFIED" AND o.concept_id = @current_suicidal_evaluation GROUP BY encounter_id) o
ON tmhv.encounter_id = o.encounter_id
SET tmhv.current_suicidal_evaluation  = o.names;

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT GROUP_CONCAT(cn.name SEPARATOR ' | ') names, encounter_id FROM concept_name cn JOIN obs o ON o.voided = 0 AND cn.voided = 0 AND
value_coded = cn.concept_id AND locale='fr' AND concept_name_type = "FULLY_SPECIFIED" AND o.value_coded IN (@security_plan, @discuss_patient_with_supervisor, @hospitalize_due_to_suicide_risk) GROUP BY encounter_id
) o ON tmhv.encounter_id = o.encounter_id
SET tmhv.high_result_for_suicidal_screening = o.names;

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT GROUP_CONCAT(cn.name SEPARATOR ' | ') names, encounter_id FROM concept_name cn JOIN obs o ON o.voided = 0 AND cn.voided = 0 AND
value_coded = cn.concept_id AND locale='fr' AND concept_name_type = "FULLY_SPECIFIED" AND o.concept_id = @mh_diagnosis
-- and value_coded in (select concept_id from concept_set where concept_set = @hum_diagnoses)
GROUP BY encounter_id
) o ON tmhv.encounter_id = o.encounter_id
SET tmhv.diagnosis = o.names;

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT GROUP_CONCAT(cn.name SEPARATOR ' | ') names, encounter_id FROM concept_name cn JOIN obs o ON o.voided = 0 AND cn.voided = 0 AND
value_coded = cn.concept_id AND locale='fr' AND concept_name_type = "FULLY_SPECIFIED" AND o.concept_id = @mental_health_intervention
GROUP BY encounter_id
) o ON tmhv.encounter_id = o.encounter_id
SET tmhv.psychological_intervention = o.names,
	tmhv.other_psychological_intervention = (SELECT comments FROM obs WHERE voided = 0 AND concept_id = @mental_health_intervention AND value_coded = @other AND tmhv.encounter_id = obs.encounter_id);

##### medications
DROP TEMPORARY TABLE IF EXISTS temp_medications_construct;
CREATE TEMPORARY TABLE temp_medications_construct
(
person_id INT, 
encounter_id INT, 
obs_group_id INT, 
obs_id INT, 
concept_id INT, 
value_coded INT,
value_numeric INT,
value_drug INT,
date_created DATETIME
);

INSERT INTO temp_medications_construct (person_id, encounter_id, obs_group_id, obs_id, concept_id, value_coded, value_numeric, value_drug, date_created)
SELECT person_id, encounter_id, obs_group_id, obs_id, concept_id, value_coded, value_numeric, value_drug, date_created FROM obs WHERE obs_group_id IN (
SELECT obs_id FROM obs WHERE concept_id = CONCEPT_FROM_MAPPING('PIH', 'Prescription construct') AND voided = 0);


DROP TEMPORARY TABLE IF EXISTS temp_med_order;
CREATE TEMPORARY TABLE temp_med_order
SELECT 
	person_id, 
	encounter_id,  
    obs_group_id, 
    obs_id, 
    concept_id, 
    value_coded,
    value_drug,
    drug_order
FROM (SELECT
		@r:= IF(@u = encounter_id, @r + 1,1) AS drug_order, person_id, encounter_id,  obs_group_id, obs_id, concept_id, value_coded, value_drug, @u:= encounter_id
FROM temp_medications_construct,
	(SELECT @rownum := 0) AS r,
	(SELECT @u:= 0) AS u
WHERE concept_id = CONCEPT_FROM_MAPPING('PIH', 'Mental health medication')
ORDER BY person_id, encounter_id, obs_group_id DESC) meds;

-- meds
UPDATE temp_mentalhealth_visit tmhv LEFT JOIN temp_med_order tmo ON patient_id = person_id AND tmhv.encounter_id = tmo.encounter_id AND tmo.drug_order = 1
SET obs_group_id_med1 = tmo.obs_group_id,
	medication_1 = CONCEPT_NAME(tmo.value_coded, 'en'),
    drug_name_1 = drugName(tmo.value_drug);

UPDATE temp_mentalhealth_visit tmhv LEFT JOIN temp_med_order tmo ON patient_id = person_id AND tmhv.encounter_id = tmo.encounter_id AND tmo.drug_order = 2
SET obs_group_id_med2 = tmo.obs_group_id,
	medication_2 = CONCEPT_NAME(tmo.value_coded, 'en'),
    drug_name_2 = drugName(tmo.value_drug);

UPDATE temp_mentalhealth_visit tmhv LEFT JOIN temp_med_order tmo ON patient_id = person_id AND tmhv.encounter_id = tmo.encounter_id AND tmo.drug_order = 3
SET obs_group_id_med3 = tmo.obs_group_id,
	medication_3 = CONCEPT_NAME(tmo.value_coded, 'en'),
    drug_name_3 = drugName(tmo.value_drug);

-- quantity
UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med1 = obs_group_id AND tmc.concept_id = CONCEPT_FROM_MAPPING('CIEL', '160856')
SET quantity_1 = value_numeric;

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med2 = obs_group_id AND tmc.concept_id = CONCEPT_FROM_MAPPING('CIEL', '160856')
SET quantity_2 = value_numeric;

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med3 = obs_group_id AND tmc.concept_id = CONCEPT_FROM_MAPPING('CIEL', '160856')
SET quantity_3 = value_numeric;

-- dosing units
UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med1 = obs_group_id AND tmc.concept_id =  @dosing_units
SET dosing_units_1 = CONCEPT_NAME(tmc.value_coded, 'en');

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med2 = obs_group_id AND tmc.concept_id = @dosing_units 
SET dosing_units_2 = CONCEPT_NAME(tmc.value_coded, 'en');

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med3 = obs_group_id AND tmc.concept_id = @dosing_units
SET dosing_units_3 = CONCEPT_NAME(tmc.value_coded, 'en');

-- duration units
UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med1 = obs_group_id AND tmc.concept_id =  @duration_units 
SET duration_units_1 = CONCEPT_NAME(tmc.value_coded, 'en');

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med2 = obs_group_id AND tmc.concept_id = @duration_units
SET duration_units_2 = CONCEPT_NAME(tmc.value_coded, 'en');

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med3 = obs_group_id AND tmc.concept_id = @duration_units 
SET duration_units_3 = CONCEPT_NAME(tmc.value_coded, 'en');

-- frequency
UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med1 = obs_group_id AND tmc.concept_id =  @frequency
SET frequency_1 = CONCEPT_NAME(tmc.value_coded, 'en');

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med2 = obs_group_id AND tmc.concept_id = @frequency
SET frequency_2 = CONCEPT_NAME(tmc.value_coded, 'en');

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med3 = obs_group_id AND tmc.concept_id = @frequency
SET frequency_3 = CONCEPT_NAME(tmc.value_coded, 'en');

-- route
UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med1 = obs_group_id AND tmc.concept_id =  @routes
SET route_1 = CONCEPT_NAME(tmc.value_coded, 'en');

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med2 = obs_group_id AND tmc.concept_id = @routes
SET route_2 = CONCEPT_NAME(tmc.value_coded, 'en');

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med3 = obs_group_id AND tmc.concept_id = @routes
SET route_3 = CONCEPT_NAME(tmc.value_coded, 'en');

-- duration
UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med1 = obs_group_id AND tmc.concept_id =  @duration
SET duration_1 = value_numeric;

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med2 = obs_group_id AND tmc.concept_id = @duration
SET duration_2 = value_numeric;

UPDATE temp_mentalhealth_visit LEFT JOIN temp_medications_construct tmc ON obs_group_id_med3 = obs_group_id AND tmc.concept_id = @duration
SET duration_3 = value_numeric;

-- medication comments
UPDATE temp_mentalhealth_visit tmhv
SET tmhv.medication_comments = (SELECT value_text FROM obs WHERE voided = 0 AND tmhv.encounter_id = obs.encounter_id AND concept_id = @medication_comments);

-- pregnancy questions
UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN obs preg ON preg.encounter_id = tmhv.encounter_id AND preg.concept_id = @pregnant AND preg.voided = 0
SET tmhv.pregnant = CONCEPT_NAME(preg.value_coded, 'fr');

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN obs lmd ON lmd.encounter_id = tmhv.encounter_id AND lmd.concept_id = @last_menstruation_date AND lmd.voided = 0
SET tmhv.last_menstruation_date = lmd.value_datetime
;

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN obs edd ON edd.encounter_id = tmhv.encounter_id AND edd.concept_id = @estimated_delivery_date AND edd.voided = 0
SET tmhv.estimated_delivery_date = edd.value_datetime
;

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT GROUP_CONCAT(cn.name SEPARATOR ' | ') names, encounter_id FROM concept_name cn JOIN obs o ON o.voided = 0 AND cn.voided = 0 AND
value_coded = cn.concept_id AND locale='fr' AND concept_name_type = "FULLY_SPECIFIED" AND o.concept_id = @type_of_provider GROUP BY encounter_id
) o ON tmhv.encounter_id = o.encounter_id
SET tmhv.type_of_provider = o.names;

UPDATE temp_mentalhealth_visit tmhv
LEFT JOIN
(
SELECT GROUP_CONCAT(cn.name SEPARATOR ' | ') names, encounter_id FROM concept_name cn JOIN obs o ON o.voided = 0 AND cn.voided = 0 AND
value_coded = cn.concept_id AND locale='fr' AND concept_name_type = "FULLY_SPECIFIED" AND o.concept_id = @type_of_referral_roles GROUP BY encounter_id
) o ON tmhv.encounter_id = o.encounter_id
SET tmhv.type_of_referral_roles = o.names;

UPDATE temp_mentalhealth_visit tmhv
SET tmhv.disposition = (SELECT CONCEPT_NAME(value_coded, 'fr') FROM obs WHERE concept_id = @disposition AND voided = 0 AND tmhv.encounter_id = obs.encounter_id),
	tmhv.disposition_comment = (SELECT value_text FROM obs WHERE concept_id = @disposition_comment AND voided = 0 AND tmhv.encounter_id = obs.encounter_id),
    tmhv.return_date = (SELECT DATE(value_datetime) FROM obs WHERE concept_id = @return_date AND voided = 0 AND tmhv.encounter_id = obs.encounter_id);


SELECT
encounter_id,
patient_id,
emr_id,
gender,
unknown_patient,
PERSON_ADDRESS_STATE_PROVINCE(patient_id) 'province',
PERSON_ADDRESS_CITY_VILLAGE(patient_id) 'city_village',
PERSON_ADDRESS_THREE(patient_id) 'address3',
PERSON_ADDRESS_ONE(patient_id) 'address1',
PERSON_ADDRESS_TWO(patient_id) 'address2',
provider,
visit_id,
enc_location,
encounter_date,
age_at_enc,
referred_from_community_by,
other_referring_person,
type_of_referral_role 'referral_role_from_within_facility',
other_referring_role_type,
hospitalized_since_last_visit,
hospitalization_reason,
hospitalized_at_time_of_visit,
traumatic_event,
adherence_to_appt,
zldsi_score,
ces_dc,
psc_35,
pcl,
cgi_s,
cgi_i,
cgi_e,
whodas,
days_with_difficulties,
days_without_usual_activity,
days_with_less_activity,
aims,
seizure_frequency,
past_suicidal_evaluation,
last_suicide_attempt_date,
suicidal_screen_completed,
suicidal_screening_result,
high_result_for_suicidal_screening,
diagnosis,
psychological_intervention,
other_psychological_intervention,
medication_1,
drug_name_1,
quantity_1,
dosing_units_1,
frequency_1,
duration_1,
duration_units_1,
route_1,
medication_2,
drug_name_2,
quantity_2,
dosing_units_2,
frequency_2,
duration_2,
duration_units_2,
route_2,
medication_3,
drug_name_3,
quantity_3,
dosing_units_3,
frequency_3,
duration_3,
duration_units_3,
route_3,
medication_comments,
pregnant, 
last_menstruation_date,
estimated_delivery_date,
type_of_provider,
type_of_referral_roles "referred_to",
disposition,
disposition_comment,
return_date
FROM temp_mentalhealth_visit
;