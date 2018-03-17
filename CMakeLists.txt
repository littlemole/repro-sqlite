############################################
cmake_minimum_required(VERSION 2.8.9)
cmake_policy(SET CMP0054 NEW)
project(reprosqlite)
include(CTest)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(INSTALL_DEBUG "On")
set(INSTALL_RELEASE "On")

find_package(GTest REQUIRED)
find_package(OpenSSL REQUIRED)

############################################
# clang support
############################################

set(LINKERFLAGS "")
set(STDLIB "")
set(FLAGS "")


if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(STDLIB "c++abi")
    set(LINKERFLAGS "-stdlib=libc++ -fcoroutines-ts  -std=c++14")
    set(FLAGS "-stdlib=libc++ -fcoroutines-ts -D_RESUMABLE_FUNCTIONS_SUPPORTED")
endif()

set( CMAKE_EXE_LINKER_FLAGS  "${CMAKE_EXE_LINKER_FLAGS} ${LINKERFLAGS}" )

message(" COMPILER: ${CMAKE_CXX_COMPILER_ID}")
message(" FLAGS: ${FLAGS}")

############################################
# OS support
############################################


IF (WIN32)

	set(OSLIBS "Ws2_32" "Rpcrt4")

	find_library(SQLITE_LIBRARY NAMES sqlite3)
	find_library(NG2HTTP_LIBRARY NAMES nghttp2)
	find_library(LIBEVENT_LIBRARY NAMES event)

	set(BUILDFLAGS "-await ${FLAGS}")
	set(DEBUGFLAGS "-DMOL_PROMISE_DEBUG")
	set(LIBS ${GTEST_LIBRARIES} ${OPENSSL_LIBRARIES} ${NG2HTTP_LIBRARY} ${SQLITE_LIBRARY} ${STDLIB}  )

	if( "${CMAKE_BUILD_TYPE}" STREQUAL "Release")
		find_library(PRIOCPP_LIBRARY NAMES priocpp)
		set(INSTALL_DEBUG "Off")
		set(LIBS ${LIBS} ${CMAKE_PROJECT_NAME} ${PRIOCPP_LIBRARY} )
		set(DEBUGFLAGS " ")
	else()
		find_library(PRIOCPPD_LIBRARY NAMES priocppd)
		set(INSTALL_RELEASE "Off")
		set(LIBS ${LIBS} ${CMAKE_PROJECT_NAME}d ${PRIOCPPD_LIBRARY} )
		set(DEBUGFLAGS "-DMOL_PROMISE_DEBUG ")
	endif()

 ELSEIF(UNIX)

    set(OSLIBS "pthread")

    find_package(PkgConfig)
    pkg_check_modules(SQLITE REQUIRED sqlite3)
    pkg_check_modules(NGHTTP2 REQUIRED libnghttp2)
    pkg_check_modules(PRIOCPP REQUIRED priocpp)
    pkg_check_modules(LIBEVENT REQUIRED libevent_pthreads)

	set(LIBEVENT_LIBRARY ${LIBEVENT_LIBRARIES})

    set(BUILDFLAGS " ${FLAGS}")
	set(DEBUGFLAGS "-g -DMOL_PROMISE_DEBUG")

	set(LIBS priocppd ${GTEST_LIBRARIES} ${OPENSSL_LIBRARIES} ${NGHTTP2_LIBRARIES} ${SQLITE_LIBRARIES} ${STDLIB} )
ENDIF ()

############################################
# macros
############################################

macro(AddCompilerFlags target flags)
    get_target_property(CF ${target} COMPILE_FLAGS)
    if(CF STREQUAL "CF-NOTFOUND")
        SET(CF "") # set to empty string
    else()
        SET(CF "${CF} ") # a space to cleanly separate from existing content
    endif()

    SET(CF "${CF} ${flags}" )
    set_target_properties(${target} PROPERTIES COMPILE_FLAGS ${CF} )
endmacro()

############################################
# defaults
############################################


set(BACKEND ${LIBEVENT_LIBRARY})

option(WITH_LIBEVENT "use libevent (default:on)" ON)
if(WITH_LIBEVENT)
    add_definitions(-DPROMISE_USE_LIBEVENT)
else()
    add_definitions(-DPROMISE_USE_BOOST_ASIO)
    set(BACKEND "boost_system")
endif()


############################################
# sources
############################################

include_directories(include)
include_directories(${PRIOCPP_INCLUDE_DIRS})
include_directories(${OPENSSL_INCLUDE_DIR})

file(GLOB SOURCES "src/*.cpp")
file(GLOB HEADERS "include/reprosqlite/*.h")

############################################
# targets
############################################

add_library(reprosqlite  STATIC ${SOURCES})
add_library(reprosqlited STATIC ${SOURCES})

add_executable(Tests t/test.cpp)

AddCompilerFlags(reprosqlite ${BUILDFLAGS})

AddCompilerFlags(reprosqlited ${BUILDFLAGS})
AddCompilerFlags(reprosqlited ${DEBUGFLAGS})

AddCompilerFlags(Tests ${BUILDFLAGS})
AddCompilerFlags(Tests ${DEBUGFLAGS})


############################################
# libs
############################################

target_link_libraries(Tests reprosqlited ${LIBS} ${BACKEND} ${OSLIBS} )


############################################
# tests
############################################

add_test(NAME AllTests COMMAND Tests)

file(COPY test.db DESTINATION .)

############################################
# install rules
############################################
 
if( "${INSTALL_RELEASE}" STREQUAL "On")
	install(TARGETS reprosqlite DESTINATION lib)
endif()

if( "${INSTALL_DEBUG}" STREQUAL "On")
	install(TARGETS reprosqlited DESTINATION lib)
endif()

install(FILES ${HEADERS} DESTINATION include/reprosqlite)

install(FILES reprosqlite.pc DESTINATION lib/pkgconfig)
