# PowerSchool DAT Tag Syntax Reference

## Overview
DAT (Data Access Tag) syntax is PowerSchool's templating language for PSHTML pages. Tags are evaluated server-side before the page is sent to the browser.

## Tag Categories

### 1. Substitution Tags `~()`

Evaluates and outputs a value.

| Syntax | Example | Description |
|--------|---------|-------------|
| `~(fieldname)` | `~(curstudid)` | Current field value from context |
| `~(gpv.param)` | `~(gpv.studentid)` | Get Parameter Value - URL parameter |
| `~[fieldname]` | `~[student_name]` | Context field (alternative syntax) |

**Common GPV parameters:**
- `~(gpv.studentid)` - Student ID from URL
- `~(gpv.frn)` - FRN from URL
- `~(gpv.ac)` - Action code from URL
- `~(gpv.changesSaved)` - Changes saved flag

### 2. Conditional Tags `~[if]...[/if]`

Controls content display based on conditions.

```html
~[if.condition]
    Content when true
[/if]

~[if.condition]
    Content when true
[else]
    Content when false
[/if]
```

**Condition Syntax:**
- `~[if.~(gpv.var)=value]` - Equals
- `~[if.~(gpv.var)!=value]` - Not equals
- `~[if.~(gpv.var)]` - Truthy (exists and non-empty)
- `~[if!~(gpv.var)]` - Falsy (empty or missing)
- `~[if.~[field]=value]` - Context field equals
- `~[if.condition1][if.condition2]...` - AND (all must be true)

**Examples:**
```html
~[if.~(gpv.changesSaved)=true]
    <div class="feedback-confirm">Changes saved!</div>
[/if]

~[if.~(ac)=upd]
    <input type="hidden" name="id" value="~(id)">
[/if]

~[if.~(gpv.mode)=edit][else]
    <h2>New Record</h2>
[/if]
```

### 3. Loop Tags `~[tlist_sql]...[/tlist_sql]`

Iterates over SQL query results.

```html
~[tlist_sql:query_name]
    SELECT column1, column2 FROM table WHERE condition
[/tlist_sql]
```

**Inside loop:**
- `~(column_name)` - Current row column value
- `~[count]` - Current row number (1-indexed)
- `~[total]` - Total rows
- `~[if.first]...[/if]` - First row
- `~[if.last]...[/if]` - Last row
- `~[if.odd]...[/if]` - Odd row
- `~[if.even]...[/if]` - Even row

**Example:**
```html
<table class="grid">
    <thead><tr><th>Name</th><th>Grade</th></tr></thead>
    <tbody>
    ~[tlist_sql:students]
        SELECT lastfirst, grade_level FROM students WHERE enroll_status = 0
    [/tlist_sql]
        <tr class="~[if.odd]odd[else]even[/if]">
            <td>~(lastfirst)</td>
            <td>~(grade_level)</td>
        </tr>
    ~[/tlist_sql]
    </tbody>
</table>
```

### 4. Text/Localization Tags `~[text:key]`

Outputs localized text from PowerSchool's message bundle.

```html
~[text:psx.common.changes_recorded]
~[text:psx.common.submit]
~[text:psx.common.cancel]
```

### 5. Include Tags `~[include:path]`

Includes another PSHTML file.

```html
~[include:/path/to/include.pshtml]
```

### 6. Script Tags `~[script]...[/script]`

Server-side JavaScript (Rhino engine).

```html
~[script]
    var x = ~(gpv.value);
    var result = x * 2;
[/script]
~[result]
```

## Tag Nesting Rules

- Tags can be nested: `~[if.~(gpv.show)=true]~[tlist_sql:q]...[/tlist_sql][/if]`
- Each `[/if]` matches nearest `[if...]`
- `tlist_sql` blocks cannot be nested inside each other
- Always close conditionals and loops

## Escaping Tags

To output literal `~(` or `~[`:
- `~[(]text[)]` - Outputs `~(text)`
- `~[[]]text[[]]` - Outputs `~[text]`

## Common Patterns

### Form Action Detection
```html
~[if.~(ac)=prim]
    <h2>Create New</h2>
[else]
~[if.~(ac)=upd]
    <h2>Edit Record</h2>
[/if][/if]
```

### Student Context Preservation
```html
<form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
```

### Success Message
```html
~[if.~(gpv.changesSaved)=true]
    <div class="feedback-confirm">~[text:psx.common.changes_recorded]</div>
[/if]
```

### Conditional Form Fields
```html
~[if.~(ac)=upd]
    <input type="hidden" name="id" value="~(id)">
[/if]
<input type="hidden" name="ac" value="~(ac)">
```