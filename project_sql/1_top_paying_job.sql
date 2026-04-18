--1. What are top-paying data analyst job?
SELECT
    jf.job_id,
    jf.job_title,
    jf.job_location,
    jf.job_schedule_type,
    jf.salary_year_avg,
    jf.job_posted_date,
    cd.name AS company_name
FROM 
    job_postings_fact jf
LEFT JOIN 
    company_dim cd
ON
    jf.company_id = cd.company_id
WHERE 
    job_title_short = 'Data Analyst' AND 
    job_location = 'Anywhere' AND 
    salary_year_avg IS NOT NULL
ORDER BY
    salary_year_avg DESC
LIMIT 10