CALL initialize_global_metadata();

SELECT o.encounter_id "request enc", so.encounter_id "spec enc", p.patient_id, zl.identifier zlemr, zl_loc.name loc_registered,
CONCAT(n.given_name, ' ',n.family_name) "Patient_name",
un.value unknown_patient, pr.gender, ROUND(DATEDIFF(eo.encounter_datetime, pr.birthdate)/365.25, 1) age_at_enc, pa.state_province department, pa.city_village commune, pa.address3 section, pa.address1 locality, pa.address2 street_landmark,
o.order_number,
eo.encounter_datetime "Order_datetime",
CONCAT(pno.given_name, ' ',pno.family_name) "Ordering_provider",
procname1.name "Request_coded_proc1",
procname2.name "Request_coded_proc2",
procname3.name "Request_coded_proc3",
proc_non.value_text "Request_non_coded_proc",
pre_dxname.name "Prepath_dx",
o.instructions "Request_instructions",
tord.clinical_history "Request_history",
se.encounter_datetime "Specimen_date",
CONCAT(pns.given_name, ' ',pns.family_name) "Specimen_provider",
clin_hist.value_text "Clinical_history",
procname4.name "Specimen_coded_proc1",
procname5.name "Specimen_coded_proc2",
procname6.name "Specimen_coded_proc3",
obsjoins.Specimen_non_coded_proc,
obsjoins.Specimen_accession_number,
obsjoins.Post_Op_diagnosis,
obsjoins.Specimen_details_1,
obsjoins.Specimen_details_2,
obsjoins.Specimen_details_3,
obsjoins.Specimen_details_4,
CONCAT(pnas.given_name, ' ',pnas.family_name) "Attending_surgeon",
CONCAT(pnr.given_name, ' ',pnr.family_name) "Resident",
obsjoins.MD_to_notify,
obsjoins.Urgent_review,
obsjoins.Results_date,
obsjoins.Results_note,
obsjoins.File_uploaded
FROM orders o
INNER JOIN patient p on o.patient_id = p.patient_id
INNER JOIN encounter eo on eo.encounter_id = o.encounter_id
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
-- Ordering Provider Name
INNER JOIN encounter_provider ep ON ep.encounter_id = o.encounter_id and ep.voided = 0
INNER JOIN provider pv ON pv.provider_id = ep.provider_id
INNER JOIN person_name pno ON pno.person_id = pv.person_id and pno.voided = 0
-- clinical history from request (order)
LEFT OUTER JOIN test_order tord on tord.order_id = o.order_id
-- pre-path dx
LEFT OUTER JOIN concept_name pre_dxname on pre_dxname.concept_id = o.order_reason and pre_dxname.locale = 'en' and pre_dxname.locale_preferred = '1' and pre_dxname.voided = 0
-- non-coded procedure
LEFT OUTER JOIN obs proc_non on proc_non.encounter_id = eo.encounter_id and proc_non.concept_id =
  (select concept_id from report_mapping where source = 'PIH' and code = 'Procedure ordered, non-coded')
-- procedures
left outer join obs obs_proc1 on obs_proc1.encounter_id = o.encounter_id and obs_proc1.voided = 0 and obs_proc1.concept_id =
  (select concept_id from report_mapping where source = 'PIH' and code = 'Pathology procedure ordered')
left outer join concept_name procname1 on procname1.concept_id = obs_proc1.value_coded and procname1.locale = 'fr' and procname1.voided = 0 and procname1.locale_preferred=1
left outer join obs obs_proc2 on obs_proc2.encounter_id = o.encounter_id and obs_proc2.voided = 0 and obs_proc2.concept_id =
                (select concept_id from report_mapping where source = 'PIH' and code = 'Pathology procedure ordered')
                and obs_proc2.obs_id != obs_proc1.obs_id
left outer join concept_name procname2 on procname2.concept_id = obs_proc2.value_coded and procname2.locale = 'fr' and procname2.voided = 0 and procname2.locale_preferred=1
left outer join obs obs_proc3 on obs_proc3.encounter_id = o.encounter_id and obs_proc3.voided = 0 and obs_proc3.concept_id =
                (select concept_id from report_mapping where source = 'PIH' and code = 'Pathology procedure ordered')
                and obs_proc3.obs_id not in (obs_proc1.obs_id,obs_proc2.obs_id)
left outer join concept_name procname3 on procname3.concept_id = obs_proc3.value_coded and procname3.locale = 'fr' and procname3.voided = 0 and procname3.locale_preferred=1
-- get specimen encounter
LEFT OUTER JOIN obs so on so.voided = 0 and so.value_text = o.order_number and so.concept_id =
    (select concept_id from report_mapping where source = 'PIH' and code = 'Test order number')
 -- Specimen Date
LEFT OUTER JOIN encounter se on se.encounter_id = so.encounter_id and se.voided = 0
-- Specimen Provider Name
LEFT OUTER JOIN encounter_provider eps ON eps.encounter_id = so.encounter_id and eps.voided = 0 and eps.encounter_role_id =
      (select encounter_role_id from encounter_role where name = 'Ordering Provider')
LEFT OUTER JOIN provider pvs ON pvs.provider_id = eps.provider_id
LEFT OUTER JOIN person_name pns ON pns.person_id = pvs.person_id and pns.voided = 0
-- Attending Surgeon Provider Name
LEFT OUTER JOIN encounter_provider epas ON epas.encounter_id = so.encounter_id and epas.voided = 0 and epas.encounter_role_id =
      (select encounter_role_id from encounter_role where name = 'Attending Surgeon')
LEFT OUTER JOIN provider pvas ON pvas.provider_id = epas.provider_id
LEFT OUTER JOIN person_name pnas ON pnas.person_id = pvas.person_id and pnas.voided = 0
-- Resident Provider Name
LEFT OUTER JOIN encounter_provider epr ON epr.encounter_id = so.encounter_id and epr.voided = 0 and epr.encounter_role_id =
      (select encounter_role_id from encounter_role where name = 'Assisting Surgeon')
LEFT OUTER JOIN provider pvr ON pvr.provider_id = epr.provider_id
LEFT OUTER JOIN person_name pnr ON pnr.person_id = pvr.person_id and pnr.voided = 0
-- clinical history
LEFT OUTER JOIN obs clin_hist on clin_hist.encounter_id = so.encounter_id and clin_hist.voided = 0 and clin_hist.concept_id =
   (select concept_id from report_mapping where source = 'CIEL' and code = '160221')
-- coded procedures on specimen
left outer join obs obs_proc4 on obs_proc4.encounter_id = se.encounter_id and obs_proc4.voided = 0 and obs_proc4.concept_id =
    (select concept_id from report_mapping where source = 'PIH' and code = 'Pathology procedure performed')
 left outer join concept_name procname4 on procname4.concept_id = obs_proc4.value_coded and procname4.locale = 'fr' and procname4.voided = 0 and procname4.locale_preferred=1
 left outer join obs obs_proc5 on obs_proc5.encounter_id = se.encounter_id and obs_proc5.voided = 0 and obs_proc5.concept_id =
                 (select concept_id from report_mapping where source = 'PIH' and code = 'Pathology procedure performed')
                 and obs_proc5.obs_id != obs_proc4.obs_id
 left outer join concept_name procname5 on procname5.concept_id = obs_proc5.value_coded and procname5.locale = 'fr' and procname5.voided = 0 and procname5.locale_preferred=1
 left outer join obs obs_proc6 on obs_proc6.encounter_id = se.encounter_id and obs_proc6.voided = 0 and obs_proc6.concept_id =
                 (select concept_id from report_mapping where source = 'PIH' and code = 'Pathology procedure performed')
                 and obs_proc6.obs_id not in (obs_proc4.obs_id,obs_proc5.obs_id)
 left outer join concept_name procname6 on procname6.concept_id = obs_proc6.value_coded and procname6.locale = 'fr' and procname6.voided = 0 and procname6.locale_preferred=1
-- straight obs of specimen encounter
LEFT OUTER JOIN (
  select ot.encounter_id,
  max(CASE when rm.source = 'PIH' and rm.code = 'Procedure performed non-coded' then ot.value_text end) 'Specimen_non_coded_proc',
  max(CASE when rm.source = 'PIH' and rm.code = 'Emergency' then cn.name end) 'Urgent_review',
  max(CASE when rm.source = 'CIEL' and rm.code = '160221' then ot.value_text end) 'Clinical_history',
  max(CASE when rm.source = 'PIH' and rm.code = 'DIAGNOSIS' then cn.name end) 'Post_Op_diagnosis',
  max(CASE when rm.source = 'PIH' and rm.code = 'Name of clinician for test results' then ot.value_text end) 'MD_to_notify',
  max(CASE when rm.source = 'PIH' and rm.code = 'Pathology sample comment' then ot.value_text end) 'Results_note',
  max(CASE when rm.source = 'PIH' and rm.code = '10775' then ot.value_text end) 'Specimen_details_1',
  max(CASE when rm.source = 'PIH' and rm.code = '10776' then ot.value_text end) 'Specimen_details_2',
  max(CASE when rm.source = 'PIH' and rm.code = '10777' then ot.value_text end) 'Specimen_details_3',
  max(CASE when rm.source = 'PIH' and rm.code = '10778' then ot.value_text end) 'Specimen_details_4',
  max(CASE when rm.source = 'PIH' and rm.code = 'Date of test results' then ot.value_datetime end) 'Results_date',
  max(CASE when rm.source = 'CIEL' and rm.code = '162086' then ot.value_text end) 'Specimen_accession_number',
  max(CASE when rm.source = 'PIH' and rm.code = 'PDF file' then if(ifnull(ot.value_complex,' ')=' ','No','Oui') end) 'File_uploaded'
  from encounter e, report_mapping rm, obs ot
  LEFT OUTER JOIN concept_name cn on ot.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
  where 1=1
  and e.encounter_type in
     (select encounter_type_id  from encounter_type where name = 'Specimen Collection')
   and rm.concept_id = ot.concept_id
  and ot.encounter_id = e.encounter_id
  and e.voided = 0
  and ot.voided = 0
  group by ot.encounter_id) obsjoins ON obsjoins.encounter_id = se.encounter_id
where  o.order_type_id = @pathologyTestOrder
AND date(o.date_activated) >= @startDate
AND date(o.date_activated) <= @endDate
group by o.order_id
order by eo.encounter_datetime
;
