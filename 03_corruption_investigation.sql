SELECT
    record_id,
    COUNT(record_id)
FROM
    water_quality
GROUP BY
    record_id
HAVING
    COUNT(record_id) > 1;
    
    SELECT
    record_id,
    COUNT(record_id)
FROM
    visits
GROUP BY
    record_id
HAVING
    COUNT(record_id) > 1;
    
  DROP TABLE IF EXISTS `auditor_report`;

CREATE TABLE `auditor_report` (
    `location_id` VARCHAR(32),
    `type_of_water_source` VARCHAR(64),
    `true_water_source_score` int DEFAULT NULL,
    `statements` VARCHAR(255)
); 
   
   
   
   SELECT
    location_id,
    true_water_source_score
FROM
    auditor_report;
    
  
  --
  SELECT
    auditor_report.location_id AS audit_location,
    auditor_report.true_water_source_score,
    visits.location_id AS visit_location,
    visits.record_id
FROM
    auditor_report
JOIN
    visits
ON
    auditor_report.location_id = visits.location_id;
    
    -- This query joins auditor_report to visits (to get record_id),
-- then joins water_quality (via record_id) to bring in the surveyor's subjective_quality_score
SELECT
    auditor_report.location_id AS audit_location,
    auditor_report.true_water_source_score,
    visits.location_id AS visit_location,
    visits.record_id,
    water_quality.subjective_quality_score
FROM
    auditor_report
JOIN
    visits
    ON auditor_report.location_id = visits.location_id
JOIN
    water_quality
    ON visits.record_id = water_quality.record_id;
    
    
    -- This query compares the auditor's re-recorded score against the original surveyor's score
-- for each location, linking auditor_report -> visits -> water_quality via location_id and record_id
SELECT
    auditor_report.location_id,
    visits.record_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score
FROM
    auditor_report
JOIN
    visits
    ON auditor_report.location_id = visits.location_id
JOIN
    water_quality
    ON visits.record_id = water_quality.record_id;
    
    
    -- This query checks whether the auditor's score and the surveyor's score agree for each record
SELECT
    auditor_report.location_id,
    visits.record_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score
FROM
    auditor_report
JOIN
    visits
    ON auditor_report.location_id = visits.location_id
JOIN
    water_quality
    ON visits.record_id = water_quality.record_id
WHERE
    auditor_report.true_water_source_score = water_quality.subjective_quality_score;
    
    
    -- This counts how many records have matching auditor and surveyor scores
SELECT
    COUNT(*)
FROM
    auditor_report
JOIN
    visits
    ON auditor_report.location_id = visits.location_id
JOIN
    water_quality
    ON visits.record_id = water_quality.record_id
WHERE
    auditor_report.true_water_source_score = water_quality.subjective_quality_score;
    
    
    -- This counts matching auditor/surveyor scores, restricted to the first visit only (visit_count = 1)
-- to avoid counting the same location multiple times
SELECT
    COUNT(*)
FROM
    auditor_report
JOIN
    visits
    ON auditor_report.location_id = visits.location_id
JOIN
    water_quality
    ON visits.record_id = water_quality.record_id
WHERE
    auditor_report.true_water_source_score = water_quality.subjective_quality_score
    AND visits.visit_count = 1;
    
    
   -- This pulls the full details of records where the auditor's score
-- does NOT match the surveyor's score (i.e. the incorrect records)
SELECT
    auditor_report.location_id,
    visits.record_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score
FROM
    auditor_report
JOIN
    visits
    ON auditor_report.location_id = visits.location_id
JOIN
    water_quality
    ON visits.record_id = water_quality.record_id
WHERE
    auditor_report.true_water_source_score != water_quality.subjective_quality_score
    AND visits.visit_count = 1;
    
    
    -- This checks whether the type_of_water_source recorded by the auditor
-- matches the type_of_water_source recorded by our surveyors, for the 102 records
SELECT
    auditor_report.location_id,
    visits.record_id,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score,
    water_source.type_of_water_source AS survey_source,
    auditor_report.type_of_water_source AS auditor_source
FROM
    auditor_report
JOIN
    visits
    ON auditor_report.location_id = visits.location_id
JOIN
    water_quality
    ON visits.record_id = water_quality.record_id
JOIN
    water_source
    ON visits.source_id = water_source.source_id
WHERE
    auditor_report.true_water_source_score != water_quality.subjective_quality_score
    AND visits.visit_count = 1;
    
    
    -- This pulls the 102 records where the auditor's score does NOT match the surveyor's score,
-- and links each record to the employee who recorded it, using their name instead of raw ID.
SELECT
    auditor_report.location_id,
    visits.record_id,
    employee.employee_name,
    auditor_report.true_water_source_score AS auditor_score,
    water_quality.subjective_quality_score AS surveyor_score
FROM
    auditor_report
JOIN
    visits
    ON auditor_report.location_id = visits.location_id
JOIN
    water_quality
    ON visits.record_id = water_quality.record_id
JOIN
    employee
    ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE
    auditor_report.true_water_source_score != water_quality.subjective_quality_score
    AND visits.visit_count = 1;
    
    
    -- This view joins the auditor report to the database, returning all records
-- where the auditor's score and the surveyor's (employee's) score didn't match,
-- along with the employee's name and any citizen statements collected by the auditor.
CREATE VIEW Incorrect_records AS (
    SELECT
        auditor_report.location_id,
        visits.record_id,
        employee.employee_name,
        auditor_report.true_water_source_score AS auditor_score,
        water_quality.subjective_quality_score AS surveyor_score,
        auditor_report.statements AS statements
    FROM
        auditor_report
    JOIN
        visits
        ON auditor_report.location_id = visits.location_id
    JOIN
        water_quality
        ON visits.record_id = water_quality.record_id
    JOIN
        employee
        ON employee.assigned_employee_id = visits.assigned_employee_id
    WHERE
        visits.visit_count = 1
        AND auditor_report.true_water_source_score != water_quality.subjective_quality_score
);


SELECT * FROM Incorrect_records;

-- This counts how many "incorrect" records (mismatched scores) each employee has,
SELECT
    employee_name,
    COUNT(employee_name) AS number_of_mistakes
FROM
    Incorrect_records
GROUP BY
    employee_name
ORDER BY
    number_of_mistakes DESC;
    
    
    -- This calculates the average number of mistakes per employee,
-- using error_count (number of mismatched records per employee) as a baseline for comparison
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM
        Incorrect_records
    GROUP BY
        employee_name
)
SELECT
    AVG(number_of_mistakes)
FROM
    error_count;


-- This CTE calculates the number of mistakes each employee made
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM
        Incorrect_records
    GROUP BY
        employee_name
)
-- This query returns employees whose mistake count is above the average for all employees
SELECT
    employee_name,
    number_of_mistakes
FROM
    error_count
WHERE
    number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count);
    
    
    -- This CTE calculates the number of mistakes each employee made
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM
        Incorrect_records
    GROUP BY
        employee_name
),
-- This CTE selects the employees with an above-average number of mistakes
suspect_list AS (
    SELECT
        employee_name,
        number_of_mistakes
    FROM
        error_count
    WHERE
        number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
)
-- This query pulls the statements for all records gathered by our four "suspect" employees
SELECT
    employee_name,
    location_id,
    statements
FROM
    Incorrect_records
WHERE
    employee_name IN (SELECT employee_name FROM suspect_list);
    
    
    -- This filters the suspect employees' records to only those where the statement mentions "cash"
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM
        Incorrect_records
    GROUP BY
        employee_name
),
suspect_list AS (
    SELECT
        employee_name,
        number_of_mistakes
    FROM
        error_count
    WHERE
        number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
)
SELECT
    employee_name,
    location_id,
    statements
FROM
    Incorrect_records
WHERE
    employee_name IN (SELECT employee_name FROM suspect_list)
    AND statements LIKE '%cash%';
    
    
    -- This checks whether ANY employees outside our suspect list also have "cash" mentioned
-- in their statements. If this returns zero rows, it means only our 4 suspects
WITH error_count AS (
    SELECT
        employee_name,
        COUNT(employee_name) AS number_of_mistakes
    FROM
        Incorrect_records
    GROUP BY
        employee_name
),
suspect_list AS (
    SELECT
        employee_name,
        number_of_mistakes
    FROM
        error_count
    WHERE
        number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count)
)
SELECT
    employee_name,
    location_id,
    statements
FROM
    Incorrect_records
WHERE
    employee_name NOT IN (SELECT employee_name FROM suspect_list)
    AND statements LIKE '%cash%';
