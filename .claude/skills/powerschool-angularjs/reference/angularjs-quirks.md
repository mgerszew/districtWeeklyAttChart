# PowerSchool AngularJS Quirks

PowerSchool's AngularJS implementation has specific quirks you must follow. This is the most critical reference — violating these rules will break your plugin.

## 1. AngularJS is Auto-Bootstrapped — No `ng-app`

**NEVER use `ng-app` in your HTML.** PowerSchool automatically bootstraps AngularJS via `data-module-name` and `data-require-path` attributes.

```html
<!-- home.html - PowerSchool auto-bootstraps via data-require-path + data-module-name -->
<div data-require-path="/scripts/components/{plugin}/app/controllers/main.controller.js?~[time]"
     data-module-name="{plugin}App" ng-cloak>
    <div ng-controller="{plugin}Controller">
        <{plugin}-navigation></{plugin}-navigation>
    </div>
</div>
```

### Rules
- **No `ng-app` directive** anywhere in HTML
- `data-module-name="{plugin}App"` must match `angular.module('{plugin}App', ...)` in app.js
- Scripts loaded via `data-require-path` with PowerSchool cache-buster `?~[time]`
- `ng-cloak` prevents flash of uncompiled Angular

## 2. AMD/RequireJS Module System — Not ES6 Modules

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

### Key Patterns
- `require.config({ urlArgs: "bust=v2" + Math.random() * 2 })` for cache busting in app.js
- `require('angular')` — loads Angular from PowerSchool's require config
- `require('components/shared/powerschoolModule')` — loads PowerSchool's Angular module
- Absolute paths from WEB_ROOT: `require('/scripts/components/{plugin}/app/app.js')`
- Return `angular.module('appName', ['deps'])` from app.js

## 3. ES5 Only — No Modern JavaScript

AngularJS 1.4.7 runs in ES5 environment. **Do not use:**
- Arrow functions (`=>`)
- `const` / `let`
- Template literals (`` `string` ``)
- Destructuring
- Spread operator
- Classes
- Modules (`import`/`export`)

Use `var`, `function()`, string concatenation, `angular.forEach()`.

## 4. PowerSchool Module Dependency

```javascript
// app.js - Always depend on 'powerSchoolModule'
define(function(require) {
    var angular = require('angular');
    require('components/shared/powerschoolModule');  // Required
    return angular.module('{plugin}App', ['powerSchoolModule']);
});
```

## 5. Cache Busting

| Target | Method |
|--------|--------|
| Scripts in HTML | `?~[time]` in `data-require-path` |
| app.js | `require.config({ urlArgs: "bust=v2" + Math.random() * 2 })` |
| Data endpoints | POST requests (not cached by browsers) |

## Quick Checklist

- [ ] No `ng-app` in HTML
- [ ] `data-module-name` matches module name in app.js
- [ ] `data-require-path` points to controller with `?~[time]`
- [ ] `ng-cloak` on bootstrap element
- [ ] All JS uses `define`/`require` (production) or inline `<script>` (dev)
- [ ] No ES6 syntax
- [ ] Module depends on `powerSchoolModule`
- [ ] jQuery referenced as `$j`, not `$`