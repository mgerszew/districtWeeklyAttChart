-- Student Attendance Analytics Query
-- Parameters: ~(gpv.start_date), ~(gpv.end_date), ~(studentfrn)
-- Returns: GPV parameters for attendance summary and detail rows

WITH params AS (
    SELECT
        TO_DATE(COALESCE('~(gpv.start_date)', TO_CHAR(TRUNC(SYSDATE) - 30, 'YYYY'), 'YYYY-MM-DD'), 'YYYY-MM-DD') AS start_date,
        TO_DATE(COALESCE('~(gpv.end_date)', TO_CHAR(TRUNC(SYSDATE), 'YYYY-MM-DD'), 'YYYY-MM-DD'), 'YYYY-MM-DD') AS end_date,
        '~(studentfrn)' AS student_frn
    FROM dual
),
student_info AS (
    SELECT
        s.id AS student_id,
        s.student_number,
        s.lastfirst,
        s.grade_level,
        s.schoolid
    FROM students s
    JOIN params p ON s.dcid = p.student_frn
),
enrollment AS (
    SELECT
        e.studentid,
        e.schoolid,
        e.entrydate,
        e.exitdate,
        e.grade_level
    FROM reenrollments e
    JOIN student_info si ON e.studentid = si.student_id
    WHERE e.entrydate <= (SELECT end_date FROM params)
      AND (e.exitdate IS NULL OR e.exitdate >= (SELECT start_date FROM params))
      AND e.schoolid = si.schoolid
),
school_calendar AS (
    SELECT
        cal.calendardate,
        cal.schoolid,
        cal.day_number,
        cal.cycle_day_letter,
        cal.membership_value
    FROM calendar_day cal
    JOIN params p ON 1=1
    WHERE cal.calendardate BETWEEN p.start_date AND p.end_date
      AND cal.membership_value > 0
      AND cal.schoolid = (SELECT schoolid FROM student_info)
),
attendance_detail AS (
    SELECT
        a.studentid,
        a.att_date,
        a.periodid,
        a.attendance_codeid,
        a.att_mode_code,
        a.presence_status_cd,
        ac.att_code,
        ac.description,
        ac.presence_status_cd AS code_presence_status,
        c.course_name,
        c.course_number,
        p.period_number,
        p.abbreviation AS period_abbrev
    FROM attendance a
    JOIN enrollment e ON a.studentid = e.studentid
    JOIN attendance_code ac ON a.attendance_codeid = ac.id
    LEFT JOIN sections s ON a.sectionid = s.id
    LEFT JOIN courses c ON s.course_number = c.course_number
    LEFT JOIN periods p ON a.periodid = p.id
    JOIN params p2 ON a.studentid = p2.student_frn
    WHERE a.att_date BETWEEN p2.start_date AND p2.end_date
      AND a.studentid = (SELECT student_id FROM student_info)
),
daily_summary AS (
    SELECT
        ad.att_date,
        COUNT(DISTINCT ad.periodid) AS periods_scheduled,
        SUM(CASE WHEN ad.code_presence_status = 'Present' THEN 1 ELSE 0 END) AS periods_present,
        SUM(CASE WHEN ad.code_presence_status = 'Absent' THEN 1 ELSE 0 END) AS periods_absent,
        LISTAGG(DISTINCT ad.att_code, ', ') WITHIN GROUP (ORDER BY ad.att_code) AS codes_used
    FROM attendance_detail ad
    GROUP BY ad.att_date
),
code_summary AS (
    SELECT
        ad.attendance_codeid,
        ac.att_code,
        ac.description,
        COUNT(*) AS occurrence_count,
        ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS percentage
    FROM attendance_detail ad
    JOIN attendance_code ac ON ad.attendance_codeid = ac.id
    WHERE ad.code_presence_status = 'Absent'
    GROUP BY ad.attendance_codeid, ac.att_code, ac.description
),
overall_totals AS (
    SELECT
        (SELECT COUNT(*) FROM school_calendar) AS total_days,
        SUM(periods_present) AS total_periods_present,
        SUM(periods_scheduled) AS total_periods_scheduled,
        SUM(periods_absent) AS total_periods_absent
    FROM daily_summary
)
SELECT
    -- GPV parameters for the page template
    'total_days' AS gpv_name,
    TO_CHAR(ot.total_days) AS gpv_value
FROM overall_totals ot
UNION ALL
SELECT 'days_present', TO_CHAR(ROUND(ot.total_periods_present / GREATEST(ot.total_periods_scheduled / ot.total_days, 1)))
FROM overall_totals ot
UNION ALL
SELECT 'days_absent', TO_CHAR(ROUND(ot.total_periods_absent / GREATEST(ot.total_periods_scheduled / ot.total_days, 1)))
FROM overall_totals ot
UNION ALL
SELECT 'attendance_rate', TO_CHAR(ROUND(ot.total_periods_present / NULLIF(ot.total_periods_scheduled, 0) * 100, 1))
FROM overall_totals ot
UNION ALL
SELECT 'attendance_rows', (
    SELECT LISTAGG(
        '<tr>' ||
        '<td>' || TO_CHAR(ad.att_date, 'MM/DD/YYYY') || '</td>' ||
        '<td>' || ad.period_abbrev || '</td>' ||
        '<td>' || ad.course_name || ' (' || ad.course_number || ')' || '</td>' ||
        '<td>' || ad.att_code || '</td>' ||
        '<td>' || ad.description || '</td>' ||
        '<td>' || CASE WHEN ad.att_mode_code = 'ATT_ModeMeeting' THEN 'Full Period' ELSE 'Partial' END || '</td>' ||
        '</tr>', ''
    ) WITHIN GROUP (ORDER BY ad.att_date DESC, ad.period_number)
    FROM attendance_detail ad
)
FROM dual
UNION ALL
SELECT 'summary_rows', (
    SELECT LISTAGG(
        '<tr>' ||
        '<td>' || cs.att_code || '</td>' ||
        '<td>' || cs.description || '</td>' ||
        '<td>' || cs.occurrence_count || '</td>' ||
        '<td>' || cs.percentage || '%' || '</td>' ||
        '</tr>', ''
    ) WITHIN GROUP (ORDER BY cs.occurrence_count DESC)
    FROM code_summary cs
)
FROM dual;