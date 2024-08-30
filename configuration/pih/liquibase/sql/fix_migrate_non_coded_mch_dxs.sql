-- this is not in a liquibase changeset because it is a one-off script to fix a data migration issue
-- see: https://pihemr.atlassian.net/browse/HAI-995

-- confirm changeset has run (count should be 1)
select count(*) from liquibasechangelog where ID='20240122-migrate-noncoded-dxs';

-- create a temporary table to store the mappings
drop temporary table if exists dx_translations;
create temporary table dx_translations
(non_coded_dx text,
 code_dx       int(11)
);

insert into dx_translations (non_coded_dx, code_dx)
values
    ('Phase expulsive du travail',concept_from_mapping('CIEL','163506')),
    ('algie pelvienne',concept_from_mapping('CIEL','131034')),
    ('IGU prob.',concept_from_mapping('PIH','15052')),
    ('IGU pb',concept_from_mapping('PIH','15052')),
    ('epigastralgie',concept_from_mapping('CIEL','141128')),
    ('IGU',concept_from_mapping('PIH','15052')),
    ('uc1',concept_from_mapping('CIEL','168593')),
    ('IGU prob',concept_from_mapping('PIH','15052')),
    ('UC2',concept_from_mapping('CIEL','168594')),
    ('UTERUS MYOMATEUX',concept_from_mapping('CIEL','123455')),
    ('Mycose vaginale',concept_from_mapping('CIEL','298')),
    ('Uc1 ancien',concept_from_mapping('CIEL','168593')),
    ('HTA chronique',concept_from_mapping('CIEL','168592')),
    ('PES stab.',concept_from_mapping('CIEL','168611')),
    ('uterus polymyomateux',concept_from_mapping('CIEL','123455')),
    ('IGU probable',concept_from_mapping('PIH','15052')),
    ('Phase expulsive',concept_from_mapping('CIEL','163506')),
    ('Uc1 recent',concept_from_mapping('CIEL','168593')),
    ('SUA',concept_from_mapping('CIEL','141631')),
    ('Infection genito-urinaire',concept_from_mapping('PIH','15052')),
    ('Infection génito urinaire pb',concept_from_mapping('PIH','15052')),
    ('OMPK synd',concept_from_mapping('CIEL','129569')),
    ('Algie pelvienne chronique',concept_from_mapping('CIEL','155579')),
    ('Mycose vag',concept_from_mapping('CIEL','298')),
    ('ASCUS',concept_from_mapping('CIEL','145822')),
    ('suivi post op',concept_from_mapping('CIEL','159007')),
    ('BDCFNR',concept_from_mapping('CIEL','168595')),
    ('INFECTION GENITO URINAIRE',concept_from_mapping('PIH','15052')),
    ('infertilite primaire',concept_from_mapping('CIEL','129123')),
    ('OMPK',concept_from_mapping('CIEL','129569')),
    ('Perimenopause',concept_from_mapping('CIEL','160595')),
    ('IGU a inv',concept_from_mapping('PIH','15052')),
    ('Masse ovarienne',concept_from_mapping('CIEL','152755')),
    ('PES stabilisée',concept_from_mapping('CIEL','168611')),
    ('Infertilite secondaire',concept_from_mapping('CIEL','126976')),
    ('Infection génito urinaire',concept_from_mapping('PIH','15052')),
    ('HTAc',concept_from_mapping('CIEL','168592')),
    ('gardnerella vaginalis',concept_from_mapping('CIEL','139633')),
    ('PES prob.',concept_from_mapping('CIEL','113006')),
    ('AGUS',concept_from_mapping('CIEL','155209')),
    ('PCOS',concept_from_mapping('CIEL','129569')),
    ('HTA non controlee',concept_from_mapping('CIEL','165587')),
    ('anamnios',concept_from_mapping('CIEL','168588')),
    ('BDCF non rassurant',concept_from_mapping('CIEL','168595')),
    ('uc2 ancien',concept_from_mapping('CIEL','168594')),
    ('anemie probable',concept_from_mapping('CIEL','121629')),
    ('douleur epigastrique',concept_from_mapping('CIEL','141128')),
    ('PES stab',concept_from_mapping('CIEL','168611'));

-- sanity check, should be 0, do not continue if not
select count(*) from dx_translations;

-- get a count of the problematic obs, for reference
select count(*) from obs coded where coded.concept_id=concept_from_mapping('PIH','DIAGNOSIS') and coded.value_coded is null and coded.voided=0;

drop temporary table if exists coded_obs_to_recreate;
create temporary table coded_obs_to_recreate
(person_id                 int(11),
 concept_id              int(11),
 encounter_id              int(11),
 order_id                    int(11),
 obs_datetime              datetime,
 location_id               int(11),
 obs_group_id              int(11),
 accession_number    varchar(255),
 comments                    varchar(255),
 previous_version          int(11),
 non_coded_value   text,
 value_coded             int(11)
);

insert into coded_obs_to_recreate (
    person_id,
    concept_id,
    encounter_id,
    order_id,
    obs_datetime,
    location_id,
    obs_group_id,
    accession_number,
    comments,
    previous_version,
    non_coded_value)
select
    coded.person_id,
    coded.concept_id,
    coded.encounter_id,
    coded.order_id,
    coded.obs_datetime,
    coded.location_id,
    coded.obs_group_id,
    coded.accession_number,
    coded.comments,
    coded.obs_id,
    non_coded.value_text from obs coded, obs non_coded where
        non_coded.concept_id=concept_from_mapping('PIH','Diagnosis or problem, non-coded') and non_coded.voided=1 and non_coded.void_reason='migrated to coded mch dx' and
        coded.concept_id=concept_from_mapping('PIH','DIAGNOSIS') and coded.value_coded is null and coded.voided=0 and
    non_coded.obs_group_id is not null and coded.obs_group_id is not null and non_coded.obs_group_id = coded.obs_group_id;

-- figure out the coded obs to use for each
update coded_obs_to_recreate u, dx_translations t set u.value_coded = t.code_dx where upper(trim(t.non_coded_dx)) = upper(trim(u.non_coded_value));

-- record this number for sanity check later
select count(*) from coded_obs_to_recreate;

-- sanity check, should be 0, do not proceed if not
select count(*) from coded_obs_to_recreate where value_coded is null;

-- first void out the old obs that we are going recreate, to make sure if anything goes wrong we have the proper auditing infp
update obs o, coded_obs_to_recreate coded set o.voided=1, o.void_reason='fixed migration to coded mch dx', o.voided_by =  (select user_id from users where username = 'admin'), o.date_voided=now()
where coded.previous_version = o.obs_id;

-- sanity check, should equal the count of rows in coded_obs_to_recreate
select count(*) from obs where void_reason='fixed migration to coded mch dx';

# now actually insert the new coded obs into the table
insert into obs (
    person_id,
    concept_id,
    encounter_id,
    order_id,
    obs_datetime,
    location_id,
    obs_group_id,
    accession_number,
    value_coded,
    comments,
    creator,
    date_created,
    uuid,
    previous_version)
select person_id,
       concept_id,
       encounter_id,
       order_id,
       obs_datetime,
       location_id,
       obs_group_id,
       accession_number,
       value_coded,
       comments,
       (select user_id from users where username = 'admin'),
       now(),
       uuid(),
       previous_version
from coded_obs_to_recreate;


-- the previous count of these from above, minus the count of those with "fixed migration to coded mch dx", should equal this count
select count(*) from obs coded where coded.concept_id=concept_from_mapping('PIH','DIAGNOSIS') and coded.value_coded is null and coded.voided=0;
