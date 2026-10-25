#include <gtest/gtest.h>
#include "infrastructure/Pbkdf2Hasher.h"

TEST(Pbkdf2HasherTest, CorrectPasswordVerifies) {
    mlms::Pbkdf2Hasher h;
    auto r = h.hash("S3cret!pass");
    EXPECT_TRUE(h.verify("S3cret!pass", r.saltHex, r.iterations, r.hashHex));
}

TEST(Pbkdf2HasherTest, WrongPasswordFails) {
    mlms::Pbkdf2Hasher h;
    auto r = h.hash("S3cret!pass");
    EXPECT_FALSE(h.verify("wrong", r.saltHex, r.iterations, r.hashHex));
}

TEST(Pbkdf2HasherTest, SamePasswordGivesDifferentHashes) {
    mlms::Pbkdf2Hasher h;
    auto a = h.hash("same");
    auto b = h.hash("same");
    EXPECT_NE(a.saltHex, b.saltHex);
    EXPECT_NE(a.hashHex, b.hashHex);
}

TEST(Pbkdf2HasherTest, HashIsNotPlainText) {
    mlms::Pbkdf2Hasher h;
    auto r = h.hash("S3cret!pass");
    EXPECT_EQ(r.hashHex.find("S3cret"), std::string::npos);
    EXPECT_GE(r.iterations, 210000);
}