CALL initialize_global_metadata();

SELECT p.patient_id, dos.identifier dossierId, zl.identifier zlemr, zl_loc.name loc_registered, e.encounter_datetime, el.name encounter_location, et.name,
CONCAT(pn.given_name, ' ',pn.family_name) provider, obsjoins.*,
Medication_1,
Dose_Quantity_1,
Dose_Units_1,
Duration_1,
Duration_Units_1,
Frequency_1,
Instructions_1,
Medication_2,
Dose_Quantity_2,
Dose_Units_2,
Duration_2,
Duration_Units_2,
Frequency_2,
Instructions_2,
Medication_3,
Dose_Quantity_3,
Dose_Units_3,
Duration_3,
Duration_Units_3,
Frequency_3,
Instructions_3,
Medication_4,
Dose_Quantity_4,
Dose_Units_4,
Duration_4,
Duration_Units_4,
Frequency_4,
Instructions_4,
Medication_5,
Dose_Quantity_5,
Dose_Units_5,
Duration_5,
Duration_Units_5,
Frequency_5,
Instructions_5,
Medication_6,
Dose_Quantity_6,
Dose_Units_6,
Duration_6,
Duration_Units_6,
Frequency_6,
Instructions_6,
Medication_7,
Dose_Quantity_7,
Dose_Units_7,
Duration_7,
Duration_Units_7,
Frequency_7,
Instructions_7,
Medication_8,
Dose_Quantity_8,
Dose_Units_8,
Duration_8,
Duration_Units_8,
Frequency_8,
Instructions_8
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
 LEFT OUTER JOIN
 (select
o.encounter_id,
max(CASE when  crs.name = 'CIEL' and crt.code = '162749' then o.value_text end) "Clinical_Plan",
group_concat(CASE when  crs.name = 'PIH' and crt.code = 'Lab test ordered coded' then cn.name end  separator ',' ) "Lab_Tests",
max(CASE when  crs.name = 'PIH' and crt.code = 'HUM Disposition categories' then cn.name end) "Disposition",
max(CASE when  crs.name = 'PIH' and crt.code = 'DISPOSITION COMMENTS' then o.value_text end) "Comment",
max(CASE when  crs.name = 'PIH' and crt.code = 'RETURN VISIT DATE' then o.value_datetime end) "Return_visit_date"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id) obsjoins on obsjoins.encounter_id = e.encounter_id
 -- Medication 1
LEFT OUTER JOIN
  (select
o.encounter_id, obs_group_id,
max(CASE when  crs.name = 'PIH' and crt.code = 'MEDICATION ORDERS' then d.name end) "Medication_1",
max(CASE when  crs.name = 'CIEL' and crt.code = '160856' then o.value_numeric end) "Dose_Quantity_1",
max(CASE when  crs.name = 'PIH' and crt.code = 'Dosing units coded' then cn.name end) "Dose_Units_1",
max(CASE when  crs.name = 'CIEL' and crt.code = '159368' then o.value_numeric end) "Duration_1",
max(CASE when  crs.name = 'PIH' and crt.code = 'TIME UNITS' then cn.name end) "Duration_Units_1",
max(CASE when  crs.name = 'PIH' and crt.code = 'Drug frequency for HUM' then cn.name end) "Frequency_1",
max(CASE when  crs.name = 'PIH' and crt.code = 'Prescription instructions non-coded' then o.value_text end) "Instructions_1"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id, o.obs_group_id) med1 on med1.encounter_id = e.encounter_id and
     med1.obs_group_id = (
    select obscon1.obs_id from obs obscon1
    INNER JOIN concept_reference_map crmc on crmc.concept_id = obscon1.concept_id
    INNER JOIN concept_reference_term crtc on crtc.concept_reference_term_id = crmc.concept_reference_term_id
	INNER JOIN concept_reference_source crsc on crsc.concept_source_id = crtc.concept_source_id
	where crsc.name = 'PIH' and crtc.code = 'Prescription construct'
	and obscon1.encounter_id = e.encounter_id limit 1)
-- Medication 2
LEFT OUTER JOIN
  (select
o.encounter_id, obs_group_id,
max(CASE when  crs.name = 'PIH' and crt.code = 'MEDICATION ORDERS' then d.name end) "Medication_2",
max(CASE when  crs.name = 'CIEL' and crt.code = '160856' then o.value_numeric end) "Dose_Quantity_2",
max(CASE when  crs.name = 'PIH' and crt.code = 'Dosing units coded' then cn.name end) "Dose_Units_2",
max(CASE when  crs.name = 'CIEL' and crt.code = '159368' then o.value_numeric end) "Duration_2",
max(CASE when  crs.name = 'PIH' and crt.code = 'TIME UNITS' then cn.name end) "Duration_Units_2",
max(CASE when  crs.name = 'PIH' and crt.code = 'Drug frequency for HUM' then cn.name end) "Frequency_2",
max(CASE when  crs.name = 'PIH' and crt.code = 'Prescription instructions non-coded' then o.value_text end) "Instructions_2"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id, o.obs_group_id) med2 on med2.encounter_id = e.encounter_id and
     med2.obs_group_id = (
    select obscon2.obs_id from obs obscon2
    INNER JOIN concept_reference_map crmc on crmc.concept_id = obscon2.concept_id
    INNER JOIN concept_reference_term crtc on crtc.concept_reference_term_id = crmc.concept_reference_term_id
	INNER JOIN concept_reference_source crsc on crsc.concept_source_id = crtc.concept_source_id
	where crsc.name = 'PIH' and crtc.code = 'Prescription construct'
	and obscon2.encounter_id = e.encounter_id
    and obscon2.obs_id <> med1.obs_group_id limit 1)
-- Medication 3
LEFT OUTER JOIN
  (select
o.encounter_id, obs_group_id,
max(CASE when  crs.name = 'PIH' and crt.code = 'MEDICATION ORDERS' then d.name end) "Medication_3",
max(CASE when  crs.name = 'CIEL' and crt.code = '160856' then o.value_numeric end) "Dose_Quantity_3",
max(CASE when  crs.name = 'PIH' and crt.code = 'Dosing units coded' then cn.name end) "Dose_Units_3",
max(CASE when  crs.name = 'CIEL' and crt.code = '159368' then o.value_numeric end) "Duration_3",
max(CASE when  crs.name = 'PIH' and crt.code = 'TIME UNITS' then cn.name end) "Duration_Units_3",
max(CASE when  crs.name = 'PIH' and crt.code = 'Drug frequency for HUM' then cn.name end) "Frequency_3",
max(CASE when  crs.name = 'PIH' and crt.code = 'Prescription instructions non-coded' then o.value_text end) "Instructions_3"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id, o.obs_group_id) med3 on med3.encounter_id = e.encounter_id and
     med3.obs_group_id = (
    select obscon3.obs_id from obs obscon3
    INNER JOIN concept_reference_map crmc on crmc.concept_id = obscon3.concept_id
    INNER JOIN concept_reference_term crtc on crtc.concept_reference_term_id = crmc.concept_reference_term_id
	INNER JOIN concept_reference_source crsc on crsc.concept_source_id = crtc.concept_source_id
	where crsc.name = 'PIH' and crtc.code = 'Prescription construct'
	and obscon3.encounter_id = e.encounter_id
    and obscon3.obs_id not in (med1.obs_group_id,med2.obs_group_id) limit 1)
-- Medication 4
LEFT OUTER JOIN
  (select
o.encounter_id, obs_group_id,
max(CASE when  crs.name = 'PIH' and crt.code = 'MEDICATION ORDERS' then d.name end) "Medication_4",
max(CASE when  crs.name = 'CIEL' and crt.code = '160856' then o.value_numeric end) "Dose_Quantity_4",
max(CASE when  crs.name = 'PIH' and crt.code = 'Dosing units coded' then cn.name end) "Dose_Units_4",
max(CASE when  crs.name = 'CIEL' and crt.code = '159368' then o.value_numeric end) "Duration_4",
max(CASE when  crs.name = 'PIH' and crt.code = 'TIME UNITS' then cn.name end) "Duration_Units_4",
max(CASE when  crs.name = 'PIH' and crt.code = 'Drug frequency for HUM' then cn.name end) "Frequency_4",
max(CASE when  crs.name = 'PIH' and crt.code = 'Prescription instructions non-coded' then o.value_text end) "Instructions_4"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id, o.obs_group_id) med4 on med4.encounter_id = e.encounter_id and
     med4.obs_group_id = (
    select obscon4.obs_id from obs obscon4
    INNER JOIN concept_reference_map crmc on crmc.concept_id = obscon4.concept_id
    INNER JOIN concept_reference_term crtc on crtc.concept_reference_term_id = crmc.concept_reference_term_id
	INNER JOIN concept_reference_source crsc on crsc.concept_source_id = crtc.concept_source_id
	where crsc.name = 'PIH' and crtc.code = 'Prescription construct'
	and obscon4.encounter_id = e.encounter_id
    and obscon4.obs_id not in (med1.obs_group_id,med2.obs_group_id,med3.obs_group_id) limit 1)
-- Medication 5
LEFT OUTER JOIN
  (select
o.encounter_id, obs_group_id,
max(CASE when  crs.name = 'PIH' and crt.code = 'MEDICATION ORDERS' then d.name end) "Medication_5",
max(CASE when  crs.name = 'CIEL' and crt.code = '160856' then o.value_numeric end) "Dose_Quantity_5",
max(CASE when  crs.name = 'PIH' and crt.code = 'Dosing units coded' then cn.name end) "Dose_Units_5",
max(CASE when  crs.name = 'CIEL' and crt.code = '159368' then o.value_numeric end) "Duration_5",
max(CASE when  crs.name = 'PIH' and crt.code = 'TIME UNITS' then cn.name end) "Duration_Units_5",
max(CASE when  crs.name = 'PIH' and crt.code = 'Drug frequency for HUM' then cn.name end) "Frequency_5",
max(CASE when  crs.name = 'PIH' and crt.code = 'Prescription instructions non-coded' then o.value_text end) "Instructions_5"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id, o.obs_group_id) med5 on med5.encounter_id = e.encounter_id and
     med5.obs_group_id = (
    select obscon5.obs_id from obs obscon5
    INNER JOIN concept_reference_map crmc on crmc.concept_id = obscon5.concept_id
    INNER JOIN concept_reference_term crtc on crtc.concept_reference_term_id = crmc.concept_reference_term_id
	INNER JOIN concept_reference_source crsc on crsc.concept_source_id = crtc.concept_source_id
	where crsc.name = 'PIH' and crtc.code = 'Prescription construct'
	and obscon5.encounter_id = e.encounter_id
    and obscon5.obs_id not in (med1.obs_group_id,med2.obs_group_id,med3.obs_group_id,med4.obs_group_id) limit 1)
 -- Medication 6
LEFT OUTER JOIN
  (select
o.encounter_id, obs_group_id,
max(CASE when  crs.name = 'PIH' and crt.code = 'MEDICATION ORDERS' then d.name end) "Medication_6",
max(CASE when  crs.name = 'CIEL' and crt.code = '160856' then o.value_numeric end) "Dose_Quantity_6",
max(CASE when  crs.name = 'PIH' and crt.code = 'Dosing units coded' then cn.name end) "Dose_Units_6",
max(CASE when  crs.name = 'CIEL' and crt.code = '159368' then o.value_numeric end) "Duration_6",
max(CASE when  crs.name = 'PIH' and crt.code = 'TIME UNITS' then cn.name end) "Duration_Units_6",
max(CASE when  crs.name = 'PIH' and crt.code = 'Drug frequency for HUM' then cn.name end) "Frequency_6",
max(CASE when  crs.name = 'PIH' and crt.code = 'Prescription instructions non-coded' then o.value_text end) "Instructions_6"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id, o.obs_group_id) med6 on med6.encounter_id = e.encounter_id and
     med6.obs_group_id = (
    select obscon6.obs_id from obs obscon6
    INNER JOIN concept_reference_map crmc on crmc.concept_id = obscon6.concept_id
    INNER JOIN concept_reference_term crtc on crtc.concept_reference_term_id = crmc.concept_reference_term_id
	INNER JOIN concept_reference_source crsc on crsc.concept_source_id = crtc.concept_source_id
	where crsc.name = 'PIH' and crtc.code = 'Prescription construct'
	and obscon6.encounter_id = e.encounter_id
    and obscon6.obs_id not in (med1.obs_group_id,med2.obs_group_id,med3.obs_group_id,med4.obs_group_id,med5.obs_group_id) limit 1)
-- Medication 7
LEFT OUTER JOIN
  (select
o.encounter_id, obs_group_id,
max(CASE when  crs.name = 'PIH' and crt.code = 'MEDICATION ORDERS' then d.name end) "Medication_7",
max(CASE when  crs.name = 'CIEL' and crt.code = '160856' then o.value_numeric end) "Dose_Quantity_7",
max(CASE when  crs.name = 'PIH' and crt.code = 'Dosing units coded' then cn.name end) "Dose_Units_7",
max(CASE when  crs.name = 'CIEL' and crt.code = '159368' then o.value_numeric end) "Duration_7",
max(CASE when  crs.name = 'PIH' and crt.code = 'TIME UNITS' then cn.name end) "Duration_Units_7",
max(CASE when  crs.name = 'PIH' and crt.code = 'Drug frequency for HUM' then cn.name end) "Frequency_7",
max(CASE when  crs.name = 'PIH' and crt.code = 'Prescription instructions non-coded' then o.value_text end) "Instructions_7"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id, o.obs_group_id) med7 on med7.encounter_id = e.encounter_id and
     med7.obs_group_id = (
    select obscon7.obs_id from obs obscon7
    INNER JOIN concept_reference_map crmc on crmc.concept_id = obscon7.concept_id
    INNER JOIN concept_reference_term crtc on crtc.concept_reference_term_id = crmc.concept_reference_term_id
	INNER JOIN concept_reference_source crsc on crsc.concept_source_id = crtc.concept_source_id
	where crsc.name = 'PIH' and crtc.code = 'Prescription construct'
	and obscon7.encounter_id = e.encounter_id
    and obscon7.obs_id not in (med1.obs_group_id,med2.obs_group_id,med3.obs_group_id,med4.obs_group_id,med5.obs_group_id,med6.obs_group_id) limit 1)
-- Medication 8
LEFT OUTER JOIN
  (select
o.encounter_id, obs_group_id,
max(CASE when  crs.name = 'PIH' and crt.code = 'MEDICATION ORDERS' then d.name end) "Medication_8",
max(CASE when  crs.name = 'CIEL' and crt.code = '160856' then o.value_numeric end) "Dose_Quantity_8",
max(CASE when  crs.name = 'PIH' and crt.code = 'Dosing units coded' then cn.name end) "Dose_Units_8",
max(CASE when  crs.name = 'CIEL' and crt.code = '159368' then o.value_numeric end) "Duration_8",
max(CASE when  crs.name = 'PIH' and crt.code = 'TIME UNITS' then cn.name end) "Duration_Units_8",
max(CASE when  crs.name = 'PIH' and crt.code = 'Drug frequency for HUM' then cn.name end) "Frequency_8",
max(CASE when  crs.name = 'PIH' and crt.code = 'Prescription instructions non-coded' then o.value_text end) "Instructions_8"
from obs o
-- join in mapping of obs question (not needed if this is a standalone export)
INNER JOIN concept_reference_map crm on crm.concept_id = o.concept_id
INNER JOIN concept_reference_term crt on crt.concept_reference_term_id = crm.concept_reference_term_id
INNER JOIN concept_reference_source crs on crs.concept_source_id = crt.concept_source_id
LEFT OUTER JOIN concept_name cn on o.value_coded = cn.concept_id and cn.locale = 'en' and cn.locale_preferred = '1'  and cn.voided = 0
LEFT OUTER JOIN drug d on d.concept_id = o.value_coded
 where o.voided = 0
 group by o.encounter_id, o.obs_group_id) med8 on med8.encounter_id = e.encounter_id and
     med8.obs_group_id = (
    select obscon8.obs_id from obs obscon8
    INNER JOIN concept_reference_map crmc on crmc.concept_id = obscon8.concept_id
    INNER JOIN concept_reference_term crtc on crtc.concept_reference_term_id = crmc.concept_reference_term_id
	INNER JOIN concept_reference_source crsc on crsc.concept_source_id = crtc.concept_source_id
	where crsc.name = 'PIH' and crtc.code = 'Prescription construct'
	and obscon8.encounter_id = e.encounter_id
    and obscon8.obs_id not in (med1.obs_group_id,med2.obs_group_id,med3.obs_group_id,med4.obs_group_id,med5.obs_group_id,med6.obs_group_id,med7.obs_group_id) limit 1)
 WHERE p.voided = 0
-- and e.encounter_id=5497
-- exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id =@testPt
                         AND voided = 0)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
GROUP BY e.encounter_id;

