# PowerSchool AngularJS Plugin Development Reference

This document captures PowerSchool-specific AngularJS patterns for building admin portal plugins. Use this as a reference when building AngularJS customizations for PowerSchool.

---

## PowerSchool-Specific AngularJS Quirks

### 1. AngularJS is Auto-Bootstrapped by PowerSchool
**DO NOT** use `ng-app` in your HTML. PowerSchool automatically bootstraps AngularJS via `data-module-name` and `data-require-path` attributes.

```html
<!-- home.html - PowerSchool auto-bootstraps via data-require-path + data-module-name -->
<div data-require-path="/scripts/components/{plugin}/app/controllers/main.controller.js?~[time]"
     data-module-name="{plugin}App" ng-cloak>
    <div ng-controller="{plugin}Controller">
        <{plugin}-navigation></{plugin}-navigation>
    </div>
</div>
```

- No `ng-app` directive in HTML
- PowerSchool loads the module via `data-module-name="{plugin}App"` (matches `angular.module('{plugin}App', ...)` in app.js)
- Scripts loaded via `data-require-path` with PowerSchool cache-buster `?~[time]`
- `ng-cloak` prevents flash of uncompiled Angular

---

### 2. AMD/RequireJS Module System (Not ES6 Modules)
All JavaScript uses **AMD/RequireJS** (`define`/`require`), **not ES6 imports**.

```javascript
// app.js - Module definition
'use strict';
require.config({
    urlArgs: "bust=v2" + Math.random() * 2  // Cache busting
});
define(function(require) {
    var angular = require('angular');
    require('components/shared/powerschoolModule');  // PowerSchool core module
    return angular.module('{plugin}App', ['powerSchoolModule']);
});

// Controller - AMD style
define(function (require) {
    var app = require('/scripts/components/{plugin}/app/app.js');
    app.controller('{plugin}Controller', ['$scope', '$http', '$compile', function ($scope, $http, $compile) {
        // controller logic
    }]);
});

// Service - AMD style
define(function (require) {
    var app = require('/scripts/components/{plugin}/app/app.js');
    app.service('{plugin}General', function () {
        this.ampHandler = function(a) { /* ... */ };
        this.dateHandlerNG = function(dts) { /* ... */ };
    });
});
```

**Key patterns:**
- `require.config({ urlArgs: "bust=v2" + Math.random() * 2 })` for cache busting in app.js
- `require('angular')` - loads Angular from PowerSchool's require config
- `require('components/shared/powerschoolModule')` - loads PowerSchool's Angular module
- Absolute paths from WEB_ROOT: `require('/scripts/components/{plugin}/app/app.js')`
- Return `angular.module('appName', ['deps'])` from app.js

---

### 3. File Structure - Production vs Development Paths

Scripts go under `/scripts/components/{plugin}/` (production). During development, store under `/admin/{plugin}/` for cache-busting.

```
WEB_ROOT/
├── scripts/
│   └── components/
│       └── {plugin}/
│           ├── app/
│           │   ├── app.js                    # Module definition
│           │   ├── controllers/
│           │   │   ├── main.controller.js
│           │   │   ├── reports.controller.js
│           │   │   └── ...
│           │   ├── services/
│           │   │   ├── general.service.js
│           │   │   └── unique.service.js
│           │   └── directives/
│           │       ├── navigation.directive.js
│           │       └── navigationSearch.directive.js
│           └── templates/                    # HTML templates (ng-include)
│               ├── navigation.html
│               ├── navigationSearch.html
│               └── reports/
│                   ├── fieldSecurityGrid.html
│                   └── ...
├── admin/
│   └── {plugin}/
│       ├── app/                              # Dev path for scripts
│       │   ├── app.js
│       │   ├── controllers/
│       │   ├── services/
│       │   └── directives/
│       ├── templates/                        # Dev path for templates
│       ├── data/                             # JSON data endpoints
│       │   ├── plugins.json
│       │   ├── installed_plugins.json
│       │   └── userRoles.json
│       ├── css/
│       │   └── main.css
│       ├── images/
│       ├── home.html                         # Main entry page
│       └── documentation/
│           └── doc.html
├── admin/students/{plugin}/                  # Student-facing pages
└── teachers/{plugin}/                        # Teacher-facing pages
```

**Path Rules:**

| Asset Type | Production Path | Development Path |
|------------|-----------------|------------------|
| **JavaScript (AMD modules)** | `/scripts/components/{plugin}/app/` | `/admin/{plugin}/app/` |
| **HTML Templates (ng-include)** | `/scripts/components/{plugin}/templates/` | `/admin/{plugin}/templates/` |
| **Data Endpoints (JSON)** | `/admin/{plugin}/data/` | Same |
| **Images** | `/admin/{plugin}/images/` | Same |
| **CSS** | `/admin/{plugin}/css/` | Same |
| **Home/Entry HTML** | `/admin/{plugin}/home.html` | Same |
| **Documentation** | `/admin/{plugin}/documentation/` | Same |
| **Student-facing** | `/admin/students/{plugin}/` | Same |
| **Teacher-facing** | `/teachers/{plugin}/` | Same |

---

### 3.5 Simplified Development Patterns (Inline Scripts)

For rapid prototyping, learning, or simple single-page tools, you can inline AngularJS code directly in `home.html` instead of using the full AMD/RequireJS structure. Two patterns are documented below—choose based on your needs.

> **Note:** These patterns are for **development/sandbox environments only**. Production plugins should use the full AMD structure in Section 2.

#### Pattern A: Fully Inline (Single HTML File)

All AngularJS code (module, controllers, services, directives) lives in `<script>` tags in `home.html`. Templates use `<script type="text/ng-template">`.

```html
<!-- /admin/{plugin}/home.html -->
<head>
    <title>{Plugin Name}</title>
    ~[wc:commonscripts]
<link href="/images/css/screen.css" rel="stylesheet" media="screen">
    <link href="/images/css/print.css" rel="stylesheet" media="print">
</head>

<!-- Page auto-registration — see "Page Permission Registration" section -->
~[if.~(f.table_info;table=pages;fn=count;dothisfor=all;*path={plugin}/home.html)=0]
    ~(f.table_sel;table=pages;fn=create_rec)
    ~(f.field_set;name=[pages]path;value={plugin}/home.html)
    ~(f.field_set;name=[pages]security;value={SECURITY_BITMASK})
    ~[f.table_sel;table=pages;fn=save_rec]
    ~[f.table_sel;table=pages;fn=unload_rec]
[/if]

<body>
    ~[wc:admin_header_css]
    <!-- breadcrumb start -->{Plugin Name}<!-- breadcrumb end -->
    ~[wc:admin_navigation_css]
    <h1>{Plugin Name}</h1>

    <!-- Bootstrap: data-module-name REQUIRED. data-require-path MAY be required to trigger bootstrap. -->
    <div data-require-path="/admin/{plugin}/app/bootstrap.js?~[time]"
         data-module-name="{plugin}App" ng-cloak>
        <div ng-controller="{plugin}Controller">
            <{plugin}-navigation></{plugin}-navigation>
        </div>
    </div>

    <!-- Inline Templates (ng-template) -->
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

    <!-- Inline AngularJS Application -->
    <script>
        'use strict';

        // Module definition (no AMD wrapper)
        angular.module('{plugin}App', ['powerSchoolModule']);

        // Controller
        angular.module('{plugin}App').controller('{plugin}Controller',
            ['$scope', '$http', '$compile', '{plugin}General', '{plugin}Unique',
            function ($scope, $http, $compile, general, unique) {
                $scope.navItems = [];
                $scope.switchReport = function(report) { window.location.href = report; };

                $http({
                    url: '/admin/{plugin}/data/plugins.json',
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                }).then(function (response) {
                    $scope.navItems = response.data.reports.concat(response.data.tools);
                });
            }]);

        // Services
        angular.module('{plugin}App').service('{plugin}General', function() {
            this.ampHandler = function(a) { /* ... */ };
            this.dateHandlerNG = function(dts) { /* ... */ };
        });

        angular.module('{plugin}App').service('{plugin}Unique', function() {
            this.simpleObjArray = function(primeArray, keyname) {
                var output = [], keys = [];
                angular.forEach(primeArray, function(item) {
                    var key = item[keyname];
                    if (keys.indexOf(key) === -1) {
                        keys.push(key);
                        output.push(item);
                    }
                });
                return output;
            };
        });

        // Directives
        angular.module('{plugin}App').directive('{plugin}Navigation', function($plugin}Navigation', ['$http', '$compile',
            function ($http, $compile) {
                return {
                    restrict: 'E',
                    template: '<div ng-include="\'navigation.html\'"></div>',
                    link: function (scope) {
                        // link logic if needed
                    }
                };
            }]);

        angular.module('{plugin}App').directive('{plugin}NavigationSearch', ['$http', '$compile',
            function ($http, $compile) {
                return {
                    restrict: 'E',
                    template: '<div ng-include="\'navigationSearch.html\'"></div>',
                    controller: ['$http', '$scope', function($http, $scope) {
                        $scope.switchReport = function(report) { window.location.href = report; };
                    }],
                    controllerAs: 'navCtrl'
                };
            }]);
    </script>

    ~[wc:admin_footer_css]
</body>
```

#### Pattern B: Hybrid (Inline Logic + External Templates)

Module/controllers/services inline; templates served from `/admin/{plugin}/templates/` via `ng-include`.

```html
<!-- /admin/{plugin}/home.html -->
<head>
    <title>{Plugin Name}</title>
    ~[wc:commonscripts]
<link href="/images/css/screen.css" rel="stylesheet" media="screen">
    <link href="/images/css/print.css" rel="stylesheet" media="print">
</head>

<!-- Page auto-registration — see "Page Permission Registration" section -->
~[if.~(f.table_info;table=pages;fn=count;dothisfor=all;*path={plugin}/home.html)=0]
    ~(f.table_sel;table=pages;fn=create_rec)
    ~(f.field_set;name=[pages]path;value={plugin}/home.html)
    ~(f.field_set;name=[pages]security;value={SECURITY_BITMASK})
    ~[f.table_sel;table=pages;fn=save_rec]
    ~[f.table_sel;table=pages;fn=unload_rec]
[/if]

<body>
    ~[wc:admin_header_css]
    <!-- breadcrumb start -->{Plugin Name}<!-- breadcrumb end -->
    ~[wc:admin_navigation_css]
    <h1>{Plugin Name}</h1>

    <div data-require-path="/admin/{plugin}/app/bootstrap.js?~[time]"
         data-module-name="{plugin}App" ng-cloak>
        <div ng-controller="{plugin}Controller">
            <{plugin}-navigation></{plugin}-navigation>
            <{plugin}-navigation-search></{plugin}-navigation-search>
        </div>
    </div>

    <!-- Inline AngularJS Application (no templates) -->
    <script>
        'use strict';
        angular.module('{plugin}App', ['powerSchoolModule']);

        angular.module('{plugin}App').controller('{plugin}Controller',
            ['$scope', '$http', '$compile', '{plugin}General', '{plugin}Unique',
            function ($scope, $http, $compile, general, unique) {
                $scope.reportData = [];
                $scope.filterMaps = {};

                $http({
                    url: '/admin/{plugin}/data/installed_plugins.json',
                    method: 'POST',
                    headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                }).then(function (response) {
                    $scope.reportData = response.data;
                    $scope.setupMaps = [
                        {'map': 'publisherMap', 'key': 'publisher'},
                        {'map': 'cdnStatusMap', 'key': 'cdnStatus'}
                    ];
                    angular.forEach($scope.setupMaps, function (map) {
                        $scope.uniques[map.key] = unique.simpleObjArray($scope.reportData, map.key);
                        $scope.uniques[map.key] = general.sortMap($scope.uniques[map.key], map.key);
                        $scope.filterMaps[map.map] = general.makeMap($scope.uniques[map.key], map.key);
                    });
                });
            }]);

        angular.module('{plugin}App').service('{plugin}General', function() {
            this.ampHandler = function(a) { /* ... */ };
            this.dateHandlerNG = function(dts) { /* ... */ };
            this.sortMap = function(arr, key) { return arr.sort(function(a,b){ return (a[key] > b[key]) ? 1 : -1; }); };
            this.makeMap = function(arr, key) {
                var map = {}; angular.forEach(arr, function(item){ map[item[key]] = true; }); return map;
            };
        });

        angular.module('{plugin}App').service('{plugin}Unique', function() {
            this.simpleObjArray = function(primeArray, keyname) {
                var output = [], keys = [];
                angular.forEach(primeArray, function(item) {
                    var key = item[keyname];
                    if (keys.indexOf(key) === -1) { keys.push(key); output.push(item); }
                });
                return output;
            };
        });

        angular.module('{plugin}App').directive('{plugin}Navigation', ['$http', '$compile',
            function ($http, $compile) {
                return {
                    restrict: 'E',
                    template: '<div ng-include="\'/admin/{plugin}/templates/navigation.html\'"></div>'
                };
            }]);

        angular.module('{plugin}App').directive('{plugin}NavigationSearch', ['$http', '$compile',
            function ($http, $compile) {
                return {
                    restrict: 'E',
                    template: '<div ng-include="\'/admin/{plugin}/templates/navigationSearch.html\'"></div>',
                    controller: ['$http', '$scope', function($http, $scope) {
                        $scope.switchReport = function(report) { window.location.href = report; };
                    }],
                    controllerAs: 'navCtrl'
                };
            }]);
    </script>

    ~[wc:admin_footer_css]
</body>
```

**External templates** at `/admin/{plugin}/templates/navigation.html` and `/admin/{plugin}/templates/navigationSearch.html` (same content as `ng-template` blocks above, without `<script>` wrapper).

#### Pattern Comparison

| Scenario | Recommended Pattern |
|----------|---------------------|
| Quick prototype / learning | **Pattern A (Fully Inline)** |
| Single-page tool, < 200 lines JS | **Pattern A (Fully Inline)** |
| Multi-template page, team dev | **Pattern B (Hybrid)** |
| Production plugin | **Full AMD (Section 2)** |

#### Bootstrap Trigger Note

PowerSchool's auto-bootstrap uses `data-module-name` + `data-require-path`. With inline scripts:

- `data-module-name="{plugin}App"` is **always required**
- `data-require-path` **may be required** to trigger bootstrap — test both in your environment:
  - Include `data-require-path="/admin/{plugin}/app/bootstrap.js?~[time]"` (empty file)
  - Omit `data-require-path` entirely
- Choose based on what works in your sandbox

#### Cache-Busting Note

Inline scripts don't need `?~[time]` cache-busting since they're part of the HTML response.

---

### 4. PowerSchool HTML Template Syntax

PowerSchool uses TCL-style server-side includes and conditionals in `.html` files:

```html
<!-- home.html -->
<head>
    <title>{Plugin Name}</title>
    <!-- required scripts -->
    ~[wc:commonscripts]                    <!-- PowerSchool common scripts include -->
    <!-- Required style sheets -->
<link href="/images/css/screen.css" rel="stylesheet" media="screen">
    <link href="/images/css/print.css" rel="stylesheet" media="print">
</head>

<!-- Page auto-registration — see "Page Permission Registration" section -->
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

**PowerSchool Template Syntax:**
- `~[wc:commonscripts]` - Includes PowerSchool common scripts (jQuery, Angular, etc.)
- `~[wc:admin_header_css]` / `~[wc:admin_footer_css]` - Admin layout styles
- `~[wc:admin_navigation_css]` - Admin navigation styles
- `~[if.~(f.table_info...)]` - TCL conditional for page cataloging
- `~[time]` - Cache-busting timestamp (e.g., `?~[time]` on script URLs)
- `<!-- breadcrumb start -->...<!-- breadcrumb end -->` - Breadcrumb placeholder

---
 
### 4.5 Page Permission Registration (Auto-Registration)
 
PowerSchool auto-registers plugin pages in the `pages` table on first load. Include this TCL block in your `home.html` **before** `<body>`:
 
```html
<!-- Page cataloging auto-registration (PowerSchool TCL) -->
~[if.~(f.table_info;table=pages;fn=count;dothisfor=all;*path={plugin}/home.html)=0]
    ~(f.table_sel;table=pages;fn=create_rec)
    ~(f.field_set;name=[pages]path;value={plugin}/home.html)
    ~(f.field_set;name=[pages]security;value=00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
    ~[f.table_sel;table=pages;fn=save_rec]
    ~[f.table_sel;table=pages;fn=unload_rec]
[/if]
```
 
**DEVELOPER: Set the `security` value above.** It is a bitmask where character position (1-indexed from left) = PowerSchool group ID. Change `0` to `1` for groups that should have access.
 
---
 
**Production Plugin Pattern**: For production plugins, extract this block to `/admin/{plugin}/page_registration.html` and include it:
 
```html
<!-- In home.html, before <body> -->
~[include file="/admin/{plugin}/page_registration.html"]
```
 
Set the security bitmask once in `page_registration.html`.
 
---
 
### 5. $http Calls Use POST + Form-URLEncoded

PowerSchool endpoints expect `POST` with `application/x-www-form-urlencoded`:

```javascript
$http({
    "url": '/admin/{plugin}/data/installed_plugins.json',
    "method": 'POST',
    "headers": {"Content-Type": "application/x-www-form-urlencoded"}
})
.then(function (response) {
    $scope.reportData = response.data;
});
```

- **Always POST** (even for data retrieval)
- **Content-Type**: `application/x-www-form-urlencoded`
- Data files served from `/admin/{plugin}/data/*.json`

---

### 6. AngularJS Patterns Specific to This Codebase

#### Controllers use `$scope` (not `controllerAs` consistently)

```javascript
app.controller('ReportsController', ['$scope', '$http', '$compile', '{plugin}General', '{plugin}Unique',
    function ($scope, $http, $compile, general, unique) {
        $scope.reportData = [];
        $scope.filterMaps = {};
        // ...
    }
]);
```

#### Directives use `restrict: 'E'` + `template` + `ng-include`

```javascript
app.directive('{plugin}NavigationSearch', ['$http','$compile', function ($http, $compile) {
    return {
        restrict: 'E',
        link: function (scope, element, attrs) {
            scope.contentUrl = "/scripts/components/{plugin}/templates/navigationSearch.html";
            $http({ url: '/admin/{plugin}/data/plugins.json', method: 'POST', ... })
                .then(function (response) {
                    scope.navItems = response.data.reports.concat(response.data.tools);
                });
        },
        template: '<div ng-include="contentUrl"></div>',
        controller: ('navigationSearchController', ['$http','$scope', function($http,$scope) {
            $scope.switchReport = function(report) { window.location.href = report; }
        }]),
        controllerAs: 'navCtrl'
    };
}]);
```

#### Services use AMD + `angular.forEach`

```javascript
define(function (require) {
    var app = require('/scripts/components/{plugin}/app/app.js');
    app.service('{plugin}Unique', function() {
        this.simpleObjArray = function(primeArray, keyname) {
            var output = [], keys = [];
            angular.forEach(primeArray, function (item) {
                var key = item[keyname];
                if (keys.indexOf(key) === -1) {
                    keys.push(key);
                    output.push(item);
                }
            });
            return output;
        };
    });
});
```

#### Templates use `ng-repeat`, `ng-if`, `ng-change`, `ng-model`

```html
<!-- navigationSearch.html -->
<select ng-model="selectReport" ng-change="switchReport(selectReport)">
    <option ng-repeat="report in navItems"
            ng-if="report.active === true"
            value="{{ report.url }}">{{ report.name }}</option>
</select>
```

---

### 7. Data Handling Patterns

#### Date Handling (PowerSchool returns strings)

```javascript
// Convert timestamp strings to Date objects
rec.whencreated = new Date(rec.whencreated);
rec.whenmodified = new Date(rec.whenmodified);

// Fix ampersand encoding in text fields
var textFields = ['pluginname', 'description', 'publisher'];
textFields.forEach(function(field) {
    if (rec[field] && typeof rec[field] === 'string') {
        rec[field] = rec[field].replace(/&/gi, "&");
    }
});
```

#### JSON Parsing with Error Handling

```javascript
try {
    rec.cdn = JSON.parse(rec.cdn || '[]');
    rec.cdn = [...new Set(rec.cdn)];  // Remove duplicates
} catch (e) {
    rec.cdn = [];
}
```

#### Filter Map Generation (Dynamic UI Filters)

```javascript
$scope.setupMaps = [
    {'map': 'publisherMap', 'key': 'publisher'},
    {'map': 'cdnStatusMap', 'key': 'cdnStatus'}
];

angular.forEach($scope.setupMaps, function (map) {
    $scope.uniques[map.key] = unique.simpleObjArray($scope.reportData, map.key);
    $scope.uniques[map.key] = general.sortMap($scope.uniques[map.key], map.key);
    $scope.filterMaps[map.map] = general.makeMap($scope.uniques[map.key], map.key);
});
```

---

### 8. Cache Busting

- **Scripts**: `?~[time]` in `data-require-path` (PowerSchool timestamp)
- **App.js**: `require.config({ urlArgs: "bust=v2" + Math.random() * 2 })`
- **Data**: POST requests (not cached by browsers)

---

### 9. PowerSchool Module Dependency

```javascript
// app.js - Always depend on 'powerSchoolModule'
define(function(require) {
    var angular = require('angular');
    require('components/shared/powerschoolModule');  // Required
    return angular.module('{plugin}App', ['powerSchoolModule']);
});
```

---

## Quick Reference Checklist for New Plugins

| Task | Production Path | Dev Path | Simplified Dev Path |
|------|-----------------|----------|---------------------|
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

---

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

---

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

---

*Generated for PSUG 2026 - Customizing with AI session*