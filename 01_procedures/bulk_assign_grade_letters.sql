-- =====================================================================
-- PROCEDURE bulk_assign_grade_letters
-- Finds every enrollment of a semester that has a score but no letter,
-- computes the letters and saves them all at once.
-- Uses: BULK COLLECT into a nested table of %ROWTYPE records,
--       nested tables + EXTEND, FORALL ... SAVE EXCEPTIONS,
--       SQL%BULK_EXCEPTIONS, function call, RAISE_APPLICATION_ERROR.
-- Errors: -20090 semester missing,
--         -20091 some rows failed (caller should ROLLBACK)
-- =====================================================================
CREATE OR REPLACE PROCEDURE bulk_assign_grade_letters (
  p_semester      IN  VARCHAR2,
  p_updated_count OUT NUMBER
)
IS
  TYPE enrollment_tab IS TABLE OF enrollments%ROWTYPE;   -- collection of records
  v_enrollments enrollment_tab;

  TYPE letter_tab IS TABLE OF VARCHAR2(1);
  v_letters letter_tab := letter_tab();
  v_ids     num_list   := num_list();

  e_bulk_errors EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);
BEGIN
  p_updated_count := 0;

  IF p_semester IS NULL THEN
    RAISE_APPLICATION_ERROR(-20090, 'Semester is required (example: 2026-FALL).');
  END IF;

  -- 1) Fetch ALL matching rows in one go
  SELECT *
    BULK COLLECT INTO v_enrollments
    FROM enrollments
   WHERE semester     = p_semester
     AND score        IS NOT NULL
     AND grade_letter IS NULL;

  IF v_enrollments.COUNT = 0 THEN
    DBMS_OUTPUT.PUT_LINE('Nothing to do: every scored enrollment already has a letter.');
    RETURN;
  END IF;

  -- 2) Prepare the parallel lists (the PL/SQL part: compute each letter)
  FOR i IN 1 .. v_enrollments.COUNT LOOP
    v_ids.EXTEND;
    v_letters.EXTEND;
    v_ids(i)     := v_enrollments(i).enrollment_id;
    v_letters(i) := get_grade_letter(v_enrollments(i).score);
  END LOOP;

  -- 3) Save ALL letters with ONE call to the SQL engine
  FORALL i IN 1 .. v_ids.COUNT SAVE EXCEPTIONS
    UPDATE enrollments
       SET grade_letter = v_letters(i)
     WHERE enrollment_id = v_ids(i);

  p_updated_count := SQL%ROWCOUNT;
  DBMS_OUTPUT.PUT_LINE('Letters assigned: ' || p_updated_count);
EXCEPTION
  WHEN e_bulk_errors THEN
    FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('  FAILED enrollment ' ||
        v_ids(SQL%BULK_EXCEPTIONS(j).ERROR_INDEX) || ': ' ||
        SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
    END LOOP;
    RAISE_APPLICATION_ERROR(-20091,
      SQL%BULK_EXCEPTIONS.COUNT || ' row(s) failed. Please ROLLBACK and check the data.');
END bulk_assign_grade_letters;
/
