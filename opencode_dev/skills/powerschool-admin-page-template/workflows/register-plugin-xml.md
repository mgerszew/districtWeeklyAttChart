# Workflow: Register Page in plugin.xml

## Overview
Register a new Admin Portal student page in plugin.xml. Only do this if explicitly asked or if page doesn't exist in plugin.xml.

## When to Register

| Situation | Action |
|-----------|--------|
| New page, not in plugin.xml | Register |
| Page already in plugin.xml | Update values only |
| Modifying existing page | No registration needed |
| Adding form fields | No registration needed |

## Step 1: Check Existing plugin.xml

Open your plugin's `plugin.xml` and search for:
```xml
<page>
    <name>your_page_name</name>
</page>
```

If found, **only edit values** - don't duplicate.

## Step 2: Add Page Entry

Add inside `<plugin>` element:

```xml
<page>
    <name>page_name</name>
    <path>/admin/students/page_name.pshtml</path>
    <description>Page Description</description>
    <permission>permission_name</permission>
</page>
```

### Fields

| Field | Value | Notes |
|-------|-------|-------|
| `<name>` | `page_name` | Must match .pshtml filename (without extension) |
| `<path>` | `/admin/students/page_name.pshtml` | Full path from web root |
| `<description>` | `Page Description` | Shows in admin UI |
| `<permission>` | `permission_name` | Must match permission entry |

## Step 3: Add Permission Entry

```xml
<permission>
    <name>permission_name</name>
    <description>View/Edit Page Description</description>
    <default>false</default>
</permission>
```

### Fields

| Field | Value | Notes |
|-------|-------|-------|
| `<name>` | `permission_name` | Matches page's permission |
| `<description>` | `View/Edit Page Description` | Admin UI label |
| `<default>` | `false` | Off by default (recommended) |

## Step 4: Verify Structure

plugin.xml should have this order:
```xml
<plugin>
    <publisher>...</publisher>
    <pluginname>...</pluginname>
    <description>...</description>
    <version>...</version>
    <pluginid>...</pluginid>
    
    <!-- Pages -->
    <page>...</page>
    <page>...</page>
    
    <!-- Permissions -->
    <permission>...</permission>
    <permission>...</permission>
    
    <!-- Tables (if custom) -->
    <table>...</table>
</plugin>
```

## Step 5: Deploy & Test

1. Deploy plugin to PowerSchool
2. Go to **System > Plugin Management > [Your Plugin]**
3. Verify page appears in page list
4. Assign permission to test user
5. Navigate to student page
6. Verify page loads with student context

## Common Issues

| Issue | Fix |
|-------|-----|
| Page not in admin | Check `<path>` starts with `/admin/students/` |
| Permission denied | Assign permission to user role |
| Student context lost | Ensure `frn=~(studentfrn)` in form action |
| Duplicate entry | Remove duplicate, keep one |

## Checklist

- [ ] Page not already in plugin.xml
- [ ] `<name>` matches .pshtml filename
- [ ] `<path>` correct: `/admin/students/[name].pshtml`
- [ ] `<permission>` matches permission entry name
- [ ] Permission entry added with `<default>false</default>`
- [ ] XML well-formed (no duplicate tags)
- [ ] Plugin deployed and loaded
- [ ] Permission assigned to test role
- [ ] Page accessible in Admin Portal