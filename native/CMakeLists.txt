cmake_minimum_required(VERSION 3.24)
project(wind_core_cpp LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Shared helper: locates dart_cpp_bridge, sets up the runtime dependency,
# and verifies that generated wire code exists.
include(cmake/dcb_bridge.cmake)

# --- Third-party dependencies (libwebp + libpng + zlib) ---
include(FetchContent)

# zlib（libpng 依赖）
set(SKIP_INSTALL_ALL ON CACHE BOOL "" FORCE)
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
FetchContent_Declare(zlib
  GIT_REPOSITORY https://github.com/madler/zlib.git
  GIT_TAG v1.3.1
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(zlib)
# 让 libpng 的 find_package(ZLIB) 直接命中刚构建的静态库
set(ZLIB_INCLUDE_DIR "${zlib_SOURCE_DIR};${zlib_BINARY_DIR}" CACHE PATH "" FORCE)
set(ZLIB_LIBRARY zlibstatic CACHE STRING "" FORCE)
if(NOT TARGET ZLIB::ZLIB)
  add_library(ZLIB::ZLIB ALIAS zlibstatic)
endif()
target_include_directories(zlibstatic PUBLIC
  "${zlib_SOURCE_DIR}" "${zlib_BINARY_DIR}")

# libpng（静态库）
# 强制走“无 awk”分支：Git Bash 自带的 awk 会触发 genout.cmake 编译
# pnglibconf.c 的复杂路径（缺少 zlib include 而失败），直接用预生成配置头。
# 注意不能设 *-NOTFOUND（会被 find_program 重新搜索），用假值常量绕过。
set(AWK FALSE CACHE FILEPATH "Disable awk: use prebuilt pnglibconf.h" FORCE)
set(PNG_SHARED OFF CACHE BOOL "" FORCE)
set(PNG_STATIC ON CACHE BOOL "" FORCE)
set(PNG_EXECUTABLES OFF CACHE BOOL "" FORCE)
set(PNG_TESTS OFF CACHE BOOL "" FORCE)
set(PNG_BUILD_ZLIB ON CACHE BOOL "" FORCE)
FetchContent_Declare(libpng
  GIT_REPOSITORY https://github.com/pnggroup/libpng.git
  GIT_TAG v1.6.43
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(libpng)
# pnglibconf.h 生成在 build 目录，补进 png_static 的公开头路径
target_include_directories(png_static PUBLIC "${libpng_BINARY_DIR}")

# libwebp（静态库，只保留核心编解码）
set(WEBP_BUILD_ANIM_UTILS OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_CWEBP OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_DWEBP OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_GIF2WEBP OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_IMG2WEBP OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_VWEBP OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_WEBPINFO OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_WEBPMUX OFF CACHE BOOL "" FORCE)
set(WEBP_BUILD_EXTRAS OFF CACHE BOOL "" FORCE)
# 临时切到静态库：全局 BUILD_SHARED_LIBS=ON（ wind_core_cpp 是 DLL），
# 但 libwebp 需要静态链接进来，避免运行时多带一个 libwebp.dll
set(BUILD_SHARED_LIBS OFF)
FetchContent_Declare(libwebp
  GIT_REPOSITORY https://github.com/webmproject/libwebp.git
  GIT_TAG v1.4.0
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(libwebp)
set(BUILD_SHARED_LIBS ON)

# --- Library target ---
option(BUILD_SHARED_LIBS "Build shared library" ON)
add_library(wind_core_cpp
  generated/wire_dispatch.cpp
  api_impl/bridge_api.cpp
  api_impl/jm_decode.cpp
  api_impl/jm_md5.cpp
)

target_include_directories(wind_core_cpp
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/api
    ${CMAKE_CURRENT_SOURCE_DIR}/api_impl
    ${CMAKE_CURRENT_SOURCE_DIR}/generated
)

target_link_libraries(wind_core_cpp PRIVATE
  $<LINK_LIBRARY:WHOLE_ARCHIVE,dart_cpp_bridge::runtime>
  png_static
  webp
)

if(WIN32)
  target_compile_options(wind_core_cpp PRIVATE /utf-8)
endif()
