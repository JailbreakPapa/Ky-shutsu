# Copyright (c) WD Studios Corp. All Rights Reserved.
#
# This file provides utilities for integrating local third-party libraries into O3DE's build system.
# The `chaos_add_local_library` function associates a local library folder or a Git repository with the project,
# making it available under the `3rdParty::` namespace, and optionally linking it to specified targets.

include(FetchContent)

# Function to add a local target from a directory or Git repository
#
# Usage:
#   chaos_add_local_target(
#       NAME <library_name>
#       [PATH <local_path>]
#       [GIT_REPO <git_repository_url>]
#       [GIT_TAG <git_tag_or_branch>]
#       [TARGET_NAME <actual_target_name>]           # For single target (backward compatibility)
#       [TARGET_NAMES <target1> <target2> ...]       # For multiple targets
#       [ALIAS_NAMES <alias1> <alias2> ...]          # Corresponding aliases for multiple targets
#       [SOURCE_SUBDIR <subdirectory>]
#       [INCLUDE_VAR <variable_name>]
#   )
#
# Arguments:
#   NAME          - The name for the library alias (e.g., JoltPhysics) - Required
#   PATH          - Optional local path to the library source
#   GIT_REPO      - Optional Git repository URL to clone
#   GIT_TAG       - Optional Git tag or branch to checkout
#   TARGET_NAME   - The actual target name defined by the library (single target case)
#   TARGET_NAMES  - List of actual target names defined by the library (multiple targets case)
#   ALIAS_NAMES   - List of alias names for the targets (required if TARGET_NAMES is used)
#   SOURCE_SUBDIR - Optional subdirectory within the source to add (default: root)
#   INCLUDE_VAR   - Optional variable to set with the source directory in the parent scope
#
# Behavior:
#   - Clones the Git repository or uses the local path.
#   - Adds the specified subdirectory (or root) with add_subdirectory.
#   - Creates aliases (e.g., 3rdParty::<NAME> or as specified in ALIAS_NAMES) for the targets.
#   - Allows said targets to be found by find_package.
#
function(chaos_add_local_target)
    set(options)
    set(oneValueArgs NAME PATH GIT_REPO GIT_TAG SOURCE_SUBDIR)
    set(multiValueArgs TARGET_NAMES ALIAS_NAMES)
    cmake_parse_arguments(chaos_add_local_target "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate required arguments
    if(NOT chaos_add_local_target_NAME)
        message(FATAL_ERROR "chaos_add_local_target: NAME argument is required")
    endif()
    set(NAME ${chaos_add_local_target_NAME})

    # Determine the target list
    if(chaos_add_local_target_TARGET_NAMES)
        set(TARGET_LIST ${chaos_add_local_target_TARGET_NAMES})
    else()
        message(FATAL_ERROR "chaos_add_local_target: TARGET_NAMES must be provided")
    endif()

    # Handle source location
    if(chaos_add_local_target_GIT_REPO)
        if(NOT DEFINED CHAOS_3RDPARTY_DIR)
            message(FATAL_ERROR "CHAOS_3RDPARTY_DIR is not defined. Set it (e.g., set(CHAOS_3RDPARTY_DIR \"${CMAKE_SOURCE_DIR}/3rdParty\")).")
        endif()
        set(BASE_PATH "${CHAOS_3RDPARTY_DIR}/${NAME}")

        include(FetchContent)
        set(fetch_args GIT_REPOSITORY ${chaos_add_local_target_GIT_REPO} SOURCE_DIR ${BASE_PATH})
        if(chaos_add_local_target_GIT_TAG)
            list(APPEND fetch_args GIT_TAG ${chaos_add_local_target_GIT_TAG})
        endif()
        if(chaos_add_local_target_SOURCE_SUBDIR)
            list(APPEND fetch_args SOURCE_SUBDIR ${chaos_add_local_target_SOURCE_SUBDIR})
        endif()

        FetchContent_Declare(${NAME} ${fetch_args})
        FetchContent_MakeAvailable(${NAME})

        string(TOLOWER ${NAME} lowercase_name)
        set(source_dir ${${lowercase_name}_SOURCE_DIR})
        if(chaos_add_local_target_SOURCE_SUBDIR)
            set(source_dir "${source_dir}/${chaos_add_local_target_SOURCE_SUBDIR}")
        endif()
    elseif(chaos_add_local_target_PATH)
        set(source_dir ${chaos_add_local_target_PATH})
        if(chaos_add_local_target_SOURCE_SUBDIR)
            set(source_dir "${source_dir}/${chaos_add_local_target_SOURCE_SUBDIR}")
        endif()
        add_subdirectory(${source_dir})
    else()
        message(FATAL_ERROR "chaos_add_local_target: Either PATH or GIT_REPO must be provided")
    endif()

    # Verify all targets exist
    foreach(target IN LISTS TARGET_LIST)
        if(NOT TARGET ${target})
            message(FATAL_ERROR "Target ${target} was not defined after adding subdirectory")
        endif()
    endforeach()

    # Create aliases if ALIAS_NAMES provided or default for single target
    list(LENGTH TARGET_LIST target_count)
    if(chaos_add_local_target_ALIAS_NAMES)
        # Manually calculate the length of the alias list
        list(LENGTH chaos_add_local_target_ALIAS_NAMES alias_count)

        # Compare the two calculated lengths
        if(NOT ${target_count} EQUAL ${alias_count})
            message(FATAL_ERROR "chaos_add_local_target: TARGET_NAMES and ALIAS_NAMES must have the same number of elements. Got ${target_count} targets and ${alias_count} aliases.")
        endif()
        math(EXPR target_count "${target_count} - 1")
        foreach(i RANGE 0 ${target_count})
            list(GET TARGET_LIST ${i} target_name)
            list(GET chaos_add_local_target_ALIAS_NAMES ${i} alias_name)
            if(NOT TARGET ${alias_name})
                add_library(${alias_name} ALIAS ${target_name})
            endif()
        endforeach()
    elseif(target_count EQUAL 1)
        set(DEFAULT_ALIAS "3rdParty::${NAME}")
        if(NOT TARGET ${DEFAULT_ALIAS})
            add_library(${DEFAULT_ALIAS} ALIAS ${TARGET_LIST})
        endif()
    endif()

    # Generate config file
    string(TOUPPER "${NAME}" UPPER_NAME)
    set(config_dir "${CMAKE_BINARY_DIR}/3rdParty/lib/cmake/${NAME}")
    file(MAKE_DIRECTORY "${config_dir}")
    set(config_file "${config_dir}/${NAME}Config.cmake")
    set(targets_file "${config_dir}/${NAME}Targets.cmake")

    # Export targets
    export(TARGETS ${TARGET_LIST} NAMESPACE ${NAME}:: FILE "${targets_file}")

    # Create prefixed target list
    set(prefixed_targets "")
    foreach(target IN LISTS TARGET_LIST)
        list(APPEND prefixed_targets "${NAME}::${target}")
    endforeach()

    # Debug: Confirm config file path
    message(STATUS "Generating config file at: ${config_file}")

    # Write config file
    file(WRITE "${config_file}" "
# ${NAME}Config.cmake - Configuration file for ${NAME}
include(\"\${CMAKE_CURRENT_LIST_DIR}/${NAME}Targets.cmake\")
set(${UPPER_NAME}_FOUND TRUE)
set(${UPPER_NAME}_INCLUDE_DIR \"${source_dir}/include\")
set(${UPPER_NAME}_LIBRARY \"${prefixed_targets}\")
set(${UPPER_NAME}_LIBRARIES \"${prefixed_targets}\")
")

    # Verify file creation
    if(EXISTS "${config_file}")
        message(STATUS "${NAME}Config.cmake created successfully")
    else()
        message(FATAL_ERROR "${NAME}Config.cmake failed to create at ${config_file}")
    endif()

    # Update CMAKE_PREFIX_PATH
    list(APPEND CMAKE_PREFIX_PATH "${CMAKE_BINARY_DIR}/3rdParty")
    list(REMOVE_DUPLICATES CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" PARENT_SCOPE)

    # Set variables in parent scope
    set(${UPPER_NAME}_INCLUDE_DIR "${source_dir}/include" PARENT_SCOPE)
    set(${UPPER_NAME}_LIBRARY "${prefixed_targets}" PARENT_SCOPE)
    set(${UPPER_NAME}_LIBRARIES "${prefixed_targets}" PARENT_SCOPE)
    set(${UPPER_NAME}_FOUND TRUE PARENT_SCOPE)
endfunction()

# Function to associate a local library folder or clone a Git repository and set up the library
#
# Usage:
#   chaos_add_local_library(
#       NAME <library_name>
#       [PATH <library_path>]
#       [GIT_REPO <git_repository_url>]
#       [GIT_TAG <git_tag_or_branch>]
#       [TARGETS <target1> <target2> ...]
#   )
#
# Arguments:
#   NAME     - The name of the library (e.g., MyLibrary) - Required
#   PATH     - Optional path to a local library folder
#   GIT_REPO - Optional URL of the Git repository to clone if the library is not present
#   GIT_TAG  - Optional Git tag, branch, or commit to check out (defaults to the repository's default branch if omitted)
#   TARGETS  - Optional list of targets to link the library to
#
# Behavior:
#   - Clones the Git repository into 3rdParty/<library_name> if GIT_REPO is provided.
#   - Sets up the library as an imported target under 3rdParty::<library_name>.
#   - Searches for include directories named "include" or "inc".
#   - Recursively searches for library files (e.g., .lib, .a, .so).
#   - On Windows, exports DLLs by setting INTERFACE_LY_RUNTIME_DEPENDENCIES.
#   - Links the library to specified TARGETS with PRIVATE linkage, if provided.
#
function(chaos_add_local_library)
    set(options)
    set(oneValueArgs NAME PATH GIT_REPO GIT_TAG)
    set(multiValueArgs TARGETS)
    cmake_parse_arguments(chaos_add_local_library "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Validate required arguments
    if(NOT chaos_add_local_library_NAME)
        message(FATAL_ERROR "chaos_add_local_library: NAME argument is required")
    endif()

    set(NAME ${chaos_add_local_library_NAME})

    # Determine the base path
    if(chaos_add_local_library_GIT_REPO)
        # Ensure CHAOS_3RDPARTY_DIR is defined
        if(NOT DEFINED CHAOS_3RDPARTY_DIR)
            message(FATAL_ERROR "CHAOS_3RDPARTY_DIR is not defined. Please set it in your main CMakeLists.txt (e.g., set(CHAOS_3RDPARTY_DIR \"${CMAKE_SOURCE_DIR}/3rdParty\")).")
        endif()
        set(BASE_PATH "${CHAOS_3RDPARTY_DIR}/${NAME}")

        # Configure FetchContent to clone the repository
        set(fetch_args GIT_REPOSITORY ${chaos_add_local_library_GIT_REPO} SOURCE_DIR ${BASE_PATH})
        if(chaos_add_local_library_GIT_TAG)
            list(APPEND fetch_args GIT_TAG ${chaos_add_local_library_GIT_TAG})
        endif()

        # Declare and populate the Git repository
        FetchContent_Declare(${NAME} ${fetch_args})
        message(STATUS "Ensuring ${NAME} is available from ${chaos_add_local_library_GIT_REPO} in ${BASE_PATH}")
        FetchContent_Populate(${NAME})
    elseif(chaos_add_local_library_PATH)
        set(BASE_PATH "${chaos_add_local_library_PATH}")
    else()
        message(FATAL_ERROR "chaos_add_local_library: Either PATH or GIT_REPO must be provided")
    endif()

    # Set up the library as an imported target if not already defined
    if(NOT TARGET 3rdParty::${NAME})
        # Add the base path to CMAKE_PREFIX_PATH for find_package
        list(APPEND CMAKE_PREFIX_PATH "${BASE_PATH}")
        set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH}" CACHE INTERNAL "")

        # Attempt to find a CMake config file in the library folder
        find_package(${NAME} CONFIG PATHS "${BASE_PATH}" NO_DEFAULT_PATH QUIET)

        if(${NAME}_FOUND)
            # If a config file exists, alias the target to 3rdParty:: namespace
            if(NOT TARGET 3rdParty::${NAME})
                add_library(3rdParty::${NAME} ALIAS ${NAME}::${NAME})
            endif()
        else()
            # No config file; manually configure the library

            # Find include directory: check for "include" or "inc"
            set(INCLUDE_DIR "${BASE_PATH}/include")
            if(NOT EXISTS "${INCLUDE_DIR}")
                set(INCLUDE_DIR "${BASE_PATH}/inc")
            endif()
            if(NOT EXISTS "${INCLUDE_DIR}")
                message(WARNING "Include directory not found for ${NAME} in ${BASE_PATH}/include or ${BASE_PATH}/inc")
            endif()

            # Find library files recursively
            if(WIN32)
                file(GLOB_RECURSE LIB_FILES "${BASE_PATH}/**/*.lib")
                file(GLOB_RECURSE DLL_FILES "${BASE_PATH}/**/*.dll")
            else()
                file(GLOB_RECURSE LIB_FILES "${BASE_PATH}/**/*.a" "${BASE_PATH}/**/*.so")
            endif()

            # Verify that library files were found
            if(NOT LIB_FILES)
                message(FATAL_ERROR "No library files found for ${NAME} in ${BASE_PATH}")
            endif()

            # Create an imported interface target
            add_library(3rdParty::${NAME} INTERFACE IMPORTED GLOBAL)
            if(INCLUDE_DIR)
                target_include_directories(3rdParty::${NAME} INTERFACE "${INCLUDE_DIR}")
            endif()
            target_link_libraries(3rdParty::${NAME} INTERFACE "${LIB_FILES}")

            # On Windows, set runtime dependencies for DLLs
            if(WIN32 AND DLL_FILES)
                set_property(TARGET 3rdParty::${NAME} PROPERTY INTERFACE_LY_RUNTIME_DEPENDENCIES "${DLL_FILES}")
            endif()
        endif()
    endif()

    # Link the library to specified targets
    if(chaos_add_local_library_TARGETS)
        foreach(target IN LISTS chaos_add_local_library_TARGETS)
            if(TARGET ${target})
                target_link_libraries(${target} PRIVATE 3rdParty::${NAME})
            else()
                message(WARNING "Target ${target} does not exist. Cannot link library ${NAME}.")
            endif()
        endforeach()
    endif()
endfunction()
