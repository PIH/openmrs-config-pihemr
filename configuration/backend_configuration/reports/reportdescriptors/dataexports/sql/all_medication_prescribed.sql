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

insert into temp_medication_orders (
encounter_id, 
patient_id,
order_id,
concept_id,
drug_id,
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
update temp_medication_orders tm set user_entered = encounter_creator_name(encounter_id);
update temp_medication_orders tm set order_drug = concept_name(concept_id, 'en');
update temp_medication_orders tm set order_formulation = drugName(drug_id);
update temp_medication_orders tm set order_formulation_non_coded = (select drug_non_coded from drug_order d where d.order_id = tm.order_id);
update temp_medication_orders tm set order_quantity_units = concept_name(order_quantity_units_id, 'en');
update temp_medication_orders tm set order_dose_unit = concept_name(order_dose_units_id, 'en');
update temp_medication_orders tm set order_route = concept_name(order_route_id, 'en');
update temp_medication_orders tm set order_frequency = (select concept_name(concept_id, 'en') from order_frequency d where d.order_frequency_id = tm.order_frequency_id);
update temp_medication_orders tm set order_reason = concept_name(order_reason_concept, 'en');
update temp_medication_orders tm  set order_comments = obs_value_text(tm.encounter_id, 'PIH', 'Medication comments (text)');
update temp_medication_orders tm  set order_duration_units = concept_name(order_duration_units_id, 'en');
update temp_medication_orders tm  set product_code = openboxesCode(drug_id);
update temp_medication_orders tm  set prescriber = provider(tm.encounter_id);

-- final query
select 
emr_id,
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
