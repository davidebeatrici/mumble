# Copyright 2019 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

find_pkg(Qt5 COMPONENTS Test REQUIRED)

add_subdirectory(TestCrypt)

add_subdirectory(TestCryptographicHash)

add_subdirectory(TestCryptographicRandom)

add_subdirectory(TestFFDHE)

add_subdirectory(TestPacketDataStream)

add_subdirectory(TestPasswordGenerator)

add_subdirectory(TestSelfSignedCertificate)

add_subdirectory(TestServerAddress)

add_subdirectory(TestServerResolver)

add_subdirectory(TestSSLLocks)

add_subdirectory(TestStdAbs)

add_subdirectory(TestTimer)

add_subdirectory(TestUnresolvedServerAddress)

add_subdirectory(TestXMLTools)
