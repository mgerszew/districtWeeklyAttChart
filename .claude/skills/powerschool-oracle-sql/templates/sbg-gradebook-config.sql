-- ============================================
-- SBG Template: Gradebook / Config Validation
-- Group: Gradebook/Config (Queries #17, #24)
-- Tables: gradeschoolconfig, gradesectionconfig, schools, courses, sections, terms, schoolstaff, users
-- ============================================

WITH params AS (
  SELECT 
    30 AS yearid,            -- Year ID
    84 AS schoolid           -- School number
  FROM dual
),
term_year AS (
  SELECT t.id, t.firstday, t.lastday
  FROM terms t
  WHERE t.yearid = (SELECT yearid FROM params)
    AND t.isyearrec = 1
    AND t.schoolid = (SELECT schoolid FROM params)
),
-- Query #17: Final Grade Setup Validation
grade_config AS (
  SELECT 
    gsc.schoolid,
    gsc.yearid,
    gsc.gradetype,
    gsc.gradetypename,
    gsc.calculationtype,
    gsc.includeinfinalgrade,
    gsc.weight
  FROM gradeschoolconfig gsc
  WHERE gsc.yearid = (SELECT yearid FROM params)
    AND gsc.schoolid = (SELECT schoolid FROM params)
),
section_config AS (
  SELECT 
    gsc.sectionid,
    gsc.yearid,
    gsc.gradetype,
    gsc.calculationtype,
    gsc.weight,
    sec.course_number,
    c.course_name
  FROM gradesectionconfig gsc
  JOIN sections sec ON sec.id = gsc.sectionid
  JOIN courses c ON c.course_number = sec.course_number
  JOIN term_year ty ON ty.id = sec.termid
  WHERE gsc.yearid = (SELECT yearid FROM params)
),
schools AS (
  SELECT s.school_number, s.name
  FROM schools s
  WHERE s.school_number = (SELECT schoolid FROM params)
)
-- ============================================
-- FINAL: Grade Config Validation Report
-- ============================================
SELECT 
  gc.schoolid,
  sch.name AS school_name,
  gc.gradetype,
  gc.gradetypename,
  gc.calculationtype,
  gc.includeinfinalgrade,
  gc.weight,
  'School Level' AS config_level
FROM grade_config gc
JOIN schools sch ON sch.school_number = gc.schoolid
UNION ALL
SELECT 
  sc.sectionid AS schoolid,
  c.course_name AS school_name,
  sc.gradetype,
  '' AS gradetypename,
  sc.calculationtype,
  1 AS includeinfinalgrade,
  sc.weight,
  'Section Level' AS config_level
FROM section_config sc
JOIN courses c ON c.course_number = sc.course_number
ORDER BY config_level, schoolid, gradetype

-- ============================================
-- VARIANT: Teacher Gradebook Calculation (Query #24)
-- ============================================
-- WITH params AS (SELECT 30 AS yearid, 84 AS schoolid FROM dual),
-- term_year AS (
--   SELECT t.id, t.firstday, t.lastday
--   FROM terms t
--   WHERE t.yearid = (SELECT yearid FROM params)
--     AND t.isyearrec = 1
--     AND t.schoolid = (SELECT schoolid FROM params)
-- ),
-- teacher_sections AS (
--   SELECT 
--     sec.id AS sectionid,
--     sec.course_number,
--     sec.teacher,
--     c.course_name,
--     c.credittype
--   FROM sections sec
--   JOIN courses c ON c.course_number = sec.course_number
--   JOIN term_year ty ON ty.id = sec.termid
--   WHERE sec.schoolid = (SELECT schoolid FROM params)
-- ),
-- teacher_info AS (
--   SELECT 
--     ss.id AS staffid,
--     u.lastfirst AS teacher_name,
--     u.email
--   FROM schoolstaff ss
--   JOIN users u ON u.dcid = ss.users_dcid
--   WHERE ss.schoolid = (SELECT schoolid FROM params)
-- )
-- SELECT 
--   ts.course_number,
--   c.course_name,
--   ti.teacher_name,
--   gc.gradetype,
--   gc.calculationtype,
--   gc.weight
-- FROM teacher_sections ts
-- JOIN teacher_info ti ON ti.staffid = ts.teacher
-- JOIN courses c ON c.course_number = ts.course_number
-- JOIN grade_config gc ON gc.schoolid = (SELECT schoolid FROM params) AND gc.yearid = (SELECT yearid FROM params)
-- WHERE gc.gradetype IN ('S1','S2','Y1')
-- ORDER BY ti.teacher_name, ts.course_number