# Copyright 2019 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

set(MURMUR_RC "murmur.rc")

set(GRPC_FILE "${CMAKE_CURRENT_SOURCE_DIR}/MurmurRPC.proto")
set(ICE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/Murmur.ice")

include(qt-utils)

option(grpc "Build support for gRPC." ON)
option(ice "Build support for Ice RPC." ON)

find_pkg(Qt5 COMPONENTS Sql REQUIRED)

set(MURMUR_SOURCES
	"main.cpp"
	"Cert.cpp"
	"Messages.cpp"
	"Meta.cpp"
	"Meta.h"
	"PBKDF2.cpp"
	"PBKDF2.h"
	"Register.cpp"
	"RPC.cpp"
	"Server.cpp"
	"Server.h"
	"ServerDB.cpp"
	"ServerDB.h"
	"ServerUser.cpp"
	"ServerUser.h"

	"${SHARED_SOURCE_DIR}/ACL.cpp"
	"${SHARED_SOURCE_DIR}/ACL.h"
	"${SHARED_SOURCE_DIR}/Channel.cpp"
	"${SHARED_SOURCE_DIR}/Channel.h"
	"${SHARED_SOURCE_DIR}/Connection.cpp"
	"${SHARED_SOURCE_DIR}/Connection.h"
	"${SHARED_SOURCE_DIR}/Group.cpp"
	"${SHARED_SOURCE_DIR}/Group.h"
)

add_executable(murmur ${MURMUR_SOURCES})

set_target_properties(murmur PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR})
set_target_properties(murmur PROPERTIES AUTOMOC ON)

target_compile_definitions(murmur PRIVATE "MURMUR")

target_include_directories(murmur PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR} # This is required for includes in current folder to be found by files from the shared directory.
	${SHARED_SOURCE_DIR}
)

target_link_libraries(murmur PRIVATE shared Qt5::Sql)

if(static)
	# MariaDB and MySQL
	if(TARGET Qt5::QMYSQLDriverPlugin)
		include_qt_plugin(murmur PRIVATE "QMYSQLDriverPlugin")
		target_link_libraries(murmur PRIVATE Qt5::QMYSQLDriverPlugin)
	endif()
	# Open DataBase Connectivity
	if(TARGET Qt5::QODBCDriverPlugin)
		include_qt_plugin(murmur PRIVATE "QODBCDriverPlugin")
		target_link_libraries(murmur PRIVATE Qt5::QODBCDriverPlugin)
		if(WIN32)
			find_library(LIB_ODBC32 "odbc32")
			target_link_libraries(murmur PRIVATE ${LIB_ODBC32})
		endif()
	endif()
	# PostgreSQL
	if(TARGET Qt5::QPSQLDriverPlugin)
		include_qt_plugin(murmur PRIVATE "QPSQLDriverPlugin")
		target_link_libraries(murmur PRIVATE Qt5::QPSQLDriverPlugin)
	endif()
	# SQLite
	if(TARGET Qt5::QSQLiteDriverPlugin)
		include_qt_plugin(murmur PRIVATE "QSQLiteDriverPlugin")
		target_link_libraries(murmur PRIVATE Qt5::QSQLiteDriverPlugin)
	endif()
endif()

if(WIN32)
	configure_file(${MURMUR_RC} ${CMAKE_CURRENT_BINARY_DIR})

	target_sources(murmur PRIVATE
		"About.cpp"
		"About.h"
		"Tray.cpp"
		"Tray.h"
		"murmur.qrc"

		"${SHARED_SOURCE_DIR}/mumble/mumble.appcompat.manifest"
		"${CMAKE_CURRENT_BINARY_DIR}/${MURMUR_RC}"
	)

	find_pkg(Qt5 COMPONENTS Widgets REQUIRED)
	target_link_libraries(murmur 
		PRIVATE 
			Qt5::Widgets
			Dbghelp.lib
			shlwapi.lib
	)

	if(static AND TARGET Qt5::QWindowsIntegrationPlugin)
		include_qt_plugin(murmur PRIVATE QWindowsIntegrationPlugin)
		target_link_libraries(murmur PRIVATE Qt5::QWindowsIntegrationPlugin)
	endif()
else()
	if(${CMAKE_SYSTEM_NAME} STREQUAL "Linux")
		find_library(CAP_LIBRARY NAMES cap)
		target_link_libraries(murmur PRIVATE ${CAP_LIBRARY})
	endif()

	target_sources(murmur PRIVATE "UnixMurmur.cpp" "UnixMurmur.h")
	set_target_properties(murmur PROPERTIES OUTPUT_NAME "murmurd")
endif()

if(bonjour)
	if(NOT APPLE)
		find_pkg("avahi-compat-libdns_sd" QUIET)
		if(NOT avahi-compat-libdns_sd_FOUND)
			find_library(LIB_DNSSD "dnssd")
			if(LIB_DNSSD-NOTFOUND)
				message(FATAL_ERROR "Bonjour library not found!")
			endif()
			target_link_libraries(murmur PRIVATE ${LIB_DNSSD})
		endif()
	endif()

	target_compile_definitions(murmur PRIVATE "USE_BONJOUR")

	target_include_directories(murmur PRIVATE "${3RDPARTY_DIR}/qqbonjour-src")

	target_sources(murmur PRIVATE
		"BonjourServer.cpp"
		"BonjourServer.h"

		"${3RDPARTY_DIR}/qqbonjour-src/BonjourRecord.h"
		"${3RDPARTY_DIR}/qqbonjour-src/BonjourServiceRegister.cpp"
		"${3RDPARTY_DIR}/qqbonjour-src/BonjourServiceRegister.h"
	)

	target_link_libraries(murmur PRIVATE ${avahi-compat-libdns_sd_LIBRARIES})
endif()

if(dbus AND NOT WIN32 AND NOT APPLE)
	find_pkg(Qt5 COMPONENTS DBus REQUIRED)
	target_compile_definitions(murmur PRIVATE "USE_DBUS")
	target_sources(murmur PRIVATE "DBus.cpp" "DBus.h")
	target_link_libraries(murmur PRIVATE Qt5::DBus)
endif()

if(grpc)
	find_pkg(GRPC REQUIRED)

	protobuf_generate(LANGUAGE cpp TARGET murmur PROTOS ${GRPC_FILE})

	add_subdirectory("${SHARED_SOURCE_DIR}/murmur_grpcwrapper_protoc_plugin" "${CMAKE_CURRENT_BINARY_DIR}/murmur_grpcwrapper_protoc_plugin")

	get_filename_component(GRPC_FILE_NAME ${GRPC_FILE} NAME_WE)

	add_custom_command(
		OUTPUT "MurmurRPC.proto.Wrapper.cpp"
		COMMAND protobuf::protoc
		ARGS "--plugin=$<TARGET_FILE:protoc-gen-murmur-grpcwrapper>" "-I${CMAKE_CURRENT_SOURCE_DIR}" "--murmur-grpcwrapper_out=${CMAKE_CURRENT_BINARY_DIR}" ${GRPC_FILE}
		DEPENDS protobuf::protoc protoc-gen-murmur-grpcwrapper ${GRPC_FILE}
		COMMENT "Generating gRPC wrapper"
		VERBATIM
		# protoc doesn't seem to parse the plugin path correctly on Windows: it only finds the executable when in the current directory or in PATH.
		WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/murmur_grpcwrapper_protoc_plugin"
	)

	set(GRPC_GENERATED_FILES "MurmurRPC.grpc.pb.cc" "MurmurRPC.grpc.pb.h")

	add_custom_command(
		OUTPUT ${GRPC_GENERATED_FILES}
		COMMAND protobuf::protoc
		ARGS "--plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>" "-I${CMAKE_CURRENT_SOURCE_DIR}" "--grpc_out=${CMAKE_CURRENT_BINARY_DIR}" ${GRPC_FILE}
		DEPENDS protobuf::protoc gRPC::grpc_cpp_plugin ${GRPC_FILE}
		COMMENT "Running gRPC compiler"
		VERBATIM
	)

	add_custom_target(generate-grpc-files DEPENDS "MurmurRPC.proto.Wrapper.cpp" ${GRPC_GENERATED_FILES})

	add_dependencies(murmur generate-grpc-files)

	target_compile_definitions(murmur PRIVATE "USE_GRPC")

	target_include_directories(murmur PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

	target_sources(murmur PRIVATE "MurmurGRPCImpl.cpp" "MurmurGRPCImpl.h" ${GRPC_GENERATED_FILES})

	target_link_libraries(murmur PRIVATE gRPC::grpc++_reflection)

	if(${CMAKE_SYSTEM_NAME} STREQUAL "FreeBSD")
		target_link_libraries(murmur PRIVATE gRPC::gpr)
	endif()
endif()

if(ice)
	find_pkg(Ice 
		COMPONENTS 
			Ice
			IceUtil
			IceSSL
			IceDiscovery
			IceLocatorDiscovery
		REQUIRED
	)

	if(Ice_VERSION LESS 3.7)
		if(Ice_VERSION_MAJOR LESS 3)
			message(FATAL_ERROR "Unsupported Ice version, at least 3.0 is required.")
		endif()
	endif()

	get_filename_component(ICE_FILE_NAME ${ICE_FILE} NAME_WE)

	list(APPEND ICE_GENERATED_FILES "${ICE_FILE_NAME}.cpp")
	list(APPEND ICE_GENERATED_FILES "${ICE_FILE_NAME}.h")

	foreach(SLICE_DIR ${Ice_SLICE_DIRS})
		list(APPEND SLICE_INCLUDE_ARGS "-I${SLICE_DIR}")
	endforeach()

	add_custom_command(
		OUTPUT ${ICE_GENERATED_FILES}
		COMMAND ${Ice_SLICE2CPP_EXECUTABLE}
		ARGS "--checksum" ${SLICE_INCLUDE_ARGS} ${ICE_FILE}
		MAIN_DEPENDENCY ${ICE_FILE}
		COMMENT "Generating Ice files"
		VERBATIM
	)

	# We explicitly tell CMake not to call any autogen tools (e.g. MOC) for the generated files.
	# @ref https://cmake.org/cmake/help/latest/policy/CMP0071.html
	set_property(SOURCE ${ICE_GENERATED_FILES} PROPERTY SKIP_AUTOGEN ON)

	target_compile_definitions(murmur 
		PRIVATE 
			"USE_ICE"
			"ICE_STATIC_LIBS"
	)

	target_include_directories(murmur 
		PRIVATE 
			${CMAKE_CURRENT_BINARY_DIR}
			${Ice_INCLUDE_DIRS}
	)

	target_sources(murmur PRIVATE "MurmurIce.cpp" "MurmurIce.h" ${ICE_GENERATED_FILES})

	target_link_libraries(murmur 
		PRIVATE
			Ice::Ice
			Ice::IceUtil
			Ice::IceSSL
			Ice::IceDiscovery
			Ice::IceLocatorDiscovery
	)
endif()
