#include <iostream>
#include "domain/Version.h"

int main() {
    std::cout << "MLMS v" << mlms::appVersion()
              << " (SQLite " << mlms::sqliteVersion() << ")\n";
    return 0;
}