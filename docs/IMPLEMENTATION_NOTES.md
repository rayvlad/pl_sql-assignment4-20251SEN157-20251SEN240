# Implementation and Performance Notes

## 1. Where each required concept is used
| Requirement | Where |
|---|---|
| %ROWTYPE record | `register_student_course` (`students%ROWTYPE`, `courses%ROWTYPE`), `update_score`, `calculate_gpa`, `bulk_assign_grade_letters` (collection of `enrollments%ROWTYPE`) |
| User-defined record | `register_student_course` (`registration_rec`) |
| Cursor-based record | `print_course_roster` (`c_roster%ROWTYPE`) |
| Associative array | `calculate_gpa` (letter to grade points) |
| Nested table | `num_list` type in `bulk_import_scores`, `bulk_assign_grade_letters`, `bulk_vs_loop_demo`; `student_score_tab` in `get_top_students` |
| VARRAY | `print_course_roster` (counters for A,B,C,D,F) |
| Implicit cursor INSERT | `register_student_course`, `update_score` (audit row), `bulk_vs_loop_demo` |
| Implicit cursor UPDATE with `SQL%FOUND` / `SQL%NOTFOUND` / `SQL%ROWCOUNT` | `update_score` |
| Implicit cursor DELETE with `SQL%NOTFOUND` / `SQL%ROWCOUNT` | `drop_enrollment` |
| Explicit cursor OPEN/FETCH/CLOSE | `print_course_roster` (parameterized cursor) |
| Cursor FOR loop | `calculate_gpa` |
| BULK COLLECT | `bulk_assign_grade_letters`, `get_top_students` |
| FORALL + SAVE EXCEPTIONS + `SQL%BULK_EXCEPTIONS` | `bulk_import_scores`, `bulk_assign_grade_letters` |
| Predefined exceptions | `NO_DATA_FOUND`: several; `TOO_MANY_ROWS`: `get_student_score`; `DUP_VAL_ON_INDEX`: `register_student_course` |
| User-defined exceptions | `e_student_not_active`, `e_course_full`, `e_empty_roster`, `e_size_mismatch` |
| `PRAGMA EXCEPTION_INIT` | `drop_enrollment` (ORA-02292), bulk procedures (ORA-24381) |
| `RAISE_APPLICATION_ERROR` | all procedures and functions (codes -20010 to -20111) |
| Functions called from SQL / PL/SQL | `test_success_cases.sql` tests S5 |

## 2. Design decisions
- **Errors are never hidden.** Functions raise errors instead of returning empty or misleading values. The only NULL results are honest ones (no score yet, no graded courses yet).
- **Procedures do not COMMIT.** The caller decides, so tests can ROLLBACK and be re-run.
- **Bulk partial failure.** `bulk_import_scores` keeps good rows and reports bad ones (caller chooses COMMIT or ROLLBACK). `bulk_assign_grade_letters` treats any failure as an error so the batch can be rolled back.

## 3. Performance considerations (bulk processing)
PL/SQL and SQL are two separate engines. Each SQL statement executed inside a PL/SQL loop forces a **context switch** between them. A loop of 20,000 inserts causes about 20,000 switches.

- `BULK COLLECT` fetches all rows of a query into a collection in **one** switch.
- `FORALL` sends the whole collection to the SQL engine in **one** switch, which then runs the DML for every element.

`bulk_vs_loop_demo` measures both approaches on the same data. _(After running test S8, In our run with 20,000 rows, the loop took 148 centiseconds and FORALL took 11 centiseconds, so FORALL was about 13.5x faster.

Trade-offs: collections live in memory (PGA), so a huge result set should be fetched in chunks with `BULK COLLECT ... LIMIT`. Row-by-row processing is still the right tool when each row needs its own complicated logic or its own error handling; in this project we use an explicit cursor for the roster for that reason.

`SAVE EXCEPTIONS` lets FORALL continue after a failing row; Oracle collects the failures in `SQL%BULK_EXCEPTIONS` (index and error code) and raises ORA-24381 at the end.
