# PowerSchool Home Page Template Syntax

PowerSchool HTML template syntax (PSHTML) used in `home.html` files.

## Base Template Structure

```html
<!-- home.html -->
<head>
    <title>{Plugin Name}</title>
    <!-- Required scripts -->
    ~[wc:commonscripts]
    <!-- Required style sheets -->
    <link href="/images/css/screen.css" rel="stylesheet" media="screen">
    <link href="/images/css/print.css" rel="stylesheet" media="print">
</head>

<!-- Page auto-registration (PowerSchool TCL) -->
~[if.~(f.table_info;table=pages;fn=count;dothisfor=all;*path={plugin}/home.html)=0]
    ~(f.table_sel;table=pages;fn=create_rec)
    ~(f.field_set;name=[pages]path;value={plugin}/home.html)
    ~(f.field_set;name=[pages]security;value={SECURITY_BITMASK})
    ~[f.table_sel;table=pages;fn=save_rec]
    ~[f.table_sel;table=pages;fn=unload_rec]
[/if]

<body>
    ~[wc:admin_header_css]                 <!-- Admin header styles -->
    <!-- breadcrumb start -->{Plugin Name}<!-- breadcrumb end -->
    ~[wc:admin_navigation_css]             <!-- Admin navigation styles -->
    <!-- Start of Page -->
    <h1>{Plugin Name}</h1>
    <!-- Angular bootstrap via data-require-path + data-module-name -->
    <div data-require-path="/scripts/components/{plugin}/app/controllers/main.controller.js?~[time]"
         data-module-name="{plugin}App" ng-cloak>
        <div ng-controller="{plugin}Controller">
            <{plugin}-navigation></{plugin}-navigation>
        </div>
    </div>
    ~[wc:admin_footer_css]                 <!-- Admin footer styles -->
</body>
```

## PowerSchool Template Syntax

| Syntax | Purpose |
|--------|---------|
| `~[wc:commonscripts]` | Includes PowerSchool common scripts (jQuery, Angular, etc.) |
| `~[wc:admin_header_css]` | Admin header frame CSS |
| `~[wc:admin_navigation_css]` | Admin navigation styles |
| `~[wc:admin_footer_css]` | Admin footer frame CSS |
| `~[wc:title_student_begin_css]Title~[wc:title_student_end_css]` | Student page title bar (student pages) |
| `~[if.~(f.table_info...)]` | TCL conditional for page cataloging |
| `~[time]` | Cache-busting timestamp (e.g., `?~[time]` on script URLs) |
| `<!-- breadcrumb start -->...<!-- breadcrumb end -->` | Breadcrumb placeholder |

## Page Permission Registration (Auto-Registration)

PowerSchool auto-registers plugin pages in the `pages` table on first load. Include this TCL block in your `home.html` **before** `<body>`:

```html
<!-- Page cataloging auto-registration (PowerSchool TCL) -->
~[if.~(f.table_info;table=pages;fn=count;dothisfor=all;*path={plugin}/home.html)=0]
    ~(f.table_sel;table=pages;fn=create_rec)
    ~(f.field_set;name=[pages]path;value={plugin}/home.html)
    ~(f.field_set;name=[pages]security;value={SECURITY_BITMASK})
    ~[f.table_sel;table=pages;fn=save_rec]
    ~[f.table_sel;table=pages;fn=unload_rec]
[/if]
```

**DEVELOPER: Set the `security` value.** It's a bitmask where character position (1-indexed from left) = PowerSchool group ID. Change `0` to `1` for groups that should have access.

### Production Plugin Pattern

Extract to `/admin/{plugin}/page_registration.html` and include:

```html
<!-- In home.html, before <body> -->
~[include file="/admin/{plugin}/page_registration.html"]
```

Set the security bitmask once in `page_registration.html`.

## Bootstrap Trigger Note

PowerSchool's auto-bootstrap uses `data-module-name` + `data-require-path`. With inline scripts:

- `data-module-name="{plugin}App"` is **always required**
- `data-require-path` **may be required** to trigger bootstrap — test both in your environment:
  - Include `data-require-path="/admin/{plugin}/app/bootstrap.js?~[time]"` (empty file)
  - Omit `data-require-path` entirely
- Choose based on what works in your sandbox

## Cache-Busting Note

Inline scripts don't need `?~[time]` cache-busting since they're part of the HTML response.

## Inline Template Patterns (Dev Only)

### Pattern A: Fully Inline Templates

```html
<script type="text/ng-template" id="navigation.html">
    <nav>
        <ul>
            <li ng-repeat="item in navItems"><a ng-href="{{item.url}}">{{item.name}}</a></li>
        </ul>
    </nav>
</script>

<script type="text/ng-template" id="navigationSearch.html">
    <select ng-model="selectReport" ng-change="switchReport(selectReport)">
        <option ng-repeat="report in navItems"
                ng-if="report.active === true"
                value="{{ report.url }}">{{ report.name }}</option>
    </select>
</script>
```

### Pattern B: Hybrid (External Templates)

```html
<!-- In directive template -->
template: '<div ng-include="\'/admin/{plugin}/templates/navigation.html\'"></div>'
```

External templates at `/admin/{plugin}/templates/navigation.html` (same content, no `<script>` wrapper).

## Key Tags That Must Remain Unchanged

- `~[wc:commonscripts]`
- `~[wc:admin_header_frame_css]` / `~[wc:admin_header_css]`
- `~[wc:admin_navigation_frame_css]` / `~[wc:admin_navigation_css]`
- `~[wc:admin_footer_frame_css]` / `~[wc:admin_footer_css]`
- `~[wc:title_student_begin_css]...~[wc:title_student_end_css]`
- `<!-- breadcrumb start -->...<!-- breadcrumb end -->`