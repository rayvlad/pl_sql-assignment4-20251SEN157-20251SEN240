-- =====================================================================
-- test_error_cases.sql
-- Each test CAUSES an error on purpose and proves it is handled.
-- Expected output for every test: "Expected error caught: ORA-200xx..."
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT ===== TEST E1: student does not exist (NO_DATA_FOUND -> ORA-20041) =====
DECLARE v_r VARCHAR2(300);
BEGIN
  register_student_course(9999, 101, '2026-FALL', v_r);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E2: suspended student (user-defined exception -> ORA-20042) =====
DECLARE v_r VARCHAR2(300);
BEGIN
  register_student_course(1010, 101, '2026-FALL', v_r);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E3: course is full (user-defined exception -> ORA-20044) =====
DECLARE v_r VARCHAR2(300);
BEGIN
  register_student_course(1003, 105, '2026-FALL', v_r);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E4: duplicate registration (DUP_VAL_ON_INDEX -> ORA-20045) =====
DECLARE v_r VARCHAR2(300);
BEGIN
  register_student_course(1001, 101, '2026-FALL', v_r);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E5a: invalid score 150 (ORA-20010 from function) =====
DECLARE v_l VARCHAR2(1);
BEGIN
  update_score(1, 150, v_l);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E5b: enrollment does not exist (ORA-20051) =====
DECLARE v_l VARCHAR2(1);
BEGIN
  update_score(999, 80, v_l);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E6a: drop a missing enrollment (SQL%NOTFOUND -> ORA-20060) =====
BEGIN
  drop_enrollment(999);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E6b: drop enrollment that has grade history (ORA-02292 -> ORA-20061) =====
DECLARE v_l VARCHAR2(1);
BEGIN
  update_score(1, 95, v_l);      -- creates a GRADE_LOG row for enrollment 1
  drop_enrollment(1);            -- now the delete must be refused
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/
ROLLBACK;

PROMPT ===== TEST E7: roster of a course with nobody enrolled (ORA-20070) =====
BEGIN
  print_course_roster(106, '2026-FALL');
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E8a: bulk import with 2 bad rows (SAVE EXCEPTIONS / ORA-24381) =====
DECLARE
  v_ids    num_list := num_list(6, 7, 12);
  v_scores num_list := num_list(91, 150, -5);   -- 150 and -5 violate the 0..100 CHECK
  v_ok     NUMBER;
  v_bad    NUMBER;
BEGIN
  bulk_import_scores(v_ids, v_scores, v_ok, v_bad);
  DBMS_OUTPUT.PUT_LINE('Result -> OK=' || v_ok || ' FAILED=' || v_bad || '  (expected OK=1, FAILED=2)');
END;
/
SELECT enrollment_id, score FROM enrollments WHERE enrollment_id IN (6, 7, 12);
ROLLBACK;

PROMPT ===== TEST E8b: lists of different size (ORA-20081) =====
DECLARE
  v_ok NUMBER; v_bad NUMBER;
BEGIN
  bulk_import_scores(num_list(1, 2, 3), num_list(50), v_ok, v_bad);
  DBMS_OUTPUT.PUT_LINE('UNEXPECTED: no error raised');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E9a: GPA of a missing student (ORA-20020) =====
BEGIN
  DBMS_OUTPUT.PUT_LINE('GPA: ' || calculate_gpa(9999));
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E9b: NO_DATA_FOUND in get_student_score (ORA-20110) =====
BEGIN
  DBMS_OUTPUT.PUT_LINE('Score: ' || get_student_score(1004, 103));
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E9c: TOO_MANY_ROWS in get_student_score (ORA-20111) =====
BEGIN
  DBMS_OUTPUT.PUT_LINE('Score: ' || get_student_score(1001, 101));
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E10: get_top_students with N = 0 (ORA-20030) =====
BEGIN
  DBMS_OUTPUT.PUT_LINE('Rows: ' || get_top_students(101, '2026-FALL', 0).COUNT);
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Expected error caught: ' || SQLERRM);
END;
/

PROMPT ===== TEST E11: invalid score passed straight to the function (ORA-20010) =====
SELECT get_grade_letter(101) FROM dual;
