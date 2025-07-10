-- set @startDate = '2000-05-01';
-- set @endDate = '2022-06-09';
set @partition = '${partitionNum}';
SET @locale = ifnull(@locale, GLOBAL_PROPERTY_VALUE('default_locale', 'en'));
set @mch_program = (select program_id from program where uuid = '41a2715e-8a14-11e8-9a94-a6cf71072f73');
select encounter_type_id into @delivery_note from encounter_type where uuid='00e5ebb2-90ec-11e8-9eb6-529269fb1459'; 

DROP TEMPORARY TABLE IF EXISTS temp_delivery;
CREATE TEMPORARY TABLE temp_delivery
(
    patient_id                           int(11),
    dossierId                            varchar(50),
    zlemrid                              varchar(50),
    loc_registered                       varchar(255),
    mch_program_id                       int(11),
    encounter_datetime                   datetime,
    encounter_location                   varchar(255),
    encounter_type                       varchar(255),
    provider                             varchar(255),
    date_entered                         datetime,
    encounter_id                         int(11),
    delivery_datetime                    datetime,
    partogram_completed                  bit,
    dystocia                             varchar(255),
    prolapsed_cord                       bit,
    Postpartum_hemorrhage                varchar(10),
    Intrapartum_hemorrhage               varchar(10),
    Placental_abruption                  varchar(10),
    Placenta_praevia                     varchar(10),
    Rupture_of_uterus                    varchar(10),
    Other_hemorrhage                     varchar(10),
    Other_hemorrhage_details             varchar(255),
    late_cord_clamping                   bit,
    placenta_delivery                    varchar(255),
    AMTSL                                bit,
    Placenta_completeness                varchar(255),
    Intact_membranes                     bit,
    Retained_placenta                    bit,
    Perineal_laceration                  bit,
    Perineal_suture                      varchar(255),
    Episiotomy                           varchar(255),
    Postpartum_blood_loss                varchar(255),
    Transfusion                          bit,
    maternal_delivery_type_deprecated    varchar(500),
    Caesarean_hysterectomy               varchar(10),
    C_section_with_tubal_ligation        varchar(10),
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
    mom_Premature_rupture_of_membranes   varchar(10),
    mom_Chorioamnionitis                 varchar(10),
    mom_Placental_abnormality            varchar(10),
    mom_Hypertension                     varchar(10),
    mom_Severe_pre_eclampsia             varchar(10),
    mom_Eclampsia                        varchar(10),
    mom_Acute_pulmonary_edema            varchar(10),
    mom_Puerperal_infection              varchar(10),
    mom_Victim_of_GBV                    varchar(10),
    mom_Herpes_simplex                   varchar(10),
    mom_Syphilis                         varchar(10),
    mom_Other_STI                        varchar(10),
    mom_Other_finding                    varchar(10),
    mom_Other_finding_details            varchar(255),
    Mental_health_assessment             varchar(1000),
    Birth_1_obs_group_id                 int(11),
    Birth_1_outcome                      varchar(255),
    Birth_1_weight                       double,
    Birth_1_APGAR_5_minute               int,
    Birth_1_APGAR_1_minute               int,
    Birth_1_APGAR_10_minute              int,
    Birth_1_neonatal_resuscitation       varchar(255),
    Birth_1_macerated_fetus              bit,
    Birth_2_obs_group_id                 int(11),    
    Birth_2_outcome                      varchar(255),
    Birth_2_weight                       double,
    Birth_2_APGAR_5_minute               int,
    Birth_2_APGAR_1_minute               int,
    Birth_2_APGAR_10_minute              int,
    Birth_2_neonatal_resuscitation       varchar(255),
    Birth_2_macerated_fetus              bit,
    Birth_3_obs_group_id                 int(11),    
    Birth_3_outcome                      varchar(255),
    Birth_3_weight                       double,
    Birth_3_APGAR_5_minute               int,
    Birth_3_APGAR_1_minute               int,
    Birth_3_APGAR_10_minute              int,
    Birth_3_neonatal_resuscitation       varchar(255),
    Birth_3_macerated_fetus              bit,
    Birth_4_obs_group_id                 int(11),    
    Birth_4_outcome                      varchar(255),
    Birth_4_weight                       double,
    Birth_4_APGAR_5_minute               int,
    Birth_4_APGAR_1_minute               int,
    Birth_4_APGAR_10_minute              int,
    Birth_4_neonatal_resuscitation       varchar(255),
    Birth_4_macerated_fetus              bit,
    number_prenatal_visits               int,
    referred_by                          varchar(1000),
    referred_by_other_details            varchar(255),
    nutrition_newborn_counseling         bit,
    family_planning_after_delivery       bit,
    diagnosis_1_obs_group_id             int(11),
    diagnosis_1                          varchar(255),
    diagnosis_1_confirmed                varchar(255),
    diagnosis_1_primary                  varchar(255),
    diagnosis_2_obs_group_id             int(11),
    diagnosis_2                          varchar(255),
    diagnosis_2_confirmed                varchar(255),
    diagnosis_2_primary                  varchar(255),
    diagnosis_3_obs_group_id             int(11),
    diagnosis_3                          varchar(255),
    diagnosis_3_confirmed                varchar(255),
    diagnosis_3_primary                  varchar(255),
    diagnosis_4_obs_group_id             int(11),
    diagnosis_4                          varchar(255),
    diagnosis_4_confirmed                varchar(255),
    diagnosis_4_primary                  varchar(255),
    diagnosis_5_obs_group_id             int(11),
    diagnosis_5                          varchar(255),
    diagnosis_5_confirmed                varchar(255),
    diagnosis_5_primary                  varchar(255),
    diagnosis_6_obs_group_id             int(11),
    diagnosis_6                          varchar(255),
    diagnosis_6_confirmed                varchar(255),
    diagnosis_6_primary                  varchar(255),
    diagnosis_7_obs_group_id             int(11),
    diagnosis_7                          varchar(255),
    diagnosis_7_confirmed                varchar(255),
    diagnosis_7_primary                  varchar(255),
    diagnosis_8_obs_group_id             int(11),
    diagnosis_8                          varchar(255),
    diagnosis_8_confirmed                varchar(255),
    diagnosis_8_primary                  varchar(255),
    diagnosis_9_obs_group_id             int(11),
    diagnosis_9                          varchar(255),
    diagnosis_9_confirmed                varchar(255),
    diagnosis_9_primary                  varchar(255),
    diagnosis_10_obs_group_id            int(11),
    diagnosis_10                         varchar(255),
    diagnosis_10_confirmed               varchar(255),
    diagnosis_10_primary                 varchar(255),
    disposition                          varchar(255),
    disposition_comment                  text,
    return_visit_date                    datetime
);

-- insert encounters into temp table
insert into temp_delivery (
  patient_id,
  encounter_id,
  encounter_datetime,
  date_entered,
  encounter_type)
select
  patient_id,
  encounter_id,
  encounter_datetime,
  e.date_created, 
  et.name
from encounter e
inner join encounter_type et on et.encounter_type_id = e.encounter_type
where e.encounter_type in (@delivery_note)
AND ((date(e.encounter_datetime) >=@startDate) or @startDate is null)
AND ((date(e.encounter_datetime) <=@endDate)  or @endDate is null)
and voided = 0
;

create index temp_delivery_encounter_id on temp_delivery (encounter_id);

-- encounter and demo info
update temp_delivery set zlemrid = zlemr(patient_id);
update temp_delivery set dossierid = dosid(patient_id);
update temp_delivery set loc_registered = loc_registered(patient_id);
update temp_delivery set encounter_location = encounter_location_name(encounter_id);
update temp_delivery set provider = provider(encounter_id);

UPDATE temp_delivery t 
SET mch_program_id = patient_program_id_from_encounter(patient_id, @mch_program, encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.comments, o.date_created  
from obs o
 inner join temp_delivery t on t.encounter_id = o.encounter_id
where o.voided = 0
;
create index temp_obs_ci1 on temp_obs(encounter_id,value_coded);
create index temp_obs_ci2 on temp_obs(encounter_id,concept_id);
create index temp_obs_ci3 on temp_obs(obs_group_id,concept_id);

set @yes = concept_from_mapping('PIH','YES');
set @no = concept_from_mapping('PIH','NO');
set @procedure_performed = concept_from_mapping('CIEL','1651');

set @del_datetime = concept_from_mapping('PIH','5599');
set @part = concept_from_mapping('PIH','13964');
set @dystocia = concept_from_mapping('CIEL','163449');
set @prolapsed_cord = concept_from_mapping('CIEL','113617');

set @dx = concept_from_mapping('PIH','3064');
set @pp_hem = concept_from_mapping('CIEL','230');
set @ip_hem = concept_from_mapping('CIEL','136601');
set @abruption = concept_from_mapping('CIEL','130108');
set @praevia = concept_from_mapping('CIEL','114127');
set @rupture = concept_from_mapping('CIEL','127259');
set @other_hem = concept_from_mapping('CIEL','150802');
set @placenta_delivery = concept_from_mapping('PIH','13550');
set @maternal_delivery_type_deprecated = concept_from_mapping('PIH','11663');
set @fetal_membrane_status = concept_from_mapping('CIEL','164900');
set @Intact_fetal_membranes = concept_from_mapping('CIEL','164899');  -- membrane
set @Ruptured_fetal_membranes = concept_from_mapping('CIEL','127244');
set @Placenta_completeness = concept_from_mapping('CIEL','163454');
set @AMTSL = concept_from_mapping('CIEL','163452');
set @late_cord_clamping = concept_from_mapping('CIEL','163450');
set @Postpartum_blood_loss = concept_from_mapping('CIEL','162092');
set @Retained_placenta = concept_from_mapping('CIEL','127592');
set @Perineal_laceration = concept_from_mapping('CIEL','114244');
set @Transfusion = concept_from_mapping('CIEL','1063');
set @Postpartum_blood_loss = concept_from_mapping('CIEL','162092');
set @maternal_delivery_type_deprecated = concept_from_mapping('PIH','11663');
set @Perineal_suture = concept_from_mapping('CIEL','164157');
set @Episiotomy = concept_from_mapping('CIEL','5577');
set @C_section_with_tubal_ligation = concept_from_mapping('CIEL','161890');
set @Caesarean_hysterectomy = concept_from_mapping('CIEL','161848');


drop temporary table if exists temp_obs_collated;
create temporary table temp_obs_collated 
select 
encounter_id,
max(case when concept_id = @del_datetime then value_datetime end) "delivery_datetime",
max(case when concept_id = @part and value_coded = @yes then 1
		 when concept_id = @part and value_coded = @no then 0 end) "partogram_completed",
max(case when concept_id = @dystocia then concept_name(value_coded, @locale) end) "dystocia",
max(case when concept_id = @prolapsed_cord and value_coded = @yes then 1
		 when concept_id = @prolapsed_cord and value_coded = @no then 0 end) "prolapsed_cord",
max(case when concept_id = @dx and value_coded = @pp_hem then 1 end) "Postpartum_hemorrhage",
max(case when concept_id = @dx and value_coded = @ip_hem then 1 end) "Intrapartum_hemorrhage",
max(case when concept_id = @dx and value_coded = @abruption then 1 end) "Placental_abruption",
max(case when concept_id = @dx and value_coded = @praevia then 1 end) "Placenta_praevia",
max(case when concept_id = @dx and value_coded = @rupture then 1 end) "Rupture_of_uterus",
max(case when concept_id = @dx and value_coded = @other_hem then 1 end) "Other_hemorrhage",
max(case when concept_id = @Placenta_completeness then concept_name(value_coded, @locale) end) "Placenta_completeness",
max(case when concept_id = @AMTSL and value_coded = @yes then 1
		 when concept_id = @AMTSL and value_coded = @no then 0 end) "AMTSL",
max(case when concept_id = @late_cord_clamping and value_coded = @yes then 1
		 when concept_id = @late_cord_clamping and value_coded = @no then 0 end) "late_cord_clamping",
max(case when concept_id = @Postpartum_blood_loss then concept_name(value_coded, @locale) end) "Postpartum_blood_loss",
max(case when concept_id = @Retained_placenta and value_coded = @yes then 1
		 when concept_id = @Retained_placenta and value_coded = @no then 0 end) "Retained_placenta",
max(case when concept_id = @Perineal_laceration and value_coded = @yes then 1
		 when concept_id = @Perineal_laceration and value_coded = @no then 0 end) "Perineal_laceration",
max(case when concept_id = @Transfusion and value_coded = @yes then 1
		 when concept_id = @Transfusion and value_coded = @no then 0 end) "Transfusion",
max(case when concept_id = @placenta_delivery then concept_name(value_coded, @locale) end) "placenta_delivery",
max(case when concept_id = @fetal_membrane_status and value_coded = @Intact_fetal_membranes then 1
		 when concept_id = @fetal_membrane_status and value_coded = @Ruptured_fetal_membranes then 0 end) "Intact_membranes",
group_concat(DISTINCT case when concept_id = @maternal_delivery_type_deprecated then concept_name(value_coded, @locale) end  separator ' | ') "maternal_delivery_type_deprecated",
max(case when concept_id = @procedure_performed and value_coded = @Perineal_suture then 1 end)  "Perineal_suture",
max(case when concept_id = @procedure_performed and value_coded = @Episiotomy then 1 end)  "Episiotomy",
max(case when concept_id = @procedure_performed and value_coded = @C_section_with_tubal_ligation then 1 end)  "C_section_with_tubal_ligation",
max(case when concept_id = @procedure_performed and value_coded = @Caesarean_hysterectomy then 1 end)  "Caesarean_hysterectomy"
from temp_obs
group by encounter_id;

create index temp_obs_collated_ei on temp_obs_collated(encounter_id);

update temp_delivery t 
inner join temp_obs_collated o on o.encounter_id = t.encounter_id
set t.delivery_datetime = o.delivery_datetime,
	t.partogram_completed = o.partogram_completed,
	t.dystocia = o.dystocia,
	t.prolapsed_cord = o.prolapsed_cord,
	t.Postpartum_hemorrhage = o.Postpartum_hemorrhage,
	t.Intrapartum_hemorrhage = o.Intrapartum_hemorrhage,
	t.Placental_abruption = o.Placental_abruption,	
	t.Placenta_praevia = o.Placenta_praevia,		
	t.Rupture_of_uterus = o.Rupture_of_uterus,	
	t.Other_hemorrhage = o.Other_hemorrhage,
	t.placenta_delivery = o.placenta_delivery,
	t.maternal_delivery_type_deprecated = o.maternal_delivery_type_deprecated,
	t.Intact_membranes = o.Intact_membranes,
	t.Placenta_completeness = o.Placenta_completeness,
	t.AMTSL = o.AMTSL,
	t.late_cord_clamping = o.late_cord_clamping,
	t.Postpartum_blood_loss = o.Postpartum_blood_loss,
	t.Retained_placenta = o.Retained_placenta,
	t.Perineal_laceration = o.Perineal_laceration,
	t.Transfusion = o.Transfusion,
	t.Postpartum_blood_loss = o.Postpartum_blood_loss,
	t.maternal_delivery_type_deprecated = o.maternal_delivery_type_deprecated,
	t.Perineal_suture = o.Perineal_suture,
	t.Episiotomy = o.Episiotomy,
	t.C_section_with_tubal_ligation = o.C_section_with_tubal_ligation,
	t.Caesarean_hysterectomy = o.Caesarean_hysterectomy	;

update temp_delivery set Other_hemorrhage_details = obs_from_group_id_comment_from_temp(obs_group_id_of_coded_answer(encounter_id,'CIEL','150802'), 'PIH','3064');

-- findings for baby and mom
set @baby_Malpresentation_of_fetus = concept_from_mapping('CIEL','115939');
set @baby_Cephalopelvic_disproportion = concept_from_mapping('CIEL','145935');
set @baby_Extreme_premature = concept_from_mapping('CIEL','111523');
set @baby_Very_premature = concept_from_mapping('PIH','11789');
set @baby_Moderate_to_late_preterm = concept_from_mapping('PIH','11790');
set @baby_Respiratory_distress = concept_from_mapping('CIEL','127639');
set @baby_Birth_asphyxia = concept_from_mapping('PIH','7557');
set @baby_Acute_fetal_distress = concept_from_mapping('CIEL','118256');
set @baby_Intrauterine_growth_retardation = concept_from_mapping('CIEL','118245');
set @baby_Congenital_malformation = concept_from_mapping('CIEL','143849');
set @baby_Meconium_aspiration = concept_from_mapping('CIEL','115866');

set @mom_Premature_rupture_of_membranes = concept_from_mapping('CIEL','129211');
set @mom_Chorioamnionitis = concept_from_mapping('CIEL','145548');
set @mom_Placental_abnormality = concept_from_mapping('CIEL','130109');
set @mom_Hypertension = concept_from_mapping('CIEL','117399');
set @mom_Severe_pre_eclampsia = concept_from_mapping('CIEL','113006');
set @mom_Eclampsia = concept_from_mapping('CIEL','118744');
set @mom_Acute_pulmonary_edema = concept_from_mapping('CIEL','121856');
set @mom_Puerperal_infection = concept_from_mapping('CIEL','130');
set @mom_Victim_of_GBV = concept_from_mapping('CIEL','165088');
set @mom_Herpes_simplex = concept_from_mapping('CIEL','138706');
set @mom_Syphilis = concept_from_mapping('CIEL','112493');
set @mom_Other_STI = concept_from_mapping('CIEL','112992');
set @mom_Other_finding = concept_from_mapping('CIEL','5622');
set @del_complications  = concept_from_mapping('PIH','6644');
set @other = concept_from_mapping('PIH','5622');

drop temporary table if exists temp_obs_collated;
create temporary table temp_obs_collated 
select encounter_id,
max(case when concept_id = @dx and value_coded = @baby_Malpresentation_of_fetus then 1 end) "baby_Malpresentation_of_fetus",
max(case when concept_id = @dx and value_coded = @baby_Cephalopelvic_disproportion then 1 end) "baby_Cephalopelvic_disproportion",
max(case when concept_id = @dx and value_coded = @baby_Extreme_premature then 1 end) "baby_Extreme_premature",
max(case when concept_id = @dx and value_coded = @baby_Very_premature then 1 end) "baby_Very_premature",
max(case when concept_id = @dx and value_coded = @baby_Moderate_to_late_preterm then 1 end) "baby_Moderate_to_late_preterm",
max(case when concept_id = @dx and value_coded = @baby_Respiratory_distress then 1 end) "baby_Respiratory_distress",
max(case when concept_id = @dx and value_coded = @baby_Birth_asphyxia then 1 end) "baby_Birth_asphyxia",
max(case when concept_id = @dx and value_coded = @baby_Acute_fetal_distress then 1 end) "baby_Acute_fetal_distress",
max(case when concept_id = @dx and value_coded = @baby_Intrauterine_growth_retardation then 1 end) "baby_Intrauterine_growth_retardation",
max(case when concept_id = @dx and value_coded = @baby_Congenital_malformation then 1 end) "baby_Congenital_malformation",
max(case when concept_id = @dx and value_coded = @baby_Meconium_aspiration then 1 end) "baby_Meconium_aspiration",
max(case when concept_id = @dx and value_coded = @del_datetime then 1 end) "delivery_datetime",
max(case when concept_id = @dx and value_coded = @mom_Premature_rupture_of_membranes then 1 end) "mom_Premature_rupture_of_membranes",
max(case when concept_id = @dx and value_coded = @mom_Chorioamnionitis then 1 end) "mom_Chorioamnionitis",
max(case when concept_id = @dx and value_coded = @mom_Placental_abnormality then 1 end) "mom_Placental_abnormality",
max(case when concept_id = @dx and value_coded = @mom_Hypertension then 1 end) "mom_Hypertension",
max(case when concept_id = @dx and value_coded = @mom_Severe_pre_eclampsia then 1 end) "mom_Severe_pre_eclampsia",
max(case when concept_id = @dx and value_coded = @mom_Eclampsia then 1 end) "mom_Eclampsia",
max(case when concept_id = @dx and value_coded = @mom_Acute_pulmonary_edema then 1 end) "mom_Acute_pulmonary_edema",
max(case when concept_id = @dx and value_coded = @mom_Puerperal_infection then 1 end) "mom_Puerperal_infection",
max(case when concept_id = @dx and value_coded = @mom_Victim_of_GBV then 1 end) "mom_Victim_of_GBV",
max(case when concept_id = @dx and value_coded = @mom_Herpes_simplex then 1 end) "mom_Herpes_simplex",
max(case when concept_id = @dx and value_coded = @mom_Syphilis then 1 end) "mom_Syphilis",
max(case when concept_id = @dx and value_coded = @mom_Other_STI then 1 end) "mom_Other_STI",
max(case when concept_id = @dx and value_coded = @mom_Other_finding then 1 end) "mom_Other_finding",
max(case when concept_id = @del_complications and value_coded = @other then comments end) "mom_Other_finding_details"
from temp_obs
group by encounter_id;

create index temp_obs_collated_ei on temp_obs_collated(encounter_id);

update temp_delivery t 
inner join temp_obs_collated o on o.encounter_id = t.encounter_id
set t.baby_Malpresentation_of_fetus = o.baby_Malpresentation_of_fetus,
	t.baby_Cephalopelvic_disproportion = o.baby_Cephalopelvic_disproportion,
	t.baby_Extreme_premature = o.baby_Extreme_premature,
	t.baby_Very_premature = o.baby_Very_premature,
	t.baby_Moderate_to_late_preterm = o.baby_Moderate_to_late_preterm,
	t.baby_Respiratory_distress = o.baby_Respiratory_distress,
	t.baby_Birth_asphyxia = o.baby_Birth_asphyxia,
	t.baby_Acute_fetal_distress = o.baby_Acute_fetal_distress,
	t.baby_Intrauterine_growth_retardation = o.baby_Intrauterine_growth_retardation,
	t.baby_Congenital_malformation = o.baby_Congenital_malformation,
	t.baby_Meconium_aspiration = o.baby_Meconium_aspiration,
	t.mom_Premature_rupture_of_membranes = o.mom_Premature_rupture_of_membranes,
	t.mom_Chorioamnionitis = o.mom_Chorioamnionitis,
	t.mom_Placental_abnormality = o.mom_Placental_abnormality,
	t.mom_Hypertension = o.mom_Hypertension,
	t.mom_Severe_pre_eclampsia = o.mom_Severe_pre_eclampsia,
	t.mom_Eclampsia = o.mom_Eclampsia,
	t.mom_Acute_pulmonary_edema = o.mom_Acute_pulmonary_edema,
	t.mom_Puerperal_infection = o.mom_Puerperal_infection,
	t.mom_Victim_of_GBV = o.mom_Victim_of_GBV,
	t.mom_Herpes_simplex = o.mom_Herpes_simplex,
	t.mom_Syphilis = o.mom_Syphilis,
	t.mom_Other_STI = o.mom_Other_STI,
	t.mom_Other_finding = o.mom_Other_finding,
	t.mom_Other_finding_details = o.mom_Other_finding_details;

update temp_delivery set Mental_health_assessment = obs_value_coded_list_from_temp(encounter_id,'PIH','10594',@locale);

update temp_delivery set Birth_1_obs_group_id = obs_id_from_temp(encounter_id,'CIEL','1585', 0);
update temp_delivery set Birth_2_obs_group_id = obs_id_from_temp(encounter_id,'CIEL','1585', 1);
update temp_delivery set Birth_3_obs_group_id = obs_id_from_temp(encounter_id,'CIEL','1585', 2);
update temp_delivery set Birth_4_obs_group_id = obs_id_from_temp(encounter_id,'CIEL','1585', 3);

set @Birth_outcome = concept_from_mapping('CIEL','161033');
set @Birth_weight = concept_from_mapping('CIEL','5916');
set @Birth_APGAR_5_minute = concept_from_mapping('CIEL','1504');
set @Birth_APGAR_1_minute = concept_from_mapping('PIH','14419');
set @Birth_APGAR_10_minute = concept_from_mapping('PIH','14785');
set @Birth_neonatal_resuscitation = concept_from_mapping('CIEL','162131');
set @Birth_macerated_fetus = concept_from_mapping('CIEL','135437');

drop temporary table if exists temp_obs_collated;
create temporary table temp_obs_collated 
select 
o.encounter_id,
max(case when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_outcome then concept_name(value_coded, @locale) end) "Birth_1_outcome",
max(case when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_weight then value_numeric end) "Birth_1_weight",
max(case when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_APGAR_5_minute then value_numeric end) "Birth_1_APGAR_5_minute",
max(case when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_APGAR_1_minute then value_numeric end) "Birth_1_APGAR_1_minute",
max(case when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_APGAR_10_minute then value_numeric end) "Birth_1_APGAR_10_minute",
max(case when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_neonatal_resuscitation and value_coded = @yes then 1
         when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_neonatal_resuscitation and value_coded = @no then 0 end) "Birth_1_neonatal_resuscitation",
max(case when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_macerated_fetus and value_coded = @yes then 1 
         when obs_group_id = Birth_1_obs_group_id and concept_id = @Birth_macerated_fetus and value_coded = @yes then 0 end) "Birth_1_macerated_fetus",
max(case when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_outcome then concept_name(value_coded, @locale) end) "Birth_2_outcome",
max(case when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_weight then value_numeric end) "Birth_2_weight",
max(case when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_APGAR_5_minute then value_numeric end) "Birth_2_APGAR_5_minute",
max(case when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_APGAR_1_minute then value_numeric end) "Birth_2_APGAR_1_minute",
max(case when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_APGAR_10_minute then value_numeric end) "Birth_2_APGAR_10_minute",
max(case when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_neonatal_resuscitation and value_coded = @yes then 1
         when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_neonatal_resuscitation and value_coded = @no then 0 end) "Birth_2_neonatal_resuscitation",
max(case when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_macerated_fetus and value_coded = @yes then 1 
         when obs_group_id = Birth_2_obs_group_id and concept_id = @Birth_macerated_fetus and value_coded = @yes then 0 end) "Birth_2_macerated_fetus",
max(case when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_outcome then concept_name(value_coded, @locale) end) "Birth_3_outcome",
max(case when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_weight then value_numeric end) "Birth_3_weight",
max(case when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_APGAR_5_minute then value_numeric end) "Birth_3_APGAR_5_minute",
max(case when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_APGAR_1_minute then value_numeric end) "Birth_3_APGAR_1_minute",
max(case when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_APGAR_10_minute then value_numeric end) "Birth_3_APGAR_10_minute",
max(case when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_neonatal_resuscitation and value_coded = @yes then 1
         when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_neonatal_resuscitation and value_coded = @no then 0 end) "Birth_3_neonatal_resuscitation",
max(case when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_macerated_fetus and value_coded = @yes then 1 
         when obs_group_id = Birth_3_obs_group_id and concept_id = @Birth_macerated_fetus and value_coded = @yes then 0 end) "Birth_3_macerated_fetus",
max(case when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_outcome then concept_name(value_coded, @locale) end) "Birth_4_outcome",
max(case when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_weight then value_numeric end) "Birth_4_weight",
max(case when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_APGAR_5_minute then value_numeric end) "Birth_4_APGAR_5_minute",
max(case when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_APGAR_1_minute then value_numeric end) "Birth_4_APGAR_1_minute",
max(case when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_APGAR_10_minute then value_numeric end) "Birth_4_APGAR_10_minute",
max(case when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_neonatal_resuscitation and value_coded = @yes then 1
         when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_neonatal_resuscitation and value_coded = @no then 0 end) "Birth_4_neonatal_resuscitation",
max(case when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_macerated_fetus and value_coded = @yes then 1 
         when obs_group_id = Birth_4_obs_group_id and concept_id = @Birth_macerated_fetus and value_coded = @yes then 0 end) "Birth_4_macerated_fetus"         
from temp_obs o
inner join temp_delivery t on o.person_id = t.patient_id
group by encounter_id;

create index temp_obs_collated_ei on temp_obs_collated(encounter_id);

update temp_delivery t 
inner join temp_obs_collated o on o.encounter_id = t.encounter_id
set t.Birth_1_APGAR_1_minute = o.Birth_1_APGAR_1_minute,
	t.Birth_1_APGAR_10_minute = o.Birth_1_APGAR_10_minute,
	t.Birth_1_APGAR_5_minute = o.Birth_1_APGAR_5_minute,
	t.Birth_1_macerated_fetus = o.Birth_1_macerated_fetus,
	t.Birth_1_neonatal_resuscitation = o.Birth_1_neonatal_resuscitation,
	t.Birth_1_outcome = o.Birth_1_outcome,
	t.Birth_1_weight = o.Birth_1_weight,
	t.Birth_2_APGAR_1_minute = o.Birth_2_APGAR_1_minute,
	t.Birth_2_APGAR_10_minute = o.Birth_2_APGAR_10_minute,
	t.Birth_2_APGAR_5_minute = o.Birth_2_APGAR_5_minute,
	t.Birth_2_macerated_fetus = o.Birth_2_macerated_fetus,
	t.Birth_2_neonatal_resuscitation = o.Birth_2_neonatal_resuscitation,
	t.Birth_2_outcome = o.Birth_2_outcome,
	t.Birth_2_weight = o.Birth_2_weight,
	t.Birth_3_APGAR_1_minute = o.Birth_3_APGAR_1_minute,
	t.Birth_3_APGAR_10_minute = o.Birth_3_APGAR_10_minute,
	t.Birth_3_APGAR_5_minute = o.Birth_3_APGAR_5_minute,
	t.Birth_3_macerated_fetus = o.Birth_3_macerated_fetus,
	t.Birth_3_neonatal_resuscitation = o.Birth_3_neonatal_resuscitation,
	t.Birth_3_outcome = o.Birth_3_outcome,
	t.Birth_3_weight = o.Birth_3_weight,
	t.Birth_4_APGAR_1_minute = o.Birth_4_APGAR_1_minute,
	t.Birth_4_APGAR_10_minute = o.Birth_4_APGAR_10_minute,
	t.Birth_4_APGAR_5_minute = o.Birth_4_APGAR_5_minute,
	t.Birth_4_macerated_fetus = o.Birth_4_macerated_fetus,
	t.Birth_4_neonatal_resuscitation = o.Birth_4_neonatal_resuscitation,
	t.Birth_4_outcome = o.Birth_4_outcome,
	t.Birth_4_weight = o.Birth_4_weight;

-- newborn details and disposition info
set @number_prenatal_visits = concept_from_mapping('CIEL','1590');
set @referred_by = concept_from_mapping('PIH','10635');
set @nutrition_newborn_counseling = concept_from_mapping('CIEL','161651');
set @family_planning_after_delivery = concept_from_mapping('PIH','13564');
set @disposition = concept_from_mapping('PIH','8620');
set @disposition_comment = concept_from_mapping('PIH','DISPOSITION COMMENTS');
set @return_visit_date = concept_from_mapping('PIH','5096');

drop temporary table if exists temp_obs_collated;
create temporary table temp_obs_collated 
select encounter_id,
max(case when concept_id = @number_prenatal_visits then value_numeric end) "number_prenatal_visits",
group_concat(case when concept_id = @referred_by then concept_name(value_coded, @locale) end separator ' | ') "referred_by",
max(case when concept_id = @referred_by and value_coded = @other then comments end) "referred_by_other_details",
max(case when concept_id = @nutrition_newborn_counseling and value_coded = @yes then 1
		 when concept_id = @nutrition_newborn_counseling and value_coded = @no then 0 end) "nutrition_newborn_counseling",
max(case when concept_id = @family_planning_after_delivery and value_coded = @yes then 1
		 when concept_id = @family_planning_after_delivery and value_coded = @no then 0 end) "family_planning_after_delivery",
max(case when concept_id = @disposition then concept_name(value_coded, @locale) end) "disposition",
max(case when concept_id = @disposition_comment then value_text end) "disposition_comment",
max(case when concept_id = @return_visit_date then value_datetime end) "return_visit_date"
from temp_obs o
group by encounter_id;

update temp_delivery t 
inner join temp_obs_collated o on o.encounter_id = t.encounter_id
set t.number_prenatal_visits = o.number_prenatal_visits,
	t.referred_by = o.referred_by,
	t.referred_by_other_details = o.referred_by_other_details,
	t.nutrition_newborn_counseling = o.nutrition_newborn_counseling,
	t.family_planning_after_delivery = o.family_planning_after_delivery,
	t.disposition = o.disposition,	
	t.disposition_comment = o.disposition_comment,
	t.return_visit_date = o.return_visit_date;


-- diagnosis information
drop temporary table if exists temp_dx;
CREATE TEMPORARY TABLE temp_dx
SELECT 	t.encounter_id,
		obs_group_id,
		obs_id,
		concept_id,
		value_coded
from temp_delivery t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.voided = 0
	and o.concept_id in (concept_from_mapping('PIH','7539'), concept_from_mapping('PIH','3064'),  concept_from_mapping('PIH','1379'),concept_from_mapping('PIH','7537')) 
;

create index temp_dx_obs_id on temp_dx(obs_id);

drop temporary table if exists temp_dx_dup;
CREATE TEMPORARY TABLE temp_dx_dup
SELECT * from temp_dx;

create index temp_dx_dup_obs_id on temp_dx_dup (obs_id);
create index temp_dx_dup_ci1 on temp_dx_dup (obs_group_id,concept_id);
create index temp_dx_dup_ci2 on temp_dx_dup (encounter_id, concept_id);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 0)
set diagnosis_1_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_1_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_1 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_1_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_1_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_1_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_1_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0)
;

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 1)
set diagnosis_2_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_2_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_2 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_2_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_2_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_2_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_2_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 2)
set diagnosis_3_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_3_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_3 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_3_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_3_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_3_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_3_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 3)
set diagnosis_4_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_4_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_4 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_4_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_4_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_4_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_4_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 4)
set diagnosis_5_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_5_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_5 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_5_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_5_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_5_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_5_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 5)
set diagnosis_6_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_6_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_6 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_6_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_6_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_6_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_6_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 6)
set diagnosis_7_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_7_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_7 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_7_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_7_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_7_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_7_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 7)
set diagnosis_8_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_8_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_8 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_8_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_8_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_8_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_8_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 8)
set diagnosis_9_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_9_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_9 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_9_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_9_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_9_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_9_primary = if(value_coded = concept_from_mapping('PIH','7534'),1, 0);

update temp_delivery t 
inner join temp_dx tdx on tdx.obs_id = 
	(select obs_id from temp_dx_dup tdd
	where tdd.encounter_id = t.encounter_id
	and tdd.concept_id = concept_from_mapping('PIH','7539') 
	order by tdd.obs_id limit 1 offset 9)
set diagnosis_10_obs_group_id = tdx.obs_id;	
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_10_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','3064')
set t.diagnosis_10 = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_10_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','1379')
set t.diagnosis_10_confirmed = concept_name(tdd.value_coded,@locale)
;
update temp_delivery t
inner join temp_dx_dup tdd on tdd.obs_group_id = t.diagnosis_10_obs_group_id and tdd.concept_id =  concept_from_mapping('PIH','7537')
set t.diagnosis_10_primary = if(value_coded = concept_from_mapping('PIH','7534'),concept_name(concept_from_mapping('PIH','YES'),@locale), concept_name(concept_from_mapping('PIH','NO'),@locale))
;

-- select final output
SELECT 
dossierId,
zlemrid,
loc_registered,
concat(@partition, '-', mch_program_id),
encounter_datetime,
encounter_location,
encounter_type,
date_entered,
provider,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',encounter_id),encounter_id) "encounter_id",
delivery_datetime,
partogram_completed,
dystocia,
prolapsed_cord,
Postpartum_hemorrhage,
Intrapartum_hemorrhage,
Placental_abruption,
Placenta_praevia,
Rupture_of_uterus,
Other_hemorrhage,
Other_hemorrhage_details,
late_cord_clamping,
placenta_delivery,
AMTSL,
Placenta_completeness,
Intact_membranes,
Retained_placenta,
Perineal_laceration,
Perineal_suture,
Episiotomy,
Postpartum_blood_loss,
Transfusion,
maternal_delivery_type_deprecated,
Caesarean_hysterectomy,
C_section_with_tubal_ligation,
baby_Malpresentation_of_fetus,
baby_Cephalopelvic_disproportion,
baby_Extreme_premature,
baby_Very_premature,
baby_Moderate_to_late_preterm,
baby_Respiratory_distress,
baby_Birth_asphyxia,
baby_Acute_fetal_distress,
baby_Intrauterine_growth_retardation,
baby_Congenital_malformation,
baby_Meconium_aspiration,
mom_Premature_rupture_of_membranes,
mom_Chorioamnionitis,
mom_Placental_abnormality,
mom_Hypertension,
mom_Severe_pre_eclampsia,
mom_Eclampsia,
mom_Acute_pulmonary_edema,
mom_Puerperal_infection,
mom_Victim_of_GBV,
mom_Herpes_simplex,
mom_Syphilis,
mom_Other_STI,
mom_Other_finding,
mom_Other_finding_details,
Mental_health_assessment,
Birth_1_outcome,
Birth_1_weight,
Birth_1_APGAR_5_minute,
Birth_1_APGAR_1_minute,
Birth_1_APGAR_10_minute,
Birth_1_neonatal_resuscitation,
Birth_1_macerated_fetus,
Birth_2_outcome,
Birth_2_weight,
Birth_2_APGAR_5_minute,
Birth_2_APGAR_1_minute,
Birth_2_APGAR_10_minute,
Birth_2_neonatal_resuscitation,
Birth_2_macerated_fetus,
Birth_3_outcome,
Birth_3_weight,
Birth_3_APGAR_5_minute,
Birth_3_APGAR_1_minute,
Birth_3_APGAR_10_minute,
Birth_3_neonatal_resuscitation,
Birth_3_macerated_fetus,
Birth_4_outcome,
Birth_4_weight,
Birth_4_APGAR_5_minute,
Birth_4_APGAR_1_minute,
Birth_4_APGAR_10_minute,
Birth_4_neonatal_resuscitation,
Birth_4_macerated_fetus,
number_prenatal_visits,
referred_by,
referred_by_other_details,
nutrition_newborn_counseling,
family_planning_after_delivery,
diagnosis_1,
diagnosis_1_confirmed,
diagnosis_1_primary,
diagnosis_2,
diagnosis_2_confirmed,
diagnosis_2_primary,
diagnosis_3,
diagnosis_3_confirmed,
diagnosis_3_primary,
diagnosis_4,
diagnosis_4_confirmed,
diagnosis_4_primary,
diagnosis_5,
diagnosis_5_confirmed,
diagnosis_5_primary,
diagnosis_6,
diagnosis_6_confirmed,
diagnosis_6_primary,
diagnosis_7,
diagnosis_7_confirmed,
diagnosis_7_primary,
diagnosis_8,
diagnosis_8_confirmed,
diagnosis_8_primary,
diagnosis_9,
diagnosis_9_confirmed,
diagnosis_9_primary,
diagnosis_10,
diagnosis_10_confirmed,
diagnosis_10_primary,
disposition,
disposition_comment,
return_visit_date
from temp_delivery ;
