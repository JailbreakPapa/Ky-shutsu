ns_cmake_init()

# Get the name of this folder as the project name
set(PROJECT_NAME "wdvideopublic")

ns_create_target(SHARED_LIBRARY ${PROJECT_NAME} NO_NS_PREFIX NO_UNITY NO_WARNINGS_AS_ERRORS)

set_property(TARGET ${TARGET_NAME} PROPERTY CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

    configure_file(
    resource.h
    wdvideopublic.rc
    )

ns_setup_dependancys_apui(${PROJECT_NAME})

if(MSVC)
  target_compile_options(${PROJECT_NAME} PRIVATE /W4 /-WX /GR)
endif()



target_link_libraries(${PROJECT_NAME}
  PUBLIC
  Foundation
  libvpx
  libtheora
  libsimplewebm
)

add_dependencies(${PROJECT_NAME}
  libvpx
  libtheora
  libsimplewebm
)


ns_setup_iwyu()

ns_integrate_vcpkg(${PROJECT_NAME} libvorbis OFF)
ns_integrate_vcpkg(${PROJECT_NAME} libogg OFF)
ns_integrate_vcpkg(${PROJECT_NAME} opus OFF)

# Start configuring our "Heavy 3rdParty" dependencies here, so we can use them in the rest of the targets.
ns_setup_heavylibs()


