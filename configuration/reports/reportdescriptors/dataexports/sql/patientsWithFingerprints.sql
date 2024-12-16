CALL initialize_global_metadata();

select
       pat.patient_id,
       zl.identifier as 'ZL ID',
       dos.identifier as Dossier,
       h.identifier as HIVEMR_V1,
       bio.date_created "Last_Fingerprint_Date",
       bio.identifier "Fingerprint_Identifier",
       pa.state_province as Department,
       pa.city_village as Commune,
       pa.address3 as Section,
       pa.address1 as Locality,
       pa.address2 as StreetLandmark,
       ahe_section.user_generated_id as 'Section Communale CDC ID',
       p.birthdate as 'Date de naissance',
       p.birthdate_estimated as 'Date de naissance estimated',
       CAST(CONCAT(timestampdiff(YEAR, p.birthdate, NOW()), '.', MOD(timestampdiff(MONTH, p.birthdate, NOW()), 12) ) as CHAR) as Age,
       p.gender as Sexe
  from patient pat

 inner join person p
    on pat.patient_id = p.person_id
   and p.voided = 0

 left outer join person_address pa
    on pat.patient_id = pa.person_id
   and pa.voided = 0

 left outer join patient_identifier dos
   on pat.patient_id = dos.patient_id
  and identifier_type = @dosId
  and dos.voided = 0


 left outer join patient_identifier zl
   on pat.patient_id = zl.patient_id
  and zl.identifier_type = @zlId
  and zl.voided = 0
  and zl.preferred= 1


 left outer join patient_identifier h
   on pat.patient_id = h.patient_id
  and h.identifier_type = @hivId
  and h.voided = 0

 left outer join patient_identifier bio on bio.patient_identifier_id =
    (select patient_identifier_id from patient_identifier bio2
    where pat.patient_id = bio2.patient_id
    and bio2.identifier_type = @biometricId
    and bio2.voided = 0
    order by bio2.date_created desc limit 1)

LEFT OUTER JOIN address_hierarchy_entry ahe_country on ahe_country.level_id = 1 and ahe_country.name = pa.country
LEFT OUTER JOIN address_hierarchy_entry ahe_dept on ahe_dept.level_id = 2 and ahe_dept.parent_id = ahe_country.address_hierarchy_entry_id and ahe_dept.name = pa.state_province
LEFT OUTER JOIN address_hierarchy_entry ahe_commune on ahe_commune.level_id = 3 and ahe_commune.parent_id = ahe_dept.address_hierarchy_entry_id and ahe_commune.name = pa.city_village
LEFT OUTER JOIN address_hierarchy_entry ahe_section on ahe_section.level_id = 4 and ahe_section.parent_id = ahe_commune.address_hierarchy_entry_id and ahe_section.name = pa.address3

where pat.voided = 0
and bio.date_created is not null
group by p.person_id
;
