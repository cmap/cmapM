# This file will be configured to contain variables for CPack. These variables
# should be set in the CMake list file of the project before CPack module is
# included. Example variables are:
#   CPACK_GENERATOR                     - Generator used to create package
#   CPACK_INSTALL_CMAKE_PROJECTS        - For each project (path, name, component)
#   CPACK_CMAKE_GENERATOR               - CMake Generator used for the projects
#   CPACK_INSTALL_COMMANDS              - Extra commands to install components
#   CPACK_INSTALL_DIRECTORIES           - Extra directories to install
#   CPACK_PACKAGE_DESCRIPTION_FILE      - Description file for the package
#   CPACK_PACKAGE_DESCRIPTION_SUMMARY   - Summary of the package
#   CPACK_PACKAGE_EXECUTABLES           - List of pairs of executables and labels
#   CPACK_PACKAGE_FILE_NAME             - Name of the package generated
#   CPACK_PACKAGE_ICON                  - Icon used for the package
#   CPACK_PACKAGE_INSTALL_DIRECTORY     - Name of directory for the installer
#   CPACK_PACKAGE_NAME                  - Package project name
#   CPACK_PACKAGE_VENDOR                - Package project vendor
#   CPACK_PACKAGE_VERSION               - Package project version
#   CPACK_PACKAGE_VERSION_MAJOR         - Package project version (major)
#   CPACK_PACKAGE_VERSION_MINOR         - Package project version (minor)
#   CPACK_PACKAGE_VERSION_PATCH         - Package project version (patch)

# There are certain generator specific ones

# NSIS Generator:
#   CPACK_PACKAGE_INSTALL_REGISTRY_KEY  - Name of the registry key for the installer
#   CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS - Extra commands used during uninstall
#   CPACK_NSIS_EXTRA_INSTALL_COMMANDS   - Extra commands used during install


SET(CPACK_BINARY_BUNDLE "")
SET(CPACK_BINARY_CYGWIN "")
SET(CPACK_BINARY_DEB "")
SET(CPACK_BINARY_DRAGNDROP "")
SET(CPACK_BINARY_NSIS "")
SET(CPACK_BINARY_OSXX11 "")
SET(CPACK_BINARY_PACKAGEMAKER "")
SET(CPACK_BINARY_RPM "")
SET(CPACK_BINARY_STGZ "")
SET(CPACK_BINARY_TBZ2 "")
SET(CPACK_BINARY_TGZ "")
SET(CPACK_BINARY_TZ "")
SET(CPACK_BINARY_ZIP "")
SET(CPACK_CMAKE_GENERATOR "Unix Makefiles")
SET(CPACK_COMPONENT_UNSPECIFIED_HIDDEN "TRUE")
SET(CPACK_COMPONENT_UNSPECIFIED_REQUIRED "TRUE")
SET(CPACK_DEBIAN_PACKAGE_SECTION "devel")
SET(CPACK_DEBIAN_PACKAGE_SUGGESTS "doxygen")
SET(CPACK_GENERATOR "TGZ")
SET(CPACK_IGNORE_FILES "/CVS/;/\\.svn/;\\.swp$;\\.git/;\\.gitignore;build/;")
SET(CPACK_INSTALLED_DIRECTORIES "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp;/")
SET(CPACK_INSTALL_CMAKE_PROJECTS "")
SET(CPACK_INSTALL_PREFIX "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp")
SET(CPACK_MODULE_PATH "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp/cmake")
SET(CPACK_NSIS_DISPLAY_NAME "MTOC++ 1.5.1")
SET(CPACK_NSIS_INSTALLER_ICON_CODE "")
SET(CPACK_NSIS_INSTALLER_MUI_ICON_CODE "")
SET(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")
SET(CPACK_NSIS_PACKAGE_NAME "MTOC++ 1.5.1")
SET(CPACK_OUTPUT_CONFIG_FILE "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build/CPackConfig.cmake")
SET(CPACK_PACKAGE_CONTACT "Martin Drohmann <mdrohmann@uni-muenster.de>, Daniel Wirtz <daniel.wirtz@mathematik.uni-stuttgart.de>")
SET(CPACK_PACKAGE_DEFAULT_LOCATION "/")
SET(CPACK_PACKAGE_DESCRIPTION "This package includes two programs to build beautiful Doxygen documentation
  for Matlab projects. The filter program 'mtocpp' transforms relevant parts of
  the M-Files into C++ syntax, which can be parsed by doxygen. The generated
  html files can be processed by the program 'postprocess' in order to generate
  documentation looking more like Matlab.")
SET(CPACK_PACKAGE_DESCRIPTION_FILE "/xchip/cogs/tools/bin/share/cmake-2.8/Templates/CPack.GenericDescription.txt")
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Doxygen filter for Matlab M-files and scripts")
SET(CPACK_PACKAGE_FILE_NAME "MTOC++-1.5.1-Source")
SET(CPACK_PACKAGE_INSTALL_DIRECTORY "MTOC++ 1.5.1")
SET(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "MTOC++ 1.5.1")
SET(CPACK_PACKAGE_NAME "MTOC++")
SET(CPACK_PACKAGE_RELOCATABLE "true")
SET(CPACK_PACKAGE_VENDOR "MDDW")
SET(CPACK_PACKAGE_VERSION "1.5.1")
SET(CPACK_PACKAGE_VERSION_MAJOR "1")
SET(CPACK_PACKAGE_VERSION_MINOR "5")
SET(CPACK_PACKAGE_VERSION_PATCH "1")
SET(CPACK_RESOURCE_FILE_LICENSE "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp/License.txt")
SET(CPACK_RESOURCE_FILE_README "/xchip/cogs/tools/bin/share/cmake-2.8/Templates/CPack.GenericDescription.txt")
SET(CPACK_RESOURCE_FILE_WELCOME "/xchip/cogs/tools/bin/share/cmake-2.8/Templates/CPack.GenericWelcome.txt")
SET(CPACK_SET_DESTDIR "OFF")
SET(CPACK_SOURCE_CYGWIN "")
SET(CPACK_SOURCE_GENERATOR "TGZ")
SET(CPACK_SOURCE_IGNORE_FILES "/CVS/;/\\.svn/;\\.swp$;\\.git/;\\.gitignore;build/;")
SET(CPACK_SOURCE_INSTALLED_DIRECTORIES "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp;/")
SET(CPACK_SOURCE_OUTPUT_CONFIG_FILE "/xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build/CPackSourceConfig.cmake")
SET(CPACK_SOURCE_PACKAGE_FILE_NAME "MTOC++-1.5.1-Source")
SET(CPACK_SOURCE_TBZ2 "")
SET(CPACK_SOURCE_TGZ "")
SET(CPACK_SOURCE_TOPLEVEL_TAG "Linux-Source")
SET(CPACK_SOURCE_TZ "")
SET(CPACK_SOURCE_ZIP "")
SET(CPACK_STRIP_FILES "")
SET(CPACK_SYSTEM_NAME "Linux")
SET(CPACK_TOPLEVEL_TAG "Linux-Source")
