-- set @startDate = '2020-06-28';
-- set @endDate = '2021-06-29';

SET @locale = ifnull(@locale, GLOBAL_PROPERTY_VALUE('default_locale', 'en'));

select encounter_type_id into @echo_note from encounter_type where uuid = 'fdee591e-78ba-11e9-8f9e-2a86e4085a59'; 

DROP TEMPORARY TABLE IF EXISTS temp_echo;
CREATE TEMPORARY TABLE temp_echo
(
    patient_id                      int(11),
    dossierId                       varchar(50),
    emrid                           varchar(50),
    loc_registered                  varchar(255),
    encounter_datetime              datetime,
    encounter_location              varchar(255),
    provider                        varchar(255),
    encounter_id                    int(11),
    systolic_bp						double,
    diastolic_bp					double,
    heart_rate						double,
    murmur							varchar(255),
    NYHA_class						varchar(255),
    left_ventricle_systolic_function varchar(255),
    right_ventricle_dimension		varchar(255),
    mitral_valve					varchar(255),
    pericardium						varchar(255),	
    inferior_vena_cava				varchar(255),
    left_ventricle_dimension		varchar(255),	
    pulmonary_artery_systolic_pressure	double,
    disease_category				varchar(255),
    disease_category_other_comment	varchar(255),
    peripartum_cardiomyopathy_diagnosis varchar(255),
    ischemic_cardiomyopathy_diagnosis varchar(255),
    study_results_changed_treatment_plan varchar(255),
    general_comments				varchar(255)
    );

-- insert encounters into temp table
insert into temp_echo (
  patient_id,
  encounter_id,
  encounter_datetime)
select
  patient_id,
  encounter_id,
  encounter_datetime
from encounter e
where e.encounter_type in (@echo_note)
AND ((date(e.encounter_datetime) >=@startDate) or @startDate is null)
AND ((date(e.encounter_datetime) <=@endDate)  or @endDate is null)
and voided = 0
;
-- encounter and demo info
update temp_echo set emrid = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_echo set dossierid = dosid(patient_id);
update temp_echo set loc_registered = loc_registered(patient_id);
update temp_echo set encounter_location = encounter_location_name(encounter_id);
update temp_echo set provider = provider(encounter_id);

-- vital signs
update temp_echo set systolic_bp = obs_value_numeric(encounter_id, 'PIH','5085');
update temp_echo set diastolic_bp = obs_value_numeric(encounter_id, 'PIH','5086');
update temp_echo set heart_rate = obs_value_numeric(encounter_id, 'PIH','5087');
update temp_echo set murmur = obs_value_coded_list(encounter_id, 'PIH','562',@locale);
update temp_echo set NYHA_class = obs_value_coded_list(encounter_id, 'PIH','3139',@locale);

-- Echocardiogram Consultation
update temp_echo set left_ventricle_systolic_function = obs_value_coded_list(encounter_id, 'PIH','11994',@locale);
update temp_echo set right_ventricle_dimension = obs_value_coded_list(encounter_id, 'PIH','11997',@locale);
update temp_echo set mitral_valve = obs_value_coded_list(encounter_id, 'PIH','11998',@locale);
update temp_echo set pericardium = obs_value_coded_list(encounter_id, 'PIH','3993',@locale);
update temp_echo set inferior_vena_cava = obs_value_coded_list(encounter_id, 'PIH','11999',@locale);
update temp_echo set left_ventricle_dimension = obs_value_coded_list(encounter_id, 'PIH','13595',@locale);
update temp_echo set pulmonary_artery_systolic_pressure = obs_value_numeric(encounter_id, 'PIH','3991');

-- diagnosis
update temp_echo set disease_category = obs_value_coded_list(encounter_id, 'PIH','10529',@locale);
update temp_echo set disease_category_other_comment = obs_value_text(encounter_id, 'PIH','11973');
update temp_echo set peripartum_cardiomyopathy_diagnosis = obs_single_value_coded(encounter_id, 'PIH','3064','PIH','3129');
update temp_echo set ischemic_cardiomyopathy_diagnosis = obs_single_value_coded(encounter_id, 'PIH','3064','CIEL','139529');

-- Other
update temp_echo set study_results_changed_treatment_plan = obs_value_coded_list(encounter_id, 'PIH','13594',@locale);
update temp_echo set general_comments = obs_value_text(encounter_id, 'PIH','3407');

-- select final output
select * from temp_echo;
