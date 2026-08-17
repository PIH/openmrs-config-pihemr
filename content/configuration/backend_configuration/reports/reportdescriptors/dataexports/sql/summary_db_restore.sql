## This table will be used by implementers (and analysts)
## to have an understanding of how old the extracted/sourced/restored data is.
## This table is useful for data monitoring and especially useful on a production instance. 
## Due to intermittent internet connectivity
## at various sites, it is important to have a visibity of the latest data restored without having to 
## log into the petl server for a site and check the logs. 

SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_last_created_datapoints_sourced;

CREATE TEMPORARY TABLE temp_last_created_datapoints_sourced (
backup_datetime                                 DATETIME,
restore_datetime                                DATETIME,
last_sourced_patient_datapoint_created_on       DATETIME,
last_sourced_encounter_datapoint_created_on     DATETIME,
last_sourced_obs_datapoint_created_on           DATETIME
);

INSERT INTO temp_last_created_datapoints_sourced(last_sourced_patient_datapoint_created_on)
SELECT MAX(date_created) FROM patient WHERE voided = 0;

UPDATE temp_last_created_datapoints_sourced SET last_sourced_encounter_datapoint_created_on =  (SELECT MAX(date_created) FROM encounter WHERE voided = 0);

UPDATE temp_last_created_datapoints_sourced SET last_sourced_obs_datapoint_created_on = (SELECT MAX(date_created) FROM obs WHERE voided = 0);

update temp_last_created_datapoints_sourced
set backup_datetime = global_property_value('percona_backup_date', null);

update temp_last_created_datapoints_sourced
set restore_datetime = global_property_value('percona_restore_date', null);

SELECT * FROM temp_last_created_datapoints_sourced;
