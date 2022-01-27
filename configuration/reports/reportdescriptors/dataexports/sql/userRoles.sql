select      u.username as Username,
            person_given_name(u.person_id) as `First Name`,
            person_family_name(u.person_id) as `Last Name`,
            if(ur.role like 'Application Role: %', 'Application Role', if(ur.role like 'Privilege Level: %', 'Privilege Level', '')) as `Role Type`,
            if(ur.role like 'Application Role: %', substring_index(ur.role, 'Application Role: ', -1), if(ur.role like 'Privilege Level: %', substring_index(ur.role, 'Privilege Level: ', -1), ur.role)) as `Role Value`,
            if(u.retired, false, true) as `User Active`,
            u.date_created as `User Date Created`,
            u.date_changed as `User Last Updated`
from        user_role ur
inner join  users u on ur.user_id = u.user_id
order by    u.username
;
