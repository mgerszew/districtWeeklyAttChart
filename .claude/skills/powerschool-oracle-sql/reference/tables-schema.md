# PowerSchool Oracle SQL — Key Table Schema Reference

Extracted from query patterns in `PowerSchool_Oracle_Query_Reference.md`

---

## Core Tables

### students
| Column | Type | Notes |
|--------|------|-------|
| dcid | NUMBER | PK; use for joins to contact/enrollment tables |
| id | VARCHAR2 | Student number (legacy); use for cc.studentid |
| lastfirst | VARCHAR2 | 'Last, First' |
| first_name / last_name | VARCHAR2 | |
| grade_level | NUMBER | -2 to 12 |
| schoolid | NUMBER | → **schools.school_number** (not schoolid!) |
| entrydate / exitdate | DATE | |
| enroll_status | NUMBER | 0=active, -1=pre-reg, >0=inactive |
| ethnicity | NUMBER | FK to gen (cat='federalrace') |
| gender | VARCHAR2 | 'M'/'F' |
| dob | DATE | |
| person_id | NUMBER | → PERSON.id |

### schools
| Column | Type | Notes |
|--------|------|-------|
| school_number | NUMBER | **FK target for most schoolid columns** |
| schoolid | NUMBER | Internal DCID (different!) |
| name | VARCHAR2 | |
| schoolcategorycodesetid | NUMBER | → CODESET.codesetid (ELEM/SEC) |
| low_grade / high_grade | NUMBER | |

### terms
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| yearid | NUMBER | → years.yearid |
| schoolid | NUMBER | → **schools.school_number** |
| name | VARCHAR2 | '2024-2025', 'Q1', 'S1', etc. |
| firstday / lastday | DATE | |
| isyearrec | NUMBER | 1 = year record (use for year-level queries) |
| abbreviation | VARCHAR2 | |

### calendar_day
| Column | Type | Notes |
|--------|------|-------|
| schoolid | NUMBER | → **schools.school_number** |
| date_value | DATE | |
| insession | NUMBER | 1 = school day |
| day_in_school_year | NUMBER | 1, 2, 3... |
| school_year | NUMBER | |
| schedule_id | NUMBER | |

---

## Enrollment Tables

### cc (Course Enrollment)
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| studentid | NUMBER | → **students.id** (not dcid!) |
| sectionid | NUMBER | → sections.id |
| dateenrolled / dateleft | DATE | |
| expression | VARCHAR2 | Period/day pattern (e.g., '1(A-B)') |
| termid | NUMBER | → terms.id (legacy) |

### sections
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| course_number | VARCHAR2 | → courses.course_number |
| schoolid | NUMBER | → **schools.school_number** |
| termid | NUMBER | → terms.id |
| teacher | NUMBER | → schoolstaff.id |
| expression | VARCHAR2 | |
| grade_level | NUMBER | |

### courses
| Column | Type | Notes |
|--------|------|-------|
| course_number | VARCHAR2 | PK |
| course_name | VARCHAR2 | |
| credittype | VARCHAR2 | |

### PS_ENROLLMENT_ALL
| Column | Type | Notes |
|--------|------|-------|
| studentid | NUMBER | → students.id |
| schoolid | NUMBER | → **schools.school_number** |
| entrydate / exitdate | DATE | |
| grade_level | NUMBER | |
| yearid | NUMBER | → years.yearid |
| | | Best for date-based snapshots |

### reenrollments
| Column | Type | Notes |
|--------|------|-------|
| studentid | NUMBER | → students.id |
| entrydate / exitdate | DATE | |
| grade_level | NUMBER | |
| schoolid | NUMBER | → **schools.school_number** |
| yearid | NUMBER | |
| | | Historical records; union with students for full history |

---

## Attendance Tables

### PS_ADAADM_MEETING_PTOD / ps_adaadm_meeting_ptod
| Column | Type | Notes |
|--------|------|-------|
| schoolid | NUMBER | → **schools.school_number** |
| calendardate | DATE | |
| membershipvalue | NUMBER | Filter > 0 |
| ada / adm | NUMBER | |
| tardy / absent | NUMBER | |

### PS_ATTENDANCE_MEETING
| Column | Type | Notes |
|--------|------|-------|
| studentid | NUMBER | → students.id |
| att_date | DATE | |
| attendance_codeid | NUMBER | → attendance_code.id |
| periodid | NUMBER | → period.id |
| sectionid | NUMBER | → sections.id |

### attendance (table)
| Column | Type | Notes |
|--------|------|-------|
| studentid | NUMBER | → students.id |
| att_date | DATE | |
| attendance_codeid | NUMBER | → attendance_code.id |
| periodid | NUMBER | → period.id |
| att_comment | CLOB | JSON in ScholarChip queries |

### attendance_code
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| att_code | VARCHAR2 | 'A', 'T', 'ISS', 'OSS', 'P', etc. |
| description | VARCHAR2 | |
| presence_status_cd | VARCHAR2 | 'Absent', 'Present', 'Tardy' |

### ps_period_att
| Column | Type | Notes |
|--------|------|-------|
| schoolid | NUMBER | → **schools.school_number** |
| yearid | NUMBER | |
| potential_periods | NUMBER | For suspension day conversion |

---

## SBG Tables

### STANDARD
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| identifier | VARCHAR2 | 'MAT-01.OA.1', 'ELA-R.1.2' |
| name | VARCHAR2 | |
| description | CLOB | |
| yearid | NUMBER | → years.yearid |
| standardgradelevelid | NUMBER | |
| standardidentifier | VARCHAR2 | Parent rollup code |
| isactive | NUMBER | 1/0 |

### STANDARDGRADESECTION (SGS)
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| standardid | NUMBER | → STANDARD.id |
| sectionid | NUMBER | → sections.id |
| studentid | NUMBER | → students.id |
| standardgrade | NUMBER | 1.0-4.0 |
| storecode | VARCHAR2 | 'Q1','Q2','S1','Y1' |
| termid | NUMBER | → terms.id |
| grader | NUMBER | → schoolstaff.id |

### STANDARDGRADEROLLUP
| Column | Type | Notes |
|--------|------|-------|
| parentstandardid | NUMBER | → STANDARD.id |
| childstandardid | NUMBER | → STANDARD.id |
| rolluptype | VARCHAR2 | |

### STANDARDCOURSEASSOC
| Column | Type | Notes |
|--------|------|-------|
| course_number | VARCHAR2 | → courses.course_number |
| standardid | NUMBER | → STANDARD.id |

### STANDARDSCORE
| Column | Type | Notes |
|--------|------|-------|
| studentid | NUMBER | → students.id |
| assignmentid | NUMBER | → ASSIGNMENT.id |
| standardid | NUMBER | → STANDARD.id |
| score | NUMBER | |

### STANDARDSGRADES
| Column | Type | Notes |
|--------|------|-------|
| studentid | NUMBER | → students.id |
| standardid | NUMBER | → STANDARD.id |
| storecode | VARCHAR2 | |
| yearid | NUMBER | |
| grade | VARCHAR2 | Alpha grade |
| percent / points | NUMBER | |

### TERMBINS / Termbins
| Column | Type | Notes |
|--------|------|-------|
| termid | NUMBER | |
| storecode | VARCHAR2 | |
| gradelevel | NUMBER | |
| yearid | NUMBER | |
| | | Maps storecodes to terms |

### ASSIGNMENT
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| name | VARCHAR2 | |
| identifier | VARCHAR2 | |
| category | VARCHAR2 | |
| maxpoints | NUMBER | |
| sectionid | NUMBER | → sections.id |

### ASSIGNMENTSTANDARDASSOC
| Column | Type | Notes |
|--------|------|-------|
| assignmentid | NUMBER | → ASSIGNMENT.id |
| standardid | NUMBER | → STANDARD.id |

---

## Contacts Tables

### PERSON
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| first_name / last_name | VARCHAR2 | |
| email_addr | VARCHAR2 | |

### STUDENTCONTACTASSOC
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| studentdcid | NUMBER | → students.dcid |
| personid | NUMBER | → PERSON.id |

### STUDENTCONTACTDETAIL
| Column | Type | Notes |
|--------|------|-------|
| studentcontactassocid | NUMBER | → STUDENTCONTACTASSOC.id |
| relationship_codesetid | NUMBER | → CODESET.codesetid |
| contact_priority_codesetid | NUMBER | → CODESET.codesetid |
| isactive | NUMBER | 1/0 |

### ORIGINALCONTACTMAP
| Column | Type | Notes |
|--------|------|-------|
| personid | NUMBER | → PERSON.id |
| studentdcid | NUMBER | → students.dcid |
| originalcontacttype | VARCHAR2 | 'guardian','father','mother' |

### PERSONPHONENUMBERASSOC
| Column | Type | Notes |
|--------|------|-------|
| personid | NUMBER | → PERSON.id |
| phonenumberid | NUMBER | → PHONENUMBER.id |
| phonetypecodesetid | NUMBER | → CODESET.codesetid |
| priority | NUMBER | Lower = higher priority |

### PHONENUMBER
| Column | Type | Notes |
|--------|------|-------|
| id | NUMBER | PK |
| phonenumber | VARCHAR2 | Raw format |

### PERSONEMAILADDRESSASSOC / EMAILADDRESS
| Column | Type | Notes |
|--------|------|-------|
| personid / emailaddressid | NUMBER | FKs |
| emailaddress | VARCHAR2 | |

### PERSONADDRESSASSOC / PERSONADDRESS
| Column | Type | Notes |
|--------|------|-------|
| personid / personaddressid | NUMBER | FKs |
| address_line1, city, state, zip | VARCHAR2 | |
| addresstypecodesetid | NUMBER | → CODESET.codesetid |
| state_codesetid | NUMBER | → CODESET.codesetid |

### GUARDIANPERSONASSOC / guardianstudent
| Column | Type | Notes |
|--------|------|-------|
| guardianpersonid / personid | NUMBER | |
| studentsdcid | NUMBER | → students.dcid |

---

## Custom Tables (District-Specific)

### U_STUDENTS_BPS
| Known Columns | Notes |
|---------------|-------|
| studentsdcid | → students.dcid |
| contracted_periods | For Saber attendance |
| Saber course mapping | JSON or custom fields |

### U_SECTIONS_BPS
| Column | Notes |
|--------|-------|
| id | → sections.id |
| physical_schoolid | → **schools.school_number** |

### U_SCHOOLS_BPS
| Column | Notes |
|--------|-------|
| schoolid | → **schools.school_number** |
| capacity | Custom capacity field |

### U_CLG_ARC_TRGTS (VPR Targets)
| Column | Notes |
|--------|-------|
| standardid | → STANDARD.id |
| yearid | |
| gradelevel | |
| target_score | |
| proficiency_threshold | |
| storecode | |

### S_ND_STU_X (State Custom)
| Column | Notes |
|--------|-------|
| studentsdcid | → students.dcid |
| whencreated | Date student added to PS |
| lep_indicator / iep_indicator / frl_status | Flags |

---

## Reference Tables

### CODESET
| Column | Notes |
|--------|-------|
| codesetid | PK |
| code | Machine code ('Mobile', 'ELEM', 'guardian') |
| displayvalue | Human label ('Mobile Phone', 'Elementary', 'Guardian') |

### gen
| Column | Notes |
|--------|-------|
| cat | Category ('federalrace', 'iep', 'lep') |
| name | Code value |
| value | Label |

### period
| Column | Notes |
|--------|-------|
| id | PK |
| period_number | |
| schoolid | → **schools.school_number** |

### schoolstaff
| Column | Notes |
|--------|-------|
| id | PK |
| users_dcid | → users.dcid |
| schoolid | → **schools.school_number** |

### users
| Column | Notes |
|--------|-------|
| dcid | PK |
| lastfirst | |
| email | |

---

## Quick FK Reference

| Table | FK Column | References |
|-------|-----------|------------|
| students.schoolid | → schools.school_number |
| cc.studentid | → students.id |
| cc.sectionid | → sections.id |
| sections.schoolid | → schools.school_number |
| sections.course_number | → courses.course_number |
| sections.termid | → terms.id |
| sections.teacher | → schoolstaff.id |
| terms.schoolid | → schools.school_number |
| calendar_day.schoolid | → schools.school_number |
| PS_ADAADM_MEETING_PTOD.schoolid | → schools.school_number |
| PS_ATTENDANCE_MEETING.studentid | → students.id |
| attendance.studentid | → students.id |
| STANDARDGRADESECTION.standardid | → STANDARD.id |
| STANDARDGRADESECTION.sectionid | → sections.id |
| STANDARDGRADESECTION.studentid | → students.id |
| STUDENTCONTACTASSOC.studentdcid | → students.dcid |
| STUDENTCONTACTASSOC.personid | → PERSON.id |
| PERSONPHONENUMBERASSOC.personid | → PERSON.id |
| U_SECTIONS_BPS.physical_schoolid | → schools.school_number |
| U_CLG_ARC_TRGTS.standardid | → STANDARD.id |

---

## Cross-References

- **Common patterns**: `reference/common-patterns.md`
- **Attendance queries**: `reference/attendance.md`
- **Contacts queries**: `reference/contacts.md`
- **Enrollment queries**: `reference/enrollment.md`
- **SBG queries**: `reference/sbg.md`