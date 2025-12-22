# luabuilder.cmake - CMake module for building Lua from source

# Function to build Lua library from source
# Usage: build_lua(LUA_SOURCE_DIR [LIB_TYPE] [BUILD_EXECUTABLES])
#   LUA_SOURCE_DIR: Path to Lua source code (required)
#   LIB_TYPE: "STATIC" or "SHARED", defaults to "STATIC" (optional)
#   BUILD_EXECUTABLES: TRUE/FALSE to build lua/luac executables, defaults to FALSE (optional)
function (build_lua LUA_SOURCE_DIR)
  # Parse optional arguments
  set(LIB_TYPE "STATIC") # Default to static library
  set(BUILD_EXECUTABLES FALSE) # Default to not building executables

  # Check for optional arguments
  if (${ARGC} GREATER 1)
    set(LIB_TYPE "${ARGV1}")
  endif ()

  if (${ARGC} GREATER 2)
    set(BUILD_EXECUTABLES "${ARGV2}")
  endif ()

  # Validate library type
  if (NOT "${LIB_TYPE}" STREQUAL "STATIC" AND NOT "${LIB_TYPE}" STREQUAL "SHARED")
    message(FATAL_ERROR "LIB_TYPE must be either 'STATIC' or 'SHARED', got '${LIB_TYPE}'")
  endif ()

  # Validate BUILD_EXECUTABLES
  if (NOT "${BUILD_EXECUTABLES}" STREQUAL "TRUE" AND NOT "${BUILD_EXECUTABLES}" STREQUAL "FALSE")
    message(FATAL_ERROR "BUILD_EXECUTABLES must be either 'TRUE' or 'FALSE', got '${BUILD_EXECUTABLES}'")
  endif ()

  # Validate the source directory exists
  if (NOT EXISTS "${LUA_SOURCE_DIR}")
    message(FATAL_ERROR "Lua source directory '${LUA_SOURCE_DIR}' does not exist")
  endif ()

  message(STATUS "Building Lua from source: ${LUA_SOURCE_DIR}")
  message(STATUS "Library type: ${LIB_TYPE}")
  message(STATUS "Build executables: ${BUILD_EXECUTABLES}")

  # Find Lua source files
  file(GLOB LUA_SOURCES "${LUA_SOURCE_DIR}/*.c" "${LUA_SOURCE_DIR}/*.h*")

  # Check if we're in a standard Lua source structure (with src/ directory)
  if (EXISTS "${LUA_SOURCE_DIR}/src")
    file(GLOB LUA_SOURCES "${LUA_SOURCE_DIR}/src/*.c" "${LUA_SOURCE_DIR}/src/*.h*")
    set(LUA_INCLUDE_DIR "${LUA_SOURCE_DIR}/src")
  else ()
    set(LUA_INCLUDE_DIR "${LUA_SOURCE_DIR}")
  endif ()

  if (NOT LUA_SOURCES)
    message(FATAL_ERROR "No Lua source files found in '${LUA_SOURCE_DIR}'")
  endif ()

  # Count source files for info
  list(LENGTH LUA_SOURCES LUA_SOURCES_COUNT)
  message(STATUS "Found ${LUA_SOURCES_COUNT} Lua source files")

  # Filter source files based on whether we're building executables
  set(LIBRARY_SOURCES ${LUA_SOURCES})

  # If we're only building the library (not executables), exclude lua.c and luac.c
  if (NOT BUILD_EXECUTABLES)
    list(FILTER LIBRARY_SOURCES EXCLUDE REGEX ".*lua\\.c$")
    list(FILTER LIBRARY_SOURCES EXCLUDE REGEX ".*luac\\.c$")
    message(STATUS "Excluding lua.c and luac.c from library build")
  endif ()

  # Try to determine Lua version from source
  set(LUA_VERSION_MAJOR "0")
  set(LUA_VERSION_MINOR "0")
  set(LUA_VERSION_PATCH "0")

  if (EXISTS "${LUA_INCLUDE_DIR}/lua.h")
    file(READ "${LUA_INCLUDE_DIR}/lua.h" LUA_H_CONTENTS)
    string(REGEX MATCH "LUA_VERSION_MAJOR[ \t]+\"([0-9]+)\"" _ ${LUA_H_CONTENTS})
    if (CMAKE_MATCH_1)
      set(LUA_VERSION_MAJOR ${CMAKE_MATCH_1})
    endif ()
    string(REGEX MATCH "LUA_VERSION_MINOR[ \t]+\"([0-9]+)\"" _ ${LUA_H_CONTENTS})
    if (CMAKE_MATCH_1)
      set(LUA_VERSION_MINOR ${CMAKE_MATCH_1})
    endif ()
    string(REGEX MATCH "LUA_VERSION_RELEASE[ \t]+\"([0-9]+)\"" _ ${LUA_H_CONTENTS})
    if (CMAKE_MATCH_1)
      set(LUA_VERSION_PATCH ${CMAKE_MATCH_1})
    endif ()
    message(STATUS "Detected Lua version: ${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}.${LUA_VERSION_PATCH}")
  endif ()

  # Create the Lua library target
  add_library(liblua ${LIB_TYPE} ${LIBRARY_SOURCES})
  set_target_properties(liblua PROPERTIES OUTPUT_NAME "liblua")

  # Set include directories
  target_include_directories(liblua PUBLIC ${LUA_INCLUDE_DIR})

  # Platform-specific settings
  if (WIN32)
    # Windows specific settings
    if ("${LIB_TYPE}" STREQUAL "SHARED")
      target_compile_definitions(liblua PRIVATE LUA_BUILD_AS_DLL)
      target_compile_definitions(liblua PUBLIC LUA_USE_DLL)
    endif ()
  else ()
    # Unix/Linux specific settings
    target_compile_definitions(liblua PRIVATE LUA_USE_LINUX)
    if ("${LIB_TYPE}" STREQUAL "SHARED")
      target_compile_definitions(liblua PUBLIC LUA_USE_DLL)
    endif ()
  endif ()

  # Set properties
  set_target_properties(
    liblua
    PROPERTIES VERSION ${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}.${LUA_VERSION_PATCH}
               SOVERSION ${LUA_VERSION_MAJOR}
               OUTPUT_NAME "liblua")

  # For shared libraries on Unix-like systems, set the appropriate suffix
  if ("${LIB_TYPE}" STREQUAL "SHARED"
      AND UNIX
      AND NOT APPLE)
    set_target_properties(lua PROPERTIES PREFIX "lib" SUFFIX ".so.${LUA_VERSION_MAJOR}.${LUA_VERSION_MINOR}")
  endif ()

  # Build executables if requested
  if (BUILD_EXECUTABLES)
    message(STATUS "Building Lua executables")

    # Find lua.c
    set(LUA_C_PATH "")
    if (EXISTS "${LUA_SOURCE_DIR}/lua.c")
      set(LUA_C_PATH "${LUA_SOURCE_DIR}/lua.c")
    elseif (EXISTS "${LUA_SOURCE_DIR}/src/lua.c")
      set(LUA_C_PATH "${LUA_SOURCE_DIR}/src/lua.c")
    endif ()

    # Build lua interpreter
    if (LUA_C_PATH)
      add_executable(lua ${LUA_C_PATH})
      target_link_libraries(lua liblua)
      set_target_properties(lua PROPERTIES OUTPUT_NAME "lua")
      message(STATUS "Created Lua interpreter executable: lua")
    else ()
      message(WARNING "lua.c not found, skipping Lua interpreter build")
    endif ()

    # Find luac.c
    set(LUAC_C_PATH "")
    if (EXISTS "${LUA_SOURCE_DIR}/luac.c")
      set(LUAC_C_PATH "${LUA_SOURCE_DIR}/luac.c")
    elseif (EXISTS "${LUA_SOURCE_DIR}/src/luac.c")
      set(LUAC_C_PATH "${LUA_SOURCE_DIR}/src/luac.c")
    endif ()

    # Build luac compiler
    if (LUAC_C_PATH)
      add_executable(luac ${LUAC_C_PATH})
      target_link_libraries(luac liblua)
      set_target_properties(luac PROPERTIES OUTPUT_NAME "luac")
      message(STATUS "Created Lua compiler executable: luac")
    else ()
      message(WARNING "luac.c not found, skipping Lua compiler build")
    endif ()
  endif ()

  # Create an alias target for easier linking
  add_library(Lua::Lua ALIAS liblua)

  # Install the Lua library
  install(
    TARGETS liblua
    EXPORT LuaTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  # Install Lua header files
  # Find all header files
  file(GLOB LUA_HEADERS "${LUA_INCLUDE_DIR}/*.h" "${LUA_INCLUDE_DIR}/*.hpp")
  if (LUA_HEADERS)
    # Also create a version-less include directory for easier inclusion
    install(FILES ${LUA_HEADERS} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/lua)
  endif ()

  # Install executables if built
  if (BUILD_EXECUTABLES)
    if (TARGET lua)
      install(TARGETS lua RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
    endif ()

    if (TARGET luac)
      install(TARGETS luac RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
    endif ()
  endif ()

  message(STATUS "Lua library target 'liblua' (${LIB_TYPE}) created successfully with installation support")
endfunction ()
