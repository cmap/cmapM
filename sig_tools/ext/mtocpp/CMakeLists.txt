PROJECT (MTOC++)
CMAKE_MINIMUM_REQUIRED(VERSION 2.6)

SET(MTOC++_VERSION_MAJOR 1)
SET(MTOC++_VERSION_MINOR 5)

# Default install prefix is "/usr/local"
SET(CUSTOM_DOC_DIR "share/doc/mtocpp"
  CACHE PATH "Custom directory where the documentation files will be installed")

SET(CMAKE_CXX_FLAGS "-Wall")
# path to FindRagel.cmake and WindowsToolChain.cmake
SET(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# enable make test
ENABLE_TESTING()

FIND_PACKAGE(Ragel REQUIRED)
FIND_PACKAGE(Doxygen REQUIRED)
FIND_PACKAGE(LATEX)

IF(DOXYGEN_DOT_FOUND)
  SET(MTOC++_HAVE_DOT "YES")
ELSE(DOXYGEN_DOT_FOUND)
  SET(MTOC++_HAVE_DOT "NO")
ENDIF(DOXYGEN_DOT_FOUND)

# files that need configuration...
CONFIGURE_FILE(
  "${CMAKE_CURRENT_SOURCE_DIR}/test/test.sh.in"
  "${CMAKE_CURRENT_BINARY_DIR}/test.sh"
  @ONLY
  )

CONFIGURE_FILE(
  "${CMAKE_CURRENT_SOURCE_DIR}/src/config.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/config.h"
  )

CONFIGURE_FILE(
  "${CMAKE_CURRENT_SOURCE_DIR}/test/mtoc.sh.in"
  "${CMAKE_CURRENT_SOURCE_DIR}/test/mtoc.sh"
  )

CONFIGURE_FILE(
  "${CMAKE_CURRENT_SOURCE_DIR}/src/docs/doxygen.conf.in"
  "${CMAKE_CURRENT_BINARY_DIR}/doxygen.conf"
  )

# pathes where to look for header files
INCLUDE_DIRECTORIES("${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/src")

# Ragel preprocessing
RAGEL_PARSER(src/mfilescanner_parser)
RAGEL_PARSER(src/confscanner)
RAGEL_PARSER(src/postprocess)

# Explicitly define where the binaries should go (needed for custom target documentation)
set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
set (CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_CURRENT_BINARY_DIR})
set (CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_CURRENT_BINARY_DIR})

# create mtocpp
ADD_EXECUTABLE(mtocpp src/mtocpp.cc mfilescanner_parser.cc src/mfilescanner.cc confscanner.cc)
# create mtocpp_post
ADD_EXECUTABLE(mtocpp_post postprocess.cc)

# add options for cross compilation on windows
IF(CMAKE_CROSSCOMPILING)
  TARGET_LINK_LIBRARIES(mtocpp -lshlwapi)
ENDIF(CMAKE_CROSSCOMPILING)

# add target for documentation
ADD_CUSTOM_TARGET(documentation ALL
  COMMENT "Creating HTML documentation... (see ${CMAKE_CURRENT_BINARY_DIR}/docs/doxygen.log for warnings)"
  COMMAND ${DOXYGEN_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/doxygen.conf
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/mtocpp_post -q ${CMAKE_CURRENT_BINARY_DIR}/docs
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/src/docs/tabs.css ${CMAKE_CURRENT_BINARY_DIR}/docs/
  DEPENDS mtocpp mtocpp_post
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/src/docs"
)

# add target for pdf documentation
IF(DEFINED LATEX_COMPILER)
ADD_CUSTOM_TARGET(documentation_pdf ALL
  COMMENT "Creating PDF documentation... (see ${CMAKE_CURRENT_BINARY_DIR}/docs/latex/refman.log for latex errors/warnings)"
  COMMAND make
  COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/docs/latex/refman.pdf ${CMAKE_CURRENT_BINARY_DIR}/docs/manual.pdf
  COMMAND ${CMAKE_COMMAND} -E echo "PDF docs at ${CMAKE_CURRENT_BINARY_DIR}/docs/manual.pdf!"
  COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_CURRENT_BINARY_DIR}/docs/latex/
  WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/docs/latex/"
)
ENDIF(DEFINED LATEX_COMPILER)

INSTALL(TARGETS mtocpp mtocpp_post DESTINATION bin)
INSTALL(FILES ${CMAKE_CURRENT_SOURCE_DIR}/License.txt DESTINATION ${CUSTOM_DOC_DIR})
#INSTALL(FILES ${CMAKE_CURRENT_SOURCE_DIR}/mtocpp.conf.example DESTINATION ${CUSTOM_DOC_DIR})
INSTALL(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/docs/ DESTINATION ${CUSTOM_DOC_DIR})

# add test target: test examples (unix only so far)
IF (UNIX)
	ADD_TEST(MTOCPP_TEST "${CMAKE_CURRENT_BINARY_DIR}/test.sh")
	SET_TESTS_PROPERTIES(MTOCPP_TEST PROPERTIES FAIL_REGULAR_EXPRESSION "(failed)")
ENDIF(UNIX)

ADD_TEST(NAME MTOCPP_DOXYTEST COMMAND ${DOXYGEN_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/test/doxygen.conf")
# enable dashboard scripting
INCLUDE (CTest)

SET (CTEST_PROJECT_NAME "MTOC++")

# build a CPack driven installer package
SET (CPACK_GENERATOR "DEB;TGZ")
SET (CPACK_SOURCE_GENERATOR "TGZ")
SET (CPACK_RESOURCE_FILE_LICENSE
  "${CMAKE_CURRENT_SOURCE_DIR}/License.txt")
SET (CPACK_PACKAGE_VERSION_MAJOR "${MTOC++_VERSION_MAJOR}")
SET (CPACK_PACKAGE_VERSION_MINOR "${MTOC++_VERSION_MINOR}")
SET (CPACK_PACKAGE_VENDOR "MDDW")
SET (CPACK_PACKAGE_CONTACT "Martin Drohmann <mdrohmann@uni-muenster.de>, Daniel Wirtz <daniel.wirtz@mathematik.uni-stuttgart.de>")
SET (CPACK_PACKAGE_DESCRIPTION_SUMMARY "Doxygen filter for Matlab M-files and scripts")
SET (CPACK_PACKAGE_DESCRIPTION
  "This package includes two programs to build beautiful Doxygen documentation
  for Matlab projects. The filter program 'mtocpp' transforms relevant parts of
  the M-Files into C++ syntax, which can be parsed by doxygen. The generated
  html files can be processed by the program 'postprocess' in order to generate
  documentation looking more like Matlab.")
SET (CPACK_DEBIAN_PACKAGE_SECTION "devel")
SET (CPACK_DEBIAN_PACKAGE_SUGGESTS "doxygen")
SET (CPACK_SOURCE_IGNORE_FILES "/CVS/;/\\\\.svn/;\\\\.swp$;\\\\.git/;\\\\.gitignore;build/;")

INCLUDE (CPack)
