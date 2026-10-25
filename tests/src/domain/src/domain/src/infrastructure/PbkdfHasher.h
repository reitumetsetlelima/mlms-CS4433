#pragma once
#include "domain/IPasswordHasher.h"

namespace mlms {

class Pbkdf2Hasher : public IPasswordHasher {
public:
    static constexpr int kIterations = 210000;
    HashResult hash(const std::string& password) const override;
    bool verify(const std::string& password,
                const std::string& saltHex,
                int iterations,
                const std::string& expectedHashHex) const override;
};

}  // namespace mlms