-- set @startDate='2015-12-01';
-- set @endDate='2025-02-05';

SELECT encounter_type_id INTO @mhEncounterTypeId FROM encounter_type et WHERE et.uuid ='a8584ab8-cc2a-11e5-9956-625662870761';
set @answerExists = concept_name(concept_from_mapping('PIH','YES'), global_property_value('default_locale', 'en'));

SET @partition = '${partitionNum}';


DROP TEMPORARY TABLE IF EXISTS temp_mh_encounters;
CREATE TEMPORARY TABLE temp_mh_encounters
(
emr_id                            varchar(50),  
dossier_id                        varchar(50),  
encounter_id                      int(11),      
encounter_datetime                datetime,       
patient_id                        int(11),      
visit_id                          int(11),      
creator                           int(11),      
user_entered                      text,         
location_id                       int(11),      
encounter_location                varchar(255), 
entered_datetime                  datetime,     
provider                          text,         
loc_registered                    varchar(255),   
unknown_patient                   varchar(50),    
gender                            varchar(50),    
department                        varchar(255),   
commune                           varchar(255),   
section                           varchar(255),   
locality                          varchar(255),   
street_landmark                   varchar(255),   
section_communale_CDC_ID          varchar(11),    
age_at_enc                        double,         
referred_from_community_by        varchar(255), 
other_referring_person            text,         
type_of_referral_role             VARCHAR(255), 
other_referring_role_type         text,         
referred_from_other_service       VARCHAR(255), 
referred_from_other_service_other text,         
visit_type                        varchar(255), 
consultation_method               varchar(255), 
chief_complaint                   text,         
new_patient                       tinyint,      
chw_for_mental_health             tinyint,      
patient_relapse                   tinyint,      
hospitalized_since_last_visit     tinyint,      
reason_for_hospitalization        text,         
adherence_to_appointment_day      varchar(255), 
hospitalized_at_time_of_visit     tinyint,      
zldsi_score                       int,          
ces_dc_score                      int,          
psc_35_score                      int,          
pcl_5_score                       int,            
cgi_s_score                       int,          
cgi_i_score                       int,          
cgi_e_score                       int,          
whodas_score                      int,          
days_with_difficulties            int,          
days_without_usual_activity       int,          
days_with_less_activity           int           ,  
aims                              varchar(20),  
seizure_frequency                 int,          
appearance_normal                 tinyint,      
speech_normal                     tinyint,      
cognitive_function_normal         tinyint,      
mood_disorder                     tinyint,      
muscle_tone_normal                tinyint,      
traumatic_event                   tinyint,      
introspection_normal              tinyint,      
thought_content                   varchar(255), 
danger_to_self                    tinyint,      
anxiety_and_phobia                tinyint,      
psychosocial_evaluation           tinyint,      
judgement                         varchar(255), 
danger_to_others                  tinyint,      
affect                            tinyint,      
additional_comments               text,         
thought_process                   varchar(255), 
past_suicidal_ideation            tinyint,      
current_suicidal_ideation         tinyint,      
past_suicidal_attempts            tinyint,      
current_suicidal_attempts         tinyint,      
last_suicide_attempt_date         date,         
suicidal_screen_completed         VARCHAR(50),  
suicidal_screening_result         VARCHAR(255), 
discussed_patient_with_supervisor tinyint,      
safety_plan_completed             tinyint,      
hospitalize_due_to_suicide_risk   tinyint,   
psychological_intervention        text,
other_psychological_intervention  text,
medication_comments               text,
pregnant                          tinyint,      
last_menstruation_date            DATE,         
estimated_delivery_date           DATE,         
type_of_provider                  TEXT,         
referred_to_roles                 TEXT,         
disposition                       VARCHAR(255), 
disposition_comment               TEXT,         
return_date                       DATE,         
index_asc                         int,          
index_desc                        int           
);


INSERT INTO temp_mh_encounters (patient_id, encounter_id, visit_id, encounter_datetime, entered_datetime, creator, location_id)
SELECT  patient_id,
		encounter_id,
		visit_id,
		encounter_datetime,
		date_created,
		creator,
		location_id
FROM encounter e
where e.voided = 0
and e.encounter_type = @mhEncounterTypeId
and (DATE(encounter_datetime) >=  date(@startDate) or @startDate is null)
and (DATE(encounter_datetime) <=  date(@endDate) or @endDate is null);

update temp_mh_encounters set user_entered= person_name_of_user(creator);
update temp_mh_encounters set encounter_location = location_name(location_id);
update temp_mh_encounters set provider = provider(encounter_id);
update temp_mh_encounters set age_at_enc = age_at_enc(patient_id, encounter_id);

-- patient-level information  ------------------------------

DROP TEMPORARY TABLE IF EXISTS temp_mh_patient;
CREATE TEMPORARY TABLE temp_mh_patient
(
patient_id               int(11),      
dossier_id               varchar(50),  
emr_id                   varchar(50),  
loc_registered           varchar(255), 
unknown_patient          varchar(50),  
gender                   varchar(50),  
department               varchar(255), 
commune                  varchar(255), 
section                  varchar(255),  
locality                 varchar(255), 
street_landmark          varchar(255), 
section_communale_CDC_ID varchar(11)    
    );
   
insert into temp_mh_patient(patient_id)
select distinct patient_id from temp_mh_encounters;

create index temp_mh_patient_pi on temp_mh_patient(patient_id);

update temp_mh_patient set emr_id = zlemr(patient_id);
update temp_mh_patient set dossier_id = dosid(patient_id);
update temp_mh_patient set loc_registered = loc_registered(patient_id);
update temp_mh_patient set unknown_patient = unknown_patient(patient_id);
update temp_mh_patient set gender = gender(patient_id);

update temp_mh_patient t
inner join person_address a on a.person_address_id =
	(select a2.person_address_id from person_address a2
	where a2.person_id = t.patient_id
	order by preferred desc, date_created desc limit 1)
set 	t.department = a.state_province,
	t.commune = a.city_village,
	t.section = a.address3,
	t.locality = a.address1,
	t.street_landmark = a.address2;

update temp_mh_patient set section_communale_CDC_ID = cdc_id(patient_id);

update temp_mh_encounters t
inner join temp_mh_patient p on t.patient_id = p.patient_id
set t.dossier_id = p.dossier_id,
	t.emr_id = p.emr_id,
	t.loc_registered = p.loc_registered,
	t.unknown_patient = p.unknown_patient,
	t.gender = p.gender,
	t.department = p.department,
	t.commune = p.commune,
	t.section = p.section,
	t.locality = p.locality,
	t.street_landmark = p.street_landmark,
	t.section_communale_CDC_ID = p.section_communale_CDC_ID;

-- set up temporary obs table

DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.comments,o.date_created 
from obs o
inner join temp_mh_encounters t on t.encounter_id = o.encounter_id
where o.voided = 0;

create index temp_obs_ei on temp_obs(encounter_id);
create index temp_obs_c1 on temp_obs(encounter_id, concept_id);

-- referral section ------------------------------------------------

update temp_mh_encounters set referred_from_community_by = obs_value_coded_list_from_temp(encounter_id, 'PIH','10647', @locale);
update temp_mh_encounters set other_referring_person = obs_value_text_from_temp(encounter_id, 'PIH','6421');
update temp_mh_encounters set type_of_referral_role = obs_value_coded_list_from_temp(encounter_id, 'PIH','10635', @locale);
update temp_mh_encounters set other_referring_role_type = obs_value_text_from_temp(encounter_id, 'PIH','14415');
update temp_mh_encounters set referred_from_other_service = obs_value_coded_list_from_temp(encounter_id, 'PIH','7454', @locale);
update temp_mh_encounters set referred_from_other_service_other = obs_value_text_from_temp(encounter_id, 'PIH','15027');
update temp_mh_encounters set visit_type = obs_value_coded_list_from_temp(encounter_id, 'PIH','13236', @locale);
update temp_mh_encounters set consultation_method = obs_value_coded_list_from_temp(encounter_id, 'PIH','3589', @locale);
update temp_mh_encounters set chief_complaint = obs_value_text_from_temp(encounter_id, 'PIH','10137');
update temp_mh_encounters set new_patient =value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14986',0));
update temp_mh_encounters set chw_for_mental_health =value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','14991',0));
update temp_mh_encounters set patient_relapse =value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','13724',0));
update temp_mh_encounters set patient_relapse =value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','13724',0));

update temp_mh_encounters set hospitalized_since_last_visit = value_coded_as_boolean(obs_id_from_temp(encounter_id, 'PIH','1715',0));

update temp_mh_encounters set reason_for_hospitalization = obs_value_text_from_temp(encounter_id, 'PIH','11065');
update temp_mh_encounters set adherence_to_appointment_day = obs_value_coded_list_from_temp(encounter_id, 'PIH','10552', @locale);
update temp_mh_encounters set hospitalized_at_time_of_visit = 	if(obs_single_value_coded_from_temp(encounter_id,'PIH','3289','PIH','1429')= @answerExists,1,0);

-- Scores section
update temp_mh_encounters set zldsi_score=obs_value_numeric_from_temp(encounter_id,'PIH', '10584'); 
update temp_mh_encounters set ces_dc_score=obs_value_numeric_from_temp(encounter_id,'PIH', '10590'); 
update temp_mh_encounters set pcl_5_score=obs_value_numeric_from_temp(encounter_id,'PIH', '12428'); 
update temp_mh_encounters set psc_35_score=obs_value_numeric_from_temp(encounter_id,'PIH', '12422');
update temp_mh_encounters set cgi_s_score=obs_value_numeric_from_temp(encounter_id,'PIH', '10586'); 
update temp_mh_encounters set cgi_i_score=obs_value_numeric_from_temp(encounter_id,'PIH', '10587'); 
update temp_mh_encounters set cgi_e_score=obs_value_numeric_from_temp(encounter_id,'PIH', '10585'); 
update temp_mh_encounters set whodas_score=obs_value_numeric_from_temp(encounter_id,'PIH', '10589'); 
update temp_mh_encounters set days_with_difficulties=obs_value_numeric_from_temp(encounter_id,'PIH', '10650');
update temp_mh_encounters set days_without_usual_activity=obs_value_numeric_from_temp(encounter_id,'PIH', '10651'); 
update temp_mh_encounters set days_with_less_activity=obs_value_numeric_from_temp(encounter_id,'PIH', '10652'); 
update temp_mh_encounters set aims=obs_value_coded_list_from_temp(encounter_id,'PIH','10591',@locale);
update temp_mh_encounters set seizure_frequency=obs_value_numeric_from_temp(encounter_id,'PIH','6797');

-- status section ----------------------------------------------

set @normal = concept_name(concept_from_mapping('PIH','1115'),@locale);
set @abnormal = concept_name(concept_from_mapping('PIH','1116'),@locale);
set @yes = concept_name(concept_from_mapping('PIH','1065'),@locale);
set @no = concept_name(concept_from_mapping('PIH','1066'),@locale);


update temp_mh_encounters set appearance_normal = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','14126',@locale) = @normal then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','14126',@locale) = @abnormal then 0
	END;
	
update temp_mh_encounters set speech_normal = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','14293',@locale) = @yes then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','14293',@locale) = @no then 0
	END;

update temp_mh_encounters set cognitive_function_normal = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','7331',@locale) = @yes then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','7331',@locale) = @no then 0
	END;

update temp_mh_encounters set mood_disorder = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','9527',@locale) = @yes then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','9527',@locale) = @no then 0
	END;

update temp_mh_encounters set muscle_tone_normal = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','15034',@locale) = @normal then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','15034',@locale) = @abnormal then 0
	END;

update temp_mh_encounters set traumatic_event = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','12362',@locale) = @yes then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','12362',@locale) = @no then 0
	END;

update temp_mh_encounters set introspection_normal = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','13089',@locale) = @normal then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','13089',@locale) = @abnormal then 0
	END;

update temp_mh_encounters set thought_process = 
	obs_value_coded_list_from_temp(encounter_id,'PIH','14157',@locale);

update temp_mh_encounters set danger_to_self = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','10633',@locale) = @yes then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','10633',@locale) = @no then 0
	END;

update temp_mh_encounters set anxiety_and_phobia = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','2719',@locale) = @yes then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','2719',@locale) = @no then 0
	END;

update temp_mh_encounters set psychosocial_evaluation = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','13175',@locale) = @yes then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','13175',@locale) = @no then 0
	END;

update temp_mh_encounters set judgement = 
	obs_value_coded_list_from_temp(encounter_id,'PIH','14110',@locale);

update temp_mh_encounters set danger_to_others = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','15106',@locale) = @yes then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','15106',@locale) = @no then 0
	END;

update temp_mh_encounters set affect = 
	CASE
		when obs_value_coded_list_from_temp(encounter_id,'PIH','14155',@locale) = @normal then 1
		when obs_value_coded_list_from_temp(encounter_id,'PIH','13089',@locale) = @abnormal then 0
	END;

update temp_mh_encounters set additional_comments = 
	 obs_value_text_from_temp(encounter_id, 'PIH','10472');

update temp_mh_encounters set thought_process = 
	obs_value_coded_list_from_temp(encounter_id,'PIH','14156',@locale);

-- suicidal evaluation ---------------------------------------------

update temp_mh_encounters set past_suicidal_ideation = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','10140','PIH','10633')= @answerExists,1,null);
update temp_mh_encounters set past_suicidal_attempts = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','10140','PIH','7514')= @answerExists,1,null);
update temp_mh_encounters set current_suicidal_ideation = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','10594','PIH','10633')= @answerExists,1,null);
update temp_mh_encounters set current_suicidal_attempts = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','10594','PIH','7514')= @answerExists,1,null);
update temp_mh_encounters set last_suicide_attempt_date = 
	date(obs_value_datetime_from_temp(encounter_id,'PIH','12420'));
update temp_mh_encounters set suicidal_screen_completed = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','10648','PIH','1065')= @answerExists,1,null);
update temp_mh_encounters set suicidal_screening_result = 
	obs_value_coded_list_from_temp(encounter_id,'PIH','12376',@locale);
update temp_mh_encounters set discussed_patient_with_supervisor = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','12421','PIH','12429')= @answerExists,1,0);
update temp_mh_encounters set safety_plan_completed = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','10636','PIH','10646')= @answerExists,1,0);
update temp_mh_encounters set hospitalize_due_to_suicide_risk = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','12421','PIH','12426')= @answerExists,1,0);

-- Psychological interventions -----------------------------

update temp_mh_encounters set psychological_intervention = 
	obs_value_coded_list_from_temp(encounter_id,'PIH','10636',@locale);

update temp_mh_encounters set other_psychological_intervention = 
	 obs_comments_from_temp(encounter_id, 'PIH','10636','PIH','5622');

-- Medication Section ---------------------------------------------
-- actual medications included in another export/table

update temp_mh_encounters set medication_comments = 
	 obs_value_text_from_temp(encounter_id, 'PIH','10637');

-- Plan Section --------------------------------------------

update temp_mh_encounters set pregnant = 
	if(obs_single_value_coded_from_temp(encounter_id,'PIH','5272','PIH','1065')= @answerExists,1,null);

update temp_mh_encounters set last_menstruation_date = 
	date(obs_value_datetime_from_temp(encounter_id,'PIH','968'));
update temp_mh_encounters set estimated_delivery_date = 
	date(obs_value_datetime_from_temp(encounter_id,'PIH','5596'));

update temp_mh_encounters set type_of_provider = 
	obs_value_coded_list_from_temp(encounter_id,'PIH','10649',@locale);

update temp_mh_encounters set referred_to_roles = 
	obs_value_coded_list_from_temp(encounter_id,'PIH','12553',@locale);

update temp_mh_encounters set disposition = 
	obs_value_coded_list_from_temp(encounter_id,'PIH','8620',@locale);

update temp_mh_encounters set disposition_comment = 
	obs_value_text_from_temp(encounter_id,'PIH','2881');

update temp_mh_encounters set return_date = 
	date(obs_value_datetime_from_temp(encounter_id,'PIH','5096'));
    
-- indexes -----------------------------------------

-- The ascending/descending indexes are calculated ordering on the encounter date
-- new temp tables are used to build them and then joined into the main temp table.
### index ascending
drop temporary table if exists temp_visit_index_asc;
CREATE TEMPORARY TABLE temp_visit_index_asc
(
    SELECT
            patient_id,
            encounter_datetime,
            encounter_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            encounter_datetime,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_mh_encounters,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_datetime ASC, encounter_id ASC
        ) index_ascending );
CREATE INDEX tvia_e ON temp_visit_index_asc(encounter_id);
update temp_mh_encounters t
inner join temp_visit_index_asc tvia on tvia.encounter_id = t.encounter_id
set t.index_asc = tvia.index_asc;

drop temporary table if exists temp_visit_index_desc;
CREATE TEMPORARY TABLE temp_visit_index_desc
(
    SELECT
            patient_id,
            encounter_datetime,
            encounter_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            encounter_datetime,
            encounter_id,
            patient_id,
            @u:= patient_id
      FROM temp_mh_encounters,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_datetime DESC, encounter_id DESC
        ) index_descending );
       
 CREATE INDEX tvid_e ON temp_visit_index_desc(encounter_id);      
update temp_mh_encounters t
inner join temp_visit_index_desc tvid on tvid.encounter_id = t.encounter_id
set t.index_desc = tvid.index_desc;

-- final output ------------------------------------

select 
emr_id,
dossier_id,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',encounter_id),encounter_id) "encounter_id",
encounter_datetime,
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',patient_id),patient_id) "patient_id",
if(@partition REGEXP '^[0-9]+$' = 1,concat(@partition,'-',visit_id),visit_id) "visit_id",
user_entered,
encounter_location,
entered_datetime,
provider,
loc_registered,
unknown_patient,
gender,
department,
commune,
section,
locality,
street_landmark,
section_communale_CDC_ID,
age_at_enc,
referred_from_community_by,
other_referring_person,
type_of_referral_role,
other_referring_role_type,
referred_from_other_service,
referred_from_other_service_other,
visit_type,
consultation_method,
chief_complaint,
new_patient,
chw_for_mental_health,
patient_relapse,
hospitalized_since_last_visit,
reason_for_hospitalization,
adherence_to_appointment_day,
hospitalized_at_time_of_visit,
zldsi_score,
ces_dc_score,
psc_35_score,
pcl_5_score,
cgi_s_score,
cgi_i_score,
cgi_e_score,
whodas_score,
days_with_difficulties,
days_without_usual_activity,
days_with_less_activity,
aims,
seizure_frequency,
appearance_normal,
speech_normal,
cognitive_function_normal,
mood_disorder,
muscle_tone_normal,
traumatic_event,
introspection_normal,
thought_content,
danger_to_self,
anxiety_and_phobia,
psychosocial_evaluation,
judgement,
danger_to_others,
affect,
additional_comments,
thought_process,
past_suicidal_ideation,
current_suicidal_ideation,
past_suicidal_attempts,
current_suicidal_attempts,
last_suicide_attempt_date,
suicidal_screen_completed,
suicidal_screening_result,
discussed_patient_with_supervisor,
safety_plan_completed,
hospitalize_due_to_suicide_risk,
pregnant,
psychological_intervention,
other_psychological_intervention,
medication_comments,
last_menstruation_date,
estimated_delivery_date,
type_of_provider,
referred_to_roles,
disposition,
disposition_comment,
return_date,
index_asc,
index_desc
from temp_mh_encounters;
