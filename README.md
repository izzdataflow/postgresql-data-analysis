<a name="top"></a>

# 🐘 PostgreSQL Data Analysis — Job Market for Data Analysts

---

## 📋 Table of Contents

- [📌 Introduction](#-introduction)
- [🧭 Background](#-background)
- [🛠️ Tools I Used](#️-tools-i-used)
- [🗄️ Database Schema](#️-database-schema)
- [🔍 The Analysis](#-the-analysis)
  - [Query 1 — Top-Paying Data Analyst Jobs](#query-1--top-paying-data-analyst-jobs)
  - [Query 2 — Skills Required for Top-Paying Roles](#query-2--skills-required-for-top-paying-roles)
  - [Query 3 — Most In-Demand Skills](#query-3--most-in-demand-skills)
  - [Query 4 — Top Skills Based on Salary](#query-4--top-skills-based-on-salary)
  - [Query 5 — Most Optimal Skills to Learn](#query-5--most-optimal-skills-to-learn)
- [💡 What I Learned](#-what-i-learned)
- [📝 Conclusions](#-conclusions)

---

## 📌 Introduction

This project uses **PostgreSQL** to explore a real-world job postings dataset and answer five strategic career questions for anyone targeting a **Data Analyst** role. Rather than guessing which skills to learn, the goal is to let the data answer that question — by analysing salary ranges, skill frequency, and the overlap between the two.

All queries are written from scratch and progressively build in complexity, from basic filtering and sorting (Q1) through to multi-CTE aggregation patterns (Q5).

**Business Rules applied throughout:**
> - Remote roles are identified by `job_location = 'Anywhere'` or `job_work_from_home = true`
> - Only postings with `salary_year_avg IS NOT NULL` are included in salary calculations
> - **Optimal skill = High Demand AND High Paying**

[↑ Back to Top](#top)

---

## 🧭 Background

Breaking into or growing within data analytics requires knowing not just *what* to learn, but *what to prioritise*. Job postings contain a huge amount of signal — salary ranges, required skills, company names, locations — but that signal is buried in raw data.

The five questions this project answers reflect a real decision-making process:

| # | Question | Why It Matters |
|---|---|---|
| 1 | What are the top-paying jobs for my role? | Sets salary expectations and identifies target companies |
| 2 | What skills do those top-paying roles require? | Reveals what skills the best-paying employers actually want |
| 3 | What are the most in-demand skills overall? | Shows the baseline skills needed just to get interviews |
| 4 | Which skills correlate with the highest salaries? | Identifies specialist skills worth learning for pay growth |
| 5 | What are the most optimal skills to learn? | Combines Q3 + Q4 — high demand AND high pay in one view |

The dataset covers job postings across multiple roles and locations. All analysis here is scoped to **Data Analyst** positions.

[↑ Back to Top](#top)

---

## 🛠️ Tools I Used

| Tool | Purpose |
|---|---|
| **PostgreSQL** | Database engine — all queries run here |
| **pgAdmin / psql** | Query execution and result inspection |
| **SQL** | Core language for all data extraction and analysis |
| **CTEs** (`WITH`) | Used in Q2 and Q5 to structure multi-step logic |
| **Aggregate functions** | `COUNT()`, `AVG()`, `ROUND()` for demand and salary metrics |
| **Git & GitHub** | Version control and project hosting |

[↑ Back to Top](#top)

---

## 🗄️ Database Schema

Four tables power all five queries:

```
job_postings_fact              -- Core fact table: one row per job posting
  ├── job_id                   -- PK, joins to skills_job_dim
  ├── company_id               -- FK → company_dim
  ├── job_title_short          -- Standardised role label (e.g. 'Data Analyst')
  ├── job_title                -- Full job title string
  ├── job_location             -- Location string ('Anywhere' = remote)
  ├── job_schedule_type        -- Full-time, part-time, contract, etc.
  ├── job_work_from_home       -- BOOLEAN: true = remote eligible
  ├── salary_year_avg          -- Annual average salary (nullable)
  └── job_posted_date          -- Date posting was published

company_dim                    -- Company reference / dimension table
  ├── company_id               -- PK
  └── name                     -- Company name

skills_job_dim                 -- Bridge table: resolves job ↔ skills (many-to-many)
  ├── job_id                   -- FK → job_postings_fact
  └── skill_id                 -- FK → skills_dim

skills_dim                     -- Skills reference / dimension table
  ├── skill_id                 -- PK
  └── skills                   -- Skill name (e.g. 'sql', 'python', 'tableau')
```

> `skills_job_dim` is a **bridge table** — it exists purely to resolve the many-to-many relationship between job postings and skills. One job can require many skills; one skill can appear in many jobs.

[↑ Back to Top](#top)

---

## 🔍 The Analysis

Each query targets `job_title_short = 'Data Analyst'`. Filters vary per question — see the overview below before diving in.

| # | Scope | Salary filter | Remote filter | Demand filter |
|---|---|---|---|---|
| Q1 | Top 10 | ✅ | `job_location = 'Anywhere'` | — |
| Q2 | Top 10 + skills | ✅ | `job_location = 'Anywhere'` | — |
| Q3 | All postings | ❌ | — | Top 5 |
| Q4 | All postings | ✅ | — | Top 25 |
| Q5 | Remote only | ✅ | `job_work_from_home = true` | `COUNT > 30` |

---

### Query 1 — Top-Paying Data Analyst Jobs

**Goal:** Find the 10 highest-paying remote Data Analyst roles, including company names.

```sql
-- LEFT JOIN company_dim to get the company name alongside each posting
-- LEFT JOIN chosen so job rows are kept even if the company reference is missing
-- Filters: remote (Anywhere), salary must exist, role = Data Analyst
-- ORDER BY salary DESC + LIMIT 10 surfaces only the top earners
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
    job_location = 'Anywhere' AND       -- 'Anywhere' = fully remote roles
    salary_year_avg IS NOT NULL         -- Exclude postings without salary info
ORDER BY
    salary_year_avg DESC
LIMIT 10;
```

**What this tells us:** The salary ceiling for remote Data Analyst roles and which companies offer the highest compensation.

[↑ Back to Top](#top)

---

### Query 2 — Skills Required for Top-Paying Roles

**Goal:** For the same top 10 jobs from Q1, reveal which specific skills each role demands.

```sql
-- CTE re-runs the Q1 filter to isolate the top 10 jobs cleanly
-- Main query joins two more tables via the bridge (skills_job_dim) to get skill names
-- INNER JOIN on skills tables: only returns jobs that actually list skills
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
INNER JOIN skills_job_dim jd ON tpj.job_id = jd.job_id    -- Bridge: job_id → skill_id
INNER JOIN skills_dim sd     ON jd.skill_id = sd.skill_id; -- Lookup: skill_id → skill name
```

**What this tells us:** The exact skill sets that the highest-paying employers look for — helps decide what to prioritise learning to maximise earning potential.

[↑ Back to Top](#top)

---

### Query 3 — Most In-Demand Skills

**Goal:** Count how many job postings mention each skill across all Data Analyst roles — return the top 5.

```sql
-- COUNT(jd.job_id) counts postings per skill
-- Note: one job can list many skills, so skill counts overlap across postings
-- No salary filter here — captures full demand including unspecified-salary roles
-- LIMIT 5 returns only the most frequently required skills
SELECT
    sd.skills,
    COUNT(jd.job_id) AS job_count   -- Total job postings requiring this skill
FROM
    job_postings_fact jf
INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
INNER JOIN skills_dim sd     ON jd.skill_id = sd.skill_id
WHERE
    jf.job_title_short = 'Data Analyst'
GROUP BY
    sd.skills
ORDER BY
    job_count DESC
LIMIT 5;
```

**What this tells us:** The baseline must-have skills that appear most frequently across all Data Analyst postings — the safe bets for getting interviews regardless of salary tier.

[↑ Back to Top](#top)

---

### Query 4 — Top Skills Based on Salary

**Goal:** Find which skills correlate with the highest average annual salaries for Data Analysts.

```sql
-- AVG(salary_year_avg) per skill shows the earning potential associated with each skill
-- ROUND(..., 2) keeps output values clean to 2 decimal places
-- IS NOT NULL ensures missing salary rows don't skew the averages
SELECT
    sd.skills,
    ROUND(AVG(salary_year_avg), 2) AS avg_salary    -- Average annual salary for roles requiring this skill
FROM
    job_postings_fact jf
INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
INNER JOIN skills_dim sd     ON jd.skill_id = sd.skill_id
WHERE
    jf.job_title_short = 'Data Analyst' AND
    jf.salary_year_avg IS NOT NULL                  -- Only postings with salary data
GROUP BY
    sd.skills
ORDER BY
    avg_salary DESC
LIMIT 25;
```

**What this tells us:** Specialist or niche skills (cloud platforms, big data tools) often command higher salaries even when they appear in fewer postings than core skills like SQL.

[↑ Back to Top](#top)

---

### Query 5 — Most Optimal Skills to Learn

**Goal:** Combine demand (Q3) and salary (Q4) to find skills that are both **high-demand** and **high-paying** for remote Data Analyst roles.

> **Optimal = High Demand AND High Paying**

---

#### Version A — Using Two CTEs

```sql
/*
  Two CTEs run independently on the same dataset, then JOIN on skill_id.
  This separates the "demand" and "salary" concerns into distinct named steps.
  Both CTEs share identical WHERE filters: remote, salary not null, Data Analyst.
  Useful for learning — each CTE can be run and validated in isolation.
*/
WITH skills_demand AS (
    -- CTE 1: Demand signal — how many remote DA postings require each skill
    SELECT
        sd.skill_id,
        sd.skills,
        COUNT(jd.job_id) AS job_count
    FROM
        job_postings_fact jf
    INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
    INNER JOIN skills_dim sd     ON jd.skill_id = sd.skill_id
    WHERE
        jf.job_title_short = 'Data Analyst' AND
        jf.salary_year_avg IS NOT NULL AND
        jf.job_work_from_home = true            -- Remote roles only (boolean filter)
    GROUP BY
        sd.skill_id
),
avg_salary AS (
    -- CTE 2: Pay signal — average salary for remote DA postings requiring each skill
    SELECT
        sd.skill_id,
        sd.skills,
        ROUND(AVG(salary_year_avg), 2) AS avg_salary
    FROM
        job_postings_fact jf
    INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
    INNER JOIN skills_dim sd     ON jd.skill_id = sd.skill_id
    WHERE
        jf.job_title_short = 'Data Analyst' AND
        jf.salary_year_avg IS NOT NULL AND
        jf.job_work_from_home = true
    GROUP BY
        sd.skill_id
)
-- Join both CTEs on skill_id to see demand and salary side by side for every skill
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
    job_count DESC,     -- Primary: most in-demand skills first
    avg_salary DESC     -- Tiebreaker: highest salary within equal demand counts
LIMIT 25;
```

---

#### Version B — Simplified Rewrite (Single Query)

```sql
/*
  Produces the same result as Version A without CTEs.
  Key difference: HAVING COUNT > 30 filters out low-frequency/niche skills
  so only skills with meaningful sample sizes appear in the "optimal" list.
  Primary sort is flipped to avg_salary DESC — surfaces highest-paying skills first.
*/
SELECT
    sd.skill_id,
    sd.skills,
    COUNT(jd.job_id)                AS job_count,
    ROUND(AVG(salary_year_avg), 2)  AS avg_salary
FROM
    job_postings_fact jf
INNER JOIN skills_job_dim jd ON jf.job_id = jd.job_id
INNER JOIN skills_dim sd     ON jd.skill_id = sd.skill_id
WHERE
    jf.job_title_short = 'Data Analyst' AND
    jf.salary_year_avg IS NOT NULL AND
    jf.job_work_from_home = true
GROUP BY
    sd.skill_id,
    sd.skills
HAVING
    COUNT(jd.job_id) > 30           -- Removes skills that appear in fewer than 30 postings
ORDER BY
    avg_salary DESC,                -- Primary: highest-paying first
    job_count DESC                  -- Secondary: most in-demand within same salary tier
LIMIT 25;
```

---

#### Version A vs Version B

| | Version A (Two CTEs) | Version B (Single Query) |
|---|---|---|
| Structure | Two CTEs joined on `skill_id` | One query with `GROUP BY` + `HAVING` |
| Readability | Verbose — each concern is isolated | Concise — everything in one pass |
| Demand filter | None (all demand counts included) | `HAVING COUNT > 30` removes low-sample skills |
| Primary sort | Demand (`job_count DESC`) first | Salary (`avg_salary DESC`) first |
| Best for | Learning / debugging step by step | Production / cleaner codebase |

**What this tells us:** The sweet-spot skills to invest time in — those that appear frequently in job postings *and* are associated with higher pay.

[↑ Back to Top](#top)

---

## 💡 What I Learned

Working through these five queries introduced and reinforced several important SQL patterns:

**Joins & Table Relationships**
- `LEFT JOIN` vs `INNER JOIN` — knowing when to keep unmatched rows (LEFT) vs when to require a match (INNER) changes the result set significantly. Q1 uses LEFT to keep job rows even if company data is missing; Q2 onwards uses INNER because skills data must exist.
- The **bridge table pattern** — `skills_job_dim` sits between `job_postings_fact` and `skills_dim` to handle the many-to-many relationship. Joining through it is a recurring pattern in relational data models.

**Aggregation**
- `COUNT()`, `AVG()`, and `ROUND()` are the core tools for summarising grouped data. Pairing `AVG(salary_year_avg)` with `IS NOT NULL` in the WHERE clause keeps averages meaningful.
- `GROUP BY` is mandatory whenever aggregate functions appear alongside non-aggregate columns — forgetting this is one of the most common SQL errors.

**Filtering Aggregates**
- `HAVING` vs `WHERE` — `WHERE` filters rows *before* grouping; `HAVING` filters *after* aggregation. Using `HAVING COUNT(jd.job_id) > 30` in Q5 is the correct way to set a minimum demand threshold — `WHERE` cannot do this.

**CTEs (`WITH`)**
- CTEs (`WITH ... AS`) make complex queries readable by breaking them into named steps. The two-CTE approach in Q5 Version A is slightly less efficient but much easier to reason about and debug — a useful technique when learning.
- Rewriting the dual-CTE into a single query (Version B) shows how to consolidate logic once the approach is validated.

**Query Design Thinking**
- The same business question can be approached multiple ways. Q5 demonstrates two valid solutions with different tradeoffs — understanding *why* each version differs is more valuable than memorising the syntax.
- Small filter differences (`job_location = 'Anywhere'` vs `job_work_from_home = true`) can return meaningfully different datasets — always check what each filter actually captures.

[↑ Back to Top](#top)

---

## 📝 Conclusions

This project set out to answer five practical job market questions using SQL, and each query builds on the last:

**From the analysis:**

1. **Remote Data Analyst salaries have a high ceiling** — the top 10 roles span a wide range, and company name matters. Q1 makes this visible at a glance.

2. **Top-paying roles require a specific skill stack** — Q2 shows that the highest-compensated postings tend to cluster around a consistent set of tools. Knowing this stack helps target upskilling efficiently.

3. **SQL, Excel, and Python dominate raw demand** — Q3 confirms that these three skills appear in the most postings by far. They are the non-negotiables for getting interviews.

4. **Niche and specialist skills command premium salaries** — Q4 reveals that cloud tools, big data platforms, and less common libraries often appear at the top of the salary ranking despite lower overall demand. There is a pay premium for going deep.

5. **The optimal learning path sits at the intersection** — Q5 combines Q3 and Q4 to surface skills that are both frequently required *and* well-compensated. These are the highest-ROI skills to learn next.

**Overall takeaway:** Core skills (SQL, Python, Excel) are necessary for employability. Specialist skills (cloud, big data, advanced tooling) unlock higher compensation. The optimal path is to build the core first, then layer in the high-salary specialists strategically.

[↑ Back to Top](#top)
