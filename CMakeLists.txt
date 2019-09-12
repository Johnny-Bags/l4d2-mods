cmake_minimum_required(VERSION 3.0)
project(mods)

if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
	set(PLUGINS_DIR ${CMAKE_CURRENT_LIST_DIR}/../../plugins)
	if (EXISTS ${PLUGINS_DIR})
		set (CMAKE_INSTALL_PREFIX ${PLUGINS_DIR} CACHE PATH "default install path" FORCE)
	endif()
endif()

add_subdirectory(berserker)
add_subdirectory(medic)
