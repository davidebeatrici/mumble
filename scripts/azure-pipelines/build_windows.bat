:: Copyright 2020 The Mumble Developers. All rights reserved.
:: Use of this source code is governed by a BSD-style license
:: that can be found in the LICENSE file at the root of the
:: Mumble source tree or at <https://www.mumble.info/LICENSE>.
::
:: Builds Mumble using the specified build script.
:: The path to the script is relative to the build environment's root.
:: The configuration we build with is adjusted to be close to
:: our release builds.
::
:: Below is a list of configuration variables used from environment.
::
:: Predefined variables:
::
::  AGENT_BUILDDIRECTORY         - The local path on the agent where all folders
::                                 for a given build pipeline are created
::  BUILD_SOURCESDIRECTORY       - The local path on the agent where the
::                                 repository is downloaded.
::  AGENT_TOOLSDIRECTORY         - The directory used by tasks such as
::                                 Node Tool Installer and Use Python Version
::                                 to switch between multiple versions of a tool.
::                                 We store our build environment there, in the
::                                 folder specified by MUMBLE_ENVIRONMENT_DIR.
::
:: Defined in .azure-pipelines.yml:
::
::  MUMBLE_ENVIRONMENT_STORE     - Path to the folder the build environment is stored in.
::  MUMBLE_ENVIRONMENT_SOURCE    - Build environment web source folder URL
::  MUMBLE_ENVIRONMENT_VERSION   - Full build environment version
::                                 Must match archive and extracted folder name.
::  MUMBLE_ENVIRONMENT_TOOLCHAIN - Path to the vcpkg CMake toolchain, used for CMake.
::

@echo on

cd /d %AGENT_BUILDDIRECTORY%

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat"

:: Delete MinGW, otherwise CMake picks it over MSVC.
:: We don't delete the (Chocolatey) packages because it takes ~10 minutes...
del C:\ProgramData\chocolatey\bin\gcc.exe
del C:\ProgramData\chocolatey\bin\g++.exe
del C:\ProgramData\chocolatey\bin\c++.exe
del C:\Strawberry\c\bin\gcc.exe
del C:\Strawberry\c\bin\g++.exe
del C:\Strawberry\c\bin\c++.exe

cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE="%MUMBLE_ENVIRONMENT_TOOLCHAIN%" -DVCPKG_TARGET_TRIPLET=x64-windows-static-md -DIce_HOME="%MUMBLE_ENVIRONMENT_PATH%\installed\x64-windows-static-md" -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -Dpackaging=ON -Dstatic=ON -Dsymbols=ON -Dasio=ON -Dg15=ON "%BUILD_SOURCESDIRECTORY%"

if errorlevel 1 (
	exit /b %errorlevel%
)

cmake --build .

if errorlevel 1 (
	exit /b %errorlevel%
)

ctest

if errorlevel 1 (
	exit /b %errorlevel%
)
