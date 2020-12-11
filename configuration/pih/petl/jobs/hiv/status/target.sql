create table hiv_status
(
status_id int PRIMARY KEY,
patient_id int,
zl_emr_id varchar(255),
patient_location varchar(255),
status_outcome varchar(255),
start_date date,
end_date date,
index_ascending int,
index_descending int
 );
