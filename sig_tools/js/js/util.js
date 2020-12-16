// Public
exports.list2index = list2index;
exports.pick = pick;

/**
 * @function list2index
 * @memberof Mortar#
 * @desc ```Generate lookup table for an array of values to their zero-indexed position 
 * in the array.```
 * Note: in the case of duplicate values, the index of the last 
 * occurrence of the element is returned.
 * @param {Array} array of values.
 * @returns {Object} object of values to zero-based array indices
 */

function list2index(list) {
  var lut = {};
  var i;
  for (i = 0; i<list.length; i++) {
      lut[list[i]] = i;
  }
  return lut;
}

/**
 * @function pick
 * @memberof Mortar#
 * @desc ```Returns arg if defined else return def```
 * @param arg argument
 * @param def default
 * @returns value
 * 
 */
function pick(arg, def) {
  return (typeof arg == 'undefined' ? def : arg);
}