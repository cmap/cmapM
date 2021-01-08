# This file will be configured to contain variables for CPack. These variables
# should be set in the CMake list file of the project before CPack module is
# included. The list of available CPACK_xxx variables and their associated
# documentation may be obtained using
#  cpack --help-variable-list
#
# Some variables are common to all generators (e.g. CPACK_PACKAGE_NAME)
# and some are specific to a generator
# (e.g. CPACK_NSIS_EXTRA_INSTALL_COMMANDS). The generator specific variables
# usually begin with CPACK_<GENNAME>_xxxx.


SET(CPACK_BINARY_7Z "")
SET(CPACK_BINARY_BUNDLE "")
SET(CPACK_BINARY_CYGWIN "")
SET(CPACK_BINARY_DEB "")
SET(CPACK_BINARY_DRAGNDROP "")
SET(CPACK_BINARY_IFW "")
SET(CPACK_BINARY_NSIS "")
SET(CPACK_BINARY_OSXX11 "")
SET(CPACK_BINARY_PACKAGEMAKER "")
SET(CPACK_BINARY_RPM "")
SET(CPACK_BINARY_STGZ "")
SET(CPACK_BINARY_TBZ2 "")
SET(CPACK_BINARY_TGZ "")
SET(CPACK_BINARY_TXZ "")
SET(CPACK_BINARY_TZ "")
SET(CPACK_BINARY_WIX "")
SET(CPACK_BINARY_ZIP "")
SET(CPACK_CMAKE_GENERATOR "Unix Makefiles")
SET(CPACK_COMPONENT_UNSPECIFIED_HIDDEN "TRUE")
SET(CPACK_COMPONENT_UNSPECIFIED_REQUIRED "TRUE")
SET(CPACK_DEBIAN_PACKAGE_SECTION "devel")
SET(CPACK_DEBIAN_PACKAGE_SUGGESTS "doxygen")
SET(CPACK_GENERATOR "DEB;TGZ")
SET(CPACK_INSTALL_CMAKE_PROJECTS "/Users/narayan/workspace/mortar/ext/mtocpp;MTOC++;ALL;/")
SET(CPACK_INSTALL_PREFIX "/Users/narayan/workspace/mortar/ext/mtocpp/build_macosx")
SET(CPACK_MODULE_PATH "/Users/narayan/workspace/mortar/ext/mtocpp/cmake")
SET(CPACK_NSIS_DISPLAY_NAME "MTOC++ 1.5.1")
SET(CPACK_NSIS_INSTALLER_ICON_CODE "")
SET(CPACK_NSIS_INSTALLER_MUI_ICON_CODE "")
SET(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")
SET(CPACK_NSIS_PACKAGE_NAME "MTOC++ 1.5.1")
SET(CPACK_OSX_SYSROOT "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk")
SET(CPACK_OUTPUT_CONFIG_FILE "/Users/narayan/workspace/mortar/ext/mtocpp/CPackConfig.cmake")
SET(CPACK_PACKAGE_CONTACT "Martin Drohmann <mdrohmann@uni-muenster.de>, Daniel Wirtz <daniel.wirtz@mathematik.uni-stuttgart.de>")
SET(CPACK_PACKAGE_DEFAULT_LOCATION "/")
SET(CPACK_PACKAGE_DESCRIPTION "This package includes two programs to build beautiful Doxygen documentation
  for Matlab projects. The filter program 'mtocpp' transforms relevant parts of
  the M-Files into C++ syntax, which can be parsed by doxygen. The generated
  html files can be processed by the program 'postprocess' in order to generate
  documentation looking more like Matlab.")
SET(CPACK_PACKAGE_DESCRIPTION_FILE "/usr/local/Cellar/cmake/3.2.3/share/cmake/Templates/CPack.GenericDescription.txt")
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Doxygen filter for Matlab M-files and scripts")
SET(CPACK_PACKAGE_FILE_NAME "MTOC++-1.5.1-Darwin")
SET(CPACK_PACKAGE_INSTALL_DIRECTORY "MTOC++ 1.5.1")
SET(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "MTOC++ 1.5.1")
SET(CPACK_PACKAGE_NAME "MTOC++")
SET(CPACK_PACKAGE_RELOCATABLE "true")
SET(CPACK_PACKAGE_VENDOR "MDDW")
SET(CPACK_PACKAGE_VERSION "1.5.1")
SET(CPACK_PACKAGE_VERSION_MAJOR "1")
SET(CPACK_PACKAGE_VERSION_MINOR "5")
SET(CPACK_PACKAGE_VERSION_PATCH "1")
SET(CPACK_RESOURCE_FILE_LICENSE "/Users/narayan/workspace/mortar/ext/mtocpp/License.txt")
SET(CPACK_RESOURCE_FILE_README "/usr/local/Cellar/cmake/3.2.3/share/cmake/Templates/CPack.GenericDescription.txt")
SET(CPACK_RESOURCE_FILE_WELCOME "/usr/local/Cellar/cmake/3.2.3/share/cmake/Templates/CPack.GenericWelcome.txt")
SET(CPACK_SET_DESTDIR "OFF")
SET(CPACK_SOURCE_7Z "")
SET(CPACK_SOURCE_CYGWIN "")
SET(CPACK_SOURCE_GENERATOR "TGZ")
SET(CPACK_SOURCE_IGNORE_FILES "/CVS/;/\\.svn/;\\.swp$;\\.git/;\\.gitignore;build/;")
SET(CPACK_SOURCE_OUTPUT_CONFIG_FILE "/Users/narayan/workspace/mortar/ext/mtocpp/CPackSourceConfig.cmake")
SET(CPACK_SOURCE_TBZ2 "")
SET(CPACK_SOURCE_TGZ "")
SET(CPACK_SOURCE_TXZ "")
SET(CPACK_SOURCE_TZ "")
SET(CPACK_SOURCE_ZIP "")
SET(CPACK_SYSTEM_NAME "Darwin")
SET(CPACK_TOPLEVEL_TAG "Darwin")
SET(CPACK_WIX_SIZEOF_VOID_P "8")

if(NOT CPACK_PROPERTIES_FILE)
  set(CPACK_PROPERTIES_FILE "/Users/narayan/workspace/mortar/ext/mtocpp/CPackProperties.cmake")
endif()

if(EXISTS ${CPACK_PROPERTIES_FILE})
  include(${CPACK_PROPERTIES_FILE})
endif()
