#pragma once
#include <stdexcept>
#include <string>

namespace mlms {

class MlmsError : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};
class ValidationError : public MlmsError {
public:
    using MlmsError::MlmsError;
};
class AuthError : public MlmsError {
public:
    using MlmsError::MlmsError;
};
class NotFoundError : public MlmsError {
public:
    using MlmsError::MlmsError;
};
class RuleViolation : public MlmsError {
public:
    using MlmsError::MlmsError;
};
class DatabaseError : public MlmsError {
public:
    using MlmsError::MlmsError;
};

}  // namespace mlms