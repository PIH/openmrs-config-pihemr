-- set @startDate = '2022-06-05';
-- set @endDate = '2022-06-05';

CALL initialize_global_metadata();
SET @locale = GLOBAL_PROPERTY_VALUE('default_locale', 'en');
select encounter_type_id into @obgynnote from encounter_type where uuid = 'd83e98fd-dc7b-420f-aa3f-36f648b4483d'; 

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
    General_Exam_Comments text,
    Mental_Exam           varchar(255),
    Mental_Exam_Other     varchar(255),
    Mental_Exam_Comments  text,
    Skin_Exam             varchar(255),
    Skin_Exam_Other       varchar(255),
    Skin_Exam_Comments    text,
    HEENT_Exam            varchar(255),
    HEENT_Exam_Other      varchar(255), 
    HEENT_Exam_Comments   text,
    Cardiac_Exam          varchar(255),
    Cardiac_Exam_Other    varchar(255),
    Cardiac_Exam_Comments text,
    Chest_Exam            varchar(255),
    Chest_Exam_Other      varchar(255),
    Chest_Exam_Comments   text,
    Abdominal_Exam        varchar(255),
    Abdominal_Exam_Other  varchar(255),
    Abdominal_Exam_Comments text,
    Urogenital_Exam       varchar(255),
    Urogenital_Exam_Other varchar(255),
    Urogenital_Exam_Comments text,
    Gynecology_exam       varchar(255),
    Gynecology_exam_Other varchar(255),
    Gynecology_exam_Comments text,
    VIA					varchar(255),
    cryotherapy_cervix	BIT,
    pap_test_performed	BIT,
    Musculoskeletal_Exam  varchar(255),
    Musculoskeletal_Exam_Other varchar(255),
    Pitting_edema		varchar(255),			
    Musculoskeletal_Exam_Comments text,
    Fundal_height         double,
    Uterine_Contraction   varchar(255),
    UC_Comment            varchar(255),
    Fetal_presentation_1    varchar(255),
    Fetal_position_1        varchar(255),
    Fetal_heart_rate_1      double,
    Fetal_presentation_2    varchar(255),
    Fetal_position_2        varchar(255),
    Fetal_heart_rate_2      double,
    Fetal_presentation_3    varchar(255),
    Fetal_position_3        varchar(255),
    Fetal_heart_rate_3      double,
    Fetal_presentation_4    varchar(255),
    Fetal_position_4        varchar(255),
    Fetal_heart_rate_4      double,
    Gross_Motor_Exam      varchar(255),
    Gross_Motor_Comments  text,
    Fine_Motor_Exam       varchar(255),
    Fine_Motor_Comments   text,
    Language_Exam         varchar(255),
    Language_Comments     text,
    Social_Skills_Exam    varchar(255),
    Social_Skills_Comments text,
    Physical_Exam_Comment text
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
where e.encounter_type in (@obgynnote)
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
update temp_exam set VIA = obs_value_coded_list(encounter_id,'PIH','9759',@locale);
update temp_exam te
        JOIN obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', '10484')
        AND value_coded = CONCEPT_FROM_MAPPING('PIH', '9764')
        AND o.voided = 0 
SET 
    cryotherapy_cervix = 1;
update temp_exam te
        JOIN obs o ON te.encounter_id = o.encounter_id
        AND concept_id = CONCEPT_FROM_MAPPING('PIH', '11319')
        AND value_coded = CONCEPT_FROM_MAPPING('PIH', '1267')
        AND o.voided = 0 
SET 
    pap_test_performed = 1;

update temp_exam set Musculoskeletal_Exam = obs_value_coded_list(encounter_id,'PIH','MUSCULOSKELETAL EXAM FINDINGS',@locale);
update temp_exam set Musculoskeletal_Exam_other = obs_comments(encounter_id,'PIH','MUSCULOSKELETAL EXAM FINDINGS','PIH','OTHER');
update temp_exam set Pitting_edema = obs_value_coded_list(encounter_id,'CIEL','130166',@locale);
update temp_exam set Musculoskeletal_Exam_comments = obs_value_text(encounter_id,'CIEL','163048');

update temp_exam set Fundal_height = obs_value_numeric(encounter_id,'CIEL','1439');
update temp_exam set Uterine_Contraction = obs_value_coded_list(encounter_id,'CIEL','163750',@locale);
update temp_exam set UC_Comment = obs_value_text(encounter_id,'CIEL','160968');

update temp_exam set Fetal_presentation_1 = obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', '13592', 0),'CIEL','160090',@locale);
update temp_exam set Fetal_position_1 = obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', '13592', 0),'CIEL','163749',@locale);
update temp_exam set Fetal_heart_rate_1 = obs_from_group_id_value_numeric(obs_id(encounter_id, 'PIH', '13592', 0),'CIEL','1440');

update temp_exam set Fetal_presentation_2 = obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', '13592', 1),'CIEL','160090',@locale);
update temp_exam set Fetal_position_2 = obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', '13592', 1),'CIEL','163749',@locale);
update temp_exam set Fetal_heart_rate_2 = obs_from_group_id_value_numeric(obs_id(encounter_id, 'PIH', '13592', 1),'CIEL','1440');

update temp_exam set Fetal_presentation_3 = obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', '13592', 2),'CIEL','160090',@locale);
update temp_exam set Fetal_position_3 = obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', '13592', 2),'CIEL','163749',@locale);
update temp_exam set Fetal_heart_rate_3 = obs_from_group_id_value_numeric(obs_id(encounter_id, 'PIH', '13592', 2),'CIEL','1440');

update temp_exam set Fetal_presentation_4 = obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', '13592', 3),'CIEL','160090',@locale);
update temp_exam set Fetal_position_4 = obs_from_group_id_value_coded_list(obs_id(encounter_id, 'PIH', '13592', 3),'CIEL','163749',@locale);
update temp_exam set Fetal_heart_rate_4 = obs_from_group_id_value_numeric(obs_id(encounter_id, 'PIH', '13592', 3),'CIEL','1440');

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
