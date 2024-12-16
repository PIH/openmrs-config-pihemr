SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_user_logins;

CREATE TEMPORARY TABLE temp_user_logins (
    login_id char(36),
    username varchar(50),
    date_logged_in datetime,
    date_logged_out datetime,
    date_expired datetime,
    active_duration_minutes int
);

-- Right now, we are only interested in successful logins.
-- Once we introduce Multi-Factor authentication, this may or may not change for this table
INSERT INTO temp_user_logins(login_id, username, date_logged_in)
SELECT  login_id, username, event_datetime
FROM    authentication_event_log
WHERE   event_type = 'LOGIN_SUCCEEDED'
;

create index temp_user_loginx_login_idx on temp_user_logins(login_id);

-- Update date_expired
UPDATE temp_user_logins s inner join authentication_event_log l on s.login_id = l.login_id
    SET s.date_expired = l.event_datetime
WHERE l.event_type = 'LOGIN_EXPIRED'
;

-- Update date_logged_out
UPDATE temp_user_logins s inner join authentication_event_log l on s.login_id = l.login_id
    SET s.date_logged_out = l.event_datetime
WHERE l.event_type = 'LOGOUT_SUCCEEDED'
;

-- Calculate active_duration_minutes

-- If we have date_logged_in and date_logged_out, we use those
UPDATE temp_user_logins s
SET active_duration_minutes = timestampdiff(MINUTE, date_logged_in, date_logged_out)
WHERE date_logged_out is not null and date_logged_in is not null
;

-- If not, we use date_logged_in until 30 minutes prior to session expiry, which is inferred as last activity
UPDATE temp_user_logins s
SET active_duration_minutes = (timestampdiff(MINUTE, date_logged_in, date_expired) - 30)
WHERE active_duration_minutes is null and date_expired is not null and date_logged_in is not null
;

-- If the computed duration above is less than zero, do not adjust for session timeout (likely server restart)
UPDATE temp_user_logins s
SET active_duration_minutes = timestampdiff(MINUTE, date_logged_in, date_expired)
WHERE active_duration_minutes < 0
;

-- Select all out of table
SELECT * FROM temp_user_logins;