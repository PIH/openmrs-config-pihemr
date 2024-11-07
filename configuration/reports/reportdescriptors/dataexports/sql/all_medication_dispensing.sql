SELECT encounter_type_id  INTO @disp_enc_type FROM encounter_type et WHERE uuid='8ff50dea-18a1-4609-b4c9-3f8f2d611b84';
SET @partition = '${partitionNum}';

DROP TABLE IF EXISTS all_medication_dispensing;
CREATE TEMPORARY TABLE all_medication_dispensing
(
patient_id int,
obs_group_id int,
form varchar(10),
emr_id varchar(50),
encounter_id int,
encounter_datetime datetime,
encounter_location varchar(100),
date_entered date,
user_entered varchar(30),
encounter_provider varchar(30),
drug_id int(11),
drug_name varchar(500),
drug_openboxes_code int,
duration int,
duration_unit varchar(20),
quantity_per_dose double,
dose_unit text,
frequency varchar(50),
quantity_dispensed int,
quantity_unit varchar(30),
order_id int, 
dispensing_status varchar(50),
status_reason varchar(50),
instructions text
);

set @dispensing_construct =  concept_from_mapping('PIH','9070');
-- add a row for every dispensing obs group construct
insert into all_medication_dispensing
(patient_id,
encounter_id,
obs_group_id,
form
)
select 
o.person_id,
o.encounter_id,
o.obs_id,
'Old'
from obs o 
where concept_id =  @dispensing_construct
AND o.voided = 0;

create index med_encounter_id on all_medication_dispensing(encounter_id);
create index med_obs_group on all_medication_dispensing(obs_group_id);

-- copy all distinct encounters to a row-per-encounter table to update the encounter-level columns
DROP TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter
(
encounter_id 			int(11),
encounter_datetime		datetime,
encounter_location_id   int(11),	
encounter_location      varchar(255),
date_entered 			date,
creator					int(11),
user_entered            varchar(255),
encounter_provider 		varchar(255)
);

insert into temp_encounter (encounter_id)
select distinct encounter_id from all_medication_dispensing;

create index temp_encounter_encounter_id on temp_encounter(encounter_id);

update temp_encounter 
set encounter_provider = provider(encounter_id);

update temp_encounter t
inner join encounter e on t.encounter_id = e.encounter_id 
set t.encounter_datetime = e.encounter_datetime,
	t.encounter_location_id = e.location_id,
	t.date_entered = e.date_created ,
	t.creator = e.creator ;

update temp_encounter 
set encounter_location = location_name(encounter_location_id);

update temp_encounter 
set user_entered =  person_name_of_user(creator);

update all_medication_dispensing md
inner join temp_encounter t on md.encounter_id = t.encounter_id
set md.encounter_datetime = t.encounter_datetime,
	md.encounter_location = t.encounter_location,
	md.date_entered = t.date_entered,
	md.user_entered = t.user_entered,
	md.encounter_provider = t.encounter_provider;

-- update emr ids 
-- copy all distinct patients to a row-per-encounter table
DROP TABLE IF EXISTS temp_emr_ids;
CREATE TEMPORARY TABLE temp_emr_ids
(patient_id int(11),
emr_id		varchar(50)
);

insert into temp_emr_ids (patient_id)
select distinct patient_id from all_medication_dispensing;

create index temp_emr_ids_patient_id on temp_emr_ids(patient_id);

UPDATE temp_emr_ids
SET emr_id=PATIENT_IDENTIFIER(patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 

update all_medication_dispensing md
inner join temp_emr_ids ei on ei.patient_id = md.patient_id
set md.emr_id = ei.emr_id;

-- create a reduced obs table with only rows for the dispensing obs groups for all of the obs-level columns
drop temporary table if exists temp_obs;
create temporary table temp_obs 
select o.obs_group_id ,o.concept_id, o.value_coded, o.value_numeric, o.value_text,  o.value_drug  
from obs o
inner join all_medication_dispensing t on t.obs_group_id = o.obs_group_id 
where o.voided = 0;

create index temp_obs_obs_ci on temp_obs(obs_group_id, concept_id);

-- collate and decode observations to each obs_group
set @dose = concept_from_mapping('PIH','9073');
set @doseUnit = concept_from_mapping('PIH','9074');
set @drug = concept_from_mapping('PIH','1282');
set @duration = concept_from_mapping('PIH','9075');
set @duration_unit = concept_from_mapping('PIH','6412');
set @frequency = concept_from_mapping('PIH','9363');
set @inxs = concept_from_mapping('PIH','9072');
set @quantity = concept_from_mapping('PIH','9071');
set @qunits = concept_from_mapping('PIH','9074');
drop temporary table if exists temp_obs_collated;
create temporary table temp_obs_collated 
select 
obs_group_id,
max(case when concept_id = @dose then value_numeric end) "dose",
max(case when concept_id = @doseUnit then value_text end) "doseUnit",
max(case when concept_id = @drug then value_drug end) "drugId",
max(case when concept_id = @duration then value_numeric end) "duration",
max(case when concept_id = @duration_unit then concept_name(value_coded,@locale) end) "duration_unit",
max(case when concept_id = @frequency then concept_name(value_coded,@locale) end) "frequency",
max(case when concept_id = @quantity then value_numeric end) "quantity",
max(case when concept_id = @qunits then value_text end) "qunits",
max(case when concept_id = @inxs then value_text end) "inxs"
from temp_obs 
group by obs_group_id;

create index temp_obs_collated_ogi on temp_obs_collated(obs_group_id);

update all_medication_dispensing t
inner join  temp_obs_collated o on o.obs_group_id = t.obs_group_id
set t.duration = o.duration,
	t.quantity_unit = o.qunits,
	t.duration_unit = o.duration_unit,
	t.quantity_per_dose = o.dose,
	t.dose_unit = o.doseUnit,
	t.frequency= o.frequency,
	t.quantity_dispensed = o.quantity,
	t.drug_id = o.drugId,
	t.instructions = o.inxs;

-- -- copy all distinct drugs to a row-per-drug table to update the drug level columns
DROP TABLE IF EXISTS temp_drug_ids;
CREATE TEMPORARY TABLE temp_drug_ids
(drug_id            int(11),
drug_name           varchar(255),
drug_openboxes_code int
);

insert into temp_drug_ids (drug_id)
select distinct drug_id from all_medication_dispensing;

create index temp_drug_id_dr on temp_drug_ids(drug_id);

UPDATE temp_drug_ids tgt 
SET drug_name= drugName(drug_id);

UPDATE temp_drug_ids tgt 
SET drug_openboxes_code= openboxesCode (drug_id);

update all_medication_dispensing tgt
inner join temp_drug_ids t on t.drug_id = tgt.drug_id
set tgt.drug_name = t.drug_name,
	tgt.drug_openboxes_code = t.drug_openboxes_code;

-- New Form --------
INSERT INTO all_medication_dispensing(form, patient_id, emr_id,encounter_datetime, user_entered,drug_name, drug_openboxes_code,
quantity_per_dose,dose_unit, frequency,quantity_dispensed, quantity_unit, order_id, dispensing_status, status_reason,instructions)
SELECT 
'New' AS form,
patient_id,
PATIENT_IDENTIFIER(patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')) emr_id,
md.date_created date_entered,
u.username user_entered,
drugName(drug_id) drug_name,
openboxesCode(drug_id) drug_openboxes_code,
dose quantity_per_dose,
concept_name(dose_units,'en') dose_units,
concept_name(of2.concept_id ,'en') frequency,
quantity quantity_dispensed,
concept_name(quantity_units,'en') AS quantity_unit, 
drug_order_id AS order_id, 
concept_name(status, 'en') AS dispensing_status,
concept_name(status_reason, 'en') AS status_reason,
dosing_instructions prescription
FROM medication_dispense md 
LEFT OUTER JOIN users u ON md.creator=u.user_id
LEFT OUTER JOIN order_frequency of2 ON of2.order_frequency_id = md.frequency;

-- final select of the data
SELECT 
form,
CONCAT(@partition,'-',patient_id) "patient_id",
emr_id,
CONCAT(@partition,'-',encounter_id) "encounter_id",
encounter_datetime,
encounter_location,
user_entered,
encounter_provider,
drug_name,
drug_openboxes_code,
duration,
duration_unit,
quantity_per_dose,
dose_unit,
frequency,
quantity_dispensed,
quantity_unit,
order_id,
dispensing_status,
status_reason,
instructions
FROM all_medication_dispensing;
