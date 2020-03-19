# Copyright 2019 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

find_package(PkgConfig QUIET)

include(FindPackageMessage)

function(pkgconfig_search MODULE)
	if(NOT PkgConfig_FOUND)
		return()
	endif()

	# We don't want pkg_search_module() to write into the variables that will be passed to the pkgconfig_search()'s caller.
	set(PRIVATE "PRIVATE_${MODULE}")

	pkg_search_module(${PRIVATE} ${MODULE} QUIET)

	if(NOT ${PRIVATE}_FOUND)
		return()
	endif()

	if(NOT ${PRIVATE}_LINK_LIBRARIES)
		foreach(LIBRARY ${${PRIVATE}_LIBRARIES})
			# A cache entry named by <VAR> is created to store the result of find_library().
			# If the library is found the result is stored in the variable and the search will not be repeated unless the variable is cleared.
			# Using a name that depends on the loop-item is suggested in contrast to clearing the variable.
			# @ref https://cmake.org/pipermail/cmake/2011-November/047171.html
			find_library(${LIBRARY}_LINK ${PRIVATE_LIBRARY} PATHS ${${PRIVATE}_LIBRARY_DIRS})
			list(APPEND ${PRIVATE}_LINK_LIBRARIES ${${LIBRARY}_LINK})
		endforeach()
	endif()

	set(${MODULE}_LIBRARIES ${${PRIVATE}_LINK_LIBRARIES} PARENT_SCOPE)
	set(${MODULE}_VERSION ${${PRIVATE}_VERSION} PARENT_SCOPE)
	set(${MODULE}_FOUND ${${PRIVATE}_FOUND} PARENT_SCOPE)
endfunction()

# This macro's main purpose is to call find_package() with CONFIG and then with MODULE if it fails.
# It also handles multiple package names and searches them with pkg-config if they are not found.
macro(find_pkg ALIASES)
	# We specify "CONFIG", "MODULE" and "NO_MODULE" so that they are not considered unparsed arguments (passed to find_package()).
	cmake_parse_arguments(FIND_PACKAGE "ALIASES;CONFIG;MODULE;NO_DEFAULT_PATH;NO_MODULE;REQUIRED;QUIET" "" "COMPONENTS;PATHS" ${ARGN})

	if(FIND_PACKAGE_COMPONENTS)
		list(APPEND FIND_PACKAGE_ARGUMENTS "COMPONENTS" ${FIND_PACKAGE_COMPONENTS})
		string(REPLACE ";" ", " COMPONENTS_STRING "${FIND_PACKAGE_COMPONENTS}")
	endif()

	if(FIND_PACKAGE_PATHS)
		list(APPEND FIND_PACKAGE_ARGUMENTS "PATHS" ${FIND_PACKAGE_PATHS})
	endif()

	if(FIND_PACKAGE_NO_DEFAULT_PATH)
		list(APPEND FIND_PACKAGE_ARGUMENTS "NO_DEFAULT_PATH")
	endif()

	foreach(ALIAS ${ALIASES})
		set(NAME ${ALIAS})

		find_package(${NAME} ${FIND_PACKAGE_ARGUMENTS} QUIET CONFIG ${FIND_PACKAGE_UNPARSED_ARGUMENTS})
		if(${NAME}_FOUND)
			break()
		endif()

		find_package(${NAME} ${FIND_PACKAGE_ARGUMENTS} QUIET MODULE ${FIND_PACKAGE_UNPARSED_ARGUMENTS})
		if(${NAME}_FOUND)
			break()
		endif()

		pkgconfig_search(${NAME})
		if(${NAME}_FOUND)
			break()
		endif()
	endforeach()

	unset(FIND_PACKAGE_ARGUMENTS)

	if(${NAME}_FOUND)
		if(NOT ${NAME}_VERSION OR NOT ${NAME}_LIBRARIES)
			# The FindOpenSSL module defines the variables with an uppercase prefix.
			string(TOUPPER ${NAME} NAME_UPPER)

			if(NOT ${NAME}_VERSION)
				set(${NAME}_VERSION ${${NAME_UPPER}_VERSION})
			endif()

			if(NOT ${NAME}_LIBRARIES)
				set(${NAME}_LIBRARIES ${${NAME_UPPER}_LIBRARIES})
			endif()

			unset(NAME_UPPER)
		endif()

		if(FIND_PACKAGE_COMPONENTS)
			set(${NAME}_COMPONENTS ${FIND_PACKAGE_COMPONENTS})
		endif()

		if(NOT FIND_PACKAGE_QUIET)
			if(COMPONENTS_STRING)
				set(MESSAGE "Found ${NAME} component(s): ${COMPONENTS_STRING}")
			else()
				set(MESSAGE "Found ${NAME}")
			endif()

			if(${NAME}_VERSION)
				set(MESSAGE "${MESSAGE} | Version: ${${NAME}_VERSION}")
			endif()

			find_package_message(${NAME} ${MESSAGE} "[${NAME}][${${NAME}_COMPONENTS}][${${NAME}_VERSION}]")

			unset(MESSAGE)
		endif()
	elseif(FIND_PACKAGE_REQUIRED)
		if(COMPONENTS_STRING)
			message(FATAL_ERROR "Missing ${NAME} component(s): ${COMPONENTS_STRING}")
		else()
			message(FATAL_ERROR "${NAME} not found!")
		endif()
	elseif(NOT FIND_PACKAGE_QUIET)
		if(COMPONENTS_STRING)
			message(STATUS "Missing ${NAME} component(s): ${COMPONENTS_STRING}")
		else()
			message(STATUS "${NAME} not found!")
		endif()
	endif()

	unset(COMPONENTS_STRING)
	unset(NAME)
endmacro()
