-- set @startDate = '2001-03-15';
-- set @endDate = '2021-03-19';

CALL initialize_global_metadata();
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
select encounter_type_id into @obgynnote from encounter_type where uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d'; 
 
DROP TEMPORARY TABLE IF EXISTS temp_vaccinations;
CREATE TEMPORARY TABLE temp_vaccinations
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
    BCG_dose_1            datetime,
    Polio_dose_0          datetime,
    Polio_dose_1          datetime,
    Polio_dose_2          datetime,
  Polio_dose_3            datetime,
    Polio_Booster_1       datetime,
    Polio_Booster_2       datetime,
    Pentavalent_dose_1    datetime,
    Pentavalent_dose_2    datetime,
    Pentavalent_dose_3    datetime,
    Rotavirus_dose_1      datetime,
    Rotavirus_dose_2      datetime,
    Measles_Rubella_dose_1 datetime,
    DT_dose_0             datetime,
    DT_dose_1             datetime,
    DT_dose_2             datetime,
    DT_dose_3             datetime,
    DT_Booster_1          datetime,
    DT_Booster_2          datetime
);

insert into temp_vaccinations (
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
where e.encounter_type in (@obgynnote)
 AND date(e.encounter_datetime) >=@startDate
 AND date(e.encounter_datetime) <=@endDate
and voided = 0
;

update temp_vaccinations set zlemrid = zlemr(patient_id);
update temp_vaccinations set dossierid = dosid(patient_id);
update temp_vaccinations set loc_registered = loc_registered(patient_id);
update temp_vaccinations set encounter_location = encounter_location_name(encounter_id);
update temp_vaccinations set provider = provider(encounter_id);

set @immunization = concept_from_mapping('CIEL','984');
set @sequence = concept_from_mapping('CIEL','1418');

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','BACILLE CAMILE-GUERIN VACCINATION'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 1)
 set t.BCG_dose_1 = o.value_datetime;

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','ORAL POLIO VACCINATION'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 0)
 set t.Polio_dose_0 = o.value_datetime;

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','ORAL POLIO VACCINATION'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 1)
 set t.Polio_dose_1 = o.value_datetime;
 
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','ORAL POLIO VACCINATION'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id
    and o2.concept_id = @sequence
    and o2.value_numeric = 2)
 set t.Polio_dose_2 = o.value_datetime;
 
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','ORAL POLIO VACCINATION'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 3)
 set t.Polio_dose_3 = o.value_datetime;
 
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','ORAL POLIO VACCINATION'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 11)
 set t.Polio_Booster_1 = o.value_datetime;
 
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','ORAL POLIO VACCINATION'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 12)
 set t.Polio_Booster_2 = o.value_datetime;
 
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('CIEL','1423'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 1)
 set t.Pentavalent_dose_1 = o.value_datetime;
  
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('CIEL','1423'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 2)
 set t.Pentavalent_dose_2 = o.value_datetime;
  
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('CIEL','1423'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 3)
 set t.Pentavalent_dose_3 = o.value_datetime;
 
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('CIEL','83531'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 1)
 set t.Rotavirus_dose_1 = o.value_datetime;
 
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('CIEL','83531'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 2)
 set t.Rotavirus_dose_2 = o.value_datetime;
 
update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('CIEL','162586'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 1)
 set t.Measles_Rubella_dose_1 = o.value_datetime;

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','DIPTHERIA TETANUS BOOSTER'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 0)
 set t.DT_dose_0 = o.value_datetime;

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','DIPTHERIA TETANUS BOOSTER'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 1)
 set t.DT_dose_1 = o.value_datetime;

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','DIPTHERIA TETANUS BOOSTER'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 2)
 set t.DT_dose_2 = o.value_datetime;

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','DIPTHERIA TETANUS BOOSTER'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 3)
 set t.DT_dose_3 = o.value_datetime;

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','DIPTHERIA TETANUS BOOSTER'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 11)
 set t.DT_Booster_1 = o.value_datetime;

update temp_vaccinations t
inner join obs o on o.encounter_id = t.encounter_id  and o.voided = 0 and o.concept_id = concept_from_mapping('CIEL','1410')
  and o.obs_group_id in
    (select obs_group_id from obs o1
    where o1.voided = 0
    and o1.concept_id = @immunization
    and o1.value_coded = concept_from_mapping('PIH','DIPTHERIA TETANUS BOOSTER'))
  and o.obs_group_id in 
    (select obs_group_id from obs o2 
    where o2.encounter_id = t.encounter_id and o2.voided = 0
    and o2.concept_id = @sequence
    and o2.value_numeric = 12)
 set t.DT_Booster_2 = o.value_datetime;

 -- select final output
select * from temp_vaccinations;
