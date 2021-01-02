# CMake generated Testfile for 
# Source directory: /Users/narayan/workspace/mortar/ext/mtocpp
# Build directory: /Users/narayan/workspace/mortar/ext/mtocpp
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(MTOCPP_TEST "/Users/narayan/workspace/mortar/ext/mtocpp/test.sh")
set_tests_properties(MTOCPP_TEST PROPERTIES  FAIL_REGULAR_EXPRESSION "(failed)")
add_test(MTOCPP_DOXYTEST "/usr/local/bin/doxygen" "/Users/narayan/workspace/mortar/ext/mtocpp/test/doxygen.conf")
