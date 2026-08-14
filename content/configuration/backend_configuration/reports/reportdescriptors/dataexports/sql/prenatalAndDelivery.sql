CALL initialize_global_metadata();

SELECT p.patient_id, zl.identifier zlemr, dos.identifier dossier_id,
    zl_loc.name loc_registered, un.value unknown_patient, pr.gender,
    ROUND(DATEDIFF(e.encounter_datetime, pr.birthdate)/365.25, 1) age_at_enc,
    pa.state_province department, pa.city_village commune, pa.address3 section,
    pa.address1 locality, pa.address2 street_landmark,
    e.encounter_datetime, el.name encounter_location,
    CONCAT(pn.given_name, ' ',pn.family_name) provider, e.visit_id,
    obsjoins.encounter_id "Encounter_id", et.name "Encounter_Type",

    Mothers_Group_ID "Mothers_Group_ID",
    Trimester_at_Enrollment "Trimester_at_Enrollment",
    HIV_Test_Performed "HIV_Test_Performed",
    Mental_Health_Diagnosis "Mental_Health_Diagnosis",
    Risk_Factor "Risk_Factor",
    Other_Risk "Other_Risk",
    Gravida "Gravida",
    Para "Para",
    Abortus "Abortus",
    Living "Living",
    Due_Date "Due_Date",
    Last_Menstrual_Period "Last_Menstrual_Period",
    Return_Visit_Date "Return_Visit_Date",
    Delivery_Date "Delivery_Date",
    Delivery_Type "Delivery_Type",
    Apgar_Score "Apgar_Score",
    Delivery_Finding "Delivery_Finding",
    Other_Delivery_Finding "Other_Delivery_Finding",

    SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 1), ",", -1) Diagnosis_1,
    IF(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 2), ",", -1) <> SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 1), ",", -1),SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 2), ",", -1),NULL)  Diagnosis_2,
    IF(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 3), ",", -1) <> SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 2), ",", -1),SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 3), ",", -1),NULL)  Diagnosis_3,
    IF(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 4), ",", -1) <> SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 3), ",", -1),SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 4), ",", -1),NULL) Diagnosis_4,
    IF(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 5), ",", -1) <> SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 4), ",", -1),SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 5), ",", -1),NULL) Diagnosis_5,
    IF(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 6), ",", -1) <> SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 5), ",", -1),SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 6), ",", -1),NULL) Diagnosis_6,
    IF(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 7), ",", -1) <> SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 6), ",", -1),SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 7), ",", -1),NULL) Diagnosis_7,
    IF(SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 8), ",", -1) <> SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 7), ",", -1),SUBSTRING_INDEX(SUBSTRING_INDEX(GROUP_CONCAT(cn.name), "," , 8), ",", -1),NULL) Diagnosis_8

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
INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0 AND e.encounter_type in (@ANCInitEnc, @ANCFollowEnc, @DeliveryEnc)
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
    -- Intake
    max(CASE when rm.source = 'PIH' and rm.code = '11665' then o.value_text end) 'Mothers_Group_ID',
    max(CASE when rm.source = 'PIH' and rm.code = '11661' then cn.name end) 'Trimester_at_Enrollment',
    max(CASE when rm.source = 'CIEL' and rm.code = '164401' then cn.name end) 'HIV_Test_Performed',
    group_concat(CASE when rm.source = 'PIH' and rm.code = 'Mental health diagnosis' then cn.name end separator ',') 'Mental_Health_Diagnosis',
    group_concat(CASE when rm.source = 'CIEL' and rm.code = '160079' then cn.name end separator ',') 'Risk_Factor',
    max(CASE when rm.source = 'CIEL' and rm.code = '160079' then o.comments end) 'Other_Risk',
    max(CASE when rm.source = 'CIEL' and rm.code = '5624' then o.value_numeric end) 'Gravida',
    max(CASE when rm.source = 'CIEL' and rm.code = '1053' then o.value_numeric end) 'Para',
    max(CASE when rm.source = 'CIEL' and rm.code = '1823' then o.value_numeric end) 'Abortus',
    max(CASE when rm.source = 'CIEL' and rm.code = '1825' then o.value_numeric end) 'Living',
    max(CASE when rm.source = 'CIEL' and rm.code = '5596' then o.value_datetime end) 'Due_Date',
    max(CASE when rm.source = 'CIEL' and rm.code = '1427' then o.value_datetime end) 'Last_Menstrual_Period',
    max(CASE when rm.source = 'PIH' and rm.code = 'RETURN VISIT DATE' then o.value_datetime end) 'Return_Visit_Date',

    -- Delivery
    max(CASE when rm.source = 'CIEL' and rm.code = '5596' then o.value_datetime end) 'Delivery_Date',
    group_concat(CASE when rm.source = 'PIH' and rm.code = '11663' then cn.name end separator ',') 'Delivery_Type',
    max(CASE when rm.source = 'PIH' and rm.code = '11932' then cn.name end) 'Apgar_Score',
    group_concat(CASE when rm.source = 'PIH' and rm.code = '6644' then cn.name end separator ',') 'Delivery_Finding',
    max(CASE when rm.source = 'PIH' and rm.code = '6644' then o.comments end) 'Other_Delivery_Finding'

from encounter e, report_mapping rm, obs o

LEFT OUTER JOIN concept_name cn
  on o.value_coded = cn.concept_id
 and cn.locale = 'en'
 and cn.locale_preferred = '1'
 and cn.voided = 0
where 1=1
    and e.encounter_type in (@ANCInitEnc, @ANCFollowEnc, @DeliveryEnc)
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

LEFT OUTER JOIN
obs obs_diag ON obs_diag.encounter_id = e.encounter_id AND obs_diag.concept_id = diagcode.concept_id AND obs_diag.voided = 0
LEFT OUTER JOIN
concept_name cn ON obs_diag.value_coded = cn.concept_id AND locale = 'fr' AND cn.voided = 0 AND locale_preferred = 1
-- end columns joins

-- DOSSIER ID (The UUID is for Hôpital Universitaire de Mirebalais - Prensipal)
LEFT OUTER JOIN
(SELECT patient_id, location_id, identifier_type, identifier
   from patient_identifier WHERE identifier_type = @dosId
    AND location_id = (select location_id from location where uuid = '24bd1390-5959-11e4-8ed6-0800200c9a66')
    and voided = 0
 ORDER BY date_created DESC) dos ON p.patient_id = dos.patient_id
WHERE p.voided = 0


-- exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = @testPt
                         AND voided = 0)

AND date(e.encounter_datetime) >= date(@startDate)
AND date(e.encounter_datetime) <= date(@endDate)
GROUP BY e.encounter_id
order by e.encounter_datetime;
