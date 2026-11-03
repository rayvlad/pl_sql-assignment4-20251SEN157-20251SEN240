-- =====================================================================
-- PROCEDURE bulk_vs_loop_demo
-- Performance experiment: insert N rows (a) one by one in a loop and
-- (b) with FORALL, and print how long each took.
-- Why FORALL is faster: the loop makes N trips between the PL/SQL engine
-- and the SQL engine (N "context switches"); FORALL makes just ONE.
-- Uses the scratch table PERF_TEST. It cleans up after itself and does
-- not COMMIT or ROLLBACK anything of the caller.
-- Errors: -20100 invalid number of rows
-- =====================================================================
CREATE OR REPLACE PROCEDURE bulk_vs_loop_demo (
  p_rows IN PLS_INTEGER DEFAULT 10000
)
IS
  TYPE label_tab IS TABLE OF VARCHAR2(50);
  v_ids    num_list   := num_list();
  v_labels label_tab  := label_tab();
  v_start  NUMBER;
  v_loop_cs NUMBER;     -- centiseconds (1/100 s)
  v_bulk_cs NUMBER;
BEGIN
  IF p_rows IS NULL OR p_rows < 1 OR p_rows > 1000000 THEN
    RAISE_APPLICATION_ERROR(-20100, 'p_rows must be between 1 and 1,000,000.');
  END IF;

  DELETE FROM perf_test;

  -- (a) Row-by-row: one context switch per row
  v_start := DBMS_UTILITY.GET_TIME;
  FOR i IN 1 .. p_rows LOOP
    INSERT INTO perf_test (id, label) VALUES (i, 'row ' || i);
  END LOOP;
  v_loop_cs := DBMS_UTILITY.GET_TIME - v_start;

  DELETE FROM perf_test;

  -- (b) Bulk: prepare the data in memory first...
  v_ids.EXTEND(p_rows);
  v_labels.EXTEND(p_rows);
  FOR i IN 1 .. p_rows LOOP
    v_ids(i)    := i;
    v_labels(i) := 'row ' || i;
  END LOOP;

  -- ...then send it all in ONE call
  v_start := DBMS_UTILITY.GET_TIME;
  FORALL i IN 1 .. p_rows
    INSERT INTO perf_test (id, label) VALUES (v_ids(i), v_labels(i));
  v_bulk_cs := DBMS_UTILITY.GET_TIME - v_start;

  DBMS_OUTPUT.PUT_LINE('Rows inserted by FORALL: ' || SQL%ROWCOUNT);
  DBMS_OUTPUT.PUT_LINE('Loop   time: ' || v_loop_cs || ' centiseconds');
  DBMS_OUTPUT.PUT_LINE('FORALL time: ' || v_bulk_cs || ' centiseconds');
  IF v_bulk_cs > 0 THEN
    DBMS_OUTPUT.PUT_LINE('FORALL was about ' || ROUND(v_loop_cs / v_bulk_cs, 1) || 'x faster.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('FORALL was too fast to measure (under 0.01 s).');
  END IF;

  DELETE FROM perf_test;   -- clean up (uncommitted, like everything else here)
EXCEPTION
  WHEN OTHERS THEN
    RAISE;
END bulk_vs_loop_demo;
/
