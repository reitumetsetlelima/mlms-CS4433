#include <gtest/gtest.h>
#include "data/Database.h"
#include "domain/Errors.h"

class DatabaseTest : public ::testing::Test {
protected:
    mlms::Database db{":memory:"};
    void SetUp() override { db.execScriptFromFile(MLMS_SCHEMA_PATH); }

    void addStudent() {
        db.execScript(
            "INSERT INTO users(username,full_name,role,password_hash,password_salt,"
            "hash_iterations,created_at) VALUES ('stud1','Student One','STUDENT',"
            "'h','s',210000,'2026-01-01T00:00:00Z');");
    }
};

TEST_F(DatabaseTest, CreatesAll14Tables) {
    const char* tables[] = {"users", "departments", "courses", "course_allocations",
        "enrolments", "assignments", "extensions", "submissions",
        "submission_versions", "marks", "moderations", "moderator_designations",
        "notifications", "audit_log"};
    for (const char* t : tables) EXPECT_TRUE(db.tableExists(t)) << t;
}

TEST_F(DatabaseTest, DuplicateEnrolmentIsRejected) {
    db.execScript("INSERT INTO departments(name) VALUES ('Science');");
    db.execScript("INSERT INTO courses(code,title,department_id) VALUES ('C1','Course',1);");
    addStudent();
    const char* enrol =
        "INSERT INTO enrolments(course_id,student_id,enrolled_at) "
        "VALUES (1,1,'2026-01-01T00:00:00Z');";
    db.execScript(enrol);
    EXPECT_THROW(db.execScript(enrol), mlms::DatabaseError);
}

TEST_F(DatabaseTest, AuditLogCannotBeChanged) {
    addStudent();
    db.execScript(
        "INSERT INTO audit_log(user_id,occurred_at_utc,entity_type,entity_id,action,"
        "new_value,reason) VALUES (1,'2026-01-01T00:00:00Z','MARK',1,'MARK_CREATE','5','x');");
    EXPECT_THROW(db.execScript("UPDATE audit_log SET reason='changed';"), mlms::DatabaseError);
    EXPECT_THROW(db.execScript("DELETE FROM audit_log;"), mlms::DatabaseError);
}

TEST_F(DatabaseTest, BadSqlThrowsInsteadOfCrashing) {
    EXPECT_THROW(db.execScript("THIS IS NOT SQL"), mlms::DatabaseError);
}