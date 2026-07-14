# PowerSchool Form Action Codes Reference

## Overview
Form actions in PowerSchool Admin Portal are controlled by the hidden `ac` (action code) input field. The value determines what server-side logic executes when the form is submitted.

## Standard Action Codes

| Code | Name | HTTP Method | Typical Use | Server Behavior |
|------|------|-------------|-------------|-----------------|
| `prim` | Primary/Insert | POST | Create new record | Inserts new row, redirects to list or edit |
| `upd` | Update | POST | Edit existing record | Updates existing row, shows success message |
| `del` | Delete | POST | Delete record | Deletes row, redirects to list |
| `cpy` | Copy | POST | Duplicate record | Creates copy, opens edit mode |
| `view` | View | GET | Read-only display | Shows read-only form |
| `list` | List | GET | Return to list | Redirects to list page |

## Form Structure

### Standard Form Tag
```html
<form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
```

### Hidden Action Input
```html
<input type="hidden" name="ac" value="prim">
```

### Complete Minimal Form
```html
<form action="/~[self.page]?frn=~(studentfrn)&changesSaved=true" method="POST">
    <input type="hidden" name="ac" value="prim">
    <!-- form fields here -->
    <div class="button-row">~[submitbutton]</div>
</form>
```

## Action-Specific Patterns

### Create New Record (`prim`)
```html
~[if.~(ac)=prim]
    <h2>Add New Record</h2>
[/if]
<input type="hidden" name="ac" value="prim">
```
- No ID field needed
- On success: redirects with `changesSaved=true`

### Edit Existing Record (`upd`)
```html
~[if.~(ac)=upd]
    <input type="hidden" name="id" value="~(id)">
    <h2>Edit Record</h2>
[/if]
<input type="hidden" name="ac" value="upd">
```
- Requires hidden `id` field with record primary key
- Pre-populates form fields with existing data

### Delete Record (`del`)
```html
~[if.~(ac)=del]
    <input type="hidden" name="id" value="~(id)">
    <h2>Delete Record</h2>
    <p>Are you sure you want to delete this record?</p>
[/if]
<input type="hidden" name="ac" value="del">
```
- Requires confirmation (typically separate confirm page or JS confirm)
- Redirects to list page after deletion

### Copy Record (`cpy`)
```html
~[if.~(ac)=cpy]
    <input type="hidden" name="copy_id" value="~(id)">
    <h2>Copy Record</h2>
[/if]
<input type="hidden" name="ac" value="cpy">
```
- Uses `copy_id` to identify source record
- Opens form with copied data, saves as new on submit

## Form Submission Flow

```
User submits form
       ↓
Server receives POST with ac=prim/upd/del/cpy
       ↓
Validates input
       ↓
Executes action (INSERT/UPDATE/DELETE)
       ↓
Redirects to same page with ?changesSaved=true
       ↓
Page loads, shows success message via:
    ~[if.~(gpv.changesSaved)=true]
        <div class="feedback-confirm">~[text:psx.common.changes_recorded]</div>
    [/if]
```

## URL Parameters

| Parameter | Source | Purpose |
|-----------|--------|---------|
| `frn` | `~(studentfrn)` | Student context (FRN) |
| `changesSaved` | Added on redirect | Triggers success message |
| `ac` | Hidden form field | Action code |
| `id` | Hidden form field | Record ID (for upd/del/cpy) |
| `gpv.*` | URL query string | Get Parameter Values |

## JavaScript Form Handling

```javascript
// Set action before submit
function setAction(action) {
    $j('input[name="ac"]').val(action);
    $j('form').submit();
}

// Confirm delete
$j('.delete-btn').on('click', function(e) {
    if (!confirm('Are you sure?')) {
        e.preventDefault();
        return false;
    }
    setAction('del');
});
```

## Common Field Names

| Field | Purpose | Used With |
|-------|---------|-----------|
| `ac` | Action code | All |
| `id` | Primary key | upd, del, cpy |
| `copy_id` | Source record ID | cpy |
| `frn` | Student FRN | All (URL param) |
| `changesSaved` | Success flag | URL param (server-set) |

## Best Practices

1. **Always include `frn=~(studentfrn)`** in form action URL
2. **Use `changesSaved=true`** redirect pattern for success messages
3. **Conditional action field** based on mode:
   ```html
   <input type="hidden" name="ac" value="~[if.~(ac)]~(ac)[else]prim[/if]">
   ```
4. **Validate on server** - client-side validation is supplemental only
5. **Use `~[submitbutton]`** for consistent localized button text