-- set @startDate='2020-01-01';
-- set @endDate='2021-08-14';

set @locale = global_property_value('default_locale', 'en');

select order_type_id into @testOrder from order_type where uuid = '52a447d3-a64a-11e3-9aeb-50e549534c5e';
select encounter_type_id into @specimenCollEnc from encounter_type where uuid = '39C09928-0CAB-4DBA-8E48-39C631FA4286';

drop temporary table if exists temp_report;
create temporary table temp_report
(
    patient_id      int,
    emr_id          varchar(255),
    specimen_encounter_id int,
    order_encounter_id int,
    loc_registered  varchar(255),
    unknown_patient char(1),
    gender          char(1),
    age_at_enc      int,
    patient_address varchar(1000),
    order_number    varchar(255),
    order_concept_id int,
    orderable       varchar(255),
    status          varchar(255),
    orderer         varchar(255),
    order_datetime  datetime,
    date_stopped    datetime,
    auto_expire_date datetime,
    fulfiller_status varchar(255),
    ordering_location varchar(255),
    urgency         varchar(255),
    specimen_collection_datetime datetime,
    collection_date_estimated varchar(255),
    test_location  varchar(255),
    result_date     datetime
);

-- load temporary table with all lab test orders within the date range 
insert into temp_report (
    patient_id,
    order_number,
    order_concept_id,
    order_encounter_id,
    order_datetime,
    date_stopped,
    auto_expire_date,
    fulfiller_status,
    urgency
)
select
    o.patient_id,
    o.order_number,
    o.concept_id,
    o.encounter_id,
    o.date_activated,
    o.date_stopped,
    o.auto_expire_date,
    o.fulfiller_status,
     o.urgency
from
    orders o
where o.order_type_id =@testOrder
      and order_action = 'NEW'
      and date(o.date_activated) >= date(@startDate)
      and date(o.date_activated) <= date(@endDate);
  

## REMOVE TEST PATIENTS
delete
from temp_report
where patient_id in
      (
          select a.person_id
          from person_attribute a
          inner join person_attribute_type t on a.person_attribute_type_id = t.person_attribute_type_id
          where a.value = 'true'
          and t.name = 'Test Patient'
      );
      
-- To join in the specimen encounters, a temporary table is created with all lab specimen encounters within the date range is loaded.
-- This table is indexed and then joined with the main report temp table
drop temporary table if exists temp_spec;
create temporary table temp_spec
(
    specimen_encounter_id int,
    order_number   varchar(255) 
   );      

CREATE  INDEX order_number ON temp_spec(order_number);   


insert into temp_spec (
    specimen_encounter_id,
    order_number
)
select
    e.encounter_id,
    o.value_text
from
    encounter e
    inner join obs o on o.encounter_id = e.encounter_id and o.voided = 0 and o.concept_id =  concept_from_mapping('PIH','10781')
where e.encounter_type = @specimenCollEnc
      and e.voided = 0
      and date(e.encounter_datetime) >= date(@startDate)
      and date(e.encounter_datetime) <= date(@endDate);

update temp_report t
  LEFT OUTER JOIN temp_spec ts on ts.order_number = t.order_number 
  set  t.specimen_encounter_id = ts.specimen_encounter_id;

-- Individual columns are populated here:
update temp_report set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 
update temp_report set gender = gender(patient_id);
update temp_report set loc_registered = loc_registered(patient_id);
update temp_report set age_at_enc = age_at_enc(patient_id,order_encounter_id );
update temp_report set unknown_patient = unknown_patient(patient_id);
update temp_report set patient_address = person_address(patient_id);
update temp_report set orderable = IFNULL(concept_name(order_concept_id, @locale),concept_name(order_concept_id, 'en'));
-- status is derived by the order fulfiller status and other fields
update temp_report t set status =
    CASE
       WHEN t.date_stopped is not null and specimen_encounter_id is null THEN 'Cancelled'
       WHEN t.auto_expire_date < CURDATE() and specimen_encounter_id is null THEN 'Expired'
       WHEN t.fulfiller_status = 'COMPLETED' THEN 'Reported'
       WHEN t.fulfiller_status = 'IN_PROGRESS' THEN 'Collected'
       WHEN t.fulfiller_status = 'EXCEPTION' THEN 'Not Performed'
       ELSE 'Ordered'
    END ;
update temp_report t set orderer = provider(t.order_encounter_id);
update temp_report t set ordering_location = encounter_location_name(t.order_encounter_id);
update temp_report t set specimen_collection_datetime = encounter_date(t.order_encounter_id);
update temp_report t set test_location = obs_value_coded_list(t.specimen_encounter_id, 'PIH','11791',@locale);
update temp_report t set result_date = obs_value_datetime(t.specimen_encounter_id,'PIH','Date of test results'); 
update temp_report t set collection_date_estimated = obs_value_coded_list(t.specimen_encounter_id, 'PIH','11781',@locale);

-- final output
select 
patient_id, 
emr_id, 
loc_registered,
unknown_patient, 
gender, 
age_at_enc,
patient_address,
order_number,
orderable,
status,
orderer,
order_datetime,
ordering_location,
urgency,
specimen_collection_datetime,
collection_date_estimated,
test_location,
result_date
from temp_report;
