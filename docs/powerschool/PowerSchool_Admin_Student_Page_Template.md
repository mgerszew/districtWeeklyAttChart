# PowerSchool Admin Student Page Template

**Template Name:** Admin Student Page  
**Template Type:** PowerSchool Admin Portal Student Page  
**Category:** Admin Portal / Student Pages  
**Required PowerSchool Tags:** `~[wc:commonscripts]`, `~[wc:admin_header_frame_css]`, `~[wc:admin_navigation_frame_css]`, `~[wc:title_student_begin_css]`, `~[wc:title_student_end_css]`, `~[wc:admin_footer_frame_css]`, `~[self.page]`, `~(studentfrn)`, `~[submitbutton]`, `~[if...]`, `~[text:...]`

---

## Template Purpose

This is the standard **PowerSchool Admin Portal Student Page** template. Use this as the base template when creating new student-facing pages in the PowerSchool Admin Portal. The template includes:

- Required PowerSchool admin portal header/navigation/footer includes
- Student context (breadcrumb shows student selection path)
- Standard form wrapper with student FRN handling
- Standard content area with box-round styling
- Built-in change confirmation message handling
- Standard submit button handling via `~[submitbutton]`

---

## Complete Template (Annotated)

```html
<!--
TemplateName:Admin Student Page
-->
<!DOCTYPE html>
<html>
<head>
	<title>Enter Page Title Here</title>
<!-- required scripts -->
	~[wc:commonscripts] 
<!-- Required style sheets: screen.css, and print.css -->
	<link href="/images/css/screen.css" rel="stylesheet" media="screen">
	<link href="/images/css/print.css" rel="stylesheet" media="print">
</head> 
<body> 
	~[wc:admin_header_frame_css]
	<!-- breadcrumb start -->
		<a href="/admin/home.html" target="_top">Start Page</a> > <a href="/admin/students/home.html?selectstudent=nosearch" target="_top">Student Selection</a> > Enter Page Title Here
	<!-- breadcrumb end -->
~[wc:admin_navigation_frame_css]
<!-- start of main menu and content -->
~[wc:title_student_begin_css]Enter Page Title Here~[wc:title_student_end_css]
<form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
<!-- start of content area -->
~[if.~(gpv.changesSaved)=true]<div class="feedback-confirm">~[text:psx.common.changes_recorded]</div>[/if]
	<div class="box-round">
		 <h2>Section Title Text Goes Here</h2>
		 <p>
		 	Your paragraph text goes here.
		 </p>
        <div class="button-row"><input type="hidden" name="ac" value="prim">~[submitbutton]</div>
	</div>
</form>
<!-- end of content area -->
	~[wc:admin_footer_frame_css]
</body> 
</html>
```

---

## Placeholder Reference

| Placeholder | Description | Replace With |
|-------------|-------------|--------------|
| `Enter Page Title Here` (in `<title>`) | Browser tab title | Page-specific title |
| `Enter Page Title Here` (in breadcrumb) | Breadcrumb final item | Page-specific title |
| `Enter Page Title Here` (in title block) | Page header title | Page-specific title |
| `Section Title Text Goes Here` | Section heading (`<h2>`) | Section-specific title |
| `Your paragraph text goes here.` | Body paragraph content | Page-specific content |
| `value="prim"` | Action code for form submission | Action code for form processing (typically `prim`, `upd`, `del`, etc.) |

---

## PowerSchool Tag Reference

### Required Wrapper Tags (Do Not Remove)

| Tag | Purpose | Required |
|-----|---------|----------|
| `~[wc:commonscripts]` | Loads common PowerSchool JS libraries | **Yes** |
| `~[wc:admin_header_frame_css]` | Admin portal header frame (logo, user menu) | **Yes** |
| `~[wc:admin_navigation_frame_css]` | Left navigation menu frame | **Yes** |
| `~[wc:title_student_begin_css]` | Opens student page title block | **Yes** |
| `~[wc:title_student_end_css]` | Closes student page title block | **Yes** |
| `~[wc:admin_footer_frame_css]` | Admin portal footer frame | **Yes** |

### Form & Student Context Tags

| Tag | Purpose |
|-----|---------|
| `~[self.page]` | Current page URL (for form action) |
| `~(studentfrn)` | Current student's FRN (persists student context) |
| `~[submitbutton]` | Renders localized submit button (`[Submit]`) |
| `~[if.~(gpv.changesSaved)=true]...[/if]` | Conditional: shows "changes recorded" message |
| `~[text:psx.common.changes_recorded]` | Localized "Changes recorded" text |

### Required CSS Includes

```html
<link href="/images/css/screen.css" rel="stylesheet" media="screen">
<link href="/images/css/print.css" rel="stylesheet" media="print">
```

### Standard CSS Classes Used

| Class | Purpose |
|-------|---------|
| `box-round` | Rounded content container |
| `button-row` | Button container row |
| `feedback-confirm` | Green success message box |

---

## Usage with OpenCode

### Reference This Template in Prompts

```
@Resource Generation/PowerSchool_Admin_Student_Page_Template.md
Create a new student page for [feature] using the Admin Student Page template.
```

### Template Customization Checklist

When using this template with OpenCode, replace:

- [ ] `<title>Enter Page Title Here</title>` → Page title
- [ ] Breadcrumb: `Enter Page Title Here` → Page title
- [ ] `~[wc:title_student_begin_css]Enter Page Title Here~[wc:title_student_end_css]` → Page title
- [ ] `<h2>Section Title Text Goes Here</h2>` → Section heading
- [ ] `<p>Your paragraph text goes here.</p>` → Page content
- [ ] `value="prim"` → Appropriate action code (`prim`, `upd`, `del`, etc.)
- [ ] Add form fields between `<div class="box-round">` and `<div class="button-row">`
- [ ] Remove `<form>...</form>` if page doesn't submit data

### PowerSchool Tags - Do Not Modify

These tags **must remain unchanged** for proper Admin Portal integration:

```
~[wc:commonscripts]
~[wc:admin_header_frame_css]
~[wc:admin_navigation_frame_css]
~[wc:title_student_begin_css]...~[wc:title_student_end_css]
~[wc:admin_footer_frame_css]
~[self.page]
~(studentfrn)
~[submitbutton]
~[if.~(gpv.changesSaved)=true]...[/if]
~[text:psx.common.changes_recorded]
```

---

## Form Action Codes Reference

| Value | Action | Typical Use |
|-------|--------|-------------|
| `prim` | Primary/Insert | Create new record |
| `upd` | Update | Edit existing record |
| `del` | Delete | Delete record |
| `cpy` | Copy | Duplicate record |

---

## Example: Customized Student Page

```html
<!--
TemplateName:Admin Student Page - Emergency Contact
-->
<!DOCTYPE html>
<html>
<head>
	<title>Emergency Contacts</title>
	~[wc:commonscripts] 
	<link href="/images/css/screen.css" rel="stylesheet" media="screen">
	<link href="/images/css/print.css" rel="stylesheet" media="print">
</head> 
<body> 
	~[wc:admin_header_frame_css]
	<!-- breadcrumb start -->
		<a href="/admin/home.html" target="_top">Start Page</a> > <a href="/admin/students/home.html?selectstudent=nosearch" target="_top">Student Selection</a> > Emergency Contacts
	<!-- breadcrumb end -->
~[wc:admin_navigation_frame_css]
~[wc:title_student_begin_css]Emergency Contacts~[wc:title_student_end_css]
<form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
<!-- start of content area -->
~[if.~(gpv.changesSaved)=true]<div class="feedback-confirm">~[text:psx.common.changes_recorded]</div>[/if]
	<div class="box-round">
		 <h2>Emergency Contacts</h2>
		 <p>Manage emergency contact information for this student.</p>
        
        <!-- Form fields go here -->
        <table class="grid">
            <tr><th>Name</th><th>Relationship</th><th>Phone</th></tr>
            <tr><td><input name="contact_name" /></td><td><input name="relationship" /></td><td><input name="phone" /></td></tr>
        </table>
        
        <div class="button-row"><input type="hidden" name="ac" value="upd">~[submitbutton]</div>
	</div>
</form>
<!-- end of content area -->
	~[wc:admin_footer_frame_css]
</body> 
</html>
```

---

## Related Resources

- `@Resource Generation/PowerSchool_PSHTML_Tips.md` - PSHTML syntax reference
- `@Resource Generation/VS Code PS completions.json` - VS Code snippets for PowerSchool tags

---

*Template Source: PowerSchool Admin Portal Standard Student Page Template*  
*Location: `Resource Generation/PowerSchool_Admin_Student_Page_Template.md`*