# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.2

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
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
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.2.3/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.2.3/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/narayan/workspace/mortar/ext/mtocpp

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/narayan/workspace/mortar/ext/mtocpp

# Utility rule file for documentation_pdf.

# Include the progress variables for this target.
include CMakeFiles/documentation_pdf.dir/progress.make

CMakeFiles/documentation_pdf:
	$(CMAKE_COMMAND) -E cmake_progress_report /Users/narayan/workspace/mortar/ext/mtocpp/CMakeFiles $(CMAKE_PROGRESS_1)
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold "Creating PDF documentation... (see /Users/narayan/workspace/mortar/ext/mtocpp/docs/latex/refman.log for latex errors/warnings)"
	cd /Users/narayan/workspace/mortar/ext/mtocpp/docs/latex && make
	cd /Users/narayan/workspace/mortar/ext/mtocpp/docs/latex && /usr/local/Cellar/cmake/3.2.3/bin/cmake -E copy /Users/narayan/workspace/mortar/ext/mtocpp/docs/latex/refman.pdf /Users/narayan/workspace/mortar/ext/mtocpp/docs/manual.pdf
	cd /Users/narayan/workspace/mortar/ext/mtocpp/docs/latex && /usr/local/Cellar/cmake/3.2.3/bin/cmake -E echo PDF\ docs\ at\ /Users/narayan/workspace/mortar/ext/mtocpp/docs/manual.pdf!
	cd /Users/narayan/workspace/mortar/ext/mtocpp/docs/latex && /usr/local/Cellar/cmake/3.2.3/bin/cmake -E remove_directory /Users/narayan/workspace/mortar/ext/mtocpp/docs/latex/

documentation_pdf: CMakeFiles/documentation_pdf
documentation_pdf: CMakeFiles/documentation_pdf.dir/build.make
.PHONY : documentation_pdf

# Rule to build all files generated by this target.
CMakeFiles/documentation_pdf.dir/build: documentation_pdf
.PHONY : CMakeFiles/documentation_pdf.dir/build

CMakeFiles/documentation_pdf.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/documentation_pdf.dir/cmake_clean.cmake
.PHONY : CMakeFiles/documentation_pdf.dir/clean

CMakeFiles/documentation_pdf.dir/depend:
	cd /Users/narayan/workspace/mortar/ext/mtocpp && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/narayan/workspace/mortar/ext/mtocpp /Users/narayan/workspace/mortar/ext/mtocpp /Users/narayan/workspace/mortar/ext/mtocpp /Users/narayan/workspace/mortar/ext/mtocpp /Users/narayan/workspace/mortar/ext/mtocpp/CMakeFiles/documentation_pdf.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/documentation_pdf.dir/depend

