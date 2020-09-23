SELECT encounter_type_id into @HIV_dispensing from encounter_type where uuid = 'cc1720c9-3e4c-4fa8-a7ec-40eeaad1958c';

drop temporary table if exists temp_HIV_dispensing;
create temporary table temp_HIV_dispensing
(
patient_id int(11),
encounter_id int(11),
dispense_date datetime,
encounter_location_id  int(11),
dispense_site  varchar(255),
age_at_dispense_date int,
-- entry_date datetime,
-- entered_by varchar(100),
dac char(1),
dispense_date_ascending int,
dispense_date_descending int,
dispensed_to  varchar(100),
dispensed_accompagnateur text,
current_art_treatment_line  varchar(255),
current_art_line_start_date datetime,
max_other_line datetime,
months_dispensed int,
is_current_mmd char(1),
next_dispense_date datetime,
arv_1_med varchar(255),
arv_1_med_short_name varchar(255),
arv_1_quantity int,
arv_2_med varchar(255),
arv_2_med_short_name varchar(255),
arv_2_quantity int,
tms_1_med varchar(255),
tms_1_med_short_name varchar(255),
tms_1_quantity int,
regimen_change char(1),
days_late_to_pickup int,
regimen_match char(1)
 );
 
 insert into temp_HIV_dispensing (patient_id, encounter_id, dispense_date, encounter_location_id)
 select patient_id, encounter_id,encounter_datetime,location_id from encounter
 where encounter_type = @HIV_dispensing and voided = 0 
 ;
 
 update temp_HIV_dispensing
 set dispense_site = encounter_location_name (encounter_id);
 
update temp_HIV_dispensing
set age_at_dispense_date = age_at_enc(patient_id, encounter_id)
;

-- removed from DW! 
-- update temp_HIV_dispensing
-- set entered_by = provider(encounter_id);

update temp_HIV_dispensing
set dac = CASE when obs_single_value_coded(encounter_id, 'PIH', 3671,'PIH',9361)='Yes' then 'Y' else 'N' end;



update temp_HIV_dispensing 
set dispense_date_ascending = encounter_index_asc(encounter_id,'HIV drug dispensing',null,null);

update temp_HIV_dispensing 
set dispense_date_descending = encounter_index_desc(encounter_id,'HIV drug dispensing',null,null);

update temp_HIV_dispensing 
set dispensed_to = obs_value_coded_list(encounter_id,'PIH',12071,'en');

update temp_HIV_dispensing 
set dispensed_accompagnateur = obs_value_text(encounter_id,'CIEL',164141);

update temp_HIV_dispensing 
set current_art_treatment_line = obs_value_coded_list(encounter_id,'CIEL',164432,'en');

update temp_HIV_dispensing 
set next_dispense_date = obs_value_datetime(encounter_id,'CIEL',5096);

update temp_HIV_dispensing 
set months_dispensed = obs_value_numeric(encounter_id,'PIH',3102);

update temp_HIV_dispensing
set is_current_mmd = if(months_dispensed >= 3, 'Y','N');

drop temporary table if exists dup_HIV_dispensing;
CREATE TEMPORARY TABLE dup_HIV_dispensing SELECT * FROM temp_HIV_dispensing;

drop temporary table if exists temp_dispensing_line_start;
CREATE TEMPORARY TABLE temp_dispensing_line_start
SELECT
            @ts:= IF(@u = patient_id and @tl = current_art_treatment_line ,@ts,@ts:=dispense_date) treatment_start_date,
            dispense_date,
            encounter_id,
            patient_id,
            current_art_treatment_line,
            @u:= patient_id,
            @tl:=current_art_treatment_line
      FROM temp_HIV_dispensing,
                    (SELECT @ts:= '1900-01-01') AS ts,
                    (SELECT @u:= 0) AS u,
                    (SELECT @tl:='1900-01-01') as tl
            ORDER BY patient_id, dispense_date ASC, encounter_id ASC;

update temp_HIV_dispensing t
inner join temp_dispensing_line_start ts on ts.encounter_id = t.encounter_id
set t.current_art_line_start_date = ts.treatment_start_date;
 
-- ARV#1 med and quantity
update temp_HIV_dispensing 
set arv_1_med_short_name = obs_from_group_id_value_coded_list(obs_group_id_of_coded_answer(encounter_id,'PIH',3013),'CIEL','1282','en');

update temp_HIV_dispensing 
set arv_1_med = obs_from_group_id_value_drug(obs_group_id_of_coded_answer(encounter_id,'PIH',3013),'CIEL','1282');

update temp_HIV_dispensing 
set arv_1_quantity = obs_from_group_id_value_numeric(obs_group_id_of_coded_answer(encounter_id,'PIH',3013),'CIEL','1443');

-- ARV#2 med and quantity
update temp_HIV_dispensing 
set arv_2_med_short_name = obs_from_group_id_value_coded_list(obs_group_id_of_coded_answer(encounter_id,'PIH',2848),'CIEL','1282','en');

update temp_HIV_dispensing 
set arv_2_med = obs_from_group_id_value_drug(obs_group_id_of_coded_answer(encounter_id,'PIH',2848),'CIEL','1282');

update temp_HIV_dispensing 
set arv_2_quantity = obs_from_group_id_value_numeric(obs_group_id_of_coded_answer(encounter_id,'PIH',2848),'CIEL','1443');

-- tms med and quantity
update temp_HIV_dispensing 
set tms_1_med_short_name = obs_from_group_id_value_coded_list(obs_group_id_of_coded_answer(encounter_id,'PIH',3120),'CIEL','1282','en');

update temp_HIV_dispensing 
set tms_1_med = obs_from_group_id_value_drug(obs_group_id_of_coded_answer(encounter_id,'PIH',3120),'CIEL','1282');

update temp_HIV_dispensing 
set tms_1_quantity = obs_from_group_id_value_numeric(obs_group_id_of_coded_answer(encounter_id,'PIH',3120),'CIEL','1443');


update temp_HIV_dispensing t
left outer join dup_HIV_dispensing d on d.patient_id=t.patient_id and d.dispense_date_ascending = 1  
set t.regimen_change = if(d.arv_1_med_short_name = t.arv_1_med_short_name,0,1)  -- need to change this to FULL NAME when drugs are captured?
where t.dispense_date_descending = 1
;

update temp_HIV_dispensing t
left outer join dup_HIV_dispensing d on d.patient_id=t.patient_id and d.dispense_date_descending = 2
set t.days_late_to_pickup = if(t.dispense_date>d.next_dispense_date,datediff(t.dispense_date,d.next_dispense_date),0)
where t.dispense_date_descending = 1;

Select 
t.patient_id,
t.encounter_id,
t.dispense_date,
t.dispense_site,
t.age_at_dispense_date,
t.dac,
t.dispensed_to,
t.dispensed_accompagnateur,
t.current_art_treatment_line,
t.current_art_line_start_date,
t.months_dispensed,
t.is_current_mmd,
t.next_dispense_date,
t.arv_1_med_short_name,
t.arv_1_med,
t.arv_1_quantity,
t.arv_2_med_short_name,
t.arv_2_med,
t.arv_2_quantity,
t.tms_1_med_short_name,
t.tms_1_med,
t.tms_1_quantity,
t.regimen_change,
t.days_late_to_pickup,
t.regimen_match,
dispense_date_ascending,
dispense_date_descending
from temp_HIV_dispensing t 
order by patient_id, dispense_date asc, encounter_id asc;
