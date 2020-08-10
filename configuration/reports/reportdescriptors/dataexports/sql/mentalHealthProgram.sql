SET sql_safe_updates = 0;

DROP TEMPORARY TABLE IF EXISTS temp_mentalhealth_program;

SET SESSION group_concat_max_len = 100000;

set @program_id = program('Mental Health');
set @latest_diagnosis = concept_from_mapping('PIH', 'Mental health diagnosis');
set @encounter_type = encounter_type('Mental Health Consult');
set @zlds_score = concept_from_mapping('CIEL', '163225');
set @whodas_score = concept_from_mapping('CIEL', '163226');
set @seizures = concept_from_mapping('PIH', 'Number of seizures in the past month');
set @medication = concept_from_mapping('PIH', 'Mental health medication');
set @mh_intervention =  concept_from_mapping('PIH', 'Mental health intervention');
set @other_noncoded = concept_from_mapping('PIH', 'OTHER NON-CODED');
set @return_visit_date = concept_from_mapping('PIH', 'RETURN VISIT DATE');

create temporary table temp_mentalhealth_program
(
patient_id int,
patient_program_id int,
prog_location_id int,
zlemr varchar(255),
gender varchar(50),
age double,
assigned_chw text,
location_when_registered_in_program varchar(255),
date_enrolled date,
date_completed date,
number_of_days_in_care double,
program_status_outcome varchar(255),
unknown_patient varchar(50),
encounter_id int,
encounter_datetime datetime,
latest_diagnosis text,
latest_zlds_score double,
recent_date_zlds_score date,
previous_zlds_score double,
previous_date_zlds_score date,
baseline_zlds_score double,
baseline_date_zlds_score date,
latest_whodas_score double,
recent_date_whodas_score date,
previous_whodas_score double,
previous_date_whodas_score date,
baseline_whodas_score double,
baseline_date_whodas_score date,
latest_seizure_number double,
latest_seizure_date date,
previous_seizure_number double,
previous_seizure_date date,
baseline_seizure_number double,
baseline_seizure_date date,
latest_medication_given text,
latest_medication_date date,
latest_intervention text,
other_intervention text,
last_intervention_date date,
last_visit_date date,
next_scheduled_visit_date date,
patient_came_within_14_days_appt varchar(50),
three_months_since_latest_return_date varchar(50),
six_months_since_latest_return_date varchar(50)
);

insert into temp_mentalhealth_program (patient_id, patient_program_id, prog_location_id, zlemr, gender, date_enrolled, date_completed, number_of_days_in_care, program_status_outcome
                                        )
select patient_id,
	   patient_program_id,
       location_id,
	   zlemr(patient_id),
       gender(patient_id),
	   date(date_enrolled),
       date(date_completed),
       If(date_completed is null, datediff(now(), date_enrolled), datediff(date_completed, date_enrolled)),
       concept_name(outcome_concept_id, 'fr')
       from patient_program where program_id = @program_id and voided = 0;

-- exclude test patients
delete from temp_mentalhealth_program where
patient_id IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = (select
person_attribute_type_id from person_attribute_type where name = "Test Patient")
                         AND voided = 0)
;

-- unknown patient
update temp_mentalhealth_program tmhp
set tmhp.unknown_patient = IF(tmhp.patient_id = unknown_patient(tmhp.patient_id), 'true', NULL);

update temp_mentalhealth_program tmhp
left join person p on person_id = patient_id and p.voided = 0
set tmhp.age = CAST(CONCAT(timestampdiff(YEAR, p.birthdate, NOW()), '.', MOD(timestampdiff(MONTH, p.birthdate, NOW()), 12) ) as CHAR);

-- relationship
update temp_mentalhealth_program tmhp
inner join (select patient_program_id, patient_id, person_a, GROUP_CONCAT(' ',CONCAT(pn.given_name,' ',pn.family_name)) chw  from patient_program join relationship r on person_b = patient_id and program_id = @program_id
and r.voided = 0 and relationship = relation_type('Community Health Worker') join person_name pn on person_a = pn.person_id and pn.voided = 0 group by patient_program_id) relationship
on relationship.patient_id = tmhp.patient_id and tmhp.patient_program_id = relationship.patient_program_id
set tmhp.assigned_chw = relationship.chw;

-- location registered in Program
update temp_mentalhealth_program tmhp
left join location l on location_id = tmhp.prog_location_id and l.retired = 0
set tmhp.location_when_registered_in_program = l.name;

-- latest dignoses
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id, group_concat(distinct(cn.name) separator ' | ') diagnoses from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed) or date_completed is null)
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @latest_diagnosis  and voided = 0)
     order by e2.encounter_datetime desc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @latest_diagnosis and o.voided = 0
     left outer join concept_name cn on concept_name_id = 
        (select concept_name_id from concept_name cn2
         where cn2.concept_id = o.value_coded
         and cn2.voided = 0
         and cn2.locale in ('en','fr')
         order by field(cn2.locale,'fr','en') asc, cn2.locale_preferred desc
         limit 1)
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) tld on tld.patient_program_id = tmh.patient_program_id
set tmh.latest_diagnosis = tld.diagnoses;

-- latest zlds non null score
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @zlds_score and voided = 0)
     order by e2.encounter_datetime desc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @zlds_score and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) tzld
on tzld.patient_program_id = tmh.patient_program_id
set tmh.latest_zlds_score = tzld.value_numeric,
	tmh.recent_date_zlds_score = tzld.enc_date;

-- Previous zlds non-null score
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed) or date_completed is null)
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @zlds_score and voided = 0)
     order by e2.encounter_datetime desc
     limit 1,1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @zlds_score and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) tzld_prev
on tzld_prev.patient_program_id = tmh.patient_program_id
set tmh.previous_zlds_score = tzld_prev.value_numeric,
	tmh.previous_date_zlds_score = tzld_prev.enc_date;

-- Baseline zlds non-null score
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @zlds_score and voided = 0)
     order by e2.encounter_datetime asc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @zlds_score and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) tzld_baseline
on tzld_baseline.patient_program_id = tmh.patient_program_id
set tmh.baseline_zlds_score = tzld_baseline.value_numeric,
	tmh.baseline_date_zlds_score = tzld_baseline.enc_date;

-- latest WHODAS score
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @whodas_score and voided = 0)
     order by e2.encounter_datetime desc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @whodas_score and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) twhodas
on twhodas.patient_program_id = tmh.patient_program_id
set tmh.latest_whodas_score = twhodas.value_numeric,
	tmh.recent_date_whodas_score = twhodas.enc_date,
    tmh.encounter_id = twhodas.enc_id;

-- Previous WHODAS score
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @whodas_score and voided = 0)
     order by e2.encounter_datetime desc
     limit 1,1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @whodas_score and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) twhodas_prev
on twhodas_prev.patient_program_id = tmh.patient_program_id
set tmh.previous_whodas_score = twhodas_prev.value_numeric,
	tmh.previous_date_whodas_score = twhodas_prev.enc_date;

-- first/baseline WHODAS
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @whodas_score and voided = 0)
     order by e2.encounter_datetime asc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @whodas_score and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) twhodas_baseline
on twhodas_baseline.patient_program_id = tmh.patient_program_id
set tmh.baseline_whodas_score = twhodas_baseline.value_numeric,
	tmh.baseline_date_whodas_score = twhodas_baseline.enc_date;

-- latest number of seizures
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @seizures and voided = 0)
     order by e2.encounter_datetime desc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @seizures and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) seizure
on seizure.patient_program_id = tmh.patient_program_id
set tmh.latest_seizure_number = seizure.value_numeric,
	tmh.latest_seizure_date = seizure.enc_date;

-- Previous number of seizures
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @seizures and voided = 0)
     order by e2.encounter_datetime desc
     limit 1,1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @seizures and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) seizure_prev
on seizure_prev.patient_program_id = tmh.patient_program_id
set tmh.previous_seizure_number = seizure_prev.value_numeric,
	tmh.previous_seizure_date = seizure_prev.enc_date;

-- first/baseline number or seizures
update temp_mentalhealth_program tmh
LEFT JOIN 
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date, value_numeric from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @seizures and voided = 0)
     order by e2.encounter_datetime asc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @seizures and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) seizure_baseline
on seizure_baseline.patient_program_id = tmh.patient_program_id
set tmh.baseline_seizure_number = seizure_baseline.value_numeric,
	tmh.baseline_seizure_date = seizure_baseline.enc_date;

-- last Medication recorded
update temp_mentalhealth_program tmh
LEFT JOIN
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date, 
group_concat(distinct(cn.name) separator ' | ') "medication_names"
from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed) or date_completed is null)
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @medication and voided = 0)
     order by e2.encounter_datetime desc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @medication and o.voided = 0
     -- INNER JOIN drug cnd on cnd.drug_id  = o.value_drug
     left outer join concept_name cn on concept_name_id = 
        (select concept_name_id from concept_name cn2
         where cn2.concept_id = o.value_coded
         and cn2.voided = 0
         and cn2.locale in ('en','fr')
         order by field(cn2.locale,'fr','en') asc, cn2.locale_preferred desc
         limit 1)
     left outer join concept_name cn1 on cn1.name = 
        (select name from concept_name cn2
         where cn2.concept_id = o.value_coded
         and cn2.voided = 0
         and cn2.locale in ('en','fr')
         order by field(cn2.locale,'fr','en') asc, cn2.locale_preferred desc
         limit 1)
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id   
) medication
on medication.patient_program_id = tmh.patient_program_id
set tmh.latest_medication_given = medication.medication_names,

	tmh.latest_medication_date = medication.enc_date;

-- latest intervention
UPDATE temp_mentalhealth_program tmh
LEFT JOIN
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date, group_concat(distinct(cn.name) separator ' | ') intervention from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed) or date_completed is null)
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @mh_intervention and voided = 0)
     order by e2.encounter_datetime desc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @mh_intervention and o.voided = 0
     left outer join concept_name cn on concept_name_id = 
        (select concept_name_id from concept_name cn2
         where cn2.concept_id = o.value_coded
         and cn2.voided = 0
         and cn2.locale in ('en','fr')
         order by field(cn2.locale,'fr','en') asc, cn2.locale_preferred desc
         limit 1)
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id   
) tli ON tli.patient_program_id = tmh.patient_program_id
SET
    tmh.latest_intervention = tli.intervention,
    tmh.other_intervention = (SELECT
            comments
        FROM
            obs o
        WHERE
            o.concept_id = @mh_intervention
                AND value_coded = @other_noncoded
                AND o.voided = 0
                AND o.encounter_id = tli.enc_id),
    tmh.last_intervention_date = tli.enc_date;

-- Last Visit Date
UPDATE temp_mentalhealth_program tmh
LEFT JOIN
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     order by e2.encounter_datetime desc
     limit 1
     )
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) last_visit
on last_visit.patient_program_id = tmh.patient_program_id
set tmh.last_visit_date = date(last_visit.enc_date);

-- Next Scheduled Visit Date
UPDATE temp_mentalhealth_program tmh
LEFT JOIN
(
select pp.patient_id, patient_program_id, date_enrolled, date_completed, e.encounter_id enc_id, date(e.encounter_datetime) enc_date, value_datetime from patient_program pp
INNER JOIN
encounter e on e.encounter_id =
    (select encounter_id from encounter e2 where
     e2.voided = 0
     and e2.patient_id = pp.patient_id
     and e2.encounter_type = @encounter_type
     and (date(e2.encounter_datetime) >= date(date_enrolled) and (date(e2.encounter_datetime)  <= date(date_completed)) or 
     (date(e2.encounter_datetime) >= date(date_enrolled) and date_completed is null))
     and exists (select 1 from obs where encounter_id = e2.encounter_id and concept_id = @return_visit_date and voided = 0)
     order by e2.encounter_datetime desc
     limit 1
     )
     inner join obs o on o.encounter_id = e.encounter_id and o.concept_id = @return_visit_date and o.voided = 0
     where pp.program_id = @program_id and pp.voided = 0
     group by patient_program_id
) next_visit on next_visit.patient_program_id = tmh.patient_program_id
set tmh.next_scheduled_visit_date = date(next_visit.value_datetime),
    tmh.patient_came_within_14_days_appt = IF(datediff(now(), tmh.last_visit_date) <= 14, 'Oui', 'No'),
    tmh.three_months_since_latest_return_date = IF(datediff(now(), tmh.last_visit_date) <= 91.2501, 'No', 'Oui'),
	tmh.six_months_since_latest_return_date = IF(datediff(now(), tmh.last_visit_date) <= 182.5, 'No', 'Oui');
                                                                          
select
patient_id,
zlemr,
gender,
age,
unknown_patient,
assigned_chw,
person_address_state_province(patient_id) 'province',
person_address_city_village(patient_id) 'city_village',
person_address_three(patient_id) 'address3',
person_address_one(patient_id) 'address1',
person_address_two(patient_id) 'address2',
location_when_registered_in_program,
date_enrolled,
date_completed,
number_of_days_in_care,
program_status_outcome,
latest_diagnosis,
latest_zlds_score,
recent_date_zlds_score,
previous_zlds_score,
previous_date_zlds_score,
baseline_zlds_score,
baseline_date_zlds_score,
latest_whodas_score,
recent_date_whodas_score,
previous_whodas_score,
previous_date_whodas_score,
baseline_whodas_score,
baseline_date_whodas_score,
latest_seizure_number,
latest_seizure_date,
previous_seizure_number,
previous_seizure_date,
baseline_seizure_number,
baseline_seizure_date,
latest_medication_given,
latest_medication_date,
latest_intervention,
other_intervention,
last_intervention_date,
last_visit_date,
next_scheduled_visit_date,
three_months_since_latest_return_date,
six_months_since_latest_return_date
from temp_mentalhealth_program;
