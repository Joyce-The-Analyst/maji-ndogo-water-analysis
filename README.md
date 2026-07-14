# Maji Ndogo Water Services Analysis

## Overview
This project investigates access to clean water, data quality issues, staff performance, corruption patterns, and infrastructure improvement planning for Maji Ndogo, using SQL.

## Tools Used
MySQL Workbench, Jupyter Notebook

## Project Parts

**01 - Data Exploration**
Initial exploration of the database, identifying data quality issues (e.g., wells wrongly marked "Clean" despite contamination), and correcting pollution records.

**02 - Clustering Analysis**
Cleaning employee data (emails, phone numbers), identifying top-performing field staff, analyzing water sources by location and type, and building a queue-time pivot table by day and hour.

**03 - Corruption Investigation**
Comparing independent auditor scores against original survey data to detect discrepancies, identifying employees with above-average error rates, and cross-referencing citizen statements for signs of bribery.

**04 - Improvement Action Plan**
Combining data across tables to calculate water access percentages by province and town, then building a system to automatically recommend infrastructure improvements (e.g., install RO filters, drill wells) based on water source conditions.

## Key Files
- `01_data_exploration.sql`
- `02_clustering_analysis.sql`
- `03_corruption_investigation.sql`
- `04_improvement_action_plan.sql`
- `queue_time_pivot_results.csv` — sample output from the Part 2 queue-time analysis
