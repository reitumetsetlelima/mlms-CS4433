#pragma once
#include <sqlite3.h>
#include <string>

namespace mlms {

// Wraps one SQLite connection. Only the data layer uses this class.
class Database {
public:
    explicit Database(const std::string& path);  // use ":memory:" for tests
    ~Database();
    Database(const Database&) = delete;
    Database& operator=(const Database&) = delete;

    void execScript(const std::string& sql);
    void execScriptFromFile(const std::string& path);
    bool tableExists(const std::string& name);

    void begin();
    void commit();
    void rollback();

    sqlite3* handle() const { return db_; }

private:
    sqlite3* db_ = nullptr;
};

}  // namespace mlms