-- set @startDate = '2021-03-08';
-- set @endDate = '2021-03-12';

CALL initialize_global_metadata();
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');

DROP TEMPORARY TABLE IF EXISTS temp_history;
CREATE TEMPORARY TABLE temp_history
(
    patient_id            int(11),
    dossierId             varchar(50),
    zlemrid               varchar(50),
    loc_registered        varchar(255),
    encounter_id int(11),
    encounter_datetime    datetime,
    encounter_location    varchar(255), 
    encounter_type        varchar(255), 
    internal_refer_values varchar(1000),
    other_internal_institution varchar(255),
    external_institution_PIH  varchar(255),
    external_institution_nonPIH  varchar(255),
    community  varchar(1000),
    date_of_referral datetime,
    provider  varchar(255),
    Presenting_History  varchar(1000),
    Family_Asthma  varchar(50),
    Family_Heart_Disease  varchar(50),
    Family_Diabetes  varchar(50),
    Family_Epilepsy  varchar(50),
    Family_Hemoglobinopathy  varchar(50),
    Family_Hypertension  varchar(50),
    Family_Tuberculosis  varchar(50),
    Family_Cancer  varchar(50),
    Family_Cancer_comment  varchar(255),
    Family_Other  varchar(50),
    Family_Other_comment  varchar(255),
    Patient_asthma  varchar(3),
    Patient_heart_disease  varchar(3),
    Patient_heart_disease_comment varchar(255),
    Patient_surgery  varchar(3),
    Patient_surgery_comment  varchar(255),
    Patient_trauma  varchar(3),
    Patient_trauma_comment  varchar(255),
    Patient_epilepsy  varchar(3),
    Patient_Hemoglobinopathy  varchar(3),
    Patient_Hemoglobinopathy_comment  varchar(255),
    Patient_hypertension  varchar(3),
    Patient_diabetes  varchar(3),
    Patient_hiv  varchar(3),
    Patient_sti  varchar(3),
    Patient_sti_comment  varchar(255),
    Patient_congenital_malformation  varchar(3),
    Patient_con_malform_comment  varchar(255),
    Patient_malnutrition  varchar(3),
    Patient_measles  varchar(3),
    Patient_tuberculosis  varchar(3),
    Patient_varicella  varchar(3),
    Patient_diptheria  varchar(3),
    Patient_arf varchar(3),
    Patient_sickle_cell_anemia varchar(3),
    Patient_other  varchar(3),
    Patient_other_comment  varchar(255),
    premature_birth varchar(3),
    term_birth varchar(3),
    post_term_pregnancy varchar(3),
    delivery_location varchar(255),
    birth_weight double,
    maternal_disease varchar(255),
    maternal_disease_comment varchar(255),
    neonatal_disease varchar(255),
    neonatal_disease_comment varchar(255),
    Patient_blood_type  varchar(255),
    smoker  varchar(255),
    packs_per_year int(11),
    second_hand_smoker  varchar(255),
    alcohol_use  varchar(255), 
    illegal_drugs  varchar(255),
    current_drug_name  varchar(1000),
    pregnant  varchar(255),
    last_menstruation_date  varchar(255),
    estimated_delivery_date  varchar(255),
    currently_breast_feeding  varchar(255),
    oral_contraception  varchar(255),
    oral_contraception_start_date datetime,
    oral_contraception_end_date datetime,
    depoprovera  varchar(255),
    depoprovera_start_date datetime,
    depoprovera_end_date datetime,
    condom varchar(255),
    condom_start_date datetime,
    condom_end_date datetime,
    levonorgestrel  varchar(255),
    levonorgestrel_start_date datetime,
    levonorgestrel_end_date datetime,
    intrauterine_device  varchar(255),
    intrauterine_device_start_date datetime,
    intrauterine_device_end_date datetime,
    tubal_ligation  varchar(255),
    tubal_ligation_start_date datetime,
    tubal_ligation_end_date datetime,
    vasectomy  varchar(255),
    vasectomy_start_date datetime,
    vasectomy_end_date datetime,
    family_plan_other  varchar(255),
    family_plan_other_name  varchar(255),
    family_plan_other_start_date datetime,
    family_plan_other_end_date datetime,
    hospital1 varchar(255),
    admission_date1 datetime,
    discharge_date1 datetime,
    reason_for_hospitalization1 varchar(255),
    hospital2 varchar(255),
    admission_date2 datetime,
    discharge_date2 datetime,
    reason_for_hospitalization2 varchar(255),
    hospital3 varchar(255),
    admission_date3 datetime,
    discharge_date3 datetime,
    reason_for_hospitalization3 varchar(255),
    hospitalization_comments varchar(255),
    current_meds varchar(255),
    diagnostic_tests_history varchar(255)
);


insert into temp_history (
  patient_id,
  encounter_id,
  encounter_datetime,
  encounter_type)
select
  patient_id,
  encounter_id,
  encounter_datetime,
  et.name
from encounter e
inner join encounter_type et on et.encounter_type_id = e.encounter_type
where e.encounter_type in (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc, @NCDInitEnc)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
and voided = 0
;

update temp_history set zlemrid = zlemr(patient_id);
update temp_history set dossierid = dosid(patient_id);
update temp_history set loc_registered = loc_registered(patient_id);
update temp_history set encounter_location = encounter_location_name(encounter_id);
update temp_history set provider = provider(encounter_id);

-- HPI
update temp_history set presenting_history = obs_value_text(encounter_id, 'PIH','PRESENTING HISTORY');

-- referral section
update temp_history t
inner join 
  (select encounter_id, group_concat(concept_name(o.value_coded,@locale)) irs from obs o
  where o.voided = 0 and o.concept_id = concept_from_mapping('PIH','Type of referring service')
  and o.value_coded in 
    (concept_from_mapping('CIEL','165018'),
    concept_from_mapping('PIH','ANTENATAL CLINIC'),
    concept_from_mapping('PIH','PRIMARY CARE CLINIC' ),
    concept_from_mapping('CIEL','163558'),
    concept_from_mapping('CIEL','160449'),
    concept_from_mapping('CIEL','160448'),
    concept_from_mapping('CIEL','165048'),
    concept_from_mapping('CIEL','160473'),
    concept_from_mapping('PIH','11956'),
    concept_from_mapping('PIH','8856'),
    concept_from_mapping('PIH','VILLAGE HEALTH WORKER'),
    concept_from_mapping('PIH','Community meeting'),
    concept_from_mapping('PIH','OTHER'))
    group by encounter_id) ot on ot.encounter_id = t.encounter_id
set internal_refer_values = ot.irs;    
update temp_history set other_internal_institution = obs_comments(encounter_id,'PIH','Type of referring service','PIH','OTHER');  
update temp_history set external_institution_PIH = obs_comments(encounter_id,'PIH','Type of referring service','PIH','11956');  
update temp_history set external_institution_nonPIH = obs_comments(encounter_id,'PIH','Type of referring service','PIH','8856');  
update temp_history set date_of_referral = obs_value_datetime(encounter_id, 'CIEL','163181');

-- Family History
update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('PIH','ASTHMA')
set Family_Asthma = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale);

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('PIH','HEART DISEASE')
set Family_Heart_Disease = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale);

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('PIH','DIABETES')
set Family_Diabetes = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale);

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('PIH','EPILEPSY')
set Family_Epilepsy = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale);

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('CIEL','117635')
set Family_Hemoglobinopathy = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale);

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('PIH','HYPERTENSION')
set Family_Hypertension = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale);

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('PIH','TUBERCULOSIS')
set Family_Tuberculosis = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale);

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('CIEL','116031')
set Family_Cancer = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale),
    Family_Cancer_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160618') ;

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','160592')
  and o.value_coded = concept_from_mapping('PIH','OTHER')
set Family_Other = obs_from_group_id_value_coded_list(o.obs_group_id,'PIH','RELATIONSHIP OF RELATIVE TO PATIENT',@locale),
    Family_Other_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160618') ;

-- patient history section

update temp_history t set Patient_asthma = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','ASTHMA');
update temp_history t set Patient_heart_disease = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','HEART DISEASE');
update temp_history t set Patient_surgery = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','SURGERY');
update temp_history t set Patient_trauma = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','Traumatic Injury');
update temp_history t set Patient_epilepsy = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','EPILEPSY');
update temp_history t set Patient_Hemoglobinopathy = obs_single_value_coded(encounter_id, 'CIEL','1628','CIEL','117635');
update temp_history t set Patient_hypertension = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','HYPERTENSION');
update temp_history t set Patient_diabetes = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','DIABETES');
update temp_history t set Patient_hiv = obs_single_value_coded(encounter_id, 'CIEL','1628','CIEL','138405');
update temp_history t set Patient_sti = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','SEXUALLY TRANSMITTED INFECTION');
update temp_history t set Patient_congenital_malformation = obs_single_value_coded(encounter_id, 'CIEL','1628','CIEL','143849');
update temp_history t set Patient_malnutrition = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','MALNUTRITION');
update temp_history t set Patient_measles = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','MEASLES');
update temp_history t set Patient_tuberculosis = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','TUBERCULOSIS');
update temp_history t set Patient_varicella = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','VARICELLA');
update temp_history t set Patient_diptheria = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','Diphtheria');
update temp_history t set Patient_arf = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','ACUTE RHEUMATIC FEVER');
update temp_history t set Patient_sickle_cell_anemia  = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','Sickle-Cell Anemia');
update temp_history t set Patient_other = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','OTHER');


update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('PIH','HEART DISEASE')
set Patient_heart_disease_comment  = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('PIH','SURGERY')
set Patient_surgery_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('PIH','Traumatic Injury')
set Patient_trauma_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('CIEL','117635')
set Patient_Hemoglobinopathy_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('PIH','SEXUALLY TRANSMITTED INFECTION')
set Patient_sti_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('CIEL','143849')
set Patient_con_malform_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('PIH','OTHER')
set Patient_other_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

-- birth history section
update temp_history t set term_birth = obs_single_value_coded(encounter_id, 'CIEL','1628','CIEL','1395');
update temp_history t set premature_birth = obs_single_value_coded(encounter_id, 'CIEL','1628','PIH','Premature birth of patien');
update temp_history t set post_term_pregnancy = obs_single_value_coded(encounter_id, 'CIEL','1628','CIEL','113600');

update temp_history t set delivery_location = obs_value_coded_list(encounter_id, 'CIEL','163774',@locale);
update temp_history t set birth_weight = obs_value_numeric(encounter_id, 'CIEL','5916');

update temp_history t set maternal_disease = obs_single_value_coded(encounter_id, 'CIEL','1628','CIEL','118203');
update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('CIEL','118203')
set maternal_disease_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

update temp_history t set neonatal_disease = obs_single_value_coded(encounter_id, 'CIEL','1628','CIEL','115374');
update temp_history t
inner join obs o on o.voided = 0 and o.encounter_id = t.encounter_id 
  and o.concept_id = concept_from_mapping('CIEL','1628')
  and o.value_coded = concept_from_mapping('CIEL','115374')
set neonatal_disease_comment = obs_from_group_id_value_text(o.obs_group_id, 'CIEL','160221') ;

-- blood type section
update temp_history t set Patient_blood_type = obs_value_coded_list(encounter_id, 'PIH','BLOOD TYPING',@locale);

-- behavior/habits section
update temp_history t set smoker = obs_value_coded_list(encounter_id, 'PIH','HISTORY OF TOBACCO USE',@locale);
update temp_history t set packs_per_year = obs_value_numeric(encounter_id, 'PIH','11949');
update temp_history t set second_hand_smoker = obs_value_coded_list(encounter_id, 'CIEL','152721',@locale);
update temp_history t set alcohol_use = obs_value_coded_list(encounter_id, 'PIH','HISTORY OF ALCOHOL USE',@locale);
update temp_history t set illegal_drugs = obs_value_coded_list(encounter_id, 'PIH','HISTORY OF ILLEGAL DRUGS',@locale);
update temp_history t set current_drug_name = obs_value_text(encounter_id, 'PIH','6489');

-- sexual and reproductive history section
update temp_history t set pregnant = obs_value_coded_list(encounter_id, 'PIH','PREGNANCY STATUS',@locale);
update temp_history t set last_menstruation_date = obs_value_datetime(encounter_id, 'PIH','DATE OF LAST MENSTRUAL PERIOD');
update temp_history t set estimated_delivery_date = obs_value_datetime(encounter_id, 'PIH','ESTIMATED DATE OF CONFINEMENT');
update temp_history t set currently_breast_feeding = obs_value_coded_list(encounter_id, 'PIH','CURRENTLY BREASTFEEDING CHILD',@locale);


update temp_history t set oral_contraception = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING','PIH','ORAL CONTRACEPTION');
update temp_history t set oral_contraception_start_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','ORAL CONTRACEPTION'),
  'CIEL','163757');
update temp_history t set oral_contraception_end_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','ORAL CONTRACEPTION'),
  'CIEL','163758');

update temp_history t set depoprovera = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING','PIH','MEDROXYPROGESTERONE ACETATE');
update temp_history t set depoprovera_start_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','MEDROXYPROGESTERONE ACETATE'),
  'CIEL','163757');
update temp_history t set depoprovera_end_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','MEDROXYPROGESTERONE ACETATE'),
  'CIEL','163758');

update temp_history t set condom = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING','PIH','CONDOMS');
update temp_history t set condom_start_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','CONDOMS'),
  'CIEL','163757');
update temp_history t set condom_end_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','CONDOMS'),
  'CIEL','163758');

update temp_history t set levonorgestrel = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING','PIH','NORPLANT');
update temp_history t set levonorgestrel_start_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','NORPLANT'),
  'CIEL','163757');
update temp_history t set levonorgestrel_end_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','NORPLANT'),
  'CIEL','163758');

update temp_history t set intrauterine_device = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING','PIH','INTRAUTERINE DEVICE');
update temp_history t set intrauterine_device_start_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','INTRAUTERINE DEVICE'),
  'CIEL','163757');
update temp_history t set intrauterine_device_end_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','INTRAUTERINE DEVICE'),
  'CIEL','163758');

update temp_history t set tubal_ligation = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING','PIH','TUBAL LIGATION');
update temp_history t set tubal_ligation_start_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','TUBAL LIGATION'),
  'CIEL','163757');
update temp_history t set tubal_ligation_end_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','TUBAL LIGATION'),
  'CIEL','163758');

update temp_history t set vasectomy = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING','PIH','VASECTOMY');
update temp_history t set vasectomy_start_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','VASECTOMY'),
  'CIEL','163757');
update temp_history t set vasectomy_end_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','VASECTOMY'),
  'CIEL','163758');


update temp_history t set family_plan_other = obs_single_value_coded(encounter_id, 'PIH','METHOD OF FAMILY PLANNING','PIH','OTHER');
update temp_history t set family_plan_other_start_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','OTHER'),
  'CIEL','163757');
update temp_history t set family_plan_other_end_date = 
  obs_from_group_id_value_datetime(obs_group_id_of_value_coded(encounter_id,'PIH','METHOD OF FAMILY PLANNING','PIH','OTHER'),
  'CIEL','163758');
update temp_history t set family_plan_other_name = obs_value_text(encounter_id, 'PIH','OTHER FAMILY PLANNING METHOD, NON-CODED');

-- previous hospitalizations
update temp_history t set hospital1 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',0), 'CIEL','162724');
update temp_history t set admission_date1 = obs_from_group_id_value_datetime(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',0), 'CIEL','1640');
update temp_history t set discharge_date1 = obs_from_group_id_value_datetime(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',0), 'CIEL','1641');
update temp_history t set reason_for_hospitalization1 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',0), 'CIEL','162879');

update temp_history t set hospital2 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',1), 'CIEL','162724');
update temp_history t set admission_date2 = obs_from_group_id_value_datetime(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',1), 'CIEL','1640');
update temp_history t set discharge_date2 = obs_from_group_id_value_datetime(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',1), 'CIEL','1641');
update temp_history t set reason_for_hospitalization2= obs_from_group_id_value_text(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',1), 'CIEL','162879');

update temp_history t set hospital3 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',2), 'CIEL','162724');
update temp_history t set admission_date3 = obs_from_group_id_value_datetime(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',2), 'CIEL','1640');
update temp_history t set discharge_date3 = obs_from_group_id_value_datetime(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',2), 'CIEL','1641');
update temp_history t set reason_for_hospitalization3 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','HOSPITALIZATION CONSTRUCT',2), 'CIEL','162879');

update temp_history t set hospitalization_comments = obs_value_text(encounter_id,'PIH','Hospitalization comment');

-- current medications

update temp_history t set current_meds = obs_value_text(encounter_id,'PIH','CURRENT MEDICATIONS');

-- diagostic tests history

update temp_history t set diagnostic_tests_history = obs_value_text(encounter_id,'PIH','DIAGNOSTIC TESTS HISTORY');

-- select final output     
select * from temp_history;
