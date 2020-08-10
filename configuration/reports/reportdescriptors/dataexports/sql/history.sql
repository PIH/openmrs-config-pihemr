CALL initialize_global_metadata();

DROP TEMPORARY TABLE IF EXISTS temp_ncd_initial_referral;
DROP TEMPORARY TABLE IF EXISTS temp_ncd_initial_behavior;
DROP TEMPORARY TABLE IF EXISTS temp_ncd_pregnacy;
DROP TEMPORARY TABLE IF EXISTS temp_hist_family_plan_encounters;
DROP TEMPORARY TABLE IF EXISTS temp_hist_family_plan;
DROP TEMPORARY TABLE IF EXISTS temp_hist_hospitalisation_plan_encounters;

select concept_id  INTO @family_plan_start_date  from report_mapping where source = "CIEL" and code = "163757";
select concept_id  INTO @family_plan_end_date  from report_mapping where source = "CIEL" and code = "163758";

-- NCD Initial form referral qn
CREATE TEMPORARY TABLE IF NOT EXISTS temp_ncd_initial_referral
AS
(
SELECT
	e.encounter_id encounter_id,
    e.patient_id patient_id,
    GROUP_CONCAT(DISTINCT(internal_refer_value)) internal_refer_values,
    other_internal_institution.comments other_internal_institution,
    CONCAT(external_institution.comments, ", ", non_pih_institution.comments) external_institution,
    GROUP_CONCAT(DISTINCT(community.comm_values)) community,
    DATE(date_referral.value_datetime) date_of_referral
FROM
encounter e
-- REFERRAL
LEFT JOIN (SELECT encounter_id, value_coded, cn.name internal_refer_value FROM obs o JOIN concept_name cn ON cn.concept_id = o.value_coded AND cn.voided = 0
AND o.voided = 0 AND locale="fr" AND concept_name_type = "FULLY_SPECIFIED" AND o.concept_id =
(SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = "Type of referring service") AND value_coded IN
((SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = 165018),
(SELECT concept_id FROM report_mapping WHERE source = "PIH"  AND code = "ANTENATAL CLINIC"),
(SELECT concept_id FROM report_mapping WHERE source = "PIH"  AND code= "PRIMARY CARE CLINIC" ),
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "163558"),
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "160449"),
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "160448"),
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "165048"),
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "160473"),
(SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = "OTHER")
)) internal_refer ON e.encounter_id = internal_refer.encounter_id
LEFT JOIN obs other_internal_institution ON e.encounter_id = other_internal_institution.encounter_id AND other_internal_institution.voided = 0
AND other_internal_institution.value_coded = (SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = "OTHER")
and  other_internal_institution.concept_id = (SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = "Type of referring service")
LEFT JOIN obs external_institution ON e.encounter_id = external_institution.encounter_id AND external_institution.voided = 0 AND
external_institution.value_coded = (SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = "11956")
LEFT JOIN obs non_pih_institution ON e.encounter_id = non_pih_institution.encounter_id AND non_pih_institution.voided = 0 AND
non_pih_institution.value_coded = (SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = "Non-ZL supported site")
LEFT JOIN (SELECT o.encounter_id, o.value_coded, cn.name comm_values FROM obs o JOIN concept_name cn ON cn.concept_id = o.value_coded AND
o.voided = 0 AND cn.locale= "fr" AND cn.concept_name_type = "FULLY_SPECIFIED" AND o.value_coded IN
(
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "1555"),
(SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = "11965")
)) community ON e.encounter_id = community.encounter_id
LEFT JOIN obs date_referral ON e.patient_id = date_referral.person_id AND e.encounter_id = date_referral.encounter_id
AND date_referral.voided = 0 AND date_referral.concept_id =
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "163181")
-- Family history
WHERE e.encounter_type IN (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc, @NCDInitEnc) AND e.voided = 0
AND date(e.encounter_datetime) >= @startDate
AND date(e.encounter_datetime) <= @endDate
GROUP BY encounter_id
);

-- NCD initial form behavior qn
CREATE TEMPORARY TABLE IF NOT EXISTS temp_ncd_initial_behavior
AS
(
SELECT
e.patient_id,
e.encounter_id encounter_id,
tob_smoke.conceptname smoker,
tob_num.value_numeric packs_per_year,
sec_smoke.conceptname second_hand_smoker,
alc.conceptname alcohol_use,
ill_drugs.conceptname illegal_drugs,
current_drug_name.value_text current_drug_name
FROM
encounter e
LEFT JOIN
-- History of tobacco use
(SELECT cn.name conceptname, value_coded, encounter_id, person_id FROM obs o JOIN concept_name cn ON cn.concept_id = o.value_coded AND o.voided = 0 AND cn.voided = 0 AND
locale = "fr" AND o.concept_id =
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "163731")) tob_smoke ON tob_smoke.encounter_id = e.encounter_id AND tob_smoke.person_id = e.patient_id
LEFT JOIN
obs tob_num ON tob_num.encounter_id = e.encounter_id AND tob_num.person_id = e.patient_id AND tob_num.voided = 0 AND
tob_num.concept_id = (SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = 11949)
LEFT JOIN
-- Second hand smoke
(SELECT cn.name conceptname, value_coded, encounter_id, person_id FROM obs o JOIN concept_name cn ON cn.concept_id = o.value_coded
AND o.voided = 0 AND cn.voided = 0 AND locale="fr" AND concept_name_type="FULLY_SPECIFIED" AND
o.concept_id =
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "152721")) sec_smoke ON
sec_smoke.encounter_id = e.encounter_id AND sec_smoke.person_id = e.patient_id
LEFT JOIN
-- Alcohol
(SELECT cn.name conceptname, value_coded, encounter_id, person_id FROM obs o JOIN concept_name cn ON cn.concept_id = o.value_coded
AND o.voided = 0 AND cn.voided = 0 AND locale="fr" AND concept_name_type="FULLY_SPECIFIED" AND
o.concept_id =
(SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "159449")) alc ON alc.encounter_id = e.encounter_id AND alc.person_id = e.patient_id
LEFT JOIN
-- History of illegal drugs
(SELECT cn.name conceptname, value_coded, encounter_id, person_id FROM obs o JOIN concept_name cn ON cn.concept_id = o.value_coded
AND o.voided = 0 AND cn.voided = 0 AND locale="fr" AND concept_name_type="FULLY_SPECIFIED" AND
o.concept_id = (SELECT concept_id FROM report_mapping WHERE source = "CIEL" AND code = "162556"))
ill_drugs ON ill_drugs.encounter_id = e.encounter_id AND ill_drugs.person_id = e.patient_id
LEFT JOIN
-- drug name
obs current_drug_name ON current_drug_name.encounter_id = e.encounter_id AND current_drug_name.person_id = e.patient_id AND
current_drug_name.voided = 0 AND current_drug_name.concept_id =
(SELECT concept_id FROM report_mapping WHERE source = "PIH" AND code = 6489)
WHERE
e.encounter_type IN (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc, @NCDInitEnc) AND e.voided = 0
AND date(e.encounter_datetime) >= @startDate
AND date(e.encounter_datetime) <= @endDate
GROUP BY e.encounter_id
);


CREATE TEMPORARY TABLE temp_ncd_pregnacy
(
person_id INT,
encounter_id INT,
pregnant VARCHAR(50),
last_menstruation_date DATETIME,
estimated_delivery_date DATETIME,
currently_breast_feeding VARCHAR(50)
);
INSERT INTO temp_ncd_pregnacy (person_id, encounter_id, pregnant)
SELECT preg.person_id, preg.encounter_id,  cn.name FROM
obs preg,
concept_name cn
WHERE preg.value_coded = cn.concept_id
AND cn.concept_name_type = "FULLY_SPECIFIED" AND cn.voided = 0 AND cn.locale="fr"
AND  preg.concept_id IN (SELECT concept_id FROM report_mapping rm WHERE rm.source = "PIH" AND rm.code = "PREGNANCY STATUS")
AND encounter_id IN (SELECT encounter_id FROM encounter WHERE encounter_type IN (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc, @NCDInitEnc));

UPDATE temp_ncd_pregnacy tnp
-- estimate_delievery_date
INNER JOIN
(
SELECT encounter_id, value_datetime FROM obs WHERE voided = 0 AND concept_id =
(SELECT concept_id FROM report_mapping WHERE source="PIH" AND code="DATE OF LAST MENSTRUAL PERIOD")
) lmd ON lmd.encounter_id = tnp.encounter_id
SET tnp.last_menstruation_date = lmd.value_datetime;

UPDATE temp_ncd_pregnacy tnp
-- estimated_delivery_date
INNER JOIN
(
SELECT encounter_id, value_datetime FROM obs WHERE voided = 0 AND concept_id =
(SELECT concept_id FROM report_mapping WHERE source="CIEL" AND code="5596")
) edt ON edt.encounter_id = tnp.encounter_id
SET tnp.estimated_delivery_date = edt.value_datetime;

UPDATE temp_ncd_pregnacy tnp
-- breast feeding
INNER JOIN
(
SELECT encounter_id, name FROM obs, concept_name cn WHERE cn.concept_id = obs.value_coded AND obs.voided = 0 AND obs.concept_id =
(SELECT concept_id FROM report_mapping WHERE source="CIEL" AND code="5632")
AND cn.concept_name_type = "FULLY_SPECIFIED" AND cn.voided = 0 AND cn.locale="fr"
) breast ON breast.encounter_id = tnp.encounter_id
SET tnp.currently_breast_feeding = breast.name;


-- History family planning
CREATE TEMPORARY TABLE temp_hist_family_plan_encounters
(
encounter_id int,
patient_id int,
encounter_type int,
encounter_datetime datetime,
visit_id int
);

INSERT INTO temp_hist_family_plan_encounters (encounter_id, patient_id)
SELECT encounter_id, patient_id
from encounter
where encounter_type IN (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc, @NCDInitEnc) and voided = 0 and encounter_id in (select encounter_id from obs where concept_id = (select concept_id from
report_mapping where source = "PIH" and code="Family planning history construct"));

create temporary table temp_hist_family_plan
(
encounter_id int,
patient_id int,
concept_id int,
oral_contraception varchar(50),
oral_contraception_start_date datetime,
oral_contraception_end_date datetime,
depoprovera varchar(50),
depoprovera_start_date datetime,
depoprovera_end_date datetime,
condom varchar(50),
condom_start_date datetime,
condom_end_date datetime,
levonorgestrel varchar(50),
levonorgestrel_start_date datetime,
levonorgestrel_end_date datetime,
intrauterine_device varchar(50),
intrauterine_device_start_date datetime,
intrauterine_device_end_date datetime,
tubal_litigation varchar(50),
tubal_litigation_start_date datetime,
tubal_litigation_end_date datetime,
vasectomy varchar(50),
vasectomy_start_date datetime,
vasectomy_end_date datetime,
family_plan_other varchar(50),
family_plan_other_name varchar(255),
family_plan_other_start_date datetime,
family_plan_other_end_date datetime
);

INSERT INTO temp_hist_family_plan (encounter_id, patient_id)
(select encounter_id, patient_id from temp_hist_family_plan_encounters );

update temp_hist_family_plan set concept_id = (select concept_id from report_mapping where source = "PIH" and code = "METHOD OF FAMILY PLANNING");

update temp_hist_family_plan tnmp
left join
     obs o
ON o.value_coded = (select concept_id from report_mapping where source = "PIH" and code = "ORAL CONTRACEPTION")
and tnmp.concept_id = o.concept_id
and tnmp.encounter_id = o.encounter_id
and o.voided = 0
left join obs o1
ON o1.value_coded = (select concept_id from report_mapping where source = "CIEL" and code = "907")
and o1.concept_id = tnmp.concept_id
and tnmp.encounter_id = o1.encounter_id
and o1.voided = 0
left join obs o2
ON o2.value_coded = (select concept_id from report_mapping where source = "CIEL" and code = "190")
and o2.concept_id = tnmp.concept_id
and tnmp.encounter_id = o2.encounter_id
and o2.voided = 0
left join obs o3
ON o3.value_coded = (select concept_id from report_mapping where source = "CIEL" and code = "78796")
and o3.concept_id = tnmp.concept_id
and tnmp.encounter_id = o3.encounter_id
and o3.voided = 0
left join obs o4
ON o4.value_coded = (select concept_id from report_mapping where source = "CIEL" and code = "5275")
and o4.concept_id = tnmp.concept_id
and tnmp.encounter_id = o4.encounter_id
and o4.voided = 0
left join obs o5
ON o5.value_coded = (select concept_id from report_mapping where source = "CIEL" and code = "1472")
and o5.concept_id = tnmp.concept_id
and tnmp.encounter_id = o5.encounter_id
and o5.voided = 0
left join obs o6
ON o6.value_coded = (select concept_id from report_mapping where source = "CIEL" and code = "1489")
and o6.concept_id = tnmp.concept_id
and tnmp.encounter_id = o6.encounter_id
and o6.voided = 0
left join obs o7
ON o7.value_coded = (select concept_id from report_mapping where source = "PIH" and code = "OTHER")
and o7.concept_id = tnmp.concept_id
and tnmp.encounter_id = o7.encounter_id
and o7.voided = 0
SET tnmp.oral_contraception = IF(o.value_coded is not null, "Yes", "No"),
    tnmp.oral_contraception_start_date = (select value_datetime from obs where concept_id = @family_plan_start_date and tnmp.encounter_id = encounter_id and o.obs_group_id = obs_group_id),
	tnmp.oral_contraception_end_date = (select value_datetime from obs where concept_id = @family_plan_end_date  and tnmp.encounter_id = encounter_id and o.obs_group_id = obs_group_id),
    tnmp.depoprovera = IF(o1.value_coded is not null, "Yes", "No"),
    tnmp.depoprovera_start_date = (select value_datetime from obs where concept_id = @family_plan_start_date and tnmp.encounter_id = encounter_id and o1.obs_group_id = obs_group_id),
	tnmp.depoprovera_end_date = (select value_datetime from obs where concept_id = @family_plan_end_date and tnmp.encounter_id = encounter_id and o1.obs_group_id = obs_group_id),
	tnmp.condom = IF(o2.value_coded is not null, "Yes", "No"),
	tnmp.condom_start_date = (select value_datetime from obs where concept_id = @family_plan_start_date and tnmp.encounter_id = encounter_id and o2.obs_group_id = obs_group_id),
    tnmp.condom_end_date = (select value_datetime from obs where concept_id = @family_plan_end_date and tnmp.encounter_id = encounter_id and o2.obs_group_id = obs_group_id),
    tnmp.levonorgestrel = IF(o3.value_coded is not null, "Yes", "No"),
	tnmp.levonorgestrel_start_date = (select value_datetime from obs where concept_id = @family_plan_start_date and tnmp.encounter_id = encounter_id and o3.obs_group_id = obs_group_id),
    tnmp.levonorgestrel_end_date = (select value_datetime from obs where concept_id = @family_plan_end_date and tnmp.encounter_id = encounter_id and o3.obs_group_id = obs_group_id),
    tnmp.intrauterine_device = IF(o4.value_coded is not null, "Yes", "No"),
	tnmp.intrauterine_device_start_date = (select value_datetime from obs where concept_id = @family_plan_start_date and tnmp.encounter_id = encounter_id and o4.obs_group_id = obs_group_id),
    tnmp.intrauterine_device_end_date = (select value_datetime from obs where concept_id = @family_plan_end_date and tnmp.encounter_id = encounter_id and o4.obs_group_id = obs_group_id),
    tnmp.tubal_litigation = IF(o5.value_coded is not null, "Yes", "No"),
	tnmp.tubal_litigation_start_date = (select value_datetime from obs where concept_id = @family_plan_start_date and tnmp.encounter_id = encounter_id and o5.obs_group_id = obs_group_id),
    tnmp.tubal_litigation_end_date = (select value_datetime from obs where concept_id = @family_plan_end_date and tnmp.encounter_id = encounter_id and o5.obs_group_id = obs_group_id),
    tnmp.vasectomy = IF(o6.value_coded is not null, "Yes", "No"),
	tnmp.vasectomy_start_date = (select value_datetime from obs where concept_id = @family_plan_start_date and tnmp.encounter_id = encounter_id and o6.obs_group_id = obs_group_id),
    tnmp.vasectomy_end_date = (select value_datetime from obs where concept_id = @family_plan_end_date and tnmp.encounter_id = encounter_id and o6.obs_group_id = obs_group_id),
    tnmp.family_plan_other = IF(o7.value_coded is not null, "Yes", "No"),
    tnmp.family_plan_other_name = (select value_text from obs where voided = 0 and concept_id = (select concept_id from report_mapping where source = "PIH" and code = "OTHER FAMILY PLANNING METHOD, NON-CODED") and encounter_id = o7.encounter_id),
	tnmp.family_plan_other_start_date = (select value_datetime from obs where concept_id = @family_plan_start_date and tnmp.encounter_id = encounter_id and o7.obs_group_id = obs_group_id),
    tnmp.family_plan_other_end_date = (select value_datetime from obs where concept_id = @family_plan_end_date and tnmp.encounter_id = encounter_id and o7.obs_group_id = obs_group_id)
	;

-- past hospitalization history
CREATE TEMPORARY TABLE temp_hist_hospitalisation_plan_encounters
(
encounter_id int,
admission_date datetime,
discharge_date datetime,
hospital text,
reason_for_hospitalization text,
comments text,
current_meds text,
diagnostic_tests_history text
);

INSERT INTO temp_hist_hospitalisation_plan_encounters (encounter_id)
select DISTINCT(encounter_id) from obs where concept_id =
(select concept_id from report_mapping where source="PIH" and code="HOSPITALIZATION CONSTRUCT") and voided = 0
and encounter_id in ( select encounter_id from encounter where encounter_type in (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc, @NCDInitEnc));

update temp_hist_hospitalisation_plan_encounters  thhpe
left join obs o on o.concept_id = (select concept_id from report_mapping where source="CIEL" and code=1640)
and o.encounter_id = thhpe.encounter_id
left join obs o1 on o1.concept_id = (select concept_id from report_mapping where source="CIEL" and code=1641)
and o1.encounter_id = thhpe.encounter_id
left join obs o2 on o2.concept_id = (select concept_id from report_mapping where source="CIEL" and code=162724)
and o2.encounter_id = thhpe.encounter_id
left join obs o3 on o3.concept_id = (select concept_id from report_mapping where source="CIEL" and code=162879)
and o3.encounter_id = thhpe.encounter_id
left join obs o4 on o4.concept_id = (select concept_id from report_mapping where source="PIH" and code="Hospitalization comment")
and o4.encounter_id = thhpe.encounter_id
left join obs o5 on o5.concept_id = (select concept_id from report_mapping where source="PIH" and code="CURRENT MEDICATIONS")
and o5.encounter_id = thhpe.encounter_id
left join obs o6 on o6.concept_id = (select concept_id from report_mapping where source="PIH" and code="DIAGNOSTIC TESTS HISTORY")
and o6.encounter_id = thhpe.encounter_id
set thhpe.admission_date = o.value_datetime,
    thhpe.discharge_date = o1.value_datetime,
	thhpe.hospital = o2.value_text,
	thhpe.reason_for_hospitalization = o3.value_text,
	thhpe.comments = o4.value_text,
	thhpe.current_meds = o5.value_text,
    thhpe.diagnostic_tests_history = o6.value_text
    ;

SELECT p.patient_id, dos.identifier dossierId, zl.identifier zlemr, zl_loc.name loc_registered, e.encounter_datetime, el.name encounter_location, et.name,
tnir.internal_refer_values, tnir.other_internal_institution, tnir.external_institution, tnir.community, tnir.date_of_referral,
CONCAT(pn.given_name, ' ',pn.family_name) provider, obsjoins.*, smoker, packs_per_year, second_hand_smoker, alcohol_use, illegal_drugs, current_drug_name,
pregnant, last_menstruation_date, estimated_delivery_date, currently_breast_feeding, oral_contraception, oral_contraception_start_date, oral_contraception_end_date, depoprovera, depoprovera_start_date, depoprovera_end_date, condom, condom_start_date, condom_end_date, levonorgestrel, levonorgestrel_start_date, levonorgestrel_end_date, intrauterine_device, intrauterine_device_start_date, intrauterine_device_end_date, tubal_litigation, tubal_litigation_start_date, tubal_litigation_end_date, vasectomy, vasectomy_start_date,
vasectomy_end_date, family_plan_other, family_plan_other_name, family_plan_other_start_date, family_plan_other_end_date, admission_date, discharge_date, hospital, reason_for_hospitalization, comments, current_meds, diagnostic_tests_history
FROM patient p
INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type IN (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc, @NCDInitEnc)
-- Most recent Dossier ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type =@dosId
            AND voided = 0 ORDER BY date_created DESC) dos ON p.patient_id = dos.patient_id
-- Most recent ZL EMR ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type =@zlId
            AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON p.patient_id = zl.patient_id
-- ZL EMR ID location
INNER JOIN location zl_loc ON zl.location_id = zl_loc.location_id
INNER JOIN location el ON e.location_id = el.location_id
-- Encounter Type
INNER JOIN encounter_type et on et.encounter_type_id = e.encounter_type
-- Provider Name
INNER JOIN encounter_provider ep ON ep.encounter_id = e.encounter_id and ep.voided = 0
INNER JOIN provider pv ON pv.provider_id = ep.provider_id
INNER JOIN person_name pn ON pn.person_id = pv.person_id and pn.voided = 0
INNER JOIN
 (select
e.encounter_id,
max(CASE when crs.name = 'PIH' and crt.code = 'PRESENTING HISTORY' THEN o.value_text end) "Presenting_History",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'ASTHMA' THEN  par.name end separator ',') "Family_Asthma",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'HEART DISEASE' THEN  par.name end separator ',') "Family_Heart_Disease",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'DIABETES' THEN  par.name end separator ',') "Family_Diabetes",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'EPILEPSY' THEN  par.name end separator ',') "Family_Epilepsy",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'CIEL' and crt_answer.code = '117635' THEN  par.name end separator ',') "Family_Hemoglobinopathy",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'HYPERTENSION' THEN  par.name end separator ',') "Family_Hypertension",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'TUBERCULOSIS' THEN  par.name end separator ',') "Family_Tuberculosis",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'CIEL' and crt_answer.code = '116031' THEN  par.name end separator ',') "Family_Cancer",
group_concat(distinct CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'CIEL' and crt_answer.code = '116031' THEN  fam_com.value_text end separator ',') "Family_Cancer_comment",
group_concat(CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'OTHER' THEN  par.name end separator ',') "Family_Other" ,
group_concat(distinct CASE when crs.name = 'CIEL' and crt.code = '160592'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'OTHER' THEN  fam_com.value_text end separator ',') "Family_Other_comment",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'ASTHMA' THEN  pres.name end)  "Patient_asthma",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'HEART DISEASE' THEN  "1" end)  "Patient_heart_disease",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'SURGERY' THEN  pres.name end)  "Patient_surgery",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'SURGERY' THEN  pat_com.value_text end)  "Patient_surgery_comment",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'Traumatic Injury' THEN  pres.name end)  "Patient_trauma",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'Traumatic Injury' THEN  pat_com.value_text end)  "Patient_trauma_comment",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'EPILEPSY' THEN  pres.name end)  "Patient_epilepsy",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'CIEL' and crt_answer.code = '117635' THEN  pres.name end)  "Patient_Hemoglobinopathy",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'CIEL' and crt_answer.code = '117635' THEN  pat_com.value_text end)  "Patient_Hemoglobinopathy_comment",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'HYPERTENSION' THEN  pres.name end)  "Patient_hypertension",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'SEXUALLY TRANSMITTED INFECTION' THEN  pres.name end)  "Patient_sti",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'SEXUALLY TRANSMITTED INFECTION' THEN  pat_com.value_text end)  "Patient_sti_comment",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'CIEL' and crt_answer.code = '143849' THEN  pres.name end)  "Patient_congenital_malformation",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'CIEL' and crt_answer.code = '143849' THEN  pat_com.value_text end)  "Patient_con_malform_comment",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'MALNUTRITION' THEN  pres.name end)  "Patient_malnutrition",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'WEIGHT LOSS' THEN  pres.name end)  "Patient_weight_loss",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'MEASLES' THEN  pres.name end)  "Patient_measles",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'TUBERCULOSIS' THEN  pres.name end)  "Patient_tuberculosis",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'VARICELLA' THEN  pres.name end)  "Patient_varicella",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'Diphtheria' THEN  pres.name end)  "Patient_diptheria",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'ACUTE RHEUMATIC FEVER' THEN  pres.name end)  "Patient_raa",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'DIABETES' THEN  pres.name end)  "Patient_diabetes",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'Premature birth of patient' THEN  pres.name end)  "Patient_premature_birth",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'OTHER' THEN  pres.name end)  "Patient_other",
max(CASE when crs.name = 'CIEL' and crt.code = '1628'
                   and crs_answer.name = 'PIH' and crt_answer.code = 'OTHER' THEN  pat_com.value_text end)  "Patient_other_comment",
max(CASE when crs.name = 'PIH' and crt.code = 'BLOOD TYPING' THEN  cn.name end)  "Patient_blood_type",
max(CASE when crs.name = 'PIH' and crt.code = 'Hospitalization comment' THEN  o.value_text end)  "Patient_hospitalization",
max(CASE when crs.name = 'PIH' and crt.code = 'CURRENT MEDICATIONS' THEN  o.value_text end)  "Patient_current_meds",
max(CASE when crs.name = 'PIH' and crt.code = 'DIAGNOSTIC TESTS HISTORY' THEN  o.value_text end)  "Patient_test_history"
from encounter e
INNER JOIN obs o on o.encounter_id = e.encounter_id and o.voided = 0
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'fr' and cn.locale_preferred = '1'  and cn.voided = 0
-- join in mapping of obs answer
LEFT OUTER JOIN concept_reference_map crm_answer on crm_answer.concept_id = o.value_coded
LEFT OUTER JOIN concept_reference_term crt_answer on crt_answer.concept_reference_term_id = crm_answer.concept_reference_term_id
LEFT OUTER JOIN concept_reference_source crs_answer on crs_answer.concept_source_id = crt_answer.concept_source_id
 -- include parent joined by obsgroupid
LEFT OUTER JOIN
   (select obspar.encounter_id, obspar.obs_group_id, cn.name
   from obs obspar
   INNER JOIN concept_reference_map crm on crm.concept_id = obspar.value_coded
	INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id and crt.code in ('MOTHER','FATHER')
	INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id and crs.name = 'PIH'
	INNER JOIN concept_name cn on cn.concept_id = obspar.value_coded and cn.voided = 0 and cn.locale = 'fr' and cn.locale_preferred = '1'
	where obspar.voided = 0) par
	on par.encounter_id = o.encounter_id and par.obs_group_id = o.obs_group_id
-- include Familiy History comment joined by obsgroupid
LEFT OUTER JOIN
   (select obscom.encounter_id, obscom.obs_group_id, obscom.value_text
   from obs obscom
   INNER JOIN concept_reference_map crm on crm.concept_id = obscom.concept_id
	INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id and crt.code in ('160618') -- mapping for family history comment
	INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id and crs.name = 'CIEL'
	where obscom.voided = 0) fam_com
	on fam_com.encounter_id = o.encounter_id and fam_com.obs_group_id = o.obs_group_id
-- include sign/symptom present joined in by ObsGroupId
LEFT OUTER JOIN
   (select obspres.encounter_id, obspres.obs_group_id, cn.name
   from obs obspres
   INNER JOIN concept_reference_map crm on crm.concept_id = obspres.concept_id
	INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id and crt.code = '1729'
	INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id and crs.name = 'CIEL'
	INNER JOIN concept_name cn on cn.concept_id = obspres.value_coded and cn.voided = 0 and cn.locale = 'fr' and cn.locale_preferred = '1'
	where obspres.voided = 0) pres
	on pres.encounter_id = o.encounter_id and pres.obs_group_id = o.obs_group_id
-- include patient history comment, joined by obsgroupid
LEFT OUTER JOIN
   (select obscom.encounter_id, obscom.obs_group_id, obscom.value_text
   from obs obscom
   INNER JOIN concept_reference_map crm on crm.concept_id = obscom.concept_id
	INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id and crt.code in ('160221') -- mapping for patient history comment
	INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id and crs.name = 'CIEL'
	where obscom.voided = 0) pat_com
	on pat_com.encounter_id = o.encounter_id and pat_com.obs_group_id = o.obs_group_id
where e.voided = 0
group by encounter_id) obsjoins on obsjoins.encounter_id = e.encounter_id
LEFT OUTER JOIN temp_ncd_initial_referral tnir on tnir.encounter_id = e.encounter_id
LEFT OUTER JOIN temp_ncd_initial_behavior on temp_ncd_initial_behavior.encounter_id = e.encounter_id
LEFT OUTER JOIN temp_ncd_pregnacy on temp_ncd_pregnacy.encounter_id = e.encounter_id
LEFT OUTER JOIN temp_hist_family_plan on temp_hist_family_plan.encounter_id = e.encounter_id
LEFT OUTER JOIN temp_hist_hospitalisation_plan_encounters on temp_hist_hospitalisation_plan_encounters.encounter_id = e.encounter_id
WHERE p.voided = 0
-- exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id =@testPt
                         AND voided = 0)
AND date(e.encounter_datetime) >= @startDate
AND date(e.encounter_datetime) <= @endDate
GROUP BY e.encounter_id;
