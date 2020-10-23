SELECT encounter_type_id into @HIV_adult_intake from encounter_type where uuid = 'c31d306a-40c4-11e7-a919-92ebcb67fe33';
SELECT encounter_type_id into @HIV_adult_followup from encounter_type where uuid = 'c31d3312-40c4-11e7-a919-92ebcb67fe33';
SELECT encounter_type_id into @HIV_ped_intake from encounter_type where uuid = 'c31d3416-40c4-11e7-a919-92ebcb67fe33';
SELECT encounter_type_id into @HIV_ped_followup from encounter_type where uuid = 'c31d34f2-40c4-11e7-a919-92ebcb67fe33';

drop temporary table if exists temp_HIV_regimens;
create temporary table temp_HIV_regimens
(
patient_id int(11),
encounter_id int(11),
encounter_datetime datetime,
obs_id int(11),
obs_group_id int(11),
art_treatment_line varchar(255),
drug_id int(11),
drug_category varchar(20),
drug_short_name varchar(255),
drug_name varchar(255),
start_date datetime,
start_date_entered datetime,
end_date datetime,
end_date_entered datetime,
end_reasons varchar(255),
end_reasons_prev varchar(255),
ptme_or_prophylaxis char(1),
regimen_line_original varchar(255),
index_ascending int,
index_descending int
 );

create index temp_HIV_regimens_patient on temp_HIV_regimens (patient_id);
create index temp_HIV_regimens_obs on temp_HIV_regimens (obs_id);
create index temp_HIV_regimens_dc on temp_HIV_regimens (drug_category);
create index temp_HIV_regimens_ed on temp_HIV_regimens (encounter_datetime);
create index temp_HIV_regimens_ei on temp_HIV_regimens (encounter_id);


-- load all ART Regimen constructs into temp table 
insert into temp_HIV_regimens (patient_id, encounter_id, encounter_datetime, obs_group_id, obs_id, drug_category)
select person_id, encounter_id, obs_datetime, obs_id, obs_id,'ART'
from obs o
where o.voided = 0
and  concept_id =concept_from_mapping('PIH','6116');
 
-- load prophylaxes prescription constructs from the HIV encounters into temp table 
insert into temp_HIV_regimens (patient_id, encounter_id,encounter_datetime, obs_group_id,obs_id, ptme_or_prophylaxis,drug_category)
select o.person_id, o.encounter_id,encounter_datetime, o.obs_id,obs_id, '1','Prophylaxis'
from obs o
inner join encounter e on e.encounter_id = o.encounter_id and e.voided =0 
  and e.encounter_type in (@HIV_adult_intake,@HIV_adult_followup,@HIV_ped_intake,@HIV_ped_followup)
where o.voided =0
  and o.concept_id = concept_from_mapping('PIH','Prescription construct');
  
 -- load all TB Regimens into temp table 
insert into temp_HIV_regimens (patient_id, encounter_id,encounter_datetime, obs_id, drug_category, drug_short_name,ptme_or_prophylaxis)
select o.person_id, o.encounter_id, encounter_datetime, o.obs_id,'TB', concept_name(o.value_coded, 'en'), '1'
from obs o
inner join encounter e on e.encounter_id = o.encounter_id and e.voided =0 
  and e.encounter_type in (@HIV_adult_intake,@HIV_adult_followup,@HIV_ped_intake,@HIV_ped_followup)
where o.voided =0
  and o.concept_id = concept_from_mapping('PIH','6150');

-- add drug name
update temp_HIV_regimens t
inner join obs o on o.voided =0 and o.obs_group_id = t.obs_group_id and o.concept_id = concept_from_mapping('PIH','1282')
set drug_name = drugname(o.value_drug);
  
-- add drug short name  
update temp_HIV_regimens t
inner join obs o on o.voided =0 and o.obs_group_id = t.obs_group_id and o.concept_id = concept_from_mapping('PIH','1282')
set drug_short_name = concept_name(o.value_coded,'en')
;

-- add art treatment line  
update temp_HIV_regimens t
inner join obs o on o.voided =0 and o.obs_group_id = t.obs_group_id and o.concept_id = concept_from_mapping('CIEL','166073')
set art_treatment_line = concept_name(o.value_coded,'en'); 

-- add entered start date for ART meds
-- note this is also safeguarding against dates that are valid in oracle and mysql but not SQL Server (very high or low dates)
update temp_HIV_regimens t
left outer join obs o on o.voided =0 and o.encounter_id= t.encounter_id and  o.concept_id = concept_from_mapping('PIH','2516')
set start_date_entered = if(o.value_datetime>'1900-01-01' and o.value_datetime<'2100-01-01',o.value_datetime,null)
where drug_category = 'ART';

-- add entered start date for TB meds
-- note this is also safeguarding against dates that are valid in oracle and mysql but not SQL Server (very high or low dates)
update temp_HIV_regimens t
left outer join obs o on o.voided =0 and o.encounter_id= t.encounter_id and  o.concept_id = concept_from_mapping('PIH','1113')
set start_date_entered = if(o.value_datetime>'1900-01-01' and o.value_datetime<'2100-01-01',o.value_datetime,null)
where drug_category = 'TB';

-- add entered start date for Prophylaxes meds
-- note this is also safeguarding against dates that are valid in oracle and mysql but not SQL Server (very high or low dates)
update temp_HIV_regimens t
left outer join obs o on o.voided =0 and o.obs_group_id= t.obs_group_id and  o.concept_id = concept_from_mapping('CIEL','163526')
set start_date_entered = if(o.value_datetime>'1900-01-01' and o.value_datetime<'2100-01-01',o.value_datetime,null)
where drug_category = 'Prophylaxis';

-- entered end date
-- note this is also safeguarding against dates that are valid in oracle and mysql but not SQL Server (very high or low dates)
update temp_HIV_regimens t
left outer join obs o on o.voided =0 and o.obs_group_id= t.obs_group_id and  o.concept_id = concept_from_mapping('CIEL','164384')
set end_date_entered = if(o.value_datetime>'1900-01-01' and o.value_datetime<'2100-01-01',o.value_datetime,null)
where drug_category = 'Prophylaxis';

-- add reason stopped art 
-- we are retrieve these as the "previous" end_reasons because for ART, these are entered as the next med is prescribed
update temp_HIV_regimens t
inner join (select group_concat(concept_name(o2.value_coded, 'en')) reasons, o2.encounter_id from obs o2 where o2.voided = 0 and o2.concept_id = concept_from_mapping('PIH','1252') group by o2.encounter_id) ij
  on ij.encounter_id = t.encounter_id  
set end_reasons_prev = ij.reasons
where drug_category = 'ART';

-- add reasons stopped prohylaxis
update temp_HIV_regimens t
inner join obs o on o.voided =0 and o.obs_group_id= t.obs_group_id and  o.concept_id = concept_from_mapping('PIH','1812')
set end_reasons = concept_name(o.value_coded, 'en')
where drug_category = 'Prophylaxis';

-- The ascending/descending indexes are calculated ordering on the dispense date
-- new temp tables are used to build them and then joined into the main temp table. 
### index ascending
drop temporary table if exists temp_HIV_regimens_index_asc;
CREATE TEMPORARY TABLE temp_HIV_regimens_index_asc
(
    SELECT
            patient_id,
            obs_id,
            drug_category,
            encounter_datetime,
            encounter_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id and (@v = drug_category or drug_category is null), @r + 1,1) index_asc,
            drug_category,
            encounter_datetime,
            encounter_id,
            obs_id,
            patient_id,
            @u:= patient_id,
            @v:= drug_category
      FROM temp_HIV_regimens,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u,
                    (SELECT @v:= '') AS V
            ORDER BY patient_id, drug_category,encounter_datetime ASC, encounter_id ASC, obs_id asc
        ) index_ascending );

update temp_HIV_regimens t
inner join temp_HIV_regimens_index_asc thia on thia.obs_id = t.obs_id
set index_ascending = thia.index_asc;

### index descending
drop temporary table if exists temp_HIV_regimens_index_desc;
CREATE TEMPORARY TABLE temp_HIV_regimens_index_desc
(
    SELECT
            patient_id,
            obs_id,
            drug_category,
            encounter_datetime,
            encounter_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id and (@v = drug_category or drug_category is null), @r + 1,1) index_desc,
            drug_category,
            encounter_datetime,
            encounter_id,
            obs_id,
            patient_id,
            @u:= patient_id,
            @v:= drug_category
      FROM temp_HIV_regimens,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u,
                    (SELECT @v:= '') AS V
            ORDER BY patient_id, drug_category,encounter_datetime DESC, encounter_id DESC, obs_id DESC
        ) index_descending );

update temp_HIV_regimens t
inner join temp_HIV_regimens_index_desc thia on thia.obs_id = t.obs_id
set index_descending = thia.index_desc;

-- end_reasons
-- for ART, this copies the end_reasons_prev to the previus row
-- duplicate table is created to join in a copy of the table to do this (limitation of MYSQL)
drop temporary table if exists dup_HIV_regimens;
CREATE TEMPORARY TABLE dup_HIV_regimens SELECT * FROM temp_HIV_regimens;

update temp_HIV_regimens t
inner join dup_HIV_regimens d on d.patient_id = t.patient_id and d.drug_category = t.drug_category 
  and t.index_ascending = d.index_ascending -1
set t.end_reasons = d.end_reasons_prev;

-- regimen line original
-- for the most current line (index_descending = 1) it uses the ART line from the first entry (index_ascending = 1)
update temp_HIV_regimens t
inner join dup_HIV_regimens d on d.patient_id = t.patient_id and d.drug_category = t.drug_category 
  and d.index_ascending = 1
set t.regimen_line_original = d.art_treatment_line
where t.index_descending = 1 and t.drug_category = 'ART';

-- to calculate the drug start date, the logic is:
-- if the start_date is explicitly entered, use that
-- otherwise, whenever there is a new drug assigned for a patient, use the encounter_datetime
-- otherwise null
drop temporary table if exists temp_regimen_start_date;
CREATE TEMPORARY TABLE temp_regimen_start_date
SELECT
 --           @ts:= IF(@u <> patient_id or @td <> drug_short_name  ,@ts:=if(start_date_entered is null, encounter_datetime, start_date_entered) ,null) start_date,
            CASE
              WHEN start_date_entered is not null THEN start_date_entered
              WHEN @u <> patient_id or @td <> drug_short_name THEN encounter_datetime
              ELSE null
            END start_date,  
            start_date_entered,
            encounter_id,
            drug_category,
            encounter_datetime,
            @u:= patient_id,
            @td:=drug_short_name as drug_short_name
      FROM temp_HIV_regimens,
                    (SELECT @ts:= '1900-01-01') AS ts,
                    (SELECT @u:= 0) AS u,
                    (SELECT @td:='') as td
            ORDER BY patient_id, drug_category, encounter_datetime ASC, encounter_id ASC; 

update temp_HIV_regimens t
inner join temp_regimen_start_date ts on ts.encounter_id = t.encounter_id and ts.drug_short_name= t.drug_short_name
set t.start_date = ts.start_date;

-- to calculate the drug end_date, the logic is:
-- if the end_date is entered for a specific drug, always use that
-- otherwise if, for the same patient and drug category a new med is prescribed use the start date of the next drug 
--         (this is why we need to cycle through the rows in reverse chronological order
-- otherwise, no end_date 
drop temporary table if exists temp_regimen_end_date;
CREATE TEMPORARY TABLE temp_regimen_end_date
SELECT
            CASE
              WHEN end_date_entered is not null THEN end_date_entered
              WHEN @u = patient_id and @dc= drug_category and @td <> drug_short_name THEN @ts
              ELSE null
            END end_date,
            end_date_entered,
            encounter_id,
            encounter_datetime,
            @u:= patient_id,
            @td:=drug_short_name as drug_short_name,
            @dc:=drug_category as drug_category,
            @ts:=start_date
      FROM temp_HIV_regimens,
                    (SELECT @ts:= '1900-01-01') AS ts,
                    (SELECT @u:= 0) AS u,
                    (SELECT @td:='') as td,
                    (SELECT @dc:='') as dc
            ORDER BY patient_id, drug_category,encounter_datetime DESC, encounter_id DESC; 

update temp_HIV_regimens t
inner join temp_regimen_end_date ts on ts.encounter_id = t.encounter_id and ts.drug_short_name= t.drug_short_name
set t.end_date = ts.end_date;

-- select output
select
obs_id,                                
patient_id,
encounter_id,
drug_category,
art_treatment_line,
drug_id,
drug_short_name,
drug_name,
start_date,
end_date,
end_reasons,
ptme_or_prophylaxis,
regimen_line_original,
index_ascending,
index_descending
from temp_HIV_regimens
order by patient_id, drug_category, encounter_datetime;
