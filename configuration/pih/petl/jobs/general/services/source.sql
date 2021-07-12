select encounter_type_id into @examenes from encounter_type where uuid= 'b3a0e3ad-b80c-4f3f-9626-ace1ced7e2dd';/*26 test orders(lab)*/

drop temporary table if exists temp_services;
create temporary table temp_services
(
especialidad  varchar(20),
frecuencia_dias int,
frecuencia_semana int,
frecuencia_mes int,
frecuencia_manana int,
frecuencia_tarde int
);


set @YEAR=YEAR(NOW());

insert into temp_services (especialidad,frecuencia_dias,frecuencia_semana,frecuencia_mes,frecuencia_manana,frecuencia_tarde)
select 'examenes',(count(encounter_type))/251 as frecuencia_dia,
(count(encounter_type)/(WEEK(MAX(encounter_datetime)) - WEEK(MIN(encounter_datetime))+1)) as frecuencia_mes,
(count(encounter_type)/(MONTH(MAX(encounter_datetime))-MONTH(MIN(encounter_datetime))+1)) as frecuencia_mes,
(select count(encounter_type)/251 from encounter where HOUR (encounter_datetime) BETWEEN 01 AND 11 AND MINUTE (encounter_datetime) BETWEEN 00 AND 59 )as frecuencia_manana,
(select count(encounter_type)/251 from encounter where HOUR (encounter_datetime) BETWEEN 12 AND 23 AND MINUTE (encounter_datetime) BETWEEN 00 AND 59 ) as frecuencia_tarde
from encounter
where encounter_type=@examenes and YEAR(encounter_datetime) = @YEAR;

select 
especialidad,
frecuencia_dias,
frecuencia_semana,
frecuencia_mes,
frecuencia_manana,
frecuencia_tarde
from temp_services;