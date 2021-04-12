SELECT program_id INTO @hiv_program FROM program WHERE uuid = 'b1cb1fc1-5190-4f7a-af08-48870975dafc';
SELECT name INTO @hivDispensingEncName FROM encounter_type WHERE uuid = 'cc1720c9-3e4c-4fa8-a7ec-40eeaad1958c';

SET sql_safe_updates = 0;
SET @hiv_initial_encounter_type = ENCOUNTER_TYPE('HIV Intake');

DROP TEMPORARY TABLE IF EXISTS temp_status;
CREATE TEMPORARY TABLE temp_status
(
status_id INT(11) AUTO_INCREMENT,
patient_id INT(11),
patient_program_id INT(11),
location_id INT(11),
outcome INT(1),
status_concept_id INT(11),
start_date DATETIME,
end_date DATETIME,
return_to_care INT(1),
currently_late_for_pickup INT(1),
index_program_ascending INT(11),
index_program_descending INT(11),
index_patient_ascending INT(11),
index_patient_descending INT(11),
transfer_site VARCHAR(255),
transfer_external_sitename VARCHAR(255),
transfer_internal_sitename VARCHAR(255),
latest_encounter_id INT,
PRIMARY KEY (status_id)
);

 CREATE INDEX temp_status_patient_id ON temp_status (patient_id);
 CREATE INDEX temp_status_start_date ON temp_status (start_date);
 CREATE INDEX temp_status_index_program_ascending ON temp_status (index_program_ascending);


-- load all enrollments into temp table
INSERT INTO temp_status (patient_id, patient_program_id, location_id, start_date)
SELECT patient_id, patient_program_id, location_id, date_enrolled
FROM patient_program
WHERE program_id = @hiv_program
AND voided = 0;


-- load all status changes into temp table
INSERT INTO temp_status (patient_id, patient_program_id, status_concept_id, location_id, start_date)
SELECT pp.patient_id, ps.patient_program_id, pws.concept_id, pp.location_id,ps.start_date
FROM patient_state ps
INNER JOIN patient_program pp ON pp.patient_program_id = ps.patient_program_id AND pp.program_id = @hiv_program
INNER JOIN program_workflow_state pws WHERE pws.program_workflow_state_id = ps.state
AND ps.voided = 0;

-- load all outcomes into temp table
INSERT INTO temp_status (patient_id, patient_program_id, status_concept_id, location_id, start_date, end_date, outcome)
SELECT patient_id, patient_program_id, outcome_concept_id, location_id, date_completed, date_completed,1
FROM patient_program
WHERE program_id = @hiv_program
AND date_completed IS NOT NULL
AND voided = 0;

### program index ascending
-- The ascending/descending indexes are calculated ordering on the dispense date
-- new temp tables are used to build them and then joined into the main temp table.
-- index resets at each new patient program
DROP TEMPORARY TABLE IF EXISTS temp_status_index_asc;
CREATE TEMPORARY TABLE temp_status_index_asc
(
    SELECT
            patient_program_id,
            status_id,
            start_date,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_program_id, @r + 1,1) index_asc,
            status_id,
            start_date,
            patient_program_id,
            @u:= patient_program_id
      FROM temp_status,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_program_id ASC, start_date ASC, status_id ASC
        ) index_program_ascending );

UPDATE temp_status t
INNER JOIN temp_status_index_asc tsia ON tsia.status_id = t.status_id
SET index_program_ascending = tsia.index_asc;

DROP TEMPORARY TABLE IF EXISTS temp_status_index_desc;
CREATE TEMPORARY TABLE temp_status_index_desc
(
    SELECT
            patient_program_id,
            status_id,
            start_date,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_program_id, @r + 1,1) index_desc,
            status_id,
            start_date,
            patient_program_id,
            @u:= patient_program_id
      FROM temp_status,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_program_id DESC, start_date DESC, status_id DESC
        ) index_program_descending );

UPDATE temp_status t
INNER JOIN temp_status_index_desc tsid ON tsid.status_id = t.status_id
SET index_program_descending = tsid.index_desc;

### patient index ascending
-- The ascending/descending indexes are calculated ordering on the dispense date
-- new temp tables are used to build them and then joined into the main temp table.
-- index resets at each new patient
DROP TEMPORARY TABLE IF EXISTS temp_patient_index_asc;
CREATE TEMPORARY TABLE temp_patient_index_asc
(
    SELECT
            patient_id,
            status_id,
            status_concept_id,
            start_date,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            status_id,
            status_concept_id,
            start_date,
            patient_id,
            @u:= patient_id
      FROM temp_status,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id ASC, start_date ASC, patient_program_id ASC,  status_id ASC
        ) index_program_ascending );

UPDATE temp_status t
INNER JOIN temp_patient_index_asc tpia ON tpia.status_id = t.status_id
SET index_patient_ascending = tpia.index_asc;

DROP TEMPORARY TABLE IF EXISTS temp_patient_index_desc;
CREATE TEMPORARY TABLE temp_patient_index_desc
(
    SELECT
            patient_id,
            status_id,
            start_date,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            status_id,
            start_date,
            patient_id,
            @u:= patient_id
      FROM temp_status,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id ASC, start_date DESC, patient_program_id DESC, status_id DESC
        ) index_program_descending );

UPDATE temp_status t
INNER JOIN temp_patient_index_desc tpid ON tpid.status_id = t.status_id
SET index_patient_descending = tpid.index_desc;

## end date
DROP TEMPORARY TABLE IF EXISTS dup_status;
CREATE TEMPORARY TABLE dup_status SELECT * FROM temp_status;

CREATE INDEX dup_status_patient_program_id ON dup_status (patient_program_id);
CREATE INDEX dup_status_index_program_ascending ON dup_status (index_program_ascending);

UPDATE temp_status t
LEFT OUTER JOIN dup_status d ON d.patient_program_id = t.patient_program_id AND d.index_program_ascending = t.index_program_ascending + 1
SET t.end_date = d.start_date
WHERE t.index_program_descending <> 1;

CREATE INDEX temp_patient_index_asc_patient_id ON temp_patient_index_asc (patient_id);
CREATE INDEX temp_patient_index_asc_index ON temp_patient_index_asc (index_asc);

## return to care
-- on any rows that are not outcomes, if any of the previous rows are LTFU, then set to 1
UPDATE temp_status t
SET t.return_to_care = 1
WHERE EXISTS 
   (SELECT 1 FROM temp_patient_index_asc t2
   WHERE t2.patient_id=t.patient_id
   AND t2.index_asc < t.index_patient_ascending
   AND t2.status_concept_id = CONCEPT_FROM_MAPPING('PIH','LOST TO FOLLOWUP'))
AND t.outcome IS NULL  
;

## late for pickup.  
-- If the next dispensing date (next appointment from latest dispensing encounter)
-- is >= 29 days late then set to 1
-- if there is no next dispensing date, set to 1 
UPDATE temp_status t
LEFT OUTER JOIN encounter e ON e.encounter_id = LATESTENC(t.patient_id, @hivDispensingEncName, NULL)
LEFT OUTER JOIN obs o ON o.encounter_id = e.encounter_id AND o.voided = 0 AND o.concept_id = CONCEPT_FROM_MAPPING('PIH','5096')
SET t.currently_late_for_pickup = IF(TIMESTAMPDIFF(DAY,IFNULL(DATE(o.value_datetime),'1900-01-01'),CURRENT_DATE)>=29,1,NULL); 

## transfer status
## as stated on ticket UHM-5105 transfer_status should come from the intake form only
## changing this to use the program
/*
On new enrollments, IF there is a previous enrollment with an outcome of “Transfer to another ZL site”,
use the location from THAT enrollment to populate transfer_in_site.  Only use the latest one if there are multiple.
*/
DROP TEMPORARY TABLE IF EXISTS temp_hiv_latest_transfer;
CREATE TEMPORARY TABLE temp_hiv_latest_transfer
(
    patient_id INT(11),
    patient_program_id INT(11),
    location_id INT(11),
    status_concept_id INT(11),
    start_date DATE,
    end_date DATE,
    index_patient_ascending INT(11),
    index_patient_count INT(11)
);

INSERT INTO temp_hiv_latest_transfer
(
        patient_id,
        patient_program_id,
        location_id,
        status_concept_id,
        start_date,
        end_date,
        index_patient_ascending
)
SELECT patient_id, patient_program_id, location_id, status_concept_id, start_date, end_date, index_patient_ascending
FROM temp_status WHERE status_concept_id = 
(SELECT concept_id FROM concept_name WHERE voided = 0 AND name = "Transfer to another ZL site" AND concept_name_type = "FULLY_SPECIFIED" AND locale = "en") ORDER BY patient_id;

/** Note that this puts into account that this is a new enrollment and this enrollment is right
after the latest status outcome of transfer from another zl site
**/

UPDATE temp_hiv_latest_transfer SET index_patient_count = index_patient_ascending + 1;

UPDATE temp_status t JOIN temp_hiv_latest_transfer th ON th.patient_id = t.patient_id AND t.index_patient_ascending = th.index_patient_count
SET transfer_internal_sitename = LOCATION_NAME(th.location_id);

### Final query
SELECT 
    status_id,
    patient_id,
    ZLEMR(patient_id) "zl_emr_id",
    LOCATION_NAME(location_id) "patient_location",
    transfer_internal_sitename,
    CONCEPT_NAME(status_concept_id, 'en') "status_outcome",
    DATE(start_date),
    DATE(end_date),
    IFNULL(return_to_care,0) "return_to_care",
    IFNULL(currently_late_for_pickup,0) "currently_late_for_pickup",
    index_program_ascending,
    index_program_descending,
    index_patient_ascending,
    index_patient_descending
FROM temp_status
ORDER BY patient_id,index_patient_ascending;