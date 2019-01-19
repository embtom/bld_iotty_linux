project(iotty)
cmake_minimum_required(VERSION 2.8)

#find_package(osBase REQUIRED)

set(CMAKE_DEBUG_POSTFIX _g)
######################################################
#Compile Git Version into the library
######################################################

SET (GIT_EXECUTABLE git)
# the commit's SHA1, and whether the building workspace was dirty or not
execute_process(COMMAND 
  "${GIT_EXECUTABLE}" describe --match=NeVeRmAtCh --always --abbrev=40 --dirty
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  OUTPUT_VARIABLE GIT_SHA1
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

# the date of the commit
execute_process(COMMAND 
  "${GIT_EXECUTABLE}" log -1 --format=%ad --date=local
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  OUTPUT_VARIABLE GIT_DATE
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

# the subject of the commit
execute_process(COMMAND
  "${GIT_EXECUTABLE}" log -1 --format=%s
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  OUTPUT_VARIABLE GIT_COMMIT_SUBJECT
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

# generate version.cc
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/iotty_version.c.in" "${CMAKE_CURRENT_BINARY_DIR}/iotty_version.c" @ONLY)

######################################################
#Configure flags
######################################################
SET(CMAKE_POSITION_INDEPENDENT_CODE ON)
SET(LIB_LIST_LOCK lock_cas)
SET(LIB_SERIAL_ARCHITECTURE linux)
SET(LIB_THREAD_ARCHITECTURE posix)

######################################################
#Subdirectoris 
######################################################
add_subdirectory(lib_convention)
add_subdirectory(lib_list)
add_subdirectory(lib_log)
add_subdirectory(lib_mini_printf)
add_subdirectory(lib_serial)
add_subdirectory(lib_thread)
add_subdirectory(lib_console)
add_subdirectory(lib_tty_portmux)

######################################################
#Setup subprojects
######################################################

#LIB_TTYPORTMUX get header
get_property(HEADERS_LIB_TTYPORTMUX TARGET lib_ttyportmux PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
get_property(HEADERS_LIB_LOG TARGET lib_log PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
get_property(HEADERS_LIB_CONSOLE TARGET lib_console PROPERTY INTERFACE_INCLUDE_DIRECTORIES)
get_property(HEADERS_LIB_SERIAL TARGET lib_serial PROPERTY INTERFACE_INCLUDE_DIRECTORIES)

SET(MY_PUBLIC_HEADERS_DIR ${HEADERS_LIB_TTYPORTMUX} ${HEADERS_LIB_LOG} ${HEADERS_LIB_CONSOLE} ${HEADERS_LIB_SERIAL})
SET(PUBLISH_HEADERS_TOPDIR iotty_version.h)

FOREACH(item ${MY_PUBLIC_HEADERS_DIR})
  file(GLOB item_headers "${item}/*.h")
  LIST(APPEND PUBLISH_HEADERS_TOPDIR ${item_headers})
ENDFOREACH()

FOREACH(item ${MY_PUBLIC_HEADERS_DIR})
  file(GLOB_RECURSE item_headers "${item}/*/*.h")
  LIST(APPEND PUBLISH_HEADERS_SUBDIRS ${item_headers})
ENDFOREACH()

######################################################
#Build target settings
######################################################
add_library(${PROJECT_NAME} SHARED ${CMAKE_CURRENT_BINARY_DIR}/iotty_version.c ) 
target_link_libraries(${PROJECT_NAME} PRIVATE "-Wl,--whole-archive" lib_ttyportmux lib_log lib_console "-Wl,--no-whole-archive")
target_include_directories(${PROJECT_NAME} PRIVATE ./)
target_include_directories(${PROJECT_NAME} PUBLIC $<INSTALL_INTERFACE:include/embtom/iotty> )
#target_compile_definitions(${PROJECT_NAME} PUBLIC ${COMPILE_DEF_LIB_LIST})

######################################################
#Install
######################################################

message(STATUS "${PUBLISH_HEADERS_SUBDIRS}")

set_target_properties(${PROJECT_NAME} PROPERTIES PUBLIC_HEADER "${PUBLISH_HEADERS_TOPDIR}")

include(GNUInstallDirs)
install(TARGETS ${PROJECT_NAME}
    EXPORT iotty-targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/embtom/iotty
)
install(FILES cmake/iottyConfig.cmake DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/iotty)

install(EXPORT iotty-targets
  FILE
    iottyTargets.cmake
  NAMESPACE
    EMBTOM::
  DESTINATION
    ${CMAKE_INSTALL_LIBDIR}/cmake/iotty
)


######################################################
#CPack
######################################################

set(CPACK_GENERATOR "DEB")
SET(CPACK_PACKAGE_NAME "embtom-iotty-${CMAKE_BUILD_TYPE}")
set(CPACK_PACKAGE_VERSION_MAJOR "0")
set(CPACK_PACKAGE_VERSION_MINOR "1")
set(CPACK_PACKAGE_VERSION_PATCH "0")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS ON)
set(CPACK_PACKAGE_DESCRIPTION "EMBTOM::iotty")
set(CPACK_PACKAGE_CONTACT "Thomas Willetal t.willetal@googlemail.com")
set(CPACK_PACKAGING_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "GIT_SHA1: ${GIT_SHA1}") 

include(CPack)
