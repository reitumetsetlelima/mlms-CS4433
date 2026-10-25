# MLMS: Moderated Learning Management System

CS4433 Software Engineering final project, National University of Lesotho.

C++17 console application with SQLite storage, built with CMake.

## Build
cmake -S . -B build -G Ninja
cmake --build build

## Run tests
ctest --test-dir build --output-on-failure

## Folders
- src/ : source code, one folder per layer
- tests/ : unit tests
- db/ : schema.sql
- docs/ : design documents