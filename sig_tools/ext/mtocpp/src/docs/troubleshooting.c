/**
 * @page troubleshooting Troubleshooting mtoc++
 * @short Some hopefully useful hints when things dont go as they should!
 *
 * @section ts_config Configuration
 * @attention The first and most important message: <b>KNOWLEDGE OF DOXYGEN IS ESSENTIAL!</b>
 *
 * mtoc++ is designed as a filter for MatLab m-files, so that they can be processed by doxygen as if they were C source files.
 * Everything else regarding tags, conventions and possible formatting of display is completely defined by Doxygen.
 * So, unless explicitly explained as "feature" of mtoc++ here, one should look into Doxygen's <a href="http://www.stack.nl/~dimitri/doxygen/manual.html" target="_blank">documentation pages</a>
 * first before complaining about some stuff that mtoc++ surprisingly cannot do.
 *
 * Check out the @ref tools_direct section for details on how mtoc++ works.
 *
 * @section ts_path Issues finding binaries (MAC)
 * Thanks to a report from K. Kearney to resolve path issues on MAC platforms:
 *
 * "After building, I added \c <mydir>/mtoc++_1.4/tools to my Matlab path and tried to run MacDocMaker.setup. I encountered an issue where Matlab couldn't locate either mtocpp or latex. I think this is a Mac-specific issue; when you start Matlab in the standard way, from the Dock (rather than through the command-line matlab command), the shell it starts doesn't run any configuration scripts (.bashrc, .back_profile, etc) or set system paths. I think some versions of Matlab have a .matlabrc.sh file that can be modified to set a PATH, and I've seen something on the newsgroup about .plist files, but I just force the Matlab shell it to match my other Terminal sessions by adding the following lines to the top of the matlab shell script (<matlabroot>/bin/matlab):
 * @code
 *  source ~/.bash_profile
 *  source /etc/bashrc
 *  source /etc/profile@endcode
 *
 * With that change (and after restarting Matlab), I was able to successfully run MatlabDocMaker.setup, and then MatlabDocMaker.create on a test directory."
 *
 * @section ts_debug Debugging mtoc++
 * For hard cases like segfaults there is also hope!
 *
 * You can build your mtoc++ binaries with the \c Debug build type (starting in the source folder):
 * @code
 * mkdir build
 * cd build
 * cmake -DCMAKE_BUILD_TYPE=Debug ..
 * make
 * @endcode
 * Then, send the compiled binaries along with the used source code to us and we will try to figure out what the heck is wrong with it!
 */ 