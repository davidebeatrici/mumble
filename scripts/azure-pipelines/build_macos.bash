#!/bin/bash -ex
#
# Copyright 2019-2020 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

ver=$(python scripts/mumble-version.py)

mkdir release && cd release

<<<<<<< HEAD
make -j $(sysctl -n hw.ncpu)
make check
=======
cmake ..
make -j $(sysctl -n hw.ncpu) && make test
>>>>>>> CI: Build Linux, FreeBSD and macOS targets with CMake

# Build installer (temporarily disabled, "osax" project not implemented yet)
#cd ..
#./macx/scripts/osxdist.py --version=${ver}

#mv release/*.dmg ${BUILD_ARTIFACTSTAGINGDIRECTORY}
