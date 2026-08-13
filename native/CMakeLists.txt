cmake_minimum_required(VERSION 3.24)
project(wind_core_cpp LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# --- dart_cpp_bridge 依赖策略 ---
# 关闭 dcb 对 stdexec / asio 的 FetchContent 拉取，改用 boost::asio；
# stdexec（STDEXEC::stdexec）与 Boost 改由 quickjs-runtime 的 vcpkg 提供。
set(DCB_FETCH_STDEXEC OFF)
set(DCB_FETCH_ASIO OFF)
set(DCB_USE_BOOST_ASIO ON)

# quickjs-runtime 的 vcpkg 依赖（stdexec / Boost / OpenSSL / fmt / …）。
# 需先在仓库根目录执行 pixi run configure（或 setup-vcpkg 后任意一次 vcpkg
# manifest 安装）生成 quickjs-runtime/vcpkg_installed/。
set(QJS_VCPKG_INSTALLED
    "${CMAKE_CURRENT_SOURCE_DIR}/../quickjs-runtime/vcpkg_installed/x64-windows")
# libpng / libwebp / zlib 走 vcpkg 的 x64-windows-static-md（动态 CRT /MD，
# 与全局一致；库本体静态链接进 wind_core_cpp.dll，避免运行时多带 DLL）：
#   cd quickjs-runtime
#   third_party/vcpkg/vcpkg install --x-install-root=vcpkg_installed \
#       --triplet x64-windows-static-md
set(QJS_VCPKG_STATIC_MD
    "${CMAKE_CURRENT_SOURCE_DIR}/../quickjs-runtime/vcpkg_installed/x64-windows-static-md")
if(NOT EXISTS "${QJS_VCPKG_INSTALLED}" OR NOT EXISTS "${QJS_VCPKG_STATIC_MD}")
  message(FATAL_ERROR
    "未找到 vcpkg 依赖目录（需要 x64-windows 与 x64-windows-static-md）\n"
    "请先在仓库根目录运行: pixi run configure（生成 x64-windows），再执行\n"
    "  cd quickjs-runtime && third_party/vcpkg/vcpkg install \\\n"
    "    --x-install-root=vcpkg_installed --triplet x64-windows-static-md")
endif()
# static-md 树里也装了全套依赖（含静态版 Boost），不能直接进
# CMAKE_PREFIX_PATH——否则 quickjs-runtime 的 find_package(Boost) 会命中
# 静态库，与 TUs 的 BOOST_*_DYN_LINK 宏冲突。改用 <Pkg>_DIR 定点引用
# libpng / libwebp / zlib 的 config 包。
set(ZLIB_DIR "${QJS_VCPKG_STATIC_MD}/share/zlib")
set(PNG_DIR "${QJS_VCPKG_STATIC_MD}/share/png")
set(WebP_DIR "${QJS_VCPKG_STATIC_MD}/share/WebP")
list(APPEND CMAKE_PREFIX_PATH "${QJS_VCPKG_INSTALLED}")
# FindOpenSSL 不用 CMAKE_PREFIX_PATH，而 cmake 会把自身安装前缀（pixi 环境）
# 加进 CMAKE_SYSTEM_PREFIX_PATH，导致命中 pixi 版 libssl 而链接失败——固定到 vcpkg。
set(OPENSSL_ROOT_DIR "${QJS_VCPKG_INSTALLED}")

# Shared helper: locates dart_cpp_bridge, sets up the runtime dependency.
include(cmake/dcb_bridge.cmake)

# --- Generated wire check ---
set(GEN_WIRE "${CMAKE_CURRENT_SOURCE_DIR}/generated/wire_dispatch.cpp")
if(NOT EXISTS "${GEN_WIRE}")
  message(FATAL_ERROR
    "Missing generated wire. Run: dcb_gen_tool generate dart_cpp_bridge.yaml")
endif()

# --- Third-party dependencies (vcpkg, x64-windows-static-md) ---
# 注意：vcpkg 静态 zlib 的 config 包只提供 ZLIB::ZLIBSTATIC，ZLIB::ZLIB 别名
# 平时由 vcpkg toolchain 的 wrapper 提供——这里没走 toolchain，手动补别名，
# 否则 PNGConfig 的 find_dependency(ZLIB) 会退回模块模式找到 x64-windows 的
# 动态 z.lib，给 DLL 引入 z.dll 运行时依赖。
find_package(ZLIB CONFIG REQUIRED)   # ZLIB::ZLIBSTATIC
if(NOT TARGET ZLIB::ZLIB)
  add_library(ZLIB::ZLIB ALIAS ZLIB::ZLIBSTATIC)
endif()
find_package(PNG CONFIG REQUIRED)    # PNG::PNG
find_package(WebP CONFIG REQUIRED)   # WebP::webp / WebP::webpdecoder / WebP::sharpyuv

# --- quickjs-runtime 子工程（fetchcore / qjsbind / 测试等）---
# 内部会 include native/cmake/dcb_bridge.cmake（带重复包含保护），
# 并复用上面设置好的 DCB_* 策略与 vcpkg prefix path。
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../quickjs-runtime
                 ${CMAKE_CURRENT_BINARY_DIR}/quickjs_runtime)

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
  PNG::PNG
  WebP::webp
)

if(WIN32)
  target_compile_options(wind_core_cpp PRIVATE /utf-8)
endif()
