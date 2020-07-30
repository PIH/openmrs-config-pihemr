#set @startDate='2020-01-01';
#set @endDate='2020-05-20';
#a541af1e-105c-40bf-b345-ba1fd6a59b85 ZL
#1a2acce0-7426-11e5-a837-0800200c9a66 Wellbody
#0bc545e0-f401-11e4-b939-0800200c9a66 Liberia
 
set @locale = global_property_value('default_locale', 'en'); 
 
SELECT patient_identifier_type_id into @zlId from patient_identifier_type where uuid in ('a541af1e-105c-40bf-b345-ba1fd6a59b85' ,'1a2acce0-7426-11e5-a837-0800200c9a66','0bc545e0-f401-11e4-b939-0800200c9a66');
SELECT person_attribute_type_id into @unknownPt FROM person_attribute_type where uuid='8b56eac7-5c76-4b9c-8c6f-1deab8d3fc47';
SELECT encounter_type_id into @labResultEnc from encounter_type where uuid= '4d77916a-0620-11e5-a6c0-1697f925ec7b';
SELECT order_type_id into @test_order from order_type where uuid = '52a447d3-a64a-11e3-9aeb-50e549534c5e';
SELECT encounter_type_id into @specimen_collection from encounter_type where uuid = '39C09928-0CAB-4DBA-8E48-39C631FA4286';
SELECT concept_id into @test_order from concept where uuid = '393dec41-2fb5-428f-acfa-36ea85da6666';
SELECT concept_id into @not_performed from concept where uuid = '5dc35a2a-228c-41d0-ae19-5b1e23618eda';
SELECT concept_id into @order_number from concept where UUID = '393dec41-2fb5-428f-acfa-36ea85da6666'; 
SELECT concept_id into @result_date from concept where UUID = '68d6bd27-37ff-4d7a-87a0-f5e0f9c8dcc0'; 
SELECT concept_id into @test_location from concept where UUID = global_property_value('labworkflowowa.locationOfLaboratory', 'Unknown Location'); -- test location may differ by implementation
SELECT concept_id into @test_status from concept where UUID = '7e0cf626-dbe8-42aa-9b25-483b51350bf8'; 
SELECT concept_id into @collection_date_estimated from concept where UUID = '87f506e3-4433-40ec-b16c-b3c65e402989'; 

-- this temp table stores specimen collection encounter-level information
drop temporary table if exists temp_laborders_spec;
create temporary table temp_laborders_spec
(
  order_number varchar(50),
  concept_id int(11),
  encounter_id int(11),
  encounter_datetime  datetime,
  patient_id int(11),
  emr_id varchar(50),
  loc_registered varchar(255),
  unknown_patient varchar(50),
  gender varchar(50),
  age_at_enc int(11),
  department varchar(255),
  commune varchar(255),
  section varchar(255),
  locality varchar(255),
  street_landmark varchar(255),
  results_date datetime,
  results_entry_date datetime
 );

-- this temp table stores specimen encounter-level information from above and result-level information 
drop temporary table if exists temp_labresults;
create temporary table temp_labresults
(
  patient_id int(11),
  emr_id varchar(50),
  loc_registered varchar(255),
  unknown_patient varchar(50),
  gender varchar(50),
  age_at_enc int(11),
  department varchar(255),
  commune varchar(255),
  section varchar(255),
  locality varchar(255),
  street_landmark varchar(255),
  order_number varchar(50) ,
  orderable varchar(255),
  test varchar(255),
  specimen_collection_date datetime,
  results_date datetime,
  results_entry_date datetime,
  result varchar(255),
  units varchar(255),
  test_concept_id int(11),
  reason_not_performed text,
  result_coded_answer varchar(255),
  result_numeric_answer double,
  result_text_answer text
);
 
 -- this loads all specimen encounters (from the lab application) into a temp table 
insert into temp_laborders_spec (encounter_id,encounter_datetime,patient_id,emr_id)
select e.encounter_id,
e.encounter_datetime,
e.patient_id,
patient_identifier(e.patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'))
from encounter e
where e.encounter_type = @specimen_collection and e.voided = 0
and date(e.encounter_datetime) >= date(@startDate)
and date(e.encounter_datetime) <= date(@endDate)
;



-- updates order number 
update temp_laborders_spec t
INNER JOIN obs sco on sco.encounter_id = t.encounter_id and sco.concept_id = @test_order and sco.voided = 0
SET order_number = sco.value_text;

-- updates concept id of orderable
update temp_laborders_spec t
INNER JOIN orders o on o.order_number = t.order_number
SET t.concept_id = o.concept_id
;

 -- this adds the standalone lab results encounters into the temp table 
insert into temp_laborders_spec (encounter_id,encounter_datetime,patient_id,emr_id)
select e.encounter_id,
e.encounter_datetime,
e.patient_id,
patient_identifier(e.patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'))
from encounter e
where e.encounter_type = @labResultEnc and e.voided = 0
and date(e.encounter_datetime) >= date(@startDate)
and date(e.encounter_datetime) <= date(@endDate)
;

-- emr id location 
update temp_laborders_spec ts 
inner join patient_identifier pid on pid.patient_id = ts.patient_id and pid.identifier = ts.emr_id
inner join location l ON l.location_id = pid.location_id
set ts.loc_registered = l.name
;

-- unknown patient
update temp_laborders_spec ts
LEFT OUTER JOIN person_attribute un ON ts.patient_id = un.person_id AND un.person_attribute_type_id = @unknownPt AND un.voided = 0
set ts.unknown_patient = un.value;

-- gender & age
update temp_laborders_spec ts
INNER JOIN person pr ON ts.patient_id = pr.person_id AND pr.voided = 0
set ts.gender = pr.gender,
ts.age_at_enc = ROUND(DATEDIFF(ts.encounter_datetime, pr.birthdate)/365.25, 1);

-- address
update temp_laborders_spec ts
inner join person_address pa ON pa.person_address_id = (select person_address_id from person_address a2 where a2.person_id =  ts.patient_id and a2.voided = 0
                                                               order by a2.preferred desc, a2.date_created desc limit 1)
set department = pa.state_province,
commune = pa.city_village,
section = pa.address3,
locality =pa.address1,
street_landmark =pa.address2
;

 -- results date
update temp_laborders_spec ts
inner join obs res_date on res_date.voided = 0 and res_date.encounter_id = ts.encounter_id and res_date.concept_id = @result_date
set ts.results_date = res_date.value_datetime,
    ts.results_entry_date = res_date.date_created;


-- This query loads all specimen encounter-level information from above and observations from results entered  
insert into temp_labresults (patient_id,emr_id,loc_registered, unknown_patient, gender, age_at_enc, department, commune, section, locality, street_landmark,order_number,orderable,specimen_collection_date, results_date, results_entry_date,test_concept_id,test,result_coded_answer,result_numeric_answer,result_text_answer)
select ts.patient_id,
ts.emr_id,
ts.loc_registered, 
ts.unknown_patient, 
ts.gender, 
ts.age_at_enc, 
ts.department, 
ts.commune, 
ts.section, 
ts.locality, 
ts.street_landmark,
ts.order_number, 
ifnull(concept_name(ts.concept_id,@locale),concept_name(ts.concept_id,'en')), 
ts.encounter_datetime, 
ts.results_date,
ts.results_entry_date,
res.concept_id, 
ifnull(concept_name(res.concept_id, @locale),concept_name(res.concept_id,'en')), 
ifnull(concept_name(res.value_coded, @locale),concept_name(res.value_coded,'en')),
res.value_numeric,
res.value_text
  from temp_laborders_spec ts
-- observations from specimen collection encounters that are results (all except the ones listed below) are added here:   
INNER JOIN obs res on res.encounter_id = ts.encounter_id
  and res.voided = 0 and res.concept_id not in (@order_number,@result_date,@test_location,@test_status,@collection_date_estimated)
  and (res.value_numeric is not null or res.value_text is not null or res.value_coded is not null)
;



-- update test units (where they exist)
update temp_labresults t
INNER JOIN concept_numeric cu on cu.concept_id = t.test_concept_id
set t.units = cu.units
;

-- select  all output:
SELECT t.patient_id,
       t.emr_id,
	     t.loc_registered,
       t.unknown_patient,
       t.gender,
       t.age_at_enc,
       t.department,
       t.commune,
       t.section,
       t.locality,
       t.street_landmark,
       t.order_number,
       t.orderable,
       -- only return test name is test was performed:
       CASE when t.test_concept_id  <> @not_performed then t.test END as 'test',
       t.specimen_collection_date,
       t.results_date,
       t.results_entry_date,
       -- only return the result if the test was performed:     
       CASE 
         when t.test_concept_id  <> @not_performed  and t.result_numeric_answer is not null then t.result_numeric_answer
         when t.test_concept_id  <> @not_performed  and t.result_text_answer is not null then t.result_text_answer
         when t.test_concept_id  <> @not_performed  and t.result_coded_answer  is not null then t.result_coded_answer 
       END as 'result',
       t.units,
       CASE when t.test_concept_id  = @not_performed  then t.result_coded_answer else null END as 'reason_not_performed'  
from temp_labresults t;

