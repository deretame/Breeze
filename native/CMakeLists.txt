cmake_minimum_required(VERSION 3.24)
project(wind_core_cpp LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Shared helper: locates dart_cpp_bridge, sets up the runtime dependency,
# and verifies that generated wire code exists.
include(cmake/dcb_bridge.cmake)

# --- Library target ---
option(BUILD_SHARED_LIBS "Build shared library" ON)
add_library(wind_core_cpp
  generated/wire_dispatch.cpp
  api_impl/bridge_api.cpp
)

target_include_directories(wind_core_cpp
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/api
    ${CMAKE_CURRENT_SOURCE_DIR}/generated
)

target_link_libraries(wind_core_cpp PRIVATE
  $<LINK_LIBRARY:WHOLE_ARCHIVE,dart_cpp_bridge::runtime>)

if(WIN32)
  target_compile_options(wind_core_cpp PRIVATE /utf-8)
endif()
