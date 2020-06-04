#!/bin/bash -ex
#
# Copyright 2019-2020 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.
#
# Below is a list of configuration variables used from environment.
#
#  AGENT_BUILDDIRECTORY       - The local path on the agent where all folders
#                               for a given build pipeline are created
#  BUILD_SOURCESDIRECTORY     - The local path on the agent where the
#                               repository is downloaded.
#

cd $AGENT_BUILDDIRECTORY

# QSslDiffieHellmanParameters was introduced in Qt 5.8, Ubuntu 16.04 has 5.5.
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -Dsymbols=ON -Dqssldiffiehellmanparameters=OFF $BUILD_SOURCESDIRECTORY
cmake --build .
ctest

# TODO: The next few lines should be done by "make install": https://github.com/mumble-voip/mumble/issues/1029
mkdir -p appdir/usr/bin appdir/usr/lib/mumble appdir/usr/share/metainfo/ appdir/usr/share/icons/hicolor/scalable/apps/ appdir/usr/share/applications/
cp lib* appdir/usr/lib/
cp mumble appdir/usr/bin
cp plugins/lib* appdir/usr/lib/mumble/
cp $BUILD_SOURCESDIRECTORY/scripts/mumble.desktop appdir/usr/share/applications/
cp $BUILD_SOURCESDIRECTORY/scripts/mumble.appdata.xml appdir/usr/share/metainfo/
cp $BUILD_SOURCESDIRECTORY/icons/mumble.svg appdir/usr/share/icons/hicolor/scalable/apps/

wget -c -nv "https://github.com/probonopd/linuxdeployqt/releases/download/continuous/linuxdeployqt-continuous-x86_64.AppImage"
chmod a+x linuxdeployqt-continuous-x86_64.AppImage
ARCH=x86_64 ./linuxdeployqt-continuous-x86_64.AppImage $(find $HOME -type d -name 'appdir'| head -n 1)/usr/share/applications/*.desktop -appimage -extra-plugins=sqldrivers/libqsqlite.so

for f in Mumble*.AppImage; do
	# Embed update information into AppImage
	echo -n "zsync|https://dl.mumble.info/snapshot/latest-x86_64.AppImage.zsync" | dd of=$f seek=175720 conv=notrunc oflag=seek_bytes

	# Generate zsync file for AppImage
	zsyncmake $f
done

mv Mumble*.AppImage* $BUILD_ARTIFACTSTAGINGDIRECTORY
