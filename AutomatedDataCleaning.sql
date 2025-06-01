-- Create our Stored Procedure
DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN
-- Creating our Table
	CREATE TABLE IF NOT EXISTS `us_household_income_cleaned` (
	  `row_id` int DEFAULT NULL,
	  `id` int DEFAULT NULL,
	  `State_Code` int DEFAULT NULL,
	  `State_Name` text,
	  `State_ab` text,
	  `County` text,
	  `City` text,
	  `Place` text,
	  `Type` text,
	  `Primary` text,
	  `Zip_Code` int DEFAULT NULL,
	  `Area_Code` int DEFAULT NULL,
	  `ALand` int DEFAULT NULL,
	  `AWater` int DEFAULT NULL,
	  `Lat` double DEFAULT NULL,
	  `Lon` double DEFAULT NULL,
	  `TimeStamp` TIMESTAMP DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Copy Date to New Table
	INSERT INTO us_household_income_cleaned
    SELECT *, CURRENT_TIMESTAMP
    FROM bakery.us_household_income;
    
-- Remove Duplicates
	DELETE FROM us_household_income_cleaned
	WHERE 
		row_id IN (
		SELECT row_id
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id, `TimeStamp`
				ORDER BY id) AS row_num
		FROM 
			us_household_income_cleaned
	) duplicates
	WHERE 
		row_num > 1
	);

-- Fixing some data quality issues by fixing typos and general standardization
	UPDATE us_household_income_cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE us_household_income_cleaned
	SET County = UPPER(County);

	UPDATE us_household_income_cleaned
	SET City = UPPER(City);

	UPDATE us_household_income_cleaned
	SET Place = UPPER(Place);

	UPDATE us_household_income_cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE us_household_income_cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE us_household_income_cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';
END $$
DELIMITER ;

CALL Copy_and_Clean_Data();

SELECT *
FROM us_household_income_cleaned;

SELECT DISTINCT timestamp
FROM us_household_income_cleaned;

-- Create Event
CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 2 minute
    DO CALL Copy_and_Clean_Data();

DROP EVENT run_data_cleaning;

SHOW EVENTS;

-- -------------------------------------------------------------------------------------------------------

-- Testing & Debugging
	SELECT row_id, id, row_num
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id
				ORDER BY id) AS row_num
		FROM 
			us_household_income
	) duplicates
	WHERE 
		row_num > 1;

	SELECT row_id, id, row_num
	FROM (
		SELECT row_id, id,
			ROW_NUMBER() OVER (
				PARTITION BY id
				ORDER BY id) AS row_num
		FROM 
			us_household_income_cleaned
	) duplicates
	WHERE 
		row_num > 1;
        
SELECT COUNT(row_id)
FROM us_household_income;

SELECT COUNT(row_id)
FROM us_household_income_cleaned;

SELECT State_Name, COUNT(State_Name)
FROM us_household_income
GROUP BY State_Name;

SELECT State_Name, COUNT(State_Name)
FROM us_household_income_cleaned
GROUP BY State_Name;

-- -------------------------------------------------------------------------------------------------------

-- Create a Trigger instead of an Event?
DELIMITER $$
CREATE TRIGGER transfer_clean_data
	AFTER INSERT ON bakery.us_household_income
    FOR EACH ROW -- Remember, MySQL doesn't have a batch insert function like some editors. :(
BEGIN
	CALL Copy_and_Clean_Data();
END $$
DELIMITER ;

-- Cannot use this CALL function within a TRIGGER because it contains a "Commit Statement" (CREATE TABLE, UPDATE, etc.)
-- TRIGGERS cannot run stored procedures with commit statements.

DROP TRIGGER transfer_clean_data;
