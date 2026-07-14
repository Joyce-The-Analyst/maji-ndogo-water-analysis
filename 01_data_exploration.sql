-- MAJI NDOGO: PART 1 - BEGINNING OUR DATA-DRIVEN JOURNEY

-- 1. GET TO KNOW OUR DATA

SHOW TABLES;

SELECT * 
FROM location 
LIMIT 5;
SELECT * 
FROM visits 
LIMIT 5;
SELECT * 
FROM water_source 
LIMIT 5;
SELECT * 
FROM water_quality 
LIMIT 5;
SELECT * 
FROM well_pollution 
LIMIT 5;
SELECT * 
FROM global_water_access 
LIMIT 5;
SELECT * 
FROM employee 
LIMIT 5;

-- Data dictionary (explains every column in the database)
SELECT * 
FROM data_dictionary;


-- 2. DIVE INTO THE WATER SOURCES

-- Find all unique types of water sources
SELECT DISTINCT type_of_water_source
FROM water_source;


-- 3. UNPACK THE VISITS TO WATER SOURCES

-- Find visits with a crazy long queue time (> 500 minutes)
SELECT *
FROM visits
WHERE time_in_queue > 500;

-- Check what type of source some of those long-queue source_ids are
SELECT *
FROM water_source
WHERE source_id IN (
    'AkKi00881224',
    'SoRu37635224',
    'SoRu36096224',
    'AkRu05234224',
    'HaZa21742224'
);


-- 4. ASSESS THE QUALITY OF WATER SOURCES

-- Find records where subjective_quality_score = 10, only for home taps,
-- where the source was visited more than once
SELECT *
FROM water_quality
WHERE subjective_quality_score = 10
  AND visit_count > 1;


-- 5. INVESTIGATE POLLUTION ISSUES
-- First look at the well_pollution table
SELECT *
FROM well_pollution
LIMIT 5;

-- results says 'Clean' but biological contamination > 0.01
SELECT *
FROM well_pollution
WHERE results = 'Clean'
  AND biological > 0.01;

-- Find all descriptions that mistakenly start with "Clean" but have more text after
SELECT *
FROM well_pollution
WHERE description LIKE 'Clean_%';




-- FIXING THE DATA 
-- Step 1: Create a copy of well_pollution to test on
CREATE TABLE
    md_water_services.well_pollution_copy
AS (
    SELECT *
    FROM md_water_services.well_pollution
);

-- Step 2: Run the fixes on the COPY

-- Case 1a: Fix descriptions that mistakenly say 'Clean Bacteria: E. coli'
UPDATE
    well_pollution_copy
SET
    description = 'Bacteria: E. coli'
WHERE
    description = 'Clean Bacteria: E. coli';

-- Case 1b: Fix descriptions that mistakenly say 'Clean Bacteria: Giardia Lamblia'
UPDATE
    well_pollution_copy
SET
    description = 'Bacteria: Giardia Lamblia'
WHERE
    description = 'Clean Bacteria: Giardia Lamblia';

-- Case 2: Fix results wrongly marked 'Clean' when biological > 0.01
UPDATE
    well_pollution_copy
SET
    results = 'Contaminated: Biological'
WHERE
    biological > 0.01 AND results = 'Clean';

-- Step 3: Verify the fix worked
SELECT
    *
FROM
    well_pollution_copy
WHERE
    description LIKE 'Clean_%'
    OR (results = 'Clean' AND biological > 0.01);

-- Step 4:  apply the SAME updates to the real table
UPDATE
    well_pollution
SET
    description = 'Bacteria: E. coli'
WHERE
    description = 'Clean Bacteria: E. coli';

UPDATE
    well_pollution
SET
    description = 'Bacteria: Giardia Lamblia'
WHERE
    description = 'Clean Bacteria: Giardia Lamblia';

UPDATE
    well_pollution
SET
    results = 'Contaminated: Biological'
WHERE
    biological > 0.01 AND results = 'Clean';

-- Step 5: Clean up — drop the copy table 
DROP TABLE
    md_water_services.well_pollution_copy;
