/* 5.What are the most optimal skills to learn>
	a. Optimal : High Demand and High Paying */

--CTE
WITH skills_demand AS (
    SELECT
        sd.skill_id,
        sd.skills,
        COUNT(jd.job_id) AS job_count
    FROM 
        job_postingS_fact jf
    INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
    INNER JOIN skills_dim sd ON jd.skill_id = sd.skill_id
    WHERE 
        jf.job_title_short = 'Data Analyst' AND
        jf.salary_year_avg IS NOT NULL AND
        jf.job_work_from_home = true
    GROUP BY 
        sd.skill_id
),
avg_salary AS (
    SELECT
        sd.skill_id,
        sd.skills,
        ROUND(AVG(salary_year_avg), 2) AS avg_salary
    FROM 
        job_postingS_fact jf
    INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
    INNER JOIN skills_dim sd ON jd.skill_id = sd.skill_id
    WHERE 
        jf.job_title_short = 'Data Analyst' AND
        jf.salary_year_avg IS NOT NULL AND
        jf.job_work_from_home = true
    GROUP BY 
        sd.skill_id
)
SELECT 
    skills_demand.skill_id,
    skills_demand.skills,
    job_count,
    avg_salary
FROM 
    skills_demand
INNER JOIN
    avg_salary ON skills_demand.skill_id = avg_salary.skill_id
ORDER BY 
    job_count DESC,
    avg_salary DESC
LIMIT 25

--Rewrite from CTE
SELECT 
    sd.skill_id,
    sd.skills,
    COUNT(jd.job_id) AS job_count,
    ROUND(AVG(salary_year_avg), 2) AS avg_salary
FROM 
    job_postingS_fact jf
INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
INNER JOIN skills_dim sd ON jd.skill_id = sd.skill_id
WHERE 
    jf.job_title_short = 'Data Analyst' AND
    jf.salary_year_avg IS NOT NULL AND
    jf.job_work_from_home = true
GROUP BY
    sd.skill_id,
    sd.skills
HAVING 
    COUNT(jd.job_id) > 30
ORDER BY 
    avg_salary DESC,
    job_count DESC
LIMIT 25