--2.What are the skills required for these top-paying roles?

WITH top_paying_jobs AS (
    SELECT
        jf.job_id,
        jf.job_title,
        jf.salary_year_avg,
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
)
SELECT 
    tpj.*,
    sd.skills
FROM 
    top_paying_jobs tpj
INNER JOIN skills_job_dim jd ON TPJ.job_id = jd.job_id
INNER JOIN skills_dim sd ON jd.skill_id = sd.skill_id
