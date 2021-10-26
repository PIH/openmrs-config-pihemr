SET @reg_encounter = (SELECT encounter_type_id FROM encounter_type WHERE uuid = "873f968a-73a8-4f9c-ac78-9f4778b751b6");
SET @concept1 = CONCEPT_FROM_MAPPING("PIH", "ID Card Printing Requested");
SET @concept2 = CONCEPT_FROM_MAPPING("PIH", "Country");
SET @concept3 = CONCEPT_FROM_MAPPING("PIH", "City Village");
SET @concept4 = CONCEPT_FROM_MAPPING("PIH", "Address3");
SET @concept5 = CONCEPT_FROM_MAPPING("PIH", "State Province");
SET @concept6 = CONCEPT_FROM_MAPPING("PIH", "Address1");
SET @concept7 = CONCEPT_FROM_MAPPING("PIH", "PLACE OF BIRTH");
SET @concept8 = CONCEPT_FROM_MAPPING("PIH", "CIVIL STATUS");
SET @concept9 = CONCEPT_FROM_MAPPING("PIH", "Occupation");
SET @concept10 = CONCEPT_FROM_MAPPING("PIH", "Religion");
SET @concept11 = CONCEPT_FROM_MAPPING("PIH", "NAMES AND FIRSTNAMES OF CONTACT");
SET @concept12 = CONCEPT_FROM_MAPPING("PIH", "RELATIONSHIPS OF CONTACT");
SET @concept13 = CONCEPT_FROM_MAPPING("PIH", "TELEPHONE NUMBER OF CONTACT");
SET @concept14 = CONCEPT_FROM_MAPPING("PIH", "RELATIONSHIPS OF CONTACT");
SET @concept15 = CONCEPT_FROM_MAPPING("PIH", "ADDRESS OF PATIENT CONTACT");
SET @concept16 = CONCEPT_FROM_MAPPING("PIH", "Insurance policy number");
SET @concept17 = CONCEPT_FROM_MAPPING("PIH", "Haiti insurance company name");
SET @concept18 = CONCEPT_FROM_MAPPING("PIH", "Insurance company name (text)");

DROP TEMPORARY TABLE IF EXISTS temp_registration_activity;
CREATE TEMPORARY TABLE temp_registration_activity
AS
# patient's gender, birthdate, birtdate_estimated
SELECT 'person' AS "table_name", person_id, date_created, date_changed FROM person WHERE date_changed IS NOT NULL
AND person_id NOT IN (SELECT person_id FROM users)
UNION ALL
## patient names
SELECT 'person_name' AS "table_name", person_id, date_created, date_changed FROM person_name WHERE date_changed IS NOT NULL AND voided = 1 
AND person_id NOT IN (SELECT person_id FROM users)
UNION ALL
# patient's address
SELECT 'person_address' AS "table_name", person_id, date_created, date_changed FROM person_address WHERE date_changed IS NOT NULL AND voided = 1
AND person_id NOT IN (SELECT person_id FROM users)
UNION ALL
## patient's mother name, patient's telehone
SELECT 'person_attribute' AS "table_name", person_id, date_created, date_changed FROM person_attribute WHERE date_changed IS NOT NULL AND voided = 1 
AND person_id NOT IN (SELECT person_id FROM users)
UNION ALL
## patient identifier
SELECT 'person_identifier' AS "table_name", patient_id, date_created, date_changed FROM patient_identifier WHERE date_changed IS NOT NULL 
UNION ALL
SELECT 'encounter' AS "table_name", patient_id, date_created, date_changed FROM encounter WHERE date_changed IS NOT NULL AND encounter_type = @reg_encounter
UNION ALL
SELECT 'obs' AS "table_name", person_id, date_created, date_voided FROM obs WHERE date_voided IS NOT NULL AND voided = 1
AND concept_id IN  
(@concept1, @concept2, @concept3, @concept4, @concept5, @concept6, @concept7, @concept8, @concept9, @concept10,
@concept11, @concept12, @concept13, @concept14, @concept15, @concept16, @concept17, @concept18);

-- index desc
DROP TEMPORARY TABLE IF EXISTS temp_datakind_regact_index_desc;
CREATE TEMPORARY TABLE temp_datakind_regact_index_desc
(
    SELECT
            person_id,
            date_created,
            date_changed,
            table_name,
            index_count
FROM (SELECT
            @r:= IF(@u = person_id, @r + 1,1) index_count,
            person_id,
            date_created,
            date_changed,
            table_name,
            @u:= person_id
      FROM temp_registration_activity,
        (SELECT @r:= 1) AS r,
        (SELECT @u:= 0) AS u
      ORDER BY person_id DESC
        ) index_descending );

# final query
SELECT 
	* 
FROM
temp_datakind_regact_index_desc
ORDER BY person_id;