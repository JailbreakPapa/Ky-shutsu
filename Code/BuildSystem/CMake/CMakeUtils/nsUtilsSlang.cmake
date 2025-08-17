#[=======================================================================[
  Slang Integration Utilities

  Provides functions to download and integrate the latest (or a specified)
  release of the Slang shading language (https://github.com/shader-slang/slang)
  into the existing build system, placing the sources under
  Code/ThirdParty/slang.

  Public Entry Points:
    ns_slang_init()          - Ensures Slang sources are present and added.
    ns_link_slang_target(<t>) - Convenience helper to link a target against
                                available Slang libraries and set include dirs.

  Behavior:
    * If NS_SLANG_VERSION is "latest" (default) the GitHub releases API is
      queried to discover the most recent tag.
    * The matching source archive is downloaded and extracted using the
      shared ns_download_and_extract() helper.
    * Extraction occurs into Code/ThirdParty/slang/slang-<tag>/ ...
    * The Slang CMake project is added via add_subdirectory() if a
      CMakeLists.txt exists in the extracted folder.
    * Option variables for Slang are set to avoid building tests/examples.

  Customization Cache Variables:
    NS_SLANG_ENABLE              (BOOL, default ON)  : Master enable switch.
    NS_SLANG_VERSION             (STRING, default latest)
    NS_SLANG_ROOT                (PATH)             : Install root.
    NS_SLANG_FORCE_DOWNLOAD      (BOOL, default OFF): Re-download even if same tag present.

  Notes / Fallbacks:
    * If the GitHub API call fails, we fall back to the tag 'master'.
    * CMake 3.20+ provides string(JSON ...) which we use to parse the API
      response.
    * We guard against multiple invocations by writing a marker file with the
      resolved tag.
    * Linking helper attempts to link targets that Slang commonly defines
      (slang, slang-gfx) if they exist.

  This file is auto-included by nsUtils.cmake (it glob-includes CMakeUtils/*).
 #]=======================================================================]

set(NS_SLANG_ENABLE ON CACHE BOOL "Enable integration of Slang shading language")
set(NS_SLANG_VERSION "latest" CACHE STRING "Slang version tag to use (or 'latest')")
set(NS_SLANG_FORCE_DOWNLOAD OFF CACHE BOOL "Force re-download of Slang even if already present")

function(_ns_slang_resolve_latest_tag OUT_VAR)
    # Query GitHub Releases API for latest tag
    set(API_URL "https://api.github.com/repos/shader-slang/slang/releases/latest")
    set(API_JSON "${CMAKE_BINARY_DIR}/slang_latest.json")
    file(DOWNLOAD "${API_URL}" "${API_JSON}" STATUS DL_STATUS LOG DL_LOG TIMEOUT 15)
    list(GET DL_STATUS 0 DL_CODE)
    if(NOT DL_CODE EQUAL 0)
        message(WARNING "Slang: Failed to query GitHub API for latest release (code=${DL_CODE}). Falling back to 'master'.")
        set(${OUT_VAR} "master" PARENT_SCOPE)
        return()
    endif()
    file(READ "${API_JSON}" API_CONTENT)
    # Parse tag_name; if parsing fails fallback
    string(JSON HAS_TAG ERROR_VARIABLE JSON_ERR GET "${API_CONTENT}" tag_name)
    if(NOT JSON_ERR STREQUAL "")
        message(WARNING "Slang: Could not parse latest tag from API JSON (${JSON_ERR}). Falling back to 'master'.")
        set(${OUT_VAR} "master" PARENT_SCOPE)
        return()
    endif()
    set(${OUT_VAR} "${HAS_TAG}" PARENT_SCOPE)
endfunction()

function(ns_slang_init)
    if(NOT NS_SLANG_ENABLE)
        message(STATUS "Slang integration disabled (NS_SLANG_ENABLE=OFF)")
        return()
    endif()

    # Pull base path info from global properties (set earlier in root CMakeLists)
    get_property(NS_CMAKE_RELPATH_CODE GLOBAL PROPERTY NS_CMAKE_RELPATH_CODE)
    if(NOT NS_CMAKE_RELPATH_CODE)
        message(FATAL_ERROR "NS_CMAKE_RELPATH_CODE global property not set – call after ns_pull_all_vars/ns_cmake_init.")
    endif()

    set(NS_SLANG_ROOT "${CMAKE_SOURCE_DIR}/${NS_CMAKE_RELPATH_CODE}/ThirdParty/slang" CACHE PATH "Root directory for Slang sources")
    file(MAKE_DIRECTORY "${NS_SLANG_ROOT}")

    # Resolve tag
    set(RESOLVED_TAG "")
    if(NS_SLANG_VERSION STREQUAL "latest")
        _ns_slang_resolve_latest_tag(RESOLVED_TAG)
    else()
        set(RESOLVED_TAG "${NS_SLANG_VERSION}")
    endif()

    if(RESOLVED_TAG STREQUAL "")
        set(RESOLVED_TAG "master")
    endif()

    # Marker file to avoid repeated downloads
    set(SLANG_MARKER "${NS_SLANG_ROOT}/.slang_tag")
    set(NEED_DOWNLOAD ON)
    if(EXISTS "${SLANG_MARKER}" AND NOT NS_SLANG_FORCE_DOWNLOAD)
        file(READ "${SLANG_MARKER}" EXISTING_TAG)
        string(STRIP "${EXISTING_TAG}" EXISTING_TAG)
        if(EXISTING_TAG STREQUAL RESOLVED_TAG)
            set(NEED_DOWNLOAD OFF)
        endif()
    endif()

    if(NEED_DOWNLOAD)
        message(STATUS "Slang: Downloading tag '${RESOLVED_TAG}' ...")
        # Source archive URL; tags typically prefixed with 'v', keep as-is user specified
        set(ARCHIVE_URL "https://github.com/shader-slang/slang/archive/refs/tags/${RESOLVED_TAG}.zip")
        # Fallback if tag download fails (e.g., using 'master')
        if(RESOLVED_TAG STREQUAL "master" OR RESOLVED_TAG STREQUAL "main")
            set(ARCHIVE_URL "https://github.com/shader-slang/slang/archive/refs/heads/${RESOLVED_TAG}.zip")
        endif()
        # Use helper to download & extract
        ns_download_and_extract("${ARCHIVE_URL}" "${NS_SLANG_ROOT}" "slang-${RESOLVED_TAG}")
        file(WRITE "${SLANG_MARKER}" "${RESOLVED_TAG}")
    else()
        message(STATUS "Slang: Tag '${RESOLVED_TAG}' already present – skipping download.")
    endif()

    # Determine extracted directory name (GitHub archive produces slang-<tag> or slang-<hash>)
    file(GLOB SLANG_DIR_CANDIDATES "${NS_SLANG_ROOT}/slang-${RESOLVED_TAG}*")
    list(LENGTH SLANG_DIR_CANDIDATES CAND_COUNT)
    if(CAND_COUNT EQUAL 0)
        message(WARNING "Slang: Could not locate extracted directory for tag '${RESOLVED_TAG}'.")
        return()
    endif()
    list(GET SLANG_DIR_CANDIDATES 0 NS_SLANG_SOURCE_DIR)
    set(NS_SLANG_SOURCE_DIR "${NS_SLANG_SOURCE_DIR}" CACHE PATH "Resolved Slang source directory" FORCE)
    set_property(GLOBAL PROPERTY NS_SLANG_SOURCE_DIR "${NS_SLANG_SOURCE_DIR}")

    # If a CMake project exists, configure typical options and add it.
    if(EXISTS "${NS_SLANG_SOURCE_DIR}/CMakeLists.txt")
        # Suppress tests / extras where possible. (Guard with CACHE to avoid overwriting user changes.)
        set(SLANG_ENABLE_TESTS OFF CACHE BOOL "Disable Slang tests" FORCE)
        set(SLANG_ENABLE_EXAMPLES OFF CACHE BOOL "Disable Slang examples" FORCE)
        set(SLANG_ENABLE_REPL OFF CACHE BOOL "Disable Slang REPL" FORCE)
        # Attempt to avoid installing unless desired.
        set(SLANG_INSTALL OFF CACHE BOOL "Disable Slang install targets" FORCE)
        # Add subdirectory with isolated binary dir
        set(SLANG_BINARY_DIR "${CMAKE_BINARY_DIR}/slang-${RESOLVED_TAG}")
        if(NOT TARGET slang AND NOT TARGET slang-gfx)
            add_subdirectory("${NS_SLANG_SOURCE_DIR}" "${SLANG_BINARY_DIR}")
        endif()
    else()
        message(WARNING "Slang: No CMakeLists.txt found at ${NS_SLANG_SOURCE_DIR}; cannot add as subdirectory.")
    endif()

    # Basic interface target if upstream targets not present (header-only fallback)
    if(NOT TARGET slang)
        add_library(slang INTERFACE)
        message(STATUS "Slang: Created INTERFACE target 'slang' (headers only fallback).")
    endif()

    # Add include directories (common layout guesses)
    if(TARGET slang)
        target_include_directories(slang INTERFACE
            "$<BUILD_INTERFACE:${NS_SLANG_SOURCE_DIR}/source>"
            "$<BUILD_INTERFACE:${NS_SLANG_SOURCE_DIR}/include>"
            "$<INSTALL_INTERFACE:include>"
        )
    endif()
endfunction()

function(ns_link_slang_target TARGET_PROJECT)
    if(NOT TARGET ${TARGET_PROJECT})
        message(FATAL_ERROR "ns_link_slang_target: Target '${TARGET_PROJECT}' does not exist.")
    endif()

    get_property(NS_SLANG_SOURCE_DIR GLOBAL PROPERTY NS_SLANG_SOURCE_DIR)
    if(NOT NS_SLANG_SOURCE_DIR)
        message(WARNING "Slang not initialized; call ns_slang_init() first.")
        return()
    endif()

    # Link against available Slang targets
    if(TARGET slang-gfx)
        target_link_libraries(${TARGET_PROJECT} PUBLIC slang-gfx)
    elseif(TARGET slang)
        target_link_libraries(${TARGET_PROJECT} PUBLIC slang)
    endif()

    # Include dirs in case only interface created
    if(EXISTS "${NS_SLANG_SOURCE_DIR}/source")
        target_include_directories(${TARGET_PROJECT} PUBLIC "${NS_SLANG_SOURCE_DIR}/source")
    endif()
    if(EXISTS "${NS_SLANG_SOURCE_DIR}/include")
        target_include_directories(${TARGET_PROJECT} PUBLIC "${NS_SLANG_SOURCE_DIR}/include")
    endif()

    # Copy runtime DLLs if any (Windows builds) after build.
    if(WIN32)
        file(GLOB SLANG_DLLS
            "${CMAKE_BINARY_DIR}/slang-*/bin/*.dll"
            "${CMAKE_BINARY_DIR}/slang-*/lib/*.dll")
        if(SLANG_DLLS)
            add_custom_command(TARGET ${TARGET_PROJECT} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different ${SLANG_DLLS} $<TARGET_FILE_DIR:${TARGET_PROJECT}>
            )
        endif()
    endif()
endfunction()
