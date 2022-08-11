CALL initialize_global_metadata();

SELECT p.patient_id, zl.identifier zlemr, dos.identifier dossier_id, zl_loc.name loc_registered, un.value unknown_patient, pr.gender, ROUND(DATEDIFF(e.encounter_datetime, pr.birthdate)/365.25, 1) age_at_enc, pa.state_province department, pa.city_village commune, pa.address3 section, pa.address1 locality, pa.address2 street_landmark, e.encounter_datetime, el.name encounter_location,
CONCAT(pn.given_name, ' ',pn.family_name) provider, e.visit_id, obsjoins.encounter_id "Encounter_id", et.name "Encounter_Type",
diagname1.name "Diagnosis_1",
diagname2.name "Diagnosis_2",
diagname3.name "Diagnosis_3",
Cancer_Stage "Cancer_Stage",
Patient_Plan_Details "Patient_Plan_Details",
Presenting_History "Presenting_History",
Disease_Status "Disease_Status",
ECOG "ECOG",
Chemo_Protocol "Chemo_Protocol",
Other_Protocol "Other_Chemo_Protocol",
Chemo_Cycle_Number "Chemo_Cycle_Number",
Planned_Chemo_Cycles "Planned_Chemo_Cycles",
Chemo_Treatment_Received "Chemo_Treatment_Received",
Chemo_Treatment_Received_Reason "Chemo_Treatment_Received_Reason",
Chemo_Treatment_Tolerated "Chemo_Treatment_Tolerated",
Chemo_Treatment_Tolerated_Description "Chemo_Treatment_Tolerated_Description",
Chemo_Side_Effect "Chemo_Side_Effect",
Other_Side_Effect "Other_Side_Effect",
Pain_Scale "Pain_Scale",
Pain_Details "Pain_Details",
Patient_Plan "Patient_Plan",
Important_Visit_Info "Important_Visit_Info",
Treatment_Intent "Treatment_Intent",
disp.Outpatient_chemo "Outpatient_Chemo"
FROM patient p
-- Most recent ZL EMR ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type = @zlId
            AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON p.patient_id = zl.patient_id
-- ZL EMR ID location
INNER JOIN location zl_loc ON zl.location_id = zl_loc.location_id
-- Unknown patient
LEFT OUTER JOIN person_attribute un ON p.patient_id = un.person_id AND un.person_attribute_type_id = @unknownPt
            AND un.voided = 0
-- Gender
INNER JOIN person pr ON p.patient_id = pr.person_id AND pr.voided = 0
--  Most recent address
LEFT OUTER JOIN (SELECT * FROM person_address WHERE voided = 0 ORDER BY date_created DESC) pa ON p.patient_id = pa.person_id
INNER JOIN (SELECT person_id, given_name, family_name FROM person_name WHERE voided = 0 ORDER BY date_created desc) n ON p.patient_id = n.person_id
INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type in (@oncNoteEnc, @oncIntakeEnc, @chemoEnc, @dispEnc)
INNER JOIN location el ON e.location_id = el.location_id
-- Provider Name
INNER JOIN encounter_provider ep ON ep.encounter_id = e.encounter_id and ep.voided = 0
INNER JOIN provider pv ON pv.provider_id = ep.provider_id
INNER JOIN person_name pn ON pn.person_id = pv.person_id and pn.voided = 0
-- Encounter type
INNER JOIN encounter_type et on e.encounter_type = et.encounter_type_id
-- Joins for all other fields
INNER JOIN
(select o.encounter_id,
max(CASE when rm.source = 'CIEL' and rm.code = '160786' then cn.name end) 'Cancer_Stage',
max(CASE when rm.source = 'PIH' and rm.code = 'PATIENT PLAN COMMENTS' then o.value_text end) 'Patient_Plan_Details',
max(CASE when rm.source = 'PIH' and rm.code = 'PRESENTING HISTORY' then o.value_text end) 'Presenting_History',
max(CASE when rm.source = 'CIEL' and rm.code = '163050' then cn.name end) 'Disease_Status',
max(CASE when rm.source = 'CIEL' and rm.code = '160379' then o.value_numeric end) 'ECOG',
group_concat(CASE when rm.source = 'CIEL' and rm.code = '163073' then cn.name end separator ',') 'Chemo_Protocol',
max(CASE when rm.source = 'CIEL' and rm.code = '163073' then o.comments end) 'Other_protocol',
max(CASE when rm.source = 'PIH' and rm.code = 'CHEMOTHERAPY CYCLE NUMBER' then o.value_numeric end) 'Chemo_Cycle_Number',
max(CASE when rm.source = 'PIH' and rm.code = 'Total number of planned chemotherapy cycles' then o.value_numeric end) 'Planned_Chemo_Cycles',
max(CASE when rm.source = 'PIH' and rm.code = 'Chemotherapy treatment received' then cn.name end) 'Chemo_Treatment_Received',
max(CASE when rm.source = 'PIH' and rm.code = 'Chemotherapy treatment received' then o.comments end) 'Chemo_Treatment_Received_Reason',
max(CASE when rm.source = 'PIH' and rm.code = 'Chemotherapy treatment tolerated' then cn.name end) 'Chemo_Treatment_Tolerated',
max(CASE when rm.source = 'PIH' and rm.code = 'Chemotherapy treatment tolerated' then o.comments end) 'Chemo_Treatment_Tolerated_Description',
group_concat(CASE when rm.source = 'CIEL' and rm.code = '163075' then cn.name end separator ',') 'Chemo_Side_Effect',
max(CASE when rm.source = 'CIEL' and rm.code = '163075' then o.comments end) 'Other_Side_Effect',
max(CASE when rm.source = 'PIH' and rm.code = 'PAIN SCALE OF 0 TO 10' then o.value_numeric end) 'Pain_Scale',
max(CASE when rm.source = 'CIEL' and rm.code = '163077' then o.value_text end) 'Pain_Details',
max(CASE when rm.source = 'CIEL' and rm.code = '163059' then cn.name end) 'Patient_Plan',
max(CASE when rm.source = 'CIEL' and rm.code = '162749' then o.value_text end) 'Important_Visit_Info',
max(CASE when rm.source = 'CIEL' and rm.code = '160846' then cn.name end) 'Treatment_Intent'
from encounter e, report_mapping rm, obs o
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
where 1=1
and e.encounter_type in (@oncNoteEnc, @oncIntakeEnc, @chemoEnc, @dispEnc)
and rm.concept_id = o.concept_id
and o.encounter_id = e.encounter_id
and e.voided = 0
and o.voided = 0
group by o.encounter_id
) obsjoins ON obsjoins.encounter_id = e.encounter_id
-- Begin joins for diagnoses
inner join (select crm.concept_id from concept_reference_map crm, concept_reference_term crt, concept_reference_source crs
    where crm.concept_reference_term_id = crt.concept_reference_term_id
    and crt.concept_source_id = crs.concept_source_id
    and crs.name = 'PIH'
    and crt.code = 'DIAGNOSIS'
    ) diagcode
left outer join obs obs_diag1 on obs_diag1.encounter_id = e.encounter_id and obs_diag1.voided = 0 and obs_diag1.concept_id = diagcode.concept_id
left outer join concept_name diagname1 on diagname1.concept_id = obs_diag1.value_coded and diagname1.locale = 'fr' and diagname1.voided = 0 and diagname1.locale_preferred=1
left outer join obs obs_diag2 on obs_diag2.encounter_id = e.encounter_id and obs_diag2.voided = 0 and obs_diag2.concept_id = diagcode.concept_id
   and obs_diag2.obs_id != obs_diag1.obs_id
left outer join concept_name diagname2 on diagname2.concept_id = obs_diag2.value_coded and diagname2.locale = 'fr' and diagname2.voided = 0 and diagname2.locale_preferred=1
left outer join obs obs_diag3 on obs_diag3.encounter_id = e.encounter_id and obs_diag3.voided = 0 and obs_diag3.concept_id = diagcode.concept_id
   and obs_diag3.obs_id not in (obs_diag1.obs_id, obs_diag2.obs_id)
left outer join concept_name diagname3 on diagname3.concept_id = obs_diag3.value_coded and diagname3.locale = 'fr' and diagname3.voided = 0 and diagname3.locale_preferred=1
-- end columns joins
LEFT OUTER JOIN
(select e_disp.encounter_id,
group_concat(CASE when rm.source = 'PIH' and rm.code = 'MEDICATION ORDERS' then cn.name end separator ',') 'Outpatient_Chemo'
-- max(CASE when rm.source = 'PIH' and rm.code = '9071' then o_disp.value_numeric end) 'quantity_dispensed'
from encounter e_disp
INNER JOIN obs o_disp on o_disp.encounter_id = e_disp.encounter_id and o_disp.voided = 0
INNER JOIN report_mapping rm on rm.concept_id = o_disp.concept_id
INNER JOIN report_mapping rm2 on rm2.concept_id = o_disp.value_coded
   and ((rm2.source = 'CIEL' and rm2.code = '78738')
    or (rm2.source = 'CIEL' and rm2.code = '77941')
    or (rm2.source = 'CIEL' and rm2.code = '84668')
    or (rm2.source = 'CIEL' and rm2.code = '163060'))
LEFT OUTER JOIN concept_name cn on cn.concept_id = o_disp.value_coded and cn.locale = 'en' and cn.locale_preferred = '1'
where e_disp.voided = 0
and e_disp.encounter_type = @dispEnc
group by e_disp.encounter_id) disp on disp.encounter_id = e.encounter_id
-- DOSSIER ID (The UUID is for Hôpital Universitaire de Mirebalais - Prensipal)
LEFT OUTER JOIN
(SELECT patient_id, location_id, identifier_type, identifier from patient_identifier WHERE identifier_type = @dosId
  AND location_id = (select location_id from location where uuid = '24bd1390-5959-11e4-8ed6-0800200c9a66') and voided = 0 ORDER BY date_created DESC) dos ON p.patient_id = dos.patient_id
WHERE p.voided = 0
-- exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = @testPt
                         AND voided = 0)
AND (e.encounter_type <> @dispEnc or disp.Outpatient_chemo is not null)
AND date(e.encounter_datetime) >= @startDate
AND date(e.encounter_datetime) <= @endDate
GROUP BY e.encounter_id
order by e.encounter_datetime;
