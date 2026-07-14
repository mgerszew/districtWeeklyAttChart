# PowerSchool Oracle SQL Reference — Contacts Queries

Source: `docs/powerschool/PowerSchool_Oracle_Query_Reference.md` (lines 129-249)

---

## Query Inventory

| # | Query File | Purpose | Key Tables |
|---|------------|---------|------------|
| 1 | Contacts - Custom fields different from current Mobile contact.sql | Find contacts where custom phone ≠ mobile contact | PERSONPHONENUMBERASSOC, CODESET, PHONENUMBER, students, STUDENTCONTACTASSOC, ORIGINALCONTACTMAP, U_STUDENTS_BPS |
| 2 | Contacts - Cellphone export.sql | Export highest-priority mobile per student-contact | Same as #1 + STUDENTCONTACTDETAIL |
| 3 | Contact Mobile Validation to custom.sql | Validate mobile matches BPS custom field | OriginalContactMap, studentcontactassoc, studentcontactdetail, person, students, U_STUDENTS_BPS, personphonenumberassoc, phonenumber, codeset |
| 4 | Contact Flags.sql | Custodial/pickup/emergency flags per contact | OriginalContactMap, studentcontactassoc, studentcontactdetail, codeset, students, U_STUDENTS_BPS |
| 5 | Cellphone to Contacts Query.sql | Mismatches between BPS cellphone and contact phones | Same as #3 + PERSONPHONENUMBERASSOC, subquery pMobileCnt |
| 6 | Contacts for Clever.sql | Clever roster export with contacts | students, Terms, S_ND_STU_X, U_STUDENTS_BPS, studentContacts (derived), studentContactAssoc, studentContactDetail, person, personemailaddressassoc, emailaddress, PCAS_EMAILCONTACT, codeset |
| 7 | Contacts - PersonAddress Students.sql | Student addresses with type (home/mailing) | students, PERSON, PERSONADDRESSASSOC, PERSONADDRESS, CODESET |
| 8 | Guardian table records without Contact Associations.sql | Orphaned guardians (no StudentContactAssoc) | GUARDIANPERSONASSOC, guardianstudent, students, STUDENTCONTACTASSOC, STUDENTCONTACTDETAIL |
| 9 | Contacts for PQ DAT.sql | HTML-rich contact list for PowerQuery/Databricks | students, studentContactAssoc, studentContactDetail, person, codeset, personemails/phones/addr (derived), LISTAGG aggregation |
| 10 | Highest priority mobile contact.sql | Top-priority mobile per person (CTE for others) | PERSONPHONENUMBERASSOC, CODESET, PHONENUMBER |
| 11 | Mismatch cell phone fields.sql | BPS cellphone vs PERSONPHONENUMBER mismatch | person, OriginalContactMap, studentcontactassoc, studentcontactdetail, U_STUDENTS_BPS, personphonenumberassoc, phonenumber, codeset, PERSONPHONENUMBERASSOC |

---

## Core Contact Tables & Relationships

```
students
  └── PERSON (students.person_id = person.id)

person
  ├── PERSONPHONENUMBERASSOC (personid → person.id)
  │     ├── PHONENUMBER (phonenumberid → phonenumber.id)
  │     └── CODESET (phonetypecodesetid → codeset.codesetid)  -- 'Mobile', 'Home', etc.
  ├── PERSONEMAILADDRESSASSOC (personid → person.id)
  │     └── EMAILADDRESS (emailaddressid → emailaddress.id)
  └── PERSONADDRESSASSOC (personid → person.id)
        └── PERSONADDRESS (personaddressid → personaddress.id)
              └── CODESET (state_codesetid, addresstypecodesetid)

STUDENTCONTACTASSOC (studentdcid → students.dcid, personid → person.id)
  └── STUDENTCONTACTDETAIL (studentcontactassocid → studentcontactassoc.id)
        └── CODESET (relationship_codesetid, contact_priority_codesetid)

ORIGINALCONTACTMAP (personid → person.id, studentdcid → students.dcid)
  └── originalcontacttype IN ('guardian','father','mother',...)
```

---

## Key Join Patterns

```sql
-- Person to mobile phone (priority 1)
person p
INNER JOIN personphonenumberassoc ppna ON ppna.personid = p.id
INNER JOIN phonenumber pn ON pn.id = ppna.phonenumberid
INNER JOIN codeset cs ON cs.codesetid = ppna.phonetypecodesetid AND cs.code = 'Mobile'

-- Student to contacts (active only)
students s
INNER JOIN studentcontactassoc sca ON sca.studentdcid = s.dcid
INNER JOIN studentcontactdetail scd ON scd.studentcontactassocid = sca.studentcontactassocid AND scd.isactive = 1
INNER JOIN person cp ON cp.id = sca.personid
INNER JOIN codeset cr ON cr.codesetid = scd.relationship_codesetid  -- relationship type
INNER JOIN codeset cp ON cp.codesetid = scd.contact_priority_codesetid  -- priority

-- Guardian to contact association (find orphans)
guardianpersonassoc gpa
INNER JOIN guardianstudent gs ON gs.guardiandcid = gpa.guardianpersonid
INNER JOIN students s ON s.dcid = gs.studentsdcid
LEFT JOIN studentcontactassoc sca ON sca.personid = gpa.personid AND s.dcid = sca.studentdcid
WHERE sca.studentcontactassocid IS NULL AND s.enroll_status = 0
```

---

## Critical PowerSchool Quirks

| Quirk | Detail |
|-------|--------|
| **schoolid FK** | Most tables: `schoolid` → `SCHOOLS.school_number` (NOT `schools.schoolid` which is DCID) |
| **student DCID vs ID** | `students.dcid` = contact link; `students.id` = legacy student number |
| **PersonID** | Shared across person, guardian, contact tables |
| **CODESET codes** | Use `codeset.code` (e.g., 'Mobile') not displayvalue |
| **KEEP DENSE_RANK FIRST** | Oracle syntax for top-priority row per group |

---

## Top-Priority Mobile Pattern (Used in #1, #2, #3, #5, #10, #11)

```sql
WITH firstMobile AS (
  SELECT 
    ppna.personid,
    MAX(pn.phonenumber) KEEP (DENSE_RANK FIRST ORDER BY ppna.priority) AS mobile_phone
  FROM personphonenumberassoc ppna
  INNER JOIN phonenumber pn ON pn.id = ppna.phonenumberid
  INNER JOIN codeset cs ON cs.codesetid = ppna.phonetypecodesetid AND cs.code = 'Mobile'
  GROUP BY ppna.personid
)
SELECT * FROM firstMobile;
```

- `ppna.priority` = lower number = higher priority
- `KEEP (DENSE_RANK FIRST ORDER BY ppna.priority)` picks top-priority phone per person

---

## Phone Normalization Pattern (Used in #1, #3, #5, #11)

```sql
REPLACE(REPLACE(REPLACE(phone_number, '(', ''), ')', ''), '-', '') 
-- Also: REPLACE(phone_number, ' ', ''), REPLACE(phone_number, '.', '')
-- Compare normalized: DECODE(norm_custom, norm_mobile, 'Match', 'Mismatch')
```

---

## HTML Generation Pattern (Query #9 - PQ DAT)

```sql
LISTAGG(
  '<span class="phone">' || phonenumber || '</span>', 
  '<br/>'
) WITHIN GROUP (ORDER BY priority) AS phones_html,

'<i class="icon-' || CASE WHEN flag = 1 THEN 'check' ELSE 'times' END || '"></i>' AS flag_icon
```

---

## Clever Export Filters (Query #6)

```sql
WHERE s.enroll_status = 0  -- Active
   OR (s.enroll_status = -1 AND s.schoolid IN (40,41,42))  -- Pre-reg at specific schools
   AND s.schoolid BETWEEN 40 AND 89
```

---

## Parameterization (AGENTS.md §3)

- **No bind variables** — all use CTE `params` or hardcoded filters
- **No GPV tags** in these queries (mostly direct SQL exports)
- **Hardcoded school ranges**: `schoolid BETWEEN 40 AND 89`, `schoolid IN (84)` — move to CTE params

---

## Performance Flags

| Table | Risk | Mitigation |
|-------|------|------------|
| PERSONPHONENUMBERASSOC | Large, joined repeatedly | Index on (personid, phonetypecodesetid) |
| STUDENTCONTACTASSOC | Joined to person + detail | Filter `isactive = 1` early |
| PERSON | Core table, many joins | Index on id (PK) |
| LISTAGG (Query #9) | String aggregation | Limit with WHERE first, consider materialized view |

---

## Cross-References

- **Common patterns**: `reference/common-patterns.md` (CTE params, no binds)
- **Table schema**: `reference/tables-schema.md` (PERSON, STUDENTCONTACT*, CODESET)
- **Contacts template**: `templates/contacts-template.sql`