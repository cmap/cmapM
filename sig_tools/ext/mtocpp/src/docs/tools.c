/**
 * @page tools Configuration and use of mtoc++
 * @short Help on how to use the tools coming with mtoc++
 *
 * Make sure you have followed the @ref install.
 *
 * @par Contents
 * - @ref tools_doc
 *  - @ref tools_docmaker
 *  - @ref tools_direct
 *  - @ref tools_python
 * - @ref tools_config
 *  - @ref config_doxy
 *  - @ref config_mtocpp
 *  - @ref config_latex
 *
 * @section tools_doc Documentation creation
 * As \c mtoc++ itself is only a filter to plug into doxygen, there is little sense in calling the binaries directly.
 *
 * Thus, mtoc++ comes with a series of tools that take over the documentation generation process for different interfaces.
 *
 * Those tools can be found inside the \c <mtoc++-source-dir>/tools folder.
 *
 * @note At some stage you will need to have access to the involved binaries like \c doxygen, \c mtocpp, \c mtocpp_post or \c latex.
 * It is your responsibility to ensure the availability of the binaries in whatever environment you want to create the documentation.
 * The most obvious way is to place all binaries inside a directory contained in your local PATH variable (both unix/windows).
 * We've had reported issues with MAC users, that dont have the environment set when launching MatLab from the Dock. See @ref troubleshooting for more information.
 *
 * @subsection tools_docmaker Using the MatlabDocMaker
 * The most convenient way of using mtoc++ within your matlab project is to use the MatlabDocMaker class coming with mtoc++.
 * The MatlabDocMaker is a MatLab native class that can be directly used from within MatLab in order to create the project documentation.
 *
 * Follow these simple steps in order to quickly get your first documentation:
 * - Place the MatlabDocMaker.m file somewhere on your project's MatLab path.
 * - Change the MatlabDocMaker.getProjectName method to return your project's name
 * - Copy the contents of the \c <mtoc++-source-dir>/tools/config folder into e.g. a subfolder of your MatLab project
 * - Call the MatlabDocMaker.setup method and use the folder from the previous step as your "documentation configuration files directory".
 * - Use the MatlabDocMaker.create method to generate your documentation and look at it in a web browser.
 *
 * See the MatlabDocMaker class description for more details on how to use it.
 * @note You may of course keep the MatlabDocMaker.m and the configuration files where you initially placed your mtoc++ source and point to the
 * appropriate directories during setup.<br>
 * However, if you want to use multiple projects with mtoc++ you probably want to have different configurations for each project, so that is why we recommend to create local copies of your
 * tools and configuration within each project. (The MatlabDocMaker stores its setting dependent on the name you specify for the project!)<br>
 * The way the MatlabDocMaker works it can be easily inserted into whatever versioning system your project uses.
 * As it stores important folders in MatLab preferences each developer will still have his local documentation settings (after running MatlabDocMaker.setup on each machine, of course).
 *
 * @subsection tools_direct Using mtoc++ directly
 * Okay, so you're a crack and want to control everything. That's fine with us!
 * In this case we also assume you're familiar with whatever your operating environment is and you have solid knowledge of what's going on.
 * First, you could simply reverse-engineer what the MatlabDocMaker is doing (it automatically generates and inserts the correct scripts read by doxygen), otherwise, here are the basic steps required to get started with mtoc++ directly.
 * In short, this happens by including mtoc++ as a filter for *.m files:
 * - Compile things as necessary and make binaries accessible
 * - Modify your \c doxygen configuration file:
 *  - Setup your doxygen as usual, including the sources and output directories
 *  - Make \c doxygen parse Matlab files
 *  - Register mtoc++ as a filter for those files
 *  - If you have a custom mtocpp.conf you want mtoc++ to use, you need to create a shell/batch script that passes this file to mtoc++ and use this file as filter executable
 *  - Check if you are using latex-features of mtoc++, if so, add latex-support and provide necessary style files
 * - Run doxygen
 * - Run \c mtocpp_post passing the folder containing your HTML output as argument
 * - Look at some nice documentation, be happy!
 * - If your'e not happy, try starting with the provided Doxyfile.template in the \c tools/ directory and inserting proper values for all the placeholders we're using.
 * Everything related to mtoc++ has been put to the very bottom of the file, most critically:
 * @code
 * EXTENSION_MAPPING = .m=C++
 * INPUT             = _SourceDir_ _ConfDir_
 * FILE_PATTERNS     = *.m
 * FILTER_PATTERNS   = *.m="_ConfDir_`'_FileSep_`'_MTOCFILTER_"
 * @endcode
 * Here, the underscored values need to be replaced manually in order to insert the correct values.
 * Essentially:
 *  - \c EXTENSION_MAPPING tells doxygen to regard \c .m-Files as if they were \c C++ files, style-wise.
 *  - \c INPUT tells doxygen where to look for files.
 *  - \c FILE_PATTERNS lets doxygen also look for \c .m-Files.
 *  - \c FILTER_PATTERNS is the most important line of the configuration. Here, you need to define scripts that should be called by doxygen before certain files are processed.
 *
 * @subsection tools_python Using the python script from a unix shell
 * @todo python script, yet to come
 *
 * @section tools_config Configuring mtoc++ and doxygen
 *
 * As the configuration of doxygen/mtoc++ is independent from the actual tool used we will explain it separately.
 * The involved files can again be found inside the \c /tools/config folder.
 * - \c Doxyfile.template - @ref config_doxy
 * - \c mtocpp.conf - @ref config_mtocpp
 * - \c latexextras.template - @ref config_latex
 * - \c class_substitutes.c - @ref config_fakeclasses
 *
 *@attention USING MTOC++ DOES NOT EXCLUDE THE REQUIREMENT TO KNOW AND UNDERSTAND DOXYGEN ITSELF!<br>
 * The settings in the "Doxygen.template" file inside the \c /tools/config folder are a default
 * configuration for Doxygen which we thought might be useful in a MatLab setting/project and 
 * contains some changes in order to make mtoc++ run together with doxygen.
 * We've had lots of feedback and problem reports which actually had to do with settings purely
 * regarding doxygen, so we strongly recommend having a look through @ref config_doxy and the 
 * references therein before contacting us. Thanks!
 *
 * @subsection config_doxy Configuration options for doxygen
 * The \c Doxyfile.template file uses placeholders for specific folders etc. and contains any other configuration settings you want doxygen to use.
 * This way, the configuration files can be included into the versioning system as local developers paths are stored outside the configuration file
 * and are provided by the different tools coming with mtoc++.
 *
 * See http://www.stack.nl/~dimitri/doxygen/config.html for more information on doxygen configuration.
 *
 * @subsection config_mtocpp Configuration options for the mtoc++ filter
 * The file \c mtocpp.conf contains additional configuration for the mtoc++ parser.
 *
 * @note The mtoc++ filter takes exactly two arguments, of which the first is the file to process, and the second is an optional configuration file.
 * So if you dont want to customize mtoc++ because the default settings are just fine, there is nothing to do (you simply can set the filter target in doxygen to the \c mtocpp binary for the manual config case).
 * Otherwise, if you want to provide a config file to mtoc++, depending on your platform, you have to write a shell/batch script that
 * is included as filter callback in doxygen's configuration file. Inside the script, the first argument is forwarded to \c mtocpp
 * and the second configuration file path is provided statically in the script.<br>
 * We recommend to use the MatlabDocMaker tool described in @ref tools_docmaker, as it does all that for you.
 *
 * The following is a short list of options that can be specified in the configuration file for the mtoc++ filter.
 * All options are declared by the syntax @code <option> := <value> @endcode and are optional, as the default values are hardcoded into mtoc++.
 * - \c ALL - File Patterns
 * - \c PRINT_FIELDS - Flag indicating whether automatic struct fields or object member documentation is generated. Default \c true.
 * - \c AUTO_ADD_FIELDS - Flag indicating whether undocumented field names are added to documentation. Default \c false.
 * - \c AUTO_ADD_PARAMETERS - Flag indicating whether undocumented parameters and return values are added to documentation
 * with documentation text equal to the parameter / return value name. Default false.
 * - \c AUTO_ADD_CLASS_PROPERTIES - Flag indicating whether undocumented member variables are added to documentation
 * with documentation text equal to the parameter / return value name. Default false.
 * - AUTO_ADD_CLASSES - Flag indicating whether undocumented classes are added to documentation with documentation
 * text equal to the class name. Default \c true.
 * - REMOVE_FIRST_ARG_IN_ABSTRACT_METHODS - Flag indication whether the first argument in abstract non-static methods
 * shall be a this pointer, and therefore removed in the C++ output. Default \c true.
 * - ENABLE_OF_TYPE_PARSING - Flag indicating whether the string "of type" is parsed in the the first two lines of comments.
 * This is equivalent to the @@type tag, but makes the code more readable at some places. Default \c true.
 * - VOID_TYPE_IN_RETURN_VALUES - Flag indicating whether the typename void shall be inserted for return values with no specified type.
 * Default \c false.
 * PRINT_RETURN_VALUE_NAME - Integer flag indicating whether return value names shall be printed in the function synopsis.
 * If this flag is deactivated only the type names are written. The flag can be set to either 0, 1 or 2 and has default value \c 2:
 * 	- 0: means that no return value names shall be printed at all.
 * 	- 1: means that return value names shall be printed for return value lists with more than one element only.
 * 	- 2: means that return value names shall be printed always.
 *
 * Moreover, default descriptions/values for recurring entries like parameters or field names can be specified.
 *
 * @attention Note that the configuration file sections for variables above and rules below have to be separated
 * by a single line containing only a double hash '##'. ONLY use '##' for that purpose.
 *
 * @par Parameter default descriptions
 * Use the syntax
 * @code add(params) = 	<parameter1_name> => """Your parameter1 description text in triple quotes""",
 * 		<parameter2_name> => """Your parameter2 description text in triple quotes"""; @endcode
 * to add default descriptions to parameters of functions or class members.
 *
 * @par Struct field default descriptions
 * Use the syntax
 * @code add(fields) = <field_name> => """Your field description text in triple quotes"""; @endcode
 * to add default descriptions to fields of any struct or class (identified by a ".fieldname" syntax in the MatLab code)
 *
 * @par Extra documentation
 * Use
 * @code add(doc) = """ <some extra doc for all files> """; @endcode
 * to append some extra documentation to each class or files documentation.
 * Use
 * @code add(extra) = """ <text at end of comments> """; @endcode
 * to append text at the end of any comment.
 *
 * @par Global settings for specific files or folder groups
 * More advanced, those settings above can also be made on a group-based setting. The syntax
 * @code
 * glob = <folder or filename (regexp allowed)> {
 * 	<expressions as above>
 * 	glob = <subfolder or files> {
 * 		<expressions as above>
 * 	};
 * }
 * @endcode
 * can be used to specify groups of rules that are applied to any matching file or files in folders.
 * Nesting is possible, too.
 *
 * So for example,
 * @code glob = myfile.m { add(params) = param1 => """ param 1 description """; } @endcode
 * would cause mtoc++ to add the description "param 1 description" to any parameter called \c param1 of a method/function inside the file \c myfile.m.
 *
 * @attention Having common field names specified centrally is a quite convenient way to autogenerate documentation.
 * However, if you use e.g. the same parameter name in a different meaning and forget to explicitly specify the parameter documentation,
 * the default values will be inserted. This possibly leads to more confusion for users than it does help.
 * Furthermore, not specifiying the parameters in the local comments decreases readability of the code. One of mtoc++'s main advantages in
 * combination with doxygen is that code can be commented highly readable in-place!
 *
 * See the file itself for more detailed configuration options and examples.
 *
 * @subsection config_latex Extending default LaTeX environment for doxygen
 * The \c latexextras.template file is processed and included into the latex environment available to doxygen during the documentation creation.
 * Insert here any commands or packages that you want latex to know for your documentation formulas.
 *
 * @attention When having errors inside an LaTeX formula, doxygen will complain upon finishing and tell you to look
 * into the _formulas.log/.tex file in the documentation output folder. THIS WARNING COMES ONLY ONE TIME!
 * Upon the next creation run, only changed/new formulas will be re/generated.
 * We considered deleting all formula pngs before each re-creation, but decided not to do this for performance issues.
 * So just make sure you react to latex typos/errors immediately.
 *
 * The default packages that are included by the \c latexextras.template are
 * @code \usepackage{amsmath}
 * \usepackage{amssymb}
 * \usepackage{amsfonts}
 * \usepackage{subfig}
 * \usepackage{bbm} @endcode
 *
 * @subsection config_fakeclasses Fake classes for typical MatLab data types
 * The file \c class_substitutes.c includes some class descriptions for typical MatLab data types like handle or logical, but also introduces
 * custom types like colvec or rowvec that can be used with the @@type tag for property, parameter or return value types.
 *
 * Add new classes to this file or change existing ones as you need.
 */
