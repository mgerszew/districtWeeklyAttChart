# Production Deployment Instructions

## Manual Security Registration

This plugin uses a manual security registration step for production deployments to prevent accidental page registration in development environments.

### When deploying to production:

1. **Edit** `/admin/{plugin}/home.html` and add this line before `<body>`:
   ```html
   ~[include file="/admin/{plugin}/page_registration.html"]
   ```

2. **Create** `/admin/{plugin}/page_registration.html` using the template below, then update the security bitmask:
   - The bitmask is a 160-character string where each position corresponds to a PowerSchool group ID (1-indexed)
   - Change `0` to `1` for groups that should have access to this page
   - Consult your PowerSchool admin for correct group IDs

3. **Replace** `{plugin}` with your plugin short name in **both files**

4. **Deploy** the updated files to production

---

### Template: `/admin/{plugin}/page_registration.html`

```html
<!-- PRODUCTION ONLY: Include this file in home.html when deploying to production -->
<!-- Add to home.html before <body>: ~[include file="/admin/{plugin}/page_registration.html"] -->
<!-- Replace {plugin} with your plugin short name in both files before deploying -->

<!-- Page cataloging auto-registration (PowerSchool TCL) -->
~[if.~(f.table_info;table=pages;fn=count;dothisfor=all;*path={plugin}/home.html)=0]
    ~(f.table_sel;table=pages;fn=create_rec)
    ~(f.field_set;name=[pages]path;value={plugin}/home.html)
    ~(f.field_set;name=[pages]security;value=00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)
    ~[f.table_sel;table=pages;fn=save_rec]
    ~[f.table_sel;table=pages;fn=unload_rec]
[/if]
```

---

### Development / Sandbox

- Do **not** add the include line to `home.html`
- Do **not** create `page_registration.html`
- The page will not be registered in the `pages` table
- No security permissions are applied
- Access via direct URL only

### Reverting Access

To remove production access:
1. Update permissions directly in PowerSchool's `pages` table
2. No code change or redeploy required

### Student-Facing Pages

For pages under `/admin/students/{plugin}/`, repeat the same steps:
1. Create `/admin/students/{plugin}/page_registration.html` using the template above (update the path from `{plugin}/home.html` to `students/{plugin}/home.html`)
2. Add include to `/admin/students/{plugin}/home.html` before `<body>`
3. Update bitmask and deploy

**Note:** `/teachers/{plugin}/` pages do **not** need this include — only pages on `/admin/` path.