-- =====================================================================
-- 01_create_tables.sql
-- Student Registration and Grading System (Oracle 12c or newer)
-- Creates: tables, relationships (foreign keys), constraints, and the
-- SQL collection/object types used by the functions and procedures.
-- Safe to re-run: it drops the old objects first.
-- =====================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ---------- 0. Clean up (so the script can be run many times) --------
BEGIN
  FOR r IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('GRADE_LOG','ENROLLMENTS','COURSES',
                                 'STUDENTS','DEPARTMENTS','PERF_TEST')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || r.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
  FOR r IN (SELECT type_name FROM user_types
            WHERE type_name IN ('STUDENT_SCORE_TAB','STUDENT_SCORE_OBJ','NUM_LIST')) LOOP
    EXECUTE IMMEDIATE 'DROP TYPE ' || r.type_name || ' FORCE';
  END LOOP;
END;
/

-- ---------- 1. Tables -------------------------------------------------
CREATE TABLE departments (
  dept_id    NUMBER(4)    CONSTRAINT pk_departments PRIMARY KEY,
  dept_name  VARCHAR2(60) NOT NULL CONSTRAINT uq_dept_name UNIQUE
);

CREATE TABLE students (
  student_id       NUMBER(6)    CONSTRAINT pk_students PRIMARY KEY,
  first_name       VARCHAR2(40) NOT NULL,
  last_name        VARCHAR2(40) NOT NULL,
  email            VARCHAR2(100) NOT NULL CONSTRAINT uq_student_email UNIQUE,
  dept_id          NUMBER(4)    NOT NULL
                   CONSTRAINT fk_students_dept REFERENCES departments(dept_id),
  enrollment_date  DATE         DEFAULT SYSDATE NOT NULL,
  status           VARCHAR2(10) DEFAULT 'ACTIVE' NOT NULL
                   CONSTRAINT ck_student_status
                   CHECK (status IN ('ACTIVE','SUSPENDED','GRADUATED'))
);

CREATE TABLE courses (
  course_id     NUMBER(6)    CONSTRAINT pk_courses PRIMARY KEY,
  course_code   VARCHAR2(10) NOT NULL CONSTRAINT uq_course_code UNIQUE,
  course_name   VARCHAR2(100) NOT NULL,
  credits       NUMBER(1)    NOT NULL CONSTRAINT ck_course_credits CHECK (credits BETWEEN 1 AND 6),
  dept_id       NUMBER(4)    NOT NULL
                CONSTRAINT fk_courses_dept REFERENCES departments(dept_id),
  max_capacity  NUMBER(3)    DEFAULT 30 NOT NULL CONSTRAINT ck_course_capacity CHECK (max_capacity > 0)
);

CREATE TABLE enrollments (
  enrollment_id  NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_enrollments PRIMARY KEY,
  student_id     NUMBER(6)  NOT NULL CONSTRAINT fk_enr_student REFERENCES students(student_id),
  course_id      NUMBER(6)  NOT NULL CONSTRAINT fk_enr_course  REFERENCES courses(course_id),
  semester       VARCHAR2(10) NOT NULL,
  enroll_date    DATE DEFAULT SYSDATE NOT NULL,
  score          NUMBER(5,2) CONSTRAINT ck_enr_score  CHECK (score BETWEEN 0 AND 100),
  grade_letter   VARCHAR2(1) CONSTRAINT ck_enr_letter CHECK (grade_letter IN ('A','B','C','D','F')),
  CONSTRAINT uq_enrollment UNIQUE (student_id, course_id, semester)
);

CREATE TABLE grade_log (
  log_id         NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_grade_log PRIMARY KEY,
  enrollment_id  NUMBER NOT NULL CONSTRAINT fk_log_enrollment REFERENCES enrollments(enrollment_id),
  old_score      NUMBER(5,2),
  new_score      NUMBER(5,2),
  changed_by     VARCHAR2(30) DEFAULT USER,
  changed_on     TIMESTAMP    DEFAULT SYSTIMESTAMP
);

-- Scratch table used only by the performance demo (bulk vs loop)
CREATE TABLE perf_test (
  id     NUMBER,
  label  VARCHAR2(50)
);

-- ---------- 2. Types used by bulk processing and functions ------------
-- A list of numbers (nested table stored in the database schema)
CREATE OR REPLACE TYPE num_list AS TABLE OF NUMBER;
/

-- One "row" of a top-students result, and a list of such rows
CREATE OR REPLACE TYPE student_score_obj AS OBJECT (
  student_id  NUMBER,
  full_name   VARCHAR2(100),
  score       NUMBER
);
/

CREATE OR REPLACE TYPE student_score_tab AS TABLE OF student_score_obj;
/

PROMPT Schema created successfully.
