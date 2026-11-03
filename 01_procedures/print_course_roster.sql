-- =====================================================================
-- PROCEDURE print_course_roster
-- Prints every student in a course/semester plus a grade distribution.
-- Uses: EXPLICIT PARAMETERIZED CURSOR with OPEN / FETCH / CLOSE,
--       cursor-based record (c_roster%ROWTYPE), cursor attributes
--       %NOTFOUND, %ROWCOUNT, %ISOPEN, a VARRAY, a user-defined exception.
-- Errors: -20071 course not found, -20070 nobody enrolled
-- =====================================================================
CREATE OR REPLACE PROCEDURE print_course_roster (
  p_course_id IN NUMBER,
  p_semester  IN VARCHAR2
)
IS
  CURSOR c_roster (cp_course NUMBER, cp_semester VARCHAR2) IS
    SELECT s.student_id, s.first_name, s.last_name, e.score, e.grade_letter
      FROM enrollments e
      JOIN students s ON s.student_id = e.student_id
     WHERE e.course_id = cp_course
       AND e.semester  = cp_semester
     ORDER BY s.last_name, s.first_name;

  v_row    c_roster%ROWTYPE;          -- cursor-based record
  v_course courses%ROWTYPE;

  -- VARRAY: fixed size 5 = counters for A, B, C, D, F
  TYPE letter_counts IS VARRAY(5) OF NUMBER;
  v_counts letter_counts := letter_counts(0, 0, 0, 0, 0);
  v_idx    PLS_INTEGER;
  v_total  PLS_INTEGER := 0;

  e_empty_roster EXCEPTION;
BEGIN
  BEGIN
    SELECT * INTO v_course FROM courses WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20071, 'Course ' || p_course_id || ' not found.');
  END;

  DBMS_OUTPUT.PUT_LINE('ROSTER: ' || v_course.course_code || ' - ' ||
                       v_course.course_name || ' (' || p_semester || ')');
  DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

  OPEN c_roster(p_course_id, p_semester);          -- 1) OPEN
  LOOP
    FETCH c_roster INTO v_row;                     -- 2) FETCH one row
    EXIT WHEN c_roster%NOTFOUND;                   --    stop when no more rows

    DBMS_OUTPUT.PUT_LINE(
      c_roster%ROWCOUNT || '. ' ||
      RPAD(v_row.last_name || ' ' || v_row.first_name, 28) ||
      ' score: ' || RPAD(NVL(TO_CHAR(v_row.score), '-'), 6) ||
      ' grade: ' || NVL(v_row.grade_letter, '-'));

    IF v_row.grade_letter IS NOT NULL THEN
      v_idx := CASE v_row.grade_letter
                 WHEN 'A' THEN 1 WHEN 'B' THEN 2 WHEN 'C' THEN 3
                 WHEN 'D' THEN 4 ELSE 5 END;
      v_counts(v_idx) := v_counts(v_idx) + 1;
    END IF;
  END LOOP;

  v_total := c_roster%ROWCOUNT;   -- read BEFORE closing (afterwards it is invalid)
  CLOSE c_roster;                 -- 3) CLOSE

  IF v_total = 0 THEN
    RAISE e_empty_roster;
  END IF;

  DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
  DBMS_OUTPUT.PUT_LINE('Students: ' || v_total ||
    ' | A=' || v_counts(1) || ' B=' || v_counts(2) || ' C=' || v_counts(3) ||
    ' D=' || v_counts(4) || ' F=' || v_counts(5));
EXCEPTION
  WHEN e_empty_roster THEN
    RAISE_APPLICATION_ERROR(-20070,
      'No students enrolled in course ' || p_course_id || ' for ' || p_semester || '.');
  WHEN OTHERS THEN
    IF c_roster%ISOPEN THEN        -- do not leak an open cursor
      CLOSE c_roster;
    END IF;
    RAISE;
END print_course_roster;
/
