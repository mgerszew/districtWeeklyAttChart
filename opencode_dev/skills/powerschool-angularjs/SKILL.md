---
name: powerschool-angularjs
description: PowerSchool AngularJS Plugin Development skill - reference patterns, guided workflows, and templates for building Admin Portal plugins using AngularJS 1.4.7 with AMD/RequireJS
license: MIT
compatibility: opencode
metadata:
  audience: PowerSchool developers
  version: "1.0.0"
---

# PowerSchool AngularJS Plugin Development Skill

This skill provides reference patterns, guided workflows, and templates for building PowerSchool Admin Portal plugins using AngularJS 1.4.7 with AMD/RequireJS module system.

## Directory Structure

```
opencode_dev/skills/powerschool-angularjs/
├── SKILL.md                           # This file
├── reference/                         # Reference documentation
│   ├── angularjs-quirks.md           # Auto-bootstrap, no ng-app, AMD/RequireJS
│   ├── file-structure.md             # Production vs dev paths, path rules
│   ├── home-page-template.md         # PS HTML template syntax, page registration
│   ├── angular-patterns.md           # Controllers, services, directives, templates
│   ├── data-patterns.md              # $http POST, date handling, filter maps, cache busting
│   └── quick-reference.md            # Checklist, pitfalls, path reference table
├── workflows/                         # Guided workflows (dev/sandbox focus)
│   ├── new-plugin-inline.md          # Quick prototype - single inline home.html
│   ├── new-plugin-hybrid.md          # Inline logic + external templates via ng-include
│   └── add-angular-component.md      # Add controller/service/directive to existing plugin
└── templates/                         # Code templates (Inline + Hybrid only)
    ├── hybrid/
    │   ├── home.html                 # Hybrid home.html with inline logic + ng-include
    │   └── navigation.html           # External template example
    └── inline/
        └── home.html                 # Fully inline prototype (all in one file)
```

## Usage

Load this skill with:
```
skill powerschool-angularjs
```

Then use the `skill` tool to access specific workflows, templates, or reference docs as needed.

## Key PowerSchool AngularJS Conventions

### Critical Rules (Never Violate)
- **No `ng-app`** — PowerSchool auto-bootstraps via `data-module-name` + `data-require-path`
- **No ES6** — Use ES5 only (AngularJS 1.4.7): no arrow functions, `const`/`let`, template literals
- **AMD/RequireJS** — Production uses `define`/`require`; dev can use inline `<script>`
- **$http = POST + form-urlencoded** — PowerSchool data endpoints expect POST
- **jQuery = `$j`** — Never use `$` or `jQuery` directly
- **ng-cloak required** — Prevents flash of uncompiled Angular on bootstrap element

### Key DAT Tags
- `~(curstudid)` — Current student ID
- `~(curschoolid)` — Current school ID
- `~(curyearid)` — Current year ID
- `~(gpv.varname)` — Get Parameter Value (URL params)
- `~[wc:commonscripts]` — PowerSchool common scripts (jQuery, Angular, etc.)
- `~[wc:admin_header_frame_css]` — Admin header styles
- `~[wc:admin_navigation_frame_css]` — Admin nav styles
- `~[wc:admin_footer_frame_css]` — Admin footer styles
- `~[time]` — Cache-busting timestamp

### File Path Conventions

| Asset Type | Production Path | Development Path |
|------------|-----------------|------------------|
| JavaScript (AMD) | `/scripts/components/{plugin}/app/` | `/admin/{plugin}/app/` |
| HTML Templates (ng-include) | `/scripts/components/{plugin}/templates/` | `/admin/{plugin}/templates/` |
| Data Endpoints (JSON) | `/admin/{plugin}/data/` | Same |
| Home Page | `/admin/{plugin}/home.html` | Same |

## Development Patterns (This Skill Covers)

| Pattern | Use Case | Files |
|---------|----------|-------|
| **Inline (Pattern A)** | Quick prototype, learning, <200 lines JS | Single `home.html` with inline `<script>` + `ng-template` |
| **Hybrid (Pattern B)** | Multi-template page, team dev, <1000 lines JS | `home.html` with inline logic + external templates in `/admin/{plugin}/templates/` |

> **Note:** Production plugins should use the full AMD structure (Section 2 of reference). This skill focuses on Inline + Hybrid for rapid development.

## Related Resources

- `@docs/powerschool/POWERSCHOOL_ANGULARJS_REFERENCE.md` — Full source reference
- `@docs/powerschool/PowerSchool_PSHTML_Tips.md` — PSHTML/DAT tag syntax
- `@docs/powerschool/VS_Code_PS_completions.json` — VS Code snippets
- `powerschool-admin-page-template` — Admin Portal student page templates
- `powerschool-oracle-sql` — Oracle SQL query patterns