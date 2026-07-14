# Workflow: Debug tlist_sql Query in PowerSchool

**Goal**: Troubleshoot a query running in PowerSchool's tlist_sql report engine.

---

## Step 1: Enable Debug Output

**In PowerSchool**:
1. Navigate to **System > System Settings > Debug Settings**
2. Enable: `Debug SQL` and `Debug tlist_sql`
3. Or add to report: `~(debug.sql)` in PSHTML

**Ask opencode**:
> "How do I enable tlist_sql debug in PowerSchool 25+?"

---

## Step 2: View Substituted Query

**Ask opencode**:
> "My tlist_sql query runs but returns wrong results. Show me how to see the actual SQL after GPV/tag substitution"

**Methods substitution**:

1. Run report with `debug=1` URL param:
   ```
   /admin/reports/runreport.html?debug=1&frn=001_report
   ```
2. Check page source for `<!-- SQL: ... -->` comments
3. Or enable `log.debug.sql=true` in `server.properties`

---

## Step 3: Common Substitution Issues

**Ask opencode**:
> "My GPV parameters aren't working. What are the common problems?"

| Issue | Cause | Fix |
|-------|-------|-----|
| `~(gpv.var)` empty | Param not in URL | Add `&gpv.var=value` to URL |
| `~(curstudid)` = 0 | Not on student page | Only works in student context |
| `~(curyearid)` wrong | Term not set | Set term in UI first |
| Date format error | GPV returns string | Use `TO_DATE(~(gpv.date),'mm/dd/yyyy')` |
| Tag not replaced | Wrong syntax | Use `~(tag)` not `~[tag]` |

---

## Step 4: Test Raw SQL First

**Ask opencode**:
> "Extract the substituted SQL and test it in SQL Developer first"

1. Copy substituted SQL from debug output
2. Run in SQL Developer / SQL*Plus
3. Verify results match expectation
4. Only then put back in tlist_sql

---

## Step 5: Handle tlist_sql Limits

**Ask opencode**:
> "My query works in SQL Developer but fails in tlist_sql. What are the limits?"

| Limit | Details |
|-------|---------|
| No bind variables | Use GPV or CTE params |
| No PL/SQL | Plain SELECT only |
| Single statement | No semicolon, no multiple statements |
| Column aliases | Required for `tlist_sql` field mapping |
| Row limit | ~10K rows practical max |
| Timeout | 30-60 sec typical |

---

## Step 6: Debug Specific Patterns

### GPV Date Parameters
```sql
-- In tlist_sql:
WHERE cd.date_value BETWEEN TO_DATE(~(gpv.startdate),'mm/dd/yyyy') 
                        AND TO_DATE(~(gpv.enddate),'mm/dd/yyyy')

-- URL: &gpv.startdate=08/20/2024&gpv.enddate=06/10/2025
```

### Student Context Tags
```sql
-- Only works on student pages:
WHERE s.id = ~(curstudid)
AND s.schoolid = ~(curschoolid)
```

### Conditional Blocks
```html
~[if#~(gpv.optional_param)~]
  AND s.grade_level = ~(gpv.optional_param)
[/if#]
```

---

## Step 7: Performance in tlist_sql

**Ask opencode**:
> "My tlist_sql report times out. How to optimize?"

- Add `WHERE` filters in SQL (not PSHTML `~[if]`)
- Use CTE params inside SQL
- Avoid `LISTAGG` on large sets
- Materialized views for pre-aggregated data
- Paginate: `OFFSET ~(gpv.page) ROWS FETCH NEXT 50 ROWS ONLY` (12c+)

---

## Step 8: Test Checklist

**Ask opencode**:
> "Run through the debug checklist for my report"

- [ ] Debug enabled, captured substituted SQL
- [ ] Substituted SQL runs in SQL Developer
- [ ] Results match expected row count
- [ ] GPV params passed correctly in URL
- [ ] Date formats match (GPV string → TO_DATE)
- [ ] Student context tags valid for page type
- [ ] No PL/SQL, no binds, single statement
- [ ] Column aliases match report field names
- [ ] Query completes < 30 sec in SQL Developer

---

## Example Prompts

> "My tlist_sql attendance report returns 0 rows. Help me debug the GPV date params"
> "Extract the actual SQL from my tlist_sql report with debug=1"
> "The ~(curstudid) tag is blank. What page context do I need?"
> "My query works in SQL Developer but times out in PowerSchool. Optimize it"

---

## Quick Reference: Debug URLs

| Purpose | URL |
|---------|-----|
| Debug current report | `.../runreport.html?debug=1&frn=XXX` |
| Debug with GPV | `.../runreport.html?debug=1&gpv.yearid=33&gpv.schoolid=84` |
| View SQL only | Check page source for `<!-- SQL: SELECT ... -->` |
| Server log | `tail -f /home/powerschool/logs/tomcat-stdout.log` |