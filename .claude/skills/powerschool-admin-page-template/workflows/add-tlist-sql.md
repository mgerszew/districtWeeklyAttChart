# Workflow: Embed tlist_sql Query in Page

## Overview
Add a tlist_sql query to display database data in an Admin Portal student page.

## Prerequisites
- Existing `.html` page
- Understanding of PowerSchool schema (students, u_ tables)
- SQL knowledge (Oracle syntax)

## Step 1: Design Query

### Use CTE for Parameters
```sql
WITH params AS (
    SELECT 
        ~(curstudid) AS student_id,
        ~(curschoolid) AS school_id,
        ~(curyearid) AS year_id
    FROM dual
)
SELECT t.column1, t.column2, t.id
FROM your_table t
JOIN params p ON t.studentid = p.student_id
WHERE t.schoolid = p.school_id
ORDER BY t.column1
```

### GPV Parameters (from URL)
```sql
WITH params AS (
    SELECT 
        ~(curstudid) AS student_id,
        TO_DATE(~(gpv.startdate), 'MM/DD/YYYY') AS start_date,
        TO_DATE(~(gpv.enddate), 'MM/DD/YYYY') AS end_date
    FROM dual
)
```

## Step 2: Choose Display Pattern

### Table (Grid)
```html
<table class="grid">
    <thead>
        <tr>
            <th>Column 1</th>
            <th>Column 2</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        ~[tlist_sql:query_name]
            WITH params AS (SELECT ~(curstudid) AS student_id FROM dual)
            SELECT col1, col2, id FROM table WHERE studentid = (SELECT student_id FROM params)
        [/tlist_sql]
        <tr class="~[if.odd]odd[else]even[/if]">
            <td>~(col1)</td>
            <td>~(col2)</td>
            <td class="actions">
                <a href="/~[self.page]?frn=~(studentfrn)&ac=upd&id=~(id)">Edit</a>
            </td>
        </tr>
        ~[/tlist_sql]
    </tbody>
</table>
```

### List
```html
<ul>
    ~[tlist_sql:query_name]
        SELECT name, value FROM table WHERE studentid = ~(curstudid)
    [/tlist_sql]
    <li>~(name): ~(value)</li>
    ~[/tlist_sql]
</ul>
```

### Cards
```html
<div class="card-grid">
    ~[tlist_sql:query_name]
        SELECT title, description, date FROM table WHERE studentid = ~(curstudid)
    [/tlist_sql]
    <div class="card">
        <h3>~(title)</h3>
        <p>~(description)</p>
        <span class="date">~(date)</span>
    </div>
    ~[/tlist_sql]
</div>
```

## Step 3: Insert in Page

Place inside `<div class="box-round">` after heading, before button-row:

```html
<div class="box-round">
    <h2>Section Title</h2>
    <p>Description.</p>
    
    <!-- tlist_sql HERE -->
    
    <div class="button-row">
        <input type="hidden" name="ac" value="prim">
        ~[submitbutton]
    </div>
</div>
```

## Step 4: Add Edit/Delete Links

In tlist_sql row:
```html
<td class="actions">
    <a href="/~[self.page]?frn=~(studentfrn)&ac=upd&id=~(id)">Edit</a>
    <a href="/~[self.page]?frn=~(studentfrn)&ac=del&id=~(id)" onclick="return confirm('Delete?')">Delete</a>
</td>
```

## Step 5: Handle Empty State

```html
~[tlist_sql:query]
    SELECT ...
[/tlist_sql]
    <!-- rows -->
[else]
    <p class="no-records">No records found.</p>
[/tlist_sql]
```

## Step 6: Test

1. Deploy
2. Navigate to student page
3. Verify:
   - Data loads correctly
   - Student context maintained (FRN in URL)
   - Edit/delete links work
   - Empty state shows when no data

## Performance Tips

- **Index**: Ensure query columns indexed (studentid, schoolid)
- **Limit**: Add `AND ROWNUM <= 100` for large tables
- **Avoid SELECT ***: Explicit columns only
- **CTE params**: Compute once, reuse

## Common Tables

| Table | Key Columns | Use Case |
|-------|-------------|----------|
| `students` | id, student_number, lastfirst, grade_level | Student info |
| `attendance` | studentid, att_date, att_code, period_id | Attendance |
| `cc` | studentid, sectionid, dateenrolled, dateleft | Enrollment |
| `u_custom` | studentid, ... | Custom data |
| `contacts` | studentid, contact_name, phone | Contacts |

## Checklist

- [ ] Query uses CTE for parameters
- [ ] Student context via `~(curstudid)`
- [ ] School context via `~(curschoolid)`
- [ ] Explicit column list (no SELECT *)
- [ ] ORDER BY clause
- [ ] Edit/delete links preserve `frn=~(studentfrn)`
- [ ] Empty state handled
- [ ] Tested with multiple students