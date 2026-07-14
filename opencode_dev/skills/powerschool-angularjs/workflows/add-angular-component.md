# Workflow: Add Angular Component to Existing Plugin

Add a controller, service, or directive to an existing Inline or Hybrid plugin.

## Prerequisites
- Existing plugin using Inline or Hybrid pattern
- Know plugin folder name (e.g., `myPlugin`)

---

## Add a Controller

### Inline Pattern
Edit `home.html`, add to `<script>` block:

```javascript
angular.module('myPluginApp').controller('MyNewController',
    ['$scope', '$http', '$compile', 'myPluginGeneral', 'myPluginUnique',
    function ($scope, $http, $compile, general, unique) {
        $scope.newData = [];
        
        $scope.loadData = function() {
            $http({
                url: '/admin/myPlugin/data/newData.json',
                method: 'POST',
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}
            }).then(function(response) {
                $scope.newData = response.data;
            });
        };
        
        $scope.loadData();
    }]);
```

Use in HTML:
```html
<div ng-controller="MyNewController">
    <ul>
        <li ng-repeat="item in newData">{{item.name}}</li>
    </ul>
</div>
```

### Hybrid Pattern
Same as inline - add to `home.html` `<script>` block.

---

## Add a Service

### Inline/Hybrid Pattern
Edit `home.html`, add to `<script>` block:

```javascript
angular.module('myPluginApp').service('myPluginNewService', ['$http', function($http) {
    this.fetchItems = function(filter) {
        return $http({
            url: '/admin/myPlugin/data/items.json',
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'}
        }).then(function(response) {
            var items = response.data;
            if (filter) {
                items = items.filter(function(item) {
                    return item.category === filter;
                });
            }
            return items;
        });
    };
    
    this.saveItem = function(item) {
        return $http({
            url: '/admin/myPlugin/api/saveItem',  // Custom endpoint
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            data: $.param(item)  // jQuery param serialization
        });
    };
}]);
```

### Inject in Controller
```javascript
angular.module('myPluginApp').controller('MyController',
    ['$scope', '$http', 'myPluginNewService', function($scope, $http, newService) {
        newService.fetchItems('active').then(function(items) {
            $scope.items = items;
        });
    }]);
```

---

## Add a Directive

### Inline Pattern
Edit `home.html`, add to `<script>` block:

```javascript
// With inline template (ng-template)
angular.module('myPluginApp').directive('myPluginItemList', ['$http', '$compile',
    function ($http, $compile) {
        return {
            restrict: 'E',
            scope: {
                filter: '='
            },
            template: '<div ng-include="\'itemList.html\'"></div>',
            link: function (scope, element, attrs) {
                scope.contentUrl = 'itemList.html';  // matches ng-template id
                
                scope.$watch('filter', function(newVal) {
                    if (newVal) {
                        $http({
                            url: '/admin/myPlugin/data/items.json',
                            method: 'POST',
                            headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                        }).then(function(response) {
                            scope.items = response.data.filter(function(item) {
                                return item.category === newVal;
                            });
                        });
                    }
                });
            }
        };
    }]);
```

Add template:
```html
<script type="text/ng-template" id="itemList.html">
    <div class="item-list">
        <div ng-repeat="item in items">
            <span>{{item.name}}</span>
            <span class="category">{{item.category}}</span>
        </div>
    </div>
</script>
```

### Hybrid Pattern
Edit `home.html`, add to `<script>` block:

```javascript
angular.module('myPluginApp').directive('myPluginItemList', ['$http', '$compile',
    function ($http, $compile) {
        return {
            restrict: 'E',
            scope: {
                filter: '='
            },
            template: '<div ng-include="\'/admin/myPlugin/templates/itemList.html\'"></div>',
            link: function (scope, element, attrs) {
                scope.$watch('filter', function(newVal) {
                    if (newVal) {
                        $http({
                            url: '/admin/myPlugin/data/items.json',
                            method: 'POST',
                            headers: {'Content-Type': 'application/x-www-form-urlencoded'}
                        }).then(function(response) {
                            scope.items = response.data.filter(function(item) {
                                return item.category === newVal;
                            });
                        });
                    }
                });
            }
        };
    }]);
```

Create external template:
```bash
cat > /admin/myPlugin/templates/itemList.html << 'EOF'
<div class="item-list">
    <div ng-repeat="item in items">
        <span>{{item.name}}</span>
        <span class="category">{{item.category}}</span>
    </div>
</div>
EOF
```

### Use Directive
```html
<my-plugin-item-list filter="selectedCategory"></my-plugin-item-list>
```

---

## Naming Conventions

| Component | Variable Name | HTML Usage |
|-----------|---------------|------------|
| Module | `myPluginApp` | `data-module-name="myPluginApp"` |
| Controller | `MyController` | `ng-controller="MyController"` |
| Service | `myPluginNewService` | Inject as `'myPluginNewService'` |
| Directive | `myPluginItemList` | `<my-plugin-item-list>` |

---

## Data Endpoint for New Component

Create `/admin/myPlugin/data/newData.json`:
```json
[
  {"id": 1, "name": "New Item 1", "category": "active"},
  {"id": 2, "name": "New Item 2", "category": "inactive"}
]
```

---

## Testing Checklist

- [ ] No console errors on page load
- [ ] New component loads data
- [ ] Template renders correctly
- [ ] Scope bindings work (if directive with isolate scope)
- [ ] Service methods return promises handled correctly
- [ ] ng-cloak prevents flash (if new bootstrap element)

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting array notation for DI | Use `['$scope', '$http', fn]` not `fn($scope, $http)` |
| Using `$` instead of `$j` | Use `$j` or inject `$http` |
| ES6 syntax | Use `function() {}` and `var` |
| GET for data | Always `POST` with form-urlencoded |
| Missing `ng-cloak` | Add to bootstrap element |
| Template path wrong | Hybrid: `/admin/plugin/templates/...`; Inline: `ng-template` id |