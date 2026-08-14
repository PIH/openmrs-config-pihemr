/*
This script is intended to run after the migrate_obs_into_orders.sql script has run.  ticket (UHM-8694)
This will migrate the HIV VL Load sample id into the orders, which was missed in the original script. 
This should be a one-time execution on the Haiti HIV server.
 */

-- create temp table to hold information to migrate
drop temporary table if exists temp_obs_to_move;
create temporary table temp_obs_to_move (
results_encounter_id   int(11),
sample_obs_id int(11),
sample_number text,
order_id  int(11));

-- insert all previously-migrated encounters into temp table
insert into temp_obs_to_move (results_encounter_id)
select distinct encounter_id from obs 
where void_reason = 'migrated to Lab Specimen encounter (UHM-8694)';

-- update obs_id of sample number from old lab results encounter
update temp_obs_to_move t 
inner join obs o on o.encounter_id = t.results_encounter_id
	and o.concept_id = concept_from_mapping('PIH','10840')
set t.sample_number = o.value_text,
	t.sample_obs_id = o.obs_id;

-- remove rows without sample numbers to migrate
delete from temp_obs_to_move where sample_number is NULL ;

-- find matching order that the obs were previously migrated to
update temp_obs_to_move t
inner join encounter e_result on e_result.encounter_id = t.results_encounter_id
inner join encounter e_sample on e_result.patient_id = e_sample.patient_id
	and date(e_result.encounter_datetime) = date(e_sample.encounter_datetime)
	and e_sample.encounter_type = encounter_type('Lab Specimen Collection')
inner join obs o_hiv_vl on o_hiv_vl.encounter_id = e_sample.encounter_id 
	and o_hiv_vl.concept_id = concept_from_mapping('PIH','15124') -- hiv vl panel
set t.order_id = o_hiv_vl.order_id;

-- update accession id on order with sample number
update orders o 
inner join temp_obs_to_move t on t.order_id = o.order_id 
set o.accession_number = t.sample_number;

-- void obs that were just migrated if there are no other labs on this encounter
update obs o
inner join temp_obs_to_move t on o.obs_id = t.sample_obs_id
left join obs o2 
    on o2.encounter_id = o.encounter_id
   and o2.obs_id <> t.sample_obs_id
   and o2.voided = 0
set o.voided = 1,
    o.voided_by = 1, 
    o.date_voided = now(),
    o.void_reason = 'migrated to Lab Specimen encounter (UHM-8694)'
where o2.obs_id is null; -- other obs do not exists

-- update those lab_results encounters if there are no other non-voided obs
update encounter e 
inner join temp_obs_to_move t on e.encounter_id  = t.results_encounter_id
set voided = 1,
    voided_by = 1, 
    date_voided = now(),
    void_reason = 'migrated to Lab Specimen encounter (UHM-8694)'
where not exists
 (select 1 from obs o where o.encounter_id = e.encounter_id 
 and o.voided = 0);
