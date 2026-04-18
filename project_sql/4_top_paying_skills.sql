--4.What are the top skills based on salary for my role?

SELECT
    sd.skills,
    ROUND(AVG(salary_year_avg), 2) AS avg_salary
FROM 
    job_postingS_fact jf
INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
INNER JOIN skills_dim sd ON jd.skill_id = sd.skill_id
WHERE 
    jf.job_title_short = 'Data Analyst' AND
    jf.salary_year_avg IS NOT NULL
GROUP BY 
    sd.skills
ORDER BY
    avg_salary DESC
LIMIT 25


