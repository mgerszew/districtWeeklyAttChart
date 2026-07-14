# Workflow: Convert Bind Variables to CTE Parameters

**Goal**: Transform legacy queries using `:bind_var` or `&subst_var` into PowerSchool-compliant CTE parameter pattern.

---

## Step 1: Identify Bind Variables

**Ask opencode**:
> "Scan my query for bind variables and substitution variables"

**Search patterns**:
```regex
-- Oracle bind variables
:\w+                    -- :yearid, :schoolid, :startdate

-- SQL*Plus substitution
&\w+                    -- &yearid, &schoolid

-- PL/SQL style (invalid in tlist_sql)
DECLARE|BEGIN|:=
```

---

## Step 2: Categorize Each Variable

**Ask opencode**:
> "Classify each variable I found: input, computed, or context"

| Variable | Type | Becomes |
|----------|------|---------|
| `:yearid` | Input | `params.yearid` |
| `:schoolid` | Input | `params.schoolid` |
| `:startdate` | Input | `params.startdate` |
| `:enddate` | Input | `params.enddate` |
| `:student_list` | Input | `stulist` CTE |
| `SYSDATE` | Runtime | Keep or `params.run_date` |
| `EXTRACT(YEAR FROM ...)` | Computed | `derived_params` CTE |

---

## Step 3: Create params CTE

**Ask opencode**:
> "Generate the params CTE for my variables"

```sql
WITH params AS (
  SELECT 
    33 AS yearid,
    84 AS schoolid,
    TO_DATE('08/20/2024','mm/dd/yyyy') AS startdate,
    TO_DATE('06/10/2025','mm/dd/yyyy') AS enddate
  FROM dual
),
```

### For IN Lists (Student Lists)
```sql
stulist AS (
  SELECT column_value AS studentid
  FROM TABLE(sys.odcinumberlist(12345, 67890, 11111))
  -- Or from GPV: split ~(gpv.students) comma list
),
```

### For Multi-Year Comparison
```sql
params_yr1 AS (SELECT 27 AS yearid FROM dual),
params_yr2 AS (SELECT 28 AS yearid FROM dual),
```

---

## Step 4: Replace All References

**Ask opencode**:
> "Replace all bind variable references with CTE references"

| Old | New |
|-----|-----|
| `:yearid` | `(SELECT yearid FROM params)` |
| `&schoolid` | `(SELECT schoolid FROM params)` |
| `:startdate` | `(SELECT startdate FROM params)` |
| `IN (:student_list)` | `IN (SELECT studentid FROM stulist)` |
| `yearid = 33` | `yearid = (SELECT yearid FROM params)` |

### Join with derived_params
```sql
derived_params AS (
  SELECT 
    p.*,
    t.firstday,
    t.lastday
  FROM params p
  JOIN terms t ON t.yearid = p.yearid AND t.isyearrec = 1 AND t.schoolid = p.schoolid
)
-- Then use: (SELECT firstday FROM derived_params)
```

---

## Step 5: Handle GPV/PSHTML Tags

**Ask opencode**:
> "My query has ~(gpv.var) tags. Are these OK?"

- **In tlist_sql/PSHTML**: YES — these are pre-substitution tags
- **In raw SQL file**: NO — replace with CTE params
- **Migration**: If moving from PSHTML to standalone SQL, convert GPV → CTE

```sql
-- PSHTML (keep GPV):
WHERE cd.date_value BETWEEN ~(gpv.startdate) AND ~(gpv.enddate)

-- Standalone SQL (convert to CTE):
WHERE cd.date_value BETWEEN (SELECT startdate FROM params) 
                         AND (SELECT enddate FROM params)
```

---

## Step 6: Remove PL/SQL Blocks

**Ask opencode**:
> "Check for any DECLARE/BEGIN blocks and remove them"

**Before (invalid)**:
```sql
DECLARE
  v_year NUMBER := 33;
BEGIN
  SELECT ... WHERE yearid = v_year;
END;
```

**After (valid)**:
```sql
WITH params AS (SELECT 33 AS yearid FROM dual)
SELECT ... WHERE yearid = (SELECT yearid FROM params);
```

---

## Step 7: Validate Conversion

**Ask opencode**:
> "Run validation on my converted query"

Run: `./scripts/validate-sql.sh converted-query.sql`

**Checklist**:
- [ ] No `:var` or `&var` remain
- [ ] No `DECLARE`/`BEGIN`/`END`
- [ ] `params` CTE at top
- [ ] All former binds reference `(SELECT x FROM params)`
- [ ] `stulist` CTE for IN lists
- [ ] `derived_params` for computed values
- [ ] Query runs in SQL Developer

---

## Example: Before/After

### Before (Legacy)
```sql
SELECT s.lastfirst, COUNT(a.id) AS absences
FROM students s
JOIN attendance a ON a.studentid = s.id
WHERE a.att_date BETWEEN :startdate AND :enddate
  AND a.attendance_codeid IN (SELECT id FROM attendance_code WHERE att_code IN ('A','U'))
  AND s.schoolid = :schoolid
  AND s.enroll_status = 0
  AND s.id IN (:student_list)
ORDER BY s.lastfirst;
```

### After (CTE Params)
```sql
WITH params AS (
  SELECT 
    TO_DATE('08/20/2024','mm/dd/yyyy') AS startdate,
    TO_DATE('06/10/2025','mm/dd/yyyy') AS enddate,
    84 AS schoolid
  FROM dual
),
stulist AS (
  SELECT column_value AS studentid
  FROM TABLE(sys.odcinumberlist(1001, 1002, 1003))
)
SELECT s.lastfirst, COUNT(a.id) AS absences
FROM students s
JOIN attendance a ON a.studentid = s.id
CROSS JOIN params p
WHERE a.att_date BETWEEN p.startdate AND p.enddate
  AND a.attendance_codeid IN (SELECT id FROM attendance_code WHERE att_code IN ('A','U'))
  AND s.schoolid = p.schoolid
  AND s.enroll_status = 0
  AND s.id IN (SELECT studentid FROM stulist)
ORDER BY s.lastfirst;
```

---

## Example Prompts

> "Convert this query with :yearid and :schoolid binds to CTE params"
> "Replace the &student_list substitution variable with stulist CTE"
> "Remove the DECLARE block from this PL/SQL query"
> "My query uses ~(gpv.startdate) - should I keep it or convert?"
> "Validate my converted query has no remaining bind variables"

---

## Next Steps

- Apply to all legacy queries in repo
- Update any documentation referencing old syntax
- Add to CI validation (validate-sql.sh catches binds)