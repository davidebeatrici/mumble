# Copyright 2019-2020 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

# Overlay payload for Unix-like systems.

add_library(overlay_gl_x64 SHARED "overlay.c")

set_target_properties(overlay_gl_x64 PROPERTIES OUTPUT_NAME "overlay")
set_target_properties(overlay_gl_x64 PROPERTIES VERSION ${CMAKE_PROJECT_VERSION})
set_target_properties(overlay_gl_x64 PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})

if(NOT APPLE)
	add_library(overlay_gl_x86 SHARED "overlay.c")

	target_compile_definitions(overlay_gl_x64 PRIVATE "TARGET_UNIX")
	target_compile_definitions(overlay_gl_x86 PRIVATE "TARGET_UNIX")

	target_compile_options(overlay_gl_x64 PRIVATE "-m64")
	target_compile_options(overlay_gl_x86 PRIVATE "-m32")

	target_link_options(overlay_gl_x64 PRIVATE "-m64")
	target_link_options(overlay_gl_x86 PRIVATE "-m32")

	if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
		# Linking the overlay library with '-z now' requires all target processes to have libGL symbols in them at load time.
		# If it doesn't, the program will not start at all.
		#
		# Instead, explicitly use '-z lazy' to defer libGL symbol resolution until first use, which is never for non-libGL users.
		target_link_options(overlay_gl_x64 PRIVATE "-Wl,-z,lazy")
		target_link_options(overlay_gl_x86 PRIVATE "-Wl,-z,lazy")
	endif()

	set_target_properties(overlay_gl_x64 PROPERTIES OUTPUT_NAME "overlay.x86_64")
	set_target_properties(overlay_gl_x86 PROPERTIES OUTPUT_NAME "overlay.x86")
	set_target_properties(overlay_gl_x86 PROPERTIES VERSION ${CMAKE_PROJECT_VERSION})
	set_target_properties(overlay_gl_x86 PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
else()
	target_compile_definitions(overlay_gl_x64 PRIVATE "TARGET_MAC")
endif()
