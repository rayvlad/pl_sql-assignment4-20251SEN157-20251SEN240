-- =====================================================================
-- PROCEDURE bulk_import_scores
-- Updates many scores in ONE operation using FORALL ... SAVE EXCEPTIONS.
-- Two parallel NESTED TABLES: p_enrollment_ids(i) gets p_scores(i).
-- A bad row (for example score 150 violates the 0..100 CHECK) does NOT
-- stop the good rows: Oracle saves the errors and we report them.
-- The procedure does NOT commit: the caller decides COMMIT or ROLLBACK.
-- Errors: -20080 empty/NULL lists, -20081 lists have different sizes
-- =====================================================================
CREATE OR REPLACE PROCEDURE bulk_import_scores (
  p_enrollment_ids IN  num_list,
  p_scores         IN  num_list,
  p_success_count  OUT NUMBER,
  p_failed_count   OUT NUMBER
)
IS
  e_bulk_errors   EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);   -- ORA-24381: errors in FORALL
  e_size_mismatch EXCEPTION;
  v_idx           PLS_INTEGER;
BEGIN
  p_success_count := 0;
  p_failed_count  := 0;

  IF p_enrollment_ids IS NULL OR p_scores IS NULL
     OR p_enrollment_ids.COUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20080, 'Both lists must be provided and not empty.');
  END IF;

  IF p_enrollment_ids.COUNT <> p_scores.COUNT THEN
    RAISE e_size_mismatch;
  END IF;

  -- ONE call to the SQL engine for all rows
  FORALL i IN 1 .. p_enrollment_ids.COUNT SAVE EXCEPTIONS
    UPDATE enrollments
       SET score = p_scores(i)
     WHERE enrollment_id = p_enrollment_ids(i);

  p_success_count := SQL%ROWCOUNT;
  p_failed_count  := p_enrollment_ids.COUNT - p_success_count;  -- includes unknown ids
  DBMS_OUTPUT.PUT_LINE('Bulk import finished. Updated: ' || p_success_count ||
                       ', not updated: ' || p_failed_count);
EXCEPTION
  WHEN e_size_mismatch THEN
    RAISE_APPLICATION_ERROR(-20081,
      'Lists have different sizes: ' || p_enrollment_ids.COUNT || ' ids vs ' ||
      p_scores.COUNT || ' scores.');
  WHEN e_bulk_errors THEN
    p_success_count := SQL%ROWCOUNT;      -- rows that DID succeed
    p_failed_count  := p_enrollment_ids.COUNT - p_success_count;
    FOR j IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
      v_idx := SQL%BULK_EXCEPTIONS(j).ERROR_INDEX;     -- which element failed
      DBMS_OUTPUT.PUT_LINE('  FAILED element ' || v_idx ||
        ' (enrollment ' || p_enrollment_ids(v_idx) ||
        ', score ' || p_scores(v_idx) || '): ' ||
        SQLERRM(-SQL%BULK_EXCEPTIONS(j).ERROR_CODE));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Bulk import finished with errors. Updated: ' ||
                         p_success_count || ', not updated: ' || p_failed_count);
END bulk_import_scores;
/
