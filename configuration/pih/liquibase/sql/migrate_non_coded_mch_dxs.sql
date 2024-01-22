/*
 * This is a one-time script to migrate several diagnoses entered
 * as non-coded int he past that should now be coded
 */

-- set up translation table for diagnoses
drop temporary table if exists dx_translations;
create temporary table dx_translations
(non_coded_dx text,
code_dx       int(11)
);

insert into dx_translations (non_coded_dx, code_dx)
values
	('Phase expulsive du travail',concept_from_mapping('CIEL','163506')),
	('algie pelvienne',concept_from_mapping('CIEL','131034')),
	('IGU prob.',concept_from_mapping('PIH','15052')),
	('IGU pb',concept_from_mapping('PIH','15052')),
	('epigastralgie',concept_from_mapping('CIEL','141128')),
	('IGU',concept_from_mapping('PIH','15052')),
	('uc1',concept_from_mapping('CIEL','168593')),
	('IGU prob',concept_from_mapping('PIH','15052')),
	('UC2',concept_from_mapping('CIEL','168594')),
	('UTERUS MYOMATEUX',concept_from_mapping('CIEL','123455')),
	('Mycose vaginale',concept_from_mapping('CIEL','298')),
	('Uc1 ancien',concept_from_mapping('CIEL','168593')),
	('HTA chronique',concept_from_mapping('CIEL','168592')),
	('PES stab.',concept_from_mapping('CIEL','168611')),
	('uterus polymyomateux',concept_from_mapping('CIEL','123455')),
	('IGU probable',concept_from_mapping('PIH','15052')),
	('Phase expulsive',concept_from_mapping('CIEL','163506')),
	('Uc1 recent',concept_from_mapping('CIEL','168593')),
	('SUA',concept_from_mapping('CIEL','141631')),
	('Infection genito-urinaire',concept_from_mapping('PIH','15052')),
	('Infection génito urinaire pb',concept_from_mapping('PIH','15052')),
	('OMPK synd',concept_from_mapping('CIEL','129569')),
	('Algie pelvienne chronique',concept_from_mapping('CIEL','155579')),
	('Mycose vag',concept_from_mapping('CIEL','298')),
	('ASCUS',concept_from_mapping('CIEL','145822')),
	('suivi post op',concept_from_mapping('CIEL','159007')),
	('BDCFNR',concept_from_mapping('CIEL','168595')),
	('INFECTION GENITO URINAIRE',concept_from_mapping('PIH','15052')),
	('infertilite primaire',concept_from_mapping('CIEL','129123')),
	('OMPK',concept_from_mapping('CIEL','129569')),
	('Perimenopause',concept_from_mapping('CIEL','160595')),
	('IGU a inv',concept_from_mapping('PIH','15052')),
	('Masse ovarienne',concept_from_mapping('CIEL','152755')),
	('PES stabilisée',concept_from_mapping('CIEL','168611')),
	('Infertilite secondaire',concept_from_mapping('CIEL','126976')),
	('Infection génito urinaire',concept_from_mapping('PIH','15052')),
	('HTAc',concept_from_mapping('CIEL','168592')),
	('gardnerella vaginalis',concept_from_mapping('CIEL','139633')),
	('PES prob.',concept_from_mapping('CIEL','113006')),
	('AGUS',concept_from_mapping('CIEL','155209')),
	('PCOS',concept_from_mapping('CIEL','129569')),
	('HTA non controlee',concept_from_mapping('CIEL','165587')),
	('anamnios',concept_from_mapping('CIEL','168588')),
	('BDCF non rassurant',concept_from_mapping('CIEL','168595')),
	('uc2 ancien',concept_from_mapping('CIEL','168594')),
	('anemie probable',concept_from_mapping('CIEL','121629')),
	('douleur epigastrique',concept_from_mapping('CIEL','141128')),
	('PES stab',concept_from_mapping('CIEL','168611'))
;

-- create table of all obs to void and recreate
drop temporary table if exists non_coded_obs;
create temporary table non_coded_obs
(obs_id                 int(11),     
person_id               int(11),     
concept_id              int(11),     
encounter_id            int(11),     
obs_datetime            datetime,    
location_id             int(11),     
obs_group_id            int(11),     
value_text              text,        
creator                 int(11),     
date_created            datetime,    
status                  varchar(16), 
destination_coded_value int(11)      
);

-- insert all obs to void and recreate based on non-coded dxs (ignoring case and spacing)
insert into non_coded_obs (
	obs_id,
	person_id,
	concept_id,
	encounter_id,
	obs_datetime,
	location_id,
	obs_group_id,
	value_text,
	creator,
	date_created,
	status,
	destination_coded_value)
select 
	o.obs_id,
	o.person_id,
	o.concept_id,
	o.encounter_id,
	o.obs_datetime,
	o.location_id,
	o.obs_group_id,
	o.value_text,
	o.creator,
	o.date_created,
	o.status, 
	d.code_dx 
from obs o 
 inner join dx_translations d on 
	upper(trim(d.non_coded_dx)) = upper(trim(o.value_text))
where o.concept_id = concept_from_mapping('CIEL','161602')
and voided = 0
;

-- void non-coded obs
update obs o
inner join non_coded_obs n on n.obs_id = o.obs_id 
set o.voided = 1,
	voided_by = 1,
	date_voided = now(),
	void_reason = 'migrated to coded mch dx';
	
-- insert coded obs
insert into obs (
	person_id,
	concept_id,
	encounter_id,
	obs_datetime,
	location_id,
	obs_group_id,
	creator,
	date_created,
	status,
	value_coded,
	previous_version,
	uuid)
select 
	person_id,
	concept_from_mapping('CIEL','1284'),
	encounter_id,
	obs_datetime,
	location_id,
	obs_group_id,
	creator,
	date_created,
	status,
	destination_coded_value,
	obs_id,
	uuid()
from non_coded_obs;
