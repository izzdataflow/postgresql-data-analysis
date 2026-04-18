--3.What are the most in-demand skills for my role?

SELECT
    sd.skills,
    COUNT(jd.job_id) AS job_count
FROM 
    job_postingS_fact jf
INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
INNER JOIN skills_dim sd ON jd.skill_id = sd.skill_id
WHERE 
    jf.job_title_short = 'Data Analyst'
GROUP BY 
    sd.skills
ORDER BY
    job_count DESC
LIMIT 5


