cmake_minimum_required(VERSION 3.18)
project(LocalModelModule CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# iOS uses a static library — DynamicLibrary.process() links into the app binary.
# Build with:
#   cmake -B build-ios -G Xcode \
#         -DCMAKE_SYSTEM_NAME=iOS \
#         -DCMAKE_OSX_ARCHITECTURES=arm64 \
#         -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0
#   cmake --build build-ios --config Release

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

set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE          OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS    OFF CACHE BOOL "" FORCE)

# Enable Metal for GPU acceleration on Apple Silicon
set(GGML_METAL ON CACHE BOOL "" FORCE)

FetchContent_MakeAvailable(llama_cpp)

set(NATIVE_SRC ${CMAKE_CURRENT_SOURCE_DIR}/../../native)

# Static library — linked into the app so DynamicLibrary.process() can find it
add_library(local_model STATIC
    ${NATIVE_SRC}/src/local_model.cpp
)

target_include_directories(local_model
    PRIVATE ${NATIVE_SRC}/include/
)

target_link_libraries(local_model
    PRIVATE llama
)
