SET @infant_concept_uuid       = '23eeeec5-7f82-4bea-8bdf-f959900882e7';
SET @birthtime_concept_uuid      = '5599AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
SET @inborn_visit_attribute_type_uuid = '86f716fc-5e26-4eb1-9484-46370cff28f0';

DROP TABLE IF EXISTS tmp_inborn_visit;

CREATE TABLE tmp_inborn_visit AS
SELECT v.*
FROM obs o1
JOIN concept c1 ON o1.concept_id = c1.concept_id
JOIN obs o2    ON o2.obs_group_id = o1.obs_group_id
JOIN concept c2 ON o2.concept_id = c2.concept_id
JOIN person p  ON p.uuid = o1.comments
JOIN visit v   ON v.patient_id   = p.person_id
              AND v.date_started = o2.value_datetime
WHERE c1.uuid = @infant_concept_uuid
  AND o1.comments REGEXP '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
  AND c2.uuid = @birthtime_concept_uuid
  AND o1.obs_group_id IS NOT NULL;

INSERT INTO visit_attribute
       (visit_id, attribute_type_id, value_reference, uuid, creator, date_created)
SELECT t.visit_id,
       vat.visit_attribute_type_id,
       'true',
       UUID(),
       t.creator,
       t.date_created
  FROM tmp_inborn_visit t
  JOIN visit_attribute_type vat
    ON vat.uuid = @inborn_visit_attribute_type_uuid
  LEFT JOIN visit_attribute va
         ON va.visit_id          = t.visit_id
        AND va.attribute_type_id = vat.visit_attribute_type_id
        AND va.value_reference   = 'true'
 WHERE va.visit_attribute_id IS NULL;

DROP TABLE IF EXISTS tmp_inborn_visit;
