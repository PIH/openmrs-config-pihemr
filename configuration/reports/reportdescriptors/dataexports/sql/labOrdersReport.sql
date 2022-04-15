-- set @startDate='2020-01-01';
-- set @endDate='2021-08-14';

SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
SET sql_safe_updates = 0;

SELECT order_type_id INTO @testOrder FROM order_type WHERE uuid = '52a447d3-a64a-11e3-9aeb-50e549534c5e';
SELECT encounter_type_id INTO @specimenCollEnc FROM encounter_type WHERE uuid = '39C09928-0CAB-4DBA-8E48-39C631FA4286';

DROP TEMPORARY TABLE IF EXISTS temp_report;
CREATE TEMPORARY TABLE temp_report
(
    patient_id      INT,
    emr_id          VARCHAR(255),
    specimen_encounter_id INT,
    order_encounter_id INT,
    loc_registered  VARCHAR(255),
    unknown_patient CHAR(1),
    gender          CHAR(1),
    age_at_enc      INT,
    patient_address VARCHAR(1000),
    order_number    VARCHAR(255),
    accession_number VARCHAR(255),
    order_concept_id INT,
    orderable       VARCHAR(255),
    status          VARCHAR(255),
    orderer         VARCHAR(255),
    orderer_provider_type VARCHAR(255),
    order_datetime  DATETIME,
    date_stopped    DATETIME,
    auto_expire_date DATETIME,
    fulfiller_status VARCHAR(255),
    ordering_location VARCHAR(255),
    urgency         VARCHAR(255),
    specimen_collection_datetime DATETIME,
    collection_date_estimated VARCHAR(255),
    test_location  VARCHAR(255),
    result_date     DATETIME
);

-- load temporary table with all lab test orders within the date range 
INSERT INTO temp_report (
    patient_id,
    order_number,
    accession_number,
    order_concept_id,
    order_encounter_id,
    order_datetime,
    date_stopped,
    auto_expire_date,
    fulfiller_status,
    urgency
)
SELECT
    o.patient_id,
    o.order_number,
    o.accession_number,
    o.concept_id,
    o.encounter_id,
    o.date_activated,
    o.date_stopped,
    o.auto_expire_date,
    o.fulfiller_status,
     o.urgency
FROM
    orders o
WHERE o.order_type_id =@testOrder
      AND order_action = 'NEW'
      AND (@startDate IS NULL OR DATE(o.date_activated) >= DATE(@startDate))
      AND (@endDate IS NULL OR DATE(o.date_activated) <= DATE(@endDate));

## REMOVE TEST PATIENTS
DELETE
FROM temp_report
WHERE patient_id IN
      (
          SELECT a.person_id
          FROM person_attribute a
          INNER JOIN person_attribute_type t ON a.person_attribute_type_id = t.person_attribute_type_id
          WHERE a.value = 'true'
          AND t.name = 'Test Patient'
      );
      
-- To join in the specimen encounters, a temporary table is created with all lab specimen encounters within the date range is loaded.
-- This table is indexed and then joined with the main report temp table
DROP TEMPORARY TABLE IF EXISTS temp_spec;
CREATE TEMPORARY TABLE temp_spec
(
    specimen_encounter_id INT,
    order_number   VARCHAR(255) 
   );      

CREATE  INDEX order_number ON temp_spec(order_number);


INSERT INTO temp_spec (
    specimen_encounter_id,
    order_number
)
SELECT
    e.encounter_id,
    o.value_text
FROM
    encounter e
    INNER JOIN obs o ON o.encounter_id = e.encounter_id AND o.voided = 0 AND o.concept_id =  CONCEPT_FROM_MAPPING('PIH','10781')
WHERE e.encounter_type = @specimenCollEnc
      AND e.voided = 0;

UPDATE temp_report t
  LEFT OUTER JOIN temp_spec ts ON ts.order_number = t.order_number 
  SET  t.specimen_encounter_id = ts.specimen_encounter_id;

-- Individual columns are populated here:
UPDATE temp_report SET emr_id = PATIENT_IDENTIFIER(patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 
UPDATE temp_report SET gender = GENDER(patient_id);
UPDATE temp_report SET loc_registered = LOC_REGISTERED(patient_id);
UPDATE temp_report SET age_at_enc = AGE_AT_ENC(patient_id,order_encounter_id );
UPDATE temp_report SET unknown_patient = IF(UNKNOWN_PATIENT(patient_id) IS NULL,NULL,'1'); 
UPDATE temp_report SET patient_address = PERSON_ADDRESS(patient_id);
UPDATE temp_report SET orderable = IFNULL(CONCEPT_NAME(order_concept_id, @locale),CONCEPT_NAME(order_concept_id, 'en'));
-- status is derived by the order fulfiller status and other fields
UPDATE temp_report t SET status =
    CASE
       WHEN t.date_stopped IS NOT NULL AND specimen_encounter_id IS NULL THEN 'Cancelled'
       WHEN t.auto_expire_date < CURDATE() AND specimen_encounter_id IS NULL THEN 'Expired'
       WHEN t.fulfiller_status = 'COMPLETED' THEN 'Reported'
       WHEN t.fulfiller_status = 'IN_PROGRESS' THEN 'Collected'
       WHEN t.fulfiller_status = 'EXCEPTION' THEN 'Not Performed'
       ELSE 'Ordered'
    END ;
UPDATE temp_report t SET orderer = PROVIDER(t.order_encounter_id);
UPDATE temp_report t SET orderer_provider_type = PROVIDER_TYPE(t.order_encounter_id);
UPDATE temp_report t SET ordering_location = ENCOUNTER_LOCATION_NAME(t.order_encounter_id);

update temp_report t
  inner join encounter e on e.encounter_id = t.specimen_encounter_id
set t.specimen_collection_datetime = e.encounter_datetime;

update temp_report t 
  inner join obs o on o.encounter_id = t.specimen_encounter_id and o.voided  = 0 
    and o.concept_id = concept_from_mapping('PIH','11791')
set test_location = concept_name(o.value_coded, @locale);
 
update temp_report t 
  inner join obs o on o.encounter_id = t.specimen_encounter_id and o.voided  = 0 
    and o.concept_id = concept_from_mapping('PIH','Date of test results')
set result_date = o.value_datetime;

update temp_report t 
  inner join obs o on o.encounter_id = t.specimen_encounter_id and o.voided  = 0 
    and o.concept_id = concept_from_mapping('PIH','11781')
set collection_date_estimated = concept_name(o.value_coded, @locale);

-- final output
SELECT 
emr_id, 
loc_registered,
unknown_patient, 
gender, 
age_at_enc,
patient_address,
order_number,
accession_number "Lab_ID",
orderable,
status,
orderer,
orderer_provider_type,
order_datetime,
ordering_location,
urgency,
specimen_collection_datetime,
collection_date_estimated,
test_location,
result_date
FROM temp_report;
