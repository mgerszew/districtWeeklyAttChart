-- ============================================
-- SBG Template: Subject/Domain Averages
-- Group: Subject Averages (Queries #6, #7, #14, #15, #21, #22, #23)
-- Tables: STANDARDSGRADES, standards, ps_enrollment_all, cc, sections, termbins, students
-- ============================================

WITH params AS (
  SELECT 
    28 AS yearid,            -- Year ID
    84 AS schoolid,          -- School number
    'Q3' AS storecode        -- Store code
  FROM dual
),
tb AS (
  SELECT termid, storecode, gradelevel
  FROM termbins
  WHERE yearid = (SELECT yearid FROM params)
),
enr AS (
  SELECT pea.studentid, pea.schoolid, pea.grade_level
  FROM ps_enrollment_all pea
  WHERE pea.yearid = (SELECT yearid FROM params)
    AND pea.schoolid = (SELECT schoolid FROM params)
    AND pea.entrydate <= (SELECT lastday FROM terms WHERE yearid = (SELECT yearid FROM params) AND isyearrec = 1 AND schoolid = (SELECT schoolid FROM params))
    AND pea.exitdate > (SELECT firstday FROM terms WHERE yearid = (SELECT yearid FROM params) AND isyearrec = 1 AND schoolid = (SELECT schoolid FROM params))
),
sg_grades AS (
  SELECT 
    sg.studentid,
    sg.standardid,
    sg.storecode,
    sg.grade,
    sg.percent,
    sg.points,
    s.identifier AS std_identifier,
    s.name AS std_name,
    s.standardidentifier AS parent_identifier
  FROM standardsgrades sg
  JOIN standard s ON s.id = sg.standardid
  JOIN enr e ON e.studentid = sg.studentid
  WHERE sg.yearid = (SELECT yearid FROM params)
    AND sg.storecode = (SELECT storecode FROM params)
),
domain_scores AS (
  SELECT 
    e.studentid,
    e.grade_level,
    s.parent_identifier AS domain_id,
    s.identifier AS standard_id,
    MAX(sg.percent) KEEP (DENSE_RANK FIRST ORDER BY sg.storecode) AS latest_percent,
    MAX(sg.grade) KEEP (DENSE_RANK FIRST ORDER BY sg.storecode) AS latest_grade
  FROM enr e
  JOIN sg_grades sg ON sg.studentid = e.studentid
  JOIN standard s ON s.id = sg.standardid
  WHERE s.standardidentifier IS NOT NULL  -- Has parent = domain
  GROUP BY e.studentid, e.grade_level, s.parent_identifier, s.identifier
),
student_domain_avg AS (
  SELECT 
    studentid,
    grade_level,
    domain_id,
    ROUND(AVG(latest_percent), 2) AS domain_avg_pct
  FROM domain_scores
  GROUP BY studentid, grade_level, domain_id
)
-- ============================================
-- FINAL: Subject/Domain Average by Grade
-- ============================================
SELECT 
  sda.grade_level,
  sda.domain_id,
  COUNT(*) AS student_count,
  ROUND(AVG(sda.domain_avg_pct), 2) AS avg_domain_pct,
  MIN(sda.domain_avg_pct) AS min_pct,
  MAX(sda.domain_avg_pct) AS max_pct,
  ROUND(STDDEV(sda.domain_avg_pct), 2) AS stddev_pct
FROM student_domain_avg sda
GROUP BY sda.grade_level, sda.domain_id
ORDER BY sda.grade_level, sda.domain_id

-- ============================================
-- VARIANT: Subject Area Aggregate (Query #21)
-- ============================================
-- WITH subjScores AS (
--   SELECT 
--     e.studentid, e.grade_level,
--     s.identifier AS subject_id,  -- Top-level (ELA, MAT, SCI)
--     AVG(sg.percent) AS subject_avg
--   FROM enr e
--   JOIN sg_grades sg ON sg.studentid = e.studentid
--   JOIN standard s ON s.id = sg.standardid
--   WHERE s.standardidentifier IS NULL  -- Top-level subjects
--   GROUP BY e.studentid, e.grade_level, s.identifier
-- )
-- SELECT grade_level, subject_id, COUNT(*), ROUND(AVG(subject_avg),2), MIN(subject_avg), MAX(subject_avg)
-- FROM subjScores GROUP BY grade_level, subject_id;

-- ============================================
-- VARIANT: PS9 Subject Average (Query #22)
-- ============================================
-- WITH stan AS (
--   SELECT sgs.studentid, sgs.standardid, sgs.standardgrade
--   FROM standardgradesection sgs
--   JOIN sections sec ON sec.id = sgs.sectionid
--   JOIN terms t ON t.id = sec.termid
--   WHERE t.yearid = (SELECT yearid FROM params)
--     AND sgs.storecode = (SELECT storecode FROM params)
-- )
-- SELECT stu.grade_level, s.identifier, ROUND(AVG(stan.standardgrade),2)
-- FROM stan
-- JOIN standard s ON s.id = stan.standardid
-- JOIN students stu ON stu.id = stan.studentid
-- WHERE s.standardidentifier IS NULL
-- GROUP BY stu.grade_level, s.identifier;

-- ============================================
-- VARIANT: Subject Avg By Year (Query #23)
-- ============================================
-- WITH grLvlByYr AS (
--   SELECT s.id, s.grade_level, t.yearid
--   FROM students s
--   JOIN terms t ON t.yearid = s.schoolid  -- or enrollment
--   WHERE t.isyearrec = 1
-- ),
-- subjScores AS (
--   SELECT 
--     glby.grade_level, glby.yearid,
--     st.identifier AS subject_id,
--     AVG(sg.percent) AS avg_pct
--   FROM grLvlByYr glby
--   JOIN standardsgrades sg ON sg.studentid = glby.id AND sg.yearid = glby.yearid
--   JOIN standard st ON st.id = sg.standardid
--   WHERE st.standardidentifier IS NULL
--   GROUP BY glby.grade_level, glby.yearid, st.identifier
-- )
-- SELECT * FROM subjScores ORDER BY yearid, grade_level, subject_id;

-- ============================================
-- VARIANT: SBAC Comparison (Query #6)
-- ============================================
-- Join domain_scores with external SBAC data table
-- SELECT ds.domain_id, ds.avg_domain_pct, sbac.score AS sbac_score
-- FROM student_domain_avg ds
-- LEFT JOIN sbac_results sbac ON sbac.studentid = ds.studentid AND sbac.subject = ds.domain_id