-- set @startDate = '2021-03-01';
-- set @endDate = '2021-03-19';

CALL initialize_global_metadata();
 
DROP TEMPORARY TABLE IF EXISTS temp_cc;
CREATE TEMPORARY TABLE temp_cc
(
    patient_id            int(11),
    dossierId             varchar(50),
    zlemrid               varchar(50),
    loc_registered        varchar(255), 
    encounter_datetime    datetime,
    encounter_location    varchar(255), 
    encounter_type        varchar(255),                
    provider              varchar(255), 
    encounter_id          int(11),
    chief_complaint       varchar(255)
);

insert into temp_cc (
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

update temp_cc set zlemrid = zlemr(patient_id);
update temp_cc set dossierid = dosid(patient_id);
update temp_cc set loc_registered = loc_registered(patient_id);
update temp_cc set encounter_location = encounter_location_name(encounter_id);
update temp_cc set provider = provider(encounter_id);

update temp_cc set chief_complaint = obs_value_text(encounter_id, 'CIEL','160531');

 -- select final output
select * from temp_cc;
