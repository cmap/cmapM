//Public
exports.parseList = parseList;

/**
 * @function parseList
 * @memberof Mortar#
 * @desc ```Reads lines from string input```
 * @param {String} String with newlines
 * @returns {Array<String>} 
 */
function parseList(raw) {
 raw = raw.replace(/(\r\n|\n|\r)+/gi, '\n');
 var lines = raw.split('\n');
 // drop the last empty line
 if (lines[lines.length-1] === "") {
  lines.splice(lines.length-1, 1);
 }
 return lines;
}