# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 2.8

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canoncical targets will work.
.SUFFIXES:

# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list

# Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /xchip/cogs/tools/bin/bin/cmake

# The command to remove a file.
RM = /xchip/cogs/tools/bin/bin/cmake -E remove -f

# The program to use to edit the cache.
CMAKE_EDIT_COMMAND = /xchip/cogs/tools/bin/bin/ccmake

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /xchip/cogs/narayan/code/github/mortar/ext/mtocpp

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build

# Utility rule file for ContinuousStart.

CMakeFiles/ContinuousStart:
	/xchip/cogs/tools/bin/bin/ctest -D ContinuousStart

ContinuousStart: CMakeFiles/ContinuousStart
ContinuousStart: CMakeFiles/ContinuousStart.dir/build.make
.PHONY : ContinuousStart

# Rule to build all files generated by this target.
CMakeFiles/ContinuousStart.dir/build: ContinuousStart
.PHONY : CMakeFiles/ContinuousStart.dir/build

CMakeFiles/ContinuousStart.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/ContinuousStart.dir/cmake_clean.cmake
.PHONY : CMakeFiles/ContinuousStart.dir/clean

CMakeFiles/ContinuousStart.dir/depend:
	cd /xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /xchip/cogs/narayan/code/github/mortar/ext/mtocpp /xchip/cogs/narayan/code/github/mortar/ext/mtocpp /xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build /xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build /xchip/cogs/narayan/code/github/mortar/ext/mtocpp/build/CMakeFiles/ContinuousStart.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/ContinuousStart.dir/depend

