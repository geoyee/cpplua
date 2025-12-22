cmake_minimum_required(VERSION 3.26 FATAL_ERROR)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(LINK_WHAT_YOU_USE ON)

project(cpplua LANGUAGES C CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

include(GNUInstallDirs)
include(LuaBuilder)

if (PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR "Please create a build directory and run CMake from there")
endif ()

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (WIN32)
    set(CMAKE_INSTALL_PREFIX
        "${CMAKE_CURRENT_SOURCE_DIR}/install"
        CACHE PATH "Install path prefix" FORCE)
    string(REPLACE "\\" "/" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
  else ()
    set(CMAKE_INSTALL_PREFIX
        "/usr/local"
        CACHE PATH "Install path prefix" FORCE)
  endif ()
endif ()
message(STATUS "CMAKE_INSTALL_PREFIX: ${CMAKE_INSTALL_PREFIX}")

add_definitions(-D_USE_MATH_DEFINES)

string(COMPARE EQUAL ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR} IS_MAIN_PROJECT)
if (${IS_MAIN_PROJECT})
  message(STATUS "Building main project")
else ()
  message(STATUS "Building subproject")
endif ()

build_lua(${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/lua)
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/sol2)

if (${IS_MAIN_PROJECT})
  add_executable(${PROJECT_NAME} main.cpp)
  target_link_libraries(${PROJECT_NAME} PRIVATE Lua::Lua sol2::sol2)
  target_compile_definitions(${PROJECT_NAME} PRIVATE "__CMAKE_CURRENT_SOURCE_DIR=\"$<1:${CMAKE_CURRENT_SOURCE_DIR}>\"")

  if (MSVC)
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
  else ()
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
  endif ()
endif ()

set_target_properties(${PROJECT_NAME} PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

install(TARGETS ${PROJECT_NAME} DESTINATION bin)
