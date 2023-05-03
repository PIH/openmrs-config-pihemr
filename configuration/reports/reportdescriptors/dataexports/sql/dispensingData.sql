-- set @startDate = '2021-01-01';
-- set @endDate = '2021-12-31';

SET @pharmacy_encounter = ENCOUNTER_TYPE('8ff50dea-18a1-4609-b4c9-3f8f2d611b84');
SET @dispenser_role = (select encounter_role_id from encounter_role er where uuid = 'bad21515-fd04-4ff6-bfcd-78456d12f168');
SET @ordering_provider = (select encounter_role_id from encounter_role er where uuid = 'c458d78e-8374-4767-ad58-9f8fe276e01c');

DROP TEMPORARY TABLE IF EXISTS temp_meds;
CREATE TEMPORARY TABLE temp_meds
(	encounter_id		int(11),
	obs_id				int(11),
	medication			varchar(255),	
	drug_name			varchar(255),
	dosage				double,
	dosageUnits			varchar(255),
	frequency			varchar(255),
	duration			int,
	durationUnits		varchar(255),
	amount				int,
	instructions		varchar(255));

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.encounter_id, obs_id, obs_datetime, voided
from obs o 
where o.concept_id = concept_from_mapping('PIH','9070') -- dispensing construct 
;

-- create index temp_obs_1 on temp_obs(obs_datetime, voided);  -- removed this because creating the index was taking more time than the subsequent query

insert into temp_meds(encounter_id,obs_id)
select o.encounter_id, obs_id 
from temp_obs o 
where DATE(o.obs_datetime) >= @startDate AND DATE(o.obs_datetime) <= @endDate
 and o.voided = 0
;
create index temp_meds_oi on temp_meds(obs_id);
create index temp_meds_ei on temp_meds(encounter_id);

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.value_coded_name_id ,o.value_drug ,o.comments 
from obs o
inner join temp_meds t on t.obs_id = o.obs_group_id
where o.voided = 0;

create index temp_obs_ci1 on temp_obs(obs_group_id, concept_id);

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','1282')
set t.medication = concept_name(o.value_coded, @locale);

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','1282')
set t.drug_name = drugName(o.value_drug);

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','9073')
set t.dosage = value_numeric;

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','9074')
set t.dosageUnits = value_text;

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','9363')
set t.frequency = concept_name(o.value_coded, @locale);

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','9075')
set t.duration = value_numeric;

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','6412')
set t.durationUnits = concept_name(o.value_coded, @locale);

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','9071')
set t.amount = value_numeric;

update temp_meds t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','9072')
set t.instructions = value_text;

DROP TEMPORARY TABLE IF EXISTS temp_dispensing_enc;
CREATE TEMPORARY TABLE temp_dispensing_enc
(
	patient_id			int(11),
	encounter_id		int(11),
	visit_id				int(11),
	patientIdentifier	varchar(25),
	location_id			int(11),
	dispensedLocation	varchar(255),
	dispensedDatetime	datetime,
	dispensedBy			varchar(255),
	prescribedBy		varchar(255),
	typeOfPrescription	varchar(255),
	locationOfPrescription	varchar(255)
);

INSERT INTO temp_dispensing_enc(encounter_id)
select distinct encounter_id from temp_meds;

create index temp_dispensing_enc_ei on temp_dispensing_enc(encounter_id);

update temp_dispensing_enc t
inner join encounter e on e.encounter_id = t.encounter_id
set t.patient_id = e.patient_id,
	t.visit_id = e.visit_id ,
	t.location_id = e.location_id ,
	t.dispensedDatetime = e.encounter_datetime; 
 
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.value_coded_name_id ,o.comments,o.date_created  
from obs o
inner join temp_dispensing_enc t on t.encounter_id = o.encounter_id 
where o.voided = 0
and o.concept_id in (
	concept_from_mapping('PIH', '9292'),
	concept_from_mapping('PIH', '9293'))
and o.obs_group_id is null;

-- create index temp_obs_concept_id on temp_obs(concept_id);
create index temp_obs_ci1 on temp_obs(encounter_id, concept_id);

update temp_dispensing_enc t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.concept_id = concept_from_mapping('PIH', '9292')
set typeOfPrescription = concept_name(o.value_coded, @locale);

update temp_dispensing_enc t
inner join temp_obs o on o.encounter_id = t.encounter_id and o.concept_id = concept_from_mapping('PIH', '9293')
set locationOfPrescription = LOCATION_NAME(o.value_text);

-- update temp_dispensing_enc set typeOfPrescription = OBS_VALUE_CODED_LIST_FROM_TEMP(encounter_id, 'PIH', '9292', @locale);
-- update temp_dispensing_enc set locationOfPrescription = LOCATION_NAME(OBS_VALUE_TEXT_FROM_TEMP(encounter_id, 'PIH', '9293'));

update temp_dispensing_enc set dispensedLocation = location_name(location_id);
update temp_dispensing_enc set patientIdentifier = zlemr(patient_id);
update temp_dispensing_enc set dispensedBy = provider_name_of_type(encounter_id, @dispenser_role, 0);
update temp_dispensing_enc set prescribedBy = provider_name_of_type(encounter_id, @ordering_provider, 0);
update temp_dispensing_enc set dispensedLocation = encounter_location_name(encounter_id); 

select 
e.visit_id,
e.encounter_id,
m.medication,
m.drug_name,
m.dosage,
m.dosageUnits,
m.frequency,
m.duration,
m.durationUnits,
m.amount,
m.instructions,
e.patientIdentifier,
e.dispensedLocation,
e.dispensedDatetime,
e.dispensedBy,
e.prescribedBy,
e.typeOfPrescription,
e.locationOfPrescription
from temp_dispensing_enc e
inner join temp_meds m on m.encounter_id = e.encounter_id 
;
