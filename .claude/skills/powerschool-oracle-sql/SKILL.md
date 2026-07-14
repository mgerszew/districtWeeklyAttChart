---
name: powerschool-oracle-sql
description: PowerSchool Oracle SQL development skill - reference patterns, guided workflows, and templates for Attendance, Contacts, Enrollment, and SBG queries
license: MIT
compatibility: opencode
metadata:
  audience: PowerSchool developers
  version: "1.0.0"
---

## PowerSchool Oracle SQL Skill

This skill provides reference patterns, guided workflows, and SQL templates for developing Oracle queries against the PowerSchool SIS schema. All content is organized in the skill directory for on-demand loading.

### Directory Structure

```
.claude/skills/powerschool-oracle-sql/
├── SKILL.md                 # This file
├── reference/               # Reference documentation
│   ├── attendance.md        # Attendance query patterns
│   ├── contacts.md          # Contacts query patterns
│   ├── enrollment.md        # Enrollment query patterns
│   ├── sbg.md               # Standards-Based Grading patterns
│   ├── common-patterns.md   # Common SQL patterns (CTEs, GPV, tlist_sql)
│   └── tables-schema.md     # PowerSchool table schema reference
├── workflows/               # Guided workflows
│   ├── new-query.md         # Create new queries from templates
│   ├── debug-tlist.md       # Debug tlist_sql queries
│   ├── convert-to-cte.md    # Convert legacy queries to CTE style
│   ├── optimize-query.md    # Optimize query performance
│   └── validate-query.md    # Validate against schema
├── templates/               # SQL templates
│   ├── attendance-template.sql
│   ├── contacts-template.sql
│   ├── enrollment-template.sql
│   ├── sbg-assessment-load.sql
│   ├── sbg-gradebook-config.sql
│   ├── sbg-proficiency-grade.sql
│   ├── sbg-reportcard-psm.sql
│   ├── sbg-standards-assignments.sql
│   ├── sbg-subject-averages.sql
│   └── sbg-vpr-crp.sql
└── scripts/
    └── validate-sql.sh      # SQL validation script
```

### Usage

Load this skill with:
```
skill powerschool-oracle-sql
```

Then use the `skill` tool to access specific workflows, templates, or reference docs as needed for your task.

### Key PowerSchool Conventions

- **No bind variables** - Use GPV substitution `~(gpv.varname)` or inline tags `~(curstudid)`
- **CTE-based parameterization** - Use `params` / `daynumByYear` style CTEs
- **Explicit column lists** - Avoid `SELECT *` on production schemas
- **ANSI JOIN syntax** - Prefer `JOIN ... ON` over comma joins
- **Schema qualification** - Qualify tables where the codebase does so
