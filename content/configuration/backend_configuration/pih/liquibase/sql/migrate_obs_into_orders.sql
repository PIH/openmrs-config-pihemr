/*
The following script will migrate lab results entered in the standalone Lab Results form
into the appropriate Lab Specimen Encounter form.  This is for a specific use case that happened
on the Haiti HIV EMR where users were 
  1) creating HIV VL orders
  2) adding sample collection date for those orders
  3) entering the results on the standalone "Add past lab results" form instead of the Lab App 
*/

-- create temp table to hold relevant key values
drop temporary table if exists migrate_into_orders;
create temporary table migrate_into_orders
(order_id                   int(11),
sample_encounter_id         int(11),
result_encounter_id         int(11),
result_date_obs_id          int(11),
hiv_vl_construct_obs_id     int(11),
new_hiv_vl_construct_obs_id int(11)
);

-- add all instances of standalone results added with same patient and date of sample collection
insert into migrate_into_orders (order_id, sample_encounter_id, result_encounter_id)
select distinct o.order_id, e_sample.encounter_id, e_result.encounter_id 
from orders o
inner join encounter e_sample on e_sample.patient_id = o.patient_id
	and e_sample.encounter_type = encounter_type('Lab Specimen Collection')
	and e_sample.voided = 0 
inner join obs o_sample on o_sample.encounter_id = e_sample.encounter_id
	and o_sample.order_id = o.order_id 
	and o_sample.voided = 0
inner join encounter e_result on e_result.patient_id = o.patient_id
	and date(e_result.encounter_datetime) = date(e_sample.encounter_datetime)
	and e_result.encounter_type = encounter_type('Laboratory Results')
	and e_result.voided = 0
 inner join obs o_result on o_result.encounter_id = e_result.encounter_id
 	and o_result.concept_id = concept_from_mapping('PIH','HIV viral load construct')
	and o_result.voided = 0 		
where o.concept_id = concept_from_mapping('PIH','15124') -- HIV VL order
and fulfiller_status <> 'COMPLETED'
and o.voided = 0
order by o.date_activated desc;

update migrate_into_orders m
inner join obs o on o.encounter_id = m.result_encounter_id 
	and o.concept_id = concept_from_mapping('PIH','Date of test results')
	and o.voided = 0
set m.result_date_obs_id = o.obs_id;

update migrate_into_orders m
inner join obs o on o.encounter_id = m.result_encounter_id 
	and o.concept_id = concept_from_mapping('PIH','HIV viral load construct')
	and o.voided = 0
set m.hiv_vl_construct_obs_id = o.obs_id;

-- insert hiv vl panel
insert into obs 
	(person_id,
	concept_id,
	encounter_id,
	obs_datetime,
	location_id, 
	obs_group_id, 
	value_datetime, 
	order_id,
	creator, 
	date_created,
	uuid, 
	status,
	previous_version,
	comments)
select 
	o.person_id,
	concept_from_mapping('PIH','15124'),
	m.sample_encounter_id,
	o.obs_datetime,
	o.location_id, 
	o.obs_group_id, 
	o.value_datetime, 
	m.order_id,
	o.creator, 
	o.date_created,
	uuid(),
	o.status,
	o.obs_id,
	'result-entry-form^d760dcec-f2b3-46c5-a6af-7e83c2165fd1'
from migrate_into_orders m
inner join obs o on o.obs_id = m.hiv_vl_construct_obs_id;

-- retrieve new hiv_vl_construct_obs_id
update migrate_into_orders m
inner join obs o on o.encounter_id = m.sample_encounter_id 
	and o.concept_id = concept_from_mapping('PIH','15124')
	and o.voided = 0
set m.new_hiv_vl_construct_obs_id = o.obs_id;


-- insert result date
insert into obs 
	(person_id,
	concept_id,
	encounter_id,
	obs_datetime,
	location_id, 
	value_datetime, 
	value_numeric,
	value_coded,
	order_id,
	creator, 
	date_created,
	uuid, 
	status,
	previous_version,
	comments)
select 
	o.person_id,
	o.concept_id,
	m.sample_encounter_id,
	o.obs_datetime,
	o.location_id, 
	o.value_datetime, 
	o.value_numeric,
	o.value_coded,
	m.order_id,
	o.creator, 
	o.date_created,
	uuid(), 
	o.status,
	o.obs_id,
	'result-entry-form^result-date'
from migrate_into_orders m
inner join obs o on o.obs_id = m.result_date_obs_id;

-- insert HIV viral load, qualitative
insert into obs 
	(person_id,
	concept_id,
	encounter_id,
	obs_datetime,
	location_id, 
	obs_group_id, 
	value_datetime,
	value_numeric,
	value_coded,
	order_id,
	creator, 
	date_created,
	uuid, 
	status,
	previous_version,
	comments)
select 
	o.person_id,
	o.concept_id,
	m.sample_encounter_id,
	o.obs_datetime,
	o.location_id, 
	new_hiv_vl_construct_obs_id, 
	o.value_datetime, 
	o.value_numeric,
	o.value_coded,
	m.order_id,
	o.creator, 
	o.date_created,
	uuid(),
	o.status,
	o.obs_id,
	'result-entry-form^d760dcec-f2b3-46c5-a6af-7e83c2165fd1^1305AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA'
from migrate_into_orders m
inner join obs o on  o.obs_group_id = hiv_vl_construct_obs_id
and o.concept_id = concept_from_mapping('PIH','11546') ;
;

-- insert HIV viral load, quantitative
insert into obs 
	(person_id,
	concept_id,
	encounter_id,
	obs_datetime,
	location_id, 
	obs_group_id, 
	value_datetime,
	value_numeric,
	value_coded,
	order_id,
	creator, 
	date_created,
	uuid, 
	status,
	previous_version,
	comments)
select 
	o.person_id,
	o.concept_id,
	m.sample_encounter_id,
	o.obs_datetime,
	o.location_id, 
	new_hiv_vl_construct_obs_id, 
	o.value_datetime, 
	o.value_numeric,
	o.value_coded,
	m.order_id,
	o.creator, 
	o.date_created,
	uuid(),
	o.status,
	o.obs_id,
	'result-entry-form^d760dcec-f2b3-46c5-a6af-7e83c2165fd1^3cd4a882-26fe-102b-80cb-0017a47871b2'
from migrate_into_orders m
inner join obs o on  o.obs_group_id = hiv_vl_construct_obs_id
and o.concept_id = concept_from_mapping('PIH','HIV VIRAL LOAD') ;
;

-- insert Lower limit of detection
insert into obs 
	(person_id,
	concept_id,
	encounter_id,
	obs_datetime,
	location_id, 
	obs_group_id, 
	value_datetime,
	value_numeric,
	value_coded,
	order_id,
	creator, 
	date_created,
	uuid, 
	status,
	previous_version,
	comments)
select 
	o.person_id,
	o.concept_id,
	m.sample_encounter_id,
	o.obs_datetime,
	o.location_id, 
	new_hiv_vl_construct_obs_id, 
	o.value_datetime, 
	o.value_numeric,
	o.value_coded,
	m.order_id,
	o.creator, 
	o.date_created,
	uuid(),
	o.status,
	o.obs_id,
	'result-entry-form^d760dcec-f2b3-46c5-a6af-7e83c2165fd1^53cb83ed-5d55-4b63-922f-d6b8fc67a5f8'
from migrate_into_orders m
inner join obs o on  o.obs_group_id = hiv_vl_construct_obs_id
and o.concept_id = concept_from_mapping('PIH','Detectable lower limit') ;
;

-- update order to Complete
update orders o
inner join migrate_into_orders m on m.order_id = o.order_id
set o.fulfiller_status = 'COMPLETED';

-- void obs that were just migrated
update obs o 
inner join migrate_into_orders m on o.obs_id = m.result_date_obs_id 
	or obs_id = m.hiv_vl_construct_obs_id
	or obs_group_id = m.hiv_vl_construct_obs_id
set voided = 1,
    voided_by = 1, 
    date_voided = now(),
    void_reason = 'migrated to Lab Specimen encounter (UHM-8694)';

-- update those lab_results encounters if there are no other non-voided obs
update encounter e 
inner join migrate_into_orders m on e.encounter_id  = m.result_encounter_id
set voided = 1,
    voided_by = 1, 
    date_voided = now(),
    void_reason = 'migrated to Lab Specimen encounter (UHM-8694)'
where not exists
 (select 1 from obs o where o.encounter_id = e.encounter_id 
 and o.voided = 0);
