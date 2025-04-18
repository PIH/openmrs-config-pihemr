#
-- This function accepts encounter_id, concept_id for the question and answer
-- It will find a single, best observation that matches this, and return the comment
-- this function runs against the temp_obs table
#
DROP FUNCTION IF EXISTS obs_comments_from_temp_using_concept_id;
#
CREATE FUNCTION obs_comments_from_temp_using_concept_id(_encounterId int(11), _concept_id int(11), _concept_id1 int(11))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      o.comments into ret
    from        temp_obs o
    where       o.voided = 0
    and         o.encounter_id = _encounterId
    and         o.concept_id = _concept_id
    and 		o.value_coded = _concept_id1
    order by    o.date_created desc, o.obs_id desc
    limit 1;

    RETURN ret;

END
#
-- This function accepts encounter_id, concept_id
-- It will find a single, best observation that matches this, and return the value_datetime
-- from the temporary table temp_obs
#
DROP FUNCTION IF EXISTS obs_value_datetime_from_temp_using_concept_id;
#
CREATE FUNCTION obs_value_datetime_from_temp_using_concept_id(_encounterId int(11), _concept_id int(11))
RETURNS datetime
DETERMINISTIC

BEGIN

DECLARE ret datetime;

select      o.value_datetime into ret
from        temp_obs o
where       o.voided = 0
and         o.encounter_id = _encounterId
and         o.concept_id = _concept_id 
order by    o.date_created desc, o.obs_id desc
limit 1;

RETURN ret;

END
#
-- This function accepts obs_group_id, concept_id
-- It will find the value_numeric entry of the latest obs that matches this
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_numeric_using_concept_id;
#
CREATE FUNCTION obs_from_group_id_value_numeric_using_concept_id(_obsGroupId int(11), _concept_id int(11))
    RETURNS double
    DETERMINISTIC

BEGIN

    DECLARE ret double;

    select      value_numeric into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = _concept_id
      order by obs_datetime desc limit 1;

    RETURN ret;

END
#
-- This function accepts obs_group_id, concept_id
-- It will find the value_coded entries that match this, separated by |
#
DROP FUNCTION IF EXISTS obs_from_group_id_value_coded_list_using_concept_id;
#
CREATE FUNCTION obs_from_group_id_value_coded_list_using_concept_id(_obsGroupId int(11), _concept_id int(11), _locale varchar(50))
    RETURNS text
    DETERMINISTIC

BEGIN

    DECLARE ret text;

    select      group_concat(distinct concept_name(o.value_coded, _locale) separator ' | ') into ret
    from        obs o
    where       o.voided = 0
      and       o.obs_group_id= _obsGroupId
      and       o.concept_id = _concept_id;

    RETURN ret;

END
