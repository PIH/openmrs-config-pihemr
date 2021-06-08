-- set @startDate = '2020-04-27';
-- set @endDate = '2021-04-27';

SET @locale =  ifnull(@locale,if(@startDate is null, 'en', GLOBAL_PROPERTY_VALUE('default_locale', 'en')));

select encounter_type_id into @delivery_note from encounter_type where uuid = '00e5ebb2-90ec-11e8-9eb6-529269fb1459'; 

DROP TEMPORARY TABLE IF EXISTS temp_delivery;
CREATE TEMPORARY TABLE temp_delivery
(
    patient_id                      int(11),
    dossierId                       varchar(50),
    zlemrid                         varchar(50),
    loc_registered                  varchar(255),
    encounter_datetime              datetime,
    encounter_location              varchar(255),
    encounter_type                  varchar(255),
    provider                        varchar(255),
    encounter_id                    int(11),
    delivery_datetime               datetime,
    dystocia                        varchar(255),
    prolapsed_cord                  varchar(255),
    Postpartum_hemorrhage           varchar(10),
    Intrapartum_hemorrhage          varchar(10),
    Placental_abruption             varchar(10),
    Placenta_praevia                varchar(10),
    Rupture_of_uterus               varchar(10),
    Other_hemorrhage                varchar(10),
    Other_hemorrhage_details        varchar(255),
    late_cord_clamping              varchar(255),
    placenta_delivery               varchar(255),
    AMTSL                           varchar(255),
    Placenta_completeness           varchar(255),
    Intact_membranes                varchar(255),
    Retained_placenta               varchar(255),
    Perineal_laceration             varchar(255),
    Perineal_suture                 varchar(255),
    Episiotomy                      varchar(255),
    Postpartum_blood_loss           varchar(255),
    Transfusion                     varchar(255),
    Type_of_delivery                varchar(1000),
    c_section_maternal_reasons      varchar(300),
    other_c_section_maternal_reasons    text,
    c_section_fetal_reasons         varchar(255),
    other_c_section_fetal_reason        text,
    c_section_obstetrical_reasons   varchar(255),
    other_c_section_obstetrical_reason  text,
    Caesarean_hysterectomy          varchar(10),
    C_section_with_tubal_ligation   varchar(10),
    baby_Malpresentation_of_fetus        varchar(10),
    baby_Cephalopelvic_disproportion     varchar(10),
    baby_Extreme_premature               varchar(10),
    baby_Very_premature                  varchar(10),
    baby_Moderate_to_late_preterm        varchar(10),
    baby_Respiratory_distress            varchar(10),
    baby_Birth_asphyxia                  varchar(10),
    baby_Acute_fetal_distress            varchar(10),
    baby_Intrauterine_growth_retardation varchar(10),
    baby_Congenital_malformation         varchar(10),
    baby_Meconium_aspiration             varchar(10),
    mom_Premature_rupture_of_membranes  varchar(10),
    mom_Chorioamnionitis                varchar(10),
    mom_Placental_abnormality           varchar(10),
    mom_Hypertension                    varchar(10),
    mom_Severe_pre_eclampsia            varchar(10),
    mom_Eclampsia                       varchar(10),
    mom_Acute_pulmonary_edema           varchar(10),
    mom_Puerperal_infection             varchar(10),
    mom_Victim_of_GBV                   varchar(10),
    mom_Herpes_simplex                  varchar(10),
    mom_Syphilis                        varchar(10),
    mom_Other_STI                       varchar(10),
    mom_Other_finding            varchar(10),
    mom_Other_finding_details    varchar(255),
    Mental_health_assessment        varchar(1000),
    Birth_1_outcome                 varchar(255),
    Birth_1_weight                  double,
    Birth_1_APGAR                   int,
    Birth_1_neonatal_resuscitation  varchar(255),
    Birth_1_macerated_fetus         varchar(255),
    Birth_2_outcome                 varchar(255),
    Birth_2_weight                  double,
    Birth_2_APGAR                   int,
    Birth_2_neonatal_resuscitation  varchar(255),
    Birth_2_macerated_fetus         varchar(255),
    Birth_3_outcome                 varchar(255),
    Birth_3_weight                  double,
    Birth_3_APGAR                   int,
    Birth_3_neonatal_resuscitation  varchar(255),
    Birth_3_macerated_fetus         varchar(255),
    Birth_4_outcome                 varchar(255),
    Birth_4_weight                  double,
    Birth_4_APGAR                   int,
    Birth_4_neonatal_resuscitation  varchar(255),
    Birth_4_macerated_fetus         varchar(255),
    number_prenatal_visits          int,
    referred_by                     varchar(1000),
    referred_by_other_details       varchar(255),
    nutrition_newborn_counseling    varchar(255),
    family_planning_after_delivery  varchar(255),
    diagnosis_1                     varchar(255),
    diagnosis_1_confirmed           varchar(255),
    diagnosis_1_primary             varchar(255),
    diagnosis_2                     varchar(255),
    diagnosis_2_confirmed           varchar(255),
    diagnosis_2_primary             varchar(255),    
    diagnosis_3                     varchar(255),
    diagnosis_3_confirmed           varchar(255),
    diagnosis_3_primary             varchar(255),
    diagnosis_4                     varchar(255),
    diagnosis_4_confirmed           varchar(255),
    diagnosis_4_primary             varchar(255),
    diagnosis_5                     varchar(255),
    diagnosis_5_confirmed           varchar(255),
    diagnosis_5_primary            varchar(255),
    diagnosis_6                     varchar(255),
    diagnosis_6_confirmed           varchar(255),
    diagnosis_6_primary            varchar(255),
    diagnosis_7                     varchar(255),
    diagnosis_7_confirmed           varchar(255),
    diagnosis_7_primary            varchar(255),
    diagnosis_8                     varchar(255),
    diagnosis_8_confirmed           varchar(255),
    diagnosis_8_primary            varchar(255),
    diagnosis_9                     varchar(255),
    diagnosis_9_confirmed           varchar(255),
    diagnosis_9_primary            varchar(255),
    diagnosis_10                    varchar(255),
    diagnosis_10_confirmed          varchar(255),
    diagnosis_10_primary           varchar(255),
    disposition                     varchar(255),
    disposition_comment             varchar(255),
    return_visit_date               datetime
    );

-- insert encounters into temp table
insert into temp_delivery (
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
where e.encounter_type in (@delivery_note)
AND ((date(e.encounter_datetime) >=@startDate) or @startDate is null)
AND ((date(e.encounter_datetime) <=@endDate)  or @endDate is null)
and voided = 0
;
-- encounter and demo info
update temp_delivery set zlemrid = zlemr(patient_id);
update temp_delivery set dossierid = dosid(patient_id);
update temp_delivery set loc_registered = loc_registered(patient_id);
update temp_delivery set encounter_location = encounter_location_name(encounter_id);
update temp_delivery set provider = provider(encounter_id);


update temp_delivery set delivery_datetime = obs_value_datetime(encounter_id,'PIH','5599');
update temp_delivery set dystocia = obs_value_coded_list(encounter_id,'CIEL','163449',@locale);
update temp_delivery set prolapsed_cord = obs_value_coded_list(encounter_id,'CIEL','113617',@locale);

-- vaginal hemorrhage details 
update temp_delivery set Postpartum_hemorrhage = obs_single_value_coded(encounter_id, 'PIH','3064','CIEL','230');
update temp_delivery set Intrapartum_hemorrhage = obs_single_value_coded(encounter_id, 'PIH','3064','CIEL','136601');
update temp_delivery set Placental_abruption = obs_single_value_coded(encounter_id, 'PIH','3064','CIEL','130108');
update temp_delivery set Placenta_praevia = obs_single_value_coded(encounter_id, 'PIH','3064','CIEL','114127');
update temp_delivery set Rupture_of_uterus = obs_single_value_coded(encounter_id, 'PIH','3064','CIEL','127259');
update temp_delivery set Other_hemorrhage = obs_single_value_coded(encounter_id, 'PIH','3064','CIEL','150802');
update temp_delivery set Other_hemorrhage_details = obs_from_group_id_comment(obs_group_id_of_coded_answer(encounter_id,'CIEL','150802'), 'PIH','3064');

update temp_delivery set late_cord_clamping = obs_value_coded_list(encounter_id,'CIEL','163450',@locale);
update temp_delivery set placenta_delivery = obs_value_coded_list(encounter_id,'PIH','13550',@locale);
update temp_delivery set AMTSL = obs_value_coded_list(encounter_id,'CIEL','163452',@locale);
update temp_delivery set Placenta_completeness = obs_value_coded_list(encounter_id,'CIEL','163454',@locale);

update temp_delivery set Intact_membranes = obs_value_coded_list(encounter_id,'CIEL','164900',@locale);
update temp_delivery set Retained_placenta = obs_value_coded_list(encounter_id,'CIEL','127592',@locale);
update temp_delivery set Perineal_laceration = obs_value_coded_list(encounter_id,'CIEL','114244',@locale);

update temp_delivery set Perineal_suture = obs_single_value_coded(encounter_id, 'CIEL','1651','CIEL','164157');
update temp_delivery set Episiotomy = obs_single_value_coded(encounter_id, 'CIEL','1651','CIEL','5577');  


update temp_delivery set Postpartum_blood_loss = obs_value_coded_list(encounter_id,'CIEL','162092',@locale);
update temp_delivery set Transfusion = obs_value_coded_list(encounter_id,'CIEL','1063',@locale);

update temp_delivery set Type_of_delivery = obs_value_coded_list(encounter_id,'PIH','11663',@locale);

-- - c - section
-- maternal
update temp_delivery t set c_section_maternal_reasons = (select group_concat(concept_name(value_coded, @locale) separator " | ")
from obs o where t.encounter_id = o.encounter_id and concept_id = concept_from_mapping("PIH", "13527") and voided = 0 and value_coded in
(
concept_from_mapping("CIEL", "113017"),
concept_from_mapping("CIEL", "113858"),
concept_from_mapping("CIEL", "117703"),
concept_from_mapping("CIEL", "113918"),
concept_from_mapping("CIEL", "113006"),
concept_from_mapping("CIEL", "118744"),
concept_from_mapping("CIEL", "111491"),
concept_from_mapping("CIEL", "162185"),
concept_from_mapping("CIEL", "158060")
));

update temp_delivery t set other_c_section_maternal_reasons = obs_comments(encounter_id, "PIH", "13527" , "PIH", "13571");

-- fetal
update temp_delivery t set c_section_fetal_reasons = (select group_concat(concept_name(value_coded, @locale) separator " | ")
from obs o where t.encounter_id = o.encounter_id and concept_id = concept_from_mapping("PIH", "13527") and voided = 0 and value_coded in
(
concept_from_mapping("CIEL", "115939"),
concept_from_mapping("CIEL", "143849"),
concept_from_mapping("CIEL", "118256"),
concept_from_mapping("CIEL", "115491")
));
update temp_delivery t set other_c_section_fetal_reason = obs_comments(encounter_id, "PIH", "13527" , "PIH", "13572");

-- obsterical
update temp_delivery t set c_section_obstetrical_reasons   = (select group_concat(concept_name(value_coded, @locale) separator " | ")
from obs o where t.encounter_id = o.encounter_id and concept_id = concept_from_mapping("PIH", "13527") and voided = 0 and value_coded in
(
concept_from_mapping("CIEL", "130109"),
concept_from_mapping("CIEL", "113617"),
concept_from_mapping("CIEL", "114127"),
concept_from_mapping("CIEL", "113814"),
concept_from_mapping("CIEL", "145935"),
concept_from_mapping("CIEL", "113602")
));
update temp_delivery t set other_c_section_obstetrical_reason = obs_comments(encounter_id, "PIH", "13527" , "PIH", "13573");

update temp_delivery set Caesarean_hysterectomy = obs_single_value_coded(encounter_id, 'CIEL','1651','CIEL','161848');  
update temp_delivery set C_section_with_tubal_ligation = obs_single_value_coded(encounter_id, 'CIEL','1651','CIEL','161890');

-- findings for baby
update temp_delivery set baby_Malpresentation_of_fetus = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','115939');  
update temp_delivery set baby_Cephalopelvic_disproportion = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','145935');  
update temp_delivery set baby_Extreme_premature = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','111523');  
update temp_delivery set baby_Very_premature = obs_single_value_coded(encounter_id, 'CIEL','1284','PIH','11789');  
update temp_delivery set baby_Moderate_to_late_preterm = obs_single_value_coded(encounter_id, 'CIEL','1284','PIH','11790');  
update temp_delivery set baby_Respiratory_distress = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','127639');  
update temp_delivery set baby_Birth_asphyxia = obs_single_value_coded(encounter_id, 'CIEL','1284','PIH','7557');  
update temp_delivery set baby_Acute_fetal_distress = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','118256');  
update temp_delivery set baby_Intrauterine_growth_retardation = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','118245');  
update temp_delivery set baby_Congenital_malformation = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','143849');  
update temp_delivery set baby_Meconium_aspiration = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','115866');  

-- findings for mother
update temp_delivery set mom_Premature_rupture_of_membranes = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','129211');  
update temp_delivery set mom_Chorioamnionitis = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','145548');  
update temp_delivery set mom_Placental_abnormality = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','130109');  
update temp_delivery set mom_Hypertension = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','117399');  
update temp_delivery set mom_Severe_pre_eclampsia = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','113006');  
update temp_delivery set mom_Eclampsia = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','118744');  
update temp_delivery set mom_Acute_pulmonary_edema = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','121856');  
update temp_delivery set mom_Puerperal_infection = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','130');  
update temp_delivery set mom_Victim_of_GBV = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','165088');  
update temp_delivery set mom_Herpes_simplex = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','138706');  
update temp_delivery set mom_Syphilis = obs_single_value_coded(encounter_id, 'CIEL','1284','CIEL','112493');  
update temp_delivery set mom_Other_STI = obs_single_value_coded(encounter_id, 'PIH','6644','CIEL','112992');  
update temp_delivery set mom_Other_finding = obs_single_value_coded(encounter_id, 'PIH','6644','CIEL','5622');  
update temp_delivery set mom_Other_finding_details = obs_comments(encounter_id, 'PIH','6644','CIEL','5622');  

update temp_delivery set Mental_health_assessment = obs_value_coded_list(encounter_id,'PIH','10594',@locale);

-- birth details (1 to 3)
update temp_delivery set Birth_1_outcome = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 0),'CIEL','161033',@locale);
update temp_delivery set Birth_1_weight = obs_from_group_id_value_numeric(obs_id(encounter_id,'CIEL','1585', 0),'CIEL','5916');
update temp_delivery set Birth_1_APGAR = obs_from_group_id_value_numeric(obs_id(encounter_id,'CIEL','1585', 0),'CIEL','1504');
update temp_delivery set Birth_1_neonatal_resuscitation = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 0),'CIEL','162131',@locale);
update temp_delivery set Birth_1_macerated_fetus = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 0),'CIEL','135437',@locale);

update temp_delivery set Birth_2_outcome = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 1),'CIEL','161033',@locale);
update temp_delivery set Birth_2_weight = obs_from_group_id_value_numeric(obs_id(encounter_id,'CIEL','1585', 1),'CIEL','5916');
update temp_delivery set Birth_2_APGAR = obs_from_group_id_value_numeric(obs_id(encounter_id,'CIEL','1585', 1),'CIEL','1504');
update temp_delivery set Birth_2_neonatal_resuscitation = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 1),'CIEL','162131',@locale);
update temp_delivery set Birth_2_macerated_fetus = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 1),'CIEL','135437',@locale);

update temp_delivery set Birth_3_outcome = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 2),'CIEL','161033',@locale);
update temp_delivery set Birth_3_weight = obs_from_group_id_value_numeric(obs_id(encounter_id,'CIEL','1585', 2),'CIEL','5916');
update temp_delivery set Birth_3_APGAR = obs_from_group_id_value_numeric(obs_id(encounter_id,'CIEL','1585', 2),'CIEL','1504');
update temp_delivery set Birth_3_neonatal_resuscitation = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 2),'CIEL','162131',@locale);
update temp_delivery set Birth_3_macerated_fetus = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 2),'CIEL','135437',@locale);

update temp_delivery set Birth_4_outcome = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 3),'CIEL','161033',@locale);
update temp_delivery set Birth_4_weight = obs_from_group_id_value_numeric(obs_id(encounter_id,'CIEL','1585', 3),'CIEL','5916');
update temp_delivery set Birth_4_APGAR = obs_from_group_id_value_numeric(obs_id(encounter_id,'CIEL','1585', 3),'CIEL','1504');
update temp_delivery set Birth_4_neonatal_resuscitation = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 3),'CIEL','162131',@locale);
update temp_delivery set Birth_4_macerated_fetus = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1585', 3),'CIEL','135437',@locale);

update temp_delivery set number_prenatal_visits = obs_value_numeric(encounter_id,'CIEL','1590');
update temp_delivery set referred_by = obs_value_coded_list(encounter_id,'PIH','10635',@locale);
update temp_delivery set referred_by_other_details = obs_comments(encounter_id, 'PIH','10635','CIEL','5622');
update temp_delivery set nutrition_newborn_counseling = obs_value_coded_list(encounter_id,'CIEL','161651',@locale);
update temp_delivery set family_planning_after_delivery = obs_value_coded_list(encounter_id,'PIH','13564',@locale);

-- diagnoses
update temp_delivery t set diagnosis_1 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',0),'PIH','3064',@locale);
update temp_delivery t set diagnosis_1_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',0),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',0) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_1_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;

update temp_delivery t set diagnosis_2 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',1),'PIH','3064',@locale);
update temp_delivery t set diagnosis_2_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',1),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',1) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_2_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
update temp_delivery t set diagnosis_3 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',2),'PIH','3064',@locale);
update temp_delivery t set diagnosis_3_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',2),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',2) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_3_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
update temp_delivery t set diagnosis_4 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',3),'PIH','3064',@locale);
update temp_delivery t set diagnosis_4_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',3),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',3) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_4_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
update temp_delivery t set diagnosis_5 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',4),'PIH','3064',@locale);
update temp_delivery t set diagnosis_5_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',4),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',4) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_5_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
update temp_delivery t set diagnosis_6 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',5),'PIH','3064',@locale);
update temp_delivery t set diagnosis_6_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',5),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',5) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_6_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
update temp_delivery t set diagnosis_7 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',6),'PIH','3064',@locale);
update temp_delivery t set diagnosis_7_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',6),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',6) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_7_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
update temp_delivery t set diagnosis_8 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',7),'PIH','3064',@locale);
update temp_delivery t set diagnosis_8_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',7),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',7) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_8_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
update temp_delivery t set diagnosis_9 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',8),'PIH','3064',@locale);
update temp_delivery t set diagnosis_9_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',8),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',8) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_9_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
update temp_delivery t set diagnosis_10 =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',9),'PIH','3064',@locale);
update temp_delivery t set diagnosis_10_confirmed =obs_from_group_id_value_coded_list(obs_id(t.encounter_id,'PIH','7539',9),'PIH','1379',@locale);
update temp_delivery t
inner join obs o on  o.obs_group_id =  obs_id(t.encounter_id,'PIH','7539',9) and concept_id = concept_from_mapping('PIH','7537') and o.voided = 0
set diagnosis_10_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),'@locale'), concept_name(concept_from_mapping('PIH','NO'),'@locale'))
;
-- disposition info
update temp_delivery set disposition = obs_value_coded_list(encounter_id,'PIH','8620',@locale);
update temp_delivery set disposition_comment = obs_value_text(encounter_id,'PIH','DISPOSITION COMMENTS');
update temp_delivery set return_visit_date = obs_value_datetime(encounter_id,'PIH','5096');

-- select final output
select * from temp_delivery;
