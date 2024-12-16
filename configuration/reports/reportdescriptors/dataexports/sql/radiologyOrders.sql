CALL initialize_global_metadata();

SELECT p.patient_id, zl.identifier zlemr, zl_loc.name loc_registered, un.value unknown_patient, pr.gender, ROUND(DATEDIFF(e.encounter_datetime, pr.birthdate)/365.25, 1) age_at_enc, pa.state_province department, pa.city_village commune, pa.address3 section, pa.address1 locality, pa.address2 street_landmark, e.encounter_id, e.encounter_datetime, el.name encounter_location, CONCAT(pn.given_name, ' ', pn.family_name) entered_by, CONCAT(provn.given_name, ' ', provn.family_name) provider, ocn_en.name radiology_order_en, ocn_fr.name radiology_order_fr, o.order_number, o.urgency, e.visit_id, pr.birthdate, pr.birthdate_estimated,

CASE
  WHEN o.concept_id IN(SELECT concept_id FROM concept_set WHERE concept_set = @ctOrderables) THEN 'CT'
  WHEN o.concept_id IN(SELECT concept_id FROM concept_set WHERE concept_set = @ultrasoundOrderables) THEN 'Ultrasound'
  WHEN o.concept_id IN(SELECT concept_id FROM concept_set WHERE concept_set = @xrayOrderables) THEN 'Xray'
  ELSE ''
END AS modality,

CASE
  WHEN o.concept_id IN (SELECT concept_id FROM concept_set WHERE concept_set = @radiologyChest) THEN 'chest'
  WHEN o.concept_id IN (SELECT concept_id FROM concept_set WHERE concept_set = @radiologyHeadNeck) THEN 'head and neck'
  WHEN o.concept_id IN (SELECT concept_id FROM concept_set WHERE concept_set = @radiologySpine) THEN 'spine'
  WHEN o.concept_id IN (SELECT concept_id FROM concept_set WHERE concept_set = @radiologyVascular) THEN 'vascular'
  WHEN o.concept_id IN (SELECT concept_id FROM concept_set WHERE concept_set = @radiologyAbdomenPelvis) THEN 'abdomen and pelvis'
  WHEN o.concept_id IN (SELECT concept_id FROM concept_set WHERE concept_set = @radiologyMusculoskeletal) THEN 'musculoskeletal (non-cranial/spinal)'
  ELSE '?'
END AS anatomical_grouping,

ahe_section.user_generated_id as section_communale_CDC_ID

FROM patient p

--Most recent ZL EMR ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type = @zlId AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON p.patient_id = zl.patient_id

--ZL EMR ID location
INNER JOIN location zl_loc ON zl.location_id = zl_loc.location_id

--Unknown patient
LEFT OUTER JOIN person_attribute un ON p.patient_id = un.person_id AND un.person_attribute_type_id = @unknownPt AND un.voided = 0

--Person record
INNER JOIN person pr ON p.patient_id = pr.person_id AND pr.voided = 0

--Most recent address
LEFT OUTER JOIN (SELECT * FROM person_address WHERE voided = 0 ORDER BY date_created DESC) pa ON p.patient_id = pa.person_id

-- CDC ID of address
LEFT OUTER JOIN address_hierarchy_entry ahe_country on ahe_country.level_id = 1 and ahe_country.name = pa.country
LEFT OUTER JOIN address_hierarchy_entry ahe_dept on ahe_dept.level_id = 2 and ahe_dept.parent_id = ahe_country.address_hierarchy_entry_id and ahe_dept.name = pa.state_province
LEFT OUTER JOIN address_hierarchy_entry ahe_commune on ahe_commune.level_id = 3 and ahe_commune.parent_id = ahe_dept.address_hierarchy_entry_id and ahe_commune.name = pa.city_village
LEFT OUTER JOIN address_hierarchy_entry ahe_section on ahe_section.level_id = 4 and ahe_section.parent_id = ahe_commune.address_hierarchy_entry_id and ahe_section.name = pa.address3

--Most recent name
INNER JOIN (SELECT person_id, given_name, family_name FROM person_name WHERE voided = 0 ORDER BY date_created desc) n ON p.patient_id = n.person_id

--Associated radiology order encounter
INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type = @radEnc

--User who created the encounter
INNER JOIN users u ON e.creator = u.user_id
INNER JOIN person_name pn ON u.person_id = pn.person_id AND pn.voided = 0

--Provider with Ordering Provider encounter role on associated radiology order encounter
  INNER JOIN encounter_provider ep ON e.encounter_id = ep.encounter_id AND ep.voided = 0 AND ep.encounter_role_id = @orderingProvider
INNER JOIN provider epp ON ep.provider_id = epp.provider_id
INNER JOIN person_name provn ON epp.person_id = provn.person_id AND provn.voided = 0

--Location of encounter
INNER JOIN location el ON e.location_id = el.location_id

--Order
INNER JOIN orders o ON e.encounter_id = o.encounter_id AND o.voided = 0

--English order name
INNER JOIN concept_name ocn_en ON o.concept_id = ocn_en.concept_id AND ocn_en.voided = 0 AND ocn_en.locale = 'en'

--French order name
LEFT OUTER JOIN concept_name ocn_fr ON o.concept_id = ocn_fr.concept_id AND ocn_fr.voided = 0 AND ocn_fr.locale = 'fr'

WHERE p.voided = 0

--Exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = @testPt AND voided = 0)

AND e.encounter_datetime >= @startDate AND e.encounter_datetime < ADDDATE(@endDate, INTERVAL 1 DAY)

GROUP BY o.order_id

;
