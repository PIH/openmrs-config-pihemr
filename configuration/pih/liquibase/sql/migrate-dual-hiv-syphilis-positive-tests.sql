SET @dual_hiv_syphilis_rdt_concept_uuid        = '7ff67b85-7c94-49f6-8187-786fb8f9dbdc';
SET @hiv_and_syphilis_positive_result_uuid     = '09586337-32d7-4693-bcd4-1ed66a4431b0';
SET @new_hiv_test_obsgroup_concept_uuid = '56740c9f-d86e-4240-ad59-7552385a8691';
SET @new_hiv_test_result_concept_uuid   = '3cd6c946-26fe-102b-80cb-0017a47871b2';
SET @new_hiv_test_result_value_uuid     = '3cd3a7a2-26fe-102b-80cb-0017a47871b2';
SET @new_syphilis_test_obsgroup_concept_uuid = 'ea5d701a-a8ec-48b2-84c3-2df1c25ac080';
SET @new_syphilis_test_result_concept_uuid   = '165303AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
SET @new_syphilis_test_result_positive_uuid  = '3cd8f3f6-26fe-102b-80cb-0017a47871b2';

DROP TABLE IF EXISTS tmp_migrate_hiv_test;

CREATE TABLE tmp_migrate_hiv_test AS
SELECT o.*
FROM obs o
WHERE o.voided = 0
  AND o.concept_id  = (SELECT concept_id FROM concept WHERE uuid = @dual_hiv_syphilis_rdt_concept_uuid)
  AND o.value_coded = (SELECT concept_id FROM concept WHERE uuid = @hiv_and_syphilis_positive_result_uuid);

ALTER TABLE tmp_migrate_hiv_test ADD COLUMN new_hiv_obs_uuid CHAR(38) DEFAULT NULL;
ALTER TABLE tmp_migrate_hiv_test ADD COLUMN new_hiv_obs_group_uuid   INT(11)  DEFAULT NULL;
ALTER TABLE tmp_migrate_hiv_test ADD COLUMN new_syphilis_obs_uuid CHAR(38) DEFAULT NULL;
ALTER TABLE tmp_migrate_hiv_test ADD COLUMN new_syphilis_obs_group_uuid   INT(11)  DEFAULT NULL;

UPDATE tmp_migrate_hiv_test SET new_hiv_obs_uuid = UUID();
UPDATE tmp_migrate_hiv_test SET new_syphilis_obs_uuid = UUID();

INSERT INTO obs
(person_id, concept_id, encounter_id, obs_datetime, location_id, creator,
 date_created, uuid)
SELECT t.person_id,
       (SELECT concept_id FROM concept WHERE uuid = @new_hiv_test_obsgroup_concept_uuid),
       t.encounter_id, t.obs_datetime, t.location_id, t.creator,
       NOW(), t.new_hiv_obs_uuid
FROM tmp_migrate_hiv_test t;

UPDATE tmp_migrate_hiv_test t, obs grp
SET t.new_hiv_obs_group_uuid = grp.obs_id
WHERE grp.uuid = t.new_hiv_obs_uuid;

INSERT INTO obs
(person_id, concept_id, value_coded, encounter_id, obs_datetime, location_id, creator,
 obs_group_id, date_created, uuid)
SELECT t.person_id,
       (SELECT concept_id FROM concept WHERE uuid = @new_hiv_test_result_concept_uuid),
       (SELECT concept_id FROM concept WHERE uuid = @new_hiv_test_result_value_uuid),
       t.encounter_id, t.obs_datetime, t.location_id, t.creator,
       t.new_hiv_obs_group_uuid,
       NOW(), UUID()
FROM tmp_migrate_hiv_test t
WHERE t.new_hiv_obs_group_uuid IS NOT NULL;

-- create Syphilis RDT obs group
INSERT INTO obs
(person_id, concept_id, encounter_id, obs_datetime, location_id, creator,
 date_created, uuid)
SELECT t.person_id,
       (SELECT concept_id FROM concept WHERE uuid = @new_syphilis_test_obsgroup_concept_uuid),
       t.encounter_id, t.obs_datetime, t.location_id, t.creator,
       NOW(), t.new_syphilis_obs_uuid
FROM tmp_migrate_hiv_test t;

UPDATE tmp_migrate_hiv_test t, obs grp
SET t.new_syphilis_obs_group_uuid = grp.obs_id
WHERE grp.uuid = t.new_syphilis_obs_uuid;

INSERT INTO obs
(person_id, concept_id, value_coded, encounter_id, obs_datetime, location_id, creator,
 obs_group_id, date_created, uuid)
SELECT t.person_id,
       (SELECT concept_id FROM concept WHERE uuid = @new_syphilis_test_result_concept_uuid),
       (SELECT concept_id FROM concept WHERE uuid = @new_syphilis_test_result_positive_uuid),
       t.encounter_id, t.obs_datetime, t.location_id, t.creator,
       t.new_syphilis_obs_group_uuid,
       NOW(), UUID()
FROM tmp_migrate_hiv_test t
WHERE t.new_syphilis_obs_group_uuid IS NOT NULL;

UPDATE obs o, tmp_migrate_hiv_test t
SET o.voided      = 1,
    o.voided_by   = t.creator,
    o.date_voided = NOW(),
    o.void_reason = 'SL-1332, migrate dual HIV/syphilis RDT positive results'
WHERE o.obs_id = t.obs_id;

DROP TABLE IF EXISTS tmp_migrate_hiv_test;
