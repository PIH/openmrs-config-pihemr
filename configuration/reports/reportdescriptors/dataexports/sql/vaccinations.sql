CALL initialize_global_metadata();

SELECT p.patient_id, dos.identifier dossierId, zl.identifier zlemr, zl_loc.name loc_registered, e.encounter_datetime, el.name encounter_location, et.name,
CONCAT(pn.given_name, ' ',pn.family_name) provider, obsjoins.*
FROM patient p

INNER JOIN encounter e ON p.patient_id = e.patient_id and e.voided = 0
 AND e.encounter_type in (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc, @ANCInitEnc, @ANCFollowEnc)

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
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'BACILLE CAMILE-GUERIN VACCINATION'
         and obsseq.value_numeric = 1 then date(obsdate.value_datetime) end) 'BCG dose 1',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'ORAL POLIO VACCINATION'
         and obsseq.value_numeric = 0 then date(obsdate.value_datetime) end) 'Polio dose 0',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'ORAL POLIO VACCINATION'
         and obsseq.value_numeric = 1 then date(obsdate.value_datetime) end) 'Polio dose 1',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'ORAL POLIO VACCINATION'
         and obsseq.value_numeric = 2 then date(obsdate.value_datetime) end) 'Polio dose 2',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'ORAL POLIO VACCINATION'
         and obsseq.value_numeric = 3 then date(obsdate.value_datetime) end) 'Polio dose 3',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'ORAL POLIO VACCINATION'
         and obsseq.value_numeric = 11 then date(obsdate.value_datetime) end) 'Polio Booster 1',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'ORAL POLIO VACCINATION'
         and obsseq.value_numeric = 12 then date(obsdate.value_datetime) end) 'Polio Booster 2',
max(CASE when crs_answer.name = 'CIEL' and crt_answer.code = '1423'
         and obsseq.value_numeric = 1 then date(obsdate.value_datetime) end) 'Pentavalent dose 1',
max(CASE when crs_answer.name = 'CIEL' and crt_answer.code = '1423'
         and obsseq.value_numeric = 2 then date(obsdate.value_datetime) end) 'Pentavalent dose 2',
max(CASE when crs_answer.name = 'CIEL' and crt_answer.code = '1423'
         and obsseq.value_numeric = 3 then date(obsdate.value_datetime) end) 'Pentavalent dose 3',
max(CASE when crs_answer.name = 'CIEL' and crt_answer.code = '83531'
         and obsseq.value_numeric = 1 then date(obsdate.value_datetime) end) 'Rotavirus dose 1',
max(CASE when crs_answer.name = 'CIEL' and crt_answer.code = '83531'
         and obsseq.value_numeric = 2 then date(obsdate.value_datetime) end) 'Rotavirus dose 2',
max(CASE when crs_answer.name = 'CIEL' and crt_answer.code = '162586'
         and obsseq.value_numeric = 1 then date(obsdate.value_datetime) end) 'Measles/Rubella dose 1',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'DIPTHERIA TETANUS BOOSTER'
         and obsseq.value_numeric = 0 then date(obsdate.value_datetime) end) 'DT dose 0',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'DIPTHERIA TETANUS BOOSTER'
         and obsseq.value_numeric = 1 then date(obsdate.value_datetime) end) 'DT dose 1',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'DIPTHERIA TETANUS BOOSTER'
         and obsseq.value_numeric = 2 then date(obsdate.value_datetime) end) 'DT dose 2',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'DIPTHERIA TETANUS BOOSTER'
         and obsseq.value_numeric = 3 then date(obsdate.value_datetime) end) 'DT dose 3',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'DIPTHERIA TETANUS BOOSTER'
         and obsseq.value_numeric = 11 then date(obsdate.value_datetime) end) 'DT Booster 1',
max(CASE when crs_answer.name = 'PIH' and crt_answer.code = 'DIPTHERIA TETANUS BOOSTER'
         and obsseq.value_numeric = 12 then date(obsdate.value_datetime) end) 'DT Booster 2'
from encounter e
INNER JOIN obs o on o.encounter_id = e.encounter_id and o.voided = 0
-- join in mapping of obs answer
LEFT OUTER JOIN concept_reference_map crm_answer on crm_answer.concept_id = o.value_coded
LEFT OUTER JOIN concept_reference_term crt_answer on crt_answer.concept_reference_term_id = crm_answer.concept_reference_term_id
LEFT OUTER JOIN concept_reference_source crs_answer on crs_answer.concept_source_id = crt_answer.concept_source_id
 -- include sequence number joined by obsgroupid
LEFT OUTER JOIN (select obs_group_id, value_numeric from obs where voided=0) obsseq on obsseq.obs_group_id = o.obs_group_id and obsseq.value_numeric is not null
 -- include vaccination date joined by obsgroupid
LEFT OUTER JOIN (select obs_group_id,  value_datetime from obs  where voided=0) obsdate on obsdate.obs_group_id = o.obs_group_id and obsdate.value_datetime is not null
where e.voided = 0
 group by encounter_id) obsjoins on obsjoins.encounter_id = e.encounter_id
WHERE p.voided = 0
-- exclude test patients
AND p.patient_id NOT IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = @testPt
                         AND voided = 0)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
GROUP BY e.encounter_id;
