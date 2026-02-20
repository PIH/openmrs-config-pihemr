drop temporary table if exists tmp_mappings_to_cleanup;

create temporary table tmp_mappings_to_cleanup
as
select map.concept_map_id, map.concept_id, type.name, term.code
from
    concept_reference_source source
        inner join concept_reference_term term on source.concept_source_id = term.concept_source_id
        inner join concept_reference_map map on term.concept_reference_term_id = map.concept_reference_term_id
        inner join concept_map_type type on map.concept_map_type_id = type.concept_map_type_id
where source.name = 'RxNORM'
  and type.name in ('NARROWER-THAN', 'BROADER-THAN')
;

alter table tmp_mappings_to_cleanup add same_as_map_id int;

update tmp_mappings_to_cleanup c
    inner join (
        select map.concept_map_id, map.concept_id, type.name, term.code
        from
            concept_reference_source source
                inner join concept_reference_term term on source.concept_source_id = term.concept_source_id
                inner join concept_reference_map map on term.concept_reference_term_id = map.concept_reference_term_id
                inner join concept_map_type type on map.concept_map_type_id = type.concept_map_type_id
        where source.name = 'RxNORM'
          and type.name in ('SAME-AS')
    ) s on c.concept_id = s.concept_id and c.code = s.code
set c.same_as_map_id = s.concept_map_id;

delete m from concept_reference_map m
                  inner join tmp_mappings_to_cleanup c on m.concept_map_id = c.concept_map_id
where c.same_as_map_id is not null;

drop temporary table if exists tmp_mappings_to_cleanup;