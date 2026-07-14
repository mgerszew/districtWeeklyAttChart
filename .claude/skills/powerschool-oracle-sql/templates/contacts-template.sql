-- ============================================
-- Contacts Query Template
-- Category: Contacts (phones, emails, addresses, flags)
-- Tables: students, PERSON, STUDENTCONTACTASSOC, STUDENTCONTACTDETAIL, 
--         PERSONPHONENUMBERASSOC, PHONENUMBER, CODESET,
--         PERSONEMAILADDRESSASSOC, EMAILADDRESS,
--         PERSONADDRESSASSOC, PERSONADDRESS, U_STUDENTS_BPS
-- ============================================

WITH params AS (
  SELECT 
    84 AS schoolid,                    -- School number (FK to schools.school_number)
    0 AS enroll_status                 -- 0 = active
  FROM dual
),
-- Highest priority mobile per person (reusable CTE)
first_mobile AS (
  SELECT 
    ppna.personid,
    MAX(pn.phonenumber) KEEP (DENSE_RANK FIRST ORDER BY ppna.priority) AS mobile_phone,
    MAX(ppna.priority) KEEP (DENSE_RANK FIRST ORDER BY ppna.priority) AS mobile_priority
  FROM personphonenumberassoc ppna
  JOIN phonenumber pn ON pn.id = ppna.phonenumberid
  JOIN codeset cs ON cs.codesetid = ppna.phonetypecodesetid
  WHERE cs.code = 'Mobile'
  GROUP BY ppna.personid
),
-- Active student-contact relationships
active_contacts AS (
  SELECT 
    sca.studentdcid,
    sca.personid,
    scd.relationship_codesetid,
    scd.contact_priority_codesetid,
    scd.isactive
  FROM studentcontactassoc sca
  JOIN studentcontactdetail scd 
    ON scd.studentcontactassocid = sca.studentcontactassocid
  WHERE scd.isactive = 1
),
-- Person details with normalized phones/emails
person_contacts AS (
  SELECT 
    p.id AS personid,
    p.first_name,
    p.last_name,
    fm.mobile_phone,
    fm.mobile_priority,
    LISTAGG(
      '<span class="phone">' || REPLACE(REPLACE(REPLACE(pn.phonenumber,'(',''),')',''),'-','') || '</span>',
      '<br/>'
    ) WITHIN GROUP (ORDER BY ppna.priority) AS all_phones_html,
    LISTAGG(
      '<a href="mailto:' || ea.emailaddress || '">' || ea.emailaddress || '</a>',
      '<br/>'
    ) WITHIN GROUP (ORDER BY peaa.priority) AS all_emails_html
  FROM person p
  LEFT JOIN first_mobile fm ON fm.personid = p.id
  LEFT JOIN personphonenumberassoc ppna ON ppna.personid = p.id
  LEFT JOIN phonenumber pn ON pn.id = ppna.phonenumberid
  LEFT JOIN codeset cst ON cst.codesetid = ppna.phonetypecodesetid
  LEFT JOIN personemailaddressassoc peaa ON peaa.personid = p.id
  LEFT JOIN emailaddress ea ON ea.id = peaa.emailaddressid
  GROUP BY p.id, p.first_name, p.last_name, fm.mobile_phone, fm.mobile_priority
)
-- ============================================
-- FINAL QUERY - Choose your output pattern
-- ============================================

-- Pattern 1: Student roster with guardian mobile (Cellphone Export)
-- SELECT 
--   s.id AS student_number,
--   s.lastfirst AS student_name,
--   s.grade_level,
--   pc.mobile_phone AS guardian_mobile,
--   pc.mobile_priority
-- FROM students s
-- JOIN active_contacts ac ON ac.studentdcid = s.dcid
-- JOIN person_contacts pc ON pc.personid = ac.personid
-- JOIN codeset cr ON cr.codesetid = ac.relationship_codesetid
-- WHERE cr.code IN ('guardian','father','mother')
--   AND s.enroll_status = (SELECT enroll_status FROM params)
--   AND s.schoolid = (SELECT schoolid FROM params)
-- ORDER BY s.lastfirst, pc.mobile_priority;

-- Pattern 2: Mismatch detection (BPS custom vs stored mobile)
-- SELECT 
--   s.id,
--   s.lastfirst,
--   usb.custom_mobile_field,        -- From U_STUDENTS_BPS
--   pc.mobile_phone AS stored_mobile,
--   DECODE(
--     REPLACE(REPLACE(REPLACE(usb.custom_mobile_field,'(',''),')',''),'-',''),
--     REPLACE(REPLACE(REPLACE(pc.mobile_phone,'(',''),')',''),'-',''),
--     'Match', 'Mismatch'
--   ) AS match_status
-- FROM students s
-- JOIN U_STUDENTS_BPS usb ON usb.studentsdcid = s.dcid
-- JOIN active_contacts ac ON ac.studentdcid = s.dcid
-- JOIN person_contacts pc ON pc.personid = ac.personid
-- JOIN codeset cr ON cr.codesetid = ac.relationship_codesetid
-- WHERE cr.code IN ('guardian','father','mother')
--   AND usb.custom_mobile_field IS NOT NULL;

-- Pattern 3: Contact flags (custodial, pickup, emergency)
-- SELECT 
--   s.dcid AS student_dcid,
--   p.id AS contact_personid,
--   p.first_name || ' ' || p.last_name AS contact_name,
--   NVL(MAX(CASE WHEN cr.code = 'custodial' THEN 1 END), 0) AS is_custodial,
--   NVL(MAX(CASE WHEN cr.code = 'pickup' THEN 1 END), 0) AS is_pickup,
--   NVL(MAX(CASE WHEN cr.code = 'emergency' THEN 1 END), 0) AS is_emergency
-- FROM students s
-- JOIN active_contacts ac ON ac.studentdcid = s.dcid
-- JOIN person p ON p.id = ac.personid
-- JOIN codeset cr ON cr.codesetid = ac.relationship_codesetid
-- GROUP BY s.dcid, p.id, p.first_name, p.last_name;

-- Pattern 4: HTML-rich export for PQ DAT (Phones, Emails, Addresses)
-- SELECT 
--   s.id,
--   s.lastfirst,
--   pc.all_phones_html,
--   pc.all_emails_html,
--   LISTAGG(
--     pa.address_line1 || '<br/>' || pa.city || ', ' || pa.state || ' ' || pa.zip,
--     '<br/><br/>'
--   ) WITHIN GROUP (ORDER BY paa.priority) AS addresses_html
-- FROM students s
-- JOIN active_contacts ac ON ac.studentdcid = s.dcid
-- JOIN person_contacts pc ON pc.personid = ac.personid
-- LEFT JOIN personaddressassoc paa ON paa.personid = ac.personid
-- LEFT JOIN personaddress pa ON pa.id = paa.personaddressid
-- LEFT JOIN codeset cast ON cast.codesetid = paa.addresstypecodesetid
-- GROUP BY s.id, s.lastfirst, pc.all_phones_html, pc.all_emails_html;

-- Pattern 5: Orphaned guardians (no StudentContactAssoc)
-- SELECT 
--   gpa.personid,
--   gs.studentsdcid,
--   s.lastfirst
-- FROM guardianpersonassoc gpa
-- JOIN guardianstudent gs ON gs.guardiandcid = gpa.guardianpersonid
-- JOIN students s ON s.dcid = gs.studentsdcid
-- LEFT JOIN studentcontactassoc sca 
--   ON sca.personid = gpa.personid AND s.dcid = sca.studentdcid
-- WHERE sca.studentcontactassocid IS NULL
--   AND s.enroll_status = 0