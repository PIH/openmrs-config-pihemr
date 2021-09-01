set @reg_encounter_type = (select encounter_type_id from
encounter_type where uuid = '873f968a-73a8-4f9c-ac78-9f4778b751b6');

SELECT
    p.patient_id,
    encounter_datetime 'registration_date',
    d.death_date,
	p.date_created 'patient_date_created',
    p.date_changed 'patient_date_changed',
    e.date_created 'encouter_date_created',
    e.date_changed 'encounter_date_changed'
FROM
    patient p
        LEFT JOIN
    encounter e ON p.patient_id = e.patient_id
        AND e.voided = 0
        AND p.voided = 0
        AND e.encounter_type = @reg_encounter_type
        LEFT JOIN
    person d ON d.person_id = p.patient_id
        AND d.voided = 0
ORDER BY p.patient_id;