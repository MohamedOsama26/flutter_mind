cmake_minimum_required(VERSION 3.18)
project(LocalModelModule CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

# Pin to a specific llama.cpp release tag for reproducible builds.
# Find the latest release at: https://github.com/ggerganov/llama.cpp/releases
set(LLAMA_CPP_TAG "b3958" CACHE STRING "llama.cpp release tag")

FetchContent_Declare(
    llama_cpp
    GIT_REPOSITORY https://github.com/ggerganov/llama.cpp.git
    GIT_TAG        ${LLAMA_CPP_TAG}
    GIT_SHALLOW    TRUE
)

# Disable everything we don't need
set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE          OFF CACHE BOOL "" FORCE)

# Enable OpenMP on arm64 for better multi-thread performance
if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(GGML_OPENMP ON CACHE BOOL "" FORCE)
endif()

FetchContent_MakeAvailable(llama_cpp)

# Source lives in the shared native/ folder — one level up from this file
set(NATIVE_SRC ${CMAKE_CURRENT_SOURCE_DIR}/../native)

add_library(local_model SHARED
    ${NATIVE_SRC}/src/local_model.cpp
)

target_include_directories(local_model
    PRIVATE ${NATIVE_SRC}/include/
)

target_link_libraries(local_model
    PRIVATE
    llama
    android
    log
)
