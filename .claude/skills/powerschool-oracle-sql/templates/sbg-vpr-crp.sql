-- ============================================
-- SBG Template: VPR/CRP Targets
-- Group: VPR/CRP (Queries #3, #4, #12, #26, #27, #28)
-- Tables: U_CLG_ARC_TRGTS, STANDARD, STANDARDGRADESECTION, STANDARDCOURSEASSOC, sections, terms
-- ============================================

WITH params AS (
  SELECT 
    28 AS yearid,            -- Current year (for copying FROM)
    29 AS new_yearid,        -- New year (for copying TO)
    84 AS schoolid,          -- School number
    'Q3' AS storecode        -- Store code
  FROM dual
),
targets_old AS (
  SELECT trg.standardid, trg.storecode, trg.targetvalue, trg.proficiency_threshold, trg.gradelevel
  FROM U_CLG_ARC_TRGTS trg
  WHERE trg.yearid = (SELECT yearid FROM params)
    AND trg.isactive = 1
),
standards_new AS (
  SELECT s.id, s.identifier, s.name, s.yearid
  FROM standard s
  WHERE s.yearid = (SELECT new_yearid FROM params)
    AND s.isactive = 1
),
course_standards AS (
  SELECT sca.course_number, sca.standardid
  FROM standardcourseassoc sca
  JOIN standard s ON s.id = sca.standardid
  WHERE s.yearid = (SELECT new_yearid FROM params)
),
sections_new AS (
  SELECT sec.id, sec.course_number, sec.schoolid
  FROM sections sec
  JOIN terms t ON t.id = sec.termid
  WHERE t.yearid = (SELECT new_yearid FROM params)
    AND t.isyearrec = 1
    AND sec.schoolid = (SELECT schoolid FROM params)
)

-- ============================================
-- VARIANT: CRP Completion (Query #12)
-- ============================================
-- WITH params AS (SELECT 28 AS yearid, 'Q3' AS storecode FROM dual),
-- stulist AS (SELECT column_value AS studentid FROM TABLE(sys.odcinumberlist(12345, 67890))),
-- sg AS ( ... standard grade section with row_num=1 ... ),
-- crp_items AS (
--   SELECT s.id FROM standard s WHERE s.identifier LIKE 'CRP%'
-- )
-- SELECT 
--   sg.studentid,
--   sg.standardid,
--   s.identifier,
--   sg.standardgrade,
--   CASE WHEN sg.standardgrade >= 3 THEN 'Complete' ELSE 'Incomplete' END AS status
-- FROM sg
-- JOIN crp_items c ON c.id = sg.standardid
-- WHERE sg.studentid IN (SELECT studentid FROM stulist)
--   AND sg.row_num = 1;

-- ============================================
-- VARIANT: EmpowerED CRP Data Pull (Query #3)
-- ============================================
-- WITH params AS (SELECT 28 AS yearid FROM dual),
-- sqlParams AS (
--   SELECT p.yearid, t.firstday, t.lastday
--   FROM params p
--   JOIN terms t ON t.yearid = p.yearid AND t.isyearrec = 1 AND t.schoolid = 84
-- ),
-- crp_stds AS (SELECT id FROM standard WHERE identifier LIKE 'CRP%' AND yearid = (SELECT yearid FROM params))
-- SELECT 
--   stu.id AS student_id,
--   stu.lastfirst,
--   sec.id AS section_id,
--   c.course_number,
--   s.identifier AS standard_id,
--   sgs.standardgrade,
--   sgs.storecode
-- FROM students stu
-- JOIN cc ON cc.studentid = stu.id
-- JOIN sections sec ON sec.id = cc.sectionid
-- JOIN courses c ON c.course_number = sec.course_number
-- JOIN standardgradesection sgs ON sgs.sectionid = sec.id AND sgs.studentid = stu.id
-- JOIN standard s ON s.id = sgs.standardid
-- WHERE c.course_number IN (SELECT course_number FROM course_standards WHERE standardid IN (SELECT id FROM crp_stds))
--   AND sgs.storecode = (SELECT storecode FROM params)
--   AND stu.enroll_status = 0