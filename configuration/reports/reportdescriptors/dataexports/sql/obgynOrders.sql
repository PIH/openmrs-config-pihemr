-- set @startDate = '2021-03-20';
-- set @endDate = '2021-03-20';

CALL initialize_global_metadata();
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
select encounter_type_id into @obgynnote from encounter_type where uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d'; 

DROP TEMPORARY TABLE IF EXISTS temp_orders;
CREATE TEMPORARY TABLE temp_orders
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
    order_id              int(11),
    order_type            varchar(50),
    drug_id               int(11),
    drug                  varchar(255),
    dose                  varchar(255),
    dose_unit             varchar(255),
    frequency_id          int(11),
    frequency             varchar(255),
    route                 varchar(255),    
    starting_datetime     varchar(255),    
    duration              int(11),
    duration_unit         varchar(255),  
    quantity              varchar(255),   
    refills               varchar(255)      
);

insert into temp_orders (
  patient_id,
  encounter_id,
  encounter_datetime,
  encounter_type,
  order_id,
  order_type,
  starting_datetime)
select
  e.patient_id,
  e.encounter_id,
  e.encounter_datetime,
  et.name,
  o.order_id,
  o.order_action,
  o.date_activated
from encounter e
inner join encounter_type et on et.encounter_type_id = e.encounter_type
inner join orders o on o.encounter_id = e.encounter_id and o.voided = 0
where e.encounter_type in (@obgynnote)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
and e.voided = 0
;

update temp_orders set zlemrid = zlemr(patient_id);
update temp_orders set dossierid = dosid(patient_id);
update temp_orders set loc_registered = loc_registered(patient_id);
update temp_orders set encounter_location = encounter_location_name(encounter_id);
update temp_orders set provider = provider(encounter_id);


update temp_orders t
inner join drug_order d on d.order_id = t.order_id  
set t.dose = d.dose,
   t.dose_unit = concept_name(d.dose_units,@locale), 
   frequency_id = d.frequency,
   t.route = concept_name(d.route,@locale),
   t.duration = d.duration,
   t.duration_unit = concept_name(d.duration_units,@locale),
   t.quantity = d.quantity,
   t.refills = d.num_refills,
   t.drug_id = d.drug_inventory_id
;

update temp_orders t
inner join order_frequency of on t.frequency_id = of.order_frequency_id 
set frequency = concept_name(of.concept_id, @locale);

update temp_orders t
inner join drug d on d.drug_id = t.drug_id
set t.drug = d.name;

-- select final output
select 
patient_id,
dossierId ,
zlemrid,
loc_registered, 
encounter_datetime,
encounter_location, 
encounter_type,                
provider, 
encounter_id,
order_id,
order_type,
drug,
dose,
dose_unit,
frequency,
route,    
starting_datetime,    
duration,
duration_unit,  
quantity,   
refills  
from temp_orders;    
