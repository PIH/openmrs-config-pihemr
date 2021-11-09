-- set @startDate='2021-11-01';
-- set @endDate='2021-12-21';

set @locale = global_property_value('default_locale', 'en');
select encounter_type_id into @obgyn from encounter_type where uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d';
select name into @vital_signs from encounter_type where uuid = '4fb47712-34a6-40d2-8ed3-e153abbd25b7';

drop temporary table if exists temp_obgyn;
create temporary table temp_obgyn
(
    patient_id int,
    emr_id varchar(50),
    location_registered varchar(255),
    age_at_encounter int,
    address varchar(1000),
    encounter_id int,
    visit_id int,
    encounter_datetime datetime,
    provider varchar(255),
    reason_for_visit varchar(1000),
    visit_type varchar(50),
    referring_service varchar(255),
    other_service varchar(255),
    triage_color varchar(50),
    systolic int(4),
    diastolic int(4),
    pulse int(4),
 	  respiratory_rate int(4),
		temperature int(4),
		oxygen_saturation int(4),
		presenting_history text,
    latest_vitals_encounter_id int,
    latest_vitals_datetime datetime,
    latest_vitals_height double,
    latest_vitals_weight double,
    latest_vitals_temperature double,
    latest_vitals_heart_rate int,
    latest_vitals_respiratory_rate int,
    latest_vitals_systolic int,
    latest_vitals_diastolic int,
    latest_vitals_oxygen_saturation int,
    latest_vitals_chief_complaint text,
    J9_mothers_group text,
    alcohol_use  varchar(50),
    tobacco_use varchar(50),
    illicit_drug_use varchar(50),
    illicit_drug_name text,
    traditional_healer varchar(50),
    prenatal_tea varchar(50),
    current_medications varchar(255),
    other_medication text,
    medical_history varchar(2000),
    specific_heart_disease text,
    specific_sti text,
    specific_surgery text,
    specific_trauma text,
    other_specific_history text,
    family_history_asthma varchar(50),
    family_history_heart_disease varchar(50),
    family_history_diabetes varchar(50),
    family_history_epilepsy varchar(50),
    family_history_hemoglobinopathy varchar(50),
    family_history_hypertension varchar(50),
    family_history_tuberculosis varchar(50),
    family_history_cancer varchar(50),
    family_history_cancer_specific varchar(255),
    family_history_other varchar(50),
    family_history_other_specific varchar(255),
    hiv_test varchar(50),
    on_ARV varchar(50),
    ARV_start_date date,
    regimen text,
    HIV_test_3_months varchar(255),
    viral_load_qualitative varchar(50),
    viral_load_quantitative int,
    TB_treatment_status varchar(50),
    TB_treatment_end_date datetime,
    currently_using_birth_control varchar(50),
    COC_FP_method varchar(50),
    COC_FP_Start_Date datetime,
    COC_FP_End_Date datetime,
    COP_FP_method varchar(50),
    COP_FP_Start_Date datetime,
    COP_FP_End_Date datetime,
    Depo_Provera_FP_method varchar(50),
    Depo_Provera_FP_Start_Date datetime,
    Depo_Provera_FP_End_Date datetime,
    Implant_FP_method varchar(50),
    Implant_FP_Start_Date datetime,
    Implant_FP_End_Date datetime,
    IUD_FP_method varchar(50),
    IUD_FP_Start_Date datetime,
    IUD_FP_End_Date datetime,
    Rhythm_FP_method varchar(50),
    Rhythm_FP_Start_Date datetime,
    Rhythm_FP_End_Date datetime,
    Exclusive_BF_FP_method varchar(50),
    Exclusive_BF_Start_Date datetime,
    Exclusive_BF_End_Date datetime,
    Condoms_FP_method varchar(50),
    Condoms_FP_Start_Date datetime,
    Condoms_FP_End_Date datetime,
    Tubal_Ligation_FP_method varchar(50),
    Tubal_Ligation_FP_Start_Date datetime,
    Tubal_Ligation_FP_End_Date datetime,
    received_FP_counseling varchar(50),
    current_family_planning_method varchar(255),
    current_FP_start_date datetime,
    current_FP_end_date datetime,
    date_implant_placement datetime,
    cervical_cancer_screening varchar(50),
    cervical_cancer_screening_date datetime,
    last_mentruation_date datetime,
    estimated_delivery_date datetime,
    enrollment_trimester varchar(255),
    mentrual_cycle_duration int,
    menses_duration int,
    gravida int,
    parity int,
    abortus int,
    living int,
    menarche_age int,
    number_sexual_partners int,
    age_first_sexual_intercourse int,
    pregnancy_1_birth_order int,
    pregnancy_1_delivery_type varchar(255),
    pregnancy_1_outcome varchar(255),
    pregnancy_2_birth_order int,
    pregnancy_2_delivery_type varchar(255),
    pregnancy_2_outcome varchar(255),
    pregnancy_3_birth_order int,
    pregnancy_3_delivery_type varchar(255),
    pregnancy_3_outcome varchar(255),
    pregnancy_4_birth_order int,
    pregnancy_4_delivery_type varchar(255),
    pregnancy_4_outcome varchar(255),
    pregnancy_5_birth_order int,
    pregnancy_5_delivery_type varchar(255),
    pregnancy_5_outcome varchar(255),
    pregnancy_6_birth_order int,
    pregnancy_6_delivery_type varchar(255),
    pregnancy_6_outcome varchar(255),
    pregnancy_7_birth_order int,
    pregnancy_7_delivery_type varchar(255),
    pregnancy_7_outcome varchar(255),
    pregnancy_8_birth_order int,
    pregnancy_8_delivery_type varchar(255),
    pregnancy_8_outcome varchar(255),
    pregnancy_9_birth_order int,
    pregnancy_9_delivery_type varchar(255),
    pregnancy_9_outcome varchar(255),
    pregnancy_10_birth_order int,
    pregnancy_10_delivery_type varchar(255),
    pregnancy_10_outcome varchar(255),
    number_postpartum_visits int,
    high_risk_factors varchar(1000),
    other_specific_high_risk_factor varchar(255),
    other_specific_danger_signs varchar(255),
    mental_health_dx_1 varchar(255),
    mental_health_dx_2 varchar(255),
    mental_health_dx_3 varchar(255),
    diagnosis_1 varchar(255),
    diagnosis_2 varchar(255),
    diagnosis_3 varchar(255),
    diagnosis_4 varchar(255),
    diagnosis_5 varchar(255),
    diagnosis_6 varchar(255),
    diagnosis_7 varchar(255),
    diagnosis_8 varchar(255),
    diagnosis_9 varchar(255),
    diagnosis_10 varchar(255)
);

-- load temporary table with all ob_gyn encounters within the date range
insert into temp_obgyn (
    patient_id,
    encounter_id,
    encounter_datetime,
    visit_id
)
select
    e.patient_id,
    e.encounter_id,
    e.encounter_datetime,
    e.visit_id
from
    encounter e
where e.encounter_type =@obgyn
      and date(e.encounter_datetime) >= date(@startDate)
      and date(e.encounter_datetime) <= date(@endDate)
;

create index temp_obgyn_patient on temp_obgyn(patient_id);
create index temp_obgyn_encounter_id on temp_obgyn(encounter_datetime);

-- demographics
update temp_obgyn set emr_id = zlemr(patient_id);
update temp_obgyn set location_registered = loc_registered(patient_id);
update temp_obgyn set age_at_encounter = age_at_enc(patient_id, encounter_id);
update temp_obgyn set address = person_address(patient_id);

update temp_obgyn set provider = provider(encounter_id);

-- type of consultation
update temp_obgyn t set reason_for_visit = obs_value_coded_list(t.encounter_id,'PIH','8879',@locale);
update temp_obgyn t set visit_type = obs_value_coded_list(t.encounter_id,'CIEL','164181',@locale);

-- referring services
update temp_obgyn t set referring_service = obs_value_coded_list(t.encounter_id,'PIH','7454',@locale);
update temp_obgyn t
  inner join obs o on o.encounter_id = t.encounter_id
  and o.concept_id =  concept_from_mapping('PIH','7454')
  and o.value_coded = concept_from_mapping('PIH','5622')
  and o.voided = 0
set t.other_service = o.comments
;

-- OB/GYN vital signs
update temp_obgyn t set triage_color = obs_value_coded_list(t.encounter_id,'PIH','10668',@locale);
update temp_obgyn t set systolic = obs_value_numeric(t.encounter_id,'PIH','5085');
update temp_obgyn t set diastolic = obs_value_numeric(t.encounter_id,'PIH','5086');
update temp_obgyn t set pulse = obs_value_numeric(t.encounter_id,'PIH','5087');
update temp_obgyn t set respiratory_rate = obs_value_numeric(t.encounter_id,'PIH','5242');
update temp_obgyn t set temperature = obs_value_numeric(t.encounter_id,'PIH','5088');
update temp_obgyn t set oxygen_saturation = obs_value_numeric(t.encounter_id,'PIH','5092');

-- latest vitals

update temp_obgyn t set latest_vitals_encounter_id = latestEncBetweenDates(t.patient_id, 'Signes vitaux',null, t.encounter_datetime);
update temp_obgyn t set latest_vitals_height = obs_value_numeric(t.latest_vitals_encounter_id, 'PIH','5090');
update temp_obgyn t set latest_vitals_weight = obs_value_numeric(t.latest_vitals_encounter_id, 'PIH','5089');
update temp_obgyn t set latest_vitals_temperature = obs_value_numeric(t.latest_vitals_encounter_id, 'PIH','5088');
update temp_obgyn t set latest_vitals_heart_rate = obs_value_numeric(t.latest_vitals_encounter_id, 'PIH','5087');
update temp_obgyn t set latest_vitals_respiratory_rate = obs_value_numeric(t.latest_vitals_encounter_id, 'PIH','5242');
update temp_obgyn t set latest_vitals_systolic = obs_value_numeric(t.latest_vitals_encounter_id, 'PIH','5089');
update temp_obgyn t set latest_vitals_diastolic = obs_value_numeric(t.latest_vitals_encounter_id, 'PIH','5085');
update temp_obgyn t set latest_vitals_oxygen_saturation = obs_value_numeric(t.latest_vitals_encounter_id, 'PIH','5086');
update temp_obgyn t set latest_vitals_chief_complaint = obs_value_text(t.latest_vitals_encounter_id, 'CIEL','160531');

-- chief complaint
update temp_obgyn t set presenting_history = obs_value_text(t.encounter_id,'PIH','974');

-- J9
update temp_obgyn t set J9_mothers_group = obs_value_text(t.encounter_id,'PIH','Mothers group (text)');

-- Behavior/Habits
update temp_obgyn t set alcohol_use = obs_value_coded_list(t.encounter_id,'PIH','1552',@locale);
update temp_obgyn t set tobacco_use = obs_value_coded_list(t.encounter_id,'PIH','2545',@locale);
update temp_obgyn t set illicit_drug_use = obs_value_coded_list(t.encounter_id,'PIH','2546',@locale);
update temp_obgyn t set illicit_drug_name = obs_value_text(t.encounter_id,'PIH','6489');
update temp_obgyn t set traditional_healer = obs_value_coded_list(t.encounter_id,'PIH','13242',@locale);
update temp_obgyn t set prenatal_tea = obs_value_coded_list(t.encounter_id,'PIH','13737',@locale);

-- Current Medications
update temp_obgyn t set current_medications = obs_value_coded_list(t.encounter_id,'CIEL','1193',@locale);
update temp_obgyn t set other_medication = obs_value_text(t.encounter_id,'PIH','CURRENT MEDICATIONS');

-- patient history
update temp_obgyn t set medical_history = obs_value_coded_list(t.encounter_id,'CIEL','1628',@locale);
update temp_obgyn t
  set specific_heart_disease = obs_from_group_id_value_text( obs_group_id_of_coded_answer(t.encounter_id,'PIH','3305') ,'CIEL','160221');
update temp_obgyn t
  set specific_sti = obs_from_group_id_value_text( obs_group_id_of_coded_answer(t.encounter_id,'PIH','174') ,'CIEL','160221');
update temp_obgyn t
  set specific_surgery = obs_from_group_id_value_text( obs_group_id_of_coded_answer(t.encounter_id,'PIH','6298') ,'CIEL','160221');
update temp_obgyn t
  set specific_trauma = obs_from_group_id_value_text( obs_group_id_of_coded_answer(t.encounter_id,'PIH','7532'), 'CIEL','160221');
update temp_obgyn t
  inner join obs other_group on other_group.voided = 0 and other_group.encounter_id = t.encounter_id
    and other_group.concept_id = concept_from_mapping('CIEL','1628')
    and other_group.value_coded = concept_from_mapping('PIH', '5622')
  inner join obs o on o.voided = 0 and o.obs_group_id = other_group.obs_group_id
    and o.concept_id = concept_from_mapping('CIEL','160221')
set other_specific_history = o.value_text;

-- family history
update temp_obgyn t
set family_history_asthma =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale))
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
    and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('PIH', '5')
   group by fh_group.encounter_id)
 ;

update temp_obgyn t
set family_history_heart_disease =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale))
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
     and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('PIH', '3305')
   group by fh_group.encounter_id)
 ;

update temp_obgyn t
set family_history_diabetes =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale))
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
    and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('PIH', '3720')
   group by fh_group.encounter_id)
 ;

update temp_obgyn t
set family_history_epilepsy =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale))
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
    and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('PIH', '155')
   group by fh_group.encounter_id)
 ;

update temp_obgyn t
set family_history_hemoglobinopathy =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale))
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
    and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('CIEL', '117635')
   group by fh_group.encounter_id)
 ;

update temp_obgyn t
set family_history_hypertension =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale))
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
    and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('PIH', '903')
   group by fh_group.encounter_id)
 ;

update temp_obgyn t
set family_history_tuberculosis =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale),'|')
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
    and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('PIH', '58')
   group by fh_group.encounter_id)
 ;

update temp_obgyn t
set family_history_cancer =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale))
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
    and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('CIEL', '116030')
   group by fh_group.encounter_id)
 ;

update temp_obgyn t
set family_history_other =
(select group_concat( obs_from_group_id_value_coded_list(fh_group.obs_group_id,'PIH','2172',@locale))
from obs fh_group where fh_group.voided = 0 and fh_group.encounter_id = t.encounter_id
    and fh_group.concept_id = concept_from_mapping('CIEL','160592')
    and fh_group.value_coded = concept_from_mapping('PIH', '6408')
   group by fh_group.encounter_id)
 ;

 -- HIV/TB Section
update temp_obgyn t set hiv_test = obs_value_coded_list(t.encounter_id,'PIH','HIV test done',@locale);
update temp_obgyn t set on_ARV = obs_value_coded_list(t.encounter_id,'CIEL','160119',@locale);
update temp_obgyn t set ARV_start_date = obs_value_datetime(t.encounter_id,'PIH','2516');
update temp_obgyn t set regimen = obs_value_text(t.encounter_id,'CIEL','166086');
update temp_obgyn t set HIV_test_3_months = obs_value_coded_list(t.encounter_id,'PIH','13256',@locale);
update temp_obgyn t set viral_load_qualitative = obs_value_coded_list(t.encounter_id,'CIEL','1305',@locale);
update temp_obgyn t set viral_load_quantitative = obs_value_numeric(t.encounter_id,'PIH','856');
update temp_obgyn t set TB_treatment_status = obs_value_coded_list(t.encounter_id,'CIEL','5965',@locale);
update temp_obgyn t set TB_treatment_end_date = obs_value_datetime(t.encounter_id,'PIH','2597');

-- Family Planning History

update temp_obgyn t set COC_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','159783');
update temp_obgyn t set COC_FP_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','159783'),'CIEL','163757');
update temp_obgyn t set COC_FP_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','159783'),'CIEL','163758');

update temp_obgyn t set COP_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','80784');
update temp_obgyn t set COP_FP_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','80784'),'CIEL','163757');
update temp_obgyn t set COP_FP_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','80784'),'CIEL','163758');

update temp_obgyn t set Depo_Provera_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','907');
update temp_obgyn t set Depo_Provera_FP_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','907'),'CIEL','163757');
update temp_obgyn t set Depo_Provera_FP_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','907'),'CIEL','163758');

update temp_obgyn t set Implant_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','1873');
update temp_obgyn t set Implant_FP_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','1873'),'CIEL','163757');
update temp_obgyn t set Implant_FP_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','1873'),'CIEL','163758');

update temp_obgyn t set IUD_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','5275');
update temp_obgyn t set IUD_FP_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','5275'),'CIEL','163757');
update temp_obgyn t set IUD_FP_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','5275'),'CIEL','163758');

update temp_obgyn t set Rhythm_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','5277');
update temp_obgyn t set Rhythm_FP_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','5277'),'CIEL','163757');
update temp_obgyn t set Rhythm_FP_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','5277'),'CIEL','163758');

update temp_obgyn t set Exclusive_BF_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','136163');
update temp_obgyn t set Exclusive_BF_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','136163'),'CIEL','163757');
update temp_obgyn t set Exclusive_BF_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','136163'),'CIEL','163758');

update temp_obgyn t set Condoms_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','190');
update temp_obgyn t set Condoms_FP_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','190'),'CIEL','163757');
update temp_obgyn t set Condoms_FP_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','190'),'CIEL','163758');

update temp_obgyn t set Tubal_Ligation_FP_method = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','1472');
update temp_obgyn t set Tubal_Ligation_FP_Start_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','1472'),'CIEL','163757');
update temp_obgyn t set Tubal_Ligation_FP_End_Date = obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING', 'CIEL','1472'),'CIEL','163758');

-- Family Planning

update temp_obgyn t set currently_using_birth_control = obs_value_coded_list(t.encounter_id,'CIEL','965',@locale);
update temp_obgyn t set received_FP_counseling =obs_single_value_coded(t.encounter_id,'CIEL','163560','CIEL','1382');

update temp_obgyn t set current_family_planning_method =obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', 'Family planning construct', 0),'PIH','374',@locale);
update temp_obgyn t set current_FP_start_date =obs_from_group_id_value_datetime(obs_id(encounter_id, 'PIH', 'Family planning construct', 0),'CIEL','163757');
update temp_obgyn t set current_FP_end_date =obs_from_group_id_value_datetime(obs_id(encounter_id, 'PIH', 'Family planning construct', 0),'CIEL','163758');

update temp_obgyn t set date_implant_placement =obs_value_datetime(t.encounter_id,'PIH','3203');

-- cervical cancer screening

update temp_obgyn t set cervical_cancer_screening = obs_single_value_coded(t.encounter_id,'CIEL','163560','CIEL','151185');
update temp_obgyn t set cervical_cancer_screening_date = obs_value_datetime(t.encounter_id,'CIEL','165429');

-- OB/GYN
update temp_obgyn t set last_mentruation_date =obs_value_datetime(t.encounter_id,'PIH','968');
update temp_obgyn t set estimated_delivery_date =obs_value_datetime(t.encounter_id,'PIH','5596');
update temp_obgyn t set enrollment_trimester =obs_value_coded_list(t.encounter_id,'PIH','11661',@locale);
update temp_obgyn t set mentrual_cycle_duration =obs_value_numeric(t.encounter_id,'CIEL','160597');
update temp_obgyn t set menses_duration =obs_value_numeric(t.encounter_id,'CIEL','163732');
update temp_obgyn t set gravida =obs_value_numeric(t.encounter_id,'PIH','5624');
update temp_obgyn t set parity =obs_value_numeric(t.encounter_id,'PIH','1053');
update temp_obgyn t set abortus =obs_value_numeric(t.encounter_id,'PIH','7012');
update temp_obgyn t set living =obs_value_numeric(t.encounter_id,'CIEL','1825');
update temp_obgyn t set menarche_age =obs_value_numeric(t.encounter_id,'CIEL','160598');
update temp_obgyn t set number_sexual_partners =obs_value_numeric(t.encounter_id,'PIH','5570');
update temp_obgyn t set age_first_sexual_intercourse =obs_value_numeric(t.encounter_id,'CIEL','163587');

-- Birth History

update temp_obgyn t set pregnancy_1_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',0),'CIEL','163460');
update temp_obgyn t set pregnancy_1_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',0),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_1_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',0),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_2_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',1),'CIEL','163460');
update temp_obgyn t set pregnancy_2_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',1),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_2_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',1),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_3_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',2),'CIEL','163460');
update temp_obgyn t set pregnancy_3_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',2),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_3_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',2),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_4_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',3),'CIEL','163460');
update temp_obgyn t set pregnancy_4_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',3),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_4_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',3),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_5_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',4),'CIEL','163460');
update temp_obgyn t set pregnancy_5_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',4),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_5_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',4),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_6_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',5),'CIEL','163460');
update temp_obgyn t set pregnancy_6_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',5),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_6_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',5),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_7_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',6),'CIEL','163460');
update temp_obgyn t set pregnancy_7_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',6),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_7_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',6),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_8_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',7),'CIEL','163460');
update temp_obgyn t set pregnancy_8_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',7),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_8_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',7),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_9_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',8),'CIEL','163460');
update temp_obgyn t set pregnancy_9_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',8),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_9_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',8),'CIEL','161033',@locale);
update temp_obgyn t set pregnancy_10_birth_order =obs_from_group_id_value_numeric(obs_id(t.encounter_id,'CIEL','163588',9),'CIEL','163460');
update temp_obgyn t set pregnancy_10_delivery_type =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',9),'PIH','11663',@locale);
update temp_obgyn t set pregnancy_10_outcome =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'CIEL','163588',9),'CIEL','161033',@locale);

-- postpartum
update temp_obgyn t set number_postpartum_visits = obs_value_numeric(t.encounter_id,'CIEL','159893');

-- high risk factors
update temp_obgyn t set high_risk_factors = obs_value_coded_list(t.encounter_id,'CIEL','160079',@locale);
update temp_obgyn t set other_specific_high_risk_factor = obs_comments(t.encounter_id,'CIEL','160079','CIEL','5622');

-- danger signs
update temp_obgyn t set other_specific_danger_signs = obs_comments(t.encounter_id,'CIEL','1880','CIEL','1065');

-- Mental Health Assessment
update temp_obgyn t
  inner join obs o on o.obs_id = obs_id(t.encounter_id, 'PIH','Mental health diagnosis',0)
set mental_health_dx_1= concept_name(o.value_coded,@locale);

update temp_obgyn t
  inner join obs o on o.obs_id = obs_id(t.encounter_id, 'PIH','Mental health diagnosis',1)
set mental_health_dx_2= concept_name(o.value_coded,@locale);

update temp_obgyn t
  inner join obs o on o.obs_id = obs_id(t.encounter_id, 'PIH','Mental health diagnosis',2)
set mental_health_dx_3= concept_name(o.value_coded,@locale);

-- Diagnoses
update temp_obgyn t set diagnosis_1 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',0),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_2 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',1),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_3 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',2),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_4 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',3),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_5 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',4),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_6 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',5),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_7 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',6),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_8 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',7),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_9 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',8),'PIH','3064',@locale);
update temp_obgyn t set diagnosis_10 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',9),'PIH','3064',@locale);

Select
patient_id,
emr_id,
location_registered,
age_at_encounter,
address,
encounter_id,
visit_id,
encounter_datetime,
reason_for_visit,
provider,
visit_type,
referring_service,
other_service,
triage_color,
systolic,
diastolic,
pulse,
respiratory_rate,
temperature,
oxygen_saturation,
presenting_history,
latest_vitals_encounter_id,
latest_vitals_datetime,
latest_vitals_height,
latest_vitals_weight,
latest_vitals_temperature,
latest_vitals_heart_rate,
latest_vitals_respiratory_rate,
latest_vitals_systolic,
latest_vitals_diastolic,
latest_vitals_oxygen_saturation,
latest_vitals_chief_complaint,
J9_mothers_group,
alcohol_use,
tobacco_use,
illicit_drug_use,
illicit_drug_name,
traditional_healer,
prenatal_tea,
current_medications,
other_medication,
medical_history,
specific_heart_disease,
specific_sti,
specific_surgery,
specific_trauma,
other_specific_history,
family_history_asthma,
family_history_heart_disease,
family_history_diabetes,
family_history_epilepsy,
family_history_hemoglobinopathy,
family_history_hypertension,
family_history_tuberculosis,
family_history_cancer,
family_history_cancer_specific,
family_history_other,
family_history_other_specific,
HIV_test,
on_ARV,
ARV_start_date,
regimen,
HIV_test_3_months,
viral_load_qualitative,
viral_load_quantitative,
TB_treatment_status,
TB_treatment_end_date,
COC_FP_method,
COC_FP_Start_Date,
COC_FP_End_Date,
COP_FP_method,
COP_FP_Start_Date,
COP_FP_End_Date,
Depo_Provera_FP_method,
Depo_Provera_FP_Start_Date,
Depo_Provera_FP_End_Date,
Implant_FP_method,
Implant_FP_Start_Date,
Implant_FP_End_Date,
IUD_FP_method,
IUD_FP_Start_Date,
IUD_FP_End_Date,
Rhythm_FP_method,
Rhythm_FP_Start_Date,
Rhythm_FP_End_Date,
Exclusive_BF_FP_method,
Exclusive_BF_Start_Date,
Exclusive_BF_End_Date,
Condoms_FP_method,
Condoms_FP_Start_Date,
Condoms_FP_End_Date,
Tubal_Ligation_FP_method,
Tubal_Ligation_FP_Start_Date,
Tubal_Ligation_FP_End_Date,
currently_using_birth_control,
received_FP_counseling,
current_family_planning_method,
current_FP_start_date,
current_FP_end_date,
date_implant_placement,
last_mentruation_date,
estimated_delivery_date,
enrollment_trimester,
mentrual_cycle_duration,
menses_duration,
gravida,
parity,
abortus,
living,
menarche_age,
number_sexual_partners,
age_first_sexual_intercourse,
pregnancy_1_birth_order,
pregnancy_1_delivery_type,
pregnancy_1_outcome,
pregnancy_2_birth_order,
pregnancy_2_delivery_type,
pregnancy_2_outcome,
pregnancy_3_birth_order,
pregnancy_3_delivery_type,
pregnancy_3_outcome,
pregnancy_4_birth_order,
pregnancy_4_delivery_type,
pregnancy_4_outcome,
pregnancy_5_birth_order,
pregnancy_5_delivery_type,
pregnancy_5_outcome,
pregnancy_6_birth_order,
pregnancy_6_delivery_type,
pregnancy_6_outcome,
pregnancy_7_birth_order,
pregnancy_7_delivery_type,
pregnancy_7_outcome,
pregnancy_8_birth_order,
pregnancy_8_delivery_type,
pregnancy_8_outcome,
pregnancy_9_birth_order,
pregnancy_9_delivery_type,
pregnancy_9_outcome,
pregnancy_10_birth_order,
pregnancy_10_delivery_type,
pregnancy_10_outcome,
cervical_cancer_screening,
cervical_cancer_screening_date,
number_postpartum_visits,
other_specific_danger_signs,
high_risk_factors,
other_specific_high_risk_factor,
mental_health_dx_1,
mental_health_dx_2,
mental_health_dx_3,
diagnosis_1,
diagnosis_2,
diagnosis_3,
diagnosis_4,
diagnosis_5,
diagnosis_6,
diagnosis_7,
diagnosis_8,
diagnosis_9,
diagnosis_10
from temp_obgyn;
