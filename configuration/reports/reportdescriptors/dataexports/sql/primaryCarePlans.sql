-- set @startDate = '2021-03-01';
-- set @endDate = '2021-03-08';

CALL initialize_global_metadata();
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
 
DROP TEMPORARY TABLE IF EXISTS temp_plan;
CREATE TEMPORARY TABLE temp_plan
(
    patient_id          int(11),
    dossierId           varchar(50),
    zlemrid              varchar(50),
    loc_registered      varchar(255), 
    encounter_datetime  datetime,
    encounter_location  varchar(255), 
    encounter_type      varchar(255),                
    provider            varchar(255), 
    encounter_id        int(11),
    Clinical_Plan       varchar(1000),  
    Lab_Tests           varchar(1000),  
    Disposition         varchar(255),
    Comment             varchar(1000),     
    Return_visit_date   datetime,
    Medication_1        varchar(255),
    Dose_Quantity_1     int(11),
    Dose_Units_1        varchar(255),
    Duration_1          int(11),
    Duration_Units_1    varchar(255),
    Frequency_1         varchar(255),
    Instructions_1      varchar(255),
    Medication_2        varchar(255),
    Dose_Quantity_2     int(11),
    Dose_Units_2        varchar(255),
    Duration_2          int(11),
    Duration_Units_2    varchar(255),
    Frequency_2         varchar(255),
    Instructions_2      varchar(255),
    Medication_3        varchar(255),
    Dose_Quantity_3     int(11),
    Dose_Units_3        varchar(255),
    Duration_3          int(11),
    Duration_Units_3    varchar(255),
    Frequency_3         varchar(255),
    Instructions_3      varchar(255),
    Medication_4        varchar(255),
    Dose_Quantity_4     int(11),
    Dose_Units_4        varchar(255),
    Duration_4          int(11),
    Duration_Units_4    varchar(255),
    Frequency_4         varchar(255),
    Instructions_4      varchar(255),  
    Medication_5        varchar(255),
    Dose_Quantity_5     int(11),
    Dose_Units_5        varchar(255),
    Duration_5          int(11),
    Duration_Units_5    varchar(255),
    Frequency_5         varchar(255),
    Instructions_5      varchar(255),
    Medication_6        varchar(255),
    Dose_Quantity_6     int(11),
    Dose_Units_6        varchar(255),
    Duration_6          int(11),
    Duration_Units_6    varchar(255),
    Frequency_6         varchar(255),
    Instructions_6      varchar(255),
    Medication_7        varchar(255),
    Dose_Quantity_7     int(11),
    Dose_Units_7        varchar(255),
    Duration_7          int(11),
    Duration_Units_7    varchar(255),
    Frequency_7         varchar(255),
    Instructions_7      varchar(255),
    Medication_8        varchar(255),
    Dose_Quantity_8     int(11),
    Dose_Units_8        varchar(255),
    Duration_8          int(11),
    Duration_Units_8    varchar(255),
    Frequency_8         varchar(255),
    Instructions_8      varchar(255)
);

insert into temp_plan (
  patient_id,
  encounter_id,
  encounter_datetime,
  encounter_type)
select
  patient_id,
  encounter_id,
  encounter_datetime,
  et.name
from encounter e
inner join encounter_type et on et.encounter_type_id = e.encounter_type
where e.encounter_type in (@AdultInitEnc, @AdultFollowEnc, @PedInitEnc, @PedFollowEnc)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
and voided = 0
;

update temp_plan set zlemrid = zlemr(patient_id);
update temp_plan set dossierid = dosid(patient_id);
update temp_plan set loc_registered = loc_registered(patient_id);
update temp_plan set encounter_location = encounter_location_name(encounter_id);
update temp_plan set provider = provider(encounter_id);

update temp_plan set clinical_plan = obs_value_text(encounter_id,'CIEL','162749');
update temp_plan set lab_tests = obs_value_coded_list(encounter_id,'PIH','Lab test ordered coded',@locale);
update temp_plan set disposition = obs_value_coded_list(encounter_id,'PIH','HUM Disposition categories',@locale);
update temp_plan set comment = obs_value_text(encounter_id,'PIH','DISPOSITION COMMENTS');
update temp_plan set Return_visit_date = obs_value_datetime(encounter_id,'PIH','RETURN VISIT DATE');


update temp_plan set medication_1 = obs_from_group_id_value_drug(obs_id(encounter_id,'PIH','Prescription construct',0),'PIH','MEDICATION ORDERS'); 
update temp_plan set dose_quantity_1 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',0),'CIEL','160856'); 
update temp_plan set dose_units_1 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',0),'PIH','Dosing units coded',@locale); 
update temp_plan set duration_1 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',0),'CIEL','159368'); 
update temp_plan set duration_units_1 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',0),'PIH','TIME UNITS',@locale); 
update temp_plan set frequency_1 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',0),'PIH','Drug frequency for HUM',@locale); 
update temp_plan set instructions_1 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','Prescription construct',0),'PIH','Prescription instructions non-coded'); 

update temp_plan set medication_2 = obs_from_group_id_value_drug(obs_id(encounter_id,'PIH','Prescription construct',1),'PIH','MEDICATION ORDERS'); 
update temp_plan set dose_quantity_2 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',1),'CIEL','160856'); 
update temp_plan set dose_units_2 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',1),'PIH','Dosing units coded',@locale); 
update temp_plan set duration_2 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',1),'CIEL','159368'); 
update temp_plan set duration_units_2 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',1),'PIH','TIME UNITS',@locale); 
update temp_plan set frequency_2 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',1),'PIH','Drug frequency for HUM',@locale); 
update temp_plan set instructions_2 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','Prescription construct',1),'PIH','Prescription instructions non-coded'); 

update temp_plan set medication_3 = obs_from_group_id_value_drug(obs_id(encounter_id,'PIH','Prescription construct',2),'PIH','MEDICATION ORDERS'); 
update temp_plan set dose_quantity_3 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',2),'CIEL','160856'); 
update temp_plan set dose_units_3 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',2),'PIH','Dosing units coded',@locale); 
update temp_plan set duration_3 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',2),'CIEL','159368'); 
update temp_plan set duration_units_3 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',2),'PIH','TIME UNITS',@locale); 
update temp_plan set frequency_3 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',2),'PIH','Drug frequency for HUM',@locale); 
update temp_plan set instructions_3 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','Prescription construct',2),'PIH','Prescription instructions non-coded'); 

update temp_plan set medication_4 = obs_from_group_id_value_drug(obs_id(encounter_id,'PIH','Prescription construct',3),'PIH','MEDICATION ORDERS'); 
update temp_plan set dose_quantity_4 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',3),'CIEL','160856'); 
update temp_plan set dose_units_4 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',3),'PIH','Dosing units coded',@locale); 
update temp_plan set duration_4 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',3),'CIEL','159368'); 
update temp_plan set duration_units_4 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',3),'PIH','TIME UNITS',@locale); 
update temp_plan set frequency_4 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',3),'PIH','Drug frequency for HUM',@locale); 
update temp_plan set instructions_4 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','Prescription construct',3),'PIH','Prescription instructions non-coded'); 

update temp_plan set medication_5 = obs_from_group_id_value_drug(obs_id(encounter_id,'PIH','Prescription construct',4),'PIH','MEDICATION ORDERS'); 
update temp_plan set dose_quantity_5 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',4),'CIEL','160856'); 
update temp_plan set dose_units_5 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',4),'PIH','Dosing units coded',@locale); 
update temp_plan set duration_5 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',4),'CIEL','159368'); 
update temp_plan set duration_units_5 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',4),'PIH','TIME UNITS',@locale); 
update temp_plan set frequency_5 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',4),'PIH','Drug frequency for HUM',@locale); 
update temp_plan set instructions_5 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','Prescription construct',4),'PIH','Prescription instructions non-coded'); 

update temp_plan set medication_6 = obs_from_group_id_value_drug(obs_id(encounter_id,'PIH','Prescription construct',5),'PIH','MEDICATION ORDERS'); 
update temp_plan set dose_quantity_6 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',5),'CIEL','160856'); 
update temp_plan set dose_units_6 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',5),'PIH','Dosing units coded',@locale); 
update temp_plan set duration_6 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',5),'CIEL','159368'); 
update temp_plan set duration_units_6 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',5),'PIH','TIME UNITS',@locale); 
update temp_plan set frequency_6 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',5),'PIH','Drug frequency for HUM',@locale); 
update temp_plan set instructions_6 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','Prescription construct',5),'PIH','Prescription instructions non-coded'); 

update temp_plan set medication_7 = obs_from_group_id_value_drug(obs_id(encounter_id,'PIH','Prescription construct',6),'PIH','MEDICATION ORDERS'); 
update temp_plan set dose_quantity_7 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',6),'CIEL','160856'); 
update temp_plan set dose_units_7 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',6),'PIH','Dosing units coded',@locale); 
update temp_plan set duration_7 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',6),'CIEL','159368'); 
update temp_plan set duration_units_7 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',6),'PIH','TIME UNITS',@locale); 
update temp_plan set frequency_7 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',6),'PIH','Drug frequency for HUM',@locale); 
update temp_plan set instructions_7 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','Prescription construct',6),'PIH','Prescription instructions non-coded');

update temp_plan set medication_8 = obs_from_group_id_value_drug(obs_id(encounter_id,'PIH','Prescription construct',7),'PIH','MEDICATION ORDERS'); 
update temp_plan set dose_quantity_8 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',7),'CIEL','160856'); 
update temp_plan set dose_units_8 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',7),'PIH','Dosing units coded',@locale); 
update temp_plan set duration_8 = obs_from_group_id_value_numeric(obs_id(encounter_id,'PIH','Prescription construct',7),'CIEL','159368'); 
update temp_plan set duration_units_8 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',7),'PIH','TIME UNITS',@locale); 
update temp_plan set frequency_8 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'PIH','Prescription construct',7),'PIH','Drug frequency for HUM',@locale); 
update temp_plan set instructions_8 = obs_from_group_id_value_text(obs_id(encounter_id,'PIH','Prescription construct',7),'PIH','Prescription instructions non-coded'); 

-- select final output
select * from temp_plan;
