/** @page tips Tips for doxygen usage with mtoc
 *
 * @section tip_versioning Feature and change tracking information
 *
 *  @subsection dg_featchange New feature and change log commands
 *  New features can be tracked version-based via using
 *  @verbatim
 *  @new{<mainversionnumber>, <mainversionnumber>, <developerkey>[, <date>]} <description>
 *  @endverbatim
 * 
 *  For example, writing
 *  @verbatim
 *  @new{0,1,dw} Added a fancy new feature! (New feature Example)
 *  @endverbatim
 *  results in
 *  @new{0,1,dw} Added a fancy new feature! (New feature Example)
 * 
 *  To include a date write
 *  @verbatim
 *  @new{0,1,dw,2011-01-01} Added a fancy new feature on new year's! (New feature Example)
 *  @endverbatim
 *  results in
 *  @new{0,1,dw,2011-01-01}  Added a fancy new feature on new year's! (New feature Example)
 * 
 *  and a new related page called @ref newfeat01 listing these
 *  items. To refer to that Changelog page, use the keyword 'newfeat'
 *  together with both plainly concatenated numbers:
 *  @verbatim
 *  @ref newfeat01
 *  @endverbatim
 *  gives @ref newfeat01
 * 
 *  Changes can be tracked version-based via using
 *  @verbatim
 *  @change{<mainversionnumber>, <mainversionnumber>, <developerkey>[, <date>]} <change-text>
 *  @endverbatim
 * 
 *  For example, writing
 *  @verbatim
 *  @change{0,1,dw} Changed foo to bar! (Changelog Example)
 *  @endverbatim
 *  results in
 *  @change{0,1,dw} Changed foo to bar! (Changelog Example)
 * 
 *  The optional date works same as with the '@@new' command. The
 *  related page keys for changes are composed by the keyword 'changelog'
 *  and both plainly concatenated numbers (similar to the new feature
 *  keys).
 * 
 *
 */
