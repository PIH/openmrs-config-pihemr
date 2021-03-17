CALL initialize_global_metadata();

DROP TEMPORARY TABLE IF EXISTS temp_supplement;
CREATE TEMPORARY TABLE temp_supplement
(
    patient_id            int(11),
    dossierId             varchar(50),
    zlemrid               varchar(50),
    loc_registered        varchar(255),
    encounter_datetime    datetime,
    encounter_location    varchar(255),
    encounter_type        varchar(255),
    provider              varchar(255),
    encounter_id          int(11),--
    Vitamin_A             varchar(3),
    Vitamin_A_Age         varchar(255),
    Ferrous_Sulfate       varchar(3),
    Ferrous_Sulfate_Age   varchar(255),
    Iodine                varchar(3),
    Iodine_Age            varchar(255),
    Deworming             varchar(3),
    Deworming_Age         varchar(255),
    Zinc                  varchar(3),
    Zinc_Age              varchar(255)
);

insert into temp_supplement (
  patient_id,
  encounter_id,
  encounter_datetime,
  encounter_type)
select
  patient_id,
  encounter_id,
  encounter_datetime,
  et.name
from encounter e
inner join encounter_type et on et.encounter_type_id = e.encounter_type
where e.encounter_type in (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
and voided = 0
;

update temp_supplement set zlemrid = zlemr(patient_id);
update temp_supplement set dossierid = dosid(patient_id);
update temp_supplement set loc_registered = loc_registered(patient_id);
update temp_supplement set encounter_location = encounter_location_name(encounter_id);
update temp_supplement set provider = provider(encounter_id);

update temp_supplement set Vitamin_A = obs_single_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','VITAMIN A');
update temp_supplement set Ferrous_Sulfate = obs_single_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','FERROUS SULFATE');
update temp_supplement set Iodine = obs_single_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','IODINE');
update temp_supplement set Deworming = obs_single_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','DEWORMING');
update temp_supplement set Zinc = obs_single_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','ZINC');

update temp_supplement set Vitamin_A_Age = obs_from_group_id_value_text(obs_group_id_of_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','VITAMIN A'),'PIH','AGE SUPPLEMENT RECEIVED') ;
update temp_supplement set Ferrous_Sulfate_Age = obs_from_group_id_value_text(obs_group_id_of_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','FERROUS SULFATE'),'PIH','AGE SUPPLEMENT RECEIVED') ;
update temp_supplement set Iodine_Age = obs_from_group_id_value_text(obs_group_id_of_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','IODINE'),'PIH','AGE SUPPLEMENT RECEIVED') ;
update temp_supplement set Deworming_Age = obs_from_group_id_value_text(obs_group_id_of_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','DEWORMING'),'PIH','AGE SUPPLEMENT RECEIVED') ;
update temp_supplement set Zinc_Age = obs_from_group_id_value_text(obs_group_id_of_value_coded(encounter_id, 'PIH','SUPPLEMENT RECEIVED', 'PIH','ZINC'),'PIH','AGE SUPPLEMENT RECEIVED') ;

 -- select final output
select * from temp_supplement;