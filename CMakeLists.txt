#
# CMakeLists.txt --- a "CMake" file for building TextMagus
#
# Copyright (C) Markus Franz Xaver Johannes Oberhumer
#

#
# simple usage:
#     mkdir -p build && cd build && cmake .. && make
#
# another usage example:
#     mkdir -p build/release-i686
#     cd       build/release-i686
#     cmake ../.. \
#         -DCMAKE_C_COMPILER=gcc -DCMAKE_C_FLAGS="-m32 -march=i686" \
#         -DCMAKE_CXX_COMPILER=g++ -DCMAKE_CXX_FLAGS="-m32 -march=i686" \
#         -DCMAKE_INSTALL_PREFIX=/opt/local/prefix-i686
#     make VERBOSE=1
#     make install
#
# see http://www.cmake.org/ for more info
#

# TODO: lua -DLUA_PATH_VAR="TEXTMAGUS__xx" -DLUA_CPATH_VAR="TEXTMAGUS_xx"

#
# init
#

# Older cmake versions may work as well - but are not tested.
# Using the latest cmake version available is highly recommended in any case.
cmake_minimum_required(VERSION 3.4 FATAL_ERROR)
if (1 AND EXISTS "$ENV{HOME}/.cmake/ZMAKE_CMAKE_DIR.cmake")
include($ENV{HOME}/.cmake/ZMAKE_CMAKE_DIR.cmake)
include(${ZMAKE_CMAKE_DIR}/init.cmake)
endif()

# Disallow in-source builds. Note that you will still have to manually
# clean up a few files if you accidentally try an in-source build.
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_DISABLE_SOURCE_CHANGES  ON)
if(",${CMAKE_SOURCE_DIR}," STREQUAL ",${CMAKE_BINARY_DIR},")
    message(FATAL_ERROR "ERROR: In-source builds are not allowed.")
endif()

project(textmagus C CXX)
if(ZMAKE_CMAKE_DIR)
include(${ZMAKE_CMAKE_DIR}/tcinit.cmake)
endif()

set(CMAKE_C_STANDARD   99)  # C99
set(CMAKE_CXX_STANDARD 11)  # C++11

#
# user configuration options
#

option(ENABLE_CURSES "Build textmagus curses version." ON)
option(ENABLE_GTK2   "Build textmagus gtk2 version."   ON)
option(ENABLE_GTK3   "Build textmagus gtk3 version."   ON)
option(ENABLE_QT4    "Build textmagus qt4 version."    ON) # TODO
option(ENABLE_QT5    "Build textmagus qt5 version."    OFF) # TODO
# TODO: automoc + both qt4 and qt5 + parallel make breaks !!

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Release" CACHE STRING "" FORCE)
endif()
if(NOT CMAKE_INSTALL_PREFIX)
    set(CMAKE_INSTALL_PREFIX "/usr/local" CACHE PATH "" FORCE)
endif()

#
# advanced configuration options
#

option(ENABLE_WERROR "Build with '-Werror' compiler flag"  OFF)
option(ENABLE_SHARED "Build shared libraries (DEBUG ONLY)"  OFF)

option(SCINTILLA_LEXLIB_ALL_LEXERS "Use all Scintilla lexers" OFF)
option(SCINTILLA_LEXLIB_LPEG_LEXER "Use LPeg lexers" ON)

if(NOT ENABLE_STATIC AND NOT ENABLE_SHARED)
    set(ENABLE_STATIC ON)
endif()

include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckLibraryExists)
include(CheckSymbolExists)
include(CheckTypeSize)
include(TestBigEndian)

#
# util for "make install"
#

include(GNUInstallDirs)

macro(my_install_bin) # ARGN
    foreach(tt ${ARGN})
        install(TARGETS ${tt} DESTINATION "${CMAKE_INSTALL_FULL_BINDIR}")
        if(ENABLE_SHARED)
            set_target_properties(${tt} PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_FULL_LIBEXECDIR}/textmagus")
        endif()
    endforeach()
endmacro()

macro(my_install_lib) # ARGN
    if(ENABLE_SHARED)
        foreach(tt ${ARGN})
            install(TARGETS ${tt} DESTINATION "${CMAKE_INSTALL_FULL_LIBEXECDIR}/textmagus")
        endforeach()
    endif()
endmacro()

function(my_install_data)
    set(datadir "${CMAKE_INSTALL_FULL_DATADIR}/textmagus/textadept")
    set(s "${d}textadept")
    install(FILES ${s}/init.lua ${s}/properties.lua DESTINATION ${datadir})
    install(DIRECTORY ${s}/core ${s}/modules ${s}/themes DESTINATION ${datadir})
    set(s "${d}scintillua")
    install(DIRECTORY ${s}/lexers DESTINATION ${datadir} PATTERN "themes" EXCLUDE)
endfunction()

#
# compilation flags
#

if(ENABLE_CURSES)
    include(FindCurses)
    if(CURSES_FOUND)
        ####set(CURSES_LIBRARIES ncursesw)
        #message(STATUS "CURSES_INCLUDE_DIRS=${CURSES_INCLUDE_DIRS}")
        #message(STATUS "CURSES_LIBRARIES=${CURSES_LIBRARIES}")
    else()
        message(STATUS "WARNING: did *NOT* find Curses -- disabling")
        set(ENABLE_CURSES OFF)
    endif()
endif()

if(ENABLE_GTK2)
    include(FindGTK2)
    find_package(GTK2 2.18 QUIET COMPONENTS gtk)
    if(GTK2_FOUND)
        message(STATUS "Found GTK2 ${GTK2_VERSION}")
        set(GTK2_LIBRARIES ${GTK2_LIBRARIES} ${GTK2_GTK_LIBRARY} ${GTK2_GDK_LIBRARY})
        #message(STATUS "GTK2_INCLUDE_DIRS=${GTK2_INCLUDE_DIRS}")
        #message(STATUS "GTK2_LIBRARIES=${GTK2_LIBRARIES}")
    else()
        message(STATUS "WARNING: did *NOT* find GTK2 -- disabling")
        set(ENABLE_GTK2 OFF)
    endif()
endif()

if(ENABLE_GTK3)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(GTK3 QUIET gtk+-3.0)
    if(GTK3_FOUND)
        message(STATUS "Found GTK3 ${GTK3_VERSION}")
        set(GTK3_LIBRARIES ${GTK3_LIBRARIES} gmodule-2.0)
        #message(STATUS "GTK3_INCLUDE_DIRS=${GTK3_INCLUDE_DIRS}")
        #message(STATUS "GTK3_LIBRARIES=${GTK3_LIBRARIES}")
    else()
        message(STATUS "WARNING: did *NOT* find GTK3 -- disabling")
        set(ENABLE_GTK3 OFF)
    endif()
endif()

if(ENABLE_QT4)
    find_package(Qt4 4.6 QUIET COMPONENTS QtGui)
    if(Qt4_FOUND)
        message(STATUS "Found Qt4")
        set(QT4_INCLUDE_DIRS ${QT_QTCORE_INCLUDE_DIR} ${QT_QTGUI_INCLUDE_DIR})
        set(QT4_LIBRARIES Qt4::QtGui)
    else()
        message(STATUS "WARNING: did *NOT* find Qt4 -- disabling")
        set(ENABLE_QT4 OFF)
    endif()
endif()

if(ENABLE_QT5)
    find_package(Qt5Widgets QUIET)
    if(Qt5Widgets_FOUND)
        message(STATUS "Found Qt5")
        set(QT5_INCLUDE_DIRS ) # handled automatically by cmake
        set(QT5_LIBRARIES Qt5::Widgets)
    else()
        message(STATUS "WARNING: did *NOT* find Qt5 -- disabling")
        set(ENABLE_QT5 OFF)
    endif()
endif()

#
# compilation flags
#

message(STATUS "Info: Target OS ${CMAKE_SYSTEM_NAME}")
if(CMAKE_SYSTEM_NAME MATCHES "^Linux")
    set(LUA_CFLAGS -DLUA_USE_LINUX)
    set(LUA_EXTRA_LIBRARIES m dl)
elseif(CMAKE_SYSTEM_NAME MATCHES "^Windows")
    set(ENABLE_SHARED OFF)
    set(ENABLE_WERROR OFF)
    set(LUA_CFLAGS -DLUA_PREFER___INT64)
endif()
set(SCINTILLA_CFLAGS -DSCI_LEXER -DNO_CXX11_REGEX -DSCI_OWNREGEX)
if(SCINTILLA_LEXLIB_ALL_LEXERS)
    list(APPEND SCINTILLA_CFLAGS -DSCINTILLA_LEXLIB_ALL_LEXERS)
endif()
if(SCINTILLA_LEXLIB_LPEG_LEXER)
    list(APPEND SCINTILLA_CFLAGS -DSCINTILLA_LEXLIB_LPEG_LEXER)
endif()

# we use a high warning level by default
if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
  if(CMAKE_C_COMPILER_ID MATCHES "^(Clang)$")
#    add_definitions(-Weverything)
#    add_definitions(-Wall -Wextra -Wpointer-arith -Wwrite-strings)
#    add_definitions(-Wtautological-overlap-compare)
#    add_definitions(-Wunreachable-code)
#    set(ENABLE_WERROR OFF)
    add_definitions(-Wall -Wextra -Wpointer-arith -Wwrite-strings)
    if(NOT CMAKE_C_COMPILER_VERSION VERSION_LESS 3.4) # useable since clang-3.4
        add_definitions(-Wtautological-compare)
    endif()
  else()
    add_definitions(-Wall -Wextra -Wpointer-arith -Wwrite-strings)
  endif()
    if(ENABLE_WERROR AND CMAKE_C_COMPILER_ID MATCHES "^Clang$" AND CMAKE_SYSTEM_NAME MATCHES "^Linux")
        # glib2 on Ubuntu 12.04 uses the deprecated "register" keyword
        if(NOT CMAKE_C_COMPILER_VERSION VERSION_LESS 3.4) # since clang-3.4
            add_definitions(-Wno-deprecated-register)
        endif()
    endif()
    if(CMAKE_C_COMPILER_ID MATCHES "^GNU$" AND CMAKE_C_COMPILER_VERSION VERSION_LESS 4.8)
        add_definitions(-Wno-type-limits)
    endif()
    if(ENABLE_WERROR)
        message(STATUS "Info: enabling -Werror")
        add_definitions(-Werror)
    endif()
endif()

if(ENABLE_SHARED)
    set(STATIC "SHARED")
else()
    set(STATIC "STATIC")
endif()
if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
    set(CMAKE_SHARED_LINKER_FLAGS "-Wl,--as-needed -Wl,--no-undefined -Wl,--warn-common")
    set(CMAKE_EXE_LINKER_FLAGS    "-Wl,--as-needed -Wl,--no-undefined -Wl,--warn-common")
endif()

#
# targets
#

set(d "3rdparty/src/")

## ui_XXX: UI interface libraries (dummy libraries for automatically setting flags - this works transitively)

if(ENABLE_CURSES)
    set(t ui_curses)
    add_library(${t} INTERFACE)
    target_include_directories(${t} INTERFACE ${CURSES_INCLUDE_DIRS})
    target_compile_options(${t} INTERFACE -DCURSES -D_XOPEN_SOURCE_EXTENDED)
    target_link_libraries(${t} INTERFACE ${CURSES_LIBRARIES})
endif()

if(ENABLE_GTK2)
    set(t ui_gtk2)
    add_library(${t} INTERFACE)
    target_include_directories(${t} INTERFACE ${GTK2_INCLUDE_DIRS})
    target_compile_options(${t} INTERFACE -DGTK=2)
    target_link_libraries(${t} INTERFACE ${GTK2_LIBRARIES})
endif()

if(ENABLE_GTK3)
    set(t ui_gtk3)
    add_library(${t} INTERFACE)
    target_include_directories(${t} INTERFACE ${GTK3_INCLUDE_DIRS})
    target_compile_options(${t} INTERFACE -DGTK=3 -DGDK_DISABLE_DEPRECATION_WARNINGS)
    target_link_libraries(${t} INTERFACE ${GTK3_LIBRARIES})
endif()

if(ENABLE_QT4)
    set(t ui_qt4)
    add_library(${t} INTERFACE)
    target_include_directories(${t} INTERFACE ${QT4_INCLUDE_DIRS})
    target_compile_options(${t} INTERFACE -DQT=4 -DSCINTILLA_QT)
    target_link_libraries(${t} INTERFACE ${QT4_LIBRARIES})
endif()

if(ENABLE_QT5)
    set(t ui_qt5)
    add_library(${t} INTERFACE)
    target_include_directories(${t} INTERFACE ${QT5_INCLUDE_DIRS})
    target_compile_options(${t} INTERFACE -DQT=5 -DSCINTILLA_QT)
    target_link_libraries(${t} INTERFACE ${QT5_LIBRARIES})
endif()

## freestanding: tre

file(GLOB tre_SOURCES "${d}tre/lib/*.c")
list(REMOVE_ITEM tre_SOURCES "${CMAKE_SOURCE_DIR}/${d}tre/lib/tre-match-approx.c")
list(SORT tre_SOURCES)
if(1)
    set(t tre)
    add_library(${t} ${STATIC} ${tre_SOURCES})
    target_include_directories(${t} PRIVATE ${d}tre/lib) # note: PRIVATE - see flags for Document.cxx
    target_compile_options(${t} PRIVATE -UNDEBUG)
    my_install_lib(${t})
endif()

## curses: libtermkey & cdk

set(s ${d}libtermkey)
set(libtermkey_SOURCES ${s}/driver-csi.c ${s}/driver-ti.c ${s}/termkey.c)
list(SORT libtermkey_SOURCES)
if(ENABLE_CURSES)
    set(t libtermkey_curses)
    add_library(${t} ${STATIC} ${libtermkey_SOURCES})
    target_include_directories(${t} PUBLIC  ${d}libtermkey)
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-sign-compare -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} ui_curses)
    my_install_lib(${t})
endif()

set(s ${d}cdk)
file(GLOB cdk_SOURCES "${s}/*.c")
foreach(f calendar.c view_file.c)
    list(REMOVE_ITEM cdk_SOURCES "${CMAKE_SOURCE_DIR}/${s}/${f}")
endforeach()
list(SORT cdk_SOURCES)
if(ENABLE_CURSES)
    set(t cdk_curses)
    add_library(${t} ${STATIC} ${cdk_SOURCES})
    target_include_directories(${t} PUBLIC ${d}cdk/include)
    #target_compile_options(${t} PUBLIC -DHAVE_NCURSES_H) # FIXME: do we need this ??
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} libtermkey_curses)
    my_install_lib(${t})
endif()

## gtdialog_XXX

file(GLOB gtdialog_SOURCES "${d}gtdialog/*.c")
list(SORT gtdialog_SOURCES)
if(ENABLE_CURSES)
    set(t gtdialog_curses)
    add_library(${t} ${STATIC} ${gtdialog_SOURCES})
    target_include_directories(${t} PUBLIC  ${d}gtdialog)
    target_compile_definitions(${t} PRIVATE -DNOHELP -DLIBRARY)
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} cdk_curses)
    my_install_lib(${t})
endif()
if(ENABLE_GTK2)
    set(t gtdialog_gtk2)
    add_library(${t} ${STATIC} ${gtdialog_SOURCES})
    target_include_directories(${t} PUBLIC  ${d}gtdialog)
    target_compile_definitions(${t} PRIVATE -DNOHELP -DLIBRARY)
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} ui_gtk2)
    my_install_lib(${t})
endif()
if(ENABLE_GTK3)
    set(t gtdialog_gtk3)
    add_library(${t} ${STATIC} ${gtdialog_SOURCES})
    target_include_directories(${t} PUBLIC  ${d}gtdialog)
    target_compile_definitions(${t} PRIVATE -DNOHELP -DLIBRARY)
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} ui_gtk3)
    my_install_lib(${t})
endif()

## lua, lua_lpeg, lua_filesystem, lspawn_XXX

file(GLOB lua_SOURCES "${CMAKE_SOURCE_DIR}/${d}lua/src/*.c")
list(REMOVE_ITEM lua_SOURCES "${CMAKE_SOURCE_DIR}/${d}lua/src/lua.c")
list(SORT lua_SOURCES)
if(1)
    set(t lua)
    add_library(${t} ${STATIC} ${lua_SOURCES})
    target_include_directories(${t} PUBLIC ${d}lua/src)
    target_compile_options(${t} PUBLIC  ${LUA_CFLAGS})
    target_compile_options(${t} PRIVATE -ULUA_LIB -DLUA_COMPAT_BITLIB -DLUA_COMPAT_APIINTCASTS)
    target_link_libraries(${t} ${LUA_EXTRA_LIBRARIES})
    my_install_lib(${t})
endif()

file(GLOB lua_lpeg_SOURCES "${d}lua-lpeg/*.c")
list(SORT lua_lpeg_SOURCES)
if(1)
    set(t lua_lpeg)
    add_library(${t} ${STATIC} ${lua_lpeg_SOURCES})
    target_compile_options(${t} PRIVATE -UNDEBUG)
    target_link_libraries(${t} lua)
    my_install_lib(${t})
endif()

file(GLOB lua_filesystem_SOURCES "${d}luafilesystem/src/*.c")
list(SORT lua_filesystem_SOURCES)
if(1)
    set(t lua_filesystem)
    add_library(${t} ${STATIC} ${lua_filesystem_SOURCES})
    target_link_libraries(${t} lua)
    my_install_lib(${t})
endif()

file(GLOB lspawn_SOURCES "${d}lspawn/*.c")
list(SORT lspawn_SOURCES)
if(ENABLE_CURSES)
    set(t lspawn_curses)
    add_library(${t} ${STATIC} ${lspawn_SOURCES})
    target_compile_options(${t} PRIVATE -D_XOPEN_SOURCE)
    target_link_libraries(${t} lua ui_curses)
    my_install_lib(${t})
endif()
if(ENABLE_GTK2)
    set(t lspawn_gtk2)
    add_library(${t} ${STATIC} ${lspawn_SOURCES})
    target_compile_options(${t} PRIVATE -D_XOPEN_SOURCE)
    target_link_libraries(${t} lua ui_gtk2)
    my_install_lib(${t})
endif()
if(ENABLE_GTK3)
    set(t lspawn_gtk3)
    add_library(${t} ${STATIC} ${lspawn_SOURCES})
    target_compile_options(${t} PRIVATE -D_XOPEN_SOURCE)
    target_link_libraries(${t} lua ui_gtk3)
    my_install_lib(${t})
endif()

## scintilla: scintilla_lexlib & scintilla_XXX

set(s ${d}scintilla)

set(scintilla_lexlib_SOURCES
    ${s}/lexlib/Accessor.cxx ${s}/lexlib/CharacterSet.cxx
    ${s}/lexlib/LexerBase.cxx ${s}/lexlib/LexerModule.cxx
    ${s}/lexlib/LexerNoExceptions.cxx ${s}/lexlib/LexerSimple.cxx
    ${s}/lexlib/PropSetSimple.cxx ${s}/lexlib/StyleContext.cxx
    ${s}/lexlib/WordList.cxx
)
if(SCINTILLA_LEXLIB_ALL_LEXERS)
    file(GLOB x "${s}/lexers/*.cxx")
    list(APPEND scintilla_lexlib_SOURCES ${s}/lexlib/CharacterCategory.cxx ${x})
endif()
if(SCINTILLA_LEXLIB_LPEG_LEXER)
    list(APPEND scintilla_lexlib_SOURCES ${d}scintillua/LexLPeg.cxx)
    set_source_files_properties(${d}scintillua/LexLPeg.cxx PROPERTIES COMPILE_DEFINITIONS "LPEG_LEXER;NO_SCITE")
endif()
list(SORT scintilla_lexlib_SOURCES)
if(1)
    set(t scintilla_lexlib)
    add_library(${t} ${STATIC} ${scintilla_lexlib_SOURCES})
    target_include_directories(${t} PUBLIC ${s}/include)
    target_include_directories(${t} PUBLIC ${s}/lexlib)
    target_compile_options(${t} PUBLIC ${SCINTILLA_CFLAGS})
    if(SCINTILLA_LEXLIB_LPEG_LEXER)
        target_link_libraries(${t} lua_lpeg)
    endif()
    my_install_lib(${t})
endif()

file(GLOB scintilla_SOURCES "${s}/src/*.cxx")
list(SORT scintilla_SOURCES)
# for <tre.h>
set_source_files_properties(${s}/src/Document.cxx PROPERTIES COMPILE_FLAGS "-I${CMAKE_SOURCE_DIR}/${d}tre/lib")

if(ENABLE_CURSES)
    set(t scintilla_curses)
    add_library(${t} ${STATIC}
        ${scintilla_SOURCES}
        ${d}scinterm/ScintillaTerm.cxx
    )
    target_include_directories(${t} PUBLIC  ${d}scinterm)
    target_include_directories(${t} PRIVATE ${s}/src)
    target_compile_options(${t} PRIVATE ${SCINTILLA_CFLAGS})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-missing-field-initializers)
    endif()
    target_link_libraries(${t} tre scintilla_lexlib ui_curses)
    my_install_lib(${t})
endif()

if(ENABLE_GTK2)
    set(t scintilla_gtk2)
    add_library(${t} ${STATIC}
        ${scintilla_SOURCES}
        ${s}/gtk/PlatGTK.cxx ${s}/gtk/ScintillaGTK.cxx ${s}/gtk/scintilla-marshal.c
    )
    target_include_directories(${t} PRIVATE ${s}/src)
    target_compile_options(${t} PRIVATE ${SCINTILLA_CFLAGS})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-missing-field-initializers)
    endif()
    target_link_libraries(${t} tre scintilla_lexlib ui_gtk2)
    my_install_lib(${t})
endif()

if(ENABLE_GTK3)
    set(t scintilla_gtk3)
    add_library(${t} ${STATIC}
        ${scintilla_SOURCES}
        ${s}/gtk/PlatGTK.cxx ${s}/gtk/ScintillaGTK.cxx ${s}/gtk/scintilla-marshal.c
    )
    target_include_directories(${t} PRIVATE ${s}/src)
    target_compile_options(${t} PRIVATE ${SCINTILLA_CFLAGS})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-missing-field-initializers)
    endif()
    target_link_libraries(${t} tre scintilla_lexlib ui_gtk3)
    my_install_lib(${t})
endif()

if(ENABLE_QT4)
    set(t scintilla_qt4)
    add_library(${t} ${STATIC}
        ${scintilla_SOURCES}
        ${s}/qt/ScintillaEditBase/PlatQt.cpp
        ${s}/qt/ScintillaEditBase/ScintillaEditBase.cpp
        ${s}/qt/ScintillaEditBase/ScintillaQt.cpp
    )
    set_target_properties(${t} PROPERTIES AUTOMOC ON)
    target_include_directories(${t} PRIVATE ${s}/src)
    target_compile_options(${t} PRIVATE ${SCINTILLA_CFLAGS} -DEXPORT_IMPORT_API=)
    target_link_libraries(${t} tre scintilla_lexlib ui_qt4)
    my_install_lib(${t})
endif()

if(ENABLE_QT5)
    set(t scintilla_qt5)
    add_library(${t} ${STATIC}
        ${scintilla_SOURCES}
        ${s}/qt/ScintillaEditBase/PlatQt.cpp
        ${s}/qt/ScintillaEditBase/ScintillaEditBase.cpp
        ${s}/qt/ScintillaEditBase/ScintillaQt.cpp
    )
    set_target_properties(${t} PROPERTIES AUTOMOC ON)
    target_include_directories(${t} PRIVATE ${s}/src)
    target_compile_options(${t} PRIVATE ${SCINTILLA_CFLAGS} -DEXPORT_IMPORT_API=)
    target_link_libraries(${t} tre scintilla_lexlib ui_qt5)
    my_install_lib(${t})
endif()

## textadept: textadept-curses, textadept-gtk2 & textadept-gtk3

file(GLOB textadept_SOURCES "${d}textadept/src/*.c")
list(SORT textadept_SOURCES)

if(ENABLE_CURSES)
    set(t textadept-curses)
    add_executable(${t} ${textadept_SOURCES})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} lua_lpeg lua_filesystem lspawn_curses gtdialog_curses scintilla_curses)
    my_install_bin(${t})
endif()

if(ENABLE_GTK2)
    set(t textadept-gtk2)
    add_executable(${t} ${textadept_SOURCES})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} lua_lpeg lua_filesystem lspawn_gtk2 gtdialog_gtk2 scintilla_gtk2)
    my_install_bin(${t})
endif()

if(ENABLE_GTK3)
    set(t textadept-gtk3)
    add_executable(${t} ${textadept_SOURCES})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} lua_lpeg lua_filesystem lspawn_gtk3 gtdialog_gtk3 scintilla_gtk3)
    my_install_bin(${t})
endif()

my_install_data()

## test

if(1 AND ENABLE_CURSES)
    set(t example_jinx1_curses)
    add_executable(${t} ${d}scinterm/jinx/jinx.c)
    target_link_libraries(${t} scintilla_curses)
#    set(t example_jinx2_curses)
#    add_executable(${t} jinx2.c)
#    target_link_libraries(${t} scintilla_curses)
endif()

#
#
#

if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
    set_source_files_properties(${d}cdk/cdk.c                           PROPERTIES COMPILE_FLAGS "-Wno-unused-variable")
    set_source_files_properties(${d}cdk/draw.c                          PROPERTIES COMPILE_FLAGS "-Wno-address")
    set_source_files_properties(${d}libtermkey/driver-ti.c              PROPERTIES COMPILE_FLAGS "-Wno-missing-field-initializers")
    set_source_files_properties(${d}scinterm/ScintillaTerm.cxx          PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
    set_source_files_properties(${d}scinterm/jinx/jinx.c                PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
    set_source_files_properties(${d}scintilla/gtk/PlatGTK.cxx           PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
    set_source_files_properties(${d}scintilla/gtk/ScintillaGTK.cxx      PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
    set_source_files_properties(${d}scintilla/src/ContractionState.cxx  PROPERTIES COMPILE_FLAGS "-Wno-strict-overflow")
    set_source_files_properties(${d}scintillua/LexLPeg.cxx              PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
endif()

if(ZMAKE_CMAKE_DIR)
include(${ZMAKE_CMAKE_DIR}/main.cmake)
endif()

# vim:set ft=cmake ts=4 sw=4 tw=0 et:
