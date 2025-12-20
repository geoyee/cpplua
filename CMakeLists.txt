cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(LINK_WHAT_YOU_USE ON)

project(cpplua LANGUAGES C CXX)

include(GNUInstallDirs)
include(FetchContent)

if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(
    FATAL_ERROR "Please create a build directory and run CMake from there")
endif()

add_definitions(-D_USE_MATH_DEFINES)

string(COMPARE EQUAL ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR}
               IS_MAIN_PROJECT)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/lua)

add_executable(${PROJECT_NAME} main.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE liblua_static)

if(${IS_MAIN_PROJECT})
  if(MSVC)
    target_compile_options(
      ${PROJECT_NAME}
      INTERFACE /utf-8
                /W4
                /EHsc
                /Zc:__cplusplus
                /Zc:preprocessor
                /Gy
                $<$<CONFIG:Debug>:/Od>
                $<$<CONFIG:Release>:/O2
                /GL>)

    target_link_options(
      ${PROJECT_NAME}
      INTERFACE
      $<$<CONFIG:Release>:
      /LTCG
      /OPT:REF
      /OPT:ICF
      >)
  else()
    target_compile_options(
      ${PROJECT_NAME}
      INTERFACE -fPIC
                -Wall
                -Wextra
                -Wconversion
                -Wsign-compare
                -Werror=uninitialized
                -Werror=return-type
                -Werror=unused-result
                -Werror=suggest-override
                -Wzero-as-null-pointer-constant
                -Wmissing-declarations
                -Wold-style-cast
                -Wnon-virtual-dtor
                $<$<CONFIG:Debug>:-g>
                $<$<CONFIG:Release>:-g2
                -flto>)

    target_link_options(${PROJECT_NAME} INTERFACE $<$<CONFIG:Release>:-flto>)
  endif()
endif()

set_target_properties(${PROJECT_NAME}
                      PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
