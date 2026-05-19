SET @old_hiv_test_concept_uuid          = '7ff67b85-7c94-49f6-8187-786fb8f9dbdc';
SET @old_hiv_test_result_value_uuid     = '9f2bc0b1-3c77-4850-9fbc-9d138813fa4c';
SET @new_hiv_test_obsgroup_concept_uuid = '56740c9f-d86e-4240-ad59-7552385a8691';
SET @new_hiv_test_result_concept_uuid   = '3cd6c946-26fe-102b-80cb-0017a47871b2';
SET @new_hiv_test_positive_result_value_id  = (SELECT concept_id FROM concept WHERE uuid ='3cd3a7a2-26fe-102b-80cb-0017a47871b2');
SET @anc_intake_encounter_id  = (select encounter_type_id from encounter_type where uuid= '00e5e810-90ec-11e8-9eb6-529269fb1459');
SET @anc_followup_encounter_id  = (select encounter_type_id from encounter_type where uuid= '00e5e946-90ec-11e8-9eb6-529269fb1459');

DROP TABLE IF EXISTS tmp_migrate_hiv_test;

CREATE TABLE tmp_migrate_hiv_test AS
SELECT o.*
FROM obs o
WHERE o.voided = 0
  AND o.concept_id  = (SELECT concept_id FROM concept WHERE uuid = @old_hiv_test_concept_uuid)
  AND o.value_coded = (SELECT concept_id FROM concept WHERE uuid = @old_hiv_test_result_value_uuid)
UNION
SELECT o.*
FROM obs o, encounter e
WHERE o.encounter_id = e.encounter_id and e.encounter_type in (@anc_intake_encounter_id, @anc_followup_encounter_id)
  and o.obs_group_id is null and o.voided = 0
  AND o.concept_id  = (SELECT concept_id FROM concept WHERE uuid = @new_hiv_test_result_concept_uuid)
  AND o.value_coded = @new_hiv_test_positive_result_value_id;

ALTER TABLE tmp_migrate_hiv_test ADD COLUMN new_obs_group_uuid CHAR(38) DEFAULT NULL;
ALTER TABLE tmp_migrate_hiv_test ADD COLUMN new_obs_group_id   INT(11)  DEFAULT NULL;

UPDATE tmp_migrate_hiv_test SET new_obs_group_uuid = UUID();

INSERT INTO obs
    (person_id, concept_id, encounter_id, obs_datetime, location_id, creator,
     date_created, uuid)
SELECT t.person_id,
       (SELECT concept_id FROM concept WHERE uuid = @new_hiv_test_obsgroup_concept_uuid),
       t.encounter_id, t.obs_datetime, t.location_id, t.creator,
       NOW(), t.new_obs_group_uuid
FROM tmp_migrate_hiv_test t;

UPDATE tmp_migrate_hiv_test t, obs grp
   SET t.new_obs_group_id = grp.obs_id
 WHERE grp.uuid = t.new_obs_group_uuid;

INSERT INTO obs
    (person_id, concept_id, value_coded, encounter_id, obs_datetime, location_id, creator,
     obs_group_id, date_created, uuid)
SELECT t.person_id,
       (SELECT concept_id FROM concept WHERE uuid = @new_hiv_test_result_concept_uuid),
       @new_hiv_test_positive_result_value_id,
       t.encounter_id, t.obs_datetime, t.location_id, t.creator,
       t.new_obs_group_id,
       NOW(), UUID()
FROM tmp_migrate_hiv_test t
WHERE t.new_obs_group_id IS NOT NULL;

UPDATE obs o, tmp_migrate_hiv_test t
   SET o.voided      = 1,
       o.voided_by   = t.creator,
       o.date_voided = NOW(),
       o.void_reason = 'SL-1332, migrate HIV rapid test'
 WHERE o.obs_id = t.obs_id;

DROP TABLE IF EXISTS tmp_migrate_hiv_test;
