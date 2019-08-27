cmake_minimum_required(VERSION 3.12)
project(berserker LANGUAGES NONE)

# cmake modules
list(APPEND CMAKE_MODULE_PATH
	${CMAKE_CURRENT_LIST_DIR}/../cmake/Modules
)

include(SourcePawn)

# source files
list(APPEND SRC
	${CMAKE_CURRENT_SOURCE_DIR}/berserker.sp
)

# include dirs
list(APPEND INCLUDE_DIRS
	${CMAKE_CURRENT_LIST_DIR}/..
)

# target
add_sourcepawn_target(${PROJECT_NAME} ${SRC} ${INCLUDE_DIRS})

# install
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.smx DESTINATION .)
