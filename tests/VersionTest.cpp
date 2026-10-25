#include <gtest/gtest.h>
#include <string>
#include "domain/Version.h"

TEST(VersionTest, AppVersionIsSet) {
    EXPECT_FALSE(std::string(mlms::appVersion()).empty());
}

TEST(VersionTest, SqliteIsLinked) {
    EXPECT_FALSE(std::string(mlms::sqliteVersion()).empty());
}