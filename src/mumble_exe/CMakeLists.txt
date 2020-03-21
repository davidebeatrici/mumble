# Copyright 2019 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

add_executable(mumble_exe WIN32)

target_include_directories(mumble_exe PRIVATE "${SHARED_SOURCE_DIR}")

configure_file("${SHARED_SOURCE_DIR}/mumble/${MUMBLE_RC}" ${CMAKE_CURRENT_BINARY_DIR})

target_sources(mumble_exe PRIVATE
	"mumble_exe.cpp"
	"Overlay.cpp"

	"${SHARED_SOURCE_DIR}/mumble/mumble.appcompat.manifest"
	"${CMAKE_CURRENT_BINARY_DIR}/${MUMBLE_RC}"
)

set_property(TARGET mumble_exe PROPERTY OUTPUT_NAME "mumble")
set_property(TARGET mumble_exe PROPERTY RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

if(MSVC)
	set_property(TARGET mumble_exe PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

find_library(LIB_SHLWAPI "shlwapi")

add_dependencies(mumble_exe 
	mumble 
	overlay_exe
)

target_link_libraries(mumble_exe PRIVATE ${LIB_SHLWAPI})
