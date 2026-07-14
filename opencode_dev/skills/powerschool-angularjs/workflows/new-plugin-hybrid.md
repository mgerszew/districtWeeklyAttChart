# Workflow: Create New Plugin (Hybrid Pattern - Inline Logic + External Templates)

**Use when**: Multi-template page, team development, < 1000 lines JS  
**Output**: `/admin/{plugin}/home.html` with inline logic + external templates in `/admin/{plugin}/templates/`

## Prerequisites
- PowerSchool Admin Portal access
- Sandbox/dev environment
- Plugin folder name decided (e.g., `myPlugin`)

## Steps

### 1. Create Plugin Directory Structure
```bash
mkdir -p /admin/myPlugin/templates /admin/myPlugin/data /admin/myPlugin/css /admin/myPlugin/images
```

### 2. Copy Hybrid Template
```bash
cp templates/hybrid/home.html /admin/myPlugin/home.html
cp templates/hybrid/navigation.html /admin/myPlugin/templates/navigation.html
```

### 3. Replace Placeholders in home.html
Edit `/admin/myPlugin/home.html`:

| Placeholder | Replace With |
|-------------|--------------|
| `{plugin}` | `myPlugin` |
| `{Plugin Name}` | `My Plugin` |
| `{SECURITY_BITMASK}` | 64-char bitmask |
| Navigation data | Your report/tool items |

### 4. Replace Placeholders in navigation.html
Edit `/admin/myPlugin/templates/navigation.html`:
- Update navigation structure
- Keep `ng-repeat` and `ng-if` bindings

### 5. Configure Page Registration
In `home.html` before `<body>`:

```html
~[if.~(f.table_info;table=pages;fn=count;dothisfor=all;*path=myPlugin/home.html)=0]
    ~(f.table_sel;table=pages;fn=create_rec)
    ~(f.field_set;name=[pages]path;value=myPlugin/home.html)
    ~(f.field_set;name=[pages]security;value=000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
    ~[f.table_sel;table=pages;fn=save_rec]
    ~[f.table_sel;table=pages;fn=unload_rec]
[/if]
```

**Set security bitmask**: 64-char string, position = PowerSchool group ID. Change `0` to `1` for groups with access.

### 6. Add Data Endpoints
Create JSON files in `/admin/myPlugin/data/`:
```bash
cat > /admin/myPlugin/data/plugins.json << 'EOF'
{
  "reports": [
    {"name": "Student Report", "url": "/admin/myPlugin/studentReport.html", "active": true}
  ],
  "tools": [
    {"name": "Data Tool", "url": "/admin/myPlugin/dataTool.html", "active": true}
  ]
}
EOF
```

### 7. Test Bootstrap
Open: `https://your-powerschool/admin/myPlugin/home.html`

**Test both modes:**
1. With `data-require-path="/admin/myPlugin/app/bootstrap.js?~[time]"` (create empty bootstrap.js)
2. Without `data-require-path` attribute

### 8. Verify Functionality
- [ ] Page loads, no console errors
- [ ] Navigation renders from template
- [ ] Data loads via $http POST
- [ ] Template path resolves: `/admin/myPlugin/templates/navigation.html`
- [ ] Date handling works
- [ ] Filter maps generate

### 9. Add More Templates (As Needed)
```bash
# Create new template
cat > /admin/myPlugin/templates/reportList.html << 'EOF'
<div class="report-list">
    <h3>Available Reports</h3>
    <ul>
        <li ng-repeat="report in reports">
            <a ng-href="{{report.url}}">{{report.name}}</a>
        </li>
    </ul>
</div>
EOF
```

Update directive in home.html:
```javascript
template: '<div ng-include="\'/admin/myPlugin/templates/reportList.html\'"></div>',
```

### 10. Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Template 404 | Check path in `ng-include` matches `/admin/myPlugin/templates/filename.html` |
| $http fails | Verify POST + form-urlencoded header; check data file exists |
| Bootstrap not working | Test with/without `data-require-path`; ensure `data-module-name` matches module |
| Date shows string | Wrap in `new Date()` in controller |
| ng-cloak flash | Ensure on bootstrap div with `data-module-name` |

## Template Structure (Reference)

### home.html contains:
1. **Head**: PS tags, page registration, CSS
2. **Bootstrap div**: `data-module-name`, optional `data-require-path`, `ng-cloak`
3. **Inline `<script>`**: Module, controller, services, directives
4. **Directives reference** external templates via `ng-include`

### External templates in `/admin/myPlugin/templates/`:
- `navigation.html` — main navigation
- `navigationSearch.html` — search dropdown
- Add more as needed

## Key Differences from Inline Pattern

| Aspect | Inline | Hybrid |
|--------|--------|--------|
| Templates | `<script type="text/ng-template">` | External files in `/templates/` |
| Template loading | `ng-include="'templateId.html'"` | `ng-include="'/admin/plugin/templates/file.html'"` |
| Team dev | Hard (merge conflicts in one file) | Easier (separate template files) |
| Cache busting | Not needed | Browser may cache templates; add `?v=timestamp` if needed |
| Production move | Convert all to AMD | Convert logic to AMD, templates to production path |

## Moving to Production (When Ready)

1. **Extract JS to AMD modules**:
   - `/admin/myPlugin/app/app.js` → `/scripts/components/myPlugin/app/app.js`
   - Controllers, services, directives → respective folders
   - Wrap in `define(function(require) { ... })`

2. **Move templates**:
   - `/admin/myPlugin/templates/` → `/scripts/components/myPlugin/templates/`

3. **Update home.html**:
   - Remove inline `<script>` block
   - Update `data-require-path` to production controller path
   - Update directive `ng-include` paths to production template paths

4. **Test in production-like environment**

## Next Steps
- Add more pages under `/admin/myPlugin/`
- Create student-facing: `/admin/students/myPlugin/`
- Create teacher-facing: `/teachers/myPlugin/`
- Add to plugin.xml if creating PageSet