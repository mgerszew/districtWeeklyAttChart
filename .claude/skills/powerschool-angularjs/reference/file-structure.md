# File Structure — Production vs Development Paths

Scripts and assets location conventions.

## Directory Structure

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

## Path Rules

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

## Path Usage in Code

### Production (AMD modules in `/scripts/components/{plugin}/`)

```javascript
// In controller/service/directive AMD define
var app = require('/scripts/components/{plugin}/app/app.js');

// In directive link function
scope.contentUrl = "/scripts/components/{plugin}/templates/navigation.html";
```

### Development (Inline/Hybrid in `/admin/{plugin}/`)

```javascript
// In home.html inline script - no AMD wrapper needed
angular.module('{plugin}App').controller(...);

// In directive template (hybrid pattern)
template: '<div ng-include="\'/admin/{plugin}/templates/navigation.html\'"></div>'

// In directive link (fetching data)
$http({ url: '/admin/{plugin}/data/plugins.json', method: 'POST', ... })
```

### Data Endpoints (Same in Both)

```javascript
$http({
    url: '/admin/{plugin}/data/installed_plugins.json',
    method: 'POST',
    headers: {'Content-Type': 'application/x-www-form-urlencoded'}
})
```

### Cache-Busting

| Environment | Method |
|-------------|--------|
| **Production HTML** | `?~[time]` on `data-require-path` |
| **Production AMD** | `require.config({ urlArgs: "bust=v2" + Math.random() * 2 })` in app.js |
| **Development Inline** | Not needed (inline in HTML) |
| **Data JSON** | POST requests not cached |

## Bootstrap Paths

### Production
```html
<div data-require-path="/scripts/components/{plugin}/app/controllers/main.controller.js?~[time]"
     data-module-name="{plugin}App" ng-cloak>
```

### Development (Test Both)
```html
<!-- Option A: With bootstrap trigger file -->
<div data-require-path="/admin/{plugin}/app/bootstrap.js?~[time]"
     data-module-name="{plugin}App" ng-cloak>

<!-- Option B: Without data-require-path -->
<div data-module-name="{plugin}App" ng-cloak>
```

## Key Points

- **Production**: AMD modules under `/scripts/components/{plugin}/` — these are what PowerSchool serves in production
- **Development**: Work in `/admin/{plugin}/` for cache-busting and easier editing
- **Templates**: Match the path pattern in your `ng-include` or directive `template`
- **Data**: Always served from `/admin/{plugin}/data/` via POST
- **Sync**: When deploying, copy `/admin/{plugin}/app/` → `/scripts/components/{plugin}/app/` and `/admin/{plugin}/templates/` → `/scripts/components/{plugin}/templates/`