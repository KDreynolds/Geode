#!/bin/sh

#  build-proj-ios.sh
#  Geode
#
#  Adapted for PROJ by Kyle Reynolds on 4/14/24.
#

set -x
set -e

# Fully qualified path to script directory
SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PROJ_SOURCES="$SCRIPT_PATH/../proj"
TOOLCHAIN_FILE="$SCRIPT_PATH/../ios-cmake/ios.toolchain.cmake"
BUILD_PATH="$SCRIPT_PATH/../proj-build"

# Ensure CMake is installed.
if ! command -v cmake &> /dev/null
then
    echo "CMake not found. Installing with brew..."
    brew install cmake
fi

# Configure PROJ build for iOS
cmake -B "$BUILD_PATH" -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DPLATFORM=OS64COMBINED \
    -DENABLE_BITCODE=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    "$PROJ_SOURCES"

# Build PROJ
xcodebuild -project "$BUILD_PATH/PROJ.xcodeproj" -configuration Release -alltargets

exit 0