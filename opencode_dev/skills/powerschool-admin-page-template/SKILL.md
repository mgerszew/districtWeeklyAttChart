---
name: powerschool-admin-page-template
description: PowerSchool Admin Portal Student Page Template skill - reference patterns, guided workflows, and templates for creating Admin Portal student pages
license: MIT
compatibility: opencode
metadata:
  audience: PowerSchool developers
  version: "1.0.0"
---

## PowerSchool Admin Portal Student Page Template Skill

This skill provides reference patterns, guided workflows, and templates for creating PowerSchool Admin Portal student pages (PageSets/plugins) using the standard PowerSchool Admin Portal student page template pattern.

### Directory Structure

```
opencode_dev/skills/powerschool-admin-page-template/
├── SKILL.md                    # This file
├── reference/                  # Reference documentation
│   ├── pshtml-tags.md          # PSHTML tags reference (admin header, navigation, title, footer, form tags)
│   ├── dat-tags.md             # DAT tag syntax reference (~(), ~[], ~[if])
│   ├── form-actions.md         # Form action codes reference (prim, upd, del, cpy)
│   └── page-structure.md       # Standard page structure (DOCTYPE, head, body, commonscripts, breadcrumb, header, nav, title, footer)
├── workflows/                  # Guided workflows
│   ├── new-student-page.md     # Create new Admin Portal student page from template
│   ├── add-form-fields.md      # Add form fields to existing page
│   ├── add-tlist-sql.md        # Embed tlist_sql query in page
│   └── register-plugin-xml.md  # Register page in plugin.xml (if needed)
├── templates/                  # Page templates
│   ├── admin-student-page-template.pshtml    # Full Admin Portal student page template
│   ├── form-field-templates.pshtml           # Common form field snippets
│   ├── tlist-sql-template.pshtml             # tlist_sql embed template
│   └── plugin-xml-page-entry.xml             # plugin.xml page/permission entry template
└── scripts/
    └── validate-pshtml.sh        # PSHTML validation script (if applicable)
```

### Usage

Load this skill with:
```
skill powerschool-admin-page-template
```

Then use the `skill` tool to access specific workflows, templates, or reference docs as needed for your task.

### Key PowerSchool Admin Portal Conventions

- **PSHTML files use `.pshtml` extension** (not `.html`)
- **jQuery**: Use `$j` (not `$`/`jQuery`); prefer `jqReady()` wrapper
- **DAT tags**: `~()` substitution, `~[]` conditionals, `~[if]...[/if]` blocks
- **Admin Portal tags**: `~[wc:commonscripts]`, `~[wc:admin_header_frame_css]`, `~[wc:admin_navigation_frame_css]`, `~[wc:title_student_begin_css]...~[wc:title_student_end_css]`, `~[wc:admin_footer_frame_css]`
- **Form tags**: `~[self.page]`, `~(studentfrn)`, `~[submitbutton]`, `~[if...]`
- **jQuery**: Use `$j` (not `$`/`jQuery`); prefer `jqReady()` wrapper
- **AngularJS**: Follow existing `psFormAdmin`, `psTableGrid` patterns
- **JS syntax**: ES5 only (no arrow functions, `const`/`let`, template literals) unless build step exists
- **Form actions**: `prim` (insert), `upd` (update), `del` (delete), `cpy` (copy)
- **Form action URL**: `action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST"`
- **PSHTML style**: Match existing indentation (2 spaces), inline PS tags
- **Form action codes**: `prim` (insert), `upd` (update), `del` (delete), `cpy` (copy)
- **PSHTML tags that MUST remain unchanged**: `~[wc:commonscripts]`, `~[wc:admin_header_frame_css]`, `~[wc:admin_navigation_frame_css]`, `~[wc:title_student_begin_css]...~[wc:title_student_end_css]`, `~[wc:admin_footer_frame_css]`, `~[self.page]`, `~(studentfrn)`, `~[submitbutton]`, `~[if.~(gpv.changesSaved)=true]...[/if]`, `~[text:psx.common.changes_recorded]`
- **plugin.xml**: Read-only structure; only edit values (name, path, description, default) — do not add new `<page>`/`<permission>` blocks unless explicitly asked

### Key PowerSchool Tags Reference

| Tag | Purpose |
|-----|---------|
| `~[wc:commonscripts]` | Loads common scripts (jQuery, etc.) |
| `~[wc:admin_header_frame_css]` | Admin header frame CSS |
| `~[wc:admin_navigation_frame_css]` | Admin navigation frame CSS |
| `~[wc:title_student_begin_css]Title~[wc:title_student_end_css]` | Student page title bar |
| `~[wc:admin_footer_frame_css]` | Admin footer frame CSS |
| `~[self.page]` | Current page URL |
| `~(studentfrn)` | Student FRN (internal ID) |
| `~[submitbutton]` | Submit button |
| `~[if.condition]...[/if]` | Conditional block |
| `~(gpv.varname)` | Get Parameter Value (URL param) |
| `~(curstudid)` | Current student ID |
| `~(curschoolid)` | Current school ID |
| `~(curyearid)` | Current year ID |

### Form Action Codes

| Value | Action | Typical Use |
|-------|--------|-------------|
| `prim` | Primary/Insert | Create new record |
| `upd` | Update | Edit existing record |
| `del` | Delete | Delete record |
| `cpy` | Copy | Duplicate record |

### Template Placeholders (Replace in Templates)

- `TemplateName:Admin Student Page - [Page Name]` - Template name comment
- `<title>[Page Title]</title>` - Page title
- `Breadcrumb` - Breadcrumb navigation
- `Page Title` - Page title in title bar
- `Section Heading` - `<h2>` section heading
- `Page content description` - Descriptive paragraph
- `Form fields` - Form input fields
- `value="prim"` - Form action code (`prim`, `upd`, `del`, `cpy`)
- `Form fields go here` - Place form fields between `<div class="box-round">` and `<div class="button-row">`

### Related Resources

- `@docs/powerschool/PowerSchool_PSHTML_Tips.md` - PSHTML syntax reference
- `@docs/powerschool/VS_Code_PS_completions.json` - VS Code snippets for PowerSchool tags
- `@docs/powerschool/PowerSchool_Oracle_Query_Reference.md` - Oracle SQL reference for tlist_sql queries
- `@docs/powerschool/POWERSCHOOL_ANGULARJS_REFERENCE.md` - AngularJS plugin patterns