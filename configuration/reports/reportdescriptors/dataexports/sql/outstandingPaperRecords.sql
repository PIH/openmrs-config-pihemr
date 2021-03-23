
drop temporary table if exists temp_paper_records;
create temporary table temp_paper_records
(
    patient_id                  int(11),
    patient_primary_id          varchar(50),
    paper_record_id             varchar(255),
    patient_name                varchar(255),
    patient_address             varchar(1000),
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
update temp_paper_records set patient_address = person_address(patient_id);


select * from temp_paper_records;
