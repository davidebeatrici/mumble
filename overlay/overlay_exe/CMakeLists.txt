# Copyright 2019 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

set(OVERLAY_EXE_RC "overlay_exe.rc")

# We save the output name in a variable because it's used by configure_file()
if(64_BIT AND NOT BUILD_OVERLAY_XCOMPILE)
	set(OUTPUT_NAME "mumble_ol_helper_x64")
else()
	set(OUTPUT_NAME "mumble_ol_helper")
endif()

if(NOT BUILD_OVERLAY_XCOMPILE)
	get_target_property(MUMBLE_SOURCE_DIR mumble SOURCE_DIR)
endif()

configure_file(${OVERLAY_EXE_RC} ${CMAKE_CURRENT_BINARY_DIR})

add_executable(overlay_exe WIN32
	"overlay_exe.cpp"
	"overlay_exe.h"

	"${MUMBLE_SOURCE_DIR}/mumble.appcompat.manifest"
	"${CMAKE_CURRENT_BINARY_DIR}/${OVERLAY_EXE_RC}"
)

set_property(TARGET overlay_exe PROPERTY OUTPUT_NAME ${OUTPUT_NAME})

if(BUILD_OVERLAY_XCOMPILE)
	set_property(TARGET overlay_exe PROPERTY RUNTIME_OUTPUT_DIRECTORY ${MUMBLE_BINARY_DIR})

	target_include_directories(overlay_exe PRIVATE ${PARENT_SOURCE_DIR}/overlay)
else()
	set_property(TARGET overlay_exe PROPERTY RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
	
	target_include_directories(overlay_exe PRIVATE ${CMAKE_SOURCE_DIR}/overlay)
endif()

if(MSVC)
	set_property(TARGET overlay_exe PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

add_dependencies(overlay_exe overlay)

target_link_libraries(overlay_exe PRIVATE Shlwapi.lib)
