-- =============================================
-- Attendance Query Template
-- Category: Attendance (ADA/ADM, Tardies, Day Counts, Suspensions)
-- Tables: CALENDAR_DAY, TERMS, PS_ADAADM_MEETING_PTOD, PS_ATTENDANCE_MEETING,
--         students, reenrollments, schools, attendance_code, ps_period_att
-- =============================================

WITH params AS (
  SELECT 
    33 AS yearid,                                    -- Year ID (from TERMS.yearid)
    84 AS schoolid,                                  -- School number (FK to schools.school_number)
    TO_DATE('08/20/2024','mm/dd/yyyy') AS startdate, -- Range start
    TO_DATE('06/10/2025','mm/dd/yyyy') AS enddate,   -- Range end (exclusive of SYSDATE-1)
    0 AS min_membership                              -- Filter: membershipvalue > this
  FROM dual
),
-- Term year record for date boundaries
term_year AS (
  SELECT t.firstday, t.lastday
  FROM terms t
  WHERE t.yearid = (SELECT yearid FROM params)
    AND t.isyearrec = 1
    AND t.schoolid = (SELECT schoolid FROM params)
),
-- In-session calendar days in range
cal_days AS (
  SELECT cd.date_value, cd.day_in_school_year
  FROM calendar_day cd
  JOIN term_year ty ON 1=1
  WHERE cd.schoolid = (SELECT schoolid FROM params)
    AND cd.insession = 1
    AND cd.date_value >= (SELECT startdate FROM params)
    AND cd.date_value <= (SELECT enddate FROM params)
    AND cd.date_value < SYSDATE - 1              -- Exclude current day
),
-- First/last in-session day numbers
day_bounds AS (
  SELECT 
    MIN(day_in_school_year) AS first_day_num,
    MAX(day_in_school_year) AS last_day_num,
    COUNT(*) AS total_in_session
  FROM cal_days
),
-- ADA/ADM daily aggregates
ada_adm AS (
  SELECT 
    ada.calendardate,
    ada.membershipvalue,
    ada.ada,
    ada.adm,
    ada.tardy,
    ada.absent
  FROM ps_adaadm_meeting_ptod ada
  WHERE ada.schoolid = (SELECT schoolid FROM params)
    AND ada.calendardate BETWEEN (SELECT startdate FROM params) AND (SELECT enddate FROM params)
    AND ada.membershipvalue > (SELECT min_membership FROM params)
),
-- Student enrollment spans (current + historical)
student_spans AS (
  SELECT id AS studentid, entrydate, exitdate FROM students WHERE enroll_status = 0
  UNION ALL
  SELECT studentid, entrydate, exitdate FROM reenrollments WHERE enroll_status = 0
),
-- Meeting attendance (joined to ada for daily rates)
meeting_att AS (
  SELECT 
    m.studentid,
    m.att_date,
    ac.att_code,
    ac.presence_status_cd,
    m.periodid
  FROM PS_ATTENDANCE_MEETING m
  JOIN attendance_code ac ON ac.id = m.attendance_codeid
  WHERE m.att_date BETWEEN (SELECT startdate FROM params) AND (SELECT enddate FROM params)
    AND m.studentid IN (SELECT studentid FROM student_spans)
)

-- =============================================
-- PATTERN 1: ADA/ADM by School (Daily)
-- =============================================
-- SELECT 
--   ada.calendardate,
--   ada.ada,
--   ada.adm,
--   ROUND(ada.ada / NULLIF(ada.adm,0) * 100, 2) AS ada_pct,
--   ada.tardy,
--   ada.absent
-- FROM ada_adm ada
-- ORDER BY ada.calendardate;

-- =============================================
-- PATTERN 2: ADA/ADM by Subgroup (Race, IEP, EL, FRL)
-- =============================================
-- WITH stu_demo AS (
--   SELECT 
--     s.id,
--     s.ethnicity,
--     snd.iep_indicator,
--     snd.lep_indicator,
--     snd.frl_status
--   FROM students s
--   LEFT JOIN S_ND_STU_X snd ON snd.studentsdcid = s.dcid
--   WHERE s.enroll_status = 0
--     AND s.schoolid = (SELECT schoolid FROM params)
-- )
-- SELECT 
--   'Ethnicity' AS subgroup_type,
--   DECODE(sd.ethnicity, 1, 'Am Indian', 2, 'Asian', 3, 'Black', 4, 'Hispanic', 5, 'White', 6, 'Pacific Isl', 'Other') AS subgroup,
--   SUM(ada.ada) AS total_ada,
--   SUM(ada.adm) AS total_adm,
--   ROUND(SUM(ada.ada)/NULLIF(SUM(ada.adm),0)*100,2) AS ada_pct
-- FROM ada_adm ada
-- JOIN student_spans ss ON 1=1  -- Join via date range
-- JOIN stu_demo sd ON sd.id = ss.studentid
-- WHERE ada.calendardate BETWEEN ss.entrydate AND ss.exitdate - 1
-- GROUP BY sd.ethnicity
-- UNION ALL
-- SELECT 'IEP', DECODE(sd.iep_indicator,1,'Yes','No'), ...
-- FROM ... GROUP BY sd.iep_indicator;

-- =============================================
-- PATTERN 3: Tardy % by Student
-- =============================================
-- SELECT 
--   s.id,
--   s.lastfirst,
--   COUNT(CASE WHEN m.att_code = 'T' THEN 1 END) AS tardy_count,
--   COUNT(*) AS total_periods,
--   ROUND(COUNT(CASE WHEN m.att_code = 'T' THEN 1 END) / NULLIF(COUNT(*),0) * 100, 1) AS tardy_pct
-- FROM students s
-- JOIN meeting_att m ON m.studentid = s.id
-- WHERE s.enroll_status = 0
--   AND s.schoolid = (SELECT schoolid FROM params)
-- GROUP BY s.id, s.lastfirst
-- HAVING COUNT(CASE WHEN m.att_code = 'T' THEN 1 END) > 0
-- ORDER BY tardy_pct DESC;

-- =============================================
-- PATTERN 4: Suspension Equivalent Days (ISS/OSS)
-- =============================================
-- WITH suspended AS (
--   SELECT 
--     a.studentid,
--     a.att_date,
--     COUNT(*) AS num_periods
--   FROM attendance a
--   JOIN attendance_code ac ON ac.id = a.attendance_codeid
--   WHERE ac.att_code IN ('ISS','OSS')
--     AND a.att_date BETWEEN (SELECT startdate FROM params) AND (SELECT enddate FROM params)
--   GROUP BY a.studentid, a.att_date
-- ),
-- periods_per_day AS (
--   SELECT ppa.potential_periods
--   FROM ps_period_att ppa
--   WHERE ppa.schoolid = (SELECT schoolid FROM params)
--     AND ppa.yearid = (SELECT yearid FROM params)
-- )
-- SELECT 
--   s.id,
--   s.lastfirst,
--   ROUND(SUM(su.num_periods) / ppd.potential_periods, 1) AS equiv_days
-- FROM suspended su
-- JOIN students s ON s.id = su.studentid
-- CROSS JOIN periods_per_day ppd
-- WHERE s.enroll_status = 0
-- GROUP BY s.id, s.lastfirst, ppd.potential_periods
-- HAVING ROUND(SUM(su.num_periods) / ppd.potential_periods, 1) >= 10
-- ORDER BY equiv_days DESC;

-- =============================================
-- PATTERN 5: Day Number by Year (for attendance day counts)
-- =============================================
-- SELECT 
--   cd.schoolid,
--   cd.date_value,
--   cd.day_in_school_year,
--   db.first_day_num,
--   db.last_day_num
-- FROM cal_days cd
-- CROSS JOIN day_bounds db
-- ORDER BY cd.date_value