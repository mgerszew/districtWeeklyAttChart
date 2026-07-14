# Workflow: New Plugin - Inline Pattern (Pattern A)

Quick prototype / learning / single-page tool. All code in one `home.html`.

## Prerequisites
- PowerSchool Admin Portal access
- Sandbox/development environment
- Text editor

## Steps

### 1. Create Plugin Directory
```bash
mkdir -p /admin/myPlugin/{templates,data,css,images}
```

### 2. Create `home.html` from Template
Copy `templates/inline/home.html` to `/admin/myPlugin/home.html`

### 3. Replace Placeholders
Edit `/admin/myPlugin/home.html`:

| Placeholder | Replace With |
|-------------|--------------|
| `{plugin}` | `myPlugin` (all occurrences) |
| `{Plugin Name}` | `My Plugin` |
| `My Plugin` (in title/breadcrumb/h1) | Your plugin display name |
| `<p>Page content description...</p>` | Your description |

### 4. Add Your AngularJS Code
In the inline `<script>` block:

```javascript
// 1. Module definition
angular.module('myPluginApp', ['powerSchoolModule']);

// 2. Controllers
angular.module('myPluginApp').controller('myPluginController',
    ['$scope', '$http', '$compile', 'myPluginGeneral', 'myPluginUnique',
    function ($scope, $http, $compile, general, unique) {
        // Your controller logic
        $scope.myData = [];
        
        $http({
            url: '/admin/myPlugin/data/myData.json',
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'}
        }).then(function (response) {
            $scope.myData = response.data;
        });
    }]);

// 3. Services
angular.module('myPluginApp').service('myPluginGeneral', function() {
    this.ampHandler = function(a) { /* ... */ };
    this.dateHandlerNG = function(dts) { /* ... */ };
    this.sortMap = function(arr, key) { return arr.sort(function(a,b){ return (a[key] > b[key]) ? 1 : -1; }); };
    this.makeMap = function(arr, key) {
        var map = {}; angular.forEach(arr, function(item){ map[item[key]] = true; }); return map;
    };
});

angular.module('myPluginApp').service('myPluginUnique', function() {
    this.simpleObjArray = function(primeArray, keyname) {
        var output = [], keys = [];
        angular.forEach(primeArray, function(item) {
            var key = item[keyname];
            if (keys.indexOf(key) === -1) { keys.push(key); output.push(item); }
        });
        return output;
    };
});

// 4. Directives
angular.module('myPluginApp').directive('myPluginNavigation', ['$http', '$compile',
    function ($http, $compile) {
        return {
            restrict: 'E',
            template: '<div ng-include="\'navigation.html\'"></div>',
            link: function (scope) {
                // Fetch nav data
            }
        };
    }]);
```

### 5. Add Inline Templates
In `home.html`, add `<script type="text/ng-template">` blocks:

```html
<script type="text/ng-template" id="navigation.html">
    <nav>
        <ul>
            <li ng-repeat="item in navItems"><a ng-href="{{item.url}}">{{item.name}}</a></li>
        </ul>
    </nav>
</script>

<script type="text/ng-template" id="myTemplate.html">
    <!-- Your template HTML -->
</script>
```

### 6. Set Page Security Bitmask
In the TCL registration block (before `<body>`):

```html
~(f.field_set;name=[pages]security;value=000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
```

Change `0` to `1` at positions matching PowerSchool group IDs that need access.

### 7. Create Data Endpoint
Create `/admin/myPlugin/data/myData.json`:
```json
[
  {"id": 1, "name": "Item 1", "active": true},
  {"id": 2, "name": "Item 2", "active": false}
]
```

### 8. Test
1. Navigate to `https://your-ps-domain/admin/myPlugin/home.html`
2. Verify Angular bootstraps (no console errors)
3. Verify data loads
4. Test interactions

## Bootstrap Trigger Note
Test both:
- With `data-require-path="/admin/myPlugin/app/bootstrap.js?~[time]"` (create empty bootstrap.js)
- Without `data-require-path`

Use whichever works in your environment.

## Common Issues

| Issue | Fix |
|-------|-----|
| Angular not bootstrapping | Check `data-module-name="myPluginApp"` matches module name |
| Templates not loading | Verify `ng-include` paths match `id` in `ng-template` |
| $http 404 | Ensure data file exists at `/admin/myPlugin/data/...` |
| CORS / auth errors | Use relative paths, POST method, form-urlencoded header |
| Flash of uncompiled HTML | Ensure `ng-cloak` on bootstrap `<div>` |

## When to Graduate
Move to Hybrid pattern when:
- Templates exceed 50 lines each
- Multiple developers editing
- Need to share templates across pages
- JS exceeds ~200 lines