# US-Household-Income-Analysis
Cleaning and Analyzing US Household Income Data in SQL

## What I Did
- Cleaned and standardized raw income data using SQL (typos, duplicates, formatting).
- Joined two datasets: general region data and income statistics.
- Analyzed patterns in land/water distribution, income by state, city, and community type.

## Tools Used
- MySQL / SQL Workbench
- CSV Imports
- Basic scripting for table creation, updates, and joins

## Key Insights
- Certain types of regions (like Boroughs and CDPs) have large variance in household income.
- Puerto Rico's "Community" designation stood out with significantly lower medians.
- Land and water mass correlated loosely with region type but had little correlation with income.

## Notes
- This was a full SQL-based project with no Python used for visualization
- Includes a stored procedure and cleanup trigger concept (commented due to SQL limitations)
- Data used was provided by my online course, Analyst Builder, and came from a pre-cleaned CSV with minor formatting issues.
