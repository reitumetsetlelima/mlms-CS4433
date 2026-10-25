#include "domain/Version.h"
#include <sqlite3.h>

namespace mlms {
const char* appVersion() { return "0.1"; }
const char* sqliteVersion() { return sqlite3_libversion(); }
}