-- ============================================
-- SBG Template: Report Card / PSM
-- Group: Report Card/PSM (Queries #2, #9)
-- Tables: psm_*, standardgradesection, standard, sections, terms, students
-- ============================================

WITH params AS (
  SELECT 
    28 AS yearid,            -- Year ID
    84 AS schoolid,          -- School number
    'Q3' AS storecode,       -- Reporting term
    130238 AS student_dcid   -- Specific student (DCID)
  FROM dual
),
term_year AS (
  SELECT t.id, t.firstday, t.lastday, t.storecode
  FROM terms t
  WHERE t.yearid = (SELECT yearid FROM params)
    AND t.isyearrec = 1
    AND t.schoolid = (SELECT schoolid FROM params)
),
-- Query #2: PSM Report Card Items for specific student
psm_items AS (
  SELECT 
    psp.studentidentifier,
    psp.studentsdcid,
    psi.itemname,
    psi.itemdescription,
    psi.reportingtermid,
    psig.grade AS item_grade,
    psig.percent AS item_percent,
    psig.points AS item_points,
    psig.comment AS item_comment
  FROM psm_reportcarditem psi
  JOIN psm_reportcarditemgrade psig ON psig.reportcarditemid = psi.id
  JOIN psm_sectionenrollment pse ON pse.id = psig.sectionenrollmentid
  JOIN psm_assignmentstandard pas ON pas.standardid = psi.standardid
  JOIN psm_sectionassignment psa ON psa.id = pas.sectionassignmentid
  JOIN psm_reportingterm prt ON prt.id = psi.reportingtermid
  JOIN students s ON s.dcid = pse.studentsdcid
  WHERE s.dcid = (SELECT student_dcid FROM params)
    AND prt.yearid = (SELECT yearid FROM params)
),
-- Standard Grade Section data (for report cards)
std_grades AS (
  SELECT 
    sgs.studentid,
    sgs.standardid,
    sgs.standardgrade,
    sgs.storecode,
    s.identifier AS std_identifier,
    s.name AS std_name,
    s.description,
    sec.course_number,
    c.course_name,
    c.credittype
  FROM standardgradesection sgs
  JOIN standard s ON s.id = sgs.standardid
  JOIN sections sec ON sec.id = sgs.sectionid
  JOIN courses c ON c.course_number = sec.course_number
  JOIN terms t ON t.id = sec.termid
  WHERE t.yearid = (SELECT yearid FROM params)
    AND sgs.storecode = (SELECT storecode FROM params)
    AND sec.schoolid = (SELECT schoolid FROM params)
),
student_info AS (
  SELECT s.id, s.dcid, s.lastfirst, s.grade_level
  FROM students s
  WHERE s.dcid = (SELECT student_dcid FROM params)
)
-- ============================================
-- FINAL: Student Report Card (PSM + SGS Combined)
-- ============================================
SELECT 
  si.lastfirst AS student_name,
  si.grade_level,
  c.course_name,
  sg.std_identifier AS standard_code,
  sg.std_name AS standard_name,
  sg.standardgrade AS score_1_4,
  sg.storecode,
  pi.itemname AS psm_item,
  pi.item_grade AS psm_alpha_grade,
  pi.item_percent AS psm_percent
FROM student_info si
LEFT JOIN std_grades sg ON sg.studentid = si.id
LEFT JOIN courses c ON c.course_number = sg.course_number
LEFT JOIN psm_items pi ON pi.studentsdcid = si.dcid
  AND pi.reportingtermid = (SELECT id FROM term_year WHERE storecode = (SELECT storecode FROM params))
ORDER BY c.course_name, sg.std_identifier

-- ============================================
-- VARIANT: Count of Scores by Identifier (Query #9)
-- ============================================
-- WITH params AS (SELECT 28 AS yearid FROM dual),
-- score_counts AS (
--   SELECT 
--     st.identifier AS standard_identifier,
--     a.identifier AS assignment_identifier,
--     COUNT(ss.score) AS score_count,
--     AVG(ss.score) AS avg_score,
--     MIN(ss.score) AS min_score,
--     MAX(ss.score) AS max_score
--   FROM standard st
--   JOIN assignmentstandardassoc asa ON asa.standardid = st.id
--   JOIN assignment a ON a.id = asa.assignmentid
--   JOIN standardscore ss ON ss.assignmentid = a.id AND ss.standardid = st.id
--   WHERE st.yearid = (SELECT yearid FROM params)
--     AND st.identifier LIKE 'MAT-01.OA%'
--   GROUP BY st.identifier, a.identifier
-- )
-- SELECT * FROM score_counts ORDER BY standard_identifier, score_count DESC;

-- ============================================
-- VARIANT: PSM Section Enrollment Grades
-- ============================================
-- WITH params AS (SELECT 28 AS yearid, 130238 AS student_dcid FROM dual),
-- section_enrollments AS (
--   SELECT 
--     pse.id AS enrollment_id,
--     pse.sectionid,
--     pse.studentid,
--     sec.course_number,
--     c.course_name
--   FROM psm_sectionenrollment pse
--   JOIN sections sec ON sec.id = pse.sectionid
--   JOIN courses c ON c.course_number = sec.course_number
--   JOIN terms t ON t.id = sec.termid
--   WHERE t.yearid = (SELECT yearid FROM params)
--     AND pse.studentid = (SELECT student_dcid FROM params)
-- ),
-- enrollment_grades AS (
--   SELECT 
--     se.enrollment_id,
--     se.course_name,
--     psig.grade,
--     psig.percent,
--     psig.points,
--     prt.name AS term_name
--   FROM section_enrollments se
--   JOIN psm_reportcarditemgrade psig ON psig.sectionenrollmentid = se.enrollment_id
--   JOIN psm_reportcarditem psi ON psi.id = psig.reportcarditemid
--   JOIN psm_reportingterm prt ON prt.id = psi.reportingtermid
--   WHERE prt.yearid = (SELECT yearid FROM params)
-- )
-- SELECT * FROM enrollment_grades ORDER BY course_name, term_name