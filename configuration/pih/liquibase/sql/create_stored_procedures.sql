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
