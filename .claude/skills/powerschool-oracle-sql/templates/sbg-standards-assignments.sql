-- ============================================
-- SBG Template: Standards & Assignments
-- Group: Standards & Assignments (Queries #1, #8)
-- Tables: ASSIGNMENTSECTION, ASSIGNMENTSTANDARDASSOC, sections, STANDARD, terms
-- ============================================

WITH params AS (
  SELECT 
    28 AS yearid,            -- Standards year
    84 AS schoolid,          -- School number
    'ELA' AS domain_filter   -- Domain prefix (ELA, MAT, SCI, etc.)
  FROM dual
),
std AS (
  SELECT s.id, s.identifier, s.name, s.description, s.yearid, s.standardgradelevelid
  FROM standard s
  WHERE s.yearid = (SELECT yearid FROM params)
    AND s.identifier LIKE (SELECT domain_filter || '%' FROM params)
),
sec AS (
  SELECT sec.id, sec.course_number, sec.schoolid, sec.termid
  FROM sections sec
  JOIN terms t ON t.id = sec.termid
  WHERE t.yearid = (SELECT yearid FROM params)
    AND t.isyearrec = 1
    AND sec.schoolid = (SELECT schoolid FROM params)
),
asa AS (
  SELECT asa.assignmentid, asa.standardid
  FROM assignmentstandardassoc asa
),
assn AS (
  SELECT a.id, a.name, a.identifier, a.sectionid, a.maxpoints
  FROM assignment a
  JOIN sec s ON s.id = a.sectionid
)
-- ============================================
-- FINAL: Assignment-Standard Links
-- ============================================
SELECT 
  a.identifier AS assignment_id,
  a.name AS assignment_name,
  s.identifier AS standard_id,
  s.name AS standard_name,
  s.description AS standard_desc
FROM assn a
JOIN asa ON asa.assignmentid = a.id
JOIN std s ON s.id = asa.standardid
ORDER BY s.identifier, a.identifier

-- ============================================
-- ALTERNATIVE: Course-Standard Links (Query #13)
-- ============================================
-- WITH params AS (SELECT 33 AS yearid FROM dual),
-- sca AS (
--   SELECT sca.course_number, sca.standardid
--   FROM standardcourseassoc sca
-- ),
-- std AS (
--   SELECT id, identifier, name, yearid FROM standard WHERE yearid IN (33, 34)
-- )
-- SELECT c.course_number, c.course_name, s.identifier, s.name
-- FROM courses c
-- JOIN sca ON sca.course_number = c.course_number
-- JOIN std s ON s.id = sca.standardid
-- WHERE s.yearid IN (33, 34)
-- ORDER BY c.course_number, s.identifier