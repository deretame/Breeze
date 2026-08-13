if(VCPKG_TARGET_IS_WINDOWS)
    vcpkg_check_linkage(ONLY_STATIC_LIBRARY)
endif()
# 强制 git 不转换行尾：本机全局 core.autocrlf=true 会把 vcpkg 检出的源码
# 转成 CRLF，导致 LF 补丁/替换无法匹配（这里通过 GIT_CONFIG_* 环境变量
# 在提取时即保持 LF）
set(ENV{GIT_CONFIG_COUNT} "1")
set(ENV{GIT_CONFIG_KEY_0} "core.autocrlf")
set(ENV{GIT_CONFIG_VALUE_0} "false")
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO NVIDIA/stdexec
    REF b73f140dbe5b25329e707991addd88707d0c8305
    SHA512 f08bbb86d9db19b0238ed32a77ba3474ba0286971f39840c3c07ef0854ac61bb6e87740508a70517dd3094eda35734abbd366c9226f34edcc6c031cdefa578c2
    HEAD_REF main
)

# ---- 针对 master（2026-08-10 提交）在 Windows/vcpkg 下的修复 ----
# 官方 ports/stdexec 的补丁基于旧版本，master 代码已变化无法应用，
# 故改用 vcpkg_replace_string 做等价修改。
if(VCPKG_TARGET_IS_WINDOWS)
    # 1. master 强制 CMAKE_THREAD_PREFER_PTHREAD TRUE，Windows 上 FindThreads
    #    会去找 pthread 库导致 configure 失败（上游疏漏）
    vcpkg_replace_string("${SOURCE_PATH}/CMakeLists.txt"
        "set(CMAKE_THREAD_PREFER_PTHREAD TRUE)"
        "set(CMAKE_THREAD_PREFER_PTHREAD FALSE)")

    # 2. clangd 辅助程序不应在 vcpkg 构建中编译
    vcpkg_replace_string("${SOURCE_PATH}/CMakeLists.txt"
        "if(STDEXEC_IS_TOP_LEVEL)"
        "if(0)")

    # 3. Boost 改用 vcpkg 提供的 boost-asio（提供 Boost::asio target），
    #    不走 CPM 下载（vcpkg 构建环境中不可用）
    vcpkg_replace_string("${SOURCE_PATH}/cmake/Modules/ConfigureASIO.cmake"
        "rapids_cpm_find(\n      Boost\n      \${BOOST_VERSION}\n      CPM_ARGS\n      URL\n      https://github.com/boostorg/boost/releases/download/boost-\${BOOST_VERSION}/boost-\${BOOST_VERSION}-cmake.tar.xz\n      OPTIONS\n      \"BOOST_SKIP_INSTALL_RULES OFF\")"
        "rapids_find_package(\n      Boost REQUIRED\n      COMPONENTS system asio\n      GLOBAL_TARGETS Boost::system Boost::asio\n      BUILD_EXPORT_SET stdexec-exports\n      INSTALL_EXPORT_SET stdexec-exports\n    )")
endif()

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        asio     STDEXEC_ENABLE_ASIO
        tbb      STDEXEC_ENABLE_TBB
        taskflow STDEXEC_ENABLE_TASKFLOW
)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH_RAPIDS
    REPO rapidsai/rapids-cmake
    REF v24.02.01 # stable tag (stdexec wants branch-24.02)
    SHA512 bb8f2b1177f6451d61f2de26f39fd6d31c2f0fb80b4cd1409edc3e6e4f726e80716ec177d510d0f31b8f39169cd8b58290861f0f217daedbd299e8e426d25891
    HEAD_REF main
)
vcpkg_replace_string("${SOURCE_PATH}/CMakeLists.txt" 
    [[file(DOWNLOAD https://raw.githubusercontent.com/rapidsai/rapids-cmake/branch-24.02/RAPIDS.cmake]]
    "file(COPY_FILE \"${SOURCE_PATH_RAPIDS}/RAPIDS.cmake\""
)

vcpkg_download_distfile(execution_bs
    URLS "https://raw.githubusercontent.com/cplusplus/sender-receiver/12fde4af201017e49efd39178126f661a04dbb94/execution.bs"
    FILENAME "execution.bs"
    SHA512 90bb992356f22e4091ed35ca922f6a0143abd748499985553c0660eaf49f88d031a8f900addb6b4cf9a39ac8d1ab7c858b79677e2459136a640b2c52afe3dd23
)
vcpkg_replace_string("${SOURCE_PATH}/CMakeLists.txt" 
    [[file(DOWNLOAD "https://raw.githubusercontent.com/cplusplus/sender-receiver/main/execution.bs"]]
    "file(COPY_FILE \"${execution_bs}\""
)

# stdexec uses cpm (via rapids-cmake).
# Setup a local cpm cache from assets cached by vcpkg
file(REMOVE_RECURSE "${CURRENT_BUILDTREES_DIR}/cpm")
# Version from rapids-cmake cpm/detail/download.cmake
set(CPM_DOWNLOAD_VERSION 0.38.5)
vcpkg_download_distfile(CPM_CMAKE
    URLS https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
    FILENAME CPM_${CPM_DOWNLOAD_VERSION}.cmake
    SHA512 a376162be4fe70408c000409f7a3798e881ed183cb51d57c9540718fdd539db9028755653bd3965ae7764b5c3e36adea81e0752fe85e40790f022fa1c4668cc6
)
file(INSTALL "${CPM_CMAKE}" DESTINATION "${CURRENT_BUILDTREES_DIR}/cpm/cpm")

# Version and patch from stdexec CMakeLists.txt
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH_ICM
    REPO iboB/icm
    REF v1.5.0 # from stdexec CMakeLists.txt
    SHA512 0d5173d7640e2b411dddfc67e1ee19c921817e58de36ea8325430ee79408edc0a23e17159e22dc4a05f169596ee866effa69e7cd0000b08f47bd090d5003ba1c
    
    HEAD_REF master
    PATCHES
        "${SOURCE_PATH}/cmake/cpm/patches/icm/regex-build-error.diff"
)

vcpkg_find_acquire_program(GIT)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DSTDEXEC_BUILD_TESTS=OFF
        -DSTDEXEC_BUILD_EXAMPLES=OFF
        "-DFETCHCONTENT_SOURCE_DIR_RAPIDS-CMAKE=${SOURCE_PATH_RAPIDS}"
        "-DCPM_SOURCE_CACHE=${CURRENT_BUILDTREES_DIR}/cpm"
        "-DCPM_icm_SOURCE=${SOURCE_PATH_ICM}"
        "-DGIT_EXECUTABLE=${GIT}"
        -DSTDEXEC_BUILD_PARALLEL_SCHEDULER=ON
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/stdexec)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.txt")
