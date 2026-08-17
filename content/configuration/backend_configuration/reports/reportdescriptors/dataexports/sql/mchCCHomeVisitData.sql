SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

-- set @startDate = '2020-03-01';
-- set @endDate = '2020-05-30';

set @prenatal_homeasess_encounter_type = (select encounter_type_id from encounter_type where uuid = '91DDF969-A2D4-4603-B979-F2D6F777F4AF');
set @pediatric_homeasess_encounter_type = (select encounter_type_id from encounter_type where uuid = '0CF4717A-479F-4349-AE6F-8602E2AA41D3');
set @postnatal_homeasess_encounter_type = (select encounter_type_id from encounter_type where uuid = '0E7160DF-2DD1-4728-B951-641BBE4136B8');
set @mat_followup_homeasess_encounter_type = (select encounter_type_id from encounter_type where uuid = '690670E2-A0CC-452B-854D-B95E2EAB75C9');

set @systolic_bp = concept_from_mapping('CIEL', '5085');
set @diastolic_bp = concept_from_mapping('CIEL', '5086');
set @temp_c = concept_from_mapping('CIEL', '5088');
set @heart_rate = concept_from_mapping('CIEL', '5087');
set @respiratory_rate = concept_from_mapping('CIEL', '5242');
set @weight = concept_from_mapping('CIEL', '5089');
set @height = concept_from_mapping('CIEL', '5090');
set @head_circumference = concept_from_mapping('CIEL', '5314');
set @MUAC = concept_from_mapping('CIEL', '160908');

set @number_of_meals = concept_from_mapping('CIEL', '165591');
set @symptom_present = concept_from_mapping('PIH', '1293'); 
set @referred_to_hospital = concept_from_mapping('CIEL', '1788');
set @referral_emergency = concept_from_mapping('PIH','7813');
set @malnutrition_referral_date = concept_from_mapping('PIH', '12731');
set @pediatric_vaccination_referral = concept_from_mapping('PIH', '12836');
set @other_family_member_referred = concept_from_mapping('PIH', '12745');
set @counseling_pregnancy_danger_signs = concept_from_mapping('CIEL', '164481');
set @mental_health_referral_reason = concept_from_mapping('PIH', '12746');
set @tetanus_vaccination_referral = concept_from_mapping('PIH', '12747');
set @method_family_planning = concept_from_mapping('CIEL', '374');
set @return_visit_date = concept_from_mapping('CIEL', '5096');
set @clinical_comments = concept_from_mapping('CIEL', '159395');

set @referral_construct = concept_from_mapping('PIH', '12837');
set @type_of_referral = concept_from_mapping('PIH', '1272');
set @fulfillment_status = concept_from_mapping('PIH', '12846');
set @general_referral = concept_from_mapping('PIH', '2070');
set @mental_health_referral = concept_from_mapping('PIH', '5489');
set @fam_member_referral = concept_from_mapping('PIH', '6441');
set @tetanus_vaccine_referral = concept_from_mapping('PIH', '12747');
set @ped_vaccine_referral = concept_from_mapping('PIH', '12836');
set @malnutrition_referral = concept_from_mapping('PIH', '2234');
set @referral_comments = concept_from_mapping('CIEL', '161011');

DROP TEMPORARY TABLE IF EXISTS temp_j9_mother_home_visit;

create temporary table temp_j9_mother_home_visit
(
encounter_id int(11),
encounter_type varchar(50),
patient_id int(11),
encounter_date datetime,
systolic_bp int(11),
diastolic_bp int(11),
temp_c double,
heart_rate int(11),
respiratory_rate int(11),
weight_in_grams double,
height_in_cm double,
head_circumference  double,
MUAC text(50),
symptom_present text,
referred_to_hospital text(50),
referral_emergency text(50),
other_family_member_referred varchar(50),
counseling_pregnancy_danger_signs text,
family_planning_methods text,
mental_health_referral_reason text,
tetanus_vaccination_referral varchar(50),
malnutrition_referral_date datetime,
pediatric_vaccination_referral text,
meals_per_day int,
return_visit_date datetime,
clinical_comments text,
general_referral_actions  varchar(255),
general_referral_comments varchar(255),
general_referral_completed_date datetime,
general_referral_actor  varchar(255),
mental_health_referral_actions  varchar(255),
mental_health_referral_comments varchar(255),
mental_health_referral_completed_date datetime,
mental_health_referral_actor  varchar(255),
family_member_referral_actions  varchar(255),
family_member_referral_comments varchar(255),
family_member_referral_completed_date datetime,
family_member_referral_actor  varchar(255),
tetanus_vaccination_referral_actions  varchar(255),
tetanus_vaccination_referral_comments varchar(255),
tetanus_vaccination_referral_completed_date datetime,
tetanus_vaccination_referral_actor  varchar(255),
pediatric_vaccination_referral_actions  varchar(255),
pediatric_vaccination_referral_comments varchar(255),
pediatric_vaccination_referral_completed_date datetime,
pediatric_vaccination_referral_actor  varchar(255),
malnutrition_referral_actions  varchar(255),
malnutrition_referral_comments varchar(255),
malnutrition_referral_completed_date datetime,
malnutrition_referral_actor  varchar(255)
);


insert into temp_j9_mother_home_visit (encounter_id, encounter_type, patient_id, encounter_date)
select encounter_id, name,patient_id, date(encounter_datetime) from encounter e
inner join encounter_type et on et.encounter_type_id = e.encounter_type
where encounter_type in (@prenatal_homeasess_encounter_type, @pediatric_homeasess_encounter_type, @postnatal_homeasess_encounter_type,@mat_followup_homeasess_encounter_type) 
and voided = 0
-- filter by date
and date(encounter_datetime) >=  date(@startDate)
and date(encounter_datetime) <=  date(@endDate);


-- update vital signs
update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @systolic_bp and voided = 0
set tj9mhv.systolic_bp = o.value_numeric,
	tj9mhv.diastolic_bp = (select value_numeric from obs where concept_id = @diastolic_bp and voided = 0 and encounter_id = tj9mhv.encounter_id),
    tj9mhv.temp_c = (select value_numeric from obs where concept_id = @temp_c and voided = 0 and encounter_id = tj9mhv.encounter_id),
    tj9mhv.heart_rate = (select value_numeric from obs where concept_id = @heart_rate and voided = 0 and encounter_id = tj9mhv.encounter_id),
	tj9mhv.respiratory_rate = (select value_numeric from obs where concept_id = @respiratory_rate and voided = 0 and encounter_id = tj9mhv.encounter_id),
 	tj9mhv.weight_in_grams = (select value_numeric from obs where concept_id = @weight and voided = 0 and encounter_id = tj9mhv.encounter_id),
  tj9mhv.height_in_cm = (select value_numeric from obs where concept_id = @height and voided = 0 and encounter_id = tj9mhv.encounter_id),
  tj9mhv.head_circumference = (select value_numeric from obs where concept_id = @head_circumference and voided = 0 and encounter_id = tj9mhv.encounter_id),
  tj9mhv.MUAC = (select concept_name(value_coded,'fr') from obs where concept_id = @MUAC and voided = 0 and encounter_id = tj9mhv.encounter_id)
  ;

-- SYMPTOM PRESENT
update temp_j9_mother_home_visit tj9mhv
left join
(
select o.encounter_id encounterid, group_concat(name separator ' | ') symptom_present from obs o join concept_name cn on o.voided = 0 and cn.concept_id = o.value_coded and cn.voided = 0 and o.concept_id =
@symptom_present and cn.locale = "fr" and concept_name_type = "FULLY_SPECIFIED" group by o.encounter_id
) o on o.encounterid = tj9mhv.encounter_id
set tj9mhv.symptom_present = o.symptom_present;


update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @referred_to_hospital and voided = 0
set
-- referred_to_hospital Required field
	tj9mhv.referred_to_hospital = concept_name(o.value_coded, 'fr');


update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @referral_emergency and voided = 0
set
-- referral_emergency
    tj9mhv.referral_emergency = concept_name(o.value_coded,'fr');


update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @other_family_member_referred and voided = 0
set
-- Other_family_member_referred_to_hospital
	tj9mhv.other_family_member_referred =  concept_name(o.value_coded,'fr');
  
-- malnutrition referral date  
update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @malnutrition_referral_date and voided = 0
set
-- malnutrition date
	tj9mhv.malnutrition_referral_date =  o.value_datetime;
  
-- pediatric vaccination referral   
update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @pediatric_vaccination_referral and voided = 0
set
-- pediatriv vaccination
	tj9mhv.pediatric_vaccination_referral =  concept_name(o.value_coded,'fr');
   
-- Counseling, danger signs of pregnancy
update temp_j9_mother_home_visit tj9mhv
left join
(
select o.encounter_id encounterid, group_concat(name separator ' | ') counseling_pregnancy_danger_signs from obs o join concept_name cn on
o.voided = 0 and cn.concept_id = o.value_coded and cn.voided = 0 and o.concept_id =
@counseling_pregnancy_danger_signs and cn.locale = "fr" and concept_name_type = "FULLY_SPECIFIED" group by o.encounter_id
) o on o.encounterid = tj9mhv.encounter_id
set tj9mhv.counseling_pregnancy_danger_signs = o.counseling_pregnancy_danger_signs;

-- family planning methods
update temp_j9_mother_home_visit tj9mhv
left join
(
select o.encounter_id encounterid, group_concat(name separator ' | ') method_of_family_planning from obs o join concept_name cn on
o.voided = 0 and cn.concept_id = o.value_coded and cn.voided = 0 and o.concept_id =
@method_family_planning and cn.locale = "fr" and concept_name_type = "FULLY_SPECIFIED" group by o.encounter_id
) o on o.encounterid = tj9mhv.encounter_id
set tj9mhv.family_planning_methods = o.method_of_family_planning;



-- Reason for mental health referral
update temp_j9_mother_home_visit tj9mhv
left join
(
select o.encounter_id encounterid, group_concat(name separator ' | ') mental_health_referral_reason from obs o join concept_name cn on
o.voided = 0 and cn.concept_id = o.value_coded and cn.voided = 0 and o.concept_id =
@mental_health_referral_reason and cn.locale = "fr" and concept_name_type = "FULLY_SPECIFIED" group by o.encounter_id
) o on o.encounterid = tj9mhv.encounter_id
set tj9mhv.mental_health_referral_reason = o.mental_health_referral_reason;



update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @tetanus_vaccination_referral and voided = 0
set
-- tetanus vaccination referral
	tj9mhv.tetanus_vaccination_referral = concept_name(o.value_coded,'fr');

update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @number_of_meals and voided = 0
set
-- number of meals
	tj9mhv.meals_per_day = o.value_numeric;

update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @return_visit_date and voided = 0
set
-- return visit date
	tj9mhv.return_visit_date = o.obs_datetime;

update temp_j9_mother_home_visit tj9mhv
left join obs o on tj9mhv.encounter_id = o.encounter_id and o.concept_id = @clinical_comments and voided = 0
set
-- clinical comments
	tj9mhv.clinical_comments = o.value_text;

-- general referral
update temp_j9_mother_home_visit tj9mhv
 inner join obs ref_construct on  tj9mhv.encounter_id = ref_construct.encounter_id and ref_construct.concept_id = @referral_construct and ref_construct.voided = 0
  inner join obs gr on gr.obs_group_id = ref_construct.obs_id and gr.concept_id = @type_of_referral 
    and gr.value_coded = @general_referral and gr.voided = 0
left outer join obs fs on fs.obs_group_id = ref_construct.obs_id and fs.concept_id = @fulfillment_status and fs.voided = 0
left outer join obs rc on rc.obs_group_id = ref_construct.obs_id and rc.concept_id = @referral_comments and rc.voided = 0
set tj9mhv.general_referral_actions = concept_name(fs.value_coded, 'fr'),
    tj9mhv.general_referral_comments = rc.value_text,
    tj9mhv.general_referral_completed_date = fs.obs_datetime
--    tj9mhv.general_referral_actor
;

-- mh referral
update temp_j9_mother_home_visit tj9mhv
 inner join obs ref_construct on  tj9mhv.encounter_id = ref_construct.encounter_id and ref_construct.concept_id = @referral_construct and ref_construct.voided = 0
  inner join obs mhr on mhr.obs_group_id = ref_construct.obs_id and mhr.concept_id = @type_of_referral 
    and mhr.value_coded = @mental_health_referral and mhr.voided = 0
left outer join obs fs on fs.obs_group_id = ref_construct.obs_id and fs.concept_id = @fulfillment_status and fs.voided = 0
left outer join obs rc on rc.obs_group_id = ref_construct.obs_id and rc.concept_id = @referral_comments and rc.voided = 0
set tj9mhv.mental_health_referral_actions = concept_name(fs.value_coded, 'fr'),
    tj9mhv.mental_health_referral_comments = rc.value_text,
    tj9mhv.mental_health_referral_completed_date = fs.obs_datetime
--    tj9mhv.general_referral_actor
;

-- family member referral
update temp_j9_mother_home_visit tj9fmv
 inner join obs ref_construct on  tj9fmv.encounter_id = ref_construct.encounter_id and ref_construct.concept_id = @referral_construct and ref_construct.voided = 0
  inner join obs fmr on fmr.obs_group_id = ref_construct.obs_id and fmr.concept_id = @type_of_referral 
    and fmr.value_coded = @fam_member_referral and fmr.voided = 0
left outer join obs fs on fs.obs_group_id = ref_construct.obs_id and fs.concept_id = @fulfillment_status and fs.voided = 0
left outer join obs rc on rc.obs_group_id = ref_construct.obs_id and rc.concept_id = @referral_comments and rc.voided = 0
set tj9fmv.family_member_referral_actions = concept_name(fs.value_coded, 'fr'),
    tj9fmv.family_member_referral_comments = rc.value_text,
    tj9fmv.family_member_referral_completed_date = fs.obs_datetime
--    tj9fmv.general_referral_actor
;

-- tetanus vaccine referral
update temp_j9_mother_home_visit tj9tvv
 inner join obs ref_construct on  tj9tvv.encounter_id = ref_construct.encounter_id and ref_construct.concept_id = @referral_construct and ref_construct.voided = 0
  inner join obs tvr on tvr.obs_group_id = ref_construct.obs_id and tvr.concept_id = @type_of_referral 
    and tvr.value_coded = @tetanus_vaccine_referral and tvr.voided = 0
left outer join obs fs on fs.obs_group_id = ref_construct.obs_id and fs.concept_id = @fulfillment_status and fs.voided = 0
left outer join obs rc on rc.obs_group_id = ref_construct.obs_id and rc.concept_id = @referral_comments and rc.voided = 0
set tj9tvv.tetanus_vaccination_referral_actions = concept_name(fs.value_coded, 'fr'),
    tj9tvv.tetanus_vaccination_referral_comments = rc.value_text,
    tj9tvv.tetanus_vaccination_referral_completed_date = fs.obs_datetime
--    tj9tvv.general_referral_actor
;


-- pediatric vaccine referral
update temp_j9_mother_home_visit tj9pvv
 inner join obs ref_construct on  tj9pvv.encounter_id = ref_construct.encounter_id and ref_construct.concept_id = @referral_construct and ref_construct.voided = 0
  inner join obs pvr on pvr.obs_group_id = ref_construct.obs_id and pvr.concept_id = @type_of_referral 
    and pvr.value_coded = @ped_vaccine_referral and pvr.voided = 0
left outer join obs fs on fs.obs_group_id = ref_construct.obs_id and fs.concept_id = @fulfillment_status and fs.voided = 0
left outer join obs rc on rc.obs_group_id = ref_construct.obs_id and rc.concept_id = @referral_comments and rc.voided = 0
set tj9pvv.pediatric_vaccination_referral_actions = concept_name(fs.value_coded, 'fr'),
    tj9pvv.pediatric_vaccination_referral_comments = rc.value_text,
    tj9pvv.pediatric_vaccination_referral_completed_date = fs.obs_datetime
--    tj9pvv.general_referral_actor
;


-- malnutrition referral
update temp_j9_mother_home_visit tj9malnutrition_v
 inner join obs ref_construct on  tj9malnutrition_v.encounter_id = ref_construct.encounter_id and ref_construct.concept_id = @referral_construct and ref_construct.voided = 0
  inner join obs malnutrition_r on malnutrition_r.obs_group_id = ref_construct.obs_id and malnutrition_r.concept_id = @type_of_referral 
    and malnutrition_r.value_coded = @malnutrition_referral and malnutrition_r.voided = 0
left outer join obs fs on fs.obs_group_id = ref_construct.obs_id and fs.concept_id = @fulfillment_status and fs.voided = 0
left outer join obs rc on rc.obs_group_id = ref_construct.obs_id and rc.concept_id = @referral_comments and rc.voided = 0
set tj9malnutrition_v.malnutrition_referral_actions = concept_name(fs.value_coded, 'fr'),
    tj9malnutrition_v.malnutrition_referral_comments = rc.value_text,
    tj9malnutrition_v.malnutrition_referral_completed_date = fs.obs_datetime
--    tj9malnutrition_v.general_referral_actor
;

-- select * from temp_j9_mother_home_visit;

select
		patient_id,
        encounter_id,
        zlemr(patient_id) emr_id,
        dosId(patient_id) dossier_id,
        date(encounter_date) encounter_date,
        given_name,
        family_name,
        country,
        department,
        commune,
        section_communal,
        locality,
        street_landmark,
        birthdate_estimated,
    encounter_type,
		systolic_bp,
		diastolic_bp,
		temp_c,
		heart_rate,
		respiratory_rate,
    weight_in_grams,
    height_in_cm,
    head_circumference,
    MUAC, 
    meals_per_day, 
		symptom_present,
 		counseling_pregnancy_danger_signs,
    family_planning_methods 
 		return_visit_date,
		clinical_comments

  	referred_to_hospital,
 		referral_emergency,
    general_referral_actions,
    general_referral_comments,
    general_referral_completed_date,
    general_referral_actor,
    
    malnutrition_referral_date, 
    malnutrition_referral_actions,
    malnutrition_referral_comments,
    malnutrition_referral_completed_date,
    malnutrition_referral_actor,
    
    mental_health_referral_reason,
    mental_health_referral_actions,
    mental_health_referral_comments,
    mental_health_referral_completed_date,
    mental_health_referral_actor,
    
    other_family_member_referred,
    family_member_referral_actions,
    family_member_referral_comments,
    family_member_referral_completed_date,
    family_member_referral_actor,
            
    tetanus_vaccination_referral,
    tetanus_vaccination_referral_actions,
    tetanus_vaccination_referral_comments,
    tetanus_vaccination_referral_completed_date,
    tetanus_vaccination_referral_actor,  
                
    pediatric_vaccination_referral,
    pediatric_vaccination_referral_actions,
    pediatric_vaccination_referral_comments,
    pediatric_vaccination_referral_completed_date,
    pediatric_vaccination_referral_actor

from temp_j9_mother_home_visit inner join current_name_address on person_id = patient_id order by patient_id, encounter_date
;
