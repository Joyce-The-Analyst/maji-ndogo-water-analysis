-- This starts assembling data for our final analysis by joining location to visits
SELECT
    location.province_name,
    location.town_name,
    visits.visit_count,
    visits.location_id
FROM
    visits
JOIN
    location
    ON location.location_id = visits.location_id;
    
    
    -- This joins water_source to our existing location + visits query,
-- adding the type of water source and number of people it serves
SELECT
    location.province_name,
    location.town_name,
    visits.visit_count,
    visits.location_id,
    water_source.type_of_water_source,
    water_source.number_of_people_served
FROM
    visits
JOIN
    location
    ON location.location_id = visits.location_id
JOIN
    water_source
    ON water_source.source_id = visits.source_id
WHERE
    visits.visit_count = 1;
    
    
    -- This assembles province, town, source type, and population served,
-- keeping only the first visit per location to avoid duplicate counting
SELECT
    location.province_name,
    location.town_name,
    water_source.type_of_water_source,
    water_source.number_of_people_served
FROM
    visits
JOIN
    location
    ON location.location_id = visits.location_id
JOIN
    water_source
    ON water_source.source_id = visits.source_id
WHERE
    visits.visit_count = 1;
    
    
    -- Adds well_pollution results; LEFT JOIN preserves all rows even for non-well sources (results = NULL)
SELECT
    location.province_name,
    location.town_name,
    location.location_type,
    water_source.type_of_water_source,
    water_source.number_of_people_served,
    visits.time_in_queue,
    well_pollution.results
FROM
    visits
LEFT JOIN
    well_pollution
    ON well_pollution.source_id = visits.source_id
JOIN
    location
    ON location.location_id = visits.location_id
JOIN
    water_source
    ON water_source.source_id = visits.source_id
WHERE
    visits.visit_count = 1;
    
    
    -- This view assembles data from different tables into one to simplify analysis
CREATE VIEW combined_analysis_table AS
SELECT
    water_source.type_of_water_source AS source_type,
    location.town_name,
    location.province_name,
    location.location_type,
    water_source.number_of_people_served AS people_served,
    visits.time_in_queue,
    well_pollution.results
FROM
    visits
LEFT JOIN
    well_pollution
    ON well_pollution.source_id = visits.source_id
INNER JOIN
    location
    ON location.location_id = visits.location_id
INNER JOIN
    water_source
    ON water_source.source_id = visits.source_id
WHERE
    visits.visit_count = 1;
    
    
    SELECT * FROM combined_analysis_table;
    
    
    -- This CTE calculates the total population served in each province
WITH province_totals AS (
    SELECT
        province_name,
        SUM(people_served) AS total_ppl_serv
    FROM
        combined_analysis_table
    GROUP BY
        province_name
)
SELECT * FROM province_totals;


-- This CTE calculates the total population served in each province
WITH province_totals AS (
    SELECT
        province_name,
        SUM(people_served) AS total_ppl_serv
    FROM
        combined_analysis_table
    GROUP BY
        province_name
)
SELECT
    ct.province_name,
    -- These CASE statements create one column per source type,
    -- summing people served by that type, then converting to a percentage of the province total
    ROUND((SUM(CASE WHEN source_type = 'river'
        THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS river,
    ROUND((SUM(CASE WHEN source_type = 'shared_tap'
        THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS shared_tap,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
        THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
        THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN source_type = 'well'
        THEN people_served ELSE 0 END) * 100.0 / pt.total_ppl_serv), 0) AS well
FROM
    combined_analysis_table ct
JOIN
    province_totals pt
    ON ct.province_name = pt.province_name
GROUP BY
    ct.province_name
ORDER BY
    ct.province_name;
    
    
    -- This CTE calculates the total population served per town.
-- Since some town names repeat across different provinces (e.g. two towns called Harare),
-- i grouped by province_name AND town_name together to keep them distinct.
WITH town_totals AS (
    SELECT
        province_name,
        town_name,
        SUM(people_served) AS total_ppl_serv
    FROM
        combined_analysis_table
    GROUP BY
        province_name, town_name
)
SELECT * FROM town_totals;



-- This CTE calculates the total population served per town (grouped by province+town to keep duplicate town names distinct)
WITH town_totals AS (
    SELECT
        province_name,
        town_name,
        SUM(people_served) AS total_ppl_serv
    FROM
        combined_analysis_table
    GROUP BY
        province_name, town_name
)
-- This query calculates, for each town, what percentage of people use each type of water source
SELECT
    ct.province_name,
    ct.town_name,
    ROUND((SUM(CASE WHEN source_type = 'river'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
    ROUND((SUM(CASE WHEN source_type = 'shared_tap'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN source_type = 'well'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
    combined_analysis_table ct
JOIN -- joined on BOTH province_name and town_name, since town names aren't unique on their own
    town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY
    ct.province_name,
    ct.town_name
ORDER BY
    ct.town_name;
    
    
    -- This stores the town-level water source breakdown as a temporary table
-- so we can query it repeatedly without re-running the full calculation each time
CREATE TEMPORARY TABLE town_aggregated_water_access
WITH town_totals AS (
    SELECT
        province_name,
        town_name,
        SUM(people_served) AS total_ppl_serv
    FROM
        combined_analysis_table
    GROUP BY
        province_name, town_name
)
SELECT
    ct.province_name,
    ct.town_name,
    ROUND((SUM(CASE WHEN source_type = 'river'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS river,
    ROUND((SUM(CASE WHEN source_type = 'shared_tap'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home,
    ROUND((SUM(CASE WHEN source_type = 'tap_in_home_broken'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,
    ROUND((SUM(CASE WHEN source_type = 'well'
        THEN people_served ELSE 0 END) * 100.0 / tt.total_ppl_serv), 0) AS well
FROM
    combined_analysis_table ct
JOIN
    town_totals tt ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name
GROUP BY
    ct.province_name,
    ct.town_name;
    
    
    SELECT * FROM town_aggregated_water_access;
    
    
    
    SELECT
    province_name,
    town_name,
    river
FROM
    town_aggregated_water_access
ORDER BY
    river DESC;
    
    
    -- This table tracks water source improvement projects: what needs to be done,
-- where, and the current status of each repair/upgrade
CREATE TABLE Project_progress (
    Project_id SERIAL PRIMARY KEY,
    -- Unique ID for each project row, in case we visit the same source more than once in future

    source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE,
    -- Every source we improve must actually exist in water_source. This keeps our data honest (referential integrity).

    Address VARCHAR(50),
    Town VARCHAR(30),
    Province VARCHAR(30),
    Source_type VARCHAR(50),
    Improvement VARCHAR(50), -- what engineers should actually do at this location

    Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
    -- Only these 3 values are allowed, so engineers can't enter messy/inconsistent status text.
    -- Defaults to 'Backlog' (like a TODO list) until someone updates it.

    Date_of_completion DATE, -- engineers fill this in once the work is done
    Comments TEXT -- free-form notes from engineers, no length limit
);


-- Project_progress_query
-- This joins location, visits, and well_pollution to water_source,
-- giving us everything we need to decide what improvement each source needs
SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    well_pollution.results
FROM
    water_source
LEFT JOIN
    well_pollution
    ON water_source.source_id = well_pollution.source_id
JOIN
    visits
    ON water_source.source_id = visits.source_id
JOIN
    location
    ON location.location_id = visits.location_id;
    
    
    SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    visits.time_in_queue,
    well_pollution.results
FROM
    water_source
LEFT JOIN
    well_pollution
    ON water_source.source_id = well_pollution.source_id
JOIN
    visits
    ON water_source.source_id = visits.source_id
JOIN
    location
    ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
    AND (
        well_pollution.results != 'Clean'
        OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river')
        OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
    );
    
    
    SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    visits.time_in_queue,
    well_pollution.results
FROM
    water_source
LEFT JOIN
    well_pollution
    ON water_source.source_id = well_pollution.source_id
JOIN
    visits
    ON water_source.source_id = visits.source_id
JOIN
    location
    ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
    AND (
        well_pollution.results != 'Clean'
        OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river')
        OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
    );
    
    
    SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    visits.time_in_queue,
    well_pollution.results,
    CASE
        WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
        WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
        WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30
            THEN CONCAT("Install ", FLOOR(visits.time_in_queue / 30), " taps nearby")
        ELSE NULL
    END AS Improvement
FROM
    water_source
LEFT JOIN
    well_pollution
    ON water_source.source_id = well_pollution.source_id
JOIN
    visits
    ON water_source.source_id = visits.source_id
JOIN
    location
    ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
    AND (
        well_pollution.results != 'Clean'
        OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river')
        OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
    );
    
    
    SELECT
    location.address,
    location.town_name,
    location.province_name,
    water_source.source_id,
    water_source.type_of_water_source,
    visits.time_in_queue,
    well_pollution.results,
    CASE
        WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
        WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
        WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30
            THEN CONCAT("Install ", FLOOR(visits.time_in_queue / 30), " taps nearby")
        WHEN water_source.type_of_water_source = 'tap_in_home_broken'
            THEN 'Diagnose local infrastructure'
        ELSE NULL
    END AS Improvement
FROM
    water_source
LEFT JOIN
    well_pollution
    ON water_source.source_id = well_pollution.source_id
JOIN
    visits
    ON water_source.source_id = visits.source_id
JOIN
    location
    ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
    AND (
        well_pollution.results != 'Clean'
        OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river')
        OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
    );
    
    
    INSERT INTO Project_progress (source_id, Address, Town, Province, Source_type, Improvement)
SELECT
    water_source.source_id,
    location.address,
    location.town_name,
    location.province_name,
    water_source.type_of_water_source,
    CASE
        WHEN well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
        WHEN well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
        WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
        WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30
            THEN CONCAT("Install ", FLOOR(visits.time_in_queue / 30), " taps nearby")
        WHEN water_source.type_of_water_source = 'tap_in_home_broken'
            THEN 'Diagnose local infrastructure'
        ELSE NULL
    END
FROM
    water_source
LEFT JOIN
    well_pollution
    ON water_source.source_id = well_pollution.source_id
JOIN
    visits
    ON water_source.source_id = visits.source_id
JOIN
    location
    ON location.location_id = visits.location_id
WHERE
    visits.visit_count = 1
    AND (
        well_pollution.results != 'Clean'
        OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river')
        OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
    );
    
    SELECT * FROM Project_progress;
