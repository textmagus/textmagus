#! /bin/bash
## vim:set ts=4 sw=4 et:
set -e; set -o pipefail

echo "BUILD_METHOD_AND_BUILD_TYPE='$BUILD_METHOD_AND_BUILD_TYPE'"
echo "CMAKE_EXTRA_FLAGS='$CMAKE_EXTRA_FLAGS'"
echo "VERBOSE='$VERBOSE'"
echo "CC='$CC'"
echo "CXX='$CXX'"
echo "CPPFLAGS='$CPPFLAGS'"
echo "CFLAGS='$CFLAGS'"
echo "CXXFLAGS='$CXXFLAGS'"
echo "LDFLAGS='$LDFLAGS'"
echo "BUILD_DIR='$BUILD_DIR'"

mkdir -p "$BUILD_DIR" || exit 1
cd "$BUILD_DIR" || exit 1

set -x
cmake --version
pwd
#env | LC_ALL=C sort

if ! test -f "$TRAVIS_BUILD_DIR/CMakeLists.txt"; then
    echo "ERROR: invalid TRAVIS_BUILD_DIR '$TRAVIS_BUILD_DIR'"
    exit 1
fi

case $BUILD_METHOD_AND_BUILD_TYPE in
cmake/debug)
    cmake "$TRAVIS_BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug   "-DCMAKE_INSTALL_PREFIX=$PWD/install" $CMAKE_EXTRA_FLAGS
    make VERBOSE=$VERBOSE
    make VERBOSE=$VERBOSE install
    ;;
cmake/release)
    cmake "$TRAVIS_BUILD_DIR" -DCMAKE_BUILD_TYPE=Release "-DCMAKE_INSTALL_PREFIX=$PWD/install" $CMAKE_EXTRA_FLAGS
    make VERBOSE=$VERBOSE
    make VERBOSE=$VERBOSE install
    ;;
*)
    echo "ERROR: invalid build '$BUILD_METHOD_AND_BUILD_TYPE'"
    exit 1
    ;;
esac
