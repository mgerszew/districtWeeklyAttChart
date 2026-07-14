# PowerSchool Admin Portal Student Page Structure

## Overview
Standard structure for all Admin Portal student-facing pages. Based on PowerSchool's built-in page template with required wrapper tags.

## Complete Page Template

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
        <a href="/admin/home.html" target="_top">Start Page</a> > 
        <a href="/admin/students/home.html?selectstudent=nosearch" target="_top">Student Selection</a> > 
        Page Title
    <!-- breadcrumb end -->
    ~[wc:admin_navigation_frame_css]
    ~[wc:title_student_begin_css]Page Title~[wc:title_student_end_css]
    <form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
    <!-- start of content area -->
    ~[if.~(gpv.changesSaved)=true]
        <div class="feedback-confirm">~[text:psx.common.changes_recorded]</div>
    [/if]
        <div class="box-round">
            <h2>Section Title</h2>
            <p>Description text.</p>
            <!-- Form fields go here -->
            <div class="button-row">
                <input type="hidden" name="ac" value="prim">
                ~[submitbutton]
            </div>
        </div>
    </form>
    <!-- end of content area -->
    ~[wc:admin_footer_frame_css]
</body>
</html>
```

## Required Wrapper Tags (DO NOT REMOVE)

| Tag | Purpose | Location |
|-----|---------|----------|
| `~[wc:commonscripts]` | Loads common PS JS libraries (jQuery, etc.) | `<head>` |
| `~[wc:admin_header_frame_css]` | Admin header frame (logo, user menu) | After `<body>` |
| `~[wc:admin_navigation_frame_css]` | Left navigation menu | After header |
| `~[wc:title_student_begin_css]` | Opens student page title block | Before form |
| `~[wc:title_student_end_css]` | Closes student page title block | After title text |
| `~[wc:admin_footer_frame_css]` | Admin footer frame | Before `</body>` |

## Form & Student Context Tags

| Tag | Purpose |
|-----|---------|
| `~[self.page]` | Current page URL (form action) |
| `~(studentfrn)` | Current student's FRN (persists context) |
| `~[submitbutton]` | Renders localized submit button |
| `~[if.~(gpv.changesSaved)=true]...[/if]` | Shows "changes recorded" message |
| `~[text:psx.common.changes_recorded]` | Localized success text |

## Required CSS Includes

```html
<link href="/images/css/screen.css" rel="stylesheet" media="screen">
<link href="/images/css/print.css" rel="stylesheet" media="print">
```

## Standard CSS Classes

| Class | Usage |
|-------|-------|
| `box-round` | Main content container (rounded corners) |
| `button-row` | Button container (right-aligned) |
| `feedback-confirm` | Green success message box |
| `feedback-error` | Red error message box |
| `grid` | Data table styling |
| `box-round` | Section container |

## Breadcrumb Pattern

```html
<!-- breadcrumb start -->
    <a href="/admin/home.html" target="_top">Start Page</a> > 
    <a href="/admin/students/home.html?selectstudent=nosearch" target="_top">Student Selection</a> > 
    Page Title
<!-- breadcrumb end -->
```

**Rules:**
- Always start with "Start Page" → "Student Selection"
- Use `target="_top"` for top-frame navigation
- Final item is plain text (not a link)
- Separate with ` > ` (space-greater than-space)

## Title Block Pattern

```html
~[wc:title_student_begin_css]Page Title~[wc:title_student_end_css]
```

- Title text goes between the two tags
- Do not add extra HTML inside title block
- Matches breadcrumb final item

## Content Area Pattern

```html
<div class="box-round">
    <h2>Section Heading</h2>
    <p>Optional description paragraph.</p>
    
    <!-- Form fields, tables, etc. -->
    
    <div class="button-row">
        <input type="hidden" name="ac" value="prim">
        ~[submitbutton]
    </div>
</div>
```

## Form Patterns

### Create New (prim)
```html
<form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
    <input type="hidden" name="ac" value="prim">
    <div class="box-round">
        <h2>Add New Record</h2>
        <!-- fields -->
        <div class="button-row">~[submitbutton]</div>
    </div>
</form>
```

### Edit Existing (upd)
```html
<form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
    <input type="hidden" name="ac" value="upd">
    <input type="hidden" name="id" value="~(id)">
    <div class="box-round">
        <h2>Edit Record</h2>
        <!-- pre-populated fields -->
        <div class="button-row">~[submitbutton]</div>
    </div>
</form>
```

### Conditional Form (handles both)
```html
<form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
    <input type="hidden" name="ac" value="~[if.~(ac)]~(ac)[else]prim[/if]">
    ~[if.~(ac)=upd]
        <input type="hidden" name="id" value="~(id)">
    [/if]
    <div class="box-round">
        <h2>~[if.~(ac)=upd]Edit[else]Add[/if] Record</h2>
        <!-- fields -->
        <div class="button-row">~[submitbutton]</div>
    </div>
</form>
```

## Success Message Pattern

```html
~[if.~(gpv.changesSaved)=true]
    <div class="feedback-confirm">~[text:psx.common.changes_recorded]</div>
[/if]
```

Place immediately after form opens, before content area.

## JavaScript Inclusion Pattern

```html
~[wc:commonscripts]
<script>
// Page-specific JS here
$j(function() {
    // jqReady equivalent
});
</script>
```

**Note:** Use `$j` not `$` or `jQuery`. PowerSchool loads jQuery as `$j`.

## Page File Naming

- Extension: `.html` (not `.pshtml`)
- Location: Plugin directory under `/admin/` or custom page set
- Naming: lowercase, descriptive (e.g., `emergency_contacts.html`)

## Plugin Registration (plugin.xml)

```xml
<page>
    <name>emergency_contacts</name>
    <path>/admin/students/emergency_contacts.html</path>
    <description>Emergency Contacts</description>
    <permission>emergency_contacts</permission>
</page>
<permission>
    <name>emergency_contacts</name>
    <description>View/Edit Emergency Contacts</description>
    <default>false</default>
</permission>
```

## Checklist for New Pages

- [ ] `.html` extension
- [ ] DOCTYPE html
- [ ] `~[wc:commonscripts]` in head
- [ ] CSS includes (screen.css, print.css)
- [ ] `~[wc:admin_header_frame_css]` after body
- [ ] Breadcrumb with Start Page → Student Selection → Page Title
- [ ] `~[wc:admin_navigation_frame_css]`
- [ ] Title block with `~[wc:title_student_begin_css]Title~[wc:title_student_end_css]`
- [ ] Form with `action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST"`
- [ ] Success message conditional
- [ ] `box-round` content div
- [ ] `h2` section heading
- [ ] Hidden `ac` field
- [ ] `~[submitbutton]` in `button-row`
- [ ] `~[wc:admin_footer_frame_css]` before body close
- [ ] Registered in plugin.xml (if new page)