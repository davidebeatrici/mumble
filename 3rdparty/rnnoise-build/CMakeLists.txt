# Copyright 2005-2019 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

set(RNNOISE_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../rnnoise-src")

if(NOT EXISTS "${RNNOISE_SRC_DIR}/COPYING")
	message(FATAL_ERROR
		"${RNNOISE_SRC_DIR} was not found.\n"
		"Please checkout the submodule:\n"
		"git submodule update --init --recursive"
	)
endif()

add_library(rnnoise STATIC)

target_include_directories(rnnoise PUBLIC SYSTEM "${RNNOISE_SRC_DIR}/include")

if(MSVC)
	# Use malloc() and free() instead of variable length arrays (unsupported)
	target_compile_definitions(rnnoise PRIVATE "USE_MALLOC")
	# Define M_PI
	target_compile_definitions(rnnoise PRIVATE "_USE_MATH_DEFINES")
endif()

target_sources(rnnoise PRIVATE
	"${RNNOISE_SRC_DIR}/src/rnn_data.c"
	"${RNNOISE_SRC_DIR}/src/rnn.c"
	"${RNNOISE_SRC_DIR}/src/pitch.c"
	"${RNNOISE_SRC_DIR}/src/kiss_fft.c"
	"${RNNOISE_SRC_DIR}/src/denoise.c"
	"${RNNOISE_SRC_DIR}/src/celt_lpc.c"
)
