CALL initialize_global_metadata();

SELECT p.patient_id, dos.identifier dossierId, zl.identifier zlemr, zl_loc.name loc_registered, a.date_created,
CONCAT(pn.given_name, ' ',pn.family_name) "creator",
a.date_changed,
CONCAT(pn_ch.given_name, ' ',pn_ch.family_name) "changed_by",
a.allergen_type,
cn_allergen.name 'allergen',
cn_severity.name 'severity',
group_concat(cn_reaction.name separator ',') 'reaction',
a.comments "comments"
FROM patient p
INNER JOIN allergy a on a.patient_id = p.patient_id and a.voided = 0
-- Most recent Dossier ID
LEFT OUTER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type =@dosId
            AND voided = 0 ORDER BY date_created DESC) dos ON p.patient_id = dos.patient_id
-- Most recent ZL EMR ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type =@zlId
            AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON p.patient_id = zl.patient_id
-- ZL EMR ID location
INNER JOIN location zl_loc ON zl.location_id = zl_loc.location_id
-- Provider Name
INNER JOIN provider pv ON pv.provider_id = a.creator
INNER JOIN person_name pn ON pn.person_id = pv.person_id and pn.voided = 0
LEFT OUTER JOIN provider pv_ch ON pv_ch.provider_id = a.changed_by
LEFT OUTER JOIN person_name pn_ch ON pn_ch.person_id = pv_ch.person_id and pn_ch.voided = 0
INNER JOIN concept_name cn_allergen on cn_allergen.concept_id = a.coded_allergen and cn_allergen.locale = 'en' and cn_allergen.locale_preferred = '1'
LEFT OUTER JOIN concept_name cn_severity on cn_severity.concept_id = a.severity_concept_id and cn_severity.locale = 'en' and cn_severity.locale_preferred = '1'
LEFT OUTER JOIN allergy_reaction ar on ar.allergy_id = a.allergy_id
LEFT OUTER JOIN concept_name cn_reaction on cn_reaction.concept_id = ar.reaction_concept_id and cn_reaction.locale = 'en' and cn_reaction.locale_preferred = '1'
WHERE p.voided = 0
-- not sure we should filter by date:
AND ( date(a.date_created) >=@startDate or date(a.date_changed) >=@startDate )
AND ( date(a.date_created) <=@endDate or  date(a.date_changed) <=@endDate )
group by a.allergy_id;
