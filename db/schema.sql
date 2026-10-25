-- MLMS schema (SQLite). Dates are stored as ISO-8601 UTC text: YYYY-MM-DDTHH:MM:SSZ
PRAGMA foreign_keys = ON;

CREATE TABLE users (
    user_id               INTEGER PRIMARY KEY AUTOINCREMENT,
    username              TEXT    NOT NULL UNIQUE CHECK (length(username) BETWEEN 3 AND 50),
    full_name             TEXT    NOT NULL CHECK (length(trim(full_name)) > 0),
    role                  TEXT    NOT NULL CHECK (role IN ('ADMINISTRATOR','LECTURER','HOD','STUDENT')),
    password_hash         TEXT    NOT NULL,
    password_salt         TEXT    NOT NULL,
    hash_iterations       INTEGER NOT NULL CHECK (hash_iterations >= 210000),
    is_active             INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1)),
    failed_login_count    INTEGER NOT NULL DEFAULT 0 CHECK (failed_login_count >= 0),
    locked_until          TEXT,
    must_change_password  INTEGER NOT NULL DEFAULT 1 CHECK (must_change_password IN (0,1)),
    created_at            TEXT    NOT NULL
);

CREATE TABLE departments (
    department_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name           TEXT    NOT NULL UNIQUE CHECK (length(trim(name)) > 0),
    hod_user_id    INTEGER UNIQUE REFERENCES users(user_id)      -- one HoD per department
);

CREATE TABLE courses (
    course_id      INTEGER PRIMARY KEY AUTOINCREMENT,
    code           TEXT    NOT NULL UNIQUE,
    title          TEXT    NOT NULL CHECK (length(trim(title)) > 0),
    department_id  INTEGER NOT NULL REFERENCES departments(department_id)
);

CREATE TABLE course_allocations (
    course_id      INTEGER NOT NULL REFERENCES courses(course_id),
    lecturer_id    INTEGER NOT NULL REFERENCES users(user_id),
    PRIMARY KEY (course_id, lecturer_id)
);

CREATE TABLE enrolments (
    course_id      INTEGER NOT NULL REFERENCES courses(course_id),
    student_id     INTEGER NOT NULL REFERENCES users(user_id),
    status         TEXT    NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','WITHDRAWN')),
    enrolled_at    TEXT    NOT NULL,
    PRIMARY KEY (course_id, student_id)                          -- rejects duplicate enrolments (FR-05)
);

CREATE TABLE assignments (
    assignment_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    course_id      INTEGER NOT NULL REFERENCES courses(course_id),
    created_by     INTEGER NOT NULL REFERENCES users(user_id),
    title          TEXT    NOT NULL CHECK (length(trim(title)) > 0),
    description    TEXT    NOT NULL DEFAULT '',
    deadline       TEXT    NOT NULL,
    max_mark       REAL    NOT NULL CHECK (max_mark > 0 AND max_mark <= 1000),
    created_at     TEXT    NOT NULL
);

CREATE TABLE extensions (
    extension_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    assignment_id  INTEGER NOT NULL REFERENCES assignments(assignment_id),
    student_id     INTEGER NOT NULL REFERENCES users(user_id),
    granted_by     INTEGER NOT NULL REFERENCES users(user_id),
    new_deadline   TEXT    NOT NULL,
    reason         TEXT    NOT NULL CHECK (length(trim(reason)) > 0),
    granted_at     TEXT    NOT NULL,
    UNIQUE (assignment_id, student_id)                           -- one extension per student per assignment
);

CREATE TABLE submissions (
    submission_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    assignment_id  INTEGER NOT NULL REFERENCES assignments(assignment_id),
    student_id     INTEGER NOT NULL REFERENCES users(user_id),
    status         TEXT    NOT NULL CHECK (status IN
                   ('SUBMITTED','LATE','MARKED','RETURNED','MODERATED','RELEASED')),
    UNIQUE (assignment_id, student_id)
);

CREATE TABLE submission_versions (
    version_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    submission_id      INTEGER NOT NULL REFERENCES submissions(submission_id),
    version_no         INTEGER NOT NULL CHECK (version_no BETWEEN 1 AND 10),
    original_filename  TEXT    NOT NULL,
    stored_path        TEXT    NOT NULL,
    file_type          TEXT    NOT NULL CHECK (file_type IN ('pdf','docx','txt','zip','png','jpg','jpeg','gif')),
    file_size_bytes    INTEGER NOT NULL CHECK (file_size_bytes > 0 AND file_size_bytes <= 10485760),
    submitted_at       TEXT    NOT NULL,
    UNIQUE (submission_id, version_no)
);

CREATE TABLE marks (
    mark_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    submission_id   INTEGER NOT NULL UNIQUE REFERENCES submissions(submission_id),
    marker_id       INTEGER NOT NULL REFERENCES users(user_id),
    awarded_mark    REAL    NOT NULL CHECK (awarded_mark >= 0 AND awarded_mark = round(awarded_mark, 1)),
    penalty_points  REAL    NOT NULL DEFAULT 0 CHECK (penalty_points >= 0),
    feedback        TEXT    NOT NULL CHECK (length(trim(feedback)) > 0 AND length(feedback) <= 2000),
    marked_at       TEXT    NOT NULL,
    released_at     TEXT,
    released_by     INTEGER REFERENCES users(user_id),
    CHECK ((released_at IS NULL) = (released_by IS NULL))
);

CREATE TABLE moderations (
    moderation_id   INTEGER PRIMARY KEY AUTOINCREMENT,
    submission_id   INTEGER NOT NULL REFERENCES submissions(submission_id),
    moderator_id    INTEGER NOT NULL REFERENCES users(user_id),
    outcome         TEXT    NOT NULL CHECK (outcome IN ('APPROVED','ADJUSTED','RETURNED')),
    new_mark        REAL    CHECK (new_mark >= 0 AND new_mark = round(new_mark, 1)),
    comment         TEXT,
    moderated_at    TEXT    NOT NULL,
    CHECK ((outcome = 'ADJUSTED') = (new_mark IS NOT NULL)),
    CHECK (outcome = 'APPROVED' OR length(trim(coalesce(comment,''))) > 0)
);

CREATE TABLE moderator_designations (
    designation_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    submission_id         INTEGER NOT NULL UNIQUE REFERENCES submissions(submission_id),
    acting_moderator_id   INTEGER NOT NULL REFERENCES users(user_id),
    designated_by         INTEGER NOT NULL REFERENCES users(user_id),
    designated_at         TEXT    NOT NULL
);

CREATE TABLE notifications (
    notification_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    recipient_id     INTEGER NOT NULL REFERENCES users(user_id),
    submission_id    INTEGER REFERENCES submissions(submission_id),
    type             TEXT    NOT NULL CHECK (type IN
                     ('PENDING_MODERATION','SUBMISSION_RETURNED','MARKS_RELEASED')),
    message          TEXT    NOT NULL,
    created_at       TEXT    NOT NULL,
    is_read          INTEGER NOT NULL DEFAULT 0 CHECK (is_read IN (0,1))
);

CREATE TABLE audit_log (
    audit_id         INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          INTEGER NOT NULL REFERENCES users(user_id),
    occurred_at_utc  TEXT    NOT NULL,
    entity_type      TEXT    NOT NULL CHECK (entity_type IN ('MARK','EXTENSION')),
    entity_id        INTEGER NOT NULL,                           -- polymorphic reference, deliberately no FK
    action           TEXT    NOT NULL CHECK (action IN
                     ('MARK_CREATE','MARK_UPDATE','PENALTY_RECALC','MODERATION_ADJUST','EXTENSION_GRANT')),
    old_value        TEXT,
    new_value        TEXT    NOT NULL,
    reason           TEXT    NOT NULL CHECK (length(trim(reason)) > 0)
);

CREATE INDEX idx_courses_department     ON courses(department_id);
CREATE INDEX idx_enrolments_student     ON enrolments(student_id);
CREATE INDEX idx_assignments_course     ON assignments(course_id);
CREATE INDEX idx_submissions_assignment ON submissions(assignment_id, status);
CREATE INDEX idx_notifications_inbox    ON notifications(recipient_id, is_read);
CREATE INDEX idx_audit_entity           ON audit_log(entity_type, entity_id);

-- Business rules that span tables are enforced with triggers
CREATE TRIGGER trg_department_hod_role
BEFORE INSERT ON departments WHEN NEW.hod_user_id IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'hod_user_id must reference a user with role HOD')
    WHERE (SELECT role FROM users WHERE user_id = NEW.hod_user_id) <> 'HOD';
END;

CREATE TRIGGER trg_department_hod_role_upd
BEFORE UPDATE OF hod_user_id ON departments WHEN NEW.hod_user_id IS NOT NULL
BEGIN
    SELECT RAISE(ABORT, 'hod_user_id must reference a user with role HOD')
    WHERE (SELECT role FROM users WHERE user_id = NEW.hod_user_id) <> 'HOD';
END;

CREATE TRIGGER trg_extension_window
BEFORE INSERT ON extensions
BEGIN
    SELECT RAISE(ABORT, 'extension must be after the deadline and at most 14 days beyond it')
    WHERE NEW.new_deadline <= (SELECT deadline FROM assignments WHERE assignment_id = NEW.assignment_id)
       OR NEW.new_deadline >  (SELECT strftime('%Y-%m-%dT%H:%M:%SZ', deadline, '+14 days')
                               FROM assignments WHERE assignment_id = NEW.assignment_id);
END;

CREATE TRIGGER trg_mark_max_ins
BEFORE INSERT ON marks
BEGIN
    SELECT RAISE(ABORT, 'awarded_mark exceeds the assignment maximum')
    WHERE NEW.awarded_mark > (SELECT a.max_mark FROM submissions s
                              JOIN assignments a ON a.assignment_id = s.assignment_id
                              WHERE s.submission_id = NEW.submission_id);
END;

CREATE TRIGGER trg_mark_max_upd
BEFORE UPDATE OF awarded_mark ON marks
BEGIN
    SELECT RAISE(ABORT, 'awarded_mark exceeds the assignment maximum')
    WHERE NEW.awarded_mark > (SELECT a.max_mark FROM submissions s
                              JOIN assignments a ON a.assignment_id = s.assignment_id
                              WHERE s.submission_id = NEW.submission_id);
END;

CREATE TRIGGER trg_audit_no_update BEFORE UPDATE ON audit_log
BEGIN SELECT RAISE(ABORT, 'audit_log is append-only'); END;

CREATE TRIGGER trg_audit_no_delete BEFORE DELETE ON audit_log
BEGIN SELECT RAISE(ABORT, 'audit_log is append-only'); END;
