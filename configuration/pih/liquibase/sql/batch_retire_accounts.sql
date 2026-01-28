/* This script could retire accounts based on 3 different possible criteria:
 * 
 * If you would like to retire accounts that have not logged in since a certain number of months ago,
 * set @last_logged_in_months to that numnber e.g. SET @last_logged_in_months = 12;
 * otherwise set it to NULL e.g. SET @last_logged_in_months = NULL;
 * 
 * If you would like to retire accounts that have not logged in since a certain date,
 * set @last_logged_in_cutoff_date to that date e.g. SET @last_logged_in_cutoff_date = '2025-01-01';
 * otherwise set it to NULL e.g. SET @last_logged_in_cutoff_date = NULL;
 * 
 * If you would like to retire accounts that have never logged in and were created before a certain date,
 * set @never_logged_in_cutoff_date to that date e.g. SET @never_logged_in_cutoff_date = '2025-01-01';
 * otherwise set it to NULL e.g. SET @never_logged_in_cutoff_date = NULL;
 */


SET @never_logged_in_cutoff_date = '2025-01-01'; -- NULL
SET @last_logged_in_cutoff_date = NULL; -- '2025-01-01';
SET @last_logged_in_months = NULL; -- 12; 

drop temporary table if exists temp_users_to_retire;
create temporary table temp_users_to_retire
(user_id int(11));

-- users not logged in since a certain number of months ago
insert into temp_users_to_retire (user_id)
(select user_id from users u
where @last_logged_in_months is not null
and u.retired  = 0 
and not exists 
	(select 1 from authentication_event_log l
	 where l.user_id = u.user_id 
	 and event_type = 'LOGIN_SUCCEEDED'
	 and event_datetime > date_sub(now(), interval @last_logged_in_months month)));

-- users not logged in since a certain date
insert into temp_users_to_retire (user_id)
(select user_id from users u
where @last_logged_in_cutoff_date is not null
and u.retired  = 0 
and not exists 
	(select 1 from authentication_event_log l
	 where l.user_id = u.user_id 
	 and event_type = 'LOGIN_SUCCEEDED'
	 and event_datetime > @last_logged_in_cutoff_date));

-- users never logged in, created before a certain date
insert into temp_users_to_retire (user_id)
(select user_id from users u
where @never_logged_in_cutoff_date is not null
and date_created < @never_logged_in_cutoff_date
and u.retired  = 0 
and not exists 
	(select 1 from authentication_event_log l
	 where l.user_id = u.user_id 
	 and event_type = 'LOGIN_SUCCEEDED'));

-- remove exceptions
delete t
from temp_users_to_retire t
inner join users u on u.user_id = t.user_id 
where u.username in 
('admin',
'daemon',
'ccIntegrationUser',
'ball',
'ddesimone',
'fanderson',
'mgoodrich',
'mseaton',
'cho',
'cioan',
'jplouidor',
'wadson',
'wsaintlouis'
);

update users u
inner join temp_users_to_retire t on t.user_id = u.user_id 
set retired = 1,
	retired_by = 1,
	date_retired = now(),
	retire_reason = 'retired by script due to inactivity (HAI-1112)';
