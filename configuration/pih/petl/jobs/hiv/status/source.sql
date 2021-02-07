select program_id into @hiv_program from program where uuid = 'b1cb1fc1-5190-4f7a-af08-48870975dafc';
select name into @hivDispensingEncName from encounter_type where uuid = 'cc1720c9-3e4c-4fa8-a7ec-40eeaad1958c';

SET sql_safe_updates = 0;
SET @hiv_followup_encounter_type = ENCOUNTER_TYPE('HIV Followup Form');
SET @hiv_initial_encounter_type = ENCOUNTER_TYPE('HIV Intake Form');

drop temporary table if exists temp_hiv_transfer_encounters;
create temporary table temp_hiv_transfer_encounters
AS
select  person_id,
        obs_group_id,
        obs_id,
        e.encounter_id,
        date(encounter_datetime) encounter_date,
        obs_datetime,
        concept_id,
        value_coded,
        concept_name(concept_id, 'en'),
        concept_name(value_coded, 'en'),
        o.location_id,
        value_text
from obs o join encounter e on e.encounter_id = o.encounter_id and e.voided = 0 and o.voided = 0
and encounter_type in (@hiv_initial_encounter_type, @hiv_followup_encounter_type)
and obs_group_id in (select obs_id from obs where concept_id = concept_from_mapping('PIH', '13170') and voided = 0);

drop temporary table if exists temp_status;
create temporary table temp_status
(
status_id int(11) AUTO_INCREMENT,
patient_id int(11),
patient_program_id int(11),
location_id int(11),
outcome int(1),
status_concept_id int(11),
start_date datetime,
end_date datetime,
return_to_care int(1),
late_for_pickup int(1),
index_program_ascending int(11),
index_program_descending int(11),
index_patient_ascending int(11),
index_patient_descending int(11),
transfer_status varchar(255),
PRIMARY KEY (status_id)
);

 create index temp_status_patient_id on temp_status (patient_id);
 create index temp_status_start_date on temp_status (start_date);
 create index temp_status_index_program_ascending on temp_status (index_program_ascending);


-- load all enrollments into temp table
insert into temp_status (patient_id, patient_program_id, location_id, start_date)
select patient_id, patient_program_id, location_id, date_enrolled
from patient_program
where program_id = @hiv_program
and voided = 0;


-- load all status changes into temp table
insert into temp_status (patient_id, patient_program_id, status_concept_id, location_id, start_date)
select pp.patient_id, ps.patient_program_id, pws.concept_id, pp.location_id,ps.start_date
from patient_state ps
inner join patient_program pp on pp.patient_program_id = ps.patient_program_id and pp.program_id = @hiv_program
inner join program_workflow_state pws where pws.program_workflow_state_id = ps.state
and ps.voided = 0;


-- load all outcomes into temp table
insert into temp_status (patient_id, patient_program_id, status_concept_id, location_id, start_date, end_date, outcome)
select patient_id, patient_program_id, outcome_concept_id, location_id, date_completed, date_completed,1
from patient_program
where program_id = @hiv_program
and date_completed is not null
and voided = 0;

### program index ascending
-- The ascending/descending indexes are calculated ordering on the dispense date
-- new temp tables are used to build them and then joined into the main temp table.
-- index resets at each new patient program
drop temporary table if exists temp_status_index_asc;
CREATE TEMPORARY TABLE temp_status_index_asc
(
    SELECT
            patient_program_id,
            status_id,
            start_date,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_program_id, @r + 1,1) index_asc,
            status_id,
            start_date,
            patient_program_id,
            @u:= patient_program_id
      FROM temp_status,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_program_id asc, start_date asc, status_id asc
        ) index_program_ascending );

update temp_status t
inner join temp_status_index_asc tsia on tsia.status_id = t.status_id
set index_program_ascending = tsia.index_asc;

drop temporary table if exists temp_status_index_desc;
CREATE TEMPORARY TABLE temp_status_index_desc
(
    SELECT
            patient_program_id,
            status_id,
            start_date,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_program_id, @r + 1,1) index_desc,
            status_id,
            start_date,
            patient_program_id,
            @u:= patient_program_id
      FROM temp_status,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_program_id desc, start_date desc, status_id desc
        ) index_program_descending );

update temp_status t
inner join temp_status_index_desc tsid on tsid.status_id = t.status_id
set index_program_descending = tsid.index_desc;

### patient index ascending
-- The ascending/descending indexes are calculated ordering on the dispense date
-- new temp tables are used to build them and then joined into the main temp table.
-- index resets at each new patient
drop temporary table if exists temp_patient_index_asc;
CREATE TEMPORARY TABLE temp_patient_index_asc
(
    SELECT
            patient_id,
            status_id,
            status_concept_id,
            start_date,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            status_id,
            status_concept_id,
            start_date,
            patient_id,
            @u:= patient_id
      FROM temp_status,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id asc, start_date asc, status_id asc
        ) index_program_ascending );

update temp_status t
inner join temp_patient_index_asc tpia on tpia.status_id = t.status_id
set index_patient_ascending = tpia.index_asc;

drop temporary table if exists temp_patient_index_desc;
CREATE TEMPORARY TABLE temp_patient_index_desc
(
    SELECT
            patient_id,
            status_id,
            start_date,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            status_id,
            start_date,
            patient_id,
            @u:= patient_id
      FROM temp_status,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id asc, start_date desc, status_id desc
        ) index_program_descending );

update temp_status t
inner join temp_patient_index_desc tpid on tpid.status_id = t.status_id
set index_patient_descending = tpid.index_desc;

## end date
drop temporary table if exists dup_status;
CREATE TEMPORARY TABLE dup_status SELECT * FROM temp_status;

create index dup_status_patient_program_id on dup_status (patient_program_id);
create index dup_status_index_program_ascending on dup_status (index_program_ascending);

update temp_status t
left outer join dup_status d on d.patient_program_id = t.patient_program_id and d.index_program_ascending = t.index_program_ascending + 1
set t.end_date = d.start_date
where t.index_program_descending <> 1;

## transfer status
update temp_status t left join temp_hiv_transfer_encounters th on t.patient_id = th.person_id and th.concept_id = concept_from_mapping('PIH', 'Transfer out location')
and t.status_concept_id = concept_from_mapping('PIH', 'PATIENT TRANSFERRED OUT') and th.encounter_date between date(start_date) and date(end_date)
set t.transfer_status = concept_name(th.value_coded, 'en');

create index temp_patient_index_asc_patient_id on temp_patient_index_asc (patient_id);
create index temp_patient_index_asc_index on temp_patient_index_asc (index_patient_ascending);
create index temp_patient_index_asc_patient_id on temp_patient_index_asc (patient_id);

## return to care
-- on any rows that are not outcomes, if any of the previous rows are LTFU, then set to 1
update temp_status t
set t.return_to_care = 1
where exists 
   (select 1 from temp_patient_index_asc t2
   where t2.patient_id=t.patient_id
   and t2.index_asc < t.index_patient_ascending
   and t2.status_concept_id = concept_from_mapping('PIH','LOST TO FOLLOWUP'))
and t.outcome is null  
;

## late for pickup.  
-- If the next dispensing date (next appointment from latest dispensing encounter)
-- is >= 29 days late then set to 1
-- if there is no next dispensing date, set to 1 
update temp_status t
left outer join encounter e on e.encounter_id = latestEnc(t.patient_id, @hivDispensingEncName, null)
left outer join obs o on o.encounter_id = e.encounter_id and o.voided = 0 and o.concept_id = concept_from_mapping('PIH','5096')
set t.late_for_pickup = if(TIMESTAMPDIFF(DAY,ifnull(date(o.value_datetime),'1900-01-01'),current_date)>=29,1,null)
; 

### Final query
select 
status_id,
patient_id,
zlemr(patient_id) "zl_emr_id",
location_name(location_id) "patient_location",
transfer_status,
concept_name(status_concept_id, 'en') "status_outcome",
date(start_date),
date(end_date),
return_to_care,
late_for_pickup,
index_program_ascending,
index_program_descending,
index_patient_ascending,
index_patient_descending
from temp_status
order by patient_id,index_patient_ascending;
