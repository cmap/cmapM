# CMake generated Testfile for 
# Source directory: /xchip/cogs/narayan/code/github/mortar/ext/mtocpp
# Build directory: /xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build
# 
# This file includes the relevent testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
ADD_TEST(MTOCPP_TEST "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build/test.sh")
SET_TESTS_PROPERTIES(MTOCPP_TEST PROPERTIES  FAIL_REGULAR_EXPRESSION "(failed)")
ADD_TEST(MTOCPP_DOXYTEST "/xchip/cogs/tools/opt/bin/doxygen" "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp/test/doxygen.conf")
