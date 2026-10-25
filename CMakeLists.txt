cmake_minimum_required(VERSION 3.16)
project(MLMS LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(SQLite3 REQUIRED)
find_package(OpenSSL REQUIRED)

# Core library: every layer except the presentation layer and main
file(GLOB_RECURSE CORE_SRC CONFIGURE_DEPENDS
     src/domain/*.cpp src/application/*.cpp
     src/data/*.cpp src/infrastructure/*.cpp)
add_library(mlms_core ${CORE_SRC})
target_include_directories(mlms_core PUBLIC src)
target_link_libraries(mlms_core PUBLIC SQLite::SQLite3 OpenSSL::Crypto)

# The program
file(GLOB PRES_SRC CONFIGURE_DEPENDS src/presentation/*.cpp)
add_executable(mlms src/main.cpp ${PRES_SRC})
target_link_libraries(mlms mlms_core)

# Tests (GoogleTest is downloaded on first configure)
include(FetchContent)
FetchContent_Declare(googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip)
FetchContent_MakeAvailable(googletest)

enable_testing()
file(GLOB_RECURSE TEST_SRC CONFIGURE_DEPENDS tests/*.cpp)
add_executable(mlms_tests ${TEST_SRC})
target_link_libraries(mlms_tests mlms_core GTest::gtest_main)
target_compile_definitions(mlms_tests PRIVATE MLMS_SCHEMA_PATH="${CMAKE_SOURCE_DIR}/db/schema.sql")

include(GoogleTest)
gtest_discover_tests(mlms_tests)