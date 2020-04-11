# Copyright 2019 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

set(CMAKE_INCLUDE_CURRENT_DIR ON)

if(NOT WIN32 AND NOT (${CMAKE_SYSTEM_NAME} STREQUAL "Linux"))
	add_subdirectory(link)

	# Shared library on UNIX (e.g. ".so")
	set_target_properties(${ITEM} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/plugins")

	return()
endif()

if(WIN32)
	find_library(LIB_USER32 "user32")
endif()

file(GLOB ITEMS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "${CMAKE_CURRENT_SOURCE_DIR}/*")

foreach(ITEM ${ITEMS})
	if(IS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/${ITEM}")
		add_subdirectory(${ITEM})

		# Shared library on UNIX (e.g. ".so")
		set_target_properties(${ITEM} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/plugins")
		# Shared library on Windows (e.g. ".dll")
		set_target_properties(${ITEM} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/plugins")

		if(WIN32)
			target_link_libraries(${ITEM} ${LIB_USER32})
		endif()

		install(TARGETS ${ITEM} RUNTIME DESTINATION ./plugins COMPONENT client_bin)
	endif()
endforeach()
