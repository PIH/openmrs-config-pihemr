drop temporary table if exists temp_backup_restore_dates;
create temporary table temp_backup_restore_dates
(datetime_type varchar(255),
datetime       datetime);

insert into temp_backup_restore_dates
select 'backup',global_property_value('percona_backup_date', null);

insert into temp_backup_restore_dates
select 'restore',global_property_value('percona_restore_date', null);

select
datetime_type,
datetime
from temp_backup_restore_dates;
