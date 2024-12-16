SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_user_roles;

CREATE TEMPORARY TABLE temp_user_roles (
    user_id             int,
    username            varchar(50),
    first_name          varchar(50),
    last_name           varchar(50),
    role_type           varchar(50),
    role_value          varchar(255),
    account_enabled     bit,
    created_date        datetime,
    created_by          varchar(50),
    last_login_date     datetime,
    num_logins_recorded int
);

INSERT INTO temp_user_roles(user_id, role_type, role_value)
SELECT      ur.user_id, 'Application Role', substring_index(ur.role, 'Application Role: ', -1)
FROM        user_role ur
WHERE       ur.role like 'Application Role: %'
;

INSERT INTO temp_user_roles(user_id, role_type, role_value)
SELECT      ur.user_id, 'Privilege Level', substring_index(ur.role, 'Privilege Level: ', -1)
FROM        user_role ur
WHERE       ur.role like 'Privilege Level: %'
;

INSERT INTO temp_user_roles(user_id, role_type, role_value)
SELECT      ur.user_id, 'Privilege Level', ur.role
FROM        user_role ur
WHERE       ur.role not like 'Application Role: %' and ur.role not like 'Privilege Level: %'
;

INSERT INTO temp_user_roles(user_id, role_type, role_value)
SELECT      u.user_id, 'Provider Type', pp.name
FROM        providermanagement_provider_role pp
INNER JOIN  provider p on pp.provider_role_id = p.provider_role_id
INNER JOIN  users u on u.person_id = p.person_id
;

UPDATE temp_user_roles ur INNER JOIN users u on ur.user_id = u.user_id
SET
    ur.username = username(u.user_id),
    ur.first_name = person_given_name(u.person_id),
    ur.last_name = person_family_name(u.person_id),
    ur.account_enabled = if(u.retired, false, true),
    ur.created_date = u.date_created,
    ur.created_by = username(u.creator)
;

UPDATE temp_user_roles ur SET ur.last_login_date = user_latest_login(ur.user_id);
UPDATE temp_user_roles ur SET ur.num_logins_recorded = user_num_logins(ur.user_id);

ALTER TABLE temp_user_roles DROP COLUMN user_id;

-- Select all out of table
SELECT * FROM temp_user_roles;