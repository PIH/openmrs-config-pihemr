-- set @startDate = '2022-03-28';
-- set @endDate = '2022-04-01';

CALL initialize_global_metadata();

select encounter_role_id into @ordering_provider from encounter_role where uuid = 'c458d78e-8374-4767-ad58-9f8fe276e01c';
select encounter_role_id into @assisting_surgeon from encounter_role where uuid = '6e630e03-5182-4cb3-9a82-a5b1a85c09a7';
select encounter_role_id into @attending_surgeon from encounter_role where uuid = '9b135b19-7ebe-4a51-aea2-69a53f9383af';

DROP TEMPORARY TABLE IF EXISTS temp_pathology;
CREATE TEMPORARY TABLE temp_pathology
(
order_id                    INT(11),
order_number                VARCHAR(50),
encounter_id                INT(11),
patient_id                  INT(11),
zlemrid						          VARCHAR(50),
loc_registered				      VARCHAR(255),
patient_name				        VARCHAR(255),
unknown_patient				      VARCHAR(50),
gender						          VARCHAR(50),
age_at_enc					        INT,
department					        VARCHAR(255),
commune						          VARCHAR(255),
section						          VARCHAR(255),
locality					          VARCHAR(255),
street_landmark				      VARCHAR(255),
order_datetime				      DATETIME,
ordering_provider			      VARCHAR(255),
request_coded_proc1			    VARCHAR(255),
request_coded_proc2			    VARCHAR(255),
request_coded_proc3			    VARCHAR(255),
request_non_coded_proc		  TEXT,	
prepath_dx					        VARCHAR(255),
clinical_history			      TEXT,
specimen_accession_number	  TEXT,
post_op_diagnosis			      VARCHAR(255),
specimen_details_1			    TEXT,
specimen_details_2			    TEXT,
specimen_details_3			    TEXT,
specimen_details_4          TEXT,
attending_surgeon			      VARCHAR(255),
resident					          VARCHAR(255),
md_to_notify				        TEXT,
clinician_telephone			    TEXT,
urgent_review			          VARCHAR(255),
suspected_cancer		        VARCHAR(255),
immunohistochemistry_needed VARCHAR(255),
immunohistochemistry_sent   VARCHAR(255),
results_date				        DATETIME,
results_note				        TEXT,
file_uploaded				        VARCHAR(255)
);

insert into temp_pathology (order_id,encounter_id, order_number, patient_id, prepath_dx)
select o.order_id , o.encounter_id, o.order_number, patient_id, concept_name(order_reason,@locale)  from orders o
where o.order_type_id = @pathologyTestOrder
AND date(o.date_activated) >= @startDate
AND date(o.date_activated) <= @endDate
;

update temp_pathology t
set t.zlemrid = zlemr(patient_id);

update temp_pathology t
set t.patient_name = person_name(t.patient_id);

update temp_pathology t
set t.loc_registered  = loc_registered(t.patient_id);

update temp_pathology t
set unknown_patient = unknown_patient(t.patient_id);

update temp_pathology t
set gender = gender(t.patient_id);

update temp_pathology t
set age_at_enc = age_at_enc(t.patient_id, t.encounter_id);

update temp_pathology t
set department = person_address_state_province(t.patient_id);

update temp_pathology t
set commune = person_address_city_village(t.patient_id);

update temp_pathology t
set section = person_address_three(t.patient_id);

update temp_pathology t
set locality = person_address_one(t.patient_id);

update temp_pathology t
set street_landmark = person_address_two(t.patient_id); 

update temp_pathology t
set order_datetime  = encounter_date(encounter_id);

update temp_pathology t
set ordering_provider = provider_name_of_type(t.encounter_id , @ordering_provider,0);

update temp_pathology t
set request_coded_proc1 = value_coded_name(obs_id(t.encounter_id, 'PIH','10770',0),@locale);

update temp_pathology t
set request_coded_proc2 = value_coded_name(obs_id(t.encounter_id, 'PIH','10770',1),@locale);

update temp_pathology t
set request_coded_proc3 = value_coded_name(obs_id(t.encounter_id, 'PIH','10770',3),@locale);

update temp_pathology t
set request_non_coded_proc = obs_value_text(t.encounter_id, 'PIH','10772'); 

update temp_pathology t
set clinical_history  =  obs_value_text(t.encounter_id, 'PIH','10142'); 

update temp_pathology t
set specimen_accession_number = obs_value_text(t.encounter_id, 'PIH','10840'); 

update temp_pathology t
set post_op_diagnosis  = obs_from_group_id_value_coded_list(obs_id(t.encounter_id, 'PIH','10782',0), 'PIH','3064',@locale);

update temp_pathology t
set specimen_details_1 = obs_value_text(t.encounter_id, 'PIH','10775');  --  value_text(obs_id(t.encounter_id, 'PIH','10775',0));

update temp_pathology t
set specimen_details_2 = obs_value_text(t.encounter_id, 'PIH','10776');  --  value_text(obs_id(t.encounter_id, 'PIH','10775',0));

update temp_pathology t
set specimen_details_3 = obs_value_text(t.encounter_id, 'PIH','10777');  --  value_text(obs_id(t.encounter_id, 'PIH','10775',0));

update temp_pathology t
set specimen_details_4 = obs_value_text(t.encounter_id, 'PIH','10778');  --  value_text(obs_id(t.encounter_id, 'PIH','10775',0));

update temp_pathology t
set attending_surgeon  =  provider_name_of_type(t.encounter_id, @attending_surgeon, 0); 

update temp_pathology t
set resident  =  provider_name_of_type(t.encounter_id, @assisting_surgeon, 0); 

update temp_pathology t
set md_to_notify  = obs_value_text(t.encounter_id, 'PIH','10779'); 

update temp_pathology t
set clinician_telephone  = obs_value_text(t.encounter_id, 'PIH','6589'); 

update temp_pathology t
set urgent_review = obs_value_coded_list(t.encounter_id, 'PIH','7813',@locale);

update temp_pathology t
set suspected_cancer = obs_value_coded_list(t.encounter_id, 'PIH','14111',@locale);

update temp_pathology t
set immunohistochemistry_needed = obs_value_coded_list(t.encounter_id, 'PIH','14209',@locale);

update temp_pathology t
set immunohistochemistry_sent = obs_value_coded_list(t.encounter_id, 'PIH','14210',@locale);

update temp_pathology t
set results_date = obs_value_datetime(t.encounter_id, 'PIH','10783');

update temp_pathology t
set results_note = obs_value_text(t.encounter_id, 'PIH','7907');

update temp_pathology t
set file_uploaded = if(obs_id(t.encounter_id,'PIH','10785',0) is null,0,1 );

select 
order_id,
order_number ,
encounter_id,
patient_id,
zlemrid,
loc_registered,
patient_name,
unknown_patient,
gender,
age_at_enc,
department,
commune,
section,
locality,
street_landmark,
order_datetime,
ordering_provider,
request_coded_proc1,
request_coded_proc2,
request_coded_proc3,
request_non_coded_proc,
prepath_dx,
clinical_history,
specimen_accession_number,
post_op_diagnosis,
specimen_details_1,
specimen_details_2,
specimen_details_3,
specimen_details_4,
attending_surgeon,
resident,
md_to_notify,
clinician_telephone,
urgent_review,
suspected_cancer,
immunohistochemistry_needed,
immunohistochemistry_sent,
results_date,
results_note,
file_uploaded
from temp_pathology ;
