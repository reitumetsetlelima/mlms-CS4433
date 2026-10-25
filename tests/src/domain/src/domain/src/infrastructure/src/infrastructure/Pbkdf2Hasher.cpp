#include "infrastructure/Pbkdf2Hasher.h"
#include "domain/Errors.h"

#include <openssl/crypto.h>
#include <openssl/evp.h>
#include <openssl/rand.h>

#include <vector>

namespace mlms {
namespace {

const size_t kSaltBytes = 16;
const size_t kKeyBytes = 32;

std::string toHex(const unsigned char* data, size_t n) {
    static const char* digits = "0123456789abcdef";
    std::string out;
    out.reserve(n * 2);
    for (size_t i = 0; i < n; ++i) {
        out.push_back(digits[data[i] >> 4]);
        out.push_back(digits[data[i] & 15]);
    }
    return out;
}

std::vector<unsigned char> fromHex(const std::string& s) {
    if (s.size() % 2 != 0) throw ValidationError("invalid salt");
    std::vector<unsigned char> out;
    for (size_t i = 0; i + 1 < s.size(); i += 2) {
        out.push_back(static_cast<unsigned char>(
            std::stoi(s.substr(i, 2), nullptr, 16)));
    }
    return out;
}

std::string derive(const std::string& password,
                   const std::vector<unsigned char>& salt, int iterations) {
    unsigned char key[kKeyBytes];
    int ok = PKCS5_PBKDF2_HMAC(password.c_str(), static_cast<int>(password.size()),
                               salt.data(), static_cast<int>(salt.size()),
                               iterations, EVP_sha256(),
                               static_cast<int>(kKeyBytes), key);
    if (ok != 1) throw MlmsError("password hashing failed");
    return toHex(key, kKeyBytes);
}

}  // namespace

HashResult Pbkdf2Hasher::hash(const std::string& password) const {
    unsigned char salt[kSaltBytes];
    if (RAND_bytes(salt, static_cast<int>(kSaltBytes)) != 1) {
        throw MlmsError("could not generate a random salt");
    }
    std::vector<unsigned char> saltVec(salt, salt + kSaltBytes);
    return HashResult{derive(password, saltVec, kIterations),
                      toHex(salt, kSaltBytes), kIterations};
}

bool Pbkdf2Hasher::verify(const std::string& password, const std::string& saltHex,
                          int iterations, const std::string& expectedHashHex) const {
    std::string actual = derive(password, fromHex(saltHex), iterations);
    if (actual.size() != expectedHashHex.size()) return false;
    return CRYPTO_memcmp(actual.data(), expectedHashHex.data(), actual.size()) == 0;
}

}  // namespace mlms