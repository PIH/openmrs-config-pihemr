select encounter_type_id into @hiv_dispensing from encounter_type et where uuid = 'cc1720c9-3e4c-4fa8-a7ec-40eeaad1958c';
select name into @hiv_dispensing_name from encounter_type et where uuid = 'cc1720c9-3e4c-4fa8-a7ec-40eeaad1958c';

DROP TEMPORARY TABLE IF EXISTS temp_lost;
CREATE TEMPORARY TABLE temp_lost
(
	patient_id					int(11),
	ZL_EMR_ID					varchar(50),
	HIVEMR_V1					varchar(50),
	latest_dispensing_encounter_id int(11),
	latest_dispensing_date		datetime,
	next_dispensing_date	datetime,
	num_days_late_for_dispensing	int(11)
	);

insert into temp_lost (patient_id)
select person_id  
from person p
where p.dead = 0
and EXISTS 
	(select 1 from encounter e
	where e.patient_id = p.person_id 
	and e.voided = 0
	and e.encounter_type = @hiv_dispensing)
;

update temp_lost t
set latest_dispensing_encounter_id = latestEnc(t.patient_id,@hiv_dispensing_name,null)
;

update temp_lost t
set next_dispensing_date = obs_value_datetime(t.latest_dispensing_encounter_id, 'CIEL','5096');

update temp_lost t set ZL_EMR_ID = ZLEMR(t.patient_id);

update temp_lost t set HIVEMR_V1 = patient_identifier(t.patient_id,'139766e8-15f5-102d-96e4-000c29c2a5d7');

update temp_lost t
inner join encounter e on e.encounter_id = t.latest_dispensing_encounter_id 
set t.latest_dispensing_date = e.encounter_datetime ;

update temp_lost 
set num_days_late_for_dispensing = DATEDIFF(CURRENT_DATE(),next_dispensing_date)
where next_dispensing_date < CURRENT_DATE() 
;

select 
	patient_id,
	ZL_EMR_ID,
	HIVEMR_V1,
	latest_dispensing_date,
	next_dispensing_date,
	num_days_late_for_dispensing
from temp_lost;	
