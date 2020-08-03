CALL initialize_global_metadata();

SELECT p.patient_id, zl.identifier zlemr, zl_loc.name loc_registered, un.value unknown_patient, pr.gender, ROUND(DATEDIFF(e.encounter_datetime, pr.birthdate)/365.25, 1) age_at_enc, pa.state_province department, pa.city_village commune, pa.address3 section, pa.address1 locality, pa.address2 street_landmark, e.encounter_id, e.encounter_datetime, el.name encounter_location, CONCAT(pn.given_name, ' ', pn.family_name) entered_by, CONCAT(provn.given_name, ' ', provn.family_name) provider, COUNT(o.order_id) num_orders, e.date_created,

--Mark as retrospective if more than 30 minutes elapsed between encounter date and creation
IF(TIME_TO_SEC(e.date_created) - TIME_TO_SEC(e.encounter_datetime) > 1800, TRUE, FALSE) retrospective,

e.visit_id, pr.birthdate, pr.birthdate_estimated,

CASE
  WHEN ct_set.concept_id is not null THEN 'CT'
  WHEN us_set.concept_id is not null THEN 'Ultrasound'
  WHEN xray_set.concept_id is not null THEN 'Xray'
  ELSE ''
END as modality,

test_order.clinical_history,

ahe_section.user_generated_id as section_communale_CDC_ID

FROM patient p

--Most recent ZL EMR ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type = @zlId AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON p.patient_id = zl.patient_id

--ZL EMR ID location
INNER JOIN location zl_loc ON zl.location_id = zl_loc.location_id

--Unknown patient
LEFT OUTER JOIN person_attribute un ON p.patient_id = un.person_id AND un.person_attribute_type_id = @unknownPt AND un.voided = 0

--Person
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

--Radiology order encounter
INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type = @radEnc

--User who created the encounter
INNER JOIN users u ON e.creator = u.user_id
INNER JOIN person_name pn ON u.person_id = pn.person_id AND pn.voided = 0

--Provider with Ordering Provider encounter role
INNER JOIN encounter_provider ep ON e.encounter_id = ep.encounter_id AND ep.voided = 0 AND ep.encounter_role_id = @orderingProvider
INNER JOIN provider epp ON ep.provider_id = epp.provider_id
INNER JOIN person_name provn ON epp.person_id = provn.person_id AND provn.voided = 0

--Location of encounter
INNER JOIN location el ON e.location_id = el.location_id

--Radiology order associated with encounter
INNER JOIN orders o ON e.encounter_id = o.encounter_id AND o.voided = 0

INNER JOIN test_order ON test_order.order_id = o.order_id

-- Is ths order an Xray?
LEFT OUTER JOIN concept_set xray_set ON o.concept_id = xray_set.concept_id AND xray_set.concept_set = @xrayOrderables

-- Is the order a CT?
LEFT OUTER JOIN concept_set ct_set ON o.concept_id = ct_set.concept_id AND ct_set.concept_set = @ctOrderables

-- Is the order an Ultrasound?
LEFT OUTER JOIN concept_set us_set ON o.concept_id = us_set.concept_id AND us_set.concept_set = @ultrasoundOrderables

WHERE p.voided = 0

--Exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = @testPt AND voided = 0)

AND e.encounter_datetime >= @startDate AND e.encounter_datetime < ADDDATE(@endDate, INTERVAL 1 DAY)

GROUP BY e.encounter_id

;
