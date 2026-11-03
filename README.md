# Student Registration and Grading System (Oracle PL/SQL)

**Course:** Database Development with PL/SQL (INSY 8311), Group Assignment IV
**Class group:** _(I / B / C / D)_

## Group members
| Full name | Student ID |
|-----------|------------|
| _shimwa ray vladan_ | _(20251SEN157)_ |
| _(Nyirishema Kaliza Keva)_ | _(20251SEN240)_ |

## Application description
A small university system where students register for courses each semester and
lecturers record scores. The database stores departments, students, courses,
enrollments (with score and letter grade) and an audit log of score changes.

### Requirements the system satisfies
- Register a student in a course, only if the student is ACTIVE, the course has a free seat, and the student is not already enrolled.
- Update a score, recompute the letter grade (A 90+, B 80+, C 70+, D 60+, F below 60) and log the change.
- Drop an enrollment (refused if it has grade history).
- Print a course roster with a grade distribution.
- Import many scores at once and assign many letters at once (bulk processing), reporting rows that fail without losing the good rows.
- Compute a student's GPA and list the top students of a course.

## Database design
`DEPARTMENTS 1--* STUDENTS`, `DEPARTMENTS 1--* COURSES`, `STUDENTS 1--* ENROLLMENTS *--1 COURSES`, `ENROLLMENTS 1--* GRADE_LOG`.
All primary keys, foreign keys, UNIQUE, NOT NULL and CHECK constraints are in `00_schema/01_create_tables.sql`.

## How to run (Oracle 12c or newer, e.g. SQL Developer: open file, press F5)
1. `00_schema/01_create_tables.sql`
2. `00_schema/02_insert_sample_data.sql`
3. Compile **all files in `02_functions/` first** (the procedures call them), in any order.
4. Compile all files in `01_procedures/`.
5. Run `03_tests/test_success_cases.sql`, then `03_tests/test_error_cases.sql`.
6. Check the output, take screenshots into `screenshots/` (name: `<test_name>_output.png`).

> Functions are compiled before procedures because `register_student_course`, `update_score` and `bulk_assign_grade_letters` call functions.

## Where each requirement is demonstrated
See `docs/IMPLEMENTATION_NOTES.md` (concept-to-file table and performance explanation).

## AI usage statement
 We used an AI assistant to generate the idea of the system and initial codes improved them and to explain each concept step by step. We ran every script ourselves, read and understood the code, and are able to explain it. Both members are responsible for all submitted code.
