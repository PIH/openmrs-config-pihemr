CALL initialize_global_metadata();

SELECT p.patient_id, zl.identifier zlemr, zl_loc.name loc_registered, un.value unknown_patient, pr.gender, ROUND(DATEDIFF(e.encounter_datetime, pr.birthdate)/365.25, 1) age_at_enc, pa.state_province department, pa.city_village commune, pa.address3 section, pa.address1 locality, pa.address2 street_landmark, e.encounter_id, e.encounter_datetime, el.name encounter_location,

ssrv_n.name surgical_service,
CONCAT(attending_n.given_name, ' ', attending_n.family_name) attending,
CONCAT(asst_1_n.given_name, ' ', asst_1_n.family_name) asst_1,
CONCAT(asst_2_n.given_name, ' ', asst_2_n.family_name) asst_2,
asst_nc.value_text other_asst,
CONCAT(anesth_1_n.given_name, ' ', anesth_1_n.family_name) anesth_1,
CONCAT(anesth_2_n.given_name, ' ', anesth_2_n.family_name) anesth_2,
CONCAT(nurse_1_n.given_name, ' ', nurse_1_n.family_name) nurse_1,
CONCAT(nurse_2_n.given_name, ' ', nurse_2_n.family_name) nurse_2,
preop_1_n.name preop_dx_1,
preop_2_n.name preop_dx_2,
preop_3_n.name preop_dx_3,
postop_1_n.name postop_dx_1,
postop_2_n.name postop_dx_2,
postop_3_n.name postop_dx_3,
procedure_1_n.name procedure_1,
procedure_2_n.name procedure_2,
procedure_3_n.name procedure_3,
procedure_4_n.name procedure_4,
procedure_5_n.name procedure_5,
anesthesia_n.name anesthesia, e.date_created,

--Mark as retrospective if more than 30 minutes elapsed between encounter date and creation
IF(TIME_TO_SEC(e.date_created) - TIME_TO_SEC(e.encounter_datetime) > 1800, TRUE, FALSE) retrospective,

e.visit_id, pr.birthdate, pr.birthdate_estimated,

admission_status_n.name as admission_status

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

INNER JOIN (SELECT person_id, given_name, family_name FROM person_name WHERE voided = 0 ORDER BY date_created desc) n ON p.patient_id = n.person_id

INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type = @postOpNoteEnc

INNER JOIN location el ON e.location_id = el.location_id

--Surgical service
LEFT OUTER JOIN obs ssrv ON e.encounter_id = ssrv.encounter_id AND ssrv.concept_id = 487 AND ssrv.voided = 0
LEFT OUTER JOIN concept_name ssrv_n ON ssrv.value_coded = ssrv_n.concept_id AND ssrv_n.locale = 'fr' AND ssrv_n.voided = 0 AND ssrv_n.locale_preferred = 1

--Attending
LEFT OUTER JOIN encounter_provider attending ON e.encounter_id = attending.encounter_id AND attending.voided = 0 AND attending.encounter_role_id = 6
LEFT OUTER JOIN provider attending_p ON attending.provider_id = attending_p.provider_id AND attending_p.retired = 0
LEFT OUTER JOIN person_name attending_n ON attending_p.person_id = attending_n.person_id AND attending_n.voided = 0

--Assistant 1
LEFT OUTER JOIN encounter_provider asst_1 ON e.encounter_id = asst_1.encounter_id AND asst_1.voided = 0 AND asst_1.encounter_role_id = 8
LEFT OUTER JOIN provider asst_1_p ON asst_1.provider_id = asst_1_p.provider_id AND asst_1_p.retired = 0
LEFT OUTER JOIN person_name asst_1_n ON asst_1_p.person_id = asst_1_n.person_id AND asst_1_n.voided = 0

--Assistant 2
LEFT OUTER JOIN encounter_provider asst_2 ON e.encounter_id = asst_2.encounter_id AND asst_2.voided = 0 AND asst_2.encounter_role_id = 8 AND asst_2.encounter_provider_id != asst_1.encounter_provider_id
LEFT OUTER JOIN provider asst_2_p ON asst_2.provider_id = asst_2_p.provider_id AND asst_2_p.retired = 0
LEFT OUTER JOIN person_name asst_2_n ON asst_2_p.person_id = asst_2_n.person_id AND asst_2_n.voided = 0

--Other assistant
LEFT OUTER JOIN obs asst_nc ON e.encounter_id = asst_nc.encounter_id AND asst_nc.concept_id = 469 AND asst_nc.voided = 0

--Anesthesiologist 1
LEFT OUTER JOIN encounter_provider anesth_1 ON e.encounter_id = anesth_1.encounter_id AND anesth_1.voided = 0 AND anesth_1.encounter_role_id = 7
LEFT OUTER JOIN provider anesth_1_p ON anesth_1.provider_id = anesth_1_p.provider_id AND anesth_1_p.retired = 0
LEFT OUTER JOIN person_name anesth_1_n ON anesth_1_p.person_id = anesth_1_n.person_id AND anesth_1_n.voided = 0

--Anesthesiologist 2
LEFT OUTER JOIN encounter_provider anesth_2 ON e.encounter_id = anesth_2.encounter_id AND anesth_2.voided = 0 AND anesth_2.encounter_role_id = 7 AND anesth_2.encounter_provider_id != anesth_1.encounter_provider_id
LEFT OUTER JOIN provider anesth_2_p ON anesth_2.provider_id = anesth_2_p.provider_id AND anesth_2_p.retired = 0
LEFT OUTER JOIN person_name anesth_2_n ON anesth_2_p.person_id = anesth_2_n.person_id AND anesth_2_n.voided = 0

--Nurse 1
LEFT OUTER JOIN encounter_provider nurse_1 ON e.encounter_id = nurse_1.encounter_id AND nurse_1.voided = 0 AND nurse_1.encounter_role_id = 3
LEFT OUTER JOIN provider nurse_1_p ON nurse_1.provider_id = nurse_1_p.provider_id AND nurse_1_p.retired = 0
LEFT OUTER JOIN person_name nurse_1_n ON nurse_1_p.person_id = nurse_1_n.person_id AND nurse_1_n.voided = 0

--Nurse 2
LEFT OUTER JOIN encounter_provider nurse_2 ON e.encounter_id = nurse_2.encounter_id AND nurse_2.voided = 0 AND nurse_2.encounter_role_id = 3 AND nurse_2.encounter_provider_id != nurse_1.encounter_provider_id
LEFT OUTER JOIN provider nurse_2_p ON nurse_2.provider_id = nurse_2_p.provider_id AND nurse_2_p.retired = 0
LEFT OUTER JOIN person_name nurse_2_n ON nurse_2_p.person_id = nurse_2_n.person_id AND nurse_2_n.voided = 0

--Pre-op Dx
LEFT OUTER JOIN obs preop_1 ON e.encounter_id = preop_1.encounter_id AND preop_1.concept_id = 445 AND preop_1.voided = 0
LEFT OUTER JOIN concept_name preop_1_n ON preop_1.value_coded = preop_1_n.concept_id AND preop_1_n.locale = 'fr' AND preop_1_n.locale_preferred = 1 AND preop_1_n.voided = 0
LEFT OUTER JOIN obs preop_2 ON e.encounter_id = preop_2.encounter_id AND preop_2.concept_id = 445 AND preop_2.voided = 0 AND preop_2.obs_id != preop_1.obs_id
LEFT OUTER JOIN concept_name preop_2_n ON preop_2.value_coded = preop_2_n.concept_id AND preop_2_n.locale = 'fr' AND preop_2_n.locale_preferred = 1 AND preop_2_n.voided = 0
LEFT OUTER JOIN obs preop_3 ON e.encounter_id = preop_3.encounter_id AND preop_3.concept_id = 445 AND preop_3.voided = 0 AND preop_3.obs_id NOT IN (preop_1.obs_id, preop_2.obs_id)
LEFT OUTER JOIN concept_name preop_3_n ON preop_3.value_coded = preop_3_n.concept_id AND preop_3_n.locale = 'fr' AND preop_3_n.locale_preferred = 1 AND preop_3_n.voided = 0

--Post-op Dx
LEFT OUTER JOIN obs postop_1 ON e.encounter_id = postop_1.encounter_id AND postop_1.concept_id = 523 AND postop_1.voided = 0
LEFT OUTER JOIN concept_name postop_1_n ON postop_1.value_coded = postop_1_n.concept_id AND postop_1_n.locale = 'fr' AND postop_1_n.locale_preferred = 1 AND postop_1_n.voided = 0
LEFT OUTER JOIN obs postop_2 ON e.encounter_id = postop_2.encounter_id AND postop_2.concept_id = 523 AND postop_2.voided = 0 AND postop_2.obs_id != postop_1.obs_id
LEFT OUTER JOIN concept_name postop_2_n ON postop_2.value_coded = postop_2_n.concept_id AND postop_2_n.locale = 'fr' AND postop_2_n.locale_preferred = 1 AND postop_2_n.voided = 0
LEFT OUTER JOIN obs postop_3 ON e.encounter_id = postop_3.encounter_id AND postop_3.concept_id = 523 AND postop_3.voided = 0 AND postop_3.obs_id NOT IN (postop_1.obs_id, postop_2.obs_id)
LEFT OUTER JOIN concept_name postop_3_n ON postop_3.value_coded = postop_3_n.concept_id AND postop_3_n.locale = 'fr' AND postop_3_n.locale_preferred = 1 AND postop_3_n.voided = 0

--Procedures
LEFT OUTER JOIN obs procedure_1 ON e.encounter_id = procedure_1.encounter_id AND procedure_1.concept_id = 470 AND procedure_1.voided = 0
LEFT OUTER JOIN concept_name procedure_1_n ON procedure_1.value_coded = procedure_1_n.concept_id AND procedure_1_n.locale = 'fr' AND procedure_1_n.locale_preferred = 1 AND procedure_1_n.voided = 0
LEFT OUTER JOIN obs procedure_2 ON e.encounter_id = procedure_2.encounter_id AND procedure_2.concept_id = 470 AND procedure_2.voided = 0 AND procedure_2.obs_id != procedure_1.obs_id
LEFT OUTER JOIN concept_name procedure_2_n ON procedure_2.value_coded = procedure_2_n.concept_id AND procedure_2_n.locale = 'fr' AND procedure_2_n.locale_preferred = 1 AND procedure_2_n.voided = 0
LEFT OUTER JOIN obs procedure_3 ON e.encounter_id = procedure_3.encounter_id AND procedure_3.concept_id = 470 AND procedure_3.voided = 0 AND procedure_3.obs_id NOT IN (procedure_1.obs_id, procedure_2.obs_id)
LEFT OUTER JOIN concept_name procedure_3_n ON procedure_3.value_coded = procedure_3_n.concept_id AND procedure_3_n.locale = 'fr' AND procedure_3_n.locale_preferred = 1 AND procedure_3_n.voided = 0
LEFT OUTER JOIN obs procedure_4 ON e.encounter_id = procedure_4.encounter_id AND procedure_4.concept_id = 470 AND procedure_4.voided = 0 AND procedure_4.obs_id NOT IN (procedure_1.obs_id, procedure_2.obs_id, procedure_3.obs_id)
LEFT OUTER JOIN concept_name procedure_4_n ON procedure_4.value_coded = procedure_4_n.concept_id AND procedure_4_n.locale = 'fr' AND procedure_4_n.locale_preferred = 1 AND procedure_4_n.voided = 0
LEFT OUTER JOIN obs procedure_5 ON e.encounter_id = procedure_5.encounter_id AND procedure_5.concept_id = 470 AND procedure_5.voided = 0 AND procedure_5.obs_id NOT IN (procedure_1.obs_id, procedure_2.obs_id, procedure_3.obs_id, procedure_4.obs_id)
LEFT OUTER JOIN concept_name procedure_5_n ON procedure_5.value_coded = procedure_5_n.concept_id AND procedure_5_n.locale = 'fr' AND procedure_5_n.locale_preferred = 1 AND procedure_5_n.voided = 0

--Anesthesia
LEFT OUTER JOIN obs anesthesia ON e.encounter_id = anesthesia.encounter_id AND anesthesia.concept_id = 508 AND anesthesia.voided = 0
LEFT OUTER JOIN concept_name anesthesia_n ON anesthesia.value_coded = anesthesia_n.concept_id AND anesthesia_n.locale = 'fr' AND anesthesia_n.locale_preferred = 1 AND anesthesia_n.voided = 0

--Admission status
LEFT OUTER JOIN obs admission_status ON e.encounter_id = admission_status.encounter_id AND admission_status.concept_id = @typeOfPatient AND admission_status.voided = 0
LEFT OUTER JOIN concept_name admission_status_n ON admission_status.value_coded = admission_status_n.concept_id AND admission_status_n.locale = 'fr' AND admission_status_n.locale_preferred = 1 AND admission_status_n.voided = 0

WHERE p.voided = 0

AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = @testPt AND voided = 0)

AND e.encounter_datetime >= @startDate AND e.encounter_datetime < ADDDATE(@endDate, INTERVAL 1 DAY)

GROUP BY e.encounter_id

;
