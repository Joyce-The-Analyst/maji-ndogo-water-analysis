-- MAJI NDOGO: PART 2 - CLUSTERING DATA TO UNVEIL

-- 1. CLEANING OUR DATA — Updating employee data


-- Check the format for creating email addresses
-- Step 1: Replace space with a full stop
SELECT
    REPLACE(employee_name, ' ', '.') 
FROM
    employee;

-- Step 2: Make it all lower case
SELECT
    LOWER(REPLACE(employee_name, ' ', '.')) 
FROM
    employee;

-- Step 3: Concatenate to build the full email address
SELECT
    CONCAT(
        LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS new_email 
FROM
    employee;

-- Step 4: UPDATE the employee table with the new email addresses
UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),
                    '@ndogowater.gov');

-- check if it worked
SELECT email FROM employee LIMIT 10;


-- Check the phone_number column for formatting issues
SELECT
    LENGTH(phone_number)
FROM
    employee;
-- Returns 13 characters instead of the expected 12 -> trailing space

-- Use TRIM() to check the corrected value first
SELECT
    TRIM(phone_number)
FROM
    employee;

--  UPDATE the record
UPDATE employee
SET phone_number = TRIM(phone_number);

-- check the fix
SELECT LENGTH(phone_number) FROM employee;


-- 2. HONOURING THE WORKERS — Finding our best
-- Count how many employees live in each town
SELECT
    town_name,
    COUNT(*) AS num_employees
FROM
    employee
GROUP BY
    town_name;


-- Find the top 3 employees (assigned_employee_id) by number of visits/locations recorded
SELECT
    assigned_employee_id,
    COUNT(visit_count) AS number_of_visits
FROM
    visits
GROUP BY
    assigned_employee_id
ORDER BY
    number_of_visits DESC
LIMIT 3;

-- Use the top 3 employee_ids found above to get their info
-- (replace the IDs below with the actual top 3 IDs from your results)
SELECT
    employee_name,
    phone_number,
    email
FROM
    employee
WHERE
    assigned_employee_id IN (0, 1, 2); -- replace with your actual top 3 IDs


-- 3. ANALYSING LOCATIONS — Understanding where the water sources are
-- Count the number of records per town
SELECT
    town_name,
    COUNT(*) AS records_per_town
FROM
    location
GROUP BY
    town_name;

-- Count the number of records per province
SELECT
    province_name,
    COUNT(*) AS records_per_province
FROM
    location
GROUP BY
    province_name;


-- grouped by both province and town, ordered by province then
-- record count descending within each province
SELECT
    province_name,
    town_name,
    COUNT(*) AS records_per_town
FROM
    location
GROUP BY
    province_name,
    town_name
ORDER BY
    province_name,
    records_per_town DESC;

-- Count the number of records for each location type (Urban/Rural)
SELECT
    location_type,
    COUNT(*) AS num_sources
FROM
    location
GROUP BY
    location_type;

-- Calculate the percentage of rural water sources
-- (using SQL as a calculator)
SELECT 23740 / (15910 + 23740) * 100;

-- Or dynamically:
SELECT
    SUM(CASE WHEN location_type = 'Rural' THEN 1 ELSE 0 END) 
    / COUNT(*) * 100 AS pct_rural
FROM
    location;



-- 4. DIVING INTO THE SOURCES — Seeing the scope of the problem
-- Q1: How many people did we survey in total?
SELECT
    SUM(number_of_people_served) AS total_people_served
FROM
    water_source;

-- Q2: How many wells, taps and rivers are there? (count by type, sorted)
SELECT
    type_of_water_source,
    COUNT(*) AS number_of_sources
FROM
    water_source
GROUP BY
    type_of_water_source
ORDER BY
    number_of_sources DESC;

-- Q3: Average number of people served per water source type (rounded)
SELECT
    type_of_water_source,
    ROUND(AVG(number_of_people_served), 0) AS ave_people_per_source
FROM
    water_source
GROUP BY
    type_of_water_source;

-- Q4: Total number of people served by each type of water source,
-- ordered so the most people served is at the top
SELECT
    type_of_water_source,
    SUM(number_of_people_served) AS population_served
FROM
    water_source
GROUP BY
    type_of_water_source
ORDER BY
    population_served DESC;

-- Convert to percentages of the total population surveyed (27 million)
SELECT
    type_of_water_source,
    ROUND(
        SUM(number_of_people_served) / 27000000 * 100
    , 0) AS percentage_people_per_source
FROM
    water_source
GROUP BY
    type_of_water_source
ORDER BY
    percentage_people_per_source DESC;


-- SELECT SUM(number_of_people_served) FROM water_source;


-- 5. START OF A SOLUTION — Thinking about how we can repair
-- Rank each water source TYPE (excluding tap_in_home, since that's
-- already the best possible source) by total population served
SELECT
    type_of_water_source,
    SUM(number_of_people_served) AS people_served,
    RANK() OVER (ORDER BY SUM(number_of_people_served) DESC) AS rank_by_population
FROM
    water_source
WHERE
    type_of_water_source != 'tap_in_home'
GROUP BY
    type_of_water_source
ORDER BY
    rank_by_population;

-- Rank INDIVIDUAL sources within each type by number of people served, (excluding tap_in_home)
SELECT
    source_id,
    type_of_water_source,
    number_of_people_served,
    RANK() OVER (
        PARTITION BY type_of_water_source
        ORDER BY number_of_people_served DESC
    ) AS priority_rank
FROM
    water_source
WHERE
    type_of_water_source != 'tap_in_home'
ORDER BY
    priority_rank;

-- Alternative using DENSE_RANK() 
SELECT
    source_id,
    type_of_water_source,
    number_of_people_served,
    DENSE_RANK() OVER (
        PARTITION BY type_of_water_source
        ORDER BY number_of_people_served DESC
    ) AS priority_rank
FROM
    water_source
WHERE
    type_of_water_source != 'tap_in_home'
ORDER BY
    priority_rank;

-- using ROW_NUMBER() 

SELECT
    source_id,
    type_of_water_source,
    number_of_people_served,
    ROW_NUMBER() OVER (
        PARTITION BY type_of_water_source
        ORDER BY number_of_people_served DESC
    ) AS priority_rank
FROM
    water_source
WHERE
    type_of_water_source != 'tap_in_home'
ORDER BY
    priority_rank;


-- 6. ANALYSING QUEUES — Uncovering when citizens collect water

-- Q1: How long did the survey take? (first and last dates, difference in days)
SELECT
    DATEDIFF(MAX(time_of_record), MIN(time_of_record)) AS survey_duration_days
FROM
    visits;

-- Q2: Average total queue time for water (excluding 0/no-queue records)
SELECT
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS avg_queue_time
FROM
    visits;

-- Q3: Average queue time aggregated by day of the week
SELECT
    DAYNAME(time_of_record) AS day_of_week,
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS avg_queue_time
FROM
    visits
GROUP BY
    day_of_week;

-- Q4: Average queue time by hour of the day, formatted as HH:00
SELECT
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
    ROUND(AVG(NULLIF(time_in_queue, 0)), 0) AS avg_queue_time
FROM
    visits
WHERE
    time_in_queue != 0
GROUP BY
    hour_of_day
ORDER BY
    hour_of_day;


-- BUILDING A "PIVOT TABLE" IN SQL
-- Average queue time per hour of day, broken out by day of the week (Sun–Sat as separate columns)

SELECT
    TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,

    -- Sunday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Sunday,

    -- Monday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Monday,

    -- Tuesday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Tuesday,

    -- Wednesday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Wednesday,

    -- Thursday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Thursday,

    -- Friday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Friday,

    -- Saturday
    ROUND(AVG(
        CASE
            WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
            ELSE NULL
        END
    ), 0) AS Saturday

FROM
    visits
WHERE
    time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY
    hour_of_day
ORDER BY
    hour_of_day;
