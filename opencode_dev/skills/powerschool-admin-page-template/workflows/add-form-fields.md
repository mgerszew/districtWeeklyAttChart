# Workflow: Add Form Fields to Existing Page

## Overview
Add form input fields to an existing PowerSchool Admin Portal student page.

## Prerequisites
- Existing `.pshtml` page file
- Understanding of form action (`prim`/`upd`)

## Field Types

### Text Input
```html
<div class="form-row">
    <label for="field_name">Label:</label>
    <input type="text" name="field_name" id="field_name" value="~(field_name)" maxlength="100">
</div>
```

### Textarea
```html
<div class="form-row">
    <label for="notes">Notes:</label>
    <textarea name="notes" id="notes" rows="4" cols="60">~(notes)</textarea>
</div>
```

### Select Dropdown
```html
<div class="form-row">
    <label for="status">Status:</label>
    <select name="status" id="status">
        <option value="Active" ~([status]=Active)selected[/]>Active</option>
        <option value="Inactive" ~([status]=Inactive)selected[/]>Inactive</option>
        <option value="Pending" ~([status]=Pending)selected[/]>Pending</option>
    </select>
</div>
```

### Checkbox
```html
<div class="form-row">
    <input type="checkbox" name="is_active" id="is_active" value="1" ~([is_active]=1)checked[/]>
    <label for="is_active">Active</label>
</div>
```

### Radio Buttons
```html
<div class="form-row">
    <label>Type:</label>
    <input type="radio" name="contact_type" id="type_home" value="Home" ~([contact_type]=Home)checked[/]>
    <label for="type_home">Home</label>
    <input type="radio" name="contact_type" id="type_work" value="Work" ~([contact_type]=Work)checked[/]>
    <label for="type_work">Work</label>
    <input type="radio" name="contact_type" id="type_mobile" value="Mobile" ~([contact_type]=Mobile)checked[/]>
    <label for="type_mobile">Mobile</label>
</div>
```

### Hidden Field
```html
<input type="hidden" name="record_id" value="~(record_id)">
```

### Date Picker
```html
<div class="form-row">
    <label for="contact_date">Date:</label>
    <input type="text" name="contact_date" id="contact_date" value="~(contact_date)" class="date-picker" size="10">
</div>
<script>
$j(function() {
    $j('.date-picker').datepicker({ dateFormat: 'mm/dd/yy' });
});
</script>
```

### Readonly Display
```html
<div class="form-row">
    <label>Created:</label>
    <span class="readonly">~(created_date)</span>
</div>
```

## Pre-populating Values

### For Edit (upd) Action
Values come from database query. Use `tlist_sql` to populate:

```html
~[tlist_sql:get_record]
    SELECT field1, field2, field3
    FROM your_table
    WHERE id = ~(record_id)
[/tlist_sql]

<input type="text" name="field1" value="~(field1)">
<input type="text" name="field2" value="~(field2)">
```

### For Create (prim) Action
Values are empty or defaults:
```html
<input type="text" name="field1" value="">
<select name="status">
    <option value="Active" selected>Active</option>
    ...
</select>
```

## Conditional Fields

Show different fields based on action:
```html
~[if.~(ac)=upd]
    <input type="hidden" name="id" value="~(id)">
    <div class="form-row">
        <label>Created:</label>
        <span>~(created_date)</span>
    </div>
[/if]

~[if.~(ac)=prim]
    <div class="form-row">
        <label>Status:</label>
        <select name="status">
            <option value="Active" selected>Active</option>
            ...
        </select>
    </div>
[/if]
```

## Form Layout

### Grid/Table Layout
```html
<table class="grid">
    <tr>
        <th>Field</th>
        <th>Value</th>
    </tr>
    <tr>
        <td><label for="name">Name:</label></td>
        <td><input type="text" name="name" id="name" value="~(name)"></td>
    </tr>
    <tr>
        <td><label for="email">Email:</label></td>
        <td><input type="email" name="email" id="email" value="~(email)"></td>
    </tr>
</table>
```

### Side-by-Side (CSS)
```html
<div class="form-row two-column">
    <div class="field-half">
        <label for="first_name">First Name:</label>
        <input type="text" name="first_name" id="first_name" value="~(first_name)">
    </div>
    <div class="field-half">
        <label for="last_name">Last Name:</label>
        <input type="text" name="last_name" id="last_name" value="~(last_name)">
    </div>
</div>
```

## Validation (Client-Side)

Add to page script:
```html
<script>
$j(function() {
    $j('form').on('submit', function(e) {
        var valid = true;
        $j(this).find('[required]').each(function() {
            if (!$j(this).val().trim()) {
                $j(this).addClass('error');
                valid = false;
            } else {
                $j(this).removeClass('error');
            }
        });
        if (!valid) {
            e.preventDefault();
            alert('Please fill in all required fields.');
        }
    });
});
</script>
```

## Checklist

- [ ] Fields placed inside `<div class="box-round">` before `<div class="button-row">`
- [ ] Each input has `name` attribute matching server parameter
- [ ] Value attributes use `~(field_name)` for pre-population
- [ ] Checkboxes/radios use `~([field]=value)checked[/]` for selection
- [ ] Select options use `~([field]=value)selected[/]`
- [ ] Labels linked with `for`/`id`
- [ ] Required fields marked (server-side validation still needed)
- [ ] Hidden `ac` field present with correct action code