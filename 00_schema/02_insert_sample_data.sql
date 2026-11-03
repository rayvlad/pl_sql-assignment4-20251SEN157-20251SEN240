-- =====================================================================
-- 02_insert_sample_data.sql
-- Sample data. Run AFTER 01_create_tables.sql.
-- NOTE: enrollment_id is auto-generated (1,2,3...) in insertion order.
--       The test scripts rely on these ids, so do not reorder the
--       enrollment INSERTs below.
-- =====================================================================

-- Departments
INSERT INTO departments (dept_id, dept_name) VALUES (10, 'Information Systems');
INSERT INTO departments (dept_id, dept_name) VALUES (20, 'Business Administration');
INSERT INTO departments (dept_id, dept_name) VALUES (30, 'Mathematics and Statistics');

-- Students (1009 is GRADUATED, 1010 is SUSPENDED: used by error tests)
INSERT INTO students VALUES (1001, 'Alice',   'Uwase',      'alice.uwase@example.com',      10, DATE '2024-09-01', 'ACTIVE');
INSERT INTO students VALUES (1002, 'Bob',     'Mugisha',    'bob.mugisha@example.com',      10, DATE '2024-09-01', 'ACTIVE');
INSERT INTO students VALUES (1003, 'Chantal', 'Mukamana',   'chantal.mukamana@example.com', 10, DATE '2024-09-01', 'ACTIVE');
INSERT INTO students VALUES (1004, 'David',   'Habimana',   'david.habimana@example.com',   20, DATE '2025-01-15', 'ACTIVE');
INSERT INTO students VALUES (1005, 'Esther',  'Ingabire',   'esther.ingabire@example.com',  10, DATE '2025-01-15', 'ACTIVE');
INSERT INTO students VALUES (1006, 'Frank',   'Niyonzima',  'frank.niyonzima@example.com',  30, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students VALUES (1007, 'Grace',   'Uwimana',    'grace.uwimana@example.com',    30, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students VALUES (1008, 'Hassan',  'Nkurunziza', 'hassan.nkurunziza@example.com',20, DATE '2025-09-01', 'ACTIVE');
INSERT INTO students VALUES (1009, 'Ivan',    'Kamanzi',    'ivan.kamanzi@example.com',     10, DATE '2021-09-01', 'GRADUATED');
INSERT INTO students VALUES (1010, 'Josiane', 'Mutesi',     'josiane.mutesi@example.com',   20, DATE '2024-01-15', 'SUSPENDED');

-- Courses (course 105 has capacity 2: used to test the "course full" error)
INSERT INTO courses VALUES (101, 'INSY8311', 'Database Development with PL/SQL', 3, 10, 30);
INSERT INTO courses VALUES (102, 'INSY8312', 'Software Engineering',             3, 10, 30);
INSERT INTO courses VALUES (103, 'MATH101',  'Calculus I',                       4, 30, 30);
INSERT INTO courses VALUES (104, 'BUSA201',  'Principles of Management',         3, 20, 30);
INSERT INTO courses VALUES (105, 'INSY9001', 'Advanced Seminar',                 2, 10,  2);
INSERT INTO courses VALUES (106, 'STAT201',  'Statistics',                       3, 30, 30);

-- Enrollments: (student, course, semester, score, grade_letter)
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1001, 101, '2026-FALL', 92, 'A');  -- id 1
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1002, 101, '2026-FALL', 85, 'B');  -- id 2
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1003, 101, '2026-FALL', 74, 'C');  -- id 3
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1004, 101, '2026-FALL', 58, 'F');  -- id 4
-- ids 5, 8, 11 have a score but NO letter yet (bulk_assign_grade_letters fixes them)
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1005, 101, '2026-FALL', 79, NULL); -- id 5
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1001, 102, '2026-FALL', 88, 'B');  -- id 6
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1002, 102, '2026-FALL', 67, 'D');  -- id 7
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1003, 102, '2026-FALL', 91, NULL); -- id 8
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1001, 103, '2026-FALL', 95, 'A');  -- id 9
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1006, 103, '2026-FALL', 81, 'B');  -- id 10
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1007, 103, '2026-FALL', 62, NULL); -- id 11
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1008, 104, '2026-FALL', 77, 'C');  -- id 12
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1006, 104, '2026-FALL', 90, 'A');  -- id 13
-- ids 14, 15: course 105 (capacity 2) is now FULL; no scores yet
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1001, 105, '2026-FALL', NULL, NULL); -- id 14
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1002, 105, '2026-FALL', NULL, NULL); -- id 15
-- id 16: same student + same course, DIFFERENT semester (used to show TOO_MANY_ROWS)
INSERT INTO enrollments (student_id, course_id, semester, score, grade_letter) VALUES (1001, 101, '2025-FALL', 85, 'B');  -- id 16

COMMIT;

PROMPT Sample data inserted.
