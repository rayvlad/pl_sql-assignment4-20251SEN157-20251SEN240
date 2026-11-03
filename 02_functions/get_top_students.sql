-- =====================================================================
-- FUNCTION get_top_students
-- Returns the top N scoring students of a course in a semester, as a
-- collection of objects. Uses BULK COLLECT.
-- Call it from SQL like a table:
--   SELECT * FROM TABLE(get_top_students(101, '2026-FALL', 3));
-- Course does not exist -> ORA-20031. Bad N -> ORA-20030.
-- =====================================================================
CREATE OR REPLACE FUNCTION get_top_students (
  p_course_id IN NUMBER,
  p_semester  IN VARCHAR2,
  p_top_n     IN NUMBER DEFAULT 3
) RETURN student_score_tab
IS
  v_result student_score_tab;
  v_dummy  NUMBER;
BEGIN
  IF p_top_n IS NULL OR p_top_n < 1 THEN
    RAISE_APPLICATION_ERROR(-20030, 'p_top_n must be 1 or greater.');
  END IF;

  -- Check that the course exists (otherwise we would return an empty list silently)
  BEGIN
    SELECT course_id INTO v_dummy FROM courses WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20031,
        'Course ' || p_course_id || ' does not exist.');
  END;

  -- One trip to the SQL engine: all rows land in the collection at once
  SELECT student_score_obj(student_id, full_name, score)
    BULK COLLECT INTO v_result
    FROM (SELECT s.student_id,
                 s.first_name || ' ' || s.last_name AS full_name,
                 e.score
            FROM enrollments e
            JOIN students s ON s.student_id = e.student_id
           WHERE e.course_id = p_course_id
             AND e.semester  = p_semester
             AND e.score IS NOT NULL
           ORDER BY e.score DESC)
   WHERE ROWNUM <= p_top_n;

  RETURN v_result;   -- may be empty if nobody has a score yet: that is truthful
END get_top_students;
/
