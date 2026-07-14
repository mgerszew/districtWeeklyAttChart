# Plan: Create powerschool-admin-student-page Skill

## Objective
Create a new opencode skill at `.opencode/skills/powerschool-admin-student-page` based on the PowerSchool Admin Student Page template and using the powerschool-oracle-sql skill as a layout reference.

## Reference Files
- Template: `docs/powerschool/PowerSchool_Admin_Student_Page_Template.md`
- Layout reference: `.claude/skills/powerschool-oracle-sql/` (structure only)

## Skill Structure

```
.opencode/skills/powerschool-admin-student-page/
├── SKILL.md                          # Main skill manifest
├── templates/
│   ├── admin-student-page-template.pshtml   # Full template from reference doc
│   ├── form-field-templates.pshtml          # Common form field snippets
│   ├── tlist-sql-template.pshtml            # tlist_sql embed template
│   └── plugin-xml-page-entry.xml            # plugin.xml page/permission entry template
├── workflows/
│   ├── new-student-page.md         # Create new Admin Portal student page
│   ├── add-form-fields.md          # Add form fields to existing page
│   ├── add-tlist-sql.md            # Embed tlist_sql query in page
│   └── register-plugin-xml.md      # Register page in plugin.xml (if needed)
└── reference/
    └── powerschool-tags-reference.md    # Key PowerSchool tags reference
```

## SKILL.md Content

```markdown
# PowerSchool Admin Student Page Skill

**Skill Name:** powerschool-admin-student-page  
**Category:** PowerSchool Customization  
**Version:** 1.0.0

## Description
Skill for creating and customizing PowerSchool Admin Portal Student Pages using the standard Admin Student Page template. Provides templates, workflows, and reference for PSHTML tags, form patterns, and plugin.xml registration.

## When to Use
- Creating new Admin Portal student pages
- Adding form fields to existing student pages
- Embedding tlist_sql queries in student pages
- Registering new pages in plugin.xml

## Templates
- `templates/admin-student-page-template.pshtml` - Full page template from reference doc
- `templates/form-field-templates.pshtml` - Common form field snippets (text, select, checkbox, date, hidden)
- `templates/tlist-sql-template.pshtml` - tlist_sql embed pattern
- `templates/plugin-xml-page-entry.xml` - plugin.xml page/permission entry template

## Workflows
- `workflows/new-student-page.md` - Create new student page from template
- `workflows/add-form-fields.md` - Add form fields to existing page
- `workflows/add-tlist-sql.md` - Embed tlist_sql query
- `workflows/register-plugin-xml.md` - Register page in plugin.xml

## Reference
- `reference/powerschool-tags-reference.md` - Key PowerSchool DAT tags reference

## Key Conventions
- PSHTML files use `.pshtml` extension
- jQuery: `$j` (not `$`/`jQuery`); prefer `jqReady()`
- DAT tags: `~()`, `~[]`, `~[if]...[/if]`
- Admin tags: `~[wc:commonscripts]`, `~[wc:admin_header_frame_css]`, `~[wc:admin_navigation_frame_css]`, `~[wc:title_student_begin_css]...~[wc:title_student_end_css]`, `~[wc:admin_footer_frame_css]`
- Form: `~[self.page]`, `~(studentfrn)`, `~[submitbutton]`, `~[if.~(gpv.changesSaved)=true]`
- Form actions: `prim` (insert), `upd` (update), `del` (delete), `cpy` (copy)
- Form action URL: `/~[self.page]?frn=~(studentfrn)&changesSaved=true` method POST
- JS: ES5 only (no arrow functions, const/let, template literals)
- plugin.xml: read-only structure; edit values only, don't add new elements unless asked
```

## Template Content

### admin-student-page-template.pshtml
Use the full annotated template from `PowerSchool_Admin_Student_Page_Template.md` (lines 25-62).

### form-field-templates.pshtml
Include snippets for: text input, select dropdown, checkbox, radio, hidden, date picker, textarea, readonly display.

### tlist-sql-template.pshtml
Standard tlist_sql embed pattern with CTE params.

### plugin-xml-page-entry.xml
Template matching plugin.xml structure from project conventions.

## Workflow Content
Each workflow should be a step-by-step guide referencing templates and reference docs.

## Validation
- After creating skill, verify structure matches powerschool-oracle-sql layout
- Test skill loads with `skill powerschool-admin-student-page`