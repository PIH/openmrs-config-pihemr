-- set @startDate = '2021-03-01';
-- set @endDate = '2021-03-31';

drop temporary table if exists temp_appointments;
create temporary table temp_appointments
(
    appointment_id              int,
    patient_id                  int,
    family_name                 varchar(255),
    given_name                  varchar(255),
    zlemr_id                    varchar(255),
    dossier_number              varchar(255),
    telephone_number            varchar(255),
    start_date                  datetime,
    end_date                    datetime,
    location_id                 int,
    location_name               varchar(255),
    provider_id                 int,
    provider_name               varchar(255),
    service_type                varchar(255),
    reason                      varchar(255),
    cancel_reason               varchar(255),
    status_code                 varchar(255),
    status_name                 varchar(255),
    confidential                boolean
);

insert into temp_appointments
(
            appointment_id,
            patient_id,
            start_date,
            end_date,
            location_id,
            provider_id,
            service_type,
            reason,
            cancel_reason,
            status_code,
            confidential
)
select 	    a.appointment_id,
            a.patient_id,
            ts.start_date,
            ts.end_date,
            b.location_id,
            b.provider_id,
            t.name,
            a.reason,
            a.cancel_reason,
            a.status,
            t.confidential
from 		appointmentscheduling_appointment a
inner join	appointmentscheduling_time_slot ts on a.time_slot_id = ts.time_slot_id
inner join	appointmentscheduling_appointment_block b on ts.appointment_block_id = b.appointment_block_id
inner join	appointmentscheduling_appointment_type t on a.appointment_type_id = t.appointment_type_id
where		date(ts.start_date) <= date(@endDate)
and		    date(ts.end_date) >= date(@startDate)
and         a.voided = 0
;

update temp_appointments set family_name = person_family_name(patient_id);
update temp_appointments set given_name = person_given_name(patient_id);
update temp_appointments set zlemr_id = zlemr(patient_id);
update temp_appointments set dossier_number = dosId(patient_id);
update temp_appointments set telephone_number = phone_number(patient_id);
update temp_appointments set location_name = location_name(location_id);

update temp_appointments a
inner join provider p on a.provider_id = p.provider_id
set a.provider_name = person_name(p.person_id);

update temp_appointments a set a.status_name = CASE
    WHEN status_code = 'COMPLETED' THEN 'Terminé'
    WHEN status_code = 'WAITING' THEN 'Enregistré'
    WHEN status_code = 'MISSED' THEN 'Manqué'
    WHEN status_code = 'CANCELLED' THEN 'Annulé'
    WHEN status_code = 'SCHEDULED' THEN 'Programmé'
    END
;

select
    family_name as familyName,
    given_name as givenName,
    zlemr_id as zlEmrId,
    dossier_number as dossierNumber,
    telephone_number as telephoneNumber,
    date_format(start_date, '%d %b %Y') as date,
    date_format(start_date, '%h:%i %p') as startTime,
    date_format(end_date, '%h:%i %p') as endTime,
    location_name as location,
    provider_name as provider,
    service_type as serviceType,
    reason,
    cancel_reason as cancelReason,
    status_name as status,
    confidential
from
    temp_appointments
order by
    start_date, family_name, given_name
;