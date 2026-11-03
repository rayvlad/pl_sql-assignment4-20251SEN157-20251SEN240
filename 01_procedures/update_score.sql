-- =====================================================================
-- PROCEDURE update_score
-- Changes a student's score, recomputes the letter grade, writes an
-- audit row in GRADE_LOG.
-- Uses: %ROWTYPE record, implicit cursor with UPDATE and
--       SQL%FOUND / SQL%NOTFOUND / SQL%ROWCOUNT, function call.
-- Errors: -20050 NULL score, -20051 enrollment not found,
--         -20052 update touched no row, -20010 invalid score (from function)
-- =====================================================================
CREATE OR REPLACE PROCEDURE update_score (
  p_enrollment_id IN  NUMBER,
  p_new_score     IN  NUMBER,
  p_new_letter    OUT VARCHAR2
)
IS
  v_old enrollments%ROWTYPE;
BEGIN
  IF p_new_score IS NULL THEN
    RAISE_APPLICATION_ERROR(-20050, 'The new score cannot be NULL.');
  END IF;

  BEGIN
    SELECT * INTO v_old FROM enrollments WHERE enrollment_id = p_enrollment_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20051,
        'Enrollment ' || p_enrollment_id || ' not found.');
  END;

  -- Raises ORA-20010 if the score is outside 0..100
  p_new_letter := get_grade_letter(p_new_score);

  UPDATE enrollments
     SET score        = p_new_score,
         grade_letter = p_new_letter
   WHERE enrollment_id = p_enrollment_id;

  -- Inspect the implicit cursor RIGHT AFTER the UPDATE (before other SQL runs)
  IF SQL%NOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20052,
      'Update affected no rows for enrollment ' || p_enrollment_id || '.');
  ELSIF SQL%FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Rows updated: ' || SQL%ROWCOUNT);
  END IF;

  INSERT INTO grade_log (enrollment_id, old_score, new_score)
  VALUES (p_enrollment_id, v_old.score, p_new_score);
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END update_score;
/
