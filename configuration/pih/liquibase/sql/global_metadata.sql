#
DROP PROCEDURE IF EXISTS initialize_global_metadata;
#
CREATE PROCEDURE initialize_global_metadata()
BEGIN
	SET @dosId = (select patient_identifier_type_id from patient_identifier_type where uuid = 'e66645eb-03a8-4991-b4ce-e87318e37566');
    SET @zlId = (select patient_identifier_type_id from patient_identifier_type where uuid = 'a541af1e-105c-40bf-b345-ba1fd6a59b85');
    SET @testPt = (select person_attribute_type_id from person_attribute_type where uuid = '4f07985c-88a5-4abd-aa0c-f3ec8324d8e7');
    SET @unknownPt = (select person_attribute_type_id from person_attribute_type where uuid = '8b56eac7-5c76-4b9c-8c6f-1deab8d3fc47');
END
#
