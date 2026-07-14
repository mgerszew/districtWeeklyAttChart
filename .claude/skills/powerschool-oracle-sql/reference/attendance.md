# PowerSchool Oracle SQL Reference — Attendance Queries

Source: `docs/powerschool/PowerSchool_Oracle_Query_Reference.md` (lines 27-126)

---

## Query Inventory

| # | Query File | Purpose | Key Tables |
|---|------------|---------|------------|
| 1 | Attendance-Tardy Percentage comparisons.sql | Attendance/tardy % by school over date range | CALENDAR_DAY, TERMS, ps_adaadm_meeting_ptod, ps_membership_defaults, PS_ATTENDANCE_MEETING, students, reenrollments, gen, schools |
| 2 | ADAADM by Subgroup.sql | ADA/ADM by subgroup (race, homeless, IEP) | Students, StudentRace, gen, S_ND_STU_X, S_ND_STU_HOMELESSPROGRAMS_C, PS_ADAADM_MEETING_PTOD, SCHOOLS |
| 3 | ADAADM by School date range.sql | ADA/ADM per school over date range, feeder grouping | CALENDAR_DAY, PS_ADAADM_MEETING_PTOD, SCHOOLS |
| 4 | ADAADM by Division.sql | ADA/ADM % by Elementary vs Secondary | students, PS_ADAADM_MEETING_PTOD, SCHOOLS, CODESET |
| 5 | Attendance-Tardy Percentages by school and date range.sql | School-level attendance/tardy % for date range | CALENDAR_DAY, ps_adaadm_meeting_ptod, ps_membership_defaults, PS_ATTENDANCE_MEETING, students, reenrollments, gen, schools |
| 6 | ScholarChip Saber query.sql | Saber attendance by course category | attendance, courses, students, attendance_code, period, cc, U_STUDENTS_BPS |
| 7 | Day number by year.sql | Day-of-year number for school year window | CALENDAR_DAY, TERMS |
| 8 | Suspensions - number of equivalent days.sql | Convert suspension periods to day equivalents | attendance, ATTENDANCE_CODE, ps_period_att, students, schools, terms |

---

## Core Tables & Key Columns

### CALENDAR_DAY
- `schoolid` → **SCHOOLS.school_number** (NOT schools.schoolid)
- `date_value`, `insession`, `day_in_school_year`, `school_year`
- Join TERMS: `terms.schoolid = calendar_day.schoolid AND terms.isyearrec = 1`

### TERMS
- `schoolid`, `isyearrec`, `yearid`, `firstday`, `lastday`, `name`
- Year record: `ISYEARREC = 1`

### PS_ADAADM_MEETING_PTOD / ps_adaadm_meeting_ptod
- `schoolid`, `calendardate`, `membershipvalue`, `ada`, `adm`, `tardy`, `absent`
- Join params on school + date range

### PS_ATTENDANCE_MEETING
- `studentid`, `att_date`, `attendance_codeid`, `periodid`, `sectionid`
- Join `attendance_code` on `attendance_codeid` for code meaning

### attendance (table)
- `studentid`, `att_date`, `attendance_codeid`, `periodid`, `att_comment` (JSON in ScholarChip)
- Filter: `attendance_codeid IN (SELECT id FROM attendance_code WHERE att_code IN ('ISS','OSS'))`

### attendance_code
- `id`, `att_code`, `description`, `presence_status_cd`
- ISS/OSS codes for suspensions

### ps_period_att
- `schoolid`, `yearid`, `potential_periods` (for suspension day conversion)

### students / reenrollments
- Union pattern for historical: `students UNION reenrollments`
- Filter: `entrydate < exitdate`, `enroll_status = 0`

### SCHOOLS
- `school_number` = FK target for most tables' `schoolid`
- `schoolid` = internal DCID (different!)
- `schoolcategorycodesetid` → CODESET for Elementary/Secondary

### CODESET
- `codesetid`, `code`, `displayvalue`
- Used for school category: `displayvalue = 'ELEM'` → 'Elementary'

### U_STUDENTS_BPS (District Custom)
- Contract period totals, Saber course mapping
- Student-specific fields for local reporting

---

## Key Join Patterns

### 1. Calendar Day → Term Year Record
```sql
CALENDAR_DAY cd
INNER JOIN TERMS t 
  ON t.schoolid = cd.schoolid 
  AND t.isyearrec = 1
  AND cd.date_value BETWEEN t.firstday AND t.lastday
WHERE cd.insession = 1
```

### 2. ADA/ADM with Parameter CTE
```sql
WITH params AS (
  SELECT 84 AS schoolid, 
         TO_DATE('08/28/2024','mm/dd/yyyy') AS startdate,
         TO_DATE('06/10/2025','mm/dd/yyyy') AS enddate
  FROM dual
),
adm AS (
  SELECT * FROM ps_adaadm_meeting_ptod
  WHERE schoolid = (SELECT schoolid FROM params)
    AND calendardate BETWEEN (SELECT startdate FROM params) AND (SELECT enddate FROM params)
    AND membershipvalue > 0
)
```

### 3. Student Enrollment Union (Historical + Current)
```sql
(SELECT id AS studentid, entrydate, exitdate FROM students WHERE enroll_status = 0
 UNION ALL
 SELECT studentid, entrydate, exitdate FROM reenrollments WHERE enroll_status = 0) stu
```

### 4. Attendance Meeting with Membership Defaults
```sql
ps_adaadm_meeting_ptod ada
INNER JOIN params p ON ada.schoolid = p.schoolid
LEFT JOIN ps_membership_defaults mv ON mv.schoolid = ada.schoolid
LEFT JOIN PS_ATTENDANCE_MEETING meet 
  ON meet.studentid = stu.studentid 
  AND meet.att_date = ada.calendardate
```

### 5. School Category (Elementary/Secondary)
```sql
SCHOOLS sc
LEFT JOIN CODESET cs ON sc.schoolcategorycodesetid = cs.codesetid
CASE WHEN cs.displayvalue = 'ELEM' THEN 'Elementary' ELSE 'Secondary' END AS division
```

### 6. ScholarChip Saber JSON Extraction
```sql
JSON_VALUE(a.att_comment, '$.course') AS saber_course
FROM attendance a
JOIN courses c ON c.course_number = JSON_VALUE(a.att_comment, '$.course')
WHERE a.schoolid = 84
```

### 7. Suspension Period to Day Conversion
```sql
WITH suspended AS (
  SELECT 
    a.studentid,
    a.att_date,
    COUNT(*) AS numPeriods
  FROM attendance a
  JOIN attendance_code ac ON ac.id = a.attendance_codeid
  WHERE ac.att_code IN ('ISS','OSS')
  GROUP BY a.studentid, a.att_date
)
SELECT 
  s.studentid,
  ROUND(SUM(s.numPeriods / ppa.potential_periods), 1) AS equiv_days
FROM suspended s
JOIN ps_period_att ppa ON ppa.schoolid = s.schoolid AND ppa.yearid = 27
GROUP BY s.studentid
HAVING ROUND(SUM(s.numPeriods / ppa.potential_periods), 1) >= 10
```

---

## CTE Parameter Pattern

```sql
WITH params AS (
  SELECT 
    84 AS schoolid,
    TO_DATE('08/28/2024','mm/dd/yyyy') AS startdate,
    TO_DATE('06/10/2025','mm/dd/yyyy') AS enddate,
    33 AS yearid
  FROM dual
),
daynumByYear AS (
  SELECT 
    cd.schoolid,
    MIN(cd.day_in_school_year) AS firstDay,
    MAX(cd.day_in_school_year) AS lastDay
  FROM calendar_day cd
  JOIN terms t ON t.schoolid = cd.schoolid AND t.isyearrec = 1
  WHERE cd.insession = 1
    AND cd.date_value < SYSDATE - 1  -- Exclude current day
  GROUP BY cd.schoolid
),
reportYears AS (
  SELECT DISTINCT t.yearid FROM terms t WHERE t.isyearrec = 1
)
```

---

## Common Filters

| Filter | SQL |
|--------|-----|
| In-session days only | `cd.insession = 1` |
| Exclude today | `cd.date_value < SYSDATE - 1` |
| Membership > 0 | `ada.membershipvalue > 0` |
| Active students | `s.enroll_status = 0` |
| Valid enrollment span | `a.entrydate < a.exitdate` |
| ISS/OSS only | `ac.att_code IN ('ISS','OSS')` |
| Date range | `ada.calendardate BETWEEN :start AND :end` → CTE param |
| School filter | `ada.schoolid = 84` → CTE param |

---

## Date Handling Patterns

| Pattern | SQL |
|---------|-----|
| Fiscal year end | `enddate = '6/30/' || (EXTRACT(YEAR FROM startdate) + 1)` |
| First in-session day | `MIN(cd.day_in_school_year) WHERE insession=1` |
| Last in-session day | `MAX(cd.day_in_school_year) WHERE insession=1` |
| Day number match | `cd.day_in_school_year = params.target_day` |

---

## Hardcoded Values to Parameterize

| Query | Hardcoded | Move To |
|-------|-----------|---------|
| #1 | `ada.calendardate BETWEEN ...` | `params` CTE |
| #1 | `SYSDATE - 1` | `params` CTE or leave as-is (runtime) |
| #2 | No explicit params (uses CTEs) | Already CTE-based |
| #3 | Commented date ranges | `params` CTE |
| #4 | `ppa.year_id = 27` | `params` CTE |
| #5 | `WHERE` clauses with dates | `params` CTE |
| #6 | `school = 84`, `course_number LIKE 'LHS%'` | `params` CTE |
| #7 | `SYSDATE - 1` | `params` CTE |
| #8 | `ppa.year_id = 27` | `params` CTE |

---

## Performance Flags

| Table | Risk | Mitigation |
|-------|------|------------|
| PS_ATTENDANCE_MEETING | Very large, partitioned by date | Filter date first, then join; index (studentid, att_date) |
| ps_adaadm_meeting_ptod | Pre-aggregated, smaller | Filter school + date range first |
| CALENDAR_DAY | One row per day per school | Index (schoolid, date_value, insession) |
| attendance (Suspensions) | Filter ISS/OSS early | Join attendance_code first with IN list |
| ps_period_att | Small (periods per year) | No issue |

---

## Cross-References

- **Common patterns**: `reference/common-patterns.md`
- **Table schema**: `reference/tables-schema.md` (CALENDAR_DAY, TERMS, PS_ADAADM_MEETING_PTOD, attendance)
- **Attendance template**: `templates/attendance-template.sql`