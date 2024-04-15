#!/bin/sh

#  build-gdal-ios.sh
#  Geode
#
#  Created by Jefferson Jones on 4/14/24.
#

set -x
set -e

# Fully qualified path to script directory
SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
GDAL_SOURCES="$SCRIPT_PATH/../gdal"
TOOLCHAIN_FILE="$SCRIPT_PATH/../ios-cmake/ios.toolchain.cmake"
BUILD_PATH="$SCRIPT_PATH/../gdal-build"
PROJ_PATH="$SCRIPT_PATH/../"

# Ensure CMake is installed.
if ! command -v cmake &> /dev/null
then
    echo "CMake not found. Installing with brew..."
    brew install cmake
fi

cmake -B "$BUILD_PATH" -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DPLATFORM=OS64COMBINED \
    -DENABLE_BITCODE=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_APPS=OFF \
    -DBUILD_PYTHON_BINDINGS=OFF \
    -DPROJ_ROOT="$PROJ_PATH" \
    "$GDAL_SOURCES"


exit 0
