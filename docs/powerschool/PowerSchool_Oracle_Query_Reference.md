# PowerSchool Oracle Query Reference

*(Generated from the *.sql files under **Resource Generation/Sample queries**)*  

---

## Contents
1. [Attendance](#attendance)  
2. [Contacts](#contacts)  
3. [Enrollment](#enrollment)  
4. [SBG (Standards-Based Grading)](#sbg)  

Each entry contains:

| Field | Meaning |
|------|---------|
| **File** | Relative path from the *Sample queries* root |
| **Purpose** | Short description (taken from the leading comment block or inferred) |
| **SQL** | Full query (fenced code block) |
| **Tables / Views** | All objects referenced after `FROM`, `JOIN`, `INSERT INTO`, `UPDATE`, `DELETE FROM` |
| **Key Joins / Filters** | Important `ON` conditions and `WHERE` clauses |
| **Parameters / Bind variables** | `:` or `&` placeholders |
| **Hints / Quirks** | Oracle optimizer hints, `/*+ … */` or non-standard constructs (e.g., `CONNECT BY`, `NVL`, `DECODE`, `KEEP (DENSE_RANK FIRST)`, etc.) |

---  

## Attendance  

### 1. Attendance-Tardy Percentage comparisons.sql  
**Purpose:** Calculate attendance and tardy percentages for a set of schools over a configurable date range, comparing across schools.  
```sql
/* Full query in: Attendance/Attendance-Tardy Percentage comparisons.sql */
```
- **Tables / Views:** `CALENDAR_DAY`, `TERMS`, `ps_adaadm_meeting_ptod`, `ps_membership_defaults`, `PS_ATTENDANCE_MEETING`, `students`, `reenrollments`, `gen`, `schools`  
- **Key Joins / Filters:**  
  - `CALENDAR_DAY` ↔ `terms` on school & in-session dates (`terms.ISYEARREC = 1`)  
  - `ps_adaadm_meeting_ptod ada` ↔ `params` on school & date range  
  - `WHERE ada.MEMBERSHIPVALUE > 0` AND `ada.calendardate BETWEEN daynumByYear.firstDay AND daynumByYear.daynum_date`  
- **Parameters:** CTEs: `daynumByYear`, `att`, `reportYears`, `schoolYearDays`  
- **Hints / Quirks:** Uses `CASE WHEN`, `NVL`; cross-joins `daynumByYear` with `ON 1=1`; multiple UNION sub-queries to combine reenrollment and student tables; uses `SYSDATE - 1` to exclude current day.

### 2. ADAADM by Subgroup.sql  
**Purpose:** Report ADA (Attendance-Daily-Average) and ADM (Attendance-Daily-Maximum) totals broken down by student sub-groups such as race, homelessness, IEP, etc.  
```sql
/* Full query in: Attendance/ADAADM by Subgroup.sql */
```
- **Tables / Views:** `Students`, `StudentRace`, `gen`, `S_ND_STU_X`, `S_ND_STU_HOMELESSPROGRAMS_C`, `PS_ADAADM_MEETING_PTOD`, `SCHOOLS`  
- **Key Joins / Filters:**  
  - `Students LEFT JOIN StudentRace ON students.ID = StudentRace.StudentID`  
  - `Students LEFT JOIN gen ON gen.cat='federalrace' AND gen.name=StudentRace.RACECD`  
  - `stuFedRace LEFT JOIN S_ND_STU_HOMELESSPROGRAMS_C` with date range logic  
- **Parameters:** CTEs: `params` (beginDate, endDate), `stuFedRace`, `stuSubgroups`, `admSchool`  
- **Hints / Quirks:** Uses inline comment syntax `~[if#...]` interpreted by a reporting engine; aggregates sub-groups via UNION with calculated sort key (`schoolsubgroupsort`).

### 3. ADAADM by School date range.sql  
**Purpose:** Summarize ADA and ADM metrics for each school (and district total) over a configurable date range, with feeder-area grouping.  
```sql
/* Full query in: Attendance/ADAADM by School date range.sql */
```
- **Tables / Views:** `CALENDAR_DAY`, `PS_ADAADM_MEETING_PTOD`, `SCHOOLS`  
- **Key Joins / Filters:**  
  - `CALENDAR_DAY` filtered by `calparams` (start/end date) with `INSESSION = 1`  
  - `PS_ADAADM_MEETING_PTOD adm` ↔ `params` on school & date range  
- **Parameters:** CTEs: `searchparams`, `calparams`, `calwithnumdays`, `params`  
- **Hints / Quirks:** Fiscal-year logic (`enddate = '6/30/' || (year of startdate + 1)`); uses `cumulative_days IN (1, params.numdays)` to pick first and last in-session days; multiple commented date ranges for quick swapping.

### 4. ADAADM by Division.sql  
**Purpose:** Show ADA/ADM absence percentage and student counts for elementary vs. secondary divisions, adding extra student counts from separate queries.  
```sql
/* Full query in: Attendance/ADAADM by Division.sql */
```
- **Tables / Views:** `students`, `PS_ADAADM_MEETING_PTOD`, `SCHOOLS`, `CODESET`  
- **Key Joins / Filters:**  
  - `SCHOOLS sc LEFT JOIN CODESET codeset ON sc.schoolcategorycodesetid = codeset.codesetid`  
  - `CASE WHEN CODESET.displayvalue = 'ELEM' THEN 'Elementary' ELSE 'Secondary'`  
- **Parameters:** CTEs: `additionalElem`, `additionalSec`, `adaadm`  
- **Hints / Quirks:** Extra student counts via LEFT JOIN to `additionalElem`/`additionalSec` CTEs after main aggregation.

### 5. Attendance-Tardy Percentages by school and date range.sql  
**Purpose:** Produce school-level attendance, ADA, ADM, tardy counts and percentages for a selectable date range.  
```sql
/* Full query in: Attendance/Attendance-Tardy Percentages by school and date range.sql */
```
- **Tables / Views:** `CALENDAR_DAY`, `ps_adaadm_meeting_ptod`, `ps_membership_defaults`, `PS_ATTENDANCE_MEETING`, `students`, `reenrollments`, `Students`, `gen`, `schools`  
- **Key Joins / Filters:**  
  - Complex JOIN chain: `ps_adaadm_meeting_ptod ada` ↔ `params`, `ps_membership_defaults mv`, `PS_ATTENDANCE_MEETING meet` (LEFT JOIN), `students s` ↔ `(reenrollments UNION Students) a`  
  - `WHERE ada.MEMBERSHIPVALUE > 0` AND `a.entrydate < a.exitdate`  
- **Parameters:** CTEs: `searchparams`, `calparams`, `calwithnumdays`, `params`, `att`  
- **Hints / Quirks:** Complex UNION of reenrollments and Students; relies on cumulative day logic for first/last in-session days.

### 6. ScholarChip Saber query.sql  
**Purpose:** Extract Saber-specific attendance counts per student, broken out by course categories and contract-based attendance expectations.  
```sql
/* Full query in: Attendance/ScholarChip Saber query.sql */
```
- **Tables / Views:** `attendance`, `courses`, `students`, `attendance_code`, `period`, `cc`, `U_STUDENTS_BPS`  
- **Key Joins / Filters:**  
  - `JSON_VALUE(a.att_comment,'$.course')` to extract course info from JSON comment field  
  - Filter on school = 84 and `c.course_number LIKE 'LHS%'`  
- **Parameters:** CTE: `SCSaber` (extracts Saber course number/name from JSON)  
- **Hints / Quirks:** Uses Oracle JSON extraction (`JSON_VALUE`); proprietary table `U_STUDENTS_BPS` for contracted period totals.

### 7. Day number by year.sql  
**Purpose:** Calculate the day-of-year number for a configurable school year window, exposing the first day of the year and the target day number.  
```sql
/* Full query in: Attendance/Day number by year.sql */
```
- **Tables / Views:** `CALENDAR_DAY`, `TERMS`  
- **Key Joins / Filters:**  
  - `CALENDAR_DAY INNER JOIN TERMS ON terms.schoolid = calendar_day.SCHOOLID AND terms.ISYEARREC = 1`  
  - Filter: `CALENDAR_DAY.DATE_VALUE < SYSDATE - 1` AND `INSESSION = 1`  
- **Parameters:** CTEs: `params`, `reportYears`, `schoolYearDays`, `daynumByYear`  
- **Hints / Quirks:** Cross-join style `ON 1=1` (commented) for date alignment; selects target day by matching `day_in_school_year = curyeardaynumday`.

### 8. Suspensions - number of equivalent days.sql  
**Purpose:** Calculate the number of equivalent suspension days for each student by converting period-count suspensions into day equivalents.  
```sql
/* Full query in: Attendance/Suspensions - number of equivalent days.sql */
```
- **Tables / Views:** `attendance`, `ATTENDANCE_CODE`, `ps_period_att`, `students`, `schools`, `terms`  
- **Key Joins / Filters:**  
  - `ac.ATT_CODE IN ('ISS','OSS')`  
  - Hard-coded `ppa.year_id = 27`  
- **Parameters:** CTE: `suspended` (counts suspension periods per student/date)  
- **Hints / Quirks:** Converts suspension periods to days via `ROUND(SUM(sus.numPeriods/ppa.potential_periods),1)`; `HAVING` clause filters for ≥ 10 equivalent days.

---

## Contacts  

### 1. Contacts - Custom fields different from current Mobile contact.sql  
**Purpose:** Identify contacts whose custom-field phone values differ from the current Mobile contact value for each student.  
```sql
/* Full query in: Contacts/Contacts - Custom fields different from current Mobile contact.sql */
```
- **Tables / Views:** `PERSONPHONENUMBERASSOC`, `CODESET`, `PHONENUMBER`, `students`, `STUDENTCONTACTASSOC`, `ORIGINALCONTACTMAP`, `U_STUDENTS_BPS`  
- **Key Joins / Filters:**  
  - `inner join CODESET csm on ppnamin.PHONETYPECODESETID = csm.CODESETID` where `csm.code = 'Mobile'`  
  - Filter on `ocm.ORIGINALCONTACTTYPE IN ('guardian','father','mother')`  
- **Parameters:** None  
- **Hints / Quirks:** Oracle `KEEP (DENSE_RANK FIRST)` syntax to pick top-priority phone; `DECODE` for value comparison; `REPLACE` to normalize phone strings; CTE `firstMobile`.

### 2. Contacts - Cellphone export.sql  
**Purpose:** Export the highest-priority mobile phone number for each student-contact relationship.  
```sql
/* Full query in: Contacts/Contacts - Cellphone export.sql */
```
- **Tables / Views:** `PERSONPHONENUMBERASSOC`, `CODESET`, `PHONENUMBER`, `students`, `STUDENTCONTACTASSOC`, `STUDENTCONTACTDETAIL`, `ORIGINALCONTACTMAP`, `U_STUDENTS_BPS`  
- **Key Joins / Filters:** Same as #1; filter on `s.enroll_status <= 0`.  
- **Parameters:** None  
- **Hints / Quirks:** `KEEP (DENSE_RANK FIRST)`, `DECODE`, CTE usage.

### 3. Contact Mobile Validation to custom.sql  
**Purpose:** Validate that the stored mobile phone for each contact matches the custom-field value in the BPS table.  
```sql
/* Full query in: Contacts/Contact Mobile Validation to custom.sql */
```
- **Tables / Views:** `OriginalContactMap`, `studentcontactassoc`, `studentcontactdetail`, `person`, `students`, `U_STUDENTS_BPS`, `personphonenumberassoc`, `phonenumber`, `codeset`  
- **Key Joins / Filters:** Extensive joins to link contacts, phones, students; filter on contact types.  
- **Parameters:** None  
- **Hints / Quirks:** `DECODE` for boolean comparison; HTML string concatenation for hyperlink output.

### 4. Contact Flags.sql  
**Purpose:** Generate flags indicating custodial, pickup, and emergency status for each contact.  
```sql
/* Full query in: Contacts/Contact Flags.sql */
```
- **Tables / Views:** `OriginalContactMap`, `studentcontactassoc`, `studentcontactdetail`, `codeset`, `students`, `U_STUDENTS_BPS`  
- **Key Joins / Filters:**  
  - `inner join studentcontactassoc sca` ↔ `studentcontactdetail scd ON sca.STUDENTCONTACTASSOCID = scd.STUDENTCONTACTASSOCID AND scd.isactive = 1`  
  - `inner join codeset` for relationship types and contact roles.  
- **Parameters:** None  
- **Hints / Quirks:** Uses `NVL` and `CASE` statements to coalesce flag values; multiple comment blocks for future extensions.

### 5. Cellphone to Contacts Query.sql  
**Purpose:** Identify mismatches between BPS cellphone fields and the contact's phone number records.  
```sql
/* Full query in: Contacts/Cellphone to Contacts Query.sql */
```
- **Tables / Views:** `OriginalContactMap`, `studentcontactassoc`, `studentcontactdetail`, `person`, `students`, `U_STUDENTS_BPS`, `personphonenumberassoc`, `phonenumber`, `codeset`, `PERSONPHONENUMBERASSOC`  
- **Key Joins / Filters:** Same join pattern as #3; includes sub-query `pMobileCnt` to count mobile phone records per person.  
- **Parameters:** None  
- **Hints / Quirks:** Complex `DECODE` with `REPLACE` to normalize phone strings; sub-query counts mobiles per person.

### 6. Contacts for Clever.sql  
**Purpose:** Produce a student roster export formatted for Clever, including contact information and enrollment filters.  
```sql
/* Full query in: Contacts/Contacts for Clever.sql */
```
- **Tables / Views:** `students`, `Terms`, `S_ND_STU_X`, `U_STUDENTS_BPS`, `studentContacts` (derived sub-query), `studentContactAssoc`, `studentContactDetail`, `person`, `personemailaddressassoc`, `emailaddress`, `PCAS_EMAILCONTACT`, `codeset`  
- **Key Joins / Filters:** Complex joins to pull emails, phones, addresses; filters on enrollment status (`enroll_status = 0` or `-1` with conditions), school range (40-89), Clever-specific schools.  
- **Parameters:** None  
- **Hints / Quirks:** Uses `TO_CHAR` for date formatting; multiple `CASE` statements for school-specific IDs; commented-out alternative logic at top.

### 7. Contacts - PersonAddress Students.sql  
**Purpose:** Return student address records together with the type of address (home, mailing, etc.) and related person address data.  
```sql
/* Full query in: Contacts/Contacts - PersonAddress Students.sql */
```
- **Tables / Views:** `students`, `PERSON`, `PERSONADDRESSASSOC`, `PERSONADDRESS`, `CODESET`  
- **Key Joins / Filters:**  
  - `inner join PERSON on students.PERSON_ID = person.ID`  
  - `inner join PERSONADDRESSASSOC` ↔ `PERSONADDRESS`  
  - `inner join CODESET` for state and address type.  
- **Parameters:** None  
- **Hints / Quirks:** Commented-out alternative filter on `last_name = 'Albin'`.

### 8. Contacts - Guardian table records without Contact Associations.sql  
**Purpose:** Find guardian records that are not linked to a StudentContactAssoc entry (orphaned guardians).  
```sql
/* Full query in: Contacts/Contacts - Guardian table records without Contact Associations.sql */
```
- **Tables / Views:** `GUARDIANPERSONASSOC`, `guardianstudent`, `students`, `STUDENTCONTACTASSOC`, `STUDENTCONTACTDETAIL`  
- **Key Joins / Filters:**  
  - `LEFT JOIN STUDENTCONTACTASSOC sca ON sca.personid = gpa.PERSONID AND gs.STUDENTSDCID = sca.STUDENTDCID`  
  - Filter: `sca.STUDENTCONTACTASSOCID IS NULL AND s.ENROLL_STATUS = 0`.  
- **Parameters:** None  
- **Hints / Quirks:** Uses LEFT JOIN to detect missing association.

### 9. Contacts for PQ DAT.sql  
**Purpose:** Create a formatted HTML-rich contact list for PowerQuery/Databricks (PQ DAT) including phones, emails, addresses and flag icons.  
```sql
/* Full query in: Contacts/Contacts for PQ DAT.sql */
```
- **Tables / Views:** `students`, `studentContactAssoc`, `studentContactDetail`, `person`, `codeset`, `personemails` (derived), `personphones` (derived), `personaddr` (derived), `emailaddress`, `PERSONEMAILADDRESSASSOC`, `phonenumber`, `PERSONPHONENUMBERASSOC`, `PERSONADDRESS`, `PERSONADDRESSASSOC`  
- **Key Joins / Filters:** Multiple LEFT JOINs to aggregate emails, phones, addresses via `LISTAGG`; filter on specific student DCID (`221252`).  
- **Parameters:** None  
- **Hints / Quirks:** Extensive use of `LISTAGG` for aggregation; HTML generation inside SQL (`CHR`, `<span>`, `<i>` tags); multiple sub-queries for line-break separators.

### 10. Highest priority mobile contact.sql  
**Purpose:** Return the highest-priority mobile phone record for each person (used as a CTE in other queries).  
```sql
/* Full query in: Contacts/Highest priority mobile contact.sql */
```
- **Tables / Views:** `PERSONPHONENUMBERASSOC`, `CODESET`, `PHONENUMBER`  
- **Key Joins / Filters:** `inner join CODESET csm ON ppnamin.PHONETYPECODESETID = csm.CODESETID` where `csm.code = 'Mobile'`.  
- **Parameters:** None  
- **Hints / Quirks:** `KEEP (DENSE_RANK FIRST)` to pick the top-priority phone; commented-out example SELECT for debugging.

### 11. Mismatch cell phone fields.sql  
**Purpose:** Detect mismatches between BPS stored cell-phone fields and the phone numbers recorded in the PERSONPHONENUMBER tables.  
```sql
/* Full query in: Contacts/Mismatch cell phone fields.sql */
```
- **Tables / Views:** `person`, `OriginalContactMap`, `studentcontactassoc`, `studentcontactdetail`, `U_STUDENTS_BPS`, `personphonenumberassoc`, `phonenumber`, `codeset`, `PERSONPHONENUMBERASSOC`  
- **Key Joins / Filters:** Same join pattern as #5; filter on contact types (`father`, `mother`).  
- **Parameters:** None  
- **Hints / Quirks:** `DECODE` with `REPLACE` to compare normalized phone numbers; sub-query `pMobileCnt` counts mobile records per person.

---

## Enrollment  

### 1. Enrollment by Demographic.sql  
**Purpose:** Enrollment counts by demographic (race, EL, IEP, etc.).  
```sql
/* Full query in: Enrollment/Enrollment by Demographic.sql */
```
- **Tables / Views:** `terms`, `cc`, `students`, `S_ND_STU_X`  
- **Key Joins / Filters:**  
  - `inner join cc`, `inner join students`, `inner join termlist` (CTE)  
  - Filter on `terms.yearid = 33`, `schoolid between 80 and 89`, `ISYEARREC=1`.  
- **Parameters:** Year = 33, school range = 80-89, term = 3300-3399.  
- **Hints / Quirks:** Multiple CTEs (`countByEth`, `countByIEP`, `countBySES`, `countByEL`); large commented-out sections.

### 2. Enrollment by Demographic by date.sql  
**Purpose:** Enrollment by demographic limited to a specific snapshot date.  
```sql
/* Full query in: Enrollment/Enrollment by Demographic by date.sql */
```
- **Tables / Views:** `terms`, `cc`, `students`, `PS_ENROLLMENT_ALL`, `S_ND_STU_X`  
- **Key Joins / Filters:** Same as #1; additional filter `a.exitdate = TO_DATE('5/27/2023','mm/dd/yyyy')`.  
- **Parameters:** Year = 33, date = 5/27/2023, school range = 40-89.  
- **Hints / Quirks:** CTE `stuPop` built from `PS_ENROLLMENT_ALL` rather than `cc`.

### 3. Enrollment - BECEP at Elementary.sql  
**Purpose:** Pull enrollment data for the BECEP program at elementary schools.  
```sql
/* Full query in: Enrollment/Enrollment - BECEP at Elementary.sql */
```
- **Tables / Views:** `U_SECTIONS_BPS`, `schools`, `CC`, `students`  
- **Key Joins / Filters:** Filter on `u_sections_bps.PHYSICAL_SCHOOLID IS NOT NULL`.  
- **Parameters:** None.

### 4. Class Counts.sql  
**Purpose:** Count classes per school/section for elementary schools.  
```sql
/* Full query in: Enrollment/Class Counts.sql */
```
- **Tables / Views:** `cc`, `sections`, `terms`, `schools`, `courses`  
- **Key Joins / Filters:** Standard joins on `terms`, `schools`, `courses`.  
- **Parameters:** None.

### 5. Class Counts - Secondary.sql  
**Purpose:** Count classes per school/section for secondary schools.  
```sql
/* Full query in: Enrollment/Class Counts - Secondary.sql */
```
- **Tables / Views:** `cc`, `sections`, `terms`, `schools`, `courses`  
- **Key Joins / Filters:** Same as #4; filters on secondary school range.  
- **Parameters:** None.

### 6. Class Counts - refactor.sql  
**Purpose:** Refactored version of class counts using a different approach with a `cfg` CTE.  
```sql
/* Full query in: Enrollment/Class Counts - refactor.sql */
```
- **Tables / Views:** `dual`, `cfg` (CTE), and derived tables from sub-queries.  
- **Key Joins / Filters:** Filter on school range (`70-84` or `40-70`) AND `cc.dateenrolled`/`cc.dateleft` matching `cfgDate`.  
- **Parameters:** School ranges: 70-84, 40-70.  
- **Hints / Quirks:** Uses a CTE named `cfg`; sub-query to find distinct `cc.sectionid`.

### 7. Career Academy enrollments by year.sql  
**Purpose:** Enrollment totals for Career Academy programs per year.  
```sql
/* Full query in: Enrollment/Career Academy enrollments by year.sql */
```
- **Tables / Views:** `reenrollments`, `students`, `cc`, `terms`, `stu2021`, `re2021`  
- **Key Joins / Filters:** Filter on `stuterm.yearid = 30`.  
- **Parameters:** Year ID = 30.

### 8. ADM Rollup by Grade Band.sql  
**Purpose:** Aggregate ADM (attendance-daily-maximum) values by grade band.  
```sql
/* Full query in: Enrollment/ADM Rollup by Grade Band.sql */
```
- **Tables / Views:** `students`, `enrollment`  
- **Key Joins / Filters:** Standard joins between students and enrollment tables.  
- **Parameters:** None.

### 9. StudentID Races.sql  
**Purpose:** List student IDs together with race information.  
```sql
/* Full query in: Enrollment/StudentID Races.sql */
```
- **Tables / Views:** `students`, `STUDENTRACE`  
- **Key Joins / Filters:** `inner join STUDENTRACE ON students.ID = STUDENTRACE.StudentID`.  
- **Parameters:** None.

### 10. Student roster with homeroom.sql  
**Purpose:** Full student roster including homeroom assignment and teacher information.  
```sql
/* Full query in: Enrollment/Student roster with homeroom.sql */
```
- **Tables / Views:** `dual`, `cc`, `params` (CTE), `courses`, `students`, `sections`, `SCHOOLSTAFF`, `users`, `schools`, `terms`  
- **Key Joins / Filters:** Complex joins to link students → cc → sections → courses → SCHOOLSTAFF → users.  
- **Parameters:** None  
- **Hints / Quirks:** Selects from dummy `dual` table for constant values (e.g., date parameters).

### 11. Section enrollment physical school different.sql  
**Purpose:** Identify section enrollments where the physical school differs from the home school.  
```sql
/* Full query in: Enrollment/Section enrollment physical school different.sql */
```
- **Tables / Views:** `U_SECTIONS_BPS`, `schools`, `cc`, `students`  
- **Key Joins / Filters:** Filter on `u_sections_bps.PHYSICAL_SCHOOLID IS NOT NULL`.  
- **Parameters:** None.

### 12. Section Counts for BOY Reporting.sql  
**Purpose:** Section counts for Beginning-of-Year reporting.  
```sql
/* Full query in: Enrollment/Section Counts for BOY Reporting.sql */
```
- **Tables / Views:** `Sections`, `Schools`, `Courses`  
- **Key Joins / Filters:** Standard joins to aggregate section counts.  
- **Parameters:** None.

### 13. Panorama Student Roster.sql  
**Purpose:** Roster export formatted for the Panorama reporting system.  
```sql
/* Full query in: Enrollment/Panorama Student Roster.sql */
```
- **Tables / Views:** `reenrollments`, `enr` (derived), `terms`  
- **Key Joins / Filters:** Filter on `enr.YearID IN (33)`; uses `ROW_NUMBER() = 1` for deduplication.  
- **Parameters:** Year ID = 33.

### 14. New to District as of date.sql  
**Purpose:** Identify students newly added to the district as of a specific date.  
```sql
/* Full query in: Enrollment/New to District as of date.sql */
```
- **Tables / Views:** `Students`  
- **Key Joins / Filters:** Filter on enrollment entry date relative to a reference date.  
- **Parameters:** None.

### 15. Students added to PowerSchool by month.sql  
**Purpose:** Monthly counts of new students added to PowerSchool.  
```sql
/* Full query in: Enrollment/Students added to PowerSchool by month.sql */
```
- **Tables / Views:** `S_ND_STU_X`, `students`, `PS_ENROLLMENT_ALL`  
- **Key Joins / Filters:** Filter on `EXTRACT(YEAR FROM snd.WHENCREATED) >= 2018`.  
- **Parameters:** Year = 2018.  
- **Hints / Quirks:** Uses Oracle-style `EXTRACT` and `TO_DATE` functions.

### 16. Students on specific date by school wCapacity.sql  
**Purpose:** Student list for a given date, including school capacity information.  
```sql
/* Full query in: Enrollment/Students on specific date by school wCapacity.sql */
```
- **Tables / Views:** `ps_enrollment_all`, `schools`, `U_SCHOOLS_BPS`, `terms`  
- **Key Joins / Filters:** Filter on enrollment dates relative to term start; LEFT JOIN to `U_SCHOOLS_BPS` for capacity.  
- **Parameters:** None  
- **Hints / Quirks:** Dynamic date string built with concatenation (`TO_DATE('9/10/' || EXTRACT(YEAR FROM terms.firstday), 'mm/dd/yyyy')`).

### 17. Students in specific courses by gender-ethnicity.sql  
**Purpose:** Enrollment counts for selected courses broken down by gender and ethnicity.  
```sql
/* Full query in: Enrollment/Students in specific courses by gender-ethnicity.sql */
```
- **Tables / Views:** `cc`, `hsRemedial`, `students`, `schools`, `terms`, `courses`  
- **Key Joins / Filters:** Standard joins to aggregate enrollments by course.  
- **Parameters:** None.

### 18. Students on specific date by school.sql  
**Purpose:** Snapshot of enrollment on a given date, filtered by school.  
```sql
/* Full query in: Enrollment/Students on specific date by school.sql */
```
- **Tables / Views:** `ps_enrollment_all`, `schools`  
- **Key Joins / Filters:** Filter on `ENTRYDATE <= TO_DATE(...)` AND `exitdate > TO_DATE(...)`.  
- **Parameters:** None  
- **Hints / Quirks:** Dynamic date string built with concatenation.

### 19. Students on specific date.sql  
**Purpose:** Snapshot of enrollment on a given date (district-wide).  
```sql
/* Full query in: Enrollment/Students on specific date.sql */
```
- **Tables / Views:** `ps_enrollment_all`, `terms`  
- **Key Joins / Filters:** Same date-snapshot logic as #18, without school filter.  
- **Parameters:** None.

---

## SBG (Standards-Based Grading)  

### 1. SBG Assignment standards by year-domain-grade level.sql  
**Purpose:** List assignment standards for a given year, domain, and grade level.  
```sql
/* Full query in: SBG/SBG Assignment standards by year-domain-grade level.sql */
```
- **Tables / Views:** `ASSIGNMENTSECTION`, `ASSIGNMENTSTANDARDASSOC`, `sections`, `STANDARD`, `terms`  
- **Key Joins / Filters:** Standard joins to link assignments to standards.  
- **Parameters:** None.

### 2. PSM Report Card Items.sql  
**Purpose:** Pull report-card items for a specific student (PSM system).  
```sql
/* Full query in: SBG/PSM Report Card Items.sql */
```
- **Tables / Views:** `psm_assignmentstandard`, `psm_assignmentstandardscore`, `PSM_REPORTCARDITEM`, `PSM_REPORTCARDITEMGRADE`, `PSM_REPORTINGTERM`, `psm_sectionenrollment`, `psm_standard`, `standardgradesection`  
- **Key Joins / Filters:** Filter on `s.studentidentifier='610965'` and `studentsdcid=130238`.  
- **Parameters:** None.

### 3. EmpowerED SBG CRP Data Pull.sql  
**Purpose:** Extract CRP (College-Readiness-Plan) data for EmpowerED SBG.  
```sql
/* Full query in: SBG/EmpowerED SBG CRP Data Pull.sql */
```
- **Tables / Views:** `AssignmentSection`, `AssignmentStandardAssoc`, `cc`, `courses`, `dual`, `empowered`, `params` (CTE), `ps_enrollment_all`, `Schools`, `SchoolStaff`, `sections`, `sqlParams` (CTE), `Standard`, `StandardGradeSection`, `StandardScore`, `Students`, `terms`, `USERS`  
- **Key Joins / Filters:** Extensive joins across assignment, standard, enrollment, and user tables.  
- **Parameters:** CTEs: `params`, `sqlParams`.

### 4. CLG VPR standards query optimization.sql  
**Purpose:** Optimized query for VPR (Vision-Progress-Report) standards.  
```sql
/* Full query in: SBG/CLG VPR standards query optimization.sql */
```
- **Tables / Views:** `cc`, `Courses`, `Sections`, `stan1` through `stan5` (CTEs), `Standard`, `StandardCourseAssoc`, `stdStan` (CTE), `Students`, `TARGETS`, `Teachers`, `TermBins`, `U_CLG_ARC_TRGTS`  
- **Key Joins / Filters:** Filter on `ARCT.STORECODE = 'Q3'`; multiple standard CTEs with year filters (`yearid = 27`).  
- **Parameters:** None (hard-coded year ID; commented-out parameter reference `--~(gpv.yearid)`).

### 5. SBG Behavior Pct Proficient Grade Level.sql  
**Purpose:** Percent-proficient calculations for behavior standards by grade level.  
```sql
/* Full query in: SBG/SBG Behavior Pct Proficient Grade Level.sql */
```
- **Tables / Views:** `domainAvg` (CTE), `REENROLLMENTS`, `Sections`, `sg` (derived), `ST` (CTE), `STANDARD`, `STANDARDGRADEROLLUP`, `StandardGradeSection`, `Students`, `Termbins`, `Terms`  
- **Key Joins / Filters:** Filter on `s.YEARID = 28`; `sg.row_num=1`; `stanGrSec.standardgrade IS NOT NULL`.  
- **Parameters:** None (hard-coded year ID; commented-out parameter reference `--~(curyearid)`).

### 6. SBG Average Subject Area Score - SBAC Comparison.sql  
**Purpose:** Average subject-area scores, comparing SBAC results.  
```sql
/* Full query in: SBG/SBG Average Subject Area Score - SBAC Comparison.sql */
```
- **Tables / Views:** `cc`, `ps_enrollment_all`, `standards`, `standardsgrades`, `Students`  
- **Key Joins / Filters:** Filter on `stg.yearid=28`.  
- **Parameters:** None.

### 7. SBG Average Subject Area Score - Indian Ed grant.sql  
**Purpose:** Average subject-area scores for Indian Education grant reporting.  
```sql
/* Full query in: SBG/SBG Average Subject Area Score - Indian Ed grant.sql */
```
- **Tables / Views:** `ps_enrollment_all`, `standards`, `standardsgrades`, `Students`  
- **Key Joins / Filters:** Filter on `stg.yearid=28`.  
- **Parameters:** None.

### 8. SBG Assignments by year-domain-grade level.sql  
**Purpose:** List assignments for a given year, domain, and grade level (duplicate structure of #1).  
```sql
/* Full query in: SBG/SBG Assignments by year-domain-grade level.sql */
```
- **Tables / Views:** `ASSIGNMENTSECTION`, `ASSIGNMENTSTANDARDASSOC`, `sections`, `STANDARD`, `terms`  
- **Key Joins / Filters:** Same as #1.

### 9. SBG Count of Scores by Identifier.sql  
**Purpose:** Count of scores grouped by identifier (e.g., assignment ID).  
```sql
/* Full query in: SBG/SBG Count of Scores by Identifier.sql */
```
- **Tables / Views:** `ASSIGNMENT`, `ASSIGNMENTCATEGORYASSOC`, `assignmentsection`, `assignmentstandardassoc`, `courses`, `sections`, `standard`, `standardscore`, `TEACHERCATEGORY`, `termbins`, `terms`  
- **Key Joins / Filters:** Filter on `st.identifier LIKE 'MAT-01.OA%'`.  
- **Parameters:** None.

### 10. SBG Core Subject student improvement by year.sql  
**Purpose:** Track year-over-year improvement for core subjects.  
```sql
/* Full query in: SBG/SBG Core Subject student improvement by year.sql */
```
- **Tables / Views:** `domainAvg` (CTE), `REENROLLMENTS`, `Sections`, `sg` (derived), `ST` (CTE), `STANDARD`, `STANDARDGRADEROLLUP`, `StandardGradeSection`, `Students`, `Termbins`, `Terms`  
- **Key Joins / Filters:** Filter on `sg.row_num=1`; self-join to compare year-over-year (`y1.parentidentifier = y2.parentidentifier`).  
- **Parameters:** None.

### 11. SBG Core Subject Pct Proficient Grade Level.sql  
**Purpose:** Percent-proficient calculations for core subjects by grade level.  
```sql
/* Full query in: SBG/SBG Core Subject Pct Proficient Grade Level.sql */
```
- **Tables / Views:** Same as #5/10.  
- **Key Joins / Filters:** Filter on `s.YEARID = 29` (or parameter).  
- **Parameters:** None (hard-coded year ID; commented-out parameter reference `--~(curyearid)`).

### 12. SBG CRP Completion.sql  
**Purpose:** Completion status for CRP items.  
```sql
/* Full query in: SBG/SBG CRP Completion.sql */
```
- **Tables / Views:** `domainAvg` (CTE), `dual`, `params` (CTE), `REENROLLMENTS`, `Sections`, `sg` (derived), `ST` (CTE), `STANDARD`, `STANDARDGRADEROLLUP`, `StandardGradeSection`, `students`, `stulist` (CTE), `Termbins`, `Terms`  
- **Key Joins / Filters:** Filter on student list parameter (`:students`).  
- **Parameters:** `:students`.

### 13. SBG Courses and associated standards.sql  
**Purpose:** List courses together with their linked standards.  
```sql
/* Full query in: SBG/SBG Courses and associated standards.sql */
```
- **Tables / Views:** `courses`, `coursesWithSections` (CTE), `sections`, `selectedStandards` (CTE), `standard`, `STANDARDCOURSEASSOC`, `terms`  
- **Key Joins / Filters:** Filter on `standard.YEARID IN (33, 34)` and `yr.YEARID IN (33, 34)`.  
- **Parameters:** None.

### 14. SBG Domain Score - SBAC Comparison.sql  
**Purpose:** Domain-level score comparisons against SBAC results.  
```sql
/* Full query in: SBG/SBG Domain Score - SBAC Comparison.sql */
```
- **Tables / Views:** `ps_enrollment_all`, `SBG` (derived), `standards`, `standardsgrades`, `Students`  
- **Key Joins / Filters:** Filter on `stg.yearid=24`.  
- **Parameters:** None.

### 15. SBG Domain Score - SGS NDSA Comparison.sql  
**Purpose:** Domain-level score comparisons against SGS NDSA results.  
```sql
/* Full query in: SBG/SBG Domain Score - SGS NDSA Comparison.sql */
```
- **Tables / Views:** `cc`, `ps_enrollment_all`, `sections`, `sgs` (derived), `st` (CTE), `STANDARD`, `StandardGradeSection`, `students`, `TERMS`  
- **Key Joins / Filters:** Filter on student list parameter (`:students`).  
- **Parameters:** `:students`.

### 16. SBG Electives Pct Proficient Grade Level.sql  
**Purpose:** Percent-proficient calculations for elective courses by grade level.  
```sql
/* Full query in: SBG/SBG Electives Pct Proficient Grade Level.sql */
```
- **Tables / Views:** `domainAvg` (CTE), `REENROLLMENTS`, `Sections`, `sg` (derived), `ST` (CTE), `STANDARD`, `STANDARDGRADEROLLUP`, `StandardGradeSection`, `Students`, `Termbins`, `Terms`  
- **Key Joins / Filters:** Filter on `s.YEARID = 27`; `sg.row_num=1`.  
- **Parameters:** None.

### 17. SBG Final Grade Setup Validation.sql  
**Purpose:** Validate final grade configuration settings for schools.  
```sql
/* Full query in: SBG/SBG Final Grade Setup Validation.sql */
```
- **Tables / Views:** `gradeschoolconfig`, `schools`  
- **Key Joins / Filters:** Filter on `yearid=30`.  
- **Parameters:** None.

### 18. SBG List of Domains.sql  
**Purpose:** Enumerate domains used in SBG reporting.  
```sql
/* Full query in: SBG/SBG List of Domains.sql */
```
- **Tables / Views:** `ps_enrollment_all`, `standards`, `standardsgrades`, `Students`  
- **Key Joins / Filters:** Filter on `stg.yearid=24`.  
- **Parameters:** None.

### 19. SBG Num Assignments Per Standard PTP.sql  
**Purpose:** Count assignments per standard for the "PTP" (Performance-Task-Package).  
```sql
/* Full query in: SBG/SBG Num Assignments Per Standard PTP.sql */
```
- **Tables / Views:** `Assignment`, `AssignmentSection`, `AssignmentStandardAssoc`, `CC`, `Courses`, `dual`, `psm_assignmentstandard`, `psm_assignmentstandardscore`, `psm_grade`, `psm_gradescale`, `psm_reportcarditem`, `psm_reportcarditemgrade`, `psm_reportingterm`, `psm_sectionassignment`, `psm_sectionenrollment`, `psm_standard`, `schools`, `SchoolStaff`, `sections`, `Standard`, `StandardScore`, `Students`, `SYNC_SectionEnrollmentMap`, `SYNC_StdConversionMap`, `teachers`, `terms`, `USERS`  
- **Key Joins / Filters:** Extensive joins across assignment, standard, gradebook, and sync tables.  
- **Parameters:** None.

### 20. SBG Percent Proficient by Year-Grade-Subject.sql  
**Purpose:** Percent-proficient calculations broken down by year, grade, and subject.  
```sql
/* Full query in: SBG/SBG Percent Proficient by Year-Grade-Subject.sql */
```
- **Tables / Views:** `domainAvg` (CTE), `REENROLLMENTS`, `Sections`, `sg` (derived), `ST` (CTE), `STANDARD`, `STANDARDGRADEROLLUP`, `StandardGradeSection`, `Students`, `Termbins`, `Terms`  
- **Key Joins / Filters:** Filter on `s.YEARID = 27`; `sg.row_num=1`.  
- **Parameters:** None.

### 21. SBG Subject Area Score Aggregate.sql  
**Purpose:** Aggregate subject-area scores across schools/terms.  
```sql
/* Full query in: SBG/SBG Subject Area Score Aggregate.sql */
```
- **Tables / Views:** `schools`, `standards`, `STANDARDSGRADES`, `students`, `subjScores` (CTE), `tb` (CTE), `termbins`, `terms`  
- **Key Joins / Filters:** Standard joins to aggregate scores by subject.  
- **Parameters:** None.

### 22. SBG Subject Average PS 9.sql  
**Purpose:** Subject-average for the PS 9 (PowerSchool 9) framework.  
```sql
/* Full query in: SBG/SBG Subject Average PS 9.sql */
```
- **Tables / Views:** `stan` (CTE), `STANDARD`, `STANDARDGRADESECTION`, `students`  
- **Key Joins / Filters:** Standard joins to link standards to grade sections.  
- **Parameters:** None.

### 23. SBG Subject Avg By Year.sql  
**Purpose:** Yearly average per subject.  
```sql
/* Full query in: SBG/SBG Subject Avg By Year.sql */
```
- **Tables / Views:** `grLvlByYr` (CTE), `Prefs`, `reenrollments`, `schools`, `standards`, `STANDARDSGRADES`, `students`, `tb` (CTE), `termbins`, `terms`, `the` (CTE)  
- **Key Joins / Filters:** Filter on school number from `Prefs` table.  
- **Parameters:** None.

### 24. SBG Teacher Gradebook calculation.sql  
**Purpose:** Compute gradebook values for teachers (used in SBG reporting).  
```sql
/* Full query in: SBG/SBG Teacher Gradebook calculation.sql */
```
- **Tables / Views:** `courses`, `dual`, `gradeschoolconfig`, `gradesectionconfig`, `params` (CTE), `schools`, `schoolstaff`, `sections`, `terms`, `users`  
- **Key Joins / Filters:** Filter on `yearid=~(curyearid)`.  
- **Parameters:** None (parameter reference in comment).

### 25. Viewpoint Common Assessment load.sql  
**Purpose:** Load common assessment data for the Viewpoint platform.  
```sql
/* Full query in: SBG/Viewpoint Common Assessment load.sql */
```
- **Tables / Views:** `Prefs`, `schools`, `sg` (derived), `st` (CTE), `STANDARD`, `StandardGradeRollup`, `StandardGradeSection`, `students`, `tb` (CTE), `termbins`, `the` (CTE), `using` (CTE)  
- **Key Joins / Filters:** Filter on specific student numbers (`618636, 618727`); school number from `Prefs`.  
- **Parameters:** None.

### 26. VPR Target copy for new year.sql  
**Purpose:** Copy VPR target data for a new year.  
```sql
/* Full query in: SBG/VPR Target copy for new year.sql */
```
- **Tables / Views:** `standard`, `U_CLG_ARC_TRGTS`  
- **Key Joins / Filters:** Filter on `nystd.yearid=33`.  
- **Parameters:** None.

### 27. VPR Target copy for new year wNew standards.sql  
**Purpose:** Copy VPR target data for a new year with new standards.  
```sql
/* Full query in: SBG/VPR Target copy for new year wNew standards.sql */
```
- **Tables / Views:** `standard`, `U_CLG_ARC_TRGTS`  
- **Key Joins / Filters:** Filter on `nystd.yearid=34`.  
- **Parameters:** None.

### 28. VPR Target copy for new year wNew standards and storecodes.sql  
**Purpose:** Copy VPR target data for a new year with new standards and store codes.  
```sql
/* Full query in: SBG/VPR Target copy for new year wNew standards and storecodes.sql */
```
- **Tables / Views:** `codes` (CTE), `standard`, `U_CLG_ARC_TRGTS`  
- **Key Joins / Filters:** Filter on `nystd.ISACTIVE=1` AND `yearid=33`.  
- **Parameters:** None.

---

### How to use this file  

- **Copy-paste** the sections you need into your own documentation or a knowledge-base.  
- The **Purpose** field gives a quick description; the **SQL block** can be run directly (after adjusting bind variables if any).  
- **Tables / Views** list the PowerSchool objects involved — useful for data-model discovery.  
- **Hints / Quirks** highlight Oracle-specific constructs you may need to adapt when moving to another RDBMS.  

---

*Generated automatically by OpenCode using parallel sub-agents for parsing.*
