#set @startDate='2023-05-01';
#set @endDate='2023-05-20';
 
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
SET sql_safe_updates = 0;
set @partition = '${partitionNum}';

SELECT concept_id INTO @not_performed FROM concept WHERE uuid = '5dc35a2a-228c-41d0-ae19-5b1e23618eda';
SET @result_date = concept_from_mapping('PIH','10783');
DROP TEMPORARY TABLE IF EXISTS temp_labresults;
CREATE TEMPORARY TABLE temp_labresults
( 
  patient_id                      INT(11),      
  emr_id                          VARCHAR(50),  
  encounter_id                    INT(11),      
  encounter_type                  VARCHAR(255), 
  obs_id                          INT(11),      
  visit_id                        INT(11),      
  test_concept_id                 INT(11),      
  value_coded_concept_id          INT(11),      
  value_text                      TEXT,         
  value_numeric                   DOUBLE,       
  order_id                        INT(11),      
  loc_registered                  VARCHAR(255), 
  encounter_location_id           INT(11),      
  encounter_location              VARCHAR(255), 
  unknown_patient                 VARCHAR(50),  
  gender                          VARCHAR(50),  
  age_at_encounter                INT(11),      
  order_number                    VARCHAR(50), 
  orderable                       VARCHAR(255), 
  test                            VARCHAR(255), 
  lab_id                          VARCHAR(255),   
  LOINC                           VARCHAR(255),   
  result                          TEXT,         
  specimen_collection_date        DATETIME,     
  specimen_collection_entry_date  DATETIME,     
  user_entered                    TEXT,
  units                           VARCHAR(255), 
  reason_not_performed_concept_id INT(11),      
  reason_not_performed            VARCHAR(255), 
  results_date_obs_id             INT(11),      
  results_date                    DATETIME,     
  results_entry_date              DATETIME,
  index_asc                       INT,
  index_desc                      INT
);

-- The following porcedure populates table temp_lab_concepts with all of the concept_ids of reportable labs
call populate_lab_concepts();

-- insert labs with results
INSERT into temp_labresults
	(obs_id,
	patient_id,
	encounter_id,
	test_concept_id,
	order_id,
	value_coded_concept_id,
	value_numeric,
	value_text)	
select 
	o.obs_id, 
	o.person_id, 
	o.encounter_id , 
	o.concept_id, 
	o.order_id, 
	o.value_coded, 
	o.value_numeric, 
	o.value_text
from obs o 
inner join temp_lab_concepts c on c.concept_id = o.concept_id
where o.voided = 0
and (value_coded is not null or value_numeric is not null or value_text is not null)
and (@startDate is null or DATE(o.obs_datetime) >= DATE(@startDate))
and (@endDate is null or DATE(o.obs_datetime) <= DATE(@endDate));

-- insert labs not performed
INSERT into temp_labresults
	(obs_id,
	patient_id,
	encounter_id,
	order_id,
	reason_not_performed_concept_id)
select 
	o.obs_id, 
	o.person_id, 
	o.encounter_id, 
	o.order_id,
	o.value_coded 
from obs o 
where o.voided = 0
and concept_id = @not_performed
and (@startDate is null or DATE(o.obs_datetime) >= DATE(@startDate))
and (@endDate is null or DATE(o.obs_datetime) <= DATE(@endDate));

create index temp_labresults_pi on temp_labresults(patient_id);

-- patient level columns
DROP TEMPORARY TABLE IF EXISTS temp_lab_patient;
CREATE TEMPORARY TABLE temp_lab_patient
(
 patient_id      INT(11),      
 emr_id          VARCHAR(50),  
 unknown_patient VARCHAR(50),  
 gender          VARCHAR(50),  
 loc_registered  VARCHAR(255) 
 );
 
insert into temp_lab_patient(patient_id)
select distinct patient_id from temp_labresults;

create index temp_lab_patient_pi on temp_lab_patient(patient_id);

update temp_lab_patient set emr_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_lab_patient set loc_registered = loc_registered(patient_id);
update temp_lab_patient set unknown_patient = unknown_patient(patient_id);
update temp_lab_patient set gender = gender(patient_id);

update temp_labresults t
inner join temp_lab_patient p on t.patient_id = p.patient_id
set t.emr_id =  p.emr_id,
	t.unknown_patient =  p.unknown_patient,
	t.gender =  p.gender,
	t.loc_registered =  p.loc_registered;

-- encounter level columns
DROP TEMPORARY TABLE IF EXISTS temp_lab_encounter;
CREATE TEMPORARY TABLE temp_lab_encounter
(
 patient_id               INT(11),      
 visit_id                 INT(11),      
 encounter_id             INT(11),      
 encounter_type_id        INT(11),      
 encounter_type           VARCHAR(255), 
 encounter_location_id    INT(11),      
 encounter_location       VARCHAR(255), 
 date_created             DATETIME,
 creator                  INT(11),
 user_entered             TEXT,
 age_at_encounter         DOUBLE,       
 specimen_collection_date DATETIME      
 );
 
insert into temp_lab_encounter(encounter_id)
select distinct encounter_id from temp_labresults;

create index temp_lab_patient_ei on temp_lab_encounter(encounter_id);
  
update temp_lab_encounter t
inner join encounter e on e.encounter_id = t.encounter_id
set t.patient_id = e.patient_id ,
 	t.encounter_location_id = e.location_id,
 	t.encounter_type_id = e.encounter_type, 
	t.specimen_collection_date = e.encounter_datetime, 
	t.date_created = e.date_created,
	t.creator = e.creator,
	t.visit_id = e.visit_id;

update temp_lab_encounter t
set encounter_type = encounter_type_name_from_id(encounter_type_id);

update temp_lab_encounter t
set encounter_location = location_name(t.encounter_location_id);

update temp_lab_encounter t
set user_entered = person_name_of_user(creator);

update temp_lab_encounter t
set age_at_encounter = ROUND(age_at_enc(t.patient_id, t.encounter_id));

update temp_labresults t
inner join temp_lab_encounter e on e.encounter_id = t.encounter_id
set t.encounter_location_id = e.encounter_location_id,
	t.encounter_type = e.encounter_type,
	t.encounter_location =  e.encounter_location,
	t.specimen_collection_date = e.specimen_collection_date,
	t.specimen_collection_entry_date =  e.date_created,
	t.age_at_encounter = e.age_at_encounter,
	t.user_entered = e.user_entered,
	t.visit_id = e.visit_id;

-- order level columns
DROP TEMPORARY TABLE IF EXISTS temp_lab_orders;
CREATE TEMPORARY TABLE temp_lab_orders
(
 order_id             INT(11),      
 order_number         VARCHAR(50),  
 orderable_concept_id INT(11),      
 orderable            VARCHAR(255), 
 lab_id               VARCHAR(255)  
 );

insert into temp_lab_orders (order_id) 
select DISTINCT order_id from temp_labresults where order_id is not null;

create index temp_lab_orders_oi on temp_lab_orders(order_id);

update temp_lab_orders t
inner join orders o on o.order_id = t.order_id
set t.order_number = o.order_number,
	t.orderable_concept_id = o.concept_id,
	t.lab_id = o.accession_number; 

update temp_lab_orders t set orderable = concept_name(orderable_concept_id, @locale);

update temp_labresults t 
inner join temp_lab_orders o on o.order_id = t.order_id
set t.order_number = o.order_number,
	t.orderable = o.orderable,
	t.lab_id = o.lab_id;

-- update test-level columns
update temp_labresults t 
set test = concept_name(test_concept_id, @locale);

update temp_labresults t
set result = 
	case 
		when value_coded_concept_id is not null then concept_name(value_coded_concept_id, @locale)
		when value_numeric is not null then value_numeric
		else value_text
	end;

update temp_labresults ts
set LOINC = RETRIEVECONCEPTMAPPING(test_concept_id,'LOINC');

UPDATE temp_labresults t
INNER JOIN concept_numeric cu ON cu.concept_id = t.test_concept_id
SET t.units = cu.units;

UPDATE temp_labresults t
set reason_not_performed = concept_name(reason_not_performed_concept_id, @locale);

update temp_labresults t
inner join obs o on o.encounter_id = t.encounter_id and o.voided = 0 and o.concept_id = @result_date
set results_date = o.value_datetime,
	results_entry_date = o.date_created;

-- select final output
SELECT
	if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.obs_id),t.obs_id) "obs_id",
	if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.patient_id),t.patient_id) "patient_id",
	t.emr_id,
    if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.visit_id),t.visit_id) "visit_id",
    if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.encounter_id),t.encounter_id) "encounter_id",
    t.encounter_type,
    t.encounter_location,
    t.loc_registered,
    t.unknown_patient,
    t.gender,
    t.age_at_encounter,
	if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',t.order_number),t.order_number) "order_number",    
    t.orderable,
    test,
    t.lab_id,							   
    t.LOINC,							   
    DATE(t.specimen_collection_date) "specimen_collection_date",
    t.specimen_collection_entry_date,
    t.user_entered,
    DATE(t.results_date) "results_date",
    t.results_entry_date,
	t.result,
	t.units,
	t.reason_not_performed,
	t.index_asc,
	t.index_desc
FROM temp_labresults t;
