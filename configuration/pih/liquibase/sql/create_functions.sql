-- noinspection SqlDialectInspectionForFile

/*
  This file contains common functions that are useful writing reports
  For documentation on available functions, please see the sql_function_reference.csv file in this directory
*/

-- You should uncomment this line to check syntax in IDE.  Liquibase handles this internally.
-- DELIMITER #

/*
 get concept_id from report_mapping table
*/
#
DROP FUNCTION IF EXISTS concept_from_mapping;
#
CREATE FUNCTION concept_from_mapping(
	_source varchar(50),
    _code varchar(255)
)
    RETURNS INT
    DETERMINISTIC
BEGIN
    DECLARE mappedConcept INT;

	SELECT concept_id INTO mappedConcept FROM report_mapping WHERE source = _source and code = _code;

    RETURN mappedConcept;

END
#

/*
get names from the concept_name table
*/
#
DROP FUNCTION IF EXISTS concept_name;
#
CREATE FUNCTION concept_name(
    _conceptID INT,
    _locale varchar(50)
)
	RETURNS VARCHAR(255)
    DETERMINISTIC

BEGIN
    DECLARE conceptName varchar(255);

	SELECT name INTO conceptName
	FROM concept_name
	WHERE voided = 0
	  AND concept_id = _conceptID
	order by if(_locale = locale, 0, 1), if(locale = 'en', 0, 1),
	  locale_preferred desc, ISNULL(concept_name_type) asc, 
	  field(concept_name_type,'FULLY_SPECIFIED','SHORT')
	limit 1;

    RETURN conceptName;
END
#

/*
    return encounter type id given name or uuid
*/
#
DROP FUNCTION IF EXISTS encounter_type;
#
CREATE FUNCTION encounter_type(
    _name_or_uuid varchar(255)
)
	RETURNS INT
    DETERMINISTIC

BEGIN
    DECLARE ret varchar(255);

	SELECT  encounter_type_id INTO ret
	FROM    encounter_type where name = _name_or_uuid or uuid = _name_or_uuid;

    RETURN ret;
END
#
-- The following function accepts an encounter_type_id
-- It will return the names of the encounter_type
#
DROP FUNCTION IF EXISTS encounter_type_name_from_id;
#
CREATE FUNCTION encounter_type_name_from_id(
    _encounter_type_id INT
)
    RETURNS varchar(50)
    DETERMINISTIC

BEGIN
    DECLARE encounterName varchar(50);

    SELECT
    et.name INTO encounterName
FROM
    encounter_type et
where encounter_type_id = _encounter_type_id;

    RETURN encounterName;

END
#
/*
    return patient identifier type id
*/
#
DROP FUNCTION IF EXISTS patient_identifier;
#
CREATE FUNCTION patient_identifier(
    _patient_id int,
    _name_or_uuid varchar(255)
)
    RETURNS varchar(50)
    DETERMINISTIC

BEGIN
    DECLARE ret varchar(50);

    SELECT      i.identifier INTO ret
    FROM        patient_identifier i
    INNER JOIN  patient_identifier_type t on i.identifier_type = t.patient_identifier_type_id
    WHERE       (t.name = _name_or_uuid or t.uuid = _name_or_uuid)
    AND         i.voided = 0
    AND         i.patient_id = _patient_id
    ORDER BY    preferred desc, i.date_created desc limit 1;

    RETURN ret;
END
#
/*
This function accepts patient/person id and returns that person's age in years
*/
#
DROP FUNCTION IF EXISTS current_age_in_years;
#
CREATE FUNCTION current_age_in_years(
    _person_id int)

    RETURNS int
    DETERMINISTIC

BEGIN
    DECLARE currentAge int;

	select  TIMESTAMPDIFF(YEAR, birthdate, now()) into currentAge
	from    person p 
	where 	p.person_id = _person_id;

    RETURN currentAge;
END
#
/*
This function accepts patient/person id and returns that person's age in months
*/
#
DROP FUNCTION IF EXISTS current_age_in_months;
#
CREATE FUNCTION current_age_in_months(
    _person_id int)

    RETURNS DOUBLE
    DETERMINISTIC

BEGIN
    DECLARE currentAge DOUBLE;

	select  TIMESTAMPDIFF(MONTH, birthdate, now()) into currentAge
	from    person p 
	where 	p.person_id = _person_id;

    RETURN currentAge;
END
#
/*
 get patient age at encounter
*/
#
DROP FUNCTION IF EXISTS age_at_enc;
#
CREATE FUNCTION age_at_enc(
    _person_id int,
    _encounter_id int
)
	RETURNS DOUBLE
    DETERMINISTIC

BEGIN
    DECLARE ageAtEnc DOUBLE;

	select  TIMESTAMPDIFF(YEAR, birthdate, encounter_datetime) into ageAtENC
	from    encounter e
	join    person p on p.person_id = e.patient_id
	where   e.encounter_id = _encounter_id
	and     p.person_id = _person_id;

    RETURN ageAtEnc;
END
#

/*
get patient EMR ZL
*/
#
DROP FUNCTION IF EXISTS zlemr;
#
CREATE FUNCTION zlemr(
    _patient_id int
)
	RETURNS VARCHAR(255)
    DETERMINISTIC

BEGIN
    DECLARE  zlEMR VARCHAR(255);
    SELECT patient_identifier(_patient_id, 'ZL EMR ID') into zlEMR;
    RETURN zlEMR;
END
#

DROP FUNCTION IF EXISTS dosId;
#

CREATE FUNCTION dosId (patient_id_in int(11))
RETURNS varchar(50)

DETERMINISTIC

BEGIN

DECLARE dosId_out varchar(50);

select identifier into dosId_out
from patient_identifier pid
where pid.patient_id = patient_id_in
and pid.voided = 0
and pid.identifier_type =
  (select patient_identifier_type_id from patient_identifier_type where uuid = 'e66645eb-03a8-4991-b4ce-e87318e37566')
order by pid.preferred desc, pid.date_created asc limit 1
;

RETURN dosId_out;

END;
#
/*
unknown patient
*/
#
DROP FUNCTION IF EXISTS unknown_patient;
#
CREATE FUNCTION unknown_patient(
    _patient_id int
)
	RETURNS VARCHAR(50)
    DETERMINISTIC

BEGIN
    DECLARE  unknownPatient VARCHAR(50);

	select person_id into unknownPatient from person_attribute where person_attribute_type_id = (select person_attribute_type_id from
person_attribute_type where name = 'Unknown patient') and voided = 0 and person_id = _patient_id;

    RETURN unknownPatient;

END
#
/*
person_attribute_value
*/
#
DROP FUNCTION IF EXISTS person_attribute_value;
#
CREATE FUNCTION person_attribute_value(
    _patient_id int,
    _att_type_name varchar(50)
)
    RETURNS VARCHAR(50)
    DETERMINISTIC

BEGIN
    DECLARE  attVal VARCHAR(50);

    select      a.value into attVal
    from        person_attribute a
    inner join  person_attribute_type pat on a.person_attribute_type_id = pat.person_attribute_type_id
    where       pat.name = _att_type_name
    and         a.voided = 0
    and         a.person_id = _patient_id
    order by    a.date_created desc
    limit       1;

    RETURN attVal;

END
#

/*
gender
*/
#
DROP FUNCTION IF EXISTS gender;
#
CREATE FUNCTION gender(
    _patient_id int
)
	RETURNS VARCHAR(50)
    DETERMINISTIC

BEGIN
    DECLARE  patientGender VARCHAR(50);

	select gender into patientGender from person where person_id = _patient_id and voided =0;

    RETURN patientGender;

END
#

/*
 patient address
*/
#
DROP FUNCTION IF EXISTS person_address;
#
CREATE FUNCTION person_address(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddress TEXT;

	select concat(IFNULL(state_province,''), ',' ,IFNULL(city_village,''), ',', IFNULL(address3,''), ',', IFNULL(address1,''), ',',IFNULL(address2,'')) into patientAddress
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddress;

END
#
/*
 patient name
*/
#
DROP FUNCTION IF EXISTS person_name;
#
CREATE FUNCTION person_name(
    _person_id int
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE personName TEXT;

    select      concat(given_name, ' ', family_name) into personName
    from        person_name
    where       voided = 0
    and         person_id = _person_id
    order by    preferred desc, date_created desc
    limit       1;

    RETURN personName;

END
#
/*
patient birthdate
*/
#
DROP FUNCTION IF EXISTS birthdate;
#
CREATE FUNCTION birthdate(
    _patient_id int
)
	RETURNS date
    DETERMINISTIC

BEGIN
    DECLARE  patientBirthdate date;

	select birthdate into patientBirthdate from person where person_id = _patient_id;

    RETURN patientBirthdate;

END
#
/*
 patient GIVEN name
*/
#
DROP FUNCTION IF EXISTS person_given_name;
#
CREATE FUNCTION person_given_name(
    _person_id int
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE personGivenName TEXT;

    select      given_name into personGivenName
    from        person_name
    where       voided = 0
    and         person_id = _person_id
    order by    preferred desc, date_created desc
    limit       1;

    RETURN personGivenName;

END
#
/*
 patient FAMILY name
*/
#
DROP FUNCTION IF EXISTS person_family_name;
#
CREATE FUNCTION person_family_name(
    _person_id int
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE personFamilyName TEXT;

    select      family_name into personFamilyName
    from        person_name
    where       voided = 0
    and         person_id = _person_id
    order by    preferred desc, date_created desc
    limit       1;

    RETURN personFamilyName;

END
#
/*
 person middle name
*/
#
DROP FUNCTION IF EXISTS person_middle_name;
#
CREATE FUNCTION person_middle_name(
    _person_id int
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE personMiddleName TEXT;

    select      middle_name into personMiddleName
    from        person_name
    where       voided = 0
    and         person_id = _person_id
    order by    preferred desc, date_created desc
    limit       1;

    RETURN personMiddleName;

END
#
/*
  ZL EMR ID location
*/
#
DROP FUNCTION IF EXISTS loc_registered;
#
CREATE FUNCTION loc_registered(
    _patient_id int
)
	RETURNS VARCHAR(255)
    DETERMINISTIC

BEGIN
    DECLARE locRegistered varchar(255);

select name into locRegistered from location l join patient_identifier pi on pi.location_id = l.location_id and pi.voided = 0 and pi.patient_id = _patient_id
and identifier_type = (select pid2.patient_identifier_type_id from patient_identifier_type pid2 where
pid2.uuid = metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')) limit 1;

    RETURN locRegistered;

END
#
/*
  returns the registration date of the given patient
*/
#
DROP FUNCTION IF EXISTS registration_date;
#
CREATE FUNCTION registration_date(
    _patient_id int
)
	RETURNS DATETIME
    DETERMINISTIC

BEGIN
    DECLARE return_date datetime;

select encounter_datetime into return_date from encounter 
where patient_id = _patient_id
and encounter_type = (select encounter_type_id from encounter_type et where uuid = '873f968a-73a8-4f9c-ac78-9f4778b751b6')
and voided = 0
limit 1
;
    RETURN return_date;

END
#
/*
Provider
*/
#
DROP FUNCTION IF EXISTS provider;
#
CREATE FUNCTION provider (
    _encounter_id int
)
	RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE providerName varchar(255);

select CONCAT(given_name, ' ', family_name) into providerName
from person_name pn join provider pv on pn.person_id = pv.person_id AND pn.voided = 0
join encounter_provider ep on pv.provider_id = ep.provider_id and ep.voided = 0 and ep.encounter_id = _encounter_id
limit 1;

    RETURN providerName;

END
#
-- This function accepts encounter_id, provider_type, and offset
-- It return the name of the nth provider (based of offset) or the specified type
#
DROP FUNCTION IF EXISTS provider_name_of_type;
#
CREATE FUNCTION provider_name_of_type (
    _encounter_id int,
    _provider_type varchar(255),
    _offset_value int
)
	RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE providerName varchar(255);

select CONCAT(given_name, ' ', family_name) into providerName
from person_name pn join provider pv on pn.person_id = pv.person_id AND pn.voided = 0
inner join encounter_provider ep on pv.provider_id = ep.provider_id and ep.voided = 0 and ep.encounter_id = _encounter_id 
	and ep.encounter_role_id = _provider_type 
order by ep.date_created desc, ep.encounter_provider_id desc		
limit 1 offset _offset_value;

    RETURN providerName;

END
#
/*
This function accepts an encounter_id
It will return the text of provider type for that encounter
NOTE that this will only return one provider type and should not be used if there are multiple providers on an encounter
*/
#
DROP FUNCTION IF EXISTS provider_type;
#
CREATE FUNCTION provider_type (
    _encounter_id int
)
	RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE providerType varchar(255);

select pr.name into providerType
from providermanagement_provider_role pr
join provider pv on pr.provider_role_id = pv.provider_role_id 
join encounter_provider ep on pv.provider_id = ep.provider_id and ep.voided = 0 and ep.encounter_id = _encounter_id
limit 1;

    RETURN providerType;

END
#
-- This function accepts an encounter_id
-- It will return the date created of that encounter
#
DROP FUNCTION IF EXISTS encounter_date_created;
#
CREATE FUNCTION encounter_date_created (
    _encounter_id int
)
    RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE dateCreated datetime;

select e.date_created into dateCreated
from encounter e 
where e.encounter_id = _encounter_id;

    RETURN dateCreated;
END
#
-- This function accepts an encounter_id
-- It will return the name of the creator of that encounter
#
DROP FUNCTION IF EXISTS encounter_creator_name;
#
CREATE FUNCTION encounter_creator_name (
    _encounter_id int
)
    RETURNS VARCHAR(100)
    DETERMINISTIC
BEGIN
    DECLARE creator VARCHAR(100);

select concat(given_name, ' ', family_name) into creator
from encounter e 
inner join users u on e.creator  = u.user_id 
inner join person_name pn on pn.person_id = u.person_id 
where e.encounter_id = _encounter_id;

    RETURN creator;
END
#
/*
 returns person name of user_id
*/
#
DROP FUNCTION IF EXISTS person_name_of_user;
#
CREATE FUNCTION person_name_of_user(
    _user_id int
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE personName TEXT;

    select      concat(given_name, ' ', family_name) into personName
    from        person_name pn
    inner join users u on u.person_id  = pn.person_id and u.user_id = _user_id
    where       voided = 0
    order by    pn.preferred desc, pn.date_created desc
    limit       1;

    RETURN personName;

END
#
/*
Encounter Location
*/
#
DROP FUNCTION IF EXISTS encounter_location_name;
#
CREATE FUNCTION encounter_location_name (
    _encounter_id int
)
    RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE locName varchar(255);

    select      l.name into locName
    from        encounter e
    inner join  location l on l.location_id = e.location_id
    where       e.encounter_id = _encounter_id;

    RETURN locName;
END
#
/*
Encounter Parent Location
  It accepts encounter id and returns the parent location of the encounter.  
  It looks 3 levels deep - the encounter location, that location's parent and then that location's parent.
  The first location it finds without another parent is returned.
*/
#
DROP FUNCTION IF EXISTS encounter_parent_location_name;
#
CREATE FUNCTION encounter_parent_location_name (
    _encounter_id int
)
    RETURNS varchar(255)
    DETERMINISTIC
BEGIN
    DECLARE locName varchar(255);

    select      if(l.parent_location is null, l.name, if(lp.parent_location is null, lp.name, lp2.name)) into locName
    from        encounter e
    inner join  location l on l.location_id = e.location_id
    left outer join  location lp on lp.location_id = l.parent_location 
    left outer join  location lp2 on lp2.location_id = lp.parent_location    
    where       e.encounter_id = _encounter_id;

    RETURN locName;
END
#
/*
Encounter Date
*/
#
DROP FUNCTION IF EXISTS encounter_date;
#
CREATE FUNCTION encounter_date (
    _encounter_id int
)
    RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE encDate datetime;

    select      e.encounter_datetime into encDate
    from        encounter e
    where       e.encounter_id = _encounter_id;

    RETURN encDate;
END
#
/*
Visit date
*/
#
DROP FUNCTION IF EXISTS visit_date;
#
CREATE FUNCTION visit_date(
    _encounter_id int
)
	RETURNS DATE
    DETERMINISTIC

BEGIN
    DECLARE visitDate date;

    select date(date_started) into visitDate from visit where voided = 0 and visit_id = (select visit_id from encounter where encounter_id = _encounter_id);

    RETURN visitDate;

END
#
/*
This function accepts an obs_id and returns the obs_datetime of that obs
*/
#
DROP FUNCTION IF EXISTS obs_date;
#
CREATE FUNCTION obs_date (
    _obs_id int
)
    RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE obsDate datetime;

    select      o.obs_datetime into obsDate
    from        obs o
    where       o.obs_id = _obs_id;

    RETURN obsDate;
END
#
/*
Program
*/
#
DROP FUNCTION IF EXISTS program;
#
CREATE FUNCTION program(_name varchar (255))
	RETURNS INT
    DETERMINISTIC

BEGIN
    DECLARE programId int;

    select program_id into programId from program where retired = 0 and name = _name;

    RETURN programId;

END
#
/*
Relationship
*/
#
DROP FUNCTION IF EXISTS relation_type;
#
CREATE FUNCTION relation_type(
    _name VARCHAR(255)
)
	RETURNS INT
    DETERMINISTIC

BEGIN
    DECLARE relationshipID INT;

	SELECT relationship_type_id INTO relationshipID FROM relationship_type WHERE retired = 0 AND a_is_to_b = _name;

    RETURN relationshipID;
END
#

#

/*
 patient address
*/

#
DROP FUNCTION IF EXISTS person_address_state_province;
#
CREATE FUNCTION person_address_state_province(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressStateProvince TEXT;

	select state_province into patientAddressStateProvince
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressStateProvince;

END
#

#
DROP FUNCTION IF EXISTS person_address_city_village;
#
CREATE FUNCTION person_address_city_village(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressCityVillage TEXT;

	select city_village into patientAddressCityVillage
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressCityVillage;

END
#

#
DROP FUNCTION IF EXISTS person_address_three;
#
CREATE FUNCTION person_address_three(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressThree TEXT;

	select address3 into patientAddressThree
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressThree;

END
#

#
DROP FUNCTION IF EXISTS person_address_one;
#
CREATE FUNCTION person_address_one(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressOne TEXT;

	select address1 into patientAddressOne
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressOne;

END
#

#
DROP FUNCTION IF EXISTS person_address_two;
#
CREATE FUNCTION person_address_two(
    _patient_id int
)
	RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE patientAddressTwo TEXT;

	select address2 into patientAddressTwo
    from person_address where voided = 0 and person_id = _patient_id order by preferred desc, date_created desc limit 1;

    RETURN patientAddressTwo;

END
#
-- This function accepts patient_id
-- it returns the cdc_id of the patient's address
#
DROP FUNCTION IF EXISTS cdc_id;
#
CREATE FUNCTION cdc_id(_patient_id int(11))

  RETURNS varchar(11)
    DETERMINISTIC

BEGIN
    DECLARE cdc_id varchar(11);

select ahe_section.user_generated_id into cdc_id from
person_address pa 
LEFT OUTER JOIN address_hierarchy_entry ahe_country on ahe_country.name = pa.country
LEFT OUTER JOIN address_hierarchy_entry ahe_dept on ahe_dept.level_id = ahe_country.level_id + 1 and ahe_dept.parent_id = ahe_country.address_hierarchy_entry_id and ahe_dept.name = pa.state_province
LEFT OUTER JOIN address_hierarchy_entry ahe_commune on ahe_commune.level_id = ahe_dept.level_id + 1 and ahe_commune.parent_id = ahe_dept.address_hierarchy_entry_id and ahe_commune.name = pa.city_village
LEFT OUTER JOIN address_hierarchy_entry ahe_section on ahe_section.level_id = ahe_commune.level_id + 1 and ahe_section.parent_id = ahe_commune.address_hierarchy_entry_id and ahe_section.name = pa.address3
where pa.person_id = _patient_id
order by pa.preferred desc limit 1
;
    RETURN cdc_id;

END
#				       
				       
-- This function accepts a patient_id, concept_id and beginDate
-- It will return the obs_id of the most recent observation for that patient and concept_id SINCE the beginDate
-- if null is passed in as the beginDate, it will be disregarded
-- example: select latestObs(311450, 357, '2020-01-01') or select latestObs(311450, 357, '2020-02-12 08:59:59');

#
DROP FUNCTION IF EXISTS latestObs;
#
CREATE FUNCTION latestObs (patient_id_in int(11), concept_id_in int (11), beginDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE obs_id_out int(11);

    select obs_id into obs_id_out
    from obs o
    where o.voided = 0
      and o.person_id = patient_id_in
      and o.concept_id = concept_id_in
      and (beginDate is null or o.obs_datetime >= beginDate)
    order by o.obs_datetime desc
    limit 1;

    RETURN obs_id_out;

END
#

-- This function accepts patient_id, encounter_type and beginDate
-- It will return the latest encounter id if the patient
-- if null is passed in as the beginDate, it will be disregarded

#
DROP FUNCTION IF EXISTS latestEnc;
#
CREATE FUNCTION latestEnc(_patientId int(11), _encounterTypes varchar(255), _beginDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      encounter_id into enc_id_out
    from        encounter enc inner join encounter_type et on enc.encounter_type = et.encounter_type_id
    where       enc.voided = 0
    and         enc.patient_id = _patientId
    and         find_in_set(et.name, _encounterTypes)
    and         (_beginDate is null or enc.encounter_datetime >= _beginDate)
    order by    enc.encounter_datetime desc
    limit       1;

    RETURN enc_id_out;

END
#

-- This function accepts patient_id, encounter_type, beginDate, endDate
-- It will return the latest encounter of the specified type that it finds for the patient between the dates
-- Null date values can be used to indicate no constraint

#
DROP FUNCTION IF EXISTS latestEncBetweenDates;
#
CREATE FUNCTION latestEncBetweenDates(_patientId int(11), _encounterTypes varchar(255), _beginDate datetime, _endDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      encounter_id into enc_id_out
    from        encounter enc inner join encounter_type et on enc.encounter_type = et.encounter_type_id
    where       enc.voided = 0
      and       enc.patient_id = _patientId
      and       find_in_set(et.name, _encounterTypes)
      and       (_beginDate is null or enc.encounter_datetime >= _beginDate)
      and       (_endDate is null or enc.encounter_datetime <= _endDate)
    order by    enc.encounter_datetime desc
    limit       1;

    RETURN enc_id_out;

END
#
-- This function accepts a patient_id and single encounter_type and a begin date
-- will return the most recent encounter of that type since the begin date from the temp_encounter table
#
DROP FUNCTION IF EXISTS latest_enc_from_temp;
#
CREATE FUNCTION latest_enc_from_temp(_patientId int(11), _encounterTypeId int(11), _beginDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      encounter_id into enc_id_out
    from        temp_encounter enc 
    where       enc.patient_id = _patientId
    and         enc.encounter_type = _encounterTypeId
    and         (_beginDate is null or enc.encounter_datetime >= _beginDate)
    order by    enc.encounter_datetime desc
    limit       1;

    RETURN enc_id_out;

END
#
-- This function accepts patient_id, encounter_type and beginDate
-- It will return the first encounter of the specified type that it finds for the patient after the passed beginDate
-- if null is passed in as the beginDate, it will be disregarded
#
DROP FUNCTION IF EXISTS firstEnc;
#
CREATE FUNCTION firstEnc(_patientId int(11), _encounterTypes varchar(255), _beginDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      encounter_id into enc_id_out
    from        encounter enc inner join encounter_type et on enc.encounter_type = et.encounter_type_id
    where       enc.voided = 0
      and       enc.patient_id = _patientId
      and       find_in_set(et.name, _encounterTypes)
      and       (_beginDate is null or enc.encounter_datetime >= _beginDate)
    order by    enc.encounter_datetime asc
    limit       1;

    RETURN enc_id_out;

END
#
/*
  FUNCTIONS TO RETRIEVE OBSERVATION VALUES FROM A GIVEN ENCOUNTER
*/
-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_text
#
DROP FUNCTION IF EXISTS obs_value_text;
#
CREATE FUNCTION obs_value_text(_encounterId int(11), _source varchar(50), _term varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      o.value_text into ret
    from        obs o
    where       o.voided = 0
    and         o.encounter_id = _encounterId
    and         o.concept_id = concept_from_mapping(_source, _term)
    order by    o.date_created desc, o.obs_id desc
    limit 1;

    RETURN ret;

END

#

-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the concept name
#
DROP FUNCTION IF EXISTS obs_value_coded_list;
#
CREATE FUNCTION obs_value_coded_list(_encounterId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        obs o
    where       o.voided = 0
      and       o.encounter_id = _encounterId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#

-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_numeric
#
DROP FUNCTION IF EXISTS obs_value_numeric;
#
CREATE FUNCTION obs_value_numeric(_encounterId int(11), _source varchar(50), _term varchar(255))
RETURNS double
DETERMINISTIC

BEGIN

DECLARE ret double;

select      o.value_numeric into ret
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1;

RETURN ret;

END

#
-- This function accepts visit_id, mapping source, mapping code
-- It will find the value_coded entries that match this, separated by |
#
DROP FUNCTION IF EXISTS obs_from_visit_value_coded_list;
#
CREATE FUNCTION obs_from_visit_value_coded_list(_visitId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        obs o
    inner join encounter e on o.encounter_id = e.encounter_id and e.voided = 0
    where       o.voided = 0
      and       e.visit_id = _visitId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#

-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the value_coded entries that match this, separated by |

#

DROP FUNCTION IF EXISTS obs_from_group_id_value_coded_list;
#
CREATE FUNCTION obs_from_group_id_value_coded_list(_obsGroupId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#
-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the value_text entry that matches this
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_text;
#
CREATE FUNCTION obs_from_group_id_value_text(_obsGroupId int(11), _source varchar(50), _term varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      value_text into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#
-- This function accepts encounter_id, mapping source, mapping code
-- It will find the obs_id of the matching observation
#
DROP FUNCTION IF EXISTS obs_id;
#
CREATE FUNCTION obs_id(_encounterId int(11), _source varchar(50), _term varchar(255), _offset_value int)
RETURNS int
DETERMINISTIC

BEGIN

DECLARE ret int;

select      o.obs_id into ret
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1
offset _offset_value
;

RETURN ret;

END
#
/*
This function accepts a patient id, source & code of a concept
It will return the obs_id of the single latest obs recorded for that concept
*/
DROP FUNCTION IF EXISTS latest_obs;
#
CREATE FUNCTION latest_obs(_patient_id int(11), _source varchar(50), _term varchar(255))
    RETURNS int
    DETERMINISTIC

BEGIN

    DECLARE ret int(11);

    select      o.obs_id into ret
    from        obs o
    where       o.voided = 0
		and o.person_id = _patient_id    		
      	and       o.concept_id = concept_from_mapping(_source, _term)
    order by obs_datetime desc limit 1 ;

    RETURN ret;
    
END    
#
/*  
This function accepts an obs_id and a locale
It will return the concept name of that obs, in that locale
*/    
DROP FUNCTION IF EXISTS value_coded_name;
#
CREATE FUNCTION value_coded_name(_obs_id int(11),  _locale varchar(50))
    RETURNS varchar(255)
    DETERMINISTIC

BEGIN

    DECLARE ret varchar(255);

    select      concept_name(o.value_coded,@locale) into ret
    from        obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*  
This function accepts an obs_id
It will return the value_numeric of that obs
*/    
DROP FUNCTION IF EXISTS value_numeric;
#
CREATE FUNCTION value_numeric(_obs_id int(11))
    RETURNS double
    DETERMINISTIC

BEGIN

    DECLARE ret double;

    select      value_numeric into ret
    from        obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*  
This function accepts an obs_id
It will return the value_datetime of that obs
*/    
DROP FUNCTION IF EXISTS value_datetime;
#
CREATE FUNCTION value_datetime(_obs_id int(11))
    RETURNS datetime
    DETERMINISTIC

BEGIN

    DECLARE ret datetime;

    select      value_datetime into ret
    from        obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*  
This function accepts an obs_id
It will return the value_text of that obs
*/    
DROP FUNCTION IF EXISTS value_text;
#
CREATE FUNCTION value_text(_obs_id int(11))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      value_text into ret
    from        obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*
 This function accepts encounter_id, mapping source, mapping code
 It will find a single, best observation that matches this, translating yes/no answer into 1/0 boolean*/
#
DROP FUNCTION IF EXISTS obs_value_coded_as_boolean;
#
CREATE FUNCTION obs_value_coded_as_boolean(_encounterId int(11), _source varchar(50), _term varchar(255))
    RETURNS boolean	
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select    
    	CASE o.value_coded
    		when concept_from_mapping('PIH','1065') then 1
	    	when concept_from_mapping('PIH','1066') then 0
		END    
    into ret
    from        obs o
    where       o.voided = 0
    and         o.encounter_id = _encounterId
    and         o.concept_id = concept_from_mapping(_source, _term)
    order by    o.date_created desc, o.obs_id desc
    limit 1;

    RETURN ret;

END
#
/*  
This function accepts an obs_id 
It will return the value coded of that obs, translated into a boolean
*/    
DROP FUNCTION IF EXISTS value_coded_as_boolean;
#
CREATE FUNCTION value_coded_as_boolean(_obs_id int(11))
    RETURNS boolean
    DETERMINISTIC

BEGIN

    DECLARE ret boolean;

    select CASE o.value_coded
		WHEN concept_from_mapping('PIH','YES') then 1
		WHEN concept_from_mapping('PIH','NO') then 0
	END into ret
	from        obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*
This function accepts a patient id, source & code of a question concept and source &code of an answer concept
It will return a boolean set to 1 if that question and answer has EVER been recorded for a patient since the datetime passed in.
Null can be passed in as the datetime if it is to be disregarded.
*/
#
DROP FUNCTION IF EXISTS answerEverExists;
#
CREATE FUNCTION answerEverExists(_patient_id int(11), _source_question varchar(50), _term_question varchar(255), _source_answer varchar(50), _term_answer varchar(255), _begin_datetime datetime)
    RETURNS boolean
    DETERMINISTIC

BEGIN

  DECLARE ret boolean;


select if(obs_id is null,0,1) into ret
from obs o where o.voided =0 
	and o.person_id = _patient_id
	and o.concept_id = concept_from_mapping(_source_question,_term_question)
	and o.value_coded  = concept_from_mapping(_source_answer,_term_answer)
	and (o.obs_datetime >= _begin_datetime or _begin_datetime is null)
	limit 1;

    RETURN ret;

END
#
/*
 get global property value
*/
#
DROP FUNCTION IF EXISTS global_property_value;
#
CREATE FUNCTION global_property_value(
    _property varchar(255),
    _defaultValue text
)
    RETURNS text
    DETERMINISTIC
BEGIN
    DECLARE val text;

    SELECT property_value into val FROM global_property where property = _property;
    SELECT if(val is null || val = '', _defaultValue, val) into val;

    return val;

END
#

/*
 get global property value
*/
#
DROP FUNCTION IF EXISTS user_property_value;
#
CREATE FUNCTION user_property_value(
    _userId int,
    _property varchar(1000),
    _defaultValue text
)
    RETURNS text
    DETERMINISTIC
BEGIN
    DECLARE val text;

    SELECT property_value into val FROM user_property where user_id = _userId and property = _property;
    SELECT if(val is null || val = '', _defaultValue, val) into val;

    return val;

END
#

/*
 get metadata mapping uuid
*/
#
DROP FUNCTION IF EXISTS metadata_uuid;
#
CREATE FUNCTION metadata_uuid(
    _sourceName varchar(255),
    _codeName varchar(255)
)
    RETURNS varchar(38)
    DETERMINISTIC
BEGIN
    DECLARE ret varchar(38);

    select      m.metadata_uuid into ret
    from        metadatamapping_metadata_term_mapping m
    inner join  metadatamapping_metadata_source s on s.metadata_source_id = m.metadata_source_id
    where       s.name = _sourceName
    and         m.code = _codeName;

    return ret;
END
#

-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_datetime
#
DROP FUNCTION IF EXISTS obs_value_datetime;
#
CREATE FUNCTION obs_value_datetime(_encounterId int(11), _source varchar(50), _term varchar(255))
RETURNS datetime
DETERMINISTIC

BEGIN

DECLARE ret datetime;

select      o.value_datetime into ret
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1;

RETURN ret;

END

#

-- This function accepts encounter_id, mapping source, mapping code (for both the concept_id and value_coded) and returns
-- "yes" (in the default locale of the implementation) if the obs_id exists and
-- null if the obs_id does not exisit
-- This function is used on questions that also act as answers (i.e you either check it as true or your don't)
#
DROP FUNCTION IF EXISTS obs_single_value_coded;
#
CREATE FUNCTION obs_single_value_coded(_encounterId int(11), _source varchar(50), _term varchar(255), _source1 varchar(50), _term1 varchar(255))
RETURNS varchar(11)
DETERMINISTIC

BEGIN

DECLARE ret varchar(11);

select      IFNULL(NULL, concept_name(concept_from_mapping('PIH','YES'), global_property_value('default_locale', 'en'))) into ret FROM
(
select      obs_id
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
and         o.value_coded = concept_from_mapping(_source1, _term1)
order by    o.date_created desc, o.obs_id desc
limit 1
) obs_single_question_answer;

RETURN ret;

END

#

-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the value_datetime entry that matches this
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_datetime;
#
CREATE FUNCTION obs_from_group_id_value_datetime(_obsGroupId int(11), _source varchar(50), _term varchar(255))
    RETURNS datetime
    DETERMINISTIC

BEGIN

    DECLARE ret datetime;

    select      value_datetime into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#

-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the comments entry that matches this
#
DROP FUNCTION IF EXISTS obs_from_group_id_comment;
#
CREATE FUNCTION obs_from_group_id_comment(_obsGroupId int(11), _source varchar(50), _term varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      comments into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END

#

-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the comment

#
DROP FUNCTION IF EXISTS obs_comments;
#
CREATE FUNCTION obs_comments(_encounterId int(11), _source varchar(50), _term varchar(255), _source1 varchar(50), _term1 varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      o.comments into ret
    from        obs o
    where       o.voided = 0
    and         o.encounter_id = _encounterId
    and         o.concept_id = concept_from_mapping(_source, _term)
    and 		o.value_coded = concept_from_mapping(_source1, _term1)
    order by    o.date_created desc, o.obs_id desc
    limit 1;

    RETURN ret;

END

#

-- This function accepts visit_id, mapping source, mapping code
-- It will find a single (latest), best observation that matches this, and return the value_numeric
#
DROP FUNCTION IF EXISTS obs_from_visit_value_numeric;
#
CREATE FUNCTION obs_from_visit_value_numeric(_visitId int(11), _source varchar(50), _term varchar(255))
RETURNS double
DETERMINISTIC

BEGIN

DECLARE ret double;

select      o.value_numeric into ret
from        obs o
inner join encounter e on o.encounter_id = e.encounter_id and e.voided = 0
where       o.voided = 0
and         e.visit_id = _visitId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1;

RETURN ret;

END

#
-- This function accepts visit_id, encounter_type (single or multiple, concatenated together) and a concept source and term
-- it will return the latest encounter in that visit of that type(s) with the specified obs
#
DROP FUNCTION IF EXISTS latestEncInVisitWithObs;
#
CREATE FUNCTION latestEncInVisitWithObs( _visit_id int(11),_encounterTypes varchar(255), _source varchar(50), _term varchar(255))
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      enc.encounter_id into enc_id_out
    from        encounter enc inner join encounter_type et on enc.encounter_type = et.encounter_type_id
    inner join obs o on o.encounter_id = enc.encounter_id and o.voided = 0
    where       enc.voided = 0
      and       find_in_set(et.name, _encounterTypes)
      and       (enc.visit_id = _visit_id or _visit_id is null)
      and       o.concept_id = concept_from_mapping(_source, _term)
    order by    enc.encounter_datetime desc
    limit       1;

    RETURN enc_id_out;

END

#
-- This function accepts the encounter type or uuid
-- it will return the encounter name of that encounter
#
DROP FUNCTION IF EXISTS encounterName;
#
CREATE FUNCTION encounterName(_type_or_uuid varchar(255) )
    RETURNS varchar(255)
    DETERMINISTIC

BEGIN

  DECLARE enc_name_out varchar(255);

  select et.name into enc_name_out
  from encounter_type et
  where et.retired = 0
  and (et.encounter_type_id = _type_or_uuid or et.uuid = _type_or_uuid)
  ;

  RETURN enc_name_out;

END
#

-- This function accepts drug name or drug uuid
-- It will return the drug_id of that drug
#
DROP FUNCTION IF EXISTS drugId;
#
CREATE FUNCTION drugId(_name_or_uuid varchar(255))
    RETURNS int(11)
    DETERMINISTIC

BEGIN

  DECLARE drug_id_out int(11);

  select drug_id into drug_id_out
  from drug
  where retired = 0
  and (name = _name_or_uuid or uuid = _name_or_uuid)
  ;

  RETURN drug_id_out;

END


#
-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the value_numeric entry of the latest obs that matches this
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_numeric;
#
CREATE FUNCTION obs_from_group_id_value_numeric(_obsGroupId int(11), _source varchar(50), _term varchar(255))
    RETURNS double
    DETERMINISTIC

BEGIN

    DECLARE ret double;

    select      value_numeric into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term)
      order by obs_datetime desc limit 1;

    RETURN ret;

END

#
-- This function accepts encounter_id and drug_id
-- It will find the obs_id of the latest observation with the drug_id as an answer
#
DROP FUNCTION IF EXISTS obs_id_with_drug_answer;
#
CREATE FUNCTION obs_id_with_drug_answer(_encounter_id int(11), _drug_id int(11))
    RETURNS int
    DETERMINISTIC

BEGIN

    DECLARE ret_obs_id int;

    select      obs_id into ret_obs_id
    from        obs o
    where       o.voided = 0
      and       o.encounter_id = _encounter_id
      and       o.value_drug = _drug_id
      order by obs_datetime desc limit 1;

    RETURN ret_obs_id;

END
#
-- this following accepts encounter_id and drug_id
-- it will return the obs_group_id of the latest observation in that encounter with that drug as an answer, if it exists  
#
DROP FUNCTION IF EXISTS obs_group_id_with_drug_answer;
#
CREATE FUNCTION obs_group_id_with_drug_answer(_encounter_id int(11), _drug_id int(11))
    RETURNS int
    DETERMINISTIC

BEGIN

    DECLARE ret_obs_group_id int;

    select      obs_group_id into ret_obs_group_id
    from        obs o
    where       o.voided = 0
      and       o.encounter_id = _encounter_id
      and       o.value_drug = _drug_id
      order by obs_datetime desc limit 1;

    RETURN ret_obs_group_id;

END
#
-- This function accepts obs_id
-- It will find the obs_group_id of that observation, if there is one
#
DROP FUNCTION IF EXISTS obs_group_id_from_obs;
#
CREATE FUNCTION obs_group_id_from_obs(_obs_id int(11))
    RETURNS int
    DETERMINISTIC

BEGIN

    DECLARE ret_obs_group_id int;

    select      obs_group_id into ret_obs_group_id
    from        obs o
    where       o.voided = 0
      and       o.obs_id = _obs_id;

    RETURN ret_obs_group_id;

END
#
-- This function accepts visit_id, source and term for a concept, offset and locale
-- It will find the value coded of the obs answer with that concept, in the specified based on the offset given
#
DROP FUNCTION IF EXISTS obs_from_visit_value_coded;
#
CREATE FUNCTION obs_from_visit_value_coded(_visitId int(11), _source varchar(50), _term varchar(255), _offset_value int, _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      concept_name(o.value_coded, _locale) into ret
    from        obs o
    inner join encounter e on o.encounter_id = e.encounter_id and e.voided = 0
    where       o.voided = 0
      and       e.visit_id = _visitId
      and       o.concept_id = concept_from_mapping(_source, _term)
      order by o.obs_datetime
      limit 1
      offset _offset_value;

    RETURN ret;

END
#

#
DROP FUNCTION IF EXISTS retrieveConceptMapping;
#
CREATE FUNCTION retrieveConceptMapping(
    _concept_id int,
    _mapping_source varchar(50)
)
	RETURNS varchar(255)
    DETERMINISTIC

BEGIN
    DECLARE mapping varchar(255);


    select  group_concat(distinct crt.code separator ' | ')into mapping
    from concept_reference_term crt
    inner join concept_reference_map crm on crm.concept_reference_term_id = crt.concept_reference_term_id
    inner join concept_reference_source crs on crt.concept_source_id = crs.concept_source_id and crs.retired = 0
    inner join concept_map_type cmt on cmt.concept_map_type_id = crm.concept_map_type_id
      and cmt.uuid = '35543629-7d8c-11e1-909d-c80aa9edcf4e' -- limit mappings to 'SAME-AS'
    where  crt.retired = 0
    and crs.name = _mapping_source
    and crm.concept_id = _concept_id;

    RETURN mapping;

END
#
-- The following function accepts concept_id of a diagnosis
-- it returns a single ICD10 code that matches best
-- it will always return a "SAME-AS" mapping if it exists 
#
DROP FUNCTION IF EXISTS retrieveICD10;
#
CREATE FUNCTION retrieveICD10 (
    _concept_id int
)
	RETURNS varchar(255)
    DETERMINISTIC

BEGIN
    DECLARE mapping varchar(255);

   select  crt.code into mapping
    from concept_reference_term crt
    inner join concept_reference_map crm on crm.concept_reference_term_id = crt.concept_reference_term_id
    inner join concept_reference_source crs on crt.concept_source_id = crs.concept_source_id and crs.retired = 0
    inner join concept_map_type cmt on cmt.concept_map_type_id = crm.concept_map_type_id
   where  crt.retired = 0
    and crs.name = 'ICD-10-WHO'
    and crm.concept_id = _concept_id
    order by if(cmt.uuid = '35543629-7d8c-11e1-909d-c80aa9edcf4e',0,1) asc  -- always sort "SAME AS" mappings first
    limit 1;

    RETURN mapping;

END
#
/*
  Location name
*/
#
DROP FUNCTION IF EXISTS location_name;
#
CREATE FUNCTION location_name (
    _location_id int
)
    RETURNS TEXT
    DETERMINISTIC
BEGIN
    DECLARE locName TEXT;

    select      name into locName
    from        location
    where       location_id = _location_id;

    RETURN locName;
END
#
-- this function accepts and encounter_id and mappings of a question and coded answer of an observation
-- it will return the obs_group_id of that observation				     
#				
DROP FUNCTION IF EXISTS obs_group_id_of_value_coded;
#
CREATE FUNCTION obs_group_id_of_value_coded(_encounterId int(11), _source varchar(50), _term varchar(255), _source1 varchar(50), _term1 varchar(255))
RETURNS int(11)
DETERMINISTIC

BEGIN

DECLARE ret int(11);

select      obs_group_id into ret FROM
(
select      obs_group_id
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
and         o.value_coded = concept_from_mapping(_source1, _term1)
order by    o.date_created desc, o.obs_id desc
limit 1
) obs_group_id_of_value_coded;

RETURN ret;

END
#
-- this function accepts drug_id or uuid of a drug
-- it will return the drug name
#
DROP FUNCTION IF EXISTS drugName;
#
CREATE FUNCTION drugName(_id_or_uuid varchar(255))
    RETURNS varchar(255)
    DETERMINISTIC

BEGIN

  DECLARE drug_name_out varchar(255);

  select name into drug_name_out
  from drug
  where retired = 0
  and (drug_id = _id_or_uuid or uuid = _id_or_uuid)
  ;

  RETURN drug_name_out;

END
#
-- This function accepts an Obu Group Id and source and term of a concept
-- it will return the drug name of the value_drug that answers that question
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_drug;
#
CREATE FUNCTION obs_from_group_id_value_drug(_obsGroupId int(11), _source varchar(50), _term varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct drugName(o.value_drug) separator ' | ') into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END
#
-- This function accepts an encounter_id, and source and term of a coded answer
-- it will return the obs group id of the group that contains that answer (most recent one)
#
DROP FUNCTION IF EXISTS obs_group_id_of_coded_answer;
#
CREATE FUNCTION obs_group_id_of_coded_answer(_encounterId int(11), _source varchar(50), _term varchar(255))

	RETURNS int
    DETERMINISTIC

BEGIN
   DECLARE obs_group_id_out int(11);

 select obs_group_id into obs_group_id_out
    from obs o
    where o.voided = 0
    and o.encounter_id = _encounterId
    and o.value_coded = concept_from_mapping(_source, _term)
 order by o.obs_datetime desc
    limit 1;

    RETURN obs_group_id_out;

END
#
-- This function accepts:
--   encounter_id
--   a list of encounter types
--   begin date (can be null)
--   end date (can be null)
-- and returns the index ascending of the encounter in that set for the patient
#
DROP FUNCTION IF EXISTS encounter_index_asc;
#
CREATE FUNCTION encounter_index_asc(
    _encounter_id int(11),
    _encounterTypes varchar(255),
    _beginDate datetime,
    _endDate datetime
)
	RETURNS int
    DETERMINISTIC

BEGIN

     select count(*) into @total_count
       from encounter e
       inner join encounter_type et on e.encounter_type = et.encounter_type_id
       inner join encounter enc_in on enc_in.encounter_id = _encounter_id
       where e.voided = 0
       and find_in_set(et.name, _encounterTypes)
       and e.patient_id = enc_in.patient_id
       and (_beginDate is null or e.encounter_datetime >= _beginDate)
       and (_endDate is null or e.encounter_datetime <= _beginDate);

     select count(*) into @count_after
       from encounter e
       inner join encounter_type et on e.encounter_type = et.encounter_type_id
       inner join encounter enc_in on enc_in.encounter_id = _encounter_id
       where e.voided = 0
       and find_in_set(et.name, _encounterTypes)
       and e.patient_id = enc_in.patient_id
       and (_beginDate is null or e.encounter_datetime >= _beginDate)
       and (_endDate is null or e.encounter_datetime <= _beginDate)
       and if(e.encounter_datetime=enc_in.encounter_datetime,
            if(e.date_created=enc_in.date_created,e.encounter_id>enc_in.encounter_id,e.date_created>enc_in.date_created),
              e.encounter_datetime>enc_in.encounter_datetime)
       ;

    RETURN @total_count - @count_after;

END
#
-- This function accepts:
--   encounter_id
--   a list of encounter types
--   begin date (can be null)
--   end date (can be null)
-- and returns the index descending of the encounter in that set for the patient
#
DROP FUNCTION IF EXISTS encounter_index_desc;
#
CREATE FUNCTION encounter_index_desc(
    _encounter_id int(11),
    _encounterTypes varchar(255),
    _beginDate datetime,
    _endDate datetime
)
	RETURNS int
    DETERMINISTIC

BEGIN

     select count(*) into @total_count
       from encounter e
       inner join encounter_type et on e.encounter_type = et.encounter_type_id
       inner join encounter enc_in on enc_in.encounter_id = _encounter_id
       where e.voided = 0
       and find_in_set(et.name, _encounterTypes)
       and e.patient_id = enc_in.patient_id
       and (_beginDate is null or e.encounter_datetime >= _beginDate)
       and (_endDate is null or e.encounter_datetime <= _beginDate);

     select count(*) into @count_after
       from encounter e
       inner join encounter_type et on e.encounter_type = et.encounter_type_id
       inner join encounter enc_in on enc_in.encounter_id = _encounter_id
       where e.voided = 0
       and find_in_set(et.name, _encounterTypes)
       and e.patient_id = enc_in.patient_id
       and (_beginDate is null or e.encounter_datetime >= _beginDate)
       and (_endDate is null or e.encounter_datetime <= _beginDate)
       and if(e.encounter_datetime=enc_in.encounter_datetime,
            if(e.date_created=enc_in.date_created,e.encounter_id<enc_in.encounter_id,e.date_created<enc_in.date_created),
              e.encounter_datetime<enc_in.encounter_datetime)
       ;

    RETURN @total_count - @count_after;

END
#
-- This function acceps patient id, a list of encounter types, visit id, form id and a begin date
-- it will return the latest encounter for that patient, of one of those encounter types, in that visit of that form type since that date
-- form id and begin date can be left null
#
DROP FUNCTION IF EXISTS latestEncForminVisit;
#
CREATE FUNCTION latestEncForminVisit(_patientId int(11), _encounterTypes varchar(255), _visitId int(11), _formId int(11), _beginDate datetime)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

    DECLARE enc_id_out int(11);

    select      encounter_id into enc_id_out
    from        encounter enc inner join encounter_type et on enc.encounter_type = et.encounter_type_id
    where       enc.voided = 0
    and         enc.patient_id = _patientId
    and         enc.visit_id = _visitId
    and         enc.form_id = _formId or _formId is null
    and         find_in_set(et.name, _encounterTypes)
    and         (_beginDate is null or enc.encounter_datetime >= _beginDate)
    order by    enc.encounter_datetime desc
    limit       1;

    RETURN enc_id_out;

END
#
-- this function accepts patient_id
-- it will the phone number of the patient
#												      
DROP FUNCTION IF EXISTS phone_number;
#
CREATE FUNCTION phone_number(
    _patient_id int)
    
    RETURNS VARCHAR(50)
    DETERMINISTIC

BEGIN
    DECLARE  attVal VARCHAR(50);

    select      a.value into attVal
    from        person_attribute a
    where       person_attribute_type_id =
        (select person_attribute_type_id from person_attribute_type where uuid = '14d4f066-15f5-102d-96e4-000c29c2a5d7')
    and         a.voided = 0
    and         a.person_id = _patient_id
    order by    a.date_created desc
    limit       1;

    RETURN attVal;

END
#
-- this function accepts patient_program_id, program_workflow_id and a locale
-- it will return the name of the current state in the given locale if one exists in the given worflow
-- Note that the current state is either is the one that is either still active or the one that was active when the program was closed.
-- this is limited to the latest one to account for the rare case of multiple states in the same workflow
DROP FUNCTION IF EXISTS currentProgramState;
#
CREATE FUNCTION currentProgramState(_patient_program_id int(11), _program_workflow_id int(11), _locale varchar(50))
    RETURNS varchar(255)
    DETERMINISTIC

BEGIN

  DECLARE state_name_out varchar(255);

select concept_name(pws.concept_id, _locale) into state_name_out
from patient_state ps
inner join program_workflow_state pws on ps.state = pws.program_workflow_state_id and program_workflow_id =_program_workflow_id
inner join patient_program pp on pp.voided =0 and pp.patient_program_id = ps.patient_program_id
where ps.patient_program_id = _patient_program_id
and (ps.end_date is null or ps.end_date = pp.date_completed )
order by ps.start_date desc limit 1; 

    RETURN state_name_out;

END
#
-- this function accepts concept_id of a concept and concept_id of a concept set
-- if the concept is in that set, it returns true
-- OR if the concept is in a set that is in that set, it returns true
-- otherwise, false
#
DROP FUNCTION IF EXISTS concept_in_set;
#
CREATE FUNCTION concept_in_set(_concept_id int(11), _concept_set_id int(11))
    RETURNS boolean
    DETERMINISTIC

BEGIN

DECLARE ret boolean;

select if(cs.concept_set_id is null,false,true) into ret from concept_set cs 
where concept_id = _concept_id
and concept_set = _concept_set_id
limit 1;

select if(ret,ret,if(cs.concept_set_id is null,false,true)) into ret from concept_set cs
inner join concept_set cs2 on cs2.concept_id = _concept_id and cs2.concept_set = cs.concept_id 
where cs.concept_set = _concept_set_id
limit 1;

    RETURN ret;

END
#
-- The following diagnosis functions can work together to provide all of the details of diagnoses entered in encounters
-- they each accept encounter_id and offset and will return the details of the nth (based on offset) encounter,
-- ordered by: 
--   primary diagnoses first, then other diagnoses with an order, then diagnoses without an order. obs_id is included as a final sort factor
#
-- The following function accepts encounter_id and offset
-- It will return the obs_group_id of the construct of the nth diagnosis of that encounter (n being the offset)
#
DROP FUNCTION IF EXISTS diagnosis_obs_group_id;
#
CREATE FUNCTION diagnosis_obs_group_id(_encounter_id int(11), _offset int(11)) RETURNS int(11)
    DETERMINISTIC
BEGIN

DECLARE ret int(11);

select ogr.obs_id into ret from obs ogr 
 left outer join obs oo on oo.obs_group_id = ogr.obs_id and oo.concept_id = concept_from_mapping('PIH','7537') and oo.voided = 0
where ogr.encounter_id = _encounter_id
and ogr.concept_id = concept_from_mapping('PIH','7539')
and ogr.voided = 0
order by ISNULL(oo.value_coded) ASC ,LOCATE('7534',retrieveConceptMapping(oo.value_coded,'PIH')) DESC, ogr.obs_id ASC
limit 1
offset _offset;

    RETURN ret;

END
#
-- The following function accepts encounter_id, offset and locale
-- It will return the coded diagnosis name (if exists) in that locale of the nth diagnosis of that encounter (n being the offset)
#
DROP FUNCTION IF EXISTS diagnosis;
#
CREATE FUNCTION diagnosis(_encounter_id int(11), _offset int(11), _locale varchar(50)) RETURNS varchar(255)
    DETERMINISTIC
BEGIN

DECLARE ret varchar(255);

select concept_name(od.value_coded ,_locale) into ret from obs ogr 
 left outer join obs oo on oo.obs_group_id = ogr.obs_id and oo.concept_id = concept_from_mapping('PIH','7537') and oo.voided = 0
 left outer join obs od on od.obs_group_id = ogr.obs_id and od.concept_id = concept_from_mapping('PIH','DIAGNOSIS') and od.voided = 0
where ogr.encounter_id = _encounter_id
and ogr.concept_id = concept_from_mapping('PIH','7539')
and ogr.voided = 0
order by ISNULL(oo.value_coded) ASC ,LOCATE('7534',retrieveConceptMapping(oo.value_coded,'PIH')) DESC, ogr.obs_id ASC
limit 1
offset _offset;

    RETURN ret;

END
#
-- The following function accepts encounter_id, offset and locale
-- It will return the noncoded diagnosis (if exists) of the nth diagnosis of that encounter (n being the offset)
#
DROP FUNCTION IF EXISTS diagnosis_noncoded;
#
CREATE FUNCTION diagnosis_noncoded(_encounter_id int(11), _offset int(11)) RETURNS varchar(255)
    DETERMINISTIC
BEGIN

DECLARE ret varchar(255);

select onc.value_text into ret from obs ogr 
 left outer join obs oo on oo.obs_group_id = ogr.obs_id and oo.concept_id = concept_from_mapping('PIH','7537') and oo.voided = 0
 left outer join obs onc on onc.obs_group_id = ogr.obs_id and onc.concept_id = concept_from_mapping('PIH','7416') and onc.voided = 0
where ogr.encounter_id = _encounter_id
and ogr.concept_id = concept_from_mapping('PIH','7539')
and ogr.voided = 0
order by ISNULL(oo.value_coded) ASC ,LOCATE('7534',retrieveConceptMapping(oo.value_coded,'PIH')) DESC, ogr.obs_id ASC
limit 1
offset _offset;

    RETURN ret;

END
#
-- The following function accepts encounter_id, offset and locale
-- It will return the diagnosis order in that locale of the nth diagnosis of that encounter (n being the offset)
#
DROP FUNCTION IF EXISTS diagnosis_order;
#
CREATE FUNCTION diagnosis_order(_encounter_id int(11), _offset int(11), _locale varchar(50)) RETURNS varchar(255)
    DETERMINISTIC
BEGIN

DECLARE ret varchar(255);

select concept_name(oo.value_coded ,_locale) into ret from obs ogr 
 left outer join obs oo on oo.obs_group_id = ogr.obs_id and oo.concept_id = concept_from_mapping('PIH','7537') and oo.voided = 0
where ogr.encounter_id = _encounter_id
and ogr.concept_id = concept_from_mapping('PIH','7539')
and ogr.voided = 0
order by ISNULL(oo.value_coded) ASC ,LOCATE('7534',retrieveConceptMapping(oo.value_coded,'PIH')) DESC, ogr.obs_id ASC
limit 1
offset _offset;

    RETURN ret;

END
#
-- The following function accepts encounter_id, offset and locale
-- It will return the diagnosis certainty in that locale of the nth diagnosis of that encounter (n being the offset)
#
DROP FUNCTION IF EXISTS diagnosis_certainty;
#
CREATE FUNCTION diagnosis_certainty(_encounter_id int(11), _offset int(11), _locale varchar(50)) RETURNS varchar(255)
    DETERMINISTIC
BEGIN

DECLARE ret varchar(255);

select concept_name(oc.value_coded ,_locale) into ret from obs ogr 
 left outer join obs oo on oo.obs_group_id = ogr.obs_id and oo.concept_id = concept_from_mapping('PIH','7537') and oo.voided = 0
 left outer join obs oc on oc.obs_group_id = ogr.obs_id and oc.concept_id = concept_from_mapping('PIH','1379') and oc.voided = 0
where ogr.encounter_id = _encounter_id
and ogr.concept_id = concept_from_mapping('PIH','7539')
and ogr.voided = 0
order by ISNULL(oo.value_coded) ASC ,LOCATE('7534',retrieveConceptMapping(oo.value_coded,'PIH')) DESC, ogr.obs_id ASC
limit 1
offset _offset;

RETURN ret;

END
#

-- The following function accepts encounter_id
-- It will return the names of the creator of the encounter (names of the data entry clerk)
-- as saved in the encounter table
#
DROP FUNCTION IF EXISTS encounter_creator;
#
CREATE FUNCTION encounter_creator(
    _encounter_id INT
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE creatorName TEXT;

    SELECT CONCAT(given_name, ' ', family_name) creator_names INTO creatorName
    FROM person_name pn
    JOIN users u ON pn.voided = 0 AND u.retired = 0 AND pn.person_id = u.person_id AND pn.preferred = 1
    JOIN encounter e ON e.creator = u.user_id AND e.voided = 0 AND e.encounter_id = _encounter_id;

    RETURN creatorName;

END
#


-- The following function accepts encounter_id
-- It will return the names of the creator of the obs (names of the data entry clerk)
-- as saved in the obs table
#
DROP FUNCTION IF EXISTS obs_creator;
#
CREATE FUNCTION obs_creator(
    _encounter_id INT
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE creatorName TEXT;

    SELECT DISTINCT(CONCAT(given_name, ' ', family_name)) creator_names INTO creatorName
    FROM person_name pn
    JOIN users u ON pn.voided = 0 AND u.retired = 0 AND pn.person_id = u.person_id AND pn.preferred = 1
    JOIN obs o ON o.creator = u.user_id AND o.voided = 0 AND o.encounter_id = _encounter_id;

    RETURN creatorName;

END
#

-- The following function accepts encounter_id
-- It will return the names of the encounter_type
#
DROP FUNCTION IF EXISTS encounter_type_name;
#
CREATE FUNCTION encounter_type_name(
    _encounter_id INT
)
    RETURNS TEXT
    DETERMINISTIC

BEGIN
    DECLARE encounterName TEXT;

    SELECT
    et.name INTO encounterName
FROM
    encounter_type et
        JOIN
    encounter e ON et.encounter_type_id = e.encounter_type
        AND e.voided = 0
        AND et.retired = 0 AND e.encounter_id = _encounter_id;

    RETURN encounterName;

END
#
/* 
This function accepts patient_id, program_id and a date
It will return the patient_program_id of that patient's enrollment into that program on that date
In case of duplicates it is limited to the latest, based on date enrolled, date created
*/
#
DROP FUNCTION IF EXISTS patientProgramId;
#
CREATE FUNCTION patientProgramId(_patient_id int(11), _program_id int(11), _program_date date)
    RETURNS int(11)
    DETERMINISTIC

BEGIN

  DECLARE ret int(11);

select pp.patient_program_id into ret from patient_program pp
	where pp.patient_id = _patient_id
	and pp.program_id = _program_id
	and (pp.date_enrolled <= _program_date and (_program_date <= pp.date_completed or pp.date_completed is null))
	and pp.voided = 0
order by pp.date_enrolled desc, pp.date_created desc limit 1;

  RETURN ret;

END
#
/* 
This accepts a patient_program_id and returns the location_id for that enrollment
*/
#
DROP FUNCTION IF EXISTS programLocationId;
#
CREATE FUNCTION programLocationId(_patient_program_id int(11))
    RETURNS int(11)
    DETERMINISTIC

BEGIN

  DECLARE ret int(11);

select pp.location_id into ret from patient_program pp 
where pp.patient_program_id = _patient_program_id;
  RETURN ret;

END
#
-- this function accepts a patient_program_id for an enrollment and a state ID
-- it will return the most recent patient_state_id for that state within the program enrollment
#
DROP FUNCTION IF EXISTS mostRecentPatientStateId;
#
CREATE FUNCTION mostRecentPatientStateId(_patient_program_id int(11), _state int(11))
    RETURNS int(11)
    DETERMINISTIC

BEGIN

  DECLARE ret int(11);

select patient_state_id into ret from patient_state ps
	where ps.patient_program_id = _patient_program_id
	and ps.state =  _state
	and ps.voided = 0
	order by ps.start_date desc limit 1;

  RETURN ret;

END
#
-- this function accepts a patient_id and a program ID
-- it will return the patient_program_id of the most recent program enrollment for that patient and program
#
DROP FUNCTION IF EXISTS mostRecentPatientProgramId;
#
CREATE FUNCTION mostRecentPatientProgramId(_patient_id int(11), _program_id int(11))
    RETURNS int(11)
    DETERMINISTIC

BEGIN

  DECLARE ret int(11);

select patient_program_id into ret from patient_program pp
	where pp.patient_id = _patient_id
	and pp.program_id = _program_id
	and pp.voided = 0
	order by pp.date_enrolled desc limit 1;

  RETURN ret;

END
#
-- this function accepts a patient_program_id for a patient program enrollment
-- it will return the enrollment date of that program
#
DROP FUNCTION IF EXISTS programStartDate;
#
CREATE FUNCTION programStartDate(_patient_program_id int)
    RETURNS datetime
    DETERMINISTIC

BEGIN

  DECLARE ret datetime;

select date_enrolled into ret from patient_program pp
	where pp.patient_program_id = _patient_program_id;
	
  RETURN ret;

END
#
-- this function accepts a patient_state_id for a patient state in program enrollment
-- it will return the start date of that state
#
DROP FUNCTION IF EXISTS patientStateStartDate;
#
CREATE FUNCTION patientStateStartDate(_patient_state_id int(11))
    RETURNS datetime
    DETERMINISTIC

BEGIN

  DECLARE ret datetime;

select start_date into ret from patient_state ps
	where ps.patient_state_id = _patient_state_id;
	
  RETURN ret;
  
END
#
/* 
This function accepts an encounter_id and returns a location id
For the HIV system, since there are many encounters migrated in with "unknown location",
This function will return the encounter location unless it is unknown location, 
in which case, it will return the program enrollment location at the time of the encounter  
*/
#
DROP FUNCTION IF EXISTS hivEncounterLocationId;
#
CREATE FUNCTION hivEncounterLocationId(_encounterId int(11))
    RETURNS int(11)
    DETERMINISTIC

BEGIN

  DECLARE ret int(11);

select location_id into @unknownLocationId from location l where uuid = '8d6c993e-c2cc-11de-8d13-0010c6dffd0f';
select program_id into @hivProgramId from program where uuid = 'b1cb1fc1-5190-4f7a-af08-48870975dafc';

select if(e.location_id = @unknownLocationId, 
	ifnull(programLocationId(patientProgramId(e.patient_id,@hivProgramId,e.encounter_datetime)),@unknownLocationId),
	e.location_id)
into ret
from encounter e
where encounter_id = _encounterId
;
 RETURN ret;
END
#
/* 
The following accepts a patient id and source and term of a concept to identify order reason 
It will return the date of that patient started on that order reason
*/
#
DROP FUNCTION IF EXISTS OrderReasonStartDate;
#
CREATE FUNCTION OrderReasonStartDate(_patient_id int(11), _order_reason_source varchar(50), _order_reason_term varchar(255))
    RETURNS datetime
    DETERMINISTIC

BEGIN

  DECLARE ret datetime;


select min(ifnull(o.scheduled_date, o.date_activated)) into ret
from orders o
where o.patient_id  = _patient_id
and o.order_reason = concept_from_mapping(_order_reason_source,_order_reason_term)
and voided = 0
;

  RETURN ret;

END
#
/*
 this function accepts patient_id, drug_source and drug_term
 it will return the start date of the drug of that concept
 */
#
DROP FUNCTION IF EXISTS DrugConceptStartDate;
#
CREATE FUNCTION DrugConceptStartDate(_patient_id int(11), _drug_source varchar(50), _drug_term varchar(255))
    RETURNS datetime
    DETERMINISTIC

BEGIN

  DECLARE ret datetime;


select min(ifnull(o.scheduled_date, o.date_activated)) into ret
from orders o
where o.patient_id  = _patient_id
and o.concept_id = concept_from_mapping(_drug_source,_drug_term)
and voided = 0
;

  RETURN ret;

END
#
/* 
The following accepts a patient id, source and term of a concept to identify a drug concept 
It will return the start date of that drug
*/
#
DROP FUNCTION IF EXISTS DrugConceptStartDate;
#
CREATE FUNCTION DrugConceptStartDate(_patient_id int(11), _drug_source varchar(50), _drug_term varchar(255))
    RETURNS datetime
    DETERMINISTIC

BEGIN

  DECLARE ret datetime;


select min(ifnull(o.scheduled_date, o.date_activated)) into ret
from orders o
where o.patient_id  = _patient_id
and o.concept_id = concept_from_mapping(_drug_source,_drug_term)
and voided = 0
;

  RETURN ret;

END
#
/* 
The following accepts a patient id, source and term of a concept to identify order reason and a locale 
It will return a list of the concept names of the active drugs for that order reason
*/
#
DROP FUNCTION IF EXISTS ActiveDrugConceptNameList;
#
CREATE FUNCTION ActiveDrugConceptNameList(_patient_id int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC
    
BEGIN

  DECLARE ret text;    

select group_concat(concept_name(concept_id ,_locale )) into ret
from orders o
where o.patient_id = _patient_id 
and o.order_reason = concept_from_mapping(_source,_term)
and o.date_stopped is null
and o.voided = 0
group by patient_id;

return ret;

END
#
/*
 get boolean indicating if a given component is enabled
*/
#
/*
 this function accepts a concept id and returns the concept class id of that concept
*/
#
DROP FUNCTION IF EXISTS concept_class_id;
#
CREATE FUNCTION concept_class_id(
    _concept_id int(11)
)
	RETURNS INT(11)
    DETERMINISTIC

BEGIN
    DECLARE ret INT(11);

	SELECT  class_id INTO ret
	FROM    concept where concept_id = _concept_id;

    RETURN ret;
END
#
DROP FUNCTION IF EXISTS is_component_enabled;
#
CREATE FUNCTION is_component_enabled(
    _component varchar(255)
)
    RETURNS BOOLEAN
    DETERMINISTIC
BEGIN
    DECLARE ret BOOLEAN;
    SELECT if(lower(trim(global_property_value(concat('pihcore.component.', _component), ''))) = 'true', TRUE, FALSE) into ret;
    RETURN ret;
END
#

/*
 this function accepts patient_id and program_id and return the initial program location name
*/
DROP FUNCTION IF EXISTS initialProgramLocation;
#
CREATE FUNCTION initialProgramLocation(_patient_id INT, _program_id INT)
	RETURNS VARCHAR(255)
    DETERMINISTIC

BEGIN
	DECLARE initialProgramLocationName VARCHAR(255);

    SELECT LOCATION_NAME(location_id) INTO initialProgramLocationName FROM patient_program
    WHERE patient_id = _patient_id
    AND program_id = _program_id
    AND voided = 0
    ORDER BY date_enrolled ASC, IFNULL(date_completed,'9999-12-31') ASC LIMIT 1;

    RETURN initialProgramLocationName;

END
#

/*
 this function accepts patient_id and program_id and return the latest program location name
*/
DROP FUNCTION IF EXISTS currentProgramLocation;
#
CREATE FUNCTION currentProgramLocation(_patient_id INT, _program_id INT)
	RETURNS VARCHAR(255)
    DETERMINISTIC

BEGIN
	DECLARE currentProgramLocationName VARCHAR(255);

    SELECT LOCATION_NAME(location_id) INTO currentProgramLocationName FROM patient_program
    WHERE patient_id = _patient_id
    AND program_id = _program_id
    AND voided = 0
    ORDER BY date_enrolled DESC, IFNULL(date_completed,'9999-12-31') DESC LIMIT 1;

    RETURN currentProgramLocationName;

END
#

-- The following function accepts user_id and returns the username or system_id if username is null
#
DROP FUNCTION IF EXISTS username;
#
CREATE FUNCTION username(
    _user_id INT
)
    RETURNS VARCHAR(50)
    DETERMINISTIC

BEGIN
    DECLARE ret VARCHAR(50);
    SELECT IFNULL(username, system_id) into ret from users where user_id = _user_id;
    RETURN ret;
END
#
/*
This function accepts a patient id, source & code of a concept
It will return the obs_id of the single latest obs recorded for that concept from temp_obs table
*/
#
DROP FUNCTION IF EXISTS latest_obs_from_temp;
#
CREATE FUNCTION latest_obs_from_temp(_patient_id int(11), _source varchar(50), _term varchar(255))
    RETURNS int
    DETERMINISTIC

BEGIN

    DECLARE ret int(11);

    select      o.obs_id into ret
    from        temp_obs o
    where       o.voided = 0
		and o.person_id = _patient_id    		
      	and       o.concept_id = concept_from_mapping(_source, _term)
    order by obs_datetime desc limit 1 ;

    RETURN ret;
    
END    
#
-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_text
-- from the temporary table temp_obs
#
DROP FUNCTION IF EXISTS obs_value_text_from_temp;
#
CREATE FUNCTION obs_value_text_from_temp(_encounterId int(11), _source varchar(50), _term varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      o.value_text into ret
    from        temp_obs o
    where       o.voided = 0
    and         o.encounter_id = _encounterId
    and         o.concept_id = concept_from_mapping(_source, _term)
    order by    o.date_created desc, o.obs_id desc
    limit 1;

    RETURN ret;

END
#
/*  
This function accepts an obs_id 
It will return the value coded of that obs, translated into a boolean
from the temporary table temp_obs
*/    
#
DROP FUNCTION IF EXISTS value_coded_as_boolean_from_temp;
#
CREATE FUNCTION value_coded_as_boolean_from_temp(_obs_id int(11))
    RETURNS boolean
    DETERMINISTIC

BEGIN

    DECLARE ret boolean;

    select CASE o.value_coded
		WHEN concept_from_mapping('PIH','YES') then 1
		WHEN concept_from_mapping('PIH','NO') then 0
	END into ret
	from        temp_obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
-- This function accepts encounter_id, mapping source, mapping code
-- It will find the obs_id of the matching observation
-- from the temporary table temp_obs
#
DROP FUNCTION IF EXISTS obs_id_from_temp;
#
CREATE FUNCTION obs_id_from_temp(_encounterId int(11), _source varchar(50), _term varchar(255), _offset_value int)
RETURNS int
DETERMINISTIC

BEGIN

DECLARE ret int;

select      o.obs_id into ret
from        temp_obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1
offset _offset_value
;

RETURN ret;

END
#
-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_datetime
-- from the temporary table temp_obs
#
DROP FUNCTION IF EXISTS obs_value_datetime_from_temp;
#
CREATE FUNCTION obs_value_datetime_from_temp(_encounterId int(11), _source varchar(50), _term varchar(255))
RETURNS datetime
DETERMINISTIC

BEGIN

DECLARE ret datetime;

select      o.value_datetime into ret
from        temp_obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1;

RETURN ret;

END
#
-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the concept name
-- from the temporary table temp_obs
#
DROP FUNCTION IF EXISTS obs_value_coded_list_from_temp;
#
CREATE FUNCTION obs_value_coded_list_from_temp(_encounterId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        temp_obs o
    where       o.voided = 0
      and       o.encounter_id = _encounterId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END
#
-- This function accepts encounter_id, mapping source, mapping code (for both the concept_id and value_coded) and returns
-- "yes" (in the default locale of the implementation) if the obs_id exists and
-- null if the obs_id does not exisit
-- This function is used on questions that also act as answers (i.e you either check it as true or your don't)
-- this function runs against the temp_obs table
#
DROP FUNCTION IF EXISTS obs_single_value_coded_from_temp;
#
CREATE FUNCTION obs_single_value_coded_from_temp(_encounterId int(11), _source varchar(50), _term varchar(255), _source1 varchar(50), _term1 varchar(255))
RETURNS varchar(11)
DETERMINISTIC

BEGIN

DECLARE ret varchar(11);

select      IFNULL(NULL, concept_name(concept_from_mapping('PIH','YES'), global_property_value('default_locale', 'en'))) into ret FROM
(
select      obs_id
from        temp_obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
and         o.value_coded = concept_from_mapping(_source1, _term1)
order by    o.date_created desc, o.obs_id desc
limit 1
) obs_single_question_answer;

RETURN ret;

END
#
-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the comments entry that matches this from the temp_obs table
#
DROP FUNCTION IF EXISTS obs_from_group_id_comment_from_temp;
#
CREATE FUNCTION obs_from_group_id_comment_from_temp(_obsGroupId int(11), _source varchar(50), _term varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      comments into ret
    from        temp_obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END
#
-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the value_datetime entry that matches this from the temp_obs_
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_datetime_from_temp;
#
CREATE FUNCTION obs_from_group_id_value_datetime_from_temp(_obsGroupId int(11), _source varchar(50), _term varchar(255))
    RETURNS datetime
    DETERMINISTIC

BEGIN

    DECLARE ret datetime;

    select      value_datetime into ret
    from        temp_obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END
#
-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the comment
-- this function runs against the temp_obs table
#
DROP FUNCTION IF EXISTS obs_comments_from_temp;
#
CREATE FUNCTION obs_comments_from_temp(_encounterId int(11), _source varchar(50), _term varchar(255), _source1 varchar(50), _term1 varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      o.comments into ret
    from        temp_obs o
    where       o.voided = 0
    and         o.encounter_id = _encounterId
    and         o.concept_id = concept_from_mapping(_source, _term)
    and 		o.value_coded = concept_from_mapping(_source1, _term1)
    order by    o.date_created desc, o.obs_id desc
    limit 1;

    RETURN ret;

END
#
-- This function accepts obs_group_id, mapping source, mapping code
-- It will find the value_coded entries that match this, separated by |
-- this function runs against the temp_obs table
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_coded_list_from_temp;
#
CREATE FUNCTION obs_from_group_id_value_coded_list_from_temp(_obsGroupId int(11), _source varchar(50), _term varchar(255), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        temp_obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = concept_from_mapping(_source, _term);

    RETURN ret;

END
#
-- This function accepts encounter_id, mapping source, mapping code
-- It will find a single, best observation that matches this, and return the value_numeric
-- this function runs against the temp_obs table
#
DROP FUNCTION IF EXISTS obs_value_numeric_from_temp;
#
CREATE FUNCTION obs_value_numeric_from_temp(_encounterId int(11), _source varchar(50), _term varchar(255))
RETURNS double
DETERMINISTIC

BEGIN

DECLARE ret double;

select      o.value_numeric into ret
from        temp_obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
order by    o.date_created desc, o.obs_id desc
limit 1;

RETURN ret;

END
#
/*  
This function accepts an obs_id and a locale
It will return the concept name of that obs, in that locale from the temp_obs table
*/    
DROP FUNCTION IF EXISTS value_coded_name_from_temp;
#
CREATE FUNCTION value_coded_name_from_temp(_obs_id int(11),  _locale varchar(50))
    RETURNS varchar(255)
    DETERMINISTIC

BEGIN

    DECLARE ret varchar(255);

    select      concept_name(o.value_coded,@locale) into ret
    from        temp_obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*  
This function accepts an obs_id
It will return the value_text of that obs from temp_obs table
*/  
#
DROP FUNCTION IF EXISTS value_text_from_temp;
#
CREATE FUNCTION value_text_from_temp(_obs_id int(11))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      value_text into ret
    from        temp_obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*  
This function accepts an obs_id
It will return the value_numeric of that obs from the table temp_obs
*/    
DROP FUNCTION IF EXISTS value_numeric_from_temp;
#
CREATE FUNCTION value_numeric_from_temp(_obs_id int(11))
    RETURNS double
    DETERMINISTIC

BEGIN

    DECLARE ret double;

    select      value_numeric into ret
    from        obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*  
This function accepts an obs_id
It will return the value_datetime of that obs from the table temp_obs
*/    
DROP FUNCTION IF EXISTS value_datetime_from_temp;
#
CREATE FUNCTION value_datetime_from_temp(_obs_id int(11))
    RETURNS datetime
    DETERMINISTIC

BEGIN

    DECLARE ret datetime;

    select      value_datetime into ret
    from        obs o
    where       o.obs_id = _obs_id;

    RETURN ret;

END
#
/*
This function accepts a patient id, source & code of a question concept and source &code of an answer concept
It will return a boolean set to 1 if that question and answer has EVER been recorded for a patient since the datetime passed in.
Null can be passed in as the datetime if it is to be disregarded.
it looks at the temp_obs table created within a script for this
*/
#
DROP FUNCTION IF EXISTS answerEverExists_from_temp;
#
CREATE FUNCTION answerEverExists_from_temp(_patient_id int(11), _source_question varchar(50), _term_question varchar(255), _source_answer varchar(50), _term_answer varchar(255), _begin_datetime datetime)
    RETURNS boolean
    DETERMINISTIC

BEGIN

  DECLARE ret boolean;


select if(obs_id is null,0,1) into ret
from temp_obs o where o.voided =0 
	and o.person_id = _patient_id
	and o.concept_id = concept_from_mapping(_source_question,_term_question)
	and o.value_coded  = concept_from_mapping(_source_answer,_term_answer)
	and (o.obs_datetime >= _begin_datetime or _begin_datetime is null)
	limit 1;

    RETURN ret;

END
#
-- This function accepts a patient_id and concept_id
--  will return the obs_id of the most recent observation by that patient of the concept
-- 	described  by concept_id, from the temp_obs table
#
DROP FUNCTION IF EXISTS latest_obs_from_temp_from_concept_id;
#
CREATE FUNCTION latest_obs_from_temp_from_concept_id(_patient_id int(11), _concept_id int(11))
    RETURNS int
    DETERMINISTIC

BEGIN

    DECLARE ret int(11);

    select      o.obs_id into ret
    from        temp_obs o
    where       o.voided = 0
		and o.person_id = _patient_id    		
      	and       o.concept_id = _concept_id
    order by obs_datetime desc limit 1 ;

    RETURN ret;
    
END
#

-- This function accepts a table name and returns true if the table exists in the current database
DROP FUNCTION IF EXISTS table_exists;
#
CREATE FUNCTION table_exists(_table_name varchar(25))
    RETURNS boolean
    DETERMINISTIC
BEGIN
    DECLARE ret boolean;

    SELECT  if(count(*) > 0, true, false) into ret
    FROM    information_schema.tables
    WHERE   table_schema = database()
    AND     table_name = _table_name;

    RETURN ret;
END
#

-- This function accepts a user_id and returns the most recent login date
DROP FUNCTION IF EXISTS user_latest_login;
#
CREATE FUNCTION user_latest_login(_user_id int(11))
    RETURNS datetime
    DETERMINISTIC
BEGIN
    DECLARE ret datetime;
    IF (table_exists('authentication_event_log')) THEN
        SELECT  max(event_datetime) into ret
        FROM    authentication_event_log
        WHERE   user_id = _user_id
        AND     event_type = 'LOGIN_SUCCEEDED';
    ELSE
        SET ret = null;
    END IF;
    RETURN ret;
END
#

-- This function accepts a user_id and returns the total number of logins recorded
DROP FUNCTION IF EXISTS user_num_logins;
#
CREATE FUNCTION user_num_logins(_user_id int(11))
    RETURNS int
    DETERMINISTIC
BEGIN
    DECLARE ret int;
    IF (table_exists('authentication_event_log')) THEN
        SELECT  count(*) into ret
        FROM    authentication_event_log
        WHERE   user_id = _user_id
        AND     event_type = 'LOGIN_SUCCEEDED';
    ELSE
        SET ret = 0;
    END IF;
    RETURN ret;
END
#
-- The following function accepts drug_id and returns the correponding OpenBoxes product code
#
DROP FUNCTION IF EXISTS openboxesCode;
#
CREATE FUNCTION openboxesCode (
    _drug_id int
)
    RETURNS varchar(255)
    DETERMINISTIC

BEGIN
    DECLARE mapping varchar(255);

    select  crt.code into mapping
    from concept_reference_term crt
             inner join drug_reference_map drm on drm.term_id = crt.concept_reference_term_id
             inner join concept_reference_source crs on crt.concept_source_id = crs.concept_source_id and crs.name = 'OpenBoxes'
             inner join concept_map_type cmt on cmt.concept_map_type_id = drm.concept_map_type and cmt.name = 'SAME-AS'
    where  crt.retired = 0
      and  drm.drug_id = _drug_id
    limit 1;

    RETURN mapping;

END
#
-- this function accepts encounter id and mapping source, and returns a boolean to -- indicate if a mapping exists or not in the answer
#
DROP FUNCTION IF EXISTS answer_exists_in_encounter;
#
CREATE FUNCTION answer_exists_in_encounter(_encounterId int(11), _source varchar(50), _term varchar(255), _source1 varchar(50), _term1 varchar(255))
RETURNS boolean
DETERMINISTIC

BEGIN

DECLARE ret boolean;

select      CASE WHEN count(*) = 0 THEN FALSE ELSE TRUE END into ret FROM
(
select      obs_id
from        obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = concept_from_mapping(_source, _term)
and         o.value_coded = concept_from_mapping(_source1, _term1)
order by    o.date_created desc, o.obs_id desc
limit 1
) obs_single_question_answer;

RETURN ret;

END
#

-- This function accepts obs group Id, and a mpping source, and returns the coded answer
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_coded;
#
CREATE FUNCTION obs_from_group_id_value_coded(_obsGroupId int(11), _source varchar(50), _term varchar(255), _locale varchar(255))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      concept_name(o.value_coded, _locale) into ret
    from        obs o
    where       o.voided = 0
    and       o.obs_group_id= _obsGroupId
    and       o.concept_id = concept_from_mapping(_source, _term)
    order by    o.date_created desc, o.obs_id desc
	limit 1;

    RETURN ret;

END
#