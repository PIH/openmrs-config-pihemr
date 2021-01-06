select program_id into @hiv_program from program where uuid = 'b1cb1fc1-5190-4f7a-af08-48870975dafc';

drop temporary table if exists temp_status;
create temporary table temp_status
(
status_id int(11) AUTO_INCREMENT,
patient_id int(11),
patient_program_id int(11),
location_id int(11),
status_concept_id int(11),
start_date datetime,
end_date datetime,
index_ascending int(11),
index_descending int(11),
PRIMARY KEY (status_id)
);

 create index temp_status_patient_id on temp_status (patient_id);
 create index temp_status_start_date on temp_status (start_date);
 create index temp_status_index_ascending on temp_status (index_ascending);


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
insert into temp_status (patient_id, patient_program_id, status_concept_id, location_id, start_date, end_date)
select patient_id, patient_program_id, outcome_concept_id, location_id, date_completed, date_completed
from patient_program
where program_id = @hiv_program
and date_completed is not null
and voided = 0;


-- The ascending/descending indexes are calculated ordering on the dispense date
-- new temp tables are used to build them and then joined into the main temp table.
### index ascending
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
        ) index_ascending );

update temp_status t
inner join temp_status_index_asc tsia on tsia.status_id = t.status_id
set index_ascending = tsia.index_asc;

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
        ) index_descending );

update temp_status t
inner join temp_status_index_desc tsid on tsid.status_id = t.status_id
set index_descending = tsid.index_desc;

drop temporary table if exists dup_status;
CREATE TEMPORARY TABLE dup_status SELECT * FROM temp_status;

create index dup_status_patient_program_id on dup_status (patient_program_id);
create index dup_status_index_ascending on dup_status (index_ascending);

update temp_status t
left outer join dup_status d on d.patient_program_id = t.patient_program_id and d.index_ascending = t.index_ascending + 1
set t.end_date = d.start_date
where t.index_descending <> 1;

select 
status_id,
patient_id,
zlemr(patient_id) "zl_emr_id",
location_name(location_id) "patient_location",
concept_name(status_concept_id, 'en') "status_outcome",
date(start_date),
date(end_date),
index_ascending,
index_descending
from temp_status
order by patient_program_id, index_ascending;
