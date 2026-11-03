-- =====================================================================
-- FUNCTION get_student_score
-- Returns the score of a student in a course.
-- Demonstrates the PREDEFINED exceptions NO_DATA_FOUND and TOO_MANY_ROWS:
--   * not enrolled at all                  -> NO_DATA_FOUND  -> ORA-20110
--   * enrolled in several semesters        -> TOO_MANY_ROWS  -> ORA-20111
-- A NULL result means "enrolled but not graded yet".
-- =====================================================================
CREATE OR REPLACE FUNCTION get_student_score (
  p_student_id IN NUMBER,
  p_course_id  IN NUMBER
) RETURN NUMBER
IS
  v_score enrollments.score%TYPE;
BEGIN
  SELECT score
    INTO v_score
    FROM enrollments
   WHERE student_id = p_student_id
     AND course_id  = p_course_id;

  RETURN v_score;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20110,
      'Student ' || p_student_id || ' is not enrolled in course ' || p_course_id || '.');
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20111,
      'Student ' || p_student_id || ' took course ' || p_course_id ||
      ' in several semesters. Please query by semester instead.');
END get_student_score;
/
