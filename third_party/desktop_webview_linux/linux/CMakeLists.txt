cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "desktop_webview_linux")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "desktop_webview_linux_plugin")

find_package(PkgConfig REQUIRED)
pkg_check_modules(WebKit41 IMPORTED_TARGET webkit2gtk-4.1)
pkg_check_modules(LibSoup3 IMPORTED_TARGET libsoup-3.0)
if (WebKit41_FOUND AND LibSoup3_FOUND)
  set(WEBKIT_TARGET PkgConfig::WebKit41)
  set(LIBSOUP_TARGET PkgConfig::LibSoup3)
else()
  pkg_check_modules(WebKit40 REQUIRED IMPORTED_TARGET webkit2gtk-4.0)
  pkg_check_modules(LibSoup2 REQUIRED IMPORTED_TARGET libsoup-2.4)
  set(WEBKIT_TARGET PkgConfig::WebKit40)
  set(LIBSOUP_TARGET PkgConfig::LibSoup2)
endif()


add_library(${PLUGIN_NAME} SHARED
        "desktop_webview_linux_plugin.cc"
        webview_window.cc
        webview_window.h
        message_channel_plugin.h
        message_channel_plugin.cc
        )
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
        CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
        "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)
target_link_libraries(${PLUGIN_NAME} PRIVATE ${WEBKIT_TARGET})
target_link_libraries(${PLUGIN_NAME} PRIVATE ${LIBSOUP_TARGET})

# List of absolute paths to libraries that should be bundled with the plugin
set(desktop_webview_linux_bundled_libraries
        ""
        PARENT_SCOPE
        )
