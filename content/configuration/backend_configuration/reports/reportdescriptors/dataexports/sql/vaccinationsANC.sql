## THIS IS A ROW-PER-ENCOUNTER EXPORT
## IT LIMITS THE DATA TO ENCOUNTERS OF SPECIFIC TYPES, AND WHICH CONTAIN RELEVANT VACCINATION OBSERVATIONS
## IT ALSO LIMITS TO PATIENTS WHO HAVE EVER BEEN IN THE MCH PROGRAM, AND WHO ARE NOT TEST PATIENTS
## FOR EFFICIENCY, THIS USES TEMPORARY TABLES TO LOAD DATA IN FROM OBS GROUPS AS APPROPRIATE

## THIS EXPECTS A startDate AND endDate PARAMETER IN ORDER TO RESTRICT BY ENCOUNTERS WITHIN A GIVEN DATE RANGE
## THE EVALUATOR WILL INSERT THESE AS BELOW WHEN EXECUTING.  YOU CAN UNCOMMENT THE BELOW LINES FOR MANUAL TESTING:

## set @startDate='2019-01-01';
## set @endDate='2021-06-30';

## START BUILDING PATIENT TABLE.  LIMIT TO NON-TEST PATIENTS EVER ENROLLED IN THE MCH PROGRAM

drop temporary table if exists temp_patient;
create temporary table temp_patient
(
    patient_id     int primary key,
    dossier_num    varchar(50),
    zlemr_id       varchar(50),
    loc_registered varchar(255)
);

insert into temp_patient (patient_id)
select distinct pp.patient_id
from patient_program pp
         inner join program p on pp.program_id = p.program_id
where pp.voided = 0
  and p.name = 'MCH';

delete
from temp_patient
where patient_id in
      (
          select a.person_id
          from person_attribute a
                   inner join person_attribute_type t on a.person_attribute_type_id = t.person_attribute_type_id
          where a.value = 'true'
            and t.name = 'Test Patient'
      );

## ADD IDENTIFIERS TO PATIENT TABLE

update temp_patient p
    inner join
    (select i.patient_id, i.identifier
     from patient_identifier i
              inner join patient_identifier_type pit on i.identifier_type = pit.patient_identifier_type_id
     where i.voided = 0
       and pit.name = 'Nimewo Dosye'
     order by i.date_created asc
    ) dos
    on p.patient_id = dos.patient_id
set p.dossier_num = dos.identifier;

update temp_patient p
    inner join
    (select i.patient_id, i.identifier, l.name as location_name
     from patient_identifier i
              inner join patient_identifier_type pit on i.identifier_type = pit.patient_identifier_type_id
              inner join location l on i.location_id = l.location_id
     where i.voided = 0
       and pit.name = 'ZL EMR ID'
     order by i.date_created asc
    ) dos
    on p.patient_id = dos.patient_id
set p.zlemr_id       = dos.identifier,
    p.loc_registered = dos.location_name;


## START BUILDING VACCINATION TABLE

drop temporary table if exists temp_vaccinations;
create temporary table temp_vaccinations
(
    obs_group_id int primary key,
    encounter_id int,
    vaccine      char(38),
    dose_number  int,
    vaccine_date date
);

insert into temp_vaccinations (obs_group_id, encounter_id, vaccine)
select o.obs_group_id, o.encounter_id, a.uuid
from obs o,
     concept c,
     concept a
where o.concept_id = c.concept_id
  and o.value_coded = a.concept_id
  and c.uuid = '2dc6c690-a5fe-4cc4-97cc-32c70200a2eb' # Vaccinations
  and o.voided = 0;

insert into temp_vaccinations (obs_group_id, dose_number)
select o.obs_group_id, o.value_numeric
from obs o,
     concept c
where o.concept_id = c.concept_id
  and c.uuid = 'ef6b45b4-525e-4d74-bf81-a65a41f3feb9' # Vaccination Sequence Number
  and o.voided = 0
ON DUPLICATE KEY UPDATE dose_number = o.value_numeric;

insert into temp_vaccinations (obs_group_id, vaccine_date)
select o.obs_group_id, o.value_datetime
from obs o,
     concept c
where o.concept_id = c.concept_id
  and c.uuid = '1410AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' # Vaccine Date
  and o.voided = 0
ON DUPLICATE KEY UPDATE vaccine_date = o.value_datetime;

## BUILD ENCOUNTER TABLE.  THIS WILL REPRESENT THE ROWS IN THE EXPORT

drop temporary table if exists temp_encounter;
create temporary table temp_encounter
(
    encounter_id       int primary key,
    patient_id         int,
    dossier_num        varchar(50),
    zlemr_id           varchar(50),
    loc_registered     varchar(255),
    encounter_datetime datetime,
    encounter_location varchar(50),
    encounter_type     varchar(50),
    provider           varchar(500),
    bcg_1              datetime,
    polio_0            datetime,
    polio_1            datetime,
    polio_2            datetime,
    polio_3            datetime,
    polio_booster_1    datetime,
    polio_booster_2    datetime,
    pentavalent_1      datetime,
    pentavalent_2      datetime,
    pentavalent_3      datetime,
    rotavirus_1        datetime,
    rotavirus_2        datetime,
    mmr_1              datetime,
    tetanus_0          datetime,
    tetanus_1          datetime,
    tetanus_2          datetime,
    tetanus_3          datetime,
    tetanus_booster_1  datetime,
    tetanus_booster_2  datetime
);
insert into temp_encounter (encounter_id, patient_id, encounter_datetime, encounter_location, encounter_type, provider)
SELECT e.encounter_id,
       e.patient_id,
       e.encounter_datetime,
       el.name,
       et.name,
       CONCAT(pn.given_name, ' ', pn.family_name)
FROM temp_patient p
         INNER JOIN encounter e ON p.patient_id = e.patient_id
         INNER JOIN encounter_type et on e.encounter_type = et.encounter_type_id
         INNER JOIN location el ON e.location_id = el.location_id
         INNER JOIN encounter_provider ep ON ep.encounter_id = e.encounter_id and ep.voided = 0
         INNER JOIN provider pv ON pv.provider_id = ep.provider_id
         INNER JOIN person_name pn ON pn.person_id = pv.person_id and pn.voided = 0
WHERE e.voided = 0
  AND e.encounter_id in (select encounter_id from temp_vaccinations)
  AND et.uuid in (
                  '27d3a180-031b-11e6-a837-0800200c9a66', -- Primary Care Adult Initial Consult
                  '27d3a181-031b-11e6-a837-0800200c9a66', -- Primary Care Adult Followup Consult
                  '5b812660-0262-11e6-a837-0800200c9a66', -- Primary Care Pediatric Initial Consult
                  '229e5160-031b-11e6-a837-0800200c9a66', -- Primary Care Pediatric Followup Consult
                  'd83e98fd-dc7b-420f-aa3f-36f648b4483d' -- OB/GYN
    )
    AND e.encounter_datetime >= @startDate
    AND e.encounter_datetime < ADDDATE(@endDate, INTERVAL 1 DAY)
;

# BACILLE CAMILE-GUERIN VACCINATION

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3cd4e004-26fe-102b-80cb-0017a47871b2' and v.dose_number = 1
set e.bcg_1 = v.vaccine_date;

# ORAL POLIO VACCINATION

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2' and v.dose_number = 0
set e.polio_0 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2' and v.dose_number = 1
set e.polio_1 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2' and v.dose_number = 2
set e.polio_2 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2' and v.dose_number = 3
set e.polio_3 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2' and v.dose_number = 11
set e.polio_booster_1 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3cd42c36-26fe-102b-80cb-0017a47871b2' and v.dose_number = 12
set e.polio_booster_2 = v.vaccine_date;

# PENTAVALENT PNEUMOVAX

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '1423AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' and v.dose_number = 1
set e.pentavalent_1 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '1423AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' and v.dose_number = 2
set e.pentavalent_2 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '1423AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' and v.dose_number = 3
set e.pentavalent_3 = v.vaccine_date;

# ROTAVIRUS VACCINE

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '83531AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' and v.dose_number = 1
set e.rotavirus_1 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '83531AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' and v.dose_number = 2
set e.rotavirus_2 = v.vaccine_date;

# MEASLES/RUBELLA VACCINE

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '162586AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' and v.dose_number = 1
set e.rotavirus_1 = v.vaccine_date;

# DIPTHERIA / TETANUS

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2' and v.dose_number = 0
set e.tetanus_0 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2' and v.dose_number = 1
set e.tetanus_1 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2' and v.dose_number = 2
set e.tetanus_2 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2' and v.dose_number = 3
set e.tetanus_3 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2' and v.dose_number = 11
set e.tetanus_booster_1 = v.vaccine_date;

update temp_encounter e
    inner join temp_vaccinations v on e.encounter_id = v.encounter_id and
                                      v.vaccine = '3ccc6b7c-26fe-102b-80cb-0017a47871b2' and v.dose_number = 12
set e.tetanus_booster_2 = v.vaccine_date;

## EXECUTE FINAL SELECTION, JOINING ON ABOVE TABLES

SELECT p.patient_id,
       p.dossier_num       as dossierId,
       p.zlemr_id          as zlemr,
       p.loc_registered    as loc_registered,
       e.encounter_datetime,
       e.encounter_location,
       e.encounter_type,
       e.provider,
       e.bcg_1             as 'BCG dose 1',
       e.polio_0           as 'Polio dose 0',
       e.polio_1           as 'Polio dose 1',
       e.polio_2           as 'Polio dose 2',
       e.polio_3           as 'Polio dose 3',
       e.polio_booster_1   as 'Polio Booster 1',
       e.polio_booster_2   as 'Polio Booster 2',
       e.pentavalent_1     as 'Pentavalent dose 1',
       e.pentavalent_2     as 'Pentavalent dose 2',
       e.pentavalent_3     as 'Pentavalent dose 3',
       e.rotavirus_1       as 'Rotavirus dose 1',
       e.rotavirus_2       as 'Rotavirus dose 2',
       e.mmr_1             as 'Measles/Rubella dose 1',
       e.tetanus_0         as 'DT dose 0',
       e.tetanus_1         as 'DT dose 1',
       e.tetanus_2         as 'DT dose 2',
       e.tetanus_3         as 'DT dose 3',
       e.tetanus_booster_1 as 'DT Booster 1',
       e.tetanus_booster_2 as 'DT Booster 2'
FROM temp_encounter e
         INNER JOIN temp_patient p on e.patient_id = p.patient_id
;
