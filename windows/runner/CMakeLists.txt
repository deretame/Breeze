cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# ==============================================================================
# 🔍 托盘图标调试与复制脚本
# ==============================================================================

# 1. 定义源路径 (通常在 windows/runner/resources/app_icon.ico)
# CMAKE_CURRENT_SOURCE_DIR 指的是当前 CMakeLists.txt 所在的目录 (即 windows/runner)
set(TRAY_ICON_SRC "${CMAKE_CURRENT_SOURCE_DIR}/resources/app_icon.ico")

# 2. 定义目标路径 (即编译生成的 exe 旁边)
set(TRAY_ICON_DEST "${CMAKE_CURRENT_BINARY_DIR}/app_icon.ico")

# 3. 打印调试日志 (在编译输出中搜索 "[Zephyr]" 关键词)
message(STATUS "-------------------------------------------------------")
message(STATUS ">>> [Zephyr] 正在检查托盘图标...")
message(STATUS ">>> [Zephyr] 源文件路径: ${TRAY_ICON_SRC}")
message(STATUS ">>> [Zephyr] 目标路径:   ${TRAY_ICON_DEST}")

if(EXISTS "${TRAY_ICON_SRC}")
    message(STATUS ">>> [Zephyr] ✅ 成功找到图标文件！正在复制...")
    # 执行复制 (COPYONLY 表示如果目标已存在且较新，则不复制)
    configure_file("${TRAY_ICON_SRC}" "${TRAY_ICON_DEST}" COPYONLY)
else()
    # 如果找不到，打印错误警告，并列出 resources 目录下有什么
    message(WARNING ">>> [Zephyr] ❌ 错误：在源路径找不到图标文件！")
    file(GLOB FILES_IN_RES "${CMAKE_CURRENT_SOURCE_DIR}/resources/*")
    message(STATUS ">>> [Zephyr] resources 目录下的文件列表: ${FILES_IN_RES}")
endif()

message(STATUS "-------------------------------------------------------")
# ==============================================================================