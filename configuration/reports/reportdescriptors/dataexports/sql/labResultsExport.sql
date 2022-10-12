#set @startDate='2020-01-20';
#set @endDate='2020-05-20';
#a541af1e-105c-40bf-b345-ba1fd6a59b85 ZL
#1a2acce0-7426-11e5-a837-0800200c9a66 Wellbody
#0bc545e0-f401-11e4-b939-0800200c9a66 Liberia
 
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
SET sql_safe_updates = 0;
 
SELECT patient_identifier_type_id INTO @zlId FROM patient_identifier_type WHERE uuid IN ('a541af1e-105c-40bf-b345-ba1fd6a59b85' ,'1a2acce0-7426-11e5-a837-0800200c9a66','0bc545e0-f401-11e4-b939-0800200c9a66');
SELECT person_attribute_type_id INTO @unknownPt FROM person_attribute_type WHERE uuid='8b56eac7-5c76-4b9c-8c6f-1deab8d3fc47';
SELECT encounter_type_id INTO @labResultEnc FROM encounter_type WHERE uuid= '4d77916a-0620-11e5-a6c0-1697f925ec7b';
SELECT order_type_id INTO @test_order FROM order_type WHERE uuid = '52a447d3-a64a-11e3-9aeb-50e549534c5e';
SELECT encounter_type_id INTO @specimen_collection FROM encounter_type WHERE uuid = '39C09928-0CAB-4DBA-8E48-39C631FA4286';
SELECT concept_id INTO @test_order FROM concept WHERE uuid = '393dec41-2fb5-428f-acfa-36ea85da6666';
SELECT concept_id INTO @not_performed FROM concept WHERE uuid = '5dc35a2a-228c-41d0-ae19-5b1e23618eda';
SELECT concept_id INTO @order_number FROM concept WHERE UUID = '393dec41-2fb5-428f-acfa-36ea85da6666'; 
SELECT concept_id INTO @result_date FROM concept WHERE UUID = '68d6bd27-37ff-4d7a-87a0-f5e0f9c8dcc0'; 
SELECT concept_id INTO @test_location FROM concept WHERE UUID = GLOBAL_PROPERTY_VALUE('labworkflowowa.locationOfLaboratory', 'Unknown Location'); -- test location may differ by implementation
SELECT concept_id INTO @test_status FROM concept WHERE UUID = '7e0cf626-dbe8-42aa-9b25-483b51350bf8'; 
SELECT concept_id INTO @collection_date_estimated FROM concept WHERE UUID = '87f506e3-4433-40ec-b16c-b3c65e402989'; 

-- this temp table stores specimen collection encounter-level information
DROP TEMPORARY TABLE IF EXISTS temp_laborders_spec;
CREATE TEMPORARY TABLE temp_laborders_spec
(
  order_number VARCHAR(50),
  lab_id VARCHAR(255),	
  concept_id INT(11),
  encounter_id INT(11),
  encounter_datetime  DATETIME,
  encounter_location VARCHAR(255),
  patient_id INT(11),
  emr_id VARCHAR(50),
  loc_registered VARCHAR(255),
  unknown_patient VARCHAR(50),
  gender VARCHAR(50),
  age_at_enc INT(11),
  department VARCHAR(255),
  commune VARCHAR(255),
  section VARCHAR(255),
  locality VARCHAR(255),
  street_landmark VARCHAR(255),
  results_date DATETIME,
  results_entry_date DATETIME
 );

-- this temp table stores specimen encounter-level information from above and result-level information 
DROP TEMPORARY TABLE IF EXISTS temp_labresults;
CREATE TEMPORARY TABLE temp_labresults
(
  patient_id INT(11),
  emr_id VARCHAR(50),
  encounter_location VARCHAR(255),
  loc_registered VARCHAR(255),
  unknown_patient VARCHAR(50),
  gender VARCHAR(50),
  age_at_enc INT(11),
  department VARCHAR(255),
  commune VARCHAR(255),
  section VARCHAR(255),
  locality VARCHAR(255),
  street_landmark VARCHAR(255),
  order_number VARCHAR(50) ,
  orderable VARCHAR(255),
  test VARCHAR(255),
  lab_id VARCHAR(255),	
  LOINC VARCHAR(255),	
  specimen_collection_date DATETIME,
  results_date DATETIME,
  results_entry_date DATETIME,
  result VARCHAR(255),
  units VARCHAR(255),
  test_concept_id INT(11),
  reason_not_performed TEXT,
  result_coded_answer VARCHAR(255),
  result_numeric_answer DOUBLE,
  result_text_answer TEXT
);
 
 -- this loads all specimen encounters (from the lab application) into a temp table 
INSERT INTO temp_laborders_spec (encounter_id,encounter_datetime,patient_id,emr_id, encounter_location)
SELECT e.encounter_id,
e.encounter_datetime,
e.patient_id,
PATIENT_IDENTIFIER(e.patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')),
location_name(location_id)
FROM encounter e
WHERE e.encounter_type = @specimen_collection AND e.voided = 0
AND (@startDate IS NULL OR DATE(e.encounter_datetime) >= DATE(@startDate))
AND (@endDate IS NULL OR DATE(e.encounter_datetime) <= DATE(@endDate));



-- updates order number 
UPDATE temp_laborders_spec t
INNER JOIN obs sco ON sco.encounter_id = t.encounter_id AND sco.concept_id = @test_order AND sco.voided = 0
SET order_number = sco.value_text;

-- updates concept id and lab_id of orderable
UPDATE temp_laborders_spec t
INNER JOIN orders o ON o.order_number = t.order_number
SET t.concept_id = o.concept_id,
    t.lab_id = o.accession_number
;

 -- this adds the standalone lab results encounters into the temp table 
INSERT INTO temp_laborders_spec (encounter_id,encounter_datetime,patient_id,emr_id, encounter_location)
SELECT e.encounter_id,
e.encounter_datetime,
e.patient_id,
PATIENT_IDENTIFIER(e.patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')),
location_name(location_id)
FROM encounter e
WHERE e.encounter_type = @labResultEnc AND e.voided = 0
AND (@startDate IS NULL OR DATE(e.encounter_datetime) >= DATE(@startDate))
AND (@endDate IS NULL OR DATE(e.encounter_datetime) <= DATE(@endDate));

-- emr id location 
UPDATE temp_laborders_spec ts 
SET ts.loc_registered =loc_registered(ts.patient_id)
;

-- unknown patient
UPDATE temp_laborders_spec ts
LEFT OUTER JOIN person_attribute un ON ts.patient_id = un.person_id AND un.person_attribute_type_id = @unknownPt AND un.voided = 0
SET ts.unknown_patient = un.value;

-- gender & age
UPDATE temp_laborders_spec ts
INNER JOIN person pr ON ts.patient_id = pr.person_id AND pr.voided = 0
SET ts.gender = pr.gender,
ts.age_at_enc = ROUND(DATEDIFF(ts.encounter_datetime, pr.birthdate)/365.25, 1);

-- address
UPDATE temp_laborders_spec ts
INNER JOIN person_address pa ON pa.person_address_id = (SELECT person_address_id FROM person_address a2 WHERE a2.person_id =  ts.patient_id AND a2.voided = 0
                                                               ORDER BY a2.preferred DESC, a2.date_created DESC LIMIT 1)
SET department = pa.state_province,
commune = pa.city_village,
section = pa.address3,
locality =pa.address1,
street_landmark =pa.address2
;

 -- results date
UPDATE temp_laborders_spec ts
INNER JOIN obs res_date ON res_date.voided = 0 AND res_date.encounter_id = ts.encounter_id AND res_date.concept_id = @result_date
SET ts.results_date = res_date.value_datetime;

-- This query loads all specimen encounter-level information from above and observations from results entered  
INSERT INTO temp_labresults (patient_id,emr_id,encounter_location, loc_registered, unknown_patient, gender, age_at_enc, department, commune, section, locality, street_landmark,order_number,orderable,specimen_collection_date, results_date, results_entry_date,test_concept_id,test, lab_id, LOINC,result_coded_answer,result_numeric_answer,result_text_answer)
SELECT ts.patient_id,
ts.emr_id,
ts.encounter_location,
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
IFNULL(CONCEPT_NAME(ts.concept_id,@locale),CONCEPT_NAME(ts.concept_id,'en')), 
res.obs_datetime, 
ts.results_date,
-- ts.results_entry_date,
res.obs_datetime,
res.concept_id, 
IFNULL(CONCEPT_NAME(res.concept_id, @locale),CONCEPT_NAME(res.concept_id,'en')), 
ts.lab_id,							  
RETRIEVECONCEPTMAPPING(res.concept_id,'LOINC'),							  
IFNULL(CONCEPT_NAME(res.value_coded, @locale),CONCEPT_NAME(res.value_coded,'en')),
res.value_numeric,
res.value_text
  FROM temp_laborders_spec ts
-- observations from specimen collection encounters that are results (all except the ones listed below) are added here:   
INNER JOIN obs res ON res.encounter_id = ts.encounter_id
  AND res.voided = 0 AND res.concept_id NOT IN (@order_number,@result_date,@test_location,@test_status,@collection_date_estimated)
  AND (res.value_numeric IS NOT NULL OR res.value_text IS NOT NULL OR res.value_coded IS NOT NULL)
;

-- update test units (where they exist)
UPDATE temp_labresults t
INNER JOIN concept_numeric cu ON cu.concept_id = t.test_concept_id
SET t.units = cu.units
;

-- select  all output:
SELECT t.emr_id,
       t.loc_registered,
       t.encounter_location,
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
       CASE WHEN t.test_concept_id  <> @not_performed THEN t.test END AS 'test',
       t.lab_id,							   
       t.LOINC,							   
       DATE(t.specimen_collection_date) "specimen_collection_date",
       DATE(t.results_date) "results_date",
       t.results_entry_date,
       -- only return the result if the test was performed:     
       CASE 
         WHEN t.test_concept_id  <> @not_performed  AND t.result_numeric_answer IS NOT NULL THEN t.result_numeric_answer
         WHEN t.test_concept_id  <> @not_performed  AND t.result_text_answer IS NOT NULL THEN t.result_text_answer
         WHEN t.test_concept_id  <> @not_performed  AND t.result_coded_answer  IS NOT NULL THEN t.result_coded_answer 
       END AS 'result',
       t.units,
       CASE WHEN t.test_concept_id  = @not_performed  THEN t.result_coded_answer ELSE NULL END AS 'reason_not_performed'  
FROM temp_labresults t;
