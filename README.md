Welcome to TextMagus!


Travis CI Build Status
======================

| Branch  | Status  |
|---------|---------|
| master  | [![Travis CI build status][travis_master_badge]][travis_master_link] |

[travis_master_badge]: https://travis-ci.org/textmagus/textmagus.svg?branch=master "Travis CI build status"
[travis_master_link]:  https://travis-ci.org/textmagus/textmagus                   "Travis CI test suite"



Build requirements
==================

A halfway modern C99 and C++11 compiler.
gcc versions >= 4.6 and clang versions >= 3.3 are known to work.

A recent cmake version >= 3.4.

Curses, GTK2, GTK3, QT4 or QT5 development packages.

On Fedora 23:
```
dnf install cmake gcc-c++ git make
dnf install ncurses-devel               # for the curses version
dnf install gtk2-devel                  # for the gtk2 version
dnf install gtk3-devel                  # for the gtk3 version
dnf install qt-devel                    # for the qt4 version
dnf install qt5-qtbase-devel            # for the qt5 version
```

On Ubuntu 14.04 "Trusty":
```
apt-get install build-essential cmake g++ git
apt-get install libncurses5-dev
apt-get install libgtk2.0-dev
apt-get install libgtk-3-dev
apt-get install libqt4-dev
apt-get install qtbase5-dev
```


Getting the source
==================

```
git clone --recurse-submodules https://github.com/textmagus/textmagus
```

or

```
git clone https://github.com/textmagus/textmagus
cd textmagus
git submodule update --init
```


Building
========

Simply run

```
mkdir -p build
cd build
cmake ..
make
```
