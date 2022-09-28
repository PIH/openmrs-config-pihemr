-- set @startDate = '2000-03-28';
-- set @endDate = '2022-07-01';


CALL initialize_global_metadata();
set @partition = '${partitionNum}';

select encounter_role_id into @ordering_provider from encounter_role where uuid = 'c458d78e-8374-4767-ad58-9f8fe276e01c';
select encounter_role_id into @assisting_surgeon from encounter_role where uuid = '6e630e03-5182-4cb3-9a82-a5b1a85c09a7';
select encounter_role_id into @attending_surgeon from encounter_role where uuid = '9b135b19-7ebe-4a51-aea2-69a53f9383af';

DROP TEMPORARY TABLE IF EXISTS temp_pathology;
CREATE TEMPORARY TABLE temp_pathology
(
patient_id					INT(11),
emr_id						VARCHAR(50),
age_at_enc					INT,
gender						VARCHAR(50),
order_id					INT(11),
order_number 				VARCHAR(50),
encounter_id				INT(11),
encounter_location			VARCHAR(255),
order_datetime				DATETIME,
order_entered_datetime		DATETIME,
order_user_entered			VARCHAR(100),
ordering_provider			VARCHAR(255),
attending_surgeon			VARCHAR(255),
resident					VARCHAR(255),
md_to_notify				TEXT,
clinician_telephone			TEXT,
prepath_dx					VARCHAR(255),
clinical_history			TEXT,
post_op_diagnosis			VARCHAR(255),	
specimen_details_1			TEXT,
specimen_details_2			TEXT,
specimen_details_3			TEXT,
specimen_details_4			TEXT,
specimen_details_5			TEXT,
specimen_details_6			TEXT,
specimen_details_7			TEXT,
specimen_details_8			TEXT,
urgent_review				BIT,
suspected_cancer			BIT,
immunohistochemistry_needed	BIT,
immunohistochemistry_sent	BIT,
immunohistochemistry_sent_date	DATETIME,
latest_processed_obs_id		INT(11),
process_date				DATETIME,
process_date_entered		DATETIME,	
process_user_entered		VARCHAR(50),
specimen_accession_number	TEXT,
specimen_to_boston			BIT,
specimen_to_boston_date		DATETIME,
specimen_to_pop_obs_groupid	INT(11),
specimen_to_pap				BIT,
specimen_to_pap_date		DATETIME,
specimen_returned_pap_date	DATETIME,
latest_results_obs_id		INT(11),
results_date				DATETIME,
result_date_entered			DATETIME,
result_user_entered			VARCHAR(255),
results_note				TEXT,
file_uploaded				BIT,
cancer_confirmed			BIT,
post_result_dx_obs_group_id	INT(11),
post_result_diagnosis		VARCHAR(255)
);

insert into temp_pathology (order_id,encounter_id, order_number, patient_id, prepath_dx)
select o.order_id , o.encounter_id, o.order_number, patient_id, concept_name(order_reason,@locale)  from orders o
where o.order_type_id = @pathologyTestOrder
AND ((date(o.date_activated) >= @startDate) or  @startDate is null)
AND ((date(o.date_activated) <= @endDate) or @endDate is null)
;

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.comments,o.date_created , o.creator  
from obs o
inner join temp_pathology t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_oi on temp_obs(obs_id);
create index temp_obs_ci1 on temp_obs(encounter_id, concept_id);
create index temp_obs_ci2 on temp_obs(obs_group_id, concept_id);
update temp_pathology t
set t.emr_id = zlemr(patient_id);

update temp_pathology t
set gender = gender(t.patient_id);

update temp_pathology t
set age_at_enc = age_at_enc(t.patient_id, t.encounter_id);

update temp_pathology t
set encounter_location = encounter_location_name(t.encounter_id); 

update temp_pathology t
set order_entered_datetime = encounter_date_created(t.encounter_id);

update temp_pathology t
set order_user_entered = encounter_creator_name(t.encounter_id);

update temp_pathology t
set order_datetime  = encounter_date(encounter_id);

update temp_pathology t
set ordering_provider = provider_name_of_type(t.encounter_id , @ordering_provider,0);

update temp_pathology t
set clinical_history  =  obs_value_text_from_temp(t.encounter_id, 'PIH','10142'); 

update temp_pathology t
set post_op_diagnosis  = obs_from_group_id_value_coded_list_from_temp(obs_id(t.encounter_id, 'PIH','10782',0), 'PIH','3064',@locale);

update temp_pathology t
set specimen_details_1 = obs_value_text_from_temp(t.encounter_id, 'PIH','10775'); 

update temp_pathology t
set specimen_details_2 = obs_value_text_from_temp(t.encounter_id, 'PIH','10776'); 

update temp_pathology t
set specimen_details_3 = obs_value_text_from_temp(t.encounter_id, 'PIH','10777'); 

update temp_pathology t
set specimen_details_4 = obs_value_text_from_temp(t.encounter_id, 'PIH','10778');  

update temp_pathology t
set specimen_details_5 = obs_value_text_from_temp(t.encounter_id, 'PIH','14317');  

update temp_pathology t
set specimen_details_6 = obs_value_text_from_temp(t.encounter_id, 'PIH','14318'); 

update temp_pathology t
set specimen_details_7 = obs_value_text_from_temp(t.encounter_id, 'PIH','14319'); 

update temp_pathology t
set specimen_details_8 = obs_value_text_from_temp(t.encounter_id, 'PIH','14320'); 

update temp_pathology t
set attending_surgeon  =  provider_name_of_type(t.encounter_id, @attending_surgeon, 0); 

update temp_pathology t
set resident  =  provider_name_of_type(t.encounter_id, @assisting_surgeon, 0); 

update temp_pathology t
set md_to_notify  = obs_value_text_from_temp(t.encounter_id, 'PIH','10779'); 

update temp_pathology t
set clinician_telephone  = obs_value_text_from_temp(t.encounter_id, 'PIH','6589'); 

update temp_pathology t
set urgent_review = value_coded_as_boolean(obs_id_from_temp(t.encounter_id, 'PIH','7813',0));

update temp_pathology t
set suspected_cancer = value_coded_as_boolean(obs_id_from_temp(t.encounter_id, 'PIH','14111',0));

update temp_pathology t
set immunohistochemistry_needed = value_coded_as_boolean(obs_id_from_temp(t.encounter_id, 'PIH','14209',0));

update temp_pathology t
set immunohistochemistry_sent = value_coded_as_boolean(obs_id_from_temp(t.encounter_id, 'PIH','7818',0));

update temp_pathology t
set immunohistochemistry_sent_date = obs_value_datetime_from_temp(t.encounter_id, 'PIH','14239');
									 

update temp_pathology t
set process_date = obs_value_datetime_from_temp(t.encounter_id, 'PIH','10485');

set @process_date_id = concept_from_mapping('PIH','10485');
set @accession_number_id = concept_from_mapping('PIH','10840');
set @specimen_sent_id = concept_from_mapping('PIH','7818');
set @specimen_sent_date_id = concept_from_mapping('PIH','14239');
set @specimen_returned_date_id = concept_from_mapping('PIH','6110');

update temp_pathology t
set t.process_date_entered = 
	(select max(o.date_created) from temp_obs o 
	where o.encounter_id = t.encounter_id
	and o.voided= 0
	and o.concept_id in (@process_date_id , @accession_number_id,  @specimen_sent_id,  @specimen_sent_date_id, @specimen_returned_date_id) );

update temp_pathology t
set t.latest_processed_obs_id = 
	(select obs_id from temp_obs o 
	where o.encounter_id = t.encounter_id
	and o.voided= 0
	and o.concept_id in (@process_date_id , @accession_number_id,  @specimen_sent_id,  @specimen_sent_date_id, @specimen_returned_date_id)
	and o.date_created =t.process_date_entered
limit 1);

update temp_pathology t
inner join temp_obs o on o.obs_id = t.latest_processed_obs_id
inner join users u on o.creator  = u.user_id 
inner join person_name pn on pn.person_id = u.person_id 
set process_user_entered = concat(given_name, ' ', family_name);

update temp_pathology t
set specimen_accession_number = obs_value_text_from_temp(t.encounter_id, 'PIH','10840'); 

update temp_pathology t
inner join temp_obs o on o.encounter_id = t.encounter_id
	and o.voided = 0
	and o.concept_id = concept_from_mapping ('PIH','7818')
set t.specimen_to_boston = 
	CASE o.value_coded
		WHEN concept_from_mapping('PIH','YES') then 1
		WHEN concept_from_mapping('PIH','NO') then 0
	END  ;

update temp_pathology t
inner join temp_obs o on o.encounter_id = t.encounter_id
	and o.voided = 0
	and o.obs_group_id is null -- the "sent to Boston" data is not in a construct, like "sent to PAP" data is 
	and o.concept_id = concept_from_mapping ('PIH','14239')
set t.specimen_to_boston_date = o.value_datetime  ;

update temp_pathology t
set specimen_to_pop_obs_groupid = obs_id_from_temp(t.encounter_id, 'PIH','14315',0);

update temp_pathology t
inner join temp_obs o on o.obs_group_id = t.specimen_to_pop_obs_groupid
	and o.concept_id = concept_from_mapping('PIH','7817')
set specimen_to_pap =
	CASE o.value_coded
		WHEN concept_from_mapping('PIH','YES') then 1
		WHEN concept_from_mapping('PIH','NO') then 0
	END
;

update temp_pathology t
set specimen_to_pap_date = obs_from_group_id_value_datetime_from_temp(t.specimen_to_pop_obs_groupid,'PIH','14239');

update temp_pathology t
set specimen_returned_pap_date = obs_from_group_id_value_datetime_from_temp(t.specimen_to_pop_obs_groupid,'PIH','6110');

set @results_note_id = concept_from_mapping('PIH','7907');
set @results_date_id = concept_from_mapping('PIH','10783');
set @post_result_dx_id = concept_from_mapping('PIH','14314'); 
set @file_uploaded_id = concept_from_mapping('PIH','10785');
set @confirmed_cancer_id = concept_from_mapping('PIH','14313');

update temp_pathology t
set t.result_date_entered = 
	(select max(o.date_created) from temp_obs o 
	where o.encounter_id = t.encounter_id
	and o.voided= 0
	and o.concept_id in (@results_note_id , @results_date_id,  @post_result_dx_id,  @file_uploaded_id, @confirmed_cancer_id) );

update temp_pathology t
set t.latest_results_obs_id = 
	(select obs_id from temp_obs o 
	where o.encounter_id = t.encounter_id
	and o.voided= 0
	and o.concept_id in (@results_note_id , @results_date_id,  @post_result_dx_id,  @file_uploaded_id, @confirmed_cancer_id)
	and o.date_created =t.result_date_entered
	limit 1);

update temp_pathology t
inner join temp_obs o on o.obs_id = t.latest_results_obs_id
inner join users u on o.creator  = u.user_id 
inner join person_name pn on pn.person_id = u.person_id 
set result_user_entered = concat(given_name, ' ', family_name);

update temp_pathology t
set results_date = obs_value_datetime_from_temp(t.encounter_id, 'PIH','10783');

update temp_pathology t
inner join temp_obs o on o.encounter_id = t.encounter_id
	and o.voided = 0
	and o.concept_id = concept_from_mapping ('PIH','7907')
set t.results_note = o.value_text ;

update temp_pathology t
set file_uploaded = if(obs_id_from_temp(t.encounter_id,'PIH','10785',0) is null,0,1 );

update temp_pathology t
set cancer_confirmed = value_coded_as_boolean(obs_id_from_temp(t.encounter_id, 'PIH','14313',0));

update temp_pathology t
set post_result_dx_obs_group_id = obs_id_from_temp(t.encounter_id,'PIH','14314',0);

update temp_pathology t
set post_result_diagnosis = obs_from_group_id_value_coded_list_from_temp(t.post_result_dx_obs_group_id, 'PIH','3064',@locale);

select 
emr_id,
age_at_enc,
gender,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',order_id),order_id) "order_id",
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',order_number),order_number) "order_number",
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',encounter_id),encounter_id) "encounter_id",
encounter_location,
order_datetime,
order_entered_datetime,
order_user_entered,
ordering_provider,
attending_surgeon,
resident,
md_to_notify,
clinician_telephone,
prepath_dx,
clinical_history,
post_op_diagnosis,
specimen_details_1,
specimen_details_2,
specimen_details_3,
specimen_details_4,
specimen_details_5,
specimen_details_6,
specimen_details_7,
specimen_details_8,
urgent_review,
suspected_cancer,
immunohistochemistry_needed,
immunohistochemistry_sent,
immunohistochemistry_sent_date,
process_date,
process_date_entered,
process_user_entered,
specimen_accession_number,
specimen_to_boston,
specimen_to_boston_date,
specimen_to_pap,
specimen_to_pap_date,
specimen_returned_pap_date,
results_date,
result_date_entered,
result_user_entered,
results_note,
file_uploaded,
cancer_confirmed,
post_result_diagnosis
from temp_pathology;
