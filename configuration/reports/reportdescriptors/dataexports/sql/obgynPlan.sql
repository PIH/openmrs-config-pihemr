-- set @startDate = '2021-03-20';
-- set @endDate = '2021-03-20';

CALL initialize_global_metadata();
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
select encounter_type_id into @obgynnote from encounter_type where uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d'; 

DROP TEMPORARY TABLE IF EXISTS temp_plan;
CREATE TEMPORARY TABLE temp_plan
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
    procedure_performed_1 varchar(255),
    procedure_performed_2 varchar(255),
    procedure_performed_3 varchar(255),
    procedure_performed_4 varchar(255),
    procedure_performed_5 varchar(255),
    other_procedure_performed varchar(255),
    support_given         varchar(1000),
    other_support          varchar(255),
    treatment_status      varchar(255),
    syphilis_treatment    varchar(255),
    other_support_comment varchar(255),
    accept_CHW            varchar(50),
    mom_club              varchar(50),
    PMTCT_club            varchar(50),
    Delivery_location     varchar(50),
    ARV_for_baby          varchar(50),
    referral_services     varchar(1000),
    other_referral_services varchar(255),
    disposition           varchar(255),
    disposition_comment   varchar(255),
    return_visit_date     datetime
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
where e.encounter_type in (@obgynnote)
AND date(e.encounter_datetime) >=@startDate
AND date(e.encounter_datetime) <=@endDate
and voided = 0
;

update temp_plan set zlemrid = zlemr(patient_id);
update temp_plan set dossierid = dosid(patient_id);
update temp_plan set loc_registered = loc_registered(patient_id);
update temp_plan set encounter_location = encounter_location_name(encounter_id);
update temp_plan set provider = provider(encounter_id);

-- procedures performed
update temp_plan set procedure_performed_1 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1938',0), 'CIEL', '1651',@locale);
update temp_plan set procedure_performed_2 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1938',1), 'CIEL', '1651',@locale);
update temp_plan set procedure_performed_3 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1938',2), 'CIEL', '1651',@locale);
update temp_plan set procedure_performed_4 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1938',3), 'CIEL', '1651',@locale);
update temp_plan set procedure_performed_5 = obs_from_group_id_value_coded_list(obs_id(encounter_id,'CIEL','1938',4), 'CIEL', '1651',@locale);
update temp_plan set other_procedure_performed = obs_value_text(encounter_id, 'CIEL','165264');

-- support given
update temp_plan set support_given = obs_value_coded_list(encounter_id,'CIEL','165309',@locale);
update temp_plan set other_support = obs_comments(encounter_id,'CIEL','165309','CIEL','5622');
update temp_plan set treatment_status = obs_value_coded_list(encounter_id,'CIEL','163105',@locale);
update temp_plan set syphilis_treatment = obs_value_coded_list(encounter_id,'CIEL','165331',@locale);
update temp_plan set other_support_comment = obs_value_text(encounter_id,'PIH','13273');

-- delivery plan
update temp_plan set accept_CHW = obs_value_coded_list(encounter_id,'PIH','3293',@locale);
update temp_plan set mom_club = obs_value_coded_list(encounter_id,'PIH','13261',@locale);
update temp_plan set PMTCT_club = obs_value_coded_list(encounter_id,'PIH','13262',@locale);
update temp_plan set Delivery_location = obs_value_coded_list(encounter_id,'CIEL','159758',@locale);
update temp_plan set ARV_for_baby = obs_value_coded_list(encounter_id,'CIEL','163764',@locale);

-- referrals
update temp_plan set referral_services = obs_value_coded_list(encounter_id,'PIH','1272',@locale);
update temp_plan set other_referral_services = obs_comments(encounter_id,'PIH','1272','CIEL','5622');

-- disposition
update temp_plan set disposition = obs_value_coded_list(encounter_id,'PIH','8620',@locale);
update temp_plan set disposition_comment = obs_value_text(encounter_id,'PIH','DISPOSITION COMMENTS');
update temp_plan set return_visit_date = obs_value_datetime(encounter_id,'PIH','RETURN VISIT DATE');

-- select final output
select * from temp_plan;
