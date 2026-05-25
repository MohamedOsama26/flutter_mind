cmake_minimum_required(VERSION 3.18)
project(LocalModelModule CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# Pin to a specific llama.cpp release tag for reproducible builds.
# Find the latest release at: https://github.com/ggerganov/llama.cpp/releases
set(LLAMA_CPP_TAG "b4659" CACHE STRING "llama.cpp release tag")

FetchContent_Declare(
    llama_cpp
    GIT_REPOSITORY https://github.com/ggerganov/llama.cpp.git
    GIT_TAG        ${LLAMA_CPP_TAG}
    GIT_SHALLOW    TRUE
)

# Disable everything we don't need — significantly speeds up the build
set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE          OFF CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(llama_cpp)

add_library(local_model SHARED
    src/local_model.cpp
)

target_include_directories(local_model
    PRIVATE include/
)

target_link_libraries(local_model
    PRIVATE llama
)
