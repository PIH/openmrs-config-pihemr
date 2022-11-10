#set @startDate='2022-11-01';
#set @endDate='2022-11-08';

set sql_safe_updates = 0;

drop TEMPORARY TABLE IF EXISTS temp_obs_join;
drop TEMPORARY TABLE IF EXISTS temp_ncd_section;

select patient_identifier_type_id INTO @zlId FROM patient_identifier_type where name = "ZL EMR ID";
select person_attribute_type_id INTO @unknownPt FROM person_attribute_type where name = "Unknown patient";
select person_attribute_type_id INTO @testPt FROM person_attribute_type where name = "Test Patient";
select encounter_type_id INTO @NCDInitEnc FROM encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171'; 
select name INTO @NCDInitEncName FROM encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171'; 
select encounter_type_id INTO @NCDFollowEnc FROM encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';
select name INTO @NCDFollowEncName FROM encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';
select name INTO @vitEncName FROM encounter_type where uuid = '4fb47712-34a6-40d2-8ed3-e153abbd25b7';
select encounter_type_id INTO @labResultEnc FROM encounter_type where uuid = '4d77916a-0620-11e5-a6c0-1697f925ec7b';

create temporary table temp_ncd_section
(
patient_id int,
encounter_id int,
encounter_datetime datetime,
visit_id int,
encounter_location_id int,
encounter_type varchar(255),
emr_id varchar(50),
loc_registered varchar(255),
location_id int,
unknown_patient varchar(50),
visit_date datetime,
visit_type varchar(255),
gender varchar(50),
age_at_enc double,
department varchar(255),
commune varchar(255),
section varchar(255),
locality varchar(255),
street_landmark varchar(255),
provider varchar(255),
encounter_provider int,
provider_person_id int,
patient_program_id int,
enrolled_in_program datetime,
patient_outcome_concept_id int,
patient_state varchar(50),
pws_concept_id int,
program_state varchar(255),
program_outcome varchar(255),
encounter_location varchar(255),
person_id int,
known_chronic_disease_before_referral varchar(50),
prior_treatment_for_chronic_disease varchar(50),
chronic_disease_controlled_during_initial_visit varchar(50),
disease_category text,
comments text,
waist_circumference double,
hip_size double,
hypertension_stage text,
hypertension_comments text,
diabetes_mellitus text,
serum_glucose double,
fasting_blood_glucose_test varchar (50),
fasting_blood_glucose double,
managing_diabetic_foot_care text,
diabetes_comment text,
probably_asthma varchar(50),
respiratory_diagnosis text,
bronchiectasis varchar(50),
copd varchar(50),
copd_grade varchar(255),
commorbidities text,
inhaler_training varchar (50),
pulmonary_comment text,
categories_of_heart_failure text,
nyha_class text,
fluid_status text,
cardiomyopathy text,
heart_failure_improbable varchar(50),
heart_remarks text,
left_ventricle_systolic_function varchar(255),
right_ventricle_dimension varchar(255),
mitral_valve_finding varchar(255),
pericardium_findings varchar(255),
inferior_vena_cava_findings varchar(255),
quality varchar(255),
additional_echocardiogram_comments text,
other_disease_category text,
other_non_coded_diagnosis text,
medicine_past_two_days varchar(50),
reason_poor_compliance text,
cardiovascular_medication text,
respiratory_medication text,
endocrine_medication text,
other_medication text,
Weight_kg double,
Height_cm double,
Systolic_BP double,
Diastolic_BP double,
puffs_week_salbutamol int,
Number_seizures_since_last_visit int,
Next_NCD_appointment datetime,
date_of_admission datetime,
tobacco_product_type varchar(30),
transport_to_clinic varchar(30),
patient_has_income varchar(10),
clinical_impression_summary text
);

insert into temp_ncd_section (patient_id, encounter_id, visit_id, encounter_location_id, encounter_type, encounter_datetime,visit_type)
select patient_id, encounter_id, visit_id, location_id, group_concat(encounter_type), encounter_datetime, encounterName(encounter_type)from encounter where voided = 0 and encounter_type
in (@NCDInitEnc, @NCDFollowEnc)
AND patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = "true" AND person_attribute_type_id = @testPt
                         AND voided = 0)
AND visit_id IS NOT NULL
AND DATE(encounter_datetime) >=  date(@startDate)
AND DATE(encounter_datetime) <=  date(@endDate)
GROUP BY visit_id;

-- Most recent ZL EMR ID    
update temp_ncd_section tns set tns.emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));    
-- location registered
update temp_ncd_section tns set tns.loc_registered = loc_registered(tns.patient_id);
-- gender
update temp_ncd_section tns set tns.gender = gender(tns.patient_id);
-- age at encounter
update temp_ncd_section tns set tns.age_at_enc = age_at_enc(tns.patient_id, tns.encounter_id);
-- unknown patient
update temp_ncd_section tns set tns.unknown_patient = unknown_patient(tns.patient_id);

update temp_ncd_section tns
--  Most recent address
left outer join (select person_id, state_province, city_village, address3, address1, address2 from person_address where voided = 0 order by date_created desc) pa on tns.patient_id = pa.person_id
set tns.department = pa.state_province,
	tns.commune = pa.city_village,
	tns.section = pa.address3,
	tns.locality = pa.address1,
	tns.street_landmark = pa.address2;

update temp_ncd_section tns
--  Provider Name
INNER JOIN encounter_provider ep ON ep.encounter_id = tns.encounter_id AND ep.voided = 0
set tns.encounter_provider = ep.provider_id;

update temp_ncd_section tns
--  Provider Person ID
INNER JOIN provider pv ON pv.provider_id = tns.encounter_provider
set tns.provider_person_id = pv.person_id;

update temp_ncd_section tns
-- Provider
inner join (select person_id, given_name, family_name from person_name where voided = 0 order by date_created desc) pn on tns.provider_person_id = pn.person_id
set tns.provider = concat(pn.given_name, ' ', pn.family_name);

update temp_ncd_section tns
-- UUID of NCD program and date enrolled
LEFT JOIN patient_program pp ON pp.patient_id = tns.patient_id AND pp.voided = 0 AND pp.program_id IN
      (select program_id from program where uuid = '515796ec-bf3a-11e7-abc4-cec278b6b50a')
set tns.patient_program_id = pp.patient_program_id,
    tns.patient_outcome_concept_id = pp.outcome_concept_id,
	tns.enrolled_in_program = date(pp.date_enrolled) ;

update temp_ncd_section tns
-- patient state
LEFT OUTER JOIN patient_state ps ON ps.patient_program_id = tns.patient_program_id AND ps.end_date IS NULL AND ps.voided = 0
set tns.patient_state = ps.state;

update temp_ncd_section tns
LEFT OUTER JOIN program_workflow_state pws ON pws.program_workflow_state_id = tns.patient_state AND pws.retired = 0
set tns.pws_concept_id = pws.concept_id;

update temp_ncd_section tns
LEFT OUTER JOIN concept_name cn_state ON cn_state.concept_id = tns.pws_concept_id  AND cn_state.locale = 'en' AND cn_state.locale_preferred = '1'  AND cn_state.voided = 0
set tns.program_state = cn_state.name;

-- outcome
update temp_ncd_section tns
LEFT OUTER JOIN concept_name cn_out ON cn_out.concept_id = tns.patient_outcome_concept_id AND cn_out.locale = 'en' AND cn_out.locale_preferred = '1'  AND cn_out.voided = 0
set tns.program_outcome = cn_out.name;

update temp_ncd_section tns
-- encounter_location
INNER JOIN location el ON el.location_id = tns.encounter_location_id
set tns.encounter_location = el.name;

-- The data here comes from the NCD INFORMATION section
-- re-introducing person_id so as not to re-rwite query
update temp_ncd_section tns
left join
(select encounter_id, person_id, group_concat(name) names, comments from obs o, concept_name cn
where
value_coded = cn.concept_id  and locale="en" and concept_name_type="FULLY_SPECIFIED" and cn.voided = 0 and
o.concept_id = (select concept_id from report_mapping where source="PIH" and code = "NCD category") and o.voided = 0 group by encounter_id) ncd_information
on tns.encounter_id = ncd_information.encounter_id
set tns.person_id = ncd_information.person_id,
    tns.disease_category = ncd_information.names;
    
-- other disease categories
update temp_ncd_section tns
left join obs o on tns.encounter_id = o.encounter_id and voided = 0 and value_coded = (select concept_id from report_mapping where source="PIH" and code = "OTHER")
and concept_id = (select concept_id from report_mapping where source="PIH" and code = "NCD category") 
set tns.comments = o.comments;

update temp_ncd_section tns
left join
(select name known_chronic, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Known chronic disease before referral")) before_referral on tns.encounter_id = before_referral.encounter_id
left join
(select name prior_chronic, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Known chronic disease before referral")) prior_treatment on tns.encounter_id = prior_treatment.encounter_id
left join
(select name chronic_disease, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Chronic disease controlled during initial visit"))
controlled on tns.encounter_id = controlled.encounter_id
set tns.known_chronic_disease_before_referral = before_referral.known_chronic,
     tns.prior_treatment_for_chronic_disease = prior_treatment.prior_chronic,
     tns.chronic_disease_controlled_during_initial_visit = controlled.chronic_disease;

-- The data here comes from the ADDITIONAL VITAL SIGNS and HYPERTENSION
update temp_ncd_section tns
left join obs o on o.encounter_id = tns.encounter_id and o.voided = 0 and o.concept_id = (select concept_id from report_mapping where source = "CIEL" and code =
'163080')
left join obs o1 on o1.encounter_id = tns.encounter_id and o1.voided = 0 and o1.concept_id =
(select concept_id from report_mapping where source = "CIEL" and code = '163081')
left join (select group_concat(name) hypertension, encounter_id
from concept_name cn join obs o on o.value_coded = cn.concept_id and concept_name_type="FULLY_SPECIFIED" and locale="en" and cn.voided = 0
and o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Type of hypertension diagnosis") group by encounter_id) o2 on
o2.encounter_id = tns.encounter_id
left join obs o3 on o3.encounter_id = tns.encounter_id and o3.voided = 0 and o3.concept_id =
(select concept_id from report_mapping where source = "PIH" and code = '11971')
set tns.waist_circumference = o.value_numeric,
    tns.hip_size =  o1.value_numeric,
    tns.hypertension_stage = o2.hypertension,
    tns.hypertension_comments = o3.value_text;

-- DIABETES
update temp_ncd_section tns
left join (select encounter_id, group_concat(name) diag, o.voided void from concept_name cn join obs o on
cn.concept_id = value_coded and locale = "en" and concept_name_type = "FULLY_SPECIFIED"
and value_coded in (select concept_id from report_mapping where (source = "CIEL" and code in ('142474', '142473' , '165207', '165208' , '1449', '138291'))
or (source="PIH" and code = '12227')) and o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and cn.voided = 0 and o.voided = 0 group by encounter_id) o3 on o3.encounter_id = tns.encounter_id and o3.void = 0
left join obs o4 on o4.encounter_id = tns.encounter_id and o4.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "SERUM GLUCOSE") and o4.voided = 0
left join obs o5 on o5.encounter_id = tns.encounter_id and o5.concept_id = (select concept_id from report_mapping where source = "CIEL" and code = "160912") and o5.voided = 0
left join (select group_concat(name) foot_care, encounter_id
from concept_name cn join obs o on o.value_coded = cn.concept_id and concept_name_type="FULLY_SPECIFIED" and locale="en" and cn.voided = 0
and o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Foot care classification") group by encounter_id)
o6 on o6.encounter_id = tns.encounter_id
left join obs o7 on o7.encounter_id = tns.encounter_id and o7.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Fasting for blood glucose test") and o7.voided = 0
left join obs o8 on o8.encounter_id = tns.encounter_id and o8.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "11974") and o8.voided = 0
set tns.diabetes_mellitus = o3.diag,
    tns.serum_glucose = o4.value_numeric,
    tns.fasting_blood_glucose_test = IF(o7.value_coded = 1, "Yes", "No"),
    tns.fasting_blood_glucose = o5.value_numeric,
    tns.managing_diabetic_foot_care = o6.foot_care,
    tns.diabetes_comment = o8.value_text;

-- RESPIRATORY
update temp_ncd_section tns
left join (select encounter_id, group_concat(name) asthma_class from concept_name cn join obs o on cn.concept_id = value_coded
and concept_name_type = "FULLY_SPECIFIED" and locale = "en"
and o.voided = 0 and o.concept_id = (select concept_id from report_mapping where
source = "PIH" and code = "Asthma classification") group by encounter_id) o on tns.encounter_id = o.encounter_id
left join obs o1 on tns.encounter_id = o1.encounter_id and value_coded =
(select concept_id from report_mapping where source = "CIEL" and code = '121375')
and concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o1.voided = 0
left join obs o2 on
tns.encounter_id = o2.encounter_id and o2.value_coded =
(select concept_id from report_mapping where source = "CIEL" and code = "121011")
and o2.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o2.voided = 0
left join obs o3 on
tns.encounter_id = o3.encounter_id and o3.value_coded =
(select concept_id from report_mapping where source = "CIEL" and code = "1295")
and o3.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o3.voided = 0
left join obs o4 on tns.encounter_id = o4.encounter_id and o4.voided = 0 and
o4.concept_id = (select concept_id from report_mapping where source = "PIH" and code="COPD group classification")
set tns.respiratory_diagnosis  = o.asthma_class,
     tns.probably_asthma = IF(o1.value_coded is not null, "Yes", "No"),
     tns.bronchiectasis = IF(o2.value_coded is not null, "Yes", "No"),
     tns.copd = IF(o3.value_coded is not null, "Yes", "No"),
     tns.copd_grade = (select name from concept_name where concept_id = o4.value_coded and locale = "en" and voided = 0 and concept_name_type
     = "FULLY_SPECIFIED");

-- Comorbidities
update temp_ncd_section tns
left join
(select group_concat(distinct(name)) commob, encounter_id from concept_name cn join obs o on
cn.concept_id = value_coded and o.voided = 0 and concept_name_type = "FULLY_SPECIFIED" and locale = "en" and
o.value_coded in (select concept_id from report_mapping
where source = "CIEL" and code in ('121692', '1293', '119051')) group by encounter_id) o
on tns.encounter_id = o.encounter_id
left join obs o1 on o1.voided = 0 and o1.encounter_id = tns.encounter_id and
o1.concept_id =  (select concept_id from report_mapping
where source = "PIH" and code = '7399')
left join obs o2 on o2.encounter_id = tns.encounter_id and
o2.voided = 0 and o2.concept_id = (select concept_id from report_mapping
where source = "PIH" and code = '11972')
set tns.commorbidities = o.commob,
    tns.inhaler_training = IF(o1.value_coded = 1, "Yes", "No"),
    tns.pulmonary_comment = o2.value_text
;

-- HEART FAILURE
update temp_ncd_section tns
left join
(
select group_concat(name) heart_failure_category, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS") and
value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in ('5016', '134082', '130562', '5622')) or (source = "PIH" and
code in ('3071', '12231', '4000')))  group by encounter_id
) category_of_heart_failure on category_of_heart_failure.encounter_id = tns.encounter_id
left join
(
select group_concat(name) nyha_class, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "NYHA CLASS")
group by encounter_id) nyha_classes on nyha_classes.encounter_id = tns.encounter_id
left join
(
select group_concat(name) fluid, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "PATIENTS FLUID MANAGEMENT")
group by encounter_id) fluid_statuses on fluid_statuses.encounter_id = tns.encounter_id
left join
(
select group_concat(name) cardiomyopathy, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o.value_coded in
(select concept_id from report_mapping where source = "CIEL" and code in ('113918', '163712', '142317', '139529', '5016'))
group by encounter_id) cardiomy on cardiomy.encounter_id = tns.encounter_id
left join
obs o on tns.encounter_id = o.encounter_id and o.voided = 0 and o.concept_id =
(select concept_id from report_mapping where source = "PIH" and code = '11926')
left join
obs o1 on tns.encounter_id = o1.encounter_id and o1.voided = 0 and o1.concept_id =
(select concept_id from report_mapping where source = "PIH" and code = '11973')

set tns.categories_of_heart_failure = category_of_heart_failure.heart_failure_category,
     tns.nyha_class = nyha_classes.nyha_class,
     tns.fluid_status = fluid_statuses.fluid,
     tns.cardiomyopathy = cardiomy.cardiomyopathy,
     tns.heart_failure_improbable =IF(o.value_coded = 1, "Yes", "No"),
     tns.heart_remarks = o1.value_text
     ;

-- Echocardiogram consultation
update temp_ncd_section tns
left join
(
select group_concat(name) systolic_fxn, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Left ventricle systolic function")
group by encounter_id) left_systolic on left_systolic.encounter_id = tns.encounter_id
left join
(
select group_concat(name) ventricle_dim, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Right ventricle dimension")
group by encounter_id) right_ventricle on right_ventricle.encounter_id = tns.encounter_id
left join
(
select group_concat(name) valve_findings, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MITRAL VALVE FINDINGS")
group by encounter_id) valve_finds on valve_finds.encounter_id = tns.encounter_id
left join
(
select group_concat(name) pericardium_findings, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "PERICARDIUM FINDINGS")
group by encounter_id) pericardium_finds on pericardium_finds.encounter_id = tns.encounter_id
left join
(
select group_concat(name) cava_findings, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "Inferior vena cava findings")
group by encounter_id) inferior_vena on tns.encounter_id = inferior_vena.encounter_id
left join
(
select group_concat(name) quality, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "CIEL" and code = "165253")
group by encounter_id
) quality_findings on quality_findings.encounter_id = tns.encounter_id
left join
obs o on tns.encounter_id = o.encounter_id and o.voided = 0 and o.concept_id =
(select concept_id from report_mapping where source = "PIH" and code = '3407')
set tns.left_ventricle_systolic_function = left_systolic.systolic_fxn,
	tns.right_ventricle_dimension = right_ventricle.ventricle_dim,
	tns.mitral_valve_finding =  valve_finds.valve_findings,
    tns.pericardium_findings = pericardium_finds.pericardium_findings,
    tns.inferior_vena_cava_findings = inferior_vena.cava_findings,
    tns.quality = quality_findings.quality,
    tns.additional_echocardiogram_comments = o.value_text;

-- VISIT INFORMATION and MEDICATIONS
update temp_ncd_section tns
left join
(
select group_concat(name) other_disease, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "DIAGNOSIS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in ('119624', '5622', '113504', '148203', '117441', '115115'))
or (source = "PIH" and code = '3181'))
group by encounter_id) other_category on other_category.encounter_id = tns.encounter_id
left join obs o on o.encounter_id = tns.encounter_id and o.voided = 0 and o.concept_id
= (select concept_id from report_mapping where source = "PIH" and code = "Diagnosis or problem, non-coded")
set tns.other_disease_category = other_category.other_disease,
    tns.other_non_coded_diagnosis = o.value_text
;

-- update medicine past 2 days
update temp_ncd_section tns
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "10555")
group by encounter_id) medicine_past_two_days on tns.encounter_id = medicine_past_two_days.encounter_id
set tns.medicine_past_two_days = medicine_past_two_days.medicine;

-- update adherence info
update temp_ncd_section tns
left join
(
select group_concat(name) adherence, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "3140")
group by encounter_id) adherence_info on tns.encounter_id = adherence_info.encounter_id
set tns.reason_poor_compliance = adherence_info.adherence;

-- update cardiovascular medicine
update temp_ncd_section tns
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MEDICATION ORDERS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in
('71617', '71138', '73602', '75634', '77676', '79766', '82734', '83936'))
or (source = "PIH" and code in ('3186', '3185', '3182', '99', '1243', '3428', '3183', '251', '250', '4061', '3190')))
group by encounter_id)cardiovascular on cardiovascular.encounter_id = tns.encounter_id
set tns.cardiovascular_medication = cardiovascular.medicine;

-- update respiratory medicine
update temp_ncd_section tns
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MEDICATION ORDERS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in
('78200', '80092'))
or (source = "PIH" and code in ('1240', '798')))
group by encounter_id) respiratory on respiratory.encounter_id = tns.encounter_id
set  tns.respiratory_medication = respiratory.medicine;

-- update endocrine medication
update temp_ncd_section tns
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MEDICATION ORDERS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in
('78082', '78068', '79652'))
or (source = "PIH" and code in ('4046', '6746', '765')))
group by encounter_id) endocrine on endocrine.encounter_id = tns.encounter_id
set     tns.endocrine_medication = endocrine.medicine;

-- update other medicine
update temp_ncd_section tns
left join
(
select group_concat(name) medicine, encounter_id from concept_name cn join obs o on cn.locale="en" and
concept_name_type="FULLY_SPECIFIED" and cn.voided=0 and o.voided = 0 and
cn.concept_id = o.value_coded and
o.concept_id = (select concept_id from report_mapping where source = "PIH" and code = "MEDICATION ORDERS")
and o.value_coded in
(select concept_id from report_mapping where (source = "CIEL" and code in
('75018', '81730'))
or (source = "PIH" and code in ('4034', '2293', '960', '95', '1244', '4057', '923')))
group by encounter_id) other_meds on other_meds.encounter_id = tns.encounter_id
set tns.other_medication = other_meds.medicine;

-- update vitals (using latest vitals encounter)
update temp_ncd_section tns
set tns.Weight_kg  = obs_value_numeric(latestEnc(tns.patient_id,@vitEncName,null),'CIEL','5089'),
    tns.Height_cm  = obs_value_numeric(latestEnc(tns.patient_id,@vitEncName,null),'CIEL','5090'),
    tns.Systolic_BP  = obs_value_numeric(latestEnc(tns.patient_id,@vitEncName,null),'CIEL','5085'),
    tns.Diastolic_BP  = obs_value_numeric(latestEnc(tns.patient_id,@vitEncName,null),'CIEL','5086');
   
   -- update remaining observations
update temp_ncd_section tns
set tns.puffs_week_salbutamol = obs_value_numeric(tns.encounter_id,'PIH','Puffs per week of relief inhaler (coded)'),
    tns.Number_seizures_since_last_visit = obs_value_numeric(tns.encounter_id,'PIH','Number of seizures since last visit'),
    tns.Next_NCD_appointment = obs_value_datetime(tns.encounter_id,'PIH','RETURN VISIT DATE')
    ;
    
-- update visit date    
update temp_ncd_section tns   
inner join encounter e on e.encounter_id = tns.encounter_id
inner join visit v on v.visit_id = e.visit_id
set tns.visit_date = v.date_started;
 
-- liberia changes
-- date of admission
update temp_ncd_section tns set date_of_admission = obs_value_datetime(tns.encounter_id, 'PIH', '12602');
-- tobacco product
update temp_ncd_section tns set tobacco_product_type = obs_value_coded_list(tns.encounter_id, 'CIEL', '159377', 'en');
-- transport to clinic 
update temp_ncd_section tns set transport_to_clinic =  obs_value_coded_list(tns.encounter_id, 'PIH', '975', 'en');
-- patient has income
update temp_ncd_section tns set patient_has_income =  obs_value_coded_list(tns.encounter_id, 'PIH', '12615', 'en');
-- clinical impression summary
update temp_ncd_section tns set clinical_impression_summary = obs_value_text(tns.encounter_id, 'CIEL', '159395');


-- final query
select
  patient_id,
  emr_id,
  loc_registered,
  unknown_patient,
  encounter_datetime,
  visit_date,
  visit_type,
  enrolled_in_program,
  program_state,
  program_outcome,
  gender,
  age_at_enc,
  department,
  commune,
  section,
  locality,
  street_landmark,
  encounter_location,
  provider,
  Weight_kg,
  Height_cm,
  ROUND(Weight_kg/((Height_cm/100)*(Height_cm/100)),1) "BMI",
  Systolic_BP,
  Diastolic_BP,
  waist_circumference,
  hip_size,
  ROUND(waist_circumference/hip_size,2) "Waist_Hip_Ratio",
  disease_category,
  comments other_disease_category,
  hypertension_stage,
  hypertension_comments,
  diabetes_mellitus,
  serum_glucose,
  fasting_blood_glucose_test,
  fasting_blood_glucose,
  managing_diabetic_foot_care,
  diabetes_comment,
  puffs_week_salbutamol,
  probably_asthma,
  respiratory_diagnosis,
  bronchiectasis,
  copd,
  copd_grade,
  commorbidities,
  inhaler_training,
  pulmonary_comment,
  Number_seizures_since_last_visit,
  categories_of_heart_failure,
  nyha_class,
  fluid_status,
  cardiomyopathy,
  heart_failure_improbable,
  heart_remarks,
  left_ventricle_systolic_function,
  right_ventricle_dimension,
  mitral_valve_finding,
  pericardium_findings,
  inferior_vena_cava_findings,
  quality,
  additional_echocardiogram_comments,
  other_disease_category ncd_other_section,
  other_non_coded_diagnosis ncd_other_section_other,
  medicine_past_two_days,
  reason_poor_compliance,
  cardiovascular_medication,
  respiratory_medication,
  endocrine_medication,
  other_medication,
  Next_NCD_appointment,
  date_of_admission,
  tobacco_product_type,
  transport_to_clinic,
  patient_has_income,
  clinical_impression_summary
from temp_ncd_section tns;