

project(qvimwrapper)

# Always include srcdir and builddir in include path
# This saves typing ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY} in about every subdir
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# put the include dirs which are in the source or build tree
# before all other include dirs, so the headers in the sources
# are prefered over the already installed ones
set(CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE ON)

# Use colored output
set(CMAKE_COLOR_MAKEFILE ON)

set( CCMAKE_CXX_FLAGS_RELEASE "-O3" )
set( CCMAKE_C_FLAGS_RELEASE "-O3" )

set( CMAKE_CXX_FLAGS_DEBUG "-g3 -Wall -ansi -DDEBUG" )
set( CMAKE_C_FLAGS_DEBUG "-g3 -Wall -ansi -DDEBUG" )

find_package(Qt4 REQUIRED)
if (NOT QT_QTGUI_FOUND)
	MESSAGE(FATAL_ERROR "Could not find qt-gui library")
endif(NOT QT_QTGUI_FOUND)

include( FixQt4DebugBuild.cmake )

add_subdirectory( tests )
