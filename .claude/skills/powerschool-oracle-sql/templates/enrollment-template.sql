-- =============================================
-- Enrollment Query Template
-- Category: Enrollment (Demographics, Class Counts, Snapshots, Rosters)
-- Tables: students, cc, sections, terms, courses, schools, PS_ENROLLMENT_ALL,
--         reenrollments, U_SECTIONS_BPS, U_SCHOOLS_BPS, S_ND_STU_X, STUDENTRACE
-- =============================================

WITH params AS (
  SELECT 
    33 AS yearid,                                     -- Year ID
    40 AS schoolid_min,                               -- School range min
    89 AS schoolid_max,                               -- School range max
    TO_DATE('10/01/2024','mm/dd/yyyy') AS snap_date,  -- Snapshot date
    'Homeroom' AS homeroom_course_filter              -- Course name pattern
  FROM dual
),
-- Term year record for section filtering
term_year AS (
  SELECT t.id AS termid, t.firstday, t.lastday
  FROM terms t
  WHERE t.yearid = (SELECT yearid FROM params)
    AND t.isyearrec = 1
),
-- Active students in school range
active_students AS (
  SELECT s.id, s.dcid, s.lastfirst, s.grade_level, s.ethnicity, s.gender, s.schoolid, s.entrydate, s.exitdate
  FROM students s
  WHERE s.enroll_status = 0
    AND s.schoolid BETWEEN (SELECT schoolid_min FROM params) AND (SELECT schoolid_max FROM params)
),
-- Student demographics (state custom fields)
stu_demo AS (
  SELECT 
    s.id,
    s.ethnicity,
    snd.lep_indicator,
    snd.iep_indicator,
    snd.frl_status
  FROM active_students s
  LEFT JOIN S_ND_STU_X snd ON snd.studentsdcid = s.dcid
),
-- Current CC enrollments (active on snap_date)
cc_current AS (
  SELECT 
    cc.studentid,
    cc.sectionid,
    cc.dateenrolled,
    cc.dateleft,
    sec.course_number,
    sec.schoolid AS section_schoolid,
    sec.teacher,
    c.course_name,
    c.credittype
  FROM cc
  JOIN sections sec ON sec.id = cc.sectionid
  JOIN courses c ON c.course_number = sec.course_number
  JOIN term_year ty ON ty.termid = sec.termid
  WHERE cc.dateenrolled <= (SELECT snap_date FROM params)
    AND cc.dateleft > (SELECT snap_date FROM params)
    AND sec.schoolid BETWEEN (SELECT schoolid_min FROM params) AND (SELECT schoolid_max FROM params)
),
-- Teacher info
teachers AS (
  SELECT 
    ss.id AS staffid,
    u.lastfirst AS teacher_name,
    u.email AS teacher_email
  FROM schoolstaff ss
  JOIN users u ON u.dcid = ss.users_dcid
),
-- Homeroom sections (course_name LIKE '%Homeroom%')
homeroom_sections AS (
  SELECT sec.id AS sectionid, sec.course_number, sec.teacher
  FROM sections sec
  JOIN courses c ON c.course_number = sec.course_number
  JOIN term_year ty ON ty.termid = sec.termid
  WHERE c.course_name LIKE '%' || (SELECT homeroom_course_filter FROM params) || '%'
    AND sec.schoolid BETWEEN (SELECT schoolid_min FROM params) AND (SELECT schoolid_max FROM params)
)

-- =============================================
-- PATTERN 1: Enrollment Snapshot on Date
-- =============================================
-- SELECT 
--   sch.name AS school,
--   COUNT(*) AS enrollment
-- FROM active_students s
-- JOIN schools sch ON sch.school_number = s.schoolid
-- WHERE s.entrydate <= (SELECT snap_date FROM params)
--   AND s.exitdate > (SELECT snap_date FROM params)
-- GROUP BY sch.name
-- ORDER BY sch.name;

-- =============================================
-- PATTERN 2: Snapshot with Demographics
-- =============================================
-- SELECT 
--   sch.name AS school,
--   sd.grade_level,
--   DECODE(sd.ethnicity,1,'Am Indian',2,'Asian',3,'Black',4,'Hispanic',5,'White',6,'Pacific Isl','Other') AS ethnicity,
--   DECODE(sd.iep_indicator,1,'Yes','No') AS iep,
--   DECODE(sd.lep_indicator,1,'Yes','No') AS el,
--   DECODE(sd.frl_status,1,'Free',2,'Reduced','Paid') AS frl,
--   COUNT(*) AS cnt
-- FROM active_students s
-- JOIN schools sch ON sch.school_number = s.schoolid
-- JOIN stu_demo sd ON sd.id = s.id
-- WHERE s.entrydate <= (SELECT snap_date FROM params)
--   AND s.exitdate > (SELECT snap_date FROM params)
-- GROUP BY sch.name, sd.grade_level, sd.ethnicity, sd.iep_indicator, sd.lep_indicator, sd.frl_status
-- ORDER BY sch.name, sd.grade_level;

-- =============================================
-- PATTERN 3: Student Roster with Homeroom Teacher
-- =============================================
-- SELECT 
--   s.id AS student_number,
--   s.lastfirst AS student_name,
--   s.grade_level,
--   sch.name AS school,
--   t.teacher_name AS homeroom_teacher,
--   t.teacher_email
-- FROM active_students s
-- JOIN schools sch ON sch.school_number = s.schoolid
-- LEFT JOIN cc_current cc ON cc.studentid = s.id
-- LEFT JOIN homeroom_sections hs ON hs.sectionid = cc.sectionid
-- LEFT JOIN teachers t ON t.staffid = hs.teacher
-- WHERE s.entrydate <= (SELECT snap_date FROM params)
--   AND s.exitdate > (SELECT snap_date FROM params)
-- ORDER BY sch.name, s.grade_level, s.lastfirst;

-- =============================================
-- PATTERN 4: Class Counts by School/Grade
-- =============================================
-- SELECT 
--   sch.name AS school,
--   c.course_name,
--   COUNT(DISTINCT cc.sectionid) AS sections,
--   COUNT(*) AS enrollments
-- FROM cc_current cc
-- JOIN courses c ON c.course_number = cc.course_number
-- JOIN sections sec ON sec.id = cc.sectionid
-- JOIN schools sch ON sch.school_number = sec.schoolid
-- WHERE cc.studentid IN (SELECT id FROM active_students)
-- GROUP BY sch.name, c.course_name
-- ORDER BY sch.name, c.course_name;

-- =============================================
-- PATTERN 5: BECEP / Physical School Different
-- =============================================
-- SELECT 
--   sec.id AS sectionid,
--   c.course_name,
--   sch_home.name AS home_school,
--   sch_phys.name AS physical_school,
--   usb.physical_schoolid
-- FROM U_SECTIONS_BPS usb
-- JOIN sections sec ON sec.id = usb.id
-- JOIN courses c ON c.course_number = sec.course_number
-- JOIN schools sch_home ON sch_home.school_number = sec.schoolid
-- JOIN schools sch_phys ON sch_phys.school_number = usb.physical_schoolid
-- WHERE usb.physical_schoolid IS NOT NULL
--   AND sch_home.school_number != sch_phys.school_number;

-- =============================================
-- PATTERN 6: Panorama Roster (Deduplicated)
-- =============================================
-- WITH enr AS (
--   SELECT 
--     s.*, 
--     ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.entrydate DESC) AS rn
--   FROM students s
--   WHERE s.enroll_status IN (0, -1)
-- )
-- SELECT * FROM enr WHERE rn = 1;

-- =============================================
-- PATTERN 7: New Students by Month
-- =============================================
-- SELECT 
--   TO_CHAR(snd.whencreated, 'YYYY-MM') AS month,
--   COUNT(*) AS new_students
-- FROM S_ND_STU_X snd
-- JOIN students s ON s.dcid = snd.studentsdcid
-- WHERE EXTRACT(YEAR FROM snd.whencreated) >= 2018
-- GROUP BY TO_CHAR(snd.whencreated, 'YYYY-MM')
-- ORDER BY month;

-- =============================================
-- PATTERN 8: Section Counts for BOY Reporting
-- =============================================
-- SELECT 
--   sch.name AS school,
--   c.course_number,
--   c.course_name,
--   COUNT(DISTINCT sec.id) AS section_count
-- FROM sections sec
-- JOIN courses c ON c.course_number = sec.course_number
-- JOIN schools sch ON sch.school_number = sec.schoolid
-- JOIN term_year ty ON ty.termid = sec.termid
-- WHERE sch.school_number BETWEEN (SELECT schoolid_min FROM params) AND (SELECT schoolid_max FROM params)
-- GROUP BY sch.name, c.course_number, c.course_name
-- ORDER BY sch.name, c.course_number