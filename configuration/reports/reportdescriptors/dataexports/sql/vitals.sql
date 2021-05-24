
-- set @startDate = '2021-03-18';
-- set @endDate = '2021-03-20';

CALL initialize_global_metadata();
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
SET @locale_yes = concept_name(concept_from_mapping('PIH','YES'),@locale);
SET @locale_no = concept_name(concept_from_mapping('PIH','NO'),@locale);

DROP TEMPORARY TABLE IF EXISTS temp_vitals;
CREATE TEMPORARY TABLE temp_vitals
(
    patient_id					INT(11),
	zlemr						VARCHAR(50),
	loc_registered				VARCHAR(255),
	unknown_patient				VARCHAR(50),
	gender						VARCHAR(50),
	age_at_enc					INT(11),
	department					VARCHAR(255),	
	commune						VARCHAR(255),	
	section						VARCHAR(255),
	locality					VARCHAR(255),	
	street_landmark				VARCHAR(255),	
	encounter_id				INT(11),
	encounter_datetime			DATETIME,
	encounter_location			VARCHAR(255),
	entered_by          		VARCHAR(255),	
	provider					VARCHAR(255),	
	weight_kg					DOUBLE,
	height_cm					DOUBLE,
	#bmi						double,	--calulated
	muac						DOUBLE,
	temp_c						DOUBLE,
	heart_rate					DOUBLE,
	resp_rate					DOUBLE,
	sys_bp						DOUBLE,
	dia_bp						DOUBLE,
	o2_sat						DOUBLE,
	date_created				DATETIME,
	retrospective				TINYINT(1),
	visit_id					INT(11),
	birthdate					DATETIME,
	birthdate_estimated			TINYINT(1),
	section_communale_CDC_ID	VARCHAR(11),
	level_of_mobility			TEXT,
	confused					VARCHAR(11),
	level_of_consciousness 		TEXT, 
	TB_symptoms					TEXT,
    cough_lasting_2weeks		VARCHAR(11),
    fever						VARCHAR(11),
    night_sweats  				VARCHAR(11),
    weight_loss					VARCHAR(11),
    chief_complaint				TEXT
);

INSERT INTO temp_vitals(
	patient_id,
	encounter_id,
	visit_id,
	encounter_datetime,
    date_created,
    entered_by
)
SELECT  patient_id,
		encounter_id,
        visit_id,
        encounter_datetime,
        date_created,
        creator
FROM encounter e
WHERE voided = 0
AND encounter_type = (SELECT encounter_type_id 
			FROM encounter_type
			WHERE uuid = '4fb47712-34a6-40d2-8ed3-e153abbd25b7') #Vital Signs
AND DATE(encounter_datetime) >=@startDate
AND DATE(encounter_datetime) <=@endDate
;

UPDATE temp_vitals SET department = PERSON_ADDRESS_STATE_PROVINCE(patient_id);
UPDATE temp_vitals SET commune = PERSON_ADDRESS_CITY_VILLAGE(patient_id);
UPDATE temp_vitals SET section = PERSON_ADDRESS_THREE(patient_id);
UPDATE temp_vitals SET locality = PERSON_ADDRESS_ONE(patient_id);
UPDATE temp_vitals SET street_landmark = PERSON_ADDRESS_TWO(patient_id);

UPDATE temp_vitals tv
        INNER JOIN
    (SELECT person_id, birthdate_estimated
    FROM person
    WHERE voided = 0
    ORDER BY date_created DESC) p 
	ON tv.patient_id = p.person_id 
SET tv.birthdate_estimated = p.birthdate_estimated;

UPDATE temp_vitals SET zlemr = ZLEMR(patient_id);
UPDATE temp_vitals SET loc_registered = LOC_REGISTERED(patient_id);
UPDATE temp_vitals SET unknown_patient = UNKNOWN_PATIENT(patient_id);
UPDATE temp_vitals SET gender = GENDER(patient_id);
UPDATE temp_vitals SET encounter_location = ENCOUNTER_LOCATION_NAME(encounter_id);
UPDATE temp_vitals SET provider = PROVIDER(encounter_id);
UPDATE temp_vitals SET birthdate = BIRTHDATE(patient_id);
UPDATE temp_vitals SET age_at_enc = AGE_AT_ENC(patient_id, encounter_id);
UPDATE temp_vitals SET section_communale_CDC_ID = CDC_ID(patient_id);
	 
UPDATE temp_vitals SET weight_kg = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5089');
UPDATE temp_vitals SET height_cm = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5090');
UPDATE temp_vitals SET muac = OBS_VALUE_NUMERIC(encounter_id, 'PIH', '7956');
UPDATE temp_vitals SET temp_c = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5088');
UPDATE temp_vitals SET heart_rate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5087');
UPDATE temp_vitals SET resp_rate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5087');
UPDATE temp_vitals SET sys_bp = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5085');
UPDATE temp_vitals SET dia_bp = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5086');
UPDATE temp_vitals SET o2_sat = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5092');	
UPDATE temp_vitals SET level_of_mobility = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162753', @locale);

UPDATE temp_vitals SET confused = 
CASE 
	WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','1293','PIH','6006') = @locale_yes THEN @locale_yes
	WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','1734','PIH','6006') = @locale_yes THEN @locale_no
	ELSE NULL
END;
               
UPDATE temp_vitals SET level_of_consciousness = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '10674', @locale);
 
UPDATE temp_vitals SET TB_symptoms = OBS_VALUE_CODED_LIST(encounter_id, 'PIH', '11563', @locale);

UPDATE temp_vitals SET  cough_lasting_2weeks = 
CASE 
	WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','11563','PIH','11567') = @locale_yes THEN @locale_yes
	WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','11564','PIH','11567') = @locale_yes THEN @locale_no
	ELSE NULL
END;

UPDATE temp_vitals SET  fever = 
CASE 
	WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','11563','PIH','5945') = @locale_yes THEN @locale_yes
	WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','11564','PIH','5945') = @locale_yes THEN @locale_no
	ELSE NULL
END;

UPDATE temp_vitals SET  night_sweats = 
CASE 
      WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','11563','PIH','6029') = @locale_yes THEN @locale_yes
      WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','11564','PIH','6029') = @locale_yes THEN @locale_no
      ELSE NULL
END;

UPDATE temp_vitals SET  weight_loss = 
CASE 
	WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','11563','PIH','6477') = @locale_yes THEN @locale_yes
	WHEN OBS_SINGLE_VALUE_CODED(encounter_id,'PIH','11564','PIH','6477') = @locale_yes THEN @locale_no
	ELSE NULL
END;

UPDATE temp_vitals SET chief_complaint = obs_value_text(encounter_id, 'CIEL', '160531');

SELECT 
    patient_id,
    zlemr,
    loc_registered,
    unknown_patient,
    gender,
    age_at_enc,
    department,
    commune,
    section,
    locality,
    street_landmark,
    encounter_id,
    encounter_datetime,
    encounter_location,
    entered_by,
    provider,
    weight_kg,
    height_cm,
    ROUND(weight_kg / ((height_cm / 100) * (height_cm / 100)),1) AS bmi,
    muac,
    temp_c,
    heart_rate,
    resp_rate,
    sys_bp,
    dia_bp,
    o2_sat,
    date_created,
    IF(TIME_TO_SEC(date_created) - TIME_TO_SEC(encounter_datetime) > 1800,
        @locale_yes,
        @locale_no) AS retrospective,
    visit_id,
    birthdate,
    IF(birthdate_estimated=1,@locale_yes,@locale_no) AS birthdate_estimated,
    section_communale_CDC_ID,
    level_of_mobility,
    confused,
    level_of_consciousness,
    cough_lasting_2weeks,
    fever,
    night_sweats,
    weight_loss,
    chief_complaint
FROM
    temp_vitals
;
