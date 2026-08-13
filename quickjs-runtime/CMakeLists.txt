cmake_minimum_required(VERSION 3.25)

# ---- vcpkg 单一 triplet：x64-windows-static-md（动态 CRT /MD，库本体静态）----
# 本工程是 Breeze 唯一的 CMake 入口（pixi 独立构建与 Dart hook 构建共用），
# toolchain 由调用方传入（pixi: script/pixi/configure.py；hook: hook/build.dart）。
# 以下默认值在 project() 前设置，toolchain 加载时生效：
# - 固定 static-md triplet：依赖全部静态链接，产物无 vcpkg DLL 运行时依赖
# - install root 固定到源码目录：pixi 与 hook 共享同一棵 vcpkg_installed 树
if(NOT WIN32)
  message(FATAL_ERROR "本工程目前仅支持 Windows（vcpkg triplet x64-windows-static-md）")
endif()
if(NOT DEFINED VCPKG_TARGET_TRIPLET)
  set(VCPKG_TARGET_TRIPLET "x64-windows-static-md" CACHE STRING "vcpkg triplet")
endif()
if(NOT DEFINED VCPKG_INSTALLED_DIR)
  # 安装树放在仓库根 third_party/：与 vcpkg 克隆同处，且避开 Dart hook 对
  # 本目录（hook sourceDir）的依赖追踪扫描
  set(VCPKG_INSTALLED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../third_party/vcpkg_installed" CACHE PATH "vcpkg install root")
endif()

project(quickjs_runtime VERSION 0.1.0 LANGUAGES CXX)

# hook 构建（DcbCMakeBuilder 环境缺 LOCALAPPDATA/APPDATA，vcpkg 无法定位
# 缓存目录）以 -DVCPKG_MANIFEST_MODE=OFF 纯消费已安装树；依赖统一由 pixi 侧
# （pixi run configure，manifest 模式）安装，这里做存在性检查。
if(DEFINED VCPKG_MANIFEST_MODE AND NOT VCPKG_MANIFEST_MODE
   AND NOT EXISTS "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
  message(FATAL_ERROR
    "未找到 vcpkg 依赖树 ${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}\n"
    "请先在仓库根目录运行: pixi run configure（安装全部 vcpkg 依赖）")
endif()

# 主程序与测试默认开启；Breeze hook 构建时显式传 -DQJS_RUNTIME_BUILD_TOOLS=OFF，
# 只产出 wind_core_cpp（及 dcb_runtime），跳过主程序与测试。
option(QJS_RUNTIME_BUILD_TOOLS "构建 quickjs_runtime 主程序与测试" ON)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 目标平台：Windows 10（boost::asio 等库要求显式定义）
add_compile_definitions(_WIN32_WINNT=0x0A00)

# stdexec::task 的 task_scheduler 有 72 字节 inline 存储限制；fetch::io_scheduler
# 的 schedule 链（post|upon_error|upon_stopped）opstate 约 184 字节，超限。
# 项目级统一放大（所有 TU 必须一致，避免 ODR 违规）。
add_compile_definitions(STDEXEC_TASK_SCHEDULE_OPSTATE_SIZE=256)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "" FORCE)
endif()

# ---- polyfill JS 嵌入头文件（configure 期由 script/pixi/embed_js.py 生成，不入库）----
# 生成物：include/qjsbind/polyfill/dyn_blob_embedded.hpp。
# 注意：JS 源变更后需重新 configure 才会再生成（execute_process 无依赖追踪）。
set(DYN_BLOB_EMBEDDED
    ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/dyn_blob_embedded.hpp)
execute_process(COMMAND
    python ${CMAKE_CURRENT_SOURCE_DIR}/../script/pixi/embed_js.py
        ${DYN_BLOB_EMBEDDED}
        ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/dyn_blob.js
        --namespace qjs::dyn::polyfill
    COMMAND_ERROR_IS_FATAL ANY)

# bundle 分发器（HostRuntime 的 JS 侧）：同款 configure 期生成，不入库。
set(BUNDLE_DISPATCHER_EMBEDDED
    ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/bundle_dispatcher_embedded.hpp)
execute_process(COMMAND
    python ${CMAKE_CURRENT_SOURCE_DIR}/../script/pixi/embed_js.py
        ${BUNDLE_DISPATCHER_EMBEDDED}
        ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/bundle_dispatcher.js
        --namespace qjs::polyfill
    COMMAND_ERROR_IS_FATAL ANY)

# source map 库（@jridgewell/trace-mapping 的 esbuild 打包产物，由 js/ 工程
# 用 pnpm 构建：pixi run build-js-assets）：同款 configure 期生成，不入库。
set(SOURCE_MAP_LIB_EMBEDDED
    ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/source_map_lib_embedded.hpp)
execute_process(COMMAND
    python ${CMAKE_CURRENT_SOURCE_DIR}/../script/pixi/embed_js.py
        ${SOURCE_MAP_LIB_EMBEDDED}
        ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/source_map_lib.js
        --namespace qjs::polyfill
    COMMAND_ERROR_IS_FATAL ANY)

# Breeze 风格运行时 API（runtime_api.js 手写 + buffer_lib.js 为 js/ 工程 esbuild
# 打包产物，npm buffer）：同款 configure 期生成，不入库。
set(RUNTIME_API_EMBEDDED
    ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/runtime_api_embedded.hpp)
execute_process(COMMAND
    python ${CMAKE_CURRENT_SOURCE_DIR}/../script/pixi/embed_js.py
        ${RUNTIME_API_EMBEDDED}
        ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/runtime_api.js
        ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/buffer_lib.js
        --namespace qjs::polyfill
    COMMAND_ERROR_IS_FATAL ANY)

# Breeze 风格 crypto API polyfill（crypto.js 手写，对齐 kit crypto.d.ts 签名）：
# 同款 configure 期生成，不入库。
set(CRYPTO_EMBEDDED
    ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/crypto_embedded.hpp)
execute_process(COMMAND
    python ${CMAKE_CURRENT_SOURCE_DIR}/../script/pixi/embed_js.py
        ${CRYPTO_EMBEDDED}
        ${CMAKE_CURRENT_SOURCE_DIR}/include/qjsbind/polyfill/crypto.js
        --namespace qjs::polyfill
    COMMAND_ERROR_IS_FATAL ANY)

# ---- 第三方库（均由 vcpkg 提供）----
find_package(fmt CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(Boost REQUIRED COMPONENTS asio uuid url)
find_package(ada CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)
find_package(unofficial-brotli CONFIG REQUIRED)
find_package(utf8cpp CONFIG REQUIRED)
find_package(stdexec CONFIG REQUIRED)
find_package(glaze CONFIG REQUIRED)
find_package(qjs CONFIG REQUIRED)
find_package(lexbor CONFIG REQUIRED)
# static-md triplet 下 lexbor 只导出 lexbor::lexbor_static，补别名兼容
if(NOT TARGET lexbor::lexbor AND TARGET lexbor::lexbor_static)
  add_library(lexbor::lexbor ALIAS lexbor::lexbor_static)
endif()
find_package(GTest CONFIG REQUIRED)
# 图片解码三件套（wind_core_cpp 的 jm_decode 用）：静态链接
find_package(PNG REQUIRED)             # PNG::PNG（vcpkg wrapper → config 包）
find_package(WebP CONFIG REQUIRED)     # WebP::webp / WebP::webpdecoder / WebP::sharpyuv

# ---- dart_cpp_bridge：异步运行时（dcb 包，经 cmake/dcb_bridge.cmake 引入）----
# 头文件（dart_cpp_bridge/channel.hpp 等）与 dcb_runtime 均由 dart_cpp_bridge::runtime 提供。
# 依赖策略：stdexec / Boost 由本工程 vcpkg 提供，不由 dcb 拉取。
set(DCB_FETCH_STDEXEC OFF)
set(DCB_FETCH_ASIO OFF)
set(DCB_USE_BOOST_ASIO ON)
include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/dcb_bridge.cmake)
# boost 模式下 dcb 不会给 asio_iface 补 Boost 头路径，这里补上
if(TARGET asio_iface)
  target_link_libraries(asio_iface INTERFACE Boost::asio)
endif()

# ---- fetchcore：独立纯 C++ fetch 核心库（不 include/不链接任何 quickjs/qjsbind）----
# 类型/Client/中间件 header-only（include/fetch/），传输实现在此静态库。
# EXCLUDE_FROM_ALL：hook 构建（只交付 wind_core_cpp.dll）不白编它；
# pixi 构建里 tests/主程序链接它时仍会被自动拉出，不受影响。
add_library(fetchcore STATIC EXCLUDE_FROM_ALL src/fetch/beast_transport.cpp src/fetch/socks5.cpp src/fetch/http_proxy.cpp src/fetch/connection_pool.cpp src/fetch/pooled_transport.cpp src/fetch/dns_resolver.cpp src/fetch/doh_resolver.cpp src/fetch/process_proxy.cpp)
if(MSVC)
    target_compile_options(fetchcore PRIVATE /utf-8)
endif()
target_include_directories(fetchcore PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)
target_link_libraries(fetchcore PUBLIC
    Boost::asio
    ada::ada
    OpenSSL::SSL
    OpenSSL::Crypto
    ZLIB::ZLIB
    unofficial::brotli::brotlidec
    unofficial::brotli::brotlicommon
    STDEXEC::stdexec
    glaze::glaze
    dart_cpp_bridge::runtime
)

# ---- qjsbind：QuickJS-NG 的 C++ 自动绑定层（header-only）----
add_library(qjsbind INTERFACE)
target_include_directories(qjsbind INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_link_libraries(qjsbind INTERFACE qjs Boost::uuid Boost::url ada::ada utf8cpp::utf8cpp fetchcore spdlog::spdlog)

# ---- wind_core_cpp：Breeze Dart 侧 native 库（dcb wire，hook 构建的产物）----
# 源码留在 ../native/（api/ 声明 + api_impl/ 实现 + generated/ wire），
# 由 dcb_gen_tool 依据 dart_cpp_bridge.yaml 生成/扫描（cpp_root: native/）。
set(BREEZE_NATIVE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../native)
set(GEN_WIRE ${BREEZE_NATIVE_DIR}/generated/wire_dispatch.cpp)
if(NOT EXISTS "${GEN_WIRE}")
  message(FATAL_ERROR
    "Missing generated wire. Run: dcb_gen_tool generate dart_cpp_bridge.yaml")
endif()
# 不显式 SHARED：尊重调用方 -DBUILD_SHARED_LIBS（hook 传 ON 产出 DLL；
# pixi 独立构建默认静态库，仅供本机编译验证）
add_library(wind_core_cpp
  ${BREEZE_NATIVE_DIR}/generated/wire_dispatch.cpp
  ${BREEZE_NATIVE_DIR}/api_impl/bridge_api.cpp
  ${BREEZE_NATIVE_DIR}/api_impl/jm_decode.cpp
  ${BREEZE_NATIVE_DIR}/api_impl/jm_md5.cpp
)
target_include_directories(wind_core_cpp PRIVATE
  ${BREEZE_NATIVE_DIR}
  ${BREEZE_NATIVE_DIR}/api
  ${BREEZE_NATIVE_DIR}/api_impl
  ${BREEZE_NATIVE_DIR}/generated
)
target_link_libraries(wind_core_cpp PRIVATE
  $<LINK_LIBRARY:WHOLE_ARCHIVE,dart_cpp_bridge::runtime>
  PNG::PNG
  WebP::webp
)
if(MSVC)
  target_compile_options(wind_core_cpp PRIVATE /utf-8)
endif()

# ---- 主程序 ----
if(QJS_RUNTIME_BUILD_TOOLS)
add_executable(quickjs_runtime src/main.cpp)
target_link_libraries(quickjs_runtime PRIVATE
    qjs
    qjsbind
    Boost::asio
    STDEXEC::stdexec
    fmt::fmt
    spdlog::spdlog
)

# ---- 测试 ----
add_executable(quickjs_runtime_tests
    tests/test_main.cpp
    tests/stream_test.cpp
    tests/channel_test.cpp
    tests/sleep_test.cpp
    tests/m1_binding_test.cpp
    tests/m2_binding_test.cpp
    tests/m3_binding_test.cpp
    tests/m4_binding_test.cpp
    tests/fetch_test.cpp
    tests/fetchcore_test.cpp
    tests/wpt_runner.cpp
    tests/socks5_test.cpp
    tests/http_proxy_test.cpp
    tests/proxy_config_test.cpp
    tests/proxy_3proxy_test.cpp
    tests/cheerio_bench_test.cpp
    tests/cheerio_fast_test.cpp
    tests/mini_task_test.cpp
    tests/task_test.cpp
    tests/fetch_easy_test.cpp
    tests/connection_pool_test.cpp
    tests/dns_resolver_test.cpp
    tests/doh_resolver_test.cpp
    tests/log_test.cpp
    tests/dynamic_call_test.cpp
    tests/dyn_blob_polyfill_test.cpp
    tests/blob_store_test.cpp
    tests/host_runtime_test.cpp
    tests/opencc_test.cpp
    tests/runtime_api_test.cpp
    tests/gzip_test.cpp
    tests/crypto_test.cpp
)
target_link_libraries(quickjs_runtime_tests PRIVATE
    qjs
    qjsbind
    STDEXEC::stdexec
    fmt::fmt
    spdlog::spdlog
    dart_cpp_bridge::runtime
    GTest::gtest_main
    Boost::asio
    unofficial::brotli::brotlienc
    ZLIB::ZLIB
    lexbor::lexbor  # cheerio（BreezeHtml）用，不属网络层（fetch_cpp_decoupling.md §P4）
)

# Debug 构建 JS_CallInternal 栈帧 ~21KB：默认 1MB 线程栈下 ~48 层 JS 递归
# 即崩（QuickJS 栈检查被 __chkstk 抢先）。给测试进程 16MB 栈。
set_target_properties(quickjs_runtime_tests PROPERTIES
    LINK_FLAGS "/STACK:16777216")
endif()

