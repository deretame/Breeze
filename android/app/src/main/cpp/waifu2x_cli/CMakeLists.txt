# CMakeLists.txt for the waifu2x Android CLI binary.
#
# Builds a standalone executable `waifu2x-ncnn` that is later renamed to
# `libwaifu2x_cli.so` so Gradle packages it as a native library.
#
# Static libraries used:
#   - ncnn          (third_party/android_ncnn_deps/ncnn-android-vulkan-static)
#   - OpenCV        (third_party/android_ncnn_deps/OpenCV-android-sdk, static)
#   - libwebp       (third_party/android_ncnn_deps/libwebp, built here)
#
# Runtime dependencies left dynamic:
#   - libc++_shared.so   (provided by Flutter / NDK)
#   - libvulkan.so       (system Vulkan loader)

cmake_minimum_required(VERSION 3.22.1)
project(waifu2x-ncnn)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
set(DEPS_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../third_party/android_ncnn_deps")
get_filename_component(DEPS_ROOT "${DEPS_ROOT}" ABSOLUTE)

set(UPSTREAM_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../../third_party/RealSR-NCNN-Android/RealSR-NCNN-Android-CLI")
get_filename_component(UPSTREAM_ROOT "${UPSTREAM_ROOT}" ABSOLUTE)

set(WAIFU2X_SRC "${UPSTREAM_ROOT}/Waifu2x/src/main/jni")
set(COMMON_SRC "${UPSTREAM_ROOT}/common")

# ---------------------------------------------------------------------------
# libwebp (static, built from source)
# ---------------------------------------------------------------------------
set(libwebp_DIR "${DEPS_ROOT}/libwebp")
if(NOT EXISTS "${libwebp_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "libwebp source not found at ${libwebp_DIR}")
endif()

option(WEBP_ENABLE_SIMD "" ON)
option(WEBP_BUILD_ANIM_UTILS "" OFF)
option(WEBP_BUILD_CWEBP "" OFF)
option(WEBP_BUILD_DWEBP "" OFF)
option(WEBP_BUILD_GIF2WEBP "" OFF)
option(WEBP_BUILD_IMG2WEBP "" OFF)
option(WEBP_BUILD_VWEBP "" OFF)
option(WEBP_BUILD_WEBPINFO "" OFF)
option(WEBP_BUILD_WEBPMUX "" OFF)
option(WEBP_BUILD_EXTRAS "" OFF)
option(WEBP_BUILD_WEBP_JS "" OFF)
option(WEBP_NEAR_LOSSLESS "" OFF)
option(WEBP_ENABLE_SWAP_16BIT_CSP "" OFF)

add_subdirectory(${libwebp_DIR} ${CMAKE_CURRENT_BINARY_DIR}/libwebp)

# ---------------------------------------------------------------------------
# OpenCV (static)
# ---------------------------------------------------------------------------
set(OpenCV_DIR "${DEPS_ROOT}/OpenCV-android-sdk/sdk/native/jni")
set(OpenCV_STATIC ON)
find_package(OpenCV REQUIRED)

# ---------------------------------------------------------------------------
# ncnn (static)
# ---------------------------------------------------------------------------
set(ncnn_DIR "${DEPS_ROOT}/ncnn-android-vulkan-static/${ANDROID_ABI}/lib/cmake/ncnn")
find_package(ncnn REQUIRED)

# ncnn imported target may carry -fno-rtti / -fno-exceptions; waifu2x CLI is
# pure C++ and doesn't need them, and OpenCV headers are also fine with them.
# Keep them as-is for this executable.

# ---------------------------------------------------------------------------
# waifu2x-ncnn executable
# ---------------------------------------------------------------------------
add_executable(
    ${PROJECT_NAME}
    ${WAIFU2X_SRC}/main.cpp
    ${WAIFU2X_SRC}/waifu2x.cpp
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${WAIFU2X_SRC}
    ${COMMON_SRC}
)

target_link_libraries(${PROJECT_NAME}
    ncnn
    ${OpenCV_LIBS}
    webp
    android
    log
)

# Strip symbols in release builds to reduce size.
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${ANDROID_STRIP} $<TARGET_FILE:${PROJECT_NAME}>
    )
endif()
