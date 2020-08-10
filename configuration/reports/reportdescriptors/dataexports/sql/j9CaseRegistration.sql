select program_workflow_state_id into @prenatalGroup from program_workflow_state where uuid = '41a2753c-8a14-11e8-9a94-a6cf71072f73';
select program_workflow_state_id into @pedsGroup from program_workflow_state where uuid = '2fa7008c-aa58-11e8-98d0-529269fb1459';
select program_id into @matHealthProgram from program where uuid = '41a2715e-8a14-11e8-9a94-a6cf71072f73';
select concept_id into @mothersGroup from concept where uuid = 'c1b2db38-8f72-4290-b6ad-99826734e37e';
select concept_id into @edd from concept where uuid = '3cee56a6-26fe-102b-80cb-0017a47871b2';
select concept_id into @add from concept where uuid = '5599AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
select relationship_type_id into @aParentToB from relationship_type  where uuid = '8d91a210-c2cc-11de-8d13-0010c6dffd0f' ;
select person_attribute_type_id into @tele from person_attribute_type pat where pat.uuid =  '14d4f066-15f5-102d-96e4-000c29c2a5d7';

drop TEMPORARY TABLE IF EXISTS temp_J9_patients;

create temporary table temp_J9_patients
(
    patient_id int(11),
    patient_uuid char(38),
    given_name varchar(50),
    family_name varchar(50),
    ZL_identifier varchar(50),
    Dossier_identifier varchar(50),
    J9_group text,
    J9_program varchar(50),
    telephone varchar(50),
    birthdate date,
    age int(3),
    estimated_delivery_date date,
    actual_delivery_date date,
    mama_dossier varchar(50),
    department varchar(255),
    commune varchar(255),
    section_communal varchar(255),
    locality varchar(255),
    street_landmark varchar(255),
    j9_enrollment_date datetime
)
;

-- this populates the temp table with the cohort of patients to be included in the report
-- The logic is, patients that:
-- * have ever been in the maternal health program
-- * has a state of prenatal group or pediatric group
-- * maximum of one row per patient.  So return the most recent enrollment if more than one
insert into temp_J9_patients (patient_id, patient_uuid, j9_enrollment_date, J9_program, birthdate, age)
Select p.patient_id, per.uuid, pp.date_enrolled, wsn.name, per.birthdate, TIMESTAMPDIFF(YEAR,per.birthdate, now()) "age"
from patient p
         inner join person per on per.person_id = p.patient_id and per.dead = 0
         inner join patient_program pp on pp.patient_id = p.patient_id and pp.program_id = @matHealthProgram and pp.voided = 0  and pp.date_completed is null
         inner join patient_state ps on ps.patient_program_id = pp.patient_program_id and ps.voided = 0 and ps.state in (@prenatalGroup,@pedsGroup)
-- J9 program name
         left outer join program_workflow_state pws ON pws.program_workflow_state_id = ps.state and pws.retired = 0
         left outer join concept_name wsn on wsn.concept_id = pws.concept_id and wsn.locale = 'en' and wsn.voided =0 and wsn.locale_preferred = 1
;

-- telephone number
update temp_J9_patients t
    left outer join person_attribute pa on pa.person_id = t.patient_id and pa.person_attribute_type_id = @tele
        and pa.voided = 0
set t.telephone = pa.value
;

-- patient address
update temp_J9_patients t
    left outer join current_name_address cna on cna.person_id = t.patient_id
set t.department = cna.department,
    t.commune = cna.commune,
    t.section_communal = cna.section_communal,
    t.locality = cna.locality,
    t.street_landmark = cna.street_landmark
;

update temp_J9_patients t
set t.ZL_identifier =  zlEMR(t.patient_id)
;

update temp_J9_patients t
set t.Dossier_identifier =  dosId(t.patient_id)
;

-- patient names
update temp_J9_patients t
    left outer join current_name_address cna on cna.person_id = t.patient_id
set t.given_name = cna.given_name,
    t.family_name = cna.family_name
;

-- J9 group (latest observation of entered J9 group, since program enrollment)
update temp_J9_patients t
set t.J9_group =  (select value_text from obs where obs_id = latestObs(t.patient_id, @mothersGroup, j9_enrollment_date))
;

-- estimated delivery date
update temp_J9_patients t
set t.estimated_delivery_date =  (select value_datetime from obs where obs_id = latestObs(t.patient_id, @edd, j9_enrollment_date))
;

-- Actual Delivery Date
update temp_J9_patients t
set t.actual_delivery_date =  (select value_datetime from obs where obs_id = latestObs(t.patient_id, @add, j9_enrollment_date))
;

-- Baby's mother: return dossier id of mother (parent who is female) if the patient is < 1 year
update temp_J9_patients t
    left outer join relationship rm on rm.person_b = t.patient_id and rm.voided = 0 and rm.relationship = @aParentToB
        and gender(rm.person_a) = 'F'
        and  TIMESTAMPDIFF(YEAR,t.birthdate, now()) < 1
-- mother's dossier id
set t.mama_dossier = dosId(rm.person_a)
;

select
    patient_id,
    patient_uuid,
    given_name,
    family_name,
    ZL_identifier,
    Dossier_identifier,
    J9_group,
    J9_program,
    telephone,
    birthdate,
    age,
    estimated_delivery_date,
    actual_delivery_date,
    mama_dossier,
    department,
    commune,
    section_communal,
    locality,
    street_landmark,
    j9_enrollment_date
from temp_J9_patients;
