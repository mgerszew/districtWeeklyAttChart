# PowerSchool Oracle SQL Reference — Enrollment Queries

Source: `docs/powerschool/PowerSchool_Oracle_Query_Reference.md` (lines 252-433)

---

## Query Inventory

| # | Query File | Purpose | Key Tables |
|---|------------|---------|------------|
| 1 | Enrollment by Demographic.sql | Enrollment counts by race, EL, IEP, SES | terms, cc, students, S_ND_STU_X |
| 2 | Enrollment by Demographic by date.sql | Snapshot on specific date | terms, cc, students, PS_ENROLLMENT_ALL, S_ND_STU_X |
| 3 | Enrollment - BECEP at Elementary.sql | BECEP program at elementary schools | U_SECTIONS_BPS, schools, CC, students |
| 4 | Class Counts.sql | Class counts per school/section (elementary) | cc, sections, terms, schools, courses |
| 5 | Class Counts - Secondary.sql | Class counts for secondary schools | Same as #4, secondary school range |
| 6 | Class Counts - refactor.sql | Refactored with cfg CTE | dual, cfg (CTE), derived subqueries |
| 7 | Career Academy enrollments by year.sql | Career Academy totals per year | reenrollments, students, cc, terms, stu2021, re2021 |
| 8 | ADM Rollup by Grade Band.sql | ADM by grade band | students, enrollment |
| 9 | StudentID Races.sql | Student IDs with race info | students, STUDENTRACE |
| 10 | Student roster with homeroom.sql | Full roster + homeroom + teacher | dual, cc, params (CTE), courses, students, sections, SCHOOLSTAFF, users, schools, terms |
| 11 | Section enrollment physical school different.sql | Physical ≠ home school | U_SECTIONS_BPS, schools, cc, students |
| 12 | Section Counts for BOY Reporting.sql | BOY section counts | Sections, Schools, Courses |
| 13 | Panorama Student Roster.sql | Panorama-formatted roster | reenrollments, enr (derived), terms |
| 14 | New to District as of date.sql | New students as of date | Students |
| 15 | Students added to PowerSchool by month.sql | Monthly new student counts | S_ND_STU_X, students, PS_ENROLLMENT_ALL |
| 16 | Students on specific date by school wCapacity.sql | Snapshot + capacity | ps_enrollment_all, schools, U_SCHOOLS_BPS, terms |
| 17 | Students in specific courses by gender-ethnicity.sql | Course enrollment by gender/ethnicity | cc, hsRemedial, students, schools, terms, courses |
| 18 | Students on specific date by school.sql | Snapshot by school | ps_enrollment_all, schools |
| 19 | Students on specific date.sql | District-wide snapshot | ps_enrollment_all, terms |

---

## Core Tables & Key Columns

### students
- `id` (student_number), `dcid` (PK for joins)
- `schoolid` → **schools.school_number** (not schoolid!)
- `entrydate`, `exitdate`, `enroll_status` (0=active)
- `grade_level`, `ethnicity`, `gender`, `dob`
- `person_id` → PERSON.id

### cc (Course Enrollment)
- `studentid` → students.id
- `sectionid` → sections.id
- `dateenrolled`, `dateleft`
- `expression` (period/day pattern)

### sections
- `id`, `course_number` → courses.course_number
- `schoolid` → schools.school_number
- `termid` → terms.id
- `teacher` → schoolstaff.id

### terms
- `id`, `yearid`, `schoolid` → schools.school_number
- `firstday`, `lastday`, `isyearrec` (1 = year record)
- `name` (e.g., '2024-2025', 'Q1')

### schools
- `school_number` = FK target for students.schoolid, sections.schoolid
- `schoolid` = internal DCID
- `name`, `schoolcategorycodesetid` → CODESET

### courses
- `course_number`, `course_name`, `credittype`

### SCHOOLSTAFF / users
- `schoolstaff.id` → sections.teacher
- `schoolstaff.users_dcid` → users.dcid
- `users.lastfirst`, `users.email`

### PS_ENROLLMENT_ALL
- All enrollment records (current + historical)
- `studentid`, `schoolid`, `entrydate`, `exitdate`, `grade_level`
- Better for snapshots than `cc` (doesn't require section)

### U_SECTIONS_BPS (District Custom)
- `physical_schoolid` → schools.school_number
- Links section to physical location (may differ from home school)

### U_SCHOOLS_BPS (District Custom)
- Capacity fields, custom attributes

### S_ND_STU_X (State Custom)
- `whencreated` for "added to PS" date
- Various state fields

### STUDENTRACE
- `studentid` → students.id
- `racecd` → gen (federalrace) or codeset

---

## Key Join Patterns

### 1. Student → CC → Section → Course → Term → School
```sql
students s
INNER JOIN cc ON cc.studentid = s.id
INNER JOIN sections sec ON sec.id = cc.sectionid
INNER JOIN courses c ON c.course_number = sec.course_number
INNER JOIN terms t ON t.id = sec.termid
INNER JOIN schools sch ON sch.school_number = sec.schoolid
WHERE t.isyearrec = 1
```

### 2. Enrollment Snapshot (Date-Based)
```sql
PS_ENROLLMENT_ALL e
INNER JOIN students s ON s.id = e.studentid
INNER JOIN schools sch ON sch.school_number = e.schoolid
WHERE e.entrydate <= :snapshot_date
  AND e.exitdate > :snapshot_date
  AND s.enroll_status = 0
```

### 3. Student + Homeroom Teacher
```sql
students s
LEFT JOIN cc ON cc.studentid = s.id AND cc.dateenrolled <= :date AND cc.dateleft > :date
LEFT JOIN sections sec ON sec.id = cc.sectionid
LEFT JOIN courses c ON c.course_number = sec.course_number
LEFT JOIN schoolstaff ss ON ss.id = sec.teacher
LEFT JOIN users u ON u.dcid = ss.users_dcid
WHERE c.course_name LIKE '%Homeroom%'
```

### 4. Demographic Flags (from S_ND_STU_X / gen)
```sql
students s
LEFT JOIN S_ND_STU_X sx ON sx.studentsdcid = s.dcid
LEFT JOIN gen g_iep ON g_iep.cat = 'iep' AND g_iep.name = 'Y'
LEFT JOIN gen g_el ON g_el.cat = 'lep' AND g_el.name = 'Y'
LEFT JOIN STUDENTRACE sr ON sr.studentid = s.id
LEFT JOIN gen g_race ON g_race.cat = 'federalrace' AND g_race.name = sr.racecd
```

### 5. Physical School Different from Home
```sql
U_SECTIONS_BPS usb
INNER JOIN sections sec ON sec.id = usb.id
INNER JOIN schools home_sch ON home_sch.school_number = sec.schoolid
INNER JOIN schools phys_sch ON phys_sch.school_number = usb.physical_schoolid
WHERE usb.physical_schoolid IS NOT NULL
  AND home_sch.school_number != phys_sch.school_number
```

### 6. Panorama Roster Deduplication
```sql
WITH enr AS (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY studentid ORDER BY entrydate DESC) AS rn
  FROM PS_ENROLLMENT_ALL
  WHERE yearid = 33 AND entrydate <= :date AND exitdate > :date
)
SELECT * FROM enr WHERE rn = 1
```

---

## CTE Parameter Patterns

### Pattern 1: Config CTE (Query #6)
```sql
WITH cfg AS (
  SELECT 
    40 AS school_start,
    70 AS school_end,
    TO_DATE('10/01/2024','mm/dd/yyyy') AS cfgDate
  FROM dual
)
```

### Pattern 2: Snapshot Date (Queries #2, #16, #18, #19)
```sql
WITH params AS (
  SELECT 
    TO_DATE('10/01/2024','mm/dd/yyyy') AS snap_date,
    33 AS yearid
  FROM dual
),
snap AS (
  SELECT * FROM PS_ENROLLMENT_ALL
  WHERE entrydate <= (SELECT snap_date FROM params)
    AND exitdate > (SELECT snap_date FROM params)
    AND yearid = (SELECT yearid FROM params)
)
```

### Pattern 3: Dynamic Date from Term (Query #16)
```sql
TO_DATE('9/10/' || EXTRACT(YEAR FROM t.firstday), 'mm/dd/yyyy')
```

---

## Common Filters

| Filter | SQL |
|--------|-----|
| Active students | `s.enroll_status = 0` |
| Current year | `t.yearid = 33` → `params` CTE |
| School range | `sch.school_number BETWEEN 40 AND 89` |
| Section active on date | `cc.dateenrolled <= :date AND cc.dateleft > :date` |
| Elementary | `sch.school_number BETWEEN 40 AND 69` |
| Secondary | `sch.school_number BETWEEN 70 AND 89` |
| Course name filter | `c.course_name LIKE '%Homeroom%'` |

---

## Hardcoded Values to Parameterize

| Query | Hardcoded | Move To |
|-------|-----------|---------|
| #1 | `terms.yearid = 33`, `schoolid 80-89` | `params` CTE |
| #2 | `yearid = 33`, `date = 5/27/2023`, `school 40-89` | `params` CTE |
| #4 | School range implied | `params` CTE |
| #5 | Secondary range implied | `params` CTE |
| #6 | `school 70-84`, `40-70` | `cfg` CTE |
| #7 | `stuterm.yearid = 30` | `params` CTE |
| #10 | No params (uses dual for constants) | `params` CTE |
| #13 | `enr.YearID IN (33)` | `params` CTE |
| #15 | `EXTRACT(YEAR FROM snd.WHENCREATED) >= 2018` | `params` CTE |
| #16 | Dynamic date from term | `params` CTE + term join |
| #17 | No params | Add `params` CTE |

---

## Parameterization (AGENTS.md §3)

- **No bind variables** — use CTE `params`
- **No PL/SQL** — plain SQL only
- **GPV tags** in comments (`--~(gpv.yearid)`) indicate intended params

---

## Performance Flags

| Table | Risk | Mitigation |
|-------|------|------------|
| PS_ENROLLMENT_ALL | Large, full scans | Index (studentid, entrydate, exitdate); filter yearid first |
| cc | Large, active enrollments | Index (studentid, dateenrolled, dateleft); filter date early |
| sections | Medium | Index (id, course_number, schoolid, termid) |
| students | Core table | PK on dcid; index schoolid |
| terms | Small | PK on id; index (yearid, isyearrec) |

---

## Cross-References

- **Common patterns**: `reference/common-patterns.md` (CTE params, no binds)
- **Table schema**: `reference/tables-schema.md` (students, cc, sections, terms, PS_ENROLLMENT_ALL)
- **Enrollment template**: `templates/enrollment-template.sql`