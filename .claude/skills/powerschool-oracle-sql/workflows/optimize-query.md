# Workflow: Optimize Slow PowerSchool Query

**Goal**: Identify and fix performance bottlenecks in Oracle queries against PowerSchool schema.

---

## Step 1: Get Execution Plan

**Ask opencode**:
> "Run explain plan on my query and show the output"

```sql
EXPLAIN PLAN FOR [your query];
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(FORMAT => 'ALL'));
```

Look for:
- `FULL TABLE SCAN` on large tables
- `HASH JOIN` vs `NESTED LOOPS` (unexpected)
- `CARTESIAN PRODUCT` (missing join)
- High `COST` or `BYTES`

---

## Step 2: Identify Problem Tables

**Ask opencode**:
> "Which tables in my query are largest and have full scans?"

| Table | Typical Size | Risk |
|-------|--------------|------|
| `PS_ATTENDANCE_MEETING` | Millions | Filter `att_date` first |
| `attendance` | Millions | Filter `att_date` + `attendance_codeid` first |
| `cc` | Hundreds of thousands | Filter `termid` + `dateenrolled` first |
| `STANDARDGRADESECTION` | Large | Filter `storecode` + `yearid` first |
| `STANDARDSCORE` | Very large | Partition by yearid |
| `STANDARDSGRADES` | Large | Filter `storecode` + `yearid` first |
| `PS_ENROLLMENT_ALL` | Large | Filter `yearid` + `schoolid` first |
| `students` | ~50K-200K | PK on dcid, index schoolid |

---

## Step 3: Apply Filter-Early Pattern

**Ask opencode**:
> "Restructure my query to filter large tables in CTEs before joining"

**Before (slow)**:
```sql
SELECT ... 
FROM large_table lt
JOIN small_table st ON st.id = lt.fk
WHERE lt.yearid = 33 AND lt.schoolid = 84
```

**After (fast)**:
```sql
WITH filtered AS (
  SELECT * FROM large_table
  WHERE yearid = 33 AND schoolid = 84  -- Filter FIRST
)
SELECT ...
FROM filtered f
JOIN small_table st ON st.id = f.fk
```

---

## Step 4: Check Indexes

**Ask opencode**:
> "Show indexes on the problem tables and suggest missing ones"

```sql
SELECT index_name, column_name 
FROM user_ind_columns 
WHERE table_name = 'PS_ATTENDANCE_MEETING'
ORDER BY index_name, column_position;
```

**Common Missing Indexes**:
| Table | Suggested Index |
|-------|-----------------|
| `PS_ATTENDANCE_MEETING` | `(studentid, att_date)` |
| `attendance` | `(studentid, att_date, attendance_codeid)` |
| `cc` | `(studentid, termid, dateenrolled)` |
| `STANDARDGRADESECTION` | `(standardid, storecode, yearid)` |
| `STANDARDSCORE` | `(assignmentid, standardid, studentid)` |
| `PS_ENROLLMENT_ALL` | `(yearid, schoolid, entrydate)` |

---

## Step 5: Optimize CTE Materialization

**Ask opencode**:
> "Add MATERIALIZE hint to expensive CTEs"

```sql
WITH large_cte AS (
  SELECT /*+ MATERIALIZE */ ... FROM ...
)
```

**When to use**:
- CTE referenced multiple times
- CTE has expensive aggregation
- CTE reduces rows significantly (>90%)

---

## Step 6: Fix Join Order

**Ask opencode**:
> "Reorder joins to start with most selective filter"

```sql
-- Good: start with filtered small result
FROM (SELECT * FROM students WHERE schoolid = 84) s
JOIN cc ON cc.studentid = s.id
JOIN sections sec ON sec.id = cc.sectionid
JOIN terms t ON t.id = sec.termid

-- Bad: start with large table
FROM cc
JOIN students s ON s.id = cc.studentid
WHERE s.schoolid = 84
```

---

## Step 7: Replace UNION with UNION ALL

**Ask opencode**:
> "Change UNION to UNION ALL where duplicates are impossible"

```sql
-- If you know no duplicates:
SELECT ... FROM students WHERE ...
UNION ALL
SELECT ... FROM reenrollments WHERE ...

-- Only use UNION if dedup needed (costly)
```

---

## Step 8: Avoid SELECT * in CTEs

**Ask opencode**:
> "Replace SELECT * with explicit columns in all CTEs"

```sql
-- Bad
WITH params AS (SELECT * FROM dual)

-- Good
WITH params AS (SELECT 33 AS yearid, 84 AS schoolid FROM dual)
```

---

## Step 9: Use Bind Variables in Application (Not in SQL)

**Reminder**: PowerSchool `tlist_sql` doesn't support binds. But for SQL Developer testing:
```sql
-- Use substitution variables for testing
VARIABLE v_yearid NUMBER;
EXEC :v_yearid := 33;
SELECT ... WHERE yearid = :v_yearid;
```

---

## Step 10: Partition Large Tables (DBA)

**Ask opencode**:
> "Check if large tables are partitioned by yearid"

```sql
SELECT table_name, partition_name, high_value
FROM user_tab_partitions
WHERE table_name IN ('STANDARDSCORE', 'PS_ATTENDANCE_MEETING');
```

If not partitioned, suggest to DBA:
```sql
-- Example partition by yearid
ALTER TABLE standardscore PARTITION BY RANGE (yearid) (
  PARTITION p_2023 VALUES LESS THAN (29),
  PARTITION p_2024 VALUES LESS THAN (30),
  PARTITION p_max VALUES LESS THAN (MAXVALUE)
);
```

---

## Quick Optimization Checklist

**Ask opencode**:
> "Run optimization checklist on my query"

- [ ] Explain plan shows no full scans on large tables
- [ ] Filters applied in CTEs before joins
- [ ] Indexes exist on join/filter columns
- [ ] `UNION ALL` used where appropriate
- [ ] No `SELECT *` in CTEs
- [ ] CTEs materialized where reused
- [ ] Join order starts with most selective
- [ ] Date ranges use explicit `TO_DATE`
- [ ] No Cartesian products
- [ ] Row estimates reasonable

---

## Example Prompts

> "My attendance query does full scan on PS_ATTENDANCE_MEETING. Show me how to filter by date first in a CTE"
> "Explain plan shows HASH JOIN on cc and students. Should I reorder?"
> "STANDARDGRADESECTION query is slow. What indexes should I request?"
> "My UNION is causing a sort. Can I use UNION ALL instead?"

---

## Next Steps

- Apply fixes → re-run explain plan
- Compare execution time before/after
- Document indexes requested
- Update query with optimizations