-- =====================================================================
-- FUNCTION calculate_gpa
-- GPA = sum(grade_points * credits) / sum(credits), on a 4.0 scale.
-- Uses:
--   * an ASSOCIATIVE ARRAY (letter -> points lookup table)
--   * a %ROWTYPE record (the student row)
--   * an explicit cursor used with a cursor FOR loop
-- Student does not exist  -> ORA-20020
-- Student has no grades   -> returns NULL (honest: there is no GPA yet)
-- =====================================================================
CREATE OR REPLACE FUNCTION calculate_gpa (
  p_student_id IN NUMBER
) RETURN NUMBER
IS
  -- Associative array: key = letter, value = grade points
  TYPE grade_point_map IS TABLE OF NUMBER INDEX BY VARCHAR2(1);
  v_points        grade_point_map;

  v_student       students%ROWTYPE;      -- table-based record

  -- Explicit cursor: only graded enrollments, with course credits
  CURSOR c_grades IS
    SELECT e.grade_letter, c.credits
      FROM enrollments e
      JOIN courses c ON c.course_id = e.course_id
     WHERE e.student_id   = p_student_id
       AND e.grade_letter IS NOT NULL;

  v_total_points  NUMBER := 0;
  v_total_credits NUMBER := 0;
BEGIN
  v_points('A') := 4;
  v_points('B') := 3;
  v_points('C') := 2;
  v_points('D') := 1;
  v_points('F') := 0;

  -- Make sure the student exists
  BEGIN
    SELECT * INTO v_student FROM students WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20020,
        'Student ' || p_student_id || ' does not exist.');
  END;

  -- Cursor FOR loop: opens, fetches and closes the cursor automatically
  FOR r IN c_grades LOOP
    v_total_points  := v_total_points  + v_points(r.grade_letter) * r.credits;
    v_total_credits := v_total_credits + r.credits;
  END LOOP;

  IF v_total_credits = 0 THEN
    RETURN NULL;   -- no graded courses yet
  END IF;

  RETURN ROUND(v_total_points / v_total_credits, 2);
END calculate_gpa;
/
