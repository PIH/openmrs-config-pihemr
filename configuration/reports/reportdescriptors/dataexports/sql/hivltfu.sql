-- This data export will include a row for each patient in the HIV program that is 1 day or later for their med pickup

select program_id into @hivProgram from program where uuid = 'b1cb1fc1-5190-4f7a-af08-48870975dafc';
select encounter_type_id into @hivDispensingEncType from encounter_type where uuid = 'cc1720c9-3e4c-4fa8-a7ec-40eeaad1958c';
select name into @hivDispensingEncName from encounter_type where encounter_type_id = @hivDispensingEncType;
select person_attribute_type_id into @phoneNumber from person_attribute_type where uuid = '14d4f066-15f5-102d-96e4-000c29c2a5d7';
select encounter_type_id into @hivAdultIntakeEncType from encounter_type where uuid = 'c31d306a-40c4-11e7-a919-92ebcb67fe33';
select encounter_type_id into @hivAdultFollowupEncType from encounter_type where uuid = 'c31d3312-40c4-11e7-a919-92ebcb67fe33';
select group_concat(name) into @hivVisitEncTypes from encounter_type where encounter_type_id in (@hivAdultIntakeEncType, @hivAdultFollowupEncType);
select program_workflow_id into @HIVTreatmentStatus from program_workflow where uuid = 'aba55bfe-9490-4362-9841-0c476e379889';
select program_workflow_id into @LTFUStatus from program_workflow where uuid = '56b3e516-b57e-4ab2-bbc2-82a8b3242d67';
select program_workflow_id into @ReactivationStatus from program_workflow where uuid = '038f8382-aeca-459a-a8b9-859043b64bf8';
set @locale = global_property_value('default_locale', 'en');


drop temporary table if exists temp_tracking;
create temporary table temp_tracking
(
patient_id int(11) primary key,
patient_program_id int(11),
patient_emr_id varchar(255),
enrollment_date date,
zl_site varchar(255),
patient_name varchar(255),
age int(11),
gender char(1),
phone_number varchar(255),
department varchar(255),
commune varchar(255),
section_communale varchar(255),
locality varchar(255),
address varchar(255),
accompagnateur varchar(255),
next_dispensing_date date,
last_dispensing_date date,
days_late int(11),
next_appointment_date date,
missed_appointment int(1),
treatment_status varchar(255),
last_viral_load_date date,
last_VL_result_qualitative varchar(255)
);

create index temp_tracking_patient_id on temp_tracking (patient_id);

-- insert row for each patient in the HIV Program.
-- Note that there SHOULD NOT be multiple patient program rows where date_completed is null
-- if there are, it will grab the max patient program id
insert into temp_tracking (patient_id,zl_site,patient_program_id)
select distinct patient_id, max(location_name(location_id)),max(patient_program_id) from patient_program pp
where pp.program_id = @hivProgram
and pp.date_completed is null
group by patient_id 
;

-- dispensing date and enrollment are updated. These are used later to determine how many days late a patient is
update temp_tracking t
inner join encounter e on e.encounter_id = latestEnc(t.patient_id, @hivDispensingEncName, null)
inner join obs o on o.encounter_id = e.encounter_id and o.voided = 0 and o.concept_id = concept_from_mapping('PIH','5096')
set t.next_dispensing_date = date(o.value_datetime)
;

update temp_tracking t
inner join patient_program pp on pp.patient_program_id = t.patient_program_id
set t.enrollment_date = date(pp.date_enrolled);

-- delete rows from temp table in cases where next dispensing date is in the future (i.e. NOT late for pickups)
delete from temp_tracking  where date(next_dispensing_date) >= current_date;

-- update program state information.  Note that treatment status, LTFU status and Reactivation status are the statuses of the HIV program in Haiti
-- this may need to be updated for other implementation
update temp_tracking t set treatment_status = currentProgramState(t.patient_program_id,@HIVTreatmentStatus,@locale);

-- update various patient demographics columns
update temp_tracking t set patient_emr_id = zlemr(patient_id);
update temp_tracking t set patient_name = person_name(patient_id);
update temp_tracking t
  inner join person p on p.person_id = t.patient_id
  set age =  TIMESTAMPDIFF(YEAR, birthdate, current_timestamp);
update temp_tracking t set gender  = gender(patient_id);
update temp_tracking t set phone_number = phone_number(patient_id);
update temp_tracking t
set department = person_address_state_province(t.patient_id),
    commune = person_address_city_village(t.patient_id),
    section_communale = person_address_three(t.patient_id),
    locality = person_address_one(t.patient_id),
    address = person_address_two(t.patient_id);

-- update patient accompagnateur (latest obs captured for this)
update temp_tracking t 
inner join obs o on obs_id = latestObs(patient_id,concept_from_mapping('CIEL',164141),null)
set accompagnateur = o.value_text;

-- update last dispensing date from the last encounter of this type
update temp_tracking t
  inner join encounter e_disp on e_disp.encounter_id  = latestEnc(t.patient_id, @hivDispensingEncName, null)
  set t.last_dispensing_date = date(e_disp.encounter_datetime);

-- calculate days late from expected dispensing date, or if the patient has none, use last dispensing date or then the enrollment date
update temp_tracking set days_late =  TIMESTAMPDIFF(DAY, ifnull(next_dispensing_date,ifnull(last_dispensing_date,enrollment_date)),current_date);

-- next expected appointment date
update temp_tracking t
inner join encounter e on e.encounter_id = latestEnc(t.patient_id, @hivVisitEncTypes, null)
inner join obs o on o.encounter_id = e.encounter_id and o.voided = 0 and o.concept_id = concept_from_mapping('PIH','5096')
set t.next_appointment_date = date(o.value_datetime);

-- set missed appointment if the next expected appointment (from hiv visits encounter type) is in the past or not set
update temp_tracking t
set t.missed_appointment = if( ifnull(date(t.next_appointment_date),'1900-01-01') <current_date,1,null);

-- update date and Viral Load results (qualitative only) from the last time this was recorded
update temp_tracking t
inner join obs o on obs_id = latestObs(t.patient_id,concept_from_mapping('CIEL','1305'),null)
set last_viral_load_date = date(o.obs_datetime),
    last_VL_result_qualitative = concept_name(o.value_coded,@locale);

-- select the output
select
patient_id,
patient_emr_id,
zl_site,
enrollment_date,
patient_name,
age,
gender,
phone_number,
department,
commune,
section_communale,
locality,
address,
accompagnateur,
next_dispensing_date,
last_dispensing_date,
days_late,
missed_appointment,
treatment_status,
last_viral_load_date,
last_VL_result_qualitative
from temp_tracking;
