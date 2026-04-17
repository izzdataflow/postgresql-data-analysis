SELECT
	'2023-02-19'::DATE,
	'123'::INTEGER,
	'true'::BOOLEAN,
	'3.14'::REAL,
	job_posted_date AT TIME ZONE 'UTC' AT TIME ZONE 'UST' AS date_time,
	EXTRACT(MONTH FROM column_name) AS column_name,
FROM table_name;

SELECT 
    COUNT(job_id) AS job_posted_count,
    EXTRACT(MONTH FROM job_posted_date) AS month
FROM 
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY 
    month
ORDER BY
    job_posted_count DESC

--================================================================================================================

--- Create tables for month January - March

--January
CREATE TABLE january_jobs AS
    SELECT
        *
    FROM
        job_postings_fact
    WHERE
        EXTRACT(MONTH FROM job_posted_date) = 1;

--February
CREATE TABLE february_jobs AS
    SELECT
        *
    FROM
        job_postings_fact
    WHERE
        EXTRACT(MONTH FROM job_posted_date) = 2;    

--March
CREATE TABLE march_jobs AS
    SELECT
        *
    FROM
        job_postings_fact
    WHERE
        EXTRACT(MONTH FROM job_posted_date) = 3;

--================================================================================================================

--Case WHEN

SELECT
    job_title_short,
    COUNT(job_id) AS job_posted_count,
    CASE 
        WHEN job_location = 'Anywhere' THEN 'Remote'
        WHEN job_location = 'New York, NY' THEN 'Local'
        ELSE 'On-site'
    END AS job_location_type
FROM    
    job_postings_fact
WHERE
    job_title_short = 'Data Analyst'
GROUP BY
    job_title_short,
    job_location_type
ORDER BY job_posted_count DESC
LIMIT 20;

--================================================================================================================

--Subquery

--January
SELECT
        *
FROM(
    SELECT
        *
    FROM
        job_postings_fact
    WHERE
        EXTRACT(MONTH FROM job_posted_date) = 1;
) AS january_jobs

--CTE
WITH january_jobs AS (
    SELECT
        *
    FROM
        job_postings_fact
    WHERE
        EXTRACT(MONTH FROM job_posted_date) = 1
)
SELECT
    *
FROM january_jobs
LIMIT 50;

--Subquery WHERE
SELECT 
    company_id,
    name AS company_name
FROM 
    company_dim
WHERE company_id IN (
    SELECT
        company_id
    FROM 
        job_postings_fact
    WHERE 
        job_no_degree_mention = true
)
LIMIT 50;

--CTE
WITH company_job_count AS (
    SELECT
        company_id,
        COUNT(1) AS total_jobs
    FROM 
        job_postings_fact
    GROUP BY company_id
)
SELECT
    name AS company_name,
    total_jobs
FROM company_dim cd
LEFT JOIN company_job_count jc
ON cd.company_id = jc.company_id
ORDER BY total_jobs DESC
LIMIT 50;

WITH remote_job_skills AS(
SELECT
    sjd.skill_id,
    COUNT(1) AS skill_count
FROM 
    skills_job_dim sjd
INNER JOIN 
    job_postings_fact jpf
ON 
    sjd.job_id = jpf.job_id
WHERE 
    jpf.job_work_from_home = true
    AND jpf.job_title_short = 'Data Analyst'
GROUP BY 
    sjd.skill_id
)
SELECT
    sd.skill_id,
    sd.skills,
    rjs.skill_count
FROM remote_job_skills rjs
INNER JOIN 
    skills_dim sd
ON 
    rjs.skill_id = sd.skill_id
ORDER BY 
    rjs.skill_count DESC
LIMIT 5;

--================================================================================================================

--UNION/UNION ALL (UNION ALL often used because we want all records, including duplicates)

SELECT
    job_title_short,
    job_location,
    job_via,
    job_posted_date::DATE,
    salary_year_avg
FROM(
SELECT
    *
FROM 
    january_jobs
--UNION
UNION ALL
SELECT
    *
FROM 
    february_jobs
--UNION
UNION ALL
SELECT
    *
FROM 
    march_jobs
) AS qjp
WHERE salary_year_avg > 70000
AND job_title_short = 'Data Analyst'
ORDER BY salary_year_avg DESC
LIMIT 50