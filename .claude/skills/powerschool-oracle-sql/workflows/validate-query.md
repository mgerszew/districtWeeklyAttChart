# Workflow: Validate Query Against PowerSchool Conventions

**Goal**: Ensure query follows all AGENTS.md §3 rules and PowerSchool best practices before deployment.

---

## Step 1: Run Automated Validation

**Ask opencode**:
> "Run the validation script on my query file"

```bash
./scripts/validate-sql.sh my-query.sql
```

Or in opencode:
> "Check my query against the validation checklist"

---

## Step 2: Automated Checks (validate-sql.sh)

| Check | Pattern | Severity |
|-------|---------|----------|
| No SELECT * | `SELECT\s+\*` | ERROR |
| No bind variables | `[:&]\w+` | ERROR |
| No PL/SQL | `\bDECLARE\b` | ERROR |
| No comma joins | `FROM\s+\w+\s*,\s*\w+` | WARNING |
| Has params CTE | `WITH\s+params\s+AS` | ERROR |
| School FK correct | `schoolid.*schools\.schoolid` | ERROR |
| No hardcoded yearid | `yearid\s*=\s*\d{2}` | WARNING |
| SYSDATE -1 used | `SYSDATE\s*(?!-\s*1)` | WARNING |
| Explicit columns | (inverse of SELECT *) | ERROR |

---

## Step 3: Manual Validation Checklist

**Ask opencode**:
> "Walk through the manual validation checklist with me"

### Structure
- [ ] `WITH params AS (...)` at very top
- [ ] All user inputs in `params` (yearid, schoolid, dates, storecode)
- [ ] No hardcoded values in query body
- [ ] CTEs ordered: params → derived → base → aggregated → final
- [ ] Single final SELECT

### Joins
- [ ] ANSI JOIN syntax (`JOIN ... ON`)
- [ ] No comma joins
- [ ] All columns qualified (`alias.column`)
- [ ] School FKs → `schools.school_number` (not `schoolid`)

### Columns
- [ ] Explicit column list (no `SELECT *`)
- [ ] Meaningful aliases (`s.id AS student_id`)
- [ ] No duplicate column names in output

### Functions
- [ ] `NVL`/`COALESCE` on nullable columns
- [ ] `TO_DATE` with explicit mask for dates
- [ ] `SYSDATE - 1` to exclude current day (attendance)
- [ ] No `DECODE` where `CASE` is clearer (optional)

### Parameterization
- [ ] No `:bind_var` or `&subst_var`
- [ ] No PL/SQL blocks
- [ ] GPV tags only in PSHTML context (not raw SQL)
- [ ] IN lists → CTE (`stulist`)

### Performance
- [ ] Large tables filtered in early CTEs
- [ ] `UNION ALL` used (not `UNION`) where safe
- [ ] No `SELECT *` in any CTE
- [ ] Hints only where tested (`/*+ MATERIALIZE */`)

### PowerSchool Specific
- [ ] `terms.isyearrec = 1` for year records
- [ ] `calendar_day.insession = 1` for school days
- [ ] `students.enroll_status = 0` for active
- [ ] `cc.dateenrolled <= date AND cc.dateleft > date` for enrollment spans
- [ ] Custom tables `U_*` documented in comments

### Documentation
- [ ] Header comment: purpose, tables, author, date
- [ ] Inline comments for non-obvious logic
- [ ] `-- FIXME:` for known issues
- [ ] Parameter descriptions in `params` CTE

---

## Step 4: Fix Violations

**Ask opencode**:
> "Fix the violations found in my query"

For each violation, apply standard fix from `reference/common-patterns.md`.

---

## Step 5: Peer Review Prompt

**Ask opencode**:
> "Generate a code review summary for this query"

Output format:
```
## Query Review: [filename]

### Violations (must fix)
- [ ] SELECT * on line 45
- [ ] Hardcoded yearid=33 on line 67

### Warnings (should fix)
- [ ] UNION on line 89 (use UNION ALL)
- [ ] SYSDATE without -1 on line 23

### Suggestions
- Consider index on PS_ATTENDANCE_MEETING(studentid, att_date)
- Add comment explaining NVL on line 34

### Approved: No / Yes (with fixes)
```

---

## Step 6: Test in Sandbox

**Ask opencode**:
> "Confirm this should run in sandbox/dev only"

Per AGENTS.md §2: **Always confirm target environment before running any SQL**.

---

## Example Prompts

> "Validate my attendance query against all conventions"
> "Check for bind variables in my SBG proficiency query"
> "Review my query for school FK correctness (schoolid vs school_number)"
> "Generate a code review summary for my enrollment snapshot query"

---

## Integration with opencode

Run validation automatically:
```bash
# In workflow/validate-query.md step
./scripts/validate-sql.sh "$1" && echo "PASS" || echo "FAIL"
```

---

## Next Steps

- Fix all ERROR violations
- Address WARNING items
- Run in sandbox with debug=1
- Deploy to production only after review