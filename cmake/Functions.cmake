# Functions.cmake - Utility functions for CMake projects

# Function to update a cached variable with a new value
# Usage: update_cached(VAR_NAME VALUE)
#   VAR_NAME: Name of the variable to update in cache
#   VALUE: New value to set for the variable
function (update_cached name value)
  # Update the variable in cache with the new value
  set("${name}"
      "${value}"
      CACHE INTERNAL "*** Internal ***" FORCE)
endfunction ()

# Function to append items to a cached list variable and remove duplicates
# Usage: update_cached_list(VAR_NAME ITEM1 ITEM2 ...)
#   VAR_NAME: Name of the list variable to update in cache
#   ITEM1, ITEM2, ...: Items to append to the list
function (update_cached_list name)
  # Get current list value
  set(_tmp_list "${${name}}")

  # Append new items
  list(APPEND _tmp_list "${ARGN}")

  # Remove any duplicate entries
  list(REMOVE_DUPLICATES _tmp_list)

  # Update the cached list variable
  update_cached(${name} "${_tmp_list}")
endfunction ()
