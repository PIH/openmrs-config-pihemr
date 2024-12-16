CALL initialize_global_metadata();

SELECT p.patient_id, zl.identifier zlemr, zl_loc.name loc_registered, un.value unknown_patient, pr.gender, ROUND(DATEDIFF(e.encounter_datetime, pr.birthdate)/365.25, 1) age_at_enc, pa.state_province department, pa.city_village commune, pa.address3 section, pa.address1 locality, pa.address2 street_landmark, e.encounter_id, e.encounter_datetime, el.name encounter_location,

scheduled_n.name scheduled,
planned_n.name planned_return,
wound_n.name wound_classification,
fluids_n.name fluids_administered,
volume.value_numeric fluids_volume,
transfusion_n.name transfusion,
IF(whole_blood.obs_id IS NOT NULL, 'Oui', 'Non') whole_blood,
whole_blood_qty.value_numeric whole_blood_qty,
IF(plasma.obs_id IS NOT NULL, 'Oui', 'Non') plasma,
plasma_qty.value_numeric plasma_qty,
IF(platelets.obs_id IS NOT NULL, 'Oui', 'Non') platelets,
platelets_qty.value_numeric platelets_qty,
IF(packed_cells.obs_id IS NOT NULL, 'Oui', 'Non') packed_cells,
packed_cells_qty.value_numeric packed_cells_qty,
blood_loss.value_numeric est_blood_loss,
urine_output.value_numeric total_urine_output,
antibiotics_n.name antibiotics_administered,
antibiotics_type_n.name antibiotics_type,
venous_proph_n.name venous_throm_proph,
pathology_n.name pathology_specimen,
pathology_comment.value_text pathology_comment,
lab_n.name lab_specimen,
lab_comment.value_text lab_comment,
implant_n.name implant,
implant_comment.value_text implant_comment,
complication_n.name complication,
plan.value_text plan, e.date_created,

--Mark as retrospective if more than 30 minutes elapsed between encounter date and creation
IF(TIME_TO_SEC(e.date_created) - TIME_TO_SEC(e.encounter_datetime) > 1800, TRUE, FALSE) retrospective,
emergency_n.name emergency, e.visit_id, pr.birthdate, pr.birthdate_estimated,
ahe_section.user_generated_id as section_communale_CDC_ID

FROM patient p

--Most recent ZL EMR ID
INNER JOIN (SELECT patient_id, identifier, location_id FROM patient_identifier WHERE identifier_type = @zlId AND voided = 0 AND preferred = 1 ORDER BY date_created DESC) zl ON p.patient_id = zl.patient_id

--ZL EMR ID location
INNER JOIN location zl_loc ON zl.location_id = zl_loc.location_id

--Unknown patient
LEFT OUTER JOIN person_attribute un ON p.patient_id = un.person_id AND un.person_attribute_type_id = @unknownPt AND un.voided = 0

INNER JOIN person pr ON p.patient_id = pr.person_id AND pr.voided = 0

-- Most recent address
LEFT OUTER JOIN (SELECT * FROM person_address WHERE voided = 0 ORDER BY date_created DESC) pa ON p.patient_id = pa.person_id

-- CDC ID of address
LEFT OUTER JOIN address_hierarchy_entry ahe_country on ahe_country.level_id = 1 and ahe_country.name = pa.country
LEFT OUTER JOIN address_hierarchy_entry ahe_dept on ahe_dept.level_id = 2 and ahe_dept.parent_id = ahe_country.address_hierarchy_entry_id and ahe_dept.name = pa.state_province
LEFT OUTER JOIN address_hierarchy_entry ahe_commune on ahe_commune.level_id = 3 and ahe_commune.parent_id = ahe_dept.address_hierarchy_entry_id and ahe_commune.name = pa.city_village
LEFT OUTER JOIN address_hierarchy_entry ahe_section on ahe_section.level_id = 4 and ahe_section.parent_id = ahe_commune.address_hierarchy_entry_id and ahe_section.name = pa.address3

INNER JOIN (SELECT person_id, given_name, family_name FROM person_name WHERE voided = 0 ORDER BY date_created desc) n ON p.patient_id = n.person_id

INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type = @postOpNoteEnc

INNER JOIN location el ON e.location_id = el.location_id

--Emergency
LEFT OUTER JOIN obs emergency ON e.encounter_id = emergency.encounter_id AND emergency.concept_id = 525 AND emergency.voided = 0
LEFT OUTER JOIN concept_name emergency_n ON emergency.value_coded = emergency_n.concept_id AND emergency_n.locale = 'fr' AND emergency_n.locale_preferred = 1 AND emergency_n.voided = 0

--Scheduled
LEFT OUTER JOIN obs scheduled ON e.encounter_id = scheduled.encounter_id AND scheduled.concept_id = 441 AND scheduled.voided = 0
LEFT OUTER JOIN concept_name scheduled_n ON scheduled.value_coded = scheduled_n.concept_id AND scheduled_n.locale = 'fr' AND scheduled_n.locale_preferred = 1 AND scheduled_n.voided = 0

--Planned
LEFT OUTER JOIN obs planned ON e.encounter_id = planned.encounter_id AND planned.concept_id = 440 AND planned.voided = 0
LEFT OUTER JOIN concept_name planned_n ON planned.value_coded = planned_n.concept_id AND planned_n.locale = 'fr' AND planned_n.locale_preferred = 1 AND planned_n.voided = 0

--Wound
LEFT OUTER JOIN obs wound ON e.encounter_id = wound.encounter_id AND wound.concept_id = 522 AND wound.voided = 0
LEFT OUTER JOIN concept_name wound_n ON wound.value_coded = wound_n.concept_id AND wound_n.locale = 'fr' AND wound_n.locale_preferred = 1 AND wound_n.voided = 0

--Fluids
LEFT OUTER JOIN obs fluids ON e.encounter_id = fluids.encounter_id AND fluids.concept_id = 496 AND fluids.voided = 0
LEFT OUTER JOIN concept_name fluids_n ON fluids.value_coded = fluids_n.concept_id AND fluids_n.locale = 'fr' AND fluids_n.locale_preferred = 1 AND fluids_n.voided = 0

--Volume
LEFT OUTER JOIN obs volume ON e.encounter_id = volume.encounter_id AND volume.concept_id = 488 AND volume.voided = 0

--Transfusion
LEFT OUTER JOIN obs transfusion ON e.encounter_id = transfusion.encounter_id AND transfusion.concept_id = 443 AND transfusion.voided = 0
LEFT OUTER JOIN concept_name transfusion_n ON transfusion.value_coded = transfusion_n.concept_id AND transfusion_n.locale = 'fr' AND transfusion_n.locale_preferred = 1 AND transfusion_n.voided = 0

--Type and volume
LEFT OUTER JOIN obs whole_blood ON e.encounter_id = whole_blood.encounter_id AND whole_blood.concept_id = 475 AND whole_blood.value_coded = 474 AND whole_blood.voided = 0
LEFT OUTER JOIN obs whole_blood_qty ON whole_blood.obs_group_id = whole_blood_qty.obs_group_id AND whole_blood_qty.concept_id = 510 AND whole_blood_qty.voided = 0
LEFT OUTER JOIN obs plasma ON e.encounter_id = plasma.encounter_id AND plasma.concept_id = 475 AND plasma.value_coded = 473 AND plasma.voided = 0
LEFT OUTER JOIN obs plasma_qty ON plasma.obs_group_id = plasma_qty.obs_group_id AND plasma_qty.concept_id = 510 AND plasma_qty.voided = 0
LEFT OUTER JOIN obs platelets ON e.encounter_id = platelets.encounter_id AND platelets.concept_id = 475 AND platelets.value_coded = 472 AND platelets.voided = 0
LEFT OUTER JOIN obs platelets_qty ON platelets.obs_group_id = platelets_qty.obs_group_id AND platelets_qty.concept_id = 510 AND platelets_qty.voided = 0
LEFT OUTER JOIN obs packed_cells ON e.encounter_id = packed_cells.encounter_id AND packed_cells.concept_id = 475 AND packed_cells.value_coded = 471 AND packed_cells.voided = 0
LEFT OUTER JOIN obs packed_cells_qty ON packed_cells.obs_group_id = packed_cells_qty.obs_group_id AND packed_cells_qty.concept_id = 510 AND packed_cells_qty.voided = 0

--Blood loss
LEFT OUTER JOIN obs blood_loss ON e.encounter_id = blood_loss.encounter_id AND blood_loss.concept_id = 446 AND blood_loss.voided = 0

--Urine output
LEFT OUTER JOIN obs urine_output ON e.encounter_id = urine_output.encounter_id AND urine_output.concept_id = 500 AND urine_output.voided = 0

--Antibiotics
LEFT OUTER JOIN obs antibiotics ON e.encounter_id = antibiotics.encounter_id AND antibiotics.concept_id = 524 AND antibiotics.voided = 0
LEFT OUTER JOIN concept_name antibiotics_n ON antibiotics.value_coded = antibiotics_n.concept_id AND antibiotics_n.locale = 'fr' AND antibiotics_n.locale_preferred = 1 AND antibiotics_n.voided = 0
LEFT OUTER JOIN obs antibiotics_type ON e.encounter_id = antibiotics_type.encounter_id AND antibiotics_type.concept_id = 459 AND antibiotics_type.voided = 0
LEFT OUTER JOIN concept_name antibiotics_type_n ON antibiotics_type.value_coded = antibiotics_type_n.concept_id AND antibiotics_type_n.locale = 'fr' AND antibiotics_type_n.locale_preferred = 1 AND antibiotics_type_n.voided = 0
LEFT OUTER JOIN obs venous_proph ON e.encounter_id = venous_proph.encounter_id AND venous_proph.concept_id = 517 AND venous_proph.voided = 0
LEFT OUTER JOIN concept_name venous_proph_n ON venous_proph.value_coded = venous_proph_n.concept_id AND venous_proph_n.locale = 'fr' AND venous_proph_n.locale_preferred = 1 AND venous_proph_n.voided = 0

--Pathology sample
LEFT OUTER JOIN obs pathology ON e.encounter_id = pathology.encounter_id AND pathology.concept_id = 498 AND pathology.voided = 0
LEFT OUTER JOIN concept_name pathology_n ON pathology.value_coded = pathology_n.concept_id AND pathology_n.locale = 'fr' AND pathology_n.locale_preferred = 1 AND pathology_n.voided = 0
LEFT OUTER JOIN obs pathology_comment ON e.encounter_id = pathology_comment.encounter_id AND pathology_comment.concept_id = 499 AND pathology_comment.voided = 0

--Lab sample
LEFT OUTER JOIN obs lab ON e.encounter_id = lab.encounter_id AND lab.concept_id = 442 AND lab.voided = 0
LEFT OUTER JOIN concept_name lab_n ON lab.value_coded = lab_n.concept_id AND lab_n.locale = 'fr' AND lab_n.locale_preferred = 1 AND lab_n.voided = 0
LEFT OUTER JOIN obs lab_comment ON e.encounter_id = lab_comment.encounter_id AND lab_comment.concept_id = 526 AND lab_comment.voided = 0

--Implant
LEFT OUTER JOIN obs implant ON e.encounter_id = implant.encounter_id AND implant.concept_id = 468 AND implant.voided = 0
LEFT OUTER JOIN concept_name implant_n ON implant.value_coded = implant_n.concept_id AND implant_n.locale = 'fr' AND implant_n.locale_preferred = 1 AND implant_n.voided = 0
LEFT OUTER JOIN obs implant_comment ON e.encounter_id = implant_comment.encounter_id AND implant_comment.concept_id = 509 AND implant_comment.voided = 0

--Complications
LEFT OUTER JOIN obs complication ON e.encounter_id = complication.encounter_id AND complication.concept_id = 439 AND complication.voided = 0
LEFT OUTER JOIN concept_name complication_n ON complication.value_coded = complication_n.concept_id AND complication_n.locale = 'fr' AND complication_n.locale_preferred = 1 AND complication_n.voided = 0

--Plan
LEFT OUTER JOIN obs plan ON e.encounter_id = plan.encounter_id AND plan.concept_id = 444 AND plan.voided = 0

WHERE p.voided = 0

AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = @testPt AND voided = 0)

AND e.encounter_datetime >= @startDate AND e.encounter_datetime < ADDDATE(@endDate, INTERVAL 1 DAY)

GROUP BY e.encounter_id

;
