select      u.username as 'Username',
            person_given_name(u.person_id) as 'First name',
            person_family_name(u.person_id) as 'Last name',
            (select group_concat(role) from user_role where user_id = u.user_id) as 'Roles',
            (select group_concat(pp.name) from provider p inner join providermanagement_provider_role pp on p.provider_role_id = pp.provider_role_id where p.person_id = u.person_id) as 'Provider Type',
            if(u.retired, 0, 1) as 'Enabled',
            u.date_created as 'Date created'
from        users u
;
