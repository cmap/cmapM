/**
  @class
  @name Table
  @property {Integer} nrow Number of rows
  @property {Integer} ncol Number of columns
  @property {Array.<string>} data Table content as an array of string arrays
  @property {Array} header Header names
  @property {Object} header_lut Lookup table of header names to column index
*/

var http = require('http');
var babyparse = require('babyparse');

var list = require('./list'),
    util = require('./util');

// Public
exports.parse = parse;
exports.parseBuffer = parseBuffer;
exports.parseTable = parseTable;
exports.insertColumnIndex = insertColumnIndex;
exports.splitTable = splitTable;
exports.leftJoin = leftJoin;
exports.innerJoin = innerJoin;
exports.rightJoin = rightJoin;
exports.outerJoin = outerJoin;

function parseBuffer(buf, delimiter, callback) {
    babyparse.parse(buf, {delimiter: delimiter,
			  header: false,
			  download:false,
			  skipEmptyLines:true,
			  complete: function(res) {
			      var header = res.data.splice(0,1)[0];
			      return(makeTable(res.data, header));
/*			      if (callback && typeof(callback) === "function") {
				  callback(makeTable(res.data, header));
			      }*/
			  }
			 });
}

/**
 * ```Read table data delimited by dlm.```
 * @function parseTable
 * @param {string} raw data from an XHR call
 * @param {string} dlm delimiter. Default is '\t'
 * @param {boolean} has_header Expects that the first line is a header if true. Default is true
 * @returns {Table} Table object
*/
function parse(url, dlm, has_header, callback) {
    http.get(url,
	     function(res) {
		 var buffer ='';
		 res.on('data', function(chunk){ 
		     buffer += chunk;
		 });
		 res.on('end', function () {		     
		     if (callback && typeof(callback)==='function') {
			 callback(parseTable(buffer, dlm, has_header))
		     };
		     /*parseBuffer(buffer, dlm, function(res){
			 if (callback && typeof(callback) === "function") {
			     callback(res);
			 }
		     })*/
		 });
		 res.on('error', function (e) {
		     console.log('ERROR parsing table: ' + url + e.message);
		 });
	     }
	    );
}

function parseTable(raw, dlm, has_header) {      
    var i;
    dlm = util.pick(dlm, '\t');
    has_header = util.pick(has_header, true);
    var lines = list.parseList(raw);
    var table = {'nrow':0, 'ncol':0, 'data':[], 'header':[], 'header_lut':[]};
    for (i=(has_header ? 1 : 0); i<lines.length; i++) {
	table.data.push(lines[i].split(dlm));
    }
    table.nrow = table.data.length;
    table.ncol = table.data[0].length;
    if (has_header) {
	table.header = lines[0].split(dlm);
    }
    else {
	for (i=0; i<table.ncol; i++){
	    table.header.push('COL_'+i);
	} 
    }
    table.header_lut = util.list2index(table.header);
    return table;
}


/**
 * ```Perform a left join of two tables.```
 * @function leftJoin
 * @param {object} table Table object returned by parseTable
 * @param {object} table Table object returned by parseTable
 * @param {string} primaryKey
 * @param {string} foreignKey
 * @param {string} selectFields List of fieldnames to keep in the join
 * @returns {Table} Object of Table objects
*/
function leftJoin(p, f, primaryKey, foreignKey, selectFields) {
  var np = p.nrow, nf = f.nrow, index = {}, jdata=[];
  
   // column index of primary key
   var pki = p.header_lut[primaryKey];

    // Construct lookup of values from primary table
    // Note: duplicates are ignored
    for (var i=0; i<np; i++) {
     var row = p.data[i];
     index[row[pki]] = i;
    }

   var fki = f.header_lut[foreignKey];
   // keep track of shared values in both tables
   //var sharedValues = {};
   for (var i=0; i<nf; i++) {
     var rowf = f.data[i];
     //sharedValues[rowf[fki]]=i;
     if (rowf[fki] in index) {
       var rowp = p.data[index[rowf[fki]]];
       //mark as done in index
       index[rowf[fki]] = -1;
       jdata.push(joinFields(rowp, rowf, selectFields, p.header_lut, f.header_lut));
    }
   }

    // add rows for unmatched values from primary table
    for (var k in index) {
     if (index[k] >=0) {
       jdata.push(joinFields(p.data[index[k]], [], selectFields, p.header_lut, {}));
     }
   }

   var j = makeTable(jdata, selectFields);
   return j;
}

/**
 * ```Perform a right join of two tables.```
 * @function rightJoin
 * @param {object} table Table object returned by parseTable
 * @param {object} table Table object returned by parseTable
 * @param {string} primaryKey
 * @param {string} foreignKey
 * @param {string} selectFields List of fieldnames to keep in the join
 * @returns {Table} Object of Table objects
*/
function rightJoin(p, f, primaryKey, foreignKey, selectFields) {
  return leftJoin(f, p, foreignKey, primaryKey, selectFields);
}

/**
 * ```Perform a outer join of two tables.```
 * @function outerJoin
 * @param {object} table Table object returned by parseTable
 * @param {object} table Table object returned by parseTable
 * @param {string} primaryKey
 * @param {string} foreignKey
 * @param {string} selectFields List of fieldnames to keep in the join
 * @returns {Table} Object of Table objects
*/
function outerJoin(p, f, primaryKey, foreignKey, selectFields) {
  var np = p.nrow, nf = f.nrow, pindex = {}, findex = {}, jdata=[];
  
   // column index of primary key
   var pki = p.header_lut[primaryKey];

    // Construct lookup of values from primary table
    // Note: duplicates are ignored
    for (var i=0; i<np; i++) {
     var row = p.data[i];
     pindex[row[pki]] = i;
    }

   var fki = f.header_lut[foreignKey];
    // add foreign table values to index
    for (var i=0; i<nf; i++) {
     var row = f.data[i];
     findex[row[fki]] = i;
    }

    for (var k in pindex) {
      var rowp = p.data[pindex[k]];
      if (k in findex) {
        // value exists in foreign table
        var rowf = f.data[findex[k]];
        jdata.push(joinFields(rowp, rowf, selectFields, p.header_lut, f.header_lut));
        findex[k] = -1;
      } else {
        // push data from primary table
        jdata.push(joinFields(rowp, [], selectFields, p.header_lut, {}));
      }
    }

    // add unmatched rows from foreign table
    for (var k in findex) {
     if (findex[k] >=0) {      
       jdata.push(joinFields([], f.data[findex[k]], selectFields, {}, f.header_lut));
     }
   }

   var j = makeTable(jdata, selectFields);
   return j;
}

/**
 * ```Perform an inner join of two tables.```
 * @function innerJoin
 * @param {object} table Table object returned by parseTable
 * @param {object} table Table object returned by parseTable
 * @param {string} primaryKey
 * @param {string} foreignKey
 * @param {string} selectFields List of fieldnames to keep in the join
 * @returns {Table} Object of Table objects
*/
function innerJoin(p, f, primaryKey, foreignKey, selectFields) {
  var np = p.nrow, nf = f.nrow, index = {}, jdata=[];
  
   // column index of primary key
   var pki = p.header_lut[primaryKey];

    // Construct lookup of primary key indices
    for (var i=0; i<np; i++) {
     var row = p.data[i];
     index[row[pki]] = i;
   }

   var fki = f.header_lut[foreignKey];
   for (var i=0; i<nf; i++) {
     var rowf = f.data[i];
     var rowp = p.data[index[rowf[fki]]];
     jdata.push(joinFields(rowp, rowf, selectFields, p.header_lut, f.header_lut));
   }
   var j = makeTable(jdata, selectFields);
   return j;
 }

 function makeTable(data, fields) {
  var header_lut = util.list2index(fields);
  return {'nrow':data.length, 
  'ncol':fields.length, 
  'data':data, 
  'header':fields, 
  'header_lut':header_lut};
}

/**
 * ```retain specified fields given two table rows.```
 * @function joinFields
 * @param {Array} rowp Row from primary table
 * @param {Array} rowf Row from foreign table
 * @param {Array} keepfield Array of fields to retain from both tables
 * @param {Array} ph_lut Object of fields to column indices for primary table
 * @param {Array} fh_lut Object of fields to column indices for foreign table
*/
function joinFields(rowp, rowf, keepfield, ph_lut, fh_lut) {
    var nk = keepfield.length, join=[];
    for (var i=0; i<nk; i++){
	if (keepfield[i] in ph_lut) {
	    join.push(rowp[ph_lut[keepfield[i]]]);
	}
	else if (keepfield[i] in fh_lut) { 
	    join.push(rowf[fh_lut[keepfield[i]]]);
	}
	else {join.push([])};
    }
    return join;
}
 
/**
 * ```Split a table by a given field.```
 * @function splitTable
 * @param {object} table Table object returned by parseTable
 * @param {string} split_by Fieldname to split by    
 * @returns {Table} Object of Table objects
*/
function splitTable(table, split_by) {
  var split = {};
  var cidx = table.header_lut[split_by];
  var i=0, row;
  for (i=0; i<table.data.length; i++) {
    row = table.data[i];
    if (split[row[cidx]]===undefined) {
      split[row[cidx]] = {nrow:0, ncol:0, data:[], header:[], header_lut:[]};
    }
    split[row[cidx]].data.push(row);
  }
  
  for (var key in split){
    split[key].nrow = split[key].data.length;
    split[key].ncol = table.data.length;
    split[key].header = table.header;
    split[key].header_lut = table.header_lut;
  }

  return split;
}

/** 
* ```Prepends an index column to a table```
* @function insertColumnIndex
* @param {object} table Table object
* @param {string} column_name Name of inserted column
* @returns {Table} table Table object with inserted column
*/
function insertColumnIndex(table, column_name) {
  for (i=0; i<table.data.length; i++) {
    table.data[i]=[i+1].concat(table.data[i]);
  }
  table.header = [column_name].concat(table.header);
  table.header_lut = util.list2index(table.header);    
  return table;  
}
