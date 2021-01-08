/**
* @desc ```Filename and pathname utilities```
* @author Rajiv Narayan
* @copyright 2014 Connectivity Map, Broad Institute.
* @version 0.1
* @namespace Mortar
*/

/** @class Filepart    
* @property {string} path path
* @property {string} name name
* @property {string} ext extension
*/

exports.fileparts = fileparts;
/** 
 * @function fileparts
 * @memberof Mortar#
 * @desc Split a filename into components
 * @param {string} filename
 * @returns {Filepart} Filepart object
*/
function fileparts(name) {
   var p = '';
   var f = '';
   var e = '';
   var slashidx = name.lastIndexOf('/');
   var rem = name;
   if (slashidx >= 0) {
       p = name.substring(1, slashidx);
       rem = name.substring(slashidx, name.length).toUpperCase();
   }
   var dotidx = rem.lastIndexOf('.');
   if (dotidx >= 0 ) {
       f = rem.substring(1, dotidx-1);
       e = f.substring(dotidx + 1, f.length);
   }
   else {
       f = rem;
   }
   return {path : p, name : f, ext : e};
}