SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_users;

CREATE TEMPORARY TABLE temp_users (
    user_id             int,
    username            varchar(50),
    first_name          varchar(50),
    last_name           varchar(50),
    account_enabled     bit,
    created_date        datetime,
    created_by          varchar(50),
    provider_type       varchar(255),
    last_login_date     datetime,
    num_logins_recorded int
);

INSERT INTO temp_users(user_id, username, first_name, last_name, account_enabled, created_date, created_by, provider_type)
SELECT      u.user_id,
            username(u.user_id),
            person_given_name(u.person_id),
            person_family_name(u.person_id),
            if(u.retired, false, true),
            u.date_created,
            username(u.creator),
            (select group_concat(pp.name) from provider p inner join providermanagement_provider_role pp on p.provider_role_id = pp.provider_role_id where p.person_id = u.person_id)
FROM        users u
;

UPDATE temp_users u SET u.last_login_date = user_latest_login(u.user_id);
UPDATE temp_users u SET u.num_logins_recorded = user_num_logins(u.user_id);

ALTER TABLE temp_users DROP COLUMN user_id;

-- Select all out of table
SELECT * FROM temp_users;