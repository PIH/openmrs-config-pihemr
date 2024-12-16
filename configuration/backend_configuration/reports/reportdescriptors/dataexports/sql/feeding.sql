-- set @startDate = '2021-03-01';
-- set @endDate = '2021-03-12';

CALL initialize_global_metadata();
 
DROP TEMPORARY TABLE IF EXISTS temp_feeding;
CREATE TEMPORARY TABLE temp_feeding
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
    Breastfeed_Exclusively varchar(255), 
    Breastfeed_Exclusively_age varchar(255), 
    Infant_Formula        varchar(255), 
    Infant_Formula_age    varchar(255), 
    Mixed_Feeding         varchar(255), 
    Mixed_Feeding_age     varchar(255), 
    Stopped_Breastfeeding varchar(255), 
    Stopped_Breastfeeding_age varchar(255)
);

insert into temp_feeding (
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

update temp_feeding set zlemrid = zlemr(patient_id);
update temp_feeding set dossierid = dosid(patient_id);
update temp_feeding set loc_registered = loc_registered(patient_id);
update temp_feeding set encounter_location = encounter_location_name(encounter_id);
update temp_feeding set provider = provider(encounter_id);

-- Breastfeeding
update temp_feeding t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.value_coded = concept_from_mapping('PIH','BREASTFED EXCLUSIVELY')
set Breastfeed_Exclusively =
  case 
    when o.concept_id = concept_from_mapping('PIH', 'FEEDING METHOD PRESENT') then 'Yes'
    when o.concept_id = concept_from_mapping('PIH', 'FEEDING METHOD ABSENT') then 'No'
  end
;
update temp_feeding t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.value_coded = concept_from_mapping('PIH','BREASTFED EXCLUSIVELY')
set Breastfeed_Exclusively_age =
  obs_from_group_id_value_text(o.obs_group_id, 'PIH','FEEDING METHOD AGE');

-- infant formula 
update temp_feeding t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.value_coded = concept_from_mapping('PIH','INFANT FORMULA')
set Infant_Formula =
  case 
    when o.concept_id = concept_from_mapping('PIH', 'FEEDING METHOD PRESENT') then 'Yes'
    when o.concept_id = concept_from_mapping('PIH', 'FEEDING METHOD ABSENT') then 'No'
  end
;
update temp_feeding t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.value_coded = concept_from_mapping('PIH','INFANT FORMULA')
set Infant_Formula_age =
  obs_from_group_id_value_text(o.obs_group_id, 'PIH','FEEDING METHOD AGE');
  
-- mixed feeding
update temp_feeding t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.value_coded = concept_from_mapping('PIH','MIXED FEEDING')
set Mixed_Feeding =
  case 
    when o.concept_id = concept_from_mapping('PIH', 'FEEDING METHOD PRESENT') then 'Yes'
    when o.concept_id = concept_from_mapping('PIH', 'FEEDING METHOD ABSENT') then 'No'
  end
;
update temp_feeding t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.value_coded = concept_from_mapping('PIH','MIXED FEEDING')
set Mixed_Feeding_age =
  obs_from_group_id_value_text(o.obs_group_id, 'PIH','FEEDING METHOD AGE');
  
-- stopped breastfeeding
update temp_feeding t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.value_coded = concept_from_mapping('PIH','WEANED')
set Stopped_Breastfeeding =
  case 
    when o.concept_id = concept_from_mapping('PIH', 'FEEDING METHOD PRESENT') then 'Yes'
    when o.concept_id = concept_from_mapping('PIH', 'FEEDING METHOD ABSENT') then 'No'
  end
;
update temp_feeding t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.value_coded = concept_from_mapping('PIH','WEANED')
set Stopped_Breastfeeding_age =
  obs_from_group_id_value_text(o.obs_group_id, 'PIH','FEEDING METHOD AGE');
 
 -- select final output
select * from temp_feeding;
