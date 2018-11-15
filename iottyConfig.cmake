get_filename_component(iotty_CMAKE_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
include(CMakeFindDependencyMacro)

if(NOT TARGET EMBTOM::iotty)
    include("${iotty_CMAKE_DIR}/iottyTargets.cmake")
endif()
