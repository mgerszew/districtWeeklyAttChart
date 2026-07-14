# Data Handling Patterns

$http calls, date handling, filter maps, JSON parsing, and cache busting.

## $http Calls — POST + Form-URLEncoded

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

**Rules:**
- Always `POST` (even for data retrieval)
- Content-Type: `application/x-www-form-urlencoded`
- Data files served from `/admin/{plugin}/data/*.json`
- Use `.then()` not `.success()` (deprecated)

## Date Handling — PowerSchool Returns Strings

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

- PS returns dates as strings — always wrap with `new Date()`
- Ampersands in text fields may be double-encoded — replace `&` → `&`

## JSON Parsing with Error Handling

```javascript
try {
    rec.cdn = JSON.parse(rec.cdn || '[]');
    rec.cdn = [...new Set(rec.cdn)];  // Remove duplicates
} catch (e) {
    rec.cdn = [];
}
```

- Always wrap `JSON.parse` in try/catch
- Provide fallback (empty array/object)
- Deduplicate arrays with `Set` (or manual loop for ES5)

## Filter Map Generation (Dynamic UI Filters)

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

### Service Helpers Used
```javascript
// In {plugin}Unique service
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

// In {plugin}General service
this.sortMap = function(arr, key) {
    return arr.sort(function(a,b){ return (a[key] > b[key]) ? 1 : -1; });
};

this.makeMap = function(arr, key) {
    var map = {};
    angular.forEach(arr, function(item){ map[item[key]] = true; });
    return map;
};
```

## Cache Busting

| Asset | Method |
|-------|--------|
| **Scripts** | `?~[time]` in `data-require-path` (PowerSchool timestamp) |
| **App.js** | `require.config({ urlArgs: "bust=v2" + Math.random() * 2 })` |
| **Data** | POST requests (not cached by browsers) |

### In HTML (Production)
```html
<div data-require-path="/scripts/components/{plugin}/app/controllers/main.controller.js?~[time]"
     data-module-name="{plugin}App" ng-cloak>
```

### In app.js (AMD)
```javascript
require.config({
    urlArgs: "bust=v2" + Math.random() * 2  // Cache busting
});
```

### Inline/Dev Scripts
No cache-busting needed — part of HTML response.

## PowerSchool Module Dependency

```javascript
// app.js - Always depend on 'powerSchoolModule'
define(function(require) {
    var angular = require('angular');
    require('components/shared/powerschoolModule');  // Required
    return angular.module('{plugin}App', ['powerSchoolModule']);
});
```

- `require('angular')` — loads Angular from PowerSchool's require config
- `require('components/shared/powerschoolModule')` — loads PowerSchool's Angular module
- Return `angular.module('appName', ['powerSchoolModule'])`

## AMD/RequireJS Module System

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

**Key Patterns:**
- `require.config({ urlArgs: "bust=v2" + Math.random() * 2 })` for cache busting
- `require('angular')` — loads Angular from PS require config
- `require('components/shared/powerschoolModule')` — loads PS Angular module
- Absolute paths from WEB_ROOT: `require('/scripts/components/{plugin}/app/app.js')`
- Return `angular.module('appName', ['deps'])` from app.js

## ES5 Only — No ES6+

| Feature | Use Instead |
|---------|-------------|
| Arrow functions | `function() {}` |
| `const` / `let` | `var` |
| Template literals | String concat: `'a' + b + 'c'` |
| `forEach` on arrays | `angular.forEach(arr, fn)` |
| `Array.from`, `Set` | Manual loops, `indexOf` checks |
| Destructuring | Manual assignment |
| Default parameters | `var x = x || defaultValue` |

PowerSchool runs AngularJS 1.4.7 — ES5 only unless build step exists.