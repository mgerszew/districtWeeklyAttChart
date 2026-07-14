# Project Instructions — PowerSchool Customization & Oracle SQL

These instructions govern how the assistant (opencode) should behave in this
repository. They apply to all sessions unless a more specific instruction
file overrides them for a subdirectory.

## 1. Project Context

- This project involves customizing **PowerSchool SIS** (PageSets, plugins,
  custom pages, stored procedures) and writing/maintaining **Oracle SQL**
  against the PowerSchool schema.
- Assume production PowerSchool data may be sensitive (student PII, FERPA-
  covered records). Treat all data as confidential by default.
- **PowerSchool version: 25+**
- **Frontend Libraries:**
  | Library | Version | Notes |
  |---|---|---|
  | jQuery | 3.6.1 | Global `$j` (not `$`/`jQuery`) |
  | AngularJS | 1.4.7 | Available as `angular` |
  | FusionCharts | 3.19.0 | Via RequireJS: `require('fusioncharts/fusioncharts')` |
- **Key DAT tags:** `~(curstudid)`, `~(curyearid)`, `~(curschoolid)`, `tlist_sql`
- Fill in below as they become known to the assistant: district/customer name, sandbox vs. production connection details, relevant schema owners (e.g. custom tables prefixed `u_`).

## 2. Autonomy & Command Execution — ASK FIRST

The assistant must **ask for explicit confirmation before**, and should
default to *not* running, any of the following:

- Executing **any** SQL against a database connection (SELECT included),
  unless the person has already confirmed it's a sandbox/dev instance for
  this session.
- Any SQL that is `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, `DROP`,
  `ALTER`, or any DDL/DML — always confirm target environment and show the
  statement before running it, even in sandbox.
- Installing packages, dependencies, or PowerSchool plugins.
- Running build/deploy scripts, PageSet imports, or plugin installs.
- `git push`, `git commit --amend`, force-pushes, branch deletion, or any
  history-rewriting operation.
- Any command that writes files outside the current working directory or
  touches PowerSchool's live `/home/powerschool` install paths.

When in doubt, the assistant should describe what it intends to run and
wait for a go-ahead rather than executing it.

## 3. Coding Style & Conventions

### PowerSchool customization
- Follow existing PageSet/plugin folder conventions already present in the
  repo (don't invent new structures without asking).
- Custom fields/tables use the `u_` prefix per PowerSchool convention —
  keep this consistent in any new objects.
- PSHTML / page code: match the indentation and templating style already
  used in neighboring files rather than introducing a new pattern.
- `plugin.xml`: this file's structure (pages, permissions, tables, publisher
  block) is a fixed template for this project — treat it as **read-only
  structure, editable values only**.
  - Do **not** add new `<page>`, `<permission>`, `<table>`, `<field>`, or
    any other new XML elements/blocks to `plugin.xml` unless the person
    explicitly asks for a new page/permission/table to be registered.
  - When a task says "add a page" or "create an admin page," that means
    creating the PSHTML file under the existing path convention — it does
    **not** mean also inserting a matching `<page>`/`<permission>` pair into
    `plugin.xml` unless asked.
  - If `plugin.xml` already contains a `<page>`/`<permission>` block for the
    page being worked on, only fill in or edit the *values* already present
    (name, path, description, default) — don't duplicate the block or
    generate a second permission entry for the same page.
  - If you believe a new `<page>` or `<permission>` entry is genuinely
    needed, stop and ask first, and show the exact XML you intend to add
    before touching the file.
  - Preserve existing schema definitions; call out any breaking changes to
    existing custom tables explicitly since these can affect data already
    in production.
- Note any dependency on PowerSchool version-specific APIs or tags.

### PowerSchool Frontend (HTML/JS)
- **RequireJS for FusionCharts**: `require('fusioncharts/fusioncharts')` — no global `FusionCharts` unless explicitly loaded
- **DAT tags**: `~()` substitution, `~[]` conditionals, `~[if]...[/if]` blocks
- **jQuery**: Use `$j` (not `$`/`jQuery`); prefer `jqReady()` wrapper per VS Code completions
- **AngularJS**: Follow existing `psFormAdmin`, `psTableGrid` patterns
- **JS syntax**: ES5 only (no arrow functions, `const`/`let`, template literals) unless build step exists
- **PSHTML style**: Match existing indentation (2 spaces), inline PS tags

### Oracle SQL
- **No bind variables and no variable declarations.** PowerSchool's
  `tlist_sql` engine does not support `:bind_var` style bind parameters or
  PL/SQL-style `DECLARE`/variable assignment — queries are plain SQL
  templates evaluated inline. Do not introduce bind variables, `DECLARE`
  blocks, or session variables when writing or editing these queries.
- Parameterization instead happens via:
  - GPV (Get Parameter Value) substitution using `~(gpv.varname)` syntax,
    e.g. `WHERE calendardate BETWEEN ~(gpv.startdate) AND ~(gpv.enddate)`
  - Inline PSHTML tags evaluated before the query runs, e.g. `~(curstudid)`,
    `~(curschoolid)`
  - CTEs that compute parameter values at the top of the query (see the
    `params` / `daynumByYear` style CTEs in the Oracle query reference)
  - When editing an existing query, match whichever of these patterns it
    already uses rather than introducing a new one.
- Explicit column lists in `SELECT` — avoid `SELECT *` in code meant to run
  against production schemas that may change.
- Qualify table names with schema/owner where the codebase already does so.
- Prefer `ANSI JOIN` syntax (`JOIN ... ON`) over legacy comma-join syntax
  for readability, unless matching an existing file's style.
- For any query touching large PowerSchool tables (e.g. `studentcorefields`,
  `attendance`, `log`), flag potential performance concerns (missing
  indexes, full table scans) rather than assuming it's fine.
- Always wrap multi-statement data changes in an explicit transaction and
  mention rollback/commit behavior — never auto-commit changes silently.

## 4. PowerSchool Knowledge Base (Read On Demand)

The `docs/powerschool/` folder contains detailed reference docs collected
from prior projects. **Do not load all of these into context by default.**
Instead, read the specific file below only when the current task matches its
trigger — using the Read tool on a need-to-know basis.

| When the task involves... | Read this file |
|---|---|
| Writing/editing PSHTML tags, `~()`/`~[]` syntax, `tlist_sql`, GPV/URL params, date formatting, object reports, or anything with `~` tag syntax | `@docs/powerschool/PowerSchool_PSHTML_Tips.md` |
| Writing or reviewing Oracle SQL against the PowerSchool schema (attendance, contacts, enrollment, SBG, or any `tlist_sql` query) | `@docs/powerschool/PowerSchool_Oracle_Query_Reference.md` |
| Creating a new Admin Portal student page from scratch | `@docs/powerschool/PowerSchool_Admin_Student_Page_Template.md` |
| Writing PSHTML/JS snippets and you want to match existing shorthand conventions (e.g. `psFormAdmin`, `psTableGrid`, `jqReady`) | `@docs/powerschool/VS_Code_PS_completions.json` |
| Building AngularJS plugins for PowerSchool Admin Portal (module setup, structure, AMD/RequireJS, auto-bootstrap, template paths, $http patterns, file structure) | `@docs/powerschool/POWERSCHOOL_ANGULARJS_REFERENCE.md` |

Rules for using these:
- Load only the file(s) relevant to the specific task, not the whole folder.
- Treat their content as authoritative for PowerSchool-specific syntax and
  conventions — don't guess at tag syntax or schema/table names if a doc
  covers it.
- If a task spans multiple areas (e.g. a new admin page with a `tlist_sql`
  query), read all the relevant files for that task.
- These docs describe *syntax and patterns*, not permission to skip the
  confirm-before-running rules in Section 2 — SQL shown as reference is not
  pre-approved to execute.
- **FusionCharts examples** — none currently in repo; reference FusionCharts 3.19.0 docs for chart configs

## 5. General Working Practices

- Prefer proposing a diff/plan and asking before editing files that appear
  to be live PowerSchool configuration rather than test/scratch files.
- If a schema change or data fix is requested, ask whether it should be
  tested on a sandbox/state server copy first before touching production.
- Call out assumptions explicitly (e.g. "assuming `u_students_ext` is the
  custom table you mean") rather than guessing silently.
- Keep secrets (DB passwords, connection strings) out of code and out of
  chat — reference environment variables or config files instead.

---
*This is a starting draft — fill in the placeholders in Section 1 (PowerSchool
version, environment details, schema specifics) and adjust any rule above
that doesn't match how you actually want to work.*
