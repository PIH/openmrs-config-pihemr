SET sql_safe_updates = 0;

select concept_from_mapping('CIEL',138405) into @HIV;
select concept_from_mapping('CIEL',160538) into @pmtct;
select concept_from_mapping('CIEL',1691) into @prophylaxis;
select concept_from_mapping('CIEL',112992) into @sti;
select concept_from_mapping('CIEL',112141) into @tb;
select order_type_id into @drugOrder from order_type where uuid = '131168f4-15f5-102d-96e4-000c29c2a5d7';

drop temporary table if exists temp_HIV_regimens;
create temporary table temp_HIV_regimens
(
patient_id int(11),
order_id int(11),
previous_order_id int(11),
encounter_id int(11),
order_action varchar(50),
encounter_datetime datetime,
obs_group_id int(11),
art_treatment_line varchar(255),
drug_id int(11),
order_reason int(11),
drug_category varchar(20),
drug_short_name varchar(255),
drug_name varchar(255),
start_date datetime,
end_date datetime,
end_reasons varchar(255),
ptme_or_prophylaxis char(1),
regimen_line_original varchar(255),
index_ascending_patient int,
index_descending_patient int,
index_ascending_category int,
index_descending_category int
 );

 CREATE INDEX temp_HIV_regimens_patient_id ON temp_HIV_regimens (patient_id);
 CREATE INDEX temp_HIV_regimens_drug_category ON temp_HIV_regimens (drug_category);
 CREATE INDEX temp_HIV_regimens_date ON temp_HIV_regimens (start_date);
 
-- insert new orders
insert into temp_HIV_regimens (order_id, patient_id, order_action, encounter_id,drug_short_name,start_date, end_date, order_reason )
select order_id, patient_id, order_action, encounter_id, concept_name(concept_id, 'en'), date_activated, date_stopped, order_reason from orders o
where order_type_id = @drugOrder 
and order_reason in (@HIV, @pmtct, @prophylaxis, @sti, @tb)
and order_action in ('NEW')
and voided = 0
;

-- insert revisions, discontinues
insert into temp_HIV_regimens (order_id, patient_id, previous_order_id,order_action, encounter_id,drug_short_name,start_date, end_date, order_reason )
select o.order_id, o.patient_id, o.previous_order_id,o.order_action, o.encounter_id, concept_name(o.concept_id, 'en'), o.date_activated, o.date_stopped, o2.order_reason from orders o
inner join orders o2 on o2.order_id = o.previous_order_id 
  and o2.order_type_id = @drugOrder 
  and o2.order_reason in (@HIV, @pmtct, @prophylaxis, @sti, @tb)
  and o2.order_action in ('NEW')
  and o2.voided = 0
;

-- update stop date for expirations
update temp_HIV_regimens t
inner join orders o on o.order_id = t.order_id and o.auto_expire_date  and o.order_action = 'NEW'
set end_date = o.auto_expire_date,
    end_reasons = 'expired'
where t.end_date is null
;
-- encounter datetime
update temp_HIV_regimens t
inner join encounter e on e.encounter_id = t.encounter_id 
set t.encounter_datetime = e.encounter_datetime;

-- update drug info
update temp_HIV_regimens t
inner join drug_order do on do.order_id = t.order_id
set t.drug_id = do.drug_inventory_id;

update temp_HIV_regimens t
inner join drug d on d.drug_id = t.drug_id 
set t.drug_name = d.name;

-- add art treatment line  
update temp_HIV_regimens t
inner join obs o on o.voided =0 and o.encounter_id = t.encounter_id and o.concept_id = concept_from_mapping('CIEL','166073')
set art_treatment_line = concept_name(o.value_coded,'en'); 

-- end reason for discontinues
update temp_HIV_regimens t
inner join orders o on o.voided = 0 and o.previous_order_id = t.order_id and o.order_action = 'DISCONTINUE'
set t.end_reasons = concept_name(o.order_reason,'en')
where t.end_date is not null;

-- end reason for revisions
update temp_HIV_regimens t
inner join orders o on o.voided = 0 and o.previous_order_id = t.order_id and o.order_action = 'REVISE'
set t.end_reasons = 'Revised order'
where t.end_date is not null;

-- drug category
update temp_HIV_regimens 
set drug_category =
  CASE order_reason
    WHEN @HIV THEN 'ART'
    WHEN @pmtct THEN 'PMTCT'
    WHEN @prophylaxis THEN 'Prophylaxis'
    WHEN @sti THEN 'STI'
    WHEN @tb THEN 'TB'
  END  ;

-- ptme or prophylaxis column
update temp_HIV_regimens t
set ptme_or_prophylaxis =
  CASE WHEN drug_category in ('PMTCT','Prophylaxis') THEN '1' else '0' END;
  
-- indexes by patient/category
-- The ascending/descending indexes are calculated ordering on start date
-- new temp tables are used to build them and then joined into the main temp table. 
### index ascending
drop temporary table if exists temp_HIV_regimens_index_asc;
CREATE TEMPORARY TABLE temp_HIV_regimens_index_asc
(
    SELECT
            patient_id,
            order_id,
            drug_category,
            start_date,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id and (@v = drug_category or drug_category is null), @r + 1,1) index_asc,
            drug_category,
            start_date,
            order_id,
            patient_id,
            @u:= patient_id,
            @v:= drug_category
      FROM temp_HIV_regimens,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u,
                    (SELECT @v:= '') AS V
            ORDER BY patient_id, drug_category,start_date ASC, order_id ASC
        ) index_ascending_category );
        
CREATE INDEX tia_order_id ON temp_HIV_regimens_index_asc (order_id);        

update temp_HIV_regimens t
inner join temp_HIV_regimens_index_asc thia on thia.order_id = t.order_id
set index_ascending_category = thia.index_asc;

### index descending
drop temporary table if exists temp_HIV_regimens_index_desc;
CREATE TEMPORARY TABLE temp_HIV_regimens_index_desc
(
    SELECT
            patient_id,
            order_id,
            drug_category,
            start_date,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id and (@v = drug_category or drug_category is null), @r + 1,1) index_desc,
            drug_category,
            start_date,
            order_id,
            patient_id,
            @u:= patient_id,
            @v:= drug_category
      FROM temp_HIV_regimens,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u,
                    (SELECT @v:= '') AS V
            ORDER BY patient_id, drug_category,start_date DESC, order_id DESC
        ) index_descending_category );
        
CREATE INDEX tid_order_id ON temp_HIV_regimens_index_desc (order_id);    

update temp_HIV_regimens t
inner join temp_HIV_regimens_index_desc thia on thia.order_id = t.order_id
set index_descending_category = thia.index_desc;

-- indexes by patient
-- The ascending/descending indexes are calculated ordering on start date
-- new temp tables are us
### index patient ascending
drop temporary table if exists temp_patient_index_asc;
CREATE TEMPORARY TABLE temp_patient_index_asc
(
    SELECT
            patient_id,
            order_id,
            start_date,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            start_date,
            order_id,
            patient_id,
            @u:= patient_id
      FROM temp_HIV_regimens,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, start_date ASC, order_id ASC
        ) index_ascending_patient );

CREATE INDEX tpia_order_id ON temp_patient_index_asc (order_id);   

update temp_HIV_regimens t
inner join temp_patient_index_asc tpia on tpia.order_id = t.order_id
set index_ascending_patient = tpia.index_asc;


-- The ascending/descending indexes are calculated ordering on the dispense date
-- new temp tables are used to build them and then joined into the main temp table. 
### index patient ascending
drop temporary table if exists temp_patient_index_desc;
CREATE TEMPORARY TABLE temp_patient_index_desc
(
    SELECT
            patient_id,
            order_id,
            start_date,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            start_date,
            order_id,
            patient_id,
            @u:= patient_id
      FROM temp_HIV_regimens,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, start_date DESC, order_id DESC
        ) index_descending_patient );

CREATE INDEX tpid_order_id ON temp_patient_index_desc (order_id); 

update temp_HIV_regimens t
inner join temp_patient_index_desc tpid on tpid.order_id = t.order_id
set index_descending_patient = tpid.index_desc;

-- regimen line original
-- for the most current line (index_descending_category = 1) it uses the ART line from the first entry (index_ascending_category = 1)
drop temporary table if exists dup_HIV_regimens;
CREATE TEMPORARY TABLE dup_HIV_regimens SELECT * FROM temp_HIV_regimens;

update temp_HIV_regimens t
inner join dup_HIV_regimens d on d.patient_id = t.patient_id and d.drug_category = t.drug_category 
  and d.index_ascending_category = 1
set t.regimen_line_original = d.art_treatment_line
where t.index_descending_category = 1 and t.drug_category = 'ART';

-- select output
select
order_id,    
previous_order_id,
patient_id,
order_action,
encounter_id,
encounter_datetime,
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
index_ascending_category,
index_descending_category,
index_ascending_patient,
index_descending_patient
from temp_HIV_regimens
order by patient_id,  drug_category, encounter_datetime;
