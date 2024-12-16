-- TODO: is this still used?
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
max(CASE when  crs.name = 'PIH' and crt.code = 'HUM Disposition categories' then cn.name end) "Disposition",
max(CASE when  crs.name = 'PIH' and crt.code = 'DISPOSITION COMMENTS' then o.value_text end) "Comment",
max(CASE when  crs.name = 'PIH' and crt.code = 'RETURN VISIT DATE' then o.value_datetime end) "Return_visit_date"
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
