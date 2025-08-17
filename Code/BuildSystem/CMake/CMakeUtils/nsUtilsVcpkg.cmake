# #####################################
# ## ns_vcpkg_show_info()
# #####################################

function(ns_vcpkg_show_info)
    message("This project can use vcpkg to find its 3rd party dependencies.")
    message("You can install vcpkg either manually or using InstallVcpkg.bat.")
    message("Make sure to set the environment variable 'VCPKG_ROOT' to point to your installation of vcpkg.")
    message("")
endfunction()


# #####################################
# ## ns_vcpkg_init()
# #####################################
function(ns_vcpkg_init)
    message(STATUS "EnvVar %VCPKG_ROOT% is set to '$ENV{VCPKG_ROOT}'")

    if(CMAKE_TOOLCHAIN_FILE)
        message(STATUS "CMAKE_TOOLCHAIN_FILE is already set to '${CMAKE_TOOLCHAIN_FILE}' - not going to modify it.")
        get_filename_component(NS_VCPKG_ROOT "${CMAKE_TOOLCHAIN_FILE}" DIRECTORY)
        get_filename_component(NS_VCPKG_ROOT "${NS_VCPKG_ROOT}" DIRECTORY)
        get_filename_component(NS_VCPKG_ROOT "${NS_VCPKG_ROOT}" DIRECTORY)

    else()
        if(DEFINED ENV{VCPKG_ROOT})
            set(NS_VCPKG_ROOT "$ENV{VCPKG_ROOT}")
            message(STATUS "EnvVar VCPKG_ROOT is specified, using that.")
        else()
            set(NS_VCPKG_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/vcpkg")
            message(STATUS "EnvVar VCPKG_ROOT is not specified, using '${CMAKE_CURRENT_SOURCE_DIR}/vcpkg'.")
        endif()

        if(NOT EXISTS "${NS_VCPKG_ROOT}/vcpkg.exe" OR NOT EXISTS "${NS_VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
            message("vcpkg is not installed. Either install it manually and set the environment variable VCPKG_ROOT to its directory, or run InstallVcpkg.bat")
            return()
        endif()

        set(CMAKE_TOOLCHAIN_FILE "${NS_VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "" FORCE)
        message(STATUS "Forcing CMAKE_TOOLCHAIN_FILE to point to '${CMAKE_TOOLCHAIN_FILE}'")
    endif()

    message(STATUS "NS_VCPKG_ROOT is '${NS_VCPKG_ROOT}'")
    set_property(GLOBAL PROPERTY "NS_VCPKG_ROOT" ${NS_VCPKG_ROOT})
endfunction()




# #####################################
# ## ns_vcpkg_install(<packages>)
# #####################################
function(ns_vcpkg_install PACKAGES DYNAMIC)
    ns_cmake_init()

    get_property(NS_VCPKG_ROOT GLOBAL PROPERTY "NS_VCPKG_ROOT")

    if(NS_CMAKE_PLATFORM_WINDOWS)
        if(NS_CMAKE_ARCHITECTURE_64BIT)
            set(VCPKG_TARGET_TRIPLET "x64-windows")
        else()
            set(VCPKG_TARGET_TRIPLET "x86-windows")
        endif()
    elseif(NS_CMAKE_PLATFORM_LINUX)
        if(NS_CMAKE_ARCHITECTURE_64BIT)
            set(VCPKG_TARGET_TRIPLET "x64-linux")
        else()
            set(VCPKG_TARGET_TRIPLET "x86-linux")
        endif()
    else()
        message(FATAL_ERROR "vcpkg target triplet is not configured for this platform")
    endif()

    foreach(PACKAGE ${PACKAGES})
        if(DYNAMIC)
            message("VCPKG: Installing '${PACKAGE}', this may take a while. ${PACKAGE}:${VCPKG_TARGET_TRIPLET}-dynamic")
            execute_process(COMMAND "${NS_VCPKG_ROOT}/vcpkg.exe" install "${PACKAGE}:${VCPKG_TARGET_TRIPLET}" WORKING_DIRECTORY "${NS_VCPKG_ROOT}")
        else()
            message("VCPKG: Installing '${PACKAGE}', this may take a while. ${PACKAGE}:${VCPKG_TARGET_TRIPLET}")
            execute_process(COMMAND "${NS_VCPKG_ROOT}/vcpkg.exe" install "${PACKAGE}:${VCPKG_TARGET_TRIPLET}" WORKING_DIRECTORY "${NS_VCPKG_ROOT}")
        endif()
    endforeach()
endfunction()

# Function to integrate vcpkg manually for a specific library and its dependencies
function(ns_integrate_vcpkg target_name library_name include_only)
    if(NOT DEFINED ENV{VCPKG_ROOT})
        message(FATAL_ERROR "VCPKG_ROOT environment variable is not defined.")
    endif()
    set(VCPKG_ROOT $ENV{VCPKG_ROOT})

    # Automatically determine the platform and architecture
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(PLATFORM "windows")
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(ARCH "x64")
        else()
            set(ARCH "x86")
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        set(PLATFORM "linux")
        if(CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(ARCH "x64")
        else()
            set(ARCH "x86")
        endif()
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
        set(PLATFORM "osx")
        set(ARCH "x64") # macOS primarily supports x64; adjust as needed for Apple Silicon
    else()
        message(FATAL_ERROR "Unsupported platform: ${CMAKE_SYSTEM_NAME}")
    endif()

    # Set the triplet dynamically
    set(VCPKG_TRIPLET "${ARCH}-${PLATFORM}")

    # Paths to vcpkg directories
    set(VCPKG_PACKAGES_PATH "${VCPKG_ROOT}/packages")
    if(NOT EXISTS ${VCPKG_PACKAGES_PATH})
        message(FATAL_ERROR "Packages directory not found: ${VCPKG_PACKAGES_PATH}")
    endif()

    # Parse dependencies, considering platform constraints
    function(parse_dependencies library_name dependencies)
        set(PORT_PATH "${VCPKG_ROOT}/ports/${library_name}/vcpkg.json")
        if(NOT EXISTS ${PORT_PATH})
            message(FATAL_ERROR "vcpkg.json not found for library: ${library_name}")
        endif()

        file(READ ${PORT_PATH} JSON_CONTENT)

        # Parse dependencies array
        string(JSON DEP_LIST GET ${JSON_CONTENT} dependencies)
        if(DEP_LIST MATCHES "^\[.*\]$")
            string(JSON DEP_COUNT LENGTH ${DEP_LIST})
            foreach(DEP_INDEX RANGE 0 ${DEP_COUNT} EQUAL OFF BY 1)
                string(JSON DEP_NAME GET ${DEP_LIST} ${DEP_INDEX} name)
                string(JSON DEP_PLATFORM GET ${DEP_LIST} ${DEP_INDEX} platform)

                # Check platform constraints
                if(DEP_PLATFORM)
                    if(NOT ${PLATFORM} MATCHES ${DEP_PLATFORM})
                        continue() # Skip if platform does not match
                    endif()
                endif()

                list(APPEND ${dependencies} ${DEP_NAME})
            endforeach()
        else()
            message(WARNING "No dependencies found in ${PORT_PATH}.")
        endif()
    endfunction()

    set(ALL_DEPENDENCIES ${library_name})
    list(APPEND PROCESSED_LIBRARIES)

    # Resolve dependencies recursively, handling platform constraints
    function(resolve_all_dependencies library_name)
        if(NOT library_name IN_LIST PROCESSED_LIBRARIES)
            list(APPEND PROCESSED_LIBRARIES ${library_name})
            set(NEW_DEPENDENCIES)
            parse_dependencies(${library_name} NEW_DEPENDENCIES)
            foreach(DEP IN LISTS NEW_DEPENDENCIES)
                list(APPEND ALL_DEPENDENCIES ${DEP})
                resolve_all_dependencies(${DEP})
            endforeach()
        endif()
    endfunction()

    resolve_all_dependencies(${library_name})

    # Search for libraries, binaries, and include paths for all dependencies
    set(VCPKG_LIBS)
    set(VCPKG_DLLS)
    set(VCPKG_INCLUDES)

    foreach(DEP IN LISTS ALL_DEPENDENCIES)
        set(DEP_PACKAGE_PATH "${VCPKG_PACKAGES_PATH}/${DEP}_${VCPKG_TRIPLET}")
        if(NOT EXISTS ${DEP_PACKAGE_PATH})
            message(FATAL_ERROR "Package not found: ${DEP_PACKAGE_PATH}")
        endif()

        file(GLOB_RECURSE DEP_LIBS "${DEP_PACKAGE_PATH}/lib/*.lib")
        file(GLOB_RECURSE DEP_DLLS "${DEP_PACKAGE_PATH}/bin/*.dll")
        file(GLOB_RECURSE DEP_INCLUDES "${DEP_PACKAGE_PATH}/include/*")

        list(APPEND VCPKG_LIBS ${DEP_LIBS})
        list(APPEND VCPKG_DLLS ${DEP_DLLS})
        list(APPEND VCPKG_INCLUDES ${DEP_INCLUDES})
        list(APPEND VCPKG_INCLUDES "${DEP_PACKAGE_PATH}/include")
        
    endforeach()

    # Add include directories
    include_directories(${VCPKG_INCLUDES})

    # Link libraries to target
    if(VCPKG_LIBS)
        target_link_libraries(${target_name} PRIVATE ${VCPKG_LIBS})
    elseif(include_only)
        message(STATUS "Good to go, we are configured as a include-only target.")
    else()
        message(FATAL_ERROR "No libraries found for ${library_name} or its dependencies in packages directory.")
    endif()

    foreach(DLL ${VCPKG_DLLS})
        add_custom_command(
            TARGET ${target_name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${DLL}" "$<TARGET_FILE_DIR:${target_name}>"
        )
    endforeach()

    set_property(GLOBAL PROPERTY EXPORT_COMPILE_COMMANDS ON)
    message(STATUS "VCPKG_LIBS for ${library_name} and dependencies: ${VCPKG_LIBS}")
    message(STATUS "VCPKG_DLLS for ${library_name} and dependencies: ${VCPKG_DLLS}")
endfunction()
