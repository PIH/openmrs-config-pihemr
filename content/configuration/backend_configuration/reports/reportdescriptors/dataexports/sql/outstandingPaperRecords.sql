SET sql_safe_updates = 0;

drop temporary table if exists temp_paper_records;
create temporary table temp_paper_records
(
    patient_id                  int(11),
    patient_primary_id          varchar(50),
    paper_record_id             varchar(255),
    patient_name                varchar(255),
    patient_address_level_1     varchar(255),
    patient_address_level_2     varchar(255),  
    patient_address_level_3     varchar(255),
    patient_address_level_4     varchar(255),
    patient_address_level_5     varchar(255),
    location_name               varchar(255),
    sent_datetime               datetime
);

insert into temp_paper_records 
(
patient_id,
paper_record_id,
location_name,
sent_datetime
)
select
pid.patient_id,
pid.identifier,
location_name(ppr.request_location),
ppr.date_status_changed 
from paperrecord_paper_record_request ppr
inner join paperrecord_paper_record pr on pr.record_id = ppr.paper_record
inner join patient_identifier pid on pid.patient_identifier_id = pr.patient_identifier and pid.voided = 0 
where ppr.status = 'SENT'
;

update temp_paper_records set patient_primary_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_paper_records set patient_name = person_name(patient_id);

update temp_paper_records set patient_address_level_1 = person_address_state_province(patient_id);
update temp_paper_records set patient_address_level_2 = person_address_city_village(patient_id);
update temp_paper_records set patient_address_level_3 = person_address_three(patient_id);
update temp_paper_records set patient_address_level_4 = person_address_one(patient_id);
update temp_paper_records set patient_address_level_5 = person_address_two(patient_id);

select * from temp_paper_records;
