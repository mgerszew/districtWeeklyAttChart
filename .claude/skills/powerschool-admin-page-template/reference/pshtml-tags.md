# PowerSchool PSHTML Tags Reference

## Admin Portal Required Wrapper Tags (Do Not Remove)

| Tag | Purpose | Required |
|-----|---------|----------|
| `~[wc:commonscripts]` | Loads common PowerSchool JS libraries (jQuery, etc.) | **Yes** |
| `~[wc:admin_header_frame_css]` | Admin portal header frame (logo, user menu) | **Yes** |
| `~[wc:admin_navigation_frame_css]` | Left navigation menu frame | **Yes** |
| `~[wc:title_student_begin_css]` | Opens student page title block | **Yes** |
| `~[wc:title_student_end_css]` | Closes student page title block | **Yes** |
| `~[wc:admin_footer_frame_css]` | Admin portal footer frame | **Yes** |

## Form & Student Context Tags

| Tag | Purpose |
|-----|---------|
| `~[self.page]` | Current page URL (for form action) |
| `~(studentfrn)` | Current student's FRN (persists student context) |
| `~[submitbutton]` | Renders localized submit button (`[Submit]`) |
| `~[if.~(gpv.changesSaved)=true]...[/if]` | Conditional: shows "changes recorded" message |
| `~[text:psx.common.changes_recorded]` | Localized "Changes recorded" text |

## Required CSS Includes

```html
<link href="/images/css/screen.css" rel="stylesheet" media="screen">
<link href="/images/css/print.css" rel="stylesheet" media="print">
```

## Standard CSS Classes Used

| Class | Purpose |
|-------|---------|
| `box-round` | Rounded content container |
| `button-row` | Button container row |
| `feedback-confirm` | Green success message box |
| `grid` | Table grid styling |

## Standard Page Structure

```html
<!DOCTYPE html>
<html>
<head>
    <title>Page Title</title>
    ~[wc:commonscripts]
    <link href="/images/css/screen.css" rel="stylesheet" media="screen">
    <link href="/images/css/print.css" rel="stylesheet" media="print">
</head>
<body>
    ~[wc:admin_header_frame_css]
    <!-- breadcrumb start -->
        <a href="/admin/home.html" target="_top">Start Page</a> > <a href="/admin/students/home.html?selectstudent=nosearch" target="_top">Student Selection</a> > Page Title
    <!-- breadcrumb end -->
    ~[wc:admin_navigation_frame_css]
    ~[wc:title_student_begin_css]Page Title~[wc:title_student_end_css]
    <form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
    <!-- start of content area -->
    ~[if.~(gpv.changesSaved)=true]<div class="feedback-confirm">~[text:psx.common.changes_recorded]</div>[/if]
        <div class="box-round">
             <h2>Section Title</h2>
             <p>Description text.</p>
             <!-- Form fields go here -->
             <div class="button-row"><input type="hidden" name="ac" value="prim">~[submitbutton]</div>
        </div>
    </form>
    <!-- end of content area -->
    ~[wc:admin_footer_frame_css]
</body>
</html>
```

## DAT Tag Syntax Reference

### Substitution Tags (`~()`)

| Syntax | Example | Description |
|--------|---------|-------------|
| `~(fieldname)` | `~(curstudid)` | Substitute field value |
| `~(gpv.param)` | `~(gpv.studentid)` | Get Parameter Value from URL |

### Conditional Tags (`~[]`)

| Syntax | Example | Description |
|--------|---------|-------------|
| `~[if.condition]...[/if]` | `~[if.~(gpv.changesSaved)=true]...[/if]` | Conditional block |
| `~[if.~[field]=value]...[/if]` | `~[if.~(ac)=upd]...[/if]` | Field value conditional |

### Text/Localization Tags

| Syntax | Example | Description |
|--------|---------|-------------|
| `~[text:key]` | `~[text:psx.common.changes_recorded]` | Localized text |

## Common DAT Variables

| Variable | Description |
|----------|-------------|
| `~(curstudid)` | Current student ID |
| `~(studentfrn)` | Current student FRN |
| `~(curschoolid)` | Current school ID |
| `~(curyearid)` | Current year ID |
| `~(gpv.varname)` | URL parameter value |
| `~(ac)` | Form action code |
| `~(changesSaved)` | Changes saved flag |

## Conditional Block Syntax

```html
~[if.condition]
    Content if true
[/if]

~[if.condition]
    Content if true
[else]
    Content if false
[/if]
```

## Loop Tags (tlist_sql)

```html
~[tlist_sql:query_name]
    SELECT column1, column2 FROM table WHERE condition
[/tlist_sql]
```

Inside tlist_sql block:
- `~(column_name)` - Column value from current row
- `~[count]` - Row count
- `~[if.first]...[/if]` - First row
- `~[if.last]...[/if]` - Last row