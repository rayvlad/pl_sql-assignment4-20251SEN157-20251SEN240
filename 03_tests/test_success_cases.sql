-- =====================================================================
-- test_success_cases.sql
-- Run AFTER schema, sample data, functions and procedures.
-- Every test that changes data ends with ROLLBACK so you can re-run
-- the whole file as many times as you want.
-- Take one screenshot per test (see screenshots/ folder).
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT ===== TEST S1: register_student_course (success) =====
DECLARE
  v_result VARCHAR2(300);
BEGIN
  register_student_course(1004, 102, '2026-FALL', v_result);
  DBMS_OUTPUT.PUT_LINE(v_result);
END;
/
SELECT enrollment_id, student_id, course_id, semester
  FROM enrollments WHERE student_id = 1004 AND course_id = 102;
ROLLBACK;

PROMPT ===== TEST S2: update_score (implicit cursor UPDATE + audit log) =====
DECLARE
  v_letter VARCHAR2(1);
BEGIN
  update_score(5, 83, v_letter);          -- enrollment 5: 79/no letter -> 83
  DBMS_OUTPUT.PUT_LINE('New letter: ' || v_letter);
END;
/
SELECT enrollment_id, score, grade_letter FROM enrollments WHERE enrollment_id = 5;
SELECT enrollment_id, old_score, new_score FROM grade_log;
ROLLBACK;

PROMPT ===== TEST S3: drop_enrollment (implicit cursor DELETE) =====
BEGIN
  drop_enrollment(15);
END;
/
SELECT COUNT(*) AS rows_left_for_enrollment_15 FROM enrollments WHERE enrollment_id = 15;
ROLLBACK;

PROMPT ===== TEST S4: print_course_roster (explicit cursor) =====
BEGIN
  print_course_roster(101, '2026-FALL');
END;
/

PROMPT ===== TEST S5: functions called from SQL and from PL/SQL =====
SELECT get_grade_letter(95) AS letter_95, get_grade_letter(59.99) AS letter_59_99 FROM dual;
SELECT get_enrollment_count(101, '2026-FALL') AS students_in_101 FROM dual;
SELECT student_id, calculate_gpa(student_id) AS gpa FROM students WHERE student_id IN (1001, 1002, 1005) ORDER BY 1;
SELECT * FROM TABLE(get_top_students(101, '2026-FALL', 3));
BEGIN
  DBMS_OUTPUT.PUT_LINE('Score of student 1002 in course 102: ' || get_student_score(1002, 102));
END;
/

PROMPT ===== TEST S6: bulk_assign_grade_letters (BULK COLLECT + FORALL) =====
SELECT enrollment_id, score, grade_letter FROM enrollments WHERE grade_letter IS NULL AND score IS NOT NULL;
DECLARE
  v_updated NUMBER;
BEGIN
  bulk_assign_grade_letters('2026-FALL', v_updated);
  DBMS_OUTPUT.PUT_LINE('Total updated: ' || v_updated);
END;
/
SELECT enrollment_id, score, grade_letter FROM enrollments WHERE enrollment_id IN (5, 8, 11);
ROLLBACK;

PROMPT ===== TEST S7: bulk_import_scores (all rows valid) =====
DECLARE
  v_ids    num_list := num_list(14, 15);
  v_scores num_list := num_list(70, 85);
  v_ok     NUMBER;
  v_bad    NUMBER;
BEGIN
  bulk_import_scores(v_ids, v_scores, v_ok, v_bad);
  DBMS_OUTPUT.PUT_LINE('OK=' || v_ok || ' FAILED=' || v_bad);
END;
/
SELECT enrollment_id, score FROM enrollments WHERE enrollment_id IN (14, 15);
ROLLBACK;

PROMPT ===== TEST S8: performance, loop vs FORALL =====
BEGIN
  bulk_vs_loop_demo(20000);
END;
/
ROLLBACK;
