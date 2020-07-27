#### This report covid visit report
#### observation comes from the covid admission and covid followup forms

## sql updates
SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

-- Delete temporary covid encounter table if exists
DROP TEMPORARY TABLE IF EXISTS temp_covid_visit;

-- create temporary tale temp_covid_encounters
CREATE TEMPORARY TABLE temp_covid_visit
(
	encounter_id                  INT PRIMARY KEY,
	encounter_type_id             INT,
	patient_id                    INT,
	encounter_date                DATE,
	encounter_type                VARCHAR(255),
	location                      TEXT,
	case_condition                VARCHAR(255),
	overall_condition             VARCHAR(255),
	fever                         VARCHAR(11),
	cough                         VARCHAR(11),
	productive_cough              VARCHAR(11),
	shortness_of_breath           VARCHAR(11),
	sore_throat                   VARCHAR(11),
	rhinorrhea                    VARCHAR(11),
	headache                      VARCHAR(11),
	chest_pain                    VARCHAR(11),
	muscle_pain                   VARCHAR(11),
	fatigue                       VARCHAR(11),
	vomiting                      VARCHAR(11),
	diarrhea                      VARCHAR(11),
	loss_of_taste                 VARCHAR(11),
	sense_of_smell_loss           VARCHAR(11),
	confusion                     VARCHAR(11),
	panic_attack                  VARCHAR(11),
	suicidal_thoughts             VARCHAR(11),
	attempted_suicide             VARCHAR(11),
	other_symptom                 TEXT,
  temp                          DOUBLE,
  heart_rate                    DOUBLE,
  respiratory_rate              DOUBLE,
  bp_systolic                   DOUBLE,
  bp_diastolic                  DOUBLE,
  SpO2                          DOUBLE,
  room_air                      VARCHAR(11),
  cap_refill                    VARCHAR(50),
  cap_refill_time               DOUBLE,
  pain                          VARCHAR(50),
  general_exam                  VARCHAR(11),
  general_findings              TEXT,
  heent                         VARCHAR(11),
  heent_findings                TEXT,
  neck                          VARCHAR(11),
  neck_findings                 TEXT,
  chest                         VARCHAR(11),
  chest_findings                TEXT,
  cardiac                       VARCHAR(11),
  cardiac_findings              TEXT,
  abdominal                     VARCHAR(11),
  abdominal_findings            TEXT,
  urogenital                    VARCHAR(11),
  urogenital_findings           TEXT,
  rectal                        VARCHAR(11),
  rectal_findings               TEXT,
  musculoskeletal               VARCHAR(11),
  	musculoskeletal_findings      TEXT,
  	lymph                         VARCHAR(11),
  	lymph_findings                TEXT,
  	skin                          VARCHAR(11),
  	skin_findings                 TEXT,
  	neuro                         VARCHAR(11),
  	neuro_findings                TEXT,
 	avpu                          VARCHAR(255),
  	other_findings                TEXT,
  	medications                   VARCHAR(255),
  	medication_comments           TEXT,
  	supportive_care               VARCHAR(255),
  	o2therapy                     DOUBLE,
  	analgesic_specified           VARCHAR(255),
  	awake                         VARCHAR(11),
	pain_response                 VARCHAR(11),
	voice_response                VARCHAR(11),
	unresponsive                  VARCHAR(11),
	dexamethasone                 VARCHAR(11),
	remdesivir                    VARCHAR(11),
	lpv_r                         VARCHAR(11),
	ceftriaxone                   VARCHAR(11),
	amoxicillin                   VARCHAR(11),
	doxycycline                   VARCHAR(11),
	other_medication              TEXT,
	oxygen                        VARCHAR(11),
	ventilator                    VARCHAR(11),
	mask                          VARCHAR(11),
	mask_with_nonbreather         VARCHAR(11),
	nasal_cannula                 VARCHAR(11),
	cpap                          VARCHAR(11),
	bpap                          VARCHAR(11),
	fio2                          VARCHAR(11),
	ivf_fluid                     VARCHAR(11),
	hemoglobin                    DOUBLE,
	hematocrit                    DOUBLE,
	wbc                           DOUBLE,
	platelets                     DOUBLE,
	lymphocyte                    DOUBLE,
	neutrophil                    DOUBLE,
	crp                           DOUBLE,
	sodium                        DOUBLE,
	potassium                     DOUBLE,
	urea                          DOUBLE,
	creatinine                    DOUBLE,
	glucose                       DOUBLE,
	bilirubin                     DOUBLE,
	sgpt                          DOUBLE,
	sgot                          DOUBLE,
	pH                            DOUBLE,
	pcO2                          DOUBLE,
	pO2                           DOUBLE,
	tcO2                          DOUBLE,
	hcO3                          DOUBLE,
	be                            DOUBLE,
	sO2                           DOUBLE,
	lactate                       DOUBLE,
	x_ray                         VARCHAR(11),
	cardiac_ultrasound            VARCHAR(11),
	abdominal_ultrasound          VARCHAR(11),
	clinical_management_plan      TEXT,
	nursing_note                  TEXT,
	mh_referral                   VARCHAR(11),
	mh_note                       TEXT
);

-- insert into temp_covid_visit
INSERT INTO temp_covid_visit
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

UPDATE temp_covid_visit tc LEFT JOIN encounter_type et ON tc.encounter_type_id = et.encounter_type_id
SET encounter_type = et.name;

## Delet test patients
DELETE FROM temp_covid_visit
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

### COVID 19 admission
-- case condition
UPDATE temp_covid_visit SET case_condition = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '159640', 'en');
### COVID 19 Progress FORM
-- overall_condition
UPDATE temp_covid_visit SET overall_condition = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '159640', 'en');

-- Fever
UPDATE temp_covid_visit SET fever = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'FEVER');

-- cough
UPDATE temp_covid_visit SET cough = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'COUGH');

-- cough
UPDATE temp_covid_visit SET productive_cough = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'PRODUCTIVE COUGH');

-- shortness of breath
UPDATE temp_covid_visit SET shortness_of_breath = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '141600');

-- sore_throat
UPDATE temp_covid_visit SET sore_throat = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '158843');

-- rhinorrhea
UPDATE temp_covid_visit SET rhinorrhea = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '165501');

-- headache
UPDATE temp_covid_visit SET headache = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'HEADACHE');

-- chest pain
UPDATE temp_covid_visit SET chest_pain = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'CHEST PAIN');

-- muscle pain
UPDATE temp_covid_visit SET muscle_pain = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'MUSCLE PAIN');

-- fatigue
UPDATE temp_covid_visit SET fatigue = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'FATIGUE');

-- nausea and vomiting concept_id 3318 instead of 2530
UPDATE temp_covid_visit SET vomiting = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '133473');

-- diarrhea
UPDATE temp_covid_visit SET vomiting = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'DIARRHEA');

-- loss of taste
UPDATE temp_covid_visit SET loss_of_taste = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '135588');

-- loss of sense of smell
UPDATE temp_covid_visit SET sense_of_smell_loss = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '135589');

-- loss of sense of smell
UPDATE temp_covid_visit SET sense_of_smell_loss = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '135589');

-- confusion
UPDATE temp_covid_visit SET confusion = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'PIH', 'CONFUSION');

-- panic attack
UPDATE temp_covid_visit SET panic_attack  = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '130967');

-- suicidal thoughts
UPDATE temp_covid_visit SET suicidal_thoughts = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '125562');

-- attempted suicide
UPDATE temp_covid_visit SET attempted_suicide  = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1728', 'CIEL', '148143');

-- Symptom name, uncoded (text)
UPDATE temp_covid_visit SET other_symptom = OBS_VALUE_TEXT(encounter_id, 'CIEL', '165996');

-- vitals
UPDATE temp_covid_visit SET temp = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5088');

UPDATE temp_covid_visit SET heart_rate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5087');

UPDATE temp_covid_visit SET respiratory_rate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5242');

UPDATE temp_covid_visit SET bp_systolic = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5085');

UPDATE temp_covid_visit SET bp_diastolic = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5086');

UPDATE temp_covid_visit SET SpO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '5092');

-- room air
UPDATE temp_covid_visit SET room_air = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162739', 'CIEL', '162735');

-- Cap refill and Cap refill time
UPDATE temp_covid_visit SET cap_refill = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165890', 'en');

UPDATE temp_covid_visit SET cap_refill_time = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '162513');

-- Pain
UPDATE temp_covid_visit SET pain = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '166000', 'en');

########## Phyical Exams
UPDATE temp_covid_visit SET general_exam = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1119', 'en');
UPDATE temp_covid_visit SET general_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163042');

-- HEENT
UPDATE temp_covid_visit SET heent = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1122', 'en');
UPDATE temp_covid_visit SET heent_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163045');

-- Neck
UPDATE temp_covid_visit SET neck = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163388', 'en');
UPDATE temp_covid_visit SET neck_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '165983');

-- chest
UPDATE temp_covid_visit SET chest = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1123', 'en');
UPDATE temp_covid_visit SET chest_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160689');

-- cardiac
UPDATE temp_covid_visit SET cardiac = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1124', 'en');
UPDATE temp_covid_visit SET cardiac_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163046');

-- abdominal
UPDATE temp_covid_visit SET abdominal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1125', 'en');
UPDATE temp_covid_visit SET abdominal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160947');

-- urogenital
UPDATE temp_covid_visit SET urogenital = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1126', 'en');
UPDATE temp_covid_visit SET urogenital_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163047');

-- rectal
UPDATE temp_covid_visit SET rectal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '163746', 'en');
UPDATE temp_covid_visit SET rectal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160961');

-- musculoskeletal
UPDATE temp_covid_visit SET musculoskeletal = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1128', 'en');
UPDATE temp_covid_visit SET musculoskeletal_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163048');

-- lymph
UPDATE temp_covid_visit SET lymph = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1121', 'en');
UPDATE temp_covid_visit SET lymph_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '166005');

-- skin
UPDATE temp_covid_visit SET skin = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1120', 'en');
UPDATE temp_covid_visit SET skin_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '160981');

-- neuro
UPDATE temp_covid_visit SET neuro = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '1129', 'en');
UPDATE temp_covid_visit SET neuro_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163109');

-- avpu
UPDATE temp_covid_visit SET avpu = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '162643', 'en');

-- other
UPDATE temp_covid_visit SET other_findings = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163042');

-- Awake
UPDATE temp_covid_visit SET awake = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162643', 'CIEL', '160282');

-- Responds to pain
UPDATE temp_covid_visit SET pain_response = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162643', 'CIEL', '162644');

-- Responds to voice
UPDATE temp_covid_visit SET voice_response = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162643', 'CIEL', '162645');

-- Unresponsive
UPDATE temp_covid_visit SET unresponsive = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '162643', 'CIEL', '159508');

-- dexamethasone
UPDATE temp_covid_visit SET dexamethasone = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'Medication Orders', 'PIH', 'Dexamethasone');

-- lpv/r
UPDATE temp_covid_visit SET lpv_r = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'Medication Orders', 'CIEL', '794');

-- remdesivir
UPDATE temp_covid_visit SET remdesivir = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'Medication Orders', 'CIEL', '165878');

-- ceftriaxone
UPDATE temp_covid_visit SET ceftriaxone = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'Medication Orders', 'PIH', 'CEFTRIAXONE');

-- amoxicillin
UPDATE temp_covid_visit SET amoxicillin = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'Medication Orders', 'PIH', 'AMOXICILLIN');

-- doxycycline
UPDATE temp_covid_visit SET doxycycline = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', 'Medication Orders', 'PIH', 'DOXYCYCLINE');

-- other_medication
UPDATE temp_covid_visit SET other_medication = OBS_VALUE_TEXT(encounter_id, 'PIH', 'Medication comments (text)');

-- supportive care
UPDATE temp_covid_visit SET supportive_care = OBS_VALUE_CODED_LIST(encounter_id, 'CIEL', '165995', 'en');

-- o2therapy value
UPDATE temp_covid_visit SET o2therapy = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165986');

-- analgesic comments/description
UPDATE temp_covid_visit SET analgesic_specified = OBS_VALUE_TEXT(encounter_id, 'CIEL', '163206');

-- oxygen
UPDATE temp_covid_visit SET oxygen = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '81341');

-- ventilator
UPDATE temp_covid_visit SET ventilator = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '165998');

-- mask
UPDATE temp_covid_visit SET mask = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '165989');

-- mask with non breather
UPDATE temp_covid_visit SET mask_with_nonbreather = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '165990');

-- nasal cannula
UPDATE temp_covid_visit SET nasal_cannula = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '165893');

-- cpap
UPDATE temp_covid_visit SET cpap = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '165944');

-- bpap
UPDATE temp_covid_visit SET bpap = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '165988');

-- fio2
UPDATE temp_covid_visit SET fio2 = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '165927');

-- ivf fluid
UPDATE temp_covid_visit SET ivf_fluid = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '165995', 'CIEL', '161911');

##### Lab Results 
UPDATE temp_covid_visit SET hemoglobin = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '21');

UPDATE temp_covid_visit SET hematocrit = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1015');

UPDATE temp_covid_visit SET wbc = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '678');

UPDATE temp_covid_visit SET platelets = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '729');

UPDATE temp_covid_visit SET lymphocyte = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '952');

UPDATE temp_covid_visit SET neutrophil = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1330');

UPDATE temp_covid_visit SET crp = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '161500');

UPDATE temp_covid_visit SET sodium = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1132');

UPDATE temp_covid_visit SET potassium = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '1133');

UPDATE temp_covid_visit SET urea = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '857'); 

UPDATE temp_covid_visit SET creatinine = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '790');

UPDATE temp_covid_visit SET glucose = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '887');

UPDATE temp_covid_visit SET bilirubin = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '655');

UPDATE temp_covid_visit SET sgpt = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '654');

UPDATE temp_covid_visit SET sgot = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '653');

UPDATE temp_covid_visit SET pH = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165984');

UPDATE temp_covid_visit SET pcO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163595');

UPDATE temp_covid_visit SET pO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163598');

UPDATE temp_covid_visit SET tcO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '166002');

UPDATE temp_covid_visit SET hcO3 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163596');

UPDATE temp_covid_visit SET be = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163599');

UPDATE temp_covid_visit SET sO2 = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '163597');

UPDATE temp_covid_visit SET lactate = OBS_VALUE_NUMERIC(encounter_id, 'CIEL', '165997');

-- clinical management plan
UPDATE temp_covid_visit te SET clinical_management_plan = OBS_VALUE_TEXT(encounter_id, 'CIEL', '162749');

-- nursing note
UPDATE temp_covid_visit SET nursing_note = OBS_VALUE_TEXT(encounter_id, 'CIEL', '166021');

-- mh referral
UPDATE temp_covid_visit SET mh_referral = OBS_SINGLE_VALUE_CODED(encounter_id, 'CIEL', '1272', 'PIH', '5489');

-- mh note
UPDATE temp_covid_visit SET mh_note =  OBS_FROM_GROUP_ID_VALUE_TEXT(OBS_ID(encounter_id,'PIH','12837',0), 'CIEL', '161011');

-- Chest x-ray
UPDATE temp_covid_visit SET x_ray = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', '9485', 'PIH', 'Chest 1 view (XRay)');

-- Cardiac ultrasound
UPDATE temp_covid_visit SET cardiac_ultrasound = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', '9485', 'PIH', 'Transthoracic echocardiogram');

-- Abdominal ultrasound
UPDATE temp_covid_visit SET abdominal_ultrasound = OBS_SINGLE_VALUE_CODED(encounter_id, 'PIH', '9485', 'PIH', 'Abdomen (US)');

#### Final query
SELECT
        patient_id,
        encounter_id,
        encounter_date,
        location,
        encounter_type,
        case_condition,
	      overall_condition,
        IF(fever like "%Yes%", 1, NULL)	                fever,
        IF(cough like "%Yes%", 1, NULL)	                cough,
        IF(productive_cough	like "%Yes%", 1, NULL)      productive_cough,
        IF(shortness_of_breath like "%Yes%", 1, NULL)   shortness_of_breath,
        IF(sore_throat like "%Yes%", 1, NULL)           sore_throat,
        IF(rhinorrhea like "%Yes%", 1, NULL)            rhinorrhea,
        IF(headache like "%Yes%", 1, NULL)              headache,
        IF(chest_pain like "%Yes%", 1, NULL)            chest_pain,
        IF(muscle_pain like "%Yes%", 1, NULL)           muscle_pain,
        IF(fatigue like "%Yes%", 1, NULL)               fatigue,
        IF(vomiting like "%Yes%", 1, NULL)              vomiting,
        IF(diarrhea like "%Yes%", 1, NULL)              diarrhea,
        IF(loss_of_taste like "%Yes%", 1, NULL)         loss_of_taste,
        IF(sense_of_smell_loss like "%Yes%", 1, NULL)   sense_of_smell_loss,
        IF(confusion like "%Yes%", 1, NULL)             confusion,
        IF(panic_attack like "%Yes%", 1, NULL)          panic_attack,
        IF(suicidal_thoughts like "%Yes%", 1, NULL)     suicidal_thoughts,
        IF(attempted_suicide like "%Yes%", 1, NULL)     attempted_suicide,
        other_symptom,
        temp,
        heart_rate,
        respiratory_rate,
        bp_systolic,
        bp_diastolic,
        SpO2,
        IF(room_air like "%Yes%", 1, NULL)              room_air,
        cap_refill,
        cap_refill_time,
        pain,
        general_exam,
        general_findings,
        heent,
        heent_findings,
        neck,
        neck_findings,
        chest,
        chest_findings,
        cardiac,
        cardiac_findings,
        abdominal,
        abdominal_findings,
        urogenital,
        urogenital_findings,
        rectal,
        rectal_findings,
        musculoskeletal,
        musculoskeletal_findings,
        lymph,
        lymph_findings,
        skin,
        skin_findings,
        neuro,
        neuro_findings,
        avpu,
        IF(awake like "%Yes%", 1, NULL) awake,
        IF(pain_response like "%Yes%", 1, NULL)             pain_response,
        IF(voice_response like "%Yes%", 1, NULL)            voice_response,
        IF(unresponsive like "%Yes%", 1, NULL)              unresponsive,
        IF(other_findings like "%Yes%", 1, NULL)            other_findings,
        IF(dexamethasone like "%Yes%", 1, NULL)             dexamethasone,
        IF(remdesivir like "%Yes%", 1, NULL)                remdesivir,
        IF(lpv_r like "%Yes%", 1, NULL)                     lpv_r,
        IF(ceftriaxone like "%Yes%", 1, NULL)               ceftriaxone,
        IF(amoxicillin like "%Yes%", 1, NULL)               amoxicillin,
        IF(doxycycline like "%Yes%", 1, NULL)               doxycycline,
        other_medication,
        IF(oxygen like "%Yes%", 1, NULL)                    oxygen,
        IF(ventilator like "%Yes%", 1, NULL)                ventilator,
        IF(mask like "%Yes%", 1, NULL)                      mask,
        IF(mask_with_nonbreather like "%Yes%", 1, NULL)     mask_with_nonbreather,
        IF(nasal_cannula like "%Yes%", 1, NULL)             nasal_cannula,
        IF(cpap like "%Yes%", 1, NULL)                      cpap,
        IF(bpap like "%Yes%", 1, NULL)                      bpap,
        IF(fio2 like "%Yes%", 1, NULL)                      fio2,
        IF(ivf_fluid like "%Yes%", 1, NULL)                 ivf_fluid,
        hemoglobin,
        hematocrit,
        wbc,
        platelets,
        lymphocyte,
        neutrophil,
        crp,
        sodium,
        potassium,
        urea,
        creatinine,
        glucose,
        bilirubin,
        sgpt,
        sgot,
        pH,
        pcO2,
        pO2,
        tcO2,
        hcO3,
        be,
        sO2,
        lactate,
        IF(x_ray like "%Yes%", 1, NULL)                     x_ray,
        IF(cardiac_ultrasound like "%Yes%", 1, NULL)        cardiac_ultrasound,
        IF(abdominal_ultrasound like "%Yes%", 1, NULL)      abdominal_ultrasound,
        clinical_management_plan,
        nursing_note,
        IF(mh_referral like "%Yes%", 1, NULL)               mh_referral,
        mh_note
FROM temp_covid_visit order by patient_id;
