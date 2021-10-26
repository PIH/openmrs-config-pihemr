create or replace view report_mapping as
select crm.concept_id, crs.name "source", crt.code
from concept_reference_map crm,
     concept_reference_term crt,
     concept_reference_source crs
where crm.concept_reference_term_id = crt.concept_reference_term_id
  and crt.concept_source_id = crs.concept_source_id
  and crt.retired = 0
  and crs.retired = 0
  and crs.name in ('PIH', 'CIEL');


create or replace view current_name_address as
select p.person_id,
       p.gender,
       p.birthdate,
       p.birthdate_estimated,
       n.given_name,
       n.family_name,
       n.middle_name    "nick_name",
       a.person_address_id,
       a.country,
       a.state_province "department",
       a.city_village   "commune",
       a.address3       "section_communal",
       a.address1       "locality",
       a.address2       "street_landmark"
from person p
         LEFT OUTER JOIN person_name n ON n.person_name_id = (select person_name_id
                                                              from person_name n2
                                                              where n2.person_id = p.person_id
                                                                and n2.voided = 0
                                                              order by n2.preferred desc, n2.date_created desc
                                                              limit 1)
         LEFT OUTER JOIN person_address a ON a.person_address_id = (select person_address_id
                                                                    from person_address a2
                                                                    where a2.person_id = p.person_id
                                                                      and a2.voided = 0
                                                                    order by a2.preferred desc, a2.date_created desc
                                                                    limit 1)
where p.voided = 0;