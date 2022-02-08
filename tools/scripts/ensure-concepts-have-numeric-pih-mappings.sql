-- This is a SQL script that will ensure that all concepts have a corresponding
-- numeric PIH mapping equal to the concept ID. It should only ever be run on
-- the PIH Concepts Server, concepts.pih-emr.org.

insert into concept_reference_term (concept_source_id, code, creator, date_created, uuid)
select 5, concept_id, 1, now(), uuid() from concept
where retired = 0
  and concept_id not in
      (
          select c.concept_id
          from concept c, concept_reference_map crm,
               concept_reference_term crt, concept_map_type cmt
          where c.concept_id = crm.concept_id
            and crt.concept_source_id = 5
            and crt.code REGEXP '^[0-9]*$'
            and crm.concept_reference_term_id = crt.concept_reference_term_id
            and crm.concept_map_type_id = cmt.concept_map_type_id
            and cmt.name like 'SAME-AS'
      );
insert into concept_reference_map (concept_id, concept_reference_term_id, concept_map_type_id, creator, date_created, uuid)
select concept_id, concept_reference_term_id, 1, 1, now(), uuid() from
(select c.concept_id, crt.concept_reference_term_id from concept c
join concept_reference_term crt on c.concept_id = crt.code and crt.concept_source_id = 5 and crt.retired = 0
where c.retired = 0
  and concept_id not in
      (
          select c.concept_id
          from concept c, concept_reference_map crm,
               concept_reference_term crt, concept_map_type cmt
          where c.concept_id = crm.concept_id
            and crt.concept_source_id = 5
            and crt.code REGEXP '^[0-9]*$'
            and crm.concept_reference_term_id = crt.concept_reference_term_id
            and crm.concept_map_type_id = cmt.concept_map_type_id
            and cmt.name like 'SAME-AS'
      )) cc;