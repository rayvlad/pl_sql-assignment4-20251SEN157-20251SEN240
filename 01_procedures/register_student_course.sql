-- =====================================================================
-- PROCEDURE register_student_course
-- Enrolls one student in one course for a semester.
-- Uses: %ROWTYPE records, a user-defined RECORD, implicit cursor
--       (INSERT + SQL%ROWCOUNT), user-defined exceptions,
--       predefined exceptions, RAISE_APPLICATION_ERROR.
-- Errors raised:
--   -20040 semester is empty        -20041 student not found
--   -20042 student not ACTIVE       -20043 course not found
--   -20044 course is full           -20045 already enrolled
-- =====================================================================
CREATE OR REPLACE PROCEDURE register_student_course (
  p_student_id IN  NUMBER,
  p_course_id  IN  NUMBER,
  p_semester   IN  VARCHAR2,
  p_result     OUT VARCHAR2
)
IS
  v_student  students%ROWTYPE;     -- %ROWTYPE record (copy of a table row)
  v_course   courses%ROWTYPE;

  -- User-defined record: our own custom group of fields
  TYPE registration_rec IS RECORD (
    student_name  VARCHAR2(100),
    course_label  VARCHAR2(150),
    seats_left    NUMBER
  );
  v_info registration_rec;

  -- User-defined exceptions
  e_student_not_active EXCEPTION;
  e_course_full        EXCEPTION;
BEGIN
  IF p_semester IS NULL THEN
    RAISE_APPLICATION_ERROR(-20040, 'Semester is required (example: 2026-FALL).');
  END IF;

  -- Load the student row (NO_DATA_FOUND -> friendly message)
  BEGIN
    SELECT * INTO v_student FROM students WHERE student_id = p_student_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20041, 'Student ' || p_student_id || ' not found.');
  END;

  -- Load the course row
  BEGIN
    SELECT * INTO v_course FROM courses WHERE course_id = p_course_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20043, 'Course ' || p_course_id || ' not found.');
  END;

  -- Business rule 1: only ACTIVE students may register
  IF v_student.status <> 'ACTIVE' THEN
    RAISE e_student_not_active;
  END IF;

  -- Business rule 2: the course must have a free seat
  v_info.student_name := v_student.first_name || ' ' || v_student.last_name;
  v_info.course_label := v_course.course_code || ' - ' || v_course.course_name;
  v_info.seats_left   := v_course.max_capacity
                         - get_enrollment_count(p_course_id, p_semester);
  IF v_info.seats_left <= 0 THEN
    RAISE e_course_full;
  END IF;

  -- Implicit cursor: Oracle opens/closes it automatically for the INSERT
  INSERT INTO enrollments (student_id, course_id, semester)
  VALUES (p_student_id, p_course_id, p_semester);

  IF SQL%ROWCOUNT = 1 THEN
    p_result := 'SUCCESS: ' || v_info.student_name || ' registered in '
                || v_info.course_label || ' (' || p_semester || '). Seats left: '
                || (v_info.seats_left - 1);
  END IF;
EXCEPTION
  WHEN e_student_not_active THEN
    RAISE_APPLICATION_ERROR(-20042,
      'Student ' || p_student_id || ' has status ' || v_student.status ||
      ' and cannot register.');
  WHEN e_course_full THEN
    RAISE_APPLICATION_ERROR(-20044,
      'Course ' || v_course.course_code || ' is full (' ||
      v_course.max_capacity || ' seats) for ' || p_semester || '.');
  WHEN DUP_VAL_ON_INDEX THEN      -- predefined: unique constraint violated
    RAISE_APPLICATION_ERROR(-20045,
      'Student ' || p_student_id || ' is already enrolled in course ' ||
      p_course_id || ' for ' || p_semester || '.');
  WHEN OTHERS THEN
    RAISE;   -- never silently ignore unexpected errors
END register_student_course;
/
