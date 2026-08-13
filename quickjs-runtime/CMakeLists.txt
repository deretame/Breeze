cmake_minimum_required(VERSION 3.25)

project(quickjs_runtime VERSION 0.1.0 LANGUAGES CXX)

# 主程序与测试仅在本工程独立构建时默认开启；
# 作为库被 add_subdirectory 引入（如 Breeze native/）时默认关闭，只暴露库目标。
option(QJS_RUNTIME_BUILD_TOOLS "构建 quickjs_runtime 主程序与测试" ${PROJECT_IS_TOP_LEVEL})

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
find_package(GTest CONFIG REQUIRED)

# ---- dart_cpp_bridge：异步运行时（dcb 包，经 native/cmake/dcb_bridge.cmake 引入）----
# 头文件（dart_cpp_bridge/channel.hpp 等）与 dcb_runtime 均由 dart_cpp_bridge::runtime 提供。
# 与 native/ 共享同一套依赖策略：stdexec / Boost 由本工程 vcpkg 提供，不由 dcb 拉取。
set(DCB_FETCH_STDEXEC OFF)
set(DCB_FETCH_ASIO OFF)
set(DCB_USE_BOOST_ASIO ON)
include(${CMAKE_CURRENT_SOURCE_DIR}/../native/cmake/dcb_bridge.cmake)
# boost 模式下 dcb 不会给 asio_iface 补 Boost 头路径，这里补上
if(TARGET asio_iface)
  target_link_libraries(asio_iface INTERFACE Boost::asio)
endif()

# ---- fetchcore：独立纯 C++ fetch 核心库（不 include/不链接任何 quickjs/qjsbind）----
# 类型/Client/中间件 header-only（include/fetch/），传输实现在此静态库。
add_library(fetchcore STATIC src/fetch/beast_transport.cpp src/fetch/socks5.cpp src/fetch/http_proxy.cpp src/fetch/connection_pool.cpp src/fetch/pooled_transport.cpp src/fetch/dns_resolver.cpp src/fetch/doh_resolver.cpp src/fetch/process_proxy.cpp)
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

