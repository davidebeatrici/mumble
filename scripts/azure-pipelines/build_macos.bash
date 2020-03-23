#!/bin/bash -ex
#
# Copyright 2019-2020 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

#ver=$(python scripts/mumble-version.py)

mkdir build && cd build

cmake -Dgrpc=OFF ..

make -j $(sysctl -n hw.ncpu)
make test

# Build installer (temporarily disabled, "osax" project not implemented yet)
#cd ..
#../macx/scripts/osxdist.py --version=${ver}

#mv *.dmg ${BUILD_ARTIFACTSTAGINGDIRECTORY}
