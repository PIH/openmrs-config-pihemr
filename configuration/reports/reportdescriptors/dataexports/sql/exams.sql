-- set @startDate = '2021-03-18';
-- set @endDate = '2021-03-20';

CALL initialize_global_metadata();
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');

DROP TEMPORARY TABLE IF EXISTS temp_exam;
CREATE TEMPORARY TABLE temp_exam
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
    General_Exam          varchar(255),
    General_Exam_Other    varchar(255),
    General_Exam_Comments varchar(1000),
    Mental_Exam           varchar(255),
    Mental_Exam_Other     varchar(255),
    Mental_Exam_Comments  varchar(1000),
    Skin_Exam             varchar(255),
    Skin_Exam_Other       varchar(255),
    Skin_Exam_Comments    varchar(1000),
    HEENT_Exam            varchar(255),
    HEENT_Exam_Other      varchar(255), 
    HEENT_Exam_Comments   varchar(1000),
    Cardiac_Exam          varchar(255),
    Cardiac_Exam_Other    varchar(255),
    Cardiac_Exam_Comments varchar(1000),
    Chest_Exam            varchar(255),
    Chest_Exam_Other      varchar(255),
    Chest_Exam_Comments   varchar(1000),
    Abdominal_Exam        varchar(255),
    Abdominal_Exam_Other  varchar(255),
    Abdominal_Exam_Comments varchar(1000),
    Urogenital_Exam       varchar(255),
    Urogenital_Exam_Other varchar(255),
    Urogenital_Exam_Comments varchar(1000),
    Gynecology_exam       varchar(255),
    Gynecology_exam_Other varchar(255),
    Gynecology_exam_Comments text,
    Musculoskeletal_Exam  varchar(255),
    Musculoskeletal_Exam_Other varchar(255),
    Musculoskeletal_Exam_Comments varchar(1000),
    Fundal_height         double,
    Fetal_presentation    varchar(255),
    Fetal_position        varchar(255),
    Fetal_heart_rate      double,
    Uterine_Contraction   varchar(255),
    UC_Comment            varchar(255),
    Gross_Motor_Exam      varchar(255),
    Gross_Motor_Comments  varchar(255),
    Fine_Motor_Exam       varchar(255),
    Fine_Motor_Comments   varchar(255),
    Language_Exam         varchar(255),
    Language_Comments     varchar(255),
    Social_Skills_Exam    varchar(255),
    Social_Skills_Comments varchar(255),
    Physical_Exam_Comment varchar(255)
);

insert into temp_exam (
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

update temp_exam set zlemrid = zlemr(patient_id);
update temp_exam set dossierid = dosid(patient_id);
update temp_exam set loc_registered = loc_registered(patient_id);
update temp_exam set encounter_location = encounter_location_name(encounter_id);
update temp_exam set provider = provider(encounter_id);

update temp_exam set general_exam = obs_value_coded_list(encounter_id,'PIH','GENERAL EXAM FINDINGS',@locale);
update temp_exam set general_exam_other = obs_comments(encounter_id,'PIH','GENERAL EXAM FINDINGS','PIH','OTHER');
update temp_exam set general_exam_comments = obs_value_text(encounter_id,'CIEL','163042');

update temp_exam set mental_exam = obs_value_coded_list(encounter_id,'CIEL','163043',@locale);
update temp_exam set mental_exam_other = obs_comments(encounter_id,'CIEL','163043','PIH','OTHER');
update temp_exam set mental_exam_comments = obs_value_text(encounter_id,'CIEL','163044');

update temp_exam set skin_exam = obs_value_coded_list(encounter_id,'PIH','SKIN EXAM FINDINGS',@locale);
update temp_exam set skin_exam_other = obs_comments(encounter_id,'PIH','SKIN EXAM FINDINGS','PIH','OTHER');
update temp_exam set skin_exam_comments = obs_value_text(encounter_id,'PIH','SKIN EXAM COMMENT');

update temp_exam set HEENT_exam = obs_value_coded_list(encounter_id,'PIH','HEENT EXAM FINDINGS',@locale);
update temp_exam set HEENT_exam_other = obs_comments(encounter_id,'PIH','HEENT EXAM FINDINGS','PIH','OTHER');
update temp_exam set HEENT_exam_comments = obs_value_text(encounter_id,'CIEL','163045');

update temp_exam set cardiac_exam = obs_value_coded_list(encounter_id,'PIH','CARDIAC EXAM FINDINGS',@locale);
update temp_exam set cardiac_exam_other = obs_comments(encounter_id,'PIH','CARDIAC EXAM FINDINGS','PIH','OTHER');
update temp_exam set cardiac_exam_comments = obs_value_text(encounter_id,'CIEL','163046');

update temp_exam set chest_exam = obs_value_coded_list(encounter_id,'PIH','CHEST EXAM FINDINGS',@locale);
update temp_exam set chest_exam_other = obs_comments(encounter_id,'PIH','CHEST EXAM FINDINGS','PIH','OTHER');
update temp_exam set chest_exam_comments = obs_value_text(encounter_id,'CIEL','160689');

update temp_exam set abdominal_exam = obs_value_coded_list(encounter_id,'PIH','ABDOMINAL EXAM FINDINGS',@locale);
update temp_exam set abdominal_exam_other = obs_comments(encounter_id,'PIH','ABDOMINAL EXAM FINDINGS','PIH','OTHER');
update temp_exam set abdominal_exam_comments = obs_value_text(encounter_id,'CIEL','160947');

update temp_exam set urogenital_exam = obs_value_coded_list(encounter_id,'PIH','13228',@locale);
update temp_exam set urogenital_exam_other = obs_comments(encounter_id,'PIH','13228','PIH','OTHER');
update temp_exam set urogenital_exam_comments = obs_value_text(encounter_id,'CIEL','166363');

update temp_exam set Gynecology_exam  = obs_value_coded_list(encounter_id,'PIH','13229',@locale);
update temp_exam set Gynecology_exam_other = obs_comments(encounter_id,'PIH','13229','PIH','OTHER');
update temp_exam set Gynecology_exam_comments = obs_value_text(encounter_id,'CIEL','166364');

update temp_exam set Musculoskeletal_Exam = obs_value_coded_list(encounter_id,'PIH','MUSCULOSKELETAL EXAM FINDINGS',@locale);
update temp_exam set Musculoskeletal_Exam_other = obs_comments(encounter_id,'PIH','MUSCULOSKELETAL EXAM FINDINGS','PIH','OTHER');
update temp_exam set Musculoskeletal_Exam_comments = obs_value_text(encounter_id,'CIEL','163048');

update temp_exam set Fundal_height = obs_value_numeric(encounter_id,'CIEL','1439');
update temp_exam set Fetal_presentation = obs_value_coded_list(encounter_id,'CIEL','160090',@locale);
update temp_exam set Fetal_position = obs_value_coded_list(encounter_id,'CIEL','163749',@locale);
update temp_exam set Fetal_heart_rate = obs_value_numeric(encounter_id,'CIEL','1440');
update temp_exam set Uterine_Contraction = obs_value_coded_list(encounter_id,'CIEL','163750',@locale);
update temp_exam set UC_Comment = obs_value_text(encounter_id,'CIEL','160968');

update temp_exam set gross_motor_exam = obs_value_coded_list(encounter_id,'PIH','GROSS MOTOR SKILLS EVALUATION',@locale);
update temp_exam set gross_motor_comments = obs_value_text(encounter_id,'PIH','Gross Motor Skills Evaluation (text)');

update temp_exam set fine_motor_exam = obs_value_coded_list(encounter_id,'PIH','FINE MOTOR SKILLS EVALUATION',@locale);
update temp_exam set fine_motor_comments = obs_value_text(encounter_id,'PIH','Fine Motor Skills Evaluation (text)');

update temp_exam set language_exam = obs_value_coded_list(encounter_id,'PIH','LANGUAGE DEVELOPMENT EVALUATION',@locale);
update temp_exam set language_comments = obs_value_text(encounter_id,'PIH','Language Development Evaluation (text)');

update temp_exam set social_skills_exam = obs_value_coded_list(encounter_id,'PIH','SOCIAL SKILLS EVALUATION',@locale);
update temp_exam set social_skills_comments = obs_value_text(encounter_id,'PIH','Social Skills Evaluation (text)');

update temp_exam set Physical_Exam_Comment = obs_value_text(encounter_id,'PIH','PHYSICAL SYSTEM COMMENT');

-- select final output
select * from temp_exam;
