ns_cmake_init()

# Get the name of this folder as the project name
get_filename_component(PROJECT_NAME ${CMAKE_CURRENT_SOURCE_DIR} NAME_WE)

ns_create_target(SHARED_LIBRARY ${PROJECT_NAME} NO_NS_PREFIX NO_UNITY NO_WARNINGS_AS_ERRORS)

set_property(TARGET ${TARGET_NAME} PROPERTY CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

configure_file(
  resource.h
  ${PROJECT_NAME}.rc
)

ns_setup_dependancys_apui(${PROJECT_NAME})

if(MSVC)
  target_compile_options(${PROJECT_NAME} PRIVATE /W4 /-WX /GR)
endif()

target_link_libraries(${PROJECT_NAME}
  PUBLIC
  Foundation
  KyKernel
)

ns_setup_iwyu()




