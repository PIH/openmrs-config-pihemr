CALL initialize_global_metadata();

SELECT p.patient_id, zl.identifier zlemr, dos.identifier dossier_id, zl_loc.name loc_registered, un.value unknown_patient, pr.gender, ROUND(DATEDIFF(e.encounter_datetime, pr.birthdate)/365.25, 1) age_at_enc, pa.state_province department, pa.city_village commune, pa.address3 section, pa.address1 locality, pa.address2 street_landmark,
v.date_started "ED_Visit_Start_Datetime",
e.encounter_datetime "Triage_datetime", el.name encounter_location,
-- CONCAT(pn.given_name, ' ',pn.family_name) provider,
pr_names "providers",
obsjoins.*,
ed.encounter_datetime "EDNote_Datetime",
cn_disp_ed.name "EDNote_Disposition",
ed_diagname1.name "ED_Diagnosis1",
ed_diagname2.name "ED_Diagnosis2",
ed_diagname3.name "ED_Diagnosis3",
ed_diag_nc.value_text "ED_Diagnosis_noncoded",
ec.encounter_datetime "Consult_Datetime",
cn_disp_cons.name "Consult_Disposition",
cons_diagname1.name "Cons_Diagnosis1",
cons_diagname2.name "Cons_Diagnosis2",
cons_diagname3.name "Cons_Diagnosis3",
cons_diag_nc.value_text "Cons_Diagnosis_noncoded"
FROM patient p
-- Most recent ZL EMR ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type =@zlId
            AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON p.patient_id = zl.patient_id
-- ZL EMR ID location
INNER JOIN location zl_loc ON zl.location_id = zl_loc.location_id
-- Unknown patient
LEFT OUTER JOIN person_attribute un ON p.patient_id = un.person_id AND un.person_attribute_type_id =@unknownPt
            AND un.voided = 0
-- Gender
INNER JOIN person pr ON p.patient_id = pr.person_id AND pr.voided = 0
-- Most recent address
LEFT OUTER JOIN (SELECT * FROM person_address WHERE voided = 0 ORDER BY date_created DESC) pa ON p.patient_id = pa.person_id
INNER JOIN (SELECT person_id, given_name, family_name FROM person_name WHERE voided = 0 ORDER BY date_created desc) n ON p.patient_id = n.person_id
INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type =@EDTriageEnc
INNER JOIN location el ON e.location_id = el.location_id
-- Provider Name
-- INNER JOIN encounter_provider ep ON ep.encounter_id = e.encounter_id and ep.voided = 0
-- INNER JOIN provider pv ON pv.provider_id = ep.provider_id
-- INNER JOIN person_name pn ON pn.person_id = pv.person_id and pn.voided = 0
LEFT OUTER JOIN (select ep.encounter_id, GROUP_CONCAT(CONCAT(pn.given_name, ' ',pn.family_name) order by ep.date_created asc) pr_names from encounter_provider ep
     INNER JOIN provider pv ON pv.provider_id = ep.provider_id
     INNER JOIN person_name pn ON pn.person_id = pv.person_id and pn.voided = 0
     group by ep.encounter_id) pr on pr.encounter_id = e.encounter_id
-- join in Emergency visit
LEFT OUTER JOIN visit v on v.visit_id = e.visit_id
-- latest disposition of consult note from that visit
LEFT OUTER JOIN encounter ec on ec.encounter_id =
      (select encounter_id from encounter ec2 where ec2.visit_id = e.visit_id and ec2.encounter_type = @consEnc and ec2.voided = 0
      and ec2.form_id = (select form_id from form where uuid = 'a3fc5c38-eb32-11e2-981f-96c0fcb18276')  -- uuid for form id for consult note
      order by ec2.encounter_datetime desc limit 1)
LEFT OUTER JOIN obs disp_cons on disp_cons.encounter_id = ec.encounter_id and disp_cons.voided = 0 and disp_cons.concept_id =
      (select concept_id from report_mapping where source = 'PIH' and code = 'HUM Disposition categories')
LEFT OUTER JOIN concept_name cn_disp_cons on cn_disp_cons.concept_id = disp_cons.value_coded and cn_disp_cons.voided = 0 and cn_disp_cons.locale = 'fr' and cn_disp_cons.locale_preferred = '1'
-- latest disposition of ED note from that visit
LEFT OUTER JOIN encounter ed on ed.encounter_id =
      (select encounter_id from encounter ed2 where ed2.visit_id = e.visit_id and ed2.encounter_type = @consEnc and ed2.voided = 0
      and ed2.form_id = (select form_id from form where uuid = '793915d6-f8d9-11e2-8ff2-fd54ab5fdb2a') -- uuid for form id for ED note
      order by ed2.encounter_datetime desc limit 1)
LEFT OUTER JOIN obs disp_ed on disp_ed.encounter_id = ed.encounter_id and disp_ed.voided = 0 and disp_ed.concept_id =
      (select concept_id from report_mapping where source = 'PIH' and code = 'HUM Disposition categories')
LEFT OUTER JOIN concept_name cn_disp_ed on cn_disp_ed.concept_id = disp_ed.value_coded and cn_disp_ed.voided = 0 and cn_disp_ed.locale = 'fr' and cn_disp_ed.locale_preferred = '1'
-- Diagnoses for latest ED Note (bringing back 3 coded diagnoses, 1 non-coded)
inner join report_mapping diag on diag.source = 'PIH' and diag.code = 'DIAGNOSIS'
inner join report_mapping diag_nc on diag_nc.source = 'PIH' and diag_nc.code = 'Diagnosis or problem, non-coded'
left outer join obs ed_diag1 on ed_diag1.encounter_id = ed.encounter_id and ed_diag1.voided = 0 and ed_diag1.concept_id = diag.concept_id
left outer join concept_name ed_diagname1 on ed_diagname1.concept_id = ed_diag1.value_coded and ed_diagname1.locale = 'fr' and ed_diagname1.voided = 0 and ed_diagname1.locale_preferred=1
left outer join obs ed_diag2 on ed_diag2.encounter_id = ed.encounter_id and ed_diag2.voided = 0 and ed_diag2.concept_id = diag.concept_id
     and ed_diag2.obs_id <> ed_diag1.obs_id
left outer join concept_name ed_diagname2 on ed_diagname2.concept_id = ed_diag2.value_coded and ed_diagname2.locale = 'fr' and ed_diagname2.voided = 0 and ed_diagname2.locale_preferred=1
left outer join obs ed_diag3 on ed_diag3.encounter_id = ed.encounter_id and ed_diag3.voided = 0 and ed_diag3.concept_id = diag.concept_id
     and ed_diag3.obs_id not in (ed_diag1.obs_id,ed_diag2.obs_id)
left outer join concept_name ed_diagname3 on ed_diagname3.concept_id = ed_diag3.value_coded and ed_diagname3.locale = 'fr' and ed_diagname3.voided = 0 and ed_diagname3.locale_preferred=1
left outer join obs ed_diag_nc on ed_diag_nc.encounter_id = ed.encounter_id and ed_diag_nc.voided = 0 and ed_diag_nc.concept_id = diag_nc.concept_id
-- Diagnoses for Consult Note (bringing back 3 coded diagnoses, 1 non-coded)
left outer join obs cons_diag1 on cons_diag1.encounter_id = ec.encounter_id and cons_diag1.voided = 0 and cons_diag1.concept_id = diag.concept_id
left outer join concept_name cons_diagname1 on cons_diagname1.concept_id = cons_diag1.value_coded and cons_diagname1.locale = 'fr' and cons_diagname1.voided = 0 and cons_diagname1.locale_preferred=1
left outer join obs cons_diag2 on cons_diag2.encounter_id = ec.encounter_id and cons_diag2.voided = 0 and cons_diag2.concept_id = diag.concept_id
     and cons_diag2.obs_id <> cons_diag1.obs_id
left outer join concept_name cons_diagname2 on cons_diagname2.concept_id = cons_diag2.value_coded and cons_diagname2.locale = 'fr' and cons_diagname2.voided = 0 and cons_diagname2.locale_preferred=1
left outer join obs cons_diag3 on cons_diag3.encounter_id = ec.encounter_id and cons_diag3.voided = 0 and cons_diag3.concept_id = diag.concept_id
     and cons_diag3.obs_id not in (cons_diag1.obs_id,cons_diag2.obs_id)
left outer join concept_name cons_diagname3 on cons_diagname3.concept_id = cons_diag3.value_coded and cons_diagname3.locale = 'fr' and cons_diagname3.voided = 0 and cons_diagname3.locale_preferred=1
left outer join obs cons_diag_nc on cons_diag_nc.encounter_id = ec.encounter_id and cons_diag_nc.voided = 0 and cons_diag_nc.concept_id = diag_nc.concept_id
-- DOSSIER ID (The UUID is for Hôpital Universitaire de Mirebalais - Prensipal)
LEFT OUTER JOIN
(SELECT patient_id, location_id, identifier_type, identifier from patient_identifier WHERE identifier_type = @dosId
  AND location_id = (select location_id from location where uuid = '24bd1390-5959-11e4-8ed6-0800200c9a66') and voided = 0 ORDER BY date_created DESC)
  dos ON p.patient_id = dos.patient_id
-- Straight Obs Joins
INNER JOIN
(select o.encounter_id,
max(CASE when crs.name = 'PIH' and crt.code = 'Triage queue status' and cnf.name is not null then cnf.name
         when crs.name = 'PIH' and crt.code = 'Triage queue status' and cnf.name is null then cne.name end) 'Triage_queue_status',
max(CASE when crs.name = 'PIH' and crt.code = 'Triage color classification' and cnf.name is not null then cnf.name
         when crs.name = 'PIH' and crt.code = 'Triage color classification' and cnf.name is null then cne.name end) 'Triage_Color',
max(CASE when crs.name = 'PIH' and crt.code = 'Triage score' then o.value_numeric end) 'Triage_Score',
max(CASE when crs.name = 'CIEL' and crt.code = '160531' then o.value_text end) 'Chief_Complaint',
max(CASE when crs.name = 'PIH' and crt.code = 'WEIGHT (KG)' then o.value_numeric end) 'Weight_(KG)',
max(CASE when crs.name = 'PIH' and crt.code = 'Mobility' and cnf.name is not null then cnf.name
         when crs.name = 'PIH' and crt.code = 'Mobility' and cnf.name is null then cne.name end) 'Mobility',
max(CASE when crs.name = 'PIH' and crt.code = 'RESPIRATORY RATE' then o.value_numeric end) 'Respiratory_Rate',
max(CASE when crs.name = 'PIH' and crt.code = 'BLOOD OXYGEN SATURATION' then o.value_numeric end) 'Blood_Oxygen_Saturation',
max(CASE when crs.name = 'PIH' and crt.code = 'PULSE' then o.value_numeric end) 'Pulse',
max(CASE when crs.name = 'PIH' and crt.code = 'SYSTOLIC BLOOD PRESSURE' then o.value_numeric end) 'Systolic_Blood_Pressure',
max(CASE when crs.name = 'PIH' and crt.code = 'DIASTOLIC BLOOD PRESSURE' then o.value_numeric end) 'Diastolic_Blood_Pressure',
max(CASE when crs.name = 'PIH' and crt.code = 'TEMPERATURE (C)' then o.value_numeric end) 'Temperature_(C)',
max(CASE when sets.name = 'PIH' and sets.code = 'Response triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Response triage symptom' and cnf.name is null then cne.name end) 'Response',
max(CASE when answers.name = 'PIH' and answers.code = 'Traumatic Injury' and cnf.name is not null then cnf.name
         when answers.name = 'PIH' and answers.code = 'Traumatic Injury' and cnf.name is null then cne.name end) 'Trauma_Present',
max(CASE when sets.name = 'PIH' and sets.code = 'Neurological triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Neurological triage symptom' and cnf.name is null then cne.name end) 'Neurological',
max(CASE when sets.name = 'PIH' and sets.code = 'Burn triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Burn triage symptom' and cnf.name is null then cne.name end) 'Burn',
max(CASE when sets.name = 'PIH' and sets.code = 'Glucose triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Glucose triage symptom' and cnf.name is null then cne.name end) 'Glucose',
max(CASE when sets.name = 'PIH' and sets.code = 'Trauma triage symptom' and answers.code is null  and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Trauma triage symptom' and answers.code is null and cnf.name is null then cne.name end) 'Trauma_type',
max(CASE when sets.name = 'PIH' and sets.code = 'Digestive triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Digestive triage symptom' and cnf.name is null then cne.name end) 'Digestive',
max(CASE when sets.name = 'PIH' and sets.code = 'Pregrancy triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Pregrancy triage symptom' and cnf.name is null then cne.name end) 'Pregnancy',
max(CASE when sets.name = 'PIH' and sets.code = 'Respiratory triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Respiratory triage symptom' and cnf.name is null then cne.name end) 'Respiratory',
max(CASE when sets.name = 'PIH' and sets.code = 'Pain triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Pain triage symptom' and cnf.name is null then cne.name end) 'Pain',
max(CASE when sets.name = 'PIH' and sets.code = 'Other triage symptom' and cnf.name is not null then cnf.name
         when sets.name = 'PIH' and sets.code = 'Other triage symptom' and cnf.name is null then cne.name end) 'Other_Symptom',
max(CASE when crs.name = 'PIH' and crt.code = 'CLINICAL IMPRESSION COMMENTS' then o.value_text end) 'Clinical_Impression',
max(CASE when crs.name = 'PIH' and crt.code = 'B-HCG' then cnf.name end) 'Pregnancy_Test',
max(CASE when crs.name = 'PIH' and crt.code = 'SERUM GLUCOSE' then o.value_numeric end) 'Glucose_Value',
max(CASE when crs.name = 'PIH' and crt.code = 'Paracetamol dose (mg)' then o.value_numeric end) 'Paracetamol_dose',
group_concat(distinct CASE when crs.name = 'PIH' and crt.code = 'Emergency treatment' and cnf.name is not null then cnf.name
                           when crs.name = 'PIH' and crt.code = 'Emergency treatment' and cnf.name is null then cne.name end order by cne.name separator ',') 'Treatment_Administered',
max(CASE when crs.name = 'PIH' and crt.code = '3077' then round(o.value_numeric/60,0) end) 'Wait_Minutes'
from encounter e, concept_reference_map crm,  concept_reference_term crt, concept_reference_source crs, obs o
-- the following will pull in French and English names of the coded answers.  The above CASE logic will show French if present and otherwise English
LEFT OUTER JOIN concept_name cnf on o.value_coded = cnf.concept_id and cnf.locale = 'fr' and cnf.locale_preferred = '1'  and cnf.voided = 0
LEFT OUTER JOIN concept_name cne on o.value_coded = cne.concept_id and cne.locale = 'en' and cne.locale_preferred = '1'  and cne.voided = 0
LEFT OUTER JOIN obs obs2 on obs2.obs_id = o.obs_group_id
LEFT OUTER JOIN
(select crm2.concept_id,crs2.name, crt2.code from concept_reference_map crm2, concept_reference_term crt2, concept_reference_source crs2
where 1=1
and crm2.concept_reference_term_id = crt2.concept_reference_term_id
and crt2.concept_source_id = crs2.concept_source_id) obsgrp on obsgrp.concept_id = obs2.concept_id
-- The following joins in the concept tables that are used above for the concepts that are grouped into sets
LEFT OUTER JOIN
(select crss.name, crts.code,cs.concept_id  from concept_reference_source crss, concept_reference_term crts, concept_reference_map crms, concept_set cs
where crms.concept_reference_term_id = crts.concept_reference_term_id
and crts.concept_source_id = crss.concept_source_id
and cs.concept_set = crms.concept_id) sets on sets.concept_id = o.value_coded
-- The following joins in the concept tables that are used specifically for trauma (because the "trauma present" button answers
-- the same question as the trauma symptoms dropdown
LEFT OUTER JOIN
(select crsa.name, crta.code, crma.concept_id  from concept_reference_source crsa, concept_reference_term crta, concept_reference_map crma
where crma.concept_reference_term_id = crta.concept_reference_term_id
and crta.concept_source_id = crsa.concept_source_id
and crsa.name = 'PIH' and crta.code = 'Traumatic Injury') answers on answers.concept_id = o.value_coded
where 1=1
and e.encounter_type =@EDTriageEnc
and crm.concept_reference_term_id = crt.concept_reference_term_id
and crt.concept_source_id = crs.concept_source_id
and crm.concept_id = o.concept_id
and o.encounter_id = e.encounter_id
and e.voided = 0
and o.voided = 0
 group by o.encounter_id
) obsjoins ON obsjoins.encounter_id = e.encounter_id
-- end columns joins
WHERE p.voided = 0
-- exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id =@testPt
                         AND voided = 0)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
GROUP BY e.encounter_id
;
