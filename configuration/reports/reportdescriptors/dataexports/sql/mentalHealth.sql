DROP TEMPORARY TABLE IF EXISTS temp_mentalhealth_visit;

SET sql_safe_updates = 0;
SET SESSION group_concat_max_len = 100000;

set @encounter_type = encounter_type('Mental Health Consult');
set @role_of_referring_person = concept_from_mapping('PIH','Role of referring person');
set @other_referring_person = concept_from_mapping('PIH','OTHER');
set @type_of_referral_role = concept_from_mapping('PIH','Type of referral role');
set @other_referring_role_type = concept_from_mapping('PIH','OTHER');
set @hospitalization = concept_from_mapping('CIEL','976');
set @hospitalization_reason = concept_from_mapping('CIEL','162879');
set @type_of_patient =  concept_from_mapping('PIH', 'TYPE OF PATIENT');
set @inpatient_hospitalization = concept_from_mapping('PIH','INPATIENT HOSPITALIZATION');
set @traumatic_event = concept_from_mapping('PIH','12362');
set @yes =   concept_from_mapping('PIH', 'YES');
set @adherence_to_appt = concept_from_mapping('PIH','Appearance at appointment time');
set @zldsi_score = concept_from_Mapping('CIEL','163225');
set @ces_dc = concept_from_Mapping('CIEL','163228');
set @psc_35 = concept_from_Mapping('CIEL','165534');
set @pcl = concept_from_Mapping('CIEL','165535');
set @cgi_s = concept_from_Mapping('CIEL','163222');
set @cgi_i = concept_from_Mapping('CIEL','163223');
set @cgi_e = concept_from_Mapping('CIEL','163224');
set @whodas = concept_from_Mapping('CIEL','163226');
set @days_with_difficulties = concept_from_mapping('PIH','Days with difficulties in past month');
set @days_without_usual_activity = concept_from_mapping('PIH','Days without usual activity in past month');
set @days_with_less_activity = concept_from_mapping('PIH','Days with less activity in past month');
set @aims = concept_from_mapping('CIEL','163227');
set @seizure_frequency = concept_from_mapping('PIH','Number of seizures in the past month');
set @past_suicidal_evaluation = concept_from_mapping('CIEL','1628');
set @current_suicidal_evaluation = concept_from_mapping('PIH','Mental health diagnosis');
set @last_suicide_attempt_date = concept_from_mapping('CIEL','165530');
set @suicidal_screen_completed = concept_from_mapping('PIH','Suicidal evaluation');
set @suicidal_screening_result = concept_from_mapping('PIH', 'Result of suicide risk evaluation');
set @security_plan = concept_from_mapping('PIH','Security plan');
set @discuss_patient_with_supervisor = concept_from_mapping('CIEL', '165532');
set @hospitalize_due_to_suicide_risk = concept_from_mapping('CIEL', '165533');
set @mh_diagnosis = concept_from_mapping('PIH','Mental health diagnosis');
set @hum_diagnoses = concept_from_mapping('PIH','HUM Psychological diagnoses');
set @mental_health_intervention = concept_from_mapping('PIH','Mental health intervention');
set @other = concept_from_mapping('PIH','OTHER');
set @medication = concept_from_mapping('PIH', 'Mental health medication');
set @dose =  concept_from_mapping('CIEL', '160856 ');
set @dosing_units =  concept_from_mapping('PIH', 'Dosing units coded');
set @frequency =  concept_from_mapping('PIH', 'Drug frequency for HUM');
set @duration =  concept_from_mapping('CIEL', '159368 ');
set @duration_units =  concept_from_mapping('PIH', 'TIME UNITS');
set @medication_comments = concept_from_mapping('PIH', 'Medication comments (text)');
set @pregnant = concept_from_mapping('CIEL', '5272');
set @last_menstruation_date = concept_from_mapping('PIH','DATE OF LAST MENSTRUAL PERIOD');
set @estimated_delivery_date = concept_from_mapping('PIH','ESTIMATED DATE OF CONFINEMENT');
set @type_of_referral_roles = concept_from_mapping('PIH','Role of referral out provider');
set @type_of_provider = concept_from_mapping('PIH','Type of provider');
set @disposition = concept_from_mapping('PIH','HUM Disposition categories');
set @disposition_comment = concept_from_mapping('PIH','PATIENT PLAN COMMENTS');
set @return_date = concept_from_mapping('PIH','RETURN VISIT DATE');
set @routes = concept_from_mapping('PIH', '12651');
set @oral = concept_from_mapping('CIEL', '160240');
set @intraveneous = concept_from_mapping('CIEL', '160242');
set @intramuscular = concept_from_mapping('CIEL', '160243');


create temporary table temp_mentalhealth_visit
(
patient_id int,
zl_emr_id varchar(255),
gender varchar(50),
unknown_patient text,
patient_address text,
provider varchar(255),
loc_registered varchar(255),
location_id int,
enc_location varchar(255),
encounter_id int,
encounter_date datetime,
age_at_enc double,
visit_date date,
visit_id int,
referred_from_community_by varchar(255),
other_referring_person varchar(255),
type_of_referral_role varchar(255),
other_referring_role_type varchar(255),
hospitalized_since_last_visit varchar(50),
hospitalization_reason text,
hospitalized_at_time_of_visit varchar(50),
traumatic_event varchar(50),
adherence_to_appt varchar(225),
zldsi_score double,
ces_dc double,
psc_35 double,
pcl double,
cgi_s double,
cgi_i double,
cgi_e double,
whodas double,
days_with_difficulties double,
days_without_usual_activity double,
days_with_less_activity double,
aims varchar(255),
seizure_frequency double,
past_suicidal_evaluation varchar(255),
current_suicidal_evaluation varchar(255),
last_suicide_attempt_date date,
suicidal_screen_completed varchar(50),
suicidal_screening_result varchar(255),
high_result_for_suicidal_screening text,
diagnosis text,
psychological_intervention text,
other_psychological_intervention text,
medication_1 text,
quantity_1 double,
dosing_units_1 text,
frequency_1 text,
duration_1 double,
duration_units_1 text,
route_1 text,
medication_2 text,
quantity_2 double,
dosing_units_2 text,
frequency_2 text,
duration_2 double,
duration_units_2 text,
route_2 text,
medication_3 text,
quantity_3 double,
dosing_units_3 text,
frequency_3 text,
duration_3 double,
duration_units_3 text,
route_3 text,
medication_comments text,
pregnant varchar(50),
last_menstruation_date date,
estimated_delivery_date date,
type_of_provider text,
type_of_referral_roles text,
disposition varchar(255),
disposition_comment text,
return_date date
);

insert into temp_mentalhealth_visit (   patient_id,
										zl_emr_id, gender,
                                        encounter_id,
                                        encounter_date,
                                        age_at_enc,
                                        provider,
                                        patient_address,
                                        -- loc_registered,
                                        location_id,
                                        -- visit_date,
                                        visit_id
                                        )
select patient_id,
	   zlemr(patient_id),
       gender(patient_id),
       encounter_id,
       encounter_datetime,
       age_at_enc(patient_id, encounter_id),
       provider(encounter_id),
       person_address(patient_id),
       -- loc_registered(patient_id),
       location_id,
       -- visit_date(patient_id),
       visit_id
 from encounter where voided = 0 and encounter_type = @encounter_type
-- filter by date
 AND date(encounter_datetime) >=  date(@startDate)
 AND date(encounter_datetime) <=  date(@endDate)
;

-- exclude test patients
delete from temp_mentalhealth_visit where
patient_id IN (SELECT person_id FROM person_attribute WHERE value = 'true' AND person_attribute_type_id = (select
person_attribute_type_id from person_attribute_type where name = "Test Patient")
                         AND voided = 0)
;

-- unknown patient
update temp_mentalhealth_visit tmhv
set tmhv.unknown_patient = IF(tmhv.patient_id = unknown_patient(tmhv.patient_id), 'true', NULL);
-- location
update temp_mentalhealth_visit tmhv
left join location l on tmhv.location_id = l.location_id
set tmhv.enc_location = l.name;

-- Role of referring person
update temp_mentalhealth_visit tmhv
left join
(
select encounter_id,  group_concat(name separator ' | ') names  from obs o join concept_name cn on cn.concept_id = o.value_coded and cn.voided = 0
and o.voided = 0 and o.concept_id = @role_of_referring_person and cn.locale = "fr" and concept_name_type = "FULLY_SPECIFIED"
group by encounter_id
) o on o.encounter_id = tmhv.encounter_id
set tmhv.referred_from_community_by = o.names;

update temp_mentalhealth_visit tmhv
set tmhv.other_referring_person = (select comments from obs where voided = 0 and encounter_id = tmhv.encounter_id and value_coded = @other_referring_person
and concept_id = @role_of_referring_person);

update temp_mentalhealth_visit tmhv
left join
(
select encounter_id, group_concat(name separator ' | ') names from obs o join concept_name cn on cn.concept_id = o.value_coded and cn.voided = 0
and o.voided = 0 and o.concept_id = @type_of_referral_role and cn.locale = "fr" and concept_name_type = "FULLY_SPECIFIED"
group by encounter_id
) o on o.encounter_id = tmhv.encounter_id
set tmhv.type_of_referral_role = o.names;

update temp_mentalhealth_visit tmhv
set tmhv.other_referring_role_type = (select comments from obs where voided = 0 and encounter_id = tmhv.encounter_id and value_coded = @other_referring_role_type
and concept_id = @type_of_referral_role);

-- hospitalization
update temp_mentalhealth_visit tmhv
set tmhv.hospitalized_since_last_visit = (select concept_name(value_coded, 'fr') from obs where voided = 0 and concept_id = @hospitalization and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.hospitalization_reason = (select value_text from obs where voided = 0 and concept_id = @hospitalization_reason and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.hospitalization_reason = (select value_text from obs where voided = 0 and concept_id = @hospitalization_reason and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.hospitalized_at_time_of_visit = IF(@inpatient_hospitalization=(select value_coded from obs where voided = 0 and concept_id = @type_of_patient
and tmhv.encounter_id = encounter_id), 'Oui', Null);

-- traumatic event
update temp_mentalhealth_visit tmhv
set tmhv.traumatic_event = IF(@yes=(select value_coded from obs where voided = 0 and concept_id = @traumatic_event
and tmhv.encounter_id = encounter_id), 'Oui', Null);

-- Adherence to appointment day
update temp_mentalhealth_visit tmhv
set tmhv.adherence_to_appt = (select concept_name(value_coded, 'fr') from obs where voided = 0 and concept_id = @adherence_to_appt
and tmhv.encounter_id = encounter_id);

-- scores
update temp_mentalhealth_visit tmhv
set tmhv.zldsi_score = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @zldsi_score);

update temp_mentalhealth_visit tmhv
set tmhv.ces_dc = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @ces_dc);

update temp_mentalhealth_visit tmhv
set tmhv.psc_35 = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @psc_35);

update temp_mentalhealth_visit tmhv
set tmhv.pcl = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @pcl);

update temp_mentalhealth_visit tmhv
set tmhv.cgi_s = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @cgi_s);

update temp_mentalhealth_visit tmhv
set tmhv.cgi_i = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @cgi_i);

update temp_mentalhealth_visit tmhv
set tmhv.cgi_e = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @cgi_e);

update temp_mentalhealth_visit tmhv
set tmhv.whodas = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @whodas);

update temp_mentalhealth_visit tmhv
set tmhv.days_with_difficulties = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @days_with_difficulties);

update temp_mentalhealth_visit tmhv
set tmhv.days_without_usual_activity = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @days_without_usual_activity);

update temp_mentalhealth_visit tmhv
set tmhv.days_with_less_activity = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @days_with_less_activity);

update temp_mentalhealth_visit tmhv
set tmhv.aims = (select concept_name(value_coded, 'fr') from obs where voided = 0 and concept_id = @aims and tmhv.encounter_id = encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.seizure_frequency = (select value_numeric from obs where voided = 0 and encounter_id = tmhv.encounter_id and concept_id = @seizure_frequency);

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @past_suicidal_evaluation group by encounter_id) o
on tmhv.encounter_id = o.encounter_id
set tmhv.past_suicidal_evaluation  = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @current_suicidal_evaluation group by encounter_id) o
on tmhv.encounter_id = o.encounter_id
set tmhv.current_suicidal_evaluation  = o.names;

update temp_mentalhealth_visit tmhv
set tmhv.last_suicide_attempt_date = (select date(value_datetime) from obs where concept_id = @last_suicide_attempt_date and voided = 0 and tmhv.encounter_id = obs.encounter_id);

update temp_mentalhealth_visit tmhv
set tmhv.suicidal_screen_completed = IF(1=(select value_coded from obs where concept_id = @suicidal_screen_completed and voided = 0 and tmhv.encounter_id = obs.encounter_id),'Oui', Null);

update temp_mentalhealth_visit tmhv
set tmhv.suicidal_screening_result = (select concept_name(value_coded, 'fr') from obs where voided = 0 and concept_id = @suicidal_screening_result and tmhv.encounter_id = obs.encounter_id);

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @current_suicidal_evaluation group by encounter_id) o
on tmhv.encounter_id = o.encounter_id
set tmhv.current_suicidal_evaluation  = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.value_coded in (@security_plan, @discuss_patient_with_supervisor, @hospitalize_due_to_suicide_risk) group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.high_result_for_suicidal_screening = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @mh_diagnosis
-- and value_coded in (select concept_id from concept_set where concept_set = @hum_diagnoses)
group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.diagnosis = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @mental_health_intervention
group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.psychological_intervention = o.names,
	tmhv.other_psychological_intervention = (select comments from obs where voided = 0 and concept_id = @mental_health_intervention and value_coded = @other and tmhv.encounter_id = obs.encounter_id);

update temp_mentalhealth_visit tmhv
left join
(
select e.encounter_id,
medication_1,
quantity_1,
dosing_units_1,
frequency_1,
duration_1,
duration_units_1,
route_1,
medication_2,
quantity_2,
dosing_units_2,
frequency_2,
duration_2,
duration_units_2,
route_2,
medication_3,
quantity_3,
dosing_units_3,
frequency_3,
duration_3,
duration_units_3,
route_3
from encounter e
inner join obs pres_con1 on pres_con1.obs_id =
   (select opc1.obs_id from obs opc1 where  opc1.encounter_id = e.encounter_id and opc1.concept_id = 3101 limit 1)
left outer join
  (select o1.obs_group_id,
  MAX(CASE WHEN o1.concept_id = @medication THEN cn1.name END) "medication_1",
  MAX(CASE WHEN o1.concept_id = @dose THEN o1.value_numeric END) "quantity_1",
  MAX(CASE WHEN o1.concept_id = @dosing_units THEN cn1.name END) "dosing_units_1",
  MAX(CASE WHEN o1.concept_id = @frequency THEN cn1.name END) "frequency_1",
  MAX(CASE WHEN o1.concept_id = @duration THEN o1.value_numeric END) "duration_1",
  MAX(CASE WHEN o1.concept_id = @duration_units THEN cn1.name END) "duration_units_1",
  MAX(CASE WHEN o1.concept_id = @routes THEN cn1.name END) "route_1"
  from obs o1
  LEFT OUTER JOIN concept_name cn1 on cn1.concept_name_id =
     (select concept_name_id from concept_name cn11
     where cn11.concept_id = o1.value_coded
     and cn11.voided  = 0
     and cn11.locale in ('en', 'fr')
     order by field(cn11.locale,'fr','en') asc, cn11.locale_preferred desc
    limit 1)
group by o1.obs_group_id) m1 on m1.obs_group_id = pres_con1.obs_id
-- ------------
left outer join obs pres_con2 on pres_con2.obs_id =
   (select opc2.obs_id from obs opc2 where  opc2.encounter_id = e.encounter_id and opc2.concept_id = 3101 and opc2.obs_id <> pres_con1.obs_id limit 1)
left outer join
  (select o2.obs_group_id,
  MAX(CASE WHEN o2.concept_id = @medication THEN cn2.name END) "medication_2",
  MAX(CASE WHEN o2.concept_id = @dose THEN o2.value_numeric END) "quantity_2",
  MAX(CASE WHEN o2.concept_id = @dosing_units THEN cn2.name END) "dosing_units_2",
  MAX(CASE WHEN o2.concept_id = @frequency THEN cn2.name END) "frequency_2",
  MAX(CASE WHEN o2.concept_id = @duration THEN o2.value_numeric END) "duration_2",
  MAX(CASE WHEN o2.concept_id = @duration_units THEN cn2.name END) "duration_units_2",
  MAX(CASE WHEN o2.concept_id = @routes THEN cn2.name END) "route_2"
  from obs o2
   LEFT OUTER JOIN concept_name cn2 on cn2.concept_name_id =
     (select concept_name_id from concept_name cn21
     where cn21.concept_id = o2.value_coded
     and cn21.voided  = 0
     and cn21.locale in ('en', 'fr')
     order by field(cn21.locale,'fr','en') asc, cn21.locale_preferred desc
    limit 1)
  group by o2.obs_group_id) m2 on m2.obs_group_id =pres_con2.obs_id
-- ------------
left outer join obs pres_con3 on pres_con3.obs_id =
   (select opc3.obs_id from obs opc3 where  opc3.encounter_id = e.encounter_id and opc3.concept_id = 3101 and opc3.obs_id not in (pres_con1.obs_id,pres_con2.obs_id)  limit 1)
left outer join
  (select o3.obs_group_id,
  MAX(CASE WHEN o3.concept_id = @medication THEN cn3.name END) "medication_3",
  MAX(CASE WHEN o3.concept_id = @dose THEN o3.value_numeric END) "quantity_3",
  MAX(CASE WHEN o3.concept_id = @dosing_units THEN cn3.name END) "dosing_units_3",
  MAX(CASE WHEN o3.concept_id = @frequency THEN cn3.name END) "frequency_3",
  MAX(CASE WHEN o3.concept_id = @duration THEN o3.value_numeric END) "duration_3",
  MAX(CASE WHEN o3.concept_id = @duration_units THEN cn3.name END) "duration_units_3",
  MAX(CASE WHEN o3.concept_id = @routes THEN cn3.name END) "route_3"
  from obs o3
  LEFT OUTER JOIN concept_name cn3 on cn3.concept_name_id =
     (select concept_name_id from concept_name cn31
     where cn31.concept_id = o3.value_coded
     and cn31.voided  = 0
     and cn31.locale in ('en', 'fr')
     order by field(cn31.locale,'fr','en') asc, cn31.locale_preferred desc
    limit 1)
  group by o3.obs_group_id) m3 on m3.obs_group_id =pres_con3.obs_id
  ) o on tmhv.encounter_id = o.encounter_id
  set tmhv.medication_1 = o.medication_1,
  tmhv.quantity_1 = o.quantity_1,
tmhv.dosing_units_1 = o.dosing_units_1,
tmhv.frequency_1 = o.frequency_1,
tmhv.duration_1 = o.duration_1,
tmhv.duration_units_1 = o.duration_units_1,
tmhv.route_1 = o.route_1,
tmhv.medication_2 = o.medication_2,
tmhv.quantity_2 = o.quantity_2,
tmhv.dosing_units_2 = o.dosing_units_2,
tmhv.frequency_2 = o.frequency_2,
tmhv.duration_2 = o.duration_2,
tmhv.duration_units_2 = o.duration_units_2,
tmhv.route_2 = o.route_2,
tmhv.medication_3 = o.medication_3,
tmhv.quantity_3 = o.quantity_3,
tmhv.dosing_units_3 = o.dosing_units_3,
tmhv.frequency_3 = o.frequency_3,
tmhv.duration_3 = o.duration_3,
tmhv.duration_units_3 = o.duration_units_3,
tmhv.route_3 = o.route_3,
tmhv.medication_comments = (select value_text from obs where voided = 0 and tmhv.encounter_id = obs.encounter_id and concept_id = @medication_comments);

-- pregnancy questions
update temp_mentalhealth_visit tmhv
left join obs preg on preg.encounter_id = tmhv.encounter_id and preg.concept_id = @pregnant and preg.voided = 0
set tmhv.pregnant = concept_name(preg.value_coded, 'fr');

update temp_mentalhealth_visit tmhv
left join obs lmd on lmd.encounter_id = tmhv.encounter_id and lmd.concept_id = @last_menstruation_date and lmd.voided = 0
set tmhv.last_menstruation_date = lmd.value_datetime
;

update temp_mentalhealth_visit tmhv
left join obs edd on edd.encounter_id = tmhv.encounter_id and edd.concept_id = @estimated_delivery_date and edd.voided = 0
set tmhv.estimated_delivery_date = edd.value_datetime
;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @type_of_provider group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.type_of_provider = o.names;

update temp_mentalhealth_visit tmhv
left join
(
select group_concat(cn.name separator ' | ') names, encounter_id from concept_name cn join obs o on o.voided = 0 and cn.voided = 0 and
value_coded = cn.concept_id and locale='fr' and concept_name_type = "FULLY_SPECIFIED" and o.concept_id = @type_of_referral_roles group by encounter_id
) o on tmhv.encounter_id = o.encounter_id
set tmhv.type_of_referral_roles = o.names;

update temp_mentalhealth_visit tmhv
set tmhv.disposition = (select concept_name(value_coded, 'fr') from obs where concept_id = @disposition and voided = 0 and tmhv.encounter_id = obs.encounter_id),
	tmhv.disposition_comment = (select value_text from obs where concept_id = @disposition_comment and voided = 0 and tmhv.encounter_id = obs.encounter_id),
    tmhv.return_date = (select date(value_datetime) from obs where concept_id = @return_date and voided = 0 and tmhv.encounter_id = obs.encounter_id);


select
encounter_id,
patient_id,
zl_emr_id,
gender,
unknown_patient,
person_address_state_province(patient_id) 'province',
person_address_city_village(patient_id) 'city_village',
person_address_three(patient_id) 'address3',
person_address_one(patient_id) 'address1',
person_address_two(patient_id) 'address2',
provider,
visit_id,
enc_location,
encounter_date,
age_at_enc,
referred_from_community_by,
other_referring_person,
type_of_referral_role 'referral_role_from_within_facility',
other_referring_role_type,
hospitalized_since_last_visit,
hospitalization_reason,
hospitalized_at_time_of_visit,
traumatic_event,
adherence_to_appt,
zldsi_score,
ces_dc,
psc_35,
pcl,
cgi_s,
cgi_i,
cgi_e,
whodas,
days_with_difficulties,
days_without_usual_activity,
days_with_less_activity,
aims,
seizure_frequency,
past_suicidal_evaluation,
last_suicide_attempt_date,
suicidal_screen_completed,
suicidal_screening_result,
high_result_for_suicidal_screening,
diagnosis,
psychological_intervention,
other_psychological_intervention,
medication_1,
quantity_1,
dosing_units_1,
frequency_1,
duration_1,
duration_units_1,
route_1,
medication_2,
quantity_2,
dosing_units_2,
frequency_2,
duration_2,
duration_units_2,
route_2,
medication_3,
quantity_3,
dosing_units_3,
frequency_3,
duration_3,
duration_units_3,
route_3,
medication_comments,
pregnant, 
last_menstruation_date,
estimated_delivery_date,
type_of_provider,
type_of_referral_roles "referred_to",
disposition,
disposition_comment,
return_date
from temp_mentalhealth_visit
;
