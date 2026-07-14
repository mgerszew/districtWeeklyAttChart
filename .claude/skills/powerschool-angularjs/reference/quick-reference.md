# Quick Reference

Checklist, common pitfalls, and path reference table.

## New Plugin Checklist

| Task | Production Path | Dev Path | Simplified Dev |
|------|-----------------|----------|----------------|
| Module definition | `define(fn(require) { require('angular'); require('components/shared/powerschoolModule'); return angular.module('{plugin}App', ['powerSchoolModule']); })` | Same | `<script>angular.module('{plugin}App', ['powerSchoolModule']);</script>` in home.html |
| Controller | `define(fn(require) { var app = require('/scripts/components/{plugin}/app/app.js'); app.controller('{plugin}Controller', ['$scope', '$http', fn($scope, $http) {...}]); })` | Same (path adjusts) | `<script>angular.module('{plugin}App').controller('{plugin}Controller', ['$scope', '$http', fn(...)]);</script>` in home.html |
| Service | `define(fn(require) { var app = require('/scripts/components/{plugin}/app/app.js'); app.service('{plugin}General', fn() {...}); })` | Same | `<script>angular.module('{plugin}App').service('{plugin}General', fn() {...});</script>` in home.html |
| Directive | `define(fn(require) { var app = require('/scripts/components/{plugin}/app/app.js'); app.directive('{plugin}Nav', fn() { return { restrict: 'E', template: '<div ng-include="tpl"></div>', link: fn(scope) {...} }; }); })` | Same | `<script>angular.module('{plugin}App').directive('{plugin}Nav', fn() {...});</script>` in home.html |
| Template (ng-include) | `/scripts/components/{plugin}/templates/myTemplate.html` | `/admin/{plugin}/templates/myTemplate.html` | Pattern A: `<script type="text/ng-template" id="myTemplate.html">` in home.html<br>Pattern B: `/admin/{plugin}/templates/myTemplate.html` |
| Data endpoint | `/admin/{plugin}/data/myData.json` (served via POST) | Same | Same |
| Home page | `/admin/{plugin}/home.html` with `data-require-path` + `data-module-name` | Same | Same (test with/without `data-require-path`) |
| Cache busting | `?~[time]` on scripts, `require.config({urlArgs: "bust=v2" + Math.random()})` in app.js | Same | Not needed for inline scripts |
| $http calls | `POST`, `Content-Type: application/x-www-form-urlencoded` | Same | Same |
| Angular bootstrap | **Never use `ng-app`** — use `data-module-name` + `data-require-path` | Same | Same |

## Common Pitfalls to Avoid

1. ❌ **Don't use `ng-app`** — PowerSchool auto-bootstraps via `data-module-name`
2. ❌ **Don't use ES6 imports** — Use AMD `define`/`require`
3. ❌ **Don't use GET for data** — PowerSchool data endpoints expect POST
4. ❌ **Don't forget `application/x-www-form-urlencoded`** header
5. ❌ **Don't put scripts in wrong location** — Use `/scripts/components/{plugin}/` (prod) or `/admin/{plugin}/app/` (dev)
6. ❌ **Don't use `controllerAs` exclusively** — Controllers use `$scope`; directives may use `controllerAs`
7. ❌ **Don't forget `~[time]` cache buster** on script loads in HTML
8. ❌ **Don't forget `ng-cloak`** on bootstrapped element to prevent flash
9. ❌ **Don't parse dates without `new Date()`** — PS returns date strings
10. ❌ **Don't use arrow functions/const/let** — ES5 only (AngularJS 1.4.7)

## File Path Quick Reference

| Type | Production Path | Dev Path |
|------|-----------------|----------|
| Module entry | `/scripts/components/{plugin}/app/app.js` | `/admin/{plugin}/app/app.js` |
| Controllers | `/scripts/components/{plugin}/app/controllers/` | `/admin/{plugin}/app/controllers/` |
| Services | `/scripts/components/{plugin}/app/services/` | `/admin/{plugin}/app/services/` |
| Directives | `/scripts/components/{plugin}/app/directives/` | `/admin/{plugin}/app/directives/` |
| Templates (ng-include) | `/scripts/components/{plugin}/templates/` | `/admin/{plugin}/templates/` |
| Data (JSON) | `/admin/{plugin}/data/` | Same |
| Styles | `/admin/{plugin}/css/` | Same |
| Images | `/admin/{plugin}/images/` | Same |
| Home page | `/admin/{plugin}/home.html` | Same |
| Documentation | `/admin/{plugin}/documentation/` | Same |
| Student-facing | `/admin/students/{plugin}/` | Same |
| Teacher-facing | `/teachers/{plugin}/` | Same |

## Pattern Selection Guide

| Scenario | Recommended Pattern |
|----------|---------------------|
| Quick prototype / learning | **Pattern A (Fully Inline)** |
| Single-page tool, < 200 lines JS | **Pattern A (Fully Inline)** |
| Multi-template page, team dev | **Pattern B (Hybrid)** |
| Production plugin | **Full AMD (Section 2 of reference)** |

## Template Placeholders

Replace these in templates:

- `{plugin}` — Your plugin name (e.g., `myPlugin`)
- `{plugin}App` — Angular module name
- `{plugin}Controller` — Controller name
- `{plugin}General`, `{plugin}Unique` — Service names
- `{plugin}Navigation`, `{plugin}NavigationSearch` — Directive names
- `{SECURITY_BITMASK}` — 64-char bitmask for page permissions

## PowerSchool Tags Quick Reference

| Tag | Purpose |
|-----|---------|
| `~[wc:commonscripts]` | Loads common scripts (jQuery, Angular, etc.) |
| `~[wc:admin_header_css]` | Admin header frame CSS |
| `~[wc:admin_navigation_css]` | Admin navigation styles |
| `~[wc:admin_footer_css]` | Admin footer frame CSS |
| `~[wc:title_student_begin_css]...~[wc:title_student_end_css]` | Student page title bar |
| `~[if.condition]...[/if]` | Conditional block |
| `~(gpv.varname)` | Get Parameter Value (URL param) |
| `~(curstudid)` | Current student ID |
| `~(curschoolid)` | Current school ID |
| `~(curyearid)` | Current year ID |
| `~[time]` | Cache-busting timestamp |
| `~[self.page]` | Current page URL |

## Form Action Codes

| Value | Action | Typical Use |
|-------|--------|-------------|
| `prim` | Primary/Insert | Create new record |
| `upd` | Update | Edit existing record |
| `del` | Delete | Delete record |
| `cpy` | Copy | Duplicate record |

## $http Pattern (Always Use)

```javascript
$http({
    url: '/admin/{plugin}/data/your_data.json',
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'}
}).then(function(response) {
    $scope.yourData = response.data;
});
```

## Date Handling Pattern

```javascript
rec.whencreated = new Date(rec.whencreated);
rec.whenmodified = new Date(rec.whenmodified);

// Fix ampersand encoding
var textFields = ['pluginname', 'description', 'publisher'];
textFields.forEach(function(field) {
    if (rec[field] && typeof rec[field] === 'string') {
        rec[field] = rec[field].replace(/&/gi, "&");
    }
});
```

## JSON Parse Pattern

```javascript
try {
    rec.cdn = JSON.parse(rec.cdn || '[]');
    rec.cdn = [...new Set(rec.cdn)];
} catch (e) {
    rec.cdn = [];
}
```