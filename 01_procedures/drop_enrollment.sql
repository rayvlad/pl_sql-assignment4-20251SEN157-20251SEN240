-- =====================================================================
-- PROCEDURE drop_enrollment
-- Removes an enrollment.
-- Uses: implicit cursor with DELETE (SQL%NOTFOUND, SQL%ROWCOUNT) and
--       PRAGMA EXCEPTION_INIT to give a name to Oracle error ORA-02292
--       (child record found: the enrollment has grade history).
-- Errors: -20060 enrollment not found, -20061 has grade history
-- =====================================================================
CREATE OR REPLACE PROCEDURE drop_enrollment (
  p_enrollment_id IN NUMBER
)
IS
  e_has_grade_history EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_has_grade_history, -2292);
BEGIN
  DELETE FROM enrollments
   WHERE enrollment_id = p_enrollment_id;

  IF SQL%NOTFOUND THEN
    RAISE_APPLICATION_ERROR(-20060,
      'Enrollment ' || p_enrollment_id || ' does not exist: nothing deleted.');
  END IF;

  DBMS_OUTPUT.PUT_LINE('Enrollment ' || p_enrollment_id ||
                       ' dropped. Rows deleted: ' || SQL%ROWCOUNT);
EXCEPTION
  WHEN e_has_grade_history THEN
    RAISE_APPLICATION_ERROR(-20061,
      'Enrollment ' || p_enrollment_id ||
      ' has grade history in GRADE_LOG and cannot be dropped.');
END drop_enrollment;
/
