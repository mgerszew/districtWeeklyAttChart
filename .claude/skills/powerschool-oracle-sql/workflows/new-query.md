# Workflow: Create New PowerSchool Query

**Goal**: Build a new query from scratch following all conventions.

---

## Step 1: Identify Category

**Ask opencode**:
> "Which category does this query belong to? Attendance, Contacts, Enrollment, or SBG?"

Categories:
- **Attendance**: ADA/ADM, tardies, suspensions, day counts
- **Contacts**: Phones, emails, addresses, guardians, Clever export
- **Enrollment**: Demographics, class counts, snapshots, rosters
- **SBG**: Standards, proficiency, grades, VPR, report cards

---

## Step 2: Select Template

**Ask opencode**:
> "Give me the [category] template"

Templates:
- `templates/attendance-template.sql`
- `templates/contacts-template.sql`
- `templates/enrollment-template.sql`
- `templates/sbg-*.sql` (7 SBG group templates)

---

## Step 3: Define Parameters

**Ask opencode**:
> "Help me fill in the params CTE for my use case"

Standard params by category:

| Category | Required Params |
|----------|-----------------|
| Attendance | yearid, schoolid, startdate, enddate |
| Contacts | schoolid (or studentdcid), contact_type |
| Enrollment | yearid, schoolid_min, schoolid_max, snap_date |
| SBG | yearid, schoolid, storecode, grade_level |

Example:
```sql
WITH params AS (
  SELECT 
    33 AS yearid,
    84 AS schoolid,
    TO_DATE('08/20/2024','mm/dd/yyyy') AS startdate,
    TO_DATE('06/10/2025','mm/dd/yyyy') AS enddate
  FROM dual
)
```

---

## Step 4: Build Query in CTE Stages

**Ask opencode**:
> "Walk me through building the CTE chain for [specific requirement]"

Standard CTE order:
```sql
WITH params AS (...),
derived_params AS (
  -- Compute from params (e.g., term dates)
),
base_data AS (
  -- Filter large tables using params
),
joined AS (
  -- Join base_data with reference tables
),
aggregated AS (
  -- Group, aggregate, calculate
)
SELECT ... FROM aggregated;
```

---

## Step 5: Apply Category Patterns

**Ask opencode**:
> "Show me the key join patterns for [category]"

Reference files:
- `reference/attendance.md` → joins, filters, date logic
- `reference/contacts.md` → person/phone/address joins, KEEP DENSE_RANK
- `reference/enrollment.md` → cc/section/term joins, snapshot logic
- `reference/sbg.md` → ST/STANDARD/STANDARDGRADESECTION, Termbins

---

## Step 6: Validate

**Ask opencode**:
> "Validate my query against conventions"

Run: `./scripts/validate-sql.sh my-query.sql`

Or follow `workflows/validate-query.md` checklist.

---

## Step 7: Test in Sandbox

**Ask opencode**:
> "Confirm I should run this in sandbox/dev"

Per AGENTS.md: **Never run SQL in production without explicit confirmation**.

```sql
-- Test with debug
SET AUTOTRACE ON EXPLAIN;
-- Run query
```

---

## Step 8: Document

**Ask opencode**:
> "Add header comment and inline docs to my query"

Required header:
```sql
/*
 * Purpose: [One-line description]
 * Tables: [Main tables]
 * Params: yearid, schoolid, ...
 * Author: [name]
 * Date: [YYYY-MM-DD]
 * Notes: [Any quirks, FIXMEs]
 */
```

---

## Example Prompts

> "Create new attendance query: ADA by grade level for school 84, year 33"
> "Build contacts export: mobile phones for all guardians at school 40-89"
> "New enrollment snapshot: students on 10/1/2024 with capacity"
> "SBG proficiency by grade: Math standards, storecode Q3, year 33"
> "Help me choose the right SBG template for VPR target copy"

---

## Template Quick Reference

| Need | Template |
|------|----------|
| ADA/ADM, tardies, day counts | `attendance-template.sql` |
| Phones, emails, addresses, guardians | `contacts-template.sql` |
| Demographics, class counts, rosters | `enrollment-template.sql` |
| Assignment-standard links | `sbg-standards-assignments.sql` |
| % Proficient by grade | `sbg-proficiency-grade.sql` |
| Subject/domain averages | `sbg-subject-averages.sql` |
| VPR/CRP targets | `sbg-vpr-crp.sql` |
| Gradebook config | `sbg-gradebook-config.sql` |
| PSM report cards | `sbg-reportcard-psm.sql` |
| Assessment loads | `sbg-assessment-load.sql` |