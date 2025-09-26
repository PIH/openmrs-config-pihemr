set sql_safe_updates = 0;
set @partition = '${partitionNum}';

drop table if exists temp_medication_orders;
create table temp_medication_orders
(
encounter_id int,
patient_id int,
emr_id varchar(20),
visit_id int,
order_id int,
orderer int,
concept_id int,
drug_id int,
location_id int,
encounter_type_id int(11),
encounter_type varchar(255),
prescription_obs_group_id int(11),
order_drug text,
order_formulation text,
order_formulation_non_coded text,
order_location varchar(255),
order_created_date date,
order_date_activated date,
user_entered varchar(255),
order_quantity int,
order_quantity_units_id int,
order_quantity_units varchar(50),
order_quantity_num_refills int,
order_dose int,
order_dose_units_id int,
order_dose_unit varchar(50),
order_dosing_instructions text,
order_route_id int,
order_route varchar(50),
order_frequency_id int,
order_frequency varchar(50),
order_duration int,
order_duration_units_id int,
order_duration_units varchar(50),
order_reason_concept int,
order_reason text,
order_comments text,
product_code varchar(25),
prescriber varchar(255)
);

-- meds from obs
set @prescription_construct = concept_from_mapping('PIH','10742');
insert into temp_medication_orders (
	encounter_id, 
	patient_id,
	encounter_type_id,
	prescription_obs_group_id,
	order_date_activated,
	order_created_date )
select 
	o.encounter_id,
	o.person_id,
	e.encounter_type,
	o.obs_id,
	e.encounter_datetime,
	e.date_created
from obs o  
inner join encounter e on e.encounter_id = o.encounter_id and e.voided = 0
where concept_id = @prescription_construct
and o.voided = 0; 

update temp_medication_orders t 
set encounter_type = encounter_type_name_from_id(encounter_type_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs AS
SELECT
    o.obs_id,
    o.voided,
    o.obs_group_id,
    o.encounter_id,
    o.person_id,
    o.concept_id,
    o.value_coded,
    o.value_numeric,
    o.value_text,
    o.value_datetime,
    o.value_drug,
    o.comments
FROM obs o
INNER JOIN temp_medication_orders m
    ON m.prescription_obs_group_id = o.obs_group_id
WHERE o.voided = 0;

update temp_medication_orders t 
set t.order_drug = obs_from_group_id_value_coded_list_from_temp(prescription_obs_group_id, 'PIH','1282', @locale);
update temp_medication_orders t 
set t.drug_id = obs_from_group_id_value_drug_from_temp(prescription_obs_group_id, 'PIH','1282');
update temp_medication_orders t 
set t.order_dose = obs_from_group_id_value_numeric_from_temp(prescription_obs_group_id, 'PIH','9073');
update temp_medication_orders t 
set t.order_dose_unit = obs_from_group_id_value_coded_list_from_temp(prescription_obs_group_id, 'PIH','10744', @locale);
update temp_medication_orders t 
set t.order_frequency = obs_from_group_id_value_coded_list_from_temp(prescription_obs_group_id, 'PIH','9362', @locale);
update temp_medication_orders t 
set t.order_duration = obs_from_group_id_value_numeric_from_temp(prescription_obs_group_id, 'PIH','9075');
update temp_medication_orders t 
set t.order_duration_units = obs_from_group_id_value_coded_list_from_temp(prescription_obs_group_id, 'PIH','6412', @locale);
update temp_medication_orders t 
set t.order_dosing_instructions = obs_from_group_id_value_text_from_temp(prescription_obs_group_id, 'PIH','9072');


-- meds from orders
insert into temp_medication_orders (
encounter_id, 
patient_id,
order_id,
concept_id,
drug_id,
encounter_type,
order_reason_concept,
order_dose,
order_dose_units_id,
order_dosing_instructions,
order_route_id,
order_frequency_id,
order_quantity,
order_quantity_units_id,
order_duration,
order_duration_units_id,
order_quantity_num_refills,
order_created_date, 
order_date_activated
)
select 
o.encounter_id,
o.patient_id,
o.order_id,
o.concept_id,
d.drug_inventory_id,
'standalone order',
o.order_reason,
d.dose,
d.dose_units,
d.dosing_instructions,
d.route,
d.frequency,
d.quantity,
d.quantity_units,
d.duration,
d.duration_units,
d.num_refills,
date(o.date_created),
date(o.date_activated)
from orders o
inner join drug_order d on o.order_id = d.order_id
where o.voided = 0;

update temp_medication_orders SET emr_id = PATIENT_IDENTIFIER(patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_medication_orders tm set visit_id = (select visit_id from encounter e where voided = 0 and tm.encounter_id = e.encounter_id);
update temp_medication_orders tm set location_id = (select location_id from encounter e where voided = 0 and tm.encounter_id = e.encounter_id);
update temp_medication_orders tm set order_location = location_name(location_id);
update temp_medication_orders tm set user_entered = encounter_creator_name(encounter_id);
update temp_medication_orders tm set order_formulation = drugName(drug_id);
update temp_medication_orders tm  set product_code = openboxesCode(drug_id);
update temp_medication_orders tm  set prescriber = provider(tm.encounter_id);

update temp_medication_orders tm set order_drug = concept_name(concept_id, 'en') where encounter_type = 'standalone order';
update temp_medication_orders tm set order_formulation_non_coded = (select drug_non_coded from drug_order d where d.order_id = tm.order_id) where encounter_type = 'standalone order';
update temp_medication_orders tm set order_quantity_units = concept_name(order_quantity_units_id, 'en') where encounter_type = 'standalone order';
update temp_medication_orders tm set order_dose_unit = concept_name(order_dose_units_id, 'en') where encounter_type = 'standalone order';
update temp_medication_orders tm set order_route = concept_name(order_route_id, 'en') where encounter_type = 'standalone order';
update temp_medication_orders tm set order_frequency = (select concept_name(concept_id, 'en') from order_frequency d where d.order_frequency_id = tm.order_frequency_id) where encounter_type = 'standalone order';
update temp_medication_orders tm set order_reason = concept_name(order_reason_concept, 'en') where encounter_type = 'standalone order';
update temp_medication_orders tm  set order_comments = obs_value_text(tm.encounter_id, 'PIH', 'Medication comments (text)') where encounter_type = 'standalone order';
update temp_medication_orders tm  set order_duration_units = concept_name(order_duration_units_id, 'en')where encounter_type = 'standalone order';

-- final query
select 
prescription_obs_group_id,
emr_id,
encounter_type,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',encounter_id),encounter_id) "encounter_id",
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',visit_id),encounter_id) "visit_id",
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',order_id),encounter_id) "order_id",
order_location,
order_created_date,
order_date_activated,
user_entered,
prescriber,
order_drug,
order_formulation,
order_formulation_non_coded,
product_code,
order_quantity,
order_quantity_units,
order_quantity_num_refills,
order_dose,
order_dose_unit,
order_dosing_instructions,
order_route,
order_frequency,
order_duration,
order_duration_units,
order_reason, 
order_comments
from temp_medication_orders
order by order_date_activated, patient_id;
