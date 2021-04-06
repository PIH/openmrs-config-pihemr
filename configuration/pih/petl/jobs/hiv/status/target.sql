create table hiv_status
(
status_id int PRIMARY KEY,
patient_id int,
zl_emr_id varchar(255),
patient_location varchar(255),
transfer_in_from varchar(255),
status_outcome varchar(255),
start_date date,
end_date date,
return_to_care int,
currently_late_for_pickup int,
index_program_ascending int,
index_program_descending int,
index_patient_ascending int,
index_patient_descending int
 );
