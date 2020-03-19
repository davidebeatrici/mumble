# Copyright 2019 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

set(GRPC_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Mumble.proto")

option(client "Build the client (Mumble)" ON)
option(server "Build the server (Murmur)" ON)

option(qssldiffiehellmanparameters "Build support for custom Diffie-Hellman parameters." ON)

option(bonjour "Build support for Bonjour." ON)

option(dbus "Build support for DBus." ON)

find_pkg(Qt5 COMPONENTS Core Network Xml REQUIRED)
find_pkg(OpenSSL COMPONENTS Crypto SSL REQUIRED)
find_pkg(Protobuf REQUIRED)

add_library(shared STATIC)

protobuf_generate(LANGUAGE cpp TARGET shared PROTOS ${GRPC_FILE} OUT_VAR BUILT_GRPC_FILES)

set_target_properties(shared PROPERTIES AUTOMOC ON)

# We explicitly tell CMake not to call any autogen tools (e.g. MOC) for the generated files.
# @ref https://cmake.org/cmake/help/latest/policy/CMP0071.html
set_property(SOURCE ${BUILT_GRPC_FILES} PROPERTY SKIP_AUTOGEN ON)

set(SHARED_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(SHARED_SOURCES
	"Ban.cpp"
	"CryptographicHash.cpp"
	"CryptographicRandom.cpp"
	"CryptState.cpp"
	"EnvUtils.cpp"
	"FFDHE.cpp"
	"HostAddress.cpp"
	"HTMLFilter.cpp"
	"License.cpp"
	"LogEmitter.cpp"
	"OSInfo.cpp"
	"PasswordGenerator.cpp"
	"PlatformCheck.cpp"
	"SelfSignedCertificate.cpp"
	"ServerAddress.cpp"
	"ServerResolver.cpp"
	"ServerResolverRecord.cpp"
	"SSL.cpp"
	"SSLCipherInfo.cpp"
	"SSLLocks.cpp"
	"Timer.cpp"
	"UnresolvedServerAddress.cpp"
	"User.cpp"
	"Version.cpp"

	"${3RDPARTY_DIR}/arc4random-src/arc4random_uniform.cpp"
)

set(SHARED_HEADERS
	# We have to specify the absolute path because otherwise targets linking to the library fail to find the headers.
	# @ref https://cmake.org/cmake/help/latest/policy/CMP0076.html
	# @ref https://gitlab.kitware.com/cmake/cmake/issues/17556
	"${SHARED_SOURCE_DIR}/Ban.h"
	"${SHARED_SOURCE_DIR}/ByteSwap.h"
	"${SHARED_SOURCE_DIR}/CryptographicHash.h"
	"${SHARED_SOURCE_DIR}/CryptographicRandom.h"
	"${SHARED_SOURCE_DIR}/CryptState.h"
	"${SHARED_SOURCE_DIR}/EnvUtils.h"
	"${SHARED_SOURCE_DIR}/FFDHE.h"
	"${SHARED_SOURCE_DIR}/FFDHETable.h"
	"${SHARED_SOURCE_DIR}/HostAddress.h"
	"${SHARED_SOURCE_DIR}/HTMLFilter.h"
	"${SHARED_SOURCE_DIR}/License.h"
	"${SHARED_SOURCE_DIR}/licenses.h"
	"${SHARED_SOURCE_DIR}/LogEmitter.h"
	"${SHARED_SOURCE_DIR}/Net.h"
	"${SHARED_SOURCE_DIR}/OSInfo.h"
	"${SHARED_SOURCE_DIR}/PasswordGenerator.h"
	"${SHARED_SOURCE_DIR}/PlatformCheck.h"
	"${SHARED_SOURCE_DIR}/SelfSignedCertificate.h"
	"${SHARED_SOURCE_DIR}/ServerAddress.h"
	"${SHARED_SOURCE_DIR}/ServerResolver.h"
	"${SHARED_SOURCE_DIR}/ServerResolverRecord.h"
	"${SHARED_SOURCE_DIR}/SSL.h"
	"${SHARED_SOURCE_DIR}/SSLCipherInfo.h"
	"${SHARED_SOURCE_DIR}/SSLCipherInfoTable.h"
	"${SHARED_SOURCE_DIR}/SSLLocks.h"
	"${SHARED_SOURCE_DIR}/Timer.h"
	"${SHARED_SOURCE_DIR}/UnresolvedServerAddress.h"
	"${SHARED_SOURCE_DIR}/User.h"
	"${SHARED_SOURCE_DIR}/Version.h"

	"${3RDPARTY_DIR}/arc4random-src/arc4random_uniform.h"
)

target_sources(shared PRIVATE ${SHARED_SOURCES})
target_sources(shared PUBLIC ${SHARED_HEADERS})

target_compile_definitions(shared PUBLIC "MUMBLE_VERSION=${PROJECT_VERSION}" "MUMBLE_VERSION_STRING=${version}")

target_include_directories(shared PUBLIC
	${CMAKE_CURRENT_SOURCE_DIR}
	${CMAKE_CURRENT_BINARY_DIR}
)

target_include_directories(shared PRIVATE "${3RDPARTY_DIR}/arc4random-src")

target_link_libraries(shared PUBLIC protobuf::libprotobuf OpenSSL::Crypto OpenSSL::SSL Qt5::Core Qt5::Network Qt5::Xml)

if(WIN32)
	find_library(LIB_QWAVE "qwave")
	target_link_libraries(shared PUBLIC ${LIB_QWAVE})
elseif(APPLE)
	find_library(CORE_SERVICES_LIBRARY "CoreServices")
	target_link_libraries(shared PUBLIC ${CORE_SERVICES_LIBRARY})
endif()

if(qssldiffiehellmanparameters)
	target_compile_definitions(shared PUBLIC "USE_QSSLDIFFIEHELLMANPARAMETERS")
endif()

if(client)
	add_subdirectory(mumble)
endif()

if(server)
	add_subdirectory(murmur)
endif()

if(BUILD_TESTING)
	add_subdirectory(tests)
endif()
