-- =====================================================================
-- FUNCTION get_enrollment_count
-- How many students are enrolled in a course in a given semester?
-- Used by register_student_course to check if a course is full.
-- =====================================================================
CREATE OR REPLACE FUNCTION get_enrollment_count (
  p_course_id IN NUMBER,
  p_semester  IN VARCHAR2
) RETURN NUMBER
IS
  v_count NUMBER;
BEGIN
  -- COUNT(*) always returns exactly one row, so NO_DATA_FOUND cannot happen.
  SELECT COUNT(*)
    INTO v_count
    FROM enrollments
   WHERE course_id = p_course_id
     AND semester  = p_semester;

  RETURN v_count;
EXCEPTION
  WHEN OTHERS THEN
    -- Do not hide the problem: re-raise with context (TRUE keeps the original error stack)
    RAISE_APPLICATION_ERROR(-20099,
      'get_enrollment_count failed: ' || SQLERRM, TRUE);
END get_enrollment_count;
/
