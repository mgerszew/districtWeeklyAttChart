# PowerSchool Oracle SQL Reference — SBG (Standards-Based Grading) Queries

Source: `docs/powerschool/PowerSchool_Oracle_Query_Reference.md` (lines 436-689)

---

## Query Groups (28 queries consolidated)

| Group | Queries | Core Pattern |
|-------|---------|--------------|
| **Standards & Assignments** | #1, #8 | `ASSIGNMENTSTANDARDASSOC` → `STANDARD` → `sections` → `terms` |
| **Proficiency by Grade** | #5, #11, #16, #20 | CTEs: `domainAvg`, `ST`, `sg` (row_num=1) → `STANDARDGRADEROLLUP` → `Students` |
| **Subject/Domain Averages** | #6, #7, #14, #15, #21, #22, #23 | `standardsgrades` + `ps_enrollment_all` + `termbins` aggregation |
| **VPR/CRP Targets** | #3, #4, #12, #26, #27, #28 | `U_CLG_ARC_TRGTS` + `StandardGradeSection` + `StandardCourseAssoc` |
| **Gradebook/Config** | #17, #24 | `gradeschoolconfig`, `gradesectionconfig`, `schoolstaff` |
| **Report Card/PSM** | #2, #9 | `psm_*` tables, `standardgradesection` |
| **Assessment Loading** | #19, #25 | `Prefs` + derived CTEs (`sg`, `st`, `tb`, `the`, `using`) |

---

## Core SBG Tables & Relationships

```
STANDARD
  ├── id, identifier (e.g., 'MAT-01.OA.1'), name, description
  ├── yearid → years.yearid
  ├── standardgradelevelid
  └── standardidentifier (parent rollup code)

STANDARDGRADESECTION (SGS)
  ├── id
  ├── standardid → STANDARD.id
  ├── sectionid → sections.id
  ├── studentid → students.id
  ├── standardgrade (1-4 score)
  ├── storecode (Q1, Q2, S1, Y1)
  └── termid → terms.id

STANDARDGRADEROLLUP (SGR)
  ├── parentstandardid → STANDARD.id
  ├── childstandardid → STANDARD.id
  └── rolluptype

STANDARDCOURSEASSOC
  ├── course_number → courses.course_number
  └── standardid → STANDARD.id

ASSIGNMENT
  ├── id, name, identifier, category, maxpoints
  └── sectionid → sections.id

ASSIGNMENTSTANDARDASSOC
  ├── assignmentid → ASSIGNMENT.id
  └── standardid → STANDARD.id

STANDARDSCORE
  ├── studentid → students.id
  ├── assignmentid → ASSIGNMENT.id
  ├── standardid → STANDARD.id
  └── score

TERMBINS / Termbins
  ├── termid, storecode, gradelevel, yearid
  └── Maps storecodes to terms

STANDARDSGRADES
  ├── studentid, standardid, storecode, yearid
  ├── grade (alpha), percent, points
  └── Used for final grades

U_CLG_ARC_TRGTS (District Custom - VPR Targets)
  ├── standardid, yearid, gradelevel
  ├── target_score, proficiency_threshold
  └── Used for VPR (Vision-Progress-Report)

PSM_* tables (PowerSchool Mobile / Report Card)
  ├── psm_assignmentstandard, psm_assignmentstandardscore
  ├── psm_reportcarditem, psm_reportcarditemgrade
  ├── psm_reportingterm, psm_sectionenrollment, psm_standard
```

---

## Shared CTE Patterns

### 1. `params` / `sqlParams` — Year, School, Storecode

```sql
WITH params AS (
  SELECT 
    28 AS yearid,
    84 AS schoolid,
    'Q3' AS storecode
  FROM dual
),
sqlParams AS (
  SELECT 
    p.yearid,
    p.schoolid,
    t.firstday,
    t.lastday
  FROM params p
  JOIN terms t ON t.yearid = p.yearid AND t.isyearrec = 1 AND t.schoolid = p.schoolid
)
```

### 2. `Termbins` / `tb` — Storecode → Term Mapping

```sql
Termbins tb AS (
  SELECT termid, storecode, gradelevel
  FROM termbins
  WHERE yearid = (SELECT yearid FROM params)
)
```

### 3. `ST` / `sg` — StandardGradeSection with Row Number

```sql
ST AS (
  SELECT sgs.*, s.identifier, s.name, s.yearid
  FROM standardgradesection sgs
  JOIN standard s ON s.id = sgs.standardid
  JOIN sections sec ON sec.id = sgs.sectionid
  JOIN terms t ON t.id = sec.termid
  WHERE t.yearid = (SELECT yearid FROM params)
    AND sgs.storecode = (SELECT storecode FROM params)
),
sg AS (
  SELECT st.*, 
    ROW_NUMBER() OVER (PARTITION BY st.studentid, st.standardid ORDER BY st.standardgrade DESC) AS row_num
  FROM ST st
  WHERE st.standardgrade IS NOT NULL
)
```

### 4. `domainAvg` — Domain-Level Aggregation

```sql
domainAvg AS (
  SELECT 
    s.identifier AS domain_id,
    s.name AS domain_name,
    AVG(sgs.standardgrade) AS avg_score
  FROM standardgradesection sgs
  JOIN standard s ON s.id = sgs.standardid
  WHERE sgs.storecode = (SELECT storecode FROM params)
  GROUP BY s.identifier, s.name
)
```

### 5. `stan1`..`stan5` — Year-Specific Standard CTEs (Query #4)

```sql
stan1 AS (
  SELECT * FROM standard WHERE yearid = 27 AND identifier LIKE 'ELA%'
),
stan2 AS (
  SELECT * FROM standard WHERE yearid = 27 AND identifier LIKE 'MAT%'
),
stan3 AS (
  SELECT * FROM standard WHERE yearid = 27 AND identifier LIKE 'SCI%'
),
stan4 AS (
  SELECT * FROM standard WHERE yearid = 27 AND identifier LIKE 'SS%'
),
stan5 AS (
  SELECT * FROM standard WHERE yearid = 27 AND identifier LIKE 'ART%'
)
```

---

## Key Join Patterns

### Standards → Grade Section → Section → Student
```sql
STANDARD s
JOIN STANDARDGRADESECTION sgs ON sgs.standardid = s.id
JOIN sections sec ON sec.id = sgs.sectionid
JOIN students stu ON stu.id = sgs.studentid
JOIN terms t ON t.id = sec.termid
WHERE t.yearid = (SELECT yearid FROM params)
```

### Assignment → Standard → Score
```sql
ASSIGNMENT a
JOIN ASSIGNMENTSTANDARDASSOC asa ON asa.assignmentid = a.id
JOIN STANDARD s ON s.id = asa.standardid
JOIN STANDARDSCORE sc ON sc.assignmentid = a.id AND sc.standardid = s.id
JOIN students stu ON stu.id = sc.studentid
```

### Course → StandardCourseAssoc → Standard
```sql
courses c
JOIN STANDARDCOURSEASSOC sca ON sca.course_number = c.course_number
JOIN STANDARD s ON s.id = sca.standardid
WHERE s.yearid = (SELECT yearid FROM params)
```

### VPR Targets
```sql
U_CLG_ARC_TRGTS trg
JOIN STANDARD s ON s.id = trg.standardid
JOIN STANDARDGRADESECTION sgs ON sgs.standardid = s.id
JOIN sections sec ON sec.id = sgs.sectionid
JOIN students stu ON stu.id = sgs.studentid
WHERE trg.yearid = (SELECT yearid FROM params)
  AND sgs.storecode = (SELECT storecode FROM params)
```

---

## Common Filters

| Filter | SQL |
|--------|-----|
| Year record terms | `t.isyearrec = 1` |
| Specific storecode | `sgs.storecode = 'Q3'` |
| Grade level | `stu.grade_level = 5` |
| Active students | `stu.enroll_status = 0` |
| Non-null grades | `sgs.standardgrade IS NOT NULL` |
| Latest score per standard | `sg.row_num = 1` |
| Year filter on standard | `s.yearid = (SELECT yearid FROM params)` |

---

## Hardcoded Values to Parameterize

| Query | Hardcoded | Move To |
|-------|-----------|---------|
| #3 | Hardcoded student IDs `610965`, `130238` | `params` CTE or `:students` GPV |
| #4 | `yearid = 27` in stan1-stan5 | `params` CTE |
| #5 | `s.YEARID = 28`, `sg.row_num=1` | `params` CTE |
| #6 | `stg.yearid=28` | `params` CTE |
| #7 | `stg.yearid=28` | `params` CTE |
| #11 | `s.YEARID = 29` | `params` CTE |
| #12 | `:students` param ref (commented) | `params` CTE |
| #13 | `standard.YEARID IN (33, 34)`, `yr.YEARID IN (33, 34)` | `params` CTE |
| #14 | `stg.yearid=24` | `params` CTE |
| #15 | `:students` param, `nystd.yearid=33/34` | `params` CTE |
| #16 | `s.YEARID = 27` | `params` CTE |
| #17 | `yearid=30` | `params` CTE |
| #18 | `stg.yearid=24` | `params` CTE |
| #20 | `s.YEARID = 27` | `params` CTE |
| #23 | School from `Prefs` table | `params` CTE |
| #24 | `yearid=~(curyearid)` | `params` CTE |
| #25 | Student IDs `618636, 618727`, school from `Prefs` | `params` CTE |
| #26 | `nystd.yearid=33` | `params` CTE |
| #27 | `nystd.yearid=34` | `params` CTE |
| #28 | `nystd.ISACTIVE=1 AND yearid=33` | `params` CTE |

---

## Parameterization (AGENTS.md §3)

- **No bind variables** — use CTE `params`
- **No PL/SQL** — plain SQL only
- **GPV tags** in comments (`--~(gpv.yearid)`) indicate intended params

---

## Proficiency Calculation Pattern

```sql
-- % Proficient (score >= 3)
SELECT 
  stu.grade_level,
  COUNT(CASE WHEN sg.standardgrade >= 3 THEN 1 END) * 100.0 / COUNT(*) AS pct_proficient
FROM sg
JOIN students stu ON stu.id = sg.studentid
JOIN standard s ON s.id = sg.standardid
JOIN standardgraderollup sgr ON sgr.childstandardid = s.id
WHERE sg.row_num = 1
GROUP BY stu.grade_level
```

---

## Year-Over-Year Comparison (Queries #10, #12)

```sql
WITH y1 AS (
  SELECT * FROM sg WHERE yearid = 28
),
y2 AS (
  SELECT * FROM sg WHERE yearid = 29
)
SELECT 
  y1.studentid,
  y1.standardid,
  y1.standardgrade AS grade_yr1,
  y2.standardgrade AS grade_yr2,
  y2.standardgrade - y1.standardgrade AS improvement
FROM y1
JOIN y2 ON y2.studentid = y1.studentid 
  AND y2.standardid = y1.standardid
```

---

## Performance Flags

| Table | Risk | Mitigation |
|-------|------|------------|
| STANDARDGRADESECTION | Large, heavily joined | Index on (standardid, sectionid, studentid, storecode); filter storecode first |
| STANDARDSCORE | Very large | Partition by yearid; index (assignmentid, standardid, studentid) |
| STANDARD | Medium | Index on (yearid, identifier); small enough for full scan |
| STANDARDSGRADES | Large final grades | Index on (studentid, standardid, storecode, yearid) |
| TERMBINS | Small | PK on (termid, storecode, yearid) |

---

## Cross-References

- **Common patterns**: `reference/common-patterns.md` (CTE params, no binds, NVL, DECODE)
- **Table schema**: `reference/tables-schema.md` (STANDARD, STANDARDGRADESECTION, etc.)
- **SBG templates**: `templates/sbg-*.sql` (7 group templates)

---

## Quick Reference: SBG Template Mapping

| Group | Template File | Use When |
|-------|---------------|----------|
| Standards & Assignments | `sbg-standards-assignments.sql` | Need assignment-standard links |
| Proficiency by Grade | `sbg-proficiency-grade.sql` | % proficient by grade level |
| Subject Averages | `sbg-subject-averages.sql` | Aggregate scores by subject |
| VPR/CRP Targets | `sbg-vpr-crp.sql` | Target tracking, copy to new year |
| Gradebook/Config | `sbg-gradebook-config.sql` | Config validation |
| Report Card/PSM | `sbg-reportcard-psm.sql` | PSM report card data |
| Assessment Load | `sbg-assessment-load.sql` | Bulk load/import |