# PowerSchool Oracle SQL — Common Patterns & Conventions

Source: `AGENTS.md` §3 (Coding Style & Conventions) + `docs/powerschool/PowerSchool_Oracle_Query_Reference.md`

---

## Core Rules (AGENTS.md §3)

### ❌ FORBIDDEN
- **Bind variables**: `:var`, `&var` — PowerSchool `tlist_sql` does not support them
- **PL/SQL blocks**: `DECLARE`, `BEGIN`, variable assignment
- **SELECT *** — Always use explicit column lists
- **Legacy comma joins**: `FROM a, b WHERE a.id = b.id` — Use ANSI JOIN

### ✅ REQUIRED
- **Parameterization via CTE**: `WITH params AS (SELECT ... FROM dual)`
- **GPV substitution**: `WHERE x = ~(gpv.varname)` (in PSHTML/tlist_sql context)
- **PSHTML tags**: `~(curstudid)`, `~(curschoolid)`, `~(curyearid)`
- **Explicit column lists**: `SELECT a.id, a.name, b.value`
- **ANSI JOIN syntax**: `JOIN b ON a.id = b.a_id`

---

## CTE Parameter Pattern (Standard)

```sql
WITH params AS (
  SELECT 
    33 AS yearid,
    84 AS schoolid,
    TO_DATE('08/20/2024','mm/dd/yyyy') AS startdate,
    TO_DATE('06/10/2025','mm/dd/yyyy') AS enddate,
    'Q3' AS storecode
  FROM dual
),
derived_params AS (
  SELECT 
    p.*,
    t.firstday,
    t.lastday
  FROM params p
  JOIN terms t ON t.yearid = p.yearid AND t.isyearrec = 1 AND t.schoolid = p.schoolid
)
SELECT ...
FROM derived_params dp
JOIN students s ON s.schoolid = dp.schoolid
...
```

### Variation: Multiple Param Sets (Year-over-Year)
```sql
WITH params_yr1 AS (SELECT 27 AS yearid FROM dual),
     params_yr2 AS (SELECT 28 AS yearid FROM dual)
SELECT ...
FROM params_yr1 p1
JOIN params_yr2 p2 ON 1=1  -- Cross join for comparison
...
```

---

## GPV / PSHTML Substitution (tlist_sql Context)

```sql
-- In PSHTML/tlist_sql report:
WHERE calendardate BETWEEN ~(gpv.startdate) AND ~(gpv.enddate)
  AND schoolid = ~(gpv.schoolid)
  AND studentid = ~(curstudid)
```

- Evaluated **before** query runs
- Not valid in raw SQL*Plus/SQL Developer — use CTE params there

---

## Date Handling

### Exclude Current Day (Standard)
```sql
WHERE cd.date_value < SYSDATE - 1
```

### Fiscal Year End
```sql
enddate = '6/30/' || (EXTRACT(YEAR FROM startdate) + 1)
```

### Dynamic Date from Term
```sql
TO_DATE('9/10/' || EXTRACT(YEAR FROM t.firstday), 'mm/dd/yyyy')
```

### First/Last In-Session Day
```sql
WITH cal AS (
  SELECT cd.*,
    ROW_NUMBER() OVER (PARTITION BY cd.schoolid ORDER BY cd.date_value) AS rn_asc,
    ROW_NUMBER() OVER (PARTITION BY cd.schoolid ORDER BY cd.date_value DESC) AS rn_desc
  FROM calendar_day cd
  JOIN terms t ON t.schoolid = cd.schoolid AND t.isyearrec = 1
  WHERE cd.insession = 1 AND cd.date_value < SYSDATE - 1
)
SELECT * FROM cal WHERE rn_asc = 1 OR rn_desc = 1
```

---

## School ID Quirk (CRITICAL)

| Column | References | NOT |
|--------|------------|-----|
| `students.schoolid` | `schools.school_number` | `schools.schoolid` (DCID) |
| `sections.schoolid` | `schools.school_number` | `schools.schoolid` |
| `calendar_day.schoolid` | `schools.school_number` | `schools.schoolid` |
| `PS_ADAADM_MEETING_PTOD.schoolid` | `schools.school_number` | `schools.schoolid` |

**Always use `schools.school_number` as FK target**

---

## Common Functions & Constructs

| Need | Oracle Syntax |
|------|---------------|
| Null coalesce | `NVL(col, default)` |
| Nullif | `NULLIF(col, '')` |
| Case expression | `CASE WHEN cond THEN a ELSE b END` |
| Decode (legacy) | `DECODE(col, val1, ret1, val2, ret2, default)` |
| String concat | `a || b` or `CONCAT(a, b)` |
| Substring | `SUBSTR(str, 1, 10)` |
| Replace | `REPLACE(str, 'old', 'new')` |
| Date literal | `DATE '2024-08-20'` or `TO_DATE('08/20/2024','mm/dd/yyyy')` |
| Current date | `SYSDATE` (not `CURRENT_DATE`) |
| JSON extract | `JSON_VALUE(col, '$.path')` |
| Row number | `ROW_NUMBER() OVER (PARTITION BY x ORDER BY y)` |
| List aggregate | `LISTAGG(col, ',') WITHIN GROUP (ORDER BY x)` |
| Keep first | `MAX(col) KEEP (DENSE_RANK FIRST ORDER BY priority)` |

---

## Union Patterns

### Students + Reenrollments (Historical)
```sql
(SELECT id AS studentid, entrydate, exitdate FROM students WHERE enroll_status = 0
 UNION ALL
 SELECT studentid, entrydate, exitdate FROM reenrollments WHERE enroll_status = 0) stu
```

### Demographic Aggregation (UNION ALL per category)
```sql
SELECT 'Ethnicity' AS category, race_label AS subgroup, COUNT(*) AS cnt FROM ... GROUP BY race_label
UNION ALL
SELECT 'IEP', CASE WHEN iep=1 THEN 'Yes' ELSE 'No' END, COUNT(*) FROM ... GROUP BY iep
UNION ALL
SELECT 'EL', CASE WHEN lep=1 THEN 'Yes' ELSE 'No' END, COUNT(*) FROM ... GROUP BY lep
```

---

## Performance Patterns

### Filter Early, Join Late
```sql
-- Good: filter calendar_day first
WITH cal AS (
  SELECT * FROM calendar_day 
  WHERE insession = 1 AND date_value BETWEEN :start AND :end
)
SELECT ... FROM cal JOIN terms ...

-- Bad: join first, filter later
SELECT ... FROM calendar_day cd JOIN terms t ... WHERE cd.insession = 1
```

### Materialize Large CTEs
```sql
WITH large_cte AS (SELECT /*+ MATERIALIZE */ ...)
SELECT ... FROM large_cte ...
```

### Avoid SELECT * in CTEs
```sql
-- Good
WITH params AS (SELECT yearid, schoolid FROM ...)
SELECT p.yearid, s.id FROM params p JOIN students s ON s.schoolid = p.schoolid

-- Bad
WITH params AS (SELECT * FROM ...)
```

---

## Validation Checklist (for validate-query workflow)

| Check | Pass Criteria |
|-------|---------------|
| No bind variables | No `:var` or `&var` |
| No PL/SQL | No `DECLARE`/`BEGIN` |
| No SELECT * | All columns explicit |
| Tables qualified | `schema.table` or `alias.column` |
| ANSI joins used | No comma joins |
| CTE params present | `WITH params AS (...)` at top |
| School FKs correct | `schoolid` → `schools.school_number` |
| No hardcoded years | Year IDs in `params` CTE |
| Date excludes today | `SYSDATE - 1` or param |
| NVL/COALESCE used | Nullable columns handled |

---

## Template Structure (All Templates Follow This)

```sql
-- =============================================
-- [Category] Query Template
-- Purpose: [One-line description]
-- Tables: [Key tables]
-- =============================================

WITH params AS (
  SELECT 
    [yearid] AS yearid,
    [schoolid] AS schoolid,
    TO_DATE('[start]','mm/dd/yyyy') AS startdate,
    TO_DATE('[end]','mm/dd/yyyy') AS enddate,
    '[storecode]' AS storecode
  FROM dual
),
[domain_cte] AS (
  -- Derived parameters, date ranges, term lookups
)
SELECT 
  [explicit columns]
FROM [domain_cte] dc
JOIN [core_table] ct ON ct.[fk] = dc.[pk]
WHERE [filters using dc.params]
ORDER BY [sort]
```

---

## Cross-References

- **AGENTS.md §3**: Full coding conventions
- **Attendance queries**: `reference/attendance.md`
- **Contacts queries**: `reference/contacts.md`
- **Enrollment queries**: `reference/enrollment.md`
- **SBG queries**: `reference/sbg.md`
- **Table schema**: `reference/tables-schema.md`
- **Templates**: `templates/*.sql`