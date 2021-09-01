DROP TEMPORARY TABLE IF EXISTS temp_obs_count;
CREATE TEMPORARY TABLE temp_obs_count AS
SELECT encounter_id, COUNT(obs_id) obs_count FROM obs o WHERE o.voided = 0 GROUP BY o.encounter_id;


DROP TEMPORARY TABLE IF EXISTS temp_datakind_enc;
CREATE TEMPORARY TABLE temp_datakind_enc
AS
SELECT 
    patient_id,
    e.encounter_id 'encounter_id',
    e.encounter_datetime 'encounter_datetime',
    ENCOUNTER_TYPE_NAME(e.encounter_id) 'encounter_type',
    ENCOUNTER_LOCATION_NAME(e.encounter_id) 'encounter_location',
    PROVIDER(e.encounter_id) 'provider',
    ENCOUNTER_CREATOR(e.encounter_id) 'data_entry_clerk',
    date_created 'date_entered',
    date_changed,
    toc.obs_count
FROM
    encounter e
    LEFT JOIN temp_obs_count toc ON toc.encounter_id = e.encounter_id
WHERE
    voided = 0 ORDER BY e.patient_id;

-- index
CREATE INDEX temp_datakind_enc_patientid ON temp_datakind_enc(patient_id);
CREATE INDEX temp_datakind_enc_encounterid ON temp_datakind_enc(encounter_id);

-- index asc
DROP TEMPORARY TABLE IF EXISTS temp_datakind_index_asc;
CREATE TEMPORARY TABLE temp_datakind_index_asc
(
    SELECT
            patient_id,
            encounter_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            patient_id,
            encounter_id,
            @u:= patient_id
      FROM temp_datakind_enc,
        (SELECT @r:= 1) AS r,
        (SELECT @u:= 0) AS u
      ORDER BY patient_id, encounter_id ASC
        ) index_ascending );

-- index
CREATE INDEX temp_datakind_index_asc_patientid ON temp_datakind_index_asc(patient_id);
CREATE INDEX temp_datakind_index_asc_encounterid ON temp_datakind_index_asc(encounter_id);
CREATE INDEX temp_datakind_index_asc_indexasc ON temp_datakind_index_asc(index_asc);

-- index desc
DROP TEMPORARY TABLE IF EXISTS temp_datakind_index_desc;
CREATE TEMPORARY TABLE temp_datakind_index_desc
(
    SELECT
            patient_id,
            encounter_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            patient_id,
            encounter_id,
            @u:= patient_id
      FROM temp_datakind_enc,
        (SELECT @r:= 1) AS r,
        (SELECT @u:= 0) AS u
      ORDER BY patient_id, encounter_id DESC
        ) index_descending );

-- indexes
CREATE INDEX temp_datakind_index_desc_patientid ON temp_datakind_index_desc(patient_id);
CREATE INDEX temp_datakind_index_desc_encounterid ON temp_datakind_index_desc(encounter_id);
CREATE INDEX temp_datakind_index_desc_indexasc ON temp_datakind_index_desc(index_desc);

SELECT 
	t.patient_id,
    t.encounter_id,
    t.encounter_datetime,
    t.encounter_type,
    t.encounter_location,
    t.provider,
    t.data_entry_clerk,
    t.date_entered,
    t.date_changed,
    t.obs_count,
    index_asc,
    index_desc
FROM temp_datakind_enc t JOIN temp_datakind_index_asc td ON t.encounter_id = td.encounter_id
JOIN temp_datakind_index_desc te ON t.encounter_id = te.encounter_id;