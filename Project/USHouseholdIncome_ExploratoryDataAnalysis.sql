# US Household Income Project (Exploratory Data Analysis)
# P0. Prepping

# 1. To Do's
-- Set up Database & Tables x2
-- Remove Duplicates
-- Add ID Column
-- Correct Data Types

# 2. Create Database & Tables
CREATE DATABASE world_life_expectancy;
-- To insert the initial .csv data set I used the 'Table Data Import Wizard.'

Select *, ROW_NUMBER() OVER()
FROM us_household_income
ORDER BY State_Name;

Select *, ROW_NUMBER() OVER()
FROM us_household_income_statistics
ORDER BY State_Name;

# Creating Backups
CREATE TABLE us_household_income_backup LIKE us_household_income;
INSERT INTO us_household_income_backup SELECT * FROM us_household_income;

CREATE TABLE us_household_income_statistics_backup LIKE us_household_income_statistics;
INSERT INTO us_household_income_statistics_backup SELECT * FROM us_household_income_statistics;

# Checking Backups
Select *, ROW_NUMBER() OVER()
FROM us_household_income
ORDER BY State_Name;

Select *, ROW_NUMBER() OVER()
FROM us_household_income_statistics
ORDER BY State_Name;

-- ----------------------------------------------------------------------------------------------
# P1. Data Cleaning

# A. Fix the first column name in the statistics table.
ALTER TABLE us_household_income_statistics
RENAME COLUMN `ï»¿id` to `id`;

# B. Check the number of entries missed during import.
SELECT 
(SELECT Count(id) FROM us_household_income) household_income_entries,
(SELECT Count(id) FROM us_household_income_statistics) statistics_entries,
((SELECT Count(id) FROM us_household_income_statistics) - (SELECT Count(id) FROM us_household_income)) missing_household_income_entries;
-- For this project we are not going to worry about the missing data unless it becomes necessary later.

Select *
FROM us_household_income
ORDER BY State_Name;

Select *
FROM us_household_income_statistics
ORDER BY State_Name;

# C. Check for duplicate entries.
SELECT id, COUNT(id)
FROM us_household_income
GROUP BY ID
HAVING COUNT(ID) > 1;

# Single out the duplicates
SELECT *
FROM (
	SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
	FROM us_household_income) duplicates
WHERE row_num > 1;

# Delete duplicates
DELETE FROM us_household_income
WHERE row_id IN (
	SELECT row_id
	FROM (
		SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
		FROM us_household_income) duplicates
	WHERE row_num > 1);

# D. Repeat for Statistics Table
SELECT id, COUNT(id)
FROM us_household_income_statistics
GROUP BY ID
HAVING COUNT(ID) > 1;
-- There are no duplicates so we don't need to remove any entries.

# E. Check for misspelled state names (saw some with improper capitalization).
SELECT State_Name
FROM us_household_income
GROUP BY State_Name;
-- Included misspellings, but no capitalization errors.

SELECT DISTINCT State_Name
FROM us_household_income
ORDER BY State_Name;

# Fix alabama capitalization.
UPDATE us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

# Fix other misspellings
UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

# F. Check for misspelled state abreviations
SELECT DISTINCT State_ab
FROM us_household_income
ORDER BY State_ab;
-- All looks good!

# G. Find any missing Counties, Cities, & Places
SELECT *
FROM us_household_income;

SELECT *
FROM us_household_income
WHERE Place = ''
OR County = ''
OR City = '';
-- Looks like just 1 error. We can update on the County + City.

SELECT *
FROM us_household_income
WHERE County = 'Autauga County'
ORDER BY City
;

UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County' AND City = 'Vinemont';
-- Wonderful, everything looks fixed!

# H. Checking the Type column:
SELECT *
FROM us_household_income;

SELECT `Type`, COUNT(`Type`)
FROM us_household_income
GROUP BY `Type`;
-- We can make an educated guess that Boroughs should be in the Borough category. We'll leave CDP and CPD for now as we don't know for certain if they are the same or not.

UPDATE us_household_income
SET `Type` = 'Borough'
WHERE `Type` = 'Boroughs';

# I. Checking that all entries exist (having land or water)
SELECT *
FROM us_household_income;

SELECT ALand, AWATER
FROM us_household_income
WHERE (AWater = 0 OR AWater = '' OR AWater IS NULL)
AND (ALand = 0 OR ALand = '' OR ALand IS NULL);
-- Looks good!

-- ----------------------------------------------------------------------------------------------
# P2. Exploratory Data Analysis

SELECT *
FROM us_household_income;

SELECT *
FROM us_household_income_statistics;

# This data is less based on time (like my previous project) and is more categorical.
# A. Ranking states based on their statistical data (landmass, watermass, etc.)
SELECT State_Name, County, City, ALand, AWater
FROM us_household_income;

# Narrow down to just states. Order by Total Land (most to least).
SELECT ROW_NUMBER() OVER(ORDER BY SUM(ALand) DESC) 'Rank', State_Name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_Name;

# Order by Total Water (most to least).
SELECT ROW_NUMBER() OVER(ORDER BY SUM(AWater) DESC) 'Rank', State_Name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_Name;

# Find just the top 10 of each
SELECT ROW_NUMBER() OVER(ORDER BY SUM(ALand) DESC) 'Rank', State_Name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_Name
LIMIT 10;

SELECT ROW_NUMBER() OVER(ORDER BY SUM(AWater) DESC) 'Rank', State_Name, SUM(ALand), SUM(AWater)
FROM us_household_income
GROUP BY State_Name
LIMIT 10;

# B. Comparing data from both tables.
SELECT *
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id;

# Finding data not present in both tables.
SELECT *
FROM us_household_income hi
RIGHT JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE hi.id IS NULL;
-- Although in some data sets we may want to populate these nulls or remove the extra entries, we are going to continue on with them unchanged for now.

# Filter out empty data.
SELECT *
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE (Mean != 0 OR Median != 0 OR Stdev != 0 OR sum_w != 0);

# C. Looking at Mean & Median
SELECT hi.State_Name, County, `Type`, `Primary`, Mean, Median
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE (Mean != 0 OR Median != 0 OR Stdev != 0 OR sum_w != 0);

# States ranked by average household income.
SELECT ROW_NUMBER() OVER(ORDER BY AVG(Mean) DESC) 'Rank', hi.State_Name, ROUND(AVG(Mean), 2), ROUND(AVG(Median), 2)
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE (Mean != 0 OR Median != 0 OR Stdev != 0 OR sum_w != 0)
GROUP BY hi.State_Name
ORDER BY 3 DESC;

# States ranked by average median household income.
SELECT ROW_NUMBER() OVER(ORDER BY AVG(Median) DESC) 'Rank', hi.State_Name, ROUND(AVG(Mean), 2), ROUND(AVG(Median), 2)
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE (Mean != 0 OR Median != 0 OR Stdev != 0 OR sum_w != 0)
GROUP BY hi.State_Name
ORDER BY 4 DESC;

# D. Looking at Type.
SELECT ROW_NUMBER() OVER(ORDER BY AVG(Mean) DESC) 'Rank', hi.`Type`, COUNT(hi.`Type`), ROUND(AVG(Mean), 2), ROUND(AVG(Median), 2)
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE (Mean != 0 OR Median != 0 OR Stdev != 0 OR sum_w != 0)
GROUP BY hi.`Type`
ORDER BY 4 DESC;
-- Here we can see how often each region type occurs and which has the highest average household income.

# Average Median Income.
SELECT ROW_NUMBER() OVER(ORDER BY AVG(Median) DESC) 'Rank', hi.`Type`, COUNT(hi.`Type`), ROUND(AVG(Mean), 2), ROUND(AVG(Median), 2)
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE (Mean != 0 OR Median != 0 OR Stdev != 0 OR sum_w != 0)
GROUP BY hi.`Type`
ORDER BY 5 DESC;
-- Noticing Community ranking really low. Let's see what states this Type falls under.

SELECT State_Name, COUNT(`Type`)
FROM us_household_income
WHERE `Type` = 'Community'
GROUP BY State_Name;
-- Looks like they are all from Puerto Rico. Interesting that this is a category here and nowhere else.

# Remove outlayers (looking only at groups with higher counts)
SELECT ROW_NUMBER() OVER(ORDER BY AVG(Median) DESC) 'Rank', hi.`Type`, COUNT(hi.`Type`), ROUND(AVG(Mean), 2), ROUND(AVG(Median), 2)
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE (Mean != 0 OR Median != 0 OR Stdev != 0 OR sum_w != 0)
GROUP BY hi.`Type`
HAVING COUNT(hi.`Type`) > 100
ORDER BY 5 DESC;
-- Whether or not you should do this depends on the data set.

# E. Looking at Cities average income.
SELECT ROW_NUMBER() OVER(ORDER BY AVG(Mean) DESC) 'Rank', hi.State_Name, City, ROUND(AVG(Mean),2), ROUND(AVG(Median),2)
FROM us_household_income hi
JOIN us_household_income_statistics s
	ON hi.id = s.id
WHERE (Mean != 0 OR Median != 0 OR Stdev != 0 OR sum_w != 0)
GROUP BY hi.State_Name, City
ORDER BY ROUND(AVG(Mean),2) DESC;
