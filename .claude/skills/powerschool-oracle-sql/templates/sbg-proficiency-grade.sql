-- ============================================
-- SBG Template: Proficiency by Grade Level
-- Group: Proficiency (Queries #5, #11, #16, #20)
-- Tables: STANDARD, STANDARDGRADESECTION, STANDARDGRADEROLLUP, students, sections, terms
-- CTEs: params, ST, sg, domainAvg, Termbins
-- ============================================

WITH params AS (
  SELECT 
    28 AS yearid,            -- School year
    84 AS schoolid,          -- School number
    'Q3' AS storecode        -- Reporting term
  FROM dual
),
term_bins AS (
  SELECT termid, storecode, gradelevel
  FROM termbins
  WHERE yearid = (SELECT yearid FROM params)
),
-- StandardGradeSection joined to Standard, Section, Term
ST AS (
  SELECT 
    sgs.*, 
    s.identifier, 
    s.name AS standard_name, 
    s.yearid AS standard_yearid,
    sec.id AS section_id,
    sec.course_number,
    sec.schoolid AS section_schoolid,
    t.id AS term_id,
    t.yearid AS term_yearid,
    t.gradelevel AS term_gradelevel
  FROM standardgradesection sgs
  JOIN standard s ON s.id = sgs.standardid
  JOIN sections sec ON sec.id = sgs.sectionid
  JOIN terms t ON t.id = sec.termid
  WHERE t.yearid = (SELECT yearid FROM params)
    AND sgs.storecode = (SELECT storecode FROM params)
),
-- Latest score per student per standard
sg AS (
  SELECT 
    st.*, 
    ROW_NUMBER() OVER (PARTITION BY st.studentid, st.standardid ORDER BY st.standardgrade DESC) AS row_num
  FROM ST st
  WHERE st.standardgrade IS NOT NULL
),
-- Domain averages (for behavior/electives/core grouping)
domainAvg AS (
  SELECT 
    s.identifier AS domain_identifier,
    s.name AS domain_name,
    AVG(sgs.standardgrade) AS avg_score
  FROM standardgradesection sgs
  JOIN standard s ON s.id = sgs.standardid
  WHERE sgs.storecode = (SELECT storecode FROM params)
    AND s.standardidentifier IS NOT NULL  -- Has parent = is child standard
  GROUP BY s.identifier, s.name
)
-- ============================================
-- FINAL: % Proficient by Grade Level (Behavior/Core/Electives)
-- ============================================
SELECT 
  stu.grade_level,
  COUNT(DISTINCT sg.studentid) AS students_assessed,
  COUNT(CASE WHEN sg.standardgrade >= 3 THEN 1 END) AS proficient_count,
  ROUND(COUNT(CASE WHEN sg.standardgrade >= 3 THEN 1 END) * 100.0 / NULLIF(COUNT(DISTINCT sg.studentid), 0), 1) AS pct_proficient,
  ROUND(AVG(sg.standardgrade), 2) AS avg_score
FROM sg
JOIN students stu ON stu.id = sg.studentid
JOIN standard s ON s.id = sg.standardid
JOIN standardgraderollup sgr ON sgr.childstandardid = s.id
WHERE sg.row_num = 1
  AND stu.enroll_status = 0
  AND stu.schoolid = (SELECT schoolid FROM params)
  -- Filter by domain type (uncomment one):
  -- AND sgr.parentstandardid IN (SELECT id FROM standard WHERE identifier LIKE 'BEH%')  -- Behavior
  -- AND sgr.parentstandardid IN (SELECT id FROM standard WHERE identifier IN ('ELA','MAT','SCI','SS'))  -- Core
  -- AND sgr.parentstandardid IN (SELECT id FROM standard WHERE identifier LIKE 'ART%' OR identifier LIKE 'PE%' OR identifier LIKE 'MUS%')  -- Electives
GROUP BY stu.grade_level
ORDER BY stu.grade_level

-- ============================================
-- VARIANT: % Proficient by Year-Grade-Subject (Query #20)
-- ============================================
-- SELECT 
--   p.yearid AS year,
--   stu.grade_level AS grade,
--   sgr.parentstandardid AS subject_parent,
--   s.identifier AS standard_id,
--   COUNT(DISTINCT sg.studentid) AS assessed,
--   COUNT(CASE WHEN sg.standardgrade >= 3 THEN 1 END) AS proficient,
--   ROUND(COUNT(CASE WHEN sg.standardgrade >= 3 THEN 1 END) * 100.0 / NULLIF(COUNT(DISTINCT sg.studentid),0), 1) AS pct_proficient
-- FROM sg
-- JOIN students stu ON stu.id = sg.studentid
-- JOIN standard s ON s.id = sg.standardid
-- JOIN standardgraderollup sgr ON sgr.childstandardid = s.id
-- JOIN params p ON 1=1
-- WHERE sg.row_num = 1
--   AND stu.enroll_status = 0
-- GROUP BY p.yearid, stu.grade_level, sgr.parentstandardid, s.identifier
-- ORDER BY p.yearid, stu.grade_level, sgr.parentstandardid;

-- ============================================
-- VARIANT: Student Improvement Year-over-Year (Query #10)
-- ============================================
-- WITH y1 AS (
--   SELECT studentid, standardid, standardgrade
--   FROM sg WHERE yearid = 28
-- ),
-- y2 AS (
--   SELECT studentid, standardid, standardgrade
--   FROM sg WHERE yearid = 29
-- )
-- SELECT 
--   y1.studentid,
--   y1.standardid,
--   y1.standardgrade AS grade_yr1,
--   y2.standardgrade AS grade_yr2,
--   y2.standardgrade - y1.standardgrade AS improvement
-- FROM y1
-- JOIN y2 ON y2.studentid = y1.studentid AND y2.standardid = y1.standardid
-- WHERE y1.standardgrade IS NOT NULL AND y2.standardgrade IS NOT NULL
--   AND y2.standardgrade > y1.standardgrade;

-- ============================================
-- VARIANT: Behavior Pct Proficient (Query #5)
-- ============================================
-- Same as main query but filter:
-- AND sgr.parentstandardid IN (SELECT id FROM standard WHERE identifier LIKE 'BEH%')

-- ============================================
-- VARIANT: Electives Pct Proficient (Query #16)
-- ============================================
-- Same as main query but filter:
-- AND sgr.parentstandardid IN (SELECT id FROM standard WHERE identifier IN ('ART','MUS','PE','TEC','WL','CTE'))