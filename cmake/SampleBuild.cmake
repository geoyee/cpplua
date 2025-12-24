# SampleBuild.cmake - CMake module for building sample executables with Lua support

# Function to upgrade target properties
# Usage: target_upgrade(TARGET)
#   TARGET: Target to upgrade (required)
function (target_upgrade TARGET)
  # Link libraries
  target_link_libraries(${TARGET} PRIVATE ${DEPEND_LIBS})

  # Add SOL_ALL_SAFETIES_ON flag
  target_compile_definitions(${TARGET} PRIVATE SOL_ALL_SAFETIES_ON=1)

  # Set compile options based on platform
  if (MSVC)
    target_compile_options(
      ${TARGET}
      PRIVATE /utf-8
              /W4
              /EHsc
              /Zc:__cplusplus
              /Zc:preprocessor
              /Gy
              $<$<CONFIG:Debug>:/Od>
              $<$<CONFIG:Release>:/O2
              /GL>)

    target_link_options(${TARGET} PRIVATE $<$<CONFIG:Release>:/LTCG /OPT:REF /OPT:ICF>)
  else ()
    target_compile_options(
      ${TARGET}
      PRIVATE -fPIC
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

    target_link_options(${TARGET} PRIVATE $<$<CONFIG:Release>:-flto>)
  endif ()

  # Enable interprocedural optimization for release builds
  set_target_properties(${TARGET} PROPERTIES INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
endfunction ()

# Function to build sample executables from sample directory
# Usage: build_samples(SAMPLE_DIR)
#   SAMPLE_DIR: Path to samples directory (required)
function (build_samples SAMPLE_DIR)
  # Validate the sample directory exists
  if (NOT EXISTS "${SAMPLE_DIR}")
    message(FATAL_ERROR "Sample directory '${SAMPLE_DIR}' does not exist")
  endif ()

  message(STATUS "Building samples from: ${SAMPLE_DIR}")

  # Get all subdirectories in the sample directory
  file(
    GLOB SAMPLE_SUBDIRS
    RELATIVE "${SAMPLE_DIR}"
    "${SAMPLE_DIR}/*")

  # Filter to only directories
  set(SAMPLE_DIRECTORIES "")
  foreach (SUBDIR ${SAMPLE_SUBDIRS})
    if (IS_DIRECTORY "${SAMPLE_DIR}/${SUBDIR}")
      list(APPEND SAMPLE_DIRECTORIES "${SUBDIR}")
    endif ()
  endforeach ()

  if (NOT SAMPLE_DIRECTORIES)
    message(WARNING "No sample subdirectories found in '${SAMPLE_DIR}'")
    return()
  endif ()

  list(LENGTH SAMPLE_DIRECTORIES SAMPLE_DIRECTORIES_COUNT)
  message(STATUS "Found ${SAMPLE_DIRECTORIES_COUNT} sample directories")

  # Build each sample
  foreach (SAMPLE_NAME ${SAMPLE_DIRECTORIES})
    # Define sample source directory
    set(SAMPLE_SOURCE_DIR "${SAMPLE_DIR}/${SAMPLE_NAME}")

    # Check if main.cpp exists
    if (NOT EXISTS "${SAMPLE_SOURCE_DIR}/main.cpp")
      message(WARNING "Sample '${SAMPLE_NAME}' does not have main.cpp, skipping")
      continue()
    endif ()

    message(STATUS "Building sample: ${SAMPLE_NAME}")

    # Create executable
    add_executable(${SAMPLE_NAME} "${SAMPLE_SOURCE_DIR}/main.cpp")
    target_upgrade(${SAMPLE_NAME})

    set(HAS_LIBRARY FALSE)
    # Build and link library (optional)
    if (EXISTS "${SAMPLE_SOURCE_DIR}/lib.cpp")
      set(HAS_LIBRARY TRUE)

      # Create library
      add_library("lib${SAMPLE_NAME}" SHARED "${SAMPLE_SOURCE_DIR}/lib.cpp" "${SAMPLE_SOURCE_DIR}/lib.h")
      target_upgrade("lib${SAMPLE_NAME}")

      # Set library output name and include directory
      if (WIN32)
        set_target_properties("lib${SAMPLE_NAME}" PROPERTIES PREFIX "" OUTPUT_NAME "lib${SAMPLE_NAME}")
      else ()
        set_target_properties("lib${SAMPLE_NAME}" PROPERTIES PREFIX "lib" OUTPUT_NAME "${SAMPLE_NAME}")
      endif ()
      target_include_directories("lib${SAMPLE_NAME}" PUBLIC "${SAMPLE_SOURCE_DIR}")
      message(STATUS "  Linked library: lib${SAMPLE_NAME}")

      # Link library
      target_link_libraries(${SAMPLE_NAME} PRIVATE "lib${SAMPLE_NAME}")
    endif ()

    # For multi-config generators (like Visual Studio), set output directory per config
    if (CMAKE_CONFIGURATION_TYPES)
      # Multi-config generator (Visual Studio, Xcode)
      foreach (CONFIG ${CMAKE_CONFIGURATION_TYPES})
        string(TOUPPER ${CONFIG} CONFIG_UPPER)
        set_target_properties(${SAMPLE_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${CONFIG_UPPER}
                                                        "${CMAKE_BINARY_DIR}/samples/${SAMPLE_NAME}/${CONFIG}")
      endforeach ()
    else ()
      # Single-config generator (Makefile, Ninja)
      if (CMAKE_BUILD_TYPE)
        string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE_UPPER)
        set_target_properties(
          ${SAMPLE_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${BUILD_TYPE_UPPER}
                                    "${CMAKE_BINARY_DIR}/samples/${SAMPLE_NAME}/${CMAKE_BUILD_TYPE}")
      else ()
        set_target_properties(${SAMPLE_NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY
                                                        "${CMAKE_BINARY_DIR}/samples/${SAMPLE_NAME}")
      endif ()
    endif ()

    # Find Lua files
    file(GLOB LUA_FILES "${SAMPLE_SOURCE_DIR}/*.lua")
    if (LUA_FILES)
      list(LENGTH LUA_FILES LUA_FILES_COUNT)
      message(STATUS "  Found ${LUA_FILES_COUNT} Lua files")

      # Create a generic copy command that uses a generator expression to obtain the target directory
      add_custom_command(
        TARGET ${SAMPLE_NAME}
        POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:${SAMPLE_NAME}>"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different ${LUA_FILES} "$<TARGET_FILE_DIR:${SAMPLE_NAME}>/"
        COMMENT "Copying Lua files for sample ${SAMPLE_NAME}")

      # Install Lua files along with the executable
      # For installation, all files go to the same directory
      install(FILES ${LUA_FILES} DESTINATION "${CMAKE_INSTALL_BINDIR}/${SAMPLE_NAME}")
    endif ()

    # Install the executable
    install(TARGETS ${SAMPLE_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}/${SAMPLE_NAME}")

    # Install the library (optional)
    if (HAS_LIBRARY)
      install(TARGETS "lib${SAMPLE_NAME}" LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}/${SAMPLE_NAME}")
    endif ()

    message(STATUS "  Sample '${SAMPLE_NAME}' configured")
  endforeach ()

  message(STATUS "All samples configured successfully")
endfunction ()
