#!/bin/bash -ex
#
# Copyright 2019-2020 The Mumble Developers. All rights reserved.
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file at the root of the
# Mumble source tree or at <https://www.mumble.info/LICENSE>.

<<<<<<< HEAD
brew update
brew install pkg-config qt5 boost libogg libvorbis flac libsndfile protobuf openssl ice
=======
brew update && brew upgrade

brew install cmake pkg-config qt5 boost libogg libvorbis flac libsndfile protobuf openssl ice grpc speexdsp opus jack portaudio
>>>>>>> CI: Build Linux, FreeBSD and macOS targets with CMake
