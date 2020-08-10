CALL initialize_global_metadata();

SELECT p.patient_id, dos.identifier dossierId, zl.identifier zlemr, zl_loc.name loc_registered, e.encounter_datetime, el.name encounter_location, et.name,
CONCAT(pn.given_name, ' ',pn.family_name) provider, obsjoins.*
FROM patient p
INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type in (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc)
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
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'GENERAL EXAM FINDINGS' then cn.name end separator ',') "General_Exam",
max(CASE when  crs.name = 'PIH' and crt.code = 'GENERAL EXAM FINDINGS' then o.comments end) "General_Exam_Other",
max(CASE when crs.name = 'CIEL' and crt.code = '163042' then o.value_text end) "General_Exam_Comments",
group_concat(distinct CASE when crs.name = 'CIEL' and crt.code = '163043' then cn.name end separator ',') "Mental_Exam",
max(CASE when  crs.name = 'CIEL' and crt.code = '163043' then o.comments end) "Mental_Exam_Other",
max(CASE when crs.name = 'CIEL' and crt.code = '163044' then o.value_text end) "Mental_Exam_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'SKIN EXAM FINDINGS' then cn.name end separator ',') "Skin_Exam",
max(CASE when  crs.name = 'PIH' and crt.code = 'SKIN EXAM FINDINGS' then o.comments end) "Skin_Exam_Other",
max(CASE when crs.name = 'PIH' and crt.code = 'SKIN EXAM COMMENT' then o.value_text end) "Skin_Exam_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'HEENT EXAM FINDINGS' then cn.name end separator ',') "HEENT_Exam",
max(CASE when  crs.name = 'PIH' and crt.code = 'HEENT EXAM FINDINGS' then o.comments end) "HEENT_Exam_Other",
max(CASE when crs.name = 'CIEL' and crt.code = '163045' then o.value_text end) "HEENT_Exam_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'CARDIAC EXAM FINDINGS' then cn.name end separator ',') "Cardiac_Exam",
max(CASE when  crs.name = 'PIH' and crt.code = 'CARDIAC EXAM FINDINGS' then o.comments end) "Cardiac_Exam_Other",
max(CASE when crs.name = 'CIEL' and crt.code = '163046' then o.value_text end) "Cardiac_Exam_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'CHEST EXAM FINDINGS' then cn.name end separator ',') "Chest_Exam",
max(CASE when  crs.name = 'PIH' and crt.code = 'CHEST EXAM FINDINGS' then o.comments end) "Chest_Exam_Other",
max(CASE when crs.name = 'CIEL' and crt.code = '160689' then o.value_text end) "Chest_Exam_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'ABDOMINAL EXAM FINDINGS' then cn.name end separator ',') "Abdominal_Exam",
max(CASE when  crs.name = 'PIH' and crt.code = 'ABDOMINAL EXAM FINDINGS' then o.comments end) "Abdominal_Exam_Other",
max(CASE when crs.name = 'CIEL' and crt.code = '160947' then o.value_text end) "Abdominal_Exam_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'UROGENITAL EXAM FINDINGS' then cn.name end separator ',') "Urogenital_Exam",
max(CASE when  crs.name = 'PIH' and crt.code = 'UROGENITAL EXAM FINDINGS' then o.comments end) "Urogenital_Exam_Other",
max(CASE when crs.name = 'CIEL' and crt.code = '163047' then o.value_text end) "Urogenital_Exam_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'MUSCULOSKELETAL EXAM FINDINGS' then cn.name end separator ',') "Musculoskeletal_Exam",
max(CASE when  crs.name = 'PIH' and crt.code = 'MUSCULOSKELETAL EXAM FINDINGS' then o.comments end) "Musculoskeletal_Exam_Other",
max(CASE when crs.name = 'CIEL' and crt.code = '163048' then o.value_text end) "Musculoskeletal_Exam_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'GROSS MOTOR SKILLS EVALUATION' then cn.name end separator ',') "Gross_Motor_Exam",
max(CASE when crs.name = 'PIH' and crt.code = 'Gross Motor Skills Evaluation (text)' then o.value_text end) "Gross_Motor_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'FINE MOTOR SKILLS EVALUATION' then cn.name end separator ',') "Fine_Motor_Exam",
max(CASE when crs.name = 'PIH' and crt.code = 'Fine Motor Skills Evaluation (text)' then o.value_text end) "Fine_Motor_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'LANGUAGE DEVELOPMENT EVALUATION' then cn.name end separator ',') "Language_Exam",
max(CASE when crs.name = 'PIH' and crt.code = 'Language Development Evaluation (text)' then o.value_text end) "Language_Comments",
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'SOCIAL SKILLS EVALUATION' then cn.name end separator ',') "Social_Skills_Exam",
max(CASE when crs.name = 'PIH' and crt.code = 'Social Skills Evaluation (text)' then o.value_text end) "Social_Skills_Comments",
max(CASE when crs.name = 'PIH' and crt.code = 'PHYSICAL SYSTEM COMMENT' then o.value_text end) "Physical_Exam_Comment"
from encounter e
INNER JOIN obs o on o.encounter_id = e.encounter_id and o.voided = 0
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
 where e.voided = 0
 group by encounter_id) obsjoins on obsjoins.encounter_id = e.encounter_id
WHERE p.voided = 0
-- exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id =@testPt
                         AND voided = 0)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
GROUP BY e.encounter_id;
