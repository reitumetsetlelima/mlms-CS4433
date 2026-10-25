#include "data/Database.h"
#include "domain/Errors.h"

#include <fstream>
#include <sstream>

namespace mlms {

Database::Database(const std::string& path) {
    if (sqlite3_open(path.c_str(), &db_) != SQLITE_OK) {
        std::string msg = db_ ? sqlite3_errmsg(db_) : "out of memory";
        sqlite3_close(db_);
        db_ = nullptr;
        throw DatabaseError("cannot open database: " + msg);
    }
    execScript("PRAGMA foreign_keys = ON;");
}

Database::~Database() {
    if (db_) sqlite3_close(db_);
}

void Database::execScript(const std::string& sql) {
    char* err = nullptr;
    if (sqlite3_exec(db_, sql.c_str(), nullptr, nullptr, &err) != SQLITE_OK) {
        std::string msg = err ? err : "unknown error";
        sqlite3_free(err);
        throw DatabaseError("database error: " + msg);
    }
}

void Database::execScriptFromFile(const std::string& path) {
    std::ifstream in(path);
    if (!in) throw DatabaseError("cannot read file: " + path);
    std::stringstream buffer;
    buffer << in.rdbuf();
    execScript(buffer.str());
}

bool Database::tableExists(const std::string& name) {
    const char* sql = "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?;";
    sqlite3_stmt* stmt = nullptr;
    if (sqlite3_prepare_v2(db_, sql, -1, &stmt, nullptr) != SQLITE_OK) {
        throw DatabaseError(std::string("database error: ") + sqlite3_errmsg(db_));
    }
    sqlite3_bind_text(stmt, 1, name.c_str(), -1, SQLITE_TRANSIENT);
    bool found = (sqlite3_step(stmt) == SQLITE_ROW);
    sqlite3_finalize(stmt);
    return found;
}

void Database::begin() { execScript("BEGIN;"); }
void Database::commit() { execScript("COMMIT;"); }
void Database::rollback() { execScript("ROLLBACK;"); }

}  // namespace mlms