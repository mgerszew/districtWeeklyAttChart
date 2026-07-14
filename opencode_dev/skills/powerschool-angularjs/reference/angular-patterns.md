# AngularJS Patterns Specific to PowerSchool

Patterns for controllers, services, directives, and templates used in this codebase.

## Controllers Use `$scope` (Not `controllerAs` Consistently)

```javascript
app.controller('ReportsController', ['$scope', '$http', '$compile', '{plugin}General', '{plugin}Unique',
    function ($scope, $http, $compile, general, unique) {
        $scope.reportData = [];
        $scope.filterMaps = {};
        // ...
    }
]);
```

- Inject `$scope`, `$http`, `$compile` as needed
- Use `$scope` for all view bindings
- Services injected by name (e.g., `{plugin}General`, `{plugin}Unique`)

## Directives: `restrict: 'E'` + `template` + `ng-include`

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

### Directive Patterns
- `restrict: 'E'` — element directive (`<my-directive>`)
- `template: '<div ng-include="contentUrl"></div>'` — load external template
- `link` function for DOM manipulation / data fetching
- `controller` + `controllerAs` optional for directive-specific logic

## Services: AMD + `angular.forEach`

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

- Define via AMD `define(function(require) { ... })`
- Use `angular.forEach` for array iteration (not `forEach` on arrays)
- Return `this` methods

## Templates: `ng-repeat`, `ng-if`, `ng-change`, `ng-model`

```html
<!-- navigationSearch.html -->
<select ng-model="selectReport" ng-change="switchReport(selectReport)">
    <option ng-repeat="report in navItems"
            ng-if="report.active === true"
            value="{{ report.url }}">{{ report.name }}</option>
</select>
```

- `ng-repeat` for lists
- `ng-if` for conditional rendering (removes from DOM)
- `ng-change` for select/input change handlers
- `ng-model` for two-way binding
- `{{ }}` interpolation

## Inline Template Pattern (Pattern A)

```html
<!-- In home.html -->
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

- Use `<script type="text/ng-template" id="templateId.html">` for inline templates
- Reference in directive: `template: '<div ng-include="\'templateId.html\'"></div>'`

## Hybrid Template Pattern (Pattern B)

```javascript
// In directive (inline in home.html <script>)
template: '<div ng-include="\'/admin/{plugin}/templates/navigation.html\'"></div>'
```

```html
<!-- /admin/{plugin}/templates/navigation.html -->
<nav>
    <ul>
        <li ng-repeat="item in navItems"><a ng-href="{{item.url}}">{{item.name}}</a></li>
    </ul>
</nav>
```

- Templates served from `/admin/{plugin}/templates/`
- `ng-include` with absolute path from web root
- No `<script>` wrapper needed

## Module Definition Pattern

```javascript
// Production (AMD) - app.js
define(function(require) {
    var angular = require('angular');
    require('components/shared/powerschoolModule');
    return angular.module('{plugin}App', ['powerSchoolModule']);
});

// Inline (dev) - in home.html <script>
angular.module('{plugin}App', ['powerSchoolModule']);
```

## Controller Registration Pattern

```javascript
// Production (AMD) - main.controller.js
define(function (require) {
    var app = require('/scripts/components/{plugin}/app/app.js');
    app.controller('{plugin}Controller', ['$scope', '$http', '$compile', '{plugin}General', '{plugin}Unique',
        function ($scope, $http, $compile, general, unique) {
            // ...
        }
    ]);
});

// Inline (dev) - in home.html <script>
angular.module('{plugin}App').controller('{plugin}Controller',
    ['$scope', '$http', '$compile', '{plugin}General', '{plugin}Unique',
    function ($scope, $http, $compile, general, unique) {
        // ...
    }
]);
```

## Service Registration Pattern

```javascript
// Production (AMD) - general.service.js
define(function (require) {
    var app = require('/scripts/components/{plugin}/app/app.js');
    app.service('{plugin}General', function() {
        this.ampHandler = function(a) { /* ... */ };
        this.dateHandlerNG = function(dts) { /* ... */ };
        this.sortMap = function(arr, key) { return arr.sort(function(a,b){ return (a[key] > b[key]) ? 1 : -1; }); };
        this.makeMap = function(arr, key) {
            var map = {}; angular.forEach(arr, function(item){ map[item[key]] = true; }); return map;
        };
    });
});

// Inline (dev) - in home.html <script>
angular.module('{plugin}App').service('{plugin}General', function() {
    this.ampHandler = function(a) { /* ... */ };
    this.dateHandlerNG = function(dts) { /* ... */ };
    this.sortMap = function(arr, key) { return arr.sort(function(a,b){ return (a[key] > b[key]) ? 1 : -1; }); };
    this.makeMap = function(arr, key) {
        var map = {}; angular.forEach(arr, function(item){ map[item[key]] = true; }); return map;
    };
});
```

## Directive Registration Pattern

```javascript
// Production (AMD) - navigation.directive.js
define(function (require) {
    var app = require('/scripts/components/{plugin}/app/app.js');
    app.directive('{plugin}Navigation', ['$http', '$compile',
        function ($http, $compile) {
            return {
                restrict: 'E',
                template: '<div ng-include="contentUrl"></div>',
                link: function (scope) {
                    scope.contentUrl = "/scripts/components/{plugin}/templates/navigation.html";
                    // fetch data...
                }
            };
        }
    ]);
});

// Inline (dev) - in home.html <script>
angular.module('{plugin}App').directive('{plugin}Navigation', ['$http', '$compile',
    function ($http, $compile) {
        return {
            restrict: 'E',
            template: '<div ng-include="contentUrl"></div>',
            link: function (scope) {
                scope.contentUrl = "/scripts/components/{plugin}/templates/navigation.html";
                // fetch data...
            }
        };
    }
]);
```