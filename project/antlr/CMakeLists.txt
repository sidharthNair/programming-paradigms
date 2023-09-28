CMAKE_MINIMUM_REQUIRED(VERSION 3.7 FATAL_ERROR)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)

set(CMAKE_CXX_STANDARD 17)

include(ExternalAntlr4Cpp)

include_directories(${ANTLR4_INCLUDE_DIRS})

set(ANTLR_EXECUTABLE thirdparty/antlr-4.13.1-complete.jar)
find_package(ANTLR REQUIRED)

antlr_target(Cypher Cypher.g4 LEXER PARSER
             PACKAGE antlrcpptest)

# include generated files in project environment
include_directories(${ANTLR_Cypher_OUTPUT_DIR})

# add generated grammar to demo binary target
add_executable(cypher main.cpp
               ${ANTLR_Cypher_CXX_OUTPUTS})
target_link_libraries(cypher antlr4_static)