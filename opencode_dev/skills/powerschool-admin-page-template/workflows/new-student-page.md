# Workflow: Create New Admin Portal Student Page

## Prerequisites
- PowerSchool Admin Portal access
- PageSet/plugin development environment
- Familiarity with PSHTML/DAT tags

## Steps

### 1. Copy Template
```bash
cp templates/admin-student-page-template.pshtml pages/your_page_name.pshtml
```

### 2. Replace Placeholders

Edit `pages/your_page_name.pshtml`:

| Placeholder | Replace With |
|-------------|--------------|
| `TemplateName:Admin Student Page - [Page Name]` | `TemplateName:Admin Student Page - Your Page Name` |
| `<title>Enter Page Title Here</title>` | `<title>Your Page Title</title>` |
| Breadcrumb: `Enter Page Title Here` | `Your Page Title` |
| `~[wc:title_student_begin_css]Enter Page Title Here~[wc:title_student_end_css]` | `~[wc:title_student_begin_css]Your Page Title~[wc:title_student_end_css]` |
| `<h2>Section Title Text Goes Here</h2>` | `<h2>Your Section Title</h2>` |
| `<p>Your paragraph text goes here.</p>` | `<p>Your page description.</p>` |
| `value="prim"` | Appropriate action code (`prim`, `upd`, etc.) |

### 3. Add Form Fields

Insert between `<div class="box-round">` and `<div class="button-row">`:

```html
<!-- Example fields -->
<table class="grid">
    <tr>
        <th><label for="field_name">Field Label</label></th>
        <td><input type="text" name="field_name" id="field_name" value="~(field_name)"></td>
    </tr>
    <tr>
        <th><label for="select_field">Select Field</label></th>
        <td>
            <select name="select_field" id="select_field">
                <option value="">-- Select --</option>
                <option value="opt1" ~[if.~(select_field)=opt1]selected[/if]>Option 1</option>
                <option value="opt2" ~[if.~(select_field)=opt2]selected[/if]>Option 2</option>
            </select>
        </td>
    </tr>
</table>
```

### 4. Handle Form Actions

**For create-only page:**
```html
<input type="hidden" name="ac" value="prim">
```

**For edit page (conditional):**
```html
~[if.~(ac)=upd]
    <input type="hidden" name="id" value="~(id)">
[/if]
<input type="hidden" name="ac" value="~[if.~(ac)]~(ac)[else]prim[/if]">
```

### 5. Add tlist_sql (If Needed)

See `workflows/add-tlist-sql.md` for embedding queries.

### 6. Register in plugin.xml (If New PageSet)

See `workflows/register-plugin-xml.md` for plugin.xml entry.

### 7. Test

1. Deploy to sandbox
2. Navigate to student page
3. Select student
4. Access your page via URL or navigation
5. Test form submit
6. Verify success message appears

### 8. Common Issues

| Issue | Fix |
|-------|-----|
| Student context lost | Ensure `frn=~(studentfrn)` in form action |
| Success message not showing | Check `changesSaved=true` in redirect URL |
| Tags not rendering | Verify `~[wc:commonscripts]` in `<head>` |
| Form not submitting | Check `method="POST"` and action URL |

## Checklist

- [ ] Template copied and renamed
- [ ] All 5 title placeholders replaced
- [ ] Section heading updated
- [ ] Description paragraph updated
- [ ] Form fields added
- [ ] Action code set correctly
- [ ] Hidden `id` field for edit mode
- [ ] Student FRN in form action
- [ ] Success message conditional present
- [ ] Submit button uses `~[submitbutton]`
- [ ] Tested in sandbox