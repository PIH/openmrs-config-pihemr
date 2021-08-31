SELECT 
    patient_id,
    encounter_id,
    encounter_type,
    ENCOUNTER_LOCATION_NAME(encounter_id) 'encounter_location',
    encounter_datetime,
    PROVIDER(encounter_id) 'provider',
    ENCOUNTER_CREATOR(encounter_id) 'data_entry_clerk',
    date_created 'date_entered',
    date_changed
FROM
    encounter
WHERE
    voided = 0;