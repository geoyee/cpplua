cmake_minimum_required(VERSION 3.27 FATAL_ERROR)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(LINK_WHAT_YOU_USE ON)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

project(cpplua LANGUAGES C CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

include(GNUInstallDirs)
include(Functions)
include(LuaBuild)
include(SampleBuild)

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
  message(STATUS "Building main project, include all of samples")
else ()
  message(STATUS "Building subproject, just build lua and sol2")
endif ()

build_lua(${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/lua)
set_property(TARGET liblua PROPERTY FOLDER "ExtraTargets")
update_cached_list(DEPEND_LIBS Lua::Lua)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/sol2)
update_cached_list(DEPEND_LIBS sol2::sol2)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/efsw)
set_property(TARGET efsw PROPERTY FOLDER "ExtraTargets")
set_property(TARGET efsw-static PROPERTY FOLDER "ExtraTargets")
update_cached_list(PRI_DEPEND_LIBS efsw-static)

if (${IS_MAIN_PROJECT})
  build_samples(${CMAKE_CURRENT_SOURCE_DIR}/sample)
endif ()
