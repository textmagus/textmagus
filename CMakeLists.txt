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
option(ENABLE_QT5    "Build textmagus qt5 version."    ON) # TODO

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
        ##set(CURSES_LIBRARIES -lcursesw)
        #message(STATUS "CURSES_INCLUDE_DIRS=${CURSES_INCLUDE_DIRS}")
        #message(STATUS "CURSES_LIBRARIES=${CURSES_LIBRARIES}")
    else()
        message(STATUS "WARNING: did *NOT* find Curses -- disabling")
        set(ENABLE_CURSES OFF)
    endif()
endif()
if(ENABLE_GTK2)
    include(FindGTK2)
    find_package(GTK2 2.18 COMPONENTS gtk)
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
    else()
        message(STATUS "WARNING: did *NOT* find Qt4 -- disabling")
        set(ENABLE_QT4 OFF)
    endif()
endif()
if(ENABLE_QT5)
    find_package(Qt5Widgets)
    if(Qt5Widgets_FOUND)
        message(STATUS "Found Qt5")
    else()
        message(STATUS "WARNING: did *NOT* find Qt5 -- disabling")
        set(ENABLE_QT5 OFF)
    endif()
endif()

if(CMAKE_SYSTEM_NAME MATCHES "^Linux")
    set(LUA_CFLAGS -DLUA_USE_LINUX)
    set(LUA_EXTRA_LIBRARIES dl m)
endif()
set(SCINTILLA_CFLAGS -DSCI_LEXER -DNDEBUG -DNO_CXX11_REGEX -DSCI_OWNREGEX)

# we use a high warning level by default
if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
    add_definitions(-Wall -Wextra -Wpointer-arith -Wwrite-strings)
    if(ENABLE_WERROR AND CMAKE_C_COMPILER_ID MATCHES "^Clang$" AND CMAKE_SYSTEM_NAME MATCHES "^Linux")
        # glib2 on Ubuntu 12.04 uses the deprecated "register" keyword
        add_definitions(-Wno-deprecated-register)
    endif()
    if(CMAKE_C_COMPILER_ID MATCHES "^GNU$" AND CMAKE_C_COMPILER_VERSION VERSION_LESS 4.8)
        add_definitions(-Wno-type-limits)
    endif()
    if(ENABLE_WERROR)
        add_definitions(-Werror)
        message(STATUS "INFO: enabling -Werror")
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
    target_compile_options(${t} INTERFACE -DQT=4)
    target_link_libraries(${t} INTERFACE Qt4::QtGui)
endif()

if(ENABLE_QT5)
    set(t ui_qt5)
    add_library(${t} INTERFACE)
    target_compile_options(${t} INTERFACE -DQT=5)
    target_link_libraries(${t} INTERFACE Qt5::Widgets)
endif()

## freestanding: tre

file(GLOB tre_SOURCES "${d}tre/lib/*.c")
list(REMOVE_ITEM tre_SOURCES "${CMAKE_SOURCE_DIR}/${d}tre/lib/tre-match-approx.c")
list(SORT tre_SOURCES)
if(1)
    set(t tre)
    add_library(${t} ${STATIC} ${tre_SOURCES})
    target_include_directories(${t} PRIVATE ${d}tre/lib) # note: PRIVATE - see flags for Document.cxx
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
    target_link_libraries(${t} ui_curses ui_qt4)
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

## lua, lpeg, luafilesystem, lspawn_XXX

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

file(GLOB lpeg_SOURCES "${d}lua-lpeg/*.c")
list(SORT lpeg_SOURCES)
if(1)
    set(t lpeg)
    add_library(${t} ${STATIC} ${lpeg_SOURCES})
    target_compile_options(${t} PRIVATE -UNDEBUG)
    target_link_libraries(${t} lua)
    my_install_lib(${t})
endif()

file(GLOB luafilesystem_SOURCES "${d}luafilesystem/src/*.c")
list(SORT luafilesystem_SOURCES)
if(1)
    set(t luafilesystem)
    add_library(${t} ${STATIC} ${luafilesystem_SOURCES})
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
list(SORT scintilla_lexlib_SOURCES)
if(1)
    set(t scintilla_lexlib)
    add_library(${t} ${STATIC}
        ${scintilla_lexlib_SOURCES}
    )
    target_include_directories(${t} PUBLIC ${s}/include)
    target_include_directories(${t} PUBLIC ${s}/lexlib)
    target_compile_options(${t} PUBLIC ${SCINTILLA_CFLAGS})
    my_install_lib(${t})
endif()

file(GLOB scintilla_SOURCES "${s}/src/*.cxx")
set(defs )
set(libs )
if(SCINTILLA_LEXLIB_ALL_LEXERS)
    list(APPEND defs -DSCINTILLA_LEXLIB_ALL_LEXERS)
endif()
if(SCINTILLA_LEXLIB_LPEG_LEXER)
    list(APPEND defs -DSCINTILLA_LEXLIB_LPEG_LEXER)
    list(APPEND libs lpeg)
    list(APPEND scintilla_SOURCES ${d}scintillua/LexLPeg.cxx)
    set_source_files_properties(${d}scintillua/LexLPeg.cxx PROPERTIES COMPILE_DEFINITIONS "LPEG_LEXER;NO_SCITE")
endif()
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
    target_compile_options(${t} PRIVATE ${SCINTILLA_CFLAGS} ${defs})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-missing-field-initializers -Wno-strict-overflow)
    endif()
    target_link_libraries(${t} tre scintilla_lexlib ui_curses ${libs})
    my_install_lib(${t})
endif()

if(ENABLE_GTK2)
    set(t scintilla_gtk2)
    add_library(${t} ${STATIC}
        ${scintilla_SOURCES}
        ${s}/gtk/PlatGTK.cxx ${s}/gtk/ScintillaGTK.cxx ${s}/gtk/scintilla-marshal.c
    )
    target_include_directories(${t} PRIVATE ${s}/src)
    target_compile_options(${t} PRIVATE ${SCINTILLA_CFLAGS} ${defs})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-missing-field-initializers -Wno-strict-overflow)
    endif()
    target_link_libraries(${t} tre scintilla_lexlib ui_gtk2 ${libs})
    my_install_lib(${t})
endif()

if(ENABLE_GTK3)
    set(t scintilla_gtk3)
    add_library(${t} ${STATIC}
        ${scintilla_SOURCES}
        ${s}/gtk/PlatGTK.cxx ${s}/gtk/ScintillaGTK.cxx ${s}/gtk/scintilla-marshal.c
    )
    target_include_directories(${t} PRIVATE ${s}/src)
    target_compile_options(${t} PRIVATE ${SCINTILLA_CFLAGS} ${defs})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-missing-field-initializers -Wno-strict-overflow)
    endif()
    target_link_libraries(${t} tre scintilla_lexlib ui_gtk3 ${libs})
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
    target_link_libraries(${t} lpeg luafilesystem lspawn_curses gtdialog_curses scintilla_curses)
    my_install_bin(${t})
endif()
if(ENABLE_GTK2)
    set(t textadept-gtk2)
    add_executable(${t} ${textadept_SOURCES})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} lpeg luafilesystem lspawn_gtk2 gtdialog_gtk2 scintilla_gtk2)
    my_install_bin(${t})
endif()
if(ENABLE_GTK3)
    set(t textadept-gtk3)
    add_executable(${t} ${textadept_SOURCES})
    if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
        target_compile_options(${t} PRIVATE -Wno-unused-parameter)
    endif()
    target_link_libraries(${t} lpeg luafilesystem lspawn_gtk3 gtdialog_gtk3 scintilla_gtk3)
    my_install_bin(${t})
endif()

my_install_data()

#
#
#

if(CMAKE_C_COMPILER_ID MATCHES "^(Clang|GNU)$")
    set_source_files_properties(${d}cdk/cdk.c                      PROPERTIES COMPILE_FLAGS "-Wno-unused-variable")
    set_source_files_properties(${d}cdk/draw.c                     PROPERTIES COMPILE_FLAGS "-Wno-address")
    set_source_files_properties(${d}libtermkey/driver-ti.c         PROPERTIES COMPILE_FLAGS "-Wno-missing-field-initializers")
  if(CMAKE_C_COMPILER_ID MATCHES "^Clang$")
    set_source_files_properties(${d}scinterm/ScintillaTerm.cxx     PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter -Wno-unused-private-field")
  else()
    set_source_files_properties(${d}scinterm/ScintillaTerm.cxx     PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
  endif()
    set_source_files_properties(${d}scintilla/gtk/PlatGTK.cxx      PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
    set_source_files_properties(${d}scintilla/gtk/ScintillaGTK.cxx PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
    set_source_files_properties(${d}scintillua/LexLPeg.cxx         PROPERTIES COMPILE_FLAGS "-Wno-unused-parameter")
endif()

if(ZMAKE_CMAKE_DIR)
include(${ZMAKE_CMAKE_DIR}/main.cmake)
endif()

# vim:set ft=cmake ts=4 sw=4 tw=0 et:
