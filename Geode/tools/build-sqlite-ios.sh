#!/bin/sh

#  build-sqlite-ios.sh
#  Geode
#
#  Adapted for SQLite by Kyle Reynolds on 4/19/24.
#

set -x
set -e

# Fully qualified path to script directory
SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SQLITE_SOURCES="$SCRIPT_PATH/../sqlite3"
TOOLCHAIN_FILE="$SCRIPT_PATH/../ios-cmake/ios.toolchain.cmake"
BUILD_PATH="$SCRIPT_PATH/../sqlite-build"

# Ensure CMake is installed.
if ! command -v cmake &> /dev/null
then
    echo "CMake not found. Installing with brew..."
    brew install cmake
fi

# Configure SQLite build for iOS
echo "Configuring SQLite build for iOS..."
cmake -B "$BUILD_PATH" -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE="$TOOLCHAIN_FILE" \
    -DPLATFORM=OS64COMBINED \
    -DENABLE_BITCODE=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    "$SQLITE_SOURCES"

# Build SQLite
echo "Building SQLite..."
xcodebuild -project "$BUILD_PATH/SQLite.xcodeproj" -configuration Release -alltargets

exit 0