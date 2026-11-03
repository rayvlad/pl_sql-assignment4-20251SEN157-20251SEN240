-- =====================================================================
-- FUNCTION get_grade_letter
-- Converts a numeric score (0-100) into a letter grade.
--   A: 90-100  B: 80-89  C: 70-79  D: 60-69  F: below 60
-- NULL score  -> returns NULL (nothing to convert, not an error)
-- Bad score   -> raises ORA-20010 (we never return a misleading letter)
-- =====================================================================
CREATE OR REPLACE FUNCTION get_grade_letter (
  p_score IN NUMBER
) RETURN VARCHAR2
DETERMINISTIC
IS
BEGIN
  IF p_score IS NULL THEN
    RETURN NULL;
  ELSIF p_score < 0 OR p_score > 100 THEN
    RAISE_APPLICATION_ERROR(-20010,
      'Invalid score ' || p_score || '. A score must be between 0 and 100.');
  ELSIF p_score >= 90 THEN
    RETURN 'A';
  ELSIF p_score >= 80 THEN
    RETURN 'B';
  ELSIF p_score >= 70 THEN
    RETURN 'C';
  ELSIF p_score >= 60 THEN
    RETURN 'D';
  ELSE
    RETURN 'F';
  END IF;
END get_grade_letter;
/
