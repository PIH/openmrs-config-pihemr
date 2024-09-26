SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_users;

CREATE TEMPORARY TABLE temp_users (
    user_id             int,
    username            varchar(50),
    first_name          varchar(50),
    last_name           varchar(50),
    email               varchar(500),
    account_enabled     bit,
    created_date        datetime,
    created_by          varchar(50),
    provider_type       varchar(255),
    last_login_date     datetime,
    num_logins_recorded int,
    mfa_status          varchar(50)
);

INSERT INTO temp_users(user_id, username, first_name, last_name, account_enabled, created_date, created_by, provider_type, email)
SELECT      u.user_id,
            username(u.user_id),
            person_given_name(u.person_id),
            person_family_name(u.person_id),
            if(u.retired, false, true),
            u.date_created,
            username(u.creator),
            (select group_concat(pp.name) from provider p inner join providermanagement_provider_role pp on p.provider_role_id = pp.provider_role_id where p.person_id = u.person_id),
            u.email
FROM        users u
;

UPDATE temp_users u SET u.mfa_status = user_property_value(u.user_id, 'authentication.secondaryType', 'disabled');
UPDATE temp_users u SET u.mfa_status = 'question' where u.mfa_status = 'secret';
UPDATE temp_users u SET u.mfa_status = 'authenticator' where u.mfa_status = 'totp';

call create_temp_aggregate_login_data();

UPDATE temp_users u
inner join temp_aggregate_login_data al on al.user_id = u.user_id
SET u.last_login_date = al.max_datetime,
	u.num_logins_recorded = al.counts;


ALTER TABLE temp_users DROP COLUMN user_id;

-- Select all out of table
SELECT * FROM temp_users;
