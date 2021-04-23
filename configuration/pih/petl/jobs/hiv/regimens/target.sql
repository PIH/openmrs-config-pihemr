create table hiv_regimens
(
order_id int PRIMARY KEY,
previous_order_id int,
patient_id int,
order_action varchar(50),
encounter_id int,
encounter_datetime datetime,
visit_location varchar(255), 
drug_category varchar(255),
art_treatment_line varchar(255),
drug_id varchar(255),
drug_short_name varchar(255),
drug_name varchar(255),
start_date datetime,
end_date datetime,
end_reasons varchar(255),
ptme_or_prophylaxis char(1),
regimen_line_original varchar(255),
index_ascending_category int,
index_descending_category int,
index_ascending_patient int,
index_descending_patient int
 );

