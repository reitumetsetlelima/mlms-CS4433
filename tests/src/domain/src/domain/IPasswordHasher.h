#pragma once
#include <string>

namespace mlms {

struct HashResult {
    std::string hashHex;
    std::string saltHex;
    int iterations;
};

class IPasswordHasher {
public:
    virtual ~IPasswordHasher() = default;
    virtual HashResult hash(const std::string& password) const = 0;
    virtual bool verify(const std::string& password,
                        const std::string& saltHex,
                        int iterations,
                        const std::string& expectedHashHex) const = 0;
};

}  // namespace mlms