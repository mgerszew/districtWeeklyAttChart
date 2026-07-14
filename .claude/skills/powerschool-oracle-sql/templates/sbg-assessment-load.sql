-- ============================================
-- SBG Template: Assessment Load / Bulk Import
-- Group: Assessment Loading (Queries #19, #25)
-- Tables: Assignment, AssignmentSection, AssignmentStandardAssoc, CC, Courses,
--         psm_assignmentstandard, psm_assignmentstandardscore, psm_grade,
--         psm_gradescale, psm_reportcarditem, psm_reportcarditemgrade,
--         psm_reportingterm, psm_sectionassignment, psm_sectionenrollment,
--         psm_standard, schools, SchoolStaff, sections, Standard,
--         StandardScore, Students, SYNC_SectionEnrollmentMap, SYNC_StdConversionMap,
--         teachers, terms, USERS
-- ============================================

WITH params AS (
  SELECT 
    28 AS yearid,            -- Year ID
    84 AS schoolid,          -- School number
    'IMPORT_2024_Q3' AS batch_id  -- Import batch identifier
  FROM dual
),
-- Stage 1: Assignments to import
stg_assignments AS (
  SELECT 
    a.name,
    a.identifier,
    a.category,
    a.maxpoints,
    a.dateassigned,
    a.datedue,
    a.sectionid,
    sec.course_number,
    c.course_name,
    c.credittype
  FROM assignment a
  JOIN sections sec ON sec.id = a.sectionid
  JOIN courses c ON c.course_number = sec.course_number
  WHERE sec.schoolid = (SELECT schoolid FROM params)
    AND a.batch_id = (SELECT batch_id FROM params)  -- Track import batches
),
-- Stage 2: Assignment-Standard associations
stg_assn_standards AS (
  SELECT 
    asa.assignmentid,
    asa.standardid,
    s.identifier AS standard_identifier,
    s.name AS standard_name
  FROM assignmentstandardassoc asa
  JOIN standard s ON s.id = asa.standardid
  WHERE s.yearid = (SELECT yearid FROM params)
),
-- Stage 3: Student scores per assignment-standard
stg_scores AS (
  SELECT 
    sc.studentid,
    sc.assignmentid,
    sc.standardid,
    sc.score,
    sc.points_earned,
    sc.points_possible,
    stu.lastfirst AS student_name,
    stu.grade_level
  FROM standardscore sc
  JOIN students stu ON stu.id = sc.studentid
  WHERE stu.enroll_status = 0
    AND stu.schoolid = (SELECT schoolid FROM params)
),
-- Stage 4: PSM tables (report card sync)
stg_psm_standards AS (
  SELECT 
    psm.assignmentid,
    psm.standardid,
    psm.sectionid
  FROM psm_assignmentstandard psm
  WHERE psm.batch_id = (SELECT batch_id FROM params)
),
stg_psm_scores AS (
  SELECT 
    pass.studentid,
    pass.assignmentstandardid,
    pass.score,
    pass.points_earned,
    pass.points_possible
  FROM psm_assignmentstandardscore pass
  WHERE pass.batch_id = (SELECT batch_id FROM params)
),
-- Validation: Check for missing required fields
validation AS (
  SELECT 
    'Missing assignment name' AS issue,
    COUNT(*) AS count
  FROM stg_assignments
  WHERE name IS NULL OR name = ''
  UNION ALL
  SELECT 
    'Assignment without standards' AS issue,
    COUNT(*) AS count
  FROM stg_assignments a
  LEFT JOIN stg_assn_standards sa ON sa.assignmentid = a.identifier
  WHERE sa.assignmentid IS NULL
  UNION ALL
  SELECT 
    'Score without matching assignment' AS issue,
    COUNT(*) AS count
  FROM stg_scores s
  LEFT JOIN stg_assignments a ON a.identifier = s.assignmentid
  WHERE a.identifier IS NULL
  UNION ALL
  SELECT 
    'Score for inactive student' AS issue,
    COUNT(*) AS count
  FROM stg_scores s
  JOIN students stu ON stu.id = s.studentid
  WHERE stu.enroll_status != 0
)
-- ============================================
-- FINAL: Validation Report (run before import)
-- ============================================
SELECT * FROM validation WHERE count > 0