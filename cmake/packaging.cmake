if(WIN32)
	if(64_BIT)
		set(CPACK_WIX_UPGRADE_GUID "E028BDFC-3FE2-4BEE-A33B-EB9C80611555")
	elseif(32_BIT)
		set(CPACK_WIX_UPGRADE_GUID "B0EEFCC7-8A9C-4471-AB10-CBD35BE3161D")
	endif()

	set(CPACK_WIX_UI_BANNER "${CMAKE_SOURCE_DIR}/installer/bannrbmp.bmp")
	set(CPACK_WIX_UI_DIALOG "${CMAKE_SOURCE_DIR}/installer/dlgbmp.bmp")
	set(CPACK_WIX_PRODUCT_GUID "84afea8b-15e5-4cc7-b77d-27dd17030944")
	set(CPACK_WIX_CULTURES "en-US;cs-CZ;da-DK;nl-NL;en-GB;fi-FI;fr-FR;de-DE;el-GR;it-IT;ja-JP;no-NO;pl-PL;pt-PT;ru-RU;es-ES;sv-SE;tr-TR;zh-CN;zh-TW")
	set(CPACK_WIX_PRODUCT_ICON "${CMAKE_SOURCE_DIR}/icons/mumble.ico")
	set(CPACK_WIX_EXTENSIONS "WiXUtilExtension")
	set(CPACK_PACKAGE_EXECUTABLES "mumble;Mumble" "murmur;Murmur")
	set(CPACK_CREATE_DESKTOP_LINKS "mumble;Mumble" "murmur;Murmur")
	set(CPACK_PACKAGE_INSTALL_DIRECTORY "Mumble")
endif()

if(client)
	set(CPACK_PACKAGE_NAME "Mumble (client)")
	set(CPACK_PACKAGE_FILE_NAME "Mumble_Client-${version}-${CMAKE_SYSTEM_PROCESSOR}")
	set(CPACK_PACKAGE_VENDOR "Mumble VoIP")
	set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Mumble is a free, open source, low latency, high quality voice chat application.")
	set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/installer/gpl.rtf")
	set(CPACK_COMPONENTS_ALL client_bin)
	set(CPACK_COMPONENT_CLIENT_BIN_REQUIRED ON)
	set(CPACK_COMPONENT_CLIENT_BIN_DISPLAY_NAME "Mumble")
	set(CPACK_COMPONENT_CLIENT_BIN_DESCRIPTION "The Mumble VoIP Client")
	install(FILES
		"${CMAKE_SOURCE_DIR}/README"
		"${CMAKE_SOURCE_DIR}/CHANGES"
		"${CMAKE_SOURCE_DIR}/installer/gpl.txt"
		"${CMAKE_SOURCE_DIR}/installer/qt.txt"
		"${CMAKE_SOURCE_DIR}/installer/speex.txt"
		DESTINATION "."
		COMPONENT client_bin
	)
endif()

if(server AND NOT client)
	set(CPACK_PACKAGE_NAME "Mumble (server)")
	set(CPACK_PACKAGE_FILE_NAME "Mumble_Server-${version}-${CMAKE_SYSTEM_PROCESSOR}")
	set(CPACK_PACKAGE_VENDOR "Mumble VoIP")
	set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Mumble is a free, open source, low latency, high quality voice chat application.")
	set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/installer/gpl.rtf")
	set(CPACK_COMPONENT_SERVER_BIN_REQUIRED ON)
	install(FILES
		"${CMAKE_SOURCE_DIR}/README"
		"${CMAKE_SOURCE_DIR}/CHANGES"
		"${CMAKE_SOURCE_DIR}/installer/gpl.txt"
		"${CMAKE_SOURCE_DIR}/installer/qt.txt"
		DESTINATION "."
		COMPONENT server_bin
	)
endif()

if(server)
	set(CPACK_COMPONENTS_ALL server_bin)
	set(CPACK_COMPONENT_SERVER_BIN_DISPLAY_NAME "Murmur")
	set(CPACK_COMPONENT_SERVER_BIN_DESCRIPTION "The Murmur VoIP Server")
	if(WIN32)
		install(FILES "${CMAKE_SOURCE_DIR}/scripts/murmur.ini" DESTINATION "." COMPONENT server_bin)
	endif()
endif()

if(client AND server)
	set(CPACK_PACKAGE_NAME "Mumble")
	set(CPACK_PACKAGE_FILE_NAME "Mumble-${version}-${CMAKE_SYSTEM_PROCESSOR}")
	set(CPACK_PACKAGE_VENDOR "Mumble VoIP")
	set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Mumble is a free, open source, low latency, high quality voice chat application.")
	set(CPACK_COMPONENTS_ALL client_bin server_bin)
endif()

include(CPack)
