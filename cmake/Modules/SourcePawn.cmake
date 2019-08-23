list(APPEND SourcePawn_ROOT
	${CMAKE_CURRENT_LIST_DIR}/../../..
	${CMAKE_SOURCE_DIR}/../..
	${CMAKE_SOURCE_DIR}/..
	../..
	..
	.
)

find_package(SourcePawn)

function(add_sourcepawn_target NAME SRC INCLUDE_DIRS)
	foreach(DIR ${INCLUDE_DIRS})
		list(APPEND OPT_INCLUDE_DIRS -i${DIR})
	endforeach()
	
	add_custom_target(${NAME} ALL
		COMMAND
			${SOURCEPAWN_EXECUTABLE} ${SRC} ${OPT_INCLUDE_DIRS} -o ${NAME}
		SOURCES
			${SRC}
		COMMENT
			"Compiling ${NAME}..."
	)
endfunction()
