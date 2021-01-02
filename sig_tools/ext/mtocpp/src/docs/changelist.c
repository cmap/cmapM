/**
 * @page changes Changes and new features in mtoc++
 * @short Changelog and new feature list for mtoc++
 *
 * Here are all the changes/new features sorted by versions of mtoc++:
 * - @subpage newfeat0_1  - @subpage changelog0_1
 * - @subpage newfeat1_2  - @subpage changelog1_2
 * - @subpage newfeat1_3  - @subpage changelog1_3
 * - @subpage newfeat1_4  - @subpage changelog1_4
 * - @subpage newfeat1_5  - @subpage changelog1_5
 *
 * @attention The repeated occurence of the new features/changes in this
 * specific site below is just due to the fact that the mtoc++ features/changes
 * themselves have to be written down somewhere. Under usual circumstances
 * those tags below would be placed inside the MatLab files/functions/classes
 * where the actual change happened; see the comments from the MatlabDocMaker
 * as an example. So the list below is not necessarily complete, but the sites
 * referenced above contain all new features / changes!
 *
 * @new{1,5,dw,2013-02-21} Added '*.mex' files to the types of files parsed by default in Doxyfile.template
 *
 * @change{1,4,dw,2012-10-17}
 * - Using the new css-style from doxygen 1.8 for own docs
 * - Added some troubleshooting feedback
 * - Checked the CMake procedure on a Mac platform (MacBook pro), worked neatly.
 * - Added an extra section @ref tools_direct for instructions on how to directly use mtoc++
 * - Fixed broken links to MatLab method/property attributes in mtoc++ output
 * 
 * @change{1,4,dw,2012-09-27} Optimized compilation under Visual Studio 2010, now can also build the mtoc++ documentation locally.
 *
 * @change{1,4,md,2012-09-27}
 * - Added check for HAVE_DOT in doxygen.conf.in
 * - Bugfix for function-only M-files reported by Francois Rongere
 *
 * @new{1,4,md,2012-02-17}
 *- Started mtoc++ 1.4.
 *- Added alias for an "events" tag, creating a page of all events in default documentation
 *- Changed naming convention for alias-tags new and change as newer doxygen
 *  versions seem not to recognize \1\2-like combinations of arguments any more (?)
 *  now pages named "newfeat\1_\2" with underscore are created, please update your static
 *  references in your misc documentation files
 *
 * @change{1,3,dw,2012-01-16} Changed the \c SHOW_FILES default value in the
 * doxygen configuration file from "NO" to "YES".
 *
 * @change{1,3,dw,2012-01-16} Bugfix: The setting \c EXTRA_PACKAGES in the
 * doxygen configuration file was given the wrong path format, as latex follows
 * the unix file separation using only forwardslashes "/", so the inclusion
 * failed on Windows platforms.  We fixed this by passing the correctly
 * transformed path. Also a new placeholder "_FileSep_" which is being
 * processed by MatlabDocMaker (any any tools to come) and set to the correct
 * file separator character for your platform.
 *
 * @change{1,3,dw,2012-01-14} Bugfix: Moved the mtoc++ developers page
 * declaration into a separate file inside the tools/config folder, so that
 * error messages like "changelog1:13: warning: unable to resolve reference to
 * `dw' for \ref command" do not appear anymore.
 *
 * @change{1,3,dw,2011-12-08} Bugfix: The CUSTOM_DOC_DIR path is not longer
 * extended by a \c docs/ folder.
 *
 * @change{1,3,dw,2011-11-29} Added the new fake classes varargin and varargout
 * to the class_substitutes.c file with links to the MatLab online
 * documentation.
 *
 * @new{1,3,dw,2011-11-28} Started mtoc++ 1.3.
 *
 * @new{1,2,dw,2011-11-27} Reordered the Doxyfile.m4 so that changes from our
 * side are all collected to the bottom. This makes keeping custom settings 
 * over different versions easier.
 *
 * @new{1,2,dw,2011-11-25} Included a file class_substitutes.c into the config
 * directory that introduces fake classes for common matlab data types.
 *
 * @change{1,2,md,2011-11-17} Updated the test reference files
 *
 * @new{1,2,dw,2011-11-07} Created the initial mtoc++ documentation structure
 *
 * @change{1,2,dw,2011-11-07} Reordered the source code files and tools in more
 * concise folders.
 *
 * @page newfeat0_1 New features in mtoc++ 0.1
 * @short Demo features of the demo classes and examples
 *
 * See also @ref changelog0_1
 *
 * @page changelog0_1 Changes in mtoc++ 0.1
 * @short Demo changes of the demo classes and examples
 *
 * See also @ref newfeat0_1
 *
 * @page newfeat1_2 New features in mtoc++ 1.2
 * @short First "stable" release with windows/unix support.
 *
 * See also @ref changelog1_2
 *
 *
 * @page changelog1_2 Changes in mtoc++ 1.2
 * @short First "stable" release with windows/unix support.
 *
 * See also @ref newfeat1_2
 *
 * @page newfeat1_3 New features in mtoc++ 1.3
 * @short Improved stability for Windows platforms, event handling
 *
 * See also @ref changelog1_3
 *
 * @page changelog1_3 Changes in mtoc++ 1.3
 * @short Improved stability for Windows platforms, event handling
 *
 * See also @ref newfeat1_3
 *
 * @page newfeat1_4 New features in mtoc++ 1.4
 * @short Included basic source browsing, handling of varargin-parameters, basic LaTeX generation support
 *
 * See also @ref changelog1_4
 *
 * @page changelog1_4 Changes in mtoc++ 1.4
 * @short Many bugfixes due to detailed feedback! Thanks!
 *
 * See also @ref newfeat1_4
 *
 * @page newfeat1_5 New features in mtoc++ 1.5
 * @short Current development
 *
 * See also @ref changelog1_5
 *
 * @page changelog1_5 Changes in mtoc++ 1.5
 * @short Current development
 *
 * See also @ref newfeat1_5
 */
