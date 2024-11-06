/*
  This file contains stored procedures that are useful in writing reports
  For documentation on available procedures, please see the sql_function_reference.csv file in this directory
*/

-- You should uncomment this line to check syntax in IDE.  Liquibase handles this internally.
-- DELIMITER #

/*
Create table END_OF_MONTH_DATES that contains a row for each end-of-month date from 2000 to the current month
*/
#
DROP PROCEDURE IF EXISTS load_end_of_month_dates;
#
CREATE PROCEDURE load_end_of_month_dates(_start_date datetime, _end_date datetime 
)

BEGIN

drop table if exists END_OF_MONTH_DATES;
create table END_OF_MONTH_DATES
(
reporting_date date
);
	
set @month_counter = MONTH(_start_date);
set @year_counter = YEAR(_start_date);
 
WHILE last_day(CONCAT(@year_counter,'-',@month_counter,'-','01')) < _end_date DO

	INSERT INTO END_OF_MONTH_DATES
 		SELECT last_day(CONCAT(@year_counter,'-',@month_counter,'-','01'));
 
	SET @month_counter = @month_counter + 1;


	IF @month_counter = 13 THEN
		SET @month_counter = 1;
	 	SET @year_counter = @year_counter + 1;
	END IF;


END WHILE;

END
#
/* The following procedure will populate the temporary table temp_set_members
   with all of the set members in the sets in temporary table temp_sets
*/
#
DROP PROCEDURE IF EXISTS populate_set_members;
#
CREATE PROCEDURE populate_set_members()
BEGIN
	drop temporary table if exists temp_set_members;
	create temporary table temp_set_members
	select concept_id from concept_set
	where concept_set in (select concept_id from temp_sets);
END
#
/* The following procedure will populate the temporary table temp_lab_concepts
   with all of the labs that should be viewable and reportable.
   These are identified by concepts contained in sets that map up to the
   Lab Categories concept
*/
#
DROP PROCEDURE IF EXISTS populate_lab_concepts;
#
CREATE PROCEDURE populate_lab_concepts()
BEGIN

	set @labCategories = concept_from_mapping('PIH','11712');
	
	drop temporary table if exists temp_lab_concepts_staging ;
	create temporary table temp_lab_concepts_staging 
	(concept_id int(11));
	
	drop temporary table if exists temp_sets;
	create temporary table temp_sets
	select concept_id from concept_set cs 
	where concept_set = @labCategories; 
	
	call populate_set_members; 
	
	insert into temp_lab_concepts_staging(concept_id)
	select concept_id from temp_set_members;
	
	drop temporary table if exists temp_sets;
	create temporary table temp_sets
	select * from temp_set_members;
	
	call populate_set_members;
	
	insert into temp_lab_concepts_staging(concept_id)
	select concept_id from temp_set_members;
	
	drop temporary table if exists temp_sets;
	create temporary table temp_sets
	select * from temp_set_members;
	
	call populate_set_members;
	
	insert into temp_lab_concepts_staging (concept_id)
	select concept_id from temp_set_members;
	
	drop temporary table if exists temp_sets;
	create temporary table temp_sets
	select * from temp_set_members;
	
	call populate_set_members;
	
	insert into temp_lab_concepts_staging(concept_id)
	select concept_id from temp_set_members;
	
	drop temporary table if exists temp_lab_concepts;
	create temporary table temp_lab_concepts
	select distinct concept_id from temp_lab_concepts_staging; 
	
	create index temp_lab_concepts_ci on temp_lab_concepts(concept_id);
END
#
