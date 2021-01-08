(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({"./js/digest.js":[function(require,module,exports){
var table = require('./table');

// URLs to support pages, keyed by HELPID
var _help_url = {
  query_results : "http://support.lincscloud.org/hc/en-us/articles/202231633-Query-App-Results"
};
    
// Public
exports.updateHelpURL = updateHelpURL;
exports.dtQueryPreview = dtQueryPreview;
exports.dtConnectionDigestIndex = dtConnectionDigestIndex;
exports.dtConnectionDigest = dtConnectionDigest;
exports.parseTable = table.parseTable;
/**
* @function updateHelpURL
* @desc ```Updates support hyperlink(s) in a page.```    
Expects the link to have a classname 'help_url-HELPID' 
where HELPID is an internal identifier to the support page.
*/ 
function updateHelpURL(){
  $("a[class^=help_url-]").each(function() {
    var url_name = this.className.replace('help_url-','');
    $('a.'+this.className).prop('href', _help_url[url_name]);  
  }); 
}

/** 
* @function dtQueryPreview
* @desc ```Parses raw dlm separated data and populates a 
* datatable with top connections to a query```
*/
function dtQueryPreview(obj) {
    var tbl = table.parseTable(obj.raw_data, '\t', true);
    var col = [];
    
    for (var i in tbl.header) {
       col.push({sTitle: tbl.header[i]});
    }

    $(obj.target).dataTable({
       aaData: tbl.data,
       aoColumns: col,
       aaSorting: [[tbl.header_lut[obj.sort_field],
            obj.sort_order]],
       "bJQueryUI" : true, // jqui theme
       "sDom" : "RfrtiS", // infinite scrolling, reorder columns
       "bScrollCollapse": true,
       "sScrollY": "450px", 
       "sScrollX": true 
       });
}

/** 
* @function dtConnectionDigestIndex
* @desc Populates Connection digest index    
*/
function dtConnectionDigestIndex(obj) {
    var digest = table.parseTable(obj.raw_data, '\t', true);
    var col = [];
    for (var i in digest.header) {
       col.push({sTitle: digest.header[i]});
    }

    var aoColumnDefs = [];
    if (obj.link_source) {
      if ((typeof digest.header_lut[obj.link_source] != "undefined") && 
          (typeof digest.header_lut[obj.link_target] != "undefined")) {
          aoColumnDefs = [
          {targets: digest.header_lut[obj.link_source], visible: false},
          {targets: digest.header_lut[obj.link_target], 
            "render": function(data,type, row) { 
                return '<a href='+obj.base_url+row[digest.header_lut[obj.link_source]]+'>'+data + '</a>';
                }
          }
          ];
        }
        else {
          console.log('Error inserting links:'+obj.link_source+'->'+obj.link_target);
        }
      }
    
    var dt = $(obj.target).dataTable({
       aaData: digest.data,
       aoColumns: col,
       aoColumnDefs: aoColumnDefs,
       aaSorting: [[digest.header_lut[obj.sort_field],
            obj.sort_order]],
       "bJQueryUI" : true, // jqui theme
       "sDom" : "RfrtiS", // infinite scrolling, reorder columns
       "bAdjustWidth": false,
       "bScrollCollapse": true,
       "sScrollY": "450px", 
       "sScrollX": true 
       });
}

/** 
* @function dtConnectionDigest
* @desc Creates the connection digest report and data tables.
*/
function dtConnectionDigest(obj) {
   // remap some field names
   var fieldMap = {
    'pert_id': 'cmap_id',
    'pert_iname': 'cmap_iname',
    'summly': 'summary',
    'mean_rankpt_2': 'score_best2',
    'mean_rankpt_4': 'score_best4',
    'mean_rankpt_6': 'score_best6',
   };

    // parse and split table by pert_type
    var tbl = table.parseTable(obj.raw_data, '\t', true);

    // append MOA annotations if provided
    if ('moa_data' in obj) {
	var moa_tbl = table.parseTable(obj.moa_data, '\t', true);
	var selectFields = tbl.header;
	selectFields.splice(tbl.header_lut['pert_iname']+1, 0, 'moa_target');
	tbl = table.leftJoin(tbl, moa_tbl, 'pert_id', 'pert_id', selectFields);			     
    }

   var split = table.splitTable(tbl, 'pert_type');
   // insert ranks
   for (var key in split){
      split[key] = table.insertColumnIndex(split[key], 'rank');
   }
  
  var columnNames = [];
  var header = split.trt_cp.header;
  var header_lut = split.trt_cp.header_lut;

  for (var i in header) {
      if (header[i] === 'rank') {
        columnNames.push({sTitle: '', sType:'numeric'});
      }
      else {
        if (header[i] in fieldMap) {
          columnNames.push({sTitle: fieldMap[header[i]]});  
        } else {
          columnNames.push({sTitle: header[i]});  
        }
        
      }
  }
    // handle special columns
   var aoColumnDefs = [
    {targets: [header_lut.pert_type,
               header_lut.is_expressed_4,
               header_lut.is_expressed_6
              ],
     visible: false
    },
    {targets: [header_lut.rank],
      sortable: false}
    ];
    // width for moa column
    if ('moa_target' in header_lut) {
	aoColumnDefs.push({width: "1%", targets: [header_lut.moa_target]});
    }
    
    // compound table
    var dt_cp_config = {
       aaData: split.trt_cp.data,
       aoColumns: columnNames,
       aoColumnDefs: aoColumnDefs,
       fnDrawCallback: dtConnectionDigestDrawCallback,                
       bJQueryUI: true, // jqui theme
       sDom: "frtiS", // infinite scrolling, reorder columns
       autoWidth: false,
       bScrollCollapse: true,
       sScrollY: "450px", 
       sScrollX: "100%" 
       };
    // CGS table
    var dt_cgs_config = {
       fnRowCallback: function (nRow, aData) {
            var decoration = $(obj.expression_checkbox).prop("checked")?"line-through":"none";
            if (aData[split['trt_sh.cgs'].header_lut.is_expressed_4] === 0) {
                $(nRow).css({'text-decoration':decoration});
            }
        },
        aaData: split['trt_sh.cgs'].data,
        aoColumns: columnNames,
        aoColumnDefs: aoColumnDefs,
        fnDrawCallback: dtConnectionDigestDrawCallback,                
        bJQueryUI: true, // jqui theme
        sDom: "RfrtiS", // infinite scrolling, reorder columns
        bAdjustWidth: false,
        bScrollCollapse: true,
        sScrollY: "450px", 
        sScrollX: true,
    };
    // OE table
    var dt_oe_config = {
       aaData: split.trt_oe.data,
       aoColumns: columnNames,
       aoColumnDefs: aoColumnDefs,
       fnDrawCallback: dtConnectionDigestDrawCallback,                     
       bJQueryUI: true, // jqui theme
       sDom: "RfrtiS", // infinite scrolling, reorder columns
       bAdjustWidth: false,
       bScrollCollapse: true,
       sScrollY: "450px", 
       sScrollX: true 
       };

    // Handle sorting
    if ('sort_field' in obj && 'sort_order' in obj) {
       dt_cp_config['aaSorting']= [[split.trt_cp.header_lut[obj.sort_field],
            obj.sort_order]];
       dt_cgs_config['aaSorting']= [[split['trt_sh.cgs'].header_lut[obj.sort_field],
                                    obj.sort_order]];
       dt_oe_config['aaSorting']= [[split.trt_oe.header_lut[obj.sort_field],
                                    obj.sort_order]];                                    
    } else if ('sort_index' in obj && 'sort_order' in obj) {
        dt_cp_config['aaSorting']= [[obj.sort_index, obj.sort_order]];
        dt_cgs_config['aaSorting']= [[obj.sort_index, obj.sort_order]];
        dt_oe_config['aaSorting']= [[obj.sort_index, obj.sort_order]];
    }

    // instantiate DataTables
    var dt_cp = $(obj.target_cp).dataTable(dt_cp_config);
    var dt_cgs = $(obj.target_cgs).dataTable(dt_cgs_config);

    // gene expression checkbox        
    $(obj.expression_checkbox).change(function() { dt_cgs.fnDraw(); });        
    $(obj.expression_checkbox).prop('checked', true);

    var dt_oe = $(obj.target_oe).dataTable(dt_oe_config);
}

/** 
* @function dtConnectionDigestDrawCallback
* @desc Handles draw callbacks, custom ranking etc for the connection digest.
*/
function dtConnectionDigestDrawCallback( oSettings ) {
    // recompute all ranks and cache
    if(oSettings.bSorted){
        var bAscend = oSettings.aaSorting[0][1]=="asc";
        var iRows = oSettings.aiDisplayMaster.length;
        this._oRank = new Array(iRows);
        for (var j=0; j<iRows; j++) {
            this._oRank[oSettings.aiDisplayMaster[j]] = bAscend ? iRows-j : j+1 ;
        }
    }
    
    // update ranks for just visible rows since its faster
    var iStart = oSettings._iDisplayStart;
    var iStop = oSettings._iDisplayLength + iStart;
    for (var i=iStart; i<iStop ; i++ ) {
        var idx = oSettings.aiDisplay[i];
        this.fnUpdate(this._oRank[idx], oSettings.aiDisplay[i], 0, false, false );
    }
}

},{"./table":"/Users/narayan/workspace/mortar/js/js/table.js"}],"/Users/narayan/workspace/mortar/js/js/list.js":[function(require,module,exports){
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
},{}],"/Users/narayan/workspace/mortar/js/js/table.js":[function(require,module,exports){
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

},{"./list":"/Users/narayan/workspace/mortar/js/js/list.js","./util":"/Users/narayan/workspace/mortar/js/js/util.js","babyparse":"/Users/narayan/workspace/mortar/js/node_modules/babyparse/babyparse.js","http":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/http-browserify/index.js"}],"/Users/narayan/workspace/mortar/js/js/util.js":[function(require,module,exports){
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
},{}],"/Users/narayan/workspace/mortar/js/node_modules/babyparse/babyparse.js":[function(require,module,exports){
/*
	Baby Parse
	v0.4.1
	https://github.com/Rich-Harris/BabyParse

	Created by Rich Harris
	Maintained by Matt Holt

	Based on Papa Parse v4.0.7 by Matt Holt
	https://github.com/mholt/PapaParse
*/
(function(global)
{

	// A configuration object from which to draw default settings
	var DEFAULTS = {
		delimiter: "",	// empty: auto-detect
		newline: "",	// empty: auto-detect
		header: false,
		dynamicTyping: false,
		preview: 0,
		step: undefined,
		comments: false,
		complete: undefined,
		skipEmptyLines: false,
		fastMode: false
	};

	var Baby = {};
	Baby.parse = CsvToJson;
	Baby.parseFiles = ParseFiles;
	Baby.unparse = JsonToCsv;
	Baby.RECORD_SEP = String.fromCharCode(30);
	Baby.UNIT_SEP = String.fromCharCode(31);
	Baby.BYTE_ORDER_MARK = "\ufeff";
	Baby.BAD_DELIMITERS = ["\r", "\n", "\"", Baby.BYTE_ORDER_MARK];
	Baby.DefaultDelimiter = ",";		// Used if not specified and detection fails
	Baby.Parser = Parser;				// For testing/dev only
	Baby.ParserHandle = ParserHandle;	// For testing/dev only
	
	var fs = fs || require('fs')
	
	function ParseFiles(_input, _config)
	{
		if (Array.isArray(_input)) {
			var results = [];
			_input.forEach(function(input) {
				if(typeof input === 'object')
					results.push(ParseFiles(input.file, input.config));
				else
					results.push(ParseFiles(input, _config));
			});
			return results;
		} else {
			var results = {
				data: [],
				errors: []
			};
			if ((/(\.csv|\.txt)$/).test(_input)) {
				try {
					var contents = fs.readFileSync(_input).toString();
					return CsvToJson(contents, _config);
				} catch (err) {
					results.errors.push(err);
					return results;
				}
			} else {
				results.errors.push({
					type: '',
					code: '',
					message: 'Unsupported file type.',
					row: ''
				});
				return results;
			}
		}
	}

	function CsvToJson(_input, _config)
	{
		var config = copyAndValidateConfig(_config);
		var ph = new ParserHandle(config);
		var results = ph.parse(_input);
		return results;
	}




	function JsonToCsv(_input, _config)
	{
		var _output = "";
		var _fields = [];

		// Default configuration
		var _quotes = false;	// whether to surround every datum with quotes
		var _delimiter = ",";	// delimiting character
		var _newline = "\r\n";	// newline character(s)

		unpackConfig();

		if (typeof _input === 'string')
			_input = JSON.parse(_input);

		if (_input instanceof Array)
		{
			if (!_input.length || _input[0] instanceof Array)
				return serialize(null, _input);
			else if (typeof _input[0] === 'object')
				return serialize(objectKeys(_input[0]), _input);
		}
		else if (typeof _input === 'object')
		{
			if (typeof _input.data === 'string')
				_input.data = JSON.parse(_input.data);

			if (_input.data instanceof Array)
			{
				if (!_input.fields)
					_input.fields = _input.data[0] instanceof Array
									? _input.fields
									: objectKeys(_input.data[0]);

				if (!(_input.data[0] instanceof Array) && typeof _input.data[0] !== 'object')
					_input.data = [_input.data];	// handles input like [1,2,3] or ["asdf"]
			}

			return serialize(_input.fields || [], _input.data || []);
		}

		// Default (any valid paths should return before this)
		throw "exception: Unable to serialize unrecognized input";


		function unpackConfig()
		{
			if (typeof _config !== 'object')
				return;

			if (typeof _config.delimiter === 'string'
				&& _config.delimiter.length == 1
				&& Baby.BAD_DELIMITERS.indexOf(_config.delimiter) == -1)
			{
				_delimiter = _config.delimiter;
			}

			if (typeof _config.quotes === 'boolean'
				|| _config.quotes instanceof Array)
				_quotes = _config.quotes;

			if (typeof _config.newline === 'string')
				_newline = _config.newline;
		}


		// Turns an object's keys into an array
		function objectKeys(obj)
		{
			if (typeof obj !== 'object')
				return [];
			var keys = [];
			for (var key in obj)
				keys.push(key);
			return keys;
		}

		// The double for loop that iterates the data and writes out a CSV string including header row
		function serialize(fields, data)
		{
			var csv = "";

			if (typeof fields === 'string')
				fields = JSON.parse(fields);
			if (typeof data === 'string')
				data = JSON.parse(data);

			var hasHeader = fields instanceof Array && fields.length > 0;
			var dataKeyedByField = !(data[0] instanceof Array);

			// If there a header row, write it first
			if (hasHeader)
			{
				for (var i = 0; i < fields.length; i++)
				{
					if (i > 0)
						csv += _delimiter;
					csv += safe(fields[i], i);
				}
				if (data.length > 0)
					csv += _newline;
			}

			// Then write out the data
			for (var row = 0; row < data.length; row++)
			{
				var maxCol = hasHeader ? fields.length : data[row].length;

				for (var col = 0; col < maxCol; col++)
				{
					if (col > 0)
						csv += _delimiter;
					var colIdx = hasHeader && dataKeyedByField ? fields[col] : col;
					csv += safe(data[row][colIdx], col);
				}

				if (row < data.length - 1)
					csv += _newline;
			}

			return csv;
		}

		// Encloses a value around quotes if needed (makes a value safe for CSV insertion)
		function safe(str, col)
		{
			if (typeof str === "undefined" || str === null)
				return "";

			str = str.toString().replace(/"/g, '""');

			var needsQuotes = (typeof _quotes === 'boolean' && _quotes)
							|| (_quotes instanceof Array && _quotes[col])
							|| hasAny(str, Baby.BAD_DELIMITERS)
							|| str.indexOf(_delimiter) > -1
							|| str.charAt(0) == ' '
							|| str.charAt(str.length - 1) == ' ';

			return needsQuotes ? '"' + str + '"' : str;
		}

		function hasAny(str, substrings)
		{
			for (var i = 0; i < substrings.length; i++)
				if (str.indexOf(substrings[i]) > -1)
					return true;
			return false;
		}
	}






	// Use one ParserHandle per entire CSV file or string
	function ParserHandle(_config)
	{
		// One goal is to minimize the use of regular expressions...
		var FLOAT = /^\s*-?(\d*\.?\d+|\d+\.?\d*)(e[-+]?\d+)?\s*$/i;

		var self = this;
		var _stepCounter = 0;	// Number of times step was called (number of rows parsed)
		var _input;				// The input being parsed
		var _parser;			// The core parser being used
		var _paused = false;	// Whether we are paused or not
		var _delimiterError;	// Temporary state between delimiter detection and processing results
		var _fields = [];		// Fields are from the header row of the input, if there is one
		var _results = {		// The last results returned from the parser
			data: [],
			errors: [],
			meta: {}
		};

		if (isFunction(_config.step))
		{
			var userStep = _config.step;
			_config.step = function(results)
			{
				_results = results;

				if (needsHeaderRow())
					processResults();
				else	// only call user's step function after header row
				{
					processResults();

					// It's possbile that this line was empty and there's no row here after all
					if (_results.data.length == 0)
						return;

					_stepCounter += results.data.length;
					if (_config.preview && _stepCounter > _config.preview)
						_parser.abort();
					else
						userStep(_results, self);
				}
			};
		}

		this.parse = function(input)
		{
			if (!_config.newline)
				_config.newline = guessLineEndings(input);

			_delimiterError = false;
			if (!_config.delimiter)
			{
				var delimGuess = guessDelimiter(input);
				if (delimGuess.successful)
					_config.delimiter = delimGuess.bestDelimiter;
				else
				{
					_delimiterError = true;	// add error after parsing (otherwise it would be overwritten)
					_config.delimiter = Baby.DefaultDelimiter;
				}
				_results.meta.delimiter = _config.delimiter;
			}

			var parserConfig = copy(_config);
			if (_config.preview && _config.header)
				parserConfig.preview++;	// to compensate for header row

			_input = input;
			_parser = new Parser(parserConfig);
			_results = _parser.parse(_input);
			processResults();
			if (isFunction(_config.complete) && !_paused && (!self.streamer || self.streamer.finished()))
				_config.complete(_results);
			return _paused ? { meta: { paused: true } } : (_results || { meta: { paused: false } });
		};

		this.pause = function()
		{
			_paused = true;
			_parser.abort();
			_input = _input.substr(_parser.getCharIndex());
		};

		this.resume = function()
		{
			_paused = false;
			_parser = new Parser(_config);
			_parser.parse(_input);
			if (!_paused)
			{
				if (self.streamer && !self.streamer.finished())
					self.streamer.resume();		// more of the file yet to come
				else if (isFunction(_config.complete))
					_config.complete(_results);
			}
		};

		this.abort = function()
		{
			_parser.abort();
			if (isFunction(_config.complete))
				_config.complete(_results);
			_input = "";
		};

		function processResults()
		{
			if (_results && _delimiterError)
			{
				addError("Delimiter", "UndetectableDelimiter", "Unable to auto-detect delimiting character; defaulted to '"+Baby.DefaultDelimiter+"'");
				_delimiterError = false;
			}

			if (_config.skipEmptyLines)
			{
				for (var i = 0; i < _results.data.length; i++)
					if (_results.data[i].length == 1 && _results.data[i][0] == "")
						_results.data.splice(i--, 1);
			}

			if (needsHeaderRow())
				fillHeaderFields();

			return applyHeaderAndDynamicTyping();
		}

		function needsHeaderRow()
		{
			return _config.header && _fields.length == 0;
		}

		function fillHeaderFields()
		{
			if (!_results)
				return;
			for (var i = 0; needsHeaderRow() && i < _results.data.length; i++)
				for (var j = 0; j < _results.data[i].length; j++)
					_fields.push(_results.data[i][j]);
			_results.data.splice(0, 1);
		}

		function applyHeaderAndDynamicTyping()
		{
			if (!_results || (!_config.header && !_config.dynamicTyping))
				return _results;

			for (var i = 0; i < _results.data.length; i++)
			{
				var row = {};

				for (var j = 0; j < _results.data[i].length; j++)
				{
					if (_config.dynamicTyping)
					{
						var value = _results.data[i][j];
						if (value == "true" || value === "TRUE")
							_results.data[i][j] = true;
						else if (value == "false" || value === "FALSE")
							_results.data[i][j] = false;
						else
							_results.data[i][j] = tryParseFloat(value);
					}

					if (_config.header)
					{
						if (j >= _fields.length)
						{
							if (!row["__parsed_extra"])
								row["__parsed_extra"] = [];
							row["__parsed_extra"].push(_results.data[i][j]);
						}
						else
							row[_fields[j]] = _results.data[i][j];
					}
				}

				if (_config.header)
				{
					_results.data[i] = row;
					if (j > _fields.length)
						addError("FieldMismatch", "TooManyFields", "Too many fields: expected " + _fields.length + " fields but parsed " + j, i);
					else if (j < _fields.length)
						addError("FieldMismatch", "TooFewFields", "Too few fields: expected " + _fields.length + " fields but parsed " + j, i);
				}
			}

			if (_config.header && _results.meta)
				_results.meta.fields = _fields;
			return _results;
		}

		function guessDelimiter(input)
		{
			var delimChoices = [",", "\t", "|", ";", Baby.RECORD_SEP, Baby.UNIT_SEP];
			var bestDelim, bestDelta, fieldCountPrevRow;

			for (var i = 0; i < delimChoices.length; i++)
			{
				var delim = delimChoices[i];
				var delta = 0, avgFieldCount = 0;
				fieldCountPrevRow = undefined;

				var preview = new Parser({
					delimiter: delim,
					preview: 10
				}).parse(input);

				for (var j = 0; j < preview.data.length; j++)
				{
					var fieldCount = preview.data[j].length;
					avgFieldCount += fieldCount;

					if (typeof fieldCountPrevRow === 'undefined')
					{
						fieldCountPrevRow = fieldCount;
						continue;
					}
					else if (fieldCount > 1)
					{
						delta += Math.abs(fieldCount - fieldCountPrevRow);
						fieldCountPrevRow = fieldCount;
					}
				}

				avgFieldCount /= preview.data.length;

				if ((typeof bestDelta === 'undefined' || delta < bestDelta)
					&& avgFieldCount > 1.99)
				{
					bestDelta = delta;
					bestDelim = delim;
				}
			}

			_config.delimiter = bestDelim;

			return {
				successful: !!bestDelim,
				bestDelimiter: bestDelim
			}
		}

		function guessLineEndings(input)
		{
			input = input.substr(0, 1024*1024);	// max length 1 MB

			var r = input.split('\r');

			if (r.length == 1)
				return '\n';

			var numWithN = 0;
			for (var i = 0; i < r.length; i++)
			{
				if (r[i][0] == '\n')
					numWithN++;
			}

			return numWithN >= r.length / 2 ? '\r\n' : '\r';
		}

		function tryParseFloat(val)
		{
			var isNumber = FLOAT.test(val);
			return isNumber ? parseFloat(val) : val;
		}

		function addError(type, code, msg, row)
		{
			_results.errors.push({
				type: type,
				code: code,
				message: msg,
				row: row
			});
		}
	}






	// The core parser implements speedy and correct CSV parsing
	function Parser(config)
	{
		// Unpack the config object
		config = config || {};
		var delim = config.delimiter;
		var newline = config.newline;
		var comments = config.comments;
		var step = config.step;
		var preview = config.preview;
		var fastMode = config.fastMode;

		// Delimiter must be valid
		if (typeof delim !== 'string'
			|| delim.length != 1
			|| Baby.BAD_DELIMITERS.indexOf(delim) > -1)
			delim = ",";

		// Comment character must be valid
		if (comments === delim)
			throw "Comment character same as delimiter";
		else if (comments === true)
			comments = "#";
		else if (typeof comments !== 'string'
			|| Baby.BAD_DELIMITERS.indexOf(comments) > -1)
			comments = false;

		// Newline must be valid: \r, \n, or \r\n
		if (newline != '\n' && newline != '\r' && newline != '\r\n')
			newline = '\n';

		// We're gonna need these at the Parser scope
		var cursor = 0;
		var aborted = false;

		this.parse = function(input)
		{
			// For some reason, in Chrome, this speeds things up (!?)
			if (typeof input !== 'string')
				throw "Input must be a string";

			// We don't need to compute some of these every time parse() is called,
			// but having them in a more local scope seems to perform better
			var inputLen = input.length,
				delimLen = delim.length,
				newlineLen = newline.length,
				commentsLen = comments.length;
			var stepIsFunction = typeof step === 'function';

			// Establish starting state
			cursor = 0;
			var data = [], errors = [], row = [];

			if (!input)
				return returnable();

			if (fastMode)
			{
				// Fast mode assumes there are no quoted fields in the input
				var rows = input.split(newline);
				for (var i = 0; i < rows.length; i++)
				{
					if (comments && rows[i].substr(0, commentsLen) == comments)
						continue;
					if (stepIsFunction)
					{
						data = [ rows[i].split(delim) ];
						doStep();
						if (aborted)
							return returnable();
					}
					else
						data.push(rows[i].split(delim));
					if (preview && i >= preview)
					{
						data = data.slice(0, preview);
						return returnable(true);
					}
				}
				return returnable();
			}

			var nextDelim = input.indexOf(delim, cursor);
			var nextNewline = input.indexOf(newline, cursor);

			// Parser loop
			for (;;)
			{
				// Field has opening quote
				if (input[cursor] == '"')
				{
					// Start our search for the closing quote where the cursor is
					var quoteSearch = cursor;

					// Skip the opening quote
					cursor++;

					for (;;)
					{
						// Find closing quote
						var quoteSearch = input.indexOf('"', quoteSearch+1);

						if (quoteSearch === -1)
						{
							// No closing quote... what a pity
							errors.push({
								type: "Quotes",
								code: "MissingQuotes",
								message: "Quoted field unterminated",
								row: data.length,	// row has yet to be inserted
								index: cursor
							});
							return finish();
						}

						if (quoteSearch === inputLen-1)
						{
							// Closing quote at EOF
							row.push(input.substring(cursor, quoteSearch).replace(/""/g, '"'));
							data.push(row);
							if (stepIsFunction)
								doStep();
							return returnable();
						}

						// If this quote is escaped, it's part of the data; skip it
						if (input[quoteSearch+1] == '"')
						{
							quoteSearch++;
							continue;
						}

						if (input[quoteSearch+1] == delim)
						{
							// Closing quote followed by delimiter
							row.push(input.substring(cursor, quoteSearch).replace(/""/g, '"'));
							cursor = quoteSearch + 1 + delimLen;
							nextDelim = input.indexOf(delim, cursor);
							nextNewline = input.indexOf(newline, cursor);
							break;
						}

						if (input.substr(quoteSearch+1, newlineLen) === newline)
						{
							// Closing quote followed by newline
							row.push(input.substring(cursor, quoteSearch).replace(/""/g, '"'));
							saveRow(quoteSearch + 1 + newlineLen);
							nextDelim = input.indexOf(delim, cursor);	// because we may have skipped the nextDelim in the quoted field

							if (stepIsFunction)
							{
								doStep();
								if (aborted)
									return returnable();
							}
							
							if (preview && data.length >= preview)
								return returnable(true);

							break;
						}
					}

					continue;
				}

				// Comment found at start of new line
				if (comments && row.length === 0 && input.substr(cursor, commentsLen) === comments)
				{
					if (nextNewline == -1)	// Comment ends at EOF
						return returnable();
					cursor = nextNewline + newlineLen;
					nextNewline = input.indexOf(newline, cursor);
					nextDelim = input.indexOf(delim, cursor);
					continue;
				}

				// Next delimiter comes before next newline, so we've reached end of field
				if (nextDelim !== -1 && (nextDelim < nextNewline || nextNewline === -1))
				{
					row.push(input.substring(cursor, nextDelim));
					cursor = nextDelim + delimLen;
					nextDelim = input.indexOf(delim, cursor);
					continue;
				}

				// End of row
				if (nextNewline !== -1)
				{
					row.push(input.substring(cursor, nextNewline));
					saveRow(nextNewline + newlineLen);

					if (stepIsFunction)
					{
						doStep();
						if (aborted)
							return returnable();
					}

					if (preview && data.length >= preview)
						return returnable(true);

					continue;
				}

				break;
			}


			return finish();


			// Appends the remaining input from cursor to the end into
			// row, saves the row, calls step, and returns the results.
			function finish()
			{
				row.push(input.substr(cursor));
				data.push(row);
				cursor = inputLen;	// important in case parsing is paused
				if (stepIsFunction)
					doStep();
				return returnable();
			}

			// Appends the current row to the results. It sets the cursor
			// to newCursor and finds the nextNewline. The caller should
			// take care to execute user's step function and check for
			// preview and end parsing if necessary.
			function saveRow(newCursor)
			{
				data.push(row);
				row = [];
				cursor = newCursor;
				nextNewline = input.indexOf(newline, cursor);
			}

			// Returns an object with the results, errors, and meta.
			function returnable(stopped)
			{
				return {
					data: data,
					errors: errors,
					meta: {
						delimiter: delim,
						linebreak: newline,
						aborted: aborted,
						truncated: !!stopped
					}
				};
			}

			// Executes the user's step function and resets data & errors.
			function doStep()
			{
				step(returnable());
				data = [], errors = [];
			}
		};

		// Sets the abort flag
		this.abort = function()
		{
			aborted = true;
		};

		// Gets the cursor position
		this.getCharIndex = function()
		{
			return cursor;
		};
	}




	// Replaces bad config values with good, default ones
	function copyAndValidateConfig(origConfig)
	{
		if (typeof origConfig !== 'object')
			origConfig = {};

		var config = copy(origConfig);

		if (typeof config.delimiter !== 'string'
			|| config.delimiter.length != 1
			|| Baby.BAD_DELIMITERS.indexOf(config.delimiter) > -1)
			config.delimiter = DEFAULTS.delimiter;

		if (config.newline != '\n'
			&& config.newline != '\r'
			&& config.newline != '\r\n')
			config.newline = DEFAULTS.newline;

		if (typeof config.header !== 'boolean')
			config.header = DEFAULTS.header;

		if (typeof config.dynamicTyping !== 'boolean')
			config.dynamicTyping = DEFAULTS.dynamicTyping;

		if (typeof config.preview !== 'number')
			config.preview = DEFAULTS.preview;

		if (typeof config.step !== 'function')
			config.step = DEFAULTS.step;

		if (typeof config.complete !== 'function')
			config.complete = DEFAULTS.complete;

		if (typeof config.skipEmptyLines !== 'boolean')
			config.skipEmptyLines = DEFAULTS.skipEmptyLines;

		if (typeof config.fastMode !== 'boolean')
			config.fastMode = DEFAULTS.fastMode;

		return config;
	}

	function copy(obj)
	{
		if (typeof obj !== 'object')
			return obj;
		var cpy = obj instanceof Array ? [] : {};
		for (var key in obj)
			cpy[key] = copy(obj[key]);
		return cpy;
	}

	function isFunction(func)
	{
		return typeof func === 'function';
	}






	// export to Node...
	if ( typeof module !== 'undefined' && module.exports ) {
		module.exports = Baby;
	}

	// ...or as AMD module...
	else if ( typeof define === 'function' && define.amd ) {
		define( function () { return Baby; });
	}

	// ...or as browser global
	else {
		global.Baby = Baby;
	}

})(typeof window !== 'undefined' ? window : this);

},{"fs":"/Users/narayan/workspace/mortar/js/node_modules/browserify/lib/_empty.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/lib/_empty.js":[function(require,module,exports){

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/browser-resolve/empty.js":[function(require,module,exports){
module.exports=require("/Users/narayan/workspace/mortar/js/node_modules/browserify/lib/_empty.js")
},{"/Users/narayan/workspace/mortar/js/node_modules/browserify/lib/_empty.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/lib/_empty.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/index.js":[function(require,module,exports){
/*!
 * The buffer module from node.js, for the browser.
 *
 * @author   Feross Aboukhadijeh <feross@feross.org> <http://feross.org>
 * @license  MIT
 */

var base64 = require('base64-js')
var ieee754 = require('ieee754')
var isArray = require('is-array')

exports.Buffer = Buffer
exports.SlowBuffer = Buffer
exports.INSPECT_MAX_BYTES = 50
Buffer.poolSize = 8192 // not used by this implementation

var kMaxLength = 0x3fffffff

/**
 * If `Buffer.TYPED_ARRAY_SUPPORT`:
 *   === true    Use Uint8Array implementation (fastest)
 *   === false   Use Object implementation (most compatible, even IE6)
 *
 * Browsers that support typed arrays are IE 10+, Firefox 4+, Chrome 7+, Safari 5.1+,
 * Opera 11.6+, iOS 4.2+.
 *
 * Note:
 *
 * - Implementation must support adding new properties to `Uint8Array` instances.
 *   Firefox 4-29 lacked support, fixed in Firefox 30+.
 *   See: https://bugzilla.mozilla.org/show_bug.cgi?id=695438.
 *
 *  - Chrome 9-10 is missing the `TypedArray.prototype.subarray` function.
 *
 *  - IE10 has a broken `TypedArray.prototype.subarray` function which returns arrays of
 *    incorrect length in some situations.
 *
 * We detect these buggy browsers and set `Buffer.TYPED_ARRAY_SUPPORT` to `false` so they will
 * get the Object implementation, which is slower but will work correctly.
 */
Buffer.TYPED_ARRAY_SUPPORT = (function () {
  try {
    var buf = new ArrayBuffer(0)
    var arr = new Uint8Array(buf)
    arr.foo = function () { return 42 }
    return 42 === arr.foo() && // typed array instances can be augmented
        typeof arr.subarray === 'function' && // chrome 9-10 lack `subarray`
        new Uint8Array(1).subarray(1, 1).byteLength === 0 // ie10 has broken `subarray`
  } catch (e) {
    return false
  }
})()

/**
 * Class: Buffer
 * =============
 *
 * The Buffer constructor returns instances of `Uint8Array` that are augmented
 * with function properties for all the node `Buffer` API functions. We use
 * `Uint8Array` so that square bracket notation works as expected -- it returns
 * a single octet.
 *
 * By augmenting the instances, we can avoid modifying the `Uint8Array`
 * prototype.
 */
function Buffer (subject, encoding, noZero) {
  if (!(this instanceof Buffer))
    return new Buffer(subject, encoding, noZero)

  var type = typeof subject

  // Find the length
  var length
  if (type === 'number')
    length = subject > 0 ? subject >>> 0 : 0
  else if (type === 'string') {
    if (encoding === 'base64')
      subject = base64clean(subject)
    length = Buffer.byteLength(subject, encoding)
  } else if (type === 'object' && subject !== null) { // assume object is array-like
    if (subject.type === 'Buffer' && isArray(subject.data))
      subject = subject.data
    length = +subject.length > 0 ? Math.floor(+subject.length) : 0
  } else
    throw new TypeError('must start with number, buffer, array or string')

  if (this.length > kMaxLength)
    throw new RangeError('Attempt to allocate Buffer larger than maximum ' +
      'size: 0x' + kMaxLength.toString(16) + ' bytes')

  var buf
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    // Preferred: Return an augmented `Uint8Array` instance for best performance
    buf = Buffer._augment(new Uint8Array(length))
  } else {
    // Fallback: Return THIS instance of Buffer (created by `new`)
    buf = this
    buf.length = length
    buf._isBuffer = true
  }

  var i
  if (Buffer.TYPED_ARRAY_SUPPORT && typeof subject.byteLength === 'number') {
    // Speed optimization -- use set if we're copying from a typed array
    buf._set(subject)
  } else if (isArrayish(subject)) {
    // Treat array-ish objects as a byte array
    if (Buffer.isBuffer(subject)) {
      for (i = 0; i < length; i++)
        buf[i] = subject.readUInt8(i)
    } else {
      for (i = 0; i < length; i++)
        buf[i] = ((subject[i] % 256) + 256) % 256
    }
  } else if (type === 'string') {
    buf.write(subject, 0, encoding)
  } else if (type === 'number' && !Buffer.TYPED_ARRAY_SUPPORT && !noZero) {
    for (i = 0; i < length; i++) {
      buf[i] = 0
    }
  }

  return buf
}

Buffer.isBuffer = function (b) {
  return !!(b != null && b._isBuffer)
}

Buffer.compare = function (a, b) {
  if (!Buffer.isBuffer(a) || !Buffer.isBuffer(b))
    throw new TypeError('Arguments must be Buffers')

  var x = a.length
  var y = b.length
  for (var i = 0, len = Math.min(x, y); i < len && a[i] === b[i]; i++) {}
  if (i !== len) {
    x = a[i]
    y = b[i]
  }
  if (x < y) return -1
  if (y < x) return 1
  return 0
}

Buffer.isEncoding = function (encoding) {
  switch (String(encoding).toLowerCase()) {
    case 'hex':
    case 'utf8':
    case 'utf-8':
    case 'ascii':
    case 'binary':
    case 'base64':
    case 'raw':
    case 'ucs2':
    case 'ucs-2':
    case 'utf16le':
    case 'utf-16le':
      return true
    default:
      return false
  }
}

Buffer.concat = function (list, totalLength) {
  if (!isArray(list)) throw new TypeError('Usage: Buffer.concat(list[, length])')

  if (list.length === 0) {
    return new Buffer(0)
  } else if (list.length === 1) {
    return list[0]
  }

  var i
  if (totalLength === undefined) {
    totalLength = 0
    for (i = 0; i < list.length; i++) {
      totalLength += list[i].length
    }
  }

  var buf = new Buffer(totalLength)
  var pos = 0
  for (i = 0; i < list.length; i++) {
    var item = list[i]
    item.copy(buf, pos)
    pos += item.length
  }
  return buf
}

Buffer.byteLength = function (str, encoding) {
  var ret
  str = str + ''
  switch (encoding || 'utf8') {
    case 'ascii':
    case 'binary':
    case 'raw':
      ret = str.length
      break
    case 'ucs2':
    case 'ucs-2':
    case 'utf16le':
    case 'utf-16le':
      ret = str.length * 2
      break
    case 'hex':
      ret = str.length >>> 1
      break
    case 'utf8':
    case 'utf-8':
      ret = utf8ToBytes(str).length
      break
    case 'base64':
      ret = base64ToBytes(str).length
      break
    default:
      ret = str.length
  }
  return ret
}

// pre-set for values that may exist in the future
Buffer.prototype.length = undefined
Buffer.prototype.parent = undefined

// toString(encoding, start=0, end=buffer.length)
Buffer.prototype.toString = function (encoding, start, end) {
  var loweredCase = false

  start = start >>> 0
  end = end === undefined || end === Infinity ? this.length : end >>> 0

  if (!encoding) encoding = 'utf8'
  if (start < 0) start = 0
  if (end > this.length) end = this.length
  if (end <= start) return ''

  while (true) {
    switch (encoding) {
      case 'hex':
        return hexSlice(this, start, end)

      case 'utf8':
      case 'utf-8':
        return utf8Slice(this, start, end)

      case 'ascii':
        return asciiSlice(this, start, end)

      case 'binary':
        return binarySlice(this, start, end)

      case 'base64':
        return base64Slice(this, start, end)

      case 'ucs2':
      case 'ucs-2':
      case 'utf16le':
      case 'utf-16le':
        return utf16leSlice(this, start, end)

      default:
        if (loweredCase)
          throw new TypeError('Unknown encoding: ' + encoding)
        encoding = (encoding + '').toLowerCase()
        loweredCase = true
    }
  }
}

Buffer.prototype.equals = function (b) {
  if(!Buffer.isBuffer(b)) throw new TypeError('Argument must be a Buffer')
  return Buffer.compare(this, b) === 0
}

Buffer.prototype.inspect = function () {
  var str = ''
  var max = exports.INSPECT_MAX_BYTES
  if (this.length > 0) {
    str = this.toString('hex', 0, max).match(/.{2}/g).join(' ')
    if (this.length > max)
      str += ' ... '
  }
  return '<Buffer ' + str + '>'
}

Buffer.prototype.compare = function (b) {
  if (!Buffer.isBuffer(b)) throw new TypeError('Argument must be a Buffer')
  return Buffer.compare(this, b)
}

// `get` will be removed in Node 0.13+
Buffer.prototype.get = function (offset) {
  console.log('.get() is deprecated. Access using array indexes instead.')
  return this.readUInt8(offset)
}

// `set` will be removed in Node 0.13+
Buffer.prototype.set = function (v, offset) {
  console.log('.set() is deprecated. Access using array indexes instead.')
  return this.writeUInt8(v, offset)
}

function hexWrite (buf, string, offset, length) {
  offset = Number(offset) || 0
  var remaining = buf.length - offset
  if (!length) {
    length = remaining
  } else {
    length = Number(length)
    if (length > remaining) {
      length = remaining
    }
  }

  // must be an even number of digits
  var strLen = string.length
  if (strLen % 2 !== 0) throw new Error('Invalid hex string')

  if (length > strLen / 2) {
    length = strLen / 2
  }
  for (var i = 0; i < length; i++) {
    var byte = parseInt(string.substr(i * 2, 2), 16)
    if (isNaN(byte)) throw new Error('Invalid hex string')
    buf[offset + i] = byte
  }
  return i
}

function utf8Write (buf, string, offset, length) {
  var charsWritten = blitBuffer(utf8ToBytes(string), buf, offset, length)
  return charsWritten
}

function asciiWrite (buf, string, offset, length) {
  var charsWritten = blitBuffer(asciiToBytes(string), buf, offset, length)
  return charsWritten
}

function binaryWrite (buf, string, offset, length) {
  return asciiWrite(buf, string, offset, length)
}

function base64Write (buf, string, offset, length) {
  var charsWritten = blitBuffer(base64ToBytes(string), buf, offset, length)
  return charsWritten
}

function utf16leWrite (buf, string, offset, length) {
  var charsWritten = blitBuffer(utf16leToBytes(string), buf, offset, length, 2)
  return charsWritten
}

Buffer.prototype.write = function (string, offset, length, encoding) {
  // Support both (string, offset, length, encoding)
  // and the legacy (string, encoding, offset, length)
  if (isFinite(offset)) {
    if (!isFinite(length)) {
      encoding = length
      length = undefined
    }
  } else {  // legacy
    var swap = encoding
    encoding = offset
    offset = length
    length = swap
  }

  offset = Number(offset) || 0
  var remaining = this.length - offset
  if (!length) {
    length = remaining
  } else {
    length = Number(length)
    if (length > remaining) {
      length = remaining
    }
  }
  encoding = String(encoding || 'utf8').toLowerCase()

  var ret
  switch (encoding) {
    case 'hex':
      ret = hexWrite(this, string, offset, length)
      break
    case 'utf8':
    case 'utf-8':
      ret = utf8Write(this, string, offset, length)
      break
    case 'ascii':
      ret = asciiWrite(this, string, offset, length)
      break
    case 'binary':
      ret = binaryWrite(this, string, offset, length)
      break
    case 'base64':
      ret = base64Write(this, string, offset, length)
      break
    case 'ucs2':
    case 'ucs-2':
    case 'utf16le':
    case 'utf-16le':
      ret = utf16leWrite(this, string, offset, length)
      break
    default:
      throw new TypeError('Unknown encoding: ' + encoding)
  }
  return ret
}

Buffer.prototype.toJSON = function () {
  return {
    type: 'Buffer',
    data: Array.prototype.slice.call(this._arr || this, 0)
  }
}

function base64Slice (buf, start, end) {
  if (start === 0 && end === buf.length) {
    return base64.fromByteArray(buf)
  } else {
    return base64.fromByteArray(buf.slice(start, end))
  }
}

function utf8Slice (buf, start, end) {
  var res = ''
  var tmp = ''
  end = Math.min(buf.length, end)

  for (var i = start; i < end; i++) {
    if (buf[i] <= 0x7F) {
      res += decodeUtf8Char(tmp) + String.fromCharCode(buf[i])
      tmp = ''
    } else {
      tmp += '%' + buf[i].toString(16)
    }
  }

  return res + decodeUtf8Char(tmp)
}

function asciiSlice (buf, start, end) {
  var ret = ''
  end = Math.min(buf.length, end)

  for (var i = start; i < end; i++) {
    ret += String.fromCharCode(buf[i])
  }
  return ret
}

function binarySlice (buf, start, end) {
  return asciiSlice(buf, start, end)
}

function hexSlice (buf, start, end) {
  var len = buf.length

  if (!start || start < 0) start = 0
  if (!end || end < 0 || end > len) end = len

  var out = ''
  for (var i = start; i < end; i++) {
    out += toHex(buf[i])
  }
  return out
}

function utf16leSlice (buf, start, end) {
  var bytes = buf.slice(start, end)
  var res = ''
  for (var i = 0; i < bytes.length; i += 2) {
    res += String.fromCharCode(bytes[i] + bytes[i + 1] * 256)
  }
  return res
}

Buffer.prototype.slice = function (start, end) {
  var len = this.length
  start = ~~start
  end = end === undefined ? len : ~~end

  if (start < 0) {
    start += len;
    if (start < 0)
      start = 0
  } else if (start > len) {
    start = len
  }

  if (end < 0) {
    end += len
    if (end < 0)
      end = 0
  } else if (end > len) {
    end = len
  }

  if (end < start)
    end = start

  if (Buffer.TYPED_ARRAY_SUPPORT) {
    return Buffer._augment(this.subarray(start, end))
  } else {
    var sliceLen = end - start
    var newBuf = new Buffer(sliceLen, undefined, true)
    for (var i = 0; i < sliceLen; i++) {
      newBuf[i] = this[i + start]
    }
    return newBuf
  }
}

/*
 * Need to make sure that buffer isn't trying to write out of bounds.
 */
function checkOffset (offset, ext, length) {
  if ((offset % 1) !== 0 || offset < 0)
    throw new RangeError('offset is not uint')
  if (offset + ext > length)
    throw new RangeError('Trying to access beyond buffer length')
}

Buffer.prototype.readUInt8 = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 1, this.length)
  return this[offset]
}

Buffer.prototype.readUInt16LE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 2, this.length)
  return this[offset] | (this[offset + 1] << 8)
}

Buffer.prototype.readUInt16BE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 2, this.length)
  return (this[offset] << 8) | this[offset + 1]
}

Buffer.prototype.readUInt32LE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 4, this.length)

  return ((this[offset]) |
      (this[offset + 1] << 8) |
      (this[offset + 2] << 16)) +
      (this[offset + 3] * 0x1000000)
}

Buffer.prototype.readUInt32BE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 4, this.length)

  return (this[offset] * 0x1000000) +
      ((this[offset + 1] << 16) |
      (this[offset + 2] << 8) |
      this[offset + 3])
}

Buffer.prototype.readInt8 = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 1, this.length)
  if (!(this[offset] & 0x80))
    return (this[offset])
  return ((0xff - this[offset] + 1) * -1)
}

Buffer.prototype.readInt16LE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 2, this.length)
  var val = this[offset] | (this[offset + 1] << 8)
  return (val & 0x8000) ? val | 0xFFFF0000 : val
}

Buffer.prototype.readInt16BE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 2, this.length)
  var val = this[offset + 1] | (this[offset] << 8)
  return (val & 0x8000) ? val | 0xFFFF0000 : val
}

Buffer.prototype.readInt32LE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 4, this.length)

  return (this[offset]) |
      (this[offset + 1] << 8) |
      (this[offset + 2] << 16) |
      (this[offset + 3] << 24)
}

Buffer.prototype.readInt32BE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 4, this.length)

  return (this[offset] << 24) |
      (this[offset + 1] << 16) |
      (this[offset + 2] << 8) |
      (this[offset + 3])
}

Buffer.prototype.readFloatLE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 4, this.length)
  return ieee754.read(this, offset, true, 23, 4)
}

Buffer.prototype.readFloatBE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 4, this.length)
  return ieee754.read(this, offset, false, 23, 4)
}

Buffer.prototype.readDoubleLE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 8, this.length)
  return ieee754.read(this, offset, true, 52, 8)
}

Buffer.prototype.readDoubleBE = function (offset, noAssert) {
  if (!noAssert)
    checkOffset(offset, 8, this.length)
  return ieee754.read(this, offset, false, 52, 8)
}

function checkInt (buf, value, offset, ext, max, min) {
  if (!Buffer.isBuffer(buf)) throw new TypeError('buffer must be a Buffer instance')
  if (value > max || value < min) throw new TypeError('value is out of bounds')
  if (offset + ext > buf.length) throw new TypeError('index out of range')
}

Buffer.prototype.writeUInt8 = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 1, 0xff, 0)
  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value)
  this[offset] = value
  return offset + 1
}

function objectWriteUInt16 (buf, value, offset, littleEndian) {
  if (value < 0) value = 0xffff + value + 1
  for (var i = 0, j = Math.min(buf.length - offset, 2); i < j; i++) {
    buf[offset + i] = (value & (0xff << (8 * (littleEndian ? i : 1 - i)))) >>>
      (littleEndian ? i : 1 - i) * 8
  }
}

Buffer.prototype.writeUInt16LE = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 2, 0xffff, 0)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = value
    this[offset + 1] = (value >>> 8)
  } else objectWriteUInt16(this, value, offset, true)
  return offset + 2
}

Buffer.prototype.writeUInt16BE = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 2, 0xffff, 0)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 8)
    this[offset + 1] = value
  } else objectWriteUInt16(this, value, offset, false)
  return offset + 2
}

function objectWriteUInt32 (buf, value, offset, littleEndian) {
  if (value < 0) value = 0xffffffff + value + 1
  for (var i = 0, j = Math.min(buf.length - offset, 4); i < j; i++) {
    buf[offset + i] = (value >>> (littleEndian ? i : 3 - i) * 8) & 0xff
  }
}

Buffer.prototype.writeUInt32LE = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 4, 0xffffffff, 0)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset + 3] = (value >>> 24)
    this[offset + 2] = (value >>> 16)
    this[offset + 1] = (value >>> 8)
    this[offset] = value
  } else objectWriteUInt32(this, value, offset, true)
  return offset + 4
}

Buffer.prototype.writeUInt32BE = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 4, 0xffffffff, 0)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 24)
    this[offset + 1] = (value >>> 16)
    this[offset + 2] = (value >>> 8)
    this[offset + 3] = value
  } else objectWriteUInt32(this, value, offset, false)
  return offset + 4
}

Buffer.prototype.writeInt8 = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 1, 0x7f, -0x80)
  if (!Buffer.TYPED_ARRAY_SUPPORT) value = Math.floor(value)
  if (value < 0) value = 0xff + value + 1
  this[offset] = value
  return offset + 1
}

Buffer.prototype.writeInt16LE = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 2, 0x7fff, -0x8000)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = value
    this[offset + 1] = (value >>> 8)
  } else objectWriteUInt16(this, value, offset, true)
  return offset + 2
}

Buffer.prototype.writeInt16BE = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 2, 0x7fff, -0x8000)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 8)
    this[offset + 1] = value
  } else objectWriteUInt16(this, value, offset, false)
  return offset + 2
}

Buffer.prototype.writeInt32LE = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = value
    this[offset + 1] = (value >>> 8)
    this[offset + 2] = (value >>> 16)
    this[offset + 3] = (value >>> 24)
  } else objectWriteUInt32(this, value, offset, true)
  return offset + 4
}

Buffer.prototype.writeInt32BE = function (value, offset, noAssert) {
  value = +value
  offset = offset >>> 0
  if (!noAssert)
    checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)
  if (value < 0) value = 0xffffffff + value + 1
  if (Buffer.TYPED_ARRAY_SUPPORT) {
    this[offset] = (value >>> 24)
    this[offset + 1] = (value >>> 16)
    this[offset + 2] = (value >>> 8)
    this[offset + 3] = value
  } else objectWriteUInt32(this, value, offset, false)
  return offset + 4
}

function checkIEEE754 (buf, value, offset, ext, max, min) {
  if (value > max || value < min) throw new TypeError('value is out of bounds')
  if (offset + ext > buf.length) throw new TypeError('index out of range')
}

function writeFloat (buf, value, offset, littleEndian, noAssert) {
  if (!noAssert)
    checkIEEE754(buf, value, offset, 4, 3.4028234663852886e+38, -3.4028234663852886e+38)
  ieee754.write(buf, value, offset, littleEndian, 23, 4)
  return offset + 4
}

Buffer.prototype.writeFloatLE = function (value, offset, noAssert) {
  return writeFloat(this, value, offset, true, noAssert)
}

Buffer.prototype.writeFloatBE = function (value, offset, noAssert) {
  return writeFloat(this, value, offset, false, noAssert)
}

function writeDouble (buf, value, offset, littleEndian, noAssert) {
  if (!noAssert)
    checkIEEE754(buf, value, offset, 8, 1.7976931348623157E+308, -1.7976931348623157E+308)
  ieee754.write(buf, value, offset, littleEndian, 52, 8)
  return offset + 8
}

Buffer.prototype.writeDoubleLE = function (value, offset, noAssert) {
  return writeDouble(this, value, offset, true, noAssert)
}

Buffer.prototype.writeDoubleBE = function (value, offset, noAssert) {
  return writeDouble(this, value, offset, false, noAssert)
}

// copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)
Buffer.prototype.copy = function (target, target_start, start, end) {
  var source = this

  if (!start) start = 0
  if (!end && end !== 0) end = this.length
  if (!target_start) target_start = 0

  // Copy 0 bytes; we're done
  if (end === start) return
  if (target.length === 0 || source.length === 0) return

  // Fatal error conditions
  if (end < start) throw new TypeError('sourceEnd < sourceStart')
  if (target_start < 0 || target_start >= target.length)
    throw new TypeError('targetStart out of bounds')
  if (start < 0 || start >= source.length) throw new TypeError('sourceStart out of bounds')
  if (end < 0 || end > source.length) throw new TypeError('sourceEnd out of bounds')

  // Are we oob?
  if (end > this.length)
    end = this.length
  if (target.length - target_start < end - start)
    end = target.length - target_start + start

  var len = end - start

  if (len < 1000 || !Buffer.TYPED_ARRAY_SUPPORT) {
    for (var i = 0; i < len; i++) {
      target[i + target_start] = this[i + start]
    }
  } else {
    target._set(this.subarray(start, start + len), target_start)
  }
}

// fill(value, start=0, end=buffer.length)
Buffer.prototype.fill = function (value, start, end) {
  if (!value) value = 0
  if (!start) start = 0
  if (!end) end = this.length

  if (end < start) throw new TypeError('end < start')

  // Fill 0 bytes; we're done
  if (end === start) return
  if (this.length === 0) return

  if (start < 0 || start >= this.length) throw new TypeError('start out of bounds')
  if (end < 0 || end > this.length) throw new TypeError('end out of bounds')

  var i
  if (typeof value === 'number') {
    for (i = start; i < end; i++) {
      this[i] = value
    }
  } else {
    var bytes = utf8ToBytes(value.toString())
    var len = bytes.length
    for (i = start; i < end; i++) {
      this[i] = bytes[i % len]
    }
  }

  return this
}

/**
 * Creates a new `ArrayBuffer` with the *copied* memory of the buffer instance.
 * Added in Node 0.12. Only available in browsers that support ArrayBuffer.
 */
Buffer.prototype.toArrayBuffer = function () {
  if (typeof Uint8Array !== 'undefined') {
    if (Buffer.TYPED_ARRAY_SUPPORT) {
      return (new Buffer(this)).buffer
    } else {
      var buf = new Uint8Array(this.length)
      for (var i = 0, len = buf.length; i < len; i += 1) {
        buf[i] = this[i]
      }
      return buf.buffer
    }
  } else {
    throw new TypeError('Buffer.toArrayBuffer not supported in this browser')
  }
}

// HELPER FUNCTIONS
// ================

var BP = Buffer.prototype

/**
 * Augment a Uint8Array *instance* (not the Uint8Array class!) with Buffer methods
 */
Buffer._augment = function (arr) {
  arr.constructor = Buffer
  arr._isBuffer = true

  // save reference to original Uint8Array get/set methods before overwriting
  arr._get = arr.get
  arr._set = arr.set

  // deprecated, will be removed in node 0.13+
  arr.get = BP.get
  arr.set = BP.set

  arr.write = BP.write
  arr.toString = BP.toString
  arr.toLocaleString = BP.toString
  arr.toJSON = BP.toJSON
  arr.equals = BP.equals
  arr.compare = BP.compare
  arr.copy = BP.copy
  arr.slice = BP.slice
  arr.readUInt8 = BP.readUInt8
  arr.readUInt16LE = BP.readUInt16LE
  arr.readUInt16BE = BP.readUInt16BE
  arr.readUInt32LE = BP.readUInt32LE
  arr.readUInt32BE = BP.readUInt32BE
  arr.readInt8 = BP.readInt8
  arr.readInt16LE = BP.readInt16LE
  arr.readInt16BE = BP.readInt16BE
  arr.readInt32LE = BP.readInt32LE
  arr.readInt32BE = BP.readInt32BE
  arr.readFloatLE = BP.readFloatLE
  arr.readFloatBE = BP.readFloatBE
  arr.readDoubleLE = BP.readDoubleLE
  arr.readDoubleBE = BP.readDoubleBE
  arr.writeUInt8 = BP.writeUInt8
  arr.writeUInt16LE = BP.writeUInt16LE
  arr.writeUInt16BE = BP.writeUInt16BE
  arr.writeUInt32LE = BP.writeUInt32LE
  arr.writeUInt32BE = BP.writeUInt32BE
  arr.writeInt8 = BP.writeInt8
  arr.writeInt16LE = BP.writeInt16LE
  arr.writeInt16BE = BP.writeInt16BE
  arr.writeInt32LE = BP.writeInt32LE
  arr.writeInt32BE = BP.writeInt32BE
  arr.writeFloatLE = BP.writeFloatLE
  arr.writeFloatBE = BP.writeFloatBE
  arr.writeDoubleLE = BP.writeDoubleLE
  arr.writeDoubleBE = BP.writeDoubleBE
  arr.fill = BP.fill
  arr.inspect = BP.inspect
  arr.toArrayBuffer = BP.toArrayBuffer

  return arr
}

var INVALID_BASE64_RE = /[^+\/0-9A-z]/g

function base64clean (str) {
  // Node strips out invalid characters like \n and \t from the string, base64-js does not
  str = stringtrim(str).replace(INVALID_BASE64_RE, '')
  // Node allows for non-padded base64 strings (missing trailing ===), base64-js does not
  while (str.length % 4 !== 0) {
    str = str + '='
  }
  return str
}

function stringtrim (str) {
  if (str.trim) return str.trim()
  return str.replace(/^\s+|\s+$/g, '')
}

function isArrayish (subject) {
  return isArray(subject) || Buffer.isBuffer(subject) ||
      subject && typeof subject === 'object' &&
      typeof subject.length === 'number'
}

function toHex (n) {
  if (n < 16) return '0' + n.toString(16)
  return n.toString(16)
}

function utf8ToBytes (str) {
  var byteArray = []
  for (var i = 0; i < str.length; i++) {
    var b = str.charCodeAt(i)
    if (b <= 0x7F) {
      byteArray.push(b)
    } else {
      var start = i
      if (b >= 0xD800 && b <= 0xDFFF) i++
      var h = encodeURIComponent(str.slice(start, i+1)).substr(1).split('%')
      for (var j = 0; j < h.length; j++) {
        byteArray.push(parseInt(h[j], 16))
      }
    }
  }
  return byteArray
}

function asciiToBytes (str) {
  var byteArray = []
  for (var i = 0; i < str.length; i++) {
    // Node's code seems to be doing this and not & 0x7F..
    byteArray.push(str.charCodeAt(i) & 0xFF)
  }
  return byteArray
}

function utf16leToBytes (str) {
  var c, hi, lo
  var byteArray = []
  for (var i = 0; i < str.length; i++) {
    c = str.charCodeAt(i)
    hi = c >> 8
    lo = c % 256
    byteArray.push(lo)
    byteArray.push(hi)
  }

  return byteArray
}

function base64ToBytes (str) {
  return base64.toByteArray(str)
}

function blitBuffer (src, dst, offset, length, unitSize) {
  if (unitSize) length -= length % unitSize;
  for (var i = 0; i < length; i++) {
    if ((i + offset >= dst.length) || (i >= src.length))
      break
    dst[i + offset] = src[i]
  }
  return i
}

function decodeUtf8Char (str) {
  try {
    return decodeURIComponent(str)
  } catch (err) {
    return String.fromCharCode(0xFFFD) // UTF 8 invalid char
  }
}

},{"base64-js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/node_modules/base64-js/lib/b64.js","ieee754":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/node_modules/ieee754/index.js","is-array":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/node_modules/is-array/index.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/node_modules/base64-js/lib/b64.js":[function(require,module,exports){
var lookup = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

;(function (exports) {
	'use strict';

  var Arr = (typeof Uint8Array !== 'undefined')
    ? Uint8Array
    : Array

	var PLUS   = '+'.charCodeAt(0)
	var SLASH  = '/'.charCodeAt(0)
	var NUMBER = '0'.charCodeAt(0)
	var LOWER  = 'a'.charCodeAt(0)
	var UPPER  = 'A'.charCodeAt(0)

	function decode (elt) {
		var code = elt.charCodeAt(0)
		if (code === PLUS)
			return 62 // '+'
		if (code === SLASH)
			return 63 // '/'
		if (code < NUMBER)
			return -1 //no match
		if (code < NUMBER + 10)
			return code - NUMBER + 26 + 26
		if (code < UPPER + 26)
			return code - UPPER
		if (code < LOWER + 26)
			return code - LOWER + 26
	}

	function b64ToByteArray (b64) {
		var i, j, l, tmp, placeHolders, arr

		if (b64.length % 4 > 0) {
			throw new Error('Invalid string. Length must be a multiple of 4')
		}

		// the number of equal signs (place holders)
		// if there are two placeholders, than the two characters before it
		// represent one byte
		// if there is only one, then the three characters before it represent 2 bytes
		// this is just a cheap hack to not do indexOf twice
		var len = b64.length
		placeHolders = '=' === b64.charAt(len - 2) ? 2 : '=' === b64.charAt(len - 1) ? 1 : 0

		// base64 is 4/3 + up to two characters of the original data
		arr = new Arr(b64.length * 3 / 4 - placeHolders)

		// if there are placeholders, only get up to the last complete 4 chars
		l = placeHolders > 0 ? b64.length - 4 : b64.length

		var L = 0

		function push (v) {
			arr[L++] = v
		}

		for (i = 0, j = 0; i < l; i += 4, j += 3) {
			tmp = (decode(b64.charAt(i)) << 18) | (decode(b64.charAt(i + 1)) << 12) | (decode(b64.charAt(i + 2)) << 6) | decode(b64.charAt(i + 3))
			push((tmp & 0xFF0000) >> 16)
			push((tmp & 0xFF00) >> 8)
			push(tmp & 0xFF)
		}

		if (placeHolders === 2) {
			tmp = (decode(b64.charAt(i)) << 2) | (decode(b64.charAt(i + 1)) >> 4)
			push(tmp & 0xFF)
		} else if (placeHolders === 1) {
			tmp = (decode(b64.charAt(i)) << 10) | (decode(b64.charAt(i + 1)) << 4) | (decode(b64.charAt(i + 2)) >> 2)
			push((tmp >> 8) & 0xFF)
			push(tmp & 0xFF)
		}

		return arr
	}

	function uint8ToBase64 (uint8) {
		var i,
			extraBytes = uint8.length % 3, // if we have 1 byte left, pad 2 bytes
			output = "",
			temp, length

		function encode (num) {
			return lookup.charAt(num)
		}

		function tripletToBase64 (num) {
			return encode(num >> 18 & 0x3F) + encode(num >> 12 & 0x3F) + encode(num >> 6 & 0x3F) + encode(num & 0x3F)
		}

		// go through the array every three bytes, we'll deal with trailing stuff later
		for (i = 0, length = uint8.length - extraBytes; i < length; i += 3) {
			temp = (uint8[i] << 16) + (uint8[i + 1] << 8) + (uint8[i + 2])
			output += tripletToBase64(temp)
		}

		// pad the end with zeros, but make sure to not forget the extra bytes
		switch (extraBytes) {
			case 1:
				temp = uint8[uint8.length - 1]
				output += encode(temp >> 2)
				output += encode((temp << 4) & 0x3F)
				output += '=='
				break
			case 2:
				temp = (uint8[uint8.length - 2] << 8) + (uint8[uint8.length - 1])
				output += encode(temp >> 10)
				output += encode((temp >> 4) & 0x3F)
				output += encode((temp << 2) & 0x3F)
				output += '='
				break
		}

		return output
	}

	exports.toByteArray = b64ToByteArray
	exports.fromByteArray = uint8ToBase64
}(typeof exports === 'undefined' ? (this.base64js = {}) : exports))

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/node_modules/ieee754/index.js":[function(require,module,exports){
exports.read = function (buffer, offset, isLE, mLen, nBytes) {
  var e, m
  var eLen = nBytes * 8 - mLen - 1
  var eMax = (1 << eLen) - 1
  var eBias = eMax >> 1
  var nBits = -7
  var i = isLE ? (nBytes - 1) : 0
  var d = isLE ? -1 : 1
  var s = buffer[offset + i]

  i += d

  e = s & ((1 << (-nBits)) - 1)
  s >>= (-nBits)
  nBits += eLen
  for (; nBits > 0; e = e * 256 + buffer[offset + i], i += d, nBits -= 8) {}

  m = e & ((1 << (-nBits)) - 1)
  e >>= (-nBits)
  nBits += mLen
  for (; nBits > 0; m = m * 256 + buffer[offset + i], i += d, nBits -= 8) {}

  if (e === 0) {
    e = 1 - eBias
  } else if (e === eMax) {
    return m ? NaN : ((s ? -1 : 1) * Infinity)
  } else {
    m = m + Math.pow(2, mLen)
    e = e - eBias
  }
  return (s ? -1 : 1) * m * Math.pow(2, e - mLen)
}

exports.write = function (buffer, value, offset, isLE, mLen, nBytes) {
  var e, m, c
  var eLen = nBytes * 8 - mLen - 1
  var eMax = (1 << eLen) - 1
  var eBias = eMax >> 1
  var rt = (mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0)
  var i = isLE ? 0 : (nBytes - 1)
  var d = isLE ? 1 : -1
  var s = value < 0 || (value === 0 && 1 / value < 0) ? 1 : 0

  value = Math.abs(value)

  if (isNaN(value) || value === Infinity) {
    m = isNaN(value) ? 1 : 0
    e = eMax
  } else {
    e = Math.floor(Math.log(value) / Math.LN2)
    if (value * (c = Math.pow(2, -e)) < 1) {
      e--
      c *= 2
    }
    if (e + eBias >= 1) {
      value += rt / c
    } else {
      value += rt * Math.pow(2, 1 - eBias)
    }
    if (value * c >= 2) {
      e++
      c /= 2
    }

    if (e + eBias >= eMax) {
      m = 0
      e = eMax
    } else if (e + eBias >= 1) {
      m = (value * c - 1) * Math.pow(2, mLen)
      e = e + eBias
    } else {
      m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen)
      e = 0
    }
  }

  for (; mLen >= 8; buffer[offset + i] = m & 0xff, i += d, m /= 256, mLen -= 8) {}

  e = (e << mLen) | m
  eLen += mLen
  for (; eLen > 0; buffer[offset + i] = e & 0xff, i += d, e /= 256, eLen -= 8) {}

  buffer[offset + i - d] |= s * 128
}

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/node_modules/is-array/index.js":[function(require,module,exports){

/**
 * isArray
 */

var isArray = Array.isArray;

/**
 * toString
 */

var str = Object.prototype.toString;

/**
 * Whether or not the given `val`
 * is an array.
 *
 * example:
 *
 *        isArray([]);
 *        // > true
 *        isArray(arguments);
 *        // > false
 *        isArray('');
 *        // > false
 *
 * @param {mixed} val
 * @return {bool}
 */

module.exports = isArray || function (val) {
  return !! val && '[object Array]' == str.call(val);
};

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/events/events.js":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

function EventEmitter() {
  this._events = this._events || {};
  this._maxListeners = this._maxListeners || undefined;
}
module.exports = EventEmitter;

// Backwards-compat with node 0.10.x
EventEmitter.EventEmitter = EventEmitter;

EventEmitter.prototype._events = undefined;
EventEmitter.prototype._maxListeners = undefined;

// By default EventEmitters will print a warning if more than 10 listeners are
// added to it. This is a useful default which helps finding memory leaks.
EventEmitter.defaultMaxListeners = 10;

// Obviously not all Emitters should be limited to 10. This function allows
// that to be increased. Set to zero for unlimited.
EventEmitter.prototype.setMaxListeners = function(n) {
  if (!isNumber(n) || n < 0 || isNaN(n))
    throw TypeError('n must be a positive number');
  this._maxListeners = n;
  return this;
};

EventEmitter.prototype.emit = function(type) {
  var er, handler, len, args, i, listeners;

  if (!this._events)
    this._events = {};

  // If there is no 'error' event listener then throw.
  if (type === 'error') {
    if (!this._events.error ||
        (isObject(this._events.error) && !this._events.error.length)) {
      er = arguments[1];
      if (er instanceof Error) {
        throw er; // Unhandled 'error' event
      }
      throw TypeError('Uncaught, unspecified "error" event.');
    }
  }

  handler = this._events[type];

  if (isUndefined(handler))
    return false;

  if (isFunction(handler)) {
    switch (arguments.length) {
      // fast cases
      case 1:
        handler.call(this);
        break;
      case 2:
        handler.call(this, arguments[1]);
        break;
      case 3:
        handler.call(this, arguments[1], arguments[2]);
        break;
      // slower
      default:
        len = arguments.length;
        args = new Array(len - 1);
        for (i = 1; i < len; i++)
          args[i - 1] = arguments[i];
        handler.apply(this, args);
    }
  } else if (isObject(handler)) {
    len = arguments.length;
    args = new Array(len - 1);
    for (i = 1; i < len; i++)
      args[i - 1] = arguments[i];

    listeners = handler.slice();
    len = listeners.length;
    for (i = 0; i < len; i++)
      listeners[i].apply(this, args);
  }

  return true;
};

EventEmitter.prototype.addListener = function(type, listener) {
  var m;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events)
    this._events = {};

  // To avoid recursion in the case that type === "newListener"! Before
  // adding it to the listeners, first emit "newListener".
  if (this._events.newListener)
    this.emit('newListener', type,
              isFunction(listener.listener) ?
              listener.listener : listener);

  if (!this._events[type])
    // Optimize the case of one listener. Don't need the extra array object.
    this._events[type] = listener;
  else if (isObject(this._events[type]))
    // If we've already got an array, just append.
    this._events[type].push(listener);
  else
    // Adding the second element, need to change to array.
    this._events[type] = [this._events[type], listener];

  // Check for listener leak
  if (isObject(this._events[type]) && !this._events[type].warned) {
    var m;
    if (!isUndefined(this._maxListeners)) {
      m = this._maxListeners;
    } else {
      m = EventEmitter.defaultMaxListeners;
    }

    if (m && m > 0 && this._events[type].length > m) {
      this._events[type].warned = true;
      console.error('(node) warning: possible EventEmitter memory ' +
                    'leak detected. %d listeners added. ' +
                    'Use emitter.setMaxListeners() to increase limit.',
                    this._events[type].length);
      if (typeof console.trace === 'function') {
        // not supported in IE 10
        console.trace();
      }
    }
  }

  return this;
};

EventEmitter.prototype.on = EventEmitter.prototype.addListener;

EventEmitter.prototype.once = function(type, listener) {
  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  var fired = false;

  function g() {
    this.removeListener(type, g);

    if (!fired) {
      fired = true;
      listener.apply(this, arguments);
    }
  }

  g.listener = listener;
  this.on(type, g);

  return this;
};

// emits a 'removeListener' event iff the listener was removed
EventEmitter.prototype.removeListener = function(type, listener) {
  var list, position, length, i;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events || !this._events[type])
    return this;

  list = this._events[type];
  length = list.length;
  position = -1;

  if (list === listener ||
      (isFunction(list.listener) && list.listener === listener)) {
    delete this._events[type];
    if (this._events.removeListener)
      this.emit('removeListener', type, listener);

  } else if (isObject(list)) {
    for (i = length; i-- > 0;) {
      if (list[i] === listener ||
          (list[i].listener && list[i].listener === listener)) {
        position = i;
        break;
      }
    }

    if (position < 0)
      return this;

    if (list.length === 1) {
      list.length = 0;
      delete this._events[type];
    } else {
      list.splice(position, 1);
    }

    if (this._events.removeListener)
      this.emit('removeListener', type, listener);
  }

  return this;
};

EventEmitter.prototype.removeAllListeners = function(type) {
  var key, listeners;

  if (!this._events)
    return this;

  // not listening for removeListener, no need to emit
  if (!this._events.removeListener) {
    if (arguments.length === 0)
      this._events = {};
    else if (this._events[type])
      delete this._events[type];
    return this;
  }

  // emit removeListener for all listeners on all events
  if (arguments.length === 0) {
    for (key in this._events) {
      if (key === 'removeListener') continue;
      this.removeAllListeners(key);
    }
    this.removeAllListeners('removeListener');
    this._events = {};
    return this;
  }

  listeners = this._events[type];

  if (isFunction(listeners)) {
    this.removeListener(type, listeners);
  } else {
    // LIFO order
    while (listeners.length)
      this.removeListener(type, listeners[listeners.length - 1]);
  }
  delete this._events[type];

  return this;
};

EventEmitter.prototype.listeners = function(type) {
  var ret;
  if (!this._events || !this._events[type])
    ret = [];
  else if (isFunction(this._events[type]))
    ret = [this._events[type]];
  else
    ret = this._events[type].slice();
  return ret;
};

EventEmitter.listenerCount = function(emitter, type) {
  var ret;
  if (!emitter._events || !emitter._events[type])
    ret = 0;
  else if (isFunction(emitter._events[type]))
    ret = 1;
  else
    ret = emitter._events[type].length;
  return ret;
};

function isFunction(arg) {
  return typeof arg === 'function';
}

function isNumber(arg) {
  return typeof arg === 'number';
}

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}

function isUndefined(arg) {
  return arg === void 0;
}

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/http-browserify/index.js":[function(require,module,exports){
var http = module.exports;
var EventEmitter = require('events').EventEmitter;
var Request = require('./lib/request');
var url = require('url')

http.request = function (params, cb) {
    if (typeof params === 'string') {
        params = url.parse(params)
    }
    if (!params) params = {};
    if (!params.host && !params.port) {
        params.port = parseInt(window.location.port, 10);
    }
    if (!params.host && params.hostname) {
        params.host = params.hostname;
    }

    if (!params.protocol) {
        if (params.scheme) {
            params.protocol = params.scheme + ':';
        } else {
            params.protocol = window.location.protocol;
        }
    }

    if (!params.host) {
        params.host = window.location.hostname || window.location.host;
    }
    if (/:/.test(params.host)) {
        if (!params.port) {
            params.port = params.host.split(':')[1];
        }
        params.host = params.host.split(':')[0];
    }
    if (!params.port) params.port = params.protocol == 'https:' ? 443 : 80;
    
    var req = new Request(new xhrHttp, params);
    if (cb) req.on('response', cb);
    return req;
};

http.get = function (params, cb) {
    params.method = 'GET';
    var req = http.request(params, cb);
    req.end();
    return req;
};

http.Agent = function () {};
http.Agent.defaultMaxSockets = 4;

var xhrHttp = (function () {
    if (typeof window === 'undefined') {
        throw new Error('no window object present');
    }
    else if (window.XMLHttpRequest) {
        return window.XMLHttpRequest;
    }
    else if (window.ActiveXObject) {
        var axs = [
            'Msxml2.XMLHTTP.6.0',
            'Msxml2.XMLHTTP.3.0',
            'Microsoft.XMLHTTP'
        ];
        for (var i = 0; i < axs.length; i++) {
            try {
                var ax = new(window.ActiveXObject)(axs[i]);
                return function () {
                    if (ax) {
                        var ax_ = ax;
                        ax = null;
                        return ax_;
                    }
                    else {
                        return new(window.ActiveXObject)(axs[i]);
                    }
                };
            }
            catch (e) {}
        }
        throw new Error('ajax not supported in this browser')
    }
    else {
        throw new Error('ajax not supported in this browser');
    }
})();

http.STATUS_CODES = {
    100 : 'Continue',
    101 : 'Switching Protocols',
    102 : 'Processing',                 // RFC 2518, obsoleted by RFC 4918
    200 : 'OK',
    201 : 'Created',
    202 : 'Accepted',
    203 : 'Non-Authoritative Information',
    204 : 'No Content',
    205 : 'Reset Content',
    206 : 'Partial Content',
    207 : 'Multi-Status',               // RFC 4918
    300 : 'Multiple Choices',
    301 : 'Moved Permanently',
    302 : 'Moved Temporarily',
    303 : 'See Other',
    304 : 'Not Modified',
    305 : 'Use Proxy',
    307 : 'Temporary Redirect',
    400 : 'Bad Request',
    401 : 'Unauthorized',
    402 : 'Payment Required',
    403 : 'Forbidden',
    404 : 'Not Found',
    405 : 'Method Not Allowed',
    406 : 'Not Acceptable',
    407 : 'Proxy Authentication Required',
    408 : 'Request Time-out',
    409 : 'Conflict',
    410 : 'Gone',
    411 : 'Length Required',
    412 : 'Precondition Failed',
    413 : 'Request Entity Too Large',
    414 : 'Request-URI Too Large',
    415 : 'Unsupported Media Type',
    416 : 'Requested Range Not Satisfiable',
    417 : 'Expectation Failed',
    418 : 'I\'m a teapot',              // RFC 2324
    422 : 'Unprocessable Entity',       // RFC 4918
    423 : 'Locked',                     // RFC 4918
    424 : 'Failed Dependency',          // RFC 4918
    425 : 'Unordered Collection',       // RFC 4918
    426 : 'Upgrade Required',           // RFC 2817
    428 : 'Precondition Required',      // RFC 6585
    429 : 'Too Many Requests',          // RFC 6585
    431 : 'Request Header Fields Too Large',// RFC 6585
    500 : 'Internal Server Error',
    501 : 'Not Implemented',
    502 : 'Bad Gateway',
    503 : 'Service Unavailable',
    504 : 'Gateway Time-out',
    505 : 'HTTP Version Not Supported',
    506 : 'Variant Also Negotiates',    // RFC 2295
    507 : 'Insufficient Storage',       // RFC 4918
    509 : 'Bandwidth Limit Exceeded',
    510 : 'Not Extended',               // RFC 2774
    511 : 'Network Authentication Required' // RFC 6585
};
},{"./lib/request":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/http-browserify/lib/request.js","events":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/events/events.js","url":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/url/url.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/http-browserify/lib/request.js":[function(require,module,exports){
var Stream = require('stream');
var Response = require('./response');
var Base64 = require('Base64');
var inherits = require('inherits');

var Request = module.exports = function (xhr, params) {
    var self = this;
    self.writable = true;
    self.xhr = xhr;
    self.body = [];
    
    self.uri = (params.protocol || 'http:') + '//'
        + params.host
        + (params.port ? ':' + params.port : '')
        + (params.path || '/')
    ;
    
    if (typeof params.withCredentials === 'undefined') {
        params.withCredentials = true;
    }

    try { xhr.withCredentials = params.withCredentials }
    catch (e) {}
    
    if (params.responseType) try { xhr.responseType = params.responseType }
    catch (e) {}
    
    xhr.open(
        params.method || 'GET',
        self.uri,
        true
    );

    xhr.onerror = function(event) {
        self.emit('error', new Error('Network error'));
    };

    self._headers = {};
    
    if (params.headers) {
        var keys = objectKeys(params.headers);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            if (!self.isSafeRequestHeader(key)) continue;
            var value = params.headers[key];
            self.setHeader(key, value);
        }
    }
    
    if (params.auth) {
        //basic auth
        this.setHeader('Authorization', 'Basic ' + Base64.btoa(params.auth));
    }

    var res = new Response;
    res.on('close', function () {
        self.emit('close');
    });
    
    res.on('ready', function () {
        self.emit('response', res);
    });

    res.on('error', function (err) {
        self.emit('error', err);
    });
    
    xhr.onreadystatechange = function () {
        // Fix for IE9 bug
        // SCRIPT575: Could not complete the operation due to error c00c023f
        // It happens when a request is aborted, calling the success callback anyway with readyState === 4
        if (xhr.__aborted) return;
        res.handle(xhr);
    };
};

inherits(Request, Stream);

Request.prototype.setHeader = function (key, value) {
    this._headers[key.toLowerCase()] = value
};

Request.prototype.getHeader = function (key) {
    return this._headers[key.toLowerCase()]
};

Request.prototype.removeHeader = function (key) {
    delete this._headers[key.toLowerCase()]
};

Request.prototype.write = function (s) {
    this.body.push(s);
};

Request.prototype.destroy = function (s) {
    this.xhr.__aborted = true;
    this.xhr.abort();
    this.emit('close');
};

Request.prototype.end = function (s) {
    if (s !== undefined) this.body.push(s);

    var keys = objectKeys(this._headers);
    for (var i = 0; i < keys.length; i++) {
        var key = keys[i];
        var value = this._headers[key];
        if (isArray(value)) {
            for (var j = 0; j < value.length; j++) {
                this.xhr.setRequestHeader(key, value[j]);
            }
        }
        else this.xhr.setRequestHeader(key, value)
    }

    if (this.body.length === 0) {
        this.xhr.send('');
    }
    else if (typeof this.body[0] === 'string') {
        this.xhr.send(this.body.join(''));
    }
    else if (isArray(this.body[0])) {
        var body = [];
        for (var i = 0; i < this.body.length; i++) {
            body.push.apply(body, this.body[i]);
        }
        this.xhr.send(body);
    }
    else if (/Array/.test(Object.prototype.toString.call(this.body[0]))) {
        var len = 0;
        for (var i = 0; i < this.body.length; i++) {
            len += this.body[i].length;
        }
        var body = new(this.body[0].constructor)(len);
        var k = 0;
        
        for (var i = 0; i < this.body.length; i++) {
            var b = this.body[i];
            for (var j = 0; j < b.length; j++) {
                body[k++] = b[j];
            }
        }
        this.xhr.send(body);
    }
    else if (isXHR2Compatible(this.body[0])) {
        this.xhr.send(this.body[0]);
    }
    else {
        var body = '';
        for (var i = 0; i < this.body.length; i++) {
            body += this.body[i].toString();
        }
        this.xhr.send(body);
    }
};

// Taken from http://dxr.mozilla.org/mozilla/mozilla-central/content/base/src/nsXMLHttpRequest.cpp.html
Request.unsafeHeaders = [
    "accept-charset",
    "accept-encoding",
    "access-control-request-headers",
    "access-control-request-method",
    "connection",
    "content-length",
    "cookie",
    "cookie2",
    "content-transfer-encoding",
    "date",
    "expect",
    "host",
    "keep-alive",
    "origin",
    "referer",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade",
    "user-agent",
    "via"
];

Request.prototype.isSafeRequestHeader = function (headerName) {
    if (!headerName) return false;
    return indexOf(Request.unsafeHeaders, headerName.toLowerCase()) === -1;
};

var objectKeys = Object.keys || function (obj) {
    var keys = [];
    for (var key in obj) keys.push(key);
    return keys;
};

var isArray = Array.isArray || function (xs) {
    return Object.prototype.toString.call(xs) === '[object Array]';
};

var indexOf = function (xs, x) {
    if (xs.indexOf) return xs.indexOf(x);
    for (var i = 0; i < xs.length; i++) {
        if (xs[i] === x) return i;
    }
    return -1;
};

var isXHR2Compatible = function (obj) {
    if (typeof Blob !== 'undefined' && obj instanceof Blob) return true;
    if (typeof ArrayBuffer !== 'undefined' && obj instanceof ArrayBuffer) return true;
    if (typeof FormData !== 'undefined' && obj instanceof FormData) return true;
};

},{"./response":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/http-browserify/lib/response.js","Base64":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/http-browserify/node_modules/Base64/base64.js","inherits":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js","stream":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/stream-browserify/index.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/http-browserify/lib/response.js":[function(require,module,exports){
var Stream = require('stream');
var util = require('util');

var Response = module.exports = function (res) {
    this.offset = 0;
    this.readable = true;
};

util.inherits(Response, Stream);

var capable = {
    streaming : true,
    status2 : true
};

function parseHeaders (res) {
    var lines = res.getAllResponseHeaders().split(/\r?\n/);
    var headers = {};
    for (var i = 0; i < lines.length; i++) {
        var line = lines[i];
        if (line === '') continue;
        
        var m = line.match(/^([^:]+):\s*(.*)/);
        if (m) {
            var key = m[1].toLowerCase(), value = m[2];
            
            if (headers[key] !== undefined) {
            
                if (isArray(headers[key])) {
                    headers[key].push(value);
                }
                else {
                    headers[key] = [ headers[key], value ];
                }
            }
            else {
                headers[key] = value;
            }
        }
        else {
            headers[line] = true;
        }
    }
    return headers;
}

Response.prototype.getResponse = function (xhr) {
    var respType = String(xhr.responseType).toLowerCase();
    if (respType === 'blob') return xhr.responseBlob || xhr.response;
    if (respType === 'arraybuffer') return xhr.response;
    return xhr.responseText;
}

Response.prototype.getHeader = function (key) {
    return this.headers[key.toLowerCase()];
};

Response.prototype.handle = function (res) {
    if (res.readyState === 2 && capable.status2) {
        try {
            this.statusCode = res.status;
            this.headers = parseHeaders(res);
        }
        catch (err) {
            capable.status2 = false;
        }
        
        if (capable.status2) {
            this.emit('ready');
        }
    }
    else if (capable.streaming && res.readyState === 3) {
        try {
            if (!this.statusCode) {
                this.statusCode = res.status;
                this.headers = parseHeaders(res);
                this.emit('ready');
            }
        }
        catch (err) {}
        
        try {
            this._emitData(res);
        }
        catch (err) {
            capable.streaming = false;
        }
    }
    else if (res.readyState === 4) {
        if (!this.statusCode) {
            this.statusCode = res.status;
            this.emit('ready');
        }
        this._emitData(res);
        
        if (res.error) {
            this.emit('error', this.getResponse(res));
        }
        else this.emit('end');
        
        this.emit('close');
    }
};

Response.prototype._emitData = function (res) {
    var respBody = this.getResponse(res);
    if (respBody.toString().match(/ArrayBuffer/)) {
        this.emit('data', new Uint8Array(respBody, this.offset));
        this.offset = respBody.byteLength;
        return;
    }
    if (respBody.length > this.offset) {
        this.emit('data', respBody.slice(this.offset));
        this.offset = respBody.length;
    }
};

var isArray = Array.isArray || function (xs) {
    return Object.prototype.toString.call(xs) === '[object Array]';
};

},{"stream":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/stream-browserify/index.js","util":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/util/util.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/http-browserify/node_modules/Base64/base64.js":[function(require,module,exports){
;(function () {

  var object = typeof exports != 'undefined' ? exports : this; // #8: web workers
  var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';

  function InvalidCharacterError(message) {
    this.message = message;
  }
  InvalidCharacterError.prototype = new Error;
  InvalidCharacterError.prototype.name = 'InvalidCharacterError';

  // encoder
  // [https://gist.github.com/999166] by [https://github.com/nignag]
  object.btoa || (
  object.btoa = function (input) {
    for (
      // initialize result and counter
      var block, charCode, idx = 0, map = chars, output = '';
      // if the next input index does not exist:
      //   change the mapping table to "="
      //   check if d has no fractional digits
      input.charAt(idx | 0) || (map = '=', idx % 1);
      // "8 - idx % 1 * 8" generates the sequence 2, 4, 6, 8
      output += map.charAt(63 & block >> 8 - idx % 1 * 8)
    ) {
      charCode = input.charCodeAt(idx += 3/4);
      if (charCode > 0xFF) {
        throw new InvalidCharacterError("'btoa' failed: The string to be encoded contains characters outside of the Latin1 range.");
      }
      block = block << 8 | charCode;
    }
    return output;
  });

  // decoder
  // [https://gist.github.com/1020396] by [https://github.com/atk]
  object.atob || (
  object.atob = function (input) {
    input = input.replace(/=+$/, '');
    if (input.length % 4 == 1) {
      throw new InvalidCharacterError("'atob' failed: The string to be decoded is not correctly encoded.");
    }
    for (
      // initialize result and counters
      var bc = 0, bs, buffer, idx = 0, output = '';
      // get next character
      buffer = input.charAt(idx++);
      // character found in table? initialize bit storage and add its ascii value;
      ~buffer && (bs = bc % 4 ? bs * 64 + buffer : buffer,
        // and if not first of each 4 characters,
        // convert the first 8 bits to one ascii character
        bc++ % 4) ? output += String.fromCharCode(255 & bs >> (-2 * bc & 6)) : 0
    ) {
      // try to find character in table (0-63, not found => -1)
      buffer = chars.indexOf(buffer);
    }
    return output;
  });

}());

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js":[function(require,module,exports){
if (typeof Object.create === 'function') {
  // implementation from standard node.js 'util' module
  module.exports = function inherits(ctor, superCtor) {
    ctor.super_ = superCtor
    ctor.prototype = Object.create(superCtor.prototype, {
      constructor: {
        value: ctor,
        enumerable: false,
        writable: true,
        configurable: true
      }
    });
  };
} else {
  // old school shim for old browsers
  module.exports = function inherits(ctor, superCtor) {
    ctor.super_ = superCtor
    var TempCtor = function () {}
    TempCtor.prototype = superCtor.prototype
    ctor.prototype = new TempCtor()
    ctor.prototype.constructor = ctor
  }
}

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/insert-module-globals/node_modules/is-buffer/index.js":[function(require,module,exports){
/*!
 * Determine if an object is a Buffer
 *
 * @author   Feross Aboukhadijeh <feross@feross.org> <http://feross.org>
 * @license  MIT
 */

// The _isBuffer check is for Safari 5-7 support, because it's missing
// Object.prototype.constructor. Remove this eventually
module.exports = function (obj) {
  return obj != null && (isBuffer(obj) || isSlowBuffer(obj) || !!obj._isBuffer)
}

function isBuffer (obj) {
  return !!obj.constructor && typeof obj.constructor.isBuffer === 'function' && obj.constructor.isBuffer(obj)
}

// For Node v0.10 support. Remove this eventually.
function isSlowBuffer (obj) {
  return typeof obj.readFloatLE === 'function' && typeof obj.slice === 'function' && isBuffer(obj.slice(0, 0))
}

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/isarray/index.js":[function(require,module,exports){
module.exports = Array.isArray || function (arr) {
  return Object.prototype.toString.call(arr) == '[object Array]';
};

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/process/browser.js":[function(require,module,exports){
// shim for using process in browser

var process = module.exports = {};

process.nextTick = (function () {
    var canSetImmediate = typeof window !== 'undefined'
    && window.setImmediate;
    var canMutationObserver = typeof window !== 'undefined'
    && window.MutationObserver;
    var canPost = typeof window !== 'undefined'
    && window.postMessage && window.addEventListener
    ;

    if (canSetImmediate) {
        return function (f) { return window.setImmediate(f) };
    }

    var queue = [];

    if (canMutationObserver) {
        var hiddenDiv = document.createElement("div");
        var observer = new MutationObserver(function () {
            var queueList = queue.slice();
            queue.length = 0;
            queueList.forEach(function (fn) {
                fn();
            });
        });

        observer.observe(hiddenDiv, { attributes: true });

        return function nextTick(fn) {
            if (!queue.length) {
                hiddenDiv.setAttribute('yes', 'no');
            }
            queue.push(fn);
        };
    }

    if (canPost) {
        window.addEventListener('message', function (ev) {
            var source = ev.source;
            if ((source === window || source === null) && ev.data === 'process-tick') {
                ev.stopPropagation();
                if (queue.length > 0) {
                    var fn = queue.shift();
                    fn();
                }
            }
        }, true);

        return function nextTick(fn) {
            queue.push(fn);
            window.postMessage('process-tick', '*');
        };
    }

    return function nextTick(fn) {
        setTimeout(fn, 0);
    };
})();

process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

// TODO(shtylman)
process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/punycode/punycode.js":[function(require,module,exports){
(function (global){
/*! http://mths.be/punycode v1.2.4 by @mathias */
;(function(root) {

	/** Detect free variables */
	var freeExports = typeof exports == 'object' && exports;
	var freeModule = typeof module == 'object' && module &&
		module.exports == freeExports && module;
	var freeGlobal = typeof global == 'object' && global;
	if (freeGlobal.global === freeGlobal || freeGlobal.window === freeGlobal) {
		root = freeGlobal;
	}

	/**
	 * The `punycode` object.
	 * @name punycode
	 * @type Object
	 */
	var punycode,

	/** Highest positive signed 32-bit float value */
	maxInt = 2147483647, // aka. 0x7FFFFFFF or 2^31-1

	/** Bootstring parameters */
	base = 36,
	tMin = 1,
	tMax = 26,
	skew = 38,
	damp = 700,
	initialBias = 72,
	initialN = 128, // 0x80
	delimiter = '-', // '\x2D'

	/** Regular expressions */
	regexPunycode = /^xn--/,
	regexNonASCII = /[^ -~]/, // unprintable ASCII chars + non-ASCII chars
	regexSeparators = /\x2E|\u3002|\uFF0E|\uFF61/g, // RFC 3490 separators

	/** Error messages */
	errors = {
		'overflow': 'Overflow: input needs wider integers to process',
		'not-basic': 'Illegal input >= 0x80 (not a basic code point)',
		'invalid-input': 'Invalid input'
	},

	/** Convenience shortcuts */
	baseMinusTMin = base - tMin,
	floor = Math.floor,
	stringFromCharCode = String.fromCharCode,

	/** Temporary variable */
	key;

	/*--------------------------------------------------------------------------*/

	/**
	 * A generic error utility function.
	 * @private
	 * @param {String} type The error type.
	 * @returns {Error} Throws a `RangeError` with the applicable error message.
	 */
	function error(type) {
		throw RangeError(errors[type]);
	}

	/**
	 * A generic `Array#map` utility function.
	 * @private
	 * @param {Array} array The array to iterate over.
	 * @param {Function} callback The function that gets called for every array
	 * item.
	 * @returns {Array} A new array of values returned by the callback function.
	 */
	function map(array, fn) {
		var length = array.length;
		while (length--) {
			array[length] = fn(array[length]);
		}
		return array;
	}

	/**
	 * A simple `Array#map`-like wrapper to work with domain name strings.
	 * @private
	 * @param {String} domain The domain name.
	 * @param {Function} callback The function that gets called for every
	 * character.
	 * @returns {Array} A new string of characters returned by the callback
	 * function.
	 */
	function mapDomain(string, fn) {
		return map(string.split(regexSeparators), fn).join('.');
	}

	/**
	 * Creates an array containing the numeric code points of each Unicode
	 * character in the string. While JavaScript uses UCS-2 internally,
	 * this function will convert a pair of surrogate halves (each of which
	 * UCS-2 exposes as separate characters) into a single code point,
	 * matching UTF-16.
	 * @see `punycode.ucs2.encode`
	 * @see <http://mathiasbynens.be/notes/javascript-encoding>
	 * @memberOf punycode.ucs2
	 * @name decode
	 * @param {String} string The Unicode input string (UCS-2).
	 * @returns {Array} The new array of code points.
	 */
	function ucs2decode(string) {
		var output = [],
		    counter = 0,
		    length = string.length,
		    value,
		    extra;
		while (counter < length) {
			value = string.charCodeAt(counter++);
			if (value >= 0xD800 && value <= 0xDBFF && counter < length) {
				// high surrogate, and there is a next character
				extra = string.charCodeAt(counter++);
				if ((extra & 0xFC00) == 0xDC00) { // low surrogate
					output.push(((value & 0x3FF) << 10) + (extra & 0x3FF) + 0x10000);
				} else {
					// unmatched surrogate; only append this code unit, in case the next
					// code unit is the high surrogate of a surrogate pair
					output.push(value);
					counter--;
				}
			} else {
				output.push(value);
			}
		}
		return output;
	}

	/**
	 * Creates a string based on an array of numeric code points.
	 * @see `punycode.ucs2.decode`
	 * @memberOf punycode.ucs2
	 * @name encode
	 * @param {Array} codePoints The array of numeric code points.
	 * @returns {String} The new Unicode string (UCS-2).
	 */
	function ucs2encode(array) {
		return map(array, function(value) {
			var output = '';
			if (value > 0xFFFF) {
				value -= 0x10000;
				output += stringFromCharCode(value >>> 10 & 0x3FF | 0xD800);
				value = 0xDC00 | value & 0x3FF;
			}
			output += stringFromCharCode(value);
			return output;
		}).join('');
	}

	/**
	 * Converts a basic code point into a digit/integer.
	 * @see `digitToBasic()`
	 * @private
	 * @param {Number} codePoint The basic numeric code point value.
	 * @returns {Number} The numeric value of a basic code point (for use in
	 * representing integers) in the range `0` to `base - 1`, or `base` if
	 * the code point does not represent a value.
	 */
	function basicToDigit(codePoint) {
		if (codePoint - 48 < 10) {
			return codePoint - 22;
		}
		if (codePoint - 65 < 26) {
			return codePoint - 65;
		}
		if (codePoint - 97 < 26) {
			return codePoint - 97;
		}
		return base;
	}

	/**
	 * Converts a digit/integer into a basic code point.
	 * @see `basicToDigit()`
	 * @private
	 * @param {Number} digit The numeric value of a basic code point.
	 * @returns {Number} The basic code point whose value (when used for
	 * representing integers) is `digit`, which needs to be in the range
	 * `0` to `base - 1`. If `flag` is non-zero, the uppercase form is
	 * used; else, the lowercase form is used. The behavior is undefined
	 * if `flag` is non-zero and `digit` has no uppercase form.
	 */
	function digitToBasic(digit, flag) {
		//  0..25 map to ASCII a..z or A..Z
		// 26..35 map to ASCII 0..9
		return digit + 22 + 75 * (digit < 26) - ((flag != 0) << 5);
	}

	/**
	 * Bias adaptation function as per section 3.4 of RFC 3492.
	 * http://tools.ietf.org/html/rfc3492#section-3.4
	 * @private
	 */
	function adapt(delta, numPoints, firstTime) {
		var k = 0;
		delta = firstTime ? floor(delta / damp) : delta >> 1;
		delta += floor(delta / numPoints);
		for (/* no initialization */; delta > baseMinusTMin * tMax >> 1; k += base) {
			delta = floor(delta / baseMinusTMin);
		}
		return floor(k + (baseMinusTMin + 1) * delta / (delta + skew));
	}

	/**
	 * Converts a Punycode string of ASCII-only symbols to a string of Unicode
	 * symbols.
	 * @memberOf punycode
	 * @param {String} input The Punycode string of ASCII-only symbols.
	 * @returns {String} The resulting string of Unicode symbols.
	 */
	function decode(input) {
		// Don't use UCS-2
		var output = [],
		    inputLength = input.length,
		    out,
		    i = 0,
		    n = initialN,
		    bias = initialBias,
		    basic,
		    j,
		    index,
		    oldi,
		    w,
		    k,
		    digit,
		    t,
		    /** Cached calculation results */
		    baseMinusT;

		// Handle the basic code points: let `basic` be the number of input code
		// points before the last delimiter, or `0` if there is none, then copy
		// the first basic code points to the output.

		basic = input.lastIndexOf(delimiter);
		if (basic < 0) {
			basic = 0;
		}

		for (j = 0; j < basic; ++j) {
			// if it's not a basic code point
			if (input.charCodeAt(j) >= 0x80) {
				error('not-basic');
			}
			output.push(input.charCodeAt(j));
		}

		// Main decoding loop: start just after the last delimiter if any basic code
		// points were copied; start at the beginning otherwise.

		for (index = basic > 0 ? basic + 1 : 0; index < inputLength; /* no final expression */) {

			// `index` is the index of the next character to be consumed.
			// Decode a generalized variable-length integer into `delta`,
			// which gets added to `i`. The overflow checking is easier
			// if we increase `i` as we go, then subtract off its starting
			// value at the end to obtain `delta`.
			for (oldi = i, w = 1, k = base; /* no condition */; k += base) {

				if (index >= inputLength) {
					error('invalid-input');
				}

				digit = basicToDigit(input.charCodeAt(index++));

				if (digit >= base || digit > floor((maxInt - i) / w)) {
					error('overflow');
				}

				i += digit * w;
				t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);

				if (digit < t) {
					break;
				}

				baseMinusT = base - t;
				if (w > floor(maxInt / baseMinusT)) {
					error('overflow');
				}

				w *= baseMinusT;

			}

			out = output.length + 1;
			bias = adapt(i - oldi, out, oldi == 0);

			// `i` was supposed to wrap around from `out` to `0`,
			// incrementing `n` each time, so we'll fix that now:
			if (floor(i / out) > maxInt - n) {
				error('overflow');
			}

			n += floor(i / out);
			i %= out;

			// Insert `n` at position `i` of the output
			output.splice(i++, 0, n);

		}

		return ucs2encode(output);
	}

	/**
	 * Converts a string of Unicode symbols to a Punycode string of ASCII-only
	 * symbols.
	 * @memberOf punycode
	 * @param {String} input The string of Unicode symbols.
	 * @returns {String} The resulting Punycode string of ASCII-only symbols.
	 */
	function encode(input) {
		var n,
		    delta,
		    handledCPCount,
		    basicLength,
		    bias,
		    j,
		    m,
		    q,
		    k,
		    t,
		    currentValue,
		    output = [],
		    /** `inputLength` will hold the number of code points in `input`. */
		    inputLength,
		    /** Cached calculation results */
		    handledCPCountPlusOne,
		    baseMinusT,
		    qMinusT;

		// Convert the input in UCS-2 to Unicode
		input = ucs2decode(input);

		// Cache the length
		inputLength = input.length;

		// Initialize the state
		n = initialN;
		delta = 0;
		bias = initialBias;

		// Handle the basic code points
		for (j = 0; j < inputLength; ++j) {
			currentValue = input[j];
			if (currentValue < 0x80) {
				output.push(stringFromCharCode(currentValue));
			}
		}

		handledCPCount = basicLength = output.length;

		// `handledCPCount` is the number of code points that have been handled;
		// `basicLength` is the number of basic code points.

		// Finish the basic string - if it is not empty - with a delimiter
		if (basicLength) {
			output.push(delimiter);
		}

		// Main encoding loop:
		while (handledCPCount < inputLength) {

			// All non-basic code points < n have been handled already. Find the next
			// larger one:
			for (m = maxInt, j = 0; j < inputLength; ++j) {
				currentValue = input[j];
				if (currentValue >= n && currentValue < m) {
					m = currentValue;
				}
			}

			// Increase `delta` enough to advance the decoder's <n,i> state to <m,0>,
			// but guard against overflow
			handledCPCountPlusOne = handledCPCount + 1;
			if (m - n > floor((maxInt - delta) / handledCPCountPlusOne)) {
				error('overflow');
			}

			delta += (m - n) * handledCPCountPlusOne;
			n = m;

			for (j = 0; j < inputLength; ++j) {
				currentValue = input[j];

				if (currentValue < n && ++delta > maxInt) {
					error('overflow');
				}

				if (currentValue == n) {
					// Represent delta as a generalized variable-length integer
					for (q = delta, k = base; /* no condition */; k += base) {
						t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);
						if (q < t) {
							break;
						}
						qMinusT = q - t;
						baseMinusT = base - t;
						output.push(
							stringFromCharCode(digitToBasic(t + qMinusT % baseMinusT, 0))
						);
						q = floor(qMinusT / baseMinusT);
					}

					output.push(stringFromCharCode(digitToBasic(q, 0)));
					bias = adapt(delta, handledCPCountPlusOne, handledCPCount == basicLength);
					delta = 0;
					++handledCPCount;
				}
			}

			++delta;
			++n;

		}
		return output.join('');
	}

	/**
	 * Converts a Punycode string representing a domain name to Unicode. Only the
	 * Punycoded parts of the domain name will be converted, i.e. it doesn't
	 * matter if you call it on a string that has already been converted to
	 * Unicode.
	 * @memberOf punycode
	 * @param {String} domain The Punycode domain name to convert to Unicode.
	 * @returns {String} The Unicode representation of the given Punycode
	 * string.
	 */
	function toUnicode(domain) {
		return mapDomain(domain, function(string) {
			return regexPunycode.test(string)
				? decode(string.slice(4).toLowerCase())
				: string;
		});
	}

	/**
	 * Converts a Unicode string representing a domain name to Punycode. Only the
	 * non-ASCII parts of the domain name will be converted, i.e. it doesn't
	 * matter if you call it with a domain that's already in ASCII.
	 * @memberOf punycode
	 * @param {String} domain The domain name to convert, as a Unicode string.
	 * @returns {String} The Punycode representation of the given domain name.
	 */
	function toASCII(domain) {
		return mapDomain(domain, function(string) {
			return regexNonASCII.test(string)
				? 'xn--' + encode(string)
				: string;
		});
	}

	/*--------------------------------------------------------------------------*/

	/** Define the public API */
	punycode = {
		/**
		 * A string representing the current Punycode.js version number.
		 * @memberOf punycode
		 * @type String
		 */
		'version': '1.2.4',
		/**
		 * An object of methods to convert from JavaScript's internal character
		 * representation (UCS-2) to Unicode code points, and back.
		 * @see <http://mathiasbynens.be/notes/javascript-encoding>
		 * @memberOf punycode
		 * @type Object
		 */
		'ucs2': {
			'decode': ucs2decode,
			'encode': ucs2encode
		},
		'decode': decode,
		'encode': encode,
		'toASCII': toASCII,
		'toUnicode': toUnicode
	};

	/** Expose `punycode` */
	// Some AMD build optimizers, like r.js, check for specific condition patterns
	// like the following:
	if (
		typeof define == 'function' &&
		typeof define.amd == 'object' &&
		define.amd
	) {
		define('punycode', function() {
			return punycode;
		});
	} else if (freeExports && !freeExports.nodeType) {
		if (freeModule) { // in Node.js or RingoJS v0.8.0+
			freeModule.exports = punycode;
		} else { // in Narwhal or RingoJS v0.7.0-
			for (key in punycode) {
				punycode.hasOwnProperty(key) && (freeExports[key] = punycode[key]);
			}
		}
	} else { // in Rhino or a web browser
		root.punycode = punycode;
	}

}(this));

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9wdW55Y29kZS9wdW55Y29kZS5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EiLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIi8qISBodHRwOi8vbXRocy5iZS9wdW55Y29kZSB2MS4yLjQgYnkgQG1hdGhpYXMgKi9cbjsoZnVuY3Rpb24ocm9vdCkge1xuXG5cdC8qKiBEZXRlY3QgZnJlZSB2YXJpYWJsZXMgKi9cblx0dmFyIGZyZWVFeHBvcnRzID0gdHlwZW9mIGV4cG9ydHMgPT0gJ29iamVjdCcgJiYgZXhwb3J0cztcblx0dmFyIGZyZWVNb2R1bGUgPSB0eXBlb2YgbW9kdWxlID09ICdvYmplY3QnICYmIG1vZHVsZSAmJlxuXHRcdG1vZHVsZS5leHBvcnRzID09IGZyZWVFeHBvcnRzICYmIG1vZHVsZTtcblx0dmFyIGZyZWVHbG9iYWwgPSB0eXBlb2YgZ2xvYmFsID09ICdvYmplY3QnICYmIGdsb2JhbDtcblx0aWYgKGZyZWVHbG9iYWwuZ2xvYmFsID09PSBmcmVlR2xvYmFsIHx8IGZyZWVHbG9iYWwud2luZG93ID09PSBmcmVlR2xvYmFsKSB7XG5cdFx0cm9vdCA9IGZyZWVHbG9iYWw7XG5cdH1cblxuXHQvKipcblx0ICogVGhlIGBwdW55Y29kZWAgb2JqZWN0LlxuXHQgKiBAbmFtZSBwdW55Y29kZVxuXHQgKiBAdHlwZSBPYmplY3Rcblx0ICovXG5cdHZhciBwdW55Y29kZSxcblxuXHQvKiogSGlnaGVzdCBwb3NpdGl2ZSBzaWduZWQgMzItYml0IGZsb2F0IHZhbHVlICovXG5cdG1heEludCA9IDIxNDc0ODM2NDcsIC8vIGFrYS4gMHg3RkZGRkZGRiBvciAyXjMxLTFcblxuXHQvKiogQm9vdHN0cmluZyBwYXJhbWV0ZXJzICovXG5cdGJhc2UgPSAzNixcblx0dE1pbiA9IDEsXG5cdHRNYXggPSAyNixcblx0c2tldyA9IDM4LFxuXHRkYW1wID0gNzAwLFxuXHRpbml0aWFsQmlhcyA9IDcyLFxuXHRpbml0aWFsTiA9IDEyOCwgLy8gMHg4MFxuXHRkZWxpbWl0ZXIgPSAnLScsIC8vICdcXHgyRCdcblxuXHQvKiogUmVndWxhciBleHByZXNzaW9ucyAqL1xuXHRyZWdleFB1bnljb2RlID0gL154bi0tLyxcblx0cmVnZXhOb25BU0NJSSA9IC9bXiAtfl0vLCAvLyB1bnByaW50YWJsZSBBU0NJSSBjaGFycyArIG5vbi1BU0NJSSBjaGFyc1xuXHRyZWdleFNlcGFyYXRvcnMgPSAvXFx4MkV8XFx1MzAwMnxcXHVGRjBFfFxcdUZGNjEvZywgLy8gUkZDIDM0OTAgc2VwYXJhdG9yc1xuXG5cdC8qKiBFcnJvciBtZXNzYWdlcyAqL1xuXHRlcnJvcnMgPSB7XG5cdFx0J292ZXJmbG93JzogJ092ZXJmbG93OiBpbnB1dCBuZWVkcyB3aWRlciBpbnRlZ2VycyB0byBwcm9jZXNzJyxcblx0XHQnbm90LWJhc2ljJzogJ0lsbGVnYWwgaW5wdXQgPj0gMHg4MCAobm90IGEgYmFzaWMgY29kZSBwb2ludCknLFxuXHRcdCdpbnZhbGlkLWlucHV0JzogJ0ludmFsaWQgaW5wdXQnXG5cdH0sXG5cblx0LyoqIENvbnZlbmllbmNlIHNob3J0Y3V0cyAqL1xuXHRiYXNlTWludXNUTWluID0gYmFzZSAtIHRNaW4sXG5cdGZsb29yID0gTWF0aC5mbG9vcixcblx0c3RyaW5nRnJvbUNoYXJDb2RlID0gU3RyaW5nLmZyb21DaGFyQ29kZSxcblxuXHQvKiogVGVtcG9yYXJ5IHZhcmlhYmxlICovXG5cdGtleTtcblxuXHQvKi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tKi9cblxuXHQvKipcblx0ICogQSBnZW5lcmljIGVycm9yIHV0aWxpdHkgZnVuY3Rpb24uXG5cdCAqIEBwcml2YXRlXG5cdCAqIEBwYXJhbSB7U3RyaW5nfSB0eXBlIFRoZSBlcnJvciB0eXBlLlxuXHQgKiBAcmV0dXJucyB7RXJyb3J9IFRocm93cyBhIGBSYW5nZUVycm9yYCB3aXRoIHRoZSBhcHBsaWNhYmxlIGVycm9yIG1lc3NhZ2UuXG5cdCAqL1xuXHRmdW5jdGlvbiBlcnJvcih0eXBlKSB7XG5cdFx0dGhyb3cgUmFuZ2VFcnJvcihlcnJvcnNbdHlwZV0pO1xuXHR9XG5cblx0LyoqXG5cdCAqIEEgZ2VuZXJpYyBgQXJyYXkjbWFwYCB1dGlsaXR5IGZ1bmN0aW9uLlxuXHQgKiBAcHJpdmF0ZVxuXHQgKiBAcGFyYW0ge0FycmF5fSBhcnJheSBUaGUgYXJyYXkgdG8gaXRlcmF0ZSBvdmVyLlxuXHQgKiBAcGFyYW0ge0Z1bmN0aW9ufSBjYWxsYmFjayBUaGUgZnVuY3Rpb24gdGhhdCBnZXRzIGNhbGxlZCBmb3IgZXZlcnkgYXJyYXlcblx0ICogaXRlbS5cblx0ICogQHJldHVybnMge0FycmF5fSBBIG5ldyBhcnJheSBvZiB2YWx1ZXMgcmV0dXJuZWQgYnkgdGhlIGNhbGxiYWNrIGZ1bmN0aW9uLlxuXHQgKi9cblx0ZnVuY3Rpb24gbWFwKGFycmF5LCBmbikge1xuXHRcdHZhciBsZW5ndGggPSBhcnJheS5sZW5ndGg7XG5cdFx0d2hpbGUgKGxlbmd0aC0tKSB7XG5cdFx0XHRhcnJheVtsZW5ndGhdID0gZm4oYXJyYXlbbGVuZ3RoXSk7XG5cdFx0fVxuXHRcdHJldHVybiBhcnJheTtcblx0fVxuXG5cdC8qKlxuXHQgKiBBIHNpbXBsZSBgQXJyYXkjbWFwYC1saWtlIHdyYXBwZXIgdG8gd29yayB3aXRoIGRvbWFpbiBuYW1lIHN0cmluZ3MuXG5cdCAqIEBwcml2YXRlXG5cdCAqIEBwYXJhbSB7U3RyaW5nfSBkb21haW4gVGhlIGRvbWFpbiBuYW1lLlxuXHQgKiBAcGFyYW0ge0Z1bmN0aW9ufSBjYWxsYmFjayBUaGUgZnVuY3Rpb24gdGhhdCBnZXRzIGNhbGxlZCBmb3IgZXZlcnlcblx0ICogY2hhcmFjdGVyLlxuXHQgKiBAcmV0dXJucyB7QXJyYXl9IEEgbmV3IHN0cmluZyBvZiBjaGFyYWN0ZXJzIHJldHVybmVkIGJ5IHRoZSBjYWxsYmFja1xuXHQgKiBmdW5jdGlvbi5cblx0ICovXG5cdGZ1bmN0aW9uIG1hcERvbWFpbihzdHJpbmcsIGZuKSB7XG5cdFx0cmV0dXJuIG1hcChzdHJpbmcuc3BsaXQocmVnZXhTZXBhcmF0b3JzKSwgZm4pLmpvaW4oJy4nKTtcblx0fVxuXG5cdC8qKlxuXHQgKiBDcmVhdGVzIGFuIGFycmF5IGNvbnRhaW5pbmcgdGhlIG51bWVyaWMgY29kZSBwb2ludHMgb2YgZWFjaCBVbmljb2RlXG5cdCAqIGNoYXJhY3RlciBpbiB0aGUgc3RyaW5nLiBXaGlsZSBKYXZhU2NyaXB0IHVzZXMgVUNTLTIgaW50ZXJuYWxseSxcblx0ICogdGhpcyBmdW5jdGlvbiB3aWxsIGNvbnZlcnQgYSBwYWlyIG9mIHN1cnJvZ2F0ZSBoYWx2ZXMgKGVhY2ggb2Ygd2hpY2hcblx0ICogVUNTLTIgZXhwb3NlcyBhcyBzZXBhcmF0ZSBjaGFyYWN0ZXJzKSBpbnRvIGEgc2luZ2xlIGNvZGUgcG9pbnQsXG5cdCAqIG1hdGNoaW5nIFVURi0xNi5cblx0ICogQHNlZSBgcHVueWNvZGUudWNzMi5lbmNvZGVgXG5cdCAqIEBzZWUgPGh0dHA6Ly9tYXRoaWFzYnluZW5zLmJlL25vdGVzL2phdmFzY3JpcHQtZW5jb2Rpbmc+XG5cdCAqIEBtZW1iZXJPZiBwdW55Y29kZS51Y3MyXG5cdCAqIEBuYW1lIGRlY29kZVxuXHQgKiBAcGFyYW0ge1N0cmluZ30gc3RyaW5nIFRoZSBVbmljb2RlIGlucHV0IHN0cmluZyAoVUNTLTIpLlxuXHQgKiBAcmV0dXJucyB7QXJyYXl9IFRoZSBuZXcgYXJyYXkgb2YgY29kZSBwb2ludHMuXG5cdCAqL1xuXHRmdW5jdGlvbiB1Y3MyZGVjb2RlKHN0cmluZykge1xuXHRcdHZhciBvdXRwdXQgPSBbXSxcblx0XHQgICAgY291bnRlciA9IDAsXG5cdFx0ICAgIGxlbmd0aCA9IHN0cmluZy5sZW5ndGgsXG5cdFx0ICAgIHZhbHVlLFxuXHRcdCAgICBleHRyYTtcblx0XHR3aGlsZSAoY291bnRlciA8IGxlbmd0aCkge1xuXHRcdFx0dmFsdWUgPSBzdHJpbmcuY2hhckNvZGVBdChjb3VudGVyKyspO1xuXHRcdFx0aWYgKHZhbHVlID49IDB4RDgwMCAmJiB2YWx1ZSA8PSAweERCRkYgJiYgY291bnRlciA8IGxlbmd0aCkge1xuXHRcdFx0XHQvLyBoaWdoIHN1cnJvZ2F0ZSwgYW5kIHRoZXJlIGlzIGEgbmV4dCBjaGFyYWN0ZXJcblx0XHRcdFx0ZXh0cmEgPSBzdHJpbmcuY2hhckNvZGVBdChjb3VudGVyKyspO1xuXHRcdFx0XHRpZiAoKGV4dHJhICYgMHhGQzAwKSA9PSAweERDMDApIHsgLy8gbG93IHN1cnJvZ2F0ZVxuXHRcdFx0XHRcdG91dHB1dC5wdXNoKCgodmFsdWUgJiAweDNGRikgPDwgMTApICsgKGV4dHJhICYgMHgzRkYpICsgMHgxMDAwMCk7XG5cdFx0XHRcdH0gZWxzZSB7XG5cdFx0XHRcdFx0Ly8gdW5tYXRjaGVkIHN1cnJvZ2F0ZTsgb25seSBhcHBlbmQgdGhpcyBjb2RlIHVuaXQsIGluIGNhc2UgdGhlIG5leHRcblx0XHRcdFx0XHQvLyBjb2RlIHVuaXQgaXMgdGhlIGhpZ2ggc3Vycm9nYXRlIG9mIGEgc3Vycm9nYXRlIHBhaXJcblx0XHRcdFx0XHRvdXRwdXQucHVzaCh2YWx1ZSk7XG5cdFx0XHRcdFx0Y291bnRlci0tO1xuXHRcdFx0XHR9XG5cdFx0XHR9IGVsc2Uge1xuXHRcdFx0XHRvdXRwdXQucHVzaCh2YWx1ZSk7XG5cdFx0XHR9XG5cdFx0fVxuXHRcdHJldHVybiBvdXRwdXQ7XG5cdH1cblxuXHQvKipcblx0ICogQ3JlYXRlcyBhIHN0cmluZyBiYXNlZCBvbiBhbiBhcnJheSBvZiBudW1lcmljIGNvZGUgcG9pbnRzLlxuXHQgKiBAc2VlIGBwdW55Y29kZS51Y3MyLmRlY29kZWBcblx0ICogQG1lbWJlck9mIHB1bnljb2RlLnVjczJcblx0ICogQG5hbWUgZW5jb2RlXG5cdCAqIEBwYXJhbSB7QXJyYXl9IGNvZGVQb2ludHMgVGhlIGFycmF5IG9mIG51bWVyaWMgY29kZSBwb2ludHMuXG5cdCAqIEByZXR1cm5zIHtTdHJpbmd9IFRoZSBuZXcgVW5pY29kZSBzdHJpbmcgKFVDUy0yKS5cblx0ICovXG5cdGZ1bmN0aW9uIHVjczJlbmNvZGUoYXJyYXkpIHtcblx0XHRyZXR1cm4gbWFwKGFycmF5LCBmdW5jdGlvbih2YWx1ZSkge1xuXHRcdFx0dmFyIG91dHB1dCA9ICcnO1xuXHRcdFx0aWYgKHZhbHVlID4gMHhGRkZGKSB7XG5cdFx0XHRcdHZhbHVlIC09IDB4MTAwMDA7XG5cdFx0XHRcdG91dHB1dCArPSBzdHJpbmdGcm9tQ2hhckNvZGUodmFsdWUgPj4+IDEwICYgMHgzRkYgfCAweEQ4MDApO1xuXHRcdFx0XHR2YWx1ZSA9IDB4REMwMCB8IHZhbHVlICYgMHgzRkY7XG5cdFx0XHR9XG5cdFx0XHRvdXRwdXQgKz0gc3RyaW5nRnJvbUNoYXJDb2RlKHZhbHVlKTtcblx0XHRcdHJldHVybiBvdXRwdXQ7XG5cdFx0fSkuam9pbignJyk7XG5cdH1cblxuXHQvKipcblx0ICogQ29udmVydHMgYSBiYXNpYyBjb2RlIHBvaW50IGludG8gYSBkaWdpdC9pbnRlZ2VyLlxuXHQgKiBAc2VlIGBkaWdpdFRvQmFzaWMoKWBcblx0ICogQHByaXZhdGVcblx0ICogQHBhcmFtIHtOdW1iZXJ9IGNvZGVQb2ludCBUaGUgYmFzaWMgbnVtZXJpYyBjb2RlIHBvaW50IHZhbHVlLlxuXHQgKiBAcmV0dXJucyB7TnVtYmVyfSBUaGUgbnVtZXJpYyB2YWx1ZSBvZiBhIGJhc2ljIGNvZGUgcG9pbnQgKGZvciB1c2UgaW5cblx0ICogcmVwcmVzZW50aW5nIGludGVnZXJzKSBpbiB0aGUgcmFuZ2UgYDBgIHRvIGBiYXNlIC0gMWAsIG9yIGBiYXNlYCBpZlxuXHQgKiB0aGUgY29kZSBwb2ludCBkb2VzIG5vdCByZXByZXNlbnQgYSB2YWx1ZS5cblx0ICovXG5cdGZ1bmN0aW9uIGJhc2ljVG9EaWdpdChjb2RlUG9pbnQpIHtcblx0XHRpZiAoY29kZVBvaW50IC0gNDggPCAxMCkge1xuXHRcdFx0cmV0dXJuIGNvZGVQb2ludCAtIDIyO1xuXHRcdH1cblx0XHRpZiAoY29kZVBvaW50IC0gNjUgPCAyNikge1xuXHRcdFx0cmV0dXJuIGNvZGVQb2ludCAtIDY1O1xuXHRcdH1cblx0XHRpZiAoY29kZVBvaW50IC0gOTcgPCAyNikge1xuXHRcdFx0cmV0dXJuIGNvZGVQb2ludCAtIDk3O1xuXHRcdH1cblx0XHRyZXR1cm4gYmFzZTtcblx0fVxuXG5cdC8qKlxuXHQgKiBDb252ZXJ0cyBhIGRpZ2l0L2ludGVnZXIgaW50byBhIGJhc2ljIGNvZGUgcG9pbnQuXG5cdCAqIEBzZWUgYGJhc2ljVG9EaWdpdCgpYFxuXHQgKiBAcHJpdmF0ZVxuXHQgKiBAcGFyYW0ge051bWJlcn0gZGlnaXQgVGhlIG51bWVyaWMgdmFsdWUgb2YgYSBiYXNpYyBjb2RlIHBvaW50LlxuXHQgKiBAcmV0dXJucyB7TnVtYmVyfSBUaGUgYmFzaWMgY29kZSBwb2ludCB3aG9zZSB2YWx1ZSAod2hlbiB1c2VkIGZvclxuXHQgKiByZXByZXNlbnRpbmcgaW50ZWdlcnMpIGlzIGBkaWdpdGAsIHdoaWNoIG5lZWRzIHRvIGJlIGluIHRoZSByYW5nZVxuXHQgKiBgMGAgdG8gYGJhc2UgLSAxYC4gSWYgYGZsYWdgIGlzIG5vbi16ZXJvLCB0aGUgdXBwZXJjYXNlIGZvcm0gaXNcblx0ICogdXNlZDsgZWxzZSwgdGhlIGxvd2VyY2FzZSBmb3JtIGlzIHVzZWQuIFRoZSBiZWhhdmlvciBpcyB1bmRlZmluZWRcblx0ICogaWYgYGZsYWdgIGlzIG5vbi16ZXJvIGFuZCBgZGlnaXRgIGhhcyBubyB1cHBlcmNhc2UgZm9ybS5cblx0ICovXG5cdGZ1bmN0aW9uIGRpZ2l0VG9CYXNpYyhkaWdpdCwgZmxhZykge1xuXHRcdC8vICAwLi4yNSBtYXAgdG8gQVNDSUkgYS4ueiBvciBBLi5aXG5cdFx0Ly8gMjYuLjM1IG1hcCB0byBBU0NJSSAwLi45XG5cdFx0cmV0dXJuIGRpZ2l0ICsgMjIgKyA3NSAqIChkaWdpdCA8IDI2KSAtICgoZmxhZyAhPSAwKSA8PCA1KTtcblx0fVxuXG5cdC8qKlxuXHQgKiBCaWFzIGFkYXB0YXRpb24gZnVuY3Rpb24gYXMgcGVyIHNlY3Rpb24gMy40IG9mIFJGQyAzNDkyLlxuXHQgKiBodHRwOi8vdG9vbHMuaWV0Zi5vcmcvaHRtbC9yZmMzNDkyI3NlY3Rpb24tMy40XG5cdCAqIEBwcml2YXRlXG5cdCAqL1xuXHRmdW5jdGlvbiBhZGFwdChkZWx0YSwgbnVtUG9pbnRzLCBmaXJzdFRpbWUpIHtcblx0XHR2YXIgayA9IDA7XG5cdFx0ZGVsdGEgPSBmaXJzdFRpbWUgPyBmbG9vcihkZWx0YSAvIGRhbXApIDogZGVsdGEgPj4gMTtcblx0XHRkZWx0YSArPSBmbG9vcihkZWx0YSAvIG51bVBvaW50cyk7XG5cdFx0Zm9yICgvKiBubyBpbml0aWFsaXphdGlvbiAqLzsgZGVsdGEgPiBiYXNlTWludXNUTWluICogdE1heCA+PiAxOyBrICs9IGJhc2UpIHtcblx0XHRcdGRlbHRhID0gZmxvb3IoZGVsdGEgLyBiYXNlTWludXNUTWluKTtcblx0XHR9XG5cdFx0cmV0dXJuIGZsb29yKGsgKyAoYmFzZU1pbnVzVE1pbiArIDEpICogZGVsdGEgLyAoZGVsdGEgKyBza2V3KSk7XG5cdH1cblxuXHQvKipcblx0ICogQ29udmVydHMgYSBQdW55Y29kZSBzdHJpbmcgb2YgQVNDSUktb25seSBzeW1ib2xzIHRvIGEgc3RyaW5nIG9mIFVuaWNvZGVcblx0ICogc3ltYm9scy5cblx0ICogQG1lbWJlck9mIHB1bnljb2RlXG5cdCAqIEBwYXJhbSB7U3RyaW5nfSBpbnB1dCBUaGUgUHVueWNvZGUgc3RyaW5nIG9mIEFTQ0lJLW9ubHkgc3ltYm9scy5cblx0ICogQHJldHVybnMge1N0cmluZ30gVGhlIHJlc3VsdGluZyBzdHJpbmcgb2YgVW5pY29kZSBzeW1ib2xzLlxuXHQgKi9cblx0ZnVuY3Rpb24gZGVjb2RlKGlucHV0KSB7XG5cdFx0Ly8gRG9uJ3QgdXNlIFVDUy0yXG5cdFx0dmFyIG91dHB1dCA9IFtdLFxuXHRcdCAgICBpbnB1dExlbmd0aCA9IGlucHV0Lmxlbmd0aCxcblx0XHQgICAgb3V0LFxuXHRcdCAgICBpID0gMCxcblx0XHQgICAgbiA9IGluaXRpYWxOLFxuXHRcdCAgICBiaWFzID0gaW5pdGlhbEJpYXMsXG5cdFx0ICAgIGJhc2ljLFxuXHRcdCAgICBqLFxuXHRcdCAgICBpbmRleCxcblx0XHQgICAgb2xkaSxcblx0XHQgICAgdyxcblx0XHQgICAgayxcblx0XHQgICAgZGlnaXQsXG5cdFx0ICAgIHQsXG5cdFx0ICAgIC8qKiBDYWNoZWQgY2FsY3VsYXRpb24gcmVzdWx0cyAqL1xuXHRcdCAgICBiYXNlTWludXNUO1xuXG5cdFx0Ly8gSGFuZGxlIHRoZSBiYXNpYyBjb2RlIHBvaW50czogbGV0IGBiYXNpY2AgYmUgdGhlIG51bWJlciBvZiBpbnB1dCBjb2RlXG5cdFx0Ly8gcG9pbnRzIGJlZm9yZSB0aGUgbGFzdCBkZWxpbWl0ZXIsIG9yIGAwYCBpZiB0aGVyZSBpcyBub25lLCB0aGVuIGNvcHlcblx0XHQvLyB0aGUgZmlyc3QgYmFzaWMgY29kZSBwb2ludHMgdG8gdGhlIG91dHB1dC5cblxuXHRcdGJhc2ljID0gaW5wdXQubGFzdEluZGV4T2YoZGVsaW1pdGVyKTtcblx0XHRpZiAoYmFzaWMgPCAwKSB7XG5cdFx0XHRiYXNpYyA9IDA7XG5cdFx0fVxuXG5cdFx0Zm9yIChqID0gMDsgaiA8IGJhc2ljOyArK2opIHtcblx0XHRcdC8vIGlmIGl0J3Mgbm90IGEgYmFzaWMgY29kZSBwb2ludFxuXHRcdFx0aWYgKGlucHV0LmNoYXJDb2RlQXQoaikgPj0gMHg4MCkge1xuXHRcdFx0XHRlcnJvcignbm90LWJhc2ljJyk7XG5cdFx0XHR9XG5cdFx0XHRvdXRwdXQucHVzaChpbnB1dC5jaGFyQ29kZUF0KGopKTtcblx0XHR9XG5cblx0XHQvLyBNYWluIGRlY29kaW5nIGxvb3A6IHN0YXJ0IGp1c3QgYWZ0ZXIgdGhlIGxhc3QgZGVsaW1pdGVyIGlmIGFueSBiYXNpYyBjb2RlXG5cdFx0Ly8gcG9pbnRzIHdlcmUgY29waWVkOyBzdGFydCBhdCB0aGUgYmVnaW5uaW5nIG90aGVyd2lzZS5cblxuXHRcdGZvciAoaW5kZXggPSBiYXNpYyA+IDAgPyBiYXNpYyArIDEgOiAwOyBpbmRleCA8IGlucHV0TGVuZ3RoOyAvKiBubyBmaW5hbCBleHByZXNzaW9uICovKSB7XG5cblx0XHRcdC8vIGBpbmRleGAgaXMgdGhlIGluZGV4IG9mIHRoZSBuZXh0IGNoYXJhY3RlciB0byBiZSBjb25zdW1lZC5cblx0XHRcdC8vIERlY29kZSBhIGdlbmVyYWxpemVkIHZhcmlhYmxlLWxlbmd0aCBpbnRlZ2VyIGludG8gYGRlbHRhYCxcblx0XHRcdC8vIHdoaWNoIGdldHMgYWRkZWQgdG8gYGlgLiBUaGUgb3ZlcmZsb3cgY2hlY2tpbmcgaXMgZWFzaWVyXG5cdFx0XHQvLyBpZiB3ZSBpbmNyZWFzZSBgaWAgYXMgd2UgZ28sIHRoZW4gc3VidHJhY3Qgb2ZmIGl0cyBzdGFydGluZ1xuXHRcdFx0Ly8gdmFsdWUgYXQgdGhlIGVuZCB0byBvYnRhaW4gYGRlbHRhYC5cblx0XHRcdGZvciAob2xkaSA9IGksIHcgPSAxLCBrID0gYmFzZTsgLyogbm8gY29uZGl0aW9uICovOyBrICs9IGJhc2UpIHtcblxuXHRcdFx0XHRpZiAoaW5kZXggPj0gaW5wdXRMZW5ndGgpIHtcblx0XHRcdFx0XHRlcnJvcignaW52YWxpZC1pbnB1dCcpO1xuXHRcdFx0XHR9XG5cblx0XHRcdFx0ZGlnaXQgPSBiYXNpY1RvRGlnaXQoaW5wdXQuY2hhckNvZGVBdChpbmRleCsrKSk7XG5cblx0XHRcdFx0aWYgKGRpZ2l0ID49IGJhc2UgfHwgZGlnaXQgPiBmbG9vcigobWF4SW50IC0gaSkgLyB3KSkge1xuXHRcdFx0XHRcdGVycm9yKCdvdmVyZmxvdycpO1xuXHRcdFx0XHR9XG5cblx0XHRcdFx0aSArPSBkaWdpdCAqIHc7XG5cdFx0XHRcdHQgPSBrIDw9IGJpYXMgPyB0TWluIDogKGsgPj0gYmlhcyArIHRNYXggPyB0TWF4IDogayAtIGJpYXMpO1xuXG5cdFx0XHRcdGlmIChkaWdpdCA8IHQpIHtcblx0XHRcdFx0XHRicmVhaztcblx0XHRcdFx0fVxuXG5cdFx0XHRcdGJhc2VNaW51c1QgPSBiYXNlIC0gdDtcblx0XHRcdFx0aWYgKHcgPiBmbG9vcihtYXhJbnQgLyBiYXNlTWludXNUKSkge1xuXHRcdFx0XHRcdGVycm9yKCdvdmVyZmxvdycpO1xuXHRcdFx0XHR9XG5cblx0XHRcdFx0dyAqPSBiYXNlTWludXNUO1xuXG5cdFx0XHR9XG5cblx0XHRcdG91dCA9IG91dHB1dC5sZW5ndGggKyAxO1xuXHRcdFx0YmlhcyA9IGFkYXB0KGkgLSBvbGRpLCBvdXQsIG9sZGkgPT0gMCk7XG5cblx0XHRcdC8vIGBpYCB3YXMgc3VwcG9zZWQgdG8gd3JhcCBhcm91bmQgZnJvbSBgb3V0YCB0byBgMGAsXG5cdFx0XHQvLyBpbmNyZW1lbnRpbmcgYG5gIGVhY2ggdGltZSwgc28gd2UnbGwgZml4IHRoYXQgbm93OlxuXHRcdFx0aWYgKGZsb29yKGkgLyBvdXQpID4gbWF4SW50IC0gbikge1xuXHRcdFx0XHRlcnJvcignb3ZlcmZsb3cnKTtcblx0XHRcdH1cblxuXHRcdFx0biArPSBmbG9vcihpIC8gb3V0KTtcblx0XHRcdGkgJT0gb3V0O1xuXG5cdFx0XHQvLyBJbnNlcnQgYG5gIGF0IHBvc2l0aW9uIGBpYCBvZiB0aGUgb3V0cHV0XG5cdFx0XHRvdXRwdXQuc3BsaWNlKGkrKywgMCwgbik7XG5cblx0XHR9XG5cblx0XHRyZXR1cm4gdWNzMmVuY29kZShvdXRwdXQpO1xuXHR9XG5cblx0LyoqXG5cdCAqIENvbnZlcnRzIGEgc3RyaW5nIG9mIFVuaWNvZGUgc3ltYm9scyB0byBhIFB1bnljb2RlIHN0cmluZyBvZiBBU0NJSS1vbmx5XG5cdCAqIHN5bWJvbHMuXG5cdCAqIEBtZW1iZXJPZiBwdW55Y29kZVxuXHQgKiBAcGFyYW0ge1N0cmluZ30gaW5wdXQgVGhlIHN0cmluZyBvZiBVbmljb2RlIHN5bWJvbHMuXG5cdCAqIEByZXR1cm5zIHtTdHJpbmd9IFRoZSByZXN1bHRpbmcgUHVueWNvZGUgc3RyaW5nIG9mIEFTQ0lJLW9ubHkgc3ltYm9scy5cblx0ICovXG5cdGZ1bmN0aW9uIGVuY29kZShpbnB1dCkge1xuXHRcdHZhciBuLFxuXHRcdCAgICBkZWx0YSxcblx0XHQgICAgaGFuZGxlZENQQ291bnQsXG5cdFx0ICAgIGJhc2ljTGVuZ3RoLFxuXHRcdCAgICBiaWFzLFxuXHRcdCAgICBqLFxuXHRcdCAgICBtLFxuXHRcdCAgICBxLFxuXHRcdCAgICBrLFxuXHRcdCAgICB0LFxuXHRcdCAgICBjdXJyZW50VmFsdWUsXG5cdFx0ICAgIG91dHB1dCA9IFtdLFxuXHRcdCAgICAvKiogYGlucHV0TGVuZ3RoYCB3aWxsIGhvbGQgdGhlIG51bWJlciBvZiBjb2RlIHBvaW50cyBpbiBgaW5wdXRgLiAqL1xuXHRcdCAgICBpbnB1dExlbmd0aCxcblx0XHQgICAgLyoqIENhY2hlZCBjYWxjdWxhdGlvbiByZXN1bHRzICovXG5cdFx0ICAgIGhhbmRsZWRDUENvdW50UGx1c09uZSxcblx0XHQgICAgYmFzZU1pbnVzVCxcblx0XHQgICAgcU1pbnVzVDtcblxuXHRcdC8vIENvbnZlcnQgdGhlIGlucHV0IGluIFVDUy0yIHRvIFVuaWNvZGVcblx0XHRpbnB1dCA9IHVjczJkZWNvZGUoaW5wdXQpO1xuXG5cdFx0Ly8gQ2FjaGUgdGhlIGxlbmd0aFxuXHRcdGlucHV0TGVuZ3RoID0gaW5wdXQubGVuZ3RoO1xuXG5cdFx0Ly8gSW5pdGlhbGl6ZSB0aGUgc3RhdGVcblx0XHRuID0gaW5pdGlhbE47XG5cdFx0ZGVsdGEgPSAwO1xuXHRcdGJpYXMgPSBpbml0aWFsQmlhcztcblxuXHRcdC8vIEhhbmRsZSB0aGUgYmFzaWMgY29kZSBwb2ludHNcblx0XHRmb3IgKGogPSAwOyBqIDwgaW5wdXRMZW5ndGg7ICsraikge1xuXHRcdFx0Y3VycmVudFZhbHVlID0gaW5wdXRbal07XG5cdFx0XHRpZiAoY3VycmVudFZhbHVlIDwgMHg4MCkge1xuXHRcdFx0XHRvdXRwdXQucHVzaChzdHJpbmdGcm9tQ2hhckNvZGUoY3VycmVudFZhbHVlKSk7XG5cdFx0XHR9XG5cdFx0fVxuXG5cdFx0aGFuZGxlZENQQ291bnQgPSBiYXNpY0xlbmd0aCA9IG91dHB1dC5sZW5ndGg7XG5cblx0XHQvLyBgaGFuZGxlZENQQ291bnRgIGlzIHRoZSBudW1iZXIgb2YgY29kZSBwb2ludHMgdGhhdCBoYXZlIGJlZW4gaGFuZGxlZDtcblx0XHQvLyBgYmFzaWNMZW5ndGhgIGlzIHRoZSBudW1iZXIgb2YgYmFzaWMgY29kZSBwb2ludHMuXG5cblx0XHQvLyBGaW5pc2ggdGhlIGJhc2ljIHN0cmluZyAtIGlmIGl0IGlzIG5vdCBlbXB0eSAtIHdpdGggYSBkZWxpbWl0ZXJcblx0XHRpZiAoYmFzaWNMZW5ndGgpIHtcblx0XHRcdG91dHB1dC5wdXNoKGRlbGltaXRlcik7XG5cdFx0fVxuXG5cdFx0Ly8gTWFpbiBlbmNvZGluZyBsb29wOlxuXHRcdHdoaWxlIChoYW5kbGVkQ1BDb3VudCA8IGlucHV0TGVuZ3RoKSB7XG5cblx0XHRcdC8vIEFsbCBub24tYmFzaWMgY29kZSBwb2ludHMgPCBuIGhhdmUgYmVlbiBoYW5kbGVkIGFscmVhZHkuIEZpbmQgdGhlIG5leHRcblx0XHRcdC8vIGxhcmdlciBvbmU6XG5cdFx0XHRmb3IgKG0gPSBtYXhJbnQsIGogPSAwOyBqIDwgaW5wdXRMZW5ndGg7ICsraikge1xuXHRcdFx0XHRjdXJyZW50VmFsdWUgPSBpbnB1dFtqXTtcblx0XHRcdFx0aWYgKGN1cnJlbnRWYWx1ZSA+PSBuICYmIGN1cnJlbnRWYWx1ZSA8IG0pIHtcblx0XHRcdFx0XHRtID0gY3VycmVudFZhbHVlO1xuXHRcdFx0XHR9XG5cdFx0XHR9XG5cblx0XHRcdC8vIEluY3JlYXNlIGBkZWx0YWAgZW5vdWdoIHRvIGFkdmFuY2UgdGhlIGRlY29kZXIncyA8bixpPiBzdGF0ZSB0byA8bSwwPixcblx0XHRcdC8vIGJ1dCBndWFyZCBhZ2FpbnN0IG92ZXJmbG93XG5cdFx0XHRoYW5kbGVkQ1BDb3VudFBsdXNPbmUgPSBoYW5kbGVkQ1BDb3VudCArIDE7XG5cdFx0XHRpZiAobSAtIG4gPiBmbG9vcigobWF4SW50IC0gZGVsdGEpIC8gaGFuZGxlZENQQ291bnRQbHVzT25lKSkge1xuXHRcdFx0XHRlcnJvcignb3ZlcmZsb3cnKTtcblx0XHRcdH1cblxuXHRcdFx0ZGVsdGEgKz0gKG0gLSBuKSAqIGhhbmRsZWRDUENvdW50UGx1c09uZTtcblx0XHRcdG4gPSBtO1xuXG5cdFx0XHRmb3IgKGogPSAwOyBqIDwgaW5wdXRMZW5ndGg7ICsraikge1xuXHRcdFx0XHRjdXJyZW50VmFsdWUgPSBpbnB1dFtqXTtcblxuXHRcdFx0XHRpZiAoY3VycmVudFZhbHVlIDwgbiAmJiArK2RlbHRhID4gbWF4SW50KSB7XG5cdFx0XHRcdFx0ZXJyb3IoJ292ZXJmbG93Jyk7XG5cdFx0XHRcdH1cblxuXHRcdFx0XHRpZiAoY3VycmVudFZhbHVlID09IG4pIHtcblx0XHRcdFx0XHQvLyBSZXByZXNlbnQgZGVsdGEgYXMgYSBnZW5lcmFsaXplZCB2YXJpYWJsZS1sZW5ndGggaW50ZWdlclxuXHRcdFx0XHRcdGZvciAocSA9IGRlbHRhLCBrID0gYmFzZTsgLyogbm8gY29uZGl0aW9uICovOyBrICs9IGJhc2UpIHtcblx0XHRcdFx0XHRcdHQgPSBrIDw9IGJpYXMgPyB0TWluIDogKGsgPj0gYmlhcyArIHRNYXggPyB0TWF4IDogayAtIGJpYXMpO1xuXHRcdFx0XHRcdFx0aWYgKHEgPCB0KSB7XG5cdFx0XHRcdFx0XHRcdGJyZWFrO1xuXHRcdFx0XHRcdFx0fVxuXHRcdFx0XHRcdFx0cU1pbnVzVCA9IHEgLSB0O1xuXHRcdFx0XHRcdFx0YmFzZU1pbnVzVCA9IGJhc2UgLSB0O1xuXHRcdFx0XHRcdFx0b3V0cHV0LnB1c2goXG5cdFx0XHRcdFx0XHRcdHN0cmluZ0Zyb21DaGFyQ29kZShkaWdpdFRvQmFzaWModCArIHFNaW51c1QgJSBiYXNlTWludXNULCAwKSlcblx0XHRcdFx0XHRcdCk7XG5cdFx0XHRcdFx0XHRxID0gZmxvb3IocU1pbnVzVCAvIGJhc2VNaW51c1QpO1xuXHRcdFx0XHRcdH1cblxuXHRcdFx0XHRcdG91dHB1dC5wdXNoKHN0cmluZ0Zyb21DaGFyQ29kZShkaWdpdFRvQmFzaWMocSwgMCkpKTtcblx0XHRcdFx0XHRiaWFzID0gYWRhcHQoZGVsdGEsIGhhbmRsZWRDUENvdW50UGx1c09uZSwgaGFuZGxlZENQQ291bnQgPT0gYmFzaWNMZW5ndGgpO1xuXHRcdFx0XHRcdGRlbHRhID0gMDtcblx0XHRcdFx0XHQrK2hhbmRsZWRDUENvdW50O1xuXHRcdFx0XHR9XG5cdFx0XHR9XG5cblx0XHRcdCsrZGVsdGE7XG5cdFx0XHQrK247XG5cblx0XHR9XG5cdFx0cmV0dXJuIG91dHB1dC5qb2luKCcnKTtcblx0fVxuXG5cdC8qKlxuXHQgKiBDb252ZXJ0cyBhIFB1bnljb2RlIHN0cmluZyByZXByZXNlbnRpbmcgYSBkb21haW4gbmFtZSB0byBVbmljb2RlLiBPbmx5IHRoZVxuXHQgKiBQdW55Y29kZWQgcGFydHMgb2YgdGhlIGRvbWFpbiBuYW1lIHdpbGwgYmUgY29udmVydGVkLCBpLmUuIGl0IGRvZXNuJ3Rcblx0ICogbWF0dGVyIGlmIHlvdSBjYWxsIGl0IG9uIGEgc3RyaW5nIHRoYXQgaGFzIGFscmVhZHkgYmVlbiBjb252ZXJ0ZWQgdG9cblx0ICogVW5pY29kZS5cblx0ICogQG1lbWJlck9mIHB1bnljb2RlXG5cdCAqIEBwYXJhbSB7U3RyaW5nfSBkb21haW4gVGhlIFB1bnljb2RlIGRvbWFpbiBuYW1lIHRvIGNvbnZlcnQgdG8gVW5pY29kZS5cblx0ICogQHJldHVybnMge1N0cmluZ30gVGhlIFVuaWNvZGUgcmVwcmVzZW50YXRpb24gb2YgdGhlIGdpdmVuIFB1bnljb2RlXG5cdCAqIHN0cmluZy5cblx0ICovXG5cdGZ1bmN0aW9uIHRvVW5pY29kZShkb21haW4pIHtcblx0XHRyZXR1cm4gbWFwRG9tYWluKGRvbWFpbiwgZnVuY3Rpb24oc3RyaW5nKSB7XG5cdFx0XHRyZXR1cm4gcmVnZXhQdW55Y29kZS50ZXN0KHN0cmluZylcblx0XHRcdFx0PyBkZWNvZGUoc3RyaW5nLnNsaWNlKDQpLnRvTG93ZXJDYXNlKCkpXG5cdFx0XHRcdDogc3RyaW5nO1xuXHRcdH0pO1xuXHR9XG5cblx0LyoqXG5cdCAqIENvbnZlcnRzIGEgVW5pY29kZSBzdHJpbmcgcmVwcmVzZW50aW5nIGEgZG9tYWluIG5hbWUgdG8gUHVueWNvZGUuIE9ubHkgdGhlXG5cdCAqIG5vbi1BU0NJSSBwYXJ0cyBvZiB0aGUgZG9tYWluIG5hbWUgd2lsbCBiZSBjb252ZXJ0ZWQsIGkuZS4gaXQgZG9lc24ndFxuXHQgKiBtYXR0ZXIgaWYgeW91IGNhbGwgaXQgd2l0aCBhIGRvbWFpbiB0aGF0J3MgYWxyZWFkeSBpbiBBU0NJSS5cblx0ICogQG1lbWJlck9mIHB1bnljb2RlXG5cdCAqIEBwYXJhbSB7U3RyaW5nfSBkb21haW4gVGhlIGRvbWFpbiBuYW1lIHRvIGNvbnZlcnQsIGFzIGEgVW5pY29kZSBzdHJpbmcuXG5cdCAqIEByZXR1cm5zIHtTdHJpbmd9IFRoZSBQdW55Y29kZSByZXByZXNlbnRhdGlvbiBvZiB0aGUgZ2l2ZW4gZG9tYWluIG5hbWUuXG5cdCAqL1xuXHRmdW5jdGlvbiB0b0FTQ0lJKGRvbWFpbikge1xuXHRcdHJldHVybiBtYXBEb21haW4oZG9tYWluLCBmdW5jdGlvbihzdHJpbmcpIHtcblx0XHRcdHJldHVybiByZWdleE5vbkFTQ0lJLnRlc3Qoc3RyaW5nKVxuXHRcdFx0XHQ/ICd4bi0tJyArIGVuY29kZShzdHJpbmcpXG5cdFx0XHRcdDogc3RyaW5nO1xuXHRcdH0pO1xuXHR9XG5cblx0LyotLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSovXG5cblx0LyoqIERlZmluZSB0aGUgcHVibGljIEFQSSAqL1xuXHRwdW55Y29kZSA9IHtcblx0XHQvKipcblx0XHQgKiBBIHN0cmluZyByZXByZXNlbnRpbmcgdGhlIGN1cnJlbnQgUHVueWNvZGUuanMgdmVyc2lvbiBudW1iZXIuXG5cdFx0ICogQG1lbWJlck9mIHB1bnljb2RlXG5cdFx0ICogQHR5cGUgU3RyaW5nXG5cdFx0ICovXG5cdFx0J3ZlcnNpb24nOiAnMS4yLjQnLFxuXHRcdC8qKlxuXHRcdCAqIEFuIG9iamVjdCBvZiBtZXRob2RzIHRvIGNvbnZlcnQgZnJvbSBKYXZhU2NyaXB0J3MgaW50ZXJuYWwgY2hhcmFjdGVyXG5cdFx0ICogcmVwcmVzZW50YXRpb24gKFVDUy0yKSB0byBVbmljb2RlIGNvZGUgcG9pbnRzLCBhbmQgYmFjay5cblx0XHQgKiBAc2VlIDxodHRwOi8vbWF0aGlhc2J5bmVucy5iZS9ub3Rlcy9qYXZhc2NyaXB0LWVuY29kaW5nPlxuXHRcdCAqIEBtZW1iZXJPZiBwdW55Y29kZVxuXHRcdCAqIEB0eXBlIE9iamVjdFxuXHRcdCAqL1xuXHRcdCd1Y3MyJzoge1xuXHRcdFx0J2RlY29kZSc6IHVjczJkZWNvZGUsXG5cdFx0XHQnZW5jb2RlJzogdWNzMmVuY29kZVxuXHRcdH0sXG5cdFx0J2RlY29kZSc6IGRlY29kZSxcblx0XHQnZW5jb2RlJzogZW5jb2RlLFxuXHRcdCd0b0FTQ0lJJzogdG9BU0NJSSxcblx0XHQndG9Vbmljb2RlJzogdG9Vbmljb2RlXG5cdH07XG5cblx0LyoqIEV4cG9zZSBgcHVueWNvZGVgICovXG5cdC8vIFNvbWUgQU1EIGJ1aWxkIG9wdGltaXplcnMsIGxpa2Ugci5qcywgY2hlY2sgZm9yIHNwZWNpZmljIGNvbmRpdGlvbiBwYXR0ZXJuc1xuXHQvLyBsaWtlIHRoZSBmb2xsb3dpbmc6XG5cdGlmIChcblx0XHR0eXBlb2YgZGVmaW5lID09ICdmdW5jdGlvbicgJiZcblx0XHR0eXBlb2YgZGVmaW5lLmFtZCA9PSAnb2JqZWN0JyAmJlxuXHRcdGRlZmluZS5hbWRcblx0KSB7XG5cdFx0ZGVmaW5lKCdwdW55Y29kZScsIGZ1bmN0aW9uKCkge1xuXHRcdFx0cmV0dXJuIHB1bnljb2RlO1xuXHRcdH0pO1xuXHR9IGVsc2UgaWYgKGZyZWVFeHBvcnRzICYmICFmcmVlRXhwb3J0cy5ub2RlVHlwZSkge1xuXHRcdGlmIChmcmVlTW9kdWxlKSB7IC8vIGluIE5vZGUuanMgb3IgUmluZ29KUyB2MC44LjArXG5cdFx0XHRmcmVlTW9kdWxlLmV4cG9ydHMgPSBwdW55Y29kZTtcblx0XHR9IGVsc2UgeyAvLyBpbiBOYXJ3aGFsIG9yIFJpbmdvSlMgdjAuNy4wLVxuXHRcdFx0Zm9yIChrZXkgaW4gcHVueWNvZGUpIHtcblx0XHRcdFx0cHVueWNvZGUuaGFzT3duUHJvcGVydHkoa2V5KSAmJiAoZnJlZUV4cG9ydHNba2V5XSA9IHB1bnljb2RlW2tleV0pO1xuXHRcdFx0fVxuXHRcdH1cblx0fSBlbHNlIHsgLy8gaW4gUmhpbm8gb3IgYSB3ZWIgYnJvd3NlclxuXHRcdHJvb3QucHVueWNvZGUgPSBwdW55Y29kZTtcblx0fVxuXG59KHRoaXMpKTtcbiJdfQ==
},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/querystring-es3/decode.js":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

'use strict';

// If obj.hasOwnProperty has been overridden, then calling
// obj.hasOwnProperty(prop) will break.
// See: https://github.com/joyent/node/issues/1707
function hasOwnProperty(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
}

module.exports = function(qs, sep, eq, options) {
  sep = sep || '&';
  eq = eq || '=';
  var obj = {};

  if (typeof qs !== 'string' || qs.length === 0) {
    return obj;
  }

  var regexp = /\+/g;
  qs = qs.split(sep);

  var maxKeys = 1000;
  if (options && typeof options.maxKeys === 'number') {
    maxKeys = options.maxKeys;
  }

  var len = qs.length;
  // maxKeys <= 0 means that we should not limit keys count
  if (maxKeys > 0 && len > maxKeys) {
    len = maxKeys;
  }

  for (var i = 0; i < len; ++i) {
    var x = qs[i].replace(regexp, '%20'),
        idx = x.indexOf(eq),
        kstr, vstr, k, v;

    if (idx >= 0) {
      kstr = x.substr(0, idx);
      vstr = x.substr(idx + 1);
    } else {
      kstr = x;
      vstr = '';
    }

    k = decodeURIComponent(kstr);
    v = decodeURIComponent(vstr);

    if (!hasOwnProperty(obj, k)) {
      obj[k] = v;
    } else if (isArray(obj[k])) {
      obj[k].push(v);
    } else {
      obj[k] = [obj[k], v];
    }
  }

  return obj;
};

var isArray = Array.isArray || function (xs) {
  return Object.prototype.toString.call(xs) === '[object Array]';
};

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/querystring-es3/encode.js":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

'use strict';

var stringifyPrimitive = function(v) {
  switch (typeof v) {
    case 'string':
      return v;

    case 'boolean':
      return v ? 'true' : 'false';

    case 'number':
      return isFinite(v) ? v : '';

    default:
      return '';
  }
};

module.exports = function(obj, sep, eq, name) {
  sep = sep || '&';
  eq = eq || '=';
  if (obj === null) {
    obj = undefined;
  }

  if (typeof obj === 'object') {
    return map(objectKeys(obj), function(k) {
      var ks = encodeURIComponent(stringifyPrimitive(k)) + eq;
      if (isArray(obj[k])) {
        return map(obj[k], function(v) {
          return ks + encodeURIComponent(stringifyPrimitive(v));
        }).join(sep);
      } else {
        return ks + encodeURIComponent(stringifyPrimitive(obj[k]));
      }
    }).join(sep);

  }

  if (!name) return '';
  return encodeURIComponent(stringifyPrimitive(name)) + eq +
         encodeURIComponent(stringifyPrimitive(obj));
};

var isArray = Array.isArray || function (xs) {
  return Object.prototype.toString.call(xs) === '[object Array]';
};

function map (xs, f) {
  if (xs.map) return xs.map(f);
  var res = [];
  for (var i = 0; i < xs.length; i++) {
    res.push(f(xs[i], i));
  }
  return res;
}

var objectKeys = Object.keys || function (obj) {
  var res = [];
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) res.push(key);
  }
  return res;
};

},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/querystring-es3/index.js":[function(require,module,exports){
'use strict';

exports.decode = exports.parse = require('./decode');
exports.encode = exports.stringify = require('./encode');

},{"./decode":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/querystring-es3/decode.js","./encode":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/querystring-es3/encode.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/duplex.js":[function(require,module,exports){
module.exports = require("./lib/_stream_duplex.js")

},{"./lib/_stream_duplex.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_duplex.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_duplex.js":[function(require,module,exports){
(function (process){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

// a duplex stream is just a stream that is both readable and writable.
// Since JS doesn't have multiple prototypal inheritance, this class
// prototypally inherits from Readable, and then parasitically from
// Writable.

module.exports = Duplex;

/*<replacement>*/
var objectKeys = Object.keys || function (obj) {
  var keys = [];
  for (var key in obj) keys.push(key);
  return keys;
}
/*</replacement>*/


/*<replacement>*/
var util = require('core-util-is');
util.inherits = require('inherits');
/*</replacement>*/

var Readable = require('./_stream_readable');
var Writable = require('./_stream_writable');

util.inherits(Duplex, Readable);

forEach(objectKeys(Writable.prototype), function(method) {
  if (!Duplex.prototype[method])
    Duplex.prototype[method] = Writable.prototype[method];
});

function Duplex(options) {
  if (!(this instanceof Duplex))
    return new Duplex(options);

  Readable.call(this, options);
  Writable.call(this, options);

  if (options && options.readable === false)
    this.readable = false;

  if (options && options.writable === false)
    this.writable = false;

  this.allowHalfOpen = true;
  if (options && options.allowHalfOpen === false)
    this.allowHalfOpen = false;

  this.once('end', onend);
}

// the no-half-open enforcer
function onend() {
  // if we allow half-open state, or if the writable side ended,
  // then we're ok.
  if (this.allowHalfOpen || this._writableState.ended)
    return;

  // no more data can be written.
  // But allow more writes to happen in this tick.
  process.nextTick(this.end.bind(this));
}

function forEach (xs, f) {
  for (var i = 0, l = xs.length; i < l; i++) {
    f(xs[i], i);
  }
}

}).call(this,require('_process'))
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vbGliL19zdHJlYW1fZHVwbGV4LmpzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiI7QUFBQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EiLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG4vLyBhIGR1cGxleCBzdHJlYW0gaXMganVzdCBhIHN0cmVhbSB0aGF0IGlzIGJvdGggcmVhZGFibGUgYW5kIHdyaXRhYmxlLlxuLy8gU2luY2UgSlMgZG9lc24ndCBoYXZlIG11bHRpcGxlIHByb3RvdHlwYWwgaW5oZXJpdGFuY2UsIHRoaXMgY2xhc3Ncbi8vIHByb3RvdHlwYWxseSBpbmhlcml0cyBmcm9tIFJlYWRhYmxlLCBhbmQgdGhlbiBwYXJhc2l0aWNhbGx5IGZyb21cbi8vIFdyaXRhYmxlLlxuXG5tb2R1bGUuZXhwb3J0cyA9IER1cGxleDtcblxuLyo8cmVwbGFjZW1lbnQ+Ki9cbnZhciBvYmplY3RLZXlzID0gT2JqZWN0LmtleXMgfHwgZnVuY3Rpb24gKG9iaikge1xuICB2YXIga2V5cyA9IFtdO1xuICBmb3IgKHZhciBrZXkgaW4gb2JqKSBrZXlzLnB1c2goa2V5KTtcbiAgcmV0dXJuIGtleXM7XG59XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxuXG4vKjxyZXBsYWNlbWVudD4qL1xudmFyIHV0aWwgPSByZXF1aXJlKCdjb3JlLXV0aWwtaXMnKTtcbnV0aWwuaW5oZXJpdHMgPSByZXF1aXJlKCdpbmhlcml0cycpO1xuLyo8L3JlcGxhY2VtZW50PiovXG5cbnZhciBSZWFkYWJsZSA9IHJlcXVpcmUoJy4vX3N0cmVhbV9yZWFkYWJsZScpO1xudmFyIFdyaXRhYmxlID0gcmVxdWlyZSgnLi9fc3RyZWFtX3dyaXRhYmxlJyk7XG5cbnV0aWwuaW5oZXJpdHMoRHVwbGV4LCBSZWFkYWJsZSk7XG5cbmZvckVhY2gob2JqZWN0S2V5cyhXcml0YWJsZS5wcm90b3R5cGUpLCBmdW5jdGlvbihtZXRob2QpIHtcbiAgaWYgKCFEdXBsZXgucHJvdG90eXBlW21ldGhvZF0pXG4gICAgRHVwbGV4LnByb3RvdHlwZVttZXRob2RdID0gV3JpdGFibGUucHJvdG90eXBlW21ldGhvZF07XG59KTtcblxuZnVuY3Rpb24gRHVwbGV4KG9wdGlvbnMpIHtcbiAgaWYgKCEodGhpcyBpbnN0YW5jZW9mIER1cGxleCkpXG4gICAgcmV0dXJuIG5ldyBEdXBsZXgob3B0aW9ucyk7XG5cbiAgUmVhZGFibGUuY2FsbCh0aGlzLCBvcHRpb25zKTtcbiAgV3JpdGFibGUuY2FsbCh0aGlzLCBvcHRpb25zKTtcblxuICBpZiAob3B0aW9ucyAmJiBvcHRpb25zLnJlYWRhYmxlID09PSBmYWxzZSlcbiAgICB0aGlzLnJlYWRhYmxlID0gZmFsc2U7XG5cbiAgaWYgKG9wdGlvbnMgJiYgb3B0aW9ucy53cml0YWJsZSA9PT0gZmFsc2UpXG4gICAgdGhpcy53cml0YWJsZSA9IGZhbHNlO1xuXG4gIHRoaXMuYWxsb3dIYWxmT3BlbiA9IHRydWU7XG4gIGlmIChvcHRpb25zICYmIG9wdGlvbnMuYWxsb3dIYWxmT3BlbiA9PT0gZmFsc2UpXG4gICAgdGhpcy5hbGxvd0hhbGZPcGVuID0gZmFsc2U7XG5cbiAgdGhpcy5vbmNlKCdlbmQnLCBvbmVuZCk7XG59XG5cbi8vIHRoZSBuby1oYWxmLW9wZW4gZW5mb3JjZXJcbmZ1bmN0aW9uIG9uZW5kKCkge1xuICAvLyBpZiB3ZSBhbGxvdyBoYWxmLW9wZW4gc3RhdGUsIG9yIGlmIHRoZSB3cml0YWJsZSBzaWRlIGVuZGVkLFxuICAvLyB0aGVuIHdlJ3JlIG9rLlxuICBpZiAodGhpcy5hbGxvd0hhbGZPcGVuIHx8IHRoaXMuX3dyaXRhYmxlU3RhdGUuZW5kZWQpXG4gICAgcmV0dXJuO1xuXG4gIC8vIG5vIG1vcmUgZGF0YSBjYW4gYmUgd3JpdHRlbi5cbiAgLy8gQnV0IGFsbG93IG1vcmUgd3JpdGVzIHRvIGhhcHBlbiBpbiB0aGlzIHRpY2suXG4gIHByb2Nlc3MubmV4dFRpY2sodGhpcy5lbmQuYmluZCh0aGlzKSk7XG59XG5cbmZ1bmN0aW9uIGZvckVhY2ggKHhzLCBmKSB7XG4gIGZvciAodmFyIGkgPSAwLCBsID0geHMubGVuZ3RoOyBpIDwgbDsgaSsrKSB7XG4gICAgZih4c1tpXSwgaSk7XG4gIH1cbn1cbiJdfQ==
},{"./_stream_readable":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_readable.js","./_stream_writable":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_writable.js","_process":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/process/browser.js","core-util-is":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/node_modules/core-util-is/lib/util.js","inherits":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_passthrough.js":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

// a passthrough stream.
// basically just the most minimal sort of Transform stream.
// Every written chunk gets output as-is.

module.exports = PassThrough;

var Transform = require('./_stream_transform');

/*<replacement>*/
var util = require('core-util-is');
util.inherits = require('inherits');
/*</replacement>*/

util.inherits(PassThrough, Transform);

function PassThrough(options) {
  if (!(this instanceof PassThrough))
    return new PassThrough(options);

  Transform.call(this, options);
}

PassThrough.prototype._transform = function(chunk, encoding, cb) {
  cb(null, chunk);
};

},{"./_stream_transform":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_transform.js","core-util-is":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/node_modules/core-util-is/lib/util.js","inherits":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_readable.js":[function(require,module,exports){
(function (process){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

module.exports = Readable;

/*<replacement>*/
var isArray = require('isarray');
/*</replacement>*/


/*<replacement>*/
var Buffer = require('buffer').Buffer;
/*</replacement>*/

Readable.ReadableState = ReadableState;

var EE = require('events').EventEmitter;

/*<replacement>*/
if (!EE.listenerCount) EE.listenerCount = function(emitter, type) {
  return emitter.listeners(type).length;
};
/*</replacement>*/

var Stream = require('stream');

/*<replacement>*/
var util = require('core-util-is');
util.inherits = require('inherits');
/*</replacement>*/

var StringDecoder;


/*<replacement>*/
var debug = require('util');
if (debug && debug.debuglog) {
  debug = debug.debuglog('stream');
} else {
  debug = function () {};
}
/*</replacement>*/


util.inherits(Readable, Stream);

function ReadableState(options, stream) {
  var Duplex = require('./_stream_duplex');

  options = options || {};

  // the point at which it stops calling _read() to fill the buffer
  // Note: 0 is a valid value, means "don't call _read preemptively ever"
  var hwm = options.highWaterMark;
  var defaultHwm = options.objectMode ? 16 : 16 * 1024;
  this.highWaterMark = (hwm || hwm === 0) ? hwm : defaultHwm;

  // cast to ints.
  this.highWaterMark = ~~this.highWaterMark;

  this.buffer = [];
  this.length = 0;
  this.pipes = null;
  this.pipesCount = 0;
  this.flowing = null;
  this.ended = false;
  this.endEmitted = false;
  this.reading = false;

  // a flag to be able to tell if the onwrite cb is called immediately,
  // or on a later tick.  We set this to true at first, because any
  // actions that shouldn't happen until "later" should generally also
  // not happen before the first write call.
  this.sync = true;

  // whenever we return null, then we set a flag to say
  // that we're awaiting a 'readable' event emission.
  this.needReadable = false;
  this.emittedReadable = false;
  this.readableListening = false;


  // object stream flag. Used to make read(n) ignore n and to
  // make all the buffer merging and length checks go away
  this.objectMode = !!options.objectMode;

  if (stream instanceof Duplex)
    this.objectMode = this.objectMode || !!options.readableObjectMode;

  // Crypto is kind of old and crusty.  Historically, its default string
  // encoding is 'binary' so we have to make this configurable.
  // Everything else in the universe uses 'utf8', though.
  this.defaultEncoding = options.defaultEncoding || 'utf8';

  // when piping, we only care about 'readable' events that happen
  // after read()ing all the bytes and not getting any pushback.
  this.ranOut = false;

  // the number of writers that are awaiting a drain event in .pipe()s
  this.awaitDrain = 0;

  // if true, a maybeReadMore has been scheduled
  this.readingMore = false;

  this.decoder = null;
  this.encoding = null;
  if (options.encoding) {
    if (!StringDecoder)
      StringDecoder = require('string_decoder/').StringDecoder;
    this.decoder = new StringDecoder(options.encoding);
    this.encoding = options.encoding;
  }
}

function Readable(options) {
  var Duplex = require('./_stream_duplex');

  if (!(this instanceof Readable))
    return new Readable(options);

  this._readableState = new ReadableState(options, this);

  // legacy
  this.readable = true;

  Stream.call(this);
}

// Manually shove something into the read() buffer.
// This returns true if the highWaterMark has not been hit yet,
// similar to how Writable.write() returns true if you should
// write() some more.
Readable.prototype.push = function(chunk, encoding) {
  var state = this._readableState;

  if (util.isString(chunk) && !state.objectMode) {
    encoding = encoding || state.defaultEncoding;
    if (encoding !== state.encoding) {
      chunk = new Buffer(chunk, encoding);
      encoding = '';
    }
  }

  return readableAddChunk(this, state, chunk, encoding, false);
};

// Unshift should *always* be something directly out of read()
Readable.prototype.unshift = function(chunk) {
  var state = this._readableState;
  return readableAddChunk(this, state, chunk, '', true);
};

function readableAddChunk(stream, state, chunk, encoding, addToFront) {
  var er = chunkInvalid(state, chunk);
  if (er) {
    stream.emit('error', er);
  } else if (util.isNullOrUndefined(chunk)) {
    state.reading = false;
    if (!state.ended)
      onEofChunk(stream, state);
  } else if (state.objectMode || chunk && chunk.length > 0) {
    if (state.ended && !addToFront) {
      var e = new Error('stream.push() after EOF');
      stream.emit('error', e);
    } else if (state.endEmitted && addToFront) {
      var e = new Error('stream.unshift() after end event');
      stream.emit('error', e);
    } else {
      if (state.decoder && !addToFront && !encoding)
        chunk = state.decoder.write(chunk);

      if (!addToFront)
        state.reading = false;

      // if we want the data now, just emit it.
      if (state.flowing && state.length === 0 && !state.sync) {
        stream.emit('data', chunk);
        stream.read(0);
      } else {
        // update the buffer info.
        state.length += state.objectMode ? 1 : chunk.length;
        if (addToFront)
          state.buffer.unshift(chunk);
        else
          state.buffer.push(chunk);

        if (state.needReadable)
          emitReadable(stream);
      }

      maybeReadMore(stream, state);
    }
  } else if (!addToFront) {
    state.reading = false;
  }

  return needMoreData(state);
}



// if it's past the high water mark, we can push in some more.
// Also, if we have no data yet, we can stand some
// more bytes.  This is to work around cases where hwm=0,
// such as the repl.  Also, if the push() triggered a
// readable event, and the user called read(largeNumber) such that
// needReadable was set, then we ought to push more, so that another
// 'readable' event will be triggered.
function needMoreData(state) {
  return !state.ended &&
         (state.needReadable ||
          state.length < state.highWaterMark ||
          state.length === 0);
}

// backwards compatibility.
Readable.prototype.setEncoding = function(enc) {
  if (!StringDecoder)
    StringDecoder = require('string_decoder/').StringDecoder;
  this._readableState.decoder = new StringDecoder(enc);
  this._readableState.encoding = enc;
  return this;
};

// Don't raise the hwm > 128MB
var MAX_HWM = 0x800000;
function roundUpToNextPowerOf2(n) {
  if (n >= MAX_HWM) {
    n = MAX_HWM;
  } else {
    // Get the next highest power of 2
    n--;
    for (var p = 1; p < 32; p <<= 1) n |= n >> p;
    n++;
  }
  return n;
}

function howMuchToRead(n, state) {
  if (state.length === 0 && state.ended)
    return 0;

  if (state.objectMode)
    return n === 0 ? 0 : 1;

  if (isNaN(n) || util.isNull(n)) {
    // only flow one buffer at a time
    if (state.flowing && state.buffer.length)
      return state.buffer[0].length;
    else
      return state.length;
  }

  if (n <= 0)
    return 0;

  // If we're asking for more than the target buffer level,
  // then raise the water mark.  Bump up to the next highest
  // power of 2, to prevent increasing it excessively in tiny
  // amounts.
  if (n > state.highWaterMark)
    state.highWaterMark = roundUpToNextPowerOf2(n);

  // don't have that much.  return null, unless we've ended.
  if (n > state.length) {
    if (!state.ended) {
      state.needReadable = true;
      return 0;
    } else
      return state.length;
  }

  return n;
}

// you can override either this method, or the async _read(n) below.
Readable.prototype.read = function(n) {
  debug('read', n);
  var state = this._readableState;
  var nOrig = n;

  if (!util.isNumber(n) || n > 0)
    state.emittedReadable = false;

  // if we're doing read(0) to trigger a readable event, but we
  // already have a bunch of data in the buffer, then just trigger
  // the 'readable' event and move on.
  if (n === 0 &&
      state.needReadable &&
      (state.length >= state.highWaterMark || state.ended)) {
    debug('read: emitReadable', state.length, state.ended);
    if (state.length === 0 && state.ended)
      endReadable(this);
    else
      emitReadable(this);
    return null;
  }

  n = howMuchToRead(n, state);

  // if we've ended, and we're now clear, then finish it up.
  if (n === 0 && state.ended) {
    if (state.length === 0)
      endReadable(this);
    return null;
  }

  // All the actual chunk generation logic needs to be
  // *below* the call to _read.  The reason is that in certain
  // synthetic stream cases, such as passthrough streams, _read
  // may be a completely synchronous operation which may change
  // the state of the read buffer, providing enough data when
  // before there was *not* enough.
  //
  // So, the steps are:
  // 1. Figure out what the state of things will be after we do
  // a read from the buffer.
  //
  // 2. If that resulting state will trigger a _read, then call _read.
  // Note that this may be asynchronous, or synchronous.  Yes, it is
  // deeply ugly to write APIs this way, but that still doesn't mean
  // that the Readable class should behave improperly, as streams are
  // designed to be sync/async agnostic.
  // Take note if the _read call is sync or async (ie, if the read call
  // has returned yet), so that we know whether or not it's safe to emit
  // 'readable' etc.
  //
  // 3. Actually pull the requested chunks out of the buffer and return.

  // if we need a readable event, then we need to do some reading.
  var doRead = state.needReadable;
  debug('need readable', doRead);

  // if we currently have less than the highWaterMark, then also read some
  if (state.length === 0 || state.length - n < state.highWaterMark) {
    doRead = true;
    debug('length less than watermark', doRead);
  }

  // however, if we've ended, then there's no point, and if we're already
  // reading, then it's unnecessary.
  if (state.ended || state.reading) {
    doRead = false;
    debug('reading or ended', doRead);
  }

  if (doRead) {
    debug('do read');
    state.reading = true;
    state.sync = true;
    // if the length is currently zero, then we *need* a readable event.
    if (state.length === 0)
      state.needReadable = true;
    // call internal read method
    this._read(state.highWaterMark);
    state.sync = false;
  }

  // If _read pushed data synchronously, then `reading` will be false,
  // and we need to re-evaluate how much data we can return to the user.
  if (doRead && !state.reading)
    n = howMuchToRead(nOrig, state);

  var ret;
  if (n > 0)
    ret = fromList(n, state);
  else
    ret = null;

  if (util.isNull(ret)) {
    state.needReadable = true;
    n = 0;
  }

  state.length -= n;

  // If we have nothing in the buffer, then we want to know
  // as soon as we *do* get something into the buffer.
  if (state.length === 0 && !state.ended)
    state.needReadable = true;

  // If we tried to read() past the EOF, then emit end on the next tick.
  if (nOrig !== n && state.ended && state.length === 0)
    endReadable(this);

  if (!util.isNull(ret))
    this.emit('data', ret);

  return ret;
};

function chunkInvalid(state, chunk) {
  var er = null;
  if (!util.isBuffer(chunk) &&
      !util.isString(chunk) &&
      !util.isNullOrUndefined(chunk) &&
      !state.objectMode) {
    er = new TypeError('Invalid non-string/buffer chunk');
  }
  return er;
}


function onEofChunk(stream, state) {
  if (state.decoder && !state.ended) {
    var chunk = state.decoder.end();
    if (chunk && chunk.length) {
      state.buffer.push(chunk);
      state.length += state.objectMode ? 1 : chunk.length;
    }
  }
  state.ended = true;

  // emit 'readable' now to make sure it gets picked up.
  emitReadable(stream);
}

// Don't emit readable right away in sync mode, because this can trigger
// another read() call => stack overflow.  This way, it might trigger
// a nextTick recursion warning, but that's not so bad.
function emitReadable(stream) {
  var state = stream._readableState;
  state.needReadable = false;
  if (!state.emittedReadable) {
    debug('emitReadable', state.flowing);
    state.emittedReadable = true;
    if (state.sync)
      process.nextTick(function() {
        emitReadable_(stream);
      });
    else
      emitReadable_(stream);
  }
}

function emitReadable_(stream) {
  debug('emit readable');
  stream.emit('readable');
  flow(stream);
}


// at this point, the user has presumably seen the 'readable' event,
// and called read() to consume some data.  that may have triggered
// in turn another _read(n) call, in which case reading = true if
// it's in progress.
// However, if we're not ended, or reading, and the length < hwm,
// then go ahead and try to read some more preemptively.
function maybeReadMore(stream, state) {
  if (!state.readingMore) {
    state.readingMore = true;
    process.nextTick(function() {
      maybeReadMore_(stream, state);
    });
  }
}

function maybeReadMore_(stream, state) {
  var len = state.length;
  while (!state.reading && !state.flowing && !state.ended &&
         state.length < state.highWaterMark) {
    debug('maybeReadMore read 0');
    stream.read(0);
    if (len === state.length)
      // didn't get any data, stop spinning.
      break;
    else
      len = state.length;
  }
  state.readingMore = false;
}

// abstract method.  to be overridden in specific implementation classes.
// call cb(er, data) where data is <= n in length.
// for virtual (non-string, non-buffer) streams, "length" is somewhat
// arbitrary, and perhaps not very meaningful.
Readable.prototype._read = function(n) {
  this.emit('error', new Error('not implemented'));
};

Readable.prototype.pipe = function(dest, pipeOpts) {
  var src = this;
  var state = this._readableState;

  switch (state.pipesCount) {
    case 0:
      state.pipes = dest;
      break;
    case 1:
      state.pipes = [state.pipes, dest];
      break;
    default:
      state.pipes.push(dest);
      break;
  }
  state.pipesCount += 1;
  debug('pipe count=%d opts=%j', state.pipesCount, pipeOpts);

  var doEnd = (!pipeOpts || pipeOpts.end !== false) &&
              dest !== process.stdout &&
              dest !== process.stderr;

  var endFn = doEnd ? onend : cleanup;
  if (state.endEmitted)
    process.nextTick(endFn);
  else
    src.once('end', endFn);

  dest.on('unpipe', onunpipe);
  function onunpipe(readable) {
    debug('onunpipe');
    if (readable === src) {
      cleanup();
    }
  }

  function onend() {
    debug('onend');
    dest.end();
  }

  // when the dest drains, it reduces the awaitDrain counter
  // on the source.  This would be more elegant with a .once()
  // handler in flow(), but adding and removing repeatedly is
  // too slow.
  var ondrain = pipeOnDrain(src);
  dest.on('drain', ondrain);

  function cleanup() {
    debug('cleanup');
    // cleanup event handlers once the pipe is broken
    dest.removeListener('close', onclose);
    dest.removeListener('finish', onfinish);
    dest.removeListener('drain', ondrain);
    dest.removeListener('error', onerror);
    dest.removeListener('unpipe', onunpipe);
    src.removeListener('end', onend);
    src.removeListener('end', cleanup);
    src.removeListener('data', ondata);

    // if the reader is waiting for a drain event from this
    // specific writer, then it would cause it to never start
    // flowing again.
    // So, if this is awaiting a drain, then we just call it now.
    // If we don't know, then assume that we are waiting for one.
    if (state.awaitDrain &&
        (!dest._writableState || dest._writableState.needDrain))
      ondrain();
  }

  src.on('data', ondata);
  function ondata(chunk) {
    debug('ondata');
    var ret = dest.write(chunk);
    if (false === ret) {
      debug('false write response, pause',
            src._readableState.awaitDrain);
      src._readableState.awaitDrain++;
      src.pause();
    }
  }

  // if the dest has an error, then stop piping into it.
  // however, don't suppress the throwing behavior for this.
  function onerror(er) {
    debug('onerror', er);
    unpipe();
    dest.removeListener('error', onerror);
    if (EE.listenerCount(dest, 'error') === 0)
      dest.emit('error', er);
  }
  // This is a brutally ugly hack to make sure that our error handler
  // is attached before any userland ones.  NEVER DO THIS.
  if (!dest._events || !dest._events.error)
    dest.on('error', onerror);
  else if (isArray(dest._events.error))
    dest._events.error.unshift(onerror);
  else
    dest._events.error = [onerror, dest._events.error];



  // Both close and finish should trigger unpipe, but only once.
  function onclose() {
    dest.removeListener('finish', onfinish);
    unpipe();
  }
  dest.once('close', onclose);
  function onfinish() {
    debug('onfinish');
    dest.removeListener('close', onclose);
    unpipe();
  }
  dest.once('finish', onfinish);

  function unpipe() {
    debug('unpipe');
    src.unpipe(dest);
  }

  // tell the dest that it's being piped to
  dest.emit('pipe', src);

  // start the flow if it hasn't been started already.
  if (!state.flowing) {
    debug('pipe resume');
    src.resume();
  }

  return dest;
};

function pipeOnDrain(src) {
  return function() {
    var state = src._readableState;
    debug('pipeOnDrain', state.awaitDrain);
    if (state.awaitDrain)
      state.awaitDrain--;
    if (state.awaitDrain === 0 && EE.listenerCount(src, 'data')) {
      state.flowing = true;
      flow(src);
    }
  };
}


Readable.prototype.unpipe = function(dest) {
  var state = this._readableState;

  // if we're not piping anywhere, then do nothing.
  if (state.pipesCount === 0)
    return this;

  // just one destination.  most common case.
  if (state.pipesCount === 1) {
    // passed in one, but it's not the right one.
    if (dest && dest !== state.pipes)
      return this;

    if (!dest)
      dest = state.pipes;

    // got a match.
    state.pipes = null;
    state.pipesCount = 0;
    state.flowing = false;
    if (dest)
      dest.emit('unpipe', this);
    return this;
  }

  // slow case. multiple pipe destinations.

  if (!dest) {
    // remove all.
    var dests = state.pipes;
    var len = state.pipesCount;
    state.pipes = null;
    state.pipesCount = 0;
    state.flowing = false;

    for (var i = 0; i < len; i++)
      dests[i].emit('unpipe', this);
    return this;
  }

  // try to find the right one.
  var i = indexOf(state.pipes, dest);
  if (i === -1)
    return this;

  state.pipes.splice(i, 1);
  state.pipesCount -= 1;
  if (state.pipesCount === 1)
    state.pipes = state.pipes[0];

  dest.emit('unpipe', this);

  return this;
};

// set up data events if they are asked for
// Ensure readable listeners eventually get something
Readable.prototype.on = function(ev, fn) {
  var res = Stream.prototype.on.call(this, ev, fn);

  // If listening to data, and it has not explicitly been paused,
  // then call resume to start the flow of data on the next tick.
  if (ev === 'data' && false !== this._readableState.flowing) {
    this.resume();
  }

  if (ev === 'readable' && this.readable) {
    var state = this._readableState;
    if (!state.readableListening) {
      state.readableListening = true;
      state.emittedReadable = false;
      state.needReadable = true;
      if (!state.reading) {
        var self = this;
        process.nextTick(function() {
          debug('readable nexttick read 0');
          self.read(0);
        });
      } else if (state.length) {
        emitReadable(this, state);
      }
    }
  }

  return res;
};
Readable.prototype.addListener = Readable.prototype.on;

// pause() and resume() are remnants of the legacy readable stream API
// If the user uses them, then switch into old mode.
Readable.prototype.resume = function() {
  var state = this._readableState;
  if (!state.flowing) {
    debug('resume');
    state.flowing = true;
    if (!state.reading) {
      debug('resume read 0');
      this.read(0);
    }
    resume(this, state);
  }
  return this;
};

function resume(stream, state) {
  if (!state.resumeScheduled) {
    state.resumeScheduled = true;
    process.nextTick(function() {
      resume_(stream, state);
    });
  }
}

function resume_(stream, state) {
  state.resumeScheduled = false;
  stream.emit('resume');
  flow(stream);
  if (state.flowing && !state.reading)
    stream.read(0);
}

Readable.prototype.pause = function() {
  debug('call pause flowing=%j', this._readableState.flowing);
  if (false !== this._readableState.flowing) {
    debug('pause');
    this._readableState.flowing = false;
    this.emit('pause');
  }
  return this;
};

function flow(stream) {
  var state = stream._readableState;
  debug('flow', state.flowing);
  if (state.flowing) {
    do {
      var chunk = stream.read();
    } while (null !== chunk && state.flowing);
  }
}

// wrap an old-style stream as the async data source.
// This is *not* part of the readable stream interface.
// It is an ugly unfortunate mess of history.
Readable.prototype.wrap = function(stream) {
  var state = this._readableState;
  var paused = false;

  var self = this;
  stream.on('end', function() {
    debug('wrapped end');
    if (state.decoder && !state.ended) {
      var chunk = state.decoder.end();
      if (chunk && chunk.length)
        self.push(chunk);
    }

    self.push(null);
  });

  stream.on('data', function(chunk) {
    debug('wrapped data');
    if (state.decoder)
      chunk = state.decoder.write(chunk);
    if (!chunk || !state.objectMode && !chunk.length)
      return;

    var ret = self.push(chunk);
    if (!ret) {
      paused = true;
      stream.pause();
    }
  });

  // proxy all the other methods.
  // important when wrapping filters and duplexes.
  for (var i in stream) {
    if (util.isFunction(stream[i]) && util.isUndefined(this[i])) {
      this[i] = function(method) { return function() {
        return stream[method].apply(stream, arguments);
      }}(i);
    }
  }

  // proxy certain important events.
  var events = ['error', 'close', 'destroy', 'pause', 'resume'];
  forEach(events, function(ev) {
    stream.on(ev, self.emit.bind(self, ev));
  });

  // when we try to consume some more bytes, simply unpause the
  // underlying stream.
  self._read = function(n) {
    debug('wrapped _read', n);
    if (paused) {
      paused = false;
      stream.resume();
    }
  };

  return self;
};



// exposed for testing purposes only.
Readable._fromList = fromList;

// Pluck off n bytes from an array of buffers.
// Length is the combined lengths of all the buffers in the list.
function fromList(n, state) {
  var list = state.buffer;
  var length = state.length;
  var stringMode = !!state.decoder;
  var objectMode = !!state.objectMode;
  var ret;

  // nothing in the list, definitely empty.
  if (list.length === 0)
    return null;

  if (length === 0)
    ret = null;
  else if (objectMode)
    ret = list.shift();
  else if (!n || n >= length) {
    // read it all, truncate the array.
    if (stringMode)
      ret = list.join('');
    else
      ret = Buffer.concat(list, length);
    list.length = 0;
  } else {
    // read just some of it.
    if (n < list[0].length) {
      // just take a part of the first list item.
      // slice is the same for buffers and strings.
      var buf = list[0];
      ret = buf.slice(0, n);
      list[0] = buf.slice(n);
    } else if (n === list[0].length) {
      // first list is a perfect match
      ret = list.shift();
    } else {
      // complex case.
      // we have enough to cover it, but it spans past the first buffer.
      if (stringMode)
        ret = '';
      else
        ret = new Buffer(n);

      var c = 0;
      for (var i = 0, l = list.length; i < l && c < n; i++) {
        var buf = list[0];
        var cpy = Math.min(n - c, buf.length);

        if (stringMode)
          ret += buf.slice(0, cpy);
        else
          buf.copy(ret, c, 0, cpy);

        if (cpy < buf.length)
          list[0] = buf.slice(cpy);
        else
          list.shift();

        c += cpy;
      }
    }
  }

  return ret;
}

function endReadable(stream) {
  var state = stream._readableState;

  // If we get here before consuming all the bytes, then that is a
  // bug in node.  Should never happen.
  if (state.length > 0)
    throw new Error('endReadable called on non-empty stream');

  if (!state.endEmitted) {
    state.ended = true;
    process.nextTick(function() {
      // Check that we didn't get one last unshift.
      if (!state.endEmitted && state.length === 0) {
        state.endEmitted = true;
        stream.readable = false;
        stream.emit('end');
      }
    });
  }
}

function forEach (xs, f) {
  for (var i = 0, l = xs.length; i < l; i++) {
    f(xs[i], i);
  }
}

function indexOf (xs, x) {
  for (var i = 0, l = xs.length; i < l; i++) {
    if (xs[i] === x) return i;
  }
  return -1;
}

}).call(this,require('_process'))
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vbGliL19zdHJlYW1fcmVhZGFibGUuanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgSm95ZW50LCBJbmMuIGFuZCBvdGhlciBOb2RlIGNvbnRyaWJ1dG9ycy5cbi8vXG4vLyBQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcgYVxuLy8gY29weSBvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZVxuLy8gXCJTb2Z0d2FyZVwiKSwgdG8gZGVhbCBpbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nXG4vLyB3aXRob3V0IGxpbWl0YXRpb24gdGhlIHJpZ2h0cyB0byB1c2UsIGNvcHksIG1vZGlmeSwgbWVyZ2UsIHB1Ymxpc2gsXG4vLyBkaXN0cmlidXRlLCBzdWJsaWNlbnNlLCBhbmQvb3Igc2VsbCBjb3BpZXMgb2YgdGhlIFNvZnR3YXJlLCBhbmQgdG8gcGVybWl0XG4vLyBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzIGZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGVcbi8vIGZvbGxvd2luZyBjb25kaXRpb25zOlxuLy9cbi8vIFRoZSBhYm92ZSBjb3B5cmlnaHQgbm90aWNlIGFuZCB0aGlzIHBlcm1pc3Npb24gbm90aWNlIHNoYWxsIGJlIGluY2x1ZGVkXG4vLyBpbiBhbGwgY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS5cbi8vXG4vLyBUSEUgU09GVFdBUkUgSVMgUFJPVklERUQgXCJBUyBJU1wiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTXG4vLyBPUiBJTVBMSUVELCBJTkNMVURJTkcgQlVUIE5PVCBMSU1JVEVEIFRPIFRIRSBXQVJSQU5USUVTIE9GXG4vLyBNRVJDSEFOVEFCSUxJVFksIEZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFORCBOT05JTkZSSU5HRU1FTlQuIElOXG4vLyBOTyBFVkVOVCBTSEFMTCBUSEUgQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSxcbi8vIERBTUFHRVMgT1IgT1RIRVIgTElBQklMSVRZLCBXSEVUSEVSIElOIEFOIEFDVElPTiBPRiBDT05UUkFDVCwgVE9SVCBPUlxuLy8gT1RIRVJXSVNFLCBBUklTSU5HIEZST00sIE9VVCBPRiBPUiBJTiBDT05ORUNUSU9OIFdJVEggVEhFIFNPRlRXQVJFIE9SIFRIRVxuLy8gVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRSBTT0ZUV0FSRS5cblxubW9kdWxlLmV4cG9ydHMgPSBSZWFkYWJsZTtcblxuLyo8cmVwbGFjZW1lbnQ+Ki9cbnZhciBpc0FycmF5ID0gcmVxdWlyZSgnaXNhcnJheScpO1xuLyo8L3JlcGxhY2VtZW50PiovXG5cblxuLyo8cmVwbGFjZW1lbnQ+Ki9cbnZhciBCdWZmZXIgPSByZXF1aXJlKCdidWZmZXInKS5CdWZmZXI7XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxuUmVhZGFibGUuUmVhZGFibGVTdGF0ZSA9IFJlYWRhYmxlU3RhdGU7XG5cbnZhciBFRSA9IHJlcXVpcmUoJ2V2ZW50cycpLkV2ZW50RW1pdHRlcjtcblxuLyo8cmVwbGFjZW1lbnQ+Ki9cbmlmICghRUUubGlzdGVuZXJDb3VudCkgRUUubGlzdGVuZXJDb3VudCA9IGZ1bmN0aW9uKGVtaXR0ZXIsIHR5cGUpIHtcbiAgcmV0dXJuIGVtaXR0ZXIubGlzdGVuZXJzKHR5cGUpLmxlbmd0aDtcbn07XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxudmFyIFN0cmVhbSA9IHJlcXVpcmUoJ3N0cmVhbScpO1xuXG4vKjxyZXBsYWNlbWVudD4qL1xudmFyIHV0aWwgPSByZXF1aXJlKCdjb3JlLXV0aWwtaXMnKTtcbnV0aWwuaW5oZXJpdHMgPSByZXF1aXJlKCdpbmhlcml0cycpO1xuLyo8L3JlcGxhY2VtZW50PiovXG5cbnZhciBTdHJpbmdEZWNvZGVyO1xuXG5cbi8qPHJlcGxhY2VtZW50PiovXG52YXIgZGVidWcgPSByZXF1aXJlKCd1dGlsJyk7XG5pZiAoZGVidWcgJiYgZGVidWcuZGVidWdsb2cpIHtcbiAgZGVidWcgPSBkZWJ1Zy5kZWJ1Z2xvZygnc3RyZWFtJyk7XG59IGVsc2Uge1xuICBkZWJ1ZyA9IGZ1bmN0aW9uICgpIHt9O1xufVxuLyo8L3JlcGxhY2VtZW50PiovXG5cblxudXRpbC5pbmhlcml0cyhSZWFkYWJsZSwgU3RyZWFtKTtcblxuZnVuY3Rpb24gUmVhZGFibGVTdGF0ZShvcHRpb25zLCBzdHJlYW0pIHtcbiAgdmFyIER1cGxleCA9IHJlcXVpcmUoJy4vX3N0cmVhbV9kdXBsZXgnKTtcblxuICBvcHRpb25zID0gb3B0aW9ucyB8fCB7fTtcblxuICAvLyB0aGUgcG9pbnQgYXQgd2hpY2ggaXQgc3RvcHMgY2FsbGluZyBfcmVhZCgpIHRvIGZpbGwgdGhlIGJ1ZmZlclxuICAvLyBOb3RlOiAwIGlzIGEgdmFsaWQgdmFsdWUsIG1lYW5zIFwiZG9uJ3QgY2FsbCBfcmVhZCBwcmVlbXB0aXZlbHkgZXZlclwiXG4gIHZhciBod20gPSBvcHRpb25zLmhpZ2hXYXRlck1hcms7XG4gIHZhciBkZWZhdWx0SHdtID0gb3B0aW9ucy5vYmplY3RNb2RlID8gMTYgOiAxNiAqIDEwMjQ7XG4gIHRoaXMuaGlnaFdhdGVyTWFyayA9IChod20gfHwgaHdtID09PSAwKSA/IGh3bSA6IGRlZmF1bHRId207XG5cbiAgLy8gY2FzdCB0byBpbnRzLlxuICB0aGlzLmhpZ2hXYXRlck1hcmsgPSB+fnRoaXMuaGlnaFdhdGVyTWFyaztcblxuICB0aGlzLmJ1ZmZlciA9IFtdO1xuICB0aGlzLmxlbmd0aCA9IDA7XG4gIHRoaXMucGlwZXMgPSBudWxsO1xuICB0aGlzLnBpcGVzQ291bnQgPSAwO1xuICB0aGlzLmZsb3dpbmcgPSBudWxsO1xuICB0aGlzLmVuZGVkID0gZmFsc2U7XG4gIHRoaXMuZW5kRW1pdHRlZCA9IGZhbHNlO1xuICB0aGlzLnJlYWRpbmcgPSBmYWxzZTtcblxuICAvLyBhIGZsYWcgdG8gYmUgYWJsZSB0byB0ZWxsIGlmIHRoZSBvbndyaXRlIGNiIGlzIGNhbGxlZCBpbW1lZGlhdGVseSxcbiAgLy8gb3Igb24gYSBsYXRlciB0aWNrLiAgV2Ugc2V0IHRoaXMgdG8gdHJ1ZSBhdCBmaXJzdCwgYmVjYXVzZSBhbnlcbiAgLy8gYWN0aW9ucyB0aGF0IHNob3VsZG4ndCBoYXBwZW4gdW50aWwgXCJsYXRlclwiIHNob3VsZCBnZW5lcmFsbHkgYWxzb1xuICAvLyBub3QgaGFwcGVuIGJlZm9yZSB0aGUgZmlyc3Qgd3JpdGUgY2FsbC5cbiAgdGhpcy5zeW5jID0gdHJ1ZTtcblxuICAvLyB3aGVuZXZlciB3ZSByZXR1cm4gbnVsbCwgdGhlbiB3ZSBzZXQgYSBmbGFnIHRvIHNheVxuICAvLyB0aGF0IHdlJ3JlIGF3YWl0aW5nIGEgJ3JlYWRhYmxlJyBldmVudCBlbWlzc2lvbi5cbiAgdGhpcy5uZWVkUmVhZGFibGUgPSBmYWxzZTtcbiAgdGhpcy5lbWl0dGVkUmVhZGFibGUgPSBmYWxzZTtcbiAgdGhpcy5yZWFkYWJsZUxpc3RlbmluZyA9IGZhbHNlO1xuXG5cbiAgLy8gb2JqZWN0IHN0cmVhbSBmbGFnLiBVc2VkIHRvIG1ha2UgcmVhZChuKSBpZ25vcmUgbiBhbmQgdG9cbiAgLy8gbWFrZSBhbGwgdGhlIGJ1ZmZlciBtZXJnaW5nIGFuZCBsZW5ndGggY2hlY2tzIGdvIGF3YXlcbiAgdGhpcy5vYmplY3RNb2RlID0gISFvcHRpb25zLm9iamVjdE1vZGU7XG5cbiAgaWYgKHN0cmVhbSBpbnN0YW5jZW9mIER1cGxleClcbiAgICB0aGlzLm9iamVjdE1vZGUgPSB0aGlzLm9iamVjdE1vZGUgfHwgISFvcHRpb25zLnJlYWRhYmxlT2JqZWN0TW9kZTtcblxuICAvLyBDcnlwdG8gaXMga2luZCBvZiBvbGQgYW5kIGNydXN0eS4gIEhpc3RvcmljYWxseSwgaXRzIGRlZmF1bHQgc3RyaW5nXG4gIC8vIGVuY29kaW5nIGlzICdiaW5hcnknIHNvIHdlIGhhdmUgdG8gbWFrZSB0aGlzIGNvbmZpZ3VyYWJsZS5cbiAgLy8gRXZlcnl0aGluZyBlbHNlIGluIHRoZSB1bml2ZXJzZSB1c2VzICd1dGY4JywgdGhvdWdoLlxuICB0aGlzLmRlZmF1bHRFbmNvZGluZyA9IG9wdGlvbnMuZGVmYXVsdEVuY29kaW5nIHx8ICd1dGY4JztcblxuICAvLyB3aGVuIHBpcGluZywgd2Ugb25seSBjYXJlIGFib3V0ICdyZWFkYWJsZScgZXZlbnRzIHRoYXQgaGFwcGVuXG4gIC8vIGFmdGVyIHJlYWQoKWluZyBhbGwgdGhlIGJ5dGVzIGFuZCBub3QgZ2V0dGluZyBhbnkgcHVzaGJhY2suXG4gIHRoaXMucmFuT3V0ID0gZmFsc2U7XG5cbiAgLy8gdGhlIG51bWJlciBvZiB3cml0ZXJzIHRoYXQgYXJlIGF3YWl0aW5nIGEgZHJhaW4gZXZlbnQgaW4gLnBpcGUoKXNcbiAgdGhpcy5hd2FpdERyYWluID0gMDtcblxuICAvLyBpZiB0cnVlLCBhIG1heWJlUmVhZE1vcmUgaGFzIGJlZW4gc2NoZWR1bGVkXG4gIHRoaXMucmVhZGluZ01vcmUgPSBmYWxzZTtcblxuICB0aGlzLmRlY29kZXIgPSBudWxsO1xuICB0aGlzLmVuY29kaW5nID0gbnVsbDtcbiAgaWYgKG9wdGlvbnMuZW5jb2RpbmcpIHtcbiAgICBpZiAoIVN0cmluZ0RlY29kZXIpXG4gICAgICBTdHJpbmdEZWNvZGVyID0gcmVxdWlyZSgnc3RyaW5nX2RlY29kZXIvJykuU3RyaW5nRGVjb2RlcjtcbiAgICB0aGlzLmRlY29kZXIgPSBuZXcgU3RyaW5nRGVjb2RlcihvcHRpb25zLmVuY29kaW5nKTtcbiAgICB0aGlzLmVuY29kaW5nID0gb3B0aW9ucy5lbmNvZGluZztcbiAgfVxufVxuXG5mdW5jdGlvbiBSZWFkYWJsZShvcHRpb25zKSB7XG4gIHZhciBEdXBsZXggPSByZXF1aXJlKCcuL19zdHJlYW1fZHVwbGV4Jyk7XG5cbiAgaWYgKCEodGhpcyBpbnN0YW5jZW9mIFJlYWRhYmxlKSlcbiAgICByZXR1cm4gbmV3IFJlYWRhYmxlKG9wdGlvbnMpO1xuXG4gIHRoaXMuX3JlYWRhYmxlU3RhdGUgPSBuZXcgUmVhZGFibGVTdGF0ZShvcHRpb25zLCB0aGlzKTtcblxuICAvLyBsZWdhY3lcbiAgdGhpcy5yZWFkYWJsZSA9IHRydWU7XG5cbiAgU3RyZWFtLmNhbGwodGhpcyk7XG59XG5cbi8vIE1hbnVhbGx5IHNob3ZlIHNvbWV0aGluZyBpbnRvIHRoZSByZWFkKCkgYnVmZmVyLlxuLy8gVGhpcyByZXR1cm5zIHRydWUgaWYgdGhlIGhpZ2hXYXRlck1hcmsgaGFzIG5vdCBiZWVuIGhpdCB5ZXQsXG4vLyBzaW1pbGFyIHRvIGhvdyBXcml0YWJsZS53cml0ZSgpIHJldHVybnMgdHJ1ZSBpZiB5b3Ugc2hvdWxkXG4vLyB3cml0ZSgpIHNvbWUgbW9yZS5cblJlYWRhYmxlLnByb3RvdHlwZS5wdXNoID0gZnVuY3Rpb24oY2h1bmssIGVuY29kaW5nKSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3JlYWRhYmxlU3RhdGU7XG5cbiAgaWYgKHV0aWwuaXNTdHJpbmcoY2h1bmspICYmICFzdGF0ZS5vYmplY3RNb2RlKSB7XG4gICAgZW5jb2RpbmcgPSBlbmNvZGluZyB8fCBzdGF0ZS5kZWZhdWx0RW5jb2Rpbmc7XG4gICAgaWYgKGVuY29kaW5nICE9PSBzdGF0ZS5lbmNvZGluZykge1xuICAgICAgY2h1bmsgPSBuZXcgQnVmZmVyKGNodW5rLCBlbmNvZGluZyk7XG4gICAgICBlbmNvZGluZyA9ICcnO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiByZWFkYWJsZUFkZENodW5rKHRoaXMsIHN0YXRlLCBjaHVuaywgZW5jb2RpbmcsIGZhbHNlKTtcbn07XG5cbi8vIFVuc2hpZnQgc2hvdWxkICphbHdheXMqIGJlIHNvbWV0aGluZyBkaXJlY3RseSBvdXQgb2YgcmVhZCgpXG5SZWFkYWJsZS5wcm90b3R5cGUudW5zaGlmdCA9IGZ1bmN0aW9uKGNodW5rKSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3JlYWRhYmxlU3RhdGU7XG4gIHJldHVybiByZWFkYWJsZUFkZENodW5rKHRoaXMsIHN0YXRlLCBjaHVuaywgJycsIHRydWUpO1xufTtcblxuZnVuY3Rpb24gcmVhZGFibGVBZGRDaHVuayhzdHJlYW0sIHN0YXRlLCBjaHVuaywgZW5jb2RpbmcsIGFkZFRvRnJvbnQpIHtcbiAgdmFyIGVyID0gY2h1bmtJbnZhbGlkKHN0YXRlLCBjaHVuayk7XG4gIGlmIChlcikge1xuICAgIHN0cmVhbS5lbWl0KCdlcnJvcicsIGVyKTtcbiAgfSBlbHNlIGlmICh1dGlsLmlzTnVsbE9yVW5kZWZpbmVkKGNodW5rKSkge1xuICAgIHN0YXRlLnJlYWRpbmcgPSBmYWxzZTtcbiAgICBpZiAoIXN0YXRlLmVuZGVkKVxuICAgICAgb25Fb2ZDaHVuayhzdHJlYW0sIHN0YXRlKTtcbiAgfSBlbHNlIGlmIChzdGF0ZS5vYmplY3RNb2RlIHx8IGNodW5rICYmIGNodW5rLmxlbmd0aCA+IDApIHtcbiAgICBpZiAoc3RhdGUuZW5kZWQgJiYgIWFkZFRvRnJvbnQpIHtcbiAgICAgIHZhciBlID0gbmV3IEVycm9yKCdzdHJlYW0ucHVzaCgpIGFmdGVyIEVPRicpO1xuICAgICAgc3RyZWFtLmVtaXQoJ2Vycm9yJywgZSk7XG4gICAgfSBlbHNlIGlmIChzdGF0ZS5lbmRFbWl0dGVkICYmIGFkZFRvRnJvbnQpIHtcbiAgICAgIHZhciBlID0gbmV3IEVycm9yKCdzdHJlYW0udW5zaGlmdCgpIGFmdGVyIGVuZCBldmVudCcpO1xuICAgICAgc3RyZWFtLmVtaXQoJ2Vycm9yJywgZSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGlmIChzdGF0ZS5kZWNvZGVyICYmICFhZGRUb0Zyb250ICYmICFlbmNvZGluZylcbiAgICAgICAgY2h1bmsgPSBzdGF0ZS5kZWNvZGVyLndyaXRlKGNodW5rKTtcblxuICAgICAgaWYgKCFhZGRUb0Zyb250KVxuICAgICAgICBzdGF0ZS5yZWFkaW5nID0gZmFsc2U7XG5cbiAgICAgIC8vIGlmIHdlIHdhbnQgdGhlIGRhdGEgbm93LCBqdXN0IGVtaXQgaXQuXG4gICAgICBpZiAoc3RhdGUuZmxvd2luZyAmJiBzdGF0ZS5sZW5ndGggPT09IDAgJiYgIXN0YXRlLnN5bmMpIHtcbiAgICAgICAgc3RyZWFtLmVtaXQoJ2RhdGEnLCBjaHVuayk7XG4gICAgICAgIHN0cmVhbS5yZWFkKDApO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgLy8gdXBkYXRlIHRoZSBidWZmZXIgaW5mby5cbiAgICAgICAgc3RhdGUubGVuZ3RoICs9IHN0YXRlLm9iamVjdE1vZGUgPyAxIDogY2h1bmsubGVuZ3RoO1xuICAgICAgICBpZiAoYWRkVG9Gcm9udClcbiAgICAgICAgICBzdGF0ZS5idWZmZXIudW5zaGlmdChjaHVuayk7XG4gICAgICAgIGVsc2VcbiAgICAgICAgICBzdGF0ZS5idWZmZXIucHVzaChjaHVuayk7XG5cbiAgICAgICAgaWYgKHN0YXRlLm5lZWRSZWFkYWJsZSlcbiAgICAgICAgICBlbWl0UmVhZGFibGUoc3RyZWFtKTtcbiAgICAgIH1cblxuICAgICAgbWF5YmVSZWFkTW9yZShzdHJlYW0sIHN0YXRlKTtcbiAgICB9XG4gIH0gZWxzZSBpZiAoIWFkZFRvRnJvbnQpIHtcbiAgICBzdGF0ZS5yZWFkaW5nID0gZmFsc2U7XG4gIH1cblxuICByZXR1cm4gbmVlZE1vcmVEYXRhKHN0YXRlKTtcbn1cblxuXG5cbi8vIGlmIGl0J3MgcGFzdCB0aGUgaGlnaCB3YXRlciBtYXJrLCB3ZSBjYW4gcHVzaCBpbiBzb21lIG1vcmUuXG4vLyBBbHNvLCBpZiB3ZSBoYXZlIG5vIGRhdGEgeWV0LCB3ZSBjYW4gc3RhbmQgc29tZVxuLy8gbW9yZSBieXRlcy4gIFRoaXMgaXMgdG8gd29yayBhcm91bmQgY2FzZXMgd2hlcmUgaHdtPTAsXG4vLyBzdWNoIGFzIHRoZSByZXBsLiAgQWxzbywgaWYgdGhlIHB1c2goKSB0cmlnZ2VyZWQgYVxuLy8gcmVhZGFibGUgZXZlbnQsIGFuZCB0aGUgdXNlciBjYWxsZWQgcmVhZChsYXJnZU51bWJlcikgc3VjaCB0aGF0XG4vLyBuZWVkUmVhZGFibGUgd2FzIHNldCwgdGhlbiB3ZSBvdWdodCB0byBwdXNoIG1vcmUsIHNvIHRoYXQgYW5vdGhlclxuLy8gJ3JlYWRhYmxlJyBldmVudCB3aWxsIGJlIHRyaWdnZXJlZC5cbmZ1bmN0aW9uIG5lZWRNb3JlRGF0YShzdGF0ZSkge1xuICByZXR1cm4gIXN0YXRlLmVuZGVkICYmXG4gICAgICAgICAoc3RhdGUubmVlZFJlYWRhYmxlIHx8XG4gICAgICAgICAgc3RhdGUubGVuZ3RoIDwgc3RhdGUuaGlnaFdhdGVyTWFyayB8fFxuICAgICAgICAgIHN0YXRlLmxlbmd0aCA9PT0gMCk7XG59XG5cbi8vIGJhY2t3YXJkcyBjb21wYXRpYmlsaXR5LlxuUmVhZGFibGUucHJvdG90eXBlLnNldEVuY29kaW5nID0gZnVuY3Rpb24oZW5jKSB7XG4gIGlmICghU3RyaW5nRGVjb2RlcilcbiAgICBTdHJpbmdEZWNvZGVyID0gcmVxdWlyZSgnc3RyaW5nX2RlY29kZXIvJykuU3RyaW5nRGVjb2RlcjtcbiAgdGhpcy5fcmVhZGFibGVTdGF0ZS5kZWNvZGVyID0gbmV3IFN0cmluZ0RlY29kZXIoZW5jKTtcbiAgdGhpcy5fcmVhZGFibGVTdGF0ZS5lbmNvZGluZyA9IGVuYztcbiAgcmV0dXJuIHRoaXM7XG59O1xuXG4vLyBEb24ndCByYWlzZSB0aGUgaHdtID4gMTI4TUJcbnZhciBNQVhfSFdNID0gMHg4MDAwMDA7XG5mdW5jdGlvbiByb3VuZFVwVG9OZXh0UG93ZXJPZjIobikge1xuICBpZiAobiA+PSBNQVhfSFdNKSB7XG4gICAgbiA9IE1BWF9IV007XG4gIH0gZWxzZSB7XG4gICAgLy8gR2V0IHRoZSBuZXh0IGhpZ2hlc3QgcG93ZXIgb2YgMlxuICAgIG4tLTtcbiAgICBmb3IgKHZhciBwID0gMTsgcCA8IDMyOyBwIDw8PSAxKSBuIHw9IG4gPj4gcDtcbiAgICBuKys7XG4gIH1cbiAgcmV0dXJuIG47XG59XG5cbmZ1bmN0aW9uIGhvd011Y2hUb1JlYWQobiwgc3RhdGUpIHtcbiAgaWYgKHN0YXRlLmxlbmd0aCA9PT0gMCAmJiBzdGF0ZS5lbmRlZClcbiAgICByZXR1cm4gMDtcblxuICBpZiAoc3RhdGUub2JqZWN0TW9kZSlcbiAgICByZXR1cm4gbiA9PT0gMCA/IDAgOiAxO1xuXG4gIGlmIChpc05hTihuKSB8fCB1dGlsLmlzTnVsbChuKSkge1xuICAgIC8vIG9ubHkgZmxvdyBvbmUgYnVmZmVyIGF0IGEgdGltZVxuICAgIGlmIChzdGF0ZS5mbG93aW5nICYmIHN0YXRlLmJ1ZmZlci5sZW5ndGgpXG4gICAgICByZXR1cm4gc3RhdGUuYnVmZmVyWzBdLmxlbmd0aDtcbiAgICBlbHNlXG4gICAgICByZXR1cm4gc3RhdGUubGVuZ3RoO1xuICB9XG5cbiAgaWYgKG4gPD0gMClcbiAgICByZXR1cm4gMDtcblxuICAvLyBJZiB3ZSdyZSBhc2tpbmcgZm9yIG1vcmUgdGhhbiB0aGUgdGFyZ2V0IGJ1ZmZlciBsZXZlbCxcbiAgLy8gdGhlbiByYWlzZSB0aGUgd2F0ZXIgbWFyay4gIEJ1bXAgdXAgdG8gdGhlIG5leHQgaGlnaGVzdFxuICAvLyBwb3dlciBvZiAyLCB0byBwcmV2ZW50IGluY3JlYXNpbmcgaXQgZXhjZXNzaXZlbHkgaW4gdGlueVxuICAvLyBhbW91bnRzLlxuICBpZiAobiA+IHN0YXRlLmhpZ2hXYXRlck1hcmspXG4gICAgc3RhdGUuaGlnaFdhdGVyTWFyayA9IHJvdW5kVXBUb05leHRQb3dlck9mMihuKTtcblxuICAvLyBkb24ndCBoYXZlIHRoYXQgbXVjaC4gIHJldHVybiBudWxsLCB1bmxlc3Mgd2UndmUgZW5kZWQuXG4gIGlmIChuID4gc3RhdGUubGVuZ3RoKSB7XG4gICAgaWYgKCFzdGF0ZS5lbmRlZCkge1xuICAgICAgc3RhdGUubmVlZFJlYWRhYmxlID0gdHJ1ZTtcbiAgICAgIHJldHVybiAwO1xuICAgIH0gZWxzZVxuICAgICAgcmV0dXJuIHN0YXRlLmxlbmd0aDtcbiAgfVxuXG4gIHJldHVybiBuO1xufVxuXG4vLyB5b3UgY2FuIG92ZXJyaWRlIGVpdGhlciB0aGlzIG1ldGhvZCwgb3IgdGhlIGFzeW5jIF9yZWFkKG4pIGJlbG93LlxuUmVhZGFibGUucHJvdG90eXBlLnJlYWQgPSBmdW5jdGlvbihuKSB7XG4gIGRlYnVnKCdyZWFkJywgbik7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3JlYWRhYmxlU3RhdGU7XG4gIHZhciBuT3JpZyA9IG47XG5cbiAgaWYgKCF1dGlsLmlzTnVtYmVyKG4pIHx8IG4gPiAwKVxuICAgIHN0YXRlLmVtaXR0ZWRSZWFkYWJsZSA9IGZhbHNlO1xuXG4gIC8vIGlmIHdlJ3JlIGRvaW5nIHJlYWQoMCkgdG8gdHJpZ2dlciBhIHJlYWRhYmxlIGV2ZW50LCBidXQgd2VcbiAgLy8gYWxyZWFkeSBoYXZlIGEgYnVuY2ggb2YgZGF0YSBpbiB0aGUgYnVmZmVyLCB0aGVuIGp1c3QgdHJpZ2dlclxuICAvLyB0aGUgJ3JlYWRhYmxlJyBldmVudCBhbmQgbW92ZSBvbi5cbiAgaWYgKG4gPT09IDAgJiZcbiAgICAgIHN0YXRlLm5lZWRSZWFkYWJsZSAmJlxuICAgICAgKHN0YXRlLmxlbmd0aCA+PSBzdGF0ZS5oaWdoV2F0ZXJNYXJrIHx8IHN0YXRlLmVuZGVkKSkge1xuICAgIGRlYnVnKCdyZWFkOiBlbWl0UmVhZGFibGUnLCBzdGF0ZS5sZW5ndGgsIHN0YXRlLmVuZGVkKTtcbiAgICBpZiAoc3RhdGUubGVuZ3RoID09PSAwICYmIHN0YXRlLmVuZGVkKVxuICAgICAgZW5kUmVhZGFibGUodGhpcyk7XG4gICAgZWxzZVxuICAgICAgZW1pdFJlYWRhYmxlKHRoaXMpO1xuICAgIHJldHVybiBudWxsO1xuICB9XG5cbiAgbiA9IGhvd011Y2hUb1JlYWQobiwgc3RhdGUpO1xuXG4gIC8vIGlmIHdlJ3ZlIGVuZGVkLCBhbmQgd2UncmUgbm93IGNsZWFyLCB0aGVuIGZpbmlzaCBpdCB1cC5cbiAgaWYgKG4gPT09IDAgJiYgc3RhdGUuZW5kZWQpIHtcbiAgICBpZiAoc3RhdGUubGVuZ3RoID09PSAwKVxuICAgICAgZW5kUmVhZGFibGUodGhpcyk7XG4gICAgcmV0dXJuIG51bGw7XG4gIH1cblxuICAvLyBBbGwgdGhlIGFjdHVhbCBjaHVuayBnZW5lcmF0aW9uIGxvZ2ljIG5lZWRzIHRvIGJlXG4gIC8vICpiZWxvdyogdGhlIGNhbGwgdG8gX3JlYWQuICBUaGUgcmVhc29uIGlzIHRoYXQgaW4gY2VydGFpblxuICAvLyBzeW50aGV0aWMgc3RyZWFtIGNhc2VzLCBzdWNoIGFzIHBhc3N0aHJvdWdoIHN0cmVhbXMsIF9yZWFkXG4gIC8vIG1heSBiZSBhIGNvbXBsZXRlbHkgc3luY2hyb25vdXMgb3BlcmF0aW9uIHdoaWNoIG1heSBjaGFuZ2VcbiAgLy8gdGhlIHN0YXRlIG9mIHRoZSByZWFkIGJ1ZmZlciwgcHJvdmlkaW5nIGVub3VnaCBkYXRhIHdoZW5cbiAgLy8gYmVmb3JlIHRoZXJlIHdhcyAqbm90KiBlbm91Z2guXG4gIC8vXG4gIC8vIFNvLCB0aGUgc3RlcHMgYXJlOlxuICAvLyAxLiBGaWd1cmUgb3V0IHdoYXQgdGhlIHN0YXRlIG9mIHRoaW5ncyB3aWxsIGJlIGFmdGVyIHdlIGRvXG4gIC8vIGEgcmVhZCBmcm9tIHRoZSBidWZmZXIuXG4gIC8vXG4gIC8vIDIuIElmIHRoYXQgcmVzdWx0aW5nIHN0YXRlIHdpbGwgdHJpZ2dlciBhIF9yZWFkLCB0aGVuIGNhbGwgX3JlYWQuXG4gIC8vIE5vdGUgdGhhdCB0aGlzIG1heSBiZSBhc3luY2hyb25vdXMsIG9yIHN5bmNocm9ub3VzLiAgWWVzLCBpdCBpc1xuICAvLyBkZWVwbHkgdWdseSB0byB3cml0ZSBBUElzIHRoaXMgd2F5LCBidXQgdGhhdCBzdGlsbCBkb2Vzbid0IG1lYW5cbiAgLy8gdGhhdCB0aGUgUmVhZGFibGUgY2xhc3Mgc2hvdWxkIGJlaGF2ZSBpbXByb3Blcmx5LCBhcyBzdHJlYW1zIGFyZVxuICAvLyBkZXNpZ25lZCB0byBiZSBzeW5jL2FzeW5jIGFnbm9zdGljLlxuICAvLyBUYWtlIG5vdGUgaWYgdGhlIF9yZWFkIGNhbGwgaXMgc3luYyBvciBhc3luYyAoaWUsIGlmIHRoZSByZWFkIGNhbGxcbiAgLy8gaGFzIHJldHVybmVkIHlldCksIHNvIHRoYXQgd2Uga25vdyB3aGV0aGVyIG9yIG5vdCBpdCdzIHNhZmUgdG8gZW1pdFxuICAvLyAncmVhZGFibGUnIGV0Yy5cbiAgLy9cbiAgLy8gMy4gQWN0dWFsbHkgcHVsbCB0aGUgcmVxdWVzdGVkIGNodW5rcyBvdXQgb2YgdGhlIGJ1ZmZlciBhbmQgcmV0dXJuLlxuXG4gIC8vIGlmIHdlIG5lZWQgYSByZWFkYWJsZSBldmVudCwgdGhlbiB3ZSBuZWVkIHRvIGRvIHNvbWUgcmVhZGluZy5cbiAgdmFyIGRvUmVhZCA9IHN0YXRlLm5lZWRSZWFkYWJsZTtcbiAgZGVidWcoJ25lZWQgcmVhZGFibGUnLCBkb1JlYWQpO1xuXG4gIC8vIGlmIHdlIGN1cnJlbnRseSBoYXZlIGxlc3MgdGhhbiB0aGUgaGlnaFdhdGVyTWFyaywgdGhlbiBhbHNvIHJlYWQgc29tZVxuICBpZiAoc3RhdGUubGVuZ3RoID09PSAwIHx8IHN0YXRlLmxlbmd0aCAtIG4gPCBzdGF0ZS5oaWdoV2F0ZXJNYXJrKSB7XG4gICAgZG9SZWFkID0gdHJ1ZTtcbiAgICBkZWJ1ZygnbGVuZ3RoIGxlc3MgdGhhbiB3YXRlcm1hcmsnLCBkb1JlYWQpO1xuICB9XG5cbiAgLy8gaG93ZXZlciwgaWYgd2UndmUgZW5kZWQsIHRoZW4gdGhlcmUncyBubyBwb2ludCwgYW5kIGlmIHdlJ3JlIGFscmVhZHlcbiAgLy8gcmVhZGluZywgdGhlbiBpdCdzIHVubmVjZXNzYXJ5LlxuICBpZiAoc3RhdGUuZW5kZWQgfHwgc3RhdGUucmVhZGluZykge1xuICAgIGRvUmVhZCA9IGZhbHNlO1xuICAgIGRlYnVnKCdyZWFkaW5nIG9yIGVuZGVkJywgZG9SZWFkKTtcbiAgfVxuXG4gIGlmIChkb1JlYWQpIHtcbiAgICBkZWJ1ZygnZG8gcmVhZCcpO1xuICAgIHN0YXRlLnJlYWRpbmcgPSB0cnVlO1xuICAgIHN0YXRlLnN5bmMgPSB0cnVlO1xuICAgIC8vIGlmIHRoZSBsZW5ndGggaXMgY3VycmVudGx5IHplcm8sIHRoZW4gd2UgKm5lZWQqIGEgcmVhZGFibGUgZXZlbnQuXG4gICAgaWYgKHN0YXRlLmxlbmd0aCA9PT0gMClcbiAgICAgIHN0YXRlLm5lZWRSZWFkYWJsZSA9IHRydWU7XG4gICAgLy8gY2FsbCBpbnRlcm5hbCByZWFkIG1ldGhvZFxuICAgIHRoaXMuX3JlYWQoc3RhdGUuaGlnaFdhdGVyTWFyayk7XG4gICAgc3RhdGUuc3luYyA9IGZhbHNlO1xuICB9XG5cbiAgLy8gSWYgX3JlYWQgcHVzaGVkIGRhdGEgc3luY2hyb25vdXNseSwgdGhlbiBgcmVhZGluZ2Agd2lsbCBiZSBmYWxzZSxcbiAgLy8gYW5kIHdlIG5lZWQgdG8gcmUtZXZhbHVhdGUgaG93IG11Y2ggZGF0YSB3ZSBjYW4gcmV0dXJuIHRvIHRoZSB1c2VyLlxuICBpZiAoZG9SZWFkICYmICFzdGF0ZS5yZWFkaW5nKVxuICAgIG4gPSBob3dNdWNoVG9SZWFkKG5PcmlnLCBzdGF0ZSk7XG5cbiAgdmFyIHJldDtcbiAgaWYgKG4gPiAwKVxuICAgIHJldCA9IGZyb21MaXN0KG4sIHN0YXRlKTtcbiAgZWxzZVxuICAgIHJldCA9IG51bGw7XG5cbiAgaWYgKHV0aWwuaXNOdWxsKHJldCkpIHtcbiAgICBzdGF0ZS5uZWVkUmVhZGFibGUgPSB0cnVlO1xuICAgIG4gPSAwO1xuICB9XG5cbiAgc3RhdGUubGVuZ3RoIC09IG47XG5cbiAgLy8gSWYgd2UgaGF2ZSBub3RoaW5nIGluIHRoZSBidWZmZXIsIHRoZW4gd2Ugd2FudCB0byBrbm93XG4gIC8vIGFzIHNvb24gYXMgd2UgKmRvKiBnZXQgc29tZXRoaW5nIGludG8gdGhlIGJ1ZmZlci5cbiAgaWYgKHN0YXRlLmxlbmd0aCA9PT0gMCAmJiAhc3RhdGUuZW5kZWQpXG4gICAgc3RhdGUubmVlZFJlYWRhYmxlID0gdHJ1ZTtcblxuICAvLyBJZiB3ZSB0cmllZCB0byByZWFkKCkgcGFzdCB0aGUgRU9GLCB0aGVuIGVtaXQgZW5kIG9uIHRoZSBuZXh0IHRpY2suXG4gIGlmIChuT3JpZyAhPT0gbiAmJiBzdGF0ZS5lbmRlZCAmJiBzdGF0ZS5sZW5ndGggPT09IDApXG4gICAgZW5kUmVhZGFibGUodGhpcyk7XG5cbiAgaWYgKCF1dGlsLmlzTnVsbChyZXQpKVxuICAgIHRoaXMuZW1pdCgnZGF0YScsIHJldCk7XG5cbiAgcmV0dXJuIHJldDtcbn07XG5cbmZ1bmN0aW9uIGNodW5rSW52YWxpZChzdGF0ZSwgY2h1bmspIHtcbiAgdmFyIGVyID0gbnVsbDtcbiAgaWYgKCF1dGlsLmlzQnVmZmVyKGNodW5rKSAmJlxuICAgICAgIXV0aWwuaXNTdHJpbmcoY2h1bmspICYmXG4gICAgICAhdXRpbC5pc051bGxPclVuZGVmaW5lZChjaHVuaykgJiZcbiAgICAgICFzdGF0ZS5vYmplY3RNb2RlKSB7XG4gICAgZXIgPSBuZXcgVHlwZUVycm9yKCdJbnZhbGlkIG5vbi1zdHJpbmcvYnVmZmVyIGNodW5rJyk7XG4gIH1cbiAgcmV0dXJuIGVyO1xufVxuXG5cbmZ1bmN0aW9uIG9uRW9mQ2h1bmsoc3RyZWFtLCBzdGF0ZSkge1xuICBpZiAoc3RhdGUuZGVjb2RlciAmJiAhc3RhdGUuZW5kZWQpIHtcbiAgICB2YXIgY2h1bmsgPSBzdGF0ZS5kZWNvZGVyLmVuZCgpO1xuICAgIGlmIChjaHVuayAmJiBjaHVuay5sZW5ndGgpIHtcbiAgICAgIHN0YXRlLmJ1ZmZlci5wdXNoKGNodW5rKTtcbiAgICAgIHN0YXRlLmxlbmd0aCArPSBzdGF0ZS5vYmplY3RNb2RlID8gMSA6IGNodW5rLmxlbmd0aDtcbiAgICB9XG4gIH1cbiAgc3RhdGUuZW5kZWQgPSB0cnVlO1xuXG4gIC8vIGVtaXQgJ3JlYWRhYmxlJyBub3cgdG8gbWFrZSBzdXJlIGl0IGdldHMgcGlja2VkIHVwLlxuICBlbWl0UmVhZGFibGUoc3RyZWFtKTtcbn1cblxuLy8gRG9uJ3QgZW1pdCByZWFkYWJsZSByaWdodCBhd2F5IGluIHN5bmMgbW9kZSwgYmVjYXVzZSB0aGlzIGNhbiB0cmlnZ2VyXG4vLyBhbm90aGVyIHJlYWQoKSBjYWxsID0+IHN0YWNrIG92ZXJmbG93LiAgVGhpcyB3YXksIGl0IG1pZ2h0IHRyaWdnZXJcbi8vIGEgbmV4dFRpY2sgcmVjdXJzaW9uIHdhcm5pbmcsIGJ1dCB0aGF0J3Mgbm90IHNvIGJhZC5cbmZ1bmN0aW9uIGVtaXRSZWFkYWJsZShzdHJlYW0pIHtcbiAgdmFyIHN0YXRlID0gc3RyZWFtLl9yZWFkYWJsZVN0YXRlO1xuICBzdGF0ZS5uZWVkUmVhZGFibGUgPSBmYWxzZTtcbiAgaWYgKCFzdGF0ZS5lbWl0dGVkUmVhZGFibGUpIHtcbiAgICBkZWJ1ZygnZW1pdFJlYWRhYmxlJywgc3RhdGUuZmxvd2luZyk7XG4gICAgc3RhdGUuZW1pdHRlZFJlYWRhYmxlID0gdHJ1ZTtcbiAgICBpZiAoc3RhdGUuc3luYylcbiAgICAgIHByb2Nlc3MubmV4dFRpY2soZnVuY3Rpb24oKSB7XG4gICAgICAgIGVtaXRSZWFkYWJsZV8oc3RyZWFtKTtcbiAgICAgIH0pO1xuICAgIGVsc2VcbiAgICAgIGVtaXRSZWFkYWJsZV8oc3RyZWFtKTtcbiAgfVxufVxuXG5mdW5jdGlvbiBlbWl0UmVhZGFibGVfKHN0cmVhbSkge1xuICBkZWJ1ZygnZW1pdCByZWFkYWJsZScpO1xuICBzdHJlYW0uZW1pdCgncmVhZGFibGUnKTtcbiAgZmxvdyhzdHJlYW0pO1xufVxuXG5cbi8vIGF0IHRoaXMgcG9pbnQsIHRoZSB1c2VyIGhhcyBwcmVzdW1hYmx5IHNlZW4gdGhlICdyZWFkYWJsZScgZXZlbnQsXG4vLyBhbmQgY2FsbGVkIHJlYWQoKSB0byBjb25zdW1lIHNvbWUgZGF0YS4gIHRoYXQgbWF5IGhhdmUgdHJpZ2dlcmVkXG4vLyBpbiB0dXJuIGFub3RoZXIgX3JlYWQobikgY2FsbCwgaW4gd2hpY2ggY2FzZSByZWFkaW5nID0gdHJ1ZSBpZlxuLy8gaXQncyBpbiBwcm9ncmVzcy5cbi8vIEhvd2V2ZXIsIGlmIHdlJ3JlIG5vdCBlbmRlZCwgb3IgcmVhZGluZywgYW5kIHRoZSBsZW5ndGggPCBod20sXG4vLyB0aGVuIGdvIGFoZWFkIGFuZCB0cnkgdG8gcmVhZCBzb21lIG1vcmUgcHJlZW1wdGl2ZWx5LlxuZnVuY3Rpb24gbWF5YmVSZWFkTW9yZShzdHJlYW0sIHN0YXRlKSB7XG4gIGlmICghc3RhdGUucmVhZGluZ01vcmUpIHtcbiAgICBzdGF0ZS5yZWFkaW5nTW9yZSA9IHRydWU7XG4gICAgcHJvY2Vzcy5uZXh0VGljayhmdW5jdGlvbigpIHtcbiAgICAgIG1heWJlUmVhZE1vcmVfKHN0cmVhbSwgc3RhdGUpO1xuICAgIH0pO1xuICB9XG59XG5cbmZ1bmN0aW9uIG1heWJlUmVhZE1vcmVfKHN0cmVhbSwgc3RhdGUpIHtcbiAgdmFyIGxlbiA9IHN0YXRlLmxlbmd0aDtcbiAgd2hpbGUgKCFzdGF0ZS5yZWFkaW5nICYmICFzdGF0ZS5mbG93aW5nICYmICFzdGF0ZS5lbmRlZCAmJlxuICAgICAgICAgc3RhdGUubGVuZ3RoIDwgc3RhdGUuaGlnaFdhdGVyTWFyaykge1xuICAgIGRlYnVnKCdtYXliZVJlYWRNb3JlIHJlYWQgMCcpO1xuICAgIHN0cmVhbS5yZWFkKDApO1xuICAgIGlmIChsZW4gPT09IHN0YXRlLmxlbmd0aClcbiAgICAgIC8vIGRpZG4ndCBnZXQgYW55IGRhdGEsIHN0b3Agc3Bpbm5pbmcuXG4gICAgICBicmVhaztcbiAgICBlbHNlXG4gICAgICBsZW4gPSBzdGF0ZS5sZW5ndGg7XG4gIH1cbiAgc3RhdGUucmVhZGluZ01vcmUgPSBmYWxzZTtcbn1cblxuLy8gYWJzdHJhY3QgbWV0aG9kLiAgdG8gYmUgb3ZlcnJpZGRlbiBpbiBzcGVjaWZpYyBpbXBsZW1lbnRhdGlvbiBjbGFzc2VzLlxuLy8gY2FsbCBjYihlciwgZGF0YSkgd2hlcmUgZGF0YSBpcyA8PSBuIGluIGxlbmd0aC5cbi8vIGZvciB2aXJ0dWFsIChub24tc3RyaW5nLCBub24tYnVmZmVyKSBzdHJlYW1zLCBcImxlbmd0aFwiIGlzIHNvbWV3aGF0XG4vLyBhcmJpdHJhcnksIGFuZCBwZXJoYXBzIG5vdCB2ZXJ5IG1lYW5pbmdmdWwuXG5SZWFkYWJsZS5wcm90b3R5cGUuX3JlYWQgPSBmdW5jdGlvbihuKSB7XG4gIHRoaXMuZW1pdCgnZXJyb3InLCBuZXcgRXJyb3IoJ25vdCBpbXBsZW1lbnRlZCcpKTtcbn07XG5cblJlYWRhYmxlLnByb3RvdHlwZS5waXBlID0gZnVuY3Rpb24oZGVzdCwgcGlwZU9wdHMpIHtcbiAgdmFyIHNyYyA9IHRoaXM7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3JlYWRhYmxlU3RhdGU7XG5cbiAgc3dpdGNoIChzdGF0ZS5waXBlc0NvdW50KSB7XG4gICAgY2FzZSAwOlxuICAgICAgc3RhdGUucGlwZXMgPSBkZXN0O1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAxOlxuICAgICAgc3RhdGUucGlwZXMgPSBbc3RhdGUucGlwZXMsIGRlc3RdO1xuICAgICAgYnJlYWs7XG4gICAgZGVmYXVsdDpcbiAgICAgIHN0YXRlLnBpcGVzLnB1c2goZGVzdCk7XG4gICAgICBicmVhaztcbiAgfVxuICBzdGF0ZS5waXBlc0NvdW50ICs9IDE7XG4gIGRlYnVnKCdwaXBlIGNvdW50PSVkIG9wdHM9JWonLCBzdGF0ZS5waXBlc0NvdW50LCBwaXBlT3B0cyk7XG5cbiAgdmFyIGRvRW5kID0gKCFwaXBlT3B0cyB8fCBwaXBlT3B0cy5lbmQgIT09IGZhbHNlKSAmJlxuICAgICAgICAgICAgICBkZXN0ICE9PSBwcm9jZXNzLnN0ZG91dCAmJlxuICAgICAgICAgICAgICBkZXN0ICE9PSBwcm9jZXNzLnN0ZGVycjtcblxuICB2YXIgZW5kRm4gPSBkb0VuZCA/IG9uZW5kIDogY2xlYW51cDtcbiAgaWYgKHN0YXRlLmVuZEVtaXR0ZWQpXG4gICAgcHJvY2Vzcy5uZXh0VGljayhlbmRGbik7XG4gIGVsc2VcbiAgICBzcmMub25jZSgnZW5kJywgZW5kRm4pO1xuXG4gIGRlc3Qub24oJ3VucGlwZScsIG9udW5waXBlKTtcbiAgZnVuY3Rpb24gb251bnBpcGUocmVhZGFibGUpIHtcbiAgICBkZWJ1Zygnb251bnBpcGUnKTtcbiAgICBpZiAocmVhZGFibGUgPT09IHNyYykge1xuICAgICAgY2xlYW51cCgpO1xuICAgIH1cbiAgfVxuXG4gIGZ1bmN0aW9uIG9uZW5kKCkge1xuICAgIGRlYnVnKCdvbmVuZCcpO1xuICAgIGRlc3QuZW5kKCk7XG4gIH1cblxuICAvLyB3aGVuIHRoZSBkZXN0IGRyYWlucywgaXQgcmVkdWNlcyB0aGUgYXdhaXREcmFpbiBjb3VudGVyXG4gIC8vIG9uIHRoZSBzb3VyY2UuICBUaGlzIHdvdWxkIGJlIG1vcmUgZWxlZ2FudCB3aXRoIGEgLm9uY2UoKVxuICAvLyBoYW5kbGVyIGluIGZsb3coKSwgYnV0IGFkZGluZyBhbmQgcmVtb3ZpbmcgcmVwZWF0ZWRseSBpc1xuICAvLyB0b28gc2xvdy5cbiAgdmFyIG9uZHJhaW4gPSBwaXBlT25EcmFpbihzcmMpO1xuICBkZXN0Lm9uKCdkcmFpbicsIG9uZHJhaW4pO1xuXG4gIGZ1bmN0aW9uIGNsZWFudXAoKSB7XG4gICAgZGVidWcoJ2NsZWFudXAnKTtcbiAgICAvLyBjbGVhbnVwIGV2ZW50IGhhbmRsZXJzIG9uY2UgdGhlIHBpcGUgaXMgYnJva2VuXG4gICAgZGVzdC5yZW1vdmVMaXN0ZW5lcignY2xvc2UnLCBvbmNsb3NlKTtcbiAgICBkZXN0LnJlbW92ZUxpc3RlbmVyKCdmaW5pc2gnLCBvbmZpbmlzaCk7XG4gICAgZGVzdC5yZW1vdmVMaXN0ZW5lcignZHJhaW4nLCBvbmRyYWluKTtcbiAgICBkZXN0LnJlbW92ZUxpc3RlbmVyKCdlcnJvcicsIG9uZXJyb3IpO1xuICAgIGRlc3QucmVtb3ZlTGlzdGVuZXIoJ3VucGlwZScsIG9udW5waXBlKTtcbiAgICBzcmMucmVtb3ZlTGlzdGVuZXIoJ2VuZCcsIG9uZW5kKTtcbiAgICBzcmMucmVtb3ZlTGlzdGVuZXIoJ2VuZCcsIGNsZWFudXApO1xuICAgIHNyYy5yZW1vdmVMaXN0ZW5lcignZGF0YScsIG9uZGF0YSk7XG5cbiAgICAvLyBpZiB0aGUgcmVhZGVyIGlzIHdhaXRpbmcgZm9yIGEgZHJhaW4gZXZlbnQgZnJvbSB0aGlzXG4gICAgLy8gc3BlY2lmaWMgd3JpdGVyLCB0aGVuIGl0IHdvdWxkIGNhdXNlIGl0IHRvIG5ldmVyIHN0YXJ0XG4gICAgLy8gZmxvd2luZyBhZ2Fpbi5cbiAgICAvLyBTbywgaWYgdGhpcyBpcyBhd2FpdGluZyBhIGRyYWluLCB0aGVuIHdlIGp1c3QgY2FsbCBpdCBub3cuXG4gICAgLy8gSWYgd2UgZG9uJ3Qga25vdywgdGhlbiBhc3N1bWUgdGhhdCB3ZSBhcmUgd2FpdGluZyBmb3Igb25lLlxuICAgIGlmIChzdGF0ZS5hd2FpdERyYWluICYmXG4gICAgICAgICghZGVzdC5fd3JpdGFibGVTdGF0ZSB8fCBkZXN0Ll93cml0YWJsZVN0YXRlLm5lZWREcmFpbikpXG4gICAgICBvbmRyYWluKCk7XG4gIH1cblxuICBzcmMub24oJ2RhdGEnLCBvbmRhdGEpO1xuICBmdW5jdGlvbiBvbmRhdGEoY2h1bmspIHtcbiAgICBkZWJ1Zygnb25kYXRhJyk7XG4gICAgdmFyIHJldCA9IGRlc3Qud3JpdGUoY2h1bmspO1xuICAgIGlmIChmYWxzZSA9PT0gcmV0KSB7XG4gICAgICBkZWJ1ZygnZmFsc2Ugd3JpdGUgcmVzcG9uc2UsIHBhdXNlJyxcbiAgICAgICAgICAgIHNyYy5fcmVhZGFibGVTdGF0ZS5hd2FpdERyYWluKTtcbiAgICAgIHNyYy5fcmVhZGFibGVTdGF0ZS5hd2FpdERyYWluKys7XG4gICAgICBzcmMucGF1c2UoKTtcbiAgICB9XG4gIH1cblxuICAvLyBpZiB0aGUgZGVzdCBoYXMgYW4gZXJyb3IsIHRoZW4gc3RvcCBwaXBpbmcgaW50byBpdC5cbiAgLy8gaG93ZXZlciwgZG9uJ3Qgc3VwcHJlc3MgdGhlIHRocm93aW5nIGJlaGF2aW9yIGZvciB0aGlzLlxuICBmdW5jdGlvbiBvbmVycm9yKGVyKSB7XG4gICAgZGVidWcoJ29uZXJyb3InLCBlcik7XG4gICAgdW5waXBlKCk7XG4gICAgZGVzdC5yZW1vdmVMaXN0ZW5lcignZXJyb3InLCBvbmVycm9yKTtcbiAgICBpZiAoRUUubGlzdGVuZXJDb3VudChkZXN0LCAnZXJyb3InKSA9PT0gMClcbiAgICAgIGRlc3QuZW1pdCgnZXJyb3InLCBlcik7XG4gIH1cbiAgLy8gVGhpcyBpcyBhIGJydXRhbGx5IHVnbHkgaGFjayB0byBtYWtlIHN1cmUgdGhhdCBvdXIgZXJyb3IgaGFuZGxlclxuICAvLyBpcyBhdHRhY2hlZCBiZWZvcmUgYW55IHVzZXJsYW5kIG9uZXMuICBORVZFUiBETyBUSElTLlxuICBpZiAoIWRlc3QuX2V2ZW50cyB8fCAhZGVzdC5fZXZlbnRzLmVycm9yKVxuICAgIGRlc3Qub24oJ2Vycm9yJywgb25lcnJvcik7XG4gIGVsc2UgaWYgKGlzQXJyYXkoZGVzdC5fZXZlbnRzLmVycm9yKSlcbiAgICBkZXN0Ll9ldmVudHMuZXJyb3IudW5zaGlmdChvbmVycm9yKTtcbiAgZWxzZVxuICAgIGRlc3QuX2V2ZW50cy5lcnJvciA9IFtvbmVycm9yLCBkZXN0Ll9ldmVudHMuZXJyb3JdO1xuXG5cblxuICAvLyBCb3RoIGNsb3NlIGFuZCBmaW5pc2ggc2hvdWxkIHRyaWdnZXIgdW5waXBlLCBidXQgb25seSBvbmNlLlxuICBmdW5jdGlvbiBvbmNsb3NlKCkge1xuICAgIGRlc3QucmVtb3ZlTGlzdGVuZXIoJ2ZpbmlzaCcsIG9uZmluaXNoKTtcbiAgICB1bnBpcGUoKTtcbiAgfVxuICBkZXN0Lm9uY2UoJ2Nsb3NlJywgb25jbG9zZSk7XG4gIGZ1bmN0aW9uIG9uZmluaXNoKCkge1xuICAgIGRlYnVnKCdvbmZpbmlzaCcpO1xuICAgIGRlc3QucmVtb3ZlTGlzdGVuZXIoJ2Nsb3NlJywgb25jbG9zZSk7XG4gICAgdW5waXBlKCk7XG4gIH1cbiAgZGVzdC5vbmNlKCdmaW5pc2gnLCBvbmZpbmlzaCk7XG5cbiAgZnVuY3Rpb24gdW5waXBlKCkge1xuICAgIGRlYnVnKCd1bnBpcGUnKTtcbiAgICBzcmMudW5waXBlKGRlc3QpO1xuICB9XG5cbiAgLy8gdGVsbCB0aGUgZGVzdCB0aGF0IGl0J3MgYmVpbmcgcGlwZWQgdG9cbiAgZGVzdC5lbWl0KCdwaXBlJywgc3JjKTtcblxuICAvLyBzdGFydCB0aGUgZmxvdyBpZiBpdCBoYXNuJ3QgYmVlbiBzdGFydGVkIGFscmVhZHkuXG4gIGlmICghc3RhdGUuZmxvd2luZykge1xuICAgIGRlYnVnKCdwaXBlIHJlc3VtZScpO1xuICAgIHNyYy5yZXN1bWUoKTtcbiAgfVxuXG4gIHJldHVybiBkZXN0O1xufTtcblxuZnVuY3Rpb24gcGlwZU9uRHJhaW4oc3JjKSB7XG4gIHJldHVybiBmdW5jdGlvbigpIHtcbiAgICB2YXIgc3RhdGUgPSBzcmMuX3JlYWRhYmxlU3RhdGU7XG4gICAgZGVidWcoJ3BpcGVPbkRyYWluJywgc3RhdGUuYXdhaXREcmFpbik7XG4gICAgaWYgKHN0YXRlLmF3YWl0RHJhaW4pXG4gICAgICBzdGF0ZS5hd2FpdERyYWluLS07XG4gICAgaWYgKHN0YXRlLmF3YWl0RHJhaW4gPT09IDAgJiYgRUUubGlzdGVuZXJDb3VudChzcmMsICdkYXRhJykpIHtcbiAgICAgIHN0YXRlLmZsb3dpbmcgPSB0cnVlO1xuICAgICAgZmxvdyhzcmMpO1xuICAgIH1cbiAgfTtcbn1cblxuXG5SZWFkYWJsZS5wcm90b3R5cGUudW5waXBlID0gZnVuY3Rpb24oZGVzdCkge1xuICB2YXIgc3RhdGUgPSB0aGlzLl9yZWFkYWJsZVN0YXRlO1xuXG4gIC8vIGlmIHdlJ3JlIG5vdCBwaXBpbmcgYW55d2hlcmUsIHRoZW4gZG8gbm90aGluZy5cbiAgaWYgKHN0YXRlLnBpcGVzQ291bnQgPT09IDApXG4gICAgcmV0dXJuIHRoaXM7XG5cbiAgLy8ganVzdCBvbmUgZGVzdGluYXRpb24uICBtb3N0IGNvbW1vbiBjYXNlLlxuICBpZiAoc3RhdGUucGlwZXNDb3VudCA9PT0gMSkge1xuICAgIC8vIHBhc3NlZCBpbiBvbmUsIGJ1dCBpdCdzIG5vdCB0aGUgcmlnaHQgb25lLlxuICAgIGlmIChkZXN0ICYmIGRlc3QgIT09IHN0YXRlLnBpcGVzKVxuICAgICAgcmV0dXJuIHRoaXM7XG5cbiAgICBpZiAoIWRlc3QpXG4gICAgICBkZXN0ID0gc3RhdGUucGlwZXM7XG5cbiAgICAvLyBnb3QgYSBtYXRjaC5cbiAgICBzdGF0ZS5waXBlcyA9IG51bGw7XG4gICAgc3RhdGUucGlwZXNDb3VudCA9IDA7XG4gICAgc3RhdGUuZmxvd2luZyA9IGZhbHNlO1xuICAgIGlmIChkZXN0KVxuICAgICAgZGVzdC5lbWl0KCd1bnBpcGUnLCB0aGlzKTtcbiAgICByZXR1cm4gdGhpcztcbiAgfVxuXG4gIC8vIHNsb3cgY2FzZS4gbXVsdGlwbGUgcGlwZSBkZXN0aW5hdGlvbnMuXG5cbiAgaWYgKCFkZXN0KSB7XG4gICAgLy8gcmVtb3ZlIGFsbC5cbiAgICB2YXIgZGVzdHMgPSBzdGF0ZS5waXBlcztcbiAgICB2YXIgbGVuID0gc3RhdGUucGlwZXNDb3VudDtcbiAgICBzdGF0ZS5waXBlcyA9IG51bGw7XG4gICAgc3RhdGUucGlwZXNDb3VudCA9IDA7XG4gICAgc3RhdGUuZmxvd2luZyA9IGZhbHNlO1xuXG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCBsZW47IGkrKylcbiAgICAgIGRlc3RzW2ldLmVtaXQoJ3VucGlwZScsIHRoaXMpO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG5cbiAgLy8gdHJ5IHRvIGZpbmQgdGhlIHJpZ2h0IG9uZS5cbiAgdmFyIGkgPSBpbmRleE9mKHN0YXRlLnBpcGVzLCBkZXN0KTtcbiAgaWYgKGkgPT09IC0xKVxuICAgIHJldHVybiB0aGlzO1xuXG4gIHN0YXRlLnBpcGVzLnNwbGljZShpLCAxKTtcbiAgc3RhdGUucGlwZXNDb3VudCAtPSAxO1xuICBpZiAoc3RhdGUucGlwZXNDb3VudCA9PT0gMSlcbiAgICBzdGF0ZS5waXBlcyA9IHN0YXRlLnBpcGVzWzBdO1xuXG4gIGRlc3QuZW1pdCgndW5waXBlJywgdGhpcyk7XG5cbiAgcmV0dXJuIHRoaXM7XG59O1xuXG4vLyBzZXQgdXAgZGF0YSBldmVudHMgaWYgdGhleSBhcmUgYXNrZWQgZm9yXG4vLyBFbnN1cmUgcmVhZGFibGUgbGlzdGVuZXJzIGV2ZW50dWFsbHkgZ2V0IHNvbWV0aGluZ1xuUmVhZGFibGUucHJvdG90eXBlLm9uID0gZnVuY3Rpb24oZXYsIGZuKSB7XG4gIHZhciByZXMgPSBTdHJlYW0ucHJvdG90eXBlLm9uLmNhbGwodGhpcywgZXYsIGZuKTtcblxuICAvLyBJZiBsaXN0ZW5pbmcgdG8gZGF0YSwgYW5kIGl0IGhhcyBub3QgZXhwbGljaXRseSBiZWVuIHBhdXNlZCxcbiAgLy8gdGhlbiBjYWxsIHJlc3VtZSB0byBzdGFydCB0aGUgZmxvdyBvZiBkYXRhIG9uIHRoZSBuZXh0IHRpY2suXG4gIGlmIChldiA9PT0gJ2RhdGEnICYmIGZhbHNlICE9PSB0aGlzLl9yZWFkYWJsZVN0YXRlLmZsb3dpbmcpIHtcbiAgICB0aGlzLnJlc3VtZSgpO1xuICB9XG5cbiAgaWYgKGV2ID09PSAncmVhZGFibGUnICYmIHRoaXMucmVhZGFibGUpIHtcbiAgICB2YXIgc3RhdGUgPSB0aGlzLl9yZWFkYWJsZVN0YXRlO1xuICAgIGlmICghc3RhdGUucmVhZGFibGVMaXN0ZW5pbmcpIHtcbiAgICAgIHN0YXRlLnJlYWRhYmxlTGlzdGVuaW5nID0gdHJ1ZTtcbiAgICAgIHN0YXRlLmVtaXR0ZWRSZWFkYWJsZSA9IGZhbHNlO1xuICAgICAgc3RhdGUubmVlZFJlYWRhYmxlID0gdHJ1ZTtcbiAgICAgIGlmICghc3RhdGUucmVhZGluZykge1xuICAgICAgICB2YXIgc2VsZiA9IHRoaXM7XG4gICAgICAgIHByb2Nlc3MubmV4dFRpY2soZnVuY3Rpb24oKSB7XG4gICAgICAgICAgZGVidWcoJ3JlYWRhYmxlIG5leHR0aWNrIHJlYWQgMCcpO1xuICAgICAgICAgIHNlbGYucmVhZCgwKTtcbiAgICAgICAgfSk7XG4gICAgICB9IGVsc2UgaWYgKHN0YXRlLmxlbmd0aCkge1xuICAgICAgICBlbWl0UmVhZGFibGUodGhpcywgc3RhdGUpO1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIHJldHVybiByZXM7XG59O1xuUmVhZGFibGUucHJvdG90eXBlLmFkZExpc3RlbmVyID0gUmVhZGFibGUucHJvdG90eXBlLm9uO1xuXG4vLyBwYXVzZSgpIGFuZCByZXN1bWUoKSBhcmUgcmVtbmFudHMgb2YgdGhlIGxlZ2FjeSByZWFkYWJsZSBzdHJlYW0gQVBJXG4vLyBJZiB0aGUgdXNlciB1c2VzIHRoZW0sIHRoZW4gc3dpdGNoIGludG8gb2xkIG1vZGUuXG5SZWFkYWJsZS5wcm90b3R5cGUucmVzdW1lID0gZnVuY3Rpb24oKSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3JlYWRhYmxlU3RhdGU7XG4gIGlmICghc3RhdGUuZmxvd2luZykge1xuICAgIGRlYnVnKCdyZXN1bWUnKTtcbiAgICBzdGF0ZS5mbG93aW5nID0gdHJ1ZTtcbiAgICBpZiAoIXN0YXRlLnJlYWRpbmcpIHtcbiAgICAgIGRlYnVnKCdyZXN1bWUgcmVhZCAwJyk7XG4gICAgICB0aGlzLnJlYWQoMCk7XG4gICAgfVxuICAgIHJlc3VtZSh0aGlzLCBzdGF0ZSk7XG4gIH1cbiAgcmV0dXJuIHRoaXM7XG59O1xuXG5mdW5jdGlvbiByZXN1bWUoc3RyZWFtLCBzdGF0ZSkge1xuICBpZiAoIXN0YXRlLnJlc3VtZVNjaGVkdWxlZCkge1xuICAgIHN0YXRlLnJlc3VtZVNjaGVkdWxlZCA9IHRydWU7XG4gICAgcHJvY2Vzcy5uZXh0VGljayhmdW5jdGlvbigpIHtcbiAgICAgIHJlc3VtZV8oc3RyZWFtLCBzdGF0ZSk7XG4gICAgfSk7XG4gIH1cbn1cblxuZnVuY3Rpb24gcmVzdW1lXyhzdHJlYW0sIHN0YXRlKSB7XG4gIHN0YXRlLnJlc3VtZVNjaGVkdWxlZCA9IGZhbHNlO1xuICBzdHJlYW0uZW1pdCgncmVzdW1lJyk7XG4gIGZsb3coc3RyZWFtKTtcbiAgaWYgKHN0YXRlLmZsb3dpbmcgJiYgIXN0YXRlLnJlYWRpbmcpXG4gICAgc3RyZWFtLnJlYWQoMCk7XG59XG5cblJlYWRhYmxlLnByb3RvdHlwZS5wYXVzZSA9IGZ1bmN0aW9uKCkge1xuICBkZWJ1ZygnY2FsbCBwYXVzZSBmbG93aW5nPSVqJywgdGhpcy5fcmVhZGFibGVTdGF0ZS5mbG93aW5nKTtcbiAgaWYgKGZhbHNlICE9PSB0aGlzLl9yZWFkYWJsZVN0YXRlLmZsb3dpbmcpIHtcbiAgICBkZWJ1ZygncGF1c2UnKTtcbiAgICB0aGlzLl9yZWFkYWJsZVN0YXRlLmZsb3dpbmcgPSBmYWxzZTtcbiAgICB0aGlzLmVtaXQoJ3BhdXNlJyk7XG4gIH1cbiAgcmV0dXJuIHRoaXM7XG59O1xuXG5mdW5jdGlvbiBmbG93KHN0cmVhbSkge1xuICB2YXIgc3RhdGUgPSBzdHJlYW0uX3JlYWRhYmxlU3RhdGU7XG4gIGRlYnVnKCdmbG93Jywgc3RhdGUuZmxvd2luZyk7XG4gIGlmIChzdGF0ZS5mbG93aW5nKSB7XG4gICAgZG8ge1xuICAgICAgdmFyIGNodW5rID0gc3RyZWFtLnJlYWQoKTtcbiAgICB9IHdoaWxlIChudWxsICE9PSBjaHVuayAmJiBzdGF0ZS5mbG93aW5nKTtcbiAgfVxufVxuXG4vLyB3cmFwIGFuIG9sZC1zdHlsZSBzdHJlYW0gYXMgdGhlIGFzeW5jIGRhdGEgc291cmNlLlxuLy8gVGhpcyBpcyAqbm90KiBwYXJ0IG9mIHRoZSByZWFkYWJsZSBzdHJlYW0gaW50ZXJmYWNlLlxuLy8gSXQgaXMgYW4gdWdseSB1bmZvcnR1bmF0ZSBtZXNzIG9mIGhpc3RvcnkuXG5SZWFkYWJsZS5wcm90b3R5cGUud3JhcCA9IGZ1bmN0aW9uKHN0cmVhbSkge1xuICB2YXIgc3RhdGUgPSB0aGlzLl9yZWFkYWJsZVN0YXRlO1xuICB2YXIgcGF1c2VkID0gZmFsc2U7XG5cbiAgdmFyIHNlbGYgPSB0aGlzO1xuICBzdHJlYW0ub24oJ2VuZCcsIGZ1bmN0aW9uKCkge1xuICAgIGRlYnVnKCd3cmFwcGVkIGVuZCcpO1xuICAgIGlmIChzdGF0ZS5kZWNvZGVyICYmICFzdGF0ZS5lbmRlZCkge1xuICAgICAgdmFyIGNodW5rID0gc3RhdGUuZGVjb2Rlci5lbmQoKTtcbiAgICAgIGlmIChjaHVuayAmJiBjaHVuay5sZW5ndGgpXG4gICAgICAgIHNlbGYucHVzaChjaHVuayk7XG4gICAgfVxuXG4gICAgc2VsZi5wdXNoKG51bGwpO1xuICB9KTtcblxuICBzdHJlYW0ub24oJ2RhdGEnLCBmdW5jdGlvbihjaHVuaykge1xuICAgIGRlYnVnKCd3cmFwcGVkIGRhdGEnKTtcbiAgICBpZiAoc3RhdGUuZGVjb2RlcilcbiAgICAgIGNodW5rID0gc3RhdGUuZGVjb2Rlci53cml0ZShjaHVuayk7XG4gICAgaWYgKCFjaHVuayB8fCAhc3RhdGUub2JqZWN0TW9kZSAmJiAhY2h1bmsubGVuZ3RoKVxuICAgICAgcmV0dXJuO1xuXG4gICAgdmFyIHJldCA9IHNlbGYucHVzaChjaHVuayk7XG4gICAgaWYgKCFyZXQpIHtcbiAgICAgIHBhdXNlZCA9IHRydWU7XG4gICAgICBzdHJlYW0ucGF1c2UoKTtcbiAgICB9XG4gIH0pO1xuXG4gIC8vIHByb3h5IGFsbCB0aGUgb3RoZXIgbWV0aG9kcy5cbiAgLy8gaW1wb3J0YW50IHdoZW4gd3JhcHBpbmcgZmlsdGVycyBhbmQgZHVwbGV4ZXMuXG4gIGZvciAodmFyIGkgaW4gc3RyZWFtKSB7XG4gICAgaWYgKHV0aWwuaXNGdW5jdGlvbihzdHJlYW1baV0pICYmIHV0aWwuaXNVbmRlZmluZWQodGhpc1tpXSkpIHtcbiAgICAgIHRoaXNbaV0gPSBmdW5jdGlvbihtZXRob2QpIHsgcmV0dXJuIGZ1bmN0aW9uKCkge1xuICAgICAgICByZXR1cm4gc3RyZWFtW21ldGhvZF0uYXBwbHkoc3RyZWFtLCBhcmd1bWVudHMpO1xuICAgICAgfX0oaSk7XG4gICAgfVxuICB9XG5cbiAgLy8gcHJveHkgY2VydGFpbiBpbXBvcnRhbnQgZXZlbnRzLlxuICB2YXIgZXZlbnRzID0gWydlcnJvcicsICdjbG9zZScsICdkZXN0cm95JywgJ3BhdXNlJywgJ3Jlc3VtZSddO1xuICBmb3JFYWNoKGV2ZW50cywgZnVuY3Rpb24oZXYpIHtcbiAgICBzdHJlYW0ub24oZXYsIHNlbGYuZW1pdC5iaW5kKHNlbGYsIGV2KSk7XG4gIH0pO1xuXG4gIC8vIHdoZW4gd2UgdHJ5IHRvIGNvbnN1bWUgc29tZSBtb3JlIGJ5dGVzLCBzaW1wbHkgdW5wYXVzZSB0aGVcbiAgLy8gdW5kZXJseWluZyBzdHJlYW0uXG4gIHNlbGYuX3JlYWQgPSBmdW5jdGlvbihuKSB7XG4gICAgZGVidWcoJ3dyYXBwZWQgX3JlYWQnLCBuKTtcbiAgICBpZiAocGF1c2VkKSB7XG4gICAgICBwYXVzZWQgPSBmYWxzZTtcbiAgICAgIHN0cmVhbS5yZXN1bWUoKTtcbiAgICB9XG4gIH07XG5cbiAgcmV0dXJuIHNlbGY7XG59O1xuXG5cblxuLy8gZXhwb3NlZCBmb3IgdGVzdGluZyBwdXJwb3NlcyBvbmx5LlxuUmVhZGFibGUuX2Zyb21MaXN0ID0gZnJvbUxpc3Q7XG5cbi8vIFBsdWNrIG9mZiBuIGJ5dGVzIGZyb20gYW4gYXJyYXkgb2YgYnVmZmVycy5cbi8vIExlbmd0aCBpcyB0aGUgY29tYmluZWQgbGVuZ3RocyBvZiBhbGwgdGhlIGJ1ZmZlcnMgaW4gdGhlIGxpc3QuXG5mdW5jdGlvbiBmcm9tTGlzdChuLCBzdGF0ZSkge1xuICB2YXIgbGlzdCA9IHN0YXRlLmJ1ZmZlcjtcbiAgdmFyIGxlbmd0aCA9IHN0YXRlLmxlbmd0aDtcbiAgdmFyIHN0cmluZ01vZGUgPSAhIXN0YXRlLmRlY29kZXI7XG4gIHZhciBvYmplY3RNb2RlID0gISFzdGF0ZS5vYmplY3RNb2RlO1xuICB2YXIgcmV0O1xuXG4gIC8vIG5vdGhpbmcgaW4gdGhlIGxpc3QsIGRlZmluaXRlbHkgZW1wdHkuXG4gIGlmIChsaXN0Lmxlbmd0aCA9PT0gMClcbiAgICByZXR1cm4gbnVsbDtcblxuICBpZiAobGVuZ3RoID09PSAwKVxuICAgIHJldCA9IG51bGw7XG4gIGVsc2UgaWYgKG9iamVjdE1vZGUpXG4gICAgcmV0ID0gbGlzdC5zaGlmdCgpO1xuICBlbHNlIGlmICghbiB8fCBuID49IGxlbmd0aCkge1xuICAgIC8vIHJlYWQgaXQgYWxsLCB0cnVuY2F0ZSB0aGUgYXJyYXkuXG4gICAgaWYgKHN0cmluZ01vZGUpXG4gICAgICByZXQgPSBsaXN0LmpvaW4oJycpO1xuICAgIGVsc2VcbiAgICAgIHJldCA9IEJ1ZmZlci5jb25jYXQobGlzdCwgbGVuZ3RoKTtcbiAgICBsaXN0Lmxlbmd0aCA9IDA7XG4gIH0gZWxzZSB7XG4gICAgLy8gcmVhZCBqdXN0IHNvbWUgb2YgaXQuXG4gICAgaWYgKG4gPCBsaXN0WzBdLmxlbmd0aCkge1xuICAgICAgLy8ganVzdCB0YWtlIGEgcGFydCBvZiB0aGUgZmlyc3QgbGlzdCBpdGVtLlxuICAgICAgLy8gc2xpY2UgaXMgdGhlIHNhbWUgZm9yIGJ1ZmZlcnMgYW5kIHN0cmluZ3MuXG4gICAgICB2YXIgYnVmID0gbGlzdFswXTtcbiAgICAgIHJldCA9IGJ1Zi5zbGljZSgwLCBuKTtcbiAgICAgIGxpc3RbMF0gPSBidWYuc2xpY2Uobik7XG4gICAgfSBlbHNlIGlmIChuID09PSBsaXN0WzBdLmxlbmd0aCkge1xuICAgICAgLy8gZmlyc3QgbGlzdCBpcyBhIHBlcmZlY3QgbWF0Y2hcbiAgICAgIHJldCA9IGxpc3Quc2hpZnQoKTtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gY29tcGxleCBjYXNlLlxuICAgICAgLy8gd2UgaGF2ZSBlbm91Z2ggdG8gY292ZXIgaXQsIGJ1dCBpdCBzcGFucyBwYXN0IHRoZSBmaXJzdCBidWZmZXIuXG4gICAgICBpZiAoc3RyaW5nTW9kZSlcbiAgICAgICAgcmV0ID0gJyc7XG4gICAgICBlbHNlXG4gICAgICAgIHJldCA9IG5ldyBCdWZmZXIobik7XG5cbiAgICAgIHZhciBjID0gMDtcbiAgICAgIGZvciAodmFyIGkgPSAwLCBsID0gbGlzdC5sZW5ndGg7IGkgPCBsICYmIGMgPCBuOyBpKyspIHtcbiAgICAgICAgdmFyIGJ1ZiA9IGxpc3RbMF07XG4gICAgICAgIHZhciBjcHkgPSBNYXRoLm1pbihuIC0gYywgYnVmLmxlbmd0aCk7XG5cbiAgICAgICAgaWYgKHN0cmluZ01vZGUpXG4gICAgICAgICAgcmV0ICs9IGJ1Zi5zbGljZSgwLCBjcHkpO1xuICAgICAgICBlbHNlXG4gICAgICAgICAgYnVmLmNvcHkocmV0LCBjLCAwLCBjcHkpO1xuXG4gICAgICAgIGlmIChjcHkgPCBidWYubGVuZ3RoKVxuICAgICAgICAgIGxpc3RbMF0gPSBidWYuc2xpY2UoY3B5KTtcbiAgICAgICAgZWxzZVxuICAgICAgICAgIGxpc3Quc2hpZnQoKTtcblxuICAgICAgICBjICs9IGNweTtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICByZXR1cm4gcmV0O1xufVxuXG5mdW5jdGlvbiBlbmRSZWFkYWJsZShzdHJlYW0pIHtcbiAgdmFyIHN0YXRlID0gc3RyZWFtLl9yZWFkYWJsZVN0YXRlO1xuXG4gIC8vIElmIHdlIGdldCBoZXJlIGJlZm9yZSBjb25zdW1pbmcgYWxsIHRoZSBieXRlcywgdGhlbiB0aGF0IGlzIGFcbiAgLy8gYnVnIGluIG5vZGUuICBTaG91bGQgbmV2ZXIgaGFwcGVuLlxuICBpZiAoc3RhdGUubGVuZ3RoID4gMClcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ2VuZFJlYWRhYmxlIGNhbGxlZCBvbiBub24tZW1wdHkgc3RyZWFtJyk7XG5cbiAgaWYgKCFzdGF0ZS5lbmRFbWl0dGVkKSB7XG4gICAgc3RhdGUuZW5kZWQgPSB0cnVlO1xuICAgIHByb2Nlc3MubmV4dFRpY2soZnVuY3Rpb24oKSB7XG4gICAgICAvLyBDaGVjayB0aGF0IHdlIGRpZG4ndCBnZXQgb25lIGxhc3QgdW5zaGlmdC5cbiAgICAgIGlmICghc3RhdGUuZW5kRW1pdHRlZCAmJiBzdGF0ZS5sZW5ndGggPT09IDApIHtcbiAgICAgICAgc3RhdGUuZW5kRW1pdHRlZCA9IHRydWU7XG4gICAgICAgIHN0cmVhbS5yZWFkYWJsZSA9IGZhbHNlO1xuICAgICAgICBzdHJlYW0uZW1pdCgnZW5kJyk7XG4gICAgICB9XG4gICAgfSk7XG4gIH1cbn1cblxuZnVuY3Rpb24gZm9yRWFjaCAoeHMsIGYpIHtcbiAgZm9yICh2YXIgaSA9IDAsIGwgPSB4cy5sZW5ndGg7IGkgPCBsOyBpKyspIHtcbiAgICBmKHhzW2ldLCBpKTtcbiAgfVxufVxuXG5mdW5jdGlvbiBpbmRleE9mICh4cywgeCkge1xuICBmb3IgKHZhciBpID0gMCwgbCA9IHhzLmxlbmd0aDsgaSA8IGw7IGkrKykge1xuICAgIGlmICh4c1tpXSA9PT0geCkgcmV0dXJuIGk7XG4gIH1cbiAgcmV0dXJuIC0xO1xufVxuIl19
},{"./_stream_duplex":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_duplex.js","_process":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/process/browser.js","buffer":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/index.js","core-util-is":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/node_modules/core-util-is/lib/util.js","events":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/events/events.js","inherits":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js","isarray":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/isarray/index.js","stream":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/stream-browserify/index.js","string_decoder/":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/string_decoder/index.js","util":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/browser-resolve/empty.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_transform.js":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.


// a transform stream is a readable/writable stream where you do
// something with the data.  Sometimes it's called a "filter",
// but that's not a great name for it, since that implies a thing where
// some bits pass through, and others are simply ignored.  (That would
// be a valid example of a transform, of course.)
//
// While the output is causally related to the input, it's not a
// necessarily symmetric or synchronous transformation.  For example,
// a zlib stream might take multiple plain-text writes(), and then
// emit a single compressed chunk some time in the future.
//
// Here's how this works:
//
// The Transform stream has all the aspects of the readable and writable
// stream classes.  When you write(chunk), that calls _write(chunk,cb)
// internally, and returns false if there's a lot of pending writes
// buffered up.  When you call read(), that calls _read(n) until
// there's enough pending readable data buffered up.
//
// In a transform stream, the written data is placed in a buffer.  When
// _read(n) is called, it transforms the queued up data, calling the
// buffered _write cb's as it consumes chunks.  If consuming a single
// written chunk would result in multiple output chunks, then the first
// outputted bit calls the readcb, and subsequent chunks just go into
// the read buffer, and will cause it to emit 'readable' if necessary.
//
// This way, back-pressure is actually determined by the reading side,
// since _read has to be called to start processing a new chunk.  However,
// a pathological inflate type of transform can cause excessive buffering
// here.  For example, imagine a stream where every byte of input is
// interpreted as an integer from 0-255, and then results in that many
// bytes of output.  Writing the 4 bytes {ff,ff,ff,ff} would result in
// 1kb of data being output.  In this case, you could write a very small
// amount of input, and end up with a very large amount of output.  In
// such a pathological inflating mechanism, there'd be no way to tell
// the system to stop doing the transform.  A single 4MB write could
// cause the system to run out of memory.
//
// However, even in such a pathological case, only a single written chunk
// would be consumed, and then the rest would wait (un-transformed) until
// the results of the previous transformed chunk were consumed.

module.exports = Transform;

var Duplex = require('./_stream_duplex');

/*<replacement>*/
var util = require('core-util-is');
util.inherits = require('inherits');
/*</replacement>*/

util.inherits(Transform, Duplex);


function TransformState(options, stream) {
  this.afterTransform = function(er, data) {
    return afterTransform(stream, er, data);
  };

  this.needTransform = false;
  this.transforming = false;
  this.writecb = null;
  this.writechunk = null;
}

function afterTransform(stream, er, data) {
  var ts = stream._transformState;
  ts.transforming = false;

  var cb = ts.writecb;

  if (!cb)
    return stream.emit('error', new Error('no writecb in Transform class'));

  ts.writechunk = null;
  ts.writecb = null;

  if (!util.isNullOrUndefined(data))
    stream.push(data);

  if (cb)
    cb(er);

  var rs = stream._readableState;
  rs.reading = false;
  if (rs.needReadable || rs.length < rs.highWaterMark) {
    stream._read(rs.highWaterMark);
  }
}


function Transform(options) {
  if (!(this instanceof Transform))
    return new Transform(options);

  Duplex.call(this, options);

  this._transformState = new TransformState(options, this);

  // when the writable side finishes, then flush out anything remaining.
  var stream = this;

  // start out asking for a readable event once data is transformed.
  this._readableState.needReadable = true;

  // we have implemented the _read method, and done the other things
  // that Readable wants before the first _read call, so unset the
  // sync guard flag.
  this._readableState.sync = false;

  this.once('prefinish', function() {
    if (util.isFunction(this._flush))
      this._flush(function(er) {
        done(stream, er);
      });
    else
      done(stream);
  });
}

Transform.prototype.push = function(chunk, encoding) {
  this._transformState.needTransform = false;
  return Duplex.prototype.push.call(this, chunk, encoding);
};

// This is the part where you do stuff!
// override this function in implementation classes.
// 'chunk' is an input chunk.
//
// Call `push(newChunk)` to pass along transformed output
// to the readable side.  You may call 'push' zero or more times.
//
// Call `cb(err)` when you are done with this chunk.  If you pass
// an error, then that'll put the hurt on the whole operation.  If you
// never call cb(), then you'll never get another chunk.
Transform.prototype._transform = function(chunk, encoding, cb) {
  throw new Error('not implemented');
};

Transform.prototype._write = function(chunk, encoding, cb) {
  var ts = this._transformState;
  ts.writecb = cb;
  ts.writechunk = chunk;
  ts.writeencoding = encoding;
  if (!ts.transforming) {
    var rs = this._readableState;
    if (ts.needTransform ||
        rs.needReadable ||
        rs.length < rs.highWaterMark)
      this._read(rs.highWaterMark);
  }
};

// Doesn't matter what the args are here.
// _transform does all the work.
// That we got here means that the readable side wants more data.
Transform.prototype._read = function(n) {
  var ts = this._transformState;

  if (!util.isNull(ts.writechunk) && ts.writecb && !ts.transforming) {
    ts.transforming = true;
    this._transform(ts.writechunk, ts.writeencoding, ts.afterTransform);
  } else {
    // mark that we need a transform, so that any data that comes in
    // will get processed, now that we've asked for it.
    ts.needTransform = true;
  }
};


function done(stream, er) {
  if (er)
    return stream.emit('error', er);

  // if there's nothing in the write buffer, then that means
  // that nothing more will ever be provided
  var ws = stream._writableState;
  var ts = stream._transformState;

  if (ws.length)
    throw new Error('calling transform done when ws.length != 0');

  if (ts.transforming)
    throw new Error('calling transform done when still transforming');

  return stream.push(null);
}

},{"./_stream_duplex":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_duplex.js","core-util-is":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/node_modules/core-util-is/lib/util.js","inherits":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_writable.js":[function(require,module,exports){
(function (process){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

// A bit simpler than readable streams.
// Implement an async ._write(chunk, cb), and it'll handle all
// the drain event emission and buffering.

module.exports = Writable;

/*<replacement>*/
var Buffer = require('buffer').Buffer;
/*</replacement>*/

Writable.WritableState = WritableState;


/*<replacement>*/
var util = require('core-util-is');
util.inherits = require('inherits');
/*</replacement>*/

var Stream = require('stream');

util.inherits(Writable, Stream);

function WriteReq(chunk, encoding, cb) {
  this.chunk = chunk;
  this.encoding = encoding;
  this.callback = cb;
}

function WritableState(options, stream) {
  var Duplex = require('./_stream_duplex');

  options = options || {};

  // the point at which write() starts returning false
  // Note: 0 is a valid value, means that we always return false if
  // the entire buffer is not flushed immediately on write()
  var hwm = options.highWaterMark;
  var defaultHwm = options.objectMode ? 16 : 16 * 1024;
  this.highWaterMark = (hwm || hwm === 0) ? hwm : defaultHwm;

  // object stream flag to indicate whether or not this stream
  // contains buffers or objects.
  this.objectMode = !!options.objectMode;

  if (stream instanceof Duplex)
    this.objectMode = this.objectMode || !!options.writableObjectMode;

  // cast to ints.
  this.highWaterMark = ~~this.highWaterMark;

  this.needDrain = false;
  // at the start of calling end()
  this.ending = false;
  // when end() has been called, and returned
  this.ended = false;
  // when 'finish' is emitted
  this.finished = false;

  // should we decode strings into buffers before passing to _write?
  // this is here so that some node-core streams can optimize string
  // handling at a lower level.
  var noDecode = options.decodeStrings === false;
  this.decodeStrings = !noDecode;

  // Crypto is kind of old and crusty.  Historically, its default string
  // encoding is 'binary' so we have to make this configurable.
  // Everything else in the universe uses 'utf8', though.
  this.defaultEncoding = options.defaultEncoding || 'utf8';

  // not an actual buffer we keep track of, but a measurement
  // of how much we're waiting to get pushed to some underlying
  // socket or file.
  this.length = 0;

  // a flag to see when we're in the middle of a write.
  this.writing = false;

  // when true all writes will be buffered until .uncork() call
  this.corked = 0;

  // a flag to be able to tell if the onwrite cb is called immediately,
  // or on a later tick.  We set this to true at first, because any
  // actions that shouldn't happen until "later" should generally also
  // not happen before the first write call.
  this.sync = true;

  // a flag to know if we're processing previously buffered items, which
  // may call the _write() callback in the same tick, so that we don't
  // end up in an overlapped onwrite situation.
  this.bufferProcessing = false;

  // the callback that's passed to _write(chunk,cb)
  this.onwrite = function(er) {
    onwrite(stream, er);
  };

  // the callback that the user supplies to write(chunk,encoding,cb)
  this.writecb = null;

  // the amount that is being written when _write is called.
  this.writelen = 0;

  this.buffer = [];

  // number of pending user-supplied write callbacks
  // this must be 0 before 'finish' can be emitted
  this.pendingcb = 0;

  // emit prefinish if the only thing we're waiting for is _write cbs
  // This is relevant for synchronous Transform streams
  this.prefinished = false;

  // True if the error was already emitted and should not be thrown again
  this.errorEmitted = false;
}

function Writable(options) {
  var Duplex = require('./_stream_duplex');

  // Writable ctor is applied to Duplexes, though they're not
  // instanceof Writable, they're instanceof Readable.
  if (!(this instanceof Writable) && !(this instanceof Duplex))
    return new Writable(options);

  this._writableState = new WritableState(options, this);

  // legacy.
  this.writable = true;

  Stream.call(this);
}

// Otherwise people can pipe Writable streams, which is just wrong.
Writable.prototype.pipe = function() {
  this.emit('error', new Error('Cannot pipe. Not readable.'));
};


function writeAfterEnd(stream, state, cb) {
  var er = new Error('write after end');
  // TODO: defer error events consistently everywhere, not just the cb
  stream.emit('error', er);
  process.nextTick(function() {
    cb(er);
  });
}

// If we get something that is not a buffer, string, null, or undefined,
// and we're not in objectMode, then that's an error.
// Otherwise stream chunks are all considered to be of length=1, and the
// watermarks determine how many objects to keep in the buffer, rather than
// how many bytes or characters.
function validChunk(stream, state, chunk, cb) {
  var valid = true;
  if (!util.isBuffer(chunk) &&
      !util.isString(chunk) &&
      !util.isNullOrUndefined(chunk) &&
      !state.objectMode) {
    var er = new TypeError('Invalid non-string/buffer chunk');
    stream.emit('error', er);
    process.nextTick(function() {
      cb(er);
    });
    valid = false;
  }
  return valid;
}

Writable.prototype.write = function(chunk, encoding, cb) {
  var state = this._writableState;
  var ret = false;

  if (util.isFunction(encoding)) {
    cb = encoding;
    encoding = null;
  }

  if (util.isBuffer(chunk))
    encoding = 'buffer';
  else if (!encoding)
    encoding = state.defaultEncoding;

  if (!util.isFunction(cb))
    cb = function() {};

  if (state.ended)
    writeAfterEnd(this, state, cb);
  else if (validChunk(this, state, chunk, cb)) {
    state.pendingcb++;
    ret = writeOrBuffer(this, state, chunk, encoding, cb);
  }

  return ret;
};

Writable.prototype.cork = function() {
  var state = this._writableState;

  state.corked++;
};

Writable.prototype.uncork = function() {
  var state = this._writableState;

  if (state.corked) {
    state.corked--;

    if (!state.writing &&
        !state.corked &&
        !state.finished &&
        !state.bufferProcessing &&
        state.buffer.length)
      clearBuffer(this, state);
  }
};

function decodeChunk(state, chunk, encoding) {
  if (!state.objectMode &&
      state.decodeStrings !== false &&
      util.isString(chunk)) {
    chunk = new Buffer(chunk, encoding);
  }
  return chunk;
}

// if we're already writing something, then just put this
// in the queue, and wait our turn.  Otherwise, call _write
// If we return false, then we need a drain event, so set that flag.
function writeOrBuffer(stream, state, chunk, encoding, cb) {
  chunk = decodeChunk(state, chunk, encoding);
  if (util.isBuffer(chunk))
    encoding = 'buffer';
  var len = state.objectMode ? 1 : chunk.length;

  state.length += len;

  var ret = state.length < state.highWaterMark;
  // we must ensure that previous needDrain will not be reset to false.
  if (!ret)
    state.needDrain = true;

  if (state.writing || state.corked)
    state.buffer.push(new WriteReq(chunk, encoding, cb));
  else
    doWrite(stream, state, false, len, chunk, encoding, cb);

  return ret;
}

function doWrite(stream, state, writev, len, chunk, encoding, cb) {
  state.writelen = len;
  state.writecb = cb;
  state.writing = true;
  state.sync = true;
  if (writev)
    stream._writev(chunk, state.onwrite);
  else
    stream._write(chunk, encoding, state.onwrite);
  state.sync = false;
}

function onwriteError(stream, state, sync, er, cb) {
  if (sync)
    process.nextTick(function() {
      state.pendingcb--;
      cb(er);
    });
  else {
    state.pendingcb--;
    cb(er);
  }

  stream._writableState.errorEmitted = true;
  stream.emit('error', er);
}

function onwriteStateUpdate(state) {
  state.writing = false;
  state.writecb = null;
  state.length -= state.writelen;
  state.writelen = 0;
}

function onwrite(stream, er) {
  var state = stream._writableState;
  var sync = state.sync;
  var cb = state.writecb;

  onwriteStateUpdate(state);

  if (er)
    onwriteError(stream, state, sync, er, cb);
  else {
    // Check if we're actually ready to finish, but don't emit yet
    var finished = needFinish(stream, state);

    if (!finished &&
        !state.corked &&
        !state.bufferProcessing &&
        state.buffer.length) {
      clearBuffer(stream, state);
    }

    if (sync) {
      process.nextTick(function() {
        afterWrite(stream, state, finished, cb);
      });
    } else {
      afterWrite(stream, state, finished, cb);
    }
  }
}

function afterWrite(stream, state, finished, cb) {
  if (!finished)
    onwriteDrain(stream, state);
  state.pendingcb--;
  cb();
  finishMaybe(stream, state);
}

// Must force callback to be called on nextTick, so that we don't
// emit 'drain' before the write() consumer gets the 'false' return
// value, and has a chance to attach a 'drain' listener.
function onwriteDrain(stream, state) {
  if (state.length === 0 && state.needDrain) {
    state.needDrain = false;
    stream.emit('drain');
  }
}


// if there's something in the buffer waiting, then process it
function clearBuffer(stream, state) {
  state.bufferProcessing = true;

  if (stream._writev && state.buffer.length > 1) {
    // Fast case, write everything using _writev()
    var cbs = [];
    for (var c = 0; c < state.buffer.length; c++)
      cbs.push(state.buffer[c].callback);

    // count the one we are adding, as well.
    // TODO(isaacs) clean this up
    state.pendingcb++;
    doWrite(stream, state, true, state.length, state.buffer, '', function(err) {
      for (var i = 0; i < cbs.length; i++) {
        state.pendingcb--;
        cbs[i](err);
      }
    });

    // Clear buffer
    state.buffer = [];
  } else {
    // Slow case, write chunks one-by-one
    for (var c = 0; c < state.buffer.length; c++) {
      var entry = state.buffer[c];
      var chunk = entry.chunk;
      var encoding = entry.encoding;
      var cb = entry.callback;
      var len = state.objectMode ? 1 : chunk.length;

      doWrite(stream, state, false, len, chunk, encoding, cb);

      // if we didn't call the onwrite immediately, then
      // it means that we need to wait until it does.
      // also, that means that the chunk and cb are currently
      // being processed, so move the buffer counter past them.
      if (state.writing) {
        c++;
        break;
      }
    }

    if (c < state.buffer.length)
      state.buffer = state.buffer.slice(c);
    else
      state.buffer.length = 0;
  }

  state.bufferProcessing = false;
}

Writable.prototype._write = function(chunk, encoding, cb) {
  cb(new Error('not implemented'));

};

Writable.prototype._writev = null;

Writable.prototype.end = function(chunk, encoding, cb) {
  var state = this._writableState;

  if (util.isFunction(chunk)) {
    cb = chunk;
    chunk = null;
    encoding = null;
  } else if (util.isFunction(encoding)) {
    cb = encoding;
    encoding = null;
  }

  if (!util.isNullOrUndefined(chunk))
    this.write(chunk, encoding);

  // .end() fully uncorks
  if (state.corked) {
    state.corked = 1;
    this.uncork();
  }

  // ignore unnecessary end() calls.
  if (!state.ending && !state.finished)
    endWritable(this, state, cb);
};


function needFinish(stream, state) {
  return (state.ending &&
          state.length === 0 &&
          !state.finished &&
          !state.writing);
}

function prefinish(stream, state) {
  if (!state.prefinished) {
    state.prefinished = true;
    stream.emit('prefinish');
  }
}

function finishMaybe(stream, state) {
  var need = needFinish(stream, state);
  if (need) {
    if (state.pendingcb === 0) {
      prefinish(stream, state);
      state.finished = true;
      stream.emit('finish');
    } else
      prefinish(stream, state);
  }
  return need;
}

function endWritable(stream, state, cb) {
  state.ending = true;
  finishMaybe(stream, state);
  if (cb) {
    if (state.finished)
      process.nextTick(cb);
    else
      stream.once('finish', cb);
  }
  state.ended = true;
}

}).call(this,require('_process'))
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vbGliL19zdHJlYW1fd3JpdGFibGUuanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgSm95ZW50LCBJbmMuIGFuZCBvdGhlciBOb2RlIGNvbnRyaWJ1dG9ycy5cbi8vXG4vLyBQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcgYVxuLy8gY29weSBvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZVxuLy8gXCJTb2Z0d2FyZVwiKSwgdG8gZGVhbCBpbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nXG4vLyB3aXRob3V0IGxpbWl0YXRpb24gdGhlIHJpZ2h0cyB0byB1c2UsIGNvcHksIG1vZGlmeSwgbWVyZ2UsIHB1Ymxpc2gsXG4vLyBkaXN0cmlidXRlLCBzdWJsaWNlbnNlLCBhbmQvb3Igc2VsbCBjb3BpZXMgb2YgdGhlIFNvZnR3YXJlLCBhbmQgdG8gcGVybWl0XG4vLyBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzIGZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGVcbi8vIGZvbGxvd2luZyBjb25kaXRpb25zOlxuLy9cbi8vIFRoZSBhYm92ZSBjb3B5cmlnaHQgbm90aWNlIGFuZCB0aGlzIHBlcm1pc3Npb24gbm90aWNlIHNoYWxsIGJlIGluY2x1ZGVkXG4vLyBpbiBhbGwgY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS5cbi8vXG4vLyBUSEUgU09GVFdBUkUgSVMgUFJPVklERUQgXCJBUyBJU1wiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTXG4vLyBPUiBJTVBMSUVELCBJTkNMVURJTkcgQlVUIE5PVCBMSU1JVEVEIFRPIFRIRSBXQVJSQU5USUVTIE9GXG4vLyBNRVJDSEFOVEFCSUxJVFksIEZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFORCBOT05JTkZSSU5HRU1FTlQuIElOXG4vLyBOTyBFVkVOVCBTSEFMTCBUSEUgQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSxcbi8vIERBTUFHRVMgT1IgT1RIRVIgTElBQklMSVRZLCBXSEVUSEVSIElOIEFOIEFDVElPTiBPRiBDT05UUkFDVCwgVE9SVCBPUlxuLy8gT1RIRVJXSVNFLCBBUklTSU5HIEZST00sIE9VVCBPRiBPUiBJTiBDT05ORUNUSU9OIFdJVEggVEhFIFNPRlRXQVJFIE9SIFRIRVxuLy8gVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRSBTT0ZUV0FSRS5cblxuLy8gQSBiaXQgc2ltcGxlciB0aGFuIHJlYWRhYmxlIHN0cmVhbXMuXG4vLyBJbXBsZW1lbnQgYW4gYXN5bmMgLl93cml0ZShjaHVuaywgY2IpLCBhbmQgaXQnbGwgaGFuZGxlIGFsbFxuLy8gdGhlIGRyYWluIGV2ZW50IGVtaXNzaW9uIGFuZCBidWZmZXJpbmcuXG5cbm1vZHVsZS5leHBvcnRzID0gV3JpdGFibGU7XG5cbi8qPHJlcGxhY2VtZW50PiovXG52YXIgQnVmZmVyID0gcmVxdWlyZSgnYnVmZmVyJykuQnVmZmVyO1xuLyo8L3JlcGxhY2VtZW50PiovXG5cbldyaXRhYmxlLldyaXRhYmxlU3RhdGUgPSBXcml0YWJsZVN0YXRlO1xuXG5cbi8qPHJlcGxhY2VtZW50PiovXG52YXIgdXRpbCA9IHJlcXVpcmUoJ2NvcmUtdXRpbC1pcycpO1xudXRpbC5pbmhlcml0cyA9IHJlcXVpcmUoJ2luaGVyaXRzJyk7XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxudmFyIFN0cmVhbSA9IHJlcXVpcmUoJ3N0cmVhbScpO1xuXG51dGlsLmluaGVyaXRzKFdyaXRhYmxlLCBTdHJlYW0pO1xuXG5mdW5jdGlvbiBXcml0ZVJlcShjaHVuaywgZW5jb2RpbmcsIGNiKSB7XG4gIHRoaXMuY2h1bmsgPSBjaHVuaztcbiAgdGhpcy5lbmNvZGluZyA9IGVuY29kaW5nO1xuICB0aGlzLmNhbGxiYWNrID0gY2I7XG59XG5cbmZ1bmN0aW9uIFdyaXRhYmxlU3RhdGUob3B0aW9ucywgc3RyZWFtKSB7XG4gIHZhciBEdXBsZXggPSByZXF1aXJlKCcuL19zdHJlYW1fZHVwbGV4Jyk7XG5cbiAgb3B0aW9ucyA9IG9wdGlvbnMgfHwge307XG5cbiAgLy8gdGhlIHBvaW50IGF0IHdoaWNoIHdyaXRlKCkgc3RhcnRzIHJldHVybmluZyBmYWxzZVxuICAvLyBOb3RlOiAwIGlzIGEgdmFsaWQgdmFsdWUsIG1lYW5zIHRoYXQgd2UgYWx3YXlzIHJldHVybiBmYWxzZSBpZlxuICAvLyB0aGUgZW50aXJlIGJ1ZmZlciBpcyBub3QgZmx1c2hlZCBpbW1lZGlhdGVseSBvbiB3cml0ZSgpXG4gIHZhciBod20gPSBvcHRpb25zLmhpZ2hXYXRlck1hcms7XG4gIHZhciBkZWZhdWx0SHdtID0gb3B0aW9ucy5vYmplY3RNb2RlID8gMTYgOiAxNiAqIDEwMjQ7XG4gIHRoaXMuaGlnaFdhdGVyTWFyayA9IChod20gfHwgaHdtID09PSAwKSA/IGh3bSA6IGRlZmF1bHRId207XG5cbiAgLy8gb2JqZWN0IHN0cmVhbSBmbGFnIHRvIGluZGljYXRlIHdoZXRoZXIgb3Igbm90IHRoaXMgc3RyZWFtXG4gIC8vIGNvbnRhaW5zIGJ1ZmZlcnMgb3Igb2JqZWN0cy5cbiAgdGhpcy5vYmplY3RNb2RlID0gISFvcHRpb25zLm9iamVjdE1vZGU7XG5cbiAgaWYgKHN0cmVhbSBpbnN0YW5jZW9mIER1cGxleClcbiAgICB0aGlzLm9iamVjdE1vZGUgPSB0aGlzLm9iamVjdE1vZGUgfHwgISFvcHRpb25zLndyaXRhYmxlT2JqZWN0TW9kZTtcblxuICAvLyBjYXN0IHRvIGludHMuXG4gIHRoaXMuaGlnaFdhdGVyTWFyayA9IH5+dGhpcy5oaWdoV2F0ZXJNYXJrO1xuXG4gIHRoaXMubmVlZERyYWluID0gZmFsc2U7XG4gIC8vIGF0IHRoZSBzdGFydCBvZiBjYWxsaW5nIGVuZCgpXG4gIHRoaXMuZW5kaW5nID0gZmFsc2U7XG4gIC8vIHdoZW4gZW5kKCkgaGFzIGJlZW4gY2FsbGVkLCBhbmQgcmV0dXJuZWRcbiAgdGhpcy5lbmRlZCA9IGZhbHNlO1xuICAvLyB3aGVuICdmaW5pc2gnIGlzIGVtaXR0ZWRcbiAgdGhpcy5maW5pc2hlZCA9IGZhbHNlO1xuXG4gIC8vIHNob3VsZCB3ZSBkZWNvZGUgc3RyaW5ncyBpbnRvIGJ1ZmZlcnMgYmVmb3JlIHBhc3NpbmcgdG8gX3dyaXRlP1xuICAvLyB0aGlzIGlzIGhlcmUgc28gdGhhdCBzb21lIG5vZGUtY29yZSBzdHJlYW1zIGNhbiBvcHRpbWl6ZSBzdHJpbmdcbiAgLy8gaGFuZGxpbmcgYXQgYSBsb3dlciBsZXZlbC5cbiAgdmFyIG5vRGVjb2RlID0gb3B0aW9ucy5kZWNvZGVTdHJpbmdzID09PSBmYWxzZTtcbiAgdGhpcy5kZWNvZGVTdHJpbmdzID0gIW5vRGVjb2RlO1xuXG4gIC8vIENyeXB0byBpcyBraW5kIG9mIG9sZCBhbmQgY3J1c3R5LiAgSGlzdG9yaWNhbGx5LCBpdHMgZGVmYXVsdCBzdHJpbmdcbiAgLy8gZW5jb2RpbmcgaXMgJ2JpbmFyeScgc28gd2UgaGF2ZSB0byBtYWtlIHRoaXMgY29uZmlndXJhYmxlLlxuICAvLyBFdmVyeXRoaW5nIGVsc2UgaW4gdGhlIHVuaXZlcnNlIHVzZXMgJ3V0ZjgnLCB0aG91Z2guXG4gIHRoaXMuZGVmYXVsdEVuY29kaW5nID0gb3B0aW9ucy5kZWZhdWx0RW5jb2RpbmcgfHwgJ3V0ZjgnO1xuXG4gIC8vIG5vdCBhbiBhY3R1YWwgYnVmZmVyIHdlIGtlZXAgdHJhY2sgb2YsIGJ1dCBhIG1lYXN1cmVtZW50XG4gIC8vIG9mIGhvdyBtdWNoIHdlJ3JlIHdhaXRpbmcgdG8gZ2V0IHB1c2hlZCB0byBzb21lIHVuZGVybHlpbmdcbiAgLy8gc29ja2V0IG9yIGZpbGUuXG4gIHRoaXMubGVuZ3RoID0gMDtcblxuICAvLyBhIGZsYWcgdG8gc2VlIHdoZW4gd2UncmUgaW4gdGhlIG1pZGRsZSBvZiBhIHdyaXRlLlxuICB0aGlzLndyaXRpbmcgPSBmYWxzZTtcblxuICAvLyB3aGVuIHRydWUgYWxsIHdyaXRlcyB3aWxsIGJlIGJ1ZmZlcmVkIHVudGlsIC51bmNvcmsoKSBjYWxsXG4gIHRoaXMuY29ya2VkID0gMDtcblxuICAvLyBhIGZsYWcgdG8gYmUgYWJsZSB0byB0ZWxsIGlmIHRoZSBvbndyaXRlIGNiIGlzIGNhbGxlZCBpbW1lZGlhdGVseSxcbiAgLy8gb3Igb24gYSBsYXRlciB0aWNrLiAgV2Ugc2V0IHRoaXMgdG8gdHJ1ZSBhdCBmaXJzdCwgYmVjYXVzZSBhbnlcbiAgLy8gYWN0aW9ucyB0aGF0IHNob3VsZG4ndCBoYXBwZW4gdW50aWwgXCJsYXRlclwiIHNob3VsZCBnZW5lcmFsbHkgYWxzb1xuICAvLyBub3QgaGFwcGVuIGJlZm9yZSB0aGUgZmlyc3Qgd3JpdGUgY2FsbC5cbiAgdGhpcy5zeW5jID0gdHJ1ZTtcblxuICAvLyBhIGZsYWcgdG8ga25vdyBpZiB3ZSdyZSBwcm9jZXNzaW5nIHByZXZpb3VzbHkgYnVmZmVyZWQgaXRlbXMsIHdoaWNoXG4gIC8vIG1heSBjYWxsIHRoZSBfd3JpdGUoKSBjYWxsYmFjayBpbiB0aGUgc2FtZSB0aWNrLCBzbyB0aGF0IHdlIGRvbid0XG4gIC8vIGVuZCB1cCBpbiBhbiBvdmVybGFwcGVkIG9ud3JpdGUgc2l0dWF0aW9uLlxuICB0aGlzLmJ1ZmZlclByb2Nlc3NpbmcgPSBmYWxzZTtcblxuICAvLyB0aGUgY2FsbGJhY2sgdGhhdCdzIHBhc3NlZCB0byBfd3JpdGUoY2h1bmssY2IpXG4gIHRoaXMub253cml0ZSA9IGZ1bmN0aW9uKGVyKSB7XG4gICAgb253cml0ZShzdHJlYW0sIGVyKTtcbiAgfTtcblxuICAvLyB0aGUgY2FsbGJhY2sgdGhhdCB0aGUgdXNlciBzdXBwbGllcyB0byB3cml0ZShjaHVuayxlbmNvZGluZyxjYilcbiAgdGhpcy53cml0ZWNiID0gbnVsbDtcblxuICAvLyB0aGUgYW1vdW50IHRoYXQgaXMgYmVpbmcgd3JpdHRlbiB3aGVuIF93cml0ZSBpcyBjYWxsZWQuXG4gIHRoaXMud3JpdGVsZW4gPSAwO1xuXG4gIHRoaXMuYnVmZmVyID0gW107XG5cbiAgLy8gbnVtYmVyIG9mIHBlbmRpbmcgdXNlci1zdXBwbGllZCB3cml0ZSBjYWxsYmFja3NcbiAgLy8gdGhpcyBtdXN0IGJlIDAgYmVmb3JlICdmaW5pc2gnIGNhbiBiZSBlbWl0dGVkXG4gIHRoaXMucGVuZGluZ2NiID0gMDtcblxuICAvLyBlbWl0IHByZWZpbmlzaCBpZiB0aGUgb25seSB0aGluZyB3ZSdyZSB3YWl0aW5nIGZvciBpcyBfd3JpdGUgY2JzXG4gIC8vIFRoaXMgaXMgcmVsZXZhbnQgZm9yIHN5bmNocm9ub3VzIFRyYW5zZm9ybSBzdHJlYW1zXG4gIHRoaXMucHJlZmluaXNoZWQgPSBmYWxzZTtcblxuICAvLyBUcnVlIGlmIHRoZSBlcnJvciB3YXMgYWxyZWFkeSBlbWl0dGVkIGFuZCBzaG91bGQgbm90IGJlIHRocm93biBhZ2FpblxuICB0aGlzLmVycm9yRW1pdHRlZCA9IGZhbHNlO1xufVxuXG5mdW5jdGlvbiBXcml0YWJsZShvcHRpb25zKSB7XG4gIHZhciBEdXBsZXggPSByZXF1aXJlKCcuL19zdHJlYW1fZHVwbGV4Jyk7XG5cbiAgLy8gV3JpdGFibGUgY3RvciBpcyBhcHBsaWVkIHRvIER1cGxleGVzLCB0aG91Z2ggdGhleSdyZSBub3RcbiAgLy8gaW5zdGFuY2VvZiBXcml0YWJsZSwgdGhleSdyZSBpbnN0YW5jZW9mIFJlYWRhYmxlLlxuICBpZiAoISh0aGlzIGluc3RhbmNlb2YgV3JpdGFibGUpICYmICEodGhpcyBpbnN0YW5jZW9mIER1cGxleCkpXG4gICAgcmV0dXJuIG5ldyBXcml0YWJsZShvcHRpb25zKTtcblxuICB0aGlzLl93cml0YWJsZVN0YXRlID0gbmV3IFdyaXRhYmxlU3RhdGUob3B0aW9ucywgdGhpcyk7XG5cbiAgLy8gbGVnYWN5LlxuICB0aGlzLndyaXRhYmxlID0gdHJ1ZTtcblxuICBTdHJlYW0uY2FsbCh0aGlzKTtcbn1cblxuLy8gT3RoZXJ3aXNlIHBlb3BsZSBjYW4gcGlwZSBXcml0YWJsZSBzdHJlYW1zLCB3aGljaCBpcyBqdXN0IHdyb25nLlxuV3JpdGFibGUucHJvdG90eXBlLnBpcGUgPSBmdW5jdGlvbigpIHtcbiAgdGhpcy5lbWl0KCdlcnJvcicsIG5ldyBFcnJvcignQ2Fubm90IHBpcGUuIE5vdCByZWFkYWJsZS4nKSk7XG59O1xuXG5cbmZ1bmN0aW9uIHdyaXRlQWZ0ZXJFbmQoc3RyZWFtLCBzdGF0ZSwgY2IpIHtcbiAgdmFyIGVyID0gbmV3IEVycm9yKCd3cml0ZSBhZnRlciBlbmQnKTtcbiAgLy8gVE9ETzogZGVmZXIgZXJyb3IgZXZlbnRzIGNvbnNpc3RlbnRseSBldmVyeXdoZXJlLCBub3QganVzdCB0aGUgY2JcbiAgc3RyZWFtLmVtaXQoJ2Vycm9yJywgZXIpO1xuICBwcm9jZXNzLm5leHRUaWNrKGZ1bmN0aW9uKCkge1xuICAgIGNiKGVyKTtcbiAgfSk7XG59XG5cbi8vIElmIHdlIGdldCBzb21ldGhpbmcgdGhhdCBpcyBub3QgYSBidWZmZXIsIHN0cmluZywgbnVsbCwgb3IgdW5kZWZpbmVkLFxuLy8gYW5kIHdlJ3JlIG5vdCBpbiBvYmplY3RNb2RlLCB0aGVuIHRoYXQncyBhbiBlcnJvci5cbi8vIE90aGVyd2lzZSBzdHJlYW0gY2h1bmtzIGFyZSBhbGwgY29uc2lkZXJlZCB0byBiZSBvZiBsZW5ndGg9MSwgYW5kIHRoZVxuLy8gd2F0ZXJtYXJrcyBkZXRlcm1pbmUgaG93IG1hbnkgb2JqZWN0cyB0byBrZWVwIGluIHRoZSBidWZmZXIsIHJhdGhlciB0aGFuXG4vLyBob3cgbWFueSBieXRlcyBvciBjaGFyYWN0ZXJzLlxuZnVuY3Rpb24gdmFsaWRDaHVuayhzdHJlYW0sIHN0YXRlLCBjaHVuaywgY2IpIHtcbiAgdmFyIHZhbGlkID0gdHJ1ZTtcbiAgaWYgKCF1dGlsLmlzQnVmZmVyKGNodW5rKSAmJlxuICAgICAgIXV0aWwuaXNTdHJpbmcoY2h1bmspICYmXG4gICAgICAhdXRpbC5pc051bGxPclVuZGVmaW5lZChjaHVuaykgJiZcbiAgICAgICFzdGF0ZS5vYmplY3RNb2RlKSB7XG4gICAgdmFyIGVyID0gbmV3IFR5cGVFcnJvcignSW52YWxpZCBub24tc3RyaW5nL2J1ZmZlciBjaHVuaycpO1xuICAgIHN0cmVhbS5lbWl0KCdlcnJvcicsIGVyKTtcbiAgICBwcm9jZXNzLm5leHRUaWNrKGZ1bmN0aW9uKCkge1xuICAgICAgY2IoZXIpO1xuICAgIH0pO1xuICAgIHZhbGlkID0gZmFsc2U7XG4gIH1cbiAgcmV0dXJuIHZhbGlkO1xufVxuXG5Xcml0YWJsZS5wcm90b3R5cGUud3JpdGUgPSBmdW5jdGlvbihjaHVuaywgZW5jb2RpbmcsIGNiKSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3dyaXRhYmxlU3RhdGU7XG4gIHZhciByZXQgPSBmYWxzZTtcblxuICBpZiAodXRpbC5pc0Z1bmN0aW9uKGVuY29kaW5nKSkge1xuICAgIGNiID0gZW5jb2Rpbmc7XG4gICAgZW5jb2RpbmcgPSBudWxsO1xuICB9XG5cbiAgaWYgKHV0aWwuaXNCdWZmZXIoY2h1bmspKVxuICAgIGVuY29kaW5nID0gJ2J1ZmZlcic7XG4gIGVsc2UgaWYgKCFlbmNvZGluZylcbiAgICBlbmNvZGluZyA9IHN0YXRlLmRlZmF1bHRFbmNvZGluZztcblxuICBpZiAoIXV0aWwuaXNGdW5jdGlvbihjYikpXG4gICAgY2IgPSBmdW5jdGlvbigpIHt9O1xuXG4gIGlmIChzdGF0ZS5lbmRlZClcbiAgICB3cml0ZUFmdGVyRW5kKHRoaXMsIHN0YXRlLCBjYik7XG4gIGVsc2UgaWYgKHZhbGlkQ2h1bmsodGhpcywgc3RhdGUsIGNodW5rLCBjYikpIHtcbiAgICBzdGF0ZS5wZW5kaW5nY2IrKztcbiAgICByZXQgPSB3cml0ZU9yQnVmZmVyKHRoaXMsIHN0YXRlLCBjaHVuaywgZW5jb2RpbmcsIGNiKTtcbiAgfVxuXG4gIHJldHVybiByZXQ7XG59O1xuXG5Xcml0YWJsZS5wcm90b3R5cGUuY29yayA9IGZ1bmN0aW9uKCkge1xuICB2YXIgc3RhdGUgPSB0aGlzLl93cml0YWJsZVN0YXRlO1xuXG4gIHN0YXRlLmNvcmtlZCsrO1xufTtcblxuV3JpdGFibGUucHJvdG90eXBlLnVuY29yayA9IGZ1bmN0aW9uKCkge1xuICB2YXIgc3RhdGUgPSB0aGlzLl93cml0YWJsZVN0YXRlO1xuXG4gIGlmIChzdGF0ZS5jb3JrZWQpIHtcbiAgICBzdGF0ZS5jb3JrZWQtLTtcblxuICAgIGlmICghc3RhdGUud3JpdGluZyAmJlxuICAgICAgICAhc3RhdGUuY29ya2VkICYmXG4gICAgICAgICFzdGF0ZS5maW5pc2hlZCAmJlxuICAgICAgICAhc3RhdGUuYnVmZmVyUHJvY2Vzc2luZyAmJlxuICAgICAgICBzdGF0ZS5idWZmZXIubGVuZ3RoKVxuICAgICAgY2xlYXJCdWZmZXIodGhpcywgc3RhdGUpO1xuICB9XG59O1xuXG5mdW5jdGlvbiBkZWNvZGVDaHVuayhzdGF0ZSwgY2h1bmssIGVuY29kaW5nKSB7XG4gIGlmICghc3RhdGUub2JqZWN0TW9kZSAmJlxuICAgICAgc3RhdGUuZGVjb2RlU3RyaW5ncyAhPT0gZmFsc2UgJiZcbiAgICAgIHV0aWwuaXNTdHJpbmcoY2h1bmspKSB7XG4gICAgY2h1bmsgPSBuZXcgQnVmZmVyKGNodW5rLCBlbmNvZGluZyk7XG4gIH1cbiAgcmV0dXJuIGNodW5rO1xufVxuXG4vLyBpZiB3ZSdyZSBhbHJlYWR5IHdyaXRpbmcgc29tZXRoaW5nLCB0aGVuIGp1c3QgcHV0IHRoaXNcbi8vIGluIHRoZSBxdWV1ZSwgYW5kIHdhaXQgb3VyIHR1cm4uICBPdGhlcndpc2UsIGNhbGwgX3dyaXRlXG4vLyBJZiB3ZSByZXR1cm4gZmFsc2UsIHRoZW4gd2UgbmVlZCBhIGRyYWluIGV2ZW50LCBzbyBzZXQgdGhhdCBmbGFnLlxuZnVuY3Rpb24gd3JpdGVPckJ1ZmZlcihzdHJlYW0sIHN0YXRlLCBjaHVuaywgZW5jb2RpbmcsIGNiKSB7XG4gIGNodW5rID0gZGVjb2RlQ2h1bmsoc3RhdGUsIGNodW5rLCBlbmNvZGluZyk7XG4gIGlmICh1dGlsLmlzQnVmZmVyKGNodW5rKSlcbiAgICBlbmNvZGluZyA9ICdidWZmZXInO1xuICB2YXIgbGVuID0gc3RhdGUub2JqZWN0TW9kZSA/IDEgOiBjaHVuay5sZW5ndGg7XG5cbiAgc3RhdGUubGVuZ3RoICs9IGxlbjtcblxuICB2YXIgcmV0ID0gc3RhdGUubGVuZ3RoIDwgc3RhdGUuaGlnaFdhdGVyTWFyaztcbiAgLy8gd2UgbXVzdCBlbnN1cmUgdGhhdCBwcmV2aW91cyBuZWVkRHJhaW4gd2lsbCBub3QgYmUgcmVzZXQgdG8gZmFsc2UuXG4gIGlmICghcmV0KVxuICAgIHN0YXRlLm5lZWREcmFpbiA9IHRydWU7XG5cbiAgaWYgKHN0YXRlLndyaXRpbmcgfHwgc3RhdGUuY29ya2VkKVxuICAgIHN0YXRlLmJ1ZmZlci5wdXNoKG5ldyBXcml0ZVJlcShjaHVuaywgZW5jb2RpbmcsIGNiKSk7XG4gIGVsc2VcbiAgICBkb1dyaXRlKHN0cmVhbSwgc3RhdGUsIGZhbHNlLCBsZW4sIGNodW5rLCBlbmNvZGluZywgY2IpO1xuXG4gIHJldHVybiByZXQ7XG59XG5cbmZ1bmN0aW9uIGRvV3JpdGUoc3RyZWFtLCBzdGF0ZSwgd3JpdGV2LCBsZW4sIGNodW5rLCBlbmNvZGluZywgY2IpIHtcbiAgc3RhdGUud3JpdGVsZW4gPSBsZW47XG4gIHN0YXRlLndyaXRlY2IgPSBjYjtcbiAgc3RhdGUud3JpdGluZyA9IHRydWU7XG4gIHN0YXRlLnN5bmMgPSB0cnVlO1xuICBpZiAod3JpdGV2KVxuICAgIHN0cmVhbS5fd3JpdGV2KGNodW5rLCBzdGF0ZS5vbndyaXRlKTtcbiAgZWxzZVxuICAgIHN0cmVhbS5fd3JpdGUoY2h1bmssIGVuY29kaW5nLCBzdGF0ZS5vbndyaXRlKTtcbiAgc3RhdGUuc3luYyA9IGZhbHNlO1xufVxuXG5mdW5jdGlvbiBvbndyaXRlRXJyb3Ioc3RyZWFtLCBzdGF0ZSwgc3luYywgZXIsIGNiKSB7XG4gIGlmIChzeW5jKVxuICAgIHByb2Nlc3MubmV4dFRpY2soZnVuY3Rpb24oKSB7XG4gICAgICBzdGF0ZS5wZW5kaW5nY2ItLTtcbiAgICAgIGNiKGVyKTtcbiAgICB9KTtcbiAgZWxzZSB7XG4gICAgc3RhdGUucGVuZGluZ2NiLS07XG4gICAgY2IoZXIpO1xuICB9XG5cbiAgc3RyZWFtLl93cml0YWJsZVN0YXRlLmVycm9yRW1pdHRlZCA9IHRydWU7XG4gIHN0cmVhbS5lbWl0KCdlcnJvcicsIGVyKTtcbn1cblxuZnVuY3Rpb24gb253cml0ZVN0YXRlVXBkYXRlKHN0YXRlKSB7XG4gIHN0YXRlLndyaXRpbmcgPSBmYWxzZTtcbiAgc3RhdGUud3JpdGVjYiA9IG51bGw7XG4gIHN0YXRlLmxlbmd0aCAtPSBzdGF0ZS53cml0ZWxlbjtcbiAgc3RhdGUud3JpdGVsZW4gPSAwO1xufVxuXG5mdW5jdGlvbiBvbndyaXRlKHN0cmVhbSwgZXIpIHtcbiAgdmFyIHN0YXRlID0gc3RyZWFtLl93cml0YWJsZVN0YXRlO1xuICB2YXIgc3luYyA9IHN0YXRlLnN5bmM7XG4gIHZhciBjYiA9IHN0YXRlLndyaXRlY2I7XG5cbiAgb253cml0ZVN0YXRlVXBkYXRlKHN0YXRlKTtcblxuICBpZiAoZXIpXG4gICAgb253cml0ZUVycm9yKHN0cmVhbSwgc3RhdGUsIHN5bmMsIGVyLCBjYik7XG4gIGVsc2Uge1xuICAgIC8vIENoZWNrIGlmIHdlJ3JlIGFjdHVhbGx5IHJlYWR5IHRvIGZpbmlzaCwgYnV0IGRvbid0IGVtaXQgeWV0XG4gICAgdmFyIGZpbmlzaGVkID0gbmVlZEZpbmlzaChzdHJlYW0sIHN0YXRlKTtcblxuICAgIGlmICghZmluaXNoZWQgJiZcbiAgICAgICAgIXN0YXRlLmNvcmtlZCAmJlxuICAgICAgICAhc3RhdGUuYnVmZmVyUHJvY2Vzc2luZyAmJlxuICAgICAgICBzdGF0ZS5idWZmZXIubGVuZ3RoKSB7XG4gICAgICBjbGVhckJ1ZmZlcihzdHJlYW0sIHN0YXRlKTtcbiAgICB9XG5cbiAgICBpZiAoc3luYykge1xuICAgICAgcHJvY2Vzcy5uZXh0VGljayhmdW5jdGlvbigpIHtcbiAgICAgICAgYWZ0ZXJXcml0ZShzdHJlYW0sIHN0YXRlLCBmaW5pc2hlZCwgY2IpO1xuICAgICAgfSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGFmdGVyV3JpdGUoc3RyZWFtLCBzdGF0ZSwgZmluaXNoZWQsIGNiKTtcbiAgICB9XG4gIH1cbn1cblxuZnVuY3Rpb24gYWZ0ZXJXcml0ZShzdHJlYW0sIHN0YXRlLCBmaW5pc2hlZCwgY2IpIHtcbiAgaWYgKCFmaW5pc2hlZClcbiAgICBvbndyaXRlRHJhaW4oc3RyZWFtLCBzdGF0ZSk7XG4gIHN0YXRlLnBlbmRpbmdjYi0tO1xuICBjYigpO1xuICBmaW5pc2hNYXliZShzdHJlYW0sIHN0YXRlKTtcbn1cblxuLy8gTXVzdCBmb3JjZSBjYWxsYmFjayB0byBiZSBjYWxsZWQgb24gbmV4dFRpY2ssIHNvIHRoYXQgd2UgZG9uJ3Rcbi8vIGVtaXQgJ2RyYWluJyBiZWZvcmUgdGhlIHdyaXRlKCkgY29uc3VtZXIgZ2V0cyB0aGUgJ2ZhbHNlJyByZXR1cm5cbi8vIHZhbHVlLCBhbmQgaGFzIGEgY2hhbmNlIHRvIGF0dGFjaCBhICdkcmFpbicgbGlzdGVuZXIuXG5mdW5jdGlvbiBvbndyaXRlRHJhaW4oc3RyZWFtLCBzdGF0ZSkge1xuICBpZiAoc3RhdGUubGVuZ3RoID09PSAwICYmIHN0YXRlLm5lZWREcmFpbikge1xuICAgIHN0YXRlLm5lZWREcmFpbiA9IGZhbHNlO1xuICAgIHN0cmVhbS5lbWl0KCdkcmFpbicpO1xuICB9XG59XG5cblxuLy8gaWYgdGhlcmUncyBzb21ldGhpbmcgaW4gdGhlIGJ1ZmZlciB3YWl0aW5nLCB0aGVuIHByb2Nlc3MgaXRcbmZ1bmN0aW9uIGNsZWFyQnVmZmVyKHN0cmVhbSwgc3RhdGUpIHtcbiAgc3RhdGUuYnVmZmVyUHJvY2Vzc2luZyA9IHRydWU7XG5cbiAgaWYgKHN0cmVhbS5fd3JpdGV2ICYmIHN0YXRlLmJ1ZmZlci5sZW5ndGggPiAxKSB7XG4gICAgLy8gRmFzdCBjYXNlLCB3cml0ZSBldmVyeXRoaW5nIHVzaW5nIF93cml0ZXYoKVxuICAgIHZhciBjYnMgPSBbXTtcbiAgICBmb3IgKHZhciBjID0gMDsgYyA8IHN0YXRlLmJ1ZmZlci5sZW5ndGg7IGMrKylcbiAgICAgIGNicy5wdXNoKHN0YXRlLmJ1ZmZlcltjXS5jYWxsYmFjayk7XG5cbiAgICAvLyBjb3VudCB0aGUgb25lIHdlIGFyZSBhZGRpbmcsIGFzIHdlbGwuXG4gICAgLy8gVE9ETyhpc2FhY3MpIGNsZWFuIHRoaXMgdXBcbiAgICBzdGF0ZS5wZW5kaW5nY2IrKztcbiAgICBkb1dyaXRlKHN0cmVhbSwgc3RhdGUsIHRydWUsIHN0YXRlLmxlbmd0aCwgc3RhdGUuYnVmZmVyLCAnJywgZnVuY3Rpb24oZXJyKSB7XG4gICAgICBmb3IgKHZhciBpID0gMDsgaSA8IGNicy5sZW5ndGg7IGkrKykge1xuICAgICAgICBzdGF0ZS5wZW5kaW5nY2ItLTtcbiAgICAgICAgY2JzW2ldKGVycik7XG4gICAgICB9XG4gICAgfSk7XG5cbiAgICAvLyBDbGVhciBidWZmZXJcbiAgICBzdGF0ZS5idWZmZXIgPSBbXTtcbiAgfSBlbHNlIHtcbiAgICAvLyBTbG93IGNhc2UsIHdyaXRlIGNodW5rcyBvbmUtYnktb25lXG4gICAgZm9yICh2YXIgYyA9IDA7IGMgPCBzdGF0ZS5idWZmZXIubGVuZ3RoOyBjKyspIHtcbiAgICAgIHZhciBlbnRyeSA9IHN0YXRlLmJ1ZmZlcltjXTtcbiAgICAgIHZhciBjaHVuayA9IGVudHJ5LmNodW5rO1xuICAgICAgdmFyIGVuY29kaW5nID0gZW50cnkuZW5jb2Rpbmc7XG4gICAgICB2YXIgY2IgPSBlbnRyeS5jYWxsYmFjaztcbiAgICAgIHZhciBsZW4gPSBzdGF0ZS5vYmplY3RNb2RlID8gMSA6IGNodW5rLmxlbmd0aDtcblxuICAgICAgZG9Xcml0ZShzdHJlYW0sIHN0YXRlLCBmYWxzZSwgbGVuLCBjaHVuaywgZW5jb2RpbmcsIGNiKTtcblxuICAgICAgLy8gaWYgd2UgZGlkbid0IGNhbGwgdGhlIG9ud3JpdGUgaW1tZWRpYXRlbHksIHRoZW5cbiAgICAgIC8vIGl0IG1lYW5zIHRoYXQgd2UgbmVlZCB0byB3YWl0IHVudGlsIGl0IGRvZXMuXG4gICAgICAvLyBhbHNvLCB0aGF0IG1lYW5zIHRoYXQgdGhlIGNodW5rIGFuZCBjYiBhcmUgY3VycmVudGx5XG4gICAgICAvLyBiZWluZyBwcm9jZXNzZWQsIHNvIG1vdmUgdGhlIGJ1ZmZlciBjb3VudGVyIHBhc3QgdGhlbS5cbiAgICAgIGlmIChzdGF0ZS53cml0aW5nKSB7XG4gICAgICAgIGMrKztcbiAgICAgICAgYnJlYWs7XG4gICAgICB9XG4gICAgfVxuXG4gICAgaWYgKGMgPCBzdGF0ZS5idWZmZXIubGVuZ3RoKVxuICAgICAgc3RhdGUuYnVmZmVyID0gc3RhdGUuYnVmZmVyLnNsaWNlKGMpO1xuICAgIGVsc2VcbiAgICAgIHN0YXRlLmJ1ZmZlci5sZW5ndGggPSAwO1xuICB9XG5cbiAgc3RhdGUuYnVmZmVyUHJvY2Vzc2luZyA9IGZhbHNlO1xufVxuXG5Xcml0YWJsZS5wcm90b3R5cGUuX3dyaXRlID0gZnVuY3Rpb24oY2h1bmssIGVuY29kaW5nLCBjYikge1xuICBjYihuZXcgRXJyb3IoJ25vdCBpbXBsZW1lbnRlZCcpKTtcblxufTtcblxuV3JpdGFibGUucHJvdG90eXBlLl93cml0ZXYgPSBudWxsO1xuXG5Xcml0YWJsZS5wcm90b3R5cGUuZW5kID0gZnVuY3Rpb24oY2h1bmssIGVuY29kaW5nLCBjYikge1xuICB2YXIgc3RhdGUgPSB0aGlzLl93cml0YWJsZVN0YXRlO1xuXG4gIGlmICh1dGlsLmlzRnVuY3Rpb24oY2h1bmspKSB7XG4gICAgY2IgPSBjaHVuaztcbiAgICBjaHVuayA9IG51bGw7XG4gICAgZW5jb2RpbmcgPSBudWxsO1xuICB9IGVsc2UgaWYgKHV0aWwuaXNGdW5jdGlvbihlbmNvZGluZykpIHtcbiAgICBjYiA9IGVuY29kaW5nO1xuICAgIGVuY29kaW5nID0gbnVsbDtcbiAgfVxuXG4gIGlmICghdXRpbC5pc051bGxPclVuZGVmaW5lZChjaHVuaykpXG4gICAgdGhpcy53cml0ZShjaHVuaywgZW5jb2RpbmcpO1xuXG4gIC8vIC5lbmQoKSBmdWxseSB1bmNvcmtzXG4gIGlmIChzdGF0ZS5jb3JrZWQpIHtcbiAgICBzdGF0ZS5jb3JrZWQgPSAxO1xuICAgIHRoaXMudW5jb3JrKCk7XG4gIH1cblxuICAvLyBpZ25vcmUgdW5uZWNlc3NhcnkgZW5kKCkgY2FsbHMuXG4gIGlmICghc3RhdGUuZW5kaW5nICYmICFzdGF0ZS5maW5pc2hlZClcbiAgICBlbmRXcml0YWJsZSh0aGlzLCBzdGF0ZSwgY2IpO1xufTtcblxuXG5mdW5jdGlvbiBuZWVkRmluaXNoKHN0cmVhbSwgc3RhdGUpIHtcbiAgcmV0dXJuIChzdGF0ZS5lbmRpbmcgJiZcbiAgICAgICAgICBzdGF0ZS5sZW5ndGggPT09IDAgJiZcbiAgICAgICAgICAhc3RhdGUuZmluaXNoZWQgJiZcbiAgICAgICAgICAhc3RhdGUud3JpdGluZyk7XG59XG5cbmZ1bmN0aW9uIHByZWZpbmlzaChzdHJlYW0sIHN0YXRlKSB7XG4gIGlmICghc3RhdGUucHJlZmluaXNoZWQpIHtcbiAgICBzdGF0ZS5wcmVmaW5pc2hlZCA9IHRydWU7XG4gICAgc3RyZWFtLmVtaXQoJ3ByZWZpbmlzaCcpO1xuICB9XG59XG5cbmZ1bmN0aW9uIGZpbmlzaE1heWJlKHN0cmVhbSwgc3RhdGUpIHtcbiAgdmFyIG5lZWQgPSBuZWVkRmluaXNoKHN0cmVhbSwgc3RhdGUpO1xuICBpZiAobmVlZCkge1xuICAgIGlmIChzdGF0ZS5wZW5kaW5nY2IgPT09IDApIHtcbiAgICAgIHByZWZpbmlzaChzdHJlYW0sIHN0YXRlKTtcbiAgICAgIHN0YXRlLmZpbmlzaGVkID0gdHJ1ZTtcbiAgICAgIHN0cmVhbS5lbWl0KCdmaW5pc2gnKTtcbiAgICB9IGVsc2VcbiAgICAgIHByZWZpbmlzaChzdHJlYW0sIHN0YXRlKTtcbiAgfVxuICByZXR1cm4gbmVlZDtcbn1cblxuZnVuY3Rpb24gZW5kV3JpdGFibGUoc3RyZWFtLCBzdGF0ZSwgY2IpIHtcbiAgc3RhdGUuZW5kaW5nID0gdHJ1ZTtcbiAgZmluaXNoTWF5YmUoc3RyZWFtLCBzdGF0ZSk7XG4gIGlmIChjYikge1xuICAgIGlmIChzdGF0ZS5maW5pc2hlZClcbiAgICAgIHByb2Nlc3MubmV4dFRpY2soY2IpO1xuICAgIGVsc2VcbiAgICAgIHN0cmVhbS5vbmNlKCdmaW5pc2gnLCBjYik7XG4gIH1cbiAgc3RhdGUuZW5kZWQgPSB0cnVlO1xufVxuIl19
},{"./_stream_duplex":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_duplex.js","_process":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/process/browser.js","buffer":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/index.js","core-util-is":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/node_modules/core-util-is/lib/util.js","inherits":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js","stream":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/stream-browserify/index.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/node_modules/core-util-is/lib/util.js":[function(require,module,exports){
(function (Buffer){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

// NOTE: These type checking functions intentionally don't use `instanceof`
// because it is fragile and can be easily faked with `Object.create()`.

function isArray(arg) {
  if (Array.isArray) {
    return Array.isArray(arg);
  }
  return objectToString(arg) === '[object Array]';
}
exports.isArray = isArray;

function isBoolean(arg) {
  return typeof arg === 'boolean';
}
exports.isBoolean = isBoolean;

function isNull(arg) {
  return arg === null;
}
exports.isNull = isNull;

function isNullOrUndefined(arg) {
  return arg == null;
}
exports.isNullOrUndefined = isNullOrUndefined;

function isNumber(arg) {
  return typeof arg === 'number';
}
exports.isNumber = isNumber;

function isString(arg) {
  return typeof arg === 'string';
}
exports.isString = isString;

function isSymbol(arg) {
  return typeof arg === 'symbol';
}
exports.isSymbol = isSymbol;

function isUndefined(arg) {
  return arg === void 0;
}
exports.isUndefined = isUndefined;

function isRegExp(re) {
  return objectToString(re) === '[object RegExp]';
}
exports.isRegExp = isRegExp;

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}
exports.isObject = isObject;

function isDate(d) {
  return objectToString(d) === '[object Date]';
}
exports.isDate = isDate;

function isError(e) {
  return (objectToString(e) === '[object Error]' || e instanceof Error);
}
exports.isError = isError;

function isFunction(arg) {
  return typeof arg === 'function';
}
exports.isFunction = isFunction;

function isPrimitive(arg) {
  return arg === null ||
         typeof arg === 'boolean' ||
         typeof arg === 'number' ||
         typeof arg === 'string' ||
         typeof arg === 'symbol' ||  // ES6 symbol
         typeof arg === 'undefined';
}
exports.isPrimitive = isPrimitive;

exports.isBuffer = Buffer.isBuffer;

function objectToString(o) {
  return Object.prototype.toString.call(o);
}

}).call(this,{"isBuffer":require("../../../../insert-module-globals/node_modules/is-buffer/index.js")})
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vbm9kZV9tb2R1bGVzL2NvcmUtdXRpbC1pcy9saWIvdXRpbC5qcyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiO0FBQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIvLyBDb3B5cmlnaHQgSm95ZW50LCBJbmMuIGFuZCBvdGhlciBOb2RlIGNvbnRyaWJ1dG9ycy5cbi8vXG4vLyBQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcgYVxuLy8gY29weSBvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZVxuLy8gXCJTb2Z0d2FyZVwiKSwgdG8gZGVhbCBpbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nXG4vLyB3aXRob3V0IGxpbWl0YXRpb24gdGhlIHJpZ2h0cyB0byB1c2UsIGNvcHksIG1vZGlmeSwgbWVyZ2UsIHB1Ymxpc2gsXG4vLyBkaXN0cmlidXRlLCBzdWJsaWNlbnNlLCBhbmQvb3Igc2VsbCBjb3BpZXMgb2YgdGhlIFNvZnR3YXJlLCBhbmQgdG8gcGVybWl0XG4vLyBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzIGZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGVcbi8vIGZvbGxvd2luZyBjb25kaXRpb25zOlxuLy9cbi8vIFRoZSBhYm92ZSBjb3B5cmlnaHQgbm90aWNlIGFuZCB0aGlzIHBlcm1pc3Npb24gbm90aWNlIHNoYWxsIGJlIGluY2x1ZGVkXG4vLyBpbiBhbGwgY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS5cbi8vXG4vLyBUSEUgU09GVFdBUkUgSVMgUFJPVklERUQgXCJBUyBJU1wiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTXG4vLyBPUiBJTVBMSUVELCBJTkNMVURJTkcgQlVUIE5PVCBMSU1JVEVEIFRPIFRIRSBXQVJSQU5USUVTIE9GXG4vLyBNRVJDSEFOVEFCSUxJVFksIEZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFORCBOT05JTkZSSU5HRU1FTlQuIElOXG4vLyBOTyBFVkVOVCBTSEFMTCBUSEUgQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSxcbi8vIERBTUFHRVMgT1IgT1RIRVIgTElBQklMSVRZLCBXSEVUSEVSIElOIEFOIEFDVElPTiBPRiBDT05UUkFDVCwgVE9SVCBPUlxuLy8gT1RIRVJXSVNFLCBBUklTSU5HIEZST00sIE9VVCBPRiBPUiBJTiBDT05ORUNUSU9OIFdJVEggVEhFIFNPRlRXQVJFIE9SIFRIRVxuLy8gVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRSBTT0ZUV0FSRS5cblxuLy8gTk9URTogVGhlc2UgdHlwZSBjaGVja2luZyBmdW5jdGlvbnMgaW50ZW50aW9uYWxseSBkb24ndCB1c2UgYGluc3RhbmNlb2ZgXG4vLyBiZWNhdXNlIGl0IGlzIGZyYWdpbGUgYW5kIGNhbiBiZSBlYXNpbHkgZmFrZWQgd2l0aCBgT2JqZWN0LmNyZWF0ZSgpYC5cblxuZnVuY3Rpb24gaXNBcnJheShhcmcpIHtcbiAgaWYgKEFycmF5LmlzQXJyYXkpIHtcbiAgICByZXR1cm4gQXJyYXkuaXNBcnJheShhcmcpO1xuICB9XG4gIHJldHVybiBvYmplY3RUb1N0cmluZyhhcmcpID09PSAnW29iamVjdCBBcnJheV0nO1xufVxuZXhwb3J0cy5pc0FycmF5ID0gaXNBcnJheTtcblxuZnVuY3Rpb24gaXNCb29sZWFuKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ2Jvb2xlYW4nO1xufVxuZXhwb3J0cy5pc0Jvb2xlYW4gPSBpc0Jvb2xlYW47XG5cbmZ1bmN0aW9uIGlzTnVsbChhcmcpIHtcbiAgcmV0dXJuIGFyZyA9PT0gbnVsbDtcbn1cbmV4cG9ydHMuaXNOdWxsID0gaXNOdWxsO1xuXG5mdW5jdGlvbiBpc051bGxPclVuZGVmaW5lZChhcmcpIHtcbiAgcmV0dXJuIGFyZyA9PSBudWxsO1xufVxuZXhwb3J0cy5pc051bGxPclVuZGVmaW5lZCA9IGlzTnVsbE9yVW5kZWZpbmVkO1xuXG5mdW5jdGlvbiBpc051bWJlcihhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09ICdudW1iZXInO1xufVxuZXhwb3J0cy5pc051bWJlciA9IGlzTnVtYmVyO1xuXG5mdW5jdGlvbiBpc1N0cmluZyhhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09ICdzdHJpbmcnO1xufVxuZXhwb3J0cy5pc1N0cmluZyA9IGlzU3RyaW5nO1xuXG5mdW5jdGlvbiBpc1N5bWJvbChhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09ICdzeW1ib2wnO1xufVxuZXhwb3J0cy5pc1N5bWJvbCA9IGlzU3ltYm9sO1xuXG5mdW5jdGlvbiBpc1VuZGVmaW5lZChhcmcpIHtcbiAgcmV0dXJuIGFyZyA9PT0gdm9pZCAwO1xufVxuZXhwb3J0cy5pc1VuZGVmaW5lZCA9IGlzVW5kZWZpbmVkO1xuXG5mdW5jdGlvbiBpc1JlZ0V4cChyZSkge1xuICByZXR1cm4gb2JqZWN0VG9TdHJpbmcocmUpID09PSAnW29iamVjdCBSZWdFeHBdJztcbn1cbmV4cG9ydHMuaXNSZWdFeHAgPSBpc1JlZ0V4cDtcblxuZnVuY3Rpb24gaXNPYmplY3QoYXJnKSB7XG4gIHJldHVybiB0eXBlb2YgYXJnID09PSAnb2JqZWN0JyAmJiBhcmcgIT09IG51bGw7XG59XG5leHBvcnRzLmlzT2JqZWN0ID0gaXNPYmplY3Q7XG5cbmZ1bmN0aW9uIGlzRGF0ZShkKSB7XG4gIHJldHVybiBvYmplY3RUb1N0cmluZyhkKSA9PT0gJ1tvYmplY3QgRGF0ZV0nO1xufVxuZXhwb3J0cy5pc0RhdGUgPSBpc0RhdGU7XG5cbmZ1bmN0aW9uIGlzRXJyb3IoZSkge1xuICByZXR1cm4gKG9iamVjdFRvU3RyaW5nKGUpID09PSAnW29iamVjdCBFcnJvcl0nIHx8IGUgaW5zdGFuY2VvZiBFcnJvcik7XG59XG5leHBvcnRzLmlzRXJyb3IgPSBpc0Vycm9yO1xuXG5mdW5jdGlvbiBpc0Z1bmN0aW9uKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ2Z1bmN0aW9uJztcbn1cbmV4cG9ydHMuaXNGdW5jdGlvbiA9IGlzRnVuY3Rpb247XG5cbmZ1bmN0aW9uIGlzUHJpbWl0aXZlKGFyZykge1xuICByZXR1cm4gYXJnID09PSBudWxsIHx8XG4gICAgICAgICB0eXBlb2YgYXJnID09PSAnYm9vbGVhbicgfHxcbiAgICAgICAgIHR5cGVvZiBhcmcgPT09ICdudW1iZXInIHx8XG4gICAgICAgICB0eXBlb2YgYXJnID09PSAnc3RyaW5nJyB8fFxuICAgICAgICAgdHlwZW9mIGFyZyA9PT0gJ3N5bWJvbCcgfHwgIC8vIEVTNiBzeW1ib2xcbiAgICAgICAgIHR5cGVvZiBhcmcgPT09ICd1bmRlZmluZWQnO1xufVxuZXhwb3J0cy5pc1ByaW1pdGl2ZSA9IGlzUHJpbWl0aXZlO1xuXG5leHBvcnRzLmlzQnVmZmVyID0gQnVmZmVyLmlzQnVmZmVyO1xuXG5mdW5jdGlvbiBvYmplY3RUb1N0cmluZyhvKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwobyk7XG59XG4iXX0=
},{"../../../../insert-module-globals/node_modules/is-buffer/index.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/insert-module-globals/node_modules/is-buffer/index.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/passthrough.js":[function(require,module,exports){
module.exports = require("./lib/_stream_passthrough.js")

},{"./lib/_stream_passthrough.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_passthrough.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/readable.js":[function(require,module,exports){
(function (process){
exports = module.exports = require('./lib/_stream_readable.js');
exports.Stream = require('stream');
exports.Readable = exports;
exports.Writable = require('./lib/_stream_writable.js');
exports.Duplex = require('./lib/_stream_duplex.js');
exports.Transform = require('./lib/_stream_transform.js');
exports.PassThrough = require('./lib/_stream_passthrough.js');
if (!process.browser && process.env.READABLE_STREAM === 'disable') {
  module.exports = require('stream');
}

}).call(this,require('_process'))
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vcmVhZGFibGUuanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EiLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbImV4cG9ydHMgPSBtb2R1bGUuZXhwb3J0cyA9IHJlcXVpcmUoJy4vbGliL19zdHJlYW1fcmVhZGFibGUuanMnKTtcbmV4cG9ydHMuU3RyZWFtID0gcmVxdWlyZSgnc3RyZWFtJyk7XG5leHBvcnRzLlJlYWRhYmxlID0gZXhwb3J0cztcbmV4cG9ydHMuV3JpdGFibGUgPSByZXF1aXJlKCcuL2xpYi9fc3RyZWFtX3dyaXRhYmxlLmpzJyk7XG5leHBvcnRzLkR1cGxleCA9IHJlcXVpcmUoJy4vbGliL19zdHJlYW1fZHVwbGV4LmpzJyk7XG5leHBvcnRzLlRyYW5zZm9ybSA9IHJlcXVpcmUoJy4vbGliL19zdHJlYW1fdHJhbnNmb3JtLmpzJyk7XG5leHBvcnRzLlBhc3NUaHJvdWdoID0gcmVxdWlyZSgnLi9saWIvX3N0cmVhbV9wYXNzdGhyb3VnaC5qcycpO1xuaWYgKCFwcm9jZXNzLmJyb3dzZXIgJiYgcHJvY2Vzcy5lbnYuUkVBREFCTEVfU1RSRUFNID09PSAnZGlzYWJsZScpIHtcbiAgbW9kdWxlLmV4cG9ydHMgPSByZXF1aXJlKCdzdHJlYW0nKTtcbn1cbiJdfQ==
},{"./lib/_stream_duplex.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_duplex.js","./lib/_stream_passthrough.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_passthrough.js","./lib/_stream_readable.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_readable.js","./lib/_stream_transform.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_transform.js","./lib/_stream_writable.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_writable.js","_process":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/process/browser.js","stream":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/stream-browserify/index.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/transform.js":[function(require,module,exports){
module.exports = require("./lib/_stream_transform.js")

},{"./lib/_stream_transform.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_transform.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/writable.js":[function(require,module,exports){
module.exports = require("./lib/_stream_writable.js")

},{"./lib/_stream_writable.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/lib/_stream_writable.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/stream-browserify/index.js":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

module.exports = Stream;

var EE = require('events').EventEmitter;
var inherits = require('inherits');

inherits(Stream, EE);
Stream.Readable = require('readable-stream/readable.js');
Stream.Writable = require('readable-stream/writable.js');
Stream.Duplex = require('readable-stream/duplex.js');
Stream.Transform = require('readable-stream/transform.js');
Stream.PassThrough = require('readable-stream/passthrough.js');

// Backwards-compat with node 0.4.x
Stream.Stream = Stream;



// old-style streams.  Note that the pipe method (the only relevant
// part of this class) is overridden in the Readable class.

function Stream() {
  EE.call(this);
}

Stream.prototype.pipe = function(dest, options) {
  var source = this;

  function ondata(chunk) {
    if (dest.writable) {
      if (false === dest.write(chunk) && source.pause) {
        source.pause();
      }
    }
  }

  source.on('data', ondata);

  function ondrain() {
    if (source.readable && source.resume) {
      source.resume();
    }
  }

  dest.on('drain', ondrain);

  // If the 'end' option is not supplied, dest.end() will be called when
  // source gets the 'end' or 'close' events.  Only dest.end() once.
  if (!dest._isStdio && (!options || options.end !== false)) {
    source.on('end', onend);
    source.on('close', onclose);
  }

  var didOnEnd = false;
  function onend() {
    if (didOnEnd) return;
    didOnEnd = true;

    dest.end();
  }


  function onclose() {
    if (didOnEnd) return;
    didOnEnd = true;

    if (typeof dest.destroy === 'function') dest.destroy();
  }

  // don't leave dangling pipes when there are errors.
  function onerror(er) {
    cleanup();
    if (EE.listenerCount(this, 'error') === 0) {
      throw er; // Unhandled stream error in pipe.
    }
  }

  source.on('error', onerror);
  dest.on('error', onerror);

  // remove all the event listeners that were added.
  function cleanup() {
    source.removeListener('data', ondata);
    dest.removeListener('drain', ondrain);

    source.removeListener('end', onend);
    source.removeListener('close', onclose);

    source.removeListener('error', onerror);
    dest.removeListener('error', onerror);

    source.removeListener('end', cleanup);
    source.removeListener('close', cleanup);

    dest.removeListener('close', cleanup);
  }

  source.on('end', cleanup);
  source.on('close', cleanup);

  dest.on('close', cleanup);

  dest.emit('pipe', source);

  // Allow for unix-like usage: A.pipe(B).pipe(C)
  return dest;
};

},{"events":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/events/events.js","inherits":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js","readable-stream/duplex.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/duplex.js","readable-stream/passthrough.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/passthrough.js","readable-stream/readable.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/readable.js","readable-stream/transform.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/transform.js","readable-stream/writable.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/readable-stream/writable.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/string_decoder/index.js":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

var Buffer = require('buffer').Buffer;

var isBufferEncoding = Buffer.isEncoding
  || function(encoding) {
       switch (encoding && encoding.toLowerCase()) {
         case 'hex': case 'utf8': case 'utf-8': case 'ascii': case 'binary': case 'base64': case 'ucs2': case 'ucs-2': case 'utf16le': case 'utf-16le': case 'raw': return true;
         default: return false;
       }
     }


function assertEncoding(encoding) {
  if (encoding && !isBufferEncoding(encoding)) {
    throw new Error('Unknown encoding: ' + encoding);
  }
}

// StringDecoder provides an interface for efficiently splitting a series of
// buffers into a series of JS strings without breaking apart multi-byte
// characters. CESU-8 is handled as part of the UTF-8 encoding.
//
// @TODO Handling all encodings inside a single object makes it very difficult
// to reason about this code, so it should be split up in the future.
// @TODO There should be a utf8-strict encoding that rejects invalid UTF-8 code
// points as used by CESU-8.
var StringDecoder = exports.StringDecoder = function(encoding) {
  this.encoding = (encoding || 'utf8').toLowerCase().replace(/[-_]/, '');
  assertEncoding(encoding);
  switch (this.encoding) {
    case 'utf8':
      // CESU-8 represents each of Surrogate Pair by 3-bytes
      this.surrogateSize = 3;
      break;
    case 'ucs2':
    case 'utf16le':
      // UTF-16 represents each of Surrogate Pair by 2-bytes
      this.surrogateSize = 2;
      this.detectIncompleteChar = utf16DetectIncompleteChar;
      break;
    case 'base64':
      // Base-64 stores 3 bytes in 4 chars, and pads the remainder.
      this.surrogateSize = 3;
      this.detectIncompleteChar = base64DetectIncompleteChar;
      break;
    default:
      this.write = passThroughWrite;
      return;
  }

  // Enough space to store all bytes of a single character. UTF-8 needs 4
  // bytes, but CESU-8 may require up to 6 (3 bytes per surrogate).
  this.charBuffer = new Buffer(6);
  // Number of bytes received for the current incomplete multi-byte character.
  this.charReceived = 0;
  // Number of bytes expected for the current incomplete multi-byte character.
  this.charLength = 0;
};


// write decodes the given buffer and returns it as JS string that is
// guaranteed to not contain any partial multi-byte characters. Any partial
// character found at the end of the buffer is buffered up, and will be
// returned when calling write again with the remaining bytes.
//
// Note: Converting a Buffer containing an orphan surrogate to a String
// currently works, but converting a String to a Buffer (via `new Buffer`, or
// Buffer#write) will replace incomplete surrogates with the unicode
// replacement character. See https://codereview.chromium.org/121173009/ .
StringDecoder.prototype.write = function(buffer) {
  var charStr = '';
  // if our last write ended with an incomplete multibyte character
  while (this.charLength) {
    // determine how many remaining bytes this buffer has to offer for this char
    var available = (buffer.length >= this.charLength - this.charReceived) ?
        this.charLength - this.charReceived :
        buffer.length;

    // add the new bytes to the char buffer
    buffer.copy(this.charBuffer, this.charReceived, 0, available);
    this.charReceived += available;

    if (this.charReceived < this.charLength) {
      // still not enough chars in this buffer? wait for more ...
      return '';
    }

    // remove bytes belonging to the current character from the buffer
    buffer = buffer.slice(available, buffer.length);

    // get the character that was split
    charStr = this.charBuffer.slice(0, this.charLength).toString(this.encoding);

    // CESU-8: lead surrogate (D800-DBFF) is also the incomplete character
    var charCode = charStr.charCodeAt(charStr.length - 1);
    if (charCode >= 0xD800 && charCode <= 0xDBFF) {
      this.charLength += this.surrogateSize;
      charStr = '';
      continue;
    }
    this.charReceived = this.charLength = 0;

    // if there are no more bytes in this buffer, just emit our char
    if (buffer.length === 0) {
      return charStr;
    }
    break;
  }

  // determine and set charLength / charReceived
  this.detectIncompleteChar(buffer);

  var end = buffer.length;
  if (this.charLength) {
    // buffer the incomplete character bytes we got
    buffer.copy(this.charBuffer, 0, buffer.length - this.charReceived, end);
    end -= this.charReceived;
  }

  charStr += buffer.toString(this.encoding, 0, end);

  var end = charStr.length - 1;
  var charCode = charStr.charCodeAt(end);
  // CESU-8: lead surrogate (D800-DBFF) is also the incomplete character
  if (charCode >= 0xD800 && charCode <= 0xDBFF) {
    var size = this.surrogateSize;
    this.charLength += size;
    this.charReceived += size;
    this.charBuffer.copy(this.charBuffer, size, 0, size);
    buffer.copy(this.charBuffer, 0, 0, size);
    return charStr.substring(0, end);
  }

  // or just emit the charStr
  return charStr;
};

// detectIncompleteChar determines if there is an incomplete UTF-8 character at
// the end of the given buffer. If so, it sets this.charLength to the byte
// length that character, and sets this.charReceived to the number of bytes
// that are available for this character.
StringDecoder.prototype.detectIncompleteChar = function(buffer) {
  // determine how many bytes we have to check at the end of this buffer
  var i = (buffer.length >= 3) ? 3 : buffer.length;

  // Figure out if one of the last i bytes of our buffer announces an
  // incomplete char.
  for (; i > 0; i--) {
    var c = buffer[buffer.length - i];

    // See http://en.wikipedia.org/wiki/UTF-8#Description

    // 110XXXXX
    if (i == 1 && c >> 5 == 0x06) {
      this.charLength = 2;
      break;
    }

    // 1110XXXX
    if (i <= 2 && c >> 4 == 0x0E) {
      this.charLength = 3;
      break;
    }

    // 11110XXX
    if (i <= 3 && c >> 3 == 0x1E) {
      this.charLength = 4;
      break;
    }
  }
  this.charReceived = i;
};

StringDecoder.prototype.end = function(buffer) {
  var res = '';
  if (buffer && buffer.length)
    res = this.write(buffer);

  if (this.charReceived) {
    var cr = this.charReceived;
    var buf = this.charBuffer;
    var enc = this.encoding;
    res += buf.slice(0, cr).toString(enc);
  }

  return res;
};

function passThroughWrite(buffer) {
  return buffer.toString(this.encoding);
}

function utf16DetectIncompleteChar(buffer) {
  this.charReceived = buffer.length % 2;
  this.charLength = this.charReceived ? 2 : 0;
}

function base64DetectIncompleteChar(buffer) {
  this.charReceived = buffer.length % 3;
  this.charLength = this.charReceived ? 3 : 0;
}

},{"buffer":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/buffer/index.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/url/url.js":[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

var punycode = require('punycode');

exports.parse = urlParse;
exports.resolve = urlResolve;
exports.resolveObject = urlResolveObject;
exports.format = urlFormat;

exports.Url = Url;

function Url() {
  this.protocol = null;
  this.slashes = null;
  this.auth = null;
  this.host = null;
  this.port = null;
  this.hostname = null;
  this.hash = null;
  this.search = null;
  this.query = null;
  this.pathname = null;
  this.path = null;
  this.href = null;
}

// Reference: RFC 3986, RFC 1808, RFC 2396

// define these here so at least they only have to be
// compiled once on the first module load.
var protocolPattern = /^([a-z0-9.+-]+:)/i,
    portPattern = /:[0-9]*$/,

    // RFC 2396: characters reserved for delimiting URLs.
    // We actually just auto-escape these.
    delims = ['<', '>', '"', '`', ' ', '\r', '\n', '\t'],

    // RFC 2396: characters not allowed for various reasons.
    unwise = ['{', '}', '|', '\\', '^', '`'].concat(delims),

    // Allowed by RFCs, but cause of XSS attacks.  Always escape these.
    autoEscape = ['\''].concat(unwise),
    // Characters that are never ever allowed in a hostname.
    // Note that any invalid chars are also handled, but these
    // are the ones that are *expected* to be seen, so we fast-path
    // them.
    nonHostChars = ['%', '/', '?', ';', '#'].concat(autoEscape),
    hostEndingChars = ['/', '?', '#'],
    hostnameMaxLen = 255,
    hostnamePartPattern = /^[a-z0-9A-Z_-]{0,63}$/,
    hostnamePartStart = /^([a-z0-9A-Z_-]{0,63})(.*)$/,
    // protocols that can allow "unsafe" and "unwise" chars.
    unsafeProtocol = {
      'javascript': true,
      'javascript:': true
    },
    // protocols that never have a hostname.
    hostlessProtocol = {
      'javascript': true,
      'javascript:': true
    },
    // protocols that always contain a // bit.
    slashedProtocol = {
      'http': true,
      'https': true,
      'ftp': true,
      'gopher': true,
      'file': true,
      'http:': true,
      'https:': true,
      'ftp:': true,
      'gopher:': true,
      'file:': true
    },
    querystring = require('querystring');

function urlParse(url, parseQueryString, slashesDenoteHost) {
  if (url && isObject(url) && url instanceof Url) return url;

  var u = new Url;
  u.parse(url, parseQueryString, slashesDenoteHost);
  return u;
}

Url.prototype.parse = function(url, parseQueryString, slashesDenoteHost) {
  if (!isString(url)) {
    throw new TypeError("Parameter 'url' must be a string, not " + typeof url);
  }

  var rest = url;

  // trim before proceeding.
  // This is to support parse stuff like "  http://foo.com  \n"
  rest = rest.trim();

  var proto = protocolPattern.exec(rest);
  if (proto) {
    proto = proto[0];
    var lowerProto = proto.toLowerCase();
    this.protocol = lowerProto;
    rest = rest.substr(proto.length);
  }

  // figure out if it's got a host
  // user@server is *always* interpreted as a hostname, and url
  // resolution will treat //foo/bar as host=foo,path=bar because that's
  // how the browser resolves relative URLs.
  if (slashesDenoteHost || proto || rest.match(/^\/\/[^@\/]+@[^@\/]+/)) {
    var slashes = rest.substr(0, 2) === '//';
    if (slashes && !(proto && hostlessProtocol[proto])) {
      rest = rest.substr(2);
      this.slashes = true;
    }
  }

  if (!hostlessProtocol[proto] &&
      (slashes || (proto && !slashedProtocol[proto]))) {

    // there's a hostname.
    // the first instance of /, ?, ;, or # ends the host.
    //
    // If there is an @ in the hostname, then non-host chars *are* allowed
    // to the left of the last @ sign, unless some host-ending character
    // comes *before* the @-sign.
    // URLs are obnoxious.
    //
    // ex:
    // http://a@b@c/ => user:a@b host:c
    // http://a@b?@c => user:a host:c path:/?@c

    // v0.12 TODO(isaacs): This is not quite how Chrome does things.
    // Review our test case against browsers more comprehensively.

    // find the first instance of any hostEndingChars
    var hostEnd = -1;
    for (var i = 0; i < hostEndingChars.length; i++) {
      var hec = rest.indexOf(hostEndingChars[i]);
      if (hec !== -1 && (hostEnd === -1 || hec < hostEnd))
        hostEnd = hec;
    }

    // at this point, either we have an explicit point where the
    // auth portion cannot go past, or the last @ char is the decider.
    var auth, atSign;
    if (hostEnd === -1) {
      // atSign can be anywhere.
      atSign = rest.lastIndexOf('@');
    } else {
      // atSign must be in auth portion.
      // http://a@b/c@d => host:b auth:a path:/c@d
      atSign = rest.lastIndexOf('@', hostEnd);
    }

    // Now we have a portion which is definitely the auth.
    // Pull that off.
    if (atSign !== -1) {
      auth = rest.slice(0, atSign);
      rest = rest.slice(atSign + 1);
      this.auth = decodeURIComponent(auth);
    }

    // the host is the remaining to the left of the first non-host char
    hostEnd = -1;
    for (var i = 0; i < nonHostChars.length; i++) {
      var hec = rest.indexOf(nonHostChars[i]);
      if (hec !== -1 && (hostEnd === -1 || hec < hostEnd))
        hostEnd = hec;
    }
    // if we still have not hit it, then the entire thing is a host.
    if (hostEnd === -1)
      hostEnd = rest.length;

    this.host = rest.slice(0, hostEnd);
    rest = rest.slice(hostEnd);

    // pull out port.
    this.parseHost();

    // we've indicated that there is a hostname,
    // so even if it's empty, it has to be present.
    this.hostname = this.hostname || '';

    // if hostname begins with [ and ends with ]
    // assume that it's an IPv6 address.
    var ipv6Hostname = this.hostname[0] === '[' &&
        this.hostname[this.hostname.length - 1] === ']';

    // validate a little.
    if (!ipv6Hostname) {
      var hostparts = this.hostname.split(/\./);
      for (var i = 0, l = hostparts.length; i < l; i++) {
        var part = hostparts[i];
        if (!part) continue;
        if (!part.match(hostnamePartPattern)) {
          var newpart = '';
          for (var j = 0, k = part.length; j < k; j++) {
            if (part.charCodeAt(j) > 127) {
              // we replace non-ASCII char with a temporary placeholder
              // we need this to make sure size of hostname is not
              // broken by replacing non-ASCII by nothing
              newpart += 'x';
            } else {
              newpart += part[j];
            }
          }
          // we test again with ASCII char only
          if (!newpart.match(hostnamePartPattern)) {
            var validParts = hostparts.slice(0, i);
            var notHost = hostparts.slice(i + 1);
            var bit = part.match(hostnamePartStart);
            if (bit) {
              validParts.push(bit[1]);
              notHost.unshift(bit[2]);
            }
            if (notHost.length) {
              rest = '/' + notHost.join('.') + rest;
            }
            this.hostname = validParts.join('.');
            break;
          }
        }
      }
    }

    if (this.hostname.length > hostnameMaxLen) {
      this.hostname = '';
    } else {
      // hostnames are always lower case.
      this.hostname = this.hostname.toLowerCase();
    }

    if (!ipv6Hostname) {
      // IDNA Support: Returns a puny coded representation of "domain".
      // It only converts the part of the domain name that
      // has non ASCII characters. I.e. it dosent matter if
      // you call it with a domain that already is in ASCII.
      var domainArray = this.hostname.split('.');
      var newOut = [];
      for (var i = 0; i < domainArray.length; ++i) {
        var s = domainArray[i];
        newOut.push(s.match(/[^A-Za-z0-9_-]/) ?
            'xn--' + punycode.encode(s) : s);
      }
      this.hostname = newOut.join('.');
    }

    var p = this.port ? ':' + this.port : '';
    var h = this.hostname || '';
    this.host = h + p;
    this.href += this.host;

    // strip [ and ] from the hostname
    // the host field still retains them, though
    if (ipv6Hostname) {
      this.hostname = this.hostname.substr(1, this.hostname.length - 2);
      if (rest[0] !== '/') {
        rest = '/' + rest;
      }
    }
  }

  // now rest is set to the post-host stuff.
  // chop off any delim chars.
  if (!unsafeProtocol[lowerProto]) {

    // First, make 100% sure that any "autoEscape" chars get
    // escaped, even if encodeURIComponent doesn't think they
    // need to be.
    for (var i = 0, l = autoEscape.length; i < l; i++) {
      var ae = autoEscape[i];
      var esc = encodeURIComponent(ae);
      if (esc === ae) {
        esc = escape(ae);
      }
      rest = rest.split(ae).join(esc);
    }
  }


  // chop off from the tail first.
  var hash = rest.indexOf('#');
  if (hash !== -1) {
    // got a fragment string.
    this.hash = rest.substr(hash);
    rest = rest.slice(0, hash);
  }
  var qm = rest.indexOf('?');
  if (qm !== -1) {
    this.search = rest.substr(qm);
    this.query = rest.substr(qm + 1);
    if (parseQueryString) {
      this.query = querystring.parse(this.query);
    }
    rest = rest.slice(0, qm);
  } else if (parseQueryString) {
    // no query string, but parseQueryString still requested
    this.search = '';
    this.query = {};
  }
  if (rest) this.pathname = rest;
  if (slashedProtocol[lowerProto] &&
      this.hostname && !this.pathname) {
    this.pathname = '/';
  }

  //to support http.request
  if (this.pathname || this.search) {
    var p = this.pathname || '';
    var s = this.search || '';
    this.path = p + s;
  }

  // finally, reconstruct the href based on what has been validated.
  this.href = this.format();
  return this;
};

// format a parsed object into a url string
function urlFormat(obj) {
  // ensure it's an object, and not a string url.
  // If it's an obj, this is a no-op.
  // this way, you can call url_format() on strings
  // to clean up potentially wonky urls.
  if (isString(obj)) obj = urlParse(obj);
  if (!(obj instanceof Url)) return Url.prototype.format.call(obj);
  return obj.format();
}

Url.prototype.format = function() {
  var auth = this.auth || '';
  if (auth) {
    auth = encodeURIComponent(auth);
    auth = auth.replace(/%3A/i, ':');
    auth += '@';
  }

  var protocol = this.protocol || '',
      pathname = this.pathname || '',
      hash = this.hash || '',
      host = false,
      query = '';

  if (this.host) {
    host = auth + this.host;
  } else if (this.hostname) {
    host = auth + (this.hostname.indexOf(':') === -1 ?
        this.hostname :
        '[' + this.hostname + ']');
    if (this.port) {
      host += ':' + this.port;
    }
  }

  if (this.query &&
      isObject(this.query) &&
      Object.keys(this.query).length) {
    query = querystring.stringify(this.query);
  }

  var search = this.search || (query && ('?' + query)) || '';

  if (protocol && protocol.substr(-1) !== ':') protocol += ':';

  // only the slashedProtocols get the //.  Not mailto:, xmpp:, etc.
  // unless they had them to begin with.
  if (this.slashes ||
      (!protocol || slashedProtocol[protocol]) && host !== false) {
    host = '//' + (host || '');
    if (pathname && pathname.charAt(0) !== '/') pathname = '/' + pathname;
  } else if (!host) {
    host = '';
  }

  if (hash && hash.charAt(0) !== '#') hash = '#' + hash;
  if (search && search.charAt(0) !== '?') search = '?' + search;

  pathname = pathname.replace(/[?#]/g, function(match) {
    return encodeURIComponent(match);
  });
  search = search.replace('#', '%23');

  return protocol + host + pathname + search + hash;
};

function urlResolve(source, relative) {
  return urlParse(source, false, true).resolve(relative);
}

Url.prototype.resolve = function(relative) {
  return this.resolveObject(urlParse(relative, false, true)).format();
};

function urlResolveObject(source, relative) {
  if (!source) return relative;
  return urlParse(source, false, true).resolveObject(relative);
}

Url.prototype.resolveObject = function(relative) {
  if (isString(relative)) {
    var rel = new Url();
    rel.parse(relative, false, true);
    relative = rel;
  }

  var result = new Url();
  Object.keys(this).forEach(function(k) {
    result[k] = this[k];
  }, this);

  // hash is always overridden, no matter what.
  // even href="" will remove it.
  result.hash = relative.hash;

  // if the relative url is empty, then there's nothing left to do here.
  if (relative.href === '') {
    result.href = result.format();
    return result;
  }

  // hrefs like //foo/bar always cut to the protocol.
  if (relative.slashes && !relative.protocol) {
    // take everything except the protocol from relative
    Object.keys(relative).forEach(function(k) {
      if (k !== 'protocol')
        result[k] = relative[k];
    });

    //urlParse appends trailing / to urls like http://www.example.com
    if (slashedProtocol[result.protocol] &&
        result.hostname && !result.pathname) {
      result.path = result.pathname = '/';
    }

    result.href = result.format();
    return result;
  }

  if (relative.protocol && relative.protocol !== result.protocol) {
    // if it's a known url protocol, then changing
    // the protocol does weird things
    // first, if it's not file:, then we MUST have a host,
    // and if there was a path
    // to begin with, then we MUST have a path.
    // if it is file:, then the host is dropped,
    // because that's known to be hostless.
    // anything else is assumed to be absolute.
    if (!slashedProtocol[relative.protocol]) {
      Object.keys(relative).forEach(function(k) {
        result[k] = relative[k];
      });
      result.href = result.format();
      return result;
    }

    result.protocol = relative.protocol;
    if (!relative.host && !hostlessProtocol[relative.protocol]) {
      var relPath = (relative.pathname || '').split('/');
      while (relPath.length && !(relative.host = relPath.shift()));
      if (!relative.host) relative.host = '';
      if (!relative.hostname) relative.hostname = '';
      if (relPath[0] !== '') relPath.unshift('');
      if (relPath.length < 2) relPath.unshift('');
      result.pathname = relPath.join('/');
    } else {
      result.pathname = relative.pathname;
    }
    result.search = relative.search;
    result.query = relative.query;
    result.host = relative.host || '';
    result.auth = relative.auth;
    result.hostname = relative.hostname || relative.host;
    result.port = relative.port;
    // to support http.request
    if (result.pathname || result.search) {
      var p = result.pathname || '';
      var s = result.search || '';
      result.path = p + s;
    }
    result.slashes = result.slashes || relative.slashes;
    result.href = result.format();
    return result;
  }

  var isSourceAbs = (result.pathname && result.pathname.charAt(0) === '/'),
      isRelAbs = (
          relative.host ||
          relative.pathname && relative.pathname.charAt(0) === '/'
      ),
      mustEndAbs = (isRelAbs || isSourceAbs ||
                    (result.host && relative.pathname)),
      removeAllDots = mustEndAbs,
      srcPath = result.pathname && result.pathname.split('/') || [],
      relPath = relative.pathname && relative.pathname.split('/') || [],
      psychotic = result.protocol && !slashedProtocol[result.protocol];

  // if the url is a non-slashed url, then relative
  // links like ../.. should be able
  // to crawl up to the hostname, as well.  This is strange.
  // result.protocol has already been set by now.
  // Later on, put the first path part into the host field.
  if (psychotic) {
    result.hostname = '';
    result.port = null;
    if (result.host) {
      if (srcPath[0] === '') srcPath[0] = result.host;
      else srcPath.unshift(result.host);
    }
    result.host = '';
    if (relative.protocol) {
      relative.hostname = null;
      relative.port = null;
      if (relative.host) {
        if (relPath[0] === '') relPath[0] = relative.host;
        else relPath.unshift(relative.host);
      }
      relative.host = null;
    }
    mustEndAbs = mustEndAbs && (relPath[0] === '' || srcPath[0] === '');
  }

  if (isRelAbs) {
    // it's absolute.
    result.host = (relative.host || relative.host === '') ?
                  relative.host : result.host;
    result.hostname = (relative.hostname || relative.hostname === '') ?
                      relative.hostname : result.hostname;
    result.search = relative.search;
    result.query = relative.query;
    srcPath = relPath;
    // fall through to the dot-handling below.
  } else if (relPath.length) {
    // it's relative
    // throw away the existing file, and take the new path instead.
    if (!srcPath) srcPath = [];
    srcPath.pop();
    srcPath = srcPath.concat(relPath);
    result.search = relative.search;
    result.query = relative.query;
  } else if (!isNullOrUndefined(relative.search)) {
    // just pull out the search.
    // like href='?foo'.
    // Put this after the other two cases because it simplifies the booleans
    if (psychotic) {
      result.hostname = result.host = srcPath.shift();
      //occationaly the auth can get stuck only in host
      //this especialy happens in cases like
      //url.resolveObject('mailto:local1@domain1', 'local2@domain2')
      var authInHost = result.host && result.host.indexOf('@') > 0 ?
                       result.host.split('@') : false;
      if (authInHost) {
        result.auth = authInHost.shift();
        result.host = result.hostname = authInHost.shift();
      }
    }
    result.search = relative.search;
    result.query = relative.query;
    //to support http.request
    if (!isNull(result.pathname) || !isNull(result.search)) {
      result.path = (result.pathname ? result.pathname : '') +
                    (result.search ? result.search : '');
    }
    result.href = result.format();
    return result;
  }

  if (!srcPath.length) {
    // no path at all.  easy.
    // we've already handled the other stuff above.
    result.pathname = null;
    //to support http.request
    if (result.search) {
      result.path = '/' + result.search;
    } else {
      result.path = null;
    }
    result.href = result.format();
    return result;
  }

  // if a url ENDs in . or .., then it must get a trailing slash.
  // however, if it ends in anything else non-slashy,
  // then it must NOT get a trailing slash.
  var last = srcPath.slice(-1)[0];
  var hasTrailingSlash = (
      (result.host || relative.host) && (last === '.' || last === '..') ||
      last === '');

  // strip single dots, resolve double dots to parent dir
  // if the path tries to go above the root, `up` ends up > 0
  var up = 0;
  for (var i = srcPath.length; i >= 0; i--) {
    last = srcPath[i];
    if (last == '.') {
      srcPath.splice(i, 1);
    } else if (last === '..') {
      srcPath.splice(i, 1);
      up++;
    } else if (up) {
      srcPath.splice(i, 1);
      up--;
    }
  }

  // if the path is allowed to go above the root, restore leading ..s
  if (!mustEndAbs && !removeAllDots) {
    for (; up--; up) {
      srcPath.unshift('..');
    }
  }

  if (mustEndAbs && srcPath[0] !== '' &&
      (!srcPath[0] || srcPath[0].charAt(0) !== '/')) {
    srcPath.unshift('');
  }

  if (hasTrailingSlash && (srcPath.join('/').substr(-1) !== '/')) {
    srcPath.push('');
  }

  var isAbsolute = srcPath[0] === '' ||
      (srcPath[0] && srcPath[0].charAt(0) === '/');

  // put the host back
  if (psychotic) {
    result.hostname = result.host = isAbsolute ? '' :
                                    srcPath.length ? srcPath.shift() : '';
    //occationaly the auth can get stuck only in host
    //this especialy happens in cases like
    //url.resolveObject('mailto:local1@domain1', 'local2@domain2')
    var authInHost = result.host && result.host.indexOf('@') > 0 ?
                     result.host.split('@') : false;
    if (authInHost) {
      result.auth = authInHost.shift();
      result.host = result.hostname = authInHost.shift();
    }
  }

  mustEndAbs = mustEndAbs || (result.host && srcPath.length);

  if (mustEndAbs && !isAbsolute) {
    srcPath.unshift('');
  }

  if (!srcPath.length) {
    result.pathname = null;
    result.path = null;
  } else {
    result.pathname = srcPath.join('/');
  }

  //to support request.http
  if (!isNull(result.pathname) || !isNull(result.search)) {
    result.path = (result.pathname ? result.pathname : '') +
                  (result.search ? result.search : '');
  }
  result.auth = relative.auth || result.auth;
  result.slashes = result.slashes || relative.slashes;
  result.href = result.format();
  return result;
};

Url.prototype.parseHost = function() {
  var host = this.host;
  var port = portPattern.exec(host);
  if (port) {
    port = port[0];
    if (port !== ':') {
      this.port = port.substr(1);
    }
    host = host.substr(0, host.length - port.length);
  }
  if (host) this.hostname = host;
};

function isString(arg) {
  return typeof arg === "string";
}

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}

function isNull(arg) {
  return arg === null;
}
function isNullOrUndefined(arg) {
  return  arg == null;
}

},{"punycode":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/punycode/punycode.js","querystring":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/querystring-es3/index.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/util/node_modules/inherits/inherits_browser.js":[function(require,module,exports){
module.exports=require("/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js")
},{"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/inherits/inherits_browser.js"}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/util/support/isBufferBrowser.js":[function(require,module,exports){
module.exports = function isBuffer(arg) {
  return arg && typeof arg === 'object'
    && typeof arg.copy === 'function'
    && typeof arg.fill === 'function'
    && typeof arg.readUInt8 === 'function';
}
},{}],"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/util/util.js":[function(require,module,exports){
(function (process,global){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

var formatRegExp = /%[sdj%]/g;
exports.format = function(f) {
  if (!isString(f)) {
    var objects = [];
    for (var i = 0; i < arguments.length; i++) {
      objects.push(inspect(arguments[i]));
    }
    return objects.join(' ');
  }

  var i = 1;
  var args = arguments;
  var len = args.length;
  var str = String(f).replace(formatRegExp, function(x) {
    if (x === '%%') return '%';
    if (i >= len) return x;
    switch (x) {
      case '%s': return String(args[i++]);
      case '%d': return Number(args[i++]);
      case '%j':
        try {
          return JSON.stringify(args[i++]);
        } catch (_) {
          return '[Circular]';
        }
      default:
        return x;
    }
  });
  for (var x = args[i]; i < len; x = args[++i]) {
    if (isNull(x) || !isObject(x)) {
      str += ' ' + x;
    } else {
      str += ' ' + inspect(x);
    }
  }
  return str;
};


// Mark that a method should not be used.
// Returns a modified function which warns once by default.
// If --no-deprecation is set, then it is a no-op.
exports.deprecate = function(fn, msg) {
  // Allow for deprecating things in the process of starting up.
  if (isUndefined(global.process)) {
    return function() {
      return exports.deprecate(fn, msg).apply(this, arguments);
    };
  }

  if (process.noDeprecation === true) {
    return fn;
  }

  var warned = false;
  function deprecated() {
    if (!warned) {
      if (process.throwDeprecation) {
        throw new Error(msg);
      } else if (process.traceDeprecation) {
        console.trace(msg);
      } else {
        console.error(msg);
      }
      warned = true;
    }
    return fn.apply(this, arguments);
  }

  return deprecated;
};


var debugs = {};
var debugEnviron;
exports.debuglog = function(set) {
  if (isUndefined(debugEnviron))
    debugEnviron = process.env.NODE_DEBUG || '';
  set = set.toUpperCase();
  if (!debugs[set]) {
    if (new RegExp('\\b' + set + '\\b', 'i').test(debugEnviron)) {
      var pid = process.pid;
      debugs[set] = function() {
        var msg = exports.format.apply(exports, arguments);
        console.error('%s %d: %s', set, pid, msg);
      };
    } else {
      debugs[set] = function() {};
    }
  }
  return debugs[set];
};


/**
 * Echos the value of a value. Trys to print the value out
 * in the best way possible given the different types.
 *
 * @param {Object} obj The object to print out.
 * @param {Object} opts Optional options object that alters the output.
 */
/* legacy: obj, showHidden, depth, colors*/
function inspect(obj, opts) {
  // default options
  var ctx = {
    seen: [],
    stylize: stylizeNoColor
  };
  // legacy...
  if (arguments.length >= 3) ctx.depth = arguments[2];
  if (arguments.length >= 4) ctx.colors = arguments[3];
  if (isBoolean(opts)) {
    // legacy...
    ctx.showHidden = opts;
  } else if (opts) {
    // got an "options" object
    exports._extend(ctx, opts);
  }
  // set default options
  if (isUndefined(ctx.showHidden)) ctx.showHidden = false;
  if (isUndefined(ctx.depth)) ctx.depth = 2;
  if (isUndefined(ctx.colors)) ctx.colors = false;
  if (isUndefined(ctx.customInspect)) ctx.customInspect = true;
  if (ctx.colors) ctx.stylize = stylizeWithColor;
  return formatValue(ctx, obj, ctx.depth);
}
exports.inspect = inspect;


// http://en.wikipedia.org/wiki/ANSI_escape_code#graphics
inspect.colors = {
  'bold' : [1, 22],
  'italic' : [3, 23],
  'underline' : [4, 24],
  'inverse' : [7, 27],
  'white' : [37, 39],
  'grey' : [90, 39],
  'black' : [30, 39],
  'blue' : [34, 39],
  'cyan' : [36, 39],
  'green' : [32, 39],
  'magenta' : [35, 39],
  'red' : [31, 39],
  'yellow' : [33, 39]
};

// Don't use 'blue' not visible on cmd.exe
inspect.styles = {
  'special': 'cyan',
  'number': 'yellow',
  'boolean': 'yellow',
  'undefined': 'grey',
  'null': 'bold',
  'string': 'green',
  'date': 'magenta',
  // "name": intentionally not styling
  'regexp': 'red'
};


function stylizeWithColor(str, styleType) {
  var style = inspect.styles[styleType];

  if (style) {
    return '\u001b[' + inspect.colors[style][0] + 'm' + str +
           '\u001b[' + inspect.colors[style][1] + 'm';
  } else {
    return str;
  }
}


function stylizeNoColor(str, styleType) {
  return str;
}


function arrayToHash(array) {
  var hash = {};

  array.forEach(function(val, idx) {
    hash[val] = true;
  });

  return hash;
}


function formatValue(ctx, value, recurseTimes) {
  // Provide a hook for user-specified inspect functions.
  // Check that value is an object with an inspect function on it
  if (ctx.customInspect &&
      value &&
      isFunction(value.inspect) &&
      // Filter out the util module, it's inspect function is special
      value.inspect !== exports.inspect &&
      // Also filter out any prototype objects using the circular check.
      !(value.constructor && value.constructor.prototype === value)) {
    var ret = value.inspect(recurseTimes, ctx);
    if (!isString(ret)) {
      ret = formatValue(ctx, ret, recurseTimes);
    }
    return ret;
  }

  // Primitive types cannot have properties
  var primitive = formatPrimitive(ctx, value);
  if (primitive) {
    return primitive;
  }

  // Look up the keys of the object.
  var keys = Object.keys(value);
  var visibleKeys = arrayToHash(keys);

  if (ctx.showHidden) {
    keys = Object.getOwnPropertyNames(value);
  }

  // IE doesn't make error fields non-enumerable
  // http://msdn.microsoft.com/en-us/library/ie/dww52sbt(v=vs.94).aspx
  if (isError(value)
      && (keys.indexOf('message') >= 0 || keys.indexOf('description') >= 0)) {
    return formatError(value);
  }

  // Some type of object without properties can be shortcutted.
  if (keys.length === 0) {
    if (isFunction(value)) {
      var name = value.name ? ': ' + value.name : '';
      return ctx.stylize('[Function' + name + ']', 'special');
    }
    if (isRegExp(value)) {
      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
    }
    if (isDate(value)) {
      return ctx.stylize(Date.prototype.toString.call(value), 'date');
    }
    if (isError(value)) {
      return formatError(value);
    }
  }

  var base = '', array = false, braces = ['{', '}'];

  // Make Array say that they are Array
  if (isArray(value)) {
    array = true;
    braces = ['[', ']'];
  }

  // Make functions say that they are functions
  if (isFunction(value)) {
    var n = value.name ? ': ' + value.name : '';
    base = ' [Function' + n + ']';
  }

  // Make RegExps say that they are RegExps
  if (isRegExp(value)) {
    base = ' ' + RegExp.prototype.toString.call(value);
  }

  // Make dates with properties first say the date
  if (isDate(value)) {
    base = ' ' + Date.prototype.toUTCString.call(value);
  }

  // Make error with message first say the error
  if (isError(value)) {
    base = ' ' + formatError(value);
  }

  if (keys.length === 0 && (!array || value.length == 0)) {
    return braces[0] + base + braces[1];
  }

  if (recurseTimes < 0) {
    if (isRegExp(value)) {
      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
    } else {
      return ctx.stylize('[Object]', 'special');
    }
  }

  ctx.seen.push(value);

  var output;
  if (array) {
    output = formatArray(ctx, value, recurseTimes, visibleKeys, keys);
  } else {
    output = keys.map(function(key) {
      return formatProperty(ctx, value, recurseTimes, visibleKeys, key, array);
    });
  }

  ctx.seen.pop();

  return reduceToSingleString(output, base, braces);
}


function formatPrimitive(ctx, value) {
  if (isUndefined(value))
    return ctx.stylize('undefined', 'undefined');
  if (isString(value)) {
    var simple = '\'' + JSON.stringify(value).replace(/^"|"$/g, '')
                                             .replace(/'/g, "\\'")
                                             .replace(/\\"/g, '"') + '\'';
    return ctx.stylize(simple, 'string');
  }
  if (isNumber(value))
    return ctx.stylize('' + value, 'number');
  if (isBoolean(value))
    return ctx.stylize('' + value, 'boolean');
  // For some reason typeof null is "object", so special case here.
  if (isNull(value))
    return ctx.stylize('null', 'null');
}


function formatError(value) {
  return '[' + Error.prototype.toString.call(value) + ']';
}


function formatArray(ctx, value, recurseTimes, visibleKeys, keys) {
  var output = [];
  for (var i = 0, l = value.length; i < l; ++i) {
    if (hasOwnProperty(value, String(i))) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          String(i), true));
    } else {
      output.push('');
    }
  }
  keys.forEach(function(key) {
    if (!key.match(/^\d+$/)) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          key, true));
    }
  });
  return output;
}


function formatProperty(ctx, value, recurseTimes, visibleKeys, key, array) {
  var name, str, desc;
  desc = Object.getOwnPropertyDescriptor(value, key) || { value: value[key] };
  if (desc.get) {
    if (desc.set) {
      str = ctx.stylize('[Getter/Setter]', 'special');
    } else {
      str = ctx.stylize('[Getter]', 'special');
    }
  } else {
    if (desc.set) {
      str = ctx.stylize('[Setter]', 'special');
    }
  }
  if (!hasOwnProperty(visibleKeys, key)) {
    name = '[' + key + ']';
  }
  if (!str) {
    if (ctx.seen.indexOf(desc.value) < 0) {
      if (isNull(recurseTimes)) {
        str = formatValue(ctx, desc.value, null);
      } else {
        str = formatValue(ctx, desc.value, recurseTimes - 1);
      }
      if (str.indexOf('\n') > -1) {
        if (array) {
          str = str.split('\n').map(function(line) {
            return '  ' + line;
          }).join('\n').substr(2);
        } else {
          str = '\n' + str.split('\n').map(function(line) {
            return '   ' + line;
          }).join('\n');
        }
      }
    } else {
      str = ctx.stylize('[Circular]', 'special');
    }
  }
  if (isUndefined(name)) {
    if (array && key.match(/^\d+$/)) {
      return str;
    }
    name = JSON.stringify('' + key);
    if (name.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)) {
      name = name.substr(1, name.length - 2);
      name = ctx.stylize(name, 'name');
    } else {
      name = name.replace(/'/g, "\\'")
                 .replace(/\\"/g, '"')
                 .replace(/(^"|"$)/g, "'");
      name = ctx.stylize(name, 'string');
    }
  }

  return name + ': ' + str;
}


function reduceToSingleString(output, base, braces) {
  var numLinesEst = 0;
  var length = output.reduce(function(prev, cur) {
    numLinesEst++;
    if (cur.indexOf('\n') >= 0) numLinesEst++;
    return prev + cur.replace(/\u001b\[\d\d?m/g, '').length + 1;
  }, 0);

  if (length > 60) {
    return braces[0] +
           (base === '' ? '' : base + '\n ') +
           ' ' +
           output.join(',\n  ') +
           ' ' +
           braces[1];
  }

  return braces[0] + base + ' ' + output.join(', ') + ' ' + braces[1];
}


// NOTE: These type checking functions intentionally don't use `instanceof`
// because it is fragile and can be easily faked with `Object.create()`.
function isArray(ar) {
  return Array.isArray(ar);
}
exports.isArray = isArray;

function isBoolean(arg) {
  return typeof arg === 'boolean';
}
exports.isBoolean = isBoolean;

function isNull(arg) {
  return arg === null;
}
exports.isNull = isNull;

function isNullOrUndefined(arg) {
  return arg == null;
}
exports.isNullOrUndefined = isNullOrUndefined;

function isNumber(arg) {
  return typeof arg === 'number';
}
exports.isNumber = isNumber;

function isString(arg) {
  return typeof arg === 'string';
}
exports.isString = isString;

function isSymbol(arg) {
  return typeof arg === 'symbol';
}
exports.isSymbol = isSymbol;

function isUndefined(arg) {
  return arg === void 0;
}
exports.isUndefined = isUndefined;

function isRegExp(re) {
  return isObject(re) && objectToString(re) === '[object RegExp]';
}
exports.isRegExp = isRegExp;

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}
exports.isObject = isObject;

function isDate(d) {
  return isObject(d) && objectToString(d) === '[object Date]';
}
exports.isDate = isDate;

function isError(e) {
  return isObject(e) &&
      (objectToString(e) === '[object Error]' || e instanceof Error);
}
exports.isError = isError;

function isFunction(arg) {
  return typeof arg === 'function';
}
exports.isFunction = isFunction;

function isPrimitive(arg) {
  return arg === null ||
         typeof arg === 'boolean' ||
         typeof arg === 'number' ||
         typeof arg === 'string' ||
         typeof arg === 'symbol' ||  // ES6 symbol
         typeof arg === 'undefined';
}
exports.isPrimitive = isPrimitive;

exports.isBuffer = require('./support/isBuffer');

function objectToString(o) {
  return Object.prototype.toString.call(o);
}


function pad(n) {
  return n < 10 ? '0' + n.toString(10) : n.toString(10);
}


var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
              'Oct', 'Nov', 'Dec'];

// 26 Feb 16:19:34
function timestamp() {
  var d = new Date();
  var time = [pad(d.getHours()),
              pad(d.getMinutes()),
              pad(d.getSeconds())].join(':');
  return [d.getDate(), months[d.getMonth()], time].join(' ');
}


// log is just a thin wrapper to console.log that prepends a timestamp
exports.log = function() {
  console.log('%s - %s', timestamp(), exports.format.apply(exports, arguments));
};


/**
 * Inherit the prototype methods from one constructor into another.
 *
 * The Function.prototype.inherits from lang.js rewritten as a standalone
 * function (not on Function.prototype). NOTE: If this file is to be loaded
 * during bootstrapping this function needs to be rewritten using some native
 * functions as prototype setup using normal JavaScript does not work as
 * expected during bootstrapping (see mirror.js in r114903).
 *
 * @param {function} ctor Constructor function which needs to inherit the
 *     prototype.
 * @param {function} superCtor Constructor function to inherit prototype from.
 */
exports.inherits = require('inherits');

exports._extend = function(origin, add) {
  // Don't do anything if add isn't an object
  if (!add || !isObject(add)) return origin;

  var keys = Object.keys(add);
  var i = keys.length;
  while (i--) {
    origin[keys[i]] = add[keys[i]];
  }
  return origin;
};

function hasOwnProperty(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
}

}).call(this,require('_process'),typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
//# sourceMappingURL=data:application/json;charset:utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy91dGlsL3V0aWwuanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IjtBQUFBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0EiLCJmaWxlIjoiZ2VuZXJhdGVkLmpzIiwic291cmNlUm9vdCI6IiIsInNvdXJjZXNDb250ZW50IjpbIi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG52YXIgZm9ybWF0UmVnRXhwID0gLyVbc2RqJV0vZztcbmV4cG9ydHMuZm9ybWF0ID0gZnVuY3Rpb24oZikge1xuICBpZiAoIWlzU3RyaW5nKGYpKSB7XG4gICAgdmFyIG9iamVjdHMgPSBbXTtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGFyZ3VtZW50cy5sZW5ndGg7IGkrKykge1xuICAgICAgb2JqZWN0cy5wdXNoKGluc3BlY3QoYXJndW1lbnRzW2ldKSk7XG4gICAgfVxuICAgIHJldHVybiBvYmplY3RzLmpvaW4oJyAnKTtcbiAgfVxuXG4gIHZhciBpID0gMTtcbiAgdmFyIGFyZ3MgPSBhcmd1bWVudHM7XG4gIHZhciBsZW4gPSBhcmdzLmxlbmd0aDtcbiAgdmFyIHN0ciA9IFN0cmluZyhmKS5yZXBsYWNlKGZvcm1hdFJlZ0V4cCwgZnVuY3Rpb24oeCkge1xuICAgIGlmICh4ID09PSAnJSUnKSByZXR1cm4gJyUnO1xuICAgIGlmIChpID49IGxlbikgcmV0dXJuIHg7XG4gICAgc3dpdGNoICh4KSB7XG4gICAgICBjYXNlICclcyc6IHJldHVybiBTdHJpbmcoYXJnc1tpKytdKTtcbiAgICAgIGNhc2UgJyVkJzogcmV0dXJuIE51bWJlcihhcmdzW2krK10pO1xuICAgICAgY2FzZSAnJWonOlxuICAgICAgICB0cnkge1xuICAgICAgICAgIHJldHVybiBKU09OLnN0cmluZ2lmeShhcmdzW2krK10pO1xuICAgICAgICB9IGNhdGNoIChfKSB7XG4gICAgICAgICAgcmV0dXJuICdbQ2lyY3VsYXJdJztcbiAgICAgICAgfVxuICAgICAgZGVmYXVsdDpcbiAgICAgICAgcmV0dXJuIHg7XG4gICAgfVxuICB9KTtcbiAgZm9yICh2YXIgeCA9IGFyZ3NbaV07IGkgPCBsZW47IHggPSBhcmdzWysraV0pIHtcbiAgICBpZiAoaXNOdWxsKHgpIHx8ICFpc09iamVjdCh4KSkge1xuICAgICAgc3RyICs9ICcgJyArIHg7XG4gICAgfSBlbHNlIHtcbiAgICAgIHN0ciArPSAnICcgKyBpbnNwZWN0KHgpO1xuICAgIH1cbiAgfVxuICByZXR1cm4gc3RyO1xufTtcblxuXG4vLyBNYXJrIHRoYXQgYSBtZXRob2Qgc2hvdWxkIG5vdCBiZSB1c2VkLlxuLy8gUmV0dXJucyBhIG1vZGlmaWVkIGZ1bmN0aW9uIHdoaWNoIHdhcm5zIG9uY2UgYnkgZGVmYXVsdC5cbi8vIElmIC0tbm8tZGVwcmVjYXRpb24gaXMgc2V0LCB0aGVuIGl0IGlzIGEgbm8tb3AuXG5leHBvcnRzLmRlcHJlY2F0ZSA9IGZ1bmN0aW9uKGZuLCBtc2cpIHtcbiAgLy8gQWxsb3cgZm9yIGRlcHJlY2F0aW5nIHRoaW5ncyBpbiB0aGUgcHJvY2VzcyBvZiBzdGFydGluZyB1cC5cbiAgaWYgKGlzVW5kZWZpbmVkKGdsb2JhbC5wcm9jZXNzKSkge1xuICAgIHJldHVybiBmdW5jdGlvbigpIHtcbiAgICAgIHJldHVybiBleHBvcnRzLmRlcHJlY2F0ZShmbiwgbXNnKS5hcHBseSh0aGlzLCBhcmd1bWVudHMpO1xuICAgIH07XG4gIH1cblxuICBpZiAocHJvY2Vzcy5ub0RlcHJlY2F0aW9uID09PSB0cnVlKSB7XG4gICAgcmV0dXJuIGZuO1xuICB9XG5cbiAgdmFyIHdhcm5lZCA9IGZhbHNlO1xuICBmdW5jdGlvbiBkZXByZWNhdGVkKCkge1xuICAgIGlmICghd2FybmVkKSB7XG4gICAgICBpZiAocHJvY2Vzcy50aHJvd0RlcHJlY2F0aW9uKSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcihtc2cpO1xuICAgICAgfSBlbHNlIGlmIChwcm9jZXNzLnRyYWNlRGVwcmVjYXRpb24pIHtcbiAgICAgICAgY29uc29sZS50cmFjZShtc2cpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgY29uc29sZS5lcnJvcihtc2cpO1xuICAgICAgfVxuICAgICAgd2FybmVkID0gdHJ1ZTtcbiAgICB9XG4gICAgcmV0dXJuIGZuLmFwcGx5KHRoaXMsIGFyZ3VtZW50cyk7XG4gIH1cblxuICByZXR1cm4gZGVwcmVjYXRlZDtcbn07XG5cblxudmFyIGRlYnVncyA9IHt9O1xudmFyIGRlYnVnRW52aXJvbjtcbmV4cG9ydHMuZGVidWdsb2cgPSBmdW5jdGlvbihzZXQpIHtcbiAgaWYgKGlzVW5kZWZpbmVkKGRlYnVnRW52aXJvbikpXG4gICAgZGVidWdFbnZpcm9uID0gcHJvY2Vzcy5lbnYuTk9ERV9ERUJVRyB8fCAnJztcbiAgc2V0ID0gc2V0LnRvVXBwZXJDYXNlKCk7XG4gIGlmICghZGVidWdzW3NldF0pIHtcbiAgICBpZiAobmV3IFJlZ0V4cCgnXFxcXGInICsgc2V0ICsgJ1xcXFxiJywgJ2knKS50ZXN0KGRlYnVnRW52aXJvbikpIHtcbiAgICAgIHZhciBwaWQgPSBwcm9jZXNzLnBpZDtcbiAgICAgIGRlYnVnc1tzZXRdID0gZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBtc2cgPSBleHBvcnRzLmZvcm1hdC5hcHBseShleHBvcnRzLCBhcmd1bWVudHMpO1xuICAgICAgICBjb25zb2xlLmVycm9yKCclcyAlZDogJXMnLCBzZXQsIHBpZCwgbXNnKTtcbiAgICAgIH07XG4gICAgfSBlbHNlIHtcbiAgICAgIGRlYnVnc1tzZXRdID0gZnVuY3Rpb24oKSB7fTtcbiAgICB9XG4gIH1cbiAgcmV0dXJuIGRlYnVnc1tzZXRdO1xufTtcblxuXG4vKipcbiAqIEVjaG9zIHRoZSB2YWx1ZSBvZiBhIHZhbHVlLiBUcnlzIHRvIHByaW50IHRoZSB2YWx1ZSBvdXRcbiAqIGluIHRoZSBiZXN0IHdheSBwb3NzaWJsZSBnaXZlbiB0aGUgZGlmZmVyZW50IHR5cGVzLlxuICpcbiAqIEBwYXJhbSB7T2JqZWN0fSBvYmogVGhlIG9iamVjdCB0byBwcmludCBvdXQuXG4gKiBAcGFyYW0ge09iamVjdH0gb3B0cyBPcHRpb25hbCBvcHRpb25zIG9iamVjdCB0aGF0IGFsdGVycyB0aGUgb3V0cHV0LlxuICovXG4vKiBsZWdhY3k6IG9iaiwgc2hvd0hpZGRlbiwgZGVwdGgsIGNvbG9ycyovXG5mdW5jdGlvbiBpbnNwZWN0KG9iaiwgb3B0cykge1xuICAvLyBkZWZhdWx0IG9wdGlvbnNcbiAgdmFyIGN0eCA9IHtcbiAgICBzZWVuOiBbXSxcbiAgICBzdHlsaXplOiBzdHlsaXplTm9Db2xvclxuICB9O1xuICAvLyBsZWdhY3kuLi5cbiAgaWYgKGFyZ3VtZW50cy5sZW5ndGggPj0gMykgY3R4LmRlcHRoID0gYXJndW1lbnRzWzJdO1xuICBpZiAoYXJndW1lbnRzLmxlbmd0aCA+PSA0KSBjdHguY29sb3JzID0gYXJndW1lbnRzWzNdO1xuICBpZiAoaXNCb29sZWFuKG9wdHMpKSB7XG4gICAgLy8gbGVnYWN5Li4uXG4gICAgY3R4LnNob3dIaWRkZW4gPSBvcHRzO1xuICB9IGVsc2UgaWYgKG9wdHMpIHtcbiAgICAvLyBnb3QgYW4gXCJvcHRpb25zXCIgb2JqZWN0XG4gICAgZXhwb3J0cy5fZXh0ZW5kKGN0eCwgb3B0cyk7XG4gIH1cbiAgLy8gc2V0IGRlZmF1bHQgb3B0aW9uc1xuICBpZiAoaXNVbmRlZmluZWQoY3R4LnNob3dIaWRkZW4pKSBjdHguc2hvd0hpZGRlbiA9IGZhbHNlO1xuICBpZiAoaXNVbmRlZmluZWQoY3R4LmRlcHRoKSkgY3R4LmRlcHRoID0gMjtcbiAgaWYgKGlzVW5kZWZpbmVkKGN0eC5jb2xvcnMpKSBjdHguY29sb3JzID0gZmFsc2U7XG4gIGlmIChpc1VuZGVmaW5lZChjdHguY3VzdG9tSW5zcGVjdCkpIGN0eC5jdXN0b21JbnNwZWN0ID0gdHJ1ZTtcbiAgaWYgKGN0eC5jb2xvcnMpIGN0eC5zdHlsaXplID0gc3R5bGl6ZVdpdGhDb2xvcjtcbiAgcmV0dXJuIGZvcm1hdFZhbHVlKGN0eCwgb2JqLCBjdHguZGVwdGgpO1xufVxuZXhwb3J0cy5pbnNwZWN0ID0gaW5zcGVjdDtcblxuXG4vLyBodHRwOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL0FOU0lfZXNjYXBlX2NvZGUjZ3JhcGhpY3Ncbmluc3BlY3QuY29sb3JzID0ge1xuICAnYm9sZCcgOiBbMSwgMjJdLFxuICAnaXRhbGljJyA6IFszLCAyM10sXG4gICd1bmRlcmxpbmUnIDogWzQsIDI0XSxcbiAgJ2ludmVyc2UnIDogWzcsIDI3XSxcbiAgJ3doaXRlJyA6IFszNywgMzldLFxuICAnZ3JleScgOiBbOTAsIDM5XSxcbiAgJ2JsYWNrJyA6IFszMCwgMzldLFxuICAnYmx1ZScgOiBbMzQsIDM5XSxcbiAgJ2N5YW4nIDogWzM2LCAzOV0sXG4gICdncmVlbicgOiBbMzIsIDM5XSxcbiAgJ21hZ2VudGEnIDogWzM1LCAzOV0sXG4gICdyZWQnIDogWzMxLCAzOV0sXG4gICd5ZWxsb3cnIDogWzMzLCAzOV1cbn07XG5cbi8vIERvbid0IHVzZSAnYmx1ZScgbm90IHZpc2libGUgb24gY21kLmV4ZVxuaW5zcGVjdC5zdHlsZXMgPSB7XG4gICdzcGVjaWFsJzogJ2N5YW4nLFxuICAnbnVtYmVyJzogJ3llbGxvdycsXG4gICdib29sZWFuJzogJ3llbGxvdycsXG4gICd1bmRlZmluZWQnOiAnZ3JleScsXG4gICdudWxsJzogJ2JvbGQnLFxuICAnc3RyaW5nJzogJ2dyZWVuJyxcbiAgJ2RhdGUnOiAnbWFnZW50YScsXG4gIC8vIFwibmFtZVwiOiBpbnRlbnRpb25hbGx5IG5vdCBzdHlsaW5nXG4gICdyZWdleHAnOiAncmVkJ1xufTtcblxuXG5mdW5jdGlvbiBzdHlsaXplV2l0aENvbG9yKHN0ciwgc3R5bGVUeXBlKSB7XG4gIHZhciBzdHlsZSA9IGluc3BlY3Quc3R5bGVzW3N0eWxlVHlwZV07XG5cbiAgaWYgKHN0eWxlKSB7XG4gICAgcmV0dXJuICdcXHUwMDFiWycgKyBpbnNwZWN0LmNvbG9yc1tzdHlsZV1bMF0gKyAnbScgKyBzdHIgK1xuICAgICAgICAgICAnXFx1MDAxYlsnICsgaW5zcGVjdC5jb2xvcnNbc3R5bGVdWzFdICsgJ20nO1xuICB9IGVsc2Uge1xuICAgIHJldHVybiBzdHI7XG4gIH1cbn1cblxuXG5mdW5jdGlvbiBzdHlsaXplTm9Db2xvcihzdHIsIHN0eWxlVHlwZSkge1xuICByZXR1cm4gc3RyO1xufVxuXG5cbmZ1bmN0aW9uIGFycmF5VG9IYXNoKGFycmF5KSB7XG4gIHZhciBoYXNoID0ge307XG5cbiAgYXJyYXkuZm9yRWFjaChmdW5jdGlvbih2YWwsIGlkeCkge1xuICAgIGhhc2hbdmFsXSA9IHRydWU7XG4gIH0pO1xuXG4gIHJldHVybiBoYXNoO1xufVxuXG5cbmZ1bmN0aW9uIGZvcm1hdFZhbHVlKGN0eCwgdmFsdWUsIHJlY3Vyc2VUaW1lcykge1xuICAvLyBQcm92aWRlIGEgaG9vayBmb3IgdXNlci1zcGVjaWZpZWQgaW5zcGVjdCBmdW5jdGlvbnMuXG4gIC8vIENoZWNrIHRoYXQgdmFsdWUgaXMgYW4gb2JqZWN0IHdpdGggYW4gaW5zcGVjdCBmdW5jdGlvbiBvbiBpdFxuICBpZiAoY3R4LmN1c3RvbUluc3BlY3QgJiZcbiAgICAgIHZhbHVlICYmXG4gICAgICBpc0Z1bmN0aW9uKHZhbHVlLmluc3BlY3QpICYmXG4gICAgICAvLyBGaWx0ZXIgb3V0IHRoZSB1dGlsIG1vZHVsZSwgaXQncyBpbnNwZWN0IGZ1bmN0aW9uIGlzIHNwZWNpYWxcbiAgICAgIHZhbHVlLmluc3BlY3QgIT09IGV4cG9ydHMuaW5zcGVjdCAmJlxuICAgICAgLy8gQWxzbyBmaWx0ZXIgb3V0IGFueSBwcm90b3R5cGUgb2JqZWN0cyB1c2luZyB0aGUgY2lyY3VsYXIgY2hlY2suXG4gICAgICAhKHZhbHVlLmNvbnN0cnVjdG9yICYmIHZhbHVlLmNvbnN0cnVjdG9yLnByb3RvdHlwZSA9PT0gdmFsdWUpKSB7XG4gICAgdmFyIHJldCA9IHZhbHVlLmluc3BlY3QocmVjdXJzZVRpbWVzLCBjdHgpO1xuICAgIGlmICghaXNTdHJpbmcocmV0KSkge1xuICAgICAgcmV0ID0gZm9ybWF0VmFsdWUoY3R4LCByZXQsIHJlY3Vyc2VUaW1lcyk7XG4gICAgfVxuICAgIHJldHVybiByZXQ7XG4gIH1cblxuICAvLyBQcmltaXRpdmUgdHlwZXMgY2Fubm90IGhhdmUgcHJvcGVydGllc1xuICB2YXIgcHJpbWl0aXZlID0gZm9ybWF0UHJpbWl0aXZlKGN0eCwgdmFsdWUpO1xuICBpZiAocHJpbWl0aXZlKSB7XG4gICAgcmV0dXJuIHByaW1pdGl2ZTtcbiAgfVxuXG4gIC8vIExvb2sgdXAgdGhlIGtleXMgb2YgdGhlIG9iamVjdC5cbiAgdmFyIGtleXMgPSBPYmplY3Qua2V5cyh2YWx1ZSk7XG4gIHZhciB2aXNpYmxlS2V5cyA9IGFycmF5VG9IYXNoKGtleXMpO1xuXG4gIGlmIChjdHguc2hvd0hpZGRlbikge1xuICAgIGtleXMgPSBPYmplY3QuZ2V0T3duUHJvcGVydHlOYW1lcyh2YWx1ZSk7XG4gIH1cblxuICAvLyBJRSBkb2Vzbid0IG1ha2UgZXJyb3IgZmllbGRzIG5vbi1lbnVtZXJhYmxlXG4gIC8vIGh0dHA6Ly9tc2RuLm1pY3Jvc29mdC5jb20vZW4tdXMvbGlicmFyeS9pZS9kd3c1MnNidCh2PXZzLjk0KS5hc3B4XG4gIGlmIChpc0Vycm9yKHZhbHVlKVxuICAgICAgJiYgKGtleXMuaW5kZXhPZignbWVzc2FnZScpID49IDAgfHwga2V5cy5pbmRleE9mKCdkZXNjcmlwdGlvbicpID49IDApKSB7XG4gICAgcmV0dXJuIGZvcm1hdEVycm9yKHZhbHVlKTtcbiAgfVxuXG4gIC8vIFNvbWUgdHlwZSBvZiBvYmplY3Qgd2l0aG91dCBwcm9wZXJ0aWVzIGNhbiBiZSBzaG9ydGN1dHRlZC5cbiAgaWYgKGtleXMubGVuZ3RoID09PSAwKSB7XG4gICAgaWYgKGlzRnVuY3Rpb24odmFsdWUpKSB7XG4gICAgICB2YXIgbmFtZSA9IHZhbHVlLm5hbWUgPyAnOiAnICsgdmFsdWUubmFtZSA6ICcnO1xuICAgICAgcmV0dXJuIGN0eC5zdHlsaXplKCdbRnVuY3Rpb24nICsgbmFtZSArICddJywgJ3NwZWNpYWwnKTtcbiAgICB9XG4gICAgaWYgKGlzUmVnRXhwKHZhbHVlKSkge1xuICAgICAgcmV0dXJuIGN0eC5zdHlsaXplKFJlZ0V4cC5wcm90b3R5cGUudG9TdHJpbmcuY2FsbCh2YWx1ZSksICdyZWdleHAnKTtcbiAgICB9XG4gICAgaWYgKGlzRGF0ZSh2YWx1ZSkpIHtcbiAgICAgIHJldHVybiBjdHguc3R5bGl6ZShEYXRlLnByb3RvdHlwZS50b1N0cmluZy5jYWxsKHZhbHVlKSwgJ2RhdGUnKTtcbiAgICB9XG4gICAgaWYgKGlzRXJyb3IodmFsdWUpKSB7XG4gICAgICByZXR1cm4gZm9ybWF0RXJyb3IodmFsdWUpO1xuICAgIH1cbiAgfVxuXG4gIHZhciBiYXNlID0gJycsIGFycmF5ID0gZmFsc2UsIGJyYWNlcyA9IFsneycsICd9J107XG5cbiAgLy8gTWFrZSBBcnJheSBzYXkgdGhhdCB0aGV5IGFyZSBBcnJheVxuICBpZiAoaXNBcnJheSh2YWx1ZSkpIHtcbiAgICBhcnJheSA9IHRydWU7XG4gICAgYnJhY2VzID0gWydbJywgJ10nXTtcbiAgfVxuXG4gIC8vIE1ha2UgZnVuY3Rpb25zIHNheSB0aGF0IHRoZXkgYXJlIGZ1bmN0aW9uc1xuICBpZiAoaXNGdW5jdGlvbih2YWx1ZSkpIHtcbiAgICB2YXIgbiA9IHZhbHVlLm5hbWUgPyAnOiAnICsgdmFsdWUubmFtZSA6ICcnO1xuICAgIGJhc2UgPSAnIFtGdW5jdGlvbicgKyBuICsgJ10nO1xuICB9XG5cbiAgLy8gTWFrZSBSZWdFeHBzIHNheSB0aGF0IHRoZXkgYXJlIFJlZ0V4cHNcbiAgaWYgKGlzUmVnRXhwKHZhbHVlKSkge1xuICAgIGJhc2UgPSAnICcgKyBSZWdFeHAucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwodmFsdWUpO1xuICB9XG5cbiAgLy8gTWFrZSBkYXRlcyB3aXRoIHByb3BlcnRpZXMgZmlyc3Qgc2F5IHRoZSBkYXRlXG4gIGlmIChpc0RhdGUodmFsdWUpKSB7XG4gICAgYmFzZSA9ICcgJyArIERhdGUucHJvdG90eXBlLnRvVVRDU3RyaW5nLmNhbGwodmFsdWUpO1xuICB9XG5cbiAgLy8gTWFrZSBlcnJvciB3aXRoIG1lc3NhZ2UgZmlyc3Qgc2F5IHRoZSBlcnJvclxuICBpZiAoaXNFcnJvcih2YWx1ZSkpIHtcbiAgICBiYXNlID0gJyAnICsgZm9ybWF0RXJyb3IodmFsdWUpO1xuICB9XG5cbiAgaWYgKGtleXMubGVuZ3RoID09PSAwICYmICghYXJyYXkgfHwgdmFsdWUubGVuZ3RoID09IDApKSB7XG4gICAgcmV0dXJuIGJyYWNlc1swXSArIGJhc2UgKyBicmFjZXNbMV07XG4gIH1cblxuICBpZiAocmVjdXJzZVRpbWVzIDwgMCkge1xuICAgIGlmIChpc1JlZ0V4cCh2YWx1ZSkpIHtcbiAgICAgIHJldHVybiBjdHguc3R5bGl6ZShSZWdFeHAucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwodmFsdWUpLCAncmVnZXhwJyk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHJldHVybiBjdHguc3R5bGl6ZSgnW09iamVjdF0nLCAnc3BlY2lhbCcpO1xuICAgIH1cbiAgfVxuXG4gIGN0eC5zZWVuLnB1c2godmFsdWUpO1xuXG4gIHZhciBvdXRwdXQ7XG4gIGlmIChhcnJheSkge1xuICAgIG91dHB1dCA9IGZvcm1hdEFycmF5KGN0eCwgdmFsdWUsIHJlY3Vyc2VUaW1lcywgdmlzaWJsZUtleXMsIGtleXMpO1xuICB9IGVsc2Uge1xuICAgIG91dHB1dCA9IGtleXMubWFwKGZ1bmN0aW9uKGtleSkge1xuICAgICAgcmV0dXJuIGZvcm1hdFByb3BlcnR5KGN0eCwgdmFsdWUsIHJlY3Vyc2VUaW1lcywgdmlzaWJsZUtleXMsIGtleSwgYXJyYXkpO1xuICAgIH0pO1xuICB9XG5cbiAgY3R4LnNlZW4ucG9wKCk7XG5cbiAgcmV0dXJuIHJlZHVjZVRvU2luZ2xlU3RyaW5nKG91dHB1dCwgYmFzZSwgYnJhY2VzKTtcbn1cblxuXG5mdW5jdGlvbiBmb3JtYXRQcmltaXRpdmUoY3R4LCB2YWx1ZSkge1xuICBpZiAoaXNVbmRlZmluZWQodmFsdWUpKVxuICAgIHJldHVybiBjdHguc3R5bGl6ZSgndW5kZWZpbmVkJywgJ3VuZGVmaW5lZCcpO1xuICBpZiAoaXNTdHJpbmcodmFsdWUpKSB7XG4gICAgdmFyIHNpbXBsZSA9ICdcXCcnICsgSlNPTi5zdHJpbmdpZnkodmFsdWUpLnJlcGxhY2UoL15cInxcIiQvZywgJycpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAucmVwbGFjZSgvJy9nLCBcIlxcXFwnXCIpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAucmVwbGFjZSgvXFxcXFwiL2csICdcIicpICsgJ1xcJyc7XG4gICAgcmV0dXJuIGN0eC5zdHlsaXplKHNpbXBsZSwgJ3N0cmluZycpO1xuICB9XG4gIGlmIChpc051bWJlcih2YWx1ZSkpXG4gICAgcmV0dXJuIGN0eC5zdHlsaXplKCcnICsgdmFsdWUsICdudW1iZXInKTtcbiAgaWYgKGlzQm9vbGVhbih2YWx1ZSkpXG4gICAgcmV0dXJuIGN0eC5zdHlsaXplKCcnICsgdmFsdWUsICdib29sZWFuJyk7XG4gIC8vIEZvciBzb21lIHJlYXNvbiB0eXBlb2YgbnVsbCBpcyBcIm9iamVjdFwiLCBzbyBzcGVjaWFsIGNhc2UgaGVyZS5cbiAgaWYgKGlzTnVsbCh2YWx1ZSkpXG4gICAgcmV0dXJuIGN0eC5zdHlsaXplKCdudWxsJywgJ251bGwnKTtcbn1cblxuXG5mdW5jdGlvbiBmb3JtYXRFcnJvcih2YWx1ZSkge1xuICByZXR1cm4gJ1snICsgRXJyb3IucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwodmFsdWUpICsgJ10nO1xufVxuXG5cbmZ1bmN0aW9uIGZvcm1hdEFycmF5KGN0eCwgdmFsdWUsIHJlY3Vyc2VUaW1lcywgdmlzaWJsZUtleXMsIGtleXMpIHtcbiAgdmFyIG91dHB1dCA9IFtdO1xuICBmb3IgKHZhciBpID0gMCwgbCA9IHZhbHVlLmxlbmd0aDsgaSA8IGw7ICsraSkge1xuICAgIGlmIChoYXNPd25Qcm9wZXJ0eSh2YWx1ZSwgU3RyaW5nKGkpKSkge1xuICAgICAgb3V0cHV0LnB1c2goZm9ybWF0UHJvcGVydHkoY3R4LCB2YWx1ZSwgcmVjdXJzZVRpbWVzLCB2aXNpYmxlS2V5cyxcbiAgICAgICAgICBTdHJpbmcoaSksIHRydWUpKTtcbiAgICB9IGVsc2Uge1xuICAgICAgb3V0cHV0LnB1c2goJycpO1xuICAgIH1cbiAgfVxuICBrZXlzLmZvckVhY2goZnVuY3Rpb24oa2V5KSB7XG4gICAgaWYgKCFrZXkubWF0Y2goL15cXGQrJC8pKSB7XG4gICAgICBvdXRwdXQucHVzaChmb3JtYXRQcm9wZXJ0eShjdHgsIHZhbHVlLCByZWN1cnNlVGltZXMsIHZpc2libGVLZXlzLFxuICAgICAgICAgIGtleSwgdHJ1ZSkpO1xuICAgIH1cbiAgfSk7XG4gIHJldHVybiBvdXRwdXQ7XG59XG5cblxuZnVuY3Rpb24gZm9ybWF0UHJvcGVydHkoY3R4LCB2YWx1ZSwgcmVjdXJzZVRpbWVzLCB2aXNpYmxlS2V5cywga2V5LCBhcnJheSkge1xuICB2YXIgbmFtZSwgc3RyLCBkZXNjO1xuICBkZXNjID0gT2JqZWN0LmdldE93blByb3BlcnR5RGVzY3JpcHRvcih2YWx1ZSwga2V5KSB8fCB7IHZhbHVlOiB2YWx1ZVtrZXldIH07XG4gIGlmIChkZXNjLmdldCkge1xuICAgIGlmIChkZXNjLnNldCkge1xuICAgICAgc3RyID0gY3R4LnN0eWxpemUoJ1tHZXR0ZXIvU2V0dGVyXScsICdzcGVjaWFsJyk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHN0ciA9IGN0eC5zdHlsaXplKCdbR2V0dGVyXScsICdzcGVjaWFsJyk7XG4gICAgfVxuICB9IGVsc2Uge1xuICAgIGlmIChkZXNjLnNldCkge1xuICAgICAgc3RyID0gY3R4LnN0eWxpemUoJ1tTZXR0ZXJdJywgJ3NwZWNpYWwnKTtcbiAgICB9XG4gIH1cbiAgaWYgKCFoYXNPd25Qcm9wZXJ0eSh2aXNpYmxlS2V5cywga2V5KSkge1xuICAgIG5hbWUgPSAnWycgKyBrZXkgKyAnXSc7XG4gIH1cbiAgaWYgKCFzdHIpIHtcbiAgICBpZiAoY3R4LnNlZW4uaW5kZXhPZihkZXNjLnZhbHVlKSA8IDApIHtcbiAgICAgIGlmIChpc051bGwocmVjdXJzZVRpbWVzKSkge1xuICAgICAgICBzdHIgPSBmb3JtYXRWYWx1ZShjdHgsIGRlc2MudmFsdWUsIG51bGwpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgc3RyID0gZm9ybWF0VmFsdWUoY3R4LCBkZXNjLnZhbHVlLCByZWN1cnNlVGltZXMgLSAxKTtcbiAgICAgIH1cbiAgICAgIGlmIChzdHIuaW5kZXhPZignXFxuJykgPiAtMSkge1xuICAgICAgICBpZiAoYXJyYXkpIHtcbiAgICAgICAgICBzdHIgPSBzdHIuc3BsaXQoJ1xcbicpLm1hcChmdW5jdGlvbihsaW5lKSB7XG4gICAgICAgICAgICByZXR1cm4gJyAgJyArIGxpbmU7XG4gICAgICAgICAgfSkuam9pbignXFxuJykuc3Vic3RyKDIpO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIHN0ciA9ICdcXG4nICsgc3RyLnNwbGl0KCdcXG4nKS5tYXAoZnVuY3Rpb24obGluZSkge1xuICAgICAgICAgICAgcmV0dXJuICcgICAnICsgbGluZTtcbiAgICAgICAgICB9KS5qb2luKCdcXG4nKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBzdHIgPSBjdHguc3R5bGl6ZSgnW0NpcmN1bGFyXScsICdzcGVjaWFsJyk7XG4gICAgfVxuICB9XG4gIGlmIChpc1VuZGVmaW5lZChuYW1lKSkge1xuICAgIGlmIChhcnJheSAmJiBrZXkubWF0Y2goL15cXGQrJC8pKSB7XG4gICAgICByZXR1cm4gc3RyO1xuICAgIH1cbiAgICBuYW1lID0gSlNPTi5zdHJpbmdpZnkoJycgKyBrZXkpO1xuICAgIGlmIChuYW1lLm1hdGNoKC9eXCIoW2EtekEtWl9dW2EtekEtWl8wLTldKilcIiQvKSkge1xuICAgICAgbmFtZSA9IG5hbWUuc3Vic3RyKDEsIG5hbWUubGVuZ3RoIC0gMik7XG4gICAgICBuYW1lID0gY3R4LnN0eWxpemUobmFtZSwgJ25hbWUnKTtcbiAgICB9IGVsc2Uge1xuICAgICAgbmFtZSA9IG5hbWUucmVwbGFjZSgvJy9nLCBcIlxcXFwnXCIpXG4gICAgICAgICAgICAgICAgIC5yZXBsYWNlKC9cXFxcXCIvZywgJ1wiJylcbiAgICAgICAgICAgICAgICAgLnJlcGxhY2UoLyheXCJ8XCIkKS9nLCBcIidcIik7XG4gICAgICBuYW1lID0gY3R4LnN0eWxpemUobmFtZSwgJ3N0cmluZycpO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiBuYW1lICsgJzogJyArIHN0cjtcbn1cblxuXG5mdW5jdGlvbiByZWR1Y2VUb1NpbmdsZVN0cmluZyhvdXRwdXQsIGJhc2UsIGJyYWNlcykge1xuICB2YXIgbnVtTGluZXNFc3QgPSAwO1xuICB2YXIgbGVuZ3RoID0gb3V0cHV0LnJlZHVjZShmdW5jdGlvbihwcmV2LCBjdXIpIHtcbiAgICBudW1MaW5lc0VzdCsrO1xuICAgIGlmIChjdXIuaW5kZXhPZignXFxuJykgPj0gMCkgbnVtTGluZXNFc3QrKztcbiAgICByZXR1cm4gcHJldiArIGN1ci5yZXBsYWNlKC9cXHUwMDFiXFxbXFxkXFxkP20vZywgJycpLmxlbmd0aCArIDE7XG4gIH0sIDApO1xuXG4gIGlmIChsZW5ndGggPiA2MCkge1xuICAgIHJldHVybiBicmFjZXNbMF0gK1xuICAgICAgICAgICAoYmFzZSA9PT0gJycgPyAnJyA6IGJhc2UgKyAnXFxuICcpICtcbiAgICAgICAgICAgJyAnICtcbiAgICAgICAgICAgb3V0cHV0LmpvaW4oJyxcXG4gICcpICtcbiAgICAgICAgICAgJyAnICtcbiAgICAgICAgICAgYnJhY2VzWzFdO1xuICB9XG5cbiAgcmV0dXJuIGJyYWNlc1swXSArIGJhc2UgKyAnICcgKyBvdXRwdXQuam9pbignLCAnKSArICcgJyArIGJyYWNlc1sxXTtcbn1cblxuXG4vLyBOT1RFOiBUaGVzZSB0eXBlIGNoZWNraW5nIGZ1bmN0aW9ucyBpbnRlbnRpb25hbGx5IGRvbid0IHVzZSBgaW5zdGFuY2VvZmBcbi8vIGJlY2F1c2UgaXQgaXMgZnJhZ2lsZSBhbmQgY2FuIGJlIGVhc2lseSBmYWtlZCB3aXRoIGBPYmplY3QuY3JlYXRlKClgLlxuZnVuY3Rpb24gaXNBcnJheShhcikge1xuICByZXR1cm4gQXJyYXkuaXNBcnJheShhcik7XG59XG5leHBvcnRzLmlzQXJyYXkgPSBpc0FycmF5O1xuXG5mdW5jdGlvbiBpc0Jvb2xlYW4oYXJnKSB7XG4gIHJldHVybiB0eXBlb2YgYXJnID09PSAnYm9vbGVhbic7XG59XG5leHBvcnRzLmlzQm9vbGVhbiA9IGlzQm9vbGVhbjtcblxuZnVuY3Rpb24gaXNOdWxsKGFyZykge1xuICByZXR1cm4gYXJnID09PSBudWxsO1xufVxuZXhwb3J0cy5pc051bGwgPSBpc051bGw7XG5cbmZ1bmN0aW9uIGlzTnVsbE9yVW5kZWZpbmVkKGFyZykge1xuICByZXR1cm4gYXJnID09IG51bGw7XG59XG5leHBvcnRzLmlzTnVsbE9yVW5kZWZpbmVkID0gaXNOdWxsT3JVbmRlZmluZWQ7XG5cbmZ1bmN0aW9uIGlzTnVtYmVyKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ251bWJlcic7XG59XG5leHBvcnRzLmlzTnVtYmVyID0gaXNOdW1iZXI7XG5cbmZ1bmN0aW9uIGlzU3RyaW5nKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ3N0cmluZyc7XG59XG5leHBvcnRzLmlzU3RyaW5nID0gaXNTdHJpbmc7XG5cbmZ1bmN0aW9uIGlzU3ltYm9sKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ3N5bWJvbCc7XG59XG5leHBvcnRzLmlzU3ltYm9sID0gaXNTeW1ib2w7XG5cbmZ1bmN0aW9uIGlzVW5kZWZpbmVkKGFyZykge1xuICByZXR1cm4gYXJnID09PSB2b2lkIDA7XG59XG5leHBvcnRzLmlzVW5kZWZpbmVkID0gaXNVbmRlZmluZWQ7XG5cbmZ1bmN0aW9uIGlzUmVnRXhwKHJlKSB7XG4gIHJldHVybiBpc09iamVjdChyZSkgJiYgb2JqZWN0VG9TdHJpbmcocmUpID09PSAnW29iamVjdCBSZWdFeHBdJztcbn1cbmV4cG9ydHMuaXNSZWdFeHAgPSBpc1JlZ0V4cDtcblxuZnVuY3Rpb24gaXNPYmplY3QoYXJnKSB7XG4gIHJldHVybiB0eXBlb2YgYXJnID09PSAnb2JqZWN0JyAmJiBhcmcgIT09IG51bGw7XG59XG5leHBvcnRzLmlzT2JqZWN0ID0gaXNPYmplY3Q7XG5cbmZ1bmN0aW9uIGlzRGF0ZShkKSB7XG4gIHJldHVybiBpc09iamVjdChkKSAmJiBvYmplY3RUb1N0cmluZyhkKSA9PT0gJ1tvYmplY3QgRGF0ZV0nO1xufVxuZXhwb3J0cy5pc0RhdGUgPSBpc0RhdGU7XG5cbmZ1bmN0aW9uIGlzRXJyb3IoZSkge1xuICByZXR1cm4gaXNPYmplY3QoZSkgJiZcbiAgICAgIChvYmplY3RUb1N0cmluZyhlKSA9PT0gJ1tvYmplY3QgRXJyb3JdJyB8fCBlIGluc3RhbmNlb2YgRXJyb3IpO1xufVxuZXhwb3J0cy5pc0Vycm9yID0gaXNFcnJvcjtcblxuZnVuY3Rpb24gaXNGdW5jdGlvbihhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09ICdmdW5jdGlvbic7XG59XG5leHBvcnRzLmlzRnVuY3Rpb24gPSBpc0Z1bmN0aW9uO1xuXG5mdW5jdGlvbiBpc1ByaW1pdGl2ZShhcmcpIHtcbiAgcmV0dXJuIGFyZyA9PT0gbnVsbCB8fFxuICAgICAgICAgdHlwZW9mIGFyZyA9PT0gJ2Jvb2xlYW4nIHx8XG4gICAgICAgICB0eXBlb2YgYXJnID09PSAnbnVtYmVyJyB8fFxuICAgICAgICAgdHlwZW9mIGFyZyA9PT0gJ3N0cmluZycgfHxcbiAgICAgICAgIHR5cGVvZiBhcmcgPT09ICdzeW1ib2wnIHx8ICAvLyBFUzYgc3ltYm9sXG4gICAgICAgICB0eXBlb2YgYXJnID09PSAndW5kZWZpbmVkJztcbn1cbmV4cG9ydHMuaXNQcmltaXRpdmUgPSBpc1ByaW1pdGl2ZTtcblxuZXhwb3J0cy5pc0J1ZmZlciA9IHJlcXVpcmUoJy4vc3VwcG9ydC9pc0J1ZmZlcicpO1xuXG5mdW5jdGlvbiBvYmplY3RUb1N0cmluZyhvKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwobyk7XG59XG5cblxuZnVuY3Rpb24gcGFkKG4pIHtcbiAgcmV0dXJuIG4gPCAxMCA/ICcwJyArIG4udG9TdHJpbmcoMTApIDogbi50b1N0cmluZygxMCk7XG59XG5cblxudmFyIG1vbnRocyA9IFsnSmFuJywgJ0ZlYicsICdNYXInLCAnQXByJywgJ01heScsICdKdW4nLCAnSnVsJywgJ0F1ZycsICdTZXAnLFxuICAgICAgICAgICAgICAnT2N0JywgJ05vdicsICdEZWMnXTtcblxuLy8gMjYgRmViIDE2OjE5OjM0XG5mdW5jdGlvbiB0aW1lc3RhbXAoKSB7XG4gIHZhciBkID0gbmV3IERhdGUoKTtcbiAgdmFyIHRpbWUgPSBbcGFkKGQuZ2V0SG91cnMoKSksXG4gICAgICAgICAgICAgIHBhZChkLmdldE1pbnV0ZXMoKSksXG4gICAgICAgICAgICAgIHBhZChkLmdldFNlY29uZHMoKSldLmpvaW4oJzonKTtcbiAgcmV0dXJuIFtkLmdldERhdGUoKSwgbW9udGhzW2QuZ2V0TW9udGgoKV0sIHRpbWVdLmpvaW4oJyAnKTtcbn1cblxuXG4vLyBsb2cgaXMganVzdCBhIHRoaW4gd3JhcHBlciB0byBjb25zb2xlLmxvZyB0aGF0IHByZXBlbmRzIGEgdGltZXN0YW1wXG5leHBvcnRzLmxvZyA9IGZ1bmN0aW9uKCkge1xuICBjb25zb2xlLmxvZygnJXMgLSAlcycsIHRpbWVzdGFtcCgpLCBleHBvcnRzLmZvcm1hdC5hcHBseShleHBvcnRzLCBhcmd1bWVudHMpKTtcbn07XG5cblxuLyoqXG4gKiBJbmhlcml0IHRoZSBwcm90b3R5cGUgbWV0aG9kcyBmcm9tIG9uZSBjb25zdHJ1Y3RvciBpbnRvIGFub3RoZXIuXG4gKlxuICogVGhlIEZ1bmN0aW9uLnByb3RvdHlwZS5pbmhlcml0cyBmcm9tIGxhbmcuanMgcmV3cml0dGVuIGFzIGEgc3RhbmRhbG9uZVxuICogZnVuY3Rpb24gKG5vdCBvbiBGdW5jdGlvbi5wcm90b3R5cGUpLiBOT1RFOiBJZiB0aGlzIGZpbGUgaXMgdG8gYmUgbG9hZGVkXG4gKiBkdXJpbmcgYm9vdHN0cmFwcGluZyB0aGlzIGZ1bmN0aW9uIG5lZWRzIHRvIGJlIHJld3JpdHRlbiB1c2luZyBzb21lIG5hdGl2ZVxuICogZnVuY3Rpb25zIGFzIHByb3RvdHlwZSBzZXR1cCB1c2luZyBub3JtYWwgSmF2YVNjcmlwdCBkb2VzIG5vdCB3b3JrIGFzXG4gKiBleHBlY3RlZCBkdXJpbmcgYm9vdHN0cmFwcGluZyAoc2VlIG1pcnJvci5qcyBpbiByMTE0OTAzKS5cbiAqXG4gKiBAcGFyYW0ge2Z1bmN0aW9ufSBjdG9yIENvbnN0cnVjdG9yIGZ1bmN0aW9uIHdoaWNoIG5lZWRzIHRvIGluaGVyaXQgdGhlXG4gKiAgICAgcHJvdG90eXBlLlxuICogQHBhcmFtIHtmdW5jdGlvbn0gc3VwZXJDdG9yIENvbnN0cnVjdG9yIGZ1bmN0aW9uIHRvIGluaGVyaXQgcHJvdG90eXBlIGZyb20uXG4gKi9cbmV4cG9ydHMuaW5oZXJpdHMgPSByZXF1aXJlKCdpbmhlcml0cycpO1xuXG5leHBvcnRzLl9leHRlbmQgPSBmdW5jdGlvbihvcmlnaW4sIGFkZCkge1xuICAvLyBEb24ndCBkbyBhbnl0aGluZyBpZiBhZGQgaXNuJ3QgYW4gb2JqZWN0XG4gIGlmICghYWRkIHx8ICFpc09iamVjdChhZGQpKSByZXR1cm4gb3JpZ2luO1xuXG4gIHZhciBrZXlzID0gT2JqZWN0LmtleXMoYWRkKTtcbiAgdmFyIGkgPSBrZXlzLmxlbmd0aDtcbiAgd2hpbGUgKGktLSkge1xuICAgIG9yaWdpbltrZXlzW2ldXSA9IGFkZFtrZXlzW2ldXTtcbiAgfVxuICByZXR1cm4gb3JpZ2luO1xufTtcblxuZnVuY3Rpb24gaGFzT3duUHJvcGVydHkob2JqLCBwcm9wKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwob2JqLCBwcm9wKTtcbn1cbiJdfQ==
},{"./support/isBuffer":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/util/support/isBufferBrowser.js","_process":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/process/browser.js","inherits":"/Users/narayan/workspace/mortar/js/node_modules/browserify/node_modules/util/node_modules/inherits/inherits_browser.js"}]},{},["./js/digest.js"])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJqcy9kaWdlc3QuanMiLCJqcy9saXN0LmpzIiwianMvdGFibGUuanMiLCJqcy91dGlsLmpzIiwibm9kZV9tb2R1bGVzL2JhYnlwYXJzZS9iYWJ5cGFyc2UuanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9saWIvX2VtcHR5LmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2J1ZmZlci9pbmRleC5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9idWZmZXIvbm9kZV9tb2R1bGVzL2Jhc2U2NC1qcy9saWIvYjY0LmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2J1ZmZlci9ub2RlX21vZHVsZXMvaWVlZTc1NC9pbmRleC5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9idWZmZXIvbm9kZV9tb2R1bGVzL2lzLWFycmF5L2luZGV4LmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2V2ZW50cy9ldmVudHMuanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvaHR0cC1icm93c2VyaWZ5L2luZGV4LmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2h0dHAtYnJvd3NlcmlmeS9saWIvcmVxdWVzdC5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9odHRwLWJyb3dzZXJpZnkvbGliL3Jlc3BvbnNlLmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2h0dHAtYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvQmFzZTY0L2Jhc2U2NC5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9pbmhlcml0cy9pbmhlcml0c19icm93c2VyLmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2luc2VydC1tb2R1bGUtZ2xvYmFscy9ub2RlX21vZHVsZXMvaXMtYnVmZmVyL2luZGV4LmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL2lzYXJyYXkvaW5kZXguanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvcHJvY2Vzcy9icm93c2VyLmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL3B1bnljb2RlL3B1bnljb2RlLmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL3F1ZXJ5c3RyaW5nLWVzMy9kZWNvZGUuanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvcXVlcnlzdHJpbmctZXMzL2VuY29kZS5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9xdWVyeXN0cmluZy1lczMvaW5kZXguanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvcmVhZGFibGUtc3RyZWFtL2R1cGxleC5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vbGliL19zdHJlYW1fZHVwbGV4LmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL3JlYWRhYmxlLXN0cmVhbS9saWIvX3N0cmVhbV9wYXNzdGhyb3VnaC5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vbGliL19zdHJlYW1fcmVhZGFibGUuanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvcmVhZGFibGUtc3RyZWFtL2xpYi9fc3RyZWFtX3RyYW5zZm9ybS5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vbGliL19zdHJlYW1fd3JpdGFibGUuanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvcmVhZGFibGUtc3RyZWFtL25vZGVfbW9kdWxlcy9jb3JlLXV0aWwtaXMvbGliL3V0aWwuanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvcmVhZGFibGUtc3RyZWFtL3Bhc3N0aHJvdWdoLmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL3JlYWRhYmxlLXN0cmVhbS9yZWFkYWJsZS5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9yZWFkYWJsZS1zdHJlYW0vdHJhbnNmb3JtLmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL3JlYWRhYmxlLXN0cmVhbS93cml0YWJsZS5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9zdHJlYW0tYnJvd3NlcmlmeS9pbmRleC5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9zdHJpbmdfZGVjb2Rlci9pbmRleC5qcyIsIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy91cmwvdXJsLmpzIiwibm9kZV9tb2R1bGVzL2Jyb3dzZXJpZnkvbm9kZV9tb2R1bGVzL3V0aWwvc3VwcG9ydC9pc0J1ZmZlckJyb3dzZXIuanMiLCJub2RlX21vZHVsZXMvYnJvd3NlcmlmeS9ub2RlX21vZHVsZXMvdXRpbC91dGlsLmpzIl0sIm5hbWVzIjpbXSwibWFwcGluZ3MiOiJBQUFBO0FDQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDL1BBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ2xCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ2xVQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDbkNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNqM0JBOzs7O0FDQUE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzVoQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDeEhBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ3BGQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNqQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM3U0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDaEpBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNqTkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDeEhBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzVEQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDdkJBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ3JCQTtBQUNBO0FBQ0E7QUFDQTs7QUNIQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDdEZBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzlmQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNwRkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNyRkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNKQTtBQUNBOztBQ0RBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM1RkE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUM5Q0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDMTdCQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDak5BO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQ2hlQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7O0FDOUdBO0FBQ0E7O0FDREE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNiQTtBQUNBOztBQ0RBO0FBQ0E7O0FDREE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUMvSEE7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBOztBQzdOQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7Ozs7QUNuc0JBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTs7QUNMQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24gZSh0LG4scil7ZnVuY3Rpb24gcyhvLHUpe2lmKCFuW29dKXtpZighdFtvXSl7dmFyIGE9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtpZighdSYmYSlyZXR1cm4gYShvLCEwKTtpZihpKXJldHVybiBpKG8sITApO3ZhciBmPW5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIrbytcIidcIik7dGhyb3cgZi5jb2RlPVwiTU9EVUxFX05PVF9GT1VORFwiLGZ9dmFyIGw9bltvXT17ZXhwb3J0czp7fX07dFtvXVswXS5jYWxsKGwuZXhwb3J0cyxmdW5jdGlvbihlKXt2YXIgbj10W29dWzFdW2VdO3JldHVybiBzKG4/bjplKX0sbCxsLmV4cG9ydHMsZSx0LG4scil9cmV0dXJuIG5bb10uZXhwb3J0c312YXIgaT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2Zvcih2YXIgbz0wO288ci5sZW5ndGg7bysrKXMocltvXSk7cmV0dXJuIHN9KSIsInZhciB0YWJsZSA9IHJlcXVpcmUoJy4vdGFibGUnKTtcblxuLy8gVVJMcyB0byBzdXBwb3J0IHBhZ2VzLCBrZXllZCBieSBIRUxQSURcbnZhciBfaGVscF91cmwgPSB7XG4gIHF1ZXJ5X3Jlc3VsdHMgOiBcImh0dHA6Ly9zdXBwb3J0LmxpbmNzY2xvdWQub3JnL2hjL2VuLXVzL2FydGljbGVzLzIwMjIzMTYzMy1RdWVyeS1BcHAtUmVzdWx0c1wiXG59O1xuICAgIFxuLy8gUHVibGljXG5leHBvcnRzLnVwZGF0ZUhlbHBVUkwgPSB1cGRhdGVIZWxwVVJMO1xuZXhwb3J0cy5kdFF1ZXJ5UHJldmlldyA9IGR0UXVlcnlQcmV2aWV3O1xuZXhwb3J0cy5kdENvbm5lY3Rpb25EaWdlc3RJbmRleCA9IGR0Q29ubmVjdGlvbkRpZ2VzdEluZGV4O1xuZXhwb3J0cy5kdENvbm5lY3Rpb25EaWdlc3QgPSBkdENvbm5lY3Rpb25EaWdlc3Q7XG5leHBvcnRzLnBhcnNlVGFibGUgPSB0YWJsZS5wYXJzZVRhYmxlO1xuLyoqXG4qIEBmdW5jdGlvbiB1cGRhdGVIZWxwVVJMXG4qIEBkZXNjIGBgYFVwZGF0ZXMgc3VwcG9ydCBoeXBlcmxpbmsocykgaW4gYSBwYWdlLmBgYCAgICBcbkV4cGVjdHMgdGhlIGxpbmsgdG8gaGF2ZSBhIGNsYXNzbmFtZSAnaGVscF91cmwtSEVMUElEJyBcbndoZXJlIEhFTFBJRCBpcyBhbiBpbnRlcm5hbCBpZGVudGlmaWVyIHRvIHRoZSBzdXBwb3J0IHBhZ2UuXG4qLyBcbmZ1bmN0aW9uIHVwZGF0ZUhlbHBVUkwoKXtcbiAgJChcImFbY2xhc3NePWhlbHBfdXJsLV1cIikuZWFjaChmdW5jdGlvbigpIHtcbiAgICB2YXIgdXJsX25hbWUgPSB0aGlzLmNsYXNzTmFtZS5yZXBsYWNlKCdoZWxwX3VybC0nLCcnKTtcbiAgICAkKCdhLicrdGhpcy5jbGFzc05hbWUpLnByb3AoJ2hyZWYnLCBfaGVscF91cmxbdXJsX25hbWVdKTsgIFxuICB9KTsgXG59XG5cbi8qKiBcbiogQGZ1bmN0aW9uIGR0UXVlcnlQcmV2aWV3XG4qIEBkZXNjIGBgYFBhcnNlcyByYXcgZGxtIHNlcGFyYXRlZCBkYXRhIGFuZCBwb3B1bGF0ZXMgYSBcbiogZGF0YXRhYmxlIHdpdGggdG9wIGNvbm5lY3Rpb25zIHRvIGEgcXVlcnlgYGBcbiovXG5mdW5jdGlvbiBkdFF1ZXJ5UHJldmlldyhvYmopIHtcbiAgICB2YXIgdGJsID0gdGFibGUucGFyc2VUYWJsZShvYmoucmF3X2RhdGEsICdcXHQnLCB0cnVlKTtcbiAgICB2YXIgY29sID0gW107XG4gICAgXG4gICAgZm9yICh2YXIgaSBpbiB0YmwuaGVhZGVyKSB7XG4gICAgICAgY29sLnB1c2goe3NUaXRsZTogdGJsLmhlYWRlcltpXX0pO1xuICAgIH1cblxuICAgICQob2JqLnRhcmdldCkuZGF0YVRhYmxlKHtcbiAgICAgICBhYURhdGE6IHRibC5kYXRhLFxuICAgICAgIGFvQ29sdW1uczogY29sLFxuICAgICAgIGFhU29ydGluZzogW1t0YmwuaGVhZGVyX2x1dFtvYmouc29ydF9maWVsZF0sXG4gICAgICAgICAgICBvYmouc29ydF9vcmRlcl1dLFxuICAgICAgIFwiYkpRdWVyeVVJXCIgOiB0cnVlLCAvLyBqcXVpIHRoZW1lXG4gICAgICAgXCJzRG9tXCIgOiBcIlJmcnRpU1wiLCAvLyBpbmZpbml0ZSBzY3JvbGxpbmcsIHJlb3JkZXIgY29sdW1uc1xuICAgICAgIFwiYlNjcm9sbENvbGxhcHNlXCI6IHRydWUsXG4gICAgICAgXCJzU2Nyb2xsWVwiOiBcIjQ1MHB4XCIsIFxuICAgICAgIFwic1Njcm9sbFhcIjogdHJ1ZSBcbiAgICAgICB9KTtcbn1cblxuLyoqIFxuKiBAZnVuY3Rpb24gZHRDb25uZWN0aW9uRGlnZXN0SW5kZXhcbiogQGRlc2MgUG9wdWxhdGVzIENvbm5lY3Rpb24gZGlnZXN0IGluZGV4ICAgIFxuKi9cbmZ1bmN0aW9uIGR0Q29ubmVjdGlvbkRpZ2VzdEluZGV4KG9iaikge1xuICAgIHZhciBkaWdlc3QgPSB0YWJsZS5wYXJzZVRhYmxlKG9iai5yYXdfZGF0YSwgJ1xcdCcsIHRydWUpO1xuICAgIHZhciBjb2wgPSBbXTtcbiAgICBmb3IgKHZhciBpIGluIGRpZ2VzdC5oZWFkZXIpIHtcbiAgICAgICBjb2wucHVzaCh7c1RpdGxlOiBkaWdlc3QuaGVhZGVyW2ldfSk7XG4gICAgfVxuXG4gICAgdmFyIGFvQ29sdW1uRGVmcyA9IFtdO1xuICAgIGlmIChvYmoubGlua19zb3VyY2UpIHtcbiAgICAgIGlmICgodHlwZW9mIGRpZ2VzdC5oZWFkZXJfbHV0W29iai5saW5rX3NvdXJjZV0gIT0gXCJ1bmRlZmluZWRcIikgJiYgXG4gICAgICAgICAgKHR5cGVvZiBkaWdlc3QuaGVhZGVyX2x1dFtvYmoubGlua190YXJnZXRdICE9IFwidW5kZWZpbmVkXCIpKSB7XG4gICAgICAgICAgYW9Db2x1bW5EZWZzID0gW1xuICAgICAgICAgIHt0YXJnZXRzOiBkaWdlc3QuaGVhZGVyX2x1dFtvYmoubGlua19zb3VyY2VdLCB2aXNpYmxlOiBmYWxzZX0sXG4gICAgICAgICAge3RhcmdldHM6IGRpZ2VzdC5oZWFkZXJfbHV0W29iai5saW5rX3RhcmdldF0sIFxuICAgICAgICAgICAgXCJyZW5kZXJcIjogZnVuY3Rpb24oZGF0YSx0eXBlLCByb3cpIHsgXG4gICAgICAgICAgICAgICAgcmV0dXJuICc8YSBocmVmPScrb2JqLmJhc2VfdXJsK3Jvd1tkaWdlc3QuaGVhZGVyX2x1dFtvYmoubGlua19zb3VyY2VdXSsnPicrZGF0YSArICc8L2E+JztcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgfVxuICAgICAgICAgIF07XG4gICAgICAgIH1cbiAgICAgICAgZWxzZSB7XG4gICAgICAgICAgY29uc29sZS5sb2coJ0Vycm9yIGluc2VydGluZyBsaW5rczonK29iai5saW5rX3NvdXJjZSsnLT4nK29iai5saW5rX3RhcmdldCk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICBcbiAgICB2YXIgZHQgPSAkKG9iai50YXJnZXQpLmRhdGFUYWJsZSh7XG4gICAgICAgYWFEYXRhOiBkaWdlc3QuZGF0YSxcbiAgICAgICBhb0NvbHVtbnM6IGNvbCxcbiAgICAgICBhb0NvbHVtbkRlZnM6IGFvQ29sdW1uRGVmcyxcbiAgICAgICBhYVNvcnRpbmc6IFtbZGlnZXN0LmhlYWRlcl9sdXRbb2JqLnNvcnRfZmllbGRdLFxuICAgICAgICAgICAgb2JqLnNvcnRfb3JkZXJdXSxcbiAgICAgICBcImJKUXVlcnlVSVwiIDogdHJ1ZSwgLy8ganF1aSB0aGVtZVxuICAgICAgIFwic0RvbVwiIDogXCJSZnJ0aVNcIiwgLy8gaW5maW5pdGUgc2Nyb2xsaW5nLCByZW9yZGVyIGNvbHVtbnNcbiAgICAgICBcImJBZGp1c3RXaWR0aFwiOiBmYWxzZSxcbiAgICAgICBcImJTY3JvbGxDb2xsYXBzZVwiOiB0cnVlLFxuICAgICAgIFwic1Njcm9sbFlcIjogXCI0NTBweFwiLCBcbiAgICAgICBcInNTY3JvbGxYXCI6IHRydWUgXG4gICAgICAgfSk7XG59XG5cbi8qKiBcbiogQGZ1bmN0aW9uIGR0Q29ubmVjdGlvbkRpZ2VzdFxuKiBAZGVzYyBDcmVhdGVzIHRoZSBjb25uZWN0aW9uIGRpZ2VzdCByZXBvcnQgYW5kIGRhdGEgdGFibGVzLlxuKi9cbmZ1bmN0aW9uIGR0Q29ubmVjdGlvbkRpZ2VzdChvYmopIHtcbiAgIC8vIHJlbWFwIHNvbWUgZmllbGQgbmFtZXNcbiAgIHZhciBmaWVsZE1hcCA9IHtcbiAgICAncGVydF9pZCc6ICdjbWFwX2lkJyxcbiAgICAncGVydF9pbmFtZSc6ICdjbWFwX2luYW1lJyxcbiAgICAnc3VtbWx5JzogJ3N1bW1hcnknLFxuICAgICdtZWFuX3JhbmtwdF8yJzogJ3Njb3JlX2Jlc3QyJyxcbiAgICAnbWVhbl9yYW5rcHRfNCc6ICdzY29yZV9iZXN0NCcsXG4gICAgJ21lYW5fcmFua3B0XzYnOiAnc2NvcmVfYmVzdDYnLFxuICAgfTtcblxuICAgIC8vIHBhcnNlIGFuZCBzcGxpdCB0YWJsZSBieSBwZXJ0X3R5cGVcbiAgICB2YXIgdGJsID0gdGFibGUucGFyc2VUYWJsZShvYmoucmF3X2RhdGEsICdcXHQnLCB0cnVlKTtcblxuICAgIC8vIGFwcGVuZCBNT0EgYW5ub3RhdGlvbnMgaWYgcHJvdmlkZWRcbiAgICBpZiAoJ21vYV9kYXRhJyBpbiBvYmopIHtcblx0dmFyIG1vYV90YmwgPSB0YWJsZS5wYXJzZVRhYmxlKG9iai5tb2FfZGF0YSwgJ1xcdCcsIHRydWUpO1xuXHR2YXIgc2VsZWN0RmllbGRzID0gdGJsLmhlYWRlcjtcblx0c2VsZWN0RmllbGRzLnNwbGljZSh0YmwuaGVhZGVyX2x1dFsncGVydF9pbmFtZSddKzEsIDAsICdtb2FfdGFyZ2V0Jyk7XG5cdHRibCA9IHRhYmxlLmxlZnRKb2luKHRibCwgbW9hX3RibCwgJ3BlcnRfaWQnLCAncGVydF9pZCcsIHNlbGVjdEZpZWxkcyk7XHRcdFx0ICAgICBcbiAgICB9XG5cbiAgIHZhciBzcGxpdCA9IHRhYmxlLnNwbGl0VGFibGUodGJsLCAncGVydF90eXBlJyk7XG4gICAvLyBpbnNlcnQgcmFua3NcbiAgIGZvciAodmFyIGtleSBpbiBzcGxpdCl7XG4gICAgICBzcGxpdFtrZXldID0gdGFibGUuaW5zZXJ0Q29sdW1uSW5kZXgoc3BsaXRba2V5XSwgJ3JhbmsnKTtcbiAgIH1cbiAgXG4gIHZhciBjb2x1bW5OYW1lcyA9IFtdO1xuICB2YXIgaGVhZGVyID0gc3BsaXQudHJ0X2NwLmhlYWRlcjtcbiAgdmFyIGhlYWRlcl9sdXQgPSBzcGxpdC50cnRfY3AuaGVhZGVyX2x1dDtcblxuICBmb3IgKHZhciBpIGluIGhlYWRlcikge1xuICAgICAgaWYgKGhlYWRlcltpXSA9PT0gJ3JhbmsnKSB7XG4gICAgICAgIGNvbHVtbk5hbWVzLnB1c2goe3NUaXRsZTogJycsIHNUeXBlOidudW1lcmljJ30pO1xuICAgICAgfVxuICAgICAgZWxzZSB7XG4gICAgICAgIGlmIChoZWFkZXJbaV0gaW4gZmllbGRNYXApIHtcbiAgICAgICAgICBjb2x1bW5OYW1lcy5wdXNoKHtzVGl0bGU6IGZpZWxkTWFwW2hlYWRlcltpXV19KTsgIFxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIGNvbHVtbk5hbWVzLnB1c2goe3NUaXRsZTogaGVhZGVyW2ldfSk7ICBcbiAgICAgICAgfVxuICAgICAgICBcbiAgICAgIH1cbiAgfVxuICAgIC8vIGhhbmRsZSBzcGVjaWFsIGNvbHVtbnNcbiAgIHZhciBhb0NvbHVtbkRlZnMgPSBbXG4gICAge3RhcmdldHM6IFtoZWFkZXJfbHV0LnBlcnRfdHlwZSxcbiAgICAgICAgICAgICAgIGhlYWRlcl9sdXQuaXNfZXhwcmVzc2VkXzQsXG4gICAgICAgICAgICAgICBoZWFkZXJfbHV0LmlzX2V4cHJlc3NlZF82XG4gICAgICAgICAgICAgIF0sXG4gICAgIHZpc2libGU6IGZhbHNlXG4gICAgfSxcbiAgICB7dGFyZ2V0czogW2hlYWRlcl9sdXQucmFua10sXG4gICAgICBzb3J0YWJsZTogZmFsc2V9XG4gICAgXTtcbiAgICAvLyB3aWR0aCBmb3IgbW9hIGNvbHVtblxuICAgIGlmICgnbW9hX3RhcmdldCcgaW4gaGVhZGVyX2x1dCkge1xuXHRhb0NvbHVtbkRlZnMucHVzaCh7d2lkdGg6IFwiMSVcIiwgdGFyZ2V0czogW2hlYWRlcl9sdXQubW9hX3RhcmdldF19KTtcbiAgICB9XG4gICAgXG4gICAgLy8gY29tcG91bmQgdGFibGVcbiAgICB2YXIgZHRfY3BfY29uZmlnID0ge1xuICAgICAgIGFhRGF0YTogc3BsaXQudHJ0X2NwLmRhdGEsXG4gICAgICAgYW9Db2x1bW5zOiBjb2x1bW5OYW1lcyxcbiAgICAgICBhb0NvbHVtbkRlZnM6IGFvQ29sdW1uRGVmcyxcbiAgICAgICBmbkRyYXdDYWxsYmFjazogZHRDb25uZWN0aW9uRGlnZXN0RHJhd0NhbGxiYWNrLCAgICAgICAgICAgICAgICBcbiAgICAgICBiSlF1ZXJ5VUk6IHRydWUsIC8vIGpxdWkgdGhlbWVcbiAgICAgICBzRG9tOiBcImZydGlTXCIsIC8vIGluZmluaXRlIHNjcm9sbGluZywgcmVvcmRlciBjb2x1bW5zXG4gICAgICAgYXV0b1dpZHRoOiBmYWxzZSxcbiAgICAgICBiU2Nyb2xsQ29sbGFwc2U6IHRydWUsXG4gICAgICAgc1Njcm9sbFk6IFwiNDUwcHhcIiwgXG4gICAgICAgc1Njcm9sbFg6IFwiMTAwJVwiIFxuICAgICAgIH07XG4gICAgLy8gQ0dTIHRhYmxlXG4gICAgdmFyIGR0X2Nnc19jb25maWcgPSB7XG4gICAgICAgZm5Sb3dDYWxsYmFjazogZnVuY3Rpb24gKG5Sb3csIGFEYXRhKSB7XG4gICAgICAgICAgICB2YXIgZGVjb3JhdGlvbiA9ICQob2JqLmV4cHJlc3Npb25fY2hlY2tib3gpLnByb3AoXCJjaGVja2VkXCIpP1wibGluZS10aHJvdWdoXCI6XCJub25lXCI7XG4gICAgICAgICAgICBpZiAoYURhdGFbc3BsaXRbJ3RydF9zaC5jZ3MnXS5oZWFkZXJfbHV0LmlzX2V4cHJlc3NlZF80XSA9PT0gMCkge1xuICAgICAgICAgICAgICAgICQoblJvdykuY3NzKHsndGV4dC1kZWNvcmF0aW9uJzpkZWNvcmF0aW9ufSk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICAgIGFhRGF0YTogc3BsaXRbJ3RydF9zaC5jZ3MnXS5kYXRhLFxuICAgICAgICBhb0NvbHVtbnM6IGNvbHVtbk5hbWVzLFxuICAgICAgICBhb0NvbHVtbkRlZnM6IGFvQ29sdW1uRGVmcyxcbiAgICAgICAgZm5EcmF3Q2FsbGJhY2s6IGR0Q29ubmVjdGlvbkRpZ2VzdERyYXdDYWxsYmFjaywgICAgICAgICAgICAgICAgXG4gICAgICAgIGJKUXVlcnlVSTogdHJ1ZSwgLy8ganF1aSB0aGVtZVxuICAgICAgICBzRG9tOiBcIlJmcnRpU1wiLCAvLyBpbmZpbml0ZSBzY3JvbGxpbmcsIHJlb3JkZXIgY29sdW1uc1xuICAgICAgICBiQWRqdXN0V2lkdGg6IGZhbHNlLFxuICAgICAgICBiU2Nyb2xsQ29sbGFwc2U6IHRydWUsXG4gICAgICAgIHNTY3JvbGxZOiBcIjQ1MHB4XCIsIFxuICAgICAgICBzU2Nyb2xsWDogdHJ1ZSxcbiAgICB9O1xuICAgIC8vIE9FIHRhYmxlXG4gICAgdmFyIGR0X29lX2NvbmZpZyA9IHtcbiAgICAgICBhYURhdGE6IHNwbGl0LnRydF9vZS5kYXRhLFxuICAgICAgIGFvQ29sdW1uczogY29sdW1uTmFtZXMsXG4gICAgICAgYW9Db2x1bW5EZWZzOiBhb0NvbHVtbkRlZnMsXG4gICAgICAgZm5EcmF3Q2FsbGJhY2s6IGR0Q29ubmVjdGlvbkRpZ2VzdERyYXdDYWxsYmFjaywgICAgICAgICAgICAgICAgICAgICBcbiAgICAgICBiSlF1ZXJ5VUk6IHRydWUsIC8vIGpxdWkgdGhlbWVcbiAgICAgICBzRG9tOiBcIlJmcnRpU1wiLCAvLyBpbmZpbml0ZSBzY3JvbGxpbmcsIHJlb3JkZXIgY29sdW1uc1xuICAgICAgIGJBZGp1c3RXaWR0aDogZmFsc2UsXG4gICAgICAgYlNjcm9sbENvbGxhcHNlOiB0cnVlLFxuICAgICAgIHNTY3JvbGxZOiBcIjQ1MHB4XCIsIFxuICAgICAgIHNTY3JvbGxYOiB0cnVlIFxuICAgICAgIH07XG5cbiAgICAvLyBIYW5kbGUgc29ydGluZ1xuICAgIGlmICgnc29ydF9maWVsZCcgaW4gb2JqICYmICdzb3J0X29yZGVyJyBpbiBvYmopIHtcbiAgICAgICBkdF9jcF9jb25maWdbJ2FhU29ydGluZyddPSBbW3NwbGl0LnRydF9jcC5oZWFkZXJfbHV0W29iai5zb3J0X2ZpZWxkXSxcbiAgICAgICAgICAgIG9iai5zb3J0X29yZGVyXV07XG4gICAgICAgZHRfY2dzX2NvbmZpZ1snYWFTb3J0aW5nJ109IFtbc3BsaXRbJ3RydF9zaC5jZ3MnXS5oZWFkZXJfbHV0W29iai5zb3J0X2ZpZWxkXSxcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIG9iai5zb3J0X29yZGVyXV07XG4gICAgICAgZHRfb2VfY29uZmlnWydhYVNvcnRpbmcnXT0gW1tzcGxpdC50cnRfb2UuaGVhZGVyX2x1dFtvYmouc29ydF9maWVsZF0sXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBvYmouc29ydF9vcmRlcl1dOyAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIFxuICAgIH0gZWxzZSBpZiAoJ3NvcnRfaW5kZXgnIGluIG9iaiAmJiAnc29ydF9vcmRlcicgaW4gb2JqKSB7XG4gICAgICAgIGR0X2NwX2NvbmZpZ1snYWFTb3J0aW5nJ109IFtbb2JqLnNvcnRfaW5kZXgsIG9iai5zb3J0X29yZGVyXV07XG4gICAgICAgIGR0X2Nnc19jb25maWdbJ2FhU29ydGluZyddPSBbW29iai5zb3J0X2luZGV4LCBvYmouc29ydF9vcmRlcl1dO1xuICAgICAgICBkdF9vZV9jb25maWdbJ2FhU29ydGluZyddPSBbW29iai5zb3J0X2luZGV4LCBvYmouc29ydF9vcmRlcl1dO1xuICAgIH1cblxuICAgIC8vIGluc3RhbnRpYXRlIERhdGFUYWJsZXNcbiAgICB2YXIgZHRfY3AgPSAkKG9iai50YXJnZXRfY3ApLmRhdGFUYWJsZShkdF9jcF9jb25maWcpO1xuICAgIHZhciBkdF9jZ3MgPSAkKG9iai50YXJnZXRfY2dzKS5kYXRhVGFibGUoZHRfY2dzX2NvbmZpZyk7XG5cbiAgICAvLyBnZW5lIGV4cHJlc3Npb24gY2hlY2tib3ggICAgICAgIFxuICAgICQob2JqLmV4cHJlc3Npb25fY2hlY2tib3gpLmNoYW5nZShmdW5jdGlvbigpIHsgZHRfY2dzLmZuRHJhdygpOyB9KTsgICAgICAgIFxuICAgICQob2JqLmV4cHJlc3Npb25fY2hlY2tib3gpLnByb3AoJ2NoZWNrZWQnLCB0cnVlKTtcblxuICAgIHZhciBkdF9vZSA9ICQob2JqLnRhcmdldF9vZSkuZGF0YVRhYmxlKGR0X29lX2NvbmZpZyk7XG59XG5cbi8qKiBcbiogQGZ1bmN0aW9uIGR0Q29ubmVjdGlvbkRpZ2VzdERyYXdDYWxsYmFja1xuKiBAZGVzYyBIYW5kbGVzIGRyYXcgY2FsbGJhY2tzLCBjdXN0b20gcmFua2luZyBldGMgZm9yIHRoZSBjb25uZWN0aW9uIGRpZ2VzdC5cbiovXG5mdW5jdGlvbiBkdENvbm5lY3Rpb25EaWdlc3REcmF3Q2FsbGJhY2soIG9TZXR0aW5ncyApIHtcbiAgICAvLyByZWNvbXB1dGUgYWxsIHJhbmtzIGFuZCBjYWNoZVxuICAgIGlmKG9TZXR0aW5ncy5iU29ydGVkKXtcbiAgICAgICAgdmFyIGJBc2NlbmQgPSBvU2V0dGluZ3MuYWFTb3J0aW5nWzBdWzFdPT1cImFzY1wiO1xuICAgICAgICB2YXIgaVJvd3MgPSBvU2V0dGluZ3MuYWlEaXNwbGF5TWFzdGVyLmxlbmd0aDtcbiAgICAgICAgdGhpcy5fb1JhbmsgPSBuZXcgQXJyYXkoaVJvd3MpO1xuICAgICAgICBmb3IgKHZhciBqPTA7IGo8aVJvd3M7IGorKykge1xuICAgICAgICAgICAgdGhpcy5fb1Jhbmtbb1NldHRpbmdzLmFpRGlzcGxheU1hc3RlcltqXV0gPSBiQXNjZW5kID8gaVJvd3MtaiA6IGorMSA7XG4gICAgICAgIH1cbiAgICB9XG4gICAgXG4gICAgLy8gdXBkYXRlIHJhbmtzIGZvciBqdXN0IHZpc2libGUgcm93cyBzaW5jZSBpdHMgZmFzdGVyXG4gICAgdmFyIGlTdGFydCA9IG9TZXR0aW5ncy5faURpc3BsYXlTdGFydDtcbiAgICB2YXIgaVN0b3AgPSBvU2V0dGluZ3MuX2lEaXNwbGF5TGVuZ3RoICsgaVN0YXJ0O1xuICAgIGZvciAodmFyIGk9aVN0YXJ0OyBpPGlTdG9wIDsgaSsrICkge1xuICAgICAgICB2YXIgaWR4ID0gb1NldHRpbmdzLmFpRGlzcGxheVtpXTtcbiAgICAgICAgdGhpcy5mblVwZGF0ZSh0aGlzLl9vUmFua1tpZHhdLCBvU2V0dGluZ3MuYWlEaXNwbGF5W2ldLCAwLCBmYWxzZSwgZmFsc2UgKTtcbiAgICB9XG59XG4iLCIvL1B1YmxpY1xuZXhwb3J0cy5wYXJzZUxpc3QgPSBwYXJzZUxpc3Q7XG5cbi8qKlxuICogQGZ1bmN0aW9uIHBhcnNlTGlzdFxuICogQG1lbWJlcm9mIE1vcnRhciNcbiAqIEBkZXNjIGBgYFJlYWRzIGxpbmVzIGZyb20gc3RyaW5nIGlucHV0YGBgXG4gKiBAcGFyYW0ge1N0cmluZ30gU3RyaW5nIHdpdGggbmV3bGluZXNcbiAqIEByZXR1cm5zIHtBcnJheTxTdHJpbmc+fSBcbiAqL1xuZnVuY3Rpb24gcGFyc2VMaXN0KHJhdykge1xuIHJhdyA9IHJhdy5yZXBsYWNlKC8oXFxyXFxufFxcbnxcXHIpKy9naSwgJ1xcbicpO1xuIHZhciBsaW5lcyA9IHJhdy5zcGxpdCgnXFxuJyk7XG4gLy8gZHJvcCB0aGUgbGFzdCBlbXB0eSBsaW5lXG4gaWYgKGxpbmVzW2xpbmVzLmxlbmd0aC0xXSA9PT0gXCJcIikge1xuICBsaW5lcy5zcGxpY2UobGluZXMubGVuZ3RoLTEsIDEpO1xuIH1cbiByZXR1cm4gbGluZXM7XG59IiwiLyoqXG4gIEBjbGFzc1xuICBAbmFtZSBUYWJsZVxuICBAcHJvcGVydHkge0ludGVnZXJ9IG5yb3cgTnVtYmVyIG9mIHJvd3NcbiAgQHByb3BlcnR5IHtJbnRlZ2VyfSBuY29sIE51bWJlciBvZiBjb2x1bW5zXG4gIEBwcm9wZXJ0eSB7QXJyYXkuPHN0cmluZz59IGRhdGEgVGFibGUgY29udGVudCBhcyBhbiBhcnJheSBvZiBzdHJpbmcgYXJyYXlzXG4gIEBwcm9wZXJ0eSB7QXJyYXl9IGhlYWRlciBIZWFkZXIgbmFtZXNcbiAgQHByb3BlcnR5IHtPYmplY3R9IGhlYWRlcl9sdXQgTG9va3VwIHRhYmxlIG9mIGhlYWRlciBuYW1lcyB0byBjb2x1bW4gaW5kZXhcbiovXG5cbnZhciBodHRwID0gcmVxdWlyZSgnaHR0cCcpO1xudmFyIGJhYnlwYXJzZSA9IHJlcXVpcmUoJ2JhYnlwYXJzZScpO1xuXG52YXIgbGlzdCA9IHJlcXVpcmUoJy4vbGlzdCcpLFxuICAgIHV0aWwgPSByZXF1aXJlKCcuL3V0aWwnKTtcblxuLy8gUHVibGljXG5leHBvcnRzLnBhcnNlID0gcGFyc2U7XG5leHBvcnRzLnBhcnNlQnVmZmVyID0gcGFyc2VCdWZmZXI7XG5leHBvcnRzLnBhcnNlVGFibGUgPSBwYXJzZVRhYmxlO1xuZXhwb3J0cy5pbnNlcnRDb2x1bW5JbmRleCA9IGluc2VydENvbHVtbkluZGV4O1xuZXhwb3J0cy5zcGxpdFRhYmxlID0gc3BsaXRUYWJsZTtcbmV4cG9ydHMubGVmdEpvaW4gPSBsZWZ0Sm9pbjtcbmV4cG9ydHMuaW5uZXJKb2luID0gaW5uZXJKb2luO1xuZXhwb3J0cy5yaWdodEpvaW4gPSByaWdodEpvaW47XG5leHBvcnRzLm91dGVySm9pbiA9IG91dGVySm9pbjtcblxuZnVuY3Rpb24gcGFyc2VCdWZmZXIoYnVmLCBkZWxpbWl0ZXIsIGNhbGxiYWNrKSB7XG4gICAgYmFieXBhcnNlLnBhcnNlKGJ1Ziwge2RlbGltaXRlcjogZGVsaW1pdGVyLFxuXHRcdFx0ICBoZWFkZXI6IGZhbHNlLFxuXHRcdFx0ICBkb3dubG9hZDpmYWxzZSxcblx0XHRcdCAgc2tpcEVtcHR5TGluZXM6dHJ1ZSxcblx0XHRcdCAgY29tcGxldGU6IGZ1bmN0aW9uKHJlcykge1xuXHRcdFx0ICAgICAgdmFyIGhlYWRlciA9IHJlcy5kYXRhLnNwbGljZSgwLDEpWzBdO1xuXHRcdFx0ICAgICAgcmV0dXJuKG1ha2VUYWJsZShyZXMuZGF0YSwgaGVhZGVyKSk7XG4vKlx0XHRcdCAgICAgIGlmIChjYWxsYmFjayAmJiB0eXBlb2YoY2FsbGJhY2spID09PSBcImZ1bmN0aW9uXCIpIHtcblx0XHRcdFx0ICBjYWxsYmFjayhtYWtlVGFibGUocmVzLmRhdGEsIGhlYWRlcikpO1xuXHRcdFx0ICAgICAgfSovXG5cdFx0XHQgIH1cblx0XHRcdCB9KTtcbn1cblxuLyoqXG4gKiBgYGBSZWFkIHRhYmxlIGRhdGEgZGVsaW1pdGVkIGJ5IGRsbS5gYGBcbiAqIEBmdW5jdGlvbiBwYXJzZVRhYmxlXG4gKiBAcGFyYW0ge3N0cmluZ30gcmF3IGRhdGEgZnJvbSBhbiBYSFIgY2FsbFxuICogQHBhcmFtIHtzdHJpbmd9IGRsbSBkZWxpbWl0ZXIuIERlZmF1bHQgaXMgJ1xcdCdcbiAqIEBwYXJhbSB7Ym9vbGVhbn0gaGFzX2hlYWRlciBFeHBlY3RzIHRoYXQgdGhlIGZpcnN0IGxpbmUgaXMgYSBoZWFkZXIgaWYgdHJ1ZS4gRGVmYXVsdCBpcyB0cnVlXG4gKiBAcmV0dXJucyB7VGFibGV9IFRhYmxlIG9iamVjdFxuKi9cbmZ1bmN0aW9uIHBhcnNlKHVybCwgZGxtLCBoYXNfaGVhZGVyLCBjYWxsYmFjaykge1xuICAgIGh0dHAuZ2V0KHVybCxcblx0ICAgICBmdW5jdGlvbihyZXMpIHtcblx0XHQgdmFyIGJ1ZmZlciA9Jyc7XG5cdFx0IHJlcy5vbignZGF0YScsIGZ1bmN0aW9uKGNodW5rKXsgXG5cdFx0ICAgICBidWZmZXIgKz0gY2h1bms7XG5cdFx0IH0pO1xuXHRcdCByZXMub24oJ2VuZCcsIGZ1bmN0aW9uICgpIHtcdFx0ICAgICBcblx0XHQgICAgIGlmIChjYWxsYmFjayAmJiB0eXBlb2YoY2FsbGJhY2spPT09J2Z1bmN0aW9uJykge1xuXHRcdFx0IGNhbGxiYWNrKHBhcnNlVGFibGUoYnVmZmVyLCBkbG0sIGhhc19oZWFkZXIpKVxuXHRcdCAgICAgfTtcblx0XHQgICAgIC8qcGFyc2VCdWZmZXIoYnVmZmVyLCBkbG0sIGZ1bmN0aW9uKHJlcyl7XG5cdFx0XHQgaWYgKGNhbGxiYWNrICYmIHR5cGVvZihjYWxsYmFjaykgPT09IFwiZnVuY3Rpb25cIikge1xuXHRcdFx0ICAgICBjYWxsYmFjayhyZXMpO1xuXHRcdFx0IH1cblx0XHQgICAgIH0pKi9cblx0XHQgfSk7XG5cdFx0IHJlcy5vbignZXJyb3InLCBmdW5jdGlvbiAoZSkge1xuXHRcdCAgICAgY29uc29sZS5sb2coJ0VSUk9SIHBhcnNpbmcgdGFibGU6ICcgKyB1cmwgKyBlLm1lc3NhZ2UpO1xuXHRcdCB9KTtcblx0ICAgICB9XG5cdCAgICApO1xufVxuXG5mdW5jdGlvbiBwYXJzZVRhYmxlKHJhdywgZGxtLCBoYXNfaGVhZGVyKSB7ICAgICAgXG4gICAgdmFyIGk7XG4gICAgZGxtID0gdXRpbC5waWNrKGRsbSwgJ1xcdCcpO1xuICAgIGhhc19oZWFkZXIgPSB1dGlsLnBpY2soaGFzX2hlYWRlciwgdHJ1ZSk7XG4gICAgdmFyIGxpbmVzID0gbGlzdC5wYXJzZUxpc3QocmF3KTtcbiAgICB2YXIgdGFibGUgPSB7J25yb3cnOjAsICduY29sJzowLCAnZGF0YSc6W10sICdoZWFkZXInOltdLCAnaGVhZGVyX2x1dCc6W119O1xuICAgIGZvciAoaT0oaGFzX2hlYWRlciA/IDEgOiAwKTsgaTxsaW5lcy5sZW5ndGg7IGkrKykge1xuXHR0YWJsZS5kYXRhLnB1c2gobGluZXNbaV0uc3BsaXQoZGxtKSk7XG4gICAgfVxuICAgIHRhYmxlLm5yb3cgPSB0YWJsZS5kYXRhLmxlbmd0aDtcbiAgICB0YWJsZS5uY29sID0gdGFibGUuZGF0YVswXS5sZW5ndGg7XG4gICAgaWYgKGhhc19oZWFkZXIpIHtcblx0dGFibGUuaGVhZGVyID0gbGluZXNbMF0uc3BsaXQoZGxtKTtcbiAgICB9XG4gICAgZWxzZSB7XG5cdGZvciAoaT0wOyBpPHRhYmxlLm5jb2w7IGkrKyl7XG5cdCAgICB0YWJsZS5oZWFkZXIucHVzaCgnQ09MXycraSk7XG5cdH0gXG4gICAgfVxuICAgIHRhYmxlLmhlYWRlcl9sdXQgPSB1dGlsLmxpc3QyaW5kZXgodGFibGUuaGVhZGVyKTtcbiAgICByZXR1cm4gdGFibGU7XG59XG5cblxuLyoqXG4gKiBgYGBQZXJmb3JtIGEgbGVmdCBqb2luIG9mIHR3byB0YWJsZXMuYGBgXG4gKiBAZnVuY3Rpb24gbGVmdEpvaW5cbiAqIEBwYXJhbSB7b2JqZWN0fSB0YWJsZSBUYWJsZSBvYmplY3QgcmV0dXJuZWQgYnkgcGFyc2VUYWJsZVxuICogQHBhcmFtIHtvYmplY3R9IHRhYmxlIFRhYmxlIG9iamVjdCByZXR1cm5lZCBieSBwYXJzZVRhYmxlXG4gKiBAcGFyYW0ge3N0cmluZ30gcHJpbWFyeUtleVxuICogQHBhcmFtIHtzdHJpbmd9IGZvcmVpZ25LZXlcbiAqIEBwYXJhbSB7c3RyaW5nfSBzZWxlY3RGaWVsZHMgTGlzdCBvZiBmaWVsZG5hbWVzIHRvIGtlZXAgaW4gdGhlIGpvaW5cbiAqIEByZXR1cm5zIHtUYWJsZX0gT2JqZWN0IG9mIFRhYmxlIG9iamVjdHNcbiovXG5mdW5jdGlvbiBsZWZ0Sm9pbihwLCBmLCBwcmltYXJ5S2V5LCBmb3JlaWduS2V5LCBzZWxlY3RGaWVsZHMpIHtcbiAgdmFyIG5wID0gcC5ucm93LCBuZiA9IGYubnJvdywgaW5kZXggPSB7fSwgamRhdGE9W107XG4gIFxuICAgLy8gY29sdW1uIGluZGV4IG9mIHByaW1hcnkga2V5XG4gICB2YXIgcGtpID0gcC5oZWFkZXJfbHV0W3ByaW1hcnlLZXldO1xuXG4gICAgLy8gQ29uc3RydWN0IGxvb2t1cCBvZiB2YWx1ZXMgZnJvbSBwcmltYXJ5IHRhYmxlXG4gICAgLy8gTm90ZTogZHVwbGljYXRlcyBhcmUgaWdub3JlZFxuICAgIGZvciAodmFyIGk9MDsgaTxucDsgaSsrKSB7XG4gICAgIHZhciByb3cgPSBwLmRhdGFbaV07XG4gICAgIGluZGV4W3Jvd1twa2ldXSA9IGk7XG4gICAgfVxuXG4gICB2YXIgZmtpID0gZi5oZWFkZXJfbHV0W2ZvcmVpZ25LZXldO1xuICAgLy8ga2VlcCB0cmFjayBvZiBzaGFyZWQgdmFsdWVzIGluIGJvdGggdGFibGVzXG4gICAvL3ZhciBzaGFyZWRWYWx1ZXMgPSB7fTtcbiAgIGZvciAodmFyIGk9MDsgaTxuZjsgaSsrKSB7XG4gICAgIHZhciByb3dmID0gZi5kYXRhW2ldO1xuICAgICAvL3NoYXJlZFZhbHVlc1tyb3dmW2ZraV1dPWk7XG4gICAgIGlmIChyb3dmW2ZraV0gaW4gaW5kZXgpIHtcbiAgICAgICB2YXIgcm93cCA9IHAuZGF0YVtpbmRleFtyb3dmW2ZraV1dXTtcbiAgICAgICAvL21hcmsgYXMgZG9uZSBpbiBpbmRleFxuICAgICAgIGluZGV4W3Jvd2ZbZmtpXV0gPSAtMTtcbiAgICAgICBqZGF0YS5wdXNoKGpvaW5GaWVsZHMocm93cCwgcm93Ziwgc2VsZWN0RmllbGRzLCBwLmhlYWRlcl9sdXQsIGYuaGVhZGVyX2x1dCkpO1xuICAgIH1cbiAgIH1cblxuICAgIC8vIGFkZCByb3dzIGZvciB1bm1hdGNoZWQgdmFsdWVzIGZyb20gcHJpbWFyeSB0YWJsZVxuICAgIGZvciAodmFyIGsgaW4gaW5kZXgpIHtcbiAgICAgaWYgKGluZGV4W2tdID49MCkge1xuICAgICAgIGpkYXRhLnB1c2goam9pbkZpZWxkcyhwLmRhdGFbaW5kZXhba11dLCBbXSwgc2VsZWN0RmllbGRzLCBwLmhlYWRlcl9sdXQsIHt9KSk7XG4gICAgIH1cbiAgIH1cblxuICAgdmFyIGogPSBtYWtlVGFibGUoamRhdGEsIHNlbGVjdEZpZWxkcyk7XG4gICByZXR1cm4gajtcbn1cblxuLyoqXG4gKiBgYGBQZXJmb3JtIGEgcmlnaHQgam9pbiBvZiB0d28gdGFibGVzLmBgYFxuICogQGZ1bmN0aW9uIHJpZ2h0Sm9pblxuICogQHBhcmFtIHtvYmplY3R9IHRhYmxlIFRhYmxlIG9iamVjdCByZXR1cm5lZCBieSBwYXJzZVRhYmxlXG4gKiBAcGFyYW0ge29iamVjdH0gdGFibGUgVGFibGUgb2JqZWN0IHJldHVybmVkIGJ5IHBhcnNlVGFibGVcbiAqIEBwYXJhbSB7c3RyaW5nfSBwcmltYXJ5S2V5XG4gKiBAcGFyYW0ge3N0cmluZ30gZm9yZWlnbktleVxuICogQHBhcmFtIHtzdHJpbmd9IHNlbGVjdEZpZWxkcyBMaXN0IG9mIGZpZWxkbmFtZXMgdG8ga2VlcCBpbiB0aGUgam9pblxuICogQHJldHVybnMge1RhYmxlfSBPYmplY3Qgb2YgVGFibGUgb2JqZWN0c1xuKi9cbmZ1bmN0aW9uIHJpZ2h0Sm9pbihwLCBmLCBwcmltYXJ5S2V5LCBmb3JlaWduS2V5LCBzZWxlY3RGaWVsZHMpIHtcbiAgcmV0dXJuIGxlZnRKb2luKGYsIHAsIGZvcmVpZ25LZXksIHByaW1hcnlLZXksIHNlbGVjdEZpZWxkcyk7XG59XG5cbi8qKlxuICogYGBgUGVyZm9ybSBhIG91dGVyIGpvaW4gb2YgdHdvIHRhYmxlcy5gYGBcbiAqIEBmdW5jdGlvbiBvdXRlckpvaW5cbiAqIEBwYXJhbSB7b2JqZWN0fSB0YWJsZSBUYWJsZSBvYmplY3QgcmV0dXJuZWQgYnkgcGFyc2VUYWJsZVxuICogQHBhcmFtIHtvYmplY3R9IHRhYmxlIFRhYmxlIG9iamVjdCByZXR1cm5lZCBieSBwYXJzZVRhYmxlXG4gKiBAcGFyYW0ge3N0cmluZ30gcHJpbWFyeUtleVxuICogQHBhcmFtIHtzdHJpbmd9IGZvcmVpZ25LZXlcbiAqIEBwYXJhbSB7c3RyaW5nfSBzZWxlY3RGaWVsZHMgTGlzdCBvZiBmaWVsZG5hbWVzIHRvIGtlZXAgaW4gdGhlIGpvaW5cbiAqIEByZXR1cm5zIHtUYWJsZX0gT2JqZWN0IG9mIFRhYmxlIG9iamVjdHNcbiovXG5mdW5jdGlvbiBvdXRlckpvaW4ocCwgZiwgcHJpbWFyeUtleSwgZm9yZWlnbktleSwgc2VsZWN0RmllbGRzKSB7XG4gIHZhciBucCA9IHAubnJvdywgbmYgPSBmLm5yb3csIHBpbmRleCA9IHt9LCBmaW5kZXggPSB7fSwgamRhdGE9W107XG4gIFxuICAgLy8gY29sdW1uIGluZGV4IG9mIHByaW1hcnkga2V5XG4gICB2YXIgcGtpID0gcC5oZWFkZXJfbHV0W3ByaW1hcnlLZXldO1xuXG4gICAgLy8gQ29uc3RydWN0IGxvb2t1cCBvZiB2YWx1ZXMgZnJvbSBwcmltYXJ5IHRhYmxlXG4gICAgLy8gTm90ZTogZHVwbGljYXRlcyBhcmUgaWdub3JlZFxuICAgIGZvciAodmFyIGk9MDsgaTxucDsgaSsrKSB7XG4gICAgIHZhciByb3cgPSBwLmRhdGFbaV07XG4gICAgIHBpbmRleFtyb3dbcGtpXV0gPSBpO1xuICAgIH1cblxuICAgdmFyIGZraSA9IGYuaGVhZGVyX2x1dFtmb3JlaWduS2V5XTtcbiAgICAvLyBhZGQgZm9yZWlnbiB0YWJsZSB2YWx1ZXMgdG8gaW5kZXhcbiAgICBmb3IgKHZhciBpPTA7IGk8bmY7IGkrKykge1xuICAgICB2YXIgcm93ID0gZi5kYXRhW2ldO1xuICAgICBmaW5kZXhbcm93W2ZraV1dID0gaTtcbiAgICB9XG5cbiAgICBmb3IgKHZhciBrIGluIHBpbmRleCkge1xuICAgICAgdmFyIHJvd3AgPSBwLmRhdGFbcGluZGV4W2tdXTtcbiAgICAgIGlmIChrIGluIGZpbmRleCkge1xuICAgICAgICAvLyB2YWx1ZSBleGlzdHMgaW4gZm9yZWlnbiB0YWJsZVxuICAgICAgICB2YXIgcm93ZiA9IGYuZGF0YVtmaW5kZXhba11dO1xuICAgICAgICBqZGF0YS5wdXNoKGpvaW5GaWVsZHMocm93cCwgcm93Ziwgc2VsZWN0RmllbGRzLCBwLmhlYWRlcl9sdXQsIGYuaGVhZGVyX2x1dCkpO1xuICAgICAgICBmaW5kZXhba10gPSAtMTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIHB1c2ggZGF0YSBmcm9tIHByaW1hcnkgdGFibGVcbiAgICAgICAgamRhdGEucHVzaChqb2luRmllbGRzKHJvd3AsIFtdLCBzZWxlY3RGaWVsZHMsIHAuaGVhZGVyX2x1dCwge30pKTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICAvLyBhZGQgdW5tYXRjaGVkIHJvd3MgZnJvbSBmb3JlaWduIHRhYmxlXG4gICAgZm9yICh2YXIgayBpbiBmaW5kZXgpIHtcbiAgICAgaWYgKGZpbmRleFtrXSA+PTApIHsgICAgICBcbiAgICAgICBqZGF0YS5wdXNoKGpvaW5GaWVsZHMoW10sIGYuZGF0YVtmaW5kZXhba11dLCBzZWxlY3RGaWVsZHMsIHt9LCBmLmhlYWRlcl9sdXQpKTtcbiAgICAgfVxuICAgfVxuXG4gICB2YXIgaiA9IG1ha2VUYWJsZShqZGF0YSwgc2VsZWN0RmllbGRzKTtcbiAgIHJldHVybiBqO1xufVxuXG4vKipcbiAqIGBgYFBlcmZvcm0gYW4gaW5uZXIgam9pbiBvZiB0d28gdGFibGVzLmBgYFxuICogQGZ1bmN0aW9uIGlubmVySm9pblxuICogQHBhcmFtIHtvYmplY3R9IHRhYmxlIFRhYmxlIG9iamVjdCByZXR1cm5lZCBieSBwYXJzZVRhYmxlXG4gKiBAcGFyYW0ge29iamVjdH0gdGFibGUgVGFibGUgb2JqZWN0IHJldHVybmVkIGJ5IHBhcnNlVGFibGVcbiAqIEBwYXJhbSB7c3RyaW5nfSBwcmltYXJ5S2V5XG4gKiBAcGFyYW0ge3N0cmluZ30gZm9yZWlnbktleVxuICogQHBhcmFtIHtzdHJpbmd9IHNlbGVjdEZpZWxkcyBMaXN0IG9mIGZpZWxkbmFtZXMgdG8ga2VlcCBpbiB0aGUgam9pblxuICogQHJldHVybnMge1RhYmxlfSBPYmplY3Qgb2YgVGFibGUgb2JqZWN0c1xuKi9cbmZ1bmN0aW9uIGlubmVySm9pbihwLCBmLCBwcmltYXJ5S2V5LCBmb3JlaWduS2V5LCBzZWxlY3RGaWVsZHMpIHtcbiAgdmFyIG5wID0gcC5ucm93LCBuZiA9IGYubnJvdywgaW5kZXggPSB7fSwgamRhdGE9W107XG4gIFxuICAgLy8gY29sdW1uIGluZGV4IG9mIHByaW1hcnkga2V5XG4gICB2YXIgcGtpID0gcC5oZWFkZXJfbHV0W3ByaW1hcnlLZXldO1xuXG4gICAgLy8gQ29uc3RydWN0IGxvb2t1cCBvZiBwcmltYXJ5IGtleSBpbmRpY2VzXG4gICAgZm9yICh2YXIgaT0wOyBpPG5wOyBpKyspIHtcbiAgICAgdmFyIHJvdyA9IHAuZGF0YVtpXTtcbiAgICAgaW5kZXhbcm93W3BraV1dID0gaTtcbiAgIH1cblxuICAgdmFyIGZraSA9IGYuaGVhZGVyX2x1dFtmb3JlaWduS2V5XTtcbiAgIGZvciAodmFyIGk9MDsgaTxuZjsgaSsrKSB7XG4gICAgIHZhciByb3dmID0gZi5kYXRhW2ldO1xuICAgICB2YXIgcm93cCA9IHAuZGF0YVtpbmRleFtyb3dmW2ZraV1dXTtcbiAgICAgamRhdGEucHVzaChqb2luRmllbGRzKHJvd3AsIHJvd2YsIHNlbGVjdEZpZWxkcywgcC5oZWFkZXJfbHV0LCBmLmhlYWRlcl9sdXQpKTtcbiAgIH1cbiAgIHZhciBqID0gbWFrZVRhYmxlKGpkYXRhLCBzZWxlY3RGaWVsZHMpO1xuICAgcmV0dXJuIGo7XG4gfVxuXG4gZnVuY3Rpb24gbWFrZVRhYmxlKGRhdGEsIGZpZWxkcykge1xuICB2YXIgaGVhZGVyX2x1dCA9IHV0aWwubGlzdDJpbmRleChmaWVsZHMpO1xuICByZXR1cm4geyducm93JzpkYXRhLmxlbmd0aCwgXG4gICduY29sJzpmaWVsZHMubGVuZ3RoLCBcbiAgJ2RhdGEnOmRhdGEsIFxuICAnaGVhZGVyJzpmaWVsZHMsIFxuICAnaGVhZGVyX2x1dCc6aGVhZGVyX2x1dH07XG59XG5cbi8qKlxuICogYGBgcmV0YWluIHNwZWNpZmllZCBmaWVsZHMgZ2l2ZW4gdHdvIHRhYmxlIHJvd3MuYGBgXG4gKiBAZnVuY3Rpb24gam9pbkZpZWxkc1xuICogQHBhcmFtIHtBcnJheX0gcm93cCBSb3cgZnJvbSBwcmltYXJ5IHRhYmxlXG4gKiBAcGFyYW0ge0FycmF5fSByb3dmIFJvdyBmcm9tIGZvcmVpZ24gdGFibGVcbiAqIEBwYXJhbSB7QXJyYXl9IGtlZXBmaWVsZCBBcnJheSBvZiBmaWVsZHMgdG8gcmV0YWluIGZyb20gYm90aCB0YWJsZXNcbiAqIEBwYXJhbSB7QXJyYXl9IHBoX2x1dCBPYmplY3Qgb2YgZmllbGRzIHRvIGNvbHVtbiBpbmRpY2VzIGZvciBwcmltYXJ5IHRhYmxlXG4gKiBAcGFyYW0ge0FycmF5fSBmaF9sdXQgT2JqZWN0IG9mIGZpZWxkcyB0byBjb2x1bW4gaW5kaWNlcyBmb3IgZm9yZWlnbiB0YWJsZVxuKi9cbmZ1bmN0aW9uIGpvaW5GaWVsZHMocm93cCwgcm93Ziwga2VlcGZpZWxkLCBwaF9sdXQsIGZoX2x1dCkge1xuICAgIHZhciBuayA9IGtlZXBmaWVsZC5sZW5ndGgsIGpvaW49W107XG4gICAgZm9yICh2YXIgaT0wOyBpPG5rOyBpKyspe1xuXHRpZiAoa2VlcGZpZWxkW2ldIGluIHBoX2x1dCkge1xuXHQgICAgam9pbi5wdXNoKHJvd3BbcGhfbHV0W2tlZXBmaWVsZFtpXV1dKTtcblx0fVxuXHRlbHNlIGlmIChrZWVwZmllbGRbaV0gaW4gZmhfbHV0KSB7IFxuXHQgICAgam9pbi5wdXNoKHJvd2ZbZmhfbHV0W2tlZXBmaWVsZFtpXV1dKTtcblx0fVxuXHRlbHNlIHtqb2luLnB1c2goW10pfTtcbiAgICB9XG4gICAgcmV0dXJuIGpvaW47XG59XG4gXG4vKipcbiAqIGBgYFNwbGl0IGEgdGFibGUgYnkgYSBnaXZlbiBmaWVsZC5gYGBcbiAqIEBmdW5jdGlvbiBzcGxpdFRhYmxlXG4gKiBAcGFyYW0ge29iamVjdH0gdGFibGUgVGFibGUgb2JqZWN0IHJldHVybmVkIGJ5IHBhcnNlVGFibGVcbiAqIEBwYXJhbSB7c3RyaW5nfSBzcGxpdF9ieSBGaWVsZG5hbWUgdG8gc3BsaXQgYnkgICAgXG4gKiBAcmV0dXJucyB7VGFibGV9IE9iamVjdCBvZiBUYWJsZSBvYmplY3RzXG4qL1xuZnVuY3Rpb24gc3BsaXRUYWJsZSh0YWJsZSwgc3BsaXRfYnkpIHtcbiAgdmFyIHNwbGl0ID0ge307XG4gIHZhciBjaWR4ID0gdGFibGUuaGVhZGVyX2x1dFtzcGxpdF9ieV07XG4gIHZhciBpPTAsIHJvdztcbiAgZm9yIChpPTA7IGk8dGFibGUuZGF0YS5sZW5ndGg7IGkrKykge1xuICAgIHJvdyA9IHRhYmxlLmRhdGFbaV07XG4gICAgaWYgKHNwbGl0W3Jvd1tjaWR4XV09PT11bmRlZmluZWQpIHtcbiAgICAgIHNwbGl0W3Jvd1tjaWR4XV0gPSB7bnJvdzowLCBuY29sOjAsIGRhdGE6W10sIGhlYWRlcjpbXSwgaGVhZGVyX2x1dDpbXX07XG4gICAgfVxuICAgIHNwbGl0W3Jvd1tjaWR4XV0uZGF0YS5wdXNoKHJvdyk7XG4gIH1cbiAgXG4gIGZvciAodmFyIGtleSBpbiBzcGxpdCl7XG4gICAgc3BsaXRba2V5XS5ucm93ID0gc3BsaXRba2V5XS5kYXRhLmxlbmd0aDtcbiAgICBzcGxpdFtrZXldLm5jb2wgPSB0YWJsZS5kYXRhLmxlbmd0aDtcbiAgICBzcGxpdFtrZXldLmhlYWRlciA9IHRhYmxlLmhlYWRlcjtcbiAgICBzcGxpdFtrZXldLmhlYWRlcl9sdXQgPSB0YWJsZS5oZWFkZXJfbHV0O1xuICB9XG5cbiAgcmV0dXJuIHNwbGl0O1xufVxuXG4vKiogXG4qIGBgYFByZXBlbmRzIGFuIGluZGV4IGNvbHVtbiB0byBhIHRhYmxlYGBgXG4qIEBmdW5jdGlvbiBpbnNlcnRDb2x1bW5JbmRleFxuKiBAcGFyYW0ge29iamVjdH0gdGFibGUgVGFibGUgb2JqZWN0XG4qIEBwYXJhbSB7c3RyaW5nfSBjb2x1bW5fbmFtZSBOYW1lIG9mIGluc2VydGVkIGNvbHVtblxuKiBAcmV0dXJucyB7VGFibGV9IHRhYmxlIFRhYmxlIG9iamVjdCB3aXRoIGluc2VydGVkIGNvbHVtblxuKi9cbmZ1bmN0aW9uIGluc2VydENvbHVtbkluZGV4KHRhYmxlLCBjb2x1bW5fbmFtZSkge1xuICBmb3IgKGk9MDsgaTx0YWJsZS5kYXRhLmxlbmd0aDsgaSsrKSB7XG4gICAgdGFibGUuZGF0YVtpXT1baSsxXS5jb25jYXQodGFibGUuZGF0YVtpXSk7XG4gIH1cbiAgdGFibGUuaGVhZGVyID0gW2NvbHVtbl9uYW1lXS5jb25jYXQodGFibGUuaGVhZGVyKTtcbiAgdGFibGUuaGVhZGVyX2x1dCA9IHV0aWwubGlzdDJpbmRleCh0YWJsZS5oZWFkZXIpOyAgICBcbiAgcmV0dXJuIHRhYmxlOyAgXG59XG4iLCIvLyBQdWJsaWNcbmV4cG9ydHMubGlzdDJpbmRleCA9IGxpc3QyaW5kZXg7XG5leHBvcnRzLnBpY2sgPSBwaWNrO1xuXG4vKipcbiAqIEBmdW5jdGlvbiBsaXN0MmluZGV4XG4gKiBAbWVtYmVyb2YgTW9ydGFyI1xuICogQGRlc2MgYGBgR2VuZXJhdGUgbG9va3VwIHRhYmxlIGZvciBhbiBhcnJheSBvZiB2YWx1ZXMgdG8gdGhlaXIgemVyby1pbmRleGVkIHBvc2l0aW9uIFxuICogaW4gdGhlIGFycmF5LmBgYFxuICogTm90ZTogaW4gdGhlIGNhc2Ugb2YgZHVwbGljYXRlIHZhbHVlcywgdGhlIGluZGV4IG9mIHRoZSBsYXN0IFxuICogb2NjdXJyZW5jZSBvZiB0aGUgZWxlbWVudCBpcyByZXR1cm5lZC5cbiAqIEBwYXJhbSB7QXJyYXl9IGFycmF5IG9mIHZhbHVlcy5cbiAqIEByZXR1cm5zIHtPYmplY3R9IG9iamVjdCBvZiB2YWx1ZXMgdG8gemVyby1iYXNlZCBhcnJheSBpbmRpY2VzXG4gKi9cblxuZnVuY3Rpb24gbGlzdDJpbmRleChsaXN0KSB7XG4gIHZhciBsdXQgPSB7fTtcbiAgdmFyIGk7XG4gIGZvciAoaSA9IDA7IGk8bGlzdC5sZW5ndGg7IGkrKykge1xuICAgICAgbHV0W2xpc3RbaV1dID0gaTtcbiAgfVxuICByZXR1cm4gbHV0O1xufVxuXG4vKipcbiAqIEBmdW5jdGlvbiBwaWNrXG4gKiBAbWVtYmVyb2YgTW9ydGFyI1xuICogQGRlc2MgYGBgUmV0dXJucyBhcmcgaWYgZGVmaW5lZCBlbHNlIHJldHVybiBkZWZgYGBcbiAqIEBwYXJhbSBhcmcgYXJndW1lbnRcbiAqIEBwYXJhbSBkZWYgZGVmYXVsdFxuICogQHJldHVybnMgdmFsdWVcbiAqIFxuICovXG5mdW5jdGlvbiBwaWNrKGFyZywgZGVmKSB7XG4gIHJldHVybiAodHlwZW9mIGFyZyA9PSAndW5kZWZpbmVkJyA/IGRlZiA6IGFyZyk7XG59IiwiLypcblx0QmFieSBQYXJzZVxuXHR2MC40LjFcblx0aHR0cHM6Ly9naXRodWIuY29tL1JpY2gtSGFycmlzL0JhYnlQYXJzZVxuXG5cdENyZWF0ZWQgYnkgUmljaCBIYXJyaXNcblx0TWFpbnRhaW5lZCBieSBNYXR0IEhvbHRcblxuXHRCYXNlZCBvbiBQYXBhIFBhcnNlIHY0LjAuNyBieSBNYXR0IEhvbHRcblx0aHR0cHM6Ly9naXRodWIuY29tL21ob2x0L1BhcGFQYXJzZVxuKi9cbihmdW5jdGlvbihnbG9iYWwpXG57XG5cblx0Ly8gQSBjb25maWd1cmF0aW9uIG9iamVjdCBmcm9tIHdoaWNoIHRvIGRyYXcgZGVmYXVsdCBzZXR0aW5nc1xuXHR2YXIgREVGQVVMVFMgPSB7XG5cdFx0ZGVsaW1pdGVyOiBcIlwiLFx0Ly8gZW1wdHk6IGF1dG8tZGV0ZWN0XG5cdFx0bmV3bGluZTogXCJcIixcdC8vIGVtcHR5OiBhdXRvLWRldGVjdFxuXHRcdGhlYWRlcjogZmFsc2UsXG5cdFx0ZHluYW1pY1R5cGluZzogZmFsc2UsXG5cdFx0cHJldmlldzogMCxcblx0XHRzdGVwOiB1bmRlZmluZWQsXG5cdFx0Y29tbWVudHM6IGZhbHNlLFxuXHRcdGNvbXBsZXRlOiB1bmRlZmluZWQsXG5cdFx0c2tpcEVtcHR5TGluZXM6IGZhbHNlLFxuXHRcdGZhc3RNb2RlOiBmYWxzZVxuXHR9O1xuXG5cdHZhciBCYWJ5ID0ge307XG5cdEJhYnkucGFyc2UgPSBDc3ZUb0pzb247XG5cdEJhYnkucGFyc2VGaWxlcyA9IFBhcnNlRmlsZXM7XG5cdEJhYnkudW5wYXJzZSA9IEpzb25Ub0Nzdjtcblx0QmFieS5SRUNPUkRfU0VQID0gU3RyaW5nLmZyb21DaGFyQ29kZSgzMCk7XG5cdEJhYnkuVU5JVF9TRVAgPSBTdHJpbmcuZnJvbUNoYXJDb2RlKDMxKTtcblx0QmFieS5CWVRFX09SREVSX01BUksgPSBcIlxcdWZlZmZcIjtcblx0QmFieS5CQURfREVMSU1JVEVSUyA9IFtcIlxcclwiLCBcIlxcblwiLCBcIlxcXCJcIiwgQmFieS5CWVRFX09SREVSX01BUktdO1xuXHRCYWJ5LkRlZmF1bHREZWxpbWl0ZXIgPSBcIixcIjtcdFx0Ly8gVXNlZCBpZiBub3Qgc3BlY2lmaWVkIGFuZCBkZXRlY3Rpb24gZmFpbHNcblx0QmFieS5QYXJzZXIgPSBQYXJzZXI7XHRcdFx0XHQvLyBGb3IgdGVzdGluZy9kZXYgb25seVxuXHRCYWJ5LlBhcnNlckhhbmRsZSA9IFBhcnNlckhhbmRsZTtcdC8vIEZvciB0ZXN0aW5nL2RldiBvbmx5XG5cdFxuXHR2YXIgZnMgPSBmcyB8fCByZXF1aXJlKCdmcycpXG5cdFxuXHRmdW5jdGlvbiBQYXJzZUZpbGVzKF9pbnB1dCwgX2NvbmZpZylcblx0e1xuXHRcdGlmIChBcnJheS5pc0FycmF5KF9pbnB1dCkpIHtcblx0XHRcdHZhciByZXN1bHRzID0gW107XG5cdFx0XHRfaW5wdXQuZm9yRWFjaChmdW5jdGlvbihpbnB1dCkge1xuXHRcdFx0XHRpZih0eXBlb2YgaW5wdXQgPT09ICdvYmplY3QnKVxuXHRcdFx0XHRcdHJlc3VsdHMucHVzaChQYXJzZUZpbGVzKGlucHV0LmZpbGUsIGlucHV0LmNvbmZpZykpO1xuXHRcdFx0XHRlbHNlXG5cdFx0XHRcdFx0cmVzdWx0cy5wdXNoKFBhcnNlRmlsZXMoaW5wdXQsIF9jb25maWcpKTtcblx0XHRcdH0pO1xuXHRcdFx0cmV0dXJuIHJlc3VsdHM7XG5cdFx0fSBlbHNlIHtcblx0XHRcdHZhciByZXN1bHRzID0ge1xuXHRcdFx0XHRkYXRhOiBbXSxcblx0XHRcdFx0ZXJyb3JzOiBbXVxuXHRcdFx0fTtcblx0XHRcdGlmICgoLyhcXC5jc3Z8XFwudHh0KSQvKS50ZXN0KF9pbnB1dCkpIHtcblx0XHRcdFx0dHJ5IHtcblx0XHRcdFx0XHR2YXIgY29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMoX2lucHV0KS50b1N0cmluZygpO1xuXHRcdFx0XHRcdHJldHVybiBDc3ZUb0pzb24oY29udGVudHMsIF9jb25maWcpO1xuXHRcdFx0XHR9IGNhdGNoIChlcnIpIHtcblx0XHRcdFx0XHRyZXN1bHRzLmVycm9ycy5wdXNoKGVycik7XG5cdFx0XHRcdFx0cmV0dXJuIHJlc3VsdHM7XG5cdFx0XHRcdH1cblx0XHRcdH0gZWxzZSB7XG5cdFx0XHRcdHJlc3VsdHMuZXJyb3JzLnB1c2goe1xuXHRcdFx0XHRcdHR5cGU6ICcnLFxuXHRcdFx0XHRcdGNvZGU6ICcnLFxuXHRcdFx0XHRcdG1lc3NhZ2U6ICdVbnN1cHBvcnRlZCBmaWxlIHR5cGUuJyxcblx0XHRcdFx0XHRyb3c6ICcnXG5cdFx0XHRcdH0pO1xuXHRcdFx0XHRyZXR1cm4gcmVzdWx0cztcblx0XHRcdH1cblx0XHR9XG5cdH1cblxuXHRmdW5jdGlvbiBDc3ZUb0pzb24oX2lucHV0LCBfY29uZmlnKVxuXHR7XG5cdFx0dmFyIGNvbmZpZyA9IGNvcHlBbmRWYWxpZGF0ZUNvbmZpZyhfY29uZmlnKTtcblx0XHR2YXIgcGggPSBuZXcgUGFyc2VySGFuZGxlKGNvbmZpZyk7XG5cdFx0dmFyIHJlc3VsdHMgPSBwaC5wYXJzZShfaW5wdXQpO1xuXHRcdHJldHVybiByZXN1bHRzO1xuXHR9XG5cblxuXG5cblx0ZnVuY3Rpb24gSnNvblRvQ3N2KF9pbnB1dCwgX2NvbmZpZylcblx0e1xuXHRcdHZhciBfb3V0cHV0ID0gXCJcIjtcblx0XHR2YXIgX2ZpZWxkcyA9IFtdO1xuXG5cdFx0Ly8gRGVmYXVsdCBjb25maWd1cmF0aW9uXG5cdFx0dmFyIF9xdW90ZXMgPSBmYWxzZTtcdC8vIHdoZXRoZXIgdG8gc3Vycm91bmQgZXZlcnkgZGF0dW0gd2l0aCBxdW90ZXNcblx0XHR2YXIgX2RlbGltaXRlciA9IFwiLFwiO1x0Ly8gZGVsaW1pdGluZyBjaGFyYWN0ZXJcblx0XHR2YXIgX25ld2xpbmUgPSBcIlxcclxcblwiO1x0Ly8gbmV3bGluZSBjaGFyYWN0ZXIocylcblxuXHRcdHVucGFja0NvbmZpZygpO1xuXG5cdFx0aWYgKHR5cGVvZiBfaW5wdXQgPT09ICdzdHJpbmcnKVxuXHRcdFx0X2lucHV0ID0gSlNPTi5wYXJzZShfaW5wdXQpO1xuXG5cdFx0aWYgKF9pbnB1dCBpbnN0YW5jZW9mIEFycmF5KVxuXHRcdHtcblx0XHRcdGlmICghX2lucHV0Lmxlbmd0aCB8fCBfaW5wdXRbMF0gaW5zdGFuY2VvZiBBcnJheSlcblx0XHRcdFx0cmV0dXJuIHNlcmlhbGl6ZShudWxsLCBfaW5wdXQpO1xuXHRcdFx0ZWxzZSBpZiAodHlwZW9mIF9pbnB1dFswXSA9PT0gJ29iamVjdCcpXG5cdFx0XHRcdHJldHVybiBzZXJpYWxpemUob2JqZWN0S2V5cyhfaW5wdXRbMF0pLCBfaW5wdXQpO1xuXHRcdH1cblx0XHRlbHNlIGlmICh0eXBlb2YgX2lucHV0ID09PSAnb2JqZWN0Jylcblx0XHR7XG5cdFx0XHRpZiAodHlwZW9mIF9pbnB1dC5kYXRhID09PSAnc3RyaW5nJylcblx0XHRcdFx0X2lucHV0LmRhdGEgPSBKU09OLnBhcnNlKF9pbnB1dC5kYXRhKTtcblxuXHRcdFx0aWYgKF9pbnB1dC5kYXRhIGluc3RhbmNlb2YgQXJyYXkpXG5cdFx0XHR7XG5cdFx0XHRcdGlmICghX2lucHV0LmZpZWxkcylcblx0XHRcdFx0XHRfaW5wdXQuZmllbGRzID0gX2lucHV0LmRhdGFbMF0gaW5zdGFuY2VvZiBBcnJheVxuXHRcdFx0XHRcdFx0XHRcdFx0PyBfaW5wdXQuZmllbGRzXG5cdFx0XHRcdFx0XHRcdFx0XHQ6IG9iamVjdEtleXMoX2lucHV0LmRhdGFbMF0pO1xuXG5cdFx0XHRcdGlmICghKF9pbnB1dC5kYXRhWzBdIGluc3RhbmNlb2YgQXJyYXkpICYmIHR5cGVvZiBfaW5wdXQuZGF0YVswXSAhPT0gJ29iamVjdCcpXG5cdFx0XHRcdFx0X2lucHV0LmRhdGEgPSBbX2lucHV0LmRhdGFdO1x0Ly8gaGFuZGxlcyBpbnB1dCBsaWtlIFsxLDIsM10gb3IgW1wiYXNkZlwiXVxuXHRcdFx0fVxuXG5cdFx0XHRyZXR1cm4gc2VyaWFsaXplKF9pbnB1dC5maWVsZHMgfHwgW10sIF9pbnB1dC5kYXRhIHx8IFtdKTtcblx0XHR9XG5cblx0XHQvLyBEZWZhdWx0IChhbnkgdmFsaWQgcGF0aHMgc2hvdWxkIHJldHVybiBiZWZvcmUgdGhpcylcblx0XHR0aHJvdyBcImV4Y2VwdGlvbjogVW5hYmxlIHRvIHNlcmlhbGl6ZSB1bnJlY29nbml6ZWQgaW5wdXRcIjtcblxuXG5cdFx0ZnVuY3Rpb24gdW5wYWNrQ29uZmlnKClcblx0XHR7XG5cdFx0XHRpZiAodHlwZW9mIF9jb25maWcgIT09ICdvYmplY3QnKVxuXHRcdFx0XHRyZXR1cm47XG5cblx0XHRcdGlmICh0eXBlb2YgX2NvbmZpZy5kZWxpbWl0ZXIgPT09ICdzdHJpbmcnXG5cdFx0XHRcdCYmIF9jb25maWcuZGVsaW1pdGVyLmxlbmd0aCA9PSAxXG5cdFx0XHRcdCYmIEJhYnkuQkFEX0RFTElNSVRFUlMuaW5kZXhPZihfY29uZmlnLmRlbGltaXRlcikgPT0gLTEpXG5cdFx0XHR7XG5cdFx0XHRcdF9kZWxpbWl0ZXIgPSBfY29uZmlnLmRlbGltaXRlcjtcblx0XHRcdH1cblxuXHRcdFx0aWYgKHR5cGVvZiBfY29uZmlnLnF1b3RlcyA9PT0gJ2Jvb2xlYW4nXG5cdFx0XHRcdHx8IF9jb25maWcucXVvdGVzIGluc3RhbmNlb2YgQXJyYXkpXG5cdFx0XHRcdF9xdW90ZXMgPSBfY29uZmlnLnF1b3RlcztcblxuXHRcdFx0aWYgKHR5cGVvZiBfY29uZmlnLm5ld2xpbmUgPT09ICdzdHJpbmcnKVxuXHRcdFx0XHRfbmV3bGluZSA9IF9jb25maWcubmV3bGluZTtcblx0XHR9XG5cblxuXHRcdC8vIFR1cm5zIGFuIG9iamVjdCdzIGtleXMgaW50byBhbiBhcnJheVxuXHRcdGZ1bmN0aW9uIG9iamVjdEtleXMob2JqKVxuXHRcdHtcblx0XHRcdGlmICh0eXBlb2Ygb2JqICE9PSAnb2JqZWN0Jylcblx0XHRcdFx0cmV0dXJuIFtdO1xuXHRcdFx0dmFyIGtleXMgPSBbXTtcblx0XHRcdGZvciAodmFyIGtleSBpbiBvYmopXG5cdFx0XHRcdGtleXMucHVzaChrZXkpO1xuXHRcdFx0cmV0dXJuIGtleXM7XG5cdFx0fVxuXG5cdFx0Ly8gVGhlIGRvdWJsZSBmb3IgbG9vcCB0aGF0IGl0ZXJhdGVzIHRoZSBkYXRhIGFuZCB3cml0ZXMgb3V0IGEgQ1NWIHN0cmluZyBpbmNsdWRpbmcgaGVhZGVyIHJvd1xuXHRcdGZ1bmN0aW9uIHNlcmlhbGl6ZShmaWVsZHMsIGRhdGEpXG5cdFx0e1xuXHRcdFx0dmFyIGNzdiA9IFwiXCI7XG5cblx0XHRcdGlmICh0eXBlb2YgZmllbGRzID09PSAnc3RyaW5nJylcblx0XHRcdFx0ZmllbGRzID0gSlNPTi5wYXJzZShmaWVsZHMpO1xuXHRcdFx0aWYgKHR5cGVvZiBkYXRhID09PSAnc3RyaW5nJylcblx0XHRcdFx0ZGF0YSA9IEpTT04ucGFyc2UoZGF0YSk7XG5cblx0XHRcdHZhciBoYXNIZWFkZXIgPSBmaWVsZHMgaW5zdGFuY2VvZiBBcnJheSAmJiBmaWVsZHMubGVuZ3RoID4gMDtcblx0XHRcdHZhciBkYXRhS2V5ZWRCeUZpZWxkID0gIShkYXRhWzBdIGluc3RhbmNlb2YgQXJyYXkpO1xuXG5cdFx0XHQvLyBJZiB0aGVyZSBhIGhlYWRlciByb3csIHdyaXRlIGl0IGZpcnN0XG5cdFx0XHRpZiAoaGFzSGVhZGVyKVxuXHRcdFx0e1xuXHRcdFx0XHRmb3IgKHZhciBpID0gMDsgaSA8IGZpZWxkcy5sZW5ndGg7IGkrKylcblx0XHRcdFx0e1xuXHRcdFx0XHRcdGlmIChpID4gMClcblx0XHRcdFx0XHRcdGNzdiArPSBfZGVsaW1pdGVyO1xuXHRcdFx0XHRcdGNzdiArPSBzYWZlKGZpZWxkc1tpXSwgaSk7XG5cdFx0XHRcdH1cblx0XHRcdFx0aWYgKGRhdGEubGVuZ3RoID4gMClcblx0XHRcdFx0XHRjc3YgKz0gX25ld2xpbmU7XG5cdFx0XHR9XG5cblx0XHRcdC8vIFRoZW4gd3JpdGUgb3V0IHRoZSBkYXRhXG5cdFx0XHRmb3IgKHZhciByb3cgPSAwOyByb3cgPCBkYXRhLmxlbmd0aDsgcm93KyspXG5cdFx0XHR7XG5cdFx0XHRcdHZhciBtYXhDb2wgPSBoYXNIZWFkZXIgPyBmaWVsZHMubGVuZ3RoIDogZGF0YVtyb3ddLmxlbmd0aDtcblxuXHRcdFx0XHRmb3IgKHZhciBjb2wgPSAwOyBjb2wgPCBtYXhDb2w7IGNvbCsrKVxuXHRcdFx0XHR7XG5cdFx0XHRcdFx0aWYgKGNvbCA+IDApXG5cdFx0XHRcdFx0XHRjc3YgKz0gX2RlbGltaXRlcjtcblx0XHRcdFx0XHR2YXIgY29sSWR4ID0gaGFzSGVhZGVyICYmIGRhdGFLZXllZEJ5RmllbGQgPyBmaWVsZHNbY29sXSA6IGNvbDtcblx0XHRcdFx0XHRjc3YgKz0gc2FmZShkYXRhW3Jvd11bY29sSWR4XSwgY29sKTtcblx0XHRcdFx0fVxuXG5cdFx0XHRcdGlmIChyb3cgPCBkYXRhLmxlbmd0aCAtIDEpXG5cdFx0XHRcdFx0Y3N2ICs9IF9uZXdsaW5lO1xuXHRcdFx0fVxuXG5cdFx0XHRyZXR1cm4gY3N2O1xuXHRcdH1cblxuXHRcdC8vIEVuY2xvc2VzIGEgdmFsdWUgYXJvdW5kIHF1b3RlcyBpZiBuZWVkZWQgKG1ha2VzIGEgdmFsdWUgc2FmZSBmb3IgQ1NWIGluc2VydGlvbilcblx0XHRmdW5jdGlvbiBzYWZlKHN0ciwgY29sKVxuXHRcdHtcblx0XHRcdGlmICh0eXBlb2Ygc3RyID09PSBcInVuZGVmaW5lZFwiIHx8IHN0ciA9PT0gbnVsbClcblx0XHRcdFx0cmV0dXJuIFwiXCI7XG5cblx0XHRcdHN0ciA9IHN0ci50b1N0cmluZygpLnJlcGxhY2UoL1wiL2csICdcIlwiJyk7XG5cblx0XHRcdHZhciBuZWVkc1F1b3RlcyA9ICh0eXBlb2YgX3F1b3RlcyA9PT0gJ2Jvb2xlYW4nICYmIF9xdW90ZXMpXG5cdFx0XHRcdFx0XHRcdHx8IChfcXVvdGVzIGluc3RhbmNlb2YgQXJyYXkgJiYgX3F1b3Rlc1tjb2xdKVxuXHRcdFx0XHRcdFx0XHR8fCBoYXNBbnkoc3RyLCBCYWJ5LkJBRF9ERUxJTUlURVJTKVxuXHRcdFx0XHRcdFx0XHR8fCBzdHIuaW5kZXhPZihfZGVsaW1pdGVyKSA+IC0xXG5cdFx0XHRcdFx0XHRcdHx8IHN0ci5jaGFyQXQoMCkgPT0gJyAnXG5cdFx0XHRcdFx0XHRcdHx8IHN0ci5jaGFyQXQoc3RyLmxlbmd0aCAtIDEpID09ICcgJztcblxuXHRcdFx0cmV0dXJuIG5lZWRzUXVvdGVzID8gJ1wiJyArIHN0ciArICdcIicgOiBzdHI7XG5cdFx0fVxuXG5cdFx0ZnVuY3Rpb24gaGFzQW55KHN0ciwgc3Vic3RyaW5ncylcblx0XHR7XG5cdFx0XHRmb3IgKHZhciBpID0gMDsgaSA8IHN1YnN0cmluZ3MubGVuZ3RoOyBpKyspXG5cdFx0XHRcdGlmIChzdHIuaW5kZXhPZihzdWJzdHJpbmdzW2ldKSA+IC0xKVxuXHRcdFx0XHRcdHJldHVybiB0cnVlO1xuXHRcdFx0cmV0dXJuIGZhbHNlO1xuXHRcdH1cblx0fVxuXG5cblxuXG5cblxuXHQvLyBVc2Ugb25lIFBhcnNlckhhbmRsZSBwZXIgZW50aXJlIENTViBmaWxlIG9yIHN0cmluZ1xuXHRmdW5jdGlvbiBQYXJzZXJIYW5kbGUoX2NvbmZpZylcblx0e1xuXHRcdC8vIE9uZSBnb2FsIGlzIHRvIG1pbmltaXplIHRoZSB1c2Ugb2YgcmVndWxhciBleHByZXNzaW9ucy4uLlxuXHRcdHZhciBGTE9BVCA9IC9eXFxzKi0/KFxcZCpcXC4/XFxkK3xcXGQrXFwuP1xcZCopKGVbLStdP1xcZCspP1xccyokL2k7XG5cblx0XHR2YXIgc2VsZiA9IHRoaXM7XG5cdFx0dmFyIF9zdGVwQ291bnRlciA9IDA7XHQvLyBOdW1iZXIgb2YgdGltZXMgc3RlcCB3YXMgY2FsbGVkIChudW1iZXIgb2Ygcm93cyBwYXJzZWQpXG5cdFx0dmFyIF9pbnB1dDtcdFx0XHRcdC8vIFRoZSBpbnB1dCBiZWluZyBwYXJzZWRcblx0XHR2YXIgX3BhcnNlcjtcdFx0XHQvLyBUaGUgY29yZSBwYXJzZXIgYmVpbmcgdXNlZFxuXHRcdHZhciBfcGF1c2VkID0gZmFsc2U7XHQvLyBXaGV0aGVyIHdlIGFyZSBwYXVzZWQgb3Igbm90XG5cdFx0dmFyIF9kZWxpbWl0ZXJFcnJvcjtcdC8vIFRlbXBvcmFyeSBzdGF0ZSBiZXR3ZWVuIGRlbGltaXRlciBkZXRlY3Rpb24gYW5kIHByb2Nlc3NpbmcgcmVzdWx0c1xuXHRcdHZhciBfZmllbGRzID0gW107XHRcdC8vIEZpZWxkcyBhcmUgZnJvbSB0aGUgaGVhZGVyIHJvdyBvZiB0aGUgaW5wdXQsIGlmIHRoZXJlIGlzIG9uZVxuXHRcdHZhciBfcmVzdWx0cyA9IHtcdFx0Ly8gVGhlIGxhc3QgcmVzdWx0cyByZXR1cm5lZCBmcm9tIHRoZSBwYXJzZXJcblx0XHRcdGRhdGE6IFtdLFxuXHRcdFx0ZXJyb3JzOiBbXSxcblx0XHRcdG1ldGE6IHt9XG5cdFx0fTtcblxuXHRcdGlmIChpc0Z1bmN0aW9uKF9jb25maWcuc3RlcCkpXG5cdFx0e1xuXHRcdFx0dmFyIHVzZXJTdGVwID0gX2NvbmZpZy5zdGVwO1xuXHRcdFx0X2NvbmZpZy5zdGVwID0gZnVuY3Rpb24ocmVzdWx0cylcblx0XHRcdHtcblx0XHRcdFx0X3Jlc3VsdHMgPSByZXN1bHRzO1xuXG5cdFx0XHRcdGlmIChuZWVkc0hlYWRlclJvdygpKVxuXHRcdFx0XHRcdHByb2Nlc3NSZXN1bHRzKCk7XG5cdFx0XHRcdGVsc2VcdC8vIG9ubHkgY2FsbCB1c2VyJ3Mgc3RlcCBmdW5jdGlvbiBhZnRlciBoZWFkZXIgcm93XG5cdFx0XHRcdHtcblx0XHRcdFx0XHRwcm9jZXNzUmVzdWx0cygpO1xuXG5cdFx0XHRcdFx0Ly8gSXQncyBwb3NzYmlsZSB0aGF0IHRoaXMgbGluZSB3YXMgZW1wdHkgYW5kIHRoZXJlJ3Mgbm8gcm93IGhlcmUgYWZ0ZXIgYWxsXG5cdFx0XHRcdFx0aWYgKF9yZXN1bHRzLmRhdGEubGVuZ3RoID09IDApXG5cdFx0XHRcdFx0XHRyZXR1cm47XG5cblx0XHRcdFx0XHRfc3RlcENvdW50ZXIgKz0gcmVzdWx0cy5kYXRhLmxlbmd0aDtcblx0XHRcdFx0XHRpZiAoX2NvbmZpZy5wcmV2aWV3ICYmIF9zdGVwQ291bnRlciA+IF9jb25maWcucHJldmlldylcblx0XHRcdFx0XHRcdF9wYXJzZXIuYWJvcnQoKTtcblx0XHRcdFx0XHRlbHNlXG5cdFx0XHRcdFx0XHR1c2VyU3RlcChfcmVzdWx0cywgc2VsZik7XG5cdFx0XHRcdH1cblx0XHRcdH07XG5cdFx0fVxuXG5cdFx0dGhpcy5wYXJzZSA9IGZ1bmN0aW9uKGlucHV0KVxuXHRcdHtcblx0XHRcdGlmICghX2NvbmZpZy5uZXdsaW5lKVxuXHRcdFx0XHRfY29uZmlnLm5ld2xpbmUgPSBndWVzc0xpbmVFbmRpbmdzKGlucHV0KTtcblxuXHRcdFx0X2RlbGltaXRlckVycm9yID0gZmFsc2U7XG5cdFx0XHRpZiAoIV9jb25maWcuZGVsaW1pdGVyKVxuXHRcdFx0e1xuXHRcdFx0XHR2YXIgZGVsaW1HdWVzcyA9IGd1ZXNzRGVsaW1pdGVyKGlucHV0KTtcblx0XHRcdFx0aWYgKGRlbGltR3Vlc3Muc3VjY2Vzc2Z1bClcblx0XHRcdFx0XHRfY29uZmlnLmRlbGltaXRlciA9IGRlbGltR3Vlc3MuYmVzdERlbGltaXRlcjtcblx0XHRcdFx0ZWxzZVxuXHRcdFx0XHR7XG5cdFx0XHRcdFx0X2RlbGltaXRlckVycm9yID0gdHJ1ZTtcdC8vIGFkZCBlcnJvciBhZnRlciBwYXJzaW5nIChvdGhlcndpc2UgaXQgd291bGQgYmUgb3ZlcndyaXR0ZW4pXG5cdFx0XHRcdFx0X2NvbmZpZy5kZWxpbWl0ZXIgPSBCYWJ5LkRlZmF1bHREZWxpbWl0ZXI7XG5cdFx0XHRcdH1cblx0XHRcdFx0X3Jlc3VsdHMubWV0YS5kZWxpbWl0ZXIgPSBfY29uZmlnLmRlbGltaXRlcjtcblx0XHRcdH1cblxuXHRcdFx0dmFyIHBhcnNlckNvbmZpZyA9IGNvcHkoX2NvbmZpZyk7XG5cdFx0XHRpZiAoX2NvbmZpZy5wcmV2aWV3ICYmIF9jb25maWcuaGVhZGVyKVxuXHRcdFx0XHRwYXJzZXJDb25maWcucHJldmlldysrO1x0Ly8gdG8gY29tcGVuc2F0ZSBmb3IgaGVhZGVyIHJvd1xuXG5cdFx0XHRfaW5wdXQgPSBpbnB1dDtcblx0XHRcdF9wYXJzZXIgPSBuZXcgUGFyc2VyKHBhcnNlckNvbmZpZyk7XG5cdFx0XHRfcmVzdWx0cyA9IF9wYXJzZXIucGFyc2UoX2lucHV0KTtcblx0XHRcdHByb2Nlc3NSZXN1bHRzKCk7XG5cdFx0XHRpZiAoaXNGdW5jdGlvbihfY29uZmlnLmNvbXBsZXRlKSAmJiAhX3BhdXNlZCAmJiAoIXNlbGYuc3RyZWFtZXIgfHwgc2VsZi5zdHJlYW1lci5maW5pc2hlZCgpKSlcblx0XHRcdFx0X2NvbmZpZy5jb21wbGV0ZShfcmVzdWx0cyk7XG5cdFx0XHRyZXR1cm4gX3BhdXNlZCA/IHsgbWV0YTogeyBwYXVzZWQ6IHRydWUgfSB9IDogKF9yZXN1bHRzIHx8IHsgbWV0YTogeyBwYXVzZWQ6IGZhbHNlIH0gfSk7XG5cdFx0fTtcblxuXHRcdHRoaXMucGF1c2UgPSBmdW5jdGlvbigpXG5cdFx0e1xuXHRcdFx0X3BhdXNlZCA9IHRydWU7XG5cdFx0XHRfcGFyc2VyLmFib3J0KCk7XG5cdFx0XHRfaW5wdXQgPSBfaW5wdXQuc3Vic3RyKF9wYXJzZXIuZ2V0Q2hhckluZGV4KCkpO1xuXHRcdH07XG5cblx0XHR0aGlzLnJlc3VtZSA9IGZ1bmN0aW9uKClcblx0XHR7XG5cdFx0XHRfcGF1c2VkID0gZmFsc2U7XG5cdFx0XHRfcGFyc2VyID0gbmV3IFBhcnNlcihfY29uZmlnKTtcblx0XHRcdF9wYXJzZXIucGFyc2UoX2lucHV0KTtcblx0XHRcdGlmICghX3BhdXNlZClcblx0XHRcdHtcblx0XHRcdFx0aWYgKHNlbGYuc3RyZWFtZXIgJiYgIXNlbGYuc3RyZWFtZXIuZmluaXNoZWQoKSlcblx0XHRcdFx0XHRzZWxmLnN0cmVhbWVyLnJlc3VtZSgpO1x0XHQvLyBtb3JlIG9mIHRoZSBmaWxlIHlldCB0byBjb21lXG5cdFx0XHRcdGVsc2UgaWYgKGlzRnVuY3Rpb24oX2NvbmZpZy5jb21wbGV0ZSkpXG5cdFx0XHRcdFx0X2NvbmZpZy5jb21wbGV0ZShfcmVzdWx0cyk7XG5cdFx0XHR9XG5cdFx0fTtcblxuXHRcdHRoaXMuYWJvcnQgPSBmdW5jdGlvbigpXG5cdFx0e1xuXHRcdFx0X3BhcnNlci5hYm9ydCgpO1xuXHRcdFx0aWYgKGlzRnVuY3Rpb24oX2NvbmZpZy5jb21wbGV0ZSkpXG5cdFx0XHRcdF9jb25maWcuY29tcGxldGUoX3Jlc3VsdHMpO1xuXHRcdFx0X2lucHV0ID0gXCJcIjtcblx0XHR9O1xuXG5cdFx0ZnVuY3Rpb24gcHJvY2Vzc1Jlc3VsdHMoKVxuXHRcdHtcblx0XHRcdGlmIChfcmVzdWx0cyAmJiBfZGVsaW1pdGVyRXJyb3IpXG5cdFx0XHR7XG5cdFx0XHRcdGFkZEVycm9yKFwiRGVsaW1pdGVyXCIsIFwiVW5kZXRlY3RhYmxlRGVsaW1pdGVyXCIsIFwiVW5hYmxlIHRvIGF1dG8tZGV0ZWN0IGRlbGltaXRpbmcgY2hhcmFjdGVyOyBkZWZhdWx0ZWQgdG8gJ1wiK0JhYnkuRGVmYXVsdERlbGltaXRlcitcIidcIik7XG5cdFx0XHRcdF9kZWxpbWl0ZXJFcnJvciA9IGZhbHNlO1xuXHRcdFx0fVxuXG5cdFx0XHRpZiAoX2NvbmZpZy5za2lwRW1wdHlMaW5lcylcblx0XHRcdHtcblx0XHRcdFx0Zm9yICh2YXIgaSA9IDA7IGkgPCBfcmVzdWx0cy5kYXRhLmxlbmd0aDsgaSsrKVxuXHRcdFx0XHRcdGlmIChfcmVzdWx0cy5kYXRhW2ldLmxlbmd0aCA9PSAxICYmIF9yZXN1bHRzLmRhdGFbaV1bMF0gPT0gXCJcIilcblx0XHRcdFx0XHRcdF9yZXN1bHRzLmRhdGEuc3BsaWNlKGktLSwgMSk7XG5cdFx0XHR9XG5cblx0XHRcdGlmIChuZWVkc0hlYWRlclJvdygpKVxuXHRcdFx0XHRmaWxsSGVhZGVyRmllbGRzKCk7XG5cblx0XHRcdHJldHVybiBhcHBseUhlYWRlckFuZER5bmFtaWNUeXBpbmcoKTtcblx0XHR9XG5cblx0XHRmdW5jdGlvbiBuZWVkc0hlYWRlclJvdygpXG5cdFx0e1xuXHRcdFx0cmV0dXJuIF9jb25maWcuaGVhZGVyICYmIF9maWVsZHMubGVuZ3RoID09IDA7XG5cdFx0fVxuXG5cdFx0ZnVuY3Rpb24gZmlsbEhlYWRlckZpZWxkcygpXG5cdFx0e1xuXHRcdFx0aWYgKCFfcmVzdWx0cylcblx0XHRcdFx0cmV0dXJuO1xuXHRcdFx0Zm9yICh2YXIgaSA9IDA7IG5lZWRzSGVhZGVyUm93KCkgJiYgaSA8IF9yZXN1bHRzLmRhdGEubGVuZ3RoOyBpKyspXG5cdFx0XHRcdGZvciAodmFyIGogPSAwOyBqIDwgX3Jlc3VsdHMuZGF0YVtpXS5sZW5ndGg7IGorKylcblx0XHRcdFx0XHRfZmllbGRzLnB1c2goX3Jlc3VsdHMuZGF0YVtpXVtqXSk7XG5cdFx0XHRfcmVzdWx0cy5kYXRhLnNwbGljZSgwLCAxKTtcblx0XHR9XG5cblx0XHRmdW5jdGlvbiBhcHBseUhlYWRlckFuZER5bmFtaWNUeXBpbmcoKVxuXHRcdHtcblx0XHRcdGlmICghX3Jlc3VsdHMgfHwgKCFfY29uZmlnLmhlYWRlciAmJiAhX2NvbmZpZy5keW5hbWljVHlwaW5nKSlcblx0XHRcdFx0cmV0dXJuIF9yZXN1bHRzO1xuXG5cdFx0XHRmb3IgKHZhciBpID0gMDsgaSA8IF9yZXN1bHRzLmRhdGEubGVuZ3RoOyBpKyspXG5cdFx0XHR7XG5cdFx0XHRcdHZhciByb3cgPSB7fTtcblxuXHRcdFx0XHRmb3IgKHZhciBqID0gMDsgaiA8IF9yZXN1bHRzLmRhdGFbaV0ubGVuZ3RoOyBqKyspXG5cdFx0XHRcdHtcblx0XHRcdFx0XHRpZiAoX2NvbmZpZy5keW5hbWljVHlwaW5nKVxuXHRcdFx0XHRcdHtcblx0XHRcdFx0XHRcdHZhciB2YWx1ZSA9IF9yZXN1bHRzLmRhdGFbaV1bal07XG5cdFx0XHRcdFx0XHRpZiAodmFsdWUgPT0gXCJ0cnVlXCIgfHwgdmFsdWUgPT09IFwiVFJVRVwiKVxuXHRcdFx0XHRcdFx0XHRfcmVzdWx0cy5kYXRhW2ldW2pdID0gdHJ1ZTtcblx0XHRcdFx0XHRcdGVsc2UgaWYgKHZhbHVlID09IFwiZmFsc2VcIiB8fCB2YWx1ZSA9PT0gXCJGQUxTRVwiKVxuXHRcdFx0XHRcdFx0XHRfcmVzdWx0cy5kYXRhW2ldW2pdID0gZmFsc2U7XG5cdFx0XHRcdFx0XHRlbHNlXG5cdFx0XHRcdFx0XHRcdF9yZXN1bHRzLmRhdGFbaV1bal0gPSB0cnlQYXJzZUZsb2F0KHZhbHVlKTtcblx0XHRcdFx0XHR9XG5cblx0XHRcdFx0XHRpZiAoX2NvbmZpZy5oZWFkZXIpXG5cdFx0XHRcdFx0e1xuXHRcdFx0XHRcdFx0aWYgKGogPj0gX2ZpZWxkcy5sZW5ndGgpXG5cdFx0XHRcdFx0XHR7XG5cdFx0XHRcdFx0XHRcdGlmICghcm93W1wiX19wYXJzZWRfZXh0cmFcIl0pXG5cdFx0XHRcdFx0XHRcdFx0cm93W1wiX19wYXJzZWRfZXh0cmFcIl0gPSBbXTtcblx0XHRcdFx0XHRcdFx0cm93W1wiX19wYXJzZWRfZXh0cmFcIl0ucHVzaChfcmVzdWx0cy5kYXRhW2ldW2pdKTtcblx0XHRcdFx0XHRcdH1cblx0XHRcdFx0XHRcdGVsc2Vcblx0XHRcdFx0XHRcdFx0cm93W19maWVsZHNbal1dID0gX3Jlc3VsdHMuZGF0YVtpXVtqXTtcblx0XHRcdFx0XHR9XG5cdFx0XHRcdH1cblxuXHRcdFx0XHRpZiAoX2NvbmZpZy5oZWFkZXIpXG5cdFx0XHRcdHtcblx0XHRcdFx0XHRfcmVzdWx0cy5kYXRhW2ldID0gcm93O1xuXHRcdFx0XHRcdGlmIChqID4gX2ZpZWxkcy5sZW5ndGgpXG5cdFx0XHRcdFx0XHRhZGRFcnJvcihcIkZpZWxkTWlzbWF0Y2hcIiwgXCJUb29NYW55RmllbGRzXCIsIFwiVG9vIG1hbnkgZmllbGRzOiBleHBlY3RlZCBcIiArIF9maWVsZHMubGVuZ3RoICsgXCIgZmllbGRzIGJ1dCBwYXJzZWQgXCIgKyBqLCBpKTtcblx0XHRcdFx0XHRlbHNlIGlmIChqIDwgX2ZpZWxkcy5sZW5ndGgpXG5cdFx0XHRcdFx0XHRhZGRFcnJvcihcIkZpZWxkTWlzbWF0Y2hcIiwgXCJUb29GZXdGaWVsZHNcIiwgXCJUb28gZmV3IGZpZWxkczogZXhwZWN0ZWQgXCIgKyBfZmllbGRzLmxlbmd0aCArIFwiIGZpZWxkcyBidXQgcGFyc2VkIFwiICsgaiwgaSk7XG5cdFx0XHRcdH1cblx0XHRcdH1cblxuXHRcdFx0aWYgKF9jb25maWcuaGVhZGVyICYmIF9yZXN1bHRzLm1ldGEpXG5cdFx0XHRcdF9yZXN1bHRzLm1ldGEuZmllbGRzID0gX2ZpZWxkcztcblx0XHRcdHJldHVybiBfcmVzdWx0cztcblx0XHR9XG5cblx0XHRmdW5jdGlvbiBndWVzc0RlbGltaXRlcihpbnB1dClcblx0XHR7XG5cdFx0XHR2YXIgZGVsaW1DaG9pY2VzID0gW1wiLFwiLCBcIlxcdFwiLCBcInxcIiwgXCI7XCIsIEJhYnkuUkVDT1JEX1NFUCwgQmFieS5VTklUX1NFUF07XG5cdFx0XHR2YXIgYmVzdERlbGltLCBiZXN0RGVsdGEsIGZpZWxkQ291bnRQcmV2Um93O1xuXG5cdFx0XHRmb3IgKHZhciBpID0gMDsgaSA8IGRlbGltQ2hvaWNlcy5sZW5ndGg7IGkrKylcblx0XHRcdHtcblx0XHRcdFx0dmFyIGRlbGltID0gZGVsaW1DaG9pY2VzW2ldO1xuXHRcdFx0XHR2YXIgZGVsdGEgPSAwLCBhdmdGaWVsZENvdW50ID0gMDtcblx0XHRcdFx0ZmllbGRDb3VudFByZXZSb3cgPSB1bmRlZmluZWQ7XG5cblx0XHRcdFx0dmFyIHByZXZpZXcgPSBuZXcgUGFyc2VyKHtcblx0XHRcdFx0XHRkZWxpbWl0ZXI6IGRlbGltLFxuXHRcdFx0XHRcdHByZXZpZXc6IDEwXG5cdFx0XHRcdH0pLnBhcnNlKGlucHV0KTtcblxuXHRcdFx0XHRmb3IgKHZhciBqID0gMDsgaiA8IHByZXZpZXcuZGF0YS5sZW5ndGg7IGorKylcblx0XHRcdFx0e1xuXHRcdFx0XHRcdHZhciBmaWVsZENvdW50ID0gcHJldmlldy5kYXRhW2pdLmxlbmd0aDtcblx0XHRcdFx0XHRhdmdGaWVsZENvdW50ICs9IGZpZWxkQ291bnQ7XG5cblx0XHRcdFx0XHRpZiAodHlwZW9mIGZpZWxkQ291bnRQcmV2Um93ID09PSAndW5kZWZpbmVkJylcblx0XHRcdFx0XHR7XG5cdFx0XHRcdFx0XHRmaWVsZENvdW50UHJldlJvdyA9IGZpZWxkQ291bnQ7XG5cdFx0XHRcdFx0XHRjb250aW51ZTtcblx0XHRcdFx0XHR9XG5cdFx0XHRcdFx0ZWxzZSBpZiAoZmllbGRDb3VudCA+IDEpXG5cdFx0XHRcdFx0e1xuXHRcdFx0XHRcdFx0ZGVsdGEgKz0gTWF0aC5hYnMoZmllbGRDb3VudCAtIGZpZWxkQ291bnRQcmV2Um93KTtcblx0XHRcdFx0XHRcdGZpZWxkQ291bnRQcmV2Um93ID0gZmllbGRDb3VudDtcblx0XHRcdFx0XHR9XG5cdFx0XHRcdH1cblxuXHRcdFx0XHRhdmdGaWVsZENvdW50IC89IHByZXZpZXcuZGF0YS5sZW5ndGg7XG5cblx0XHRcdFx0aWYgKCh0eXBlb2YgYmVzdERlbHRhID09PSAndW5kZWZpbmVkJyB8fCBkZWx0YSA8IGJlc3REZWx0YSlcblx0XHRcdFx0XHQmJiBhdmdGaWVsZENvdW50ID4gMS45OSlcblx0XHRcdFx0e1xuXHRcdFx0XHRcdGJlc3REZWx0YSA9IGRlbHRhO1xuXHRcdFx0XHRcdGJlc3REZWxpbSA9IGRlbGltO1xuXHRcdFx0XHR9XG5cdFx0XHR9XG5cblx0XHRcdF9jb25maWcuZGVsaW1pdGVyID0gYmVzdERlbGltO1xuXG5cdFx0XHRyZXR1cm4ge1xuXHRcdFx0XHRzdWNjZXNzZnVsOiAhIWJlc3REZWxpbSxcblx0XHRcdFx0YmVzdERlbGltaXRlcjogYmVzdERlbGltXG5cdFx0XHR9XG5cdFx0fVxuXG5cdFx0ZnVuY3Rpb24gZ3Vlc3NMaW5lRW5kaW5ncyhpbnB1dClcblx0XHR7XG5cdFx0XHRpbnB1dCA9IGlucHV0LnN1YnN0cigwLCAxMDI0KjEwMjQpO1x0Ly8gbWF4IGxlbmd0aCAxIE1CXG5cblx0XHRcdHZhciByID0gaW5wdXQuc3BsaXQoJ1xccicpO1xuXG5cdFx0XHRpZiAoci5sZW5ndGggPT0gMSlcblx0XHRcdFx0cmV0dXJuICdcXG4nO1xuXG5cdFx0XHR2YXIgbnVtV2l0aE4gPSAwO1xuXHRcdFx0Zm9yICh2YXIgaSA9IDA7IGkgPCByLmxlbmd0aDsgaSsrKVxuXHRcdFx0e1xuXHRcdFx0XHRpZiAocltpXVswXSA9PSAnXFxuJylcblx0XHRcdFx0XHRudW1XaXRoTisrO1xuXHRcdFx0fVxuXG5cdFx0XHRyZXR1cm4gbnVtV2l0aE4gPj0gci5sZW5ndGggLyAyID8gJ1xcclxcbicgOiAnXFxyJztcblx0XHR9XG5cblx0XHRmdW5jdGlvbiB0cnlQYXJzZUZsb2F0KHZhbClcblx0XHR7XG5cdFx0XHR2YXIgaXNOdW1iZXIgPSBGTE9BVC50ZXN0KHZhbCk7XG5cdFx0XHRyZXR1cm4gaXNOdW1iZXIgPyBwYXJzZUZsb2F0KHZhbCkgOiB2YWw7XG5cdFx0fVxuXG5cdFx0ZnVuY3Rpb24gYWRkRXJyb3IodHlwZSwgY29kZSwgbXNnLCByb3cpXG5cdFx0e1xuXHRcdFx0X3Jlc3VsdHMuZXJyb3JzLnB1c2goe1xuXHRcdFx0XHR0eXBlOiB0eXBlLFxuXHRcdFx0XHRjb2RlOiBjb2RlLFxuXHRcdFx0XHRtZXNzYWdlOiBtc2csXG5cdFx0XHRcdHJvdzogcm93XG5cdFx0XHR9KTtcblx0XHR9XG5cdH1cblxuXG5cblxuXG5cblx0Ly8gVGhlIGNvcmUgcGFyc2VyIGltcGxlbWVudHMgc3BlZWR5IGFuZCBjb3JyZWN0IENTViBwYXJzaW5nXG5cdGZ1bmN0aW9uIFBhcnNlcihjb25maWcpXG5cdHtcblx0XHQvLyBVbnBhY2sgdGhlIGNvbmZpZyBvYmplY3Rcblx0XHRjb25maWcgPSBjb25maWcgfHwge307XG5cdFx0dmFyIGRlbGltID0gY29uZmlnLmRlbGltaXRlcjtcblx0XHR2YXIgbmV3bGluZSA9IGNvbmZpZy5uZXdsaW5lO1xuXHRcdHZhciBjb21tZW50cyA9IGNvbmZpZy5jb21tZW50cztcblx0XHR2YXIgc3RlcCA9IGNvbmZpZy5zdGVwO1xuXHRcdHZhciBwcmV2aWV3ID0gY29uZmlnLnByZXZpZXc7XG5cdFx0dmFyIGZhc3RNb2RlID0gY29uZmlnLmZhc3RNb2RlO1xuXG5cdFx0Ly8gRGVsaW1pdGVyIG11c3QgYmUgdmFsaWRcblx0XHRpZiAodHlwZW9mIGRlbGltICE9PSAnc3RyaW5nJ1xuXHRcdFx0fHwgZGVsaW0ubGVuZ3RoICE9IDFcblx0XHRcdHx8IEJhYnkuQkFEX0RFTElNSVRFUlMuaW5kZXhPZihkZWxpbSkgPiAtMSlcblx0XHRcdGRlbGltID0gXCIsXCI7XG5cblx0XHQvLyBDb21tZW50IGNoYXJhY3RlciBtdXN0IGJlIHZhbGlkXG5cdFx0aWYgKGNvbW1lbnRzID09PSBkZWxpbSlcblx0XHRcdHRocm93IFwiQ29tbWVudCBjaGFyYWN0ZXIgc2FtZSBhcyBkZWxpbWl0ZXJcIjtcblx0XHRlbHNlIGlmIChjb21tZW50cyA9PT0gdHJ1ZSlcblx0XHRcdGNvbW1lbnRzID0gXCIjXCI7XG5cdFx0ZWxzZSBpZiAodHlwZW9mIGNvbW1lbnRzICE9PSAnc3RyaW5nJ1xuXHRcdFx0fHwgQmFieS5CQURfREVMSU1JVEVSUy5pbmRleE9mKGNvbW1lbnRzKSA+IC0xKVxuXHRcdFx0Y29tbWVudHMgPSBmYWxzZTtcblxuXHRcdC8vIE5ld2xpbmUgbXVzdCBiZSB2YWxpZDogXFxyLCBcXG4sIG9yIFxcclxcblxuXHRcdGlmIChuZXdsaW5lICE9ICdcXG4nICYmIG5ld2xpbmUgIT0gJ1xccicgJiYgbmV3bGluZSAhPSAnXFxyXFxuJylcblx0XHRcdG5ld2xpbmUgPSAnXFxuJztcblxuXHRcdC8vIFdlJ3JlIGdvbm5hIG5lZWQgdGhlc2UgYXQgdGhlIFBhcnNlciBzY29wZVxuXHRcdHZhciBjdXJzb3IgPSAwO1xuXHRcdHZhciBhYm9ydGVkID0gZmFsc2U7XG5cblx0XHR0aGlzLnBhcnNlID0gZnVuY3Rpb24oaW5wdXQpXG5cdFx0e1xuXHRcdFx0Ly8gRm9yIHNvbWUgcmVhc29uLCBpbiBDaHJvbWUsIHRoaXMgc3BlZWRzIHRoaW5ncyB1cCAoIT8pXG5cdFx0XHRpZiAodHlwZW9mIGlucHV0ICE9PSAnc3RyaW5nJylcblx0XHRcdFx0dGhyb3cgXCJJbnB1dCBtdXN0IGJlIGEgc3RyaW5nXCI7XG5cblx0XHRcdC8vIFdlIGRvbid0IG5lZWQgdG8gY29tcHV0ZSBzb21lIG9mIHRoZXNlIGV2ZXJ5IHRpbWUgcGFyc2UoKSBpcyBjYWxsZWQsXG5cdFx0XHQvLyBidXQgaGF2aW5nIHRoZW0gaW4gYSBtb3JlIGxvY2FsIHNjb3BlIHNlZW1zIHRvIHBlcmZvcm0gYmV0dGVyXG5cdFx0XHR2YXIgaW5wdXRMZW4gPSBpbnB1dC5sZW5ndGgsXG5cdFx0XHRcdGRlbGltTGVuID0gZGVsaW0ubGVuZ3RoLFxuXHRcdFx0XHRuZXdsaW5lTGVuID0gbmV3bGluZS5sZW5ndGgsXG5cdFx0XHRcdGNvbW1lbnRzTGVuID0gY29tbWVudHMubGVuZ3RoO1xuXHRcdFx0dmFyIHN0ZXBJc0Z1bmN0aW9uID0gdHlwZW9mIHN0ZXAgPT09ICdmdW5jdGlvbic7XG5cblx0XHRcdC8vIEVzdGFibGlzaCBzdGFydGluZyBzdGF0ZVxuXHRcdFx0Y3Vyc29yID0gMDtcblx0XHRcdHZhciBkYXRhID0gW10sIGVycm9ycyA9IFtdLCByb3cgPSBbXTtcblxuXHRcdFx0aWYgKCFpbnB1dClcblx0XHRcdFx0cmV0dXJuIHJldHVybmFibGUoKTtcblxuXHRcdFx0aWYgKGZhc3RNb2RlKVxuXHRcdFx0e1xuXHRcdFx0XHQvLyBGYXN0IG1vZGUgYXNzdW1lcyB0aGVyZSBhcmUgbm8gcXVvdGVkIGZpZWxkcyBpbiB0aGUgaW5wdXRcblx0XHRcdFx0dmFyIHJvd3MgPSBpbnB1dC5zcGxpdChuZXdsaW5lKTtcblx0XHRcdFx0Zm9yICh2YXIgaSA9IDA7IGkgPCByb3dzLmxlbmd0aDsgaSsrKVxuXHRcdFx0XHR7XG5cdFx0XHRcdFx0aWYgKGNvbW1lbnRzICYmIHJvd3NbaV0uc3Vic3RyKDAsIGNvbW1lbnRzTGVuKSA9PSBjb21tZW50cylcblx0XHRcdFx0XHRcdGNvbnRpbnVlO1xuXHRcdFx0XHRcdGlmIChzdGVwSXNGdW5jdGlvbilcblx0XHRcdFx0XHR7XG5cdFx0XHRcdFx0XHRkYXRhID0gWyByb3dzW2ldLnNwbGl0KGRlbGltKSBdO1xuXHRcdFx0XHRcdFx0ZG9TdGVwKCk7XG5cdFx0XHRcdFx0XHRpZiAoYWJvcnRlZClcblx0XHRcdFx0XHRcdFx0cmV0dXJuIHJldHVybmFibGUoKTtcblx0XHRcdFx0XHR9XG5cdFx0XHRcdFx0ZWxzZVxuXHRcdFx0XHRcdFx0ZGF0YS5wdXNoKHJvd3NbaV0uc3BsaXQoZGVsaW0pKTtcblx0XHRcdFx0XHRpZiAocHJldmlldyAmJiBpID49IHByZXZpZXcpXG5cdFx0XHRcdFx0e1xuXHRcdFx0XHRcdFx0ZGF0YSA9IGRhdGEuc2xpY2UoMCwgcHJldmlldyk7XG5cdFx0XHRcdFx0XHRyZXR1cm4gcmV0dXJuYWJsZSh0cnVlKTtcblx0XHRcdFx0XHR9XG5cdFx0XHRcdH1cblx0XHRcdFx0cmV0dXJuIHJldHVybmFibGUoKTtcblx0XHRcdH1cblxuXHRcdFx0dmFyIG5leHREZWxpbSA9IGlucHV0LmluZGV4T2YoZGVsaW0sIGN1cnNvcik7XG5cdFx0XHR2YXIgbmV4dE5ld2xpbmUgPSBpbnB1dC5pbmRleE9mKG5ld2xpbmUsIGN1cnNvcik7XG5cblx0XHRcdC8vIFBhcnNlciBsb29wXG5cdFx0XHRmb3IgKDs7KVxuXHRcdFx0e1xuXHRcdFx0XHQvLyBGaWVsZCBoYXMgb3BlbmluZyBxdW90ZVxuXHRcdFx0XHRpZiAoaW5wdXRbY3Vyc29yXSA9PSAnXCInKVxuXHRcdFx0XHR7XG5cdFx0XHRcdFx0Ly8gU3RhcnQgb3VyIHNlYXJjaCBmb3IgdGhlIGNsb3NpbmcgcXVvdGUgd2hlcmUgdGhlIGN1cnNvciBpc1xuXHRcdFx0XHRcdHZhciBxdW90ZVNlYXJjaCA9IGN1cnNvcjtcblxuXHRcdFx0XHRcdC8vIFNraXAgdGhlIG9wZW5pbmcgcXVvdGVcblx0XHRcdFx0XHRjdXJzb3IrKztcblxuXHRcdFx0XHRcdGZvciAoOzspXG5cdFx0XHRcdFx0e1xuXHRcdFx0XHRcdFx0Ly8gRmluZCBjbG9zaW5nIHF1b3RlXG5cdFx0XHRcdFx0XHR2YXIgcXVvdGVTZWFyY2ggPSBpbnB1dC5pbmRleE9mKCdcIicsIHF1b3RlU2VhcmNoKzEpO1xuXG5cdFx0XHRcdFx0XHRpZiAocXVvdGVTZWFyY2ggPT09IC0xKVxuXHRcdFx0XHRcdFx0e1xuXHRcdFx0XHRcdFx0XHQvLyBObyBjbG9zaW5nIHF1b3RlLi4uIHdoYXQgYSBwaXR5XG5cdFx0XHRcdFx0XHRcdGVycm9ycy5wdXNoKHtcblx0XHRcdFx0XHRcdFx0XHR0eXBlOiBcIlF1b3Rlc1wiLFxuXHRcdFx0XHRcdFx0XHRcdGNvZGU6IFwiTWlzc2luZ1F1b3Rlc1wiLFxuXHRcdFx0XHRcdFx0XHRcdG1lc3NhZ2U6IFwiUXVvdGVkIGZpZWxkIHVudGVybWluYXRlZFwiLFxuXHRcdFx0XHRcdFx0XHRcdHJvdzogZGF0YS5sZW5ndGgsXHQvLyByb3cgaGFzIHlldCB0byBiZSBpbnNlcnRlZFxuXHRcdFx0XHRcdFx0XHRcdGluZGV4OiBjdXJzb3Jcblx0XHRcdFx0XHRcdFx0fSk7XG5cdFx0XHRcdFx0XHRcdHJldHVybiBmaW5pc2goKTtcblx0XHRcdFx0XHRcdH1cblxuXHRcdFx0XHRcdFx0aWYgKHF1b3RlU2VhcmNoID09PSBpbnB1dExlbi0xKVxuXHRcdFx0XHRcdFx0e1xuXHRcdFx0XHRcdFx0XHQvLyBDbG9zaW5nIHF1b3RlIGF0IEVPRlxuXHRcdFx0XHRcdFx0XHRyb3cucHVzaChpbnB1dC5zdWJzdHJpbmcoY3Vyc29yLCBxdW90ZVNlYXJjaCkucmVwbGFjZSgvXCJcIi9nLCAnXCInKSk7XG5cdFx0XHRcdFx0XHRcdGRhdGEucHVzaChyb3cpO1xuXHRcdFx0XHRcdFx0XHRpZiAoc3RlcElzRnVuY3Rpb24pXG5cdFx0XHRcdFx0XHRcdFx0ZG9TdGVwKCk7XG5cdFx0XHRcdFx0XHRcdHJldHVybiByZXR1cm5hYmxlKCk7XG5cdFx0XHRcdFx0XHR9XG5cblx0XHRcdFx0XHRcdC8vIElmIHRoaXMgcXVvdGUgaXMgZXNjYXBlZCwgaXQncyBwYXJ0IG9mIHRoZSBkYXRhOyBza2lwIGl0XG5cdFx0XHRcdFx0XHRpZiAoaW5wdXRbcXVvdGVTZWFyY2grMV0gPT0gJ1wiJylcblx0XHRcdFx0XHRcdHtcblx0XHRcdFx0XHRcdFx0cXVvdGVTZWFyY2grKztcblx0XHRcdFx0XHRcdFx0Y29udGludWU7XG5cdFx0XHRcdFx0XHR9XG5cblx0XHRcdFx0XHRcdGlmIChpbnB1dFtxdW90ZVNlYXJjaCsxXSA9PSBkZWxpbSlcblx0XHRcdFx0XHRcdHtcblx0XHRcdFx0XHRcdFx0Ly8gQ2xvc2luZyBxdW90ZSBmb2xsb3dlZCBieSBkZWxpbWl0ZXJcblx0XHRcdFx0XHRcdFx0cm93LnB1c2goaW5wdXQuc3Vic3RyaW5nKGN1cnNvciwgcXVvdGVTZWFyY2gpLnJlcGxhY2UoL1wiXCIvZywgJ1wiJykpO1xuXHRcdFx0XHRcdFx0XHRjdXJzb3IgPSBxdW90ZVNlYXJjaCArIDEgKyBkZWxpbUxlbjtcblx0XHRcdFx0XHRcdFx0bmV4dERlbGltID0gaW5wdXQuaW5kZXhPZihkZWxpbSwgY3Vyc29yKTtcblx0XHRcdFx0XHRcdFx0bmV4dE5ld2xpbmUgPSBpbnB1dC5pbmRleE9mKG5ld2xpbmUsIGN1cnNvcik7XG5cdFx0XHRcdFx0XHRcdGJyZWFrO1xuXHRcdFx0XHRcdFx0fVxuXG5cdFx0XHRcdFx0XHRpZiAoaW5wdXQuc3Vic3RyKHF1b3RlU2VhcmNoKzEsIG5ld2xpbmVMZW4pID09PSBuZXdsaW5lKVxuXHRcdFx0XHRcdFx0e1xuXHRcdFx0XHRcdFx0XHQvLyBDbG9zaW5nIHF1b3RlIGZvbGxvd2VkIGJ5IG5ld2xpbmVcblx0XHRcdFx0XHRcdFx0cm93LnB1c2goaW5wdXQuc3Vic3RyaW5nKGN1cnNvciwgcXVvdGVTZWFyY2gpLnJlcGxhY2UoL1wiXCIvZywgJ1wiJykpO1xuXHRcdFx0XHRcdFx0XHRzYXZlUm93KHF1b3RlU2VhcmNoICsgMSArIG5ld2xpbmVMZW4pO1xuXHRcdFx0XHRcdFx0XHRuZXh0RGVsaW0gPSBpbnB1dC5pbmRleE9mKGRlbGltLCBjdXJzb3IpO1x0Ly8gYmVjYXVzZSB3ZSBtYXkgaGF2ZSBza2lwcGVkIHRoZSBuZXh0RGVsaW0gaW4gdGhlIHF1b3RlZCBmaWVsZFxuXG5cdFx0XHRcdFx0XHRcdGlmIChzdGVwSXNGdW5jdGlvbilcblx0XHRcdFx0XHRcdFx0e1xuXHRcdFx0XHRcdFx0XHRcdGRvU3RlcCgpO1xuXHRcdFx0XHRcdFx0XHRcdGlmIChhYm9ydGVkKVxuXHRcdFx0XHRcdFx0XHRcdFx0cmV0dXJuIHJldHVybmFibGUoKTtcblx0XHRcdFx0XHRcdFx0fVxuXHRcdFx0XHRcdFx0XHRcblx0XHRcdFx0XHRcdFx0aWYgKHByZXZpZXcgJiYgZGF0YS5sZW5ndGggPj0gcHJldmlldylcblx0XHRcdFx0XHRcdFx0XHRyZXR1cm4gcmV0dXJuYWJsZSh0cnVlKTtcblxuXHRcdFx0XHRcdFx0XHRicmVhaztcblx0XHRcdFx0XHRcdH1cblx0XHRcdFx0XHR9XG5cblx0XHRcdFx0XHRjb250aW51ZTtcblx0XHRcdFx0fVxuXG5cdFx0XHRcdC8vIENvbW1lbnQgZm91bmQgYXQgc3RhcnQgb2YgbmV3IGxpbmVcblx0XHRcdFx0aWYgKGNvbW1lbnRzICYmIHJvdy5sZW5ndGggPT09IDAgJiYgaW5wdXQuc3Vic3RyKGN1cnNvciwgY29tbWVudHNMZW4pID09PSBjb21tZW50cylcblx0XHRcdFx0e1xuXHRcdFx0XHRcdGlmIChuZXh0TmV3bGluZSA9PSAtMSlcdC8vIENvbW1lbnQgZW5kcyBhdCBFT0Zcblx0XHRcdFx0XHRcdHJldHVybiByZXR1cm5hYmxlKCk7XG5cdFx0XHRcdFx0Y3Vyc29yID0gbmV4dE5ld2xpbmUgKyBuZXdsaW5lTGVuO1xuXHRcdFx0XHRcdG5leHROZXdsaW5lID0gaW5wdXQuaW5kZXhPZihuZXdsaW5lLCBjdXJzb3IpO1xuXHRcdFx0XHRcdG5leHREZWxpbSA9IGlucHV0LmluZGV4T2YoZGVsaW0sIGN1cnNvcik7XG5cdFx0XHRcdFx0Y29udGludWU7XG5cdFx0XHRcdH1cblxuXHRcdFx0XHQvLyBOZXh0IGRlbGltaXRlciBjb21lcyBiZWZvcmUgbmV4dCBuZXdsaW5lLCBzbyB3ZSd2ZSByZWFjaGVkIGVuZCBvZiBmaWVsZFxuXHRcdFx0XHRpZiAobmV4dERlbGltICE9PSAtMSAmJiAobmV4dERlbGltIDwgbmV4dE5ld2xpbmUgfHwgbmV4dE5ld2xpbmUgPT09IC0xKSlcblx0XHRcdFx0e1xuXHRcdFx0XHRcdHJvdy5wdXNoKGlucHV0LnN1YnN0cmluZyhjdXJzb3IsIG5leHREZWxpbSkpO1xuXHRcdFx0XHRcdGN1cnNvciA9IG5leHREZWxpbSArIGRlbGltTGVuO1xuXHRcdFx0XHRcdG5leHREZWxpbSA9IGlucHV0LmluZGV4T2YoZGVsaW0sIGN1cnNvcik7XG5cdFx0XHRcdFx0Y29udGludWU7XG5cdFx0XHRcdH1cblxuXHRcdFx0XHQvLyBFbmQgb2Ygcm93XG5cdFx0XHRcdGlmIChuZXh0TmV3bGluZSAhPT0gLTEpXG5cdFx0XHRcdHtcblx0XHRcdFx0XHRyb3cucHVzaChpbnB1dC5zdWJzdHJpbmcoY3Vyc29yLCBuZXh0TmV3bGluZSkpO1xuXHRcdFx0XHRcdHNhdmVSb3cobmV4dE5ld2xpbmUgKyBuZXdsaW5lTGVuKTtcblxuXHRcdFx0XHRcdGlmIChzdGVwSXNGdW5jdGlvbilcblx0XHRcdFx0XHR7XG5cdFx0XHRcdFx0XHRkb1N0ZXAoKTtcblx0XHRcdFx0XHRcdGlmIChhYm9ydGVkKVxuXHRcdFx0XHRcdFx0XHRyZXR1cm4gcmV0dXJuYWJsZSgpO1xuXHRcdFx0XHRcdH1cblxuXHRcdFx0XHRcdGlmIChwcmV2aWV3ICYmIGRhdGEubGVuZ3RoID49IHByZXZpZXcpXG5cdFx0XHRcdFx0XHRyZXR1cm4gcmV0dXJuYWJsZSh0cnVlKTtcblxuXHRcdFx0XHRcdGNvbnRpbnVlO1xuXHRcdFx0XHR9XG5cblx0XHRcdFx0YnJlYWs7XG5cdFx0XHR9XG5cblxuXHRcdFx0cmV0dXJuIGZpbmlzaCgpO1xuXG5cblx0XHRcdC8vIEFwcGVuZHMgdGhlIHJlbWFpbmluZyBpbnB1dCBmcm9tIGN1cnNvciB0byB0aGUgZW5kIGludG9cblx0XHRcdC8vIHJvdywgc2F2ZXMgdGhlIHJvdywgY2FsbHMgc3RlcCwgYW5kIHJldHVybnMgdGhlIHJlc3VsdHMuXG5cdFx0XHRmdW5jdGlvbiBmaW5pc2goKVxuXHRcdFx0e1xuXHRcdFx0XHRyb3cucHVzaChpbnB1dC5zdWJzdHIoY3Vyc29yKSk7XG5cdFx0XHRcdGRhdGEucHVzaChyb3cpO1xuXHRcdFx0XHRjdXJzb3IgPSBpbnB1dExlbjtcdC8vIGltcG9ydGFudCBpbiBjYXNlIHBhcnNpbmcgaXMgcGF1c2VkXG5cdFx0XHRcdGlmIChzdGVwSXNGdW5jdGlvbilcblx0XHRcdFx0XHRkb1N0ZXAoKTtcblx0XHRcdFx0cmV0dXJuIHJldHVybmFibGUoKTtcblx0XHRcdH1cblxuXHRcdFx0Ly8gQXBwZW5kcyB0aGUgY3VycmVudCByb3cgdG8gdGhlIHJlc3VsdHMuIEl0IHNldHMgdGhlIGN1cnNvclxuXHRcdFx0Ly8gdG8gbmV3Q3Vyc29yIGFuZCBmaW5kcyB0aGUgbmV4dE5ld2xpbmUuIFRoZSBjYWxsZXIgc2hvdWxkXG5cdFx0XHQvLyB0YWtlIGNhcmUgdG8gZXhlY3V0ZSB1c2VyJ3Mgc3RlcCBmdW5jdGlvbiBhbmQgY2hlY2sgZm9yXG5cdFx0XHQvLyBwcmV2aWV3IGFuZCBlbmQgcGFyc2luZyBpZiBuZWNlc3NhcnkuXG5cdFx0XHRmdW5jdGlvbiBzYXZlUm93KG5ld0N1cnNvcilcblx0XHRcdHtcblx0XHRcdFx0ZGF0YS5wdXNoKHJvdyk7XG5cdFx0XHRcdHJvdyA9IFtdO1xuXHRcdFx0XHRjdXJzb3IgPSBuZXdDdXJzb3I7XG5cdFx0XHRcdG5leHROZXdsaW5lID0gaW5wdXQuaW5kZXhPZihuZXdsaW5lLCBjdXJzb3IpO1xuXHRcdFx0fVxuXG5cdFx0XHQvLyBSZXR1cm5zIGFuIG9iamVjdCB3aXRoIHRoZSByZXN1bHRzLCBlcnJvcnMsIGFuZCBtZXRhLlxuXHRcdFx0ZnVuY3Rpb24gcmV0dXJuYWJsZShzdG9wcGVkKVxuXHRcdFx0e1xuXHRcdFx0XHRyZXR1cm4ge1xuXHRcdFx0XHRcdGRhdGE6IGRhdGEsXG5cdFx0XHRcdFx0ZXJyb3JzOiBlcnJvcnMsXG5cdFx0XHRcdFx0bWV0YToge1xuXHRcdFx0XHRcdFx0ZGVsaW1pdGVyOiBkZWxpbSxcblx0XHRcdFx0XHRcdGxpbmVicmVhazogbmV3bGluZSxcblx0XHRcdFx0XHRcdGFib3J0ZWQ6IGFib3J0ZWQsXG5cdFx0XHRcdFx0XHR0cnVuY2F0ZWQ6ICEhc3RvcHBlZFxuXHRcdFx0XHRcdH1cblx0XHRcdFx0fTtcblx0XHRcdH1cblxuXHRcdFx0Ly8gRXhlY3V0ZXMgdGhlIHVzZXIncyBzdGVwIGZ1bmN0aW9uIGFuZCByZXNldHMgZGF0YSAmIGVycm9ycy5cblx0XHRcdGZ1bmN0aW9uIGRvU3RlcCgpXG5cdFx0XHR7XG5cdFx0XHRcdHN0ZXAocmV0dXJuYWJsZSgpKTtcblx0XHRcdFx0ZGF0YSA9IFtdLCBlcnJvcnMgPSBbXTtcblx0XHRcdH1cblx0XHR9O1xuXG5cdFx0Ly8gU2V0cyB0aGUgYWJvcnQgZmxhZ1xuXHRcdHRoaXMuYWJvcnQgPSBmdW5jdGlvbigpXG5cdFx0e1xuXHRcdFx0YWJvcnRlZCA9IHRydWU7XG5cdFx0fTtcblxuXHRcdC8vIEdldHMgdGhlIGN1cnNvciBwb3NpdGlvblxuXHRcdHRoaXMuZ2V0Q2hhckluZGV4ID0gZnVuY3Rpb24oKVxuXHRcdHtcblx0XHRcdHJldHVybiBjdXJzb3I7XG5cdFx0fTtcblx0fVxuXG5cblxuXG5cdC8vIFJlcGxhY2VzIGJhZCBjb25maWcgdmFsdWVzIHdpdGggZ29vZCwgZGVmYXVsdCBvbmVzXG5cdGZ1bmN0aW9uIGNvcHlBbmRWYWxpZGF0ZUNvbmZpZyhvcmlnQ29uZmlnKVxuXHR7XG5cdFx0aWYgKHR5cGVvZiBvcmlnQ29uZmlnICE9PSAnb2JqZWN0Jylcblx0XHRcdG9yaWdDb25maWcgPSB7fTtcblxuXHRcdHZhciBjb25maWcgPSBjb3B5KG9yaWdDb25maWcpO1xuXG5cdFx0aWYgKHR5cGVvZiBjb25maWcuZGVsaW1pdGVyICE9PSAnc3RyaW5nJ1xuXHRcdFx0fHwgY29uZmlnLmRlbGltaXRlci5sZW5ndGggIT0gMVxuXHRcdFx0fHwgQmFieS5CQURfREVMSU1JVEVSUy5pbmRleE9mKGNvbmZpZy5kZWxpbWl0ZXIpID4gLTEpXG5cdFx0XHRjb25maWcuZGVsaW1pdGVyID0gREVGQVVMVFMuZGVsaW1pdGVyO1xuXG5cdFx0aWYgKGNvbmZpZy5uZXdsaW5lICE9ICdcXG4nXG5cdFx0XHQmJiBjb25maWcubmV3bGluZSAhPSAnXFxyJ1xuXHRcdFx0JiYgY29uZmlnLm5ld2xpbmUgIT0gJ1xcclxcbicpXG5cdFx0XHRjb25maWcubmV3bGluZSA9IERFRkFVTFRTLm5ld2xpbmU7XG5cblx0XHRpZiAodHlwZW9mIGNvbmZpZy5oZWFkZXIgIT09ICdib29sZWFuJylcblx0XHRcdGNvbmZpZy5oZWFkZXIgPSBERUZBVUxUUy5oZWFkZXI7XG5cblx0XHRpZiAodHlwZW9mIGNvbmZpZy5keW5hbWljVHlwaW5nICE9PSAnYm9vbGVhbicpXG5cdFx0XHRjb25maWcuZHluYW1pY1R5cGluZyA9IERFRkFVTFRTLmR5bmFtaWNUeXBpbmc7XG5cblx0XHRpZiAodHlwZW9mIGNvbmZpZy5wcmV2aWV3ICE9PSAnbnVtYmVyJylcblx0XHRcdGNvbmZpZy5wcmV2aWV3ID0gREVGQVVMVFMucHJldmlldztcblxuXHRcdGlmICh0eXBlb2YgY29uZmlnLnN0ZXAgIT09ICdmdW5jdGlvbicpXG5cdFx0XHRjb25maWcuc3RlcCA9IERFRkFVTFRTLnN0ZXA7XG5cblx0XHRpZiAodHlwZW9mIGNvbmZpZy5jb21wbGV0ZSAhPT0gJ2Z1bmN0aW9uJylcblx0XHRcdGNvbmZpZy5jb21wbGV0ZSA9IERFRkFVTFRTLmNvbXBsZXRlO1xuXG5cdFx0aWYgKHR5cGVvZiBjb25maWcuc2tpcEVtcHR5TGluZXMgIT09ICdib29sZWFuJylcblx0XHRcdGNvbmZpZy5za2lwRW1wdHlMaW5lcyA9IERFRkFVTFRTLnNraXBFbXB0eUxpbmVzO1xuXG5cdFx0aWYgKHR5cGVvZiBjb25maWcuZmFzdE1vZGUgIT09ICdib29sZWFuJylcblx0XHRcdGNvbmZpZy5mYXN0TW9kZSA9IERFRkFVTFRTLmZhc3RNb2RlO1xuXG5cdFx0cmV0dXJuIGNvbmZpZztcblx0fVxuXG5cdGZ1bmN0aW9uIGNvcHkob2JqKVxuXHR7XG5cdFx0aWYgKHR5cGVvZiBvYmogIT09ICdvYmplY3QnKVxuXHRcdFx0cmV0dXJuIG9iajtcblx0XHR2YXIgY3B5ID0gb2JqIGluc3RhbmNlb2YgQXJyYXkgPyBbXSA6IHt9O1xuXHRcdGZvciAodmFyIGtleSBpbiBvYmopXG5cdFx0XHRjcHlba2V5XSA9IGNvcHkob2JqW2tleV0pO1xuXHRcdHJldHVybiBjcHk7XG5cdH1cblxuXHRmdW5jdGlvbiBpc0Z1bmN0aW9uKGZ1bmMpXG5cdHtcblx0XHRyZXR1cm4gdHlwZW9mIGZ1bmMgPT09ICdmdW5jdGlvbic7XG5cdH1cblxuXG5cblxuXG5cblx0Ly8gZXhwb3J0IHRvIE5vZGUuLi5cblx0aWYgKCB0eXBlb2YgbW9kdWxlICE9PSAndW5kZWZpbmVkJyAmJiBtb2R1bGUuZXhwb3J0cyApIHtcblx0XHRtb2R1bGUuZXhwb3J0cyA9IEJhYnk7XG5cdH1cblxuXHQvLyAuLi5vciBhcyBBTUQgbW9kdWxlLi4uXG5cdGVsc2UgaWYgKCB0eXBlb2YgZGVmaW5lID09PSAnZnVuY3Rpb24nICYmIGRlZmluZS5hbWQgKSB7XG5cdFx0ZGVmaW5lKCBmdW5jdGlvbiAoKSB7IHJldHVybiBCYWJ5OyB9KTtcblx0fVxuXG5cdC8vIC4uLm9yIGFzIGJyb3dzZXIgZ2xvYmFsXG5cdGVsc2Uge1xuXHRcdGdsb2JhbC5CYWJ5ID0gQmFieTtcblx0fVxuXG59KSh0eXBlb2Ygd2luZG93ICE9PSAndW5kZWZpbmVkJyA/IHdpbmRvdyA6IHRoaXMpO1xuIixudWxsLCIvKiFcbiAqIFRoZSBidWZmZXIgbW9kdWxlIGZyb20gbm9kZS5qcywgZm9yIHRoZSBicm93c2VyLlxuICpcbiAqIEBhdXRob3IgICBGZXJvc3MgQWJvdWtoYWRpamVoIDxmZXJvc3NAZmVyb3NzLm9yZz4gPGh0dHA6Ly9mZXJvc3Mub3JnPlxuICogQGxpY2Vuc2UgIE1JVFxuICovXG5cbnZhciBiYXNlNjQgPSByZXF1aXJlKCdiYXNlNjQtanMnKVxudmFyIGllZWU3NTQgPSByZXF1aXJlKCdpZWVlNzU0JylcbnZhciBpc0FycmF5ID0gcmVxdWlyZSgnaXMtYXJyYXknKVxuXG5leHBvcnRzLkJ1ZmZlciA9IEJ1ZmZlclxuZXhwb3J0cy5TbG93QnVmZmVyID0gQnVmZmVyXG5leHBvcnRzLklOU1BFQ1RfTUFYX0JZVEVTID0gNTBcbkJ1ZmZlci5wb29sU2l6ZSA9IDgxOTIgLy8gbm90IHVzZWQgYnkgdGhpcyBpbXBsZW1lbnRhdGlvblxuXG52YXIga01heExlbmd0aCA9IDB4M2ZmZmZmZmZcblxuLyoqXG4gKiBJZiBgQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlRgOlxuICogICA9PT0gdHJ1ZSAgICBVc2UgVWludDhBcnJheSBpbXBsZW1lbnRhdGlvbiAoZmFzdGVzdClcbiAqICAgPT09IGZhbHNlICAgVXNlIE9iamVjdCBpbXBsZW1lbnRhdGlvbiAobW9zdCBjb21wYXRpYmxlLCBldmVuIElFNilcbiAqXG4gKiBCcm93c2VycyB0aGF0IHN1cHBvcnQgdHlwZWQgYXJyYXlzIGFyZSBJRSAxMCssIEZpcmVmb3ggNCssIENocm9tZSA3KywgU2FmYXJpIDUuMSssXG4gKiBPcGVyYSAxMS42KywgaU9TIDQuMisuXG4gKlxuICogTm90ZTpcbiAqXG4gKiAtIEltcGxlbWVudGF0aW9uIG11c3Qgc3VwcG9ydCBhZGRpbmcgbmV3IHByb3BlcnRpZXMgdG8gYFVpbnQ4QXJyYXlgIGluc3RhbmNlcy5cbiAqICAgRmlyZWZveCA0LTI5IGxhY2tlZCBzdXBwb3J0LCBmaXhlZCBpbiBGaXJlZm94IDMwKy5cbiAqICAgU2VlOiBodHRwczovL2J1Z3ppbGxhLm1vemlsbGEub3JnL3Nob3dfYnVnLmNnaT9pZD02OTU0MzguXG4gKlxuICogIC0gQ2hyb21lIDktMTAgaXMgbWlzc2luZyB0aGUgYFR5cGVkQXJyYXkucHJvdG90eXBlLnN1YmFycmF5YCBmdW5jdGlvbi5cbiAqXG4gKiAgLSBJRTEwIGhhcyBhIGJyb2tlbiBgVHlwZWRBcnJheS5wcm90b3R5cGUuc3ViYXJyYXlgIGZ1bmN0aW9uIHdoaWNoIHJldHVybnMgYXJyYXlzIG9mXG4gKiAgICBpbmNvcnJlY3QgbGVuZ3RoIGluIHNvbWUgc2l0dWF0aW9ucy5cbiAqXG4gKiBXZSBkZXRlY3QgdGhlc2UgYnVnZ3kgYnJvd3NlcnMgYW5kIHNldCBgQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlRgIHRvIGBmYWxzZWAgc28gdGhleSB3aWxsXG4gKiBnZXQgdGhlIE9iamVjdCBpbXBsZW1lbnRhdGlvbiwgd2hpY2ggaXMgc2xvd2VyIGJ1dCB3aWxsIHdvcmsgY29ycmVjdGx5LlxuICovXG5CdWZmZXIuVFlQRURfQVJSQVlfU1VQUE9SVCA9IChmdW5jdGlvbiAoKSB7XG4gIHRyeSB7XG4gICAgdmFyIGJ1ZiA9IG5ldyBBcnJheUJ1ZmZlcigwKVxuICAgIHZhciBhcnIgPSBuZXcgVWludDhBcnJheShidWYpXG4gICAgYXJyLmZvbyA9IGZ1bmN0aW9uICgpIHsgcmV0dXJuIDQyIH1cbiAgICByZXR1cm4gNDIgPT09IGFyci5mb28oKSAmJiAvLyB0eXBlZCBhcnJheSBpbnN0YW5jZXMgY2FuIGJlIGF1Z21lbnRlZFxuICAgICAgICB0eXBlb2YgYXJyLnN1YmFycmF5ID09PSAnZnVuY3Rpb24nICYmIC8vIGNocm9tZSA5LTEwIGxhY2sgYHN1YmFycmF5YFxuICAgICAgICBuZXcgVWludDhBcnJheSgxKS5zdWJhcnJheSgxLCAxKS5ieXRlTGVuZ3RoID09PSAwIC8vIGllMTAgaGFzIGJyb2tlbiBgc3ViYXJyYXlgXG4gIH0gY2F0Y2ggKGUpIHtcbiAgICByZXR1cm4gZmFsc2VcbiAgfVxufSkoKVxuXG4vKipcbiAqIENsYXNzOiBCdWZmZXJcbiAqID09PT09PT09PT09PT1cbiAqXG4gKiBUaGUgQnVmZmVyIGNvbnN0cnVjdG9yIHJldHVybnMgaW5zdGFuY2VzIG9mIGBVaW50OEFycmF5YCB0aGF0IGFyZSBhdWdtZW50ZWRcbiAqIHdpdGggZnVuY3Rpb24gcHJvcGVydGllcyBmb3IgYWxsIHRoZSBub2RlIGBCdWZmZXJgIEFQSSBmdW5jdGlvbnMuIFdlIHVzZVxuICogYFVpbnQ4QXJyYXlgIHNvIHRoYXQgc3F1YXJlIGJyYWNrZXQgbm90YXRpb24gd29ya3MgYXMgZXhwZWN0ZWQgLS0gaXQgcmV0dXJuc1xuICogYSBzaW5nbGUgb2N0ZXQuXG4gKlxuICogQnkgYXVnbWVudGluZyB0aGUgaW5zdGFuY2VzLCB3ZSBjYW4gYXZvaWQgbW9kaWZ5aW5nIHRoZSBgVWludDhBcnJheWBcbiAqIHByb3RvdHlwZS5cbiAqL1xuZnVuY3Rpb24gQnVmZmVyIChzdWJqZWN0LCBlbmNvZGluZywgbm9aZXJvKSB7XG4gIGlmICghKHRoaXMgaW5zdGFuY2VvZiBCdWZmZXIpKVxuICAgIHJldHVybiBuZXcgQnVmZmVyKHN1YmplY3QsIGVuY29kaW5nLCBub1plcm8pXG5cbiAgdmFyIHR5cGUgPSB0eXBlb2Ygc3ViamVjdFxuXG4gIC8vIEZpbmQgdGhlIGxlbmd0aFxuICB2YXIgbGVuZ3RoXG4gIGlmICh0eXBlID09PSAnbnVtYmVyJylcbiAgICBsZW5ndGggPSBzdWJqZWN0ID4gMCA/IHN1YmplY3QgPj4+IDAgOiAwXG4gIGVsc2UgaWYgKHR5cGUgPT09ICdzdHJpbmcnKSB7XG4gICAgaWYgKGVuY29kaW5nID09PSAnYmFzZTY0JylcbiAgICAgIHN1YmplY3QgPSBiYXNlNjRjbGVhbihzdWJqZWN0KVxuICAgIGxlbmd0aCA9IEJ1ZmZlci5ieXRlTGVuZ3RoKHN1YmplY3QsIGVuY29kaW5nKVxuICB9IGVsc2UgaWYgKHR5cGUgPT09ICdvYmplY3QnICYmIHN1YmplY3QgIT09IG51bGwpIHsgLy8gYXNzdW1lIG9iamVjdCBpcyBhcnJheS1saWtlXG4gICAgaWYgKHN1YmplY3QudHlwZSA9PT0gJ0J1ZmZlcicgJiYgaXNBcnJheShzdWJqZWN0LmRhdGEpKVxuICAgICAgc3ViamVjdCA9IHN1YmplY3QuZGF0YVxuICAgIGxlbmd0aCA9ICtzdWJqZWN0Lmxlbmd0aCA+IDAgPyBNYXRoLmZsb29yKCtzdWJqZWN0Lmxlbmd0aCkgOiAwXG4gIH0gZWxzZVxuICAgIHRocm93IG5ldyBUeXBlRXJyb3IoJ211c3Qgc3RhcnQgd2l0aCBudW1iZXIsIGJ1ZmZlciwgYXJyYXkgb3Igc3RyaW5nJylcblxuICBpZiAodGhpcy5sZW5ndGggPiBrTWF4TGVuZ3RoKVxuICAgIHRocm93IG5ldyBSYW5nZUVycm9yKCdBdHRlbXB0IHRvIGFsbG9jYXRlIEJ1ZmZlciBsYXJnZXIgdGhhbiBtYXhpbXVtICcgK1xuICAgICAgJ3NpemU6IDB4JyArIGtNYXhMZW5ndGgudG9TdHJpbmcoMTYpICsgJyBieXRlcycpXG5cbiAgdmFyIGJ1ZlxuICBpZiAoQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlQpIHtcbiAgICAvLyBQcmVmZXJyZWQ6IFJldHVybiBhbiBhdWdtZW50ZWQgYFVpbnQ4QXJyYXlgIGluc3RhbmNlIGZvciBiZXN0IHBlcmZvcm1hbmNlXG4gICAgYnVmID0gQnVmZmVyLl9hdWdtZW50KG5ldyBVaW50OEFycmF5KGxlbmd0aCkpXG4gIH0gZWxzZSB7XG4gICAgLy8gRmFsbGJhY2s6IFJldHVybiBUSElTIGluc3RhbmNlIG9mIEJ1ZmZlciAoY3JlYXRlZCBieSBgbmV3YClcbiAgICBidWYgPSB0aGlzXG4gICAgYnVmLmxlbmd0aCA9IGxlbmd0aFxuICAgIGJ1Zi5faXNCdWZmZXIgPSB0cnVlXG4gIH1cblxuICB2YXIgaVxuICBpZiAoQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlQgJiYgdHlwZW9mIHN1YmplY3QuYnl0ZUxlbmd0aCA9PT0gJ251bWJlcicpIHtcbiAgICAvLyBTcGVlZCBvcHRpbWl6YXRpb24gLS0gdXNlIHNldCBpZiB3ZSdyZSBjb3B5aW5nIGZyb20gYSB0eXBlZCBhcnJheVxuICAgIGJ1Zi5fc2V0KHN1YmplY3QpXG4gIH0gZWxzZSBpZiAoaXNBcnJheWlzaChzdWJqZWN0KSkge1xuICAgIC8vIFRyZWF0IGFycmF5LWlzaCBvYmplY3RzIGFzIGEgYnl0ZSBhcnJheVxuICAgIGlmIChCdWZmZXIuaXNCdWZmZXIoc3ViamVjdCkpIHtcbiAgICAgIGZvciAoaSA9IDA7IGkgPCBsZW5ndGg7IGkrKylcbiAgICAgICAgYnVmW2ldID0gc3ViamVjdC5yZWFkVUludDgoaSlcbiAgICB9IGVsc2Uge1xuICAgICAgZm9yIChpID0gMDsgaSA8IGxlbmd0aDsgaSsrKVxuICAgICAgICBidWZbaV0gPSAoKHN1YmplY3RbaV0gJSAyNTYpICsgMjU2KSAlIDI1NlxuICAgIH1cbiAgfSBlbHNlIGlmICh0eXBlID09PSAnc3RyaW5nJykge1xuICAgIGJ1Zi53cml0ZShzdWJqZWN0LCAwLCBlbmNvZGluZylcbiAgfSBlbHNlIGlmICh0eXBlID09PSAnbnVtYmVyJyAmJiAhQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlQgJiYgIW5vWmVybykge1xuICAgIGZvciAoaSA9IDA7IGkgPCBsZW5ndGg7IGkrKykge1xuICAgICAgYnVmW2ldID0gMFxuICAgIH1cbiAgfVxuXG4gIHJldHVybiBidWZcbn1cblxuQnVmZmVyLmlzQnVmZmVyID0gZnVuY3Rpb24gKGIpIHtcbiAgcmV0dXJuICEhKGIgIT0gbnVsbCAmJiBiLl9pc0J1ZmZlcilcbn1cblxuQnVmZmVyLmNvbXBhcmUgPSBmdW5jdGlvbiAoYSwgYikge1xuICBpZiAoIUJ1ZmZlci5pc0J1ZmZlcihhKSB8fCAhQnVmZmVyLmlzQnVmZmVyKGIpKVxuICAgIHRocm93IG5ldyBUeXBlRXJyb3IoJ0FyZ3VtZW50cyBtdXN0IGJlIEJ1ZmZlcnMnKVxuXG4gIHZhciB4ID0gYS5sZW5ndGhcbiAgdmFyIHkgPSBiLmxlbmd0aFxuICBmb3IgKHZhciBpID0gMCwgbGVuID0gTWF0aC5taW4oeCwgeSk7IGkgPCBsZW4gJiYgYVtpXSA9PT0gYltpXTsgaSsrKSB7fVxuICBpZiAoaSAhPT0gbGVuKSB7XG4gICAgeCA9IGFbaV1cbiAgICB5ID0gYltpXVxuICB9XG4gIGlmICh4IDwgeSkgcmV0dXJuIC0xXG4gIGlmICh5IDwgeCkgcmV0dXJuIDFcbiAgcmV0dXJuIDBcbn1cblxuQnVmZmVyLmlzRW5jb2RpbmcgPSBmdW5jdGlvbiAoZW5jb2RpbmcpIHtcbiAgc3dpdGNoIChTdHJpbmcoZW5jb2RpbmcpLnRvTG93ZXJDYXNlKCkpIHtcbiAgICBjYXNlICdoZXgnOlxuICAgIGNhc2UgJ3V0ZjgnOlxuICAgIGNhc2UgJ3V0Zi04JzpcbiAgICBjYXNlICdhc2NpaSc6XG4gICAgY2FzZSAnYmluYXJ5JzpcbiAgICBjYXNlICdiYXNlNjQnOlxuICAgIGNhc2UgJ3Jhdyc6XG4gICAgY2FzZSAndWNzMic6XG4gICAgY2FzZSAndWNzLTInOlxuICAgIGNhc2UgJ3V0ZjE2bGUnOlxuICAgIGNhc2UgJ3V0Zi0xNmxlJzpcbiAgICAgIHJldHVybiB0cnVlXG4gICAgZGVmYXVsdDpcbiAgICAgIHJldHVybiBmYWxzZVxuICB9XG59XG5cbkJ1ZmZlci5jb25jYXQgPSBmdW5jdGlvbiAobGlzdCwgdG90YWxMZW5ndGgpIHtcbiAgaWYgKCFpc0FycmF5KGxpc3QpKSB0aHJvdyBuZXcgVHlwZUVycm9yKCdVc2FnZTogQnVmZmVyLmNvbmNhdChsaXN0WywgbGVuZ3RoXSknKVxuXG4gIGlmIChsaXN0Lmxlbmd0aCA9PT0gMCkge1xuICAgIHJldHVybiBuZXcgQnVmZmVyKDApXG4gIH0gZWxzZSBpZiAobGlzdC5sZW5ndGggPT09IDEpIHtcbiAgICByZXR1cm4gbGlzdFswXVxuICB9XG5cbiAgdmFyIGlcbiAgaWYgKHRvdGFsTGVuZ3RoID09PSB1bmRlZmluZWQpIHtcbiAgICB0b3RhbExlbmd0aCA9IDBcbiAgICBmb3IgKGkgPSAwOyBpIDwgbGlzdC5sZW5ndGg7IGkrKykge1xuICAgICAgdG90YWxMZW5ndGggKz0gbGlzdFtpXS5sZW5ndGhcbiAgICB9XG4gIH1cblxuICB2YXIgYnVmID0gbmV3IEJ1ZmZlcih0b3RhbExlbmd0aClcbiAgdmFyIHBvcyA9IDBcbiAgZm9yIChpID0gMDsgaSA8IGxpc3QubGVuZ3RoOyBpKyspIHtcbiAgICB2YXIgaXRlbSA9IGxpc3RbaV1cbiAgICBpdGVtLmNvcHkoYnVmLCBwb3MpXG4gICAgcG9zICs9IGl0ZW0ubGVuZ3RoXG4gIH1cbiAgcmV0dXJuIGJ1ZlxufVxuXG5CdWZmZXIuYnl0ZUxlbmd0aCA9IGZ1bmN0aW9uIChzdHIsIGVuY29kaW5nKSB7XG4gIHZhciByZXRcbiAgc3RyID0gc3RyICsgJydcbiAgc3dpdGNoIChlbmNvZGluZyB8fCAndXRmOCcpIHtcbiAgICBjYXNlICdhc2NpaSc6XG4gICAgY2FzZSAnYmluYXJ5JzpcbiAgICBjYXNlICdyYXcnOlxuICAgICAgcmV0ID0gc3RyLmxlbmd0aFxuICAgICAgYnJlYWtcbiAgICBjYXNlICd1Y3MyJzpcbiAgICBjYXNlICd1Y3MtMic6XG4gICAgY2FzZSAndXRmMTZsZSc6XG4gICAgY2FzZSAndXRmLTE2bGUnOlxuICAgICAgcmV0ID0gc3RyLmxlbmd0aCAqIDJcbiAgICAgIGJyZWFrXG4gICAgY2FzZSAnaGV4JzpcbiAgICAgIHJldCA9IHN0ci5sZW5ndGggPj4+IDFcbiAgICAgIGJyZWFrXG4gICAgY2FzZSAndXRmOCc6XG4gICAgY2FzZSAndXRmLTgnOlxuICAgICAgcmV0ID0gdXRmOFRvQnl0ZXMoc3RyKS5sZW5ndGhcbiAgICAgIGJyZWFrXG4gICAgY2FzZSAnYmFzZTY0JzpcbiAgICAgIHJldCA9IGJhc2U2NFRvQnl0ZXMoc3RyKS5sZW5ndGhcbiAgICAgIGJyZWFrXG4gICAgZGVmYXVsdDpcbiAgICAgIHJldCA9IHN0ci5sZW5ndGhcbiAgfVxuICByZXR1cm4gcmV0XG59XG5cbi8vIHByZS1zZXQgZm9yIHZhbHVlcyB0aGF0IG1heSBleGlzdCBpbiB0aGUgZnV0dXJlXG5CdWZmZXIucHJvdG90eXBlLmxlbmd0aCA9IHVuZGVmaW5lZFxuQnVmZmVyLnByb3RvdHlwZS5wYXJlbnQgPSB1bmRlZmluZWRcblxuLy8gdG9TdHJpbmcoZW5jb2RpbmcsIHN0YXJ0PTAsIGVuZD1idWZmZXIubGVuZ3RoKVxuQnVmZmVyLnByb3RvdHlwZS50b1N0cmluZyA9IGZ1bmN0aW9uIChlbmNvZGluZywgc3RhcnQsIGVuZCkge1xuICB2YXIgbG93ZXJlZENhc2UgPSBmYWxzZVxuXG4gIHN0YXJ0ID0gc3RhcnQgPj4+IDBcbiAgZW5kID0gZW5kID09PSB1bmRlZmluZWQgfHwgZW5kID09PSBJbmZpbml0eSA/IHRoaXMubGVuZ3RoIDogZW5kID4+PiAwXG5cbiAgaWYgKCFlbmNvZGluZykgZW5jb2RpbmcgPSAndXRmOCdcbiAgaWYgKHN0YXJ0IDwgMCkgc3RhcnQgPSAwXG4gIGlmIChlbmQgPiB0aGlzLmxlbmd0aCkgZW5kID0gdGhpcy5sZW5ndGhcbiAgaWYgKGVuZCA8PSBzdGFydCkgcmV0dXJuICcnXG5cbiAgd2hpbGUgKHRydWUpIHtcbiAgICBzd2l0Y2ggKGVuY29kaW5nKSB7XG4gICAgICBjYXNlICdoZXgnOlxuICAgICAgICByZXR1cm4gaGV4U2xpY2UodGhpcywgc3RhcnQsIGVuZClcblxuICAgICAgY2FzZSAndXRmOCc6XG4gICAgICBjYXNlICd1dGYtOCc6XG4gICAgICAgIHJldHVybiB1dGY4U2xpY2UodGhpcywgc3RhcnQsIGVuZClcblxuICAgICAgY2FzZSAnYXNjaWknOlxuICAgICAgICByZXR1cm4gYXNjaWlTbGljZSh0aGlzLCBzdGFydCwgZW5kKVxuXG4gICAgICBjYXNlICdiaW5hcnknOlxuICAgICAgICByZXR1cm4gYmluYXJ5U2xpY2UodGhpcywgc3RhcnQsIGVuZClcblxuICAgICAgY2FzZSAnYmFzZTY0JzpcbiAgICAgICAgcmV0dXJuIGJhc2U2NFNsaWNlKHRoaXMsIHN0YXJ0LCBlbmQpXG5cbiAgICAgIGNhc2UgJ3VjczInOlxuICAgICAgY2FzZSAndWNzLTInOlxuICAgICAgY2FzZSAndXRmMTZsZSc6XG4gICAgICBjYXNlICd1dGYtMTZsZSc6XG4gICAgICAgIHJldHVybiB1dGYxNmxlU2xpY2UodGhpcywgc3RhcnQsIGVuZClcblxuICAgICAgZGVmYXVsdDpcbiAgICAgICAgaWYgKGxvd2VyZWRDYXNlKVxuICAgICAgICAgIHRocm93IG5ldyBUeXBlRXJyb3IoJ1Vua25vd24gZW5jb2Rpbmc6ICcgKyBlbmNvZGluZylcbiAgICAgICAgZW5jb2RpbmcgPSAoZW5jb2RpbmcgKyAnJykudG9Mb3dlckNhc2UoKVxuICAgICAgICBsb3dlcmVkQ2FzZSA9IHRydWVcbiAgICB9XG4gIH1cbn1cblxuQnVmZmVyLnByb3RvdHlwZS5lcXVhbHMgPSBmdW5jdGlvbiAoYikge1xuICBpZighQnVmZmVyLmlzQnVmZmVyKGIpKSB0aHJvdyBuZXcgVHlwZUVycm9yKCdBcmd1bWVudCBtdXN0IGJlIGEgQnVmZmVyJylcbiAgcmV0dXJuIEJ1ZmZlci5jb21wYXJlKHRoaXMsIGIpID09PSAwXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUuaW5zcGVjdCA9IGZ1bmN0aW9uICgpIHtcbiAgdmFyIHN0ciA9ICcnXG4gIHZhciBtYXggPSBleHBvcnRzLklOU1BFQ1RfTUFYX0JZVEVTXG4gIGlmICh0aGlzLmxlbmd0aCA+IDApIHtcbiAgICBzdHIgPSB0aGlzLnRvU3RyaW5nKCdoZXgnLCAwLCBtYXgpLm1hdGNoKC8uezJ9L2cpLmpvaW4oJyAnKVxuICAgIGlmICh0aGlzLmxlbmd0aCA+IG1heClcbiAgICAgIHN0ciArPSAnIC4uLiAnXG4gIH1cbiAgcmV0dXJuICc8QnVmZmVyICcgKyBzdHIgKyAnPidcbn1cblxuQnVmZmVyLnByb3RvdHlwZS5jb21wYXJlID0gZnVuY3Rpb24gKGIpIHtcbiAgaWYgKCFCdWZmZXIuaXNCdWZmZXIoYikpIHRocm93IG5ldyBUeXBlRXJyb3IoJ0FyZ3VtZW50IG11c3QgYmUgYSBCdWZmZXInKVxuICByZXR1cm4gQnVmZmVyLmNvbXBhcmUodGhpcywgYilcbn1cblxuLy8gYGdldGAgd2lsbCBiZSByZW1vdmVkIGluIE5vZGUgMC4xMytcbkJ1ZmZlci5wcm90b3R5cGUuZ2V0ID0gZnVuY3Rpb24gKG9mZnNldCkge1xuICBjb25zb2xlLmxvZygnLmdldCgpIGlzIGRlcHJlY2F0ZWQuIEFjY2VzcyB1c2luZyBhcnJheSBpbmRleGVzIGluc3RlYWQuJylcbiAgcmV0dXJuIHRoaXMucmVhZFVJbnQ4KG9mZnNldClcbn1cblxuLy8gYHNldGAgd2lsbCBiZSByZW1vdmVkIGluIE5vZGUgMC4xMytcbkJ1ZmZlci5wcm90b3R5cGUuc2V0ID0gZnVuY3Rpb24gKHYsIG9mZnNldCkge1xuICBjb25zb2xlLmxvZygnLnNldCgpIGlzIGRlcHJlY2F0ZWQuIEFjY2VzcyB1c2luZyBhcnJheSBpbmRleGVzIGluc3RlYWQuJylcbiAgcmV0dXJuIHRoaXMud3JpdGVVSW50OCh2LCBvZmZzZXQpXG59XG5cbmZ1bmN0aW9uIGhleFdyaXRlIChidWYsIHN0cmluZywgb2Zmc2V0LCBsZW5ndGgpIHtcbiAgb2Zmc2V0ID0gTnVtYmVyKG9mZnNldCkgfHwgMFxuICB2YXIgcmVtYWluaW5nID0gYnVmLmxlbmd0aCAtIG9mZnNldFxuICBpZiAoIWxlbmd0aCkge1xuICAgIGxlbmd0aCA9IHJlbWFpbmluZ1xuICB9IGVsc2Uge1xuICAgIGxlbmd0aCA9IE51bWJlcihsZW5ndGgpXG4gICAgaWYgKGxlbmd0aCA+IHJlbWFpbmluZykge1xuICAgICAgbGVuZ3RoID0gcmVtYWluaW5nXG4gICAgfVxuICB9XG5cbiAgLy8gbXVzdCBiZSBhbiBldmVuIG51bWJlciBvZiBkaWdpdHNcbiAgdmFyIHN0ckxlbiA9IHN0cmluZy5sZW5ndGhcbiAgaWYgKHN0ckxlbiAlIDIgIT09IDApIHRocm93IG5ldyBFcnJvcignSW52YWxpZCBoZXggc3RyaW5nJylcblxuICBpZiAobGVuZ3RoID4gc3RyTGVuIC8gMikge1xuICAgIGxlbmd0aCA9IHN0ckxlbiAvIDJcbiAgfVxuICBmb3IgKHZhciBpID0gMDsgaSA8IGxlbmd0aDsgaSsrKSB7XG4gICAgdmFyIGJ5dGUgPSBwYXJzZUludChzdHJpbmcuc3Vic3RyKGkgKiAyLCAyKSwgMTYpXG4gICAgaWYgKGlzTmFOKGJ5dGUpKSB0aHJvdyBuZXcgRXJyb3IoJ0ludmFsaWQgaGV4IHN0cmluZycpXG4gICAgYnVmW29mZnNldCArIGldID0gYnl0ZVxuICB9XG4gIHJldHVybiBpXG59XG5cbmZ1bmN0aW9uIHV0ZjhXcml0ZSAoYnVmLCBzdHJpbmcsIG9mZnNldCwgbGVuZ3RoKSB7XG4gIHZhciBjaGFyc1dyaXR0ZW4gPSBibGl0QnVmZmVyKHV0ZjhUb0J5dGVzKHN0cmluZyksIGJ1Ziwgb2Zmc2V0LCBsZW5ndGgpXG4gIHJldHVybiBjaGFyc1dyaXR0ZW5cbn1cblxuZnVuY3Rpb24gYXNjaWlXcml0ZSAoYnVmLCBzdHJpbmcsIG9mZnNldCwgbGVuZ3RoKSB7XG4gIHZhciBjaGFyc1dyaXR0ZW4gPSBibGl0QnVmZmVyKGFzY2lpVG9CeXRlcyhzdHJpbmcpLCBidWYsIG9mZnNldCwgbGVuZ3RoKVxuICByZXR1cm4gY2hhcnNXcml0dGVuXG59XG5cbmZ1bmN0aW9uIGJpbmFyeVdyaXRlIChidWYsIHN0cmluZywgb2Zmc2V0LCBsZW5ndGgpIHtcbiAgcmV0dXJuIGFzY2lpV3JpdGUoYnVmLCBzdHJpbmcsIG9mZnNldCwgbGVuZ3RoKVxufVxuXG5mdW5jdGlvbiBiYXNlNjRXcml0ZSAoYnVmLCBzdHJpbmcsIG9mZnNldCwgbGVuZ3RoKSB7XG4gIHZhciBjaGFyc1dyaXR0ZW4gPSBibGl0QnVmZmVyKGJhc2U2NFRvQnl0ZXMoc3RyaW5nKSwgYnVmLCBvZmZzZXQsIGxlbmd0aClcbiAgcmV0dXJuIGNoYXJzV3JpdHRlblxufVxuXG5mdW5jdGlvbiB1dGYxNmxlV3JpdGUgKGJ1Ziwgc3RyaW5nLCBvZmZzZXQsIGxlbmd0aCkge1xuICB2YXIgY2hhcnNXcml0dGVuID0gYmxpdEJ1ZmZlcih1dGYxNmxlVG9CeXRlcyhzdHJpbmcpLCBidWYsIG9mZnNldCwgbGVuZ3RoLCAyKVxuICByZXR1cm4gY2hhcnNXcml0dGVuXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUud3JpdGUgPSBmdW5jdGlvbiAoc3RyaW5nLCBvZmZzZXQsIGxlbmd0aCwgZW5jb2RpbmcpIHtcbiAgLy8gU3VwcG9ydCBib3RoIChzdHJpbmcsIG9mZnNldCwgbGVuZ3RoLCBlbmNvZGluZylcbiAgLy8gYW5kIHRoZSBsZWdhY3kgKHN0cmluZywgZW5jb2RpbmcsIG9mZnNldCwgbGVuZ3RoKVxuICBpZiAoaXNGaW5pdGUob2Zmc2V0KSkge1xuICAgIGlmICghaXNGaW5pdGUobGVuZ3RoKSkge1xuICAgICAgZW5jb2RpbmcgPSBsZW5ndGhcbiAgICAgIGxlbmd0aCA9IHVuZGVmaW5lZFxuICAgIH1cbiAgfSBlbHNlIHsgIC8vIGxlZ2FjeVxuICAgIHZhciBzd2FwID0gZW5jb2RpbmdcbiAgICBlbmNvZGluZyA9IG9mZnNldFxuICAgIG9mZnNldCA9IGxlbmd0aFxuICAgIGxlbmd0aCA9IHN3YXBcbiAgfVxuXG4gIG9mZnNldCA9IE51bWJlcihvZmZzZXQpIHx8IDBcbiAgdmFyIHJlbWFpbmluZyA9IHRoaXMubGVuZ3RoIC0gb2Zmc2V0XG4gIGlmICghbGVuZ3RoKSB7XG4gICAgbGVuZ3RoID0gcmVtYWluaW5nXG4gIH0gZWxzZSB7XG4gICAgbGVuZ3RoID0gTnVtYmVyKGxlbmd0aClcbiAgICBpZiAobGVuZ3RoID4gcmVtYWluaW5nKSB7XG4gICAgICBsZW5ndGggPSByZW1haW5pbmdcbiAgICB9XG4gIH1cbiAgZW5jb2RpbmcgPSBTdHJpbmcoZW5jb2RpbmcgfHwgJ3V0ZjgnKS50b0xvd2VyQ2FzZSgpXG5cbiAgdmFyIHJldFxuICBzd2l0Y2ggKGVuY29kaW5nKSB7XG4gICAgY2FzZSAnaGV4JzpcbiAgICAgIHJldCA9IGhleFdyaXRlKHRoaXMsIHN0cmluZywgb2Zmc2V0LCBsZW5ndGgpXG4gICAgICBicmVha1xuICAgIGNhc2UgJ3V0ZjgnOlxuICAgIGNhc2UgJ3V0Zi04JzpcbiAgICAgIHJldCA9IHV0ZjhXcml0ZSh0aGlzLCBzdHJpbmcsIG9mZnNldCwgbGVuZ3RoKVxuICAgICAgYnJlYWtcbiAgICBjYXNlICdhc2NpaSc6XG4gICAgICByZXQgPSBhc2NpaVdyaXRlKHRoaXMsIHN0cmluZywgb2Zmc2V0LCBsZW5ndGgpXG4gICAgICBicmVha1xuICAgIGNhc2UgJ2JpbmFyeSc6XG4gICAgICByZXQgPSBiaW5hcnlXcml0ZSh0aGlzLCBzdHJpbmcsIG9mZnNldCwgbGVuZ3RoKVxuICAgICAgYnJlYWtcbiAgICBjYXNlICdiYXNlNjQnOlxuICAgICAgcmV0ID0gYmFzZTY0V3JpdGUodGhpcywgc3RyaW5nLCBvZmZzZXQsIGxlbmd0aClcbiAgICAgIGJyZWFrXG4gICAgY2FzZSAndWNzMic6XG4gICAgY2FzZSAndWNzLTInOlxuICAgIGNhc2UgJ3V0ZjE2bGUnOlxuICAgIGNhc2UgJ3V0Zi0xNmxlJzpcbiAgICAgIHJldCA9IHV0ZjE2bGVXcml0ZSh0aGlzLCBzdHJpbmcsIG9mZnNldCwgbGVuZ3RoKVxuICAgICAgYnJlYWtcbiAgICBkZWZhdWx0OlxuICAgICAgdGhyb3cgbmV3IFR5cGVFcnJvcignVW5rbm93biBlbmNvZGluZzogJyArIGVuY29kaW5nKVxuICB9XG4gIHJldHVybiByZXRcbn1cblxuQnVmZmVyLnByb3RvdHlwZS50b0pTT04gPSBmdW5jdGlvbiAoKSB7XG4gIHJldHVybiB7XG4gICAgdHlwZTogJ0J1ZmZlcicsXG4gICAgZGF0YTogQXJyYXkucHJvdG90eXBlLnNsaWNlLmNhbGwodGhpcy5fYXJyIHx8IHRoaXMsIDApXG4gIH1cbn1cblxuZnVuY3Rpb24gYmFzZTY0U2xpY2UgKGJ1Ziwgc3RhcnQsIGVuZCkge1xuICBpZiAoc3RhcnQgPT09IDAgJiYgZW5kID09PSBidWYubGVuZ3RoKSB7XG4gICAgcmV0dXJuIGJhc2U2NC5mcm9tQnl0ZUFycmF5KGJ1ZilcbiAgfSBlbHNlIHtcbiAgICByZXR1cm4gYmFzZTY0LmZyb21CeXRlQXJyYXkoYnVmLnNsaWNlKHN0YXJ0LCBlbmQpKVxuICB9XG59XG5cbmZ1bmN0aW9uIHV0ZjhTbGljZSAoYnVmLCBzdGFydCwgZW5kKSB7XG4gIHZhciByZXMgPSAnJ1xuICB2YXIgdG1wID0gJydcbiAgZW5kID0gTWF0aC5taW4oYnVmLmxlbmd0aCwgZW5kKVxuXG4gIGZvciAodmFyIGkgPSBzdGFydDsgaSA8IGVuZDsgaSsrKSB7XG4gICAgaWYgKGJ1ZltpXSA8PSAweDdGKSB7XG4gICAgICByZXMgKz0gZGVjb2RlVXRmOENoYXIodG1wKSArIFN0cmluZy5mcm9tQ2hhckNvZGUoYnVmW2ldKVxuICAgICAgdG1wID0gJydcbiAgICB9IGVsc2Uge1xuICAgICAgdG1wICs9ICclJyArIGJ1ZltpXS50b1N0cmluZygxNilcbiAgICB9XG4gIH1cblxuICByZXR1cm4gcmVzICsgZGVjb2RlVXRmOENoYXIodG1wKVxufVxuXG5mdW5jdGlvbiBhc2NpaVNsaWNlIChidWYsIHN0YXJ0LCBlbmQpIHtcbiAgdmFyIHJldCA9ICcnXG4gIGVuZCA9IE1hdGgubWluKGJ1Zi5sZW5ndGgsIGVuZClcblxuICBmb3IgKHZhciBpID0gc3RhcnQ7IGkgPCBlbmQ7IGkrKykge1xuICAgIHJldCArPSBTdHJpbmcuZnJvbUNoYXJDb2RlKGJ1ZltpXSlcbiAgfVxuICByZXR1cm4gcmV0XG59XG5cbmZ1bmN0aW9uIGJpbmFyeVNsaWNlIChidWYsIHN0YXJ0LCBlbmQpIHtcbiAgcmV0dXJuIGFzY2lpU2xpY2UoYnVmLCBzdGFydCwgZW5kKVxufVxuXG5mdW5jdGlvbiBoZXhTbGljZSAoYnVmLCBzdGFydCwgZW5kKSB7XG4gIHZhciBsZW4gPSBidWYubGVuZ3RoXG5cbiAgaWYgKCFzdGFydCB8fCBzdGFydCA8IDApIHN0YXJ0ID0gMFxuICBpZiAoIWVuZCB8fCBlbmQgPCAwIHx8IGVuZCA+IGxlbikgZW5kID0gbGVuXG5cbiAgdmFyIG91dCA9ICcnXG4gIGZvciAodmFyIGkgPSBzdGFydDsgaSA8IGVuZDsgaSsrKSB7XG4gICAgb3V0ICs9IHRvSGV4KGJ1ZltpXSlcbiAgfVxuICByZXR1cm4gb3V0XG59XG5cbmZ1bmN0aW9uIHV0ZjE2bGVTbGljZSAoYnVmLCBzdGFydCwgZW5kKSB7XG4gIHZhciBieXRlcyA9IGJ1Zi5zbGljZShzdGFydCwgZW5kKVxuICB2YXIgcmVzID0gJydcbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBieXRlcy5sZW5ndGg7IGkgKz0gMikge1xuICAgIHJlcyArPSBTdHJpbmcuZnJvbUNoYXJDb2RlKGJ5dGVzW2ldICsgYnl0ZXNbaSArIDFdICogMjU2KVxuICB9XG4gIHJldHVybiByZXNcbn1cblxuQnVmZmVyLnByb3RvdHlwZS5zbGljZSA9IGZ1bmN0aW9uIChzdGFydCwgZW5kKSB7XG4gIHZhciBsZW4gPSB0aGlzLmxlbmd0aFxuICBzdGFydCA9IH5+c3RhcnRcbiAgZW5kID0gZW5kID09PSB1bmRlZmluZWQgPyBsZW4gOiB+fmVuZFxuXG4gIGlmIChzdGFydCA8IDApIHtcbiAgICBzdGFydCArPSBsZW47XG4gICAgaWYgKHN0YXJ0IDwgMClcbiAgICAgIHN0YXJ0ID0gMFxuICB9IGVsc2UgaWYgKHN0YXJ0ID4gbGVuKSB7XG4gICAgc3RhcnQgPSBsZW5cbiAgfVxuXG4gIGlmIChlbmQgPCAwKSB7XG4gICAgZW5kICs9IGxlblxuICAgIGlmIChlbmQgPCAwKVxuICAgICAgZW5kID0gMFxuICB9IGVsc2UgaWYgKGVuZCA+IGxlbikge1xuICAgIGVuZCA9IGxlblxuICB9XG5cbiAgaWYgKGVuZCA8IHN0YXJ0KVxuICAgIGVuZCA9IHN0YXJ0XG5cbiAgaWYgKEJ1ZmZlci5UWVBFRF9BUlJBWV9TVVBQT1JUKSB7XG4gICAgcmV0dXJuIEJ1ZmZlci5fYXVnbWVudCh0aGlzLnN1YmFycmF5KHN0YXJ0LCBlbmQpKVxuICB9IGVsc2Uge1xuICAgIHZhciBzbGljZUxlbiA9IGVuZCAtIHN0YXJ0XG4gICAgdmFyIG5ld0J1ZiA9IG5ldyBCdWZmZXIoc2xpY2VMZW4sIHVuZGVmaW5lZCwgdHJ1ZSlcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IHNsaWNlTGVuOyBpKyspIHtcbiAgICAgIG5ld0J1ZltpXSA9IHRoaXNbaSArIHN0YXJ0XVxuICAgIH1cbiAgICByZXR1cm4gbmV3QnVmXG4gIH1cbn1cblxuLypcbiAqIE5lZWQgdG8gbWFrZSBzdXJlIHRoYXQgYnVmZmVyIGlzbid0IHRyeWluZyB0byB3cml0ZSBvdXQgb2YgYm91bmRzLlxuICovXG5mdW5jdGlvbiBjaGVja09mZnNldCAob2Zmc2V0LCBleHQsIGxlbmd0aCkge1xuICBpZiAoKG9mZnNldCAlIDEpICE9PSAwIHx8IG9mZnNldCA8IDApXG4gICAgdGhyb3cgbmV3IFJhbmdlRXJyb3IoJ29mZnNldCBpcyBub3QgdWludCcpXG4gIGlmIChvZmZzZXQgKyBleHQgPiBsZW5ndGgpXG4gICAgdGhyb3cgbmV3IFJhbmdlRXJyb3IoJ1RyeWluZyB0byBhY2Nlc3MgYmV5b25kIGJ1ZmZlciBsZW5ndGgnKVxufVxuXG5CdWZmZXIucHJvdG90eXBlLnJlYWRVSW50OCA9IGZ1bmN0aW9uIChvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIGlmICghbm9Bc3NlcnQpXG4gICAgY2hlY2tPZmZzZXQob2Zmc2V0LCAxLCB0aGlzLmxlbmd0aClcbiAgcmV0dXJuIHRoaXNbb2Zmc2V0XVxufVxuXG5CdWZmZXIucHJvdG90eXBlLnJlYWRVSW50MTZMRSA9IGZ1bmN0aW9uIChvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIGlmICghbm9Bc3NlcnQpXG4gICAgY2hlY2tPZmZzZXQob2Zmc2V0LCAyLCB0aGlzLmxlbmd0aClcbiAgcmV0dXJuIHRoaXNbb2Zmc2V0XSB8ICh0aGlzW29mZnNldCArIDFdIDw8IDgpXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUucmVhZFVJbnQxNkJFID0gZnVuY3Rpb24gKG9mZnNldCwgbm9Bc3NlcnQpIHtcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja09mZnNldChvZmZzZXQsIDIsIHRoaXMubGVuZ3RoKVxuICByZXR1cm4gKHRoaXNbb2Zmc2V0XSA8PCA4KSB8IHRoaXNbb2Zmc2V0ICsgMV1cbn1cblxuQnVmZmVyLnByb3RvdHlwZS5yZWFkVUludDMyTEUgPSBmdW5jdGlvbiAob2Zmc2V0LCBub0Fzc2VydCkge1xuICBpZiAoIW5vQXNzZXJ0KVxuICAgIGNoZWNrT2Zmc2V0KG9mZnNldCwgNCwgdGhpcy5sZW5ndGgpXG5cbiAgcmV0dXJuICgodGhpc1tvZmZzZXRdKSB8XG4gICAgICAodGhpc1tvZmZzZXQgKyAxXSA8PCA4KSB8XG4gICAgICAodGhpc1tvZmZzZXQgKyAyXSA8PCAxNikpICtcbiAgICAgICh0aGlzW29mZnNldCArIDNdICogMHgxMDAwMDAwKVxufVxuXG5CdWZmZXIucHJvdG90eXBlLnJlYWRVSW50MzJCRSA9IGZ1bmN0aW9uIChvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIGlmICghbm9Bc3NlcnQpXG4gICAgY2hlY2tPZmZzZXQob2Zmc2V0LCA0LCB0aGlzLmxlbmd0aClcblxuICByZXR1cm4gKHRoaXNbb2Zmc2V0XSAqIDB4MTAwMDAwMCkgK1xuICAgICAgKCh0aGlzW29mZnNldCArIDFdIDw8IDE2KSB8XG4gICAgICAodGhpc1tvZmZzZXQgKyAyXSA8PCA4KSB8XG4gICAgICB0aGlzW29mZnNldCArIDNdKVxufVxuXG5CdWZmZXIucHJvdG90eXBlLnJlYWRJbnQ4ID0gZnVuY3Rpb24gKG9mZnNldCwgbm9Bc3NlcnQpIHtcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja09mZnNldChvZmZzZXQsIDEsIHRoaXMubGVuZ3RoKVxuICBpZiAoISh0aGlzW29mZnNldF0gJiAweDgwKSlcbiAgICByZXR1cm4gKHRoaXNbb2Zmc2V0XSlcbiAgcmV0dXJuICgoMHhmZiAtIHRoaXNbb2Zmc2V0XSArIDEpICogLTEpXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUucmVhZEludDE2TEUgPSBmdW5jdGlvbiAob2Zmc2V0LCBub0Fzc2VydCkge1xuICBpZiAoIW5vQXNzZXJ0KVxuICAgIGNoZWNrT2Zmc2V0KG9mZnNldCwgMiwgdGhpcy5sZW5ndGgpXG4gIHZhciB2YWwgPSB0aGlzW29mZnNldF0gfCAodGhpc1tvZmZzZXQgKyAxXSA8PCA4KVxuICByZXR1cm4gKHZhbCAmIDB4ODAwMCkgPyB2YWwgfCAweEZGRkYwMDAwIDogdmFsXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUucmVhZEludDE2QkUgPSBmdW5jdGlvbiAob2Zmc2V0LCBub0Fzc2VydCkge1xuICBpZiAoIW5vQXNzZXJ0KVxuICAgIGNoZWNrT2Zmc2V0KG9mZnNldCwgMiwgdGhpcy5sZW5ndGgpXG4gIHZhciB2YWwgPSB0aGlzW29mZnNldCArIDFdIHwgKHRoaXNbb2Zmc2V0XSA8PCA4KVxuICByZXR1cm4gKHZhbCAmIDB4ODAwMCkgPyB2YWwgfCAweEZGRkYwMDAwIDogdmFsXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUucmVhZEludDMyTEUgPSBmdW5jdGlvbiAob2Zmc2V0LCBub0Fzc2VydCkge1xuICBpZiAoIW5vQXNzZXJ0KVxuICAgIGNoZWNrT2Zmc2V0KG9mZnNldCwgNCwgdGhpcy5sZW5ndGgpXG5cbiAgcmV0dXJuICh0aGlzW29mZnNldF0pIHxcbiAgICAgICh0aGlzW29mZnNldCArIDFdIDw8IDgpIHxcbiAgICAgICh0aGlzW29mZnNldCArIDJdIDw8IDE2KSB8XG4gICAgICAodGhpc1tvZmZzZXQgKyAzXSA8PCAyNClcbn1cblxuQnVmZmVyLnByb3RvdHlwZS5yZWFkSW50MzJCRSA9IGZ1bmN0aW9uIChvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIGlmICghbm9Bc3NlcnQpXG4gICAgY2hlY2tPZmZzZXQob2Zmc2V0LCA0LCB0aGlzLmxlbmd0aClcblxuICByZXR1cm4gKHRoaXNbb2Zmc2V0XSA8PCAyNCkgfFxuICAgICAgKHRoaXNbb2Zmc2V0ICsgMV0gPDwgMTYpIHxcbiAgICAgICh0aGlzW29mZnNldCArIDJdIDw8IDgpIHxcbiAgICAgICh0aGlzW29mZnNldCArIDNdKVxufVxuXG5CdWZmZXIucHJvdG90eXBlLnJlYWRGbG9hdExFID0gZnVuY3Rpb24gKG9mZnNldCwgbm9Bc3NlcnQpIHtcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja09mZnNldChvZmZzZXQsIDQsIHRoaXMubGVuZ3RoKVxuICByZXR1cm4gaWVlZTc1NC5yZWFkKHRoaXMsIG9mZnNldCwgdHJ1ZSwgMjMsIDQpXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUucmVhZEZsb2F0QkUgPSBmdW5jdGlvbiAob2Zmc2V0LCBub0Fzc2VydCkge1xuICBpZiAoIW5vQXNzZXJ0KVxuICAgIGNoZWNrT2Zmc2V0KG9mZnNldCwgNCwgdGhpcy5sZW5ndGgpXG4gIHJldHVybiBpZWVlNzU0LnJlYWQodGhpcywgb2Zmc2V0LCBmYWxzZSwgMjMsIDQpXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUucmVhZERvdWJsZUxFID0gZnVuY3Rpb24gKG9mZnNldCwgbm9Bc3NlcnQpIHtcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja09mZnNldChvZmZzZXQsIDgsIHRoaXMubGVuZ3RoKVxuICByZXR1cm4gaWVlZTc1NC5yZWFkKHRoaXMsIG9mZnNldCwgdHJ1ZSwgNTIsIDgpXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUucmVhZERvdWJsZUJFID0gZnVuY3Rpb24gKG9mZnNldCwgbm9Bc3NlcnQpIHtcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja09mZnNldChvZmZzZXQsIDgsIHRoaXMubGVuZ3RoKVxuICByZXR1cm4gaWVlZTc1NC5yZWFkKHRoaXMsIG9mZnNldCwgZmFsc2UsIDUyLCA4KVxufVxuXG5mdW5jdGlvbiBjaGVja0ludCAoYnVmLCB2YWx1ZSwgb2Zmc2V0LCBleHQsIG1heCwgbWluKSB7XG4gIGlmICghQnVmZmVyLmlzQnVmZmVyKGJ1ZikpIHRocm93IG5ldyBUeXBlRXJyb3IoJ2J1ZmZlciBtdXN0IGJlIGEgQnVmZmVyIGluc3RhbmNlJylcbiAgaWYgKHZhbHVlID4gbWF4IHx8IHZhbHVlIDwgbWluKSB0aHJvdyBuZXcgVHlwZUVycm9yKCd2YWx1ZSBpcyBvdXQgb2YgYm91bmRzJylcbiAgaWYgKG9mZnNldCArIGV4dCA+IGJ1Zi5sZW5ndGgpIHRocm93IG5ldyBUeXBlRXJyb3IoJ2luZGV4IG91dCBvZiByYW5nZScpXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUud3JpdGVVSW50OCA9IGZ1bmN0aW9uICh2YWx1ZSwgb2Zmc2V0LCBub0Fzc2VydCkge1xuICB2YWx1ZSA9ICt2YWx1ZVxuICBvZmZzZXQgPSBvZmZzZXQgPj4+IDBcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja0ludCh0aGlzLCB2YWx1ZSwgb2Zmc2V0LCAxLCAweGZmLCAwKVxuICBpZiAoIUJ1ZmZlci5UWVBFRF9BUlJBWV9TVVBQT1JUKSB2YWx1ZSA9IE1hdGguZmxvb3IodmFsdWUpXG4gIHRoaXNbb2Zmc2V0XSA9IHZhbHVlXG4gIHJldHVybiBvZmZzZXQgKyAxXG59XG5cbmZ1bmN0aW9uIG9iamVjdFdyaXRlVUludDE2IChidWYsIHZhbHVlLCBvZmZzZXQsIGxpdHRsZUVuZGlhbikge1xuICBpZiAodmFsdWUgPCAwKSB2YWx1ZSA9IDB4ZmZmZiArIHZhbHVlICsgMVxuICBmb3IgKHZhciBpID0gMCwgaiA9IE1hdGgubWluKGJ1Zi5sZW5ndGggLSBvZmZzZXQsIDIpOyBpIDwgajsgaSsrKSB7XG4gICAgYnVmW29mZnNldCArIGldID0gKHZhbHVlICYgKDB4ZmYgPDwgKDggKiAobGl0dGxlRW5kaWFuID8gaSA6IDEgLSBpKSkpKSA+Pj5cbiAgICAgIChsaXR0bGVFbmRpYW4gPyBpIDogMSAtIGkpICogOFxuICB9XG59XG5cbkJ1ZmZlci5wcm90b3R5cGUud3JpdGVVSW50MTZMRSA9IGZ1bmN0aW9uICh2YWx1ZSwgb2Zmc2V0LCBub0Fzc2VydCkge1xuICB2YWx1ZSA9ICt2YWx1ZVxuICBvZmZzZXQgPSBvZmZzZXQgPj4+IDBcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja0ludCh0aGlzLCB2YWx1ZSwgb2Zmc2V0LCAyLCAweGZmZmYsIDApXG4gIGlmIChCdWZmZXIuVFlQRURfQVJSQVlfU1VQUE9SVCkge1xuICAgIHRoaXNbb2Zmc2V0XSA9IHZhbHVlXG4gICAgdGhpc1tvZmZzZXQgKyAxXSA9ICh2YWx1ZSA+Pj4gOClcbiAgfSBlbHNlIG9iamVjdFdyaXRlVUludDE2KHRoaXMsIHZhbHVlLCBvZmZzZXQsIHRydWUpXG4gIHJldHVybiBvZmZzZXQgKyAyXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUud3JpdGVVSW50MTZCRSA9IGZ1bmN0aW9uICh2YWx1ZSwgb2Zmc2V0LCBub0Fzc2VydCkge1xuICB2YWx1ZSA9ICt2YWx1ZVxuICBvZmZzZXQgPSBvZmZzZXQgPj4+IDBcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja0ludCh0aGlzLCB2YWx1ZSwgb2Zmc2V0LCAyLCAweGZmZmYsIDApXG4gIGlmIChCdWZmZXIuVFlQRURfQVJSQVlfU1VQUE9SVCkge1xuICAgIHRoaXNbb2Zmc2V0XSA9ICh2YWx1ZSA+Pj4gOClcbiAgICB0aGlzW29mZnNldCArIDFdID0gdmFsdWVcbiAgfSBlbHNlIG9iamVjdFdyaXRlVUludDE2KHRoaXMsIHZhbHVlLCBvZmZzZXQsIGZhbHNlKVxuICByZXR1cm4gb2Zmc2V0ICsgMlxufVxuXG5mdW5jdGlvbiBvYmplY3RXcml0ZVVJbnQzMiAoYnVmLCB2YWx1ZSwgb2Zmc2V0LCBsaXR0bGVFbmRpYW4pIHtcbiAgaWYgKHZhbHVlIDwgMCkgdmFsdWUgPSAweGZmZmZmZmZmICsgdmFsdWUgKyAxXG4gIGZvciAodmFyIGkgPSAwLCBqID0gTWF0aC5taW4oYnVmLmxlbmd0aCAtIG9mZnNldCwgNCk7IGkgPCBqOyBpKyspIHtcbiAgICBidWZbb2Zmc2V0ICsgaV0gPSAodmFsdWUgPj4+IChsaXR0bGVFbmRpYW4gPyBpIDogMyAtIGkpICogOCkgJiAweGZmXG4gIH1cbn1cblxuQnVmZmVyLnByb3RvdHlwZS53cml0ZVVJbnQzMkxFID0gZnVuY3Rpb24gKHZhbHVlLCBvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIHZhbHVlID0gK3ZhbHVlXG4gIG9mZnNldCA9IG9mZnNldCA+Pj4gMFxuICBpZiAoIW5vQXNzZXJ0KVxuICAgIGNoZWNrSW50KHRoaXMsIHZhbHVlLCBvZmZzZXQsIDQsIDB4ZmZmZmZmZmYsIDApXG4gIGlmIChCdWZmZXIuVFlQRURfQVJSQVlfU1VQUE9SVCkge1xuICAgIHRoaXNbb2Zmc2V0ICsgM10gPSAodmFsdWUgPj4+IDI0KVxuICAgIHRoaXNbb2Zmc2V0ICsgMl0gPSAodmFsdWUgPj4+IDE2KVxuICAgIHRoaXNbb2Zmc2V0ICsgMV0gPSAodmFsdWUgPj4+IDgpXG4gICAgdGhpc1tvZmZzZXRdID0gdmFsdWVcbiAgfSBlbHNlIG9iamVjdFdyaXRlVUludDMyKHRoaXMsIHZhbHVlLCBvZmZzZXQsIHRydWUpXG4gIHJldHVybiBvZmZzZXQgKyA0XG59XG5cbkJ1ZmZlci5wcm90b3R5cGUud3JpdGVVSW50MzJCRSA9IGZ1bmN0aW9uICh2YWx1ZSwgb2Zmc2V0LCBub0Fzc2VydCkge1xuICB2YWx1ZSA9ICt2YWx1ZVxuICBvZmZzZXQgPSBvZmZzZXQgPj4+IDBcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja0ludCh0aGlzLCB2YWx1ZSwgb2Zmc2V0LCA0LCAweGZmZmZmZmZmLCAwKVxuICBpZiAoQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlQpIHtcbiAgICB0aGlzW29mZnNldF0gPSAodmFsdWUgPj4+IDI0KVxuICAgIHRoaXNbb2Zmc2V0ICsgMV0gPSAodmFsdWUgPj4+IDE2KVxuICAgIHRoaXNbb2Zmc2V0ICsgMl0gPSAodmFsdWUgPj4+IDgpXG4gICAgdGhpc1tvZmZzZXQgKyAzXSA9IHZhbHVlXG4gIH0gZWxzZSBvYmplY3RXcml0ZVVJbnQzMih0aGlzLCB2YWx1ZSwgb2Zmc2V0LCBmYWxzZSlcbiAgcmV0dXJuIG9mZnNldCArIDRcbn1cblxuQnVmZmVyLnByb3RvdHlwZS53cml0ZUludDggPSBmdW5jdGlvbiAodmFsdWUsIG9mZnNldCwgbm9Bc3NlcnQpIHtcbiAgdmFsdWUgPSArdmFsdWVcbiAgb2Zmc2V0ID0gb2Zmc2V0ID4+PiAwXG4gIGlmICghbm9Bc3NlcnQpXG4gICAgY2hlY2tJbnQodGhpcywgdmFsdWUsIG9mZnNldCwgMSwgMHg3ZiwgLTB4ODApXG4gIGlmICghQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlQpIHZhbHVlID0gTWF0aC5mbG9vcih2YWx1ZSlcbiAgaWYgKHZhbHVlIDwgMCkgdmFsdWUgPSAweGZmICsgdmFsdWUgKyAxXG4gIHRoaXNbb2Zmc2V0XSA9IHZhbHVlXG4gIHJldHVybiBvZmZzZXQgKyAxXG59XG5cbkJ1ZmZlci5wcm90b3R5cGUud3JpdGVJbnQxNkxFID0gZnVuY3Rpb24gKHZhbHVlLCBvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIHZhbHVlID0gK3ZhbHVlXG4gIG9mZnNldCA9IG9mZnNldCA+Pj4gMFxuICBpZiAoIW5vQXNzZXJ0KVxuICAgIGNoZWNrSW50KHRoaXMsIHZhbHVlLCBvZmZzZXQsIDIsIDB4N2ZmZiwgLTB4ODAwMClcbiAgaWYgKEJ1ZmZlci5UWVBFRF9BUlJBWV9TVVBQT1JUKSB7XG4gICAgdGhpc1tvZmZzZXRdID0gdmFsdWVcbiAgICB0aGlzW29mZnNldCArIDFdID0gKHZhbHVlID4+PiA4KVxuICB9IGVsc2Ugb2JqZWN0V3JpdGVVSW50MTYodGhpcywgdmFsdWUsIG9mZnNldCwgdHJ1ZSlcbiAgcmV0dXJuIG9mZnNldCArIDJcbn1cblxuQnVmZmVyLnByb3RvdHlwZS53cml0ZUludDE2QkUgPSBmdW5jdGlvbiAodmFsdWUsIG9mZnNldCwgbm9Bc3NlcnQpIHtcbiAgdmFsdWUgPSArdmFsdWVcbiAgb2Zmc2V0ID0gb2Zmc2V0ID4+PiAwXG4gIGlmICghbm9Bc3NlcnQpXG4gICAgY2hlY2tJbnQodGhpcywgdmFsdWUsIG9mZnNldCwgMiwgMHg3ZmZmLCAtMHg4MDAwKVxuICBpZiAoQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlQpIHtcbiAgICB0aGlzW29mZnNldF0gPSAodmFsdWUgPj4+IDgpXG4gICAgdGhpc1tvZmZzZXQgKyAxXSA9IHZhbHVlXG4gIH0gZWxzZSBvYmplY3RXcml0ZVVJbnQxNih0aGlzLCB2YWx1ZSwgb2Zmc2V0LCBmYWxzZSlcbiAgcmV0dXJuIG9mZnNldCArIDJcbn1cblxuQnVmZmVyLnByb3RvdHlwZS53cml0ZUludDMyTEUgPSBmdW5jdGlvbiAodmFsdWUsIG9mZnNldCwgbm9Bc3NlcnQpIHtcbiAgdmFsdWUgPSArdmFsdWVcbiAgb2Zmc2V0ID0gb2Zmc2V0ID4+PiAwXG4gIGlmICghbm9Bc3NlcnQpXG4gICAgY2hlY2tJbnQodGhpcywgdmFsdWUsIG9mZnNldCwgNCwgMHg3ZmZmZmZmZiwgLTB4ODAwMDAwMDApXG4gIGlmIChCdWZmZXIuVFlQRURfQVJSQVlfU1VQUE9SVCkge1xuICAgIHRoaXNbb2Zmc2V0XSA9IHZhbHVlXG4gICAgdGhpc1tvZmZzZXQgKyAxXSA9ICh2YWx1ZSA+Pj4gOClcbiAgICB0aGlzW29mZnNldCArIDJdID0gKHZhbHVlID4+PiAxNilcbiAgICB0aGlzW29mZnNldCArIDNdID0gKHZhbHVlID4+PiAyNClcbiAgfSBlbHNlIG9iamVjdFdyaXRlVUludDMyKHRoaXMsIHZhbHVlLCBvZmZzZXQsIHRydWUpXG4gIHJldHVybiBvZmZzZXQgKyA0XG59XG5cbkJ1ZmZlci5wcm90b3R5cGUud3JpdGVJbnQzMkJFID0gZnVuY3Rpb24gKHZhbHVlLCBvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIHZhbHVlID0gK3ZhbHVlXG4gIG9mZnNldCA9IG9mZnNldCA+Pj4gMFxuICBpZiAoIW5vQXNzZXJ0KVxuICAgIGNoZWNrSW50KHRoaXMsIHZhbHVlLCBvZmZzZXQsIDQsIDB4N2ZmZmZmZmYsIC0weDgwMDAwMDAwKVxuICBpZiAodmFsdWUgPCAwKSB2YWx1ZSA9IDB4ZmZmZmZmZmYgKyB2YWx1ZSArIDFcbiAgaWYgKEJ1ZmZlci5UWVBFRF9BUlJBWV9TVVBQT1JUKSB7XG4gICAgdGhpc1tvZmZzZXRdID0gKHZhbHVlID4+PiAyNClcbiAgICB0aGlzW29mZnNldCArIDFdID0gKHZhbHVlID4+PiAxNilcbiAgICB0aGlzW29mZnNldCArIDJdID0gKHZhbHVlID4+PiA4KVxuICAgIHRoaXNbb2Zmc2V0ICsgM10gPSB2YWx1ZVxuICB9IGVsc2Ugb2JqZWN0V3JpdGVVSW50MzIodGhpcywgdmFsdWUsIG9mZnNldCwgZmFsc2UpXG4gIHJldHVybiBvZmZzZXQgKyA0XG59XG5cbmZ1bmN0aW9uIGNoZWNrSUVFRTc1NCAoYnVmLCB2YWx1ZSwgb2Zmc2V0LCBleHQsIG1heCwgbWluKSB7XG4gIGlmICh2YWx1ZSA+IG1heCB8fCB2YWx1ZSA8IG1pbikgdGhyb3cgbmV3IFR5cGVFcnJvcigndmFsdWUgaXMgb3V0IG9mIGJvdW5kcycpXG4gIGlmIChvZmZzZXQgKyBleHQgPiBidWYubGVuZ3RoKSB0aHJvdyBuZXcgVHlwZUVycm9yKCdpbmRleCBvdXQgb2YgcmFuZ2UnKVxufVxuXG5mdW5jdGlvbiB3cml0ZUZsb2F0IChidWYsIHZhbHVlLCBvZmZzZXQsIGxpdHRsZUVuZGlhbiwgbm9Bc3NlcnQpIHtcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja0lFRUU3NTQoYnVmLCB2YWx1ZSwgb2Zmc2V0LCA0LCAzLjQwMjgyMzQ2NjM4NTI4ODZlKzM4LCAtMy40MDI4MjM0NjYzODUyODg2ZSszOClcbiAgaWVlZTc1NC53cml0ZShidWYsIHZhbHVlLCBvZmZzZXQsIGxpdHRsZUVuZGlhbiwgMjMsIDQpXG4gIHJldHVybiBvZmZzZXQgKyA0XG59XG5cbkJ1ZmZlci5wcm90b3R5cGUud3JpdGVGbG9hdExFID0gZnVuY3Rpb24gKHZhbHVlLCBvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIHJldHVybiB3cml0ZUZsb2F0KHRoaXMsIHZhbHVlLCBvZmZzZXQsIHRydWUsIG5vQXNzZXJ0KVxufVxuXG5CdWZmZXIucHJvdG90eXBlLndyaXRlRmxvYXRCRSA9IGZ1bmN0aW9uICh2YWx1ZSwgb2Zmc2V0LCBub0Fzc2VydCkge1xuICByZXR1cm4gd3JpdGVGbG9hdCh0aGlzLCB2YWx1ZSwgb2Zmc2V0LCBmYWxzZSwgbm9Bc3NlcnQpXG59XG5cbmZ1bmN0aW9uIHdyaXRlRG91YmxlIChidWYsIHZhbHVlLCBvZmZzZXQsIGxpdHRsZUVuZGlhbiwgbm9Bc3NlcnQpIHtcbiAgaWYgKCFub0Fzc2VydClcbiAgICBjaGVja0lFRUU3NTQoYnVmLCB2YWx1ZSwgb2Zmc2V0LCA4LCAxLjc5NzY5MzEzNDg2MjMxNTdFKzMwOCwgLTEuNzk3NjkzMTM0ODYyMzE1N0UrMzA4KVxuICBpZWVlNzU0LndyaXRlKGJ1ZiwgdmFsdWUsIG9mZnNldCwgbGl0dGxlRW5kaWFuLCA1MiwgOClcbiAgcmV0dXJuIG9mZnNldCArIDhcbn1cblxuQnVmZmVyLnByb3RvdHlwZS53cml0ZURvdWJsZUxFID0gZnVuY3Rpb24gKHZhbHVlLCBvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIHJldHVybiB3cml0ZURvdWJsZSh0aGlzLCB2YWx1ZSwgb2Zmc2V0LCB0cnVlLCBub0Fzc2VydClcbn1cblxuQnVmZmVyLnByb3RvdHlwZS53cml0ZURvdWJsZUJFID0gZnVuY3Rpb24gKHZhbHVlLCBvZmZzZXQsIG5vQXNzZXJ0KSB7XG4gIHJldHVybiB3cml0ZURvdWJsZSh0aGlzLCB2YWx1ZSwgb2Zmc2V0LCBmYWxzZSwgbm9Bc3NlcnQpXG59XG5cbi8vIGNvcHkodGFyZ2V0QnVmZmVyLCB0YXJnZXRTdGFydD0wLCBzb3VyY2VTdGFydD0wLCBzb3VyY2VFbmQ9YnVmZmVyLmxlbmd0aClcbkJ1ZmZlci5wcm90b3R5cGUuY29weSA9IGZ1bmN0aW9uICh0YXJnZXQsIHRhcmdldF9zdGFydCwgc3RhcnQsIGVuZCkge1xuICB2YXIgc291cmNlID0gdGhpc1xuXG4gIGlmICghc3RhcnQpIHN0YXJ0ID0gMFxuICBpZiAoIWVuZCAmJiBlbmQgIT09IDApIGVuZCA9IHRoaXMubGVuZ3RoXG4gIGlmICghdGFyZ2V0X3N0YXJ0KSB0YXJnZXRfc3RhcnQgPSAwXG5cbiAgLy8gQ29weSAwIGJ5dGVzOyB3ZSdyZSBkb25lXG4gIGlmIChlbmQgPT09IHN0YXJ0KSByZXR1cm5cbiAgaWYgKHRhcmdldC5sZW5ndGggPT09IDAgfHwgc291cmNlLmxlbmd0aCA9PT0gMCkgcmV0dXJuXG5cbiAgLy8gRmF0YWwgZXJyb3IgY29uZGl0aW9uc1xuICBpZiAoZW5kIDwgc3RhcnQpIHRocm93IG5ldyBUeXBlRXJyb3IoJ3NvdXJjZUVuZCA8IHNvdXJjZVN0YXJ0JylcbiAgaWYgKHRhcmdldF9zdGFydCA8IDAgfHwgdGFyZ2V0X3N0YXJ0ID49IHRhcmdldC5sZW5ndGgpXG4gICAgdGhyb3cgbmV3IFR5cGVFcnJvcigndGFyZ2V0U3RhcnQgb3V0IG9mIGJvdW5kcycpXG4gIGlmIChzdGFydCA8IDAgfHwgc3RhcnQgPj0gc291cmNlLmxlbmd0aCkgdGhyb3cgbmV3IFR5cGVFcnJvcignc291cmNlU3RhcnQgb3V0IG9mIGJvdW5kcycpXG4gIGlmIChlbmQgPCAwIHx8IGVuZCA+IHNvdXJjZS5sZW5ndGgpIHRocm93IG5ldyBUeXBlRXJyb3IoJ3NvdXJjZUVuZCBvdXQgb2YgYm91bmRzJylcblxuICAvLyBBcmUgd2Ugb29iP1xuICBpZiAoZW5kID4gdGhpcy5sZW5ndGgpXG4gICAgZW5kID0gdGhpcy5sZW5ndGhcbiAgaWYgKHRhcmdldC5sZW5ndGggLSB0YXJnZXRfc3RhcnQgPCBlbmQgLSBzdGFydClcbiAgICBlbmQgPSB0YXJnZXQubGVuZ3RoIC0gdGFyZ2V0X3N0YXJ0ICsgc3RhcnRcblxuICB2YXIgbGVuID0gZW5kIC0gc3RhcnRcblxuICBpZiAobGVuIDwgMTAwMCB8fCAhQnVmZmVyLlRZUEVEX0FSUkFZX1NVUFBPUlQpIHtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGxlbjsgaSsrKSB7XG4gICAgICB0YXJnZXRbaSArIHRhcmdldF9zdGFydF0gPSB0aGlzW2kgKyBzdGFydF1cbiAgICB9XG4gIH0gZWxzZSB7XG4gICAgdGFyZ2V0Ll9zZXQodGhpcy5zdWJhcnJheShzdGFydCwgc3RhcnQgKyBsZW4pLCB0YXJnZXRfc3RhcnQpXG4gIH1cbn1cblxuLy8gZmlsbCh2YWx1ZSwgc3RhcnQ9MCwgZW5kPWJ1ZmZlci5sZW5ndGgpXG5CdWZmZXIucHJvdG90eXBlLmZpbGwgPSBmdW5jdGlvbiAodmFsdWUsIHN0YXJ0LCBlbmQpIHtcbiAgaWYgKCF2YWx1ZSkgdmFsdWUgPSAwXG4gIGlmICghc3RhcnQpIHN0YXJ0ID0gMFxuICBpZiAoIWVuZCkgZW5kID0gdGhpcy5sZW5ndGhcblxuICBpZiAoZW5kIDwgc3RhcnQpIHRocm93IG5ldyBUeXBlRXJyb3IoJ2VuZCA8IHN0YXJ0JylcblxuICAvLyBGaWxsIDAgYnl0ZXM7IHdlJ3JlIGRvbmVcbiAgaWYgKGVuZCA9PT0gc3RhcnQpIHJldHVyblxuICBpZiAodGhpcy5sZW5ndGggPT09IDApIHJldHVyblxuXG4gIGlmIChzdGFydCA8IDAgfHwgc3RhcnQgPj0gdGhpcy5sZW5ndGgpIHRocm93IG5ldyBUeXBlRXJyb3IoJ3N0YXJ0IG91dCBvZiBib3VuZHMnKVxuICBpZiAoZW5kIDwgMCB8fCBlbmQgPiB0aGlzLmxlbmd0aCkgdGhyb3cgbmV3IFR5cGVFcnJvcignZW5kIG91dCBvZiBib3VuZHMnKVxuXG4gIHZhciBpXG4gIGlmICh0eXBlb2YgdmFsdWUgPT09ICdudW1iZXInKSB7XG4gICAgZm9yIChpID0gc3RhcnQ7IGkgPCBlbmQ7IGkrKykge1xuICAgICAgdGhpc1tpXSA9IHZhbHVlXG4gICAgfVxuICB9IGVsc2Uge1xuICAgIHZhciBieXRlcyA9IHV0ZjhUb0J5dGVzKHZhbHVlLnRvU3RyaW5nKCkpXG4gICAgdmFyIGxlbiA9IGJ5dGVzLmxlbmd0aFxuICAgIGZvciAoaSA9IHN0YXJ0OyBpIDwgZW5kOyBpKyspIHtcbiAgICAgIHRoaXNbaV0gPSBieXRlc1tpICUgbGVuXVxuICAgIH1cbiAgfVxuXG4gIHJldHVybiB0aGlzXG59XG5cbi8qKlxuICogQ3JlYXRlcyBhIG5ldyBgQXJyYXlCdWZmZXJgIHdpdGggdGhlICpjb3BpZWQqIG1lbW9yeSBvZiB0aGUgYnVmZmVyIGluc3RhbmNlLlxuICogQWRkZWQgaW4gTm9kZSAwLjEyLiBPbmx5IGF2YWlsYWJsZSBpbiBicm93c2VycyB0aGF0IHN1cHBvcnQgQXJyYXlCdWZmZXIuXG4gKi9cbkJ1ZmZlci5wcm90b3R5cGUudG9BcnJheUJ1ZmZlciA9IGZ1bmN0aW9uICgpIHtcbiAgaWYgKHR5cGVvZiBVaW50OEFycmF5ICE9PSAndW5kZWZpbmVkJykge1xuICAgIGlmIChCdWZmZXIuVFlQRURfQVJSQVlfU1VQUE9SVCkge1xuICAgICAgcmV0dXJuIChuZXcgQnVmZmVyKHRoaXMpKS5idWZmZXJcbiAgICB9IGVsc2Uge1xuICAgICAgdmFyIGJ1ZiA9IG5ldyBVaW50OEFycmF5KHRoaXMubGVuZ3RoKVxuICAgICAgZm9yICh2YXIgaSA9IDAsIGxlbiA9IGJ1Zi5sZW5ndGg7IGkgPCBsZW47IGkgKz0gMSkge1xuICAgICAgICBidWZbaV0gPSB0aGlzW2ldXG4gICAgICB9XG4gICAgICByZXR1cm4gYnVmLmJ1ZmZlclxuICAgIH1cbiAgfSBlbHNlIHtcbiAgICB0aHJvdyBuZXcgVHlwZUVycm9yKCdCdWZmZXIudG9BcnJheUJ1ZmZlciBub3Qgc3VwcG9ydGVkIGluIHRoaXMgYnJvd3NlcicpXG4gIH1cbn1cblxuLy8gSEVMUEVSIEZVTkNUSU9OU1xuLy8gPT09PT09PT09PT09PT09PVxuXG52YXIgQlAgPSBCdWZmZXIucHJvdG90eXBlXG5cbi8qKlxuICogQXVnbWVudCBhIFVpbnQ4QXJyYXkgKmluc3RhbmNlKiAobm90IHRoZSBVaW50OEFycmF5IGNsYXNzISkgd2l0aCBCdWZmZXIgbWV0aG9kc1xuICovXG5CdWZmZXIuX2F1Z21lbnQgPSBmdW5jdGlvbiAoYXJyKSB7XG4gIGFyci5jb25zdHJ1Y3RvciA9IEJ1ZmZlclxuICBhcnIuX2lzQnVmZmVyID0gdHJ1ZVxuXG4gIC8vIHNhdmUgcmVmZXJlbmNlIHRvIG9yaWdpbmFsIFVpbnQ4QXJyYXkgZ2V0L3NldCBtZXRob2RzIGJlZm9yZSBvdmVyd3JpdGluZ1xuICBhcnIuX2dldCA9IGFyci5nZXRcbiAgYXJyLl9zZXQgPSBhcnIuc2V0XG5cbiAgLy8gZGVwcmVjYXRlZCwgd2lsbCBiZSByZW1vdmVkIGluIG5vZGUgMC4xMytcbiAgYXJyLmdldCA9IEJQLmdldFxuICBhcnIuc2V0ID0gQlAuc2V0XG5cbiAgYXJyLndyaXRlID0gQlAud3JpdGVcbiAgYXJyLnRvU3RyaW5nID0gQlAudG9TdHJpbmdcbiAgYXJyLnRvTG9jYWxlU3RyaW5nID0gQlAudG9TdHJpbmdcbiAgYXJyLnRvSlNPTiA9IEJQLnRvSlNPTlxuICBhcnIuZXF1YWxzID0gQlAuZXF1YWxzXG4gIGFyci5jb21wYXJlID0gQlAuY29tcGFyZVxuICBhcnIuY29weSA9IEJQLmNvcHlcbiAgYXJyLnNsaWNlID0gQlAuc2xpY2VcbiAgYXJyLnJlYWRVSW50OCA9IEJQLnJlYWRVSW50OFxuICBhcnIucmVhZFVJbnQxNkxFID0gQlAucmVhZFVJbnQxNkxFXG4gIGFyci5yZWFkVUludDE2QkUgPSBCUC5yZWFkVUludDE2QkVcbiAgYXJyLnJlYWRVSW50MzJMRSA9IEJQLnJlYWRVSW50MzJMRVxuICBhcnIucmVhZFVJbnQzMkJFID0gQlAucmVhZFVJbnQzMkJFXG4gIGFyci5yZWFkSW50OCA9IEJQLnJlYWRJbnQ4XG4gIGFyci5yZWFkSW50MTZMRSA9IEJQLnJlYWRJbnQxNkxFXG4gIGFyci5yZWFkSW50MTZCRSA9IEJQLnJlYWRJbnQxNkJFXG4gIGFyci5yZWFkSW50MzJMRSA9IEJQLnJlYWRJbnQzMkxFXG4gIGFyci5yZWFkSW50MzJCRSA9IEJQLnJlYWRJbnQzMkJFXG4gIGFyci5yZWFkRmxvYXRMRSA9IEJQLnJlYWRGbG9hdExFXG4gIGFyci5yZWFkRmxvYXRCRSA9IEJQLnJlYWRGbG9hdEJFXG4gIGFyci5yZWFkRG91YmxlTEUgPSBCUC5yZWFkRG91YmxlTEVcbiAgYXJyLnJlYWREb3VibGVCRSA9IEJQLnJlYWREb3VibGVCRVxuICBhcnIud3JpdGVVSW50OCA9IEJQLndyaXRlVUludDhcbiAgYXJyLndyaXRlVUludDE2TEUgPSBCUC53cml0ZVVJbnQxNkxFXG4gIGFyci53cml0ZVVJbnQxNkJFID0gQlAud3JpdGVVSW50MTZCRVxuICBhcnIud3JpdGVVSW50MzJMRSA9IEJQLndyaXRlVUludDMyTEVcbiAgYXJyLndyaXRlVUludDMyQkUgPSBCUC53cml0ZVVJbnQzMkJFXG4gIGFyci53cml0ZUludDggPSBCUC53cml0ZUludDhcbiAgYXJyLndyaXRlSW50MTZMRSA9IEJQLndyaXRlSW50MTZMRVxuICBhcnIud3JpdGVJbnQxNkJFID0gQlAud3JpdGVJbnQxNkJFXG4gIGFyci53cml0ZUludDMyTEUgPSBCUC53cml0ZUludDMyTEVcbiAgYXJyLndyaXRlSW50MzJCRSA9IEJQLndyaXRlSW50MzJCRVxuICBhcnIud3JpdGVGbG9hdExFID0gQlAud3JpdGVGbG9hdExFXG4gIGFyci53cml0ZUZsb2F0QkUgPSBCUC53cml0ZUZsb2F0QkVcbiAgYXJyLndyaXRlRG91YmxlTEUgPSBCUC53cml0ZURvdWJsZUxFXG4gIGFyci53cml0ZURvdWJsZUJFID0gQlAud3JpdGVEb3VibGVCRVxuICBhcnIuZmlsbCA9IEJQLmZpbGxcbiAgYXJyLmluc3BlY3QgPSBCUC5pbnNwZWN0XG4gIGFyci50b0FycmF5QnVmZmVyID0gQlAudG9BcnJheUJ1ZmZlclxuXG4gIHJldHVybiBhcnJcbn1cblxudmFyIElOVkFMSURfQkFTRTY0X1JFID0gL1teK1xcLzAtOUEtel0vZ1xuXG5mdW5jdGlvbiBiYXNlNjRjbGVhbiAoc3RyKSB7XG4gIC8vIE5vZGUgc3RyaXBzIG91dCBpbnZhbGlkIGNoYXJhY3RlcnMgbGlrZSBcXG4gYW5kIFxcdCBmcm9tIHRoZSBzdHJpbmcsIGJhc2U2NC1qcyBkb2VzIG5vdFxuICBzdHIgPSBzdHJpbmd0cmltKHN0cikucmVwbGFjZShJTlZBTElEX0JBU0U2NF9SRSwgJycpXG4gIC8vIE5vZGUgYWxsb3dzIGZvciBub24tcGFkZGVkIGJhc2U2NCBzdHJpbmdzIChtaXNzaW5nIHRyYWlsaW5nID09PSksIGJhc2U2NC1qcyBkb2VzIG5vdFxuICB3aGlsZSAoc3RyLmxlbmd0aCAlIDQgIT09IDApIHtcbiAgICBzdHIgPSBzdHIgKyAnPSdcbiAgfVxuICByZXR1cm4gc3RyXG59XG5cbmZ1bmN0aW9uIHN0cmluZ3RyaW0gKHN0cikge1xuICBpZiAoc3RyLnRyaW0pIHJldHVybiBzdHIudHJpbSgpXG4gIHJldHVybiBzdHIucmVwbGFjZSgvXlxccyt8XFxzKyQvZywgJycpXG59XG5cbmZ1bmN0aW9uIGlzQXJyYXlpc2ggKHN1YmplY3QpIHtcbiAgcmV0dXJuIGlzQXJyYXkoc3ViamVjdCkgfHwgQnVmZmVyLmlzQnVmZmVyKHN1YmplY3QpIHx8XG4gICAgICBzdWJqZWN0ICYmIHR5cGVvZiBzdWJqZWN0ID09PSAnb2JqZWN0JyAmJlxuICAgICAgdHlwZW9mIHN1YmplY3QubGVuZ3RoID09PSAnbnVtYmVyJ1xufVxuXG5mdW5jdGlvbiB0b0hleCAobikge1xuICBpZiAobiA8IDE2KSByZXR1cm4gJzAnICsgbi50b1N0cmluZygxNilcbiAgcmV0dXJuIG4udG9TdHJpbmcoMTYpXG59XG5cbmZ1bmN0aW9uIHV0ZjhUb0J5dGVzIChzdHIpIHtcbiAgdmFyIGJ5dGVBcnJheSA9IFtdXG4gIGZvciAodmFyIGkgPSAwOyBpIDwgc3RyLmxlbmd0aDsgaSsrKSB7XG4gICAgdmFyIGIgPSBzdHIuY2hhckNvZGVBdChpKVxuICAgIGlmIChiIDw9IDB4N0YpIHtcbiAgICAgIGJ5dGVBcnJheS5wdXNoKGIpXG4gICAgfSBlbHNlIHtcbiAgICAgIHZhciBzdGFydCA9IGlcbiAgICAgIGlmIChiID49IDB4RDgwMCAmJiBiIDw9IDB4REZGRikgaSsrXG4gICAgICB2YXIgaCA9IGVuY29kZVVSSUNvbXBvbmVudChzdHIuc2xpY2Uoc3RhcnQsIGkrMSkpLnN1YnN0cigxKS5zcGxpdCgnJScpXG4gICAgICBmb3IgKHZhciBqID0gMDsgaiA8IGgubGVuZ3RoOyBqKyspIHtcbiAgICAgICAgYnl0ZUFycmF5LnB1c2gocGFyc2VJbnQoaFtqXSwgMTYpKVxuICAgICAgfVxuICAgIH1cbiAgfVxuICByZXR1cm4gYnl0ZUFycmF5XG59XG5cbmZ1bmN0aW9uIGFzY2lpVG9CeXRlcyAoc3RyKSB7XG4gIHZhciBieXRlQXJyYXkgPSBbXVxuICBmb3IgKHZhciBpID0gMDsgaSA8IHN0ci5sZW5ndGg7IGkrKykge1xuICAgIC8vIE5vZGUncyBjb2RlIHNlZW1zIHRvIGJlIGRvaW5nIHRoaXMgYW5kIG5vdCAmIDB4N0YuLlxuICAgIGJ5dGVBcnJheS5wdXNoKHN0ci5jaGFyQ29kZUF0KGkpICYgMHhGRilcbiAgfVxuICByZXR1cm4gYnl0ZUFycmF5XG59XG5cbmZ1bmN0aW9uIHV0ZjE2bGVUb0J5dGVzIChzdHIpIHtcbiAgdmFyIGMsIGhpLCBsb1xuICB2YXIgYnl0ZUFycmF5ID0gW11cbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBzdHIubGVuZ3RoOyBpKyspIHtcbiAgICBjID0gc3RyLmNoYXJDb2RlQXQoaSlcbiAgICBoaSA9IGMgPj4gOFxuICAgIGxvID0gYyAlIDI1NlxuICAgIGJ5dGVBcnJheS5wdXNoKGxvKVxuICAgIGJ5dGVBcnJheS5wdXNoKGhpKVxuICB9XG5cbiAgcmV0dXJuIGJ5dGVBcnJheVxufVxuXG5mdW5jdGlvbiBiYXNlNjRUb0J5dGVzIChzdHIpIHtcbiAgcmV0dXJuIGJhc2U2NC50b0J5dGVBcnJheShzdHIpXG59XG5cbmZ1bmN0aW9uIGJsaXRCdWZmZXIgKHNyYywgZHN0LCBvZmZzZXQsIGxlbmd0aCwgdW5pdFNpemUpIHtcbiAgaWYgKHVuaXRTaXplKSBsZW5ndGggLT0gbGVuZ3RoICUgdW5pdFNpemU7XG4gIGZvciAodmFyIGkgPSAwOyBpIDwgbGVuZ3RoOyBpKyspIHtcbiAgICBpZiAoKGkgKyBvZmZzZXQgPj0gZHN0Lmxlbmd0aCkgfHwgKGkgPj0gc3JjLmxlbmd0aCkpXG4gICAgICBicmVha1xuICAgIGRzdFtpICsgb2Zmc2V0XSA9IHNyY1tpXVxuICB9XG4gIHJldHVybiBpXG59XG5cbmZ1bmN0aW9uIGRlY29kZVV0ZjhDaGFyIChzdHIpIHtcbiAgdHJ5IHtcbiAgICByZXR1cm4gZGVjb2RlVVJJQ29tcG9uZW50KHN0cilcbiAgfSBjYXRjaCAoZXJyKSB7XG4gICAgcmV0dXJuIFN0cmluZy5mcm9tQ2hhckNvZGUoMHhGRkZEKSAvLyBVVEYgOCBpbnZhbGlkIGNoYXJcbiAgfVxufVxuIiwidmFyIGxvb2t1cCA9ICdBQkNERUZHSElKS0xNTk9QUVJTVFVWV1hZWmFiY2RlZmdoaWprbG1ub3BxcnN0dXZ3eHl6MDEyMzQ1Njc4OSsvJztcblxuOyhmdW5jdGlvbiAoZXhwb3J0cykge1xuXHQndXNlIHN0cmljdCc7XG5cbiAgdmFyIEFyciA9ICh0eXBlb2YgVWludDhBcnJheSAhPT0gJ3VuZGVmaW5lZCcpXG4gICAgPyBVaW50OEFycmF5XG4gICAgOiBBcnJheVxuXG5cdHZhciBQTFVTICAgPSAnKycuY2hhckNvZGVBdCgwKVxuXHR2YXIgU0xBU0ggID0gJy8nLmNoYXJDb2RlQXQoMClcblx0dmFyIE5VTUJFUiA9ICcwJy5jaGFyQ29kZUF0KDApXG5cdHZhciBMT1dFUiAgPSAnYScuY2hhckNvZGVBdCgwKVxuXHR2YXIgVVBQRVIgID0gJ0EnLmNoYXJDb2RlQXQoMClcblxuXHRmdW5jdGlvbiBkZWNvZGUgKGVsdCkge1xuXHRcdHZhciBjb2RlID0gZWx0LmNoYXJDb2RlQXQoMClcblx0XHRpZiAoY29kZSA9PT0gUExVUylcblx0XHRcdHJldHVybiA2MiAvLyAnKydcblx0XHRpZiAoY29kZSA9PT0gU0xBU0gpXG5cdFx0XHRyZXR1cm4gNjMgLy8gJy8nXG5cdFx0aWYgKGNvZGUgPCBOVU1CRVIpXG5cdFx0XHRyZXR1cm4gLTEgLy9ubyBtYXRjaFxuXHRcdGlmIChjb2RlIDwgTlVNQkVSICsgMTApXG5cdFx0XHRyZXR1cm4gY29kZSAtIE5VTUJFUiArIDI2ICsgMjZcblx0XHRpZiAoY29kZSA8IFVQUEVSICsgMjYpXG5cdFx0XHRyZXR1cm4gY29kZSAtIFVQUEVSXG5cdFx0aWYgKGNvZGUgPCBMT1dFUiArIDI2KVxuXHRcdFx0cmV0dXJuIGNvZGUgLSBMT1dFUiArIDI2XG5cdH1cblxuXHRmdW5jdGlvbiBiNjRUb0J5dGVBcnJheSAoYjY0KSB7XG5cdFx0dmFyIGksIGosIGwsIHRtcCwgcGxhY2VIb2xkZXJzLCBhcnJcblxuXHRcdGlmIChiNjQubGVuZ3RoICUgNCA+IDApIHtcblx0XHRcdHRocm93IG5ldyBFcnJvcignSW52YWxpZCBzdHJpbmcuIExlbmd0aCBtdXN0IGJlIGEgbXVsdGlwbGUgb2YgNCcpXG5cdFx0fVxuXG5cdFx0Ly8gdGhlIG51bWJlciBvZiBlcXVhbCBzaWducyAocGxhY2UgaG9sZGVycylcblx0XHQvLyBpZiB0aGVyZSBhcmUgdHdvIHBsYWNlaG9sZGVycywgdGhhbiB0aGUgdHdvIGNoYXJhY3RlcnMgYmVmb3JlIGl0XG5cdFx0Ly8gcmVwcmVzZW50IG9uZSBieXRlXG5cdFx0Ly8gaWYgdGhlcmUgaXMgb25seSBvbmUsIHRoZW4gdGhlIHRocmVlIGNoYXJhY3RlcnMgYmVmb3JlIGl0IHJlcHJlc2VudCAyIGJ5dGVzXG5cdFx0Ly8gdGhpcyBpcyBqdXN0IGEgY2hlYXAgaGFjayB0byBub3QgZG8gaW5kZXhPZiB0d2ljZVxuXHRcdHZhciBsZW4gPSBiNjQubGVuZ3RoXG5cdFx0cGxhY2VIb2xkZXJzID0gJz0nID09PSBiNjQuY2hhckF0KGxlbiAtIDIpID8gMiA6ICc9JyA9PT0gYjY0LmNoYXJBdChsZW4gLSAxKSA/IDEgOiAwXG5cblx0XHQvLyBiYXNlNjQgaXMgNC8zICsgdXAgdG8gdHdvIGNoYXJhY3RlcnMgb2YgdGhlIG9yaWdpbmFsIGRhdGFcblx0XHRhcnIgPSBuZXcgQXJyKGI2NC5sZW5ndGggKiAzIC8gNCAtIHBsYWNlSG9sZGVycylcblxuXHRcdC8vIGlmIHRoZXJlIGFyZSBwbGFjZWhvbGRlcnMsIG9ubHkgZ2V0IHVwIHRvIHRoZSBsYXN0IGNvbXBsZXRlIDQgY2hhcnNcblx0XHRsID0gcGxhY2VIb2xkZXJzID4gMCA/IGI2NC5sZW5ndGggLSA0IDogYjY0Lmxlbmd0aFxuXG5cdFx0dmFyIEwgPSAwXG5cblx0XHRmdW5jdGlvbiBwdXNoICh2KSB7XG5cdFx0XHRhcnJbTCsrXSA9IHZcblx0XHR9XG5cblx0XHRmb3IgKGkgPSAwLCBqID0gMDsgaSA8IGw7IGkgKz0gNCwgaiArPSAzKSB7XG5cdFx0XHR0bXAgPSAoZGVjb2RlKGI2NC5jaGFyQXQoaSkpIDw8IDE4KSB8IChkZWNvZGUoYjY0LmNoYXJBdChpICsgMSkpIDw8IDEyKSB8IChkZWNvZGUoYjY0LmNoYXJBdChpICsgMikpIDw8IDYpIHwgZGVjb2RlKGI2NC5jaGFyQXQoaSArIDMpKVxuXHRcdFx0cHVzaCgodG1wICYgMHhGRjAwMDApID4+IDE2KVxuXHRcdFx0cHVzaCgodG1wICYgMHhGRjAwKSA+PiA4KVxuXHRcdFx0cHVzaCh0bXAgJiAweEZGKVxuXHRcdH1cblxuXHRcdGlmIChwbGFjZUhvbGRlcnMgPT09IDIpIHtcblx0XHRcdHRtcCA9IChkZWNvZGUoYjY0LmNoYXJBdChpKSkgPDwgMikgfCAoZGVjb2RlKGI2NC5jaGFyQXQoaSArIDEpKSA+PiA0KVxuXHRcdFx0cHVzaCh0bXAgJiAweEZGKVxuXHRcdH0gZWxzZSBpZiAocGxhY2VIb2xkZXJzID09PSAxKSB7XG5cdFx0XHR0bXAgPSAoZGVjb2RlKGI2NC5jaGFyQXQoaSkpIDw8IDEwKSB8IChkZWNvZGUoYjY0LmNoYXJBdChpICsgMSkpIDw8IDQpIHwgKGRlY29kZShiNjQuY2hhckF0KGkgKyAyKSkgPj4gMilcblx0XHRcdHB1c2goKHRtcCA+PiA4KSAmIDB4RkYpXG5cdFx0XHRwdXNoKHRtcCAmIDB4RkYpXG5cdFx0fVxuXG5cdFx0cmV0dXJuIGFyclxuXHR9XG5cblx0ZnVuY3Rpb24gdWludDhUb0Jhc2U2NCAodWludDgpIHtcblx0XHR2YXIgaSxcblx0XHRcdGV4dHJhQnl0ZXMgPSB1aW50OC5sZW5ndGggJSAzLCAvLyBpZiB3ZSBoYXZlIDEgYnl0ZSBsZWZ0LCBwYWQgMiBieXRlc1xuXHRcdFx0b3V0cHV0ID0gXCJcIixcblx0XHRcdHRlbXAsIGxlbmd0aFxuXG5cdFx0ZnVuY3Rpb24gZW5jb2RlIChudW0pIHtcblx0XHRcdHJldHVybiBsb29rdXAuY2hhckF0KG51bSlcblx0XHR9XG5cblx0XHRmdW5jdGlvbiB0cmlwbGV0VG9CYXNlNjQgKG51bSkge1xuXHRcdFx0cmV0dXJuIGVuY29kZShudW0gPj4gMTggJiAweDNGKSArIGVuY29kZShudW0gPj4gMTIgJiAweDNGKSArIGVuY29kZShudW0gPj4gNiAmIDB4M0YpICsgZW5jb2RlKG51bSAmIDB4M0YpXG5cdFx0fVxuXG5cdFx0Ly8gZ28gdGhyb3VnaCB0aGUgYXJyYXkgZXZlcnkgdGhyZWUgYnl0ZXMsIHdlJ2xsIGRlYWwgd2l0aCB0cmFpbGluZyBzdHVmZiBsYXRlclxuXHRcdGZvciAoaSA9IDAsIGxlbmd0aCA9IHVpbnQ4Lmxlbmd0aCAtIGV4dHJhQnl0ZXM7IGkgPCBsZW5ndGg7IGkgKz0gMykge1xuXHRcdFx0dGVtcCA9ICh1aW50OFtpXSA8PCAxNikgKyAodWludDhbaSArIDFdIDw8IDgpICsgKHVpbnQ4W2kgKyAyXSlcblx0XHRcdG91dHB1dCArPSB0cmlwbGV0VG9CYXNlNjQodGVtcClcblx0XHR9XG5cblx0XHQvLyBwYWQgdGhlIGVuZCB3aXRoIHplcm9zLCBidXQgbWFrZSBzdXJlIHRvIG5vdCBmb3JnZXQgdGhlIGV4dHJhIGJ5dGVzXG5cdFx0c3dpdGNoIChleHRyYUJ5dGVzKSB7XG5cdFx0XHRjYXNlIDE6XG5cdFx0XHRcdHRlbXAgPSB1aW50OFt1aW50OC5sZW5ndGggLSAxXVxuXHRcdFx0XHRvdXRwdXQgKz0gZW5jb2RlKHRlbXAgPj4gMilcblx0XHRcdFx0b3V0cHV0ICs9IGVuY29kZSgodGVtcCA8PCA0KSAmIDB4M0YpXG5cdFx0XHRcdG91dHB1dCArPSAnPT0nXG5cdFx0XHRcdGJyZWFrXG5cdFx0XHRjYXNlIDI6XG5cdFx0XHRcdHRlbXAgPSAodWludDhbdWludDgubGVuZ3RoIC0gMl0gPDwgOCkgKyAodWludDhbdWludDgubGVuZ3RoIC0gMV0pXG5cdFx0XHRcdG91dHB1dCArPSBlbmNvZGUodGVtcCA+PiAxMClcblx0XHRcdFx0b3V0cHV0ICs9IGVuY29kZSgodGVtcCA+PiA0KSAmIDB4M0YpXG5cdFx0XHRcdG91dHB1dCArPSBlbmNvZGUoKHRlbXAgPDwgMikgJiAweDNGKVxuXHRcdFx0XHRvdXRwdXQgKz0gJz0nXG5cdFx0XHRcdGJyZWFrXG5cdFx0fVxuXG5cdFx0cmV0dXJuIG91dHB1dFxuXHR9XG5cblx0ZXhwb3J0cy50b0J5dGVBcnJheSA9IGI2NFRvQnl0ZUFycmF5XG5cdGV4cG9ydHMuZnJvbUJ5dGVBcnJheSA9IHVpbnQ4VG9CYXNlNjRcbn0odHlwZW9mIGV4cG9ydHMgPT09ICd1bmRlZmluZWQnID8gKHRoaXMuYmFzZTY0anMgPSB7fSkgOiBleHBvcnRzKSlcbiIsImV4cG9ydHMucmVhZCA9IGZ1bmN0aW9uIChidWZmZXIsIG9mZnNldCwgaXNMRSwgbUxlbiwgbkJ5dGVzKSB7XG4gIHZhciBlLCBtXG4gIHZhciBlTGVuID0gbkJ5dGVzICogOCAtIG1MZW4gLSAxXG4gIHZhciBlTWF4ID0gKDEgPDwgZUxlbikgLSAxXG4gIHZhciBlQmlhcyA9IGVNYXggPj4gMVxuICB2YXIgbkJpdHMgPSAtN1xuICB2YXIgaSA9IGlzTEUgPyAobkJ5dGVzIC0gMSkgOiAwXG4gIHZhciBkID0gaXNMRSA/IC0xIDogMVxuICB2YXIgcyA9IGJ1ZmZlcltvZmZzZXQgKyBpXVxuXG4gIGkgKz0gZFxuXG4gIGUgPSBzICYgKCgxIDw8ICgtbkJpdHMpKSAtIDEpXG4gIHMgPj49ICgtbkJpdHMpXG4gIG5CaXRzICs9IGVMZW5cbiAgZm9yICg7IG5CaXRzID4gMDsgZSA9IGUgKiAyNTYgKyBidWZmZXJbb2Zmc2V0ICsgaV0sIGkgKz0gZCwgbkJpdHMgLT0gOCkge31cblxuICBtID0gZSAmICgoMSA8PCAoLW5CaXRzKSkgLSAxKVxuICBlID4+PSAoLW5CaXRzKVxuICBuQml0cyArPSBtTGVuXG4gIGZvciAoOyBuQml0cyA+IDA7IG0gPSBtICogMjU2ICsgYnVmZmVyW29mZnNldCArIGldLCBpICs9IGQsIG5CaXRzIC09IDgpIHt9XG5cbiAgaWYgKGUgPT09IDApIHtcbiAgICBlID0gMSAtIGVCaWFzXG4gIH0gZWxzZSBpZiAoZSA9PT0gZU1heCkge1xuICAgIHJldHVybiBtID8gTmFOIDogKChzID8gLTEgOiAxKSAqIEluZmluaXR5KVxuICB9IGVsc2Uge1xuICAgIG0gPSBtICsgTWF0aC5wb3coMiwgbUxlbilcbiAgICBlID0gZSAtIGVCaWFzXG4gIH1cbiAgcmV0dXJuIChzID8gLTEgOiAxKSAqIG0gKiBNYXRoLnBvdygyLCBlIC0gbUxlbilcbn1cblxuZXhwb3J0cy53cml0ZSA9IGZ1bmN0aW9uIChidWZmZXIsIHZhbHVlLCBvZmZzZXQsIGlzTEUsIG1MZW4sIG5CeXRlcykge1xuICB2YXIgZSwgbSwgY1xuICB2YXIgZUxlbiA9IG5CeXRlcyAqIDggLSBtTGVuIC0gMVxuICB2YXIgZU1heCA9ICgxIDw8IGVMZW4pIC0gMVxuICB2YXIgZUJpYXMgPSBlTWF4ID4+IDFcbiAgdmFyIHJ0ID0gKG1MZW4gPT09IDIzID8gTWF0aC5wb3coMiwgLTI0KSAtIE1hdGgucG93KDIsIC03NykgOiAwKVxuICB2YXIgaSA9IGlzTEUgPyAwIDogKG5CeXRlcyAtIDEpXG4gIHZhciBkID0gaXNMRSA/IDEgOiAtMVxuICB2YXIgcyA9IHZhbHVlIDwgMCB8fCAodmFsdWUgPT09IDAgJiYgMSAvIHZhbHVlIDwgMCkgPyAxIDogMFxuXG4gIHZhbHVlID0gTWF0aC5hYnModmFsdWUpXG5cbiAgaWYgKGlzTmFOKHZhbHVlKSB8fCB2YWx1ZSA9PT0gSW5maW5pdHkpIHtcbiAgICBtID0gaXNOYU4odmFsdWUpID8gMSA6IDBcbiAgICBlID0gZU1heFxuICB9IGVsc2Uge1xuICAgIGUgPSBNYXRoLmZsb29yKE1hdGgubG9nKHZhbHVlKSAvIE1hdGguTE4yKVxuICAgIGlmICh2YWx1ZSAqIChjID0gTWF0aC5wb3coMiwgLWUpKSA8IDEpIHtcbiAgICAgIGUtLVxuICAgICAgYyAqPSAyXG4gICAgfVxuICAgIGlmIChlICsgZUJpYXMgPj0gMSkge1xuICAgICAgdmFsdWUgKz0gcnQgLyBjXG4gICAgfSBlbHNlIHtcbiAgICAgIHZhbHVlICs9IHJ0ICogTWF0aC5wb3coMiwgMSAtIGVCaWFzKVxuICAgIH1cbiAgICBpZiAodmFsdWUgKiBjID49IDIpIHtcbiAgICAgIGUrK1xuICAgICAgYyAvPSAyXG4gICAgfVxuXG4gICAgaWYgKGUgKyBlQmlhcyA+PSBlTWF4KSB7XG4gICAgICBtID0gMFxuICAgICAgZSA9IGVNYXhcbiAgICB9IGVsc2UgaWYgKGUgKyBlQmlhcyA+PSAxKSB7XG4gICAgICBtID0gKHZhbHVlICogYyAtIDEpICogTWF0aC5wb3coMiwgbUxlbilcbiAgICAgIGUgPSBlICsgZUJpYXNcbiAgICB9IGVsc2Uge1xuICAgICAgbSA9IHZhbHVlICogTWF0aC5wb3coMiwgZUJpYXMgLSAxKSAqIE1hdGgucG93KDIsIG1MZW4pXG4gICAgICBlID0gMFxuICAgIH1cbiAgfVxuXG4gIGZvciAoOyBtTGVuID49IDg7IGJ1ZmZlcltvZmZzZXQgKyBpXSA9IG0gJiAweGZmLCBpICs9IGQsIG0gLz0gMjU2LCBtTGVuIC09IDgpIHt9XG5cbiAgZSA9IChlIDw8IG1MZW4pIHwgbVxuICBlTGVuICs9IG1MZW5cbiAgZm9yICg7IGVMZW4gPiAwOyBidWZmZXJbb2Zmc2V0ICsgaV0gPSBlICYgMHhmZiwgaSArPSBkLCBlIC89IDI1NiwgZUxlbiAtPSA4KSB7fVxuXG4gIGJ1ZmZlcltvZmZzZXQgKyBpIC0gZF0gfD0gcyAqIDEyOFxufVxuIiwiXG4vKipcbiAqIGlzQXJyYXlcbiAqL1xuXG52YXIgaXNBcnJheSA9IEFycmF5LmlzQXJyYXk7XG5cbi8qKlxuICogdG9TdHJpbmdcbiAqL1xuXG52YXIgc3RyID0gT2JqZWN0LnByb3RvdHlwZS50b1N0cmluZztcblxuLyoqXG4gKiBXaGV0aGVyIG9yIG5vdCB0aGUgZ2l2ZW4gYHZhbGBcbiAqIGlzIGFuIGFycmF5LlxuICpcbiAqIGV4YW1wbGU6XG4gKlxuICogICAgICAgIGlzQXJyYXkoW10pO1xuICogICAgICAgIC8vID4gdHJ1ZVxuICogICAgICAgIGlzQXJyYXkoYXJndW1lbnRzKTtcbiAqICAgICAgICAvLyA+IGZhbHNlXG4gKiAgICAgICAgaXNBcnJheSgnJyk7XG4gKiAgICAgICAgLy8gPiBmYWxzZVxuICpcbiAqIEBwYXJhbSB7bWl4ZWR9IHZhbFxuICogQHJldHVybiB7Ym9vbH1cbiAqL1xuXG5tb2R1bGUuZXhwb3J0cyA9IGlzQXJyYXkgfHwgZnVuY3Rpb24gKHZhbCkge1xuICByZXR1cm4gISEgdmFsICYmICdbb2JqZWN0IEFycmF5XScgPT0gc3RyLmNhbGwodmFsKTtcbn07XG4iLCIvLyBDb3B5cmlnaHQgSm95ZW50LCBJbmMuIGFuZCBvdGhlciBOb2RlIGNvbnRyaWJ1dG9ycy5cbi8vXG4vLyBQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcgYVxuLy8gY29weSBvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZVxuLy8gXCJTb2Z0d2FyZVwiKSwgdG8gZGVhbCBpbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nXG4vLyB3aXRob3V0IGxpbWl0YXRpb24gdGhlIHJpZ2h0cyB0byB1c2UsIGNvcHksIG1vZGlmeSwgbWVyZ2UsIHB1Ymxpc2gsXG4vLyBkaXN0cmlidXRlLCBzdWJsaWNlbnNlLCBhbmQvb3Igc2VsbCBjb3BpZXMgb2YgdGhlIFNvZnR3YXJlLCBhbmQgdG8gcGVybWl0XG4vLyBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzIGZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGVcbi8vIGZvbGxvd2luZyBjb25kaXRpb25zOlxuLy9cbi8vIFRoZSBhYm92ZSBjb3B5cmlnaHQgbm90aWNlIGFuZCB0aGlzIHBlcm1pc3Npb24gbm90aWNlIHNoYWxsIGJlIGluY2x1ZGVkXG4vLyBpbiBhbGwgY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS5cbi8vXG4vLyBUSEUgU09GVFdBUkUgSVMgUFJPVklERUQgXCJBUyBJU1wiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTXG4vLyBPUiBJTVBMSUVELCBJTkNMVURJTkcgQlVUIE5PVCBMSU1JVEVEIFRPIFRIRSBXQVJSQU5USUVTIE9GXG4vLyBNRVJDSEFOVEFCSUxJVFksIEZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFORCBOT05JTkZSSU5HRU1FTlQuIElOXG4vLyBOTyBFVkVOVCBTSEFMTCBUSEUgQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSxcbi8vIERBTUFHRVMgT1IgT1RIRVIgTElBQklMSVRZLCBXSEVUSEVSIElOIEFOIEFDVElPTiBPRiBDT05UUkFDVCwgVE9SVCBPUlxuLy8gT1RIRVJXSVNFLCBBUklTSU5HIEZST00sIE9VVCBPRiBPUiBJTiBDT05ORUNUSU9OIFdJVEggVEhFIFNPRlRXQVJFIE9SIFRIRVxuLy8gVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRSBTT0ZUV0FSRS5cblxuZnVuY3Rpb24gRXZlbnRFbWl0dGVyKCkge1xuICB0aGlzLl9ldmVudHMgPSB0aGlzLl9ldmVudHMgfHwge307XG4gIHRoaXMuX21heExpc3RlbmVycyA9IHRoaXMuX21heExpc3RlbmVycyB8fCB1bmRlZmluZWQ7XG59XG5tb2R1bGUuZXhwb3J0cyA9IEV2ZW50RW1pdHRlcjtcblxuLy8gQmFja3dhcmRzLWNvbXBhdCB3aXRoIG5vZGUgMC4xMC54XG5FdmVudEVtaXR0ZXIuRXZlbnRFbWl0dGVyID0gRXZlbnRFbWl0dGVyO1xuXG5FdmVudEVtaXR0ZXIucHJvdG90eXBlLl9ldmVudHMgPSB1bmRlZmluZWQ7XG5FdmVudEVtaXR0ZXIucHJvdG90eXBlLl9tYXhMaXN0ZW5lcnMgPSB1bmRlZmluZWQ7XG5cbi8vIEJ5IGRlZmF1bHQgRXZlbnRFbWl0dGVycyB3aWxsIHByaW50IGEgd2FybmluZyBpZiBtb3JlIHRoYW4gMTAgbGlzdGVuZXJzIGFyZVxuLy8gYWRkZWQgdG8gaXQuIFRoaXMgaXMgYSB1c2VmdWwgZGVmYXVsdCB3aGljaCBoZWxwcyBmaW5kaW5nIG1lbW9yeSBsZWFrcy5cbkV2ZW50RW1pdHRlci5kZWZhdWx0TWF4TGlzdGVuZXJzID0gMTA7XG5cbi8vIE9idmlvdXNseSBub3QgYWxsIEVtaXR0ZXJzIHNob3VsZCBiZSBsaW1pdGVkIHRvIDEwLiBUaGlzIGZ1bmN0aW9uIGFsbG93c1xuLy8gdGhhdCB0byBiZSBpbmNyZWFzZWQuIFNldCB0byB6ZXJvIGZvciB1bmxpbWl0ZWQuXG5FdmVudEVtaXR0ZXIucHJvdG90eXBlLnNldE1heExpc3RlbmVycyA9IGZ1bmN0aW9uKG4pIHtcbiAgaWYgKCFpc051bWJlcihuKSB8fCBuIDwgMCB8fCBpc05hTihuKSlcbiAgICB0aHJvdyBUeXBlRXJyb3IoJ24gbXVzdCBiZSBhIHBvc2l0aXZlIG51bWJlcicpO1xuICB0aGlzLl9tYXhMaXN0ZW5lcnMgPSBuO1xuICByZXR1cm4gdGhpcztcbn07XG5cbkV2ZW50RW1pdHRlci5wcm90b3R5cGUuZW1pdCA9IGZ1bmN0aW9uKHR5cGUpIHtcbiAgdmFyIGVyLCBoYW5kbGVyLCBsZW4sIGFyZ3MsIGksIGxpc3RlbmVycztcblxuICBpZiAoIXRoaXMuX2V2ZW50cylcbiAgICB0aGlzLl9ldmVudHMgPSB7fTtcblxuICAvLyBJZiB0aGVyZSBpcyBubyAnZXJyb3InIGV2ZW50IGxpc3RlbmVyIHRoZW4gdGhyb3cuXG4gIGlmICh0eXBlID09PSAnZXJyb3InKSB7XG4gICAgaWYgKCF0aGlzLl9ldmVudHMuZXJyb3IgfHxcbiAgICAgICAgKGlzT2JqZWN0KHRoaXMuX2V2ZW50cy5lcnJvcikgJiYgIXRoaXMuX2V2ZW50cy5lcnJvci5sZW5ndGgpKSB7XG4gICAgICBlciA9IGFyZ3VtZW50c1sxXTtcbiAgICAgIGlmIChlciBpbnN0YW5jZW9mIEVycm9yKSB7XG4gICAgICAgIHRocm93IGVyOyAvLyBVbmhhbmRsZWQgJ2Vycm9yJyBldmVudFxuICAgICAgfVxuICAgICAgdGhyb3cgVHlwZUVycm9yKCdVbmNhdWdodCwgdW5zcGVjaWZpZWQgXCJlcnJvclwiIGV2ZW50LicpO1xuICAgIH1cbiAgfVxuXG4gIGhhbmRsZXIgPSB0aGlzLl9ldmVudHNbdHlwZV07XG5cbiAgaWYgKGlzVW5kZWZpbmVkKGhhbmRsZXIpKVxuICAgIHJldHVybiBmYWxzZTtcblxuICBpZiAoaXNGdW5jdGlvbihoYW5kbGVyKSkge1xuICAgIHN3aXRjaCAoYXJndW1lbnRzLmxlbmd0aCkge1xuICAgICAgLy8gZmFzdCBjYXNlc1xuICAgICAgY2FzZSAxOlxuICAgICAgICBoYW5kbGVyLmNhbGwodGhpcyk7XG4gICAgICAgIGJyZWFrO1xuICAgICAgY2FzZSAyOlxuICAgICAgICBoYW5kbGVyLmNhbGwodGhpcywgYXJndW1lbnRzWzFdKTtcbiAgICAgICAgYnJlYWs7XG4gICAgICBjYXNlIDM6XG4gICAgICAgIGhhbmRsZXIuY2FsbCh0aGlzLCBhcmd1bWVudHNbMV0sIGFyZ3VtZW50c1syXSk7XG4gICAgICAgIGJyZWFrO1xuICAgICAgLy8gc2xvd2VyXG4gICAgICBkZWZhdWx0OlxuICAgICAgICBsZW4gPSBhcmd1bWVudHMubGVuZ3RoO1xuICAgICAgICBhcmdzID0gbmV3IEFycmF5KGxlbiAtIDEpO1xuICAgICAgICBmb3IgKGkgPSAxOyBpIDwgbGVuOyBpKyspXG4gICAgICAgICAgYXJnc1tpIC0gMV0gPSBhcmd1bWVudHNbaV07XG4gICAgICAgIGhhbmRsZXIuYXBwbHkodGhpcywgYXJncyk7XG4gICAgfVxuICB9IGVsc2UgaWYgKGlzT2JqZWN0KGhhbmRsZXIpKSB7XG4gICAgbGVuID0gYXJndW1lbnRzLmxlbmd0aDtcbiAgICBhcmdzID0gbmV3IEFycmF5KGxlbiAtIDEpO1xuICAgIGZvciAoaSA9IDE7IGkgPCBsZW47IGkrKylcbiAgICAgIGFyZ3NbaSAtIDFdID0gYXJndW1lbnRzW2ldO1xuXG4gICAgbGlzdGVuZXJzID0gaGFuZGxlci5zbGljZSgpO1xuICAgIGxlbiA9IGxpc3RlbmVycy5sZW5ndGg7XG4gICAgZm9yIChpID0gMDsgaSA8IGxlbjsgaSsrKVxuICAgICAgbGlzdGVuZXJzW2ldLmFwcGx5KHRoaXMsIGFyZ3MpO1xuICB9XG5cbiAgcmV0dXJuIHRydWU7XG59O1xuXG5FdmVudEVtaXR0ZXIucHJvdG90eXBlLmFkZExpc3RlbmVyID0gZnVuY3Rpb24odHlwZSwgbGlzdGVuZXIpIHtcbiAgdmFyIG07XG5cbiAgaWYgKCFpc0Z1bmN0aW9uKGxpc3RlbmVyKSlcbiAgICB0aHJvdyBUeXBlRXJyb3IoJ2xpc3RlbmVyIG11c3QgYmUgYSBmdW5jdGlvbicpO1xuXG4gIGlmICghdGhpcy5fZXZlbnRzKVxuICAgIHRoaXMuX2V2ZW50cyA9IHt9O1xuXG4gIC8vIFRvIGF2b2lkIHJlY3Vyc2lvbiBpbiB0aGUgY2FzZSB0aGF0IHR5cGUgPT09IFwibmV3TGlzdGVuZXJcIiEgQmVmb3JlXG4gIC8vIGFkZGluZyBpdCB0byB0aGUgbGlzdGVuZXJzLCBmaXJzdCBlbWl0IFwibmV3TGlzdGVuZXJcIi5cbiAgaWYgKHRoaXMuX2V2ZW50cy5uZXdMaXN0ZW5lcilcbiAgICB0aGlzLmVtaXQoJ25ld0xpc3RlbmVyJywgdHlwZSxcbiAgICAgICAgICAgICAgaXNGdW5jdGlvbihsaXN0ZW5lci5saXN0ZW5lcikgP1xuICAgICAgICAgICAgICBsaXN0ZW5lci5saXN0ZW5lciA6IGxpc3RlbmVyKTtcblxuICBpZiAoIXRoaXMuX2V2ZW50c1t0eXBlXSlcbiAgICAvLyBPcHRpbWl6ZSB0aGUgY2FzZSBvZiBvbmUgbGlzdGVuZXIuIERvbid0IG5lZWQgdGhlIGV4dHJhIGFycmF5IG9iamVjdC5cbiAgICB0aGlzLl9ldmVudHNbdHlwZV0gPSBsaXN0ZW5lcjtcbiAgZWxzZSBpZiAoaXNPYmplY3QodGhpcy5fZXZlbnRzW3R5cGVdKSlcbiAgICAvLyBJZiB3ZSd2ZSBhbHJlYWR5IGdvdCBhbiBhcnJheSwganVzdCBhcHBlbmQuXG4gICAgdGhpcy5fZXZlbnRzW3R5cGVdLnB1c2gobGlzdGVuZXIpO1xuICBlbHNlXG4gICAgLy8gQWRkaW5nIHRoZSBzZWNvbmQgZWxlbWVudCwgbmVlZCB0byBjaGFuZ2UgdG8gYXJyYXkuXG4gICAgdGhpcy5fZXZlbnRzW3R5cGVdID0gW3RoaXMuX2V2ZW50c1t0eXBlXSwgbGlzdGVuZXJdO1xuXG4gIC8vIENoZWNrIGZvciBsaXN0ZW5lciBsZWFrXG4gIGlmIChpc09iamVjdCh0aGlzLl9ldmVudHNbdHlwZV0pICYmICF0aGlzLl9ldmVudHNbdHlwZV0ud2FybmVkKSB7XG4gICAgdmFyIG07XG4gICAgaWYgKCFpc1VuZGVmaW5lZCh0aGlzLl9tYXhMaXN0ZW5lcnMpKSB7XG4gICAgICBtID0gdGhpcy5fbWF4TGlzdGVuZXJzO1xuICAgIH0gZWxzZSB7XG4gICAgICBtID0gRXZlbnRFbWl0dGVyLmRlZmF1bHRNYXhMaXN0ZW5lcnM7XG4gICAgfVxuXG4gICAgaWYgKG0gJiYgbSA+IDAgJiYgdGhpcy5fZXZlbnRzW3R5cGVdLmxlbmd0aCA+IG0pIHtcbiAgICAgIHRoaXMuX2V2ZW50c1t0eXBlXS53YXJuZWQgPSB0cnVlO1xuICAgICAgY29uc29sZS5lcnJvcignKG5vZGUpIHdhcm5pbmc6IHBvc3NpYmxlIEV2ZW50RW1pdHRlciBtZW1vcnkgJyArXG4gICAgICAgICAgICAgICAgICAgICdsZWFrIGRldGVjdGVkLiAlZCBsaXN0ZW5lcnMgYWRkZWQuICcgK1xuICAgICAgICAgICAgICAgICAgICAnVXNlIGVtaXR0ZXIuc2V0TWF4TGlzdGVuZXJzKCkgdG8gaW5jcmVhc2UgbGltaXQuJyxcbiAgICAgICAgICAgICAgICAgICAgdGhpcy5fZXZlbnRzW3R5cGVdLmxlbmd0aCk7XG4gICAgICBpZiAodHlwZW9mIGNvbnNvbGUudHJhY2UgPT09ICdmdW5jdGlvbicpIHtcbiAgICAgICAgLy8gbm90IHN1cHBvcnRlZCBpbiBJRSAxMFxuICAgICAgICBjb25zb2xlLnRyYWNlKCk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgcmV0dXJuIHRoaXM7XG59O1xuXG5FdmVudEVtaXR0ZXIucHJvdG90eXBlLm9uID0gRXZlbnRFbWl0dGVyLnByb3RvdHlwZS5hZGRMaXN0ZW5lcjtcblxuRXZlbnRFbWl0dGVyLnByb3RvdHlwZS5vbmNlID0gZnVuY3Rpb24odHlwZSwgbGlzdGVuZXIpIHtcbiAgaWYgKCFpc0Z1bmN0aW9uKGxpc3RlbmVyKSlcbiAgICB0aHJvdyBUeXBlRXJyb3IoJ2xpc3RlbmVyIG11c3QgYmUgYSBmdW5jdGlvbicpO1xuXG4gIHZhciBmaXJlZCA9IGZhbHNlO1xuXG4gIGZ1bmN0aW9uIGcoKSB7XG4gICAgdGhpcy5yZW1vdmVMaXN0ZW5lcih0eXBlLCBnKTtcblxuICAgIGlmICghZmlyZWQpIHtcbiAgICAgIGZpcmVkID0gdHJ1ZTtcbiAgICAgIGxpc3RlbmVyLmFwcGx5KHRoaXMsIGFyZ3VtZW50cyk7XG4gICAgfVxuICB9XG5cbiAgZy5saXN0ZW5lciA9IGxpc3RlbmVyO1xuICB0aGlzLm9uKHR5cGUsIGcpO1xuXG4gIHJldHVybiB0aGlzO1xufTtcblxuLy8gZW1pdHMgYSAncmVtb3ZlTGlzdGVuZXInIGV2ZW50IGlmZiB0aGUgbGlzdGVuZXIgd2FzIHJlbW92ZWRcbkV2ZW50RW1pdHRlci5wcm90b3R5cGUucmVtb3ZlTGlzdGVuZXIgPSBmdW5jdGlvbih0eXBlLCBsaXN0ZW5lcikge1xuICB2YXIgbGlzdCwgcG9zaXRpb24sIGxlbmd0aCwgaTtcblxuICBpZiAoIWlzRnVuY3Rpb24obGlzdGVuZXIpKVxuICAgIHRocm93IFR5cGVFcnJvcignbGlzdGVuZXIgbXVzdCBiZSBhIGZ1bmN0aW9uJyk7XG5cbiAgaWYgKCF0aGlzLl9ldmVudHMgfHwgIXRoaXMuX2V2ZW50c1t0eXBlXSlcbiAgICByZXR1cm4gdGhpcztcblxuICBsaXN0ID0gdGhpcy5fZXZlbnRzW3R5cGVdO1xuICBsZW5ndGggPSBsaXN0Lmxlbmd0aDtcbiAgcG9zaXRpb24gPSAtMTtcblxuICBpZiAobGlzdCA9PT0gbGlzdGVuZXIgfHxcbiAgICAgIChpc0Z1bmN0aW9uKGxpc3QubGlzdGVuZXIpICYmIGxpc3QubGlzdGVuZXIgPT09IGxpc3RlbmVyKSkge1xuICAgIGRlbGV0ZSB0aGlzLl9ldmVudHNbdHlwZV07XG4gICAgaWYgKHRoaXMuX2V2ZW50cy5yZW1vdmVMaXN0ZW5lcilcbiAgICAgIHRoaXMuZW1pdCgncmVtb3ZlTGlzdGVuZXInLCB0eXBlLCBsaXN0ZW5lcik7XG5cbiAgfSBlbHNlIGlmIChpc09iamVjdChsaXN0KSkge1xuICAgIGZvciAoaSA9IGxlbmd0aDsgaS0tID4gMDspIHtcbiAgICAgIGlmIChsaXN0W2ldID09PSBsaXN0ZW5lciB8fFxuICAgICAgICAgIChsaXN0W2ldLmxpc3RlbmVyICYmIGxpc3RbaV0ubGlzdGVuZXIgPT09IGxpc3RlbmVyKSkge1xuICAgICAgICBwb3NpdGlvbiA9IGk7XG4gICAgICAgIGJyZWFrO1xuICAgICAgfVxuICAgIH1cblxuICAgIGlmIChwb3NpdGlvbiA8IDApXG4gICAgICByZXR1cm4gdGhpcztcblxuICAgIGlmIChsaXN0Lmxlbmd0aCA9PT0gMSkge1xuICAgICAgbGlzdC5sZW5ndGggPSAwO1xuICAgICAgZGVsZXRlIHRoaXMuX2V2ZW50c1t0eXBlXTtcbiAgICB9IGVsc2Uge1xuICAgICAgbGlzdC5zcGxpY2UocG9zaXRpb24sIDEpO1xuICAgIH1cblxuICAgIGlmICh0aGlzLl9ldmVudHMucmVtb3ZlTGlzdGVuZXIpXG4gICAgICB0aGlzLmVtaXQoJ3JlbW92ZUxpc3RlbmVyJywgdHlwZSwgbGlzdGVuZXIpO1xuICB9XG5cbiAgcmV0dXJuIHRoaXM7XG59O1xuXG5FdmVudEVtaXR0ZXIucHJvdG90eXBlLnJlbW92ZUFsbExpc3RlbmVycyA9IGZ1bmN0aW9uKHR5cGUpIHtcbiAgdmFyIGtleSwgbGlzdGVuZXJzO1xuXG4gIGlmICghdGhpcy5fZXZlbnRzKVxuICAgIHJldHVybiB0aGlzO1xuXG4gIC8vIG5vdCBsaXN0ZW5pbmcgZm9yIHJlbW92ZUxpc3RlbmVyLCBubyBuZWVkIHRvIGVtaXRcbiAgaWYgKCF0aGlzLl9ldmVudHMucmVtb3ZlTGlzdGVuZXIpIHtcbiAgICBpZiAoYXJndW1lbnRzLmxlbmd0aCA9PT0gMClcbiAgICAgIHRoaXMuX2V2ZW50cyA9IHt9O1xuICAgIGVsc2UgaWYgKHRoaXMuX2V2ZW50c1t0eXBlXSlcbiAgICAgIGRlbGV0ZSB0aGlzLl9ldmVudHNbdHlwZV07XG4gICAgcmV0dXJuIHRoaXM7XG4gIH1cblxuICAvLyBlbWl0IHJlbW92ZUxpc3RlbmVyIGZvciBhbGwgbGlzdGVuZXJzIG9uIGFsbCBldmVudHNcbiAgaWYgKGFyZ3VtZW50cy5sZW5ndGggPT09IDApIHtcbiAgICBmb3IgKGtleSBpbiB0aGlzLl9ldmVudHMpIHtcbiAgICAgIGlmIChrZXkgPT09ICdyZW1vdmVMaXN0ZW5lcicpIGNvbnRpbnVlO1xuICAgICAgdGhpcy5yZW1vdmVBbGxMaXN0ZW5lcnMoa2V5KTtcbiAgICB9XG4gICAgdGhpcy5yZW1vdmVBbGxMaXN0ZW5lcnMoJ3JlbW92ZUxpc3RlbmVyJyk7XG4gICAgdGhpcy5fZXZlbnRzID0ge307XG4gICAgcmV0dXJuIHRoaXM7XG4gIH1cblxuICBsaXN0ZW5lcnMgPSB0aGlzLl9ldmVudHNbdHlwZV07XG5cbiAgaWYgKGlzRnVuY3Rpb24obGlzdGVuZXJzKSkge1xuICAgIHRoaXMucmVtb3ZlTGlzdGVuZXIodHlwZSwgbGlzdGVuZXJzKTtcbiAgfSBlbHNlIHtcbiAgICAvLyBMSUZPIG9yZGVyXG4gICAgd2hpbGUgKGxpc3RlbmVycy5sZW5ndGgpXG4gICAgICB0aGlzLnJlbW92ZUxpc3RlbmVyKHR5cGUsIGxpc3RlbmVyc1tsaXN0ZW5lcnMubGVuZ3RoIC0gMV0pO1xuICB9XG4gIGRlbGV0ZSB0aGlzLl9ldmVudHNbdHlwZV07XG5cbiAgcmV0dXJuIHRoaXM7XG59O1xuXG5FdmVudEVtaXR0ZXIucHJvdG90eXBlLmxpc3RlbmVycyA9IGZ1bmN0aW9uKHR5cGUpIHtcbiAgdmFyIHJldDtcbiAgaWYgKCF0aGlzLl9ldmVudHMgfHwgIXRoaXMuX2V2ZW50c1t0eXBlXSlcbiAgICByZXQgPSBbXTtcbiAgZWxzZSBpZiAoaXNGdW5jdGlvbih0aGlzLl9ldmVudHNbdHlwZV0pKVxuICAgIHJldCA9IFt0aGlzLl9ldmVudHNbdHlwZV1dO1xuICBlbHNlXG4gICAgcmV0ID0gdGhpcy5fZXZlbnRzW3R5cGVdLnNsaWNlKCk7XG4gIHJldHVybiByZXQ7XG59O1xuXG5FdmVudEVtaXR0ZXIubGlzdGVuZXJDb3VudCA9IGZ1bmN0aW9uKGVtaXR0ZXIsIHR5cGUpIHtcbiAgdmFyIHJldDtcbiAgaWYgKCFlbWl0dGVyLl9ldmVudHMgfHwgIWVtaXR0ZXIuX2V2ZW50c1t0eXBlXSlcbiAgICByZXQgPSAwO1xuICBlbHNlIGlmIChpc0Z1bmN0aW9uKGVtaXR0ZXIuX2V2ZW50c1t0eXBlXSkpXG4gICAgcmV0ID0gMTtcbiAgZWxzZVxuICAgIHJldCA9IGVtaXR0ZXIuX2V2ZW50c1t0eXBlXS5sZW5ndGg7XG4gIHJldHVybiByZXQ7XG59O1xuXG5mdW5jdGlvbiBpc0Z1bmN0aW9uKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ2Z1bmN0aW9uJztcbn1cblxuZnVuY3Rpb24gaXNOdW1iZXIoYXJnKSB7XG4gIHJldHVybiB0eXBlb2YgYXJnID09PSAnbnVtYmVyJztcbn1cblxuZnVuY3Rpb24gaXNPYmplY3QoYXJnKSB7XG4gIHJldHVybiB0eXBlb2YgYXJnID09PSAnb2JqZWN0JyAmJiBhcmcgIT09IG51bGw7XG59XG5cbmZ1bmN0aW9uIGlzVW5kZWZpbmVkKGFyZykge1xuICByZXR1cm4gYXJnID09PSB2b2lkIDA7XG59XG4iLCJ2YXIgaHR0cCA9IG1vZHVsZS5leHBvcnRzO1xudmFyIEV2ZW50RW1pdHRlciA9IHJlcXVpcmUoJ2V2ZW50cycpLkV2ZW50RW1pdHRlcjtcbnZhciBSZXF1ZXN0ID0gcmVxdWlyZSgnLi9saWIvcmVxdWVzdCcpO1xudmFyIHVybCA9IHJlcXVpcmUoJ3VybCcpXG5cbmh0dHAucmVxdWVzdCA9IGZ1bmN0aW9uIChwYXJhbXMsIGNiKSB7XG4gICAgaWYgKHR5cGVvZiBwYXJhbXMgPT09ICdzdHJpbmcnKSB7XG4gICAgICAgIHBhcmFtcyA9IHVybC5wYXJzZShwYXJhbXMpXG4gICAgfVxuICAgIGlmICghcGFyYW1zKSBwYXJhbXMgPSB7fTtcbiAgICBpZiAoIXBhcmFtcy5ob3N0ICYmICFwYXJhbXMucG9ydCkge1xuICAgICAgICBwYXJhbXMucG9ydCA9IHBhcnNlSW50KHdpbmRvdy5sb2NhdGlvbi5wb3J0LCAxMCk7XG4gICAgfVxuICAgIGlmICghcGFyYW1zLmhvc3QgJiYgcGFyYW1zLmhvc3RuYW1lKSB7XG4gICAgICAgIHBhcmFtcy5ob3N0ID0gcGFyYW1zLmhvc3RuYW1lO1xuICAgIH1cblxuICAgIGlmICghcGFyYW1zLnByb3RvY29sKSB7XG4gICAgICAgIGlmIChwYXJhbXMuc2NoZW1lKSB7XG4gICAgICAgICAgICBwYXJhbXMucHJvdG9jb2wgPSBwYXJhbXMuc2NoZW1lICsgJzonO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgcGFyYW1zLnByb3RvY29sID0gd2luZG93LmxvY2F0aW9uLnByb3RvY29sO1xuICAgICAgICB9XG4gICAgfVxuXG4gICAgaWYgKCFwYXJhbXMuaG9zdCkge1xuICAgICAgICBwYXJhbXMuaG9zdCA9IHdpbmRvdy5sb2NhdGlvbi5ob3N0bmFtZSB8fCB3aW5kb3cubG9jYXRpb24uaG9zdDtcbiAgICB9XG4gICAgaWYgKC86Ly50ZXN0KHBhcmFtcy5ob3N0KSkge1xuICAgICAgICBpZiAoIXBhcmFtcy5wb3J0KSB7XG4gICAgICAgICAgICBwYXJhbXMucG9ydCA9IHBhcmFtcy5ob3N0LnNwbGl0KCc6JylbMV07XG4gICAgICAgIH1cbiAgICAgICAgcGFyYW1zLmhvc3QgPSBwYXJhbXMuaG9zdC5zcGxpdCgnOicpWzBdO1xuICAgIH1cbiAgICBpZiAoIXBhcmFtcy5wb3J0KSBwYXJhbXMucG9ydCA9IHBhcmFtcy5wcm90b2NvbCA9PSAnaHR0cHM6JyA/IDQ0MyA6IDgwO1xuICAgIFxuICAgIHZhciByZXEgPSBuZXcgUmVxdWVzdChuZXcgeGhySHR0cCwgcGFyYW1zKTtcbiAgICBpZiAoY2IpIHJlcS5vbigncmVzcG9uc2UnLCBjYik7XG4gICAgcmV0dXJuIHJlcTtcbn07XG5cbmh0dHAuZ2V0ID0gZnVuY3Rpb24gKHBhcmFtcywgY2IpIHtcbiAgICBwYXJhbXMubWV0aG9kID0gJ0dFVCc7XG4gICAgdmFyIHJlcSA9IGh0dHAucmVxdWVzdChwYXJhbXMsIGNiKTtcbiAgICByZXEuZW5kKCk7XG4gICAgcmV0dXJuIHJlcTtcbn07XG5cbmh0dHAuQWdlbnQgPSBmdW5jdGlvbiAoKSB7fTtcbmh0dHAuQWdlbnQuZGVmYXVsdE1heFNvY2tldHMgPSA0O1xuXG52YXIgeGhySHR0cCA9IChmdW5jdGlvbiAoKSB7XG4gICAgaWYgKHR5cGVvZiB3aW5kb3cgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcignbm8gd2luZG93IG9iamVjdCBwcmVzZW50Jyk7XG4gICAgfVxuICAgIGVsc2UgaWYgKHdpbmRvdy5YTUxIdHRwUmVxdWVzdCkge1xuICAgICAgICByZXR1cm4gd2luZG93LlhNTEh0dHBSZXF1ZXN0O1xuICAgIH1cbiAgICBlbHNlIGlmICh3aW5kb3cuQWN0aXZlWE9iamVjdCkge1xuICAgICAgICB2YXIgYXhzID0gW1xuICAgICAgICAgICAgJ01zeG1sMi5YTUxIVFRQLjYuMCcsXG4gICAgICAgICAgICAnTXN4bWwyLlhNTEhUVFAuMy4wJyxcbiAgICAgICAgICAgICdNaWNyb3NvZnQuWE1MSFRUUCdcbiAgICAgICAgXTtcbiAgICAgICAgZm9yICh2YXIgaSA9IDA7IGkgPCBheHMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgIHRyeSB7XG4gICAgICAgICAgICAgICAgdmFyIGF4ID0gbmV3KHdpbmRvdy5BY3RpdmVYT2JqZWN0KShheHNbaV0pO1xuICAgICAgICAgICAgICAgIHJldHVybiBmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICAgICAgICAgIGlmIChheCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgdmFyIGF4XyA9IGF4O1xuICAgICAgICAgICAgICAgICAgICAgICAgYXggPSBudWxsO1xuICAgICAgICAgICAgICAgICAgICAgICAgcmV0dXJuIGF4XztcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIHJldHVybiBuZXcod2luZG93LkFjdGl2ZVhPYmplY3QpKGF4c1tpXSk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9O1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgY2F0Y2ggKGUpIHt9XG4gICAgICAgIH1cbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKCdhamF4IG5vdCBzdXBwb3J0ZWQgaW4gdGhpcyBicm93c2VyJylcbiAgICB9XG4gICAgZWxzZSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcignYWpheCBub3Qgc3VwcG9ydGVkIGluIHRoaXMgYnJvd3NlcicpO1xuICAgIH1cbn0pKCk7XG5cbmh0dHAuU1RBVFVTX0NPREVTID0ge1xuICAgIDEwMCA6ICdDb250aW51ZScsXG4gICAgMTAxIDogJ1N3aXRjaGluZyBQcm90b2NvbHMnLFxuICAgIDEwMiA6ICdQcm9jZXNzaW5nJywgICAgICAgICAgICAgICAgIC8vIFJGQyAyNTE4LCBvYnNvbGV0ZWQgYnkgUkZDIDQ5MThcbiAgICAyMDAgOiAnT0snLFxuICAgIDIwMSA6ICdDcmVhdGVkJyxcbiAgICAyMDIgOiAnQWNjZXB0ZWQnLFxuICAgIDIwMyA6ICdOb24tQXV0aG9yaXRhdGl2ZSBJbmZvcm1hdGlvbicsXG4gICAgMjA0IDogJ05vIENvbnRlbnQnLFxuICAgIDIwNSA6ICdSZXNldCBDb250ZW50JyxcbiAgICAyMDYgOiAnUGFydGlhbCBDb250ZW50JyxcbiAgICAyMDcgOiAnTXVsdGktU3RhdHVzJywgICAgICAgICAgICAgICAvLyBSRkMgNDkxOFxuICAgIDMwMCA6ICdNdWx0aXBsZSBDaG9pY2VzJyxcbiAgICAzMDEgOiAnTW92ZWQgUGVybWFuZW50bHknLFxuICAgIDMwMiA6ICdNb3ZlZCBUZW1wb3JhcmlseScsXG4gICAgMzAzIDogJ1NlZSBPdGhlcicsXG4gICAgMzA0IDogJ05vdCBNb2RpZmllZCcsXG4gICAgMzA1IDogJ1VzZSBQcm94eScsXG4gICAgMzA3IDogJ1RlbXBvcmFyeSBSZWRpcmVjdCcsXG4gICAgNDAwIDogJ0JhZCBSZXF1ZXN0JyxcbiAgICA0MDEgOiAnVW5hdXRob3JpemVkJyxcbiAgICA0MDIgOiAnUGF5bWVudCBSZXF1aXJlZCcsXG4gICAgNDAzIDogJ0ZvcmJpZGRlbicsXG4gICAgNDA0IDogJ05vdCBGb3VuZCcsXG4gICAgNDA1IDogJ01ldGhvZCBOb3QgQWxsb3dlZCcsXG4gICAgNDA2IDogJ05vdCBBY2NlcHRhYmxlJyxcbiAgICA0MDcgOiAnUHJveHkgQXV0aGVudGljYXRpb24gUmVxdWlyZWQnLFxuICAgIDQwOCA6ICdSZXF1ZXN0IFRpbWUtb3V0JyxcbiAgICA0MDkgOiAnQ29uZmxpY3QnLFxuICAgIDQxMCA6ICdHb25lJyxcbiAgICA0MTEgOiAnTGVuZ3RoIFJlcXVpcmVkJyxcbiAgICA0MTIgOiAnUHJlY29uZGl0aW9uIEZhaWxlZCcsXG4gICAgNDEzIDogJ1JlcXVlc3QgRW50aXR5IFRvbyBMYXJnZScsXG4gICAgNDE0IDogJ1JlcXVlc3QtVVJJIFRvbyBMYXJnZScsXG4gICAgNDE1IDogJ1Vuc3VwcG9ydGVkIE1lZGlhIFR5cGUnLFxuICAgIDQxNiA6ICdSZXF1ZXN0ZWQgUmFuZ2UgTm90IFNhdGlzZmlhYmxlJyxcbiAgICA0MTcgOiAnRXhwZWN0YXRpb24gRmFpbGVkJyxcbiAgICA0MTggOiAnSVxcJ20gYSB0ZWFwb3QnLCAgICAgICAgICAgICAgLy8gUkZDIDIzMjRcbiAgICA0MjIgOiAnVW5wcm9jZXNzYWJsZSBFbnRpdHknLCAgICAgICAvLyBSRkMgNDkxOFxuICAgIDQyMyA6ICdMb2NrZWQnLCAgICAgICAgICAgICAgICAgICAgIC8vIFJGQyA0OTE4XG4gICAgNDI0IDogJ0ZhaWxlZCBEZXBlbmRlbmN5JywgICAgICAgICAgLy8gUkZDIDQ5MThcbiAgICA0MjUgOiAnVW5vcmRlcmVkIENvbGxlY3Rpb24nLCAgICAgICAvLyBSRkMgNDkxOFxuICAgIDQyNiA6ICdVcGdyYWRlIFJlcXVpcmVkJywgICAgICAgICAgIC8vIFJGQyAyODE3XG4gICAgNDI4IDogJ1ByZWNvbmRpdGlvbiBSZXF1aXJlZCcsICAgICAgLy8gUkZDIDY1ODVcbiAgICA0MjkgOiAnVG9vIE1hbnkgUmVxdWVzdHMnLCAgICAgICAgICAvLyBSRkMgNjU4NVxuICAgIDQzMSA6ICdSZXF1ZXN0IEhlYWRlciBGaWVsZHMgVG9vIExhcmdlJywvLyBSRkMgNjU4NVxuICAgIDUwMCA6ICdJbnRlcm5hbCBTZXJ2ZXIgRXJyb3InLFxuICAgIDUwMSA6ICdOb3QgSW1wbGVtZW50ZWQnLFxuICAgIDUwMiA6ICdCYWQgR2F0ZXdheScsXG4gICAgNTAzIDogJ1NlcnZpY2UgVW5hdmFpbGFibGUnLFxuICAgIDUwNCA6ICdHYXRld2F5IFRpbWUtb3V0JyxcbiAgICA1MDUgOiAnSFRUUCBWZXJzaW9uIE5vdCBTdXBwb3J0ZWQnLFxuICAgIDUwNiA6ICdWYXJpYW50IEFsc28gTmVnb3RpYXRlcycsICAgIC8vIFJGQyAyMjk1XG4gICAgNTA3IDogJ0luc3VmZmljaWVudCBTdG9yYWdlJywgICAgICAgLy8gUkZDIDQ5MThcbiAgICA1MDkgOiAnQmFuZHdpZHRoIExpbWl0IEV4Y2VlZGVkJyxcbiAgICA1MTAgOiAnTm90IEV4dGVuZGVkJywgICAgICAgICAgICAgICAvLyBSRkMgMjc3NFxuICAgIDUxMSA6ICdOZXR3b3JrIEF1dGhlbnRpY2F0aW9uIFJlcXVpcmVkJyAvLyBSRkMgNjU4NVxufTsiLCJ2YXIgU3RyZWFtID0gcmVxdWlyZSgnc3RyZWFtJyk7XG52YXIgUmVzcG9uc2UgPSByZXF1aXJlKCcuL3Jlc3BvbnNlJyk7XG52YXIgQmFzZTY0ID0gcmVxdWlyZSgnQmFzZTY0Jyk7XG52YXIgaW5oZXJpdHMgPSByZXF1aXJlKCdpbmhlcml0cycpO1xuXG52YXIgUmVxdWVzdCA9IG1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gKHhociwgcGFyYW1zKSB7XG4gICAgdmFyIHNlbGYgPSB0aGlzO1xuICAgIHNlbGYud3JpdGFibGUgPSB0cnVlO1xuICAgIHNlbGYueGhyID0geGhyO1xuICAgIHNlbGYuYm9keSA9IFtdO1xuICAgIFxuICAgIHNlbGYudXJpID0gKHBhcmFtcy5wcm90b2NvbCB8fCAnaHR0cDonKSArICcvLydcbiAgICAgICAgKyBwYXJhbXMuaG9zdFxuICAgICAgICArIChwYXJhbXMucG9ydCA/ICc6JyArIHBhcmFtcy5wb3J0IDogJycpXG4gICAgICAgICsgKHBhcmFtcy5wYXRoIHx8ICcvJylcbiAgICA7XG4gICAgXG4gICAgaWYgKHR5cGVvZiBwYXJhbXMud2l0aENyZWRlbnRpYWxzID09PSAndW5kZWZpbmVkJykge1xuICAgICAgICBwYXJhbXMud2l0aENyZWRlbnRpYWxzID0gdHJ1ZTtcbiAgICB9XG5cbiAgICB0cnkgeyB4aHIud2l0aENyZWRlbnRpYWxzID0gcGFyYW1zLndpdGhDcmVkZW50aWFscyB9XG4gICAgY2F0Y2ggKGUpIHt9XG4gICAgXG4gICAgaWYgKHBhcmFtcy5yZXNwb25zZVR5cGUpIHRyeSB7IHhoci5yZXNwb25zZVR5cGUgPSBwYXJhbXMucmVzcG9uc2VUeXBlIH1cbiAgICBjYXRjaCAoZSkge31cbiAgICBcbiAgICB4aHIub3BlbihcbiAgICAgICAgcGFyYW1zLm1ldGhvZCB8fCAnR0VUJyxcbiAgICAgICAgc2VsZi51cmksXG4gICAgICAgIHRydWVcbiAgICApO1xuXG4gICAgeGhyLm9uZXJyb3IgPSBmdW5jdGlvbihldmVudCkge1xuICAgICAgICBzZWxmLmVtaXQoJ2Vycm9yJywgbmV3IEVycm9yKCdOZXR3b3JrIGVycm9yJykpO1xuICAgIH07XG5cbiAgICBzZWxmLl9oZWFkZXJzID0ge307XG4gICAgXG4gICAgaWYgKHBhcmFtcy5oZWFkZXJzKSB7XG4gICAgICAgIHZhciBrZXlzID0gb2JqZWN0S2V5cyhwYXJhbXMuaGVhZGVycyk7XG4gICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwga2V5cy5sZW5ndGg7IGkrKykge1xuICAgICAgICAgICAgdmFyIGtleSA9IGtleXNbaV07XG4gICAgICAgICAgICBpZiAoIXNlbGYuaXNTYWZlUmVxdWVzdEhlYWRlcihrZXkpKSBjb250aW51ZTtcbiAgICAgICAgICAgIHZhciB2YWx1ZSA9IHBhcmFtcy5oZWFkZXJzW2tleV07XG4gICAgICAgICAgICBzZWxmLnNldEhlYWRlcihrZXksIHZhbHVlKTtcbiAgICAgICAgfVxuICAgIH1cbiAgICBcbiAgICBpZiAocGFyYW1zLmF1dGgpIHtcbiAgICAgICAgLy9iYXNpYyBhdXRoXG4gICAgICAgIHRoaXMuc2V0SGVhZGVyKCdBdXRob3JpemF0aW9uJywgJ0Jhc2ljICcgKyBCYXNlNjQuYnRvYShwYXJhbXMuYXV0aCkpO1xuICAgIH1cblxuICAgIHZhciByZXMgPSBuZXcgUmVzcG9uc2U7XG4gICAgcmVzLm9uKCdjbG9zZScsIGZ1bmN0aW9uICgpIHtcbiAgICAgICAgc2VsZi5lbWl0KCdjbG9zZScpO1xuICAgIH0pO1xuICAgIFxuICAgIHJlcy5vbigncmVhZHknLCBmdW5jdGlvbiAoKSB7XG4gICAgICAgIHNlbGYuZW1pdCgncmVzcG9uc2UnLCByZXMpO1xuICAgIH0pO1xuXG4gICAgcmVzLm9uKCdlcnJvcicsIGZ1bmN0aW9uIChlcnIpIHtcbiAgICAgICAgc2VsZi5lbWl0KCdlcnJvcicsIGVycik7XG4gICAgfSk7XG4gICAgXG4gICAgeGhyLm9ucmVhZHlzdGF0ZWNoYW5nZSA9IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgLy8gRml4IGZvciBJRTkgYnVnXG4gICAgICAgIC8vIFNDUklQVDU3NTogQ291bGQgbm90IGNvbXBsZXRlIHRoZSBvcGVyYXRpb24gZHVlIHRvIGVycm9yIGMwMGMwMjNmXG4gICAgICAgIC8vIEl0IGhhcHBlbnMgd2hlbiBhIHJlcXVlc3QgaXMgYWJvcnRlZCwgY2FsbGluZyB0aGUgc3VjY2VzcyBjYWxsYmFjayBhbnl3YXkgd2l0aCByZWFkeVN0YXRlID09PSA0XG4gICAgICAgIGlmICh4aHIuX19hYm9ydGVkKSByZXR1cm47XG4gICAgICAgIHJlcy5oYW5kbGUoeGhyKTtcbiAgICB9O1xufTtcblxuaW5oZXJpdHMoUmVxdWVzdCwgU3RyZWFtKTtcblxuUmVxdWVzdC5wcm90b3R5cGUuc2V0SGVhZGVyID0gZnVuY3Rpb24gKGtleSwgdmFsdWUpIHtcbiAgICB0aGlzLl9oZWFkZXJzW2tleS50b0xvd2VyQ2FzZSgpXSA9IHZhbHVlXG59O1xuXG5SZXF1ZXN0LnByb3RvdHlwZS5nZXRIZWFkZXIgPSBmdW5jdGlvbiAoa2V5KSB7XG4gICAgcmV0dXJuIHRoaXMuX2hlYWRlcnNba2V5LnRvTG93ZXJDYXNlKCldXG59O1xuXG5SZXF1ZXN0LnByb3RvdHlwZS5yZW1vdmVIZWFkZXIgPSBmdW5jdGlvbiAoa2V5KSB7XG4gICAgZGVsZXRlIHRoaXMuX2hlYWRlcnNba2V5LnRvTG93ZXJDYXNlKCldXG59O1xuXG5SZXF1ZXN0LnByb3RvdHlwZS53cml0ZSA9IGZ1bmN0aW9uIChzKSB7XG4gICAgdGhpcy5ib2R5LnB1c2gocyk7XG59O1xuXG5SZXF1ZXN0LnByb3RvdHlwZS5kZXN0cm95ID0gZnVuY3Rpb24gKHMpIHtcbiAgICB0aGlzLnhoci5fX2Fib3J0ZWQgPSB0cnVlO1xuICAgIHRoaXMueGhyLmFib3J0KCk7XG4gICAgdGhpcy5lbWl0KCdjbG9zZScpO1xufTtcblxuUmVxdWVzdC5wcm90b3R5cGUuZW5kID0gZnVuY3Rpb24gKHMpIHtcbiAgICBpZiAocyAhPT0gdW5kZWZpbmVkKSB0aGlzLmJvZHkucHVzaChzKTtcblxuICAgIHZhciBrZXlzID0gb2JqZWN0S2V5cyh0aGlzLl9oZWFkZXJzKTtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGtleXMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgdmFyIGtleSA9IGtleXNbaV07XG4gICAgICAgIHZhciB2YWx1ZSA9IHRoaXMuX2hlYWRlcnNba2V5XTtcbiAgICAgICAgaWYgKGlzQXJyYXkodmFsdWUpKSB7XG4gICAgICAgICAgICBmb3IgKHZhciBqID0gMDsgaiA8IHZhbHVlLmxlbmd0aDsgaisrKSB7XG4gICAgICAgICAgICAgICAgdGhpcy54aHIuc2V0UmVxdWVzdEhlYWRlcihrZXksIHZhbHVlW2pdKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICBlbHNlIHRoaXMueGhyLnNldFJlcXVlc3RIZWFkZXIoa2V5LCB2YWx1ZSlcbiAgICB9XG5cbiAgICBpZiAodGhpcy5ib2R5Lmxlbmd0aCA9PT0gMCkge1xuICAgICAgICB0aGlzLnhoci5zZW5kKCcnKTtcbiAgICB9XG4gICAgZWxzZSBpZiAodHlwZW9mIHRoaXMuYm9keVswXSA9PT0gJ3N0cmluZycpIHtcbiAgICAgICAgdGhpcy54aHIuc2VuZCh0aGlzLmJvZHkuam9pbignJykpO1xuICAgIH1cbiAgICBlbHNlIGlmIChpc0FycmF5KHRoaXMuYm9keVswXSkpIHtcbiAgICAgICAgdmFyIGJvZHkgPSBbXTtcbiAgICAgICAgZm9yICh2YXIgaSA9IDA7IGkgPCB0aGlzLmJvZHkubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgICAgIGJvZHkucHVzaC5hcHBseShib2R5LCB0aGlzLmJvZHlbaV0pO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMueGhyLnNlbmQoYm9keSk7XG4gICAgfVxuICAgIGVsc2UgaWYgKC9BcnJheS8udGVzdChPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwodGhpcy5ib2R5WzBdKSkpIHtcbiAgICAgICAgdmFyIGxlbiA9IDA7XG4gICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgdGhpcy5ib2R5Lmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICBsZW4gKz0gdGhpcy5ib2R5W2ldLmxlbmd0aDtcbiAgICAgICAgfVxuICAgICAgICB2YXIgYm9keSA9IG5ldyh0aGlzLmJvZHlbMF0uY29uc3RydWN0b3IpKGxlbik7XG4gICAgICAgIHZhciBrID0gMDtcbiAgICAgICAgXG4gICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgdGhpcy5ib2R5Lmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICB2YXIgYiA9IHRoaXMuYm9keVtpXTtcbiAgICAgICAgICAgIGZvciAodmFyIGogPSAwOyBqIDwgYi5sZW5ndGg7IGorKykge1xuICAgICAgICAgICAgICAgIGJvZHlbaysrXSA9IGJbal07XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgdGhpcy54aHIuc2VuZChib2R5KTtcbiAgICB9XG4gICAgZWxzZSBpZiAoaXNYSFIyQ29tcGF0aWJsZSh0aGlzLmJvZHlbMF0pKSB7XG4gICAgICAgIHRoaXMueGhyLnNlbmQodGhpcy5ib2R5WzBdKTtcbiAgICB9XG4gICAgZWxzZSB7XG4gICAgICAgIHZhciBib2R5ID0gJyc7XG4gICAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgdGhpcy5ib2R5Lmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgICBib2R5ICs9IHRoaXMuYm9keVtpXS50b1N0cmluZygpO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMueGhyLnNlbmQoYm9keSk7XG4gICAgfVxufTtcblxuLy8gVGFrZW4gZnJvbSBodHRwOi8vZHhyLm1vemlsbGEub3JnL21vemlsbGEvbW96aWxsYS1jZW50cmFsL2NvbnRlbnQvYmFzZS9zcmMvbnNYTUxIdHRwUmVxdWVzdC5jcHAuaHRtbFxuUmVxdWVzdC51bnNhZmVIZWFkZXJzID0gW1xuICAgIFwiYWNjZXB0LWNoYXJzZXRcIixcbiAgICBcImFjY2VwdC1lbmNvZGluZ1wiLFxuICAgIFwiYWNjZXNzLWNvbnRyb2wtcmVxdWVzdC1oZWFkZXJzXCIsXG4gICAgXCJhY2Nlc3MtY29udHJvbC1yZXF1ZXN0LW1ldGhvZFwiLFxuICAgIFwiY29ubmVjdGlvblwiLFxuICAgIFwiY29udGVudC1sZW5ndGhcIixcbiAgICBcImNvb2tpZVwiLFxuICAgIFwiY29va2llMlwiLFxuICAgIFwiY29udGVudC10cmFuc2Zlci1lbmNvZGluZ1wiLFxuICAgIFwiZGF0ZVwiLFxuICAgIFwiZXhwZWN0XCIsXG4gICAgXCJob3N0XCIsXG4gICAgXCJrZWVwLWFsaXZlXCIsXG4gICAgXCJvcmlnaW5cIixcbiAgICBcInJlZmVyZXJcIixcbiAgICBcInRlXCIsXG4gICAgXCJ0cmFpbGVyXCIsXG4gICAgXCJ0cmFuc2Zlci1lbmNvZGluZ1wiLFxuICAgIFwidXBncmFkZVwiLFxuICAgIFwidXNlci1hZ2VudFwiLFxuICAgIFwidmlhXCJcbl07XG5cblJlcXVlc3QucHJvdG90eXBlLmlzU2FmZVJlcXVlc3RIZWFkZXIgPSBmdW5jdGlvbiAoaGVhZGVyTmFtZSkge1xuICAgIGlmICghaGVhZGVyTmFtZSkgcmV0dXJuIGZhbHNlO1xuICAgIHJldHVybiBpbmRleE9mKFJlcXVlc3QudW5zYWZlSGVhZGVycywgaGVhZGVyTmFtZS50b0xvd2VyQ2FzZSgpKSA9PT0gLTE7XG59O1xuXG52YXIgb2JqZWN0S2V5cyA9IE9iamVjdC5rZXlzIHx8IGZ1bmN0aW9uIChvYmopIHtcbiAgICB2YXIga2V5cyA9IFtdO1xuICAgIGZvciAodmFyIGtleSBpbiBvYmopIGtleXMucHVzaChrZXkpO1xuICAgIHJldHVybiBrZXlzO1xufTtcblxudmFyIGlzQXJyYXkgPSBBcnJheS5pc0FycmF5IHx8IGZ1bmN0aW9uICh4cykge1xuICAgIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwoeHMpID09PSAnW29iamVjdCBBcnJheV0nO1xufTtcblxudmFyIGluZGV4T2YgPSBmdW5jdGlvbiAoeHMsIHgpIHtcbiAgICBpZiAoeHMuaW5kZXhPZikgcmV0dXJuIHhzLmluZGV4T2YoeCk7XG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCB4cy5sZW5ndGg7IGkrKykge1xuICAgICAgICBpZiAoeHNbaV0gPT09IHgpIHJldHVybiBpO1xuICAgIH1cbiAgICByZXR1cm4gLTE7XG59O1xuXG52YXIgaXNYSFIyQ29tcGF0aWJsZSA9IGZ1bmN0aW9uIChvYmopIHtcbiAgICBpZiAodHlwZW9mIEJsb2IgIT09ICd1bmRlZmluZWQnICYmIG9iaiBpbnN0YW5jZW9mIEJsb2IpIHJldHVybiB0cnVlO1xuICAgIGlmICh0eXBlb2YgQXJyYXlCdWZmZXIgIT09ICd1bmRlZmluZWQnICYmIG9iaiBpbnN0YW5jZW9mIEFycmF5QnVmZmVyKSByZXR1cm4gdHJ1ZTtcbiAgICBpZiAodHlwZW9mIEZvcm1EYXRhICE9PSAndW5kZWZpbmVkJyAmJiBvYmogaW5zdGFuY2VvZiBGb3JtRGF0YSkgcmV0dXJuIHRydWU7XG59O1xuIiwidmFyIFN0cmVhbSA9IHJlcXVpcmUoJ3N0cmVhbScpO1xudmFyIHV0aWwgPSByZXF1aXJlKCd1dGlsJyk7XG5cbnZhciBSZXNwb25zZSA9IG1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gKHJlcykge1xuICAgIHRoaXMub2Zmc2V0ID0gMDtcbiAgICB0aGlzLnJlYWRhYmxlID0gdHJ1ZTtcbn07XG5cbnV0aWwuaW5oZXJpdHMoUmVzcG9uc2UsIFN0cmVhbSk7XG5cbnZhciBjYXBhYmxlID0ge1xuICAgIHN0cmVhbWluZyA6IHRydWUsXG4gICAgc3RhdHVzMiA6IHRydWVcbn07XG5cbmZ1bmN0aW9uIHBhcnNlSGVhZGVycyAocmVzKSB7XG4gICAgdmFyIGxpbmVzID0gcmVzLmdldEFsbFJlc3BvbnNlSGVhZGVycygpLnNwbGl0KC9cXHI/XFxuLyk7XG4gICAgdmFyIGhlYWRlcnMgPSB7fTtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGxpbmVzLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgIHZhciBsaW5lID0gbGluZXNbaV07XG4gICAgICAgIGlmIChsaW5lID09PSAnJykgY29udGludWU7XG4gICAgICAgIFxuICAgICAgICB2YXIgbSA9IGxpbmUubWF0Y2goL14oW146XSspOlxccyooLiopLyk7XG4gICAgICAgIGlmIChtKSB7XG4gICAgICAgICAgICB2YXIga2V5ID0gbVsxXS50b0xvd2VyQ2FzZSgpLCB2YWx1ZSA9IG1bMl07XG4gICAgICAgICAgICBcbiAgICAgICAgICAgIGlmIChoZWFkZXJzW2tleV0gIT09IHVuZGVmaW5lZCkge1xuICAgICAgICAgICAgXG4gICAgICAgICAgICAgICAgaWYgKGlzQXJyYXkoaGVhZGVyc1trZXldKSkge1xuICAgICAgICAgICAgICAgICAgICBoZWFkZXJzW2tleV0ucHVzaCh2YWx1ZSk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICBoZWFkZXJzW2tleV0gPSBbIGhlYWRlcnNba2V5XSwgdmFsdWUgXTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgICAgICBoZWFkZXJzW2tleV0gPSB2YWx1ZTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgICBlbHNlIHtcbiAgICAgICAgICAgIGhlYWRlcnNbbGluZV0gPSB0cnVlO1xuICAgICAgICB9XG4gICAgfVxuICAgIHJldHVybiBoZWFkZXJzO1xufVxuXG5SZXNwb25zZS5wcm90b3R5cGUuZ2V0UmVzcG9uc2UgPSBmdW5jdGlvbiAoeGhyKSB7XG4gICAgdmFyIHJlc3BUeXBlID0gU3RyaW5nKHhoci5yZXNwb25zZVR5cGUpLnRvTG93ZXJDYXNlKCk7XG4gICAgaWYgKHJlc3BUeXBlID09PSAnYmxvYicpIHJldHVybiB4aHIucmVzcG9uc2VCbG9iIHx8IHhoci5yZXNwb25zZTtcbiAgICBpZiAocmVzcFR5cGUgPT09ICdhcnJheWJ1ZmZlcicpIHJldHVybiB4aHIucmVzcG9uc2U7XG4gICAgcmV0dXJuIHhoci5yZXNwb25zZVRleHQ7XG59XG5cblJlc3BvbnNlLnByb3RvdHlwZS5nZXRIZWFkZXIgPSBmdW5jdGlvbiAoa2V5KSB7XG4gICAgcmV0dXJuIHRoaXMuaGVhZGVyc1trZXkudG9Mb3dlckNhc2UoKV07XG59O1xuXG5SZXNwb25zZS5wcm90b3R5cGUuaGFuZGxlID0gZnVuY3Rpb24gKHJlcykge1xuICAgIGlmIChyZXMucmVhZHlTdGF0ZSA9PT0gMiAmJiBjYXBhYmxlLnN0YXR1czIpIHtcbiAgICAgICAgdHJ5IHtcbiAgICAgICAgICAgIHRoaXMuc3RhdHVzQ29kZSA9IHJlcy5zdGF0dXM7XG4gICAgICAgICAgICB0aGlzLmhlYWRlcnMgPSBwYXJzZUhlYWRlcnMocmVzKTtcbiAgICAgICAgfVxuICAgICAgICBjYXRjaCAoZXJyKSB7XG4gICAgICAgICAgICBjYXBhYmxlLnN0YXR1czIgPSBmYWxzZTtcbiAgICAgICAgfVxuICAgICAgICBcbiAgICAgICAgaWYgKGNhcGFibGUuc3RhdHVzMikge1xuICAgICAgICAgICAgdGhpcy5lbWl0KCdyZWFkeScpO1xuICAgICAgICB9XG4gICAgfVxuICAgIGVsc2UgaWYgKGNhcGFibGUuc3RyZWFtaW5nICYmIHJlcy5yZWFkeVN0YXRlID09PSAzKSB7XG4gICAgICAgIHRyeSB7XG4gICAgICAgICAgICBpZiAoIXRoaXMuc3RhdHVzQ29kZSkge1xuICAgICAgICAgICAgICAgIHRoaXMuc3RhdHVzQ29kZSA9IHJlcy5zdGF0dXM7XG4gICAgICAgICAgICAgICAgdGhpcy5oZWFkZXJzID0gcGFyc2VIZWFkZXJzKHJlcyk7XG4gICAgICAgICAgICAgICAgdGhpcy5lbWl0KCdyZWFkeScpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIGNhdGNoIChlcnIpIHt9XG4gICAgICAgIFxuICAgICAgICB0cnkge1xuICAgICAgICAgICAgdGhpcy5fZW1pdERhdGEocmVzKTtcbiAgICAgICAgfVxuICAgICAgICBjYXRjaCAoZXJyKSB7XG4gICAgICAgICAgICBjYXBhYmxlLnN0cmVhbWluZyA9IGZhbHNlO1xuICAgICAgICB9XG4gICAgfVxuICAgIGVsc2UgaWYgKHJlcy5yZWFkeVN0YXRlID09PSA0KSB7XG4gICAgICAgIGlmICghdGhpcy5zdGF0dXNDb2RlKSB7XG4gICAgICAgICAgICB0aGlzLnN0YXR1c0NvZGUgPSByZXMuc3RhdHVzO1xuICAgICAgICAgICAgdGhpcy5lbWl0KCdyZWFkeScpO1xuICAgICAgICB9XG4gICAgICAgIHRoaXMuX2VtaXREYXRhKHJlcyk7XG4gICAgICAgIFxuICAgICAgICBpZiAocmVzLmVycm9yKSB7XG4gICAgICAgICAgICB0aGlzLmVtaXQoJ2Vycm9yJywgdGhpcy5nZXRSZXNwb25zZShyZXMpKTtcbiAgICAgICAgfVxuICAgICAgICBlbHNlIHRoaXMuZW1pdCgnZW5kJyk7XG4gICAgICAgIFxuICAgICAgICB0aGlzLmVtaXQoJ2Nsb3NlJyk7XG4gICAgfVxufTtcblxuUmVzcG9uc2UucHJvdG90eXBlLl9lbWl0RGF0YSA9IGZ1bmN0aW9uIChyZXMpIHtcbiAgICB2YXIgcmVzcEJvZHkgPSB0aGlzLmdldFJlc3BvbnNlKHJlcyk7XG4gICAgaWYgKHJlc3BCb2R5LnRvU3RyaW5nKCkubWF0Y2goL0FycmF5QnVmZmVyLykpIHtcbiAgICAgICAgdGhpcy5lbWl0KCdkYXRhJywgbmV3IFVpbnQ4QXJyYXkocmVzcEJvZHksIHRoaXMub2Zmc2V0KSk7XG4gICAgICAgIHRoaXMub2Zmc2V0ID0gcmVzcEJvZHkuYnl0ZUxlbmd0aDtcbiAgICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBpZiAocmVzcEJvZHkubGVuZ3RoID4gdGhpcy5vZmZzZXQpIHtcbiAgICAgICAgdGhpcy5lbWl0KCdkYXRhJywgcmVzcEJvZHkuc2xpY2UodGhpcy5vZmZzZXQpKTtcbiAgICAgICAgdGhpcy5vZmZzZXQgPSByZXNwQm9keS5sZW5ndGg7XG4gICAgfVxufTtcblxudmFyIGlzQXJyYXkgPSBBcnJheS5pc0FycmF5IHx8IGZ1bmN0aW9uICh4cykge1xuICAgIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwoeHMpID09PSAnW29iamVjdCBBcnJheV0nO1xufTtcbiIsIjsoZnVuY3Rpb24gKCkge1xuXG4gIHZhciBvYmplY3QgPSB0eXBlb2YgZXhwb3J0cyAhPSAndW5kZWZpbmVkJyA/IGV4cG9ydHMgOiB0aGlzOyAvLyAjODogd2ViIHdvcmtlcnNcbiAgdmFyIGNoYXJzID0gJ0FCQ0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaYWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXowMTIzNDU2Nzg5Ky89JztcblxuICBmdW5jdGlvbiBJbnZhbGlkQ2hhcmFjdGVyRXJyb3IobWVzc2FnZSkge1xuICAgIHRoaXMubWVzc2FnZSA9IG1lc3NhZ2U7XG4gIH1cbiAgSW52YWxpZENoYXJhY3RlckVycm9yLnByb3RvdHlwZSA9IG5ldyBFcnJvcjtcbiAgSW52YWxpZENoYXJhY3RlckVycm9yLnByb3RvdHlwZS5uYW1lID0gJ0ludmFsaWRDaGFyYWN0ZXJFcnJvcic7XG5cbiAgLy8gZW5jb2RlclxuICAvLyBbaHR0cHM6Ly9naXN0LmdpdGh1Yi5jb20vOTk5MTY2XSBieSBbaHR0cHM6Ly9naXRodWIuY29tL25pZ25hZ11cbiAgb2JqZWN0LmJ0b2EgfHwgKFxuICBvYmplY3QuYnRvYSA9IGZ1bmN0aW9uIChpbnB1dCkge1xuICAgIGZvciAoXG4gICAgICAvLyBpbml0aWFsaXplIHJlc3VsdCBhbmQgY291bnRlclxuICAgICAgdmFyIGJsb2NrLCBjaGFyQ29kZSwgaWR4ID0gMCwgbWFwID0gY2hhcnMsIG91dHB1dCA9ICcnO1xuICAgICAgLy8gaWYgdGhlIG5leHQgaW5wdXQgaW5kZXggZG9lcyBub3QgZXhpc3Q6XG4gICAgICAvLyAgIGNoYW5nZSB0aGUgbWFwcGluZyB0YWJsZSB0byBcIj1cIlxuICAgICAgLy8gICBjaGVjayBpZiBkIGhhcyBubyBmcmFjdGlvbmFsIGRpZ2l0c1xuICAgICAgaW5wdXQuY2hhckF0KGlkeCB8IDApIHx8IChtYXAgPSAnPScsIGlkeCAlIDEpO1xuICAgICAgLy8gXCI4IC0gaWR4ICUgMSAqIDhcIiBnZW5lcmF0ZXMgdGhlIHNlcXVlbmNlIDIsIDQsIDYsIDhcbiAgICAgIG91dHB1dCArPSBtYXAuY2hhckF0KDYzICYgYmxvY2sgPj4gOCAtIGlkeCAlIDEgKiA4KVxuICAgICkge1xuICAgICAgY2hhckNvZGUgPSBpbnB1dC5jaGFyQ29kZUF0KGlkeCArPSAzLzQpO1xuICAgICAgaWYgKGNoYXJDb2RlID4gMHhGRikge1xuICAgICAgICB0aHJvdyBuZXcgSW52YWxpZENoYXJhY3RlckVycm9yKFwiJ2J0b2EnIGZhaWxlZDogVGhlIHN0cmluZyB0byBiZSBlbmNvZGVkIGNvbnRhaW5zIGNoYXJhY3RlcnMgb3V0c2lkZSBvZiB0aGUgTGF0aW4xIHJhbmdlLlwiKTtcbiAgICAgIH1cbiAgICAgIGJsb2NrID0gYmxvY2sgPDwgOCB8IGNoYXJDb2RlO1xuICAgIH1cbiAgICByZXR1cm4gb3V0cHV0O1xuICB9KTtcblxuICAvLyBkZWNvZGVyXG4gIC8vIFtodHRwczovL2dpc3QuZ2l0aHViLmNvbS8xMDIwMzk2XSBieSBbaHR0cHM6Ly9naXRodWIuY29tL2F0a11cbiAgb2JqZWN0LmF0b2IgfHwgKFxuICBvYmplY3QuYXRvYiA9IGZ1bmN0aW9uIChpbnB1dCkge1xuICAgIGlucHV0ID0gaW5wdXQucmVwbGFjZSgvPSskLywgJycpO1xuICAgIGlmIChpbnB1dC5sZW5ndGggJSA0ID09IDEpIHtcbiAgICAgIHRocm93IG5ldyBJbnZhbGlkQ2hhcmFjdGVyRXJyb3IoXCInYXRvYicgZmFpbGVkOiBUaGUgc3RyaW5nIHRvIGJlIGRlY29kZWQgaXMgbm90IGNvcnJlY3RseSBlbmNvZGVkLlwiKTtcbiAgICB9XG4gICAgZm9yIChcbiAgICAgIC8vIGluaXRpYWxpemUgcmVzdWx0IGFuZCBjb3VudGVyc1xuICAgICAgdmFyIGJjID0gMCwgYnMsIGJ1ZmZlciwgaWR4ID0gMCwgb3V0cHV0ID0gJyc7XG4gICAgICAvLyBnZXQgbmV4dCBjaGFyYWN0ZXJcbiAgICAgIGJ1ZmZlciA9IGlucHV0LmNoYXJBdChpZHgrKyk7XG4gICAgICAvLyBjaGFyYWN0ZXIgZm91bmQgaW4gdGFibGU/IGluaXRpYWxpemUgYml0IHN0b3JhZ2UgYW5kIGFkZCBpdHMgYXNjaWkgdmFsdWU7XG4gICAgICB+YnVmZmVyICYmIChicyA9IGJjICUgNCA/IGJzICogNjQgKyBidWZmZXIgOiBidWZmZXIsXG4gICAgICAgIC8vIGFuZCBpZiBub3QgZmlyc3Qgb2YgZWFjaCA0IGNoYXJhY3RlcnMsXG4gICAgICAgIC8vIGNvbnZlcnQgdGhlIGZpcnN0IDggYml0cyB0byBvbmUgYXNjaWkgY2hhcmFjdGVyXG4gICAgICAgIGJjKysgJSA0KSA/IG91dHB1dCArPSBTdHJpbmcuZnJvbUNoYXJDb2RlKDI1NSAmIGJzID4+ICgtMiAqIGJjICYgNikpIDogMFxuICAgICkge1xuICAgICAgLy8gdHJ5IHRvIGZpbmQgY2hhcmFjdGVyIGluIHRhYmxlICgwLTYzLCBub3QgZm91bmQgPT4gLTEpXG4gICAgICBidWZmZXIgPSBjaGFycy5pbmRleE9mKGJ1ZmZlcik7XG4gICAgfVxuICAgIHJldHVybiBvdXRwdXQ7XG4gIH0pO1xuXG59KCkpO1xuIiwiaWYgKHR5cGVvZiBPYmplY3QuY3JlYXRlID09PSAnZnVuY3Rpb24nKSB7XG4gIC8vIGltcGxlbWVudGF0aW9uIGZyb20gc3RhbmRhcmQgbm9kZS5qcyAndXRpbCcgbW9kdWxlXG4gIG1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gaW5oZXJpdHMoY3Rvciwgc3VwZXJDdG9yKSB7XG4gICAgY3Rvci5zdXBlcl8gPSBzdXBlckN0b3JcbiAgICBjdG9yLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoc3VwZXJDdG9yLnByb3RvdHlwZSwge1xuICAgICAgY29uc3RydWN0b3I6IHtcbiAgICAgICAgdmFsdWU6IGN0b3IsXG4gICAgICAgIGVudW1lcmFibGU6IGZhbHNlLFxuICAgICAgICB3cml0YWJsZTogdHJ1ZSxcbiAgICAgICAgY29uZmlndXJhYmxlOiB0cnVlXG4gICAgICB9XG4gICAgfSk7XG4gIH07XG59IGVsc2Uge1xuICAvLyBvbGQgc2Nob29sIHNoaW0gZm9yIG9sZCBicm93c2Vyc1xuICBtb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIGluaGVyaXRzKGN0b3IsIHN1cGVyQ3Rvcikge1xuICAgIGN0b3Iuc3VwZXJfID0gc3VwZXJDdG9yXG4gICAgdmFyIFRlbXBDdG9yID0gZnVuY3Rpb24gKCkge31cbiAgICBUZW1wQ3Rvci5wcm90b3R5cGUgPSBzdXBlckN0b3IucHJvdG90eXBlXG4gICAgY3Rvci5wcm90b3R5cGUgPSBuZXcgVGVtcEN0b3IoKVxuICAgIGN0b3IucHJvdG90eXBlLmNvbnN0cnVjdG9yID0gY3RvclxuICB9XG59XG4iLCIvKiFcbiAqIERldGVybWluZSBpZiBhbiBvYmplY3QgaXMgYSBCdWZmZXJcbiAqXG4gKiBAYXV0aG9yICAgRmVyb3NzIEFib3VraGFkaWplaCA8ZmVyb3NzQGZlcm9zcy5vcmc+IDxodHRwOi8vZmVyb3NzLm9yZz5cbiAqIEBsaWNlbnNlICBNSVRcbiAqL1xuXG4vLyBUaGUgX2lzQnVmZmVyIGNoZWNrIGlzIGZvciBTYWZhcmkgNS03IHN1cHBvcnQsIGJlY2F1c2UgaXQncyBtaXNzaW5nXG4vLyBPYmplY3QucHJvdG90eXBlLmNvbnN0cnVjdG9yLiBSZW1vdmUgdGhpcyBldmVudHVhbGx5XG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uIChvYmopIHtcbiAgcmV0dXJuIG9iaiAhPSBudWxsICYmIChpc0J1ZmZlcihvYmopIHx8IGlzU2xvd0J1ZmZlcihvYmopIHx8ICEhb2JqLl9pc0J1ZmZlcilcbn1cblxuZnVuY3Rpb24gaXNCdWZmZXIgKG9iaikge1xuICByZXR1cm4gISFvYmouY29uc3RydWN0b3IgJiYgdHlwZW9mIG9iai5jb25zdHJ1Y3Rvci5pc0J1ZmZlciA9PT0gJ2Z1bmN0aW9uJyAmJiBvYmouY29uc3RydWN0b3IuaXNCdWZmZXIob2JqKVxufVxuXG4vLyBGb3IgTm9kZSB2MC4xMCBzdXBwb3J0LiBSZW1vdmUgdGhpcyBldmVudHVhbGx5LlxuZnVuY3Rpb24gaXNTbG93QnVmZmVyIChvYmopIHtcbiAgcmV0dXJuIHR5cGVvZiBvYmoucmVhZEZsb2F0TEUgPT09ICdmdW5jdGlvbicgJiYgdHlwZW9mIG9iai5zbGljZSA9PT0gJ2Z1bmN0aW9uJyAmJiBpc0J1ZmZlcihvYmouc2xpY2UoMCwgMCkpXG59XG4iLCJtb2R1bGUuZXhwb3J0cyA9IEFycmF5LmlzQXJyYXkgfHwgZnVuY3Rpb24gKGFycikge1xuICByZXR1cm4gT2JqZWN0LnByb3RvdHlwZS50b1N0cmluZy5jYWxsKGFycikgPT0gJ1tvYmplY3QgQXJyYXldJztcbn07XG4iLCIvLyBzaGltIGZvciB1c2luZyBwcm9jZXNzIGluIGJyb3dzZXJcblxudmFyIHByb2Nlc3MgPSBtb2R1bGUuZXhwb3J0cyA9IHt9O1xuXG5wcm9jZXNzLm5leHRUaWNrID0gKGZ1bmN0aW9uICgpIHtcbiAgICB2YXIgY2FuU2V0SW1tZWRpYXRlID0gdHlwZW9mIHdpbmRvdyAhPT0gJ3VuZGVmaW5lZCdcbiAgICAmJiB3aW5kb3cuc2V0SW1tZWRpYXRlO1xuICAgIHZhciBjYW5NdXRhdGlvbk9ic2VydmVyID0gdHlwZW9mIHdpbmRvdyAhPT0gJ3VuZGVmaW5lZCdcbiAgICAmJiB3aW5kb3cuTXV0YXRpb25PYnNlcnZlcjtcbiAgICB2YXIgY2FuUG9zdCA9IHR5cGVvZiB3aW5kb3cgIT09ICd1bmRlZmluZWQnXG4gICAgJiYgd2luZG93LnBvc3RNZXNzYWdlICYmIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyXG4gICAgO1xuXG4gICAgaWYgKGNhblNldEltbWVkaWF0ZSkge1xuICAgICAgICByZXR1cm4gZnVuY3Rpb24gKGYpIHsgcmV0dXJuIHdpbmRvdy5zZXRJbW1lZGlhdGUoZikgfTtcbiAgICB9XG5cbiAgICB2YXIgcXVldWUgPSBbXTtcblxuICAgIGlmIChjYW5NdXRhdGlvbk9ic2VydmVyKSB7XG4gICAgICAgIHZhciBoaWRkZW5EaXYgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KFwiZGl2XCIpO1xuICAgICAgICB2YXIgb2JzZXJ2ZXIgPSBuZXcgTXV0YXRpb25PYnNlcnZlcihmdW5jdGlvbiAoKSB7XG4gICAgICAgICAgICB2YXIgcXVldWVMaXN0ID0gcXVldWUuc2xpY2UoKTtcbiAgICAgICAgICAgIHF1ZXVlLmxlbmd0aCA9IDA7XG4gICAgICAgICAgICBxdWV1ZUxpc3QuZm9yRWFjaChmdW5jdGlvbiAoZm4pIHtcbiAgICAgICAgICAgICAgICBmbigpO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgIH0pO1xuXG4gICAgICAgIG9ic2VydmVyLm9ic2VydmUoaGlkZGVuRGl2LCB7IGF0dHJpYnV0ZXM6IHRydWUgfSk7XG5cbiAgICAgICAgcmV0dXJuIGZ1bmN0aW9uIG5leHRUaWNrKGZuKSB7XG4gICAgICAgICAgICBpZiAoIXF1ZXVlLmxlbmd0aCkge1xuICAgICAgICAgICAgICAgIGhpZGRlbkRpdi5zZXRBdHRyaWJ1dGUoJ3llcycsICdubycpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgcXVldWUucHVzaChmbik7XG4gICAgICAgIH07XG4gICAgfVxuXG4gICAgaWYgKGNhblBvc3QpIHtcbiAgICAgICAgd2luZG93LmFkZEV2ZW50TGlzdGVuZXIoJ21lc3NhZ2UnLCBmdW5jdGlvbiAoZXYpIHtcbiAgICAgICAgICAgIHZhciBzb3VyY2UgPSBldi5zb3VyY2U7XG4gICAgICAgICAgICBpZiAoKHNvdXJjZSA9PT0gd2luZG93IHx8IHNvdXJjZSA9PT0gbnVsbCkgJiYgZXYuZGF0YSA9PT0gJ3Byb2Nlc3MtdGljaycpIHtcbiAgICAgICAgICAgICAgICBldi5zdG9wUHJvcGFnYXRpb24oKTtcbiAgICAgICAgICAgICAgICBpZiAocXVldWUubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgICAgICAgICB2YXIgZm4gPSBxdWV1ZS5zaGlmdCgpO1xuICAgICAgICAgICAgICAgICAgICBmbigpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cbiAgICAgICAgfSwgdHJ1ZSk7XG5cbiAgICAgICAgcmV0dXJuIGZ1bmN0aW9uIG5leHRUaWNrKGZuKSB7XG4gICAgICAgICAgICBxdWV1ZS5wdXNoKGZuKTtcbiAgICAgICAgICAgIHdpbmRvdy5wb3N0TWVzc2FnZSgncHJvY2Vzcy10aWNrJywgJyonKTtcbiAgICAgICAgfTtcbiAgICB9XG5cbiAgICByZXR1cm4gZnVuY3Rpb24gbmV4dFRpY2soZm4pIHtcbiAgICAgICAgc2V0VGltZW91dChmbiwgMCk7XG4gICAgfTtcbn0pKCk7XG5cbnByb2Nlc3MudGl0bGUgPSAnYnJvd3Nlcic7XG5wcm9jZXNzLmJyb3dzZXIgPSB0cnVlO1xucHJvY2Vzcy5lbnYgPSB7fTtcbnByb2Nlc3MuYXJndiA9IFtdO1xuXG5mdW5jdGlvbiBub29wKCkge31cblxucHJvY2Vzcy5vbiA9IG5vb3A7XG5wcm9jZXNzLmFkZExpc3RlbmVyID0gbm9vcDtcbnByb2Nlc3Mub25jZSA9IG5vb3A7XG5wcm9jZXNzLm9mZiA9IG5vb3A7XG5wcm9jZXNzLnJlbW92ZUxpc3RlbmVyID0gbm9vcDtcbnByb2Nlc3MucmVtb3ZlQWxsTGlzdGVuZXJzID0gbm9vcDtcbnByb2Nlc3MuZW1pdCA9IG5vb3A7XG5cbnByb2Nlc3MuYmluZGluZyA9IGZ1bmN0aW9uIChuYW1lKSB7XG4gICAgdGhyb3cgbmV3IEVycm9yKCdwcm9jZXNzLmJpbmRpbmcgaXMgbm90IHN1cHBvcnRlZCcpO1xufTtcblxuLy8gVE9ETyhzaHR5bG1hbilcbnByb2Nlc3MuY3dkID0gZnVuY3Rpb24gKCkgeyByZXR1cm4gJy8nIH07XG5wcm9jZXNzLmNoZGlyID0gZnVuY3Rpb24gKGRpcikge1xuICAgIHRocm93IG5ldyBFcnJvcigncHJvY2Vzcy5jaGRpciBpcyBub3Qgc3VwcG9ydGVkJyk7XG59O1xuIiwiKGZ1bmN0aW9uIChnbG9iYWwpe1xuLyohIGh0dHA6Ly9tdGhzLmJlL3B1bnljb2RlIHYxLjIuNCBieSBAbWF0aGlhcyAqL1xuOyhmdW5jdGlvbihyb290KSB7XG5cblx0LyoqIERldGVjdCBmcmVlIHZhcmlhYmxlcyAqL1xuXHR2YXIgZnJlZUV4cG9ydHMgPSB0eXBlb2YgZXhwb3J0cyA9PSAnb2JqZWN0JyAmJiBleHBvcnRzO1xuXHR2YXIgZnJlZU1vZHVsZSA9IHR5cGVvZiBtb2R1bGUgPT0gJ29iamVjdCcgJiYgbW9kdWxlICYmXG5cdFx0bW9kdWxlLmV4cG9ydHMgPT0gZnJlZUV4cG9ydHMgJiYgbW9kdWxlO1xuXHR2YXIgZnJlZUdsb2JhbCA9IHR5cGVvZiBnbG9iYWwgPT0gJ29iamVjdCcgJiYgZ2xvYmFsO1xuXHRpZiAoZnJlZUdsb2JhbC5nbG9iYWwgPT09IGZyZWVHbG9iYWwgfHwgZnJlZUdsb2JhbC53aW5kb3cgPT09IGZyZWVHbG9iYWwpIHtcblx0XHRyb290ID0gZnJlZUdsb2JhbDtcblx0fVxuXG5cdC8qKlxuXHQgKiBUaGUgYHB1bnljb2RlYCBvYmplY3QuXG5cdCAqIEBuYW1lIHB1bnljb2RlXG5cdCAqIEB0eXBlIE9iamVjdFxuXHQgKi9cblx0dmFyIHB1bnljb2RlLFxuXG5cdC8qKiBIaWdoZXN0IHBvc2l0aXZlIHNpZ25lZCAzMi1iaXQgZmxvYXQgdmFsdWUgKi9cblx0bWF4SW50ID0gMjE0NzQ4MzY0NywgLy8gYWthLiAweDdGRkZGRkZGIG9yIDJeMzEtMVxuXG5cdC8qKiBCb290c3RyaW5nIHBhcmFtZXRlcnMgKi9cblx0YmFzZSA9IDM2LFxuXHR0TWluID0gMSxcblx0dE1heCA9IDI2LFxuXHRza2V3ID0gMzgsXG5cdGRhbXAgPSA3MDAsXG5cdGluaXRpYWxCaWFzID0gNzIsXG5cdGluaXRpYWxOID0gMTI4LCAvLyAweDgwXG5cdGRlbGltaXRlciA9ICctJywgLy8gJ1xceDJEJ1xuXG5cdC8qKiBSZWd1bGFyIGV4cHJlc3Npb25zICovXG5cdHJlZ2V4UHVueWNvZGUgPSAvXnhuLS0vLFxuXHRyZWdleE5vbkFTQ0lJID0gL1teIC1+XS8sIC8vIHVucHJpbnRhYmxlIEFTQ0lJIGNoYXJzICsgbm9uLUFTQ0lJIGNoYXJzXG5cdHJlZ2V4U2VwYXJhdG9ycyA9IC9cXHgyRXxcXHUzMDAyfFxcdUZGMEV8XFx1RkY2MS9nLCAvLyBSRkMgMzQ5MCBzZXBhcmF0b3JzXG5cblx0LyoqIEVycm9yIG1lc3NhZ2VzICovXG5cdGVycm9ycyA9IHtcblx0XHQnb3ZlcmZsb3cnOiAnT3ZlcmZsb3c6IGlucHV0IG5lZWRzIHdpZGVyIGludGVnZXJzIHRvIHByb2Nlc3MnLFxuXHRcdCdub3QtYmFzaWMnOiAnSWxsZWdhbCBpbnB1dCA+PSAweDgwIChub3QgYSBiYXNpYyBjb2RlIHBvaW50KScsXG5cdFx0J2ludmFsaWQtaW5wdXQnOiAnSW52YWxpZCBpbnB1dCdcblx0fSxcblxuXHQvKiogQ29udmVuaWVuY2Ugc2hvcnRjdXRzICovXG5cdGJhc2VNaW51c1RNaW4gPSBiYXNlIC0gdE1pbixcblx0Zmxvb3IgPSBNYXRoLmZsb29yLFxuXHRzdHJpbmdGcm9tQ2hhckNvZGUgPSBTdHJpbmcuZnJvbUNoYXJDb2RlLFxuXG5cdC8qKiBUZW1wb3JhcnkgdmFyaWFibGUgKi9cblx0a2V5O1xuXG5cdC8qLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0qL1xuXG5cdC8qKlxuXHQgKiBBIGdlbmVyaWMgZXJyb3IgdXRpbGl0eSBmdW5jdGlvbi5cblx0ICogQHByaXZhdGVcblx0ICogQHBhcmFtIHtTdHJpbmd9IHR5cGUgVGhlIGVycm9yIHR5cGUuXG5cdCAqIEByZXR1cm5zIHtFcnJvcn0gVGhyb3dzIGEgYFJhbmdlRXJyb3JgIHdpdGggdGhlIGFwcGxpY2FibGUgZXJyb3IgbWVzc2FnZS5cblx0ICovXG5cdGZ1bmN0aW9uIGVycm9yKHR5cGUpIHtcblx0XHR0aHJvdyBSYW5nZUVycm9yKGVycm9yc1t0eXBlXSk7XG5cdH1cblxuXHQvKipcblx0ICogQSBnZW5lcmljIGBBcnJheSNtYXBgIHV0aWxpdHkgZnVuY3Rpb24uXG5cdCAqIEBwcml2YXRlXG5cdCAqIEBwYXJhbSB7QXJyYXl9IGFycmF5IFRoZSBhcnJheSB0byBpdGVyYXRlIG92ZXIuXG5cdCAqIEBwYXJhbSB7RnVuY3Rpb259IGNhbGxiYWNrIFRoZSBmdW5jdGlvbiB0aGF0IGdldHMgY2FsbGVkIGZvciBldmVyeSBhcnJheVxuXHQgKiBpdGVtLlxuXHQgKiBAcmV0dXJucyB7QXJyYXl9IEEgbmV3IGFycmF5IG9mIHZhbHVlcyByZXR1cm5lZCBieSB0aGUgY2FsbGJhY2sgZnVuY3Rpb24uXG5cdCAqL1xuXHRmdW5jdGlvbiBtYXAoYXJyYXksIGZuKSB7XG5cdFx0dmFyIGxlbmd0aCA9IGFycmF5Lmxlbmd0aDtcblx0XHR3aGlsZSAobGVuZ3RoLS0pIHtcblx0XHRcdGFycmF5W2xlbmd0aF0gPSBmbihhcnJheVtsZW5ndGhdKTtcblx0XHR9XG5cdFx0cmV0dXJuIGFycmF5O1xuXHR9XG5cblx0LyoqXG5cdCAqIEEgc2ltcGxlIGBBcnJheSNtYXBgLWxpa2Ugd3JhcHBlciB0byB3b3JrIHdpdGggZG9tYWluIG5hbWUgc3RyaW5ncy5cblx0ICogQHByaXZhdGVcblx0ICogQHBhcmFtIHtTdHJpbmd9IGRvbWFpbiBUaGUgZG9tYWluIG5hbWUuXG5cdCAqIEBwYXJhbSB7RnVuY3Rpb259IGNhbGxiYWNrIFRoZSBmdW5jdGlvbiB0aGF0IGdldHMgY2FsbGVkIGZvciBldmVyeVxuXHQgKiBjaGFyYWN0ZXIuXG5cdCAqIEByZXR1cm5zIHtBcnJheX0gQSBuZXcgc3RyaW5nIG9mIGNoYXJhY3RlcnMgcmV0dXJuZWQgYnkgdGhlIGNhbGxiYWNrXG5cdCAqIGZ1bmN0aW9uLlxuXHQgKi9cblx0ZnVuY3Rpb24gbWFwRG9tYWluKHN0cmluZywgZm4pIHtcblx0XHRyZXR1cm4gbWFwKHN0cmluZy5zcGxpdChyZWdleFNlcGFyYXRvcnMpLCBmbikuam9pbignLicpO1xuXHR9XG5cblx0LyoqXG5cdCAqIENyZWF0ZXMgYW4gYXJyYXkgY29udGFpbmluZyB0aGUgbnVtZXJpYyBjb2RlIHBvaW50cyBvZiBlYWNoIFVuaWNvZGVcblx0ICogY2hhcmFjdGVyIGluIHRoZSBzdHJpbmcuIFdoaWxlIEphdmFTY3JpcHQgdXNlcyBVQ1MtMiBpbnRlcm5hbGx5LFxuXHQgKiB0aGlzIGZ1bmN0aW9uIHdpbGwgY29udmVydCBhIHBhaXIgb2Ygc3Vycm9nYXRlIGhhbHZlcyAoZWFjaCBvZiB3aGljaFxuXHQgKiBVQ1MtMiBleHBvc2VzIGFzIHNlcGFyYXRlIGNoYXJhY3RlcnMpIGludG8gYSBzaW5nbGUgY29kZSBwb2ludCxcblx0ICogbWF0Y2hpbmcgVVRGLTE2LlxuXHQgKiBAc2VlIGBwdW55Y29kZS51Y3MyLmVuY29kZWBcblx0ICogQHNlZSA8aHR0cDovL21hdGhpYXNieW5lbnMuYmUvbm90ZXMvamF2YXNjcmlwdC1lbmNvZGluZz5cblx0ICogQG1lbWJlck9mIHB1bnljb2RlLnVjczJcblx0ICogQG5hbWUgZGVjb2RlXG5cdCAqIEBwYXJhbSB7U3RyaW5nfSBzdHJpbmcgVGhlIFVuaWNvZGUgaW5wdXQgc3RyaW5nIChVQ1MtMikuXG5cdCAqIEByZXR1cm5zIHtBcnJheX0gVGhlIG5ldyBhcnJheSBvZiBjb2RlIHBvaW50cy5cblx0ICovXG5cdGZ1bmN0aW9uIHVjczJkZWNvZGUoc3RyaW5nKSB7XG5cdFx0dmFyIG91dHB1dCA9IFtdLFxuXHRcdCAgICBjb3VudGVyID0gMCxcblx0XHQgICAgbGVuZ3RoID0gc3RyaW5nLmxlbmd0aCxcblx0XHQgICAgdmFsdWUsXG5cdFx0ICAgIGV4dHJhO1xuXHRcdHdoaWxlIChjb3VudGVyIDwgbGVuZ3RoKSB7XG5cdFx0XHR2YWx1ZSA9IHN0cmluZy5jaGFyQ29kZUF0KGNvdW50ZXIrKyk7XG5cdFx0XHRpZiAodmFsdWUgPj0gMHhEODAwICYmIHZhbHVlIDw9IDB4REJGRiAmJiBjb3VudGVyIDwgbGVuZ3RoKSB7XG5cdFx0XHRcdC8vIGhpZ2ggc3Vycm9nYXRlLCBhbmQgdGhlcmUgaXMgYSBuZXh0IGNoYXJhY3RlclxuXHRcdFx0XHRleHRyYSA9IHN0cmluZy5jaGFyQ29kZUF0KGNvdW50ZXIrKyk7XG5cdFx0XHRcdGlmICgoZXh0cmEgJiAweEZDMDApID09IDB4REMwMCkgeyAvLyBsb3cgc3Vycm9nYXRlXG5cdFx0XHRcdFx0b3V0cHV0LnB1c2goKCh2YWx1ZSAmIDB4M0ZGKSA8PCAxMCkgKyAoZXh0cmEgJiAweDNGRikgKyAweDEwMDAwKTtcblx0XHRcdFx0fSBlbHNlIHtcblx0XHRcdFx0XHQvLyB1bm1hdGNoZWQgc3Vycm9nYXRlOyBvbmx5IGFwcGVuZCB0aGlzIGNvZGUgdW5pdCwgaW4gY2FzZSB0aGUgbmV4dFxuXHRcdFx0XHRcdC8vIGNvZGUgdW5pdCBpcyB0aGUgaGlnaCBzdXJyb2dhdGUgb2YgYSBzdXJyb2dhdGUgcGFpclxuXHRcdFx0XHRcdG91dHB1dC5wdXNoKHZhbHVlKTtcblx0XHRcdFx0XHRjb3VudGVyLS07XG5cdFx0XHRcdH1cblx0XHRcdH0gZWxzZSB7XG5cdFx0XHRcdG91dHB1dC5wdXNoKHZhbHVlKTtcblx0XHRcdH1cblx0XHR9XG5cdFx0cmV0dXJuIG91dHB1dDtcblx0fVxuXG5cdC8qKlxuXHQgKiBDcmVhdGVzIGEgc3RyaW5nIGJhc2VkIG9uIGFuIGFycmF5IG9mIG51bWVyaWMgY29kZSBwb2ludHMuXG5cdCAqIEBzZWUgYHB1bnljb2RlLnVjczIuZGVjb2RlYFxuXHQgKiBAbWVtYmVyT2YgcHVueWNvZGUudWNzMlxuXHQgKiBAbmFtZSBlbmNvZGVcblx0ICogQHBhcmFtIHtBcnJheX0gY29kZVBvaW50cyBUaGUgYXJyYXkgb2YgbnVtZXJpYyBjb2RlIHBvaW50cy5cblx0ICogQHJldHVybnMge1N0cmluZ30gVGhlIG5ldyBVbmljb2RlIHN0cmluZyAoVUNTLTIpLlxuXHQgKi9cblx0ZnVuY3Rpb24gdWNzMmVuY29kZShhcnJheSkge1xuXHRcdHJldHVybiBtYXAoYXJyYXksIGZ1bmN0aW9uKHZhbHVlKSB7XG5cdFx0XHR2YXIgb3V0cHV0ID0gJyc7XG5cdFx0XHRpZiAodmFsdWUgPiAweEZGRkYpIHtcblx0XHRcdFx0dmFsdWUgLT0gMHgxMDAwMDtcblx0XHRcdFx0b3V0cHV0ICs9IHN0cmluZ0Zyb21DaGFyQ29kZSh2YWx1ZSA+Pj4gMTAgJiAweDNGRiB8IDB4RDgwMCk7XG5cdFx0XHRcdHZhbHVlID0gMHhEQzAwIHwgdmFsdWUgJiAweDNGRjtcblx0XHRcdH1cblx0XHRcdG91dHB1dCArPSBzdHJpbmdGcm9tQ2hhckNvZGUodmFsdWUpO1xuXHRcdFx0cmV0dXJuIG91dHB1dDtcblx0XHR9KS5qb2luKCcnKTtcblx0fVxuXG5cdC8qKlxuXHQgKiBDb252ZXJ0cyBhIGJhc2ljIGNvZGUgcG9pbnQgaW50byBhIGRpZ2l0L2ludGVnZXIuXG5cdCAqIEBzZWUgYGRpZ2l0VG9CYXNpYygpYFxuXHQgKiBAcHJpdmF0ZVxuXHQgKiBAcGFyYW0ge051bWJlcn0gY29kZVBvaW50IFRoZSBiYXNpYyBudW1lcmljIGNvZGUgcG9pbnQgdmFsdWUuXG5cdCAqIEByZXR1cm5zIHtOdW1iZXJ9IFRoZSBudW1lcmljIHZhbHVlIG9mIGEgYmFzaWMgY29kZSBwb2ludCAoZm9yIHVzZSBpblxuXHQgKiByZXByZXNlbnRpbmcgaW50ZWdlcnMpIGluIHRoZSByYW5nZSBgMGAgdG8gYGJhc2UgLSAxYCwgb3IgYGJhc2VgIGlmXG5cdCAqIHRoZSBjb2RlIHBvaW50IGRvZXMgbm90IHJlcHJlc2VudCBhIHZhbHVlLlxuXHQgKi9cblx0ZnVuY3Rpb24gYmFzaWNUb0RpZ2l0KGNvZGVQb2ludCkge1xuXHRcdGlmIChjb2RlUG9pbnQgLSA0OCA8IDEwKSB7XG5cdFx0XHRyZXR1cm4gY29kZVBvaW50IC0gMjI7XG5cdFx0fVxuXHRcdGlmIChjb2RlUG9pbnQgLSA2NSA8IDI2KSB7XG5cdFx0XHRyZXR1cm4gY29kZVBvaW50IC0gNjU7XG5cdFx0fVxuXHRcdGlmIChjb2RlUG9pbnQgLSA5NyA8IDI2KSB7XG5cdFx0XHRyZXR1cm4gY29kZVBvaW50IC0gOTc7XG5cdFx0fVxuXHRcdHJldHVybiBiYXNlO1xuXHR9XG5cblx0LyoqXG5cdCAqIENvbnZlcnRzIGEgZGlnaXQvaW50ZWdlciBpbnRvIGEgYmFzaWMgY29kZSBwb2ludC5cblx0ICogQHNlZSBgYmFzaWNUb0RpZ2l0KClgXG5cdCAqIEBwcml2YXRlXG5cdCAqIEBwYXJhbSB7TnVtYmVyfSBkaWdpdCBUaGUgbnVtZXJpYyB2YWx1ZSBvZiBhIGJhc2ljIGNvZGUgcG9pbnQuXG5cdCAqIEByZXR1cm5zIHtOdW1iZXJ9IFRoZSBiYXNpYyBjb2RlIHBvaW50IHdob3NlIHZhbHVlICh3aGVuIHVzZWQgZm9yXG5cdCAqIHJlcHJlc2VudGluZyBpbnRlZ2VycykgaXMgYGRpZ2l0YCwgd2hpY2ggbmVlZHMgdG8gYmUgaW4gdGhlIHJhbmdlXG5cdCAqIGAwYCB0byBgYmFzZSAtIDFgLiBJZiBgZmxhZ2AgaXMgbm9uLXplcm8sIHRoZSB1cHBlcmNhc2UgZm9ybSBpc1xuXHQgKiB1c2VkOyBlbHNlLCB0aGUgbG93ZXJjYXNlIGZvcm0gaXMgdXNlZC4gVGhlIGJlaGF2aW9yIGlzIHVuZGVmaW5lZFxuXHQgKiBpZiBgZmxhZ2AgaXMgbm9uLXplcm8gYW5kIGBkaWdpdGAgaGFzIG5vIHVwcGVyY2FzZSBmb3JtLlxuXHQgKi9cblx0ZnVuY3Rpb24gZGlnaXRUb0Jhc2ljKGRpZ2l0LCBmbGFnKSB7XG5cdFx0Ly8gIDAuLjI1IG1hcCB0byBBU0NJSSBhLi56IG9yIEEuLlpcblx0XHQvLyAyNi4uMzUgbWFwIHRvIEFTQ0lJIDAuLjlcblx0XHRyZXR1cm4gZGlnaXQgKyAyMiArIDc1ICogKGRpZ2l0IDwgMjYpIC0gKChmbGFnICE9IDApIDw8IDUpO1xuXHR9XG5cblx0LyoqXG5cdCAqIEJpYXMgYWRhcHRhdGlvbiBmdW5jdGlvbiBhcyBwZXIgc2VjdGlvbiAzLjQgb2YgUkZDIDM0OTIuXG5cdCAqIGh0dHA6Ly90b29scy5pZXRmLm9yZy9odG1sL3JmYzM0OTIjc2VjdGlvbi0zLjRcblx0ICogQHByaXZhdGVcblx0ICovXG5cdGZ1bmN0aW9uIGFkYXB0KGRlbHRhLCBudW1Qb2ludHMsIGZpcnN0VGltZSkge1xuXHRcdHZhciBrID0gMDtcblx0XHRkZWx0YSA9IGZpcnN0VGltZSA/IGZsb29yKGRlbHRhIC8gZGFtcCkgOiBkZWx0YSA+PiAxO1xuXHRcdGRlbHRhICs9IGZsb29yKGRlbHRhIC8gbnVtUG9pbnRzKTtcblx0XHRmb3IgKC8qIG5vIGluaXRpYWxpemF0aW9uICovOyBkZWx0YSA+IGJhc2VNaW51c1RNaW4gKiB0TWF4ID4+IDE7IGsgKz0gYmFzZSkge1xuXHRcdFx0ZGVsdGEgPSBmbG9vcihkZWx0YSAvIGJhc2VNaW51c1RNaW4pO1xuXHRcdH1cblx0XHRyZXR1cm4gZmxvb3IoayArIChiYXNlTWludXNUTWluICsgMSkgKiBkZWx0YSAvIChkZWx0YSArIHNrZXcpKTtcblx0fVxuXG5cdC8qKlxuXHQgKiBDb252ZXJ0cyBhIFB1bnljb2RlIHN0cmluZyBvZiBBU0NJSS1vbmx5IHN5bWJvbHMgdG8gYSBzdHJpbmcgb2YgVW5pY29kZVxuXHQgKiBzeW1ib2xzLlxuXHQgKiBAbWVtYmVyT2YgcHVueWNvZGVcblx0ICogQHBhcmFtIHtTdHJpbmd9IGlucHV0IFRoZSBQdW55Y29kZSBzdHJpbmcgb2YgQVNDSUktb25seSBzeW1ib2xzLlxuXHQgKiBAcmV0dXJucyB7U3RyaW5nfSBUaGUgcmVzdWx0aW5nIHN0cmluZyBvZiBVbmljb2RlIHN5bWJvbHMuXG5cdCAqL1xuXHRmdW5jdGlvbiBkZWNvZGUoaW5wdXQpIHtcblx0XHQvLyBEb24ndCB1c2UgVUNTLTJcblx0XHR2YXIgb3V0cHV0ID0gW10sXG5cdFx0ICAgIGlucHV0TGVuZ3RoID0gaW5wdXQubGVuZ3RoLFxuXHRcdCAgICBvdXQsXG5cdFx0ICAgIGkgPSAwLFxuXHRcdCAgICBuID0gaW5pdGlhbE4sXG5cdFx0ICAgIGJpYXMgPSBpbml0aWFsQmlhcyxcblx0XHQgICAgYmFzaWMsXG5cdFx0ICAgIGosXG5cdFx0ICAgIGluZGV4LFxuXHRcdCAgICBvbGRpLFxuXHRcdCAgICB3LFxuXHRcdCAgICBrLFxuXHRcdCAgICBkaWdpdCxcblx0XHQgICAgdCxcblx0XHQgICAgLyoqIENhY2hlZCBjYWxjdWxhdGlvbiByZXN1bHRzICovXG5cdFx0ICAgIGJhc2VNaW51c1Q7XG5cblx0XHQvLyBIYW5kbGUgdGhlIGJhc2ljIGNvZGUgcG9pbnRzOiBsZXQgYGJhc2ljYCBiZSB0aGUgbnVtYmVyIG9mIGlucHV0IGNvZGVcblx0XHQvLyBwb2ludHMgYmVmb3JlIHRoZSBsYXN0IGRlbGltaXRlciwgb3IgYDBgIGlmIHRoZXJlIGlzIG5vbmUsIHRoZW4gY29weVxuXHRcdC8vIHRoZSBmaXJzdCBiYXNpYyBjb2RlIHBvaW50cyB0byB0aGUgb3V0cHV0LlxuXG5cdFx0YmFzaWMgPSBpbnB1dC5sYXN0SW5kZXhPZihkZWxpbWl0ZXIpO1xuXHRcdGlmIChiYXNpYyA8IDApIHtcblx0XHRcdGJhc2ljID0gMDtcblx0XHR9XG5cblx0XHRmb3IgKGogPSAwOyBqIDwgYmFzaWM7ICsraikge1xuXHRcdFx0Ly8gaWYgaXQncyBub3QgYSBiYXNpYyBjb2RlIHBvaW50XG5cdFx0XHRpZiAoaW5wdXQuY2hhckNvZGVBdChqKSA+PSAweDgwKSB7XG5cdFx0XHRcdGVycm9yKCdub3QtYmFzaWMnKTtcblx0XHRcdH1cblx0XHRcdG91dHB1dC5wdXNoKGlucHV0LmNoYXJDb2RlQXQoaikpO1xuXHRcdH1cblxuXHRcdC8vIE1haW4gZGVjb2RpbmcgbG9vcDogc3RhcnQganVzdCBhZnRlciB0aGUgbGFzdCBkZWxpbWl0ZXIgaWYgYW55IGJhc2ljIGNvZGVcblx0XHQvLyBwb2ludHMgd2VyZSBjb3BpZWQ7IHN0YXJ0IGF0IHRoZSBiZWdpbm5pbmcgb3RoZXJ3aXNlLlxuXG5cdFx0Zm9yIChpbmRleCA9IGJhc2ljID4gMCA/IGJhc2ljICsgMSA6IDA7IGluZGV4IDwgaW5wdXRMZW5ndGg7IC8qIG5vIGZpbmFsIGV4cHJlc3Npb24gKi8pIHtcblxuXHRcdFx0Ly8gYGluZGV4YCBpcyB0aGUgaW5kZXggb2YgdGhlIG5leHQgY2hhcmFjdGVyIHRvIGJlIGNvbnN1bWVkLlxuXHRcdFx0Ly8gRGVjb2RlIGEgZ2VuZXJhbGl6ZWQgdmFyaWFibGUtbGVuZ3RoIGludGVnZXIgaW50byBgZGVsdGFgLFxuXHRcdFx0Ly8gd2hpY2ggZ2V0cyBhZGRlZCB0byBgaWAuIFRoZSBvdmVyZmxvdyBjaGVja2luZyBpcyBlYXNpZXJcblx0XHRcdC8vIGlmIHdlIGluY3JlYXNlIGBpYCBhcyB3ZSBnbywgdGhlbiBzdWJ0cmFjdCBvZmYgaXRzIHN0YXJ0aW5nXG5cdFx0XHQvLyB2YWx1ZSBhdCB0aGUgZW5kIHRvIG9idGFpbiBgZGVsdGFgLlxuXHRcdFx0Zm9yIChvbGRpID0gaSwgdyA9IDEsIGsgPSBiYXNlOyAvKiBubyBjb25kaXRpb24gKi87IGsgKz0gYmFzZSkge1xuXG5cdFx0XHRcdGlmIChpbmRleCA+PSBpbnB1dExlbmd0aCkge1xuXHRcdFx0XHRcdGVycm9yKCdpbnZhbGlkLWlucHV0Jyk7XG5cdFx0XHRcdH1cblxuXHRcdFx0XHRkaWdpdCA9IGJhc2ljVG9EaWdpdChpbnB1dC5jaGFyQ29kZUF0KGluZGV4KyspKTtcblxuXHRcdFx0XHRpZiAoZGlnaXQgPj0gYmFzZSB8fCBkaWdpdCA+IGZsb29yKChtYXhJbnQgLSBpKSAvIHcpKSB7XG5cdFx0XHRcdFx0ZXJyb3IoJ292ZXJmbG93Jyk7XG5cdFx0XHRcdH1cblxuXHRcdFx0XHRpICs9IGRpZ2l0ICogdztcblx0XHRcdFx0dCA9IGsgPD0gYmlhcyA/IHRNaW4gOiAoayA+PSBiaWFzICsgdE1heCA/IHRNYXggOiBrIC0gYmlhcyk7XG5cblx0XHRcdFx0aWYgKGRpZ2l0IDwgdCkge1xuXHRcdFx0XHRcdGJyZWFrO1xuXHRcdFx0XHR9XG5cblx0XHRcdFx0YmFzZU1pbnVzVCA9IGJhc2UgLSB0O1xuXHRcdFx0XHRpZiAodyA+IGZsb29yKG1heEludCAvIGJhc2VNaW51c1QpKSB7XG5cdFx0XHRcdFx0ZXJyb3IoJ292ZXJmbG93Jyk7XG5cdFx0XHRcdH1cblxuXHRcdFx0XHR3ICo9IGJhc2VNaW51c1Q7XG5cblx0XHRcdH1cblxuXHRcdFx0b3V0ID0gb3V0cHV0Lmxlbmd0aCArIDE7XG5cdFx0XHRiaWFzID0gYWRhcHQoaSAtIG9sZGksIG91dCwgb2xkaSA9PSAwKTtcblxuXHRcdFx0Ly8gYGlgIHdhcyBzdXBwb3NlZCB0byB3cmFwIGFyb3VuZCBmcm9tIGBvdXRgIHRvIGAwYCxcblx0XHRcdC8vIGluY3JlbWVudGluZyBgbmAgZWFjaCB0aW1lLCBzbyB3ZSdsbCBmaXggdGhhdCBub3c6XG5cdFx0XHRpZiAoZmxvb3IoaSAvIG91dCkgPiBtYXhJbnQgLSBuKSB7XG5cdFx0XHRcdGVycm9yKCdvdmVyZmxvdycpO1xuXHRcdFx0fVxuXG5cdFx0XHRuICs9IGZsb29yKGkgLyBvdXQpO1xuXHRcdFx0aSAlPSBvdXQ7XG5cblx0XHRcdC8vIEluc2VydCBgbmAgYXQgcG9zaXRpb24gYGlgIG9mIHRoZSBvdXRwdXRcblx0XHRcdG91dHB1dC5zcGxpY2UoaSsrLCAwLCBuKTtcblxuXHRcdH1cblxuXHRcdHJldHVybiB1Y3MyZW5jb2RlKG91dHB1dCk7XG5cdH1cblxuXHQvKipcblx0ICogQ29udmVydHMgYSBzdHJpbmcgb2YgVW5pY29kZSBzeW1ib2xzIHRvIGEgUHVueWNvZGUgc3RyaW5nIG9mIEFTQ0lJLW9ubHlcblx0ICogc3ltYm9scy5cblx0ICogQG1lbWJlck9mIHB1bnljb2RlXG5cdCAqIEBwYXJhbSB7U3RyaW5nfSBpbnB1dCBUaGUgc3RyaW5nIG9mIFVuaWNvZGUgc3ltYm9scy5cblx0ICogQHJldHVybnMge1N0cmluZ30gVGhlIHJlc3VsdGluZyBQdW55Y29kZSBzdHJpbmcgb2YgQVNDSUktb25seSBzeW1ib2xzLlxuXHQgKi9cblx0ZnVuY3Rpb24gZW5jb2RlKGlucHV0KSB7XG5cdFx0dmFyIG4sXG5cdFx0ICAgIGRlbHRhLFxuXHRcdCAgICBoYW5kbGVkQ1BDb3VudCxcblx0XHQgICAgYmFzaWNMZW5ndGgsXG5cdFx0ICAgIGJpYXMsXG5cdFx0ICAgIGosXG5cdFx0ICAgIG0sXG5cdFx0ICAgIHEsXG5cdFx0ICAgIGssXG5cdFx0ICAgIHQsXG5cdFx0ICAgIGN1cnJlbnRWYWx1ZSxcblx0XHQgICAgb3V0cHV0ID0gW10sXG5cdFx0ICAgIC8qKiBgaW5wdXRMZW5ndGhgIHdpbGwgaG9sZCB0aGUgbnVtYmVyIG9mIGNvZGUgcG9pbnRzIGluIGBpbnB1dGAuICovXG5cdFx0ICAgIGlucHV0TGVuZ3RoLFxuXHRcdCAgICAvKiogQ2FjaGVkIGNhbGN1bGF0aW9uIHJlc3VsdHMgKi9cblx0XHQgICAgaGFuZGxlZENQQ291bnRQbHVzT25lLFxuXHRcdCAgICBiYXNlTWludXNULFxuXHRcdCAgICBxTWludXNUO1xuXG5cdFx0Ly8gQ29udmVydCB0aGUgaW5wdXQgaW4gVUNTLTIgdG8gVW5pY29kZVxuXHRcdGlucHV0ID0gdWNzMmRlY29kZShpbnB1dCk7XG5cblx0XHQvLyBDYWNoZSB0aGUgbGVuZ3RoXG5cdFx0aW5wdXRMZW5ndGggPSBpbnB1dC5sZW5ndGg7XG5cblx0XHQvLyBJbml0aWFsaXplIHRoZSBzdGF0ZVxuXHRcdG4gPSBpbml0aWFsTjtcblx0XHRkZWx0YSA9IDA7XG5cdFx0YmlhcyA9IGluaXRpYWxCaWFzO1xuXG5cdFx0Ly8gSGFuZGxlIHRoZSBiYXNpYyBjb2RlIHBvaW50c1xuXHRcdGZvciAoaiA9IDA7IGogPCBpbnB1dExlbmd0aDsgKytqKSB7XG5cdFx0XHRjdXJyZW50VmFsdWUgPSBpbnB1dFtqXTtcblx0XHRcdGlmIChjdXJyZW50VmFsdWUgPCAweDgwKSB7XG5cdFx0XHRcdG91dHB1dC5wdXNoKHN0cmluZ0Zyb21DaGFyQ29kZShjdXJyZW50VmFsdWUpKTtcblx0XHRcdH1cblx0XHR9XG5cblx0XHRoYW5kbGVkQ1BDb3VudCA9IGJhc2ljTGVuZ3RoID0gb3V0cHV0Lmxlbmd0aDtcblxuXHRcdC8vIGBoYW5kbGVkQ1BDb3VudGAgaXMgdGhlIG51bWJlciBvZiBjb2RlIHBvaW50cyB0aGF0IGhhdmUgYmVlbiBoYW5kbGVkO1xuXHRcdC8vIGBiYXNpY0xlbmd0aGAgaXMgdGhlIG51bWJlciBvZiBiYXNpYyBjb2RlIHBvaW50cy5cblxuXHRcdC8vIEZpbmlzaCB0aGUgYmFzaWMgc3RyaW5nIC0gaWYgaXQgaXMgbm90IGVtcHR5IC0gd2l0aCBhIGRlbGltaXRlclxuXHRcdGlmIChiYXNpY0xlbmd0aCkge1xuXHRcdFx0b3V0cHV0LnB1c2goZGVsaW1pdGVyKTtcblx0XHR9XG5cblx0XHQvLyBNYWluIGVuY29kaW5nIGxvb3A6XG5cdFx0d2hpbGUgKGhhbmRsZWRDUENvdW50IDwgaW5wdXRMZW5ndGgpIHtcblxuXHRcdFx0Ly8gQWxsIG5vbi1iYXNpYyBjb2RlIHBvaW50cyA8IG4gaGF2ZSBiZWVuIGhhbmRsZWQgYWxyZWFkeS4gRmluZCB0aGUgbmV4dFxuXHRcdFx0Ly8gbGFyZ2VyIG9uZTpcblx0XHRcdGZvciAobSA9IG1heEludCwgaiA9IDA7IGogPCBpbnB1dExlbmd0aDsgKytqKSB7XG5cdFx0XHRcdGN1cnJlbnRWYWx1ZSA9IGlucHV0W2pdO1xuXHRcdFx0XHRpZiAoY3VycmVudFZhbHVlID49IG4gJiYgY3VycmVudFZhbHVlIDwgbSkge1xuXHRcdFx0XHRcdG0gPSBjdXJyZW50VmFsdWU7XG5cdFx0XHRcdH1cblx0XHRcdH1cblxuXHRcdFx0Ly8gSW5jcmVhc2UgYGRlbHRhYCBlbm91Z2ggdG8gYWR2YW5jZSB0aGUgZGVjb2RlcidzIDxuLGk+IHN0YXRlIHRvIDxtLDA+LFxuXHRcdFx0Ly8gYnV0IGd1YXJkIGFnYWluc3Qgb3ZlcmZsb3dcblx0XHRcdGhhbmRsZWRDUENvdW50UGx1c09uZSA9IGhhbmRsZWRDUENvdW50ICsgMTtcblx0XHRcdGlmIChtIC0gbiA+IGZsb29yKChtYXhJbnQgLSBkZWx0YSkgLyBoYW5kbGVkQ1BDb3VudFBsdXNPbmUpKSB7XG5cdFx0XHRcdGVycm9yKCdvdmVyZmxvdycpO1xuXHRcdFx0fVxuXG5cdFx0XHRkZWx0YSArPSAobSAtIG4pICogaGFuZGxlZENQQ291bnRQbHVzT25lO1xuXHRcdFx0biA9IG07XG5cblx0XHRcdGZvciAoaiA9IDA7IGogPCBpbnB1dExlbmd0aDsgKytqKSB7XG5cdFx0XHRcdGN1cnJlbnRWYWx1ZSA9IGlucHV0W2pdO1xuXG5cdFx0XHRcdGlmIChjdXJyZW50VmFsdWUgPCBuICYmICsrZGVsdGEgPiBtYXhJbnQpIHtcblx0XHRcdFx0XHRlcnJvcignb3ZlcmZsb3cnKTtcblx0XHRcdFx0fVxuXG5cdFx0XHRcdGlmIChjdXJyZW50VmFsdWUgPT0gbikge1xuXHRcdFx0XHRcdC8vIFJlcHJlc2VudCBkZWx0YSBhcyBhIGdlbmVyYWxpemVkIHZhcmlhYmxlLWxlbmd0aCBpbnRlZ2VyXG5cdFx0XHRcdFx0Zm9yIChxID0gZGVsdGEsIGsgPSBiYXNlOyAvKiBubyBjb25kaXRpb24gKi87IGsgKz0gYmFzZSkge1xuXHRcdFx0XHRcdFx0dCA9IGsgPD0gYmlhcyA/IHRNaW4gOiAoayA+PSBiaWFzICsgdE1heCA/IHRNYXggOiBrIC0gYmlhcyk7XG5cdFx0XHRcdFx0XHRpZiAocSA8IHQpIHtcblx0XHRcdFx0XHRcdFx0YnJlYWs7XG5cdFx0XHRcdFx0XHR9XG5cdFx0XHRcdFx0XHRxTWludXNUID0gcSAtIHQ7XG5cdFx0XHRcdFx0XHRiYXNlTWludXNUID0gYmFzZSAtIHQ7XG5cdFx0XHRcdFx0XHRvdXRwdXQucHVzaChcblx0XHRcdFx0XHRcdFx0c3RyaW5nRnJvbUNoYXJDb2RlKGRpZ2l0VG9CYXNpYyh0ICsgcU1pbnVzVCAlIGJhc2VNaW51c1QsIDApKVxuXHRcdFx0XHRcdFx0KTtcblx0XHRcdFx0XHRcdHEgPSBmbG9vcihxTWludXNUIC8gYmFzZU1pbnVzVCk7XG5cdFx0XHRcdFx0fVxuXG5cdFx0XHRcdFx0b3V0cHV0LnB1c2goc3RyaW5nRnJvbUNoYXJDb2RlKGRpZ2l0VG9CYXNpYyhxLCAwKSkpO1xuXHRcdFx0XHRcdGJpYXMgPSBhZGFwdChkZWx0YSwgaGFuZGxlZENQQ291bnRQbHVzT25lLCBoYW5kbGVkQ1BDb3VudCA9PSBiYXNpY0xlbmd0aCk7XG5cdFx0XHRcdFx0ZGVsdGEgPSAwO1xuXHRcdFx0XHRcdCsraGFuZGxlZENQQ291bnQ7XG5cdFx0XHRcdH1cblx0XHRcdH1cblxuXHRcdFx0KytkZWx0YTtcblx0XHRcdCsrbjtcblxuXHRcdH1cblx0XHRyZXR1cm4gb3V0cHV0LmpvaW4oJycpO1xuXHR9XG5cblx0LyoqXG5cdCAqIENvbnZlcnRzIGEgUHVueWNvZGUgc3RyaW5nIHJlcHJlc2VudGluZyBhIGRvbWFpbiBuYW1lIHRvIFVuaWNvZGUuIE9ubHkgdGhlXG5cdCAqIFB1bnljb2RlZCBwYXJ0cyBvZiB0aGUgZG9tYWluIG5hbWUgd2lsbCBiZSBjb252ZXJ0ZWQsIGkuZS4gaXQgZG9lc24ndFxuXHQgKiBtYXR0ZXIgaWYgeW91IGNhbGwgaXQgb24gYSBzdHJpbmcgdGhhdCBoYXMgYWxyZWFkeSBiZWVuIGNvbnZlcnRlZCB0b1xuXHQgKiBVbmljb2RlLlxuXHQgKiBAbWVtYmVyT2YgcHVueWNvZGVcblx0ICogQHBhcmFtIHtTdHJpbmd9IGRvbWFpbiBUaGUgUHVueWNvZGUgZG9tYWluIG5hbWUgdG8gY29udmVydCB0byBVbmljb2RlLlxuXHQgKiBAcmV0dXJucyB7U3RyaW5nfSBUaGUgVW5pY29kZSByZXByZXNlbnRhdGlvbiBvZiB0aGUgZ2l2ZW4gUHVueWNvZGVcblx0ICogc3RyaW5nLlxuXHQgKi9cblx0ZnVuY3Rpb24gdG9Vbmljb2RlKGRvbWFpbikge1xuXHRcdHJldHVybiBtYXBEb21haW4oZG9tYWluLCBmdW5jdGlvbihzdHJpbmcpIHtcblx0XHRcdHJldHVybiByZWdleFB1bnljb2RlLnRlc3Qoc3RyaW5nKVxuXHRcdFx0XHQ/IGRlY29kZShzdHJpbmcuc2xpY2UoNCkudG9Mb3dlckNhc2UoKSlcblx0XHRcdFx0OiBzdHJpbmc7XG5cdFx0fSk7XG5cdH1cblxuXHQvKipcblx0ICogQ29udmVydHMgYSBVbmljb2RlIHN0cmluZyByZXByZXNlbnRpbmcgYSBkb21haW4gbmFtZSB0byBQdW55Y29kZS4gT25seSB0aGVcblx0ICogbm9uLUFTQ0lJIHBhcnRzIG9mIHRoZSBkb21haW4gbmFtZSB3aWxsIGJlIGNvbnZlcnRlZCwgaS5lLiBpdCBkb2Vzbid0XG5cdCAqIG1hdHRlciBpZiB5b3UgY2FsbCBpdCB3aXRoIGEgZG9tYWluIHRoYXQncyBhbHJlYWR5IGluIEFTQ0lJLlxuXHQgKiBAbWVtYmVyT2YgcHVueWNvZGVcblx0ICogQHBhcmFtIHtTdHJpbmd9IGRvbWFpbiBUaGUgZG9tYWluIG5hbWUgdG8gY29udmVydCwgYXMgYSBVbmljb2RlIHN0cmluZy5cblx0ICogQHJldHVybnMge1N0cmluZ30gVGhlIFB1bnljb2RlIHJlcHJlc2VudGF0aW9uIG9mIHRoZSBnaXZlbiBkb21haW4gbmFtZS5cblx0ICovXG5cdGZ1bmN0aW9uIHRvQVNDSUkoZG9tYWluKSB7XG5cdFx0cmV0dXJuIG1hcERvbWFpbihkb21haW4sIGZ1bmN0aW9uKHN0cmluZykge1xuXHRcdFx0cmV0dXJuIHJlZ2V4Tm9uQVNDSUkudGVzdChzdHJpbmcpXG5cdFx0XHRcdD8gJ3huLS0nICsgZW5jb2RlKHN0cmluZylcblx0XHRcdFx0OiBzdHJpbmc7XG5cdFx0fSk7XG5cdH1cblxuXHQvKi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tKi9cblxuXHQvKiogRGVmaW5lIHRoZSBwdWJsaWMgQVBJICovXG5cdHB1bnljb2RlID0ge1xuXHRcdC8qKlxuXHRcdCAqIEEgc3RyaW5nIHJlcHJlc2VudGluZyB0aGUgY3VycmVudCBQdW55Y29kZS5qcyB2ZXJzaW9uIG51bWJlci5cblx0XHQgKiBAbWVtYmVyT2YgcHVueWNvZGVcblx0XHQgKiBAdHlwZSBTdHJpbmdcblx0XHQgKi9cblx0XHQndmVyc2lvbic6ICcxLjIuNCcsXG5cdFx0LyoqXG5cdFx0ICogQW4gb2JqZWN0IG9mIG1ldGhvZHMgdG8gY29udmVydCBmcm9tIEphdmFTY3JpcHQncyBpbnRlcm5hbCBjaGFyYWN0ZXJcblx0XHQgKiByZXByZXNlbnRhdGlvbiAoVUNTLTIpIHRvIFVuaWNvZGUgY29kZSBwb2ludHMsIGFuZCBiYWNrLlxuXHRcdCAqIEBzZWUgPGh0dHA6Ly9tYXRoaWFzYnluZW5zLmJlL25vdGVzL2phdmFzY3JpcHQtZW5jb2Rpbmc+XG5cdFx0ICogQG1lbWJlck9mIHB1bnljb2RlXG5cdFx0ICogQHR5cGUgT2JqZWN0XG5cdFx0ICovXG5cdFx0J3VjczInOiB7XG5cdFx0XHQnZGVjb2RlJzogdWNzMmRlY29kZSxcblx0XHRcdCdlbmNvZGUnOiB1Y3MyZW5jb2RlXG5cdFx0fSxcblx0XHQnZGVjb2RlJzogZGVjb2RlLFxuXHRcdCdlbmNvZGUnOiBlbmNvZGUsXG5cdFx0J3RvQVNDSUknOiB0b0FTQ0lJLFxuXHRcdCd0b1VuaWNvZGUnOiB0b1VuaWNvZGVcblx0fTtcblxuXHQvKiogRXhwb3NlIGBwdW55Y29kZWAgKi9cblx0Ly8gU29tZSBBTUQgYnVpbGQgb3B0aW1pemVycywgbGlrZSByLmpzLCBjaGVjayBmb3Igc3BlY2lmaWMgY29uZGl0aW9uIHBhdHRlcm5zXG5cdC8vIGxpa2UgdGhlIGZvbGxvd2luZzpcblx0aWYgKFxuXHRcdHR5cGVvZiBkZWZpbmUgPT0gJ2Z1bmN0aW9uJyAmJlxuXHRcdHR5cGVvZiBkZWZpbmUuYW1kID09ICdvYmplY3QnICYmXG5cdFx0ZGVmaW5lLmFtZFxuXHQpIHtcblx0XHRkZWZpbmUoJ3B1bnljb2RlJywgZnVuY3Rpb24oKSB7XG5cdFx0XHRyZXR1cm4gcHVueWNvZGU7XG5cdFx0fSk7XG5cdH0gZWxzZSBpZiAoZnJlZUV4cG9ydHMgJiYgIWZyZWVFeHBvcnRzLm5vZGVUeXBlKSB7XG5cdFx0aWYgKGZyZWVNb2R1bGUpIHsgLy8gaW4gTm9kZS5qcyBvciBSaW5nb0pTIHYwLjguMCtcblx0XHRcdGZyZWVNb2R1bGUuZXhwb3J0cyA9IHB1bnljb2RlO1xuXHRcdH0gZWxzZSB7IC8vIGluIE5hcndoYWwgb3IgUmluZ29KUyB2MC43LjAtXG5cdFx0XHRmb3IgKGtleSBpbiBwdW55Y29kZSkge1xuXHRcdFx0XHRwdW55Y29kZS5oYXNPd25Qcm9wZXJ0eShrZXkpICYmIChmcmVlRXhwb3J0c1trZXldID0gcHVueWNvZGVba2V5XSk7XG5cdFx0XHR9XG5cdFx0fVxuXHR9IGVsc2UgeyAvLyBpbiBSaGlubyBvciBhIHdlYiBicm93c2VyXG5cdFx0cm9vdC5wdW55Y29kZSA9IHB1bnljb2RlO1xuXHR9XG5cbn0odGhpcykpO1xuXG59KS5jYWxsKHRoaXMsdHlwZW9mIGdsb2JhbCAhPT0gXCJ1bmRlZmluZWRcIiA/IGdsb2JhbCA6IHR5cGVvZiBzZWxmICE9PSBcInVuZGVmaW5lZFwiID8gc2VsZiA6IHR5cGVvZiB3aW5kb3cgIT09IFwidW5kZWZpbmVkXCIgPyB3aW5kb3cgOiB7fSlcbi8vIyBzb3VyY2VNYXBwaW5nVVJMPWRhdGE6YXBwbGljYXRpb24vanNvbjtjaGFyc2V0OnV0Zi04O2Jhc2U2NCxleUoyWlhKemFXOXVJam96TENKemIzVnlZMlZ6SWpwYkltNXZaR1ZmYlc5a2RXeGxjeTlpY205M2MyVnlhV1o1TDI1dlpHVmZiVzlrZFd4bGN5OXdkVzU1WTI5a1pTOXdkVzU1WTI5a1pTNXFjeUpkTENKdVlXMWxjeUk2VzEwc0ltMWhjSEJwYm1keklqb2lPMEZCUVVFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEVpTENKbWFXeGxJam9pWjJWdVpYSmhkR1ZrTG1weklpd2ljMjkxY21ObFVtOXZkQ0k2SWlJc0luTnZkWEpqWlhORGIyNTBaVzUwSWpwYklpOHFJU0JvZEhSd09pOHZiWFJvY3k1aVpTOXdkVzU1WTI5a1pTQjJNUzR5TGpRZ1lua2dRRzFoZEdocFlYTWdLaTljYmpzb1puVnVZM1JwYjI0b2NtOXZkQ2tnZTF4dVhHNWNkQzhxS2lCRVpYUmxZM1FnWm5KbFpTQjJZWEpwWVdKc1pYTWdLaTljYmx4MGRtRnlJR1p5WldWRmVIQnZjblJ6SUQwZ2RIbHdaVzltSUdWNGNHOXlkSE1nUFQwZ0oyOWlhbVZqZENjZ0ppWWdaWGh3YjNKMGN6dGNibHgwZG1GeUlHWnlaV1ZOYjJSMWJHVWdQU0IwZVhCbGIyWWdiVzlrZFd4bElEMDlJQ2R2WW1wbFkzUW5JQ1ltSUcxdlpIVnNaU0FtSmx4dVhIUmNkRzF2WkhWc1pTNWxlSEJ2Y25SeklEMDlJR1p5WldWRmVIQnZjblJ6SUNZbUlHMXZaSFZzWlR0Y2JseDBkbUZ5SUdaeVpXVkhiRzlpWVd3Z1BTQjBlWEJsYjJZZ1oyeHZZbUZzSUQwOUlDZHZZbXBsWTNRbklDWW1JR2RzYjJKaGJEdGNibHgwYVdZZ0tHWnlaV1ZIYkc5aVlXd3VaMnh2WW1Gc0lEMDlQU0JtY21WbFIyeHZZbUZzSUh4OElHWnlaV1ZIYkc5aVlXd3VkMmx1Wkc5M0lEMDlQU0JtY21WbFIyeHZZbUZzS1NCN1hHNWNkRngwY205dmRDQTlJR1p5WldWSGJHOWlZV3c3WEc1Y2RIMWNibHh1WEhRdktpcGNibHgwSUNvZ1ZHaGxJR0J3ZFc1NVkyOWtaV0FnYjJKcVpXTjBMbHh1WEhRZ0tpQkFibUZ0WlNCd2RXNTVZMjlrWlZ4dVhIUWdLaUJBZEhsd1pTQlBZbXBsWTNSY2JseDBJQ292WEc1Y2RIWmhjaUJ3ZFc1NVkyOWtaU3hjYmx4dVhIUXZLaW9nU0dsbmFHVnpkQ0J3YjNOcGRHbDJaU0J6YVdkdVpXUWdNekl0WW1sMElHWnNiMkYwSUhaaGJIVmxJQ292WEc1Y2RHMWhlRWx1ZENBOUlESXhORGMwT0RNMk5EY3NJQzh2SUdGcllTNGdNSGczUmtaR1JrWkdSaUJ2Y2lBeVhqTXhMVEZjYmx4dVhIUXZLaW9nUW05dmRITjBjbWx1WnlCd1lYSmhiV1YwWlhKeklDb3ZYRzVjZEdKaGMyVWdQU0F6Tml4Y2JseDBkRTFwYmlBOUlERXNYRzVjZEhSTllYZ2dQU0F5Tml4Y2JseDBjMnRsZHlBOUlETTRMRnh1WEhSa1lXMXdJRDBnTnpBd0xGeHVYSFJwYm1sMGFXRnNRbWxoY3lBOUlEY3lMRnh1WEhScGJtbDBhV0ZzVGlBOUlERXlPQ3dnTHk4Z01IZzRNRnh1WEhSa1pXeHBiV2wwWlhJZ1BTQW5MU2NzSUM4dklDZGNYSGd5UkNkY2JseHVYSFF2S2lvZ1VtVm5kV3hoY2lCbGVIQnlaWE56YVc5dWN5QXFMMXh1WEhSeVpXZGxlRkIxYm5samIyUmxJRDBnTDE1NGJpMHRMeXhjYmx4MGNtVm5aWGhPYjI1QlUwTkpTU0E5SUM5YlhpQXRmbDB2TENBdkx5QjFibkJ5YVc1MFlXSnNaU0JCVTBOSlNTQmphR0Z5Y3lBcklHNXZiaTFCVTBOSlNTQmphR0Z5YzF4dVhIUnlaV2RsZUZObGNHRnlZWFJ2Y25NZ1BTQXZYRng0TWtWOFhGeDFNekF3TW54Y1hIVkdSakJGZkZ4Y2RVWkdOakV2Wnl3Z0x5OGdVa1pESURNME9UQWdjMlZ3WVhKaGRHOXljMXh1WEc1Y2RDOHFLaUJGY25KdmNpQnRaWE56WVdkbGN5QXFMMXh1WEhSbGNuSnZjbk1nUFNCN1hHNWNkRngwSjI5MlpYSm1iRzkzSnpvZ0owOTJaWEptYkc5M09pQnBibkIxZENCdVpXVmtjeUIzYVdSbGNpQnBiblJsWjJWeWN5QjBieUJ3Y205alpYTnpKeXhjYmx4MFhIUW5ibTkwTFdKaGMybGpKem9nSjBsc2JHVm5ZV3dnYVc1d2RYUWdQajBnTUhnNE1DQW9ibTkwSUdFZ1ltRnphV01nWTI5a1pTQndiMmx1ZENrbkxGeHVYSFJjZENkcGJuWmhiR2xrTFdsdWNIVjBKem9nSjBsdWRtRnNhV1FnYVc1d2RYUW5YRzVjZEgwc1hHNWNibHgwTHlvcUlFTnZiblpsYm1sbGJtTmxJSE5vYjNKMFkzVjBjeUFxTDF4dVhIUmlZWE5sVFdsdWRYTlVUV2x1SUQwZ1ltRnpaU0F0SUhSTmFXNHNYRzVjZEdac2IyOXlJRDBnVFdGMGFDNW1iRzl2Y2l4Y2JseDBjM1J5YVc1blJuSnZiVU5vWVhKRGIyUmxJRDBnVTNSeWFXNW5MbVp5YjIxRGFHRnlRMjlrWlN4Y2JseHVYSFF2S2lvZ1ZHVnRjRzl5WVhKNUlIWmhjbWxoWW14bElDb3ZYRzVjZEd0bGVUdGNibHh1WEhRdktpMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRLaTljYmx4dVhIUXZLaXBjYmx4MElDb2dRU0JuWlc1bGNtbGpJR1Z5Y205eUlIVjBhV3hwZEhrZ1puVnVZM1JwYjI0dVhHNWNkQ0FxSUVCd2NtbDJZWFJsWEc1Y2RDQXFJRUJ3WVhKaGJTQjdVM1J5YVc1bmZTQjBlWEJsSUZSb1pTQmxjbkp2Y2lCMGVYQmxMbHh1WEhRZ0tpQkFjbVYwZFhKdWN5QjdSWEp5YjNKOUlGUm9jbTkzY3lCaElHQlNZVzVuWlVWeWNtOXlZQ0IzYVhSb0lIUm9aU0JoY0hCc2FXTmhZbXhsSUdWeWNtOXlJRzFsYzNOaFoyVXVYRzVjZENBcUwxeHVYSFJtZFc1amRHbHZiaUJsY25KdmNpaDBlWEJsS1NCN1hHNWNkRngwZEdoeWIzY2dVbUZ1WjJWRmNuSnZjaWhsY25KdmNuTmJkSGx3WlYwcE8xeHVYSFI5WEc1Y2JseDBMeW9xWEc1Y2RDQXFJRUVnWjJWdVpYSnBZeUJnUVhKeVlYa2piV0Z3WUNCMWRHbHNhWFI1SUdaMWJtTjBhVzl1TGx4dVhIUWdLaUJBY0hKcGRtRjBaVnh1WEhRZ0tpQkFjR0Z5WVcwZ2UwRnljbUY1ZlNCaGNuSmhlU0JVYUdVZ1lYSnlZWGtnZEc4Z2FYUmxjbUYwWlNCdmRtVnlMbHh1WEhRZ0tpQkFjR0Z5WVcwZ2UwWjFibU4wYVc5dWZTQmpZV3hzWW1GamF5QlVhR1VnWm5WdVkzUnBiMjRnZEdoaGRDQm5aWFJ6SUdOaGJHeGxaQ0JtYjNJZ1pYWmxjbmtnWVhKeVlYbGNibHgwSUNvZ2FYUmxiUzVjYmx4MElDb2dRSEpsZEhWeWJuTWdlMEZ5Y21GNWZTQkJJRzVsZHlCaGNuSmhlU0J2WmlCMllXeDFaWE1nY21WMGRYSnVaV1FnWW5rZ2RHaGxJR05oYkd4aVlXTnJJR1oxYm1OMGFXOXVMbHh1WEhRZ0tpOWNibHgwWm5WdVkzUnBiMjRnYldGd0tHRnljbUY1TENCbWJpa2dlMXh1WEhSY2RIWmhjaUJzWlc1bmRHZ2dQU0JoY25KaGVTNXNaVzVuZEdnN1hHNWNkRngwZDJocGJHVWdLR3hsYm1kMGFDMHRLU0I3WEc1Y2RGeDBYSFJoY25KaGVWdHNaVzVuZEdoZElEMGdabTRvWVhKeVlYbGJiR1Z1WjNSb1hTazdYRzVjZEZ4MGZWeHVYSFJjZEhKbGRIVnliaUJoY25KaGVUdGNibHgwZlZ4dVhHNWNkQzhxS2x4dVhIUWdLaUJCSUhOcGJYQnNaU0JnUVhKeVlYa2piV0Z3WUMxc2FXdGxJSGR5WVhCd1pYSWdkRzhnZDI5eWF5QjNhWFJvSUdSdmJXRnBiaUJ1WVcxbElITjBjbWx1WjNNdVhHNWNkQ0FxSUVCd2NtbDJZWFJsWEc1Y2RDQXFJRUJ3WVhKaGJTQjdVM1J5YVc1bmZTQmtiMjFoYVc0Z1ZHaGxJR1J2YldGcGJpQnVZVzFsTGx4dVhIUWdLaUJBY0dGeVlXMGdlMFoxYm1OMGFXOXVmU0JqWVd4c1ltRmpheUJVYUdVZ1puVnVZM1JwYjI0Z2RHaGhkQ0JuWlhSeklHTmhiR3hsWkNCbWIzSWdaWFpsY25sY2JseDBJQ29nWTJoaGNtRmpkR1Z5TGx4dVhIUWdLaUJBY21WMGRYSnVjeUI3UVhKeVlYbDlJRUVnYm1WM0lITjBjbWx1WnlCdlppQmphR0Z5WVdOMFpYSnpJSEpsZEhWeWJtVmtJR0o1SUhSb1pTQmpZV3hzWW1GamExeHVYSFFnS2lCbWRXNWpkR2x2Ymk1Y2JseDBJQ292WEc1Y2RHWjFibU4wYVc5dUlHMWhjRVJ2YldGcGJpaHpkSEpwYm1jc0lHWnVLU0I3WEc1Y2RGeDBjbVYwZFhKdUlHMWhjQ2h6ZEhKcGJtY3VjM0JzYVhRb2NtVm5aWGhUWlhCaGNtRjBiM0p6S1N3Z1ptNHBMbXB2YVc0b0p5NG5LVHRjYmx4MGZWeHVYRzVjZEM4cUtseHVYSFFnS2lCRGNtVmhkR1Z6SUdGdUlHRnljbUY1SUdOdmJuUmhhVzVwYm1jZ2RHaGxJRzUxYldWeWFXTWdZMjlrWlNCd2IybHVkSE1nYjJZZ1pXRmphQ0JWYm1samIyUmxYRzVjZENBcUlHTm9ZWEpoWTNSbGNpQnBiaUIwYUdVZ2MzUnlhVzVuTGlCWGFHbHNaU0JLWVhaaFUyTnlhWEIwSUhWelpYTWdWVU5UTFRJZ2FXNTBaWEp1WVd4c2VTeGNibHgwSUNvZ2RHaHBjeUJtZFc1amRHbHZiaUIzYVd4c0lHTnZiblpsY25RZ1lTQndZV2x5SUc5bUlITjFjbkp2WjJGMFpTQm9ZV3gyWlhNZ0tHVmhZMmdnYjJZZ2QyaHBZMmhjYmx4MElDb2dWVU5UTFRJZ1pYaHdiM05sY3lCaGN5QnpaWEJoY21GMFpTQmphR0Z5WVdOMFpYSnpLU0JwYm5SdklHRWdjMmx1WjJ4bElHTnZaR1VnY0c5cGJuUXNYRzVjZENBcUlHMWhkR05vYVc1bklGVlVSaTB4Tmk1Y2JseDBJQ29nUUhObFpTQmdjSFZ1ZVdOdlpHVXVkV056TWk1bGJtTnZaR1ZnWEc1Y2RDQXFJRUJ6WldVZ1BHaDBkSEE2THk5dFlYUm9hV0Z6WW5sdVpXNXpMbUpsTDI1dmRHVnpMMnBoZG1GelkzSnBjSFF0Wlc1amIyUnBibWMrWEc1Y2RDQXFJRUJ0WlcxaVpYSlBaaUJ3ZFc1NVkyOWtaUzUxWTNNeVhHNWNkQ0FxSUVCdVlXMWxJR1JsWTI5a1pWeHVYSFFnS2lCQWNHRnlZVzBnZTFOMGNtbHVaMzBnYzNSeWFXNW5JRlJvWlNCVmJtbGpiMlJsSUdsdWNIVjBJSE4wY21sdVp5QW9WVU5UTFRJcExseHVYSFFnS2lCQWNtVjBkWEp1Y3lCN1FYSnlZWGw5SUZSb1pTQnVaWGNnWVhKeVlYa2diMllnWTI5a1pTQndiMmx1ZEhNdVhHNWNkQ0FxTDF4dVhIUm1kVzVqZEdsdmJpQjFZM015WkdWamIyUmxLSE4wY21sdVp5a2dlMXh1WEhSY2RIWmhjaUJ2ZFhSd2RYUWdQU0JiWFN4Y2JseDBYSFFnSUNBZ1kyOTFiblJsY2lBOUlEQXNYRzVjZEZ4MElDQWdJR3hsYm1kMGFDQTlJSE4wY21sdVp5NXNaVzVuZEdnc1hHNWNkRngwSUNBZ0lIWmhiSFZsTEZ4dVhIUmNkQ0FnSUNCbGVIUnlZVHRjYmx4MFhIUjNhR2xzWlNBb1kyOTFiblJsY2lBOElHeGxibWQwYUNrZ2UxeHVYSFJjZEZ4MGRtRnNkV1VnUFNCemRISnBibWN1WTJoaGNrTnZaR1ZCZENoamIzVnVkR1Z5S3lzcE8xeHVYSFJjZEZ4MGFXWWdLSFpoYkhWbElENDlJREI0UkRnd01DQW1KaUIyWVd4MVpTQThQU0F3ZUVSQ1JrWWdKaVlnWTI5MWJuUmxjaUE4SUd4bGJtZDBhQ2tnZTF4dVhIUmNkRngwWEhRdkx5Qm9hV2RvSUhOMWNuSnZaMkYwWlN3Z1lXNWtJSFJvWlhKbElHbHpJR0VnYm1WNGRDQmphR0Z5WVdOMFpYSmNibHgwWEhSY2RGeDBaWGgwY21FZ1BTQnpkSEpwYm1jdVkyaGhja052WkdWQmRDaGpiM1Z1ZEdWeUt5c3BPMXh1WEhSY2RGeDBYSFJwWmlBb0tHVjRkSEpoSUNZZ01IaEdRekF3S1NBOVBTQXdlRVJETURBcElIc2dMeThnYkc5M0lITjFjbkp2WjJGMFpWeHVYSFJjZEZ4MFhIUmNkRzkxZEhCMWRDNXdkWE5vS0Nnb2RtRnNkV1VnSmlBd2VETkdSaWtnUER3Z01UQXBJQ3NnS0dWNGRISmhJQ1lnTUhnelJrWXBJQ3NnTUhneE1EQXdNQ2s3WEc1Y2RGeDBYSFJjZEgwZ1pXeHpaU0I3WEc1Y2RGeDBYSFJjZEZ4MEx5OGdkVzV0WVhSamFHVmtJSE4xY25KdloyRjBaVHNnYjI1c2VTQmhjSEJsYm1RZ2RHaHBjeUJqYjJSbElIVnVhWFFzSUdsdUlHTmhjMlVnZEdobElHNWxlSFJjYmx4MFhIUmNkRngwWEhRdkx5QmpiMlJsSUhWdWFYUWdhWE1nZEdobElHaHBaMmdnYzNWeWNtOW5ZWFJsSUc5bUlHRWdjM1Z5Y205bllYUmxJSEJoYVhKY2JseDBYSFJjZEZ4MFhIUnZkWFJ3ZFhRdWNIVnphQ2gyWVd4MVpTazdYRzVjZEZ4MFhIUmNkRngwWTI5MWJuUmxjaTB0TzF4dVhIUmNkRngwWEhSOVhHNWNkRngwWEhSOUlHVnNjMlVnZTF4dVhIUmNkRngwWEhSdmRYUndkWFF1Y0hWemFDaDJZV3gxWlNrN1hHNWNkRngwWEhSOVhHNWNkRngwZlZ4dVhIUmNkSEpsZEhWeWJpQnZkWFJ3ZFhRN1hHNWNkSDFjYmx4dVhIUXZLaXBjYmx4MElDb2dRM0psWVhSbGN5QmhJSE4wY21sdVp5QmlZWE5sWkNCdmJpQmhiaUJoY25KaGVTQnZaaUJ1ZFcxbGNtbGpJR052WkdVZ2NHOXBiblJ6TGx4dVhIUWdLaUJBYzJWbElHQndkVzU1WTI5a1pTNTFZM015TG1SbFkyOWtaV0JjYmx4MElDb2dRRzFsYldKbGNrOW1JSEIxYm5samIyUmxMblZqY3pKY2JseDBJQ29nUUc1aGJXVWdaVzVqYjJSbFhHNWNkQ0FxSUVCd1lYSmhiU0I3UVhKeVlYbDlJR052WkdWUWIybHVkSE1nVkdobElHRnljbUY1SUc5bUlHNTFiV1Z5YVdNZ1kyOWtaU0J3YjJsdWRITXVYRzVjZENBcUlFQnlaWFIxY201eklIdFRkSEpwYm1kOUlGUm9aU0J1WlhjZ1ZXNXBZMjlrWlNCemRISnBibWNnS0ZWRFV5MHlLUzVjYmx4MElDb3ZYRzVjZEdaMWJtTjBhVzl1SUhWamN6SmxibU52WkdVb1lYSnlZWGtwSUh0Y2JseDBYSFJ5WlhSMWNtNGdiV0Z3S0dGeWNtRjVMQ0JtZFc1amRHbHZiaWgyWVd4MVpTa2dlMXh1WEhSY2RGeDBkbUZ5SUc5MWRIQjFkQ0E5SUNjbk8xeHVYSFJjZEZ4MGFXWWdLSFpoYkhWbElENGdNSGhHUmtaR0tTQjdYRzVjZEZ4MFhIUmNkSFpoYkhWbElDMDlJREI0TVRBd01EQTdYRzVjZEZ4MFhIUmNkRzkxZEhCMWRDQXJQU0J6ZEhKcGJtZEdjbTl0UTJoaGNrTnZaR1VvZG1Gc2RXVWdQajQrSURFd0lDWWdNSGd6UmtZZ2ZDQXdlRVE0TURBcE8xeHVYSFJjZEZ4MFhIUjJZV3gxWlNBOUlEQjRSRU13TUNCOElIWmhiSFZsSUNZZ01IZ3pSa1k3WEc1Y2RGeDBYSFI5WEc1Y2RGeDBYSFJ2ZFhSd2RYUWdLejBnYzNSeWFXNW5Sbkp2YlVOb1lYSkRiMlJsS0haaGJIVmxLVHRjYmx4MFhIUmNkSEpsZEhWeWJpQnZkWFJ3ZFhRN1hHNWNkRngwZlNrdWFtOXBiaWduSnlrN1hHNWNkSDFjYmx4dVhIUXZLaXBjYmx4MElDb2dRMjl1ZG1WeWRITWdZU0JpWVhOcFl5QmpiMlJsSUhCdmFXNTBJR2x1ZEc4Z1lTQmthV2RwZEM5cGJuUmxaMlZ5TGx4dVhIUWdLaUJBYzJWbElHQmthV2RwZEZSdlFtRnphV01vS1dCY2JseDBJQ29nUUhCeWFYWmhkR1ZjYmx4MElDb2dRSEJoY21GdElIdE9kVzFpWlhKOUlHTnZaR1ZRYjJsdWRDQlVhR1VnWW1GemFXTWdiblZ0WlhKcFl5QmpiMlJsSUhCdmFXNTBJSFpoYkhWbExseHVYSFFnS2lCQWNtVjBkWEp1Y3lCN1RuVnRZbVZ5ZlNCVWFHVWdiblZ0WlhKcFl5QjJZV3gxWlNCdlppQmhJR0poYzJsaklHTnZaR1VnY0c5cGJuUWdLR1p2Y2lCMWMyVWdhVzVjYmx4MElDb2djbVZ3Y21WelpXNTBhVzVuSUdsdWRHVm5aWEp6S1NCcGJpQjBhR1VnY21GdVoyVWdZREJnSUhSdklHQmlZWE5sSUMwZ01XQXNJRzl5SUdCaVlYTmxZQ0JwWmx4dVhIUWdLaUIwYUdVZ1kyOWtaU0J3YjJsdWRDQmtiMlZ6SUc1dmRDQnlaWEJ5WlhObGJuUWdZU0IyWVd4MVpTNWNibHgwSUNvdlhHNWNkR1oxYm1OMGFXOXVJR0poYzJsalZHOUVhV2RwZENoamIyUmxVRzlwYm5RcElIdGNibHgwWEhScFppQW9ZMjlrWlZCdmFXNTBJQzBnTkRnZ1BDQXhNQ2tnZTF4dVhIUmNkRngwY21WMGRYSnVJR052WkdWUWIybHVkQ0F0SURJeU8xeHVYSFJjZEgxY2JseDBYSFJwWmlBb1kyOWtaVkJ2YVc1MElDMGdOalVnUENBeU5pa2dlMXh1WEhSY2RGeDBjbVYwZFhKdUlHTnZaR1ZRYjJsdWRDQXRJRFkxTzF4dVhIUmNkSDFjYmx4MFhIUnBaaUFvWTI5a1pWQnZhVzUwSUMwZ09UY2dQQ0F5TmlrZ2UxeHVYSFJjZEZ4MGNtVjBkWEp1SUdOdlpHVlFiMmx1ZENBdElEazNPMXh1WEhSY2RIMWNibHgwWEhSeVpYUjFjbTRnWW1GelpUdGNibHgwZlZ4dVhHNWNkQzhxS2x4dVhIUWdLaUJEYjI1MlpYSjBjeUJoSUdScFoybDBMMmx1ZEdWblpYSWdhVzUwYnlCaElHSmhjMmxqSUdOdlpHVWdjRzlwYm5RdVhHNWNkQ0FxSUVCelpXVWdZR0poYzJsalZHOUVhV2RwZENncFlGeHVYSFFnS2lCQWNISnBkbUYwWlZ4dVhIUWdLaUJBY0dGeVlXMGdlMDUxYldKbGNuMGdaR2xuYVhRZ1ZHaGxJRzUxYldWeWFXTWdkbUZzZFdVZ2IyWWdZU0JpWVhOcFl5QmpiMlJsSUhCdmFXNTBMbHh1WEhRZ0tpQkFjbVYwZFhKdWN5QjdUblZ0WW1WeWZTQlVhR1VnWW1GemFXTWdZMjlrWlNCd2IybHVkQ0IzYUc5elpTQjJZV3gxWlNBb2QyaGxiaUIxYzJWa0lHWnZjbHh1WEhRZ0tpQnlaWEJ5WlhObGJuUnBibWNnYVc1MFpXZGxjbk1wSUdseklHQmthV2RwZEdBc0lIZG9hV05vSUc1bFpXUnpJSFJ2SUdKbElHbHVJSFJvWlNCeVlXNW5aVnh1WEhRZ0tpQmdNR0FnZEc4Z1lHSmhjMlVnTFNBeFlDNGdTV1lnWUdac1lXZGdJR2x6SUc1dmJpMTZaWEp2TENCMGFHVWdkWEJ3WlhKallYTmxJR1p2Y20wZ2FYTmNibHgwSUNvZ2RYTmxaRHNnWld4elpTd2dkR2hsSUd4dmQyVnlZMkZ6WlNCbWIzSnRJR2x6SUhWelpXUXVJRlJvWlNCaVpXaGhkbWx2Y2lCcGN5QjFibVJsWm1sdVpXUmNibHgwSUNvZ2FXWWdZR1pzWVdkZ0lHbHpJRzV2YmkxNlpYSnZJR0Z1WkNCZ1pHbG5hWFJnSUdoaGN5QnVieUIxY0hCbGNtTmhjMlVnWm05eWJTNWNibHgwSUNvdlhHNWNkR1oxYm1OMGFXOXVJR1JwWjJsMFZHOUNZWE5wWXloa2FXZHBkQ3dnWm14aFp5a2dlMXh1WEhSY2RDOHZJQ0F3TGk0eU5TQnRZWEFnZEc4Z1FWTkRTVWtnWVM0dWVpQnZjaUJCTGk1YVhHNWNkRngwTHk4Z01qWXVMak0xSUcxaGNDQjBieUJCVTBOSlNTQXdMaTQ1WEc1Y2RGeDBjbVYwZFhKdUlHUnBaMmwwSUNzZ01qSWdLeUEzTlNBcUlDaGthV2RwZENBOElESTJLU0F0SUNnb1pteGhaeUFoUFNBd0tTQThQQ0ExS1R0Y2JseDBmVnh1WEc1Y2RDOHFLbHh1WEhRZ0tpQkNhV0Z6SUdGa1lYQjBZWFJwYjI0Z1puVnVZM1JwYjI0Z1lYTWdjR1Z5SUhObFkzUnBiMjRnTXk0MElHOW1JRkpHUXlBek5Ea3lMbHh1WEhRZ0tpQm9kSFJ3T2k4dmRHOXZiSE11YVdWMFppNXZjbWN2YUhSdGJDOXlabU16TkRreUkzTmxZM1JwYjI0dE15NDBYRzVjZENBcUlFQndjbWwyWVhSbFhHNWNkQ0FxTDF4dVhIUm1kVzVqZEdsdmJpQmhaR0Z3ZENoa1pXeDBZU3dnYm5WdFVHOXBiblJ6TENCbWFYSnpkRlJwYldVcElIdGNibHgwWEhSMllYSWdheUE5SURBN1hHNWNkRngwWkdWc2RHRWdQU0JtYVhKemRGUnBiV1VnUHlCbWJHOXZjaWhrWld4MFlTQXZJR1JoYlhBcElEb2daR1ZzZEdFZ1BqNGdNVHRjYmx4MFhIUmtaV3gwWVNBclBTQm1iRzl2Y2loa1pXeDBZU0F2SUc1MWJWQnZhVzUwY3lrN1hHNWNkRngwWm05eUlDZ3ZLaUJ1YnlCcGJtbDBhV0ZzYVhwaGRHbHZiaUFxTHpzZ1pHVnNkR0VnUGlCaVlYTmxUV2x1ZFhOVVRXbHVJQ29nZEUxaGVDQStQaUF4T3lCcklDczlJR0poYzJVcElIdGNibHgwWEhSY2RHUmxiSFJoSUQwZ1pteHZiM0lvWkdWc2RHRWdMeUJpWVhObFRXbHVkWE5VVFdsdUtUdGNibHgwWEhSOVhHNWNkRngwY21WMGRYSnVJR1pzYjI5eUtHc2dLeUFvWW1GelpVMXBiblZ6VkUxcGJpQXJJREVwSUNvZ1pHVnNkR0VnTHlBb1pHVnNkR0VnS3lCemEyVjNLU2s3WEc1Y2RIMWNibHh1WEhRdktpcGNibHgwSUNvZ1EyOXVkbVZ5ZEhNZ1lTQlFkVzU1WTI5a1pTQnpkSEpwYm1jZ2IyWWdRVk5EU1VrdGIyNXNlU0J6ZVcxaWIyeHpJSFJ2SUdFZ2MzUnlhVzVuSUc5bUlGVnVhV052WkdWY2JseDBJQ29nYzNsdFltOXNjeTVjYmx4MElDb2dRRzFsYldKbGNrOW1JSEIxYm5samIyUmxYRzVjZENBcUlFQndZWEpoYlNCN1UzUnlhVzVuZlNCcGJuQjFkQ0JVYUdVZ1VIVnVlV052WkdVZ2MzUnlhVzVuSUc5bUlFRlRRMGxKTFc5dWJIa2djM2x0WW05c2N5NWNibHgwSUNvZ1FISmxkSFZ5Ym5NZ2UxTjBjbWx1WjMwZ1ZHaGxJSEpsYzNWc2RHbHVaeUJ6ZEhKcGJtY2diMllnVlc1cFkyOWtaU0J6ZVcxaWIyeHpMbHh1WEhRZ0tpOWNibHgwWm5WdVkzUnBiMjRnWkdWamIyUmxLR2x1Y0hWMEtTQjdYRzVjZEZ4MEx5OGdSRzl1SjNRZ2RYTmxJRlZEVXkweVhHNWNkRngwZG1GeUlHOTFkSEIxZENBOUlGdGRMRnh1WEhSY2RDQWdJQ0JwYm5CMWRFeGxibWQwYUNBOUlHbHVjSFYwTG14bGJtZDBhQ3hjYmx4MFhIUWdJQ0FnYjNWMExGeHVYSFJjZENBZ0lDQnBJRDBnTUN4Y2JseDBYSFFnSUNBZ2JpQTlJR2x1YVhScFlXeE9MRnh1WEhSY2RDQWdJQ0JpYVdGeklEMGdhVzVwZEdsaGJFSnBZWE1zWEc1Y2RGeDBJQ0FnSUdKaGMybGpMRnh1WEhSY2RDQWdJQ0JxTEZ4dVhIUmNkQ0FnSUNCcGJtUmxlQ3hjYmx4MFhIUWdJQ0FnYjJ4a2FTeGNibHgwWEhRZ0lDQWdkeXhjYmx4MFhIUWdJQ0FnYXl4Y2JseDBYSFFnSUNBZ1pHbG5hWFFzWEc1Y2RGeDBJQ0FnSUhRc1hHNWNkRngwSUNBZ0lDOHFLaUJEWVdOb1pXUWdZMkZzWTNWc1lYUnBiMjRnY21WemRXeDBjeUFxTDF4dVhIUmNkQ0FnSUNCaVlYTmxUV2x1ZFhOVU8xeHVYRzVjZEZ4MEx5OGdTR0Z1Wkd4bElIUm9aU0JpWVhOcFl5QmpiMlJsSUhCdmFXNTBjem9nYkdWMElHQmlZWE5wWTJBZ1ltVWdkR2hsSUc1MWJXSmxjaUJ2WmlCcGJuQjFkQ0JqYjJSbFhHNWNkRngwTHk4Z2NHOXBiblJ6SUdKbFptOXlaU0IwYUdVZ2JHRnpkQ0JrWld4cGJXbDBaWElzSUc5eUlHQXdZQ0JwWmlCMGFHVnlaU0JwY3lCdWIyNWxMQ0IwYUdWdUlHTnZjSGxjYmx4MFhIUXZMeUIwYUdVZ1ptbHljM1FnWW1GemFXTWdZMjlrWlNCd2IybHVkSE1nZEc4Z2RHaGxJRzkxZEhCMWRDNWNibHh1WEhSY2RHSmhjMmxqSUQwZ2FXNXdkWFF1YkdGemRFbHVaR1Y0VDJZb1pHVnNhVzFwZEdWeUtUdGNibHgwWEhScFppQW9ZbUZ6YVdNZ1BDQXdLU0I3WEc1Y2RGeDBYSFJpWVhOcFl5QTlJREE3WEc1Y2RGeDBmVnh1WEc1Y2RGeDBabTl5SUNocUlEMGdNRHNnYWlBOElHSmhjMmxqT3lBcksyb3BJSHRjYmx4MFhIUmNkQzh2SUdsbUlHbDBKM01nYm05MElHRWdZbUZ6YVdNZ1kyOWtaU0J3YjJsdWRGeHVYSFJjZEZ4MGFXWWdLR2x1Y0hWMExtTm9ZWEpEYjJSbFFYUW9haWtnUGowZ01IZzRNQ2tnZTF4dVhIUmNkRngwWEhSbGNuSnZjaWduYm05MExXSmhjMmxqSnlrN1hHNWNkRngwWEhSOVhHNWNkRngwWEhSdmRYUndkWFF1Y0hWemFDaHBibkIxZEM1amFHRnlRMjlrWlVGMEtHb3BLVHRjYmx4MFhIUjlYRzVjYmx4MFhIUXZMeUJOWVdsdUlHUmxZMjlrYVc1bklHeHZiM0E2SUhOMFlYSjBJR3AxYzNRZ1lXWjBaWElnZEdobElHeGhjM1FnWkdWc2FXMXBkR1Z5SUdsbUlHRnVlU0JpWVhOcFl5QmpiMlJsWEc1Y2RGeDBMeThnY0c5cGJuUnpJSGRsY21VZ1kyOXdhV1ZrT3lCemRHRnlkQ0JoZENCMGFHVWdZbVZuYVc1dWFXNW5JRzkwYUdWeWQybHpaUzVjYmx4dVhIUmNkR1p2Y2lBb2FXNWtaWGdnUFNCaVlYTnBZeUErSURBZ1B5QmlZWE5wWXlBcklERWdPaUF3T3lCcGJtUmxlQ0E4SUdsdWNIVjBUR1Z1WjNSb095QXZLaUJ1YnlCbWFXNWhiQ0JsZUhCeVpYTnphVzl1SUNvdktTQjdYRzVjYmx4MFhIUmNkQzh2SUdCcGJtUmxlR0FnYVhNZ2RHaGxJR2x1WkdWNElHOW1JSFJvWlNCdVpYaDBJR05vWVhKaFkzUmxjaUIwYnlCaVpTQmpiMjV6ZFcxbFpDNWNibHgwWEhSY2RDOHZJRVJsWTI5a1pTQmhJR2RsYm1WeVlXeHBlbVZrSUhaaGNtbGhZbXhsTFd4bGJtZDBhQ0JwYm5SbFoyVnlJR2x1ZEc4Z1lHUmxiSFJoWUN4Y2JseDBYSFJjZEM4dklIZG9hV05vSUdkbGRITWdZV1JrWldRZ2RHOGdZR2xnTGlCVWFHVWdiM1psY21ac2IzY2dZMmhsWTJ0cGJtY2dhWE1nWldGemFXVnlYRzVjZEZ4MFhIUXZMeUJwWmlCM1pTQnBibU55WldGelpTQmdhV0FnWVhNZ2QyVWdaMjhzSUhSb1pXNGdjM1ZpZEhKaFkzUWdiMlptSUdsMGN5QnpkR0Z5ZEdsdVoxeHVYSFJjZEZ4MEx5OGdkbUZzZFdVZ1lYUWdkR2hsSUdWdVpDQjBieUJ2WW5SaGFXNGdZR1JsYkhSaFlDNWNibHgwWEhSY2RHWnZjaUFvYjJ4a2FTQTlJR2tzSUhjZ1BTQXhMQ0JySUQwZ1ltRnpaVHNnTHlvZ2JtOGdZMjl1WkdsMGFXOXVJQ292T3lCcklDczlJR0poYzJVcElIdGNibHh1WEhSY2RGeDBYSFJwWmlBb2FXNWtaWGdnUGowZ2FXNXdkWFJNWlc1bmRHZ3BJSHRjYmx4MFhIUmNkRngwWEhSbGNuSnZjaWduYVc1MllXeHBaQzFwYm5CMWRDY3BPMXh1WEhSY2RGeDBYSFI5WEc1Y2JseDBYSFJjZEZ4MFpHbG5hWFFnUFNCaVlYTnBZMVJ2UkdsbmFYUW9hVzV3ZFhRdVkyaGhja052WkdWQmRDaHBibVJsZUNzcktTazdYRzVjYmx4MFhIUmNkRngwYVdZZ0tHUnBaMmwwSUQ0OUlHSmhjMlVnZkh3Z1pHbG5hWFFnUGlCbWJHOXZjaWdvYldGNFNXNTBJQzBnYVNrZ0x5QjNLU2tnZTF4dVhIUmNkRngwWEhSY2RHVnljbTl5S0NkdmRtVnlabXh2ZHljcE8xeHVYSFJjZEZ4MFhIUjlYRzVjYmx4MFhIUmNkRngwYVNBclBTQmthV2RwZENBcUlIYzdYRzVjZEZ4MFhIUmNkSFFnUFNCcklEdzlJR0pwWVhNZ1B5QjBUV2x1SURvZ0tHc2dQajBnWW1saGN5QXJJSFJOWVhnZ1B5QjBUV0Y0SURvZ2F5QXRJR0pwWVhNcE8xeHVYRzVjZEZ4MFhIUmNkR2xtSUNoa2FXZHBkQ0E4SUhRcElIdGNibHgwWEhSY2RGeDBYSFJpY21WaGF6dGNibHgwWEhSY2RGeDBmVnh1WEc1Y2RGeDBYSFJjZEdKaGMyVk5hVzUxYzFRZ1BTQmlZWE5sSUMwZ2REdGNibHgwWEhSY2RGeDBhV1lnS0hjZ1BpQm1iRzl2Y2lodFlYaEpiblFnTHlCaVlYTmxUV2x1ZFhOVUtTa2dlMXh1WEhSY2RGeDBYSFJjZEdWeWNtOXlLQ2R2ZG1WeVpteHZkeWNwTzF4dVhIUmNkRngwWEhSOVhHNWNibHgwWEhSY2RGeDBkeUFxUFNCaVlYTmxUV2x1ZFhOVU8xeHVYRzVjZEZ4MFhIUjlYRzVjYmx4MFhIUmNkRzkxZENBOUlHOTFkSEIxZEM1c1pXNW5kR2dnS3lBeE8xeHVYSFJjZEZ4MFltbGhjeUE5SUdGa1lYQjBLR2tnTFNCdmJHUnBMQ0J2ZFhRc0lHOXNaR2tnUFQwZ01DazdYRzVjYmx4MFhIUmNkQzh2SUdCcFlDQjNZWE1nYzNWd2NHOXpaV1FnZEc4Z2QzSmhjQ0JoY205MWJtUWdabkp2YlNCZ2IzVjBZQ0IwYnlCZ01HQXNYRzVjZEZ4MFhIUXZMeUJwYm1OeVpXMWxiblJwYm1jZ1lHNWdJR1ZoWTJnZ2RHbHRaU3dnYzI4Z2QyVW5iR3dnWm1sNElIUm9ZWFFnYm05M09seHVYSFJjZEZ4MGFXWWdLR1pzYjI5eUtHa2dMeUJ2ZFhRcElENGdiV0Y0U1c1MElDMGdiaWtnZTF4dVhIUmNkRngwWEhSbGNuSnZjaWduYjNabGNtWnNiM2NuS1R0Y2JseDBYSFJjZEgxY2JseHVYSFJjZEZ4MGJpQXJQU0JtYkc5dmNpaHBJQzhnYjNWMEtUdGNibHgwWEhSY2RHa2dKVDBnYjNWME8xeHVYRzVjZEZ4MFhIUXZMeUJKYm5ObGNuUWdZRzVnSUdGMElIQnZjMmwwYVc5dUlHQnBZQ0J2WmlCMGFHVWdiM1YwY0hWMFhHNWNkRngwWEhSdmRYUndkWFF1YzNCc2FXTmxLR2tyS3l3Z01Dd2diaWs3WEc1Y2JseDBYSFI5WEc1Y2JseDBYSFJ5WlhSMWNtNGdkV056TW1WdVkyOWtaU2h2ZFhSd2RYUXBPMXh1WEhSOVhHNWNibHgwTHlvcVhHNWNkQ0FxSUVOdmJuWmxjblJ6SUdFZ2MzUnlhVzVuSUc5bUlGVnVhV052WkdVZ2MzbHRZbTlzY3lCMGJ5QmhJRkIxYm5samIyUmxJSE4wY21sdVp5QnZaaUJCVTBOSlNTMXZibXg1WEc1Y2RDQXFJSE41YldKdmJITXVYRzVjZENBcUlFQnRaVzFpWlhKUFppQndkVzU1WTI5a1pWeHVYSFFnS2lCQWNHRnlZVzBnZTFOMGNtbHVaMzBnYVc1d2RYUWdWR2hsSUhOMGNtbHVaeUJ2WmlCVmJtbGpiMlJsSUhONWJXSnZiSE11WEc1Y2RDQXFJRUJ5WlhSMWNtNXpJSHRUZEhKcGJtZDlJRlJvWlNCeVpYTjFiSFJwYm1jZ1VIVnVlV052WkdVZ2MzUnlhVzVuSUc5bUlFRlRRMGxKTFc5dWJIa2djM2x0WW05c2N5NWNibHgwSUNvdlhHNWNkR1oxYm1OMGFXOXVJR1Z1WTI5a1pTaHBibkIxZENrZ2UxeHVYSFJjZEhaaGNpQnVMRnh1WEhSY2RDQWdJQ0JrWld4MFlTeGNibHgwWEhRZ0lDQWdhR0Z1Wkd4bFpFTlFRMjkxYm5Rc1hHNWNkRngwSUNBZ0lHSmhjMmxqVEdWdVozUm9MRnh1WEhSY2RDQWdJQ0JpYVdGekxGeHVYSFJjZENBZ0lDQnFMRnh1WEhSY2RDQWdJQ0J0TEZ4dVhIUmNkQ0FnSUNCeExGeHVYSFJjZENBZ0lDQnJMRnh1WEhSY2RDQWdJQ0IwTEZ4dVhIUmNkQ0FnSUNCamRYSnlaVzUwVm1Gc2RXVXNYRzVjZEZ4MElDQWdJRzkxZEhCMWRDQTlJRnRkTEZ4dVhIUmNkQ0FnSUNBdktpb2dZR2x1Y0hWMFRHVnVaM1JvWUNCM2FXeHNJR2h2YkdRZ2RHaGxJRzUxYldKbGNpQnZaaUJqYjJSbElIQnZhVzUwY3lCcGJpQmdhVzV3ZFhSZ0xpQXFMMXh1WEhSY2RDQWdJQ0JwYm5CMWRFeGxibWQwYUN4Y2JseDBYSFFnSUNBZ0x5b3FJRU5oWTJobFpDQmpZV3hqZFd4aGRHbHZiaUJ5WlhOMWJIUnpJQ292WEc1Y2RGeDBJQ0FnSUdoaGJtUnNaV1JEVUVOdmRXNTBVR3gxYzA5dVpTeGNibHgwWEhRZ0lDQWdZbUZ6WlUxcGJuVnpWQ3hjYmx4MFhIUWdJQ0FnY1UxcGJuVnpWRHRjYmx4dVhIUmNkQzh2SUVOdmJuWmxjblFnZEdobElHbHVjSFYwSUdsdUlGVkRVeTB5SUhSdklGVnVhV052WkdWY2JseDBYSFJwYm5CMWRDQTlJSFZqY3pKa1pXTnZaR1VvYVc1d2RYUXBPMXh1WEc1Y2RGeDBMeThnUTJGamFHVWdkR2hsSUd4bGJtZDBhRnh1WEhSY2RHbHVjSFYwVEdWdVozUm9JRDBnYVc1d2RYUXViR1Z1WjNSb08xeHVYRzVjZEZ4MEx5OGdTVzVwZEdsaGJHbDZaU0IwYUdVZ2MzUmhkR1ZjYmx4MFhIUnVJRDBnYVc1cGRHbGhiRTQ3WEc1Y2RGeDBaR1ZzZEdFZ1BTQXdPMXh1WEhSY2RHSnBZWE1nUFNCcGJtbDBhV0ZzUW1saGN6dGNibHh1WEhSY2RDOHZJRWhoYm1Sc1pTQjBhR1VnWW1GemFXTWdZMjlrWlNCd2IybHVkSE5jYmx4MFhIUm1iM0lnS0dvZ1BTQXdPeUJxSUR3Z2FXNXdkWFJNWlc1bmRHZzdJQ3NyYWlrZ2UxeHVYSFJjZEZ4MFkzVnljbVZ1ZEZaaGJIVmxJRDBnYVc1d2RYUmJhbDA3WEc1Y2RGeDBYSFJwWmlBb1kzVnljbVZ1ZEZaaGJIVmxJRHdnTUhnNE1Da2dlMXh1WEhSY2RGeDBYSFJ2ZFhSd2RYUXVjSFZ6YUNoemRISnBibWRHY205dFEyaGhja052WkdVb1kzVnljbVZ1ZEZaaGJIVmxLU2s3WEc1Y2RGeDBYSFI5WEc1Y2RGeDBmVnh1WEc1Y2RGeDBhR0Z1Wkd4bFpFTlFRMjkxYm5RZ1BTQmlZWE5wWTB4bGJtZDBhQ0E5SUc5MWRIQjFkQzVzWlc1bmRHZzdYRzVjYmx4MFhIUXZMeUJnYUdGdVpHeGxaRU5RUTI5MWJuUmdJR2x6SUhSb1pTQnVkVzFpWlhJZ2IyWWdZMjlrWlNCd2IybHVkSE1nZEdoaGRDQm9ZWFpsSUdKbFpXNGdhR0Z1Wkd4bFpEdGNibHgwWEhRdkx5QmdZbUZ6YVdOTVpXNW5kR2hnSUdseklIUm9aU0J1ZFcxaVpYSWdiMllnWW1GemFXTWdZMjlrWlNCd2IybHVkSE11WEc1Y2JseDBYSFF2THlCR2FXNXBjMmdnZEdobElHSmhjMmxqSUhOMGNtbHVaeUF0SUdsbUlHbDBJR2x6SUc1dmRDQmxiWEIwZVNBdElIZHBkR2dnWVNCa1pXeHBiV2wwWlhKY2JseDBYSFJwWmlBb1ltRnphV05NWlc1bmRHZ3BJSHRjYmx4MFhIUmNkRzkxZEhCMWRDNXdkWE5vS0dSbGJHbHRhWFJsY2lrN1hHNWNkRngwZlZ4dVhHNWNkRngwTHk4Z1RXRnBiaUJsYm1OdlpHbHVaeUJzYjI5d09seHVYSFJjZEhkb2FXeGxJQ2hvWVc1a2JHVmtRMUJEYjNWdWRDQThJR2x1Y0hWMFRHVnVaM1JvS1NCN1hHNWNibHgwWEhSY2RDOHZJRUZzYkNCdWIyNHRZbUZ6YVdNZ1kyOWtaU0J3YjJsdWRITWdQQ0J1SUdoaGRtVWdZbVZsYmlCb1lXNWtiR1ZrSUdGc2NtVmhaSGt1SUVacGJtUWdkR2hsSUc1bGVIUmNibHgwWEhSY2RDOHZJR3hoY21kbGNpQnZibVU2WEc1Y2RGeDBYSFJtYjNJZ0tHMGdQU0J0WVhoSmJuUXNJR29nUFNBd095QnFJRHdnYVc1d2RYUk1aVzVuZEdnN0lDc3JhaWtnZTF4dVhIUmNkRngwWEhSamRYSnlaVzUwVm1Gc2RXVWdQU0JwYm5CMWRGdHFYVHRjYmx4MFhIUmNkRngwYVdZZ0tHTjFjbkpsYm5SV1lXeDFaU0ErUFNCdUlDWW1JR04xY25KbGJuUldZV3gxWlNBOElHMHBJSHRjYmx4MFhIUmNkRngwWEhSdElEMGdZM1Z5Y21WdWRGWmhiSFZsTzF4dVhIUmNkRngwWEhSOVhHNWNkRngwWEhSOVhHNWNibHgwWEhSY2RDOHZJRWx1WTNKbFlYTmxJR0JrWld4MFlXQWdaVzV2ZFdkb0lIUnZJR0ZrZG1GdVkyVWdkR2hsSUdSbFkyOWtaWEluY3lBOGJpeHBQaUJ6ZEdGMFpTQjBieUE4YlN3d1BpeGNibHgwWEhSY2RDOHZJR0oxZENCbmRXRnlaQ0JoWjJGcGJuTjBJRzkyWlhKbWJHOTNYRzVjZEZ4MFhIUm9ZVzVrYkdWa1ExQkRiM1Z1ZEZCc2RYTlBibVVnUFNCb1lXNWtiR1ZrUTFCRGIzVnVkQ0FySURFN1hHNWNkRngwWEhScFppQW9iU0F0SUc0Z1BpQm1iRzl2Y2lnb2JXRjRTVzUwSUMwZ1pHVnNkR0VwSUM4Z2FHRnVaR3hsWkVOUVEyOTFiblJRYkhWelQyNWxLU2tnZTF4dVhIUmNkRngwWEhSbGNuSnZjaWduYjNabGNtWnNiM2NuS1R0Y2JseDBYSFJjZEgxY2JseHVYSFJjZEZ4MFpHVnNkR0VnS3owZ0tHMGdMU0J1S1NBcUlHaGhibVJzWldSRFVFTnZkVzUwVUd4MWMwOXVaVHRjYmx4MFhIUmNkRzRnUFNCdE8xeHVYRzVjZEZ4MFhIUm1iM0lnS0dvZ1BTQXdPeUJxSUR3Z2FXNXdkWFJNWlc1bmRHZzdJQ3NyYWlrZ2UxeHVYSFJjZEZ4MFhIUmpkWEp5Wlc1MFZtRnNkV1VnUFNCcGJuQjFkRnRxWFR0Y2JseHVYSFJjZEZ4MFhIUnBaaUFvWTNWeWNtVnVkRlpoYkhWbElEd2diaUFtSmlBcksyUmxiSFJoSUQ0Z2JXRjRTVzUwS1NCN1hHNWNkRngwWEhSY2RGeDBaWEp5YjNJb0oyOTJaWEptYkc5M0p5azdYRzVjZEZ4MFhIUmNkSDFjYmx4dVhIUmNkRngwWEhScFppQW9ZM1Z5Y21WdWRGWmhiSFZsSUQwOUlHNHBJSHRjYmx4MFhIUmNkRngwWEhRdkx5QlNaWEJ5WlhObGJuUWdaR1ZzZEdFZ1lYTWdZU0JuWlc1bGNtRnNhWHBsWkNCMllYSnBZV0pzWlMxc1pXNW5kR2dnYVc1MFpXZGxjbHh1WEhSY2RGeDBYSFJjZEdadmNpQW9jU0E5SUdSbGJIUmhMQ0JySUQwZ1ltRnpaVHNnTHlvZ2JtOGdZMjl1WkdsMGFXOXVJQ292T3lCcklDczlJR0poYzJVcElIdGNibHgwWEhSY2RGeDBYSFJjZEhRZ1BTQnJJRHc5SUdKcFlYTWdQeUIwVFdsdUlEb2dLR3NnUGowZ1ltbGhjeUFySUhSTllYZ2dQeUIwVFdGNElEb2dheUF0SUdKcFlYTXBPMXh1WEhSY2RGeDBYSFJjZEZ4MGFXWWdLSEVnUENCMEtTQjdYRzVjZEZ4MFhIUmNkRngwWEhSY2RHSnlaV0ZyTzF4dVhIUmNkRngwWEhSY2RGeDBmVnh1WEhSY2RGeDBYSFJjZEZ4MGNVMXBiblZ6VkNBOUlIRWdMU0IwTzF4dVhIUmNkRngwWEhSY2RGeDBZbUZ6WlUxcGJuVnpWQ0E5SUdKaGMyVWdMU0IwTzF4dVhIUmNkRngwWEhSY2RGeDBiM1YwY0hWMExuQjFjMmdvWEc1Y2RGeDBYSFJjZEZ4MFhIUmNkSE4wY21sdVowWnliMjFEYUdGeVEyOWtaU2hrYVdkcGRGUnZRbUZ6YVdNb2RDQXJJSEZOYVc1MWMxUWdKU0JpWVhObFRXbHVkWE5VTENBd0tTbGNibHgwWEhSY2RGeDBYSFJjZENrN1hHNWNkRngwWEhSY2RGeDBYSFJ4SUQwZ1pteHZiM0lvY1UxcGJuVnpWQ0F2SUdKaGMyVk5hVzUxYzFRcE8xeHVYSFJjZEZ4MFhIUmNkSDFjYmx4dVhIUmNkRngwWEhSY2RHOTFkSEIxZEM1d2RYTm9LSE4wY21sdVowWnliMjFEYUdGeVEyOWtaU2hrYVdkcGRGUnZRbUZ6YVdNb2NTd2dNQ2twS1R0Y2JseDBYSFJjZEZ4MFhIUmlhV0Z6SUQwZ1lXUmhjSFFvWkdWc2RHRXNJR2hoYm1Sc1pXUkRVRU52ZFc1MFVHeDFjMDl1WlN3Z2FHRnVaR3hsWkVOUVEyOTFiblFnUFQwZ1ltRnphV05NWlc1bmRHZ3BPMXh1WEhSY2RGeDBYSFJjZEdSbGJIUmhJRDBnTUR0Y2JseDBYSFJjZEZ4MFhIUXJLMmhoYm1Sc1pXUkRVRU52ZFc1ME8xeHVYSFJjZEZ4MFhIUjlYRzVjZEZ4MFhIUjlYRzVjYmx4MFhIUmNkQ3NyWkdWc2RHRTdYRzVjZEZ4MFhIUXJLMjQ3WEc1Y2JseDBYSFI5WEc1Y2RGeDBjbVYwZFhKdUlHOTFkSEIxZEM1cWIybHVLQ2NuS1R0Y2JseDBmVnh1WEc1Y2RDOHFLbHh1WEhRZ0tpQkRiMjUyWlhKMGN5QmhJRkIxYm5samIyUmxJSE4wY21sdVp5QnlaWEJ5WlhObGJuUnBibWNnWVNCa2IyMWhhVzRnYm1GdFpTQjBieUJWYm1samIyUmxMaUJQYm14NUlIUm9aVnh1WEhRZ0tpQlFkVzU1WTI5a1pXUWdjR0Z5ZEhNZ2IyWWdkR2hsSUdSdmJXRnBiaUJ1WVcxbElIZHBiR3dnWW1VZ1kyOXVkbVZ5ZEdWa0xDQnBMbVV1SUdsMElHUnZaWE51SjNSY2JseDBJQ29nYldGMGRHVnlJR2xtSUhsdmRTQmpZV3hzSUdsMElHOXVJR0VnYzNSeWFXNW5JSFJvWVhRZ2FHRnpJR0ZzY21WaFpIa2dZbVZsYmlCamIyNTJaWEowWldRZ2RHOWNibHgwSUNvZ1ZXNXBZMjlrWlM1Y2JseDBJQ29nUUcxbGJXSmxjazltSUhCMWJubGpiMlJsWEc1Y2RDQXFJRUJ3WVhKaGJTQjdVM1J5YVc1bmZTQmtiMjFoYVc0Z1ZHaGxJRkIxYm5samIyUmxJR1J2YldGcGJpQnVZVzFsSUhSdklHTnZiblpsY25RZ2RHOGdWVzVwWTI5a1pTNWNibHgwSUNvZ1FISmxkSFZ5Ym5NZ2UxTjBjbWx1WjMwZ1ZHaGxJRlZ1YVdOdlpHVWdjbVZ3Y21WelpXNTBZWFJwYjI0Z2IyWWdkR2hsSUdkcGRtVnVJRkIxYm5samIyUmxYRzVjZENBcUlITjBjbWx1Wnk1Y2JseDBJQ292WEc1Y2RHWjFibU4wYVc5dUlIUnZWVzVwWTI5a1pTaGtiMjFoYVc0cElIdGNibHgwWEhSeVpYUjFjbTRnYldGd1JHOXRZV2x1S0dSdmJXRnBiaXdnWm5WdVkzUnBiMjRvYzNSeWFXNW5LU0I3WEc1Y2RGeDBYSFJ5WlhSMWNtNGdjbVZuWlhoUWRXNTVZMjlrWlM1MFpYTjBLSE4wY21sdVp5bGNibHgwWEhSY2RGeDBQeUJrWldOdlpHVW9jM1J5YVc1bkxuTnNhV05sS0RRcExuUnZURzkzWlhKRFlYTmxLQ2twWEc1Y2RGeDBYSFJjZERvZ2MzUnlhVzVuTzF4dVhIUmNkSDBwTzF4dVhIUjlYRzVjYmx4MEx5b3FYRzVjZENBcUlFTnZiblpsY25SeklHRWdWVzVwWTI5a1pTQnpkSEpwYm1jZ2NtVndjbVZ6Wlc1MGFXNW5JR0VnWkc5dFlXbHVJRzVoYldVZ2RHOGdVSFZ1ZVdOdlpHVXVJRTl1YkhrZ2RHaGxYRzVjZENBcUlHNXZiaTFCVTBOSlNTQndZWEowY3lCdlppQjBhR1VnWkc5dFlXbHVJRzVoYldVZ2QybHNiQ0JpWlNCamIyNTJaWEowWldRc0lHa3VaUzRnYVhRZ1pHOWxjMjRuZEZ4dVhIUWdLaUJ0WVhSMFpYSWdhV1lnZVc5MUlHTmhiR3dnYVhRZ2QybDBhQ0JoSUdSdmJXRnBiaUIwYUdGMEozTWdZV3h5WldGa2VTQnBiaUJCVTBOSlNTNWNibHgwSUNvZ1FHMWxiV0psY2s5bUlIQjFibmxqYjJSbFhHNWNkQ0FxSUVCd1lYSmhiU0I3VTNSeWFXNW5mU0JrYjIxaGFXNGdWR2hsSUdSdmJXRnBiaUJ1WVcxbElIUnZJR052Ym5abGNuUXNJR0Z6SUdFZ1ZXNXBZMjlrWlNCemRISnBibWN1WEc1Y2RDQXFJRUJ5WlhSMWNtNXpJSHRUZEhKcGJtZDlJRlJvWlNCUWRXNTVZMjlrWlNCeVpYQnlaWE5sYm5SaGRHbHZiaUJ2WmlCMGFHVWdaMmwyWlc0Z1pHOXRZV2x1SUc1aGJXVXVYRzVjZENBcUwxeHVYSFJtZFc1amRHbHZiaUIwYjBGVFEwbEpLR1J2YldGcGJpa2dlMXh1WEhSY2RISmxkSFZ5YmlCdFlYQkViMjFoYVc0b1pHOXRZV2x1TENCbWRXNWpkR2x2YmloemRISnBibWNwSUh0Y2JseDBYSFJjZEhKbGRIVnliaUJ5WldkbGVFNXZia0ZUUTBsSkxuUmxjM1FvYzNSeWFXNW5LVnh1WEhSY2RGeDBYSFEvSUNkNGJpMHRKeUFySUdWdVkyOWtaU2h6ZEhKcGJtY3BYRzVjZEZ4MFhIUmNkRG9nYzNSeWFXNW5PMXh1WEhSY2RIMHBPMXh1WEhSOVhHNWNibHgwTHlvdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTMHRMUzB0TFMwdExTb3ZYRzVjYmx4MEx5b3FJRVJsWm1sdVpTQjBhR1VnY0hWaWJHbGpJRUZRU1NBcUwxeHVYSFJ3ZFc1NVkyOWtaU0E5SUh0Y2JseDBYSFF2S2lwY2JseDBYSFFnS2lCQklITjBjbWx1WnlCeVpYQnlaWE5sYm5ScGJtY2dkR2hsSUdOMWNuSmxiblFnVUhWdWVXTnZaR1V1YW5NZ2RtVnljMmx2YmlCdWRXMWlaWEl1WEc1Y2RGeDBJQ29nUUcxbGJXSmxjazltSUhCMWJubGpiMlJsWEc1Y2RGeDBJQ29nUUhSNWNHVWdVM1J5YVc1blhHNWNkRngwSUNvdlhHNWNkRngwSjNabGNuTnBiMjRuT2lBbk1TNHlMalFuTEZ4dVhIUmNkQzhxS2x4dVhIUmNkQ0FxSUVGdUlHOWlhbVZqZENCdlppQnRaWFJvYjJSeklIUnZJR052Ym5abGNuUWdabkp2YlNCS1lYWmhVMk55YVhCMEozTWdhVzUwWlhKdVlXd2dZMmhoY21GamRHVnlYRzVjZEZ4MElDb2djbVZ3Y21WelpXNTBZWFJwYjI0Z0tGVkRVeTB5S1NCMGJ5QlZibWxqYjJSbElHTnZaR1VnY0c5cGJuUnpMQ0JoYm1RZ1ltRmpheTVjYmx4MFhIUWdLaUJBYzJWbElEeG9kSFJ3T2k4dmJXRjBhR2xoYzJKNWJtVnVjeTVpWlM5dWIzUmxjeTlxWVhaaGMyTnlhWEIwTFdWdVkyOWthVzVuUGx4dVhIUmNkQ0FxSUVCdFpXMWlaWEpQWmlCd2RXNTVZMjlrWlZ4dVhIUmNkQ0FxSUVCMGVYQmxJRTlpYW1WamRGeHVYSFJjZENBcUwxeHVYSFJjZENkMVkzTXlKem9nZTF4dVhIUmNkRngwSjJSbFkyOWtaU2M2SUhWamN6SmtaV052WkdVc1hHNWNkRngwWEhRblpXNWpiMlJsSnpvZ2RXTnpNbVZ1WTI5a1pWeHVYSFJjZEgwc1hHNWNkRngwSjJSbFkyOWtaU2M2SUdSbFkyOWtaU3hjYmx4MFhIUW5aVzVqYjJSbEp6b2daVzVqYjJSbExGeHVYSFJjZENkMGIwRlRRMGxKSnpvZ2RHOUJVME5KU1N4Y2JseDBYSFFuZEc5VmJtbGpiMlJsSnpvZ2RHOVZibWxqYjJSbFhHNWNkSDA3WEc1Y2JseDBMeW9xSUVWNGNHOXpaU0JnY0hWdWVXTnZaR1ZnSUNvdlhHNWNkQzh2SUZOdmJXVWdRVTFFSUdKMWFXeGtJRzl3ZEdsdGFYcGxjbk1zSUd4cGEyVWdjaTVxY3l3Z1kyaGxZMnNnWm05eUlITndaV05wWm1saklHTnZibVJwZEdsdmJpQndZWFIwWlhKdWMxeHVYSFF2THlCc2FXdGxJSFJvWlNCbWIyeHNiM2RwYm1jNlhHNWNkR2xtSUNoY2JseDBYSFIwZVhCbGIyWWdaR1ZtYVc1bElEMDlJQ2RtZFc1amRHbHZiaWNnSmlaY2JseDBYSFIwZVhCbGIyWWdaR1ZtYVc1bExtRnRaQ0E5UFNBbmIySnFaV04wSnlBbUpseHVYSFJjZEdSbFptbHVaUzVoYldSY2JseDBLU0I3WEc1Y2RGeDBaR1ZtYVc1bEtDZHdkVzU1WTI5a1pTY3NJR1oxYm1OMGFXOXVLQ2tnZTF4dVhIUmNkRngwY21WMGRYSnVJSEIxYm5samIyUmxPMXh1WEhSY2RIMHBPMXh1WEhSOUlHVnNjMlVnYVdZZ0tHWnlaV1ZGZUhCdmNuUnpJQ1ltSUNGbWNtVmxSWGh3YjNKMGN5NXViMlJsVkhsd1pTa2dlMXh1WEhSY2RHbG1JQ2htY21WbFRXOWtkV3hsS1NCN0lDOHZJR2x1SUU1dlpHVXVhbk1nYjNJZ1VtbHVaMjlLVXlCMk1DNDRMakFyWEc1Y2RGeDBYSFJtY21WbFRXOWtkV3hsTG1WNGNHOXlkSE1nUFNCd2RXNTVZMjlrWlR0Y2JseDBYSFI5SUdWc2MyVWdleUF2THlCcGJpQk9ZWEozYUdGc0lHOXlJRkpwYm1kdlNsTWdkakF1Tnk0d0xWeHVYSFJjZEZ4MFptOXlJQ2hyWlhrZ2FXNGdjSFZ1ZVdOdlpHVXBJSHRjYmx4MFhIUmNkRngwY0hWdWVXTnZaR1V1YUdGelQzZHVVSEp2Y0dWeWRIa29hMlY1S1NBbUppQW9abkpsWlVWNGNHOXlkSE5iYTJWNVhTQTlJSEIxYm5samIyUmxXMnRsZVYwcE8xeHVYSFJjZEZ4MGZWeHVYSFJjZEgxY2JseDBmU0JsYkhObElIc2dMeThnYVc0Z1VtaHBibThnYjNJZ1lTQjNaV0lnWW5KdmQzTmxjbHh1WEhSY2RISnZiM1F1Y0hWdWVXTnZaR1VnUFNCd2RXNTVZMjlrWlR0Y2JseDBmVnh1WEc1OUtIUm9hWE1wS1R0Y2JpSmRmUT09IiwiLy8gQ29weXJpZ2h0IEpveWVudCwgSW5jLiBhbmQgb3RoZXIgTm9kZSBjb250cmlidXRvcnMuXG4vL1xuLy8gUGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGFcbi8vIGNvcHkgb2YgdGhpcyBzb2Z0d2FyZSBhbmQgYXNzb2NpYXRlZCBkb2N1bWVudGF0aW9uIGZpbGVzICh0aGVcbi8vIFwiU29mdHdhcmVcIiksIHRvIGRlYWwgaW4gdGhlIFNvZnR3YXJlIHdpdGhvdXQgcmVzdHJpY3Rpb24sIGluY2x1ZGluZ1xuLy8gd2l0aG91dCBsaW1pdGF0aW9uIHRoZSByaWdodHMgdG8gdXNlLCBjb3B5LCBtb2RpZnksIG1lcmdlLCBwdWJsaXNoLFxuLy8gZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwgY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdFxuLy8gcGVyc29ucyB0byB3aG9tIHRoZSBTb2Z0d2FyZSBpcyBmdXJuaXNoZWQgdG8gZG8gc28sIHN1YmplY3QgdG8gdGhlXG4vLyBmb2xsb3dpbmcgY29uZGl0aW9uczpcbi8vXG4vLyBUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZFxuLy8gaW4gYWxsIGNvcGllcyBvciBzdWJzdGFudGlhbCBwb3J0aW9ucyBvZiB0aGUgU29mdHdhcmUuXG4vL1xuLy8gVEhFIFNPRlRXQVJFIElTIFBST1ZJREVEIFwiQVMgSVNcIiwgV0lUSE9VVCBXQVJSQU5UWSBPRiBBTlkgS0lORCwgRVhQUkVTU1xuLy8gT1IgSU1QTElFRCwgSU5DTFVESU5HIEJVVCBOT1QgTElNSVRFRCBUTyBUSEUgV0FSUkFOVElFUyBPRlxuLy8gTUVSQ0hBTlRBQklMSVRZLCBGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBTkQgTk9OSU5GUklOR0VNRU5ULiBJTlxuLy8gTk8gRVZFTlQgU0hBTEwgVEhFIEFVVEhPUlMgT1IgQ09QWVJJR0hUIEhPTERFUlMgQkUgTElBQkxFIEZPUiBBTlkgQ0xBSU0sXG4vLyBEQU1BR0VTIE9SIE9USEVSIExJQUJJTElUWSwgV0hFVEhFUiBJTiBBTiBBQ1RJT04gT0YgQ09OVFJBQ1QsIFRPUlQgT1Jcbi8vIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLCBPVVQgT0YgT1IgSU4gQ09OTkVDVElPTiBXSVRIIFRIRSBTT0ZUV0FSRSBPUiBUSEVcbi8vIFVTRSBPUiBPVEhFUiBERUFMSU5HUyBJTiBUSEUgU09GVFdBUkUuXG5cbid1c2Ugc3RyaWN0JztcblxuLy8gSWYgb2JqLmhhc093blByb3BlcnR5IGhhcyBiZWVuIG92ZXJyaWRkZW4sIHRoZW4gY2FsbGluZ1xuLy8gb2JqLmhhc093blByb3BlcnR5KHByb3ApIHdpbGwgYnJlYWsuXG4vLyBTZWU6IGh0dHBzOi8vZ2l0aHViLmNvbS9qb3llbnQvbm9kZS9pc3N1ZXMvMTcwN1xuZnVuY3Rpb24gaGFzT3duUHJvcGVydHkob2JqLCBwcm9wKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwob2JqLCBwcm9wKTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBmdW5jdGlvbihxcywgc2VwLCBlcSwgb3B0aW9ucykge1xuICBzZXAgPSBzZXAgfHwgJyYnO1xuICBlcSA9IGVxIHx8ICc9JztcbiAgdmFyIG9iaiA9IHt9O1xuXG4gIGlmICh0eXBlb2YgcXMgIT09ICdzdHJpbmcnIHx8IHFzLmxlbmd0aCA9PT0gMCkge1xuICAgIHJldHVybiBvYmo7XG4gIH1cblxuICB2YXIgcmVnZXhwID0gL1xcKy9nO1xuICBxcyA9IHFzLnNwbGl0KHNlcCk7XG5cbiAgdmFyIG1heEtleXMgPSAxMDAwO1xuICBpZiAob3B0aW9ucyAmJiB0eXBlb2Ygb3B0aW9ucy5tYXhLZXlzID09PSAnbnVtYmVyJykge1xuICAgIG1heEtleXMgPSBvcHRpb25zLm1heEtleXM7XG4gIH1cblxuICB2YXIgbGVuID0gcXMubGVuZ3RoO1xuICAvLyBtYXhLZXlzIDw9IDAgbWVhbnMgdGhhdCB3ZSBzaG91bGQgbm90IGxpbWl0IGtleXMgY291bnRcbiAgaWYgKG1heEtleXMgPiAwICYmIGxlbiA+IG1heEtleXMpIHtcbiAgICBsZW4gPSBtYXhLZXlzO1xuICB9XG5cbiAgZm9yICh2YXIgaSA9IDA7IGkgPCBsZW47ICsraSkge1xuICAgIHZhciB4ID0gcXNbaV0ucmVwbGFjZShyZWdleHAsICclMjAnKSxcbiAgICAgICAgaWR4ID0geC5pbmRleE9mKGVxKSxcbiAgICAgICAga3N0ciwgdnN0ciwgaywgdjtcblxuICAgIGlmIChpZHggPj0gMCkge1xuICAgICAga3N0ciA9IHguc3Vic3RyKDAsIGlkeCk7XG4gICAgICB2c3RyID0geC5zdWJzdHIoaWR4ICsgMSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGtzdHIgPSB4O1xuICAgICAgdnN0ciA9ICcnO1xuICAgIH1cblxuICAgIGsgPSBkZWNvZGVVUklDb21wb25lbnQoa3N0cik7XG4gICAgdiA9IGRlY29kZVVSSUNvbXBvbmVudCh2c3RyKTtcblxuICAgIGlmICghaGFzT3duUHJvcGVydHkob2JqLCBrKSkge1xuICAgICAgb2JqW2tdID0gdjtcbiAgICB9IGVsc2UgaWYgKGlzQXJyYXkob2JqW2tdKSkge1xuICAgICAgb2JqW2tdLnB1c2godik7XG4gICAgfSBlbHNlIHtcbiAgICAgIG9ialtrXSA9IFtvYmpba10sIHZdO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiBvYmo7XG59O1xuXG52YXIgaXNBcnJheSA9IEFycmF5LmlzQXJyYXkgfHwgZnVuY3Rpb24gKHhzKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwoeHMpID09PSAnW29iamVjdCBBcnJheV0nO1xufTtcbiIsIi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG4ndXNlIHN0cmljdCc7XG5cbnZhciBzdHJpbmdpZnlQcmltaXRpdmUgPSBmdW5jdGlvbih2KSB7XG4gIHN3aXRjaCAodHlwZW9mIHYpIHtcbiAgICBjYXNlICdzdHJpbmcnOlxuICAgICAgcmV0dXJuIHY7XG5cbiAgICBjYXNlICdib29sZWFuJzpcbiAgICAgIHJldHVybiB2ID8gJ3RydWUnIDogJ2ZhbHNlJztcblxuICAgIGNhc2UgJ251bWJlcic6XG4gICAgICByZXR1cm4gaXNGaW5pdGUodikgPyB2IDogJyc7XG5cbiAgICBkZWZhdWx0OlxuICAgICAgcmV0dXJuICcnO1xuICB9XG59O1xuXG5tb2R1bGUuZXhwb3J0cyA9IGZ1bmN0aW9uKG9iaiwgc2VwLCBlcSwgbmFtZSkge1xuICBzZXAgPSBzZXAgfHwgJyYnO1xuICBlcSA9IGVxIHx8ICc9JztcbiAgaWYgKG9iaiA9PT0gbnVsbCkge1xuICAgIG9iaiA9IHVuZGVmaW5lZDtcbiAgfVxuXG4gIGlmICh0eXBlb2Ygb2JqID09PSAnb2JqZWN0Jykge1xuICAgIHJldHVybiBtYXAob2JqZWN0S2V5cyhvYmopLCBmdW5jdGlvbihrKSB7XG4gICAgICB2YXIga3MgPSBlbmNvZGVVUklDb21wb25lbnQoc3RyaW5naWZ5UHJpbWl0aXZlKGspKSArIGVxO1xuICAgICAgaWYgKGlzQXJyYXkob2JqW2tdKSkge1xuICAgICAgICByZXR1cm4gbWFwKG9ialtrXSwgZnVuY3Rpb24odikge1xuICAgICAgICAgIHJldHVybiBrcyArIGVuY29kZVVSSUNvbXBvbmVudChzdHJpbmdpZnlQcmltaXRpdmUodikpO1xuICAgICAgICB9KS5qb2luKHNlcCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICByZXR1cm4ga3MgKyBlbmNvZGVVUklDb21wb25lbnQoc3RyaW5naWZ5UHJpbWl0aXZlKG9ialtrXSkpO1xuICAgICAgfVxuICAgIH0pLmpvaW4oc2VwKTtcblxuICB9XG5cbiAgaWYgKCFuYW1lKSByZXR1cm4gJyc7XG4gIHJldHVybiBlbmNvZGVVUklDb21wb25lbnQoc3RyaW5naWZ5UHJpbWl0aXZlKG5hbWUpKSArIGVxICtcbiAgICAgICAgIGVuY29kZVVSSUNvbXBvbmVudChzdHJpbmdpZnlQcmltaXRpdmUob2JqKSk7XG59O1xuXG52YXIgaXNBcnJheSA9IEFycmF5LmlzQXJyYXkgfHwgZnVuY3Rpb24gKHhzKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwoeHMpID09PSAnW29iamVjdCBBcnJheV0nO1xufTtcblxuZnVuY3Rpb24gbWFwICh4cywgZikge1xuICBpZiAoeHMubWFwKSByZXR1cm4geHMubWFwKGYpO1xuICB2YXIgcmVzID0gW107XG4gIGZvciAodmFyIGkgPSAwOyBpIDwgeHMubGVuZ3RoOyBpKyspIHtcbiAgICByZXMucHVzaChmKHhzW2ldLCBpKSk7XG4gIH1cbiAgcmV0dXJuIHJlcztcbn1cblxudmFyIG9iamVjdEtleXMgPSBPYmplY3Qua2V5cyB8fCBmdW5jdGlvbiAob2JqKSB7XG4gIHZhciByZXMgPSBbXTtcbiAgZm9yICh2YXIga2V5IGluIG9iaikge1xuICAgIGlmIChPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwob2JqLCBrZXkpKSByZXMucHVzaChrZXkpO1xuICB9XG4gIHJldHVybiByZXM7XG59O1xuIiwiJ3VzZSBzdHJpY3QnO1xuXG5leHBvcnRzLmRlY29kZSA9IGV4cG9ydHMucGFyc2UgPSByZXF1aXJlKCcuL2RlY29kZScpO1xuZXhwb3J0cy5lbmNvZGUgPSBleHBvcnRzLnN0cmluZ2lmeSA9IHJlcXVpcmUoJy4vZW5jb2RlJyk7XG4iLCJtb2R1bGUuZXhwb3J0cyA9IHJlcXVpcmUoXCIuL2xpYi9fc3RyZWFtX2R1cGxleC5qc1wiKVxuIiwiKGZ1bmN0aW9uIChwcm9jZXNzKXtcbi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG4vLyBhIGR1cGxleCBzdHJlYW0gaXMganVzdCBhIHN0cmVhbSB0aGF0IGlzIGJvdGggcmVhZGFibGUgYW5kIHdyaXRhYmxlLlxuLy8gU2luY2UgSlMgZG9lc24ndCBoYXZlIG11bHRpcGxlIHByb3RvdHlwYWwgaW5oZXJpdGFuY2UsIHRoaXMgY2xhc3Ncbi8vIHByb3RvdHlwYWxseSBpbmhlcml0cyBmcm9tIFJlYWRhYmxlLCBhbmQgdGhlbiBwYXJhc2l0aWNhbGx5IGZyb21cbi8vIFdyaXRhYmxlLlxuXG5tb2R1bGUuZXhwb3J0cyA9IER1cGxleDtcblxuLyo8cmVwbGFjZW1lbnQ+Ki9cbnZhciBvYmplY3RLZXlzID0gT2JqZWN0LmtleXMgfHwgZnVuY3Rpb24gKG9iaikge1xuICB2YXIga2V5cyA9IFtdO1xuICBmb3IgKHZhciBrZXkgaW4gb2JqKSBrZXlzLnB1c2goa2V5KTtcbiAgcmV0dXJuIGtleXM7XG59XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxuXG4vKjxyZXBsYWNlbWVudD4qL1xudmFyIHV0aWwgPSByZXF1aXJlKCdjb3JlLXV0aWwtaXMnKTtcbnV0aWwuaW5oZXJpdHMgPSByZXF1aXJlKCdpbmhlcml0cycpO1xuLyo8L3JlcGxhY2VtZW50PiovXG5cbnZhciBSZWFkYWJsZSA9IHJlcXVpcmUoJy4vX3N0cmVhbV9yZWFkYWJsZScpO1xudmFyIFdyaXRhYmxlID0gcmVxdWlyZSgnLi9fc3RyZWFtX3dyaXRhYmxlJyk7XG5cbnV0aWwuaW5oZXJpdHMoRHVwbGV4LCBSZWFkYWJsZSk7XG5cbmZvckVhY2gob2JqZWN0S2V5cyhXcml0YWJsZS5wcm90b3R5cGUpLCBmdW5jdGlvbihtZXRob2QpIHtcbiAgaWYgKCFEdXBsZXgucHJvdG90eXBlW21ldGhvZF0pXG4gICAgRHVwbGV4LnByb3RvdHlwZVttZXRob2RdID0gV3JpdGFibGUucHJvdG90eXBlW21ldGhvZF07XG59KTtcblxuZnVuY3Rpb24gRHVwbGV4KG9wdGlvbnMpIHtcbiAgaWYgKCEodGhpcyBpbnN0YW5jZW9mIER1cGxleCkpXG4gICAgcmV0dXJuIG5ldyBEdXBsZXgob3B0aW9ucyk7XG5cbiAgUmVhZGFibGUuY2FsbCh0aGlzLCBvcHRpb25zKTtcbiAgV3JpdGFibGUuY2FsbCh0aGlzLCBvcHRpb25zKTtcblxuICBpZiAob3B0aW9ucyAmJiBvcHRpb25zLnJlYWRhYmxlID09PSBmYWxzZSlcbiAgICB0aGlzLnJlYWRhYmxlID0gZmFsc2U7XG5cbiAgaWYgKG9wdGlvbnMgJiYgb3B0aW9ucy53cml0YWJsZSA9PT0gZmFsc2UpXG4gICAgdGhpcy53cml0YWJsZSA9IGZhbHNlO1xuXG4gIHRoaXMuYWxsb3dIYWxmT3BlbiA9IHRydWU7XG4gIGlmIChvcHRpb25zICYmIG9wdGlvbnMuYWxsb3dIYWxmT3BlbiA9PT0gZmFsc2UpXG4gICAgdGhpcy5hbGxvd0hhbGZPcGVuID0gZmFsc2U7XG5cbiAgdGhpcy5vbmNlKCdlbmQnLCBvbmVuZCk7XG59XG5cbi8vIHRoZSBuby1oYWxmLW9wZW4gZW5mb3JjZXJcbmZ1bmN0aW9uIG9uZW5kKCkge1xuICAvLyBpZiB3ZSBhbGxvdyBoYWxmLW9wZW4gc3RhdGUsIG9yIGlmIHRoZSB3cml0YWJsZSBzaWRlIGVuZGVkLFxuICAvLyB0aGVuIHdlJ3JlIG9rLlxuICBpZiAodGhpcy5hbGxvd0hhbGZPcGVuIHx8IHRoaXMuX3dyaXRhYmxlU3RhdGUuZW5kZWQpXG4gICAgcmV0dXJuO1xuXG4gIC8vIG5vIG1vcmUgZGF0YSBjYW4gYmUgd3JpdHRlbi5cbiAgLy8gQnV0IGFsbG93IG1vcmUgd3JpdGVzIHRvIGhhcHBlbiBpbiB0aGlzIHRpY2suXG4gIHByb2Nlc3MubmV4dFRpY2sodGhpcy5lbmQuYmluZCh0aGlzKSk7XG59XG5cbmZ1bmN0aW9uIGZvckVhY2ggKHhzLCBmKSB7XG4gIGZvciAodmFyIGkgPSAwLCBsID0geHMubGVuZ3RoOyBpIDwgbDsgaSsrKSB7XG4gICAgZih4c1tpXSwgaSk7XG4gIH1cbn1cblxufSkuY2FsbCh0aGlzLHJlcXVpcmUoJ19wcm9jZXNzJykpXG4vLyMgc291cmNlTWFwcGluZ1VSTD1kYXRhOmFwcGxpY2F0aW9uL2pzb247Y2hhcnNldDp1dGYtODtiYXNlNjQsZXlKMlpYSnphVzl1SWpvekxDSnpiM1Z5WTJWeklqcGJJbTV2WkdWZmJXOWtkV3hsY3k5aWNtOTNjMlZ5YVdaNUwyNXZaR1ZmYlc5a2RXeGxjeTl5WldGa1lXSnNaUzF6ZEhKbFlXMHZiR2xpTDE5emRISmxZVzFmWkhWd2JHVjRMbXB6SWwwc0ltNWhiV1Z6SWpwYlhTd2liV0Z3Y0dsdVozTWlPaUk3UVVGQlFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEVpTENKbWFXeGxJam9pWjJWdVpYSmhkR1ZrTG1weklpd2ljMjkxY21ObFVtOXZkQ0k2SWlJc0luTnZkWEpqWlhORGIyNTBaVzUwSWpwYklpOHZJRU52Y0hseWFXZG9kQ0JLYjNsbGJuUXNJRWx1WXk0Z1lXNWtJRzkwYUdWeUlFNXZaR1VnWTI5dWRISnBZblYwYjNKekxseHVMeTljYmk4dklGQmxjbTFwYzNOcGIyNGdhWE1nYUdWeVpXSjVJR2R5WVc1MFpXUXNJR1p5WldVZ2IyWWdZMmhoY21kbExDQjBieUJoYm5rZ2NHVnljMjl1SUc5aWRHRnBibWx1WnlCaFhHNHZMeUJqYjNCNUlHOW1JSFJvYVhNZ2MyOW1kSGRoY21VZ1lXNWtJR0Z6YzI5amFXRjBaV1FnWkc5amRXMWxiblJoZEdsdmJpQm1hV3hsY3lBb2RHaGxYRzR2THlCY0lsTnZablIzWVhKbFhDSXBMQ0IwYnlCa1pXRnNJR2x1SUhSb1pTQlRiMlowZDJGeVpTQjNhWFJvYjNWMElISmxjM1J5YVdOMGFXOXVMQ0JwYm1Oc2RXUnBibWRjYmk4dklIZHBkR2h2ZFhRZ2JHbHRhWFJoZEdsdmJpQjBhR1VnY21sbmFIUnpJSFJ2SUhWelpTd2dZMjl3ZVN3Z2JXOWthV1o1TENCdFpYSm5aU3dnY0hWaWJHbHphQ3hjYmk4dklHUnBjM1J5YVdKMWRHVXNJSE4xWW14cFkyVnVjMlVzSUdGdVpDOXZjaUJ6Wld4c0lHTnZjR2xsY3lCdlppQjBhR1VnVTI5bWRIZGhjbVVzSUdGdVpDQjBieUJ3WlhKdGFYUmNiaTh2SUhCbGNuTnZibk1nZEc4Z2QyaHZiU0IwYUdVZ1UyOW1kSGRoY21VZ2FYTWdablZ5Ym1semFHVmtJSFJ2SUdSdklITnZMQ0J6ZFdKcVpXTjBJSFJ2SUhSb1pWeHVMeThnWm05c2JHOTNhVzVuSUdOdmJtUnBkR2x2Ym5NNlhHNHZMMXh1THk4Z1ZHaGxJR0ZpYjNabElHTnZjSGx5YVdkb2RDQnViM1JwWTJVZ1lXNWtJSFJvYVhNZ2NHVnliV2x6YzJsdmJpQnViM1JwWTJVZ2MyaGhiR3dnWW1VZ2FXNWpiSFZrWldSY2JpOHZJR2x1SUdGc2JDQmpiM0JwWlhNZ2IzSWdjM1ZpYzNSaGJuUnBZV3dnY0c5eWRHbHZibk1nYjJZZ2RHaGxJRk52Wm5SM1lYSmxMbHh1THk5Y2JpOHZJRlJJUlNCVFQwWlVWMEZTUlNCSlV5QlFVazlXU1VSRlJDQmNJa0ZUSUVsVFhDSXNJRmRKVkVoUFZWUWdWMEZTVWtGT1ZGa2dUMFlnUVU1WklFdEpUa1FzSUVWWVVGSkZVMU5jYmk4dklFOVNJRWxOVUV4SlJVUXNJRWxPUTB4VlJFbE9SeUJDVlZRZ1RrOVVJRXhKVFVsVVJVUWdWRThnVkVoRklGZEJVbEpCVGxSSlJWTWdUMFpjYmk4dklFMUZVa05JUVU1VVFVSkpURWxVV1N3Z1JrbFVUa1ZUVXlCR1QxSWdRU0JRUVZKVVNVTlZURUZTSUZCVlVsQlBVMFVnUVU1RUlFNVBUa2xPUmxKSlRrZEZUVVZPVkM0Z1NVNWNiaTh2SUU1UElFVldSVTVVSUZOSVFVeE1JRlJJUlNCQlZWUklUMUpUSUU5U0lFTlBVRmxTU1VkSVZDQklUMHhFUlZKVElFSkZJRXhKUVVKTVJTQkdUMUlnUVU1WklFTk1RVWxOTEZ4dUx5OGdSRUZOUVVkRlV5QlBVaUJQVkVoRlVpQk1TVUZDU1V4SlZGa3NJRmRJUlZSSVJWSWdTVTRnUVU0Z1FVTlVTVTlPSUU5R0lFTlBUbFJTUVVOVUxDQlVUMUpVSUU5U1hHNHZMeUJQVkVoRlVsZEpVMFVzSUVGU1NWTkpUa2NnUmxKUFRTd2dUMVZVSUU5R0lFOVNJRWxPSUVOUFRrNUZRMVJKVDA0Z1YwbFVTQ0JVU0VVZ1UwOUdWRmRCVWtVZ1QxSWdWRWhGWEc0dkx5QlZVMFVnVDFJZ1QxUklSVklnUkVWQlRFbE9SMU1nU1U0Z1ZFaEZJRk5QUmxSWFFWSkZMbHh1WEc0dkx5QmhJR1IxY0d4bGVDQnpkSEpsWVcwZ2FYTWdhblZ6ZENCaElITjBjbVZoYlNCMGFHRjBJR2x6SUdKdmRHZ2djbVZoWkdGaWJHVWdZVzVrSUhkeWFYUmhZbXhsTGx4dUx5OGdVMmx1WTJVZ1NsTWdaRzlsYzI0bmRDQm9ZWFpsSUcxMWJIUnBjR3hsSUhCeWIzUnZkSGx3WVd3Z2FXNW9aWEpwZEdGdVkyVXNJSFJvYVhNZ1kyeGhjM05jYmk4dklIQnliM1J2ZEhsd1lXeHNlU0JwYm1obGNtbDBjeUJtY205dElGSmxZV1JoWW14bExDQmhibVFnZEdobGJpQndZWEpoYzJsMGFXTmhiR3g1SUdaeWIyMWNiaTh2SUZkeWFYUmhZbXhsTGx4dVhHNXRiMlIxYkdVdVpYaHdiM0owY3lBOUlFUjFjR3hsZUR0Y2JseHVMeW84Y21Wd2JHRmpaVzFsYm5RK0tpOWNiblpoY2lCdlltcGxZM1JMWlhseklEMGdUMkpxWldOMExtdGxlWE1nZkh3Z1puVnVZM1JwYjI0Z0tHOWlhaWtnZTF4dUlDQjJZWElnYTJWNWN5QTlJRnRkTzF4dUlDQm1iM0lnS0haaGNpQnJaWGtnYVc0Z2IySnFLU0JyWlhsekxuQjFjMmdvYTJWNUtUdGNiaUFnY21WMGRYSnVJR3RsZVhNN1hHNTlYRzR2S2p3dmNtVndiR0ZqWlcxbGJuUStLaTljYmx4dVhHNHZLanh5WlhCc1lXTmxiV1Z1ZEQ0cUwxeHVkbUZ5SUhWMGFXd2dQU0J5WlhGMWFYSmxLQ2RqYjNKbExYVjBhV3d0YVhNbktUdGNiblYwYVd3dWFXNW9aWEpwZEhNZ1BTQnlaWEYxYVhKbEtDZHBibWhsY21sMGN5Y3BPMXh1THlvOEwzSmxjR3hoWTJWdFpXNTBQaW92WEc1Y2JuWmhjaUJTWldGa1lXSnNaU0E5SUhKbGNYVnBjbVVvSnk0dlgzTjBjbVZoYlY5eVpXRmtZV0pzWlNjcE8xeHVkbUZ5SUZkeWFYUmhZbXhsSUQwZ2NtVnhkV2x5WlNnbkxpOWZjM1J5WldGdFgzZHlhWFJoWW14bEp5azdYRzVjYm5WMGFXd3VhVzVvWlhKcGRITW9SSFZ3YkdWNExDQlNaV0ZrWVdKc1pTazdYRzVjYm1admNrVmhZMmdvYjJKcVpXTjBTMlY1Y3loWGNtbDBZV0pzWlM1d2NtOTBiM1I1Y0dVcExDQm1kVzVqZEdsdmJpaHRaWFJvYjJRcElIdGNiaUFnYVdZZ0tDRkVkWEJzWlhndWNISnZkRzkwZVhCbFcyMWxkR2h2WkYwcFhHNGdJQ0FnUkhWd2JHVjRMbkJ5YjNSdmRIbHdaVnR0WlhSb2IyUmRJRDBnVjNKcGRHRmliR1V1Y0hKdmRHOTBlWEJsVzIxbGRHaHZaRjA3WEc1OUtUdGNibHh1Wm5WdVkzUnBiMjRnUkhWd2JHVjRLRzl3ZEdsdmJuTXBJSHRjYmlBZ2FXWWdLQ0VvZEdocGN5QnBibk4wWVc1alpXOW1JRVIxY0d4bGVDa3BYRzRnSUNBZ2NtVjBkWEp1SUc1bGR5QkVkWEJzWlhnb2IzQjBhVzl1Y3lrN1hHNWNiaUFnVW1WaFpHRmliR1V1WTJGc2JDaDBhR2x6TENCdmNIUnBiMjV6S1R0Y2JpQWdWM0pwZEdGaWJHVXVZMkZzYkNoMGFHbHpMQ0J2Y0hScGIyNXpLVHRjYmx4dUlDQnBaaUFvYjNCMGFXOXVjeUFtSmlCdmNIUnBiMjV6TG5KbFlXUmhZbXhsSUQwOVBTQm1ZV3h6WlNsY2JpQWdJQ0IwYUdsekxuSmxZV1JoWW14bElEMGdabUZzYzJVN1hHNWNiaUFnYVdZZ0tHOXdkR2x2Ym5NZ0ppWWdiM0IwYVc5dWN5NTNjbWwwWVdKc1pTQTlQVDBnWm1Gc2MyVXBYRzRnSUNBZ2RHaHBjeTUzY21sMFlXSnNaU0E5SUdaaGJITmxPMXh1WEc0Z0lIUm9hWE11WVd4c2IzZElZV3htVDNCbGJpQTlJSFJ5ZFdVN1hHNGdJR2xtSUNodmNIUnBiMjV6SUNZbUlHOXdkR2x2Ym5NdVlXeHNiM2RJWVd4bVQzQmxiaUE5UFQwZ1ptRnNjMlVwWEc0Z0lDQWdkR2hwY3k1aGJHeHZkMGhoYkdaUGNHVnVJRDBnWm1Gc2MyVTdYRzVjYmlBZ2RHaHBjeTV2Ym1ObEtDZGxibVFuTENCdmJtVnVaQ2s3WEc1OVhHNWNiaTh2SUhSb1pTQnVieTFvWVd4bUxXOXdaVzRnWlc1bWIzSmpaWEpjYm1aMWJtTjBhVzl1SUc5dVpXNWtLQ2tnZTF4dUlDQXZMeUJwWmlCM1pTQmhiR3h2ZHlCb1lXeG1MVzl3Wlc0Z2MzUmhkR1VzSUc5eUlHbG1JSFJvWlNCM2NtbDBZV0pzWlNCemFXUmxJR1Z1WkdWa0xGeHVJQ0F2THlCMGFHVnVJSGRsSjNKbElHOXJMbHh1SUNCcFppQW9kR2hwY3k1aGJHeHZkMGhoYkdaUGNHVnVJSHg4SUhSb2FYTXVYM2R5YVhSaFlteGxVM1JoZEdVdVpXNWtaV1FwWEc0Z0lDQWdjbVYwZFhKdU8xeHVYRzRnSUM4dklHNXZJRzF2Y21VZ1pHRjBZU0JqWVc0Z1ltVWdkM0pwZEhSbGJpNWNiaUFnTHk4Z1FuVjBJR0ZzYkc5M0lHMXZjbVVnZDNKcGRHVnpJSFJ2SUdoaGNIQmxiaUJwYmlCMGFHbHpJSFJwWTJzdVhHNGdJSEJ5YjJObGMzTXVibVY0ZEZScFkyc29kR2hwY3k1bGJtUXVZbWx1WkNoMGFHbHpLU2s3WEc1OVhHNWNibVoxYm1OMGFXOXVJR1p2Y2tWaFkyZ2dLSGh6TENCbUtTQjdYRzRnSUdadmNpQW9kbUZ5SUdrZ1BTQXdMQ0JzSUQwZ2VITXViR1Z1WjNSb095QnBJRHdnYkRzZ2FTc3JLU0I3WEc0Z0lDQWdaaWg0YzF0cFhTd2dhU2s3WEc0Z0lIMWNibjFjYmlKZGZRPT0iLCIvLyBDb3B5cmlnaHQgSm95ZW50LCBJbmMuIGFuZCBvdGhlciBOb2RlIGNvbnRyaWJ1dG9ycy5cbi8vXG4vLyBQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcgYVxuLy8gY29weSBvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZVxuLy8gXCJTb2Z0d2FyZVwiKSwgdG8gZGVhbCBpbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nXG4vLyB3aXRob3V0IGxpbWl0YXRpb24gdGhlIHJpZ2h0cyB0byB1c2UsIGNvcHksIG1vZGlmeSwgbWVyZ2UsIHB1Ymxpc2gsXG4vLyBkaXN0cmlidXRlLCBzdWJsaWNlbnNlLCBhbmQvb3Igc2VsbCBjb3BpZXMgb2YgdGhlIFNvZnR3YXJlLCBhbmQgdG8gcGVybWl0XG4vLyBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzIGZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGVcbi8vIGZvbGxvd2luZyBjb25kaXRpb25zOlxuLy9cbi8vIFRoZSBhYm92ZSBjb3B5cmlnaHQgbm90aWNlIGFuZCB0aGlzIHBlcm1pc3Npb24gbm90aWNlIHNoYWxsIGJlIGluY2x1ZGVkXG4vLyBpbiBhbGwgY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS5cbi8vXG4vLyBUSEUgU09GVFdBUkUgSVMgUFJPVklERUQgXCJBUyBJU1wiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTXG4vLyBPUiBJTVBMSUVELCBJTkNMVURJTkcgQlVUIE5PVCBMSU1JVEVEIFRPIFRIRSBXQVJSQU5USUVTIE9GXG4vLyBNRVJDSEFOVEFCSUxJVFksIEZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFORCBOT05JTkZSSU5HRU1FTlQuIElOXG4vLyBOTyBFVkVOVCBTSEFMTCBUSEUgQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSxcbi8vIERBTUFHRVMgT1IgT1RIRVIgTElBQklMSVRZLCBXSEVUSEVSIElOIEFOIEFDVElPTiBPRiBDT05UUkFDVCwgVE9SVCBPUlxuLy8gT1RIRVJXSVNFLCBBUklTSU5HIEZST00sIE9VVCBPRiBPUiBJTiBDT05ORUNUSU9OIFdJVEggVEhFIFNPRlRXQVJFIE9SIFRIRVxuLy8gVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRSBTT0ZUV0FSRS5cblxuLy8gYSBwYXNzdGhyb3VnaCBzdHJlYW0uXG4vLyBiYXNpY2FsbHkganVzdCB0aGUgbW9zdCBtaW5pbWFsIHNvcnQgb2YgVHJhbnNmb3JtIHN0cmVhbS5cbi8vIEV2ZXJ5IHdyaXR0ZW4gY2h1bmsgZ2V0cyBvdXRwdXQgYXMtaXMuXG5cbm1vZHVsZS5leHBvcnRzID0gUGFzc1Rocm91Z2g7XG5cbnZhciBUcmFuc2Zvcm0gPSByZXF1aXJlKCcuL19zdHJlYW1fdHJhbnNmb3JtJyk7XG5cbi8qPHJlcGxhY2VtZW50PiovXG52YXIgdXRpbCA9IHJlcXVpcmUoJ2NvcmUtdXRpbC1pcycpO1xudXRpbC5pbmhlcml0cyA9IHJlcXVpcmUoJ2luaGVyaXRzJyk7XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxudXRpbC5pbmhlcml0cyhQYXNzVGhyb3VnaCwgVHJhbnNmb3JtKTtcblxuZnVuY3Rpb24gUGFzc1Rocm91Z2gob3B0aW9ucykge1xuICBpZiAoISh0aGlzIGluc3RhbmNlb2YgUGFzc1Rocm91Z2gpKVxuICAgIHJldHVybiBuZXcgUGFzc1Rocm91Z2gob3B0aW9ucyk7XG5cbiAgVHJhbnNmb3JtLmNhbGwodGhpcywgb3B0aW9ucyk7XG59XG5cblBhc3NUaHJvdWdoLnByb3RvdHlwZS5fdHJhbnNmb3JtID0gZnVuY3Rpb24oY2h1bmssIGVuY29kaW5nLCBjYikge1xuICBjYihudWxsLCBjaHVuayk7XG59O1xuIiwiKGZ1bmN0aW9uIChwcm9jZXNzKXtcbi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG5tb2R1bGUuZXhwb3J0cyA9IFJlYWRhYmxlO1xuXG4vKjxyZXBsYWNlbWVudD4qL1xudmFyIGlzQXJyYXkgPSByZXF1aXJlKCdpc2FycmF5Jyk7XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxuXG4vKjxyZXBsYWNlbWVudD4qL1xudmFyIEJ1ZmZlciA9IHJlcXVpcmUoJ2J1ZmZlcicpLkJ1ZmZlcjtcbi8qPC9yZXBsYWNlbWVudD4qL1xuXG5SZWFkYWJsZS5SZWFkYWJsZVN0YXRlID0gUmVhZGFibGVTdGF0ZTtcblxudmFyIEVFID0gcmVxdWlyZSgnZXZlbnRzJykuRXZlbnRFbWl0dGVyO1xuXG4vKjxyZXBsYWNlbWVudD4qL1xuaWYgKCFFRS5saXN0ZW5lckNvdW50KSBFRS5saXN0ZW5lckNvdW50ID0gZnVuY3Rpb24oZW1pdHRlciwgdHlwZSkge1xuICByZXR1cm4gZW1pdHRlci5saXN0ZW5lcnModHlwZSkubGVuZ3RoO1xufTtcbi8qPC9yZXBsYWNlbWVudD4qL1xuXG52YXIgU3RyZWFtID0gcmVxdWlyZSgnc3RyZWFtJyk7XG5cbi8qPHJlcGxhY2VtZW50PiovXG52YXIgdXRpbCA9IHJlcXVpcmUoJ2NvcmUtdXRpbC1pcycpO1xudXRpbC5pbmhlcml0cyA9IHJlcXVpcmUoJ2luaGVyaXRzJyk7XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxudmFyIFN0cmluZ0RlY29kZXI7XG5cblxuLyo8cmVwbGFjZW1lbnQ+Ki9cbnZhciBkZWJ1ZyA9IHJlcXVpcmUoJ3V0aWwnKTtcbmlmIChkZWJ1ZyAmJiBkZWJ1Zy5kZWJ1Z2xvZykge1xuICBkZWJ1ZyA9IGRlYnVnLmRlYnVnbG9nKCdzdHJlYW0nKTtcbn0gZWxzZSB7XG4gIGRlYnVnID0gZnVuY3Rpb24gKCkge307XG59XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxuXG51dGlsLmluaGVyaXRzKFJlYWRhYmxlLCBTdHJlYW0pO1xuXG5mdW5jdGlvbiBSZWFkYWJsZVN0YXRlKG9wdGlvbnMsIHN0cmVhbSkge1xuICB2YXIgRHVwbGV4ID0gcmVxdWlyZSgnLi9fc3RyZWFtX2R1cGxleCcpO1xuXG4gIG9wdGlvbnMgPSBvcHRpb25zIHx8IHt9O1xuXG4gIC8vIHRoZSBwb2ludCBhdCB3aGljaCBpdCBzdG9wcyBjYWxsaW5nIF9yZWFkKCkgdG8gZmlsbCB0aGUgYnVmZmVyXG4gIC8vIE5vdGU6IDAgaXMgYSB2YWxpZCB2YWx1ZSwgbWVhbnMgXCJkb24ndCBjYWxsIF9yZWFkIHByZWVtcHRpdmVseSBldmVyXCJcbiAgdmFyIGh3bSA9IG9wdGlvbnMuaGlnaFdhdGVyTWFyaztcbiAgdmFyIGRlZmF1bHRId20gPSBvcHRpb25zLm9iamVjdE1vZGUgPyAxNiA6IDE2ICogMTAyNDtcbiAgdGhpcy5oaWdoV2F0ZXJNYXJrID0gKGh3bSB8fCBod20gPT09IDApID8gaHdtIDogZGVmYXVsdEh3bTtcblxuICAvLyBjYXN0IHRvIGludHMuXG4gIHRoaXMuaGlnaFdhdGVyTWFyayA9IH5+dGhpcy5oaWdoV2F0ZXJNYXJrO1xuXG4gIHRoaXMuYnVmZmVyID0gW107XG4gIHRoaXMubGVuZ3RoID0gMDtcbiAgdGhpcy5waXBlcyA9IG51bGw7XG4gIHRoaXMucGlwZXNDb3VudCA9IDA7XG4gIHRoaXMuZmxvd2luZyA9IG51bGw7XG4gIHRoaXMuZW5kZWQgPSBmYWxzZTtcbiAgdGhpcy5lbmRFbWl0dGVkID0gZmFsc2U7XG4gIHRoaXMucmVhZGluZyA9IGZhbHNlO1xuXG4gIC8vIGEgZmxhZyB0byBiZSBhYmxlIHRvIHRlbGwgaWYgdGhlIG9ud3JpdGUgY2IgaXMgY2FsbGVkIGltbWVkaWF0ZWx5LFxuICAvLyBvciBvbiBhIGxhdGVyIHRpY2suICBXZSBzZXQgdGhpcyB0byB0cnVlIGF0IGZpcnN0LCBiZWNhdXNlIGFueVxuICAvLyBhY3Rpb25zIHRoYXQgc2hvdWxkbid0IGhhcHBlbiB1bnRpbCBcImxhdGVyXCIgc2hvdWxkIGdlbmVyYWxseSBhbHNvXG4gIC8vIG5vdCBoYXBwZW4gYmVmb3JlIHRoZSBmaXJzdCB3cml0ZSBjYWxsLlxuICB0aGlzLnN5bmMgPSB0cnVlO1xuXG4gIC8vIHdoZW5ldmVyIHdlIHJldHVybiBudWxsLCB0aGVuIHdlIHNldCBhIGZsYWcgdG8gc2F5XG4gIC8vIHRoYXQgd2UncmUgYXdhaXRpbmcgYSAncmVhZGFibGUnIGV2ZW50IGVtaXNzaW9uLlxuICB0aGlzLm5lZWRSZWFkYWJsZSA9IGZhbHNlO1xuICB0aGlzLmVtaXR0ZWRSZWFkYWJsZSA9IGZhbHNlO1xuICB0aGlzLnJlYWRhYmxlTGlzdGVuaW5nID0gZmFsc2U7XG5cblxuICAvLyBvYmplY3Qgc3RyZWFtIGZsYWcuIFVzZWQgdG8gbWFrZSByZWFkKG4pIGlnbm9yZSBuIGFuZCB0b1xuICAvLyBtYWtlIGFsbCB0aGUgYnVmZmVyIG1lcmdpbmcgYW5kIGxlbmd0aCBjaGVja3MgZ28gYXdheVxuICB0aGlzLm9iamVjdE1vZGUgPSAhIW9wdGlvbnMub2JqZWN0TW9kZTtcblxuICBpZiAoc3RyZWFtIGluc3RhbmNlb2YgRHVwbGV4KVxuICAgIHRoaXMub2JqZWN0TW9kZSA9IHRoaXMub2JqZWN0TW9kZSB8fCAhIW9wdGlvbnMucmVhZGFibGVPYmplY3RNb2RlO1xuXG4gIC8vIENyeXB0byBpcyBraW5kIG9mIG9sZCBhbmQgY3J1c3R5LiAgSGlzdG9yaWNhbGx5LCBpdHMgZGVmYXVsdCBzdHJpbmdcbiAgLy8gZW5jb2RpbmcgaXMgJ2JpbmFyeScgc28gd2UgaGF2ZSB0byBtYWtlIHRoaXMgY29uZmlndXJhYmxlLlxuICAvLyBFdmVyeXRoaW5nIGVsc2UgaW4gdGhlIHVuaXZlcnNlIHVzZXMgJ3V0ZjgnLCB0aG91Z2guXG4gIHRoaXMuZGVmYXVsdEVuY29kaW5nID0gb3B0aW9ucy5kZWZhdWx0RW5jb2RpbmcgfHwgJ3V0ZjgnO1xuXG4gIC8vIHdoZW4gcGlwaW5nLCB3ZSBvbmx5IGNhcmUgYWJvdXQgJ3JlYWRhYmxlJyBldmVudHMgdGhhdCBoYXBwZW5cbiAgLy8gYWZ0ZXIgcmVhZCgpaW5nIGFsbCB0aGUgYnl0ZXMgYW5kIG5vdCBnZXR0aW5nIGFueSBwdXNoYmFjay5cbiAgdGhpcy5yYW5PdXQgPSBmYWxzZTtcblxuICAvLyB0aGUgbnVtYmVyIG9mIHdyaXRlcnMgdGhhdCBhcmUgYXdhaXRpbmcgYSBkcmFpbiBldmVudCBpbiAucGlwZSgpc1xuICB0aGlzLmF3YWl0RHJhaW4gPSAwO1xuXG4gIC8vIGlmIHRydWUsIGEgbWF5YmVSZWFkTW9yZSBoYXMgYmVlbiBzY2hlZHVsZWRcbiAgdGhpcy5yZWFkaW5nTW9yZSA9IGZhbHNlO1xuXG4gIHRoaXMuZGVjb2RlciA9IG51bGw7XG4gIHRoaXMuZW5jb2RpbmcgPSBudWxsO1xuICBpZiAob3B0aW9ucy5lbmNvZGluZykge1xuICAgIGlmICghU3RyaW5nRGVjb2RlcilcbiAgICAgIFN0cmluZ0RlY29kZXIgPSByZXF1aXJlKCdzdHJpbmdfZGVjb2Rlci8nKS5TdHJpbmdEZWNvZGVyO1xuICAgIHRoaXMuZGVjb2RlciA9IG5ldyBTdHJpbmdEZWNvZGVyKG9wdGlvbnMuZW5jb2RpbmcpO1xuICAgIHRoaXMuZW5jb2RpbmcgPSBvcHRpb25zLmVuY29kaW5nO1xuICB9XG59XG5cbmZ1bmN0aW9uIFJlYWRhYmxlKG9wdGlvbnMpIHtcbiAgdmFyIER1cGxleCA9IHJlcXVpcmUoJy4vX3N0cmVhbV9kdXBsZXgnKTtcblxuICBpZiAoISh0aGlzIGluc3RhbmNlb2YgUmVhZGFibGUpKVxuICAgIHJldHVybiBuZXcgUmVhZGFibGUob3B0aW9ucyk7XG5cbiAgdGhpcy5fcmVhZGFibGVTdGF0ZSA9IG5ldyBSZWFkYWJsZVN0YXRlKG9wdGlvbnMsIHRoaXMpO1xuXG4gIC8vIGxlZ2FjeVxuICB0aGlzLnJlYWRhYmxlID0gdHJ1ZTtcblxuICBTdHJlYW0uY2FsbCh0aGlzKTtcbn1cblxuLy8gTWFudWFsbHkgc2hvdmUgc29tZXRoaW5nIGludG8gdGhlIHJlYWQoKSBidWZmZXIuXG4vLyBUaGlzIHJldHVybnMgdHJ1ZSBpZiB0aGUgaGlnaFdhdGVyTWFyayBoYXMgbm90IGJlZW4gaGl0IHlldCxcbi8vIHNpbWlsYXIgdG8gaG93IFdyaXRhYmxlLndyaXRlKCkgcmV0dXJucyB0cnVlIGlmIHlvdSBzaG91bGRcbi8vIHdyaXRlKCkgc29tZSBtb3JlLlxuUmVhZGFibGUucHJvdG90eXBlLnB1c2ggPSBmdW5jdGlvbihjaHVuaywgZW5jb2RpbmcpIHtcbiAgdmFyIHN0YXRlID0gdGhpcy5fcmVhZGFibGVTdGF0ZTtcblxuICBpZiAodXRpbC5pc1N0cmluZyhjaHVuaykgJiYgIXN0YXRlLm9iamVjdE1vZGUpIHtcbiAgICBlbmNvZGluZyA9IGVuY29kaW5nIHx8IHN0YXRlLmRlZmF1bHRFbmNvZGluZztcbiAgICBpZiAoZW5jb2RpbmcgIT09IHN0YXRlLmVuY29kaW5nKSB7XG4gICAgICBjaHVuayA9IG5ldyBCdWZmZXIoY2h1bmssIGVuY29kaW5nKTtcbiAgICAgIGVuY29kaW5nID0gJyc7XG4gICAgfVxuICB9XG5cbiAgcmV0dXJuIHJlYWRhYmxlQWRkQ2h1bmsodGhpcywgc3RhdGUsIGNodW5rLCBlbmNvZGluZywgZmFsc2UpO1xufTtcblxuLy8gVW5zaGlmdCBzaG91bGQgKmFsd2F5cyogYmUgc29tZXRoaW5nIGRpcmVjdGx5IG91dCBvZiByZWFkKClcblJlYWRhYmxlLnByb3RvdHlwZS51bnNoaWZ0ID0gZnVuY3Rpb24oY2h1bmspIHtcbiAgdmFyIHN0YXRlID0gdGhpcy5fcmVhZGFibGVTdGF0ZTtcbiAgcmV0dXJuIHJlYWRhYmxlQWRkQ2h1bmsodGhpcywgc3RhdGUsIGNodW5rLCAnJywgdHJ1ZSk7XG59O1xuXG5mdW5jdGlvbiByZWFkYWJsZUFkZENodW5rKHN0cmVhbSwgc3RhdGUsIGNodW5rLCBlbmNvZGluZywgYWRkVG9Gcm9udCkge1xuICB2YXIgZXIgPSBjaHVua0ludmFsaWQoc3RhdGUsIGNodW5rKTtcbiAgaWYgKGVyKSB7XG4gICAgc3RyZWFtLmVtaXQoJ2Vycm9yJywgZXIpO1xuICB9IGVsc2UgaWYgKHV0aWwuaXNOdWxsT3JVbmRlZmluZWQoY2h1bmspKSB7XG4gICAgc3RhdGUucmVhZGluZyA9IGZhbHNlO1xuICAgIGlmICghc3RhdGUuZW5kZWQpXG4gICAgICBvbkVvZkNodW5rKHN0cmVhbSwgc3RhdGUpO1xuICB9IGVsc2UgaWYgKHN0YXRlLm9iamVjdE1vZGUgfHwgY2h1bmsgJiYgY2h1bmsubGVuZ3RoID4gMCkge1xuICAgIGlmIChzdGF0ZS5lbmRlZCAmJiAhYWRkVG9Gcm9udCkge1xuICAgICAgdmFyIGUgPSBuZXcgRXJyb3IoJ3N0cmVhbS5wdXNoKCkgYWZ0ZXIgRU9GJyk7XG4gICAgICBzdHJlYW0uZW1pdCgnZXJyb3InLCBlKTtcbiAgICB9IGVsc2UgaWYgKHN0YXRlLmVuZEVtaXR0ZWQgJiYgYWRkVG9Gcm9udCkge1xuICAgICAgdmFyIGUgPSBuZXcgRXJyb3IoJ3N0cmVhbS51bnNoaWZ0KCkgYWZ0ZXIgZW5kIGV2ZW50Jyk7XG4gICAgICBzdHJlYW0uZW1pdCgnZXJyb3InLCBlKTtcbiAgICB9IGVsc2Uge1xuICAgICAgaWYgKHN0YXRlLmRlY29kZXIgJiYgIWFkZFRvRnJvbnQgJiYgIWVuY29kaW5nKVxuICAgICAgICBjaHVuayA9IHN0YXRlLmRlY29kZXIud3JpdGUoY2h1bmspO1xuXG4gICAgICBpZiAoIWFkZFRvRnJvbnQpXG4gICAgICAgIHN0YXRlLnJlYWRpbmcgPSBmYWxzZTtcblxuICAgICAgLy8gaWYgd2Ugd2FudCB0aGUgZGF0YSBub3csIGp1c3QgZW1pdCBpdC5cbiAgICAgIGlmIChzdGF0ZS5mbG93aW5nICYmIHN0YXRlLmxlbmd0aCA9PT0gMCAmJiAhc3RhdGUuc3luYykge1xuICAgICAgICBzdHJlYW0uZW1pdCgnZGF0YScsIGNodW5rKTtcbiAgICAgICAgc3RyZWFtLnJlYWQoMCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICAvLyB1cGRhdGUgdGhlIGJ1ZmZlciBpbmZvLlxuICAgICAgICBzdGF0ZS5sZW5ndGggKz0gc3RhdGUub2JqZWN0TW9kZSA/IDEgOiBjaHVuay5sZW5ndGg7XG4gICAgICAgIGlmIChhZGRUb0Zyb250KVxuICAgICAgICAgIHN0YXRlLmJ1ZmZlci51bnNoaWZ0KGNodW5rKTtcbiAgICAgICAgZWxzZVxuICAgICAgICAgIHN0YXRlLmJ1ZmZlci5wdXNoKGNodW5rKTtcblxuICAgICAgICBpZiAoc3RhdGUubmVlZFJlYWRhYmxlKVxuICAgICAgICAgIGVtaXRSZWFkYWJsZShzdHJlYW0pO1xuICAgICAgfVxuXG4gICAgICBtYXliZVJlYWRNb3JlKHN0cmVhbSwgc3RhdGUpO1xuICAgIH1cbiAgfSBlbHNlIGlmICghYWRkVG9Gcm9udCkge1xuICAgIHN0YXRlLnJlYWRpbmcgPSBmYWxzZTtcbiAgfVxuXG4gIHJldHVybiBuZWVkTW9yZURhdGEoc3RhdGUpO1xufVxuXG5cblxuLy8gaWYgaXQncyBwYXN0IHRoZSBoaWdoIHdhdGVyIG1hcmssIHdlIGNhbiBwdXNoIGluIHNvbWUgbW9yZS5cbi8vIEFsc28sIGlmIHdlIGhhdmUgbm8gZGF0YSB5ZXQsIHdlIGNhbiBzdGFuZCBzb21lXG4vLyBtb3JlIGJ5dGVzLiAgVGhpcyBpcyB0byB3b3JrIGFyb3VuZCBjYXNlcyB3aGVyZSBod209MCxcbi8vIHN1Y2ggYXMgdGhlIHJlcGwuICBBbHNvLCBpZiB0aGUgcHVzaCgpIHRyaWdnZXJlZCBhXG4vLyByZWFkYWJsZSBldmVudCwgYW5kIHRoZSB1c2VyIGNhbGxlZCByZWFkKGxhcmdlTnVtYmVyKSBzdWNoIHRoYXRcbi8vIG5lZWRSZWFkYWJsZSB3YXMgc2V0LCB0aGVuIHdlIG91Z2h0IHRvIHB1c2ggbW9yZSwgc28gdGhhdCBhbm90aGVyXG4vLyAncmVhZGFibGUnIGV2ZW50IHdpbGwgYmUgdHJpZ2dlcmVkLlxuZnVuY3Rpb24gbmVlZE1vcmVEYXRhKHN0YXRlKSB7XG4gIHJldHVybiAhc3RhdGUuZW5kZWQgJiZcbiAgICAgICAgIChzdGF0ZS5uZWVkUmVhZGFibGUgfHxcbiAgICAgICAgICBzdGF0ZS5sZW5ndGggPCBzdGF0ZS5oaWdoV2F0ZXJNYXJrIHx8XG4gICAgICAgICAgc3RhdGUubGVuZ3RoID09PSAwKTtcbn1cblxuLy8gYmFja3dhcmRzIGNvbXBhdGliaWxpdHkuXG5SZWFkYWJsZS5wcm90b3R5cGUuc2V0RW5jb2RpbmcgPSBmdW5jdGlvbihlbmMpIHtcbiAgaWYgKCFTdHJpbmdEZWNvZGVyKVxuICAgIFN0cmluZ0RlY29kZXIgPSByZXF1aXJlKCdzdHJpbmdfZGVjb2Rlci8nKS5TdHJpbmdEZWNvZGVyO1xuICB0aGlzLl9yZWFkYWJsZVN0YXRlLmRlY29kZXIgPSBuZXcgU3RyaW5nRGVjb2RlcihlbmMpO1xuICB0aGlzLl9yZWFkYWJsZVN0YXRlLmVuY29kaW5nID0gZW5jO1xuICByZXR1cm4gdGhpcztcbn07XG5cbi8vIERvbid0IHJhaXNlIHRoZSBod20gPiAxMjhNQlxudmFyIE1BWF9IV00gPSAweDgwMDAwMDtcbmZ1bmN0aW9uIHJvdW5kVXBUb05leHRQb3dlck9mMihuKSB7XG4gIGlmIChuID49IE1BWF9IV00pIHtcbiAgICBuID0gTUFYX0hXTTtcbiAgfSBlbHNlIHtcbiAgICAvLyBHZXQgdGhlIG5leHQgaGlnaGVzdCBwb3dlciBvZiAyXG4gICAgbi0tO1xuICAgIGZvciAodmFyIHAgPSAxOyBwIDwgMzI7IHAgPDw9IDEpIG4gfD0gbiA+PiBwO1xuICAgIG4rKztcbiAgfVxuICByZXR1cm4gbjtcbn1cblxuZnVuY3Rpb24gaG93TXVjaFRvUmVhZChuLCBzdGF0ZSkge1xuICBpZiAoc3RhdGUubGVuZ3RoID09PSAwICYmIHN0YXRlLmVuZGVkKVxuICAgIHJldHVybiAwO1xuXG4gIGlmIChzdGF0ZS5vYmplY3RNb2RlKVxuICAgIHJldHVybiBuID09PSAwID8gMCA6IDE7XG5cbiAgaWYgKGlzTmFOKG4pIHx8IHV0aWwuaXNOdWxsKG4pKSB7XG4gICAgLy8gb25seSBmbG93IG9uZSBidWZmZXIgYXQgYSB0aW1lXG4gICAgaWYgKHN0YXRlLmZsb3dpbmcgJiYgc3RhdGUuYnVmZmVyLmxlbmd0aClcbiAgICAgIHJldHVybiBzdGF0ZS5idWZmZXJbMF0ubGVuZ3RoO1xuICAgIGVsc2VcbiAgICAgIHJldHVybiBzdGF0ZS5sZW5ndGg7XG4gIH1cblxuICBpZiAobiA8PSAwKVxuICAgIHJldHVybiAwO1xuXG4gIC8vIElmIHdlJ3JlIGFza2luZyBmb3IgbW9yZSB0aGFuIHRoZSB0YXJnZXQgYnVmZmVyIGxldmVsLFxuICAvLyB0aGVuIHJhaXNlIHRoZSB3YXRlciBtYXJrLiAgQnVtcCB1cCB0byB0aGUgbmV4dCBoaWdoZXN0XG4gIC8vIHBvd2VyIG9mIDIsIHRvIHByZXZlbnQgaW5jcmVhc2luZyBpdCBleGNlc3NpdmVseSBpbiB0aW55XG4gIC8vIGFtb3VudHMuXG4gIGlmIChuID4gc3RhdGUuaGlnaFdhdGVyTWFyaylcbiAgICBzdGF0ZS5oaWdoV2F0ZXJNYXJrID0gcm91bmRVcFRvTmV4dFBvd2VyT2YyKG4pO1xuXG4gIC8vIGRvbid0IGhhdmUgdGhhdCBtdWNoLiAgcmV0dXJuIG51bGwsIHVubGVzcyB3ZSd2ZSBlbmRlZC5cbiAgaWYgKG4gPiBzdGF0ZS5sZW5ndGgpIHtcbiAgICBpZiAoIXN0YXRlLmVuZGVkKSB7XG4gICAgICBzdGF0ZS5uZWVkUmVhZGFibGUgPSB0cnVlO1xuICAgICAgcmV0dXJuIDA7XG4gICAgfSBlbHNlXG4gICAgICByZXR1cm4gc3RhdGUubGVuZ3RoO1xuICB9XG5cbiAgcmV0dXJuIG47XG59XG5cbi8vIHlvdSBjYW4gb3ZlcnJpZGUgZWl0aGVyIHRoaXMgbWV0aG9kLCBvciB0aGUgYXN5bmMgX3JlYWQobikgYmVsb3cuXG5SZWFkYWJsZS5wcm90b3R5cGUucmVhZCA9IGZ1bmN0aW9uKG4pIHtcbiAgZGVidWcoJ3JlYWQnLCBuKTtcbiAgdmFyIHN0YXRlID0gdGhpcy5fcmVhZGFibGVTdGF0ZTtcbiAgdmFyIG5PcmlnID0gbjtcblxuICBpZiAoIXV0aWwuaXNOdW1iZXIobikgfHwgbiA+IDApXG4gICAgc3RhdGUuZW1pdHRlZFJlYWRhYmxlID0gZmFsc2U7XG5cbiAgLy8gaWYgd2UncmUgZG9pbmcgcmVhZCgwKSB0byB0cmlnZ2VyIGEgcmVhZGFibGUgZXZlbnQsIGJ1dCB3ZVxuICAvLyBhbHJlYWR5IGhhdmUgYSBidW5jaCBvZiBkYXRhIGluIHRoZSBidWZmZXIsIHRoZW4ganVzdCB0cmlnZ2VyXG4gIC8vIHRoZSAncmVhZGFibGUnIGV2ZW50IGFuZCBtb3ZlIG9uLlxuICBpZiAobiA9PT0gMCAmJlxuICAgICAgc3RhdGUubmVlZFJlYWRhYmxlICYmXG4gICAgICAoc3RhdGUubGVuZ3RoID49IHN0YXRlLmhpZ2hXYXRlck1hcmsgfHwgc3RhdGUuZW5kZWQpKSB7XG4gICAgZGVidWcoJ3JlYWQ6IGVtaXRSZWFkYWJsZScsIHN0YXRlLmxlbmd0aCwgc3RhdGUuZW5kZWQpO1xuICAgIGlmIChzdGF0ZS5sZW5ndGggPT09IDAgJiYgc3RhdGUuZW5kZWQpXG4gICAgICBlbmRSZWFkYWJsZSh0aGlzKTtcbiAgICBlbHNlXG4gICAgICBlbWl0UmVhZGFibGUodGhpcyk7XG4gICAgcmV0dXJuIG51bGw7XG4gIH1cblxuICBuID0gaG93TXVjaFRvUmVhZChuLCBzdGF0ZSk7XG5cbiAgLy8gaWYgd2UndmUgZW5kZWQsIGFuZCB3ZSdyZSBub3cgY2xlYXIsIHRoZW4gZmluaXNoIGl0IHVwLlxuICBpZiAobiA9PT0gMCAmJiBzdGF0ZS5lbmRlZCkge1xuICAgIGlmIChzdGF0ZS5sZW5ndGggPT09IDApXG4gICAgICBlbmRSZWFkYWJsZSh0aGlzKTtcbiAgICByZXR1cm4gbnVsbDtcbiAgfVxuXG4gIC8vIEFsbCB0aGUgYWN0dWFsIGNodW5rIGdlbmVyYXRpb24gbG9naWMgbmVlZHMgdG8gYmVcbiAgLy8gKmJlbG93KiB0aGUgY2FsbCB0byBfcmVhZC4gIFRoZSByZWFzb24gaXMgdGhhdCBpbiBjZXJ0YWluXG4gIC8vIHN5bnRoZXRpYyBzdHJlYW0gY2FzZXMsIHN1Y2ggYXMgcGFzc3Rocm91Z2ggc3RyZWFtcywgX3JlYWRcbiAgLy8gbWF5IGJlIGEgY29tcGxldGVseSBzeW5jaHJvbm91cyBvcGVyYXRpb24gd2hpY2ggbWF5IGNoYW5nZVxuICAvLyB0aGUgc3RhdGUgb2YgdGhlIHJlYWQgYnVmZmVyLCBwcm92aWRpbmcgZW5vdWdoIGRhdGEgd2hlblxuICAvLyBiZWZvcmUgdGhlcmUgd2FzICpub3QqIGVub3VnaC5cbiAgLy9cbiAgLy8gU28sIHRoZSBzdGVwcyBhcmU6XG4gIC8vIDEuIEZpZ3VyZSBvdXQgd2hhdCB0aGUgc3RhdGUgb2YgdGhpbmdzIHdpbGwgYmUgYWZ0ZXIgd2UgZG9cbiAgLy8gYSByZWFkIGZyb20gdGhlIGJ1ZmZlci5cbiAgLy9cbiAgLy8gMi4gSWYgdGhhdCByZXN1bHRpbmcgc3RhdGUgd2lsbCB0cmlnZ2VyIGEgX3JlYWQsIHRoZW4gY2FsbCBfcmVhZC5cbiAgLy8gTm90ZSB0aGF0IHRoaXMgbWF5IGJlIGFzeW5jaHJvbm91cywgb3Igc3luY2hyb25vdXMuICBZZXMsIGl0IGlzXG4gIC8vIGRlZXBseSB1Z2x5IHRvIHdyaXRlIEFQSXMgdGhpcyB3YXksIGJ1dCB0aGF0IHN0aWxsIGRvZXNuJ3QgbWVhblxuICAvLyB0aGF0IHRoZSBSZWFkYWJsZSBjbGFzcyBzaG91bGQgYmVoYXZlIGltcHJvcGVybHksIGFzIHN0cmVhbXMgYXJlXG4gIC8vIGRlc2lnbmVkIHRvIGJlIHN5bmMvYXN5bmMgYWdub3N0aWMuXG4gIC8vIFRha2Ugbm90ZSBpZiB0aGUgX3JlYWQgY2FsbCBpcyBzeW5jIG9yIGFzeW5jIChpZSwgaWYgdGhlIHJlYWQgY2FsbFxuICAvLyBoYXMgcmV0dXJuZWQgeWV0KSwgc28gdGhhdCB3ZSBrbm93IHdoZXRoZXIgb3Igbm90IGl0J3Mgc2FmZSB0byBlbWl0XG4gIC8vICdyZWFkYWJsZScgZXRjLlxuICAvL1xuICAvLyAzLiBBY3R1YWxseSBwdWxsIHRoZSByZXF1ZXN0ZWQgY2h1bmtzIG91dCBvZiB0aGUgYnVmZmVyIGFuZCByZXR1cm4uXG5cbiAgLy8gaWYgd2UgbmVlZCBhIHJlYWRhYmxlIGV2ZW50LCB0aGVuIHdlIG5lZWQgdG8gZG8gc29tZSByZWFkaW5nLlxuICB2YXIgZG9SZWFkID0gc3RhdGUubmVlZFJlYWRhYmxlO1xuICBkZWJ1ZygnbmVlZCByZWFkYWJsZScsIGRvUmVhZCk7XG5cbiAgLy8gaWYgd2UgY3VycmVudGx5IGhhdmUgbGVzcyB0aGFuIHRoZSBoaWdoV2F0ZXJNYXJrLCB0aGVuIGFsc28gcmVhZCBzb21lXG4gIGlmIChzdGF0ZS5sZW5ndGggPT09IDAgfHwgc3RhdGUubGVuZ3RoIC0gbiA8IHN0YXRlLmhpZ2hXYXRlck1hcmspIHtcbiAgICBkb1JlYWQgPSB0cnVlO1xuICAgIGRlYnVnKCdsZW5ndGggbGVzcyB0aGFuIHdhdGVybWFyaycsIGRvUmVhZCk7XG4gIH1cblxuICAvLyBob3dldmVyLCBpZiB3ZSd2ZSBlbmRlZCwgdGhlbiB0aGVyZSdzIG5vIHBvaW50LCBhbmQgaWYgd2UncmUgYWxyZWFkeVxuICAvLyByZWFkaW5nLCB0aGVuIGl0J3MgdW5uZWNlc3NhcnkuXG4gIGlmIChzdGF0ZS5lbmRlZCB8fCBzdGF0ZS5yZWFkaW5nKSB7XG4gICAgZG9SZWFkID0gZmFsc2U7XG4gICAgZGVidWcoJ3JlYWRpbmcgb3IgZW5kZWQnLCBkb1JlYWQpO1xuICB9XG5cbiAgaWYgKGRvUmVhZCkge1xuICAgIGRlYnVnKCdkbyByZWFkJyk7XG4gICAgc3RhdGUucmVhZGluZyA9IHRydWU7XG4gICAgc3RhdGUuc3luYyA9IHRydWU7XG4gICAgLy8gaWYgdGhlIGxlbmd0aCBpcyBjdXJyZW50bHkgemVybywgdGhlbiB3ZSAqbmVlZCogYSByZWFkYWJsZSBldmVudC5cbiAgICBpZiAoc3RhdGUubGVuZ3RoID09PSAwKVxuICAgICAgc3RhdGUubmVlZFJlYWRhYmxlID0gdHJ1ZTtcbiAgICAvLyBjYWxsIGludGVybmFsIHJlYWQgbWV0aG9kXG4gICAgdGhpcy5fcmVhZChzdGF0ZS5oaWdoV2F0ZXJNYXJrKTtcbiAgICBzdGF0ZS5zeW5jID0gZmFsc2U7XG4gIH1cblxuICAvLyBJZiBfcmVhZCBwdXNoZWQgZGF0YSBzeW5jaHJvbm91c2x5LCB0aGVuIGByZWFkaW5nYCB3aWxsIGJlIGZhbHNlLFxuICAvLyBhbmQgd2UgbmVlZCB0byByZS1ldmFsdWF0ZSBob3cgbXVjaCBkYXRhIHdlIGNhbiByZXR1cm4gdG8gdGhlIHVzZXIuXG4gIGlmIChkb1JlYWQgJiYgIXN0YXRlLnJlYWRpbmcpXG4gICAgbiA9IGhvd011Y2hUb1JlYWQobk9yaWcsIHN0YXRlKTtcblxuICB2YXIgcmV0O1xuICBpZiAobiA+IDApXG4gICAgcmV0ID0gZnJvbUxpc3Qobiwgc3RhdGUpO1xuICBlbHNlXG4gICAgcmV0ID0gbnVsbDtcblxuICBpZiAodXRpbC5pc051bGwocmV0KSkge1xuICAgIHN0YXRlLm5lZWRSZWFkYWJsZSA9IHRydWU7XG4gICAgbiA9IDA7XG4gIH1cblxuICBzdGF0ZS5sZW5ndGggLT0gbjtcblxuICAvLyBJZiB3ZSBoYXZlIG5vdGhpbmcgaW4gdGhlIGJ1ZmZlciwgdGhlbiB3ZSB3YW50IHRvIGtub3dcbiAgLy8gYXMgc29vbiBhcyB3ZSAqZG8qIGdldCBzb21ldGhpbmcgaW50byB0aGUgYnVmZmVyLlxuICBpZiAoc3RhdGUubGVuZ3RoID09PSAwICYmICFzdGF0ZS5lbmRlZClcbiAgICBzdGF0ZS5uZWVkUmVhZGFibGUgPSB0cnVlO1xuXG4gIC8vIElmIHdlIHRyaWVkIHRvIHJlYWQoKSBwYXN0IHRoZSBFT0YsIHRoZW4gZW1pdCBlbmQgb24gdGhlIG5leHQgdGljay5cbiAgaWYgKG5PcmlnICE9PSBuICYmIHN0YXRlLmVuZGVkICYmIHN0YXRlLmxlbmd0aCA9PT0gMClcbiAgICBlbmRSZWFkYWJsZSh0aGlzKTtcblxuICBpZiAoIXV0aWwuaXNOdWxsKHJldCkpXG4gICAgdGhpcy5lbWl0KCdkYXRhJywgcmV0KTtcblxuICByZXR1cm4gcmV0O1xufTtcblxuZnVuY3Rpb24gY2h1bmtJbnZhbGlkKHN0YXRlLCBjaHVuaykge1xuICB2YXIgZXIgPSBudWxsO1xuICBpZiAoIXV0aWwuaXNCdWZmZXIoY2h1bmspICYmXG4gICAgICAhdXRpbC5pc1N0cmluZyhjaHVuaykgJiZcbiAgICAgICF1dGlsLmlzTnVsbE9yVW5kZWZpbmVkKGNodW5rKSAmJlxuICAgICAgIXN0YXRlLm9iamVjdE1vZGUpIHtcbiAgICBlciA9IG5ldyBUeXBlRXJyb3IoJ0ludmFsaWQgbm9uLXN0cmluZy9idWZmZXIgY2h1bmsnKTtcbiAgfVxuICByZXR1cm4gZXI7XG59XG5cblxuZnVuY3Rpb24gb25Fb2ZDaHVuayhzdHJlYW0sIHN0YXRlKSB7XG4gIGlmIChzdGF0ZS5kZWNvZGVyICYmICFzdGF0ZS5lbmRlZCkge1xuICAgIHZhciBjaHVuayA9IHN0YXRlLmRlY29kZXIuZW5kKCk7XG4gICAgaWYgKGNodW5rICYmIGNodW5rLmxlbmd0aCkge1xuICAgICAgc3RhdGUuYnVmZmVyLnB1c2goY2h1bmspO1xuICAgICAgc3RhdGUubGVuZ3RoICs9IHN0YXRlLm9iamVjdE1vZGUgPyAxIDogY2h1bmsubGVuZ3RoO1xuICAgIH1cbiAgfVxuICBzdGF0ZS5lbmRlZCA9IHRydWU7XG5cbiAgLy8gZW1pdCAncmVhZGFibGUnIG5vdyB0byBtYWtlIHN1cmUgaXQgZ2V0cyBwaWNrZWQgdXAuXG4gIGVtaXRSZWFkYWJsZShzdHJlYW0pO1xufVxuXG4vLyBEb24ndCBlbWl0IHJlYWRhYmxlIHJpZ2h0IGF3YXkgaW4gc3luYyBtb2RlLCBiZWNhdXNlIHRoaXMgY2FuIHRyaWdnZXJcbi8vIGFub3RoZXIgcmVhZCgpIGNhbGwgPT4gc3RhY2sgb3ZlcmZsb3cuICBUaGlzIHdheSwgaXQgbWlnaHQgdHJpZ2dlclxuLy8gYSBuZXh0VGljayByZWN1cnNpb24gd2FybmluZywgYnV0IHRoYXQncyBub3Qgc28gYmFkLlxuZnVuY3Rpb24gZW1pdFJlYWRhYmxlKHN0cmVhbSkge1xuICB2YXIgc3RhdGUgPSBzdHJlYW0uX3JlYWRhYmxlU3RhdGU7XG4gIHN0YXRlLm5lZWRSZWFkYWJsZSA9IGZhbHNlO1xuICBpZiAoIXN0YXRlLmVtaXR0ZWRSZWFkYWJsZSkge1xuICAgIGRlYnVnKCdlbWl0UmVhZGFibGUnLCBzdGF0ZS5mbG93aW5nKTtcbiAgICBzdGF0ZS5lbWl0dGVkUmVhZGFibGUgPSB0cnVlO1xuICAgIGlmIChzdGF0ZS5zeW5jKVxuICAgICAgcHJvY2Vzcy5uZXh0VGljayhmdW5jdGlvbigpIHtcbiAgICAgICAgZW1pdFJlYWRhYmxlXyhzdHJlYW0pO1xuICAgICAgfSk7XG4gICAgZWxzZVxuICAgICAgZW1pdFJlYWRhYmxlXyhzdHJlYW0pO1xuICB9XG59XG5cbmZ1bmN0aW9uIGVtaXRSZWFkYWJsZV8oc3RyZWFtKSB7XG4gIGRlYnVnKCdlbWl0IHJlYWRhYmxlJyk7XG4gIHN0cmVhbS5lbWl0KCdyZWFkYWJsZScpO1xuICBmbG93KHN0cmVhbSk7XG59XG5cblxuLy8gYXQgdGhpcyBwb2ludCwgdGhlIHVzZXIgaGFzIHByZXN1bWFibHkgc2VlbiB0aGUgJ3JlYWRhYmxlJyBldmVudCxcbi8vIGFuZCBjYWxsZWQgcmVhZCgpIHRvIGNvbnN1bWUgc29tZSBkYXRhLiAgdGhhdCBtYXkgaGF2ZSB0cmlnZ2VyZWRcbi8vIGluIHR1cm4gYW5vdGhlciBfcmVhZChuKSBjYWxsLCBpbiB3aGljaCBjYXNlIHJlYWRpbmcgPSB0cnVlIGlmXG4vLyBpdCdzIGluIHByb2dyZXNzLlxuLy8gSG93ZXZlciwgaWYgd2UncmUgbm90IGVuZGVkLCBvciByZWFkaW5nLCBhbmQgdGhlIGxlbmd0aCA8IGh3bSxcbi8vIHRoZW4gZ28gYWhlYWQgYW5kIHRyeSB0byByZWFkIHNvbWUgbW9yZSBwcmVlbXB0aXZlbHkuXG5mdW5jdGlvbiBtYXliZVJlYWRNb3JlKHN0cmVhbSwgc3RhdGUpIHtcbiAgaWYgKCFzdGF0ZS5yZWFkaW5nTW9yZSkge1xuICAgIHN0YXRlLnJlYWRpbmdNb3JlID0gdHJ1ZTtcbiAgICBwcm9jZXNzLm5leHRUaWNrKGZ1bmN0aW9uKCkge1xuICAgICAgbWF5YmVSZWFkTW9yZV8oc3RyZWFtLCBzdGF0ZSk7XG4gICAgfSk7XG4gIH1cbn1cblxuZnVuY3Rpb24gbWF5YmVSZWFkTW9yZV8oc3RyZWFtLCBzdGF0ZSkge1xuICB2YXIgbGVuID0gc3RhdGUubGVuZ3RoO1xuICB3aGlsZSAoIXN0YXRlLnJlYWRpbmcgJiYgIXN0YXRlLmZsb3dpbmcgJiYgIXN0YXRlLmVuZGVkICYmXG4gICAgICAgICBzdGF0ZS5sZW5ndGggPCBzdGF0ZS5oaWdoV2F0ZXJNYXJrKSB7XG4gICAgZGVidWcoJ21heWJlUmVhZE1vcmUgcmVhZCAwJyk7XG4gICAgc3RyZWFtLnJlYWQoMCk7XG4gICAgaWYgKGxlbiA9PT0gc3RhdGUubGVuZ3RoKVxuICAgICAgLy8gZGlkbid0IGdldCBhbnkgZGF0YSwgc3RvcCBzcGlubmluZy5cbiAgICAgIGJyZWFrO1xuICAgIGVsc2VcbiAgICAgIGxlbiA9IHN0YXRlLmxlbmd0aDtcbiAgfVxuICBzdGF0ZS5yZWFkaW5nTW9yZSA9IGZhbHNlO1xufVxuXG4vLyBhYnN0cmFjdCBtZXRob2QuICB0byBiZSBvdmVycmlkZGVuIGluIHNwZWNpZmljIGltcGxlbWVudGF0aW9uIGNsYXNzZXMuXG4vLyBjYWxsIGNiKGVyLCBkYXRhKSB3aGVyZSBkYXRhIGlzIDw9IG4gaW4gbGVuZ3RoLlxuLy8gZm9yIHZpcnR1YWwgKG5vbi1zdHJpbmcsIG5vbi1idWZmZXIpIHN0cmVhbXMsIFwibGVuZ3RoXCIgaXMgc29tZXdoYXRcbi8vIGFyYml0cmFyeSwgYW5kIHBlcmhhcHMgbm90IHZlcnkgbWVhbmluZ2Z1bC5cblJlYWRhYmxlLnByb3RvdHlwZS5fcmVhZCA9IGZ1bmN0aW9uKG4pIHtcbiAgdGhpcy5lbWl0KCdlcnJvcicsIG5ldyBFcnJvcignbm90IGltcGxlbWVudGVkJykpO1xufTtcblxuUmVhZGFibGUucHJvdG90eXBlLnBpcGUgPSBmdW5jdGlvbihkZXN0LCBwaXBlT3B0cykge1xuICB2YXIgc3JjID0gdGhpcztcbiAgdmFyIHN0YXRlID0gdGhpcy5fcmVhZGFibGVTdGF0ZTtcblxuICBzd2l0Y2ggKHN0YXRlLnBpcGVzQ291bnQpIHtcbiAgICBjYXNlIDA6XG4gICAgICBzdGF0ZS5waXBlcyA9IGRlc3Q7XG4gICAgICBicmVhaztcbiAgICBjYXNlIDE6XG4gICAgICBzdGF0ZS5waXBlcyA9IFtzdGF0ZS5waXBlcywgZGVzdF07XG4gICAgICBicmVhaztcbiAgICBkZWZhdWx0OlxuICAgICAgc3RhdGUucGlwZXMucHVzaChkZXN0KTtcbiAgICAgIGJyZWFrO1xuICB9XG4gIHN0YXRlLnBpcGVzQ291bnQgKz0gMTtcbiAgZGVidWcoJ3BpcGUgY291bnQ9JWQgb3B0cz0laicsIHN0YXRlLnBpcGVzQ291bnQsIHBpcGVPcHRzKTtcblxuICB2YXIgZG9FbmQgPSAoIXBpcGVPcHRzIHx8IHBpcGVPcHRzLmVuZCAhPT0gZmFsc2UpICYmXG4gICAgICAgICAgICAgIGRlc3QgIT09IHByb2Nlc3Muc3Rkb3V0ICYmXG4gICAgICAgICAgICAgIGRlc3QgIT09IHByb2Nlc3Muc3RkZXJyO1xuXG4gIHZhciBlbmRGbiA9IGRvRW5kID8gb25lbmQgOiBjbGVhbnVwO1xuICBpZiAoc3RhdGUuZW5kRW1pdHRlZClcbiAgICBwcm9jZXNzLm5leHRUaWNrKGVuZEZuKTtcbiAgZWxzZVxuICAgIHNyYy5vbmNlKCdlbmQnLCBlbmRGbik7XG5cbiAgZGVzdC5vbigndW5waXBlJywgb251bnBpcGUpO1xuICBmdW5jdGlvbiBvbnVucGlwZShyZWFkYWJsZSkge1xuICAgIGRlYnVnKCdvbnVucGlwZScpO1xuICAgIGlmIChyZWFkYWJsZSA9PT0gc3JjKSB7XG4gICAgICBjbGVhbnVwKCk7XG4gICAgfVxuICB9XG5cbiAgZnVuY3Rpb24gb25lbmQoKSB7XG4gICAgZGVidWcoJ29uZW5kJyk7XG4gICAgZGVzdC5lbmQoKTtcbiAgfVxuXG4gIC8vIHdoZW4gdGhlIGRlc3QgZHJhaW5zLCBpdCByZWR1Y2VzIHRoZSBhd2FpdERyYWluIGNvdW50ZXJcbiAgLy8gb24gdGhlIHNvdXJjZS4gIFRoaXMgd291bGQgYmUgbW9yZSBlbGVnYW50IHdpdGggYSAub25jZSgpXG4gIC8vIGhhbmRsZXIgaW4gZmxvdygpLCBidXQgYWRkaW5nIGFuZCByZW1vdmluZyByZXBlYXRlZGx5IGlzXG4gIC8vIHRvbyBzbG93LlxuICB2YXIgb25kcmFpbiA9IHBpcGVPbkRyYWluKHNyYyk7XG4gIGRlc3Qub24oJ2RyYWluJywgb25kcmFpbik7XG5cbiAgZnVuY3Rpb24gY2xlYW51cCgpIHtcbiAgICBkZWJ1ZygnY2xlYW51cCcpO1xuICAgIC8vIGNsZWFudXAgZXZlbnQgaGFuZGxlcnMgb25jZSB0aGUgcGlwZSBpcyBicm9rZW5cbiAgICBkZXN0LnJlbW92ZUxpc3RlbmVyKCdjbG9zZScsIG9uY2xvc2UpO1xuICAgIGRlc3QucmVtb3ZlTGlzdGVuZXIoJ2ZpbmlzaCcsIG9uZmluaXNoKTtcbiAgICBkZXN0LnJlbW92ZUxpc3RlbmVyKCdkcmFpbicsIG9uZHJhaW4pO1xuICAgIGRlc3QucmVtb3ZlTGlzdGVuZXIoJ2Vycm9yJywgb25lcnJvcik7XG4gICAgZGVzdC5yZW1vdmVMaXN0ZW5lcigndW5waXBlJywgb251bnBpcGUpO1xuICAgIHNyYy5yZW1vdmVMaXN0ZW5lcignZW5kJywgb25lbmQpO1xuICAgIHNyYy5yZW1vdmVMaXN0ZW5lcignZW5kJywgY2xlYW51cCk7XG4gICAgc3JjLnJlbW92ZUxpc3RlbmVyKCdkYXRhJywgb25kYXRhKTtcblxuICAgIC8vIGlmIHRoZSByZWFkZXIgaXMgd2FpdGluZyBmb3IgYSBkcmFpbiBldmVudCBmcm9tIHRoaXNcbiAgICAvLyBzcGVjaWZpYyB3cml0ZXIsIHRoZW4gaXQgd291bGQgY2F1c2UgaXQgdG8gbmV2ZXIgc3RhcnRcbiAgICAvLyBmbG93aW5nIGFnYWluLlxuICAgIC8vIFNvLCBpZiB0aGlzIGlzIGF3YWl0aW5nIGEgZHJhaW4sIHRoZW4gd2UganVzdCBjYWxsIGl0IG5vdy5cbiAgICAvLyBJZiB3ZSBkb24ndCBrbm93LCB0aGVuIGFzc3VtZSB0aGF0IHdlIGFyZSB3YWl0aW5nIGZvciBvbmUuXG4gICAgaWYgKHN0YXRlLmF3YWl0RHJhaW4gJiZcbiAgICAgICAgKCFkZXN0Ll93cml0YWJsZVN0YXRlIHx8IGRlc3QuX3dyaXRhYmxlU3RhdGUubmVlZERyYWluKSlcbiAgICAgIG9uZHJhaW4oKTtcbiAgfVxuXG4gIHNyYy5vbignZGF0YScsIG9uZGF0YSk7XG4gIGZ1bmN0aW9uIG9uZGF0YShjaHVuaykge1xuICAgIGRlYnVnKCdvbmRhdGEnKTtcbiAgICB2YXIgcmV0ID0gZGVzdC53cml0ZShjaHVuayk7XG4gICAgaWYgKGZhbHNlID09PSByZXQpIHtcbiAgICAgIGRlYnVnKCdmYWxzZSB3cml0ZSByZXNwb25zZSwgcGF1c2UnLFxuICAgICAgICAgICAgc3JjLl9yZWFkYWJsZVN0YXRlLmF3YWl0RHJhaW4pO1xuICAgICAgc3JjLl9yZWFkYWJsZVN0YXRlLmF3YWl0RHJhaW4rKztcbiAgICAgIHNyYy5wYXVzZSgpO1xuICAgIH1cbiAgfVxuXG4gIC8vIGlmIHRoZSBkZXN0IGhhcyBhbiBlcnJvciwgdGhlbiBzdG9wIHBpcGluZyBpbnRvIGl0LlxuICAvLyBob3dldmVyLCBkb24ndCBzdXBwcmVzcyB0aGUgdGhyb3dpbmcgYmVoYXZpb3IgZm9yIHRoaXMuXG4gIGZ1bmN0aW9uIG9uZXJyb3IoZXIpIHtcbiAgICBkZWJ1Zygnb25lcnJvcicsIGVyKTtcbiAgICB1bnBpcGUoKTtcbiAgICBkZXN0LnJlbW92ZUxpc3RlbmVyKCdlcnJvcicsIG9uZXJyb3IpO1xuICAgIGlmIChFRS5saXN0ZW5lckNvdW50KGRlc3QsICdlcnJvcicpID09PSAwKVxuICAgICAgZGVzdC5lbWl0KCdlcnJvcicsIGVyKTtcbiAgfVxuICAvLyBUaGlzIGlzIGEgYnJ1dGFsbHkgdWdseSBoYWNrIHRvIG1ha2Ugc3VyZSB0aGF0IG91ciBlcnJvciBoYW5kbGVyXG4gIC8vIGlzIGF0dGFjaGVkIGJlZm9yZSBhbnkgdXNlcmxhbmQgb25lcy4gIE5FVkVSIERPIFRISVMuXG4gIGlmICghZGVzdC5fZXZlbnRzIHx8ICFkZXN0Ll9ldmVudHMuZXJyb3IpXG4gICAgZGVzdC5vbignZXJyb3InLCBvbmVycm9yKTtcbiAgZWxzZSBpZiAoaXNBcnJheShkZXN0Ll9ldmVudHMuZXJyb3IpKVxuICAgIGRlc3QuX2V2ZW50cy5lcnJvci51bnNoaWZ0KG9uZXJyb3IpO1xuICBlbHNlXG4gICAgZGVzdC5fZXZlbnRzLmVycm9yID0gW29uZXJyb3IsIGRlc3QuX2V2ZW50cy5lcnJvcl07XG5cblxuXG4gIC8vIEJvdGggY2xvc2UgYW5kIGZpbmlzaCBzaG91bGQgdHJpZ2dlciB1bnBpcGUsIGJ1dCBvbmx5IG9uY2UuXG4gIGZ1bmN0aW9uIG9uY2xvc2UoKSB7XG4gICAgZGVzdC5yZW1vdmVMaXN0ZW5lcignZmluaXNoJywgb25maW5pc2gpO1xuICAgIHVucGlwZSgpO1xuICB9XG4gIGRlc3Qub25jZSgnY2xvc2UnLCBvbmNsb3NlKTtcbiAgZnVuY3Rpb24gb25maW5pc2goKSB7XG4gICAgZGVidWcoJ29uZmluaXNoJyk7XG4gICAgZGVzdC5yZW1vdmVMaXN0ZW5lcignY2xvc2UnLCBvbmNsb3NlKTtcbiAgICB1bnBpcGUoKTtcbiAgfVxuICBkZXN0Lm9uY2UoJ2ZpbmlzaCcsIG9uZmluaXNoKTtcblxuICBmdW5jdGlvbiB1bnBpcGUoKSB7XG4gICAgZGVidWcoJ3VucGlwZScpO1xuICAgIHNyYy51bnBpcGUoZGVzdCk7XG4gIH1cblxuICAvLyB0ZWxsIHRoZSBkZXN0IHRoYXQgaXQncyBiZWluZyBwaXBlZCB0b1xuICBkZXN0LmVtaXQoJ3BpcGUnLCBzcmMpO1xuXG4gIC8vIHN0YXJ0IHRoZSBmbG93IGlmIGl0IGhhc24ndCBiZWVuIHN0YXJ0ZWQgYWxyZWFkeS5cbiAgaWYgKCFzdGF0ZS5mbG93aW5nKSB7XG4gICAgZGVidWcoJ3BpcGUgcmVzdW1lJyk7XG4gICAgc3JjLnJlc3VtZSgpO1xuICB9XG5cbiAgcmV0dXJuIGRlc3Q7XG59O1xuXG5mdW5jdGlvbiBwaXBlT25EcmFpbihzcmMpIHtcbiAgcmV0dXJuIGZ1bmN0aW9uKCkge1xuICAgIHZhciBzdGF0ZSA9IHNyYy5fcmVhZGFibGVTdGF0ZTtcbiAgICBkZWJ1ZygncGlwZU9uRHJhaW4nLCBzdGF0ZS5hd2FpdERyYWluKTtcbiAgICBpZiAoc3RhdGUuYXdhaXREcmFpbilcbiAgICAgIHN0YXRlLmF3YWl0RHJhaW4tLTtcbiAgICBpZiAoc3RhdGUuYXdhaXREcmFpbiA9PT0gMCAmJiBFRS5saXN0ZW5lckNvdW50KHNyYywgJ2RhdGEnKSkge1xuICAgICAgc3RhdGUuZmxvd2luZyA9IHRydWU7XG4gICAgICBmbG93KHNyYyk7XG4gICAgfVxuICB9O1xufVxuXG5cblJlYWRhYmxlLnByb3RvdHlwZS51bnBpcGUgPSBmdW5jdGlvbihkZXN0KSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3JlYWRhYmxlU3RhdGU7XG5cbiAgLy8gaWYgd2UncmUgbm90IHBpcGluZyBhbnl3aGVyZSwgdGhlbiBkbyBub3RoaW5nLlxuICBpZiAoc3RhdGUucGlwZXNDb3VudCA9PT0gMClcbiAgICByZXR1cm4gdGhpcztcblxuICAvLyBqdXN0IG9uZSBkZXN0aW5hdGlvbi4gIG1vc3QgY29tbW9uIGNhc2UuXG4gIGlmIChzdGF0ZS5waXBlc0NvdW50ID09PSAxKSB7XG4gICAgLy8gcGFzc2VkIGluIG9uZSwgYnV0IGl0J3Mgbm90IHRoZSByaWdodCBvbmUuXG4gICAgaWYgKGRlc3QgJiYgZGVzdCAhPT0gc3RhdGUucGlwZXMpXG4gICAgICByZXR1cm4gdGhpcztcblxuICAgIGlmICghZGVzdClcbiAgICAgIGRlc3QgPSBzdGF0ZS5waXBlcztcblxuICAgIC8vIGdvdCBhIG1hdGNoLlxuICAgIHN0YXRlLnBpcGVzID0gbnVsbDtcbiAgICBzdGF0ZS5waXBlc0NvdW50ID0gMDtcbiAgICBzdGF0ZS5mbG93aW5nID0gZmFsc2U7XG4gICAgaWYgKGRlc3QpXG4gICAgICBkZXN0LmVtaXQoJ3VucGlwZScsIHRoaXMpO1xuICAgIHJldHVybiB0aGlzO1xuICB9XG5cbiAgLy8gc2xvdyBjYXNlLiBtdWx0aXBsZSBwaXBlIGRlc3RpbmF0aW9ucy5cblxuICBpZiAoIWRlc3QpIHtcbiAgICAvLyByZW1vdmUgYWxsLlxuICAgIHZhciBkZXN0cyA9IHN0YXRlLnBpcGVzO1xuICAgIHZhciBsZW4gPSBzdGF0ZS5waXBlc0NvdW50O1xuICAgIHN0YXRlLnBpcGVzID0gbnVsbDtcbiAgICBzdGF0ZS5waXBlc0NvdW50ID0gMDtcbiAgICBzdGF0ZS5mbG93aW5nID0gZmFsc2U7XG5cbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGxlbjsgaSsrKVxuICAgICAgZGVzdHNbaV0uZW1pdCgndW5waXBlJywgdGhpcyk7XG4gICAgcmV0dXJuIHRoaXM7XG4gIH1cblxuICAvLyB0cnkgdG8gZmluZCB0aGUgcmlnaHQgb25lLlxuICB2YXIgaSA9IGluZGV4T2Yoc3RhdGUucGlwZXMsIGRlc3QpO1xuICBpZiAoaSA9PT0gLTEpXG4gICAgcmV0dXJuIHRoaXM7XG5cbiAgc3RhdGUucGlwZXMuc3BsaWNlKGksIDEpO1xuICBzdGF0ZS5waXBlc0NvdW50IC09IDE7XG4gIGlmIChzdGF0ZS5waXBlc0NvdW50ID09PSAxKVxuICAgIHN0YXRlLnBpcGVzID0gc3RhdGUucGlwZXNbMF07XG5cbiAgZGVzdC5lbWl0KCd1bnBpcGUnLCB0aGlzKTtcblxuICByZXR1cm4gdGhpcztcbn07XG5cbi8vIHNldCB1cCBkYXRhIGV2ZW50cyBpZiB0aGV5IGFyZSBhc2tlZCBmb3Jcbi8vIEVuc3VyZSByZWFkYWJsZSBsaXN0ZW5lcnMgZXZlbnR1YWxseSBnZXQgc29tZXRoaW5nXG5SZWFkYWJsZS5wcm90b3R5cGUub24gPSBmdW5jdGlvbihldiwgZm4pIHtcbiAgdmFyIHJlcyA9IFN0cmVhbS5wcm90b3R5cGUub24uY2FsbCh0aGlzLCBldiwgZm4pO1xuXG4gIC8vIElmIGxpc3RlbmluZyB0byBkYXRhLCBhbmQgaXQgaGFzIG5vdCBleHBsaWNpdGx5IGJlZW4gcGF1c2VkLFxuICAvLyB0aGVuIGNhbGwgcmVzdW1lIHRvIHN0YXJ0IHRoZSBmbG93IG9mIGRhdGEgb24gdGhlIG5leHQgdGljay5cbiAgaWYgKGV2ID09PSAnZGF0YScgJiYgZmFsc2UgIT09IHRoaXMuX3JlYWRhYmxlU3RhdGUuZmxvd2luZykge1xuICAgIHRoaXMucmVzdW1lKCk7XG4gIH1cblxuICBpZiAoZXYgPT09ICdyZWFkYWJsZScgJiYgdGhpcy5yZWFkYWJsZSkge1xuICAgIHZhciBzdGF0ZSA9IHRoaXMuX3JlYWRhYmxlU3RhdGU7XG4gICAgaWYgKCFzdGF0ZS5yZWFkYWJsZUxpc3RlbmluZykge1xuICAgICAgc3RhdGUucmVhZGFibGVMaXN0ZW5pbmcgPSB0cnVlO1xuICAgICAgc3RhdGUuZW1pdHRlZFJlYWRhYmxlID0gZmFsc2U7XG4gICAgICBzdGF0ZS5uZWVkUmVhZGFibGUgPSB0cnVlO1xuICAgICAgaWYgKCFzdGF0ZS5yZWFkaW5nKSB7XG4gICAgICAgIHZhciBzZWxmID0gdGhpcztcbiAgICAgICAgcHJvY2Vzcy5uZXh0VGljayhmdW5jdGlvbigpIHtcbiAgICAgICAgICBkZWJ1ZygncmVhZGFibGUgbmV4dHRpY2sgcmVhZCAwJyk7XG4gICAgICAgICAgc2VsZi5yZWFkKDApO1xuICAgICAgICB9KTtcbiAgICAgIH0gZWxzZSBpZiAoc3RhdGUubGVuZ3RoKSB7XG4gICAgICAgIGVtaXRSZWFkYWJsZSh0aGlzLCBzdGF0ZSk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgcmV0dXJuIHJlcztcbn07XG5SZWFkYWJsZS5wcm90b3R5cGUuYWRkTGlzdGVuZXIgPSBSZWFkYWJsZS5wcm90b3R5cGUub247XG5cbi8vIHBhdXNlKCkgYW5kIHJlc3VtZSgpIGFyZSByZW1uYW50cyBvZiB0aGUgbGVnYWN5IHJlYWRhYmxlIHN0cmVhbSBBUElcbi8vIElmIHRoZSB1c2VyIHVzZXMgdGhlbSwgdGhlbiBzd2l0Y2ggaW50byBvbGQgbW9kZS5cblJlYWRhYmxlLnByb3RvdHlwZS5yZXN1bWUgPSBmdW5jdGlvbigpIHtcbiAgdmFyIHN0YXRlID0gdGhpcy5fcmVhZGFibGVTdGF0ZTtcbiAgaWYgKCFzdGF0ZS5mbG93aW5nKSB7XG4gICAgZGVidWcoJ3Jlc3VtZScpO1xuICAgIHN0YXRlLmZsb3dpbmcgPSB0cnVlO1xuICAgIGlmICghc3RhdGUucmVhZGluZykge1xuICAgICAgZGVidWcoJ3Jlc3VtZSByZWFkIDAnKTtcbiAgICAgIHRoaXMucmVhZCgwKTtcbiAgICB9XG4gICAgcmVzdW1lKHRoaXMsIHN0YXRlKTtcbiAgfVxuICByZXR1cm4gdGhpcztcbn07XG5cbmZ1bmN0aW9uIHJlc3VtZShzdHJlYW0sIHN0YXRlKSB7XG4gIGlmICghc3RhdGUucmVzdW1lU2NoZWR1bGVkKSB7XG4gICAgc3RhdGUucmVzdW1lU2NoZWR1bGVkID0gdHJ1ZTtcbiAgICBwcm9jZXNzLm5leHRUaWNrKGZ1bmN0aW9uKCkge1xuICAgICAgcmVzdW1lXyhzdHJlYW0sIHN0YXRlKTtcbiAgICB9KTtcbiAgfVxufVxuXG5mdW5jdGlvbiByZXN1bWVfKHN0cmVhbSwgc3RhdGUpIHtcbiAgc3RhdGUucmVzdW1lU2NoZWR1bGVkID0gZmFsc2U7XG4gIHN0cmVhbS5lbWl0KCdyZXN1bWUnKTtcbiAgZmxvdyhzdHJlYW0pO1xuICBpZiAoc3RhdGUuZmxvd2luZyAmJiAhc3RhdGUucmVhZGluZylcbiAgICBzdHJlYW0ucmVhZCgwKTtcbn1cblxuUmVhZGFibGUucHJvdG90eXBlLnBhdXNlID0gZnVuY3Rpb24oKSB7XG4gIGRlYnVnKCdjYWxsIHBhdXNlIGZsb3dpbmc9JWonLCB0aGlzLl9yZWFkYWJsZVN0YXRlLmZsb3dpbmcpO1xuICBpZiAoZmFsc2UgIT09IHRoaXMuX3JlYWRhYmxlU3RhdGUuZmxvd2luZykge1xuICAgIGRlYnVnKCdwYXVzZScpO1xuICAgIHRoaXMuX3JlYWRhYmxlU3RhdGUuZmxvd2luZyA9IGZhbHNlO1xuICAgIHRoaXMuZW1pdCgncGF1c2UnKTtcbiAgfVxuICByZXR1cm4gdGhpcztcbn07XG5cbmZ1bmN0aW9uIGZsb3coc3RyZWFtKSB7XG4gIHZhciBzdGF0ZSA9IHN0cmVhbS5fcmVhZGFibGVTdGF0ZTtcbiAgZGVidWcoJ2Zsb3cnLCBzdGF0ZS5mbG93aW5nKTtcbiAgaWYgKHN0YXRlLmZsb3dpbmcpIHtcbiAgICBkbyB7XG4gICAgICB2YXIgY2h1bmsgPSBzdHJlYW0ucmVhZCgpO1xuICAgIH0gd2hpbGUgKG51bGwgIT09IGNodW5rICYmIHN0YXRlLmZsb3dpbmcpO1xuICB9XG59XG5cbi8vIHdyYXAgYW4gb2xkLXN0eWxlIHN0cmVhbSBhcyB0aGUgYXN5bmMgZGF0YSBzb3VyY2UuXG4vLyBUaGlzIGlzICpub3QqIHBhcnQgb2YgdGhlIHJlYWRhYmxlIHN0cmVhbSBpbnRlcmZhY2UuXG4vLyBJdCBpcyBhbiB1Z2x5IHVuZm9ydHVuYXRlIG1lc3Mgb2YgaGlzdG9yeS5cblJlYWRhYmxlLnByb3RvdHlwZS53cmFwID0gZnVuY3Rpb24oc3RyZWFtKSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3JlYWRhYmxlU3RhdGU7XG4gIHZhciBwYXVzZWQgPSBmYWxzZTtcblxuICB2YXIgc2VsZiA9IHRoaXM7XG4gIHN0cmVhbS5vbignZW5kJywgZnVuY3Rpb24oKSB7XG4gICAgZGVidWcoJ3dyYXBwZWQgZW5kJyk7XG4gICAgaWYgKHN0YXRlLmRlY29kZXIgJiYgIXN0YXRlLmVuZGVkKSB7XG4gICAgICB2YXIgY2h1bmsgPSBzdGF0ZS5kZWNvZGVyLmVuZCgpO1xuICAgICAgaWYgKGNodW5rICYmIGNodW5rLmxlbmd0aClcbiAgICAgICAgc2VsZi5wdXNoKGNodW5rKTtcbiAgICB9XG5cbiAgICBzZWxmLnB1c2gobnVsbCk7XG4gIH0pO1xuXG4gIHN0cmVhbS5vbignZGF0YScsIGZ1bmN0aW9uKGNodW5rKSB7XG4gICAgZGVidWcoJ3dyYXBwZWQgZGF0YScpO1xuICAgIGlmIChzdGF0ZS5kZWNvZGVyKVxuICAgICAgY2h1bmsgPSBzdGF0ZS5kZWNvZGVyLndyaXRlKGNodW5rKTtcbiAgICBpZiAoIWNodW5rIHx8ICFzdGF0ZS5vYmplY3RNb2RlICYmICFjaHVuay5sZW5ndGgpXG4gICAgICByZXR1cm47XG5cbiAgICB2YXIgcmV0ID0gc2VsZi5wdXNoKGNodW5rKTtcbiAgICBpZiAoIXJldCkge1xuICAgICAgcGF1c2VkID0gdHJ1ZTtcbiAgICAgIHN0cmVhbS5wYXVzZSgpO1xuICAgIH1cbiAgfSk7XG5cbiAgLy8gcHJveHkgYWxsIHRoZSBvdGhlciBtZXRob2RzLlxuICAvLyBpbXBvcnRhbnQgd2hlbiB3cmFwcGluZyBmaWx0ZXJzIGFuZCBkdXBsZXhlcy5cbiAgZm9yICh2YXIgaSBpbiBzdHJlYW0pIHtcbiAgICBpZiAodXRpbC5pc0Z1bmN0aW9uKHN0cmVhbVtpXSkgJiYgdXRpbC5pc1VuZGVmaW5lZCh0aGlzW2ldKSkge1xuICAgICAgdGhpc1tpXSA9IGZ1bmN0aW9uKG1ldGhvZCkgeyByZXR1cm4gZnVuY3Rpb24oKSB7XG4gICAgICAgIHJldHVybiBzdHJlYW1bbWV0aG9kXS5hcHBseShzdHJlYW0sIGFyZ3VtZW50cyk7XG4gICAgICB9fShpKTtcbiAgICB9XG4gIH1cblxuICAvLyBwcm94eSBjZXJ0YWluIGltcG9ydGFudCBldmVudHMuXG4gIHZhciBldmVudHMgPSBbJ2Vycm9yJywgJ2Nsb3NlJywgJ2Rlc3Ryb3knLCAncGF1c2UnLCAncmVzdW1lJ107XG4gIGZvckVhY2goZXZlbnRzLCBmdW5jdGlvbihldikge1xuICAgIHN0cmVhbS5vbihldiwgc2VsZi5lbWl0LmJpbmQoc2VsZiwgZXYpKTtcbiAgfSk7XG5cbiAgLy8gd2hlbiB3ZSB0cnkgdG8gY29uc3VtZSBzb21lIG1vcmUgYnl0ZXMsIHNpbXBseSB1bnBhdXNlIHRoZVxuICAvLyB1bmRlcmx5aW5nIHN0cmVhbS5cbiAgc2VsZi5fcmVhZCA9IGZ1bmN0aW9uKG4pIHtcbiAgICBkZWJ1Zygnd3JhcHBlZCBfcmVhZCcsIG4pO1xuICAgIGlmIChwYXVzZWQpIHtcbiAgICAgIHBhdXNlZCA9IGZhbHNlO1xuICAgICAgc3RyZWFtLnJlc3VtZSgpO1xuICAgIH1cbiAgfTtcblxuICByZXR1cm4gc2VsZjtcbn07XG5cblxuXG4vLyBleHBvc2VkIGZvciB0ZXN0aW5nIHB1cnBvc2VzIG9ubHkuXG5SZWFkYWJsZS5fZnJvbUxpc3QgPSBmcm9tTGlzdDtcblxuLy8gUGx1Y2sgb2ZmIG4gYnl0ZXMgZnJvbSBhbiBhcnJheSBvZiBidWZmZXJzLlxuLy8gTGVuZ3RoIGlzIHRoZSBjb21iaW5lZCBsZW5ndGhzIG9mIGFsbCB0aGUgYnVmZmVycyBpbiB0aGUgbGlzdC5cbmZ1bmN0aW9uIGZyb21MaXN0KG4sIHN0YXRlKSB7XG4gIHZhciBsaXN0ID0gc3RhdGUuYnVmZmVyO1xuICB2YXIgbGVuZ3RoID0gc3RhdGUubGVuZ3RoO1xuICB2YXIgc3RyaW5nTW9kZSA9ICEhc3RhdGUuZGVjb2RlcjtcbiAgdmFyIG9iamVjdE1vZGUgPSAhIXN0YXRlLm9iamVjdE1vZGU7XG4gIHZhciByZXQ7XG5cbiAgLy8gbm90aGluZyBpbiB0aGUgbGlzdCwgZGVmaW5pdGVseSBlbXB0eS5cbiAgaWYgKGxpc3QubGVuZ3RoID09PSAwKVxuICAgIHJldHVybiBudWxsO1xuXG4gIGlmIChsZW5ndGggPT09IDApXG4gICAgcmV0ID0gbnVsbDtcbiAgZWxzZSBpZiAob2JqZWN0TW9kZSlcbiAgICByZXQgPSBsaXN0LnNoaWZ0KCk7XG4gIGVsc2UgaWYgKCFuIHx8IG4gPj0gbGVuZ3RoKSB7XG4gICAgLy8gcmVhZCBpdCBhbGwsIHRydW5jYXRlIHRoZSBhcnJheS5cbiAgICBpZiAoc3RyaW5nTW9kZSlcbiAgICAgIHJldCA9IGxpc3Quam9pbignJyk7XG4gICAgZWxzZVxuICAgICAgcmV0ID0gQnVmZmVyLmNvbmNhdChsaXN0LCBsZW5ndGgpO1xuICAgIGxpc3QubGVuZ3RoID0gMDtcbiAgfSBlbHNlIHtcbiAgICAvLyByZWFkIGp1c3Qgc29tZSBvZiBpdC5cbiAgICBpZiAobiA8IGxpc3RbMF0ubGVuZ3RoKSB7XG4gICAgICAvLyBqdXN0IHRha2UgYSBwYXJ0IG9mIHRoZSBmaXJzdCBsaXN0IGl0ZW0uXG4gICAgICAvLyBzbGljZSBpcyB0aGUgc2FtZSBmb3IgYnVmZmVycyBhbmQgc3RyaW5ncy5cbiAgICAgIHZhciBidWYgPSBsaXN0WzBdO1xuICAgICAgcmV0ID0gYnVmLnNsaWNlKDAsIG4pO1xuICAgICAgbGlzdFswXSA9IGJ1Zi5zbGljZShuKTtcbiAgICB9IGVsc2UgaWYgKG4gPT09IGxpc3RbMF0ubGVuZ3RoKSB7XG4gICAgICAvLyBmaXJzdCBsaXN0IGlzIGEgcGVyZmVjdCBtYXRjaFxuICAgICAgcmV0ID0gbGlzdC5zaGlmdCgpO1xuICAgIH0gZWxzZSB7XG4gICAgICAvLyBjb21wbGV4IGNhc2UuXG4gICAgICAvLyB3ZSBoYXZlIGVub3VnaCB0byBjb3ZlciBpdCwgYnV0IGl0IHNwYW5zIHBhc3QgdGhlIGZpcnN0IGJ1ZmZlci5cbiAgICAgIGlmIChzdHJpbmdNb2RlKVxuICAgICAgICByZXQgPSAnJztcbiAgICAgIGVsc2VcbiAgICAgICAgcmV0ID0gbmV3IEJ1ZmZlcihuKTtcblxuICAgICAgdmFyIGMgPSAwO1xuICAgICAgZm9yICh2YXIgaSA9IDAsIGwgPSBsaXN0Lmxlbmd0aDsgaSA8IGwgJiYgYyA8IG47IGkrKykge1xuICAgICAgICB2YXIgYnVmID0gbGlzdFswXTtcbiAgICAgICAgdmFyIGNweSA9IE1hdGgubWluKG4gLSBjLCBidWYubGVuZ3RoKTtcblxuICAgICAgICBpZiAoc3RyaW5nTW9kZSlcbiAgICAgICAgICByZXQgKz0gYnVmLnNsaWNlKDAsIGNweSk7XG4gICAgICAgIGVsc2VcbiAgICAgICAgICBidWYuY29weShyZXQsIGMsIDAsIGNweSk7XG5cbiAgICAgICAgaWYgKGNweSA8IGJ1Zi5sZW5ndGgpXG4gICAgICAgICAgbGlzdFswXSA9IGJ1Zi5zbGljZShjcHkpO1xuICAgICAgICBlbHNlXG4gICAgICAgICAgbGlzdC5zaGlmdCgpO1xuXG4gICAgICAgIGMgKz0gY3B5O1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIHJldHVybiByZXQ7XG59XG5cbmZ1bmN0aW9uIGVuZFJlYWRhYmxlKHN0cmVhbSkge1xuICB2YXIgc3RhdGUgPSBzdHJlYW0uX3JlYWRhYmxlU3RhdGU7XG5cbiAgLy8gSWYgd2UgZ2V0IGhlcmUgYmVmb3JlIGNvbnN1bWluZyBhbGwgdGhlIGJ5dGVzLCB0aGVuIHRoYXQgaXMgYVxuICAvLyBidWcgaW4gbm9kZS4gIFNob3VsZCBuZXZlciBoYXBwZW4uXG4gIGlmIChzdGF0ZS5sZW5ndGggPiAwKVxuICAgIHRocm93IG5ldyBFcnJvcignZW5kUmVhZGFibGUgY2FsbGVkIG9uIG5vbi1lbXB0eSBzdHJlYW0nKTtcblxuICBpZiAoIXN0YXRlLmVuZEVtaXR0ZWQpIHtcbiAgICBzdGF0ZS5lbmRlZCA9IHRydWU7XG4gICAgcHJvY2Vzcy5uZXh0VGljayhmdW5jdGlvbigpIHtcbiAgICAgIC8vIENoZWNrIHRoYXQgd2UgZGlkbid0IGdldCBvbmUgbGFzdCB1bnNoaWZ0LlxuICAgICAgaWYgKCFzdGF0ZS5lbmRFbWl0dGVkICYmIHN0YXRlLmxlbmd0aCA9PT0gMCkge1xuICAgICAgICBzdGF0ZS5lbmRFbWl0dGVkID0gdHJ1ZTtcbiAgICAgICAgc3RyZWFtLnJlYWRhYmxlID0gZmFsc2U7XG4gICAgICAgIHN0cmVhbS5lbWl0KCdlbmQnKTtcbiAgICAgIH1cbiAgICB9KTtcbiAgfVxufVxuXG5mdW5jdGlvbiBmb3JFYWNoICh4cywgZikge1xuICBmb3IgKHZhciBpID0gMCwgbCA9IHhzLmxlbmd0aDsgaSA8IGw7IGkrKykge1xuICAgIGYoeHNbaV0sIGkpO1xuICB9XG59XG5cbmZ1bmN0aW9uIGluZGV4T2YgKHhzLCB4KSB7XG4gIGZvciAodmFyIGkgPSAwLCBsID0geHMubGVuZ3RoOyBpIDwgbDsgaSsrKSB7XG4gICAgaWYgKHhzW2ldID09PSB4KSByZXR1cm4gaTtcbiAgfVxuICByZXR1cm4gLTE7XG59XG5cbn0pLmNhbGwodGhpcyxyZXF1aXJlKCdfcHJvY2VzcycpKVxuLy8jIHNvdXJjZU1hcHBpbmdVUkw9ZGF0YTphcHBsaWNhdGlvbi9qc29uO2NoYXJzZXQ6dXRmLTg7YmFzZTY0LGV5SjJaWEp6YVc5dUlqb3pMQ0p6YjNWeVkyVnpJanBiSW01dlpHVmZiVzlrZFd4bGN5OWljbTkzYzJWeWFXWjVMMjV2WkdWZmJXOWtkV3hsY3k5eVpXRmtZV0pzWlMxemRISmxZVzB2YkdsaUwxOXpkSEpsWVcxZmNtVmhaR0ZpYkdVdWFuTWlYU3dpYm1GdFpYTWlPbHRkTENKdFlYQndhVzVuY3lJNklqdEJRVUZCTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQklpd2labWxzWlNJNkltZGxibVZ5WVhSbFpDNXFjeUlzSW5OdmRYSmpaVkp2YjNRaU9pSWlMQ0p6YjNWeVkyVnpRMjl1ZEdWdWRDSTZXeUl2THlCRGIzQjVjbWxuYUhRZ1NtOTVaVzUwTENCSmJtTXVJR0Z1WkNCdmRHaGxjaUJPYjJSbElHTnZiblJ5YVdKMWRHOXljeTVjYmk4dlhHNHZMeUJRWlhKdGFYTnphVzl1SUdseklHaGxjbVZpZVNCbmNtRnVkR1ZrTENCbWNtVmxJRzltSUdOb1lYSm5aU3dnZEc4Z1lXNTVJSEJsY25OdmJpQnZZblJoYVc1cGJtY2dZVnh1THk4Z1kyOXdlU0J2WmlCMGFHbHpJSE52Wm5SM1lYSmxJR0Z1WkNCaGMzTnZZMmxoZEdWa0lHUnZZM1Z0Wlc1MFlYUnBiMjRnWm1sc1pYTWdLSFJvWlZ4dUx5OGdYQ0pUYjJaMGQyRnlaVndpS1N3Z2RHOGdaR1ZoYkNCcGJpQjBhR1VnVTI5bWRIZGhjbVVnZDJsMGFHOTFkQ0J5WlhOMGNtbGpkR2x2Yml3Z2FXNWpiSFZrYVc1blhHNHZMeUIzYVhSb2IzVjBJR3hwYldsMFlYUnBiMjRnZEdobElISnBaMmgwY3lCMGJ5QjFjMlVzSUdOdmNIa3NJRzF2WkdsbWVTd2diV1Z5WjJVc0lIQjFZbXhwYzJnc1hHNHZMeUJrYVhOMGNtbGlkWFJsTENCemRXSnNhV05sYm5ObExDQmhibVF2YjNJZ2MyVnNiQ0JqYjNCcFpYTWdiMllnZEdobElGTnZablIzWVhKbExDQmhibVFnZEc4Z2NHVnliV2wwWEc0dkx5QndaWEp6YjI1eklIUnZJSGRvYjIwZ2RHaGxJRk52Wm5SM1lYSmxJR2x6SUdaMWNtNXBjMmhsWkNCMGJ5QmtieUJ6Ynl3Z2MzVmlhbVZqZENCMGJ5QjBhR1ZjYmk4dklHWnZiR3h2ZDJsdVp5QmpiMjVrYVhScGIyNXpPbHh1THk5Y2JpOHZJRlJvWlNCaFltOTJaU0JqYjNCNWNtbG5hSFFnYm05MGFXTmxJR0Z1WkNCMGFHbHpJSEJsY20xcGMzTnBiMjRnYm05MGFXTmxJSE5vWVd4c0lHSmxJR2x1WTJ4MVpHVmtYRzR2THlCcGJpQmhiR3dnWTI5d2FXVnpJRzl5SUhOMVluTjBZVzUwYVdGc0lIQnZjblJwYjI1eklHOW1JSFJvWlNCVGIyWjBkMkZ5WlM1Y2JpOHZYRzR2THlCVVNFVWdVMDlHVkZkQlVrVWdTVk1nVUZKUFZrbEVSVVFnWENKQlV5QkpVMXdpTENCWFNWUklUMVZVSUZkQlVsSkJUbFJaSUU5R0lFRk9XU0JMU1U1RUxDQkZXRkJTUlZOVFhHNHZMeUJQVWlCSlRWQk1TVVZFTENCSlRrTk1WVVJKVGtjZ1FsVlVJRTVQVkNCTVNVMUpWRVZFSUZSUElGUklSU0JYUVZKU1FVNVVTVVZUSUU5R1hHNHZMeUJOUlZKRFNFRk9WRUZDU1V4SlZGa3NJRVpKVkU1RlUxTWdSazlTSUVFZ1VFRlNWRWxEVlV4QlVpQlFWVkpRVDFORklFRk9SQ0JPVDA1SlRrWlNTVTVIUlUxRlRsUXVJRWxPWEc0dkx5Qk9UeUJGVmtWT1ZDQlRTRUZNVENCVVNFVWdRVlZVU0U5U1V5QlBVaUJEVDFCWlVrbEhTRlFnU0U5TVJFVlNVeUJDUlNCTVNVRkNURVVnUms5U0lFRk9XU0JEVEVGSlRTeGNiaTh2SUVSQlRVRkhSVk1nVDFJZ1QxUklSVklnVEVsQlFrbE1TVlJaTENCWFNFVlVTRVZTSUVsT0lFRk9JRUZEVkVsUFRpQlBSaUJEVDA1VVVrRkRWQ3dnVkU5U1ZDQlBVbHh1THk4Z1QxUklSVkpYU1ZORkxDQkJVa2xUU1U1SElFWlNUMDBzSUU5VlZDQlBSaUJQVWlCSlRpQkRUMDVPUlVOVVNVOU9JRmRKVkVnZ1ZFaEZJRk5QUmxSWFFWSkZJRTlTSUZSSVJWeHVMeThnVlZORklFOVNJRTlVU0VWU0lFUkZRVXhKVGtkVElFbE9JRlJJUlNCVFQwWlVWMEZTUlM1Y2JseHViVzlrZFd4bExtVjRjRzl5ZEhNZ1BTQlNaV0ZrWVdKc1pUdGNibHh1THlvOGNtVndiR0ZqWlcxbGJuUStLaTljYm5aaGNpQnBjMEZ5Y21GNUlEMGdjbVZ4ZFdseVpTZ25hWE5oY25KaGVTY3BPMXh1THlvOEwzSmxjR3hoWTJWdFpXNTBQaW92WEc1Y2JseHVMeW84Y21Wd2JHRmpaVzFsYm5RK0tpOWNiblpoY2lCQ2RXWm1aWElnUFNCeVpYRjFhWEpsS0NkaWRXWm1aWEluS1M1Q2RXWm1aWEk3WEc0dktqd3ZjbVZ3YkdGalpXMWxiblErS2k5Y2JseHVVbVZoWkdGaWJHVXVVbVZoWkdGaWJHVlRkR0YwWlNBOUlGSmxZV1JoWW14bFUzUmhkR1U3WEc1Y2JuWmhjaUJGUlNBOUlISmxjWFZwY21Vb0oyVjJaVzUwY3ljcExrVjJaVzUwUlcxcGRIUmxjanRjYmx4dUx5bzhjbVZ3YkdGalpXMWxiblErS2k5Y2JtbG1JQ2doUlVVdWJHbHpkR1Z1WlhKRGIzVnVkQ2tnUlVVdWJHbHpkR1Z1WlhKRGIzVnVkQ0E5SUdaMWJtTjBhVzl1S0dWdGFYUjBaWElzSUhSNWNHVXBJSHRjYmlBZ2NtVjBkWEp1SUdWdGFYUjBaWEl1YkdsemRHVnVaWEp6S0hSNWNHVXBMbXhsYm1kMGFEdGNibjA3WEc0dktqd3ZjbVZ3YkdGalpXMWxiblErS2k5Y2JseHVkbUZ5SUZOMGNtVmhiU0E5SUhKbGNYVnBjbVVvSjNOMGNtVmhiU2NwTzF4dVhHNHZLanh5WlhCc1lXTmxiV1Z1ZEQ0cUwxeHVkbUZ5SUhWMGFXd2dQU0J5WlhGMWFYSmxLQ2RqYjNKbExYVjBhV3d0YVhNbktUdGNiblYwYVd3dWFXNW9aWEpwZEhNZ1BTQnlaWEYxYVhKbEtDZHBibWhsY21sMGN5Y3BPMXh1THlvOEwzSmxjR3hoWTJWdFpXNTBQaW92WEc1Y2JuWmhjaUJUZEhKcGJtZEVaV052WkdWeU8xeHVYRzVjYmk4cVBISmxjR3hoWTJWdFpXNTBQaW92WEc1MllYSWdaR1ZpZFdjZ1BTQnlaWEYxYVhKbEtDZDFkR2xzSnlrN1hHNXBaaUFvWkdWaWRXY2dKaVlnWkdWaWRXY3VaR1ZpZFdkc2IyY3BJSHRjYmlBZ1pHVmlkV2NnUFNCa1pXSjFaeTVrWldKMVoyeHZaeWduYzNSeVpXRnRKeWs3WEc1OUlHVnNjMlVnZTF4dUlDQmtaV0oxWnlBOUlHWjFibU4wYVc5dUlDZ3BJSHQ5TzF4dWZWeHVMeW84TDNKbGNHeGhZMlZ0Wlc1MFBpb3ZYRzVjYmx4dWRYUnBiQzVwYm1obGNtbDBjeWhTWldGa1lXSnNaU3dnVTNSeVpXRnRLVHRjYmx4dVpuVnVZM1JwYjI0Z1VtVmhaR0ZpYkdWVGRHRjBaU2h2Y0hScGIyNXpMQ0J6ZEhKbFlXMHBJSHRjYmlBZ2RtRnlJRVIxY0d4bGVDQTlJSEpsY1hWcGNtVW9KeTR2WDNOMGNtVmhiVjlrZFhCc1pYZ25LVHRjYmx4dUlDQnZjSFJwYjI1eklEMGdiM0IwYVc5dWN5QjhmQ0I3ZlR0Y2JseHVJQ0F2THlCMGFHVWdjRzlwYm5RZ1lYUWdkMmhwWTJnZ2FYUWdjM1J2Y0hNZ1kyRnNiR2x1WnlCZmNtVmhaQ2dwSUhSdklHWnBiR3dnZEdobElHSjFabVpsY2x4dUlDQXZMeUJPYjNSbE9pQXdJR2x6SUdFZ2RtRnNhV1FnZG1Gc2RXVXNJRzFsWVc1eklGd2laRzl1SjNRZ1kyRnNiQ0JmY21WaFpDQndjbVZsYlhCMGFYWmxiSGtnWlhabGNsd2lYRzRnSUhaaGNpQm9kMjBnUFNCdmNIUnBiMjV6TG1ocFoyaFhZWFJsY2sxaGNtczdYRzRnSUhaaGNpQmtaV1poZFd4MFNIZHRJRDBnYjNCMGFXOXVjeTV2WW1wbFkzUk5iMlJsSUQ4Z01UWWdPaUF4TmlBcUlERXdNalE3WEc0Z0lIUm9hWE11YUdsbmFGZGhkR1Z5VFdGeWF5QTlJQ2hvZDIwZ2ZId2dhSGR0SUQwOVBTQXdLU0EvSUdoM2JTQTZJR1JsWm1GMWJIUklkMjA3WEc1Y2JpQWdMeThnWTJGemRDQjBieUJwYm5SekxseHVJQ0IwYUdsekxtaHBaMmhYWVhSbGNrMWhjbXNnUFNCK2ZuUm9hWE11YUdsbmFGZGhkR1Z5VFdGeWF6dGNibHh1SUNCMGFHbHpMbUoxWm1abGNpQTlJRnRkTzF4dUlDQjBhR2x6TG14bGJtZDBhQ0E5SURBN1hHNGdJSFJvYVhNdWNHbHdaWE1nUFNCdWRXeHNPMXh1SUNCMGFHbHpMbkJwY0dWelEyOTFiblFnUFNBd08xeHVJQ0IwYUdsekxtWnNiM2RwYm1jZ1BTQnVkV3hzTzF4dUlDQjBhR2x6TG1WdVpHVmtJRDBnWm1Gc2MyVTdYRzRnSUhSb2FYTXVaVzVrUlcxcGRIUmxaQ0E5SUdaaGJITmxPMXh1SUNCMGFHbHpMbkpsWVdScGJtY2dQU0JtWVd4elpUdGNibHh1SUNBdkx5QmhJR1pzWVdjZ2RHOGdZbVVnWVdKc1pTQjBieUIwWld4c0lHbG1JSFJvWlNCdmJuZHlhWFJsSUdOaUlHbHpJR05oYkd4bFpDQnBiVzFsWkdsaGRHVnNlU3hjYmlBZ0x5OGdiM0lnYjI0Z1lTQnNZWFJsY2lCMGFXTnJMaUFnVjJVZ2MyVjBJSFJvYVhNZ2RHOGdkSEoxWlNCaGRDQm1hWEp6ZEN3Z1ltVmpZWFZ6WlNCaGJubGNiaUFnTHk4Z1lXTjBhVzl1Y3lCMGFHRjBJSE5vYjNWc1pHNG5kQ0JvWVhCd1pXNGdkVzUwYVd3Z1hDSnNZWFJsY2x3aUlITm9iM1ZzWkNCblpXNWxjbUZzYkhrZ1lXeHpiMXh1SUNBdkx5QnViM1FnYUdGd2NHVnVJR0psWm05eVpTQjBhR1VnWm1seWMzUWdkM0pwZEdVZ1kyRnNiQzVjYmlBZ2RHaHBjeTV6ZVc1aklEMGdkSEoxWlR0Y2JseHVJQ0F2THlCM2FHVnVaWFpsY2lCM1pTQnlaWFIxY200Z2JuVnNiQ3dnZEdobGJpQjNaU0J6WlhRZ1lTQm1iR0ZuSUhSdklITmhlVnh1SUNBdkx5QjBhR0YwSUhkbEozSmxJR0YzWVdsMGFXNW5JR0VnSjNKbFlXUmhZbXhsSnlCbGRtVnVkQ0JsYldsemMybHZiaTVjYmlBZ2RHaHBjeTV1WldWa1VtVmhaR0ZpYkdVZ1BTQm1ZV3h6WlR0Y2JpQWdkR2hwY3k1bGJXbDBkR1ZrVW1WaFpHRmliR1VnUFNCbVlXeHpaVHRjYmlBZ2RHaHBjeTV5WldGa1lXSnNaVXhwYzNSbGJtbHVaeUE5SUdaaGJITmxPMXh1WEc1Y2JpQWdMeThnYjJKcVpXTjBJSE4wY21WaGJTQm1iR0ZuTGlCVmMyVmtJSFJ2SUcxaGEyVWdjbVZoWkNodUtTQnBaMjV2Y21VZ2JpQmhibVFnZEc5Y2JpQWdMeThnYldGclpTQmhiR3dnZEdobElHSjFabVpsY2lCdFpYSm5hVzVuSUdGdVpDQnNaVzVuZEdnZ1kyaGxZMnR6SUdkdklHRjNZWGxjYmlBZ2RHaHBjeTV2WW1wbFkzUk5iMlJsSUQwZ0lTRnZjSFJwYjI1ekxtOWlhbVZqZEUxdlpHVTdYRzVjYmlBZ2FXWWdLSE4wY21WaGJTQnBibk4wWVc1alpXOW1JRVIxY0d4bGVDbGNiaUFnSUNCMGFHbHpMbTlpYW1WamRFMXZaR1VnUFNCMGFHbHpMbTlpYW1WamRFMXZaR1VnZkh3Z0lTRnZjSFJwYjI1ekxuSmxZV1JoWW14bFQySnFaV04wVFc5a1pUdGNibHh1SUNBdkx5QkRjbmx3ZEc4Z2FYTWdhMmx1WkNCdlppQnZiR1FnWVc1a0lHTnlkWE4wZVM0Z0lFaHBjM1J2Y21sallXeHNlU3dnYVhSeklHUmxabUYxYkhRZ2MzUnlhVzVuWEc0Z0lDOHZJR1Z1WTI5a2FXNW5JR2x6SUNkaWFXNWhjbmtuSUhOdklIZGxJR2hoZG1VZ2RHOGdiV0ZyWlNCMGFHbHpJR052Ym1acFozVnlZV0pzWlM1Y2JpQWdMeThnUlhabGNubDBhR2x1WnlCbGJITmxJR2x1SUhSb1pTQjFibWwyWlhKelpTQjFjMlZ6SUNkMWRHWTRKeXdnZEdodmRXZG9MbHh1SUNCMGFHbHpMbVJsWm1GMWJIUkZibU52WkdsdVp5QTlJRzl3ZEdsdmJuTXVaR1ZtWVhWc2RFVnVZMjlrYVc1bklIeDhJQ2QxZEdZNEp6dGNibHh1SUNBdkx5QjNhR1Z1SUhCcGNHbHVaeXdnZDJVZ2IyNXNlU0JqWVhKbElHRmliM1YwSUNkeVpXRmtZV0pzWlNjZ1pYWmxiblJ6SUhSb1lYUWdhR0Z3Y0dWdVhHNGdJQzh2SUdGbWRHVnlJSEpsWVdRb0tXbHVaeUJoYkd3Z2RHaGxJR0o1ZEdWeklHRnVaQ0J1YjNRZ1oyVjBkR2x1WnlCaGJua2djSFZ6YUdKaFkyc3VYRzRnSUhSb2FYTXVjbUZ1VDNWMElEMGdabUZzYzJVN1hHNWNiaUFnTHk4Z2RHaGxJRzUxYldKbGNpQnZaaUIzY21sMFpYSnpJSFJvWVhRZ1lYSmxJR0YzWVdsMGFXNW5JR0VnWkhKaGFXNGdaWFpsYm5RZ2FXNGdMbkJwY0dVb0tYTmNiaUFnZEdocGN5NWhkMkZwZEVSeVlXbHVJRDBnTUR0Y2JseHVJQ0F2THlCcFppQjBjblZsTENCaElHMWhlV0psVW1WaFpFMXZjbVVnYUdGeklHSmxaVzRnYzJOb1pXUjFiR1ZrWEc0Z0lIUm9hWE11Y21WaFpHbHVaMDF2Y21VZ1BTQm1ZV3h6WlR0Y2JseHVJQ0IwYUdsekxtUmxZMjlrWlhJZ1BTQnVkV3hzTzF4dUlDQjBhR2x6TG1WdVkyOWthVzVuSUQwZ2JuVnNiRHRjYmlBZ2FXWWdLRzl3ZEdsdmJuTXVaVzVqYjJScGJtY3BJSHRjYmlBZ0lDQnBaaUFvSVZOMGNtbHVaMFJsWTI5a1pYSXBYRzRnSUNBZ0lDQlRkSEpwYm1kRVpXTnZaR1Z5SUQwZ2NtVnhkV2x5WlNnbmMzUnlhVzVuWDJSbFkyOWtaWEl2SnlrdVUzUnlhVzVuUkdWamIyUmxjanRjYmlBZ0lDQjBhR2x6TG1SbFkyOWtaWElnUFNCdVpYY2dVM1J5YVc1blJHVmpiMlJsY2lodmNIUnBiMjV6TG1WdVkyOWthVzVuS1R0Y2JpQWdJQ0IwYUdsekxtVnVZMjlrYVc1bklEMGdiM0IwYVc5dWN5NWxibU52WkdsdVp6dGNiaUFnZlZ4dWZWeHVYRzVtZFc1amRHbHZiaUJTWldGa1lXSnNaU2h2Y0hScGIyNXpLU0I3WEc0Z0lIWmhjaUJFZFhCc1pYZ2dQU0J5WlhGMWFYSmxLQ2N1TDE5emRISmxZVzFmWkhWd2JHVjRKeWs3WEc1Y2JpQWdhV1lnS0NFb2RHaHBjeUJwYm5OMFlXNWpaVzltSUZKbFlXUmhZbXhsS1NsY2JpQWdJQ0J5WlhSMWNtNGdibVYzSUZKbFlXUmhZbXhsS0c5d2RHbHZibk1wTzF4dVhHNGdJSFJvYVhNdVgzSmxZV1JoWW14bFUzUmhkR1VnUFNCdVpYY2dVbVZoWkdGaWJHVlRkR0YwWlNodmNIUnBiMjV6TENCMGFHbHpLVHRjYmx4dUlDQXZMeUJzWldkaFkzbGNiaUFnZEdocGN5NXlaV0ZrWVdKc1pTQTlJSFJ5ZFdVN1hHNWNiaUFnVTNSeVpXRnRMbU5oYkd3b2RHaHBjeWs3WEc1OVhHNWNiaTh2SUUxaGJuVmhiR3g1SUhOb2IzWmxJSE52YldWMGFHbHVaeUJwYm5SdklIUm9aU0J5WldGa0tDa2dZblZtWm1WeUxseHVMeThnVkdocGN5QnlaWFIxY201eklIUnlkV1VnYVdZZ2RHaGxJR2hwWjJoWFlYUmxjazFoY21zZ2FHRnpJRzV2ZENCaVpXVnVJR2hwZENCNVpYUXNYRzR2THlCemFXMXBiR0Z5SUhSdklHaHZkeUJYY21sMFlXSnNaUzUzY21sMFpTZ3BJSEpsZEhWeWJuTWdkSEoxWlNCcFppQjViM1VnYzJodmRXeGtYRzR2THlCM2NtbDBaU2dwSUhOdmJXVWdiVzl5WlM1Y2JsSmxZV1JoWW14bExuQnliM1J2ZEhsd1pTNXdkWE5vSUQwZ1puVnVZM1JwYjI0b1kyaDFibXNzSUdWdVkyOWthVzVuS1NCN1hHNGdJSFpoY2lCemRHRjBaU0E5SUhSb2FYTXVYM0psWVdSaFlteGxVM1JoZEdVN1hHNWNiaUFnYVdZZ0tIVjBhV3d1YVhOVGRISnBibWNvWTJoMWJtc3BJQ1ltSUNGemRHRjBaUzV2WW1wbFkzUk5iMlJsS1NCN1hHNGdJQ0FnWlc1amIyUnBibWNnUFNCbGJtTnZaR2x1WnlCOGZDQnpkR0YwWlM1a1pXWmhkV3gwUlc1amIyUnBibWM3WEc0Z0lDQWdhV1lnS0dWdVkyOWthVzVuSUNFOVBTQnpkR0YwWlM1bGJtTnZaR2x1WnlrZ2UxeHVJQ0FnSUNBZ1kyaDFibXNnUFNCdVpYY2dRblZtWm1WeUtHTm9kVzVyTENCbGJtTnZaR2x1WnlrN1hHNGdJQ0FnSUNCbGJtTnZaR2x1WnlBOUlDY25PMXh1SUNBZ0lIMWNiaUFnZlZ4dVhHNGdJSEpsZEhWeWJpQnlaV0ZrWVdKc1pVRmtaRU5vZFc1cktIUm9hWE1zSUhOMFlYUmxMQ0JqYUhWdWF5d2daVzVqYjJScGJtY3NJR1poYkhObEtUdGNibjA3WEc1Y2JpOHZJRlZ1YzJocFpuUWdjMmh2ZFd4a0lDcGhiSGRoZVhNcUlHSmxJSE52YldWMGFHbHVaeUJrYVhKbFkzUnNlU0J2ZFhRZ2IyWWdjbVZoWkNncFhHNVNaV0ZrWVdKc1pTNXdjbTkwYjNSNWNHVXVkVzV6YUdsbWRDQTlJR1oxYm1OMGFXOXVLR05vZFc1cktTQjdYRzRnSUhaaGNpQnpkR0YwWlNBOUlIUm9hWE11WDNKbFlXUmhZbXhsVTNSaGRHVTdYRzRnSUhKbGRIVnliaUJ5WldGa1lXSnNaVUZrWkVOb2RXNXJLSFJvYVhNc0lITjBZWFJsTENCamFIVnVheXdnSnljc0lIUnlkV1VwTzF4dWZUdGNibHh1Wm5WdVkzUnBiMjRnY21WaFpHRmliR1ZCWkdSRGFIVnVheWh6ZEhKbFlXMHNJSE4wWVhSbExDQmphSFZ1YXl3Z1pXNWpiMlJwYm1jc0lHRmtaRlJ2Um5KdmJuUXBJSHRjYmlBZ2RtRnlJR1Z5SUQwZ1kyaDFibXRKYm5aaGJHbGtLSE4wWVhSbExDQmphSFZ1YXlrN1hHNGdJR2xtSUNobGNpa2dlMXh1SUNBZ0lITjBjbVZoYlM1bGJXbDBLQ2RsY25KdmNpY3NJR1Z5S1R0Y2JpQWdmU0JsYkhObElHbG1JQ2gxZEdsc0xtbHpUblZzYkU5eVZXNWtaV1pwYm1Wa0tHTm9kVzVyS1NrZ2UxeHVJQ0FnSUhOMFlYUmxMbkpsWVdScGJtY2dQU0JtWVd4elpUdGNiaUFnSUNCcFppQW9JWE4wWVhSbExtVnVaR1ZrS1Z4dUlDQWdJQ0FnYjI1RmIyWkRhSFZ1YXloemRISmxZVzBzSUhOMFlYUmxLVHRjYmlBZ2ZTQmxiSE5sSUdsbUlDaHpkR0YwWlM1dlltcGxZM1JOYjJSbElIeDhJR05vZFc1cklDWW1JR05vZFc1ckxteGxibWQwYUNBK0lEQXBJSHRjYmlBZ0lDQnBaaUFvYzNSaGRHVXVaVzVrWldRZ0ppWWdJV0ZrWkZSdlJuSnZiblFwSUh0Y2JpQWdJQ0FnSUhaaGNpQmxJRDBnYm1WM0lFVnljbTl5S0NkemRISmxZVzB1Y0hWemFDZ3BJR0ZtZEdWeUlFVlBSaWNwTzF4dUlDQWdJQ0FnYzNSeVpXRnRMbVZ0YVhRb0oyVnljbTl5Snl3Z1pTazdYRzRnSUNBZ2ZTQmxiSE5sSUdsbUlDaHpkR0YwWlM1bGJtUkZiV2wwZEdWa0lDWW1JR0ZrWkZSdlJuSnZiblFwSUh0Y2JpQWdJQ0FnSUhaaGNpQmxJRDBnYm1WM0lFVnljbTl5S0NkemRISmxZVzB1ZFc1emFHbG1kQ2dwSUdGbWRHVnlJR1Z1WkNCbGRtVnVkQ2NwTzF4dUlDQWdJQ0FnYzNSeVpXRnRMbVZ0YVhRb0oyVnljbTl5Snl3Z1pTazdYRzRnSUNBZ2ZTQmxiSE5sSUh0Y2JpQWdJQ0FnSUdsbUlDaHpkR0YwWlM1a1pXTnZaR1Z5SUNZbUlDRmhaR1JVYjBaeWIyNTBJQ1ltSUNGbGJtTnZaR2x1WnlsY2JpQWdJQ0FnSUNBZ1kyaDFibXNnUFNCemRHRjBaUzVrWldOdlpHVnlMbmR5YVhSbEtHTm9kVzVyS1R0Y2JseHVJQ0FnSUNBZ2FXWWdLQ0ZoWkdSVWIwWnliMjUwS1Z4dUlDQWdJQ0FnSUNCemRHRjBaUzV5WldGa2FXNW5JRDBnWm1Gc2MyVTdYRzVjYmlBZ0lDQWdJQzh2SUdsbUlIZGxJSGRoYm5RZ2RHaGxJR1JoZEdFZ2JtOTNMQ0JxZFhOMElHVnRhWFFnYVhRdVhHNGdJQ0FnSUNCcFppQW9jM1JoZEdVdVpteHZkMmx1WnlBbUppQnpkR0YwWlM1c1pXNW5kR2dnUFQwOUlEQWdKaVlnSVhOMFlYUmxMbk41Ym1NcElIdGNiaUFnSUNBZ0lDQWdjM1J5WldGdExtVnRhWFFvSjJSaGRHRW5MQ0JqYUhWdWF5azdYRzRnSUNBZ0lDQWdJSE4wY21WaGJTNXlaV0ZrS0RBcE8xeHVJQ0FnSUNBZ2ZTQmxiSE5sSUh0Y2JpQWdJQ0FnSUNBZ0x5OGdkWEJrWVhSbElIUm9aU0JpZFdabVpYSWdhVzVtYnk1Y2JpQWdJQ0FnSUNBZ2MzUmhkR1V1YkdWdVozUm9JQ3M5SUhOMFlYUmxMbTlpYW1WamRFMXZaR1VnUHlBeElEb2dZMmgxYm1zdWJHVnVaM1JvTzF4dUlDQWdJQ0FnSUNCcFppQW9ZV1JrVkc5R2NtOXVkQ2xjYmlBZ0lDQWdJQ0FnSUNCemRHRjBaUzVpZFdabVpYSXVkVzV6YUdsbWRDaGphSFZ1YXlrN1hHNGdJQ0FnSUNBZ0lHVnNjMlZjYmlBZ0lDQWdJQ0FnSUNCemRHRjBaUzVpZFdabVpYSXVjSFZ6YUNoamFIVnVheWs3WEc1Y2JpQWdJQ0FnSUNBZ2FXWWdLSE4wWVhSbExtNWxaV1JTWldGa1lXSnNaU2xjYmlBZ0lDQWdJQ0FnSUNCbGJXbDBVbVZoWkdGaWJHVW9jM1J5WldGdEtUdGNiaUFnSUNBZ0lIMWNibHh1SUNBZ0lDQWdiV0Y1WW1WU1pXRmtUVzl5WlNoemRISmxZVzBzSUhOMFlYUmxLVHRjYmlBZ0lDQjlYRzRnSUgwZ1pXeHpaU0JwWmlBb0lXRmtaRlJ2Um5KdmJuUXBJSHRjYmlBZ0lDQnpkR0YwWlM1eVpXRmthVzVuSUQwZ1ptRnNjMlU3WEc0Z0lIMWNibHh1SUNCeVpYUjFjbTRnYm1WbFpFMXZjbVZFWVhSaEtITjBZWFJsS1R0Y2JuMWNibHh1WEc1Y2JpOHZJR2xtSUdsMEozTWdjR0Z6ZENCMGFHVWdhR2xuYUNCM1lYUmxjaUJ0WVhKckxDQjNaU0JqWVc0Z2NIVnphQ0JwYmlCemIyMWxJRzF2Y21VdVhHNHZMeUJCYkhOdkxDQnBaaUIzWlNCb1lYWmxJRzV2SUdSaGRHRWdlV1YwTENCM1pTQmpZVzRnYzNSaGJtUWdjMjl0WlZ4dUx5OGdiVzl5WlNCaWVYUmxjeTRnSUZSb2FYTWdhWE1nZEc4Z2QyOXlheUJoY205MWJtUWdZMkZ6WlhNZ2QyaGxjbVVnYUhkdFBUQXNYRzR2THlCemRXTm9JR0Z6SUhSb1pTQnlaWEJzTGlBZ1FXeHpieXdnYVdZZ2RHaGxJSEIxYzJnb0tTQjBjbWxuWjJWeVpXUWdZVnh1THk4Z2NtVmhaR0ZpYkdVZ1pYWmxiblFzSUdGdVpDQjBhR1VnZFhObGNpQmpZV3hzWldRZ2NtVmhaQ2hzWVhKblpVNTFiV0psY2lrZ2MzVmphQ0IwYUdGMFhHNHZMeUJ1WldWa1VtVmhaR0ZpYkdVZ2QyRnpJSE5sZEN3Z2RHaGxiaUIzWlNCdmRXZG9kQ0IwYnlCd2RYTm9JRzF2Y21Vc0lITnZJSFJvWVhRZ1lXNXZkR2hsY2x4dUx5OGdKM0psWVdSaFlteGxKeUJsZG1WdWRDQjNhV3hzSUdKbElIUnlhV2RuWlhKbFpDNWNibVoxYm1OMGFXOXVJRzVsWldSTmIzSmxSR0YwWVNoemRHRjBaU2tnZTF4dUlDQnlaWFIxY200Z0lYTjBZWFJsTG1WdVpHVmtJQ1ltWEc0Z0lDQWdJQ0FnSUNBb2MzUmhkR1V1Ym1WbFpGSmxZV1JoWW14bElIeDhYRzRnSUNBZ0lDQWdJQ0FnYzNSaGRHVXViR1Z1WjNSb0lEd2djM1JoZEdVdWFHbG5hRmRoZEdWeVRXRnlheUI4ZkZ4dUlDQWdJQ0FnSUNBZ0lITjBZWFJsTG14bGJtZDBhQ0E5UFQwZ01DazdYRzU5WEc1Y2JpOHZJR0poWTJ0M1lYSmtjeUJqYjIxd1lYUnBZbWxzYVhSNUxseHVVbVZoWkdGaWJHVXVjSEp2ZEc5MGVYQmxMbk5sZEVWdVkyOWthVzVuSUQwZ1puVnVZM1JwYjI0b1pXNWpLU0I3WEc0Z0lHbG1JQ2doVTNSeWFXNW5SR1ZqYjJSbGNpbGNiaUFnSUNCVGRISnBibWRFWldOdlpHVnlJRDBnY21WeGRXbHlaU2duYzNSeWFXNW5YMlJsWTI5a1pYSXZKeWt1VTNSeWFXNW5SR1ZqYjJSbGNqdGNiaUFnZEdocGN5NWZjbVZoWkdGaWJHVlRkR0YwWlM1a1pXTnZaR1Z5SUQwZ2JtVjNJRk4wY21sdVowUmxZMjlrWlhJb1pXNWpLVHRjYmlBZ2RHaHBjeTVmY21WaFpHRmliR1ZUZEdGMFpTNWxibU52WkdsdVp5QTlJR1Z1WXp0Y2JpQWdjbVYwZFhKdUlIUm9hWE03WEc1OU8xeHVYRzR2THlCRWIyNG5kQ0J5WVdselpTQjBhR1VnYUhkdElENGdNVEk0VFVKY2JuWmhjaUJOUVZoZlNGZE5JRDBnTUhnNE1EQXdNREE3WEc1bWRXNWpkR2x2YmlCeWIzVnVaRlZ3Vkc5T1pYaDBVRzkzWlhKUFpqSW9iaWtnZTF4dUlDQnBaaUFvYmlBK1BTQk5RVmhmU0ZkTktTQjdYRzRnSUNBZ2JpQTlJRTFCV0Y5SVYwMDdYRzRnSUgwZ1pXeHpaU0I3WEc0Z0lDQWdMeThnUjJWMElIUm9aU0J1WlhoMElHaHBaMmhsYzNRZ2NHOTNaWElnYjJZZ01seHVJQ0FnSUc0dExUdGNiaUFnSUNCbWIzSWdLSFpoY2lCd0lEMGdNVHNnY0NBOElETXlPeUJ3SUR3OFBTQXhLU0J1SUh3OUlHNGdQajRnY0R0Y2JpQWdJQ0J1S3lzN1hHNGdJSDFjYmlBZ2NtVjBkWEp1SUc0N1hHNTlYRzVjYm1aMWJtTjBhVzl1SUdodmQwMTFZMmhVYjFKbFlXUW9iaXdnYzNSaGRHVXBJSHRjYmlBZ2FXWWdLSE4wWVhSbExteGxibWQwYUNBOVBUMGdNQ0FtSmlCemRHRjBaUzVsYm1SbFpDbGNiaUFnSUNCeVpYUjFjbTRnTUR0Y2JseHVJQ0JwWmlBb2MzUmhkR1V1YjJKcVpXTjBUVzlrWlNsY2JpQWdJQ0J5WlhSMWNtNGdiaUE5UFQwZ01DQS9JREFnT2lBeE8xeHVYRzRnSUdsbUlDaHBjMDVoVGlodUtTQjhmQ0IxZEdsc0xtbHpUblZzYkNodUtTa2dlMXh1SUNBZ0lDOHZJRzl1YkhrZ1pteHZkeUJ2Ym1VZ1luVm1abVZ5SUdGMElHRWdkR2x0WlZ4dUlDQWdJR2xtSUNoemRHRjBaUzVtYkc5M2FXNW5JQ1ltSUhOMFlYUmxMbUoxWm1abGNpNXNaVzVuZEdncFhHNGdJQ0FnSUNCeVpYUjFjbTRnYzNSaGRHVXVZblZtWm1WeVd6QmRMbXhsYm1kMGFEdGNiaUFnSUNCbGJITmxYRzRnSUNBZ0lDQnlaWFIxY200Z2MzUmhkR1V1YkdWdVozUm9PMXh1SUNCOVhHNWNiaUFnYVdZZ0tHNGdQRDBnTUNsY2JpQWdJQ0J5WlhSMWNtNGdNRHRjYmx4dUlDQXZMeUJKWmlCM1pTZHlaU0JoYzJ0cGJtY2dabTl5SUcxdmNtVWdkR2hoYmlCMGFHVWdkR0Z5WjJWMElHSjFabVpsY2lCc1pYWmxiQ3hjYmlBZ0x5OGdkR2hsYmlCeVlXbHpaU0IwYUdVZ2QyRjBaWElnYldGeWF5NGdJRUoxYlhBZ2RYQWdkRzhnZEdobElHNWxlSFFnYUdsbmFHVnpkRnh1SUNBdkx5QndiM2RsY2lCdlppQXlMQ0IwYnlCd2NtVjJaVzUwSUdsdVkzSmxZWE5wYm1jZ2FYUWdaWGhqWlhOemFYWmxiSGtnYVc0Z2RHbHVlVnh1SUNBdkx5QmhiVzkxYm5SekxseHVJQ0JwWmlBb2JpQStJSE4wWVhSbExtaHBaMmhYWVhSbGNrMWhjbXNwWEc0Z0lDQWdjM1JoZEdVdWFHbG5hRmRoZEdWeVRXRnlheUE5SUhKdmRXNWtWWEJVYjA1bGVIUlFiM2RsY2s5bU1paHVLVHRjYmx4dUlDQXZMeUJrYjI0bmRDQm9ZWFpsSUhSb1lYUWdiWFZqYUM0Z0lISmxkSFZ5YmlCdWRXeHNMQ0IxYm14bGMzTWdkMlVuZG1VZ1pXNWtaV1F1WEc0Z0lHbG1JQ2h1SUQ0Z2MzUmhkR1V1YkdWdVozUm9LU0I3WEc0Z0lDQWdhV1lnS0NGemRHRjBaUzVsYm1SbFpDa2dlMXh1SUNBZ0lDQWdjM1JoZEdVdWJtVmxaRkpsWVdSaFlteGxJRDBnZEhKMVpUdGNiaUFnSUNBZ0lISmxkSFZ5YmlBd08xeHVJQ0FnSUgwZ1pXeHpaVnh1SUNBZ0lDQWdjbVYwZFhKdUlITjBZWFJsTG14bGJtZDBhRHRjYmlBZ2ZWeHVYRzRnSUhKbGRIVnliaUJ1TzF4dWZWeHVYRzR2THlCNWIzVWdZMkZ1SUc5MlpYSnlhV1JsSUdWcGRHaGxjaUIwYUdseklHMWxkR2h2WkN3Z2IzSWdkR2hsSUdGemVXNWpJRjl5WldGa0tHNHBJR0psYkc5M0xseHVVbVZoWkdGaWJHVXVjSEp2ZEc5MGVYQmxMbkpsWVdRZ1BTQm1kVzVqZEdsdmJpaHVLU0I3WEc0Z0lHUmxZblZuS0NkeVpXRmtKeXdnYmlrN1hHNGdJSFpoY2lCemRHRjBaU0E5SUhSb2FYTXVYM0psWVdSaFlteGxVM1JoZEdVN1hHNGdJSFpoY2lCdVQzSnBaeUE5SUc0N1hHNWNiaUFnYVdZZ0tDRjFkR2xzTG1selRuVnRZbVZ5S0c0cElIeDhJRzRnUGlBd0tWeHVJQ0FnSUhOMFlYUmxMbVZ0YVhSMFpXUlNaV0ZrWVdKc1pTQTlJR1poYkhObE8xeHVYRzRnSUM4dklHbG1JSGRsSjNKbElHUnZhVzVuSUhKbFlXUW9NQ2tnZEc4Z2RISnBaMmRsY2lCaElISmxZV1JoWW14bElHVjJaVzUwTENCaWRYUWdkMlZjYmlBZ0x5OGdZV3h5WldGa2VTQm9ZWFpsSUdFZ1luVnVZMmdnYjJZZ1pHRjBZU0JwYmlCMGFHVWdZblZtWm1WeUxDQjBhR1Z1SUdwMWMzUWdkSEpwWjJkbGNseHVJQ0F2THlCMGFHVWdKM0psWVdSaFlteGxKeUJsZG1WdWRDQmhibVFnYlc5MlpTQnZiaTVjYmlBZ2FXWWdLRzRnUFQwOUlEQWdKaVpjYmlBZ0lDQWdJSE4wWVhSbExtNWxaV1JTWldGa1lXSnNaU0FtSmx4dUlDQWdJQ0FnS0hOMFlYUmxMbXhsYm1kMGFDQStQU0J6ZEdGMFpTNW9hV2RvVjJGMFpYSk5ZWEpySUh4OElITjBZWFJsTG1WdVpHVmtLU2tnZTF4dUlDQWdJR1JsWW5WbktDZHlaV0ZrT2lCbGJXbDBVbVZoWkdGaWJHVW5MQ0J6ZEdGMFpTNXNaVzVuZEdnc0lITjBZWFJsTG1WdVpHVmtLVHRjYmlBZ0lDQnBaaUFvYzNSaGRHVXViR1Z1WjNSb0lEMDlQU0F3SUNZbUlITjBZWFJsTG1WdVpHVmtLVnh1SUNBZ0lDQWdaVzVrVW1WaFpHRmliR1VvZEdocGN5azdYRzRnSUNBZ1pXeHpaVnh1SUNBZ0lDQWdaVzFwZEZKbFlXUmhZbXhsS0hSb2FYTXBPMXh1SUNBZ0lISmxkSFZ5YmlCdWRXeHNPMXh1SUNCOVhHNWNiaUFnYmlBOUlHaHZkMDExWTJoVWIxSmxZV1FvYml3Z2MzUmhkR1VwTzF4dVhHNGdJQzh2SUdsbUlIZGxKM1psSUdWdVpHVmtMQ0JoYm1RZ2QyVW5jbVVnYm05M0lHTnNaV0Z5TENCMGFHVnVJR1pwYm1semFDQnBkQ0IxY0M1Y2JpQWdhV1lnS0c0Z1BUMDlJREFnSmlZZ2MzUmhkR1V1Wlc1a1pXUXBJSHRjYmlBZ0lDQnBaaUFvYzNSaGRHVXViR1Z1WjNSb0lEMDlQU0F3S1Z4dUlDQWdJQ0FnWlc1a1VtVmhaR0ZpYkdVb2RHaHBjeWs3WEc0Z0lDQWdjbVYwZFhKdUlHNTFiR3c3WEc0Z0lIMWNibHh1SUNBdkx5QkJiR3dnZEdobElHRmpkSFZoYkNCamFIVnVheUJuWlc1bGNtRjBhVzl1SUd4dloybGpJRzVsWldSeklIUnZJR0psWEc0Z0lDOHZJQ3BpWld4dmR5b2dkR2hsSUdOaGJHd2dkRzhnWDNKbFlXUXVJQ0JVYUdVZ2NtVmhjMjl1SUdseklIUm9ZWFFnYVc0Z1kyVnlkR0ZwYmx4dUlDQXZMeUJ6ZVc1MGFHVjBhV01nYzNSeVpXRnRJR05oYzJWekxDQnpkV05vSUdGeklIQmhjM04wYUhKdmRXZG9JSE4wY21WaGJYTXNJRjl5WldGa1hHNGdJQzh2SUcxaGVTQmlaU0JoSUdOdmJYQnNaWFJsYkhrZ2MzbHVZMmh5YjI1dmRYTWdiM0JsY21GMGFXOXVJSGRvYVdOb0lHMWhlU0JqYUdGdVoyVmNiaUFnTHk4Z2RHaGxJSE4wWVhSbElHOW1JSFJvWlNCeVpXRmtJR0oxWm1abGNpd2djSEp2ZG1sa2FXNW5JR1Z1YjNWbmFDQmtZWFJoSUhkb1pXNWNiaUFnTHk4Z1ltVm1iM0psSUhSb1pYSmxJSGRoY3lBcWJtOTBLaUJsYm05MVoyZ3VYRzRnSUM4dlhHNGdJQzh2SUZOdkxDQjBhR1VnYzNSbGNITWdZWEpsT2x4dUlDQXZMeUF4TGlCR2FXZDFjbVVnYjNWMElIZG9ZWFFnZEdobElITjBZWFJsSUc5bUlIUm9hVzVuY3lCM2FXeHNJR0psSUdGbWRHVnlJSGRsSUdSdlhHNGdJQzh2SUdFZ2NtVmhaQ0JtY205dElIUm9aU0JpZFdabVpYSXVYRzRnSUM4dlhHNGdJQzh2SURJdUlFbG1JSFJvWVhRZ2NtVnpkV3gwYVc1bklITjBZWFJsSUhkcGJHd2dkSEpwWjJkbGNpQmhJRjl5WldGa0xDQjBhR1Z1SUdOaGJHd2dYM0psWVdRdVhHNGdJQzh2SUU1dmRHVWdkR2hoZENCMGFHbHpJRzFoZVNCaVpTQmhjM2x1WTJoeWIyNXZkWE1zSUc5eUlITjVibU5vY205dWIzVnpMaUFnV1dWekxDQnBkQ0JwYzF4dUlDQXZMeUJrWldWd2JIa2dkV2RzZVNCMGJ5QjNjbWwwWlNCQlVFbHpJSFJvYVhNZ2QyRjVMQ0JpZFhRZ2RHaGhkQ0J6ZEdsc2JDQmtiMlZ6YmlkMElHMWxZVzVjYmlBZ0x5OGdkR2hoZENCMGFHVWdVbVZoWkdGaWJHVWdZMnhoYzNNZ2MyaHZkV3hrSUdKbGFHRjJaU0JwYlhCeWIzQmxjbXg1TENCaGN5QnpkSEpsWVcxeklHRnlaVnh1SUNBdkx5QmtaWE5wWjI1bFpDQjBieUJpWlNCemVXNWpMMkZ6ZVc1aklHRm5ibTl6ZEdsakxseHVJQ0F2THlCVVlXdGxJRzV2ZEdVZ2FXWWdkR2hsSUY5eVpXRmtJR05oYkd3Z2FYTWdjM2x1WXlCdmNpQmhjM2x1WXlBb2FXVXNJR2xtSUhSb1pTQnlaV0ZrSUdOaGJHeGNiaUFnTHk4Z2FHRnpJSEpsZEhWeWJtVmtJSGxsZENrc0lITnZJSFJvWVhRZ2QyVWdhMjV2ZHlCM2FHVjBhR1Z5SUc5eUlHNXZkQ0JwZENkeklITmhabVVnZEc4Z1pXMXBkRnh1SUNBdkx5QW5jbVZoWkdGaWJHVW5JR1YwWXk1Y2JpQWdMeTljYmlBZ0x5OGdNeTRnUVdOMGRXRnNiSGtnY0hWc2JDQjBhR1VnY21WeGRXVnpkR1ZrSUdOb2RXNXJjeUJ2ZFhRZ2IyWWdkR2hsSUdKMVptWmxjaUJoYm1RZ2NtVjBkWEp1TGx4dVhHNGdJQzh2SUdsbUlIZGxJRzVsWldRZ1lTQnlaV0ZrWVdKc1pTQmxkbVZ1ZEN3Z2RHaGxiaUIzWlNCdVpXVmtJSFJ2SUdSdklITnZiV1VnY21WaFpHbHVaeTVjYmlBZ2RtRnlJR1J2VW1WaFpDQTlJSE4wWVhSbExtNWxaV1JTWldGa1lXSnNaVHRjYmlBZ1pHVmlkV2NvSjI1bFpXUWdjbVZoWkdGaWJHVW5MQ0JrYjFKbFlXUXBPMXh1WEc0Z0lDOHZJR2xtSUhkbElHTjFjbkpsYm5Sc2VTQm9ZWFpsSUd4bGMzTWdkR2hoYmlCMGFHVWdhR2xuYUZkaGRHVnlUV0Z5YXl3Z2RHaGxiaUJoYkhOdklISmxZV1FnYzI5dFpWeHVJQ0JwWmlBb2MzUmhkR1V1YkdWdVozUm9JRDA5UFNBd0lIeDhJSE4wWVhSbExteGxibWQwYUNBdElHNGdQQ0J6ZEdGMFpTNW9hV2RvVjJGMFpYSk5ZWEpyS1NCN1hHNGdJQ0FnWkc5U1pXRmtJRDBnZEhKMVpUdGNiaUFnSUNCa1pXSjFaeWduYkdWdVozUm9JR3hsYzNNZ2RHaGhiaUIzWVhSbGNtMWhjbXNuTENCa2IxSmxZV1FwTzF4dUlDQjlYRzVjYmlBZ0x5OGdhRzkzWlhabGNpd2dhV1lnZDJVbmRtVWdaVzVrWldRc0lIUm9aVzRnZEdobGNtVW5jeUJ1YnlCd2IybHVkQ3dnWVc1a0lHbG1JSGRsSjNKbElHRnNjbVZoWkhsY2JpQWdMeThnY21WaFpHbHVaeXdnZEdobGJpQnBkQ2R6SUhWdWJtVmpaWE56WVhKNUxseHVJQ0JwWmlBb2MzUmhkR1V1Wlc1a1pXUWdmSHdnYzNSaGRHVXVjbVZoWkdsdVp5a2dlMXh1SUNBZ0lHUnZVbVZoWkNBOUlHWmhiSE5sTzF4dUlDQWdJR1JsWW5WbktDZHlaV0ZrYVc1bklHOXlJR1Z1WkdWa0p5d2daRzlTWldGa0tUdGNiaUFnZlZ4dVhHNGdJR2xtSUNoa2IxSmxZV1FwSUh0Y2JpQWdJQ0JrWldKMVp5Z25aRzhnY21WaFpDY3BPMXh1SUNBZ0lITjBZWFJsTG5KbFlXUnBibWNnUFNCMGNuVmxPMXh1SUNBZ0lITjBZWFJsTG5ONWJtTWdQU0IwY25WbE8xeHVJQ0FnSUM4dklHbG1JSFJvWlNCc1pXNW5kR2dnYVhNZ1kzVnljbVZ1ZEd4NUlIcGxjbThzSUhSb1pXNGdkMlVnS201bFpXUXFJR0VnY21WaFpHRmliR1VnWlhabGJuUXVYRzRnSUNBZ2FXWWdLSE4wWVhSbExteGxibWQwYUNBOVBUMGdNQ2xjYmlBZ0lDQWdJSE4wWVhSbExtNWxaV1JTWldGa1lXSnNaU0E5SUhSeWRXVTdYRzRnSUNBZ0x5OGdZMkZzYkNCcGJuUmxjbTVoYkNCeVpXRmtJRzFsZEdodlpGeHVJQ0FnSUhSb2FYTXVYM0psWVdRb2MzUmhkR1V1YUdsbmFGZGhkR1Z5VFdGeWF5azdYRzRnSUNBZ2MzUmhkR1V1YzNsdVl5QTlJR1poYkhObE8xeHVJQ0I5WEc1Y2JpQWdMeThnU1dZZ1gzSmxZV1FnY0hWemFHVmtJR1JoZEdFZ2MzbHVZMmh5YjI1dmRYTnNlU3dnZEdobGJpQmdjbVZoWkdsdVoyQWdkMmxzYkNCaVpTQm1ZV3h6WlN4Y2JpQWdMeThnWVc1a0lIZGxJRzVsWldRZ2RHOGdjbVV0WlhaaGJIVmhkR1VnYUc5M0lHMTFZMmdnWkdGMFlTQjNaU0JqWVc0Z2NtVjBkWEp1SUhSdklIUm9aU0IxYzJWeUxseHVJQ0JwWmlBb1pHOVNaV0ZrSUNZbUlDRnpkR0YwWlM1eVpXRmthVzVuS1Z4dUlDQWdJRzRnUFNCb2IzZE5kV05vVkc5U1pXRmtLRzVQY21sbkxDQnpkR0YwWlNrN1hHNWNiaUFnZG1GeUlISmxkRHRjYmlBZ2FXWWdLRzRnUGlBd0tWeHVJQ0FnSUhKbGRDQTlJR1p5YjIxTWFYTjBLRzRzSUhOMFlYUmxLVHRjYmlBZ1pXeHpaVnh1SUNBZ0lISmxkQ0E5SUc1MWJHdzdYRzVjYmlBZ2FXWWdLSFYwYVd3dWFYTk9kV3hzS0hKbGRDa3BJSHRjYmlBZ0lDQnpkR0YwWlM1dVpXVmtVbVZoWkdGaWJHVWdQU0IwY25WbE8xeHVJQ0FnSUc0Z1BTQXdPMXh1SUNCOVhHNWNiaUFnYzNSaGRHVXViR1Z1WjNSb0lDMDlJRzQ3WEc1Y2JpQWdMeThnU1dZZ2QyVWdhR0YyWlNCdWIzUm9hVzVuSUdsdUlIUm9aU0JpZFdabVpYSXNJSFJvWlc0Z2QyVWdkMkZ1ZENCMGJ5QnJibTkzWEc0Z0lDOHZJR0Z6SUhOdmIyNGdZWE1nZDJVZ0ttUnZLaUJuWlhRZ2MyOXRaWFJvYVc1bklHbHVkRzhnZEdobElHSjFabVpsY2k1Y2JpQWdhV1lnS0hOMFlYUmxMbXhsYm1kMGFDQTlQVDBnTUNBbUppQWhjM1JoZEdVdVpXNWtaV1FwWEc0Z0lDQWdjM1JoZEdVdWJtVmxaRkpsWVdSaFlteGxJRDBnZEhKMVpUdGNibHh1SUNBdkx5QkpaaUIzWlNCMGNtbGxaQ0IwYnlCeVpXRmtLQ2tnY0dGemRDQjBhR1VnUlU5R0xDQjBhR1Z1SUdWdGFYUWdaVzVrSUc5dUlIUm9aU0J1WlhoMElIUnBZMnN1WEc0Z0lHbG1JQ2h1VDNKcFp5QWhQVDBnYmlBbUppQnpkR0YwWlM1bGJtUmxaQ0FtSmlCemRHRjBaUzVzWlc1bmRHZ2dQVDA5SURBcFhHNGdJQ0FnWlc1a1VtVmhaR0ZpYkdVb2RHaHBjeWs3WEc1Y2JpQWdhV1lnS0NGMWRHbHNMbWx6VG5Wc2JDaHlaWFFwS1Z4dUlDQWdJSFJvYVhNdVpXMXBkQ2duWkdGMFlTY3NJSEpsZENrN1hHNWNiaUFnY21WMGRYSnVJSEpsZER0Y2JuMDdYRzVjYm1aMWJtTjBhVzl1SUdOb2RXNXJTVzUyWVd4cFpDaHpkR0YwWlN3Z1kyaDFibXNwSUh0Y2JpQWdkbUZ5SUdWeUlEMGdiblZzYkR0Y2JpQWdhV1lnS0NGMWRHbHNMbWx6UW5WbVptVnlLR05vZFc1cktTQW1KbHh1SUNBZ0lDQWdJWFYwYVd3dWFYTlRkSEpwYm1jb1kyaDFibXNwSUNZbVhHNGdJQ0FnSUNBaGRYUnBiQzVwYzA1MWJHeFBjbFZ1WkdWbWFXNWxaQ2hqYUhWdWF5a2dKaVpjYmlBZ0lDQWdJQ0Z6ZEdGMFpTNXZZbXBsWTNSTmIyUmxLU0I3WEc0Z0lDQWdaWElnUFNCdVpYY2dWSGx3WlVWeWNtOXlLQ2RKYm5aaGJHbGtJRzV2YmkxemRISnBibWN2WW5WbVptVnlJR05vZFc1ckp5azdYRzRnSUgxY2JpQWdjbVYwZFhKdUlHVnlPMXh1ZlZ4dVhHNWNibVoxYm1OMGFXOXVJRzl1Ulc5bVEyaDFibXNvYzNSeVpXRnRMQ0J6ZEdGMFpTa2dlMXh1SUNCcFppQW9jM1JoZEdVdVpHVmpiMlJsY2lBbUppQWhjM1JoZEdVdVpXNWtaV1FwSUh0Y2JpQWdJQ0IyWVhJZ1kyaDFibXNnUFNCemRHRjBaUzVrWldOdlpHVnlMbVZ1WkNncE8xeHVJQ0FnSUdsbUlDaGphSFZ1YXlBbUppQmphSFZ1YXk1c1pXNW5kR2dwSUh0Y2JpQWdJQ0FnSUhOMFlYUmxMbUoxWm1abGNpNXdkWE5vS0dOb2RXNXJLVHRjYmlBZ0lDQWdJSE4wWVhSbExteGxibWQwYUNBclBTQnpkR0YwWlM1dlltcGxZM1JOYjJSbElEOGdNU0E2SUdOb2RXNXJMbXhsYm1kMGFEdGNiaUFnSUNCOVhHNGdJSDFjYmlBZ2MzUmhkR1V1Wlc1a1pXUWdQU0IwY25WbE8xeHVYRzRnSUM4dklHVnRhWFFnSjNKbFlXUmhZbXhsSnlCdWIzY2dkRzhnYldGclpTQnpkWEpsSUdsMElHZGxkSE1nY0dsamEyVmtJSFZ3TGx4dUlDQmxiV2wwVW1WaFpHRmliR1VvYzNSeVpXRnRLVHRjYm4xY2JseHVMeThnUkc5dUozUWdaVzFwZENCeVpXRmtZV0pzWlNCeWFXZG9kQ0JoZDJGNUlHbHVJSE41Ym1NZ2JXOWtaU3dnWW1WallYVnpaU0IwYUdseklHTmhiaUIwY21sbloyVnlYRzR2THlCaGJtOTBhR1Z5SUhKbFlXUW9LU0JqWVd4c0lEMCtJSE4wWVdOcklHOTJaWEptYkc5M0xpQWdWR2hwY3lCM1lYa3NJR2wwSUcxcFoyaDBJSFJ5YVdkblpYSmNiaTh2SUdFZ2JtVjRkRlJwWTJzZ2NtVmpkWEp6YVc5dUlIZGhjbTVwYm1jc0lHSjFkQ0IwYUdGMEozTWdibTkwSUhOdklHSmhaQzVjYm1aMWJtTjBhVzl1SUdWdGFYUlNaV0ZrWVdKc1pTaHpkSEpsWVcwcElIdGNiaUFnZG1GeUlITjBZWFJsSUQwZ2MzUnlaV0Z0TGw5eVpXRmtZV0pzWlZOMFlYUmxPMXh1SUNCemRHRjBaUzV1WldWa1VtVmhaR0ZpYkdVZ1BTQm1ZV3h6WlR0Y2JpQWdhV1lnS0NGemRHRjBaUzVsYldsMGRHVmtVbVZoWkdGaWJHVXBJSHRjYmlBZ0lDQmtaV0oxWnlnblpXMXBkRkpsWVdSaFlteGxKeXdnYzNSaGRHVXVabXh2ZDJsdVp5azdYRzRnSUNBZ2MzUmhkR1V1WlcxcGRIUmxaRkpsWVdSaFlteGxJRDBnZEhKMVpUdGNiaUFnSUNCcFppQW9jM1JoZEdVdWMzbHVZeWxjYmlBZ0lDQWdJSEJ5YjJObGMzTXVibVY0ZEZScFkyc29ablZ1WTNScGIyNG9LU0I3WEc0Z0lDQWdJQ0FnSUdWdGFYUlNaV0ZrWVdKc1pWOG9jM1J5WldGdEtUdGNiaUFnSUNBZ0lIMHBPMXh1SUNBZ0lHVnNjMlZjYmlBZ0lDQWdJR1Z0YVhSU1pXRmtZV0pzWlY4b2MzUnlaV0Z0S1R0Y2JpQWdmVnh1ZlZ4dVhHNW1kVzVqZEdsdmJpQmxiV2wwVW1WaFpHRmliR1ZmS0hOMGNtVmhiU2tnZTF4dUlDQmtaV0oxWnlnblpXMXBkQ0J5WldGa1lXSnNaU2NwTzF4dUlDQnpkSEpsWVcwdVpXMXBkQ2duY21WaFpHRmliR1VuS1R0Y2JpQWdabXh2ZHloemRISmxZVzBwTzF4dWZWeHVYRzVjYmk4dklHRjBJSFJvYVhNZ2NHOXBiblFzSUhSb1pTQjFjMlZ5SUdoaGN5QndjbVZ6ZFcxaFlteDVJSE5sWlc0Z2RHaGxJQ2R5WldGa1lXSnNaU2NnWlhabGJuUXNYRzR2THlCaGJtUWdZMkZzYkdWa0lISmxZV1FvS1NCMGJ5QmpiMjV6ZFcxbElITnZiV1VnWkdGMFlTNGdJSFJvWVhRZ2JXRjVJR2hoZG1VZ2RISnBaMmRsY21Wa1hHNHZMeUJwYmlCMGRYSnVJR0Z1YjNSb1pYSWdYM0psWVdRb2Jpa2dZMkZzYkN3Z2FXNGdkMmhwWTJnZ1kyRnpaU0J5WldGa2FXNW5JRDBnZEhKMVpTQnBabHh1THk4Z2FYUW5jeUJwYmlCd2NtOW5jbVZ6Y3k1Y2JpOHZJRWh2ZDJWMlpYSXNJR2xtSUhkbEozSmxJRzV2ZENCbGJtUmxaQ3dnYjNJZ2NtVmhaR2x1Wnl3Z1lXNWtJSFJvWlNCc1pXNW5kR2dnUENCb2QyMHNYRzR2THlCMGFHVnVJR2R2SUdGb1pXRmtJR0Z1WkNCMGNua2dkRzhnY21WaFpDQnpiMjFsSUcxdmNtVWdjSEpsWlcxd2RHbDJaV3g1TGx4dVpuVnVZM1JwYjI0Z2JXRjVZbVZTWldGa1RXOXlaU2h6ZEhKbFlXMHNJSE4wWVhSbEtTQjdYRzRnSUdsbUlDZ2hjM1JoZEdVdWNtVmhaR2x1WjAxdmNtVXBJSHRjYmlBZ0lDQnpkR0YwWlM1eVpXRmthVzVuVFc5eVpTQTlJSFJ5ZFdVN1hHNGdJQ0FnY0hKdlkyVnpjeTV1WlhoMFZHbGpheWhtZFc1amRHbHZiaWdwSUh0Y2JpQWdJQ0FnSUcxaGVXSmxVbVZoWkUxdmNtVmZLSE4wY21WaGJTd2djM1JoZEdVcE8xeHVJQ0FnSUgwcE8xeHVJQ0I5WEc1OVhHNWNibVoxYm1OMGFXOXVJRzFoZVdKbFVtVmhaRTF2Y21WZktITjBjbVZoYlN3Z2MzUmhkR1VwSUh0Y2JpQWdkbUZ5SUd4bGJpQTlJSE4wWVhSbExteGxibWQwYUR0Y2JpQWdkMmhwYkdVZ0tDRnpkR0YwWlM1eVpXRmthVzVuSUNZbUlDRnpkR0YwWlM1bWJHOTNhVzVuSUNZbUlDRnpkR0YwWlM1bGJtUmxaQ0FtSmx4dUlDQWdJQ0FnSUNBZ2MzUmhkR1V1YkdWdVozUm9JRHdnYzNSaGRHVXVhR2xuYUZkaGRHVnlUV0Z5YXlrZ2UxeHVJQ0FnSUdSbFluVm5LQ2R0WVhsaVpWSmxZV1JOYjNKbElISmxZV1FnTUNjcE8xeHVJQ0FnSUhOMGNtVmhiUzV5WldGa0tEQXBPMXh1SUNBZ0lHbG1JQ2hzWlc0Z1BUMDlJSE4wWVhSbExteGxibWQwYUNsY2JpQWdJQ0FnSUM4dklHUnBaRzRuZENCblpYUWdZVzU1SUdSaGRHRXNJSE4wYjNBZ2MzQnBibTVwYm1jdVhHNGdJQ0FnSUNCaWNtVmhhenRjYmlBZ0lDQmxiSE5sWEc0Z0lDQWdJQ0JzWlc0Z1BTQnpkR0YwWlM1c1pXNW5kR2c3WEc0Z0lIMWNiaUFnYzNSaGRHVXVjbVZoWkdsdVowMXZjbVVnUFNCbVlXeHpaVHRjYm4xY2JseHVMeThnWVdKemRISmhZM1FnYldWMGFHOWtMaUFnZEc4Z1ltVWdiM1psY25KcFpHUmxiaUJwYmlCemNHVmphV1pwWXlCcGJYQnNaVzFsYm5SaGRHbHZiaUJqYkdGemMyVnpMbHh1THk4Z1kyRnNiQ0JqWWlobGNpd2daR0YwWVNrZ2QyaGxjbVVnWkdGMFlTQnBjeUE4UFNCdUlHbHVJR3hsYm1kMGFDNWNiaTh2SUdadmNpQjJhWEowZFdGc0lDaHViMjR0YzNSeWFXNW5MQ0J1YjI0dFluVm1abVZ5S1NCemRISmxZVzF6TENCY0lteGxibWQwYUZ3aUlHbHpJSE52YldWM2FHRjBYRzR2THlCaGNtSnBkSEpoY25rc0lHRnVaQ0J3WlhKb1lYQnpJRzV2ZENCMlpYSjVJRzFsWVc1cGJtZG1kV3d1WEc1U1pXRmtZV0pzWlM1d2NtOTBiM1I1Y0dVdVgzSmxZV1FnUFNCbWRXNWpkR2x2YmlodUtTQjdYRzRnSUhSb2FYTXVaVzFwZENnblpYSnliM0luTENCdVpYY2dSWEp5YjNJb0oyNXZkQ0JwYlhCc1pXMWxiblJsWkNjcEtUdGNibjA3WEc1Y2JsSmxZV1JoWW14bExuQnliM1J2ZEhsd1pTNXdhWEJsSUQwZ1puVnVZM1JwYjI0b1pHVnpkQ3dnY0dsd1pVOXdkSE1wSUh0Y2JpQWdkbUZ5SUhOeVl5QTlJSFJvYVhNN1hHNGdJSFpoY2lCemRHRjBaU0E5SUhSb2FYTXVYM0psWVdSaFlteGxVM1JoZEdVN1hHNWNiaUFnYzNkcGRHTm9JQ2h6ZEdGMFpTNXdhWEJsYzBOdmRXNTBLU0I3WEc0Z0lDQWdZMkZ6WlNBd09seHVJQ0FnSUNBZ2MzUmhkR1V1Y0dsd1pYTWdQU0JrWlhOME8xeHVJQ0FnSUNBZ1luSmxZV3M3WEc0Z0lDQWdZMkZ6WlNBeE9seHVJQ0FnSUNBZ2MzUmhkR1V1Y0dsd1pYTWdQU0JiYzNSaGRHVXVjR2x3WlhNc0lHUmxjM1JkTzF4dUlDQWdJQ0FnWW5KbFlXczdYRzRnSUNBZ1pHVm1ZWFZzZERwY2JpQWdJQ0FnSUhOMFlYUmxMbkJwY0dWekxuQjFjMmdvWkdWemRDazdYRzRnSUNBZ0lDQmljbVZoYXp0Y2JpQWdmVnh1SUNCemRHRjBaUzV3YVhCbGMwTnZkVzUwSUNzOUlERTdYRzRnSUdSbFluVm5LQ2R3YVhCbElHTnZkVzUwUFNWa0lHOXdkSE05SldvbkxDQnpkR0YwWlM1d2FYQmxjME52ZFc1MExDQndhWEJsVDNCMGN5azdYRzVjYmlBZ2RtRnlJR1J2Ulc1a0lEMGdLQ0Z3YVhCbFQzQjBjeUI4ZkNCd2FYQmxUM0IwY3k1bGJtUWdJVDA5SUdaaGJITmxLU0FtSmx4dUlDQWdJQ0FnSUNBZ0lDQWdJQ0JrWlhOMElDRTlQU0J3Y205alpYTnpMbk4wWkc5MWRDQW1KbHh1SUNBZ0lDQWdJQ0FnSUNBZ0lDQmtaWE4wSUNFOVBTQndjbTlqWlhOekxuTjBaR1Z5Y2p0Y2JseHVJQ0IyWVhJZ1pXNWtSbTRnUFNCa2IwVnVaQ0EvSUc5dVpXNWtJRG9nWTJ4bFlXNTFjRHRjYmlBZ2FXWWdLSE4wWVhSbExtVnVaRVZ0YVhSMFpXUXBYRzRnSUNBZ2NISnZZMlZ6Y3k1dVpYaDBWR2xqYXlobGJtUkdiaWs3WEc0Z0lHVnNjMlZjYmlBZ0lDQnpjbU11YjI1alpTZ25aVzVrSnl3Z1pXNWtSbTRwTzF4dVhHNGdJR1JsYzNRdWIyNG9KM1Z1Y0dsd1pTY3NJRzl1ZFc1d2FYQmxLVHRjYmlBZ1puVnVZM1JwYjI0Z2IyNTFibkJwY0dVb2NtVmhaR0ZpYkdVcElIdGNiaUFnSUNCa1pXSjFaeWduYjI1MWJuQnBjR1VuS1R0Y2JpQWdJQ0JwWmlBb2NtVmhaR0ZpYkdVZ1BUMDlJSE55WXlrZ2UxeHVJQ0FnSUNBZ1kyeGxZVzUxY0NncE8xeHVJQ0FnSUgxY2JpQWdmVnh1WEc0Z0lHWjFibU4wYVc5dUlHOXVaVzVrS0NrZ2UxeHVJQ0FnSUdSbFluVm5LQ2R2Ym1WdVpDY3BPMXh1SUNBZ0lHUmxjM1F1Wlc1a0tDazdYRzRnSUgxY2JseHVJQ0F2THlCM2FHVnVJSFJvWlNCa1pYTjBJR1J5WVdsdWN5d2dhWFFnY21Wa2RXTmxjeUIwYUdVZ1lYZGhhWFJFY21GcGJpQmpiM1Z1ZEdWeVhHNGdJQzh2SUc5dUlIUm9aU0J6YjNWeVkyVXVJQ0JVYUdseklIZHZkV3hrSUdKbElHMXZjbVVnWld4bFoyRnVkQ0IzYVhSb0lHRWdMbTl1WTJVb0tWeHVJQ0F2THlCb1lXNWtiR1Z5SUdsdUlHWnNiM2NvS1N3Z1luVjBJR0ZrWkdsdVp5QmhibVFnY21WdGIzWnBibWNnY21Wd1pXRjBaV1JzZVNCcGMxeHVJQ0F2THlCMGIyOGdjMnh2ZHk1Y2JpQWdkbUZ5SUc5dVpISmhhVzRnUFNCd2FYQmxUMjVFY21GcGJpaHpjbU1wTzF4dUlDQmtaWE4wTG05dUtDZGtjbUZwYmljc0lHOXVaSEpoYVc0cE8xeHVYRzRnSUdaMWJtTjBhVzl1SUdOc1pXRnVkWEFvS1NCN1hHNGdJQ0FnWkdWaWRXY29KMk5zWldGdWRYQW5LVHRjYmlBZ0lDQXZMeUJqYkdWaGJuVndJR1YyWlc1MElHaGhibVJzWlhKeklHOXVZMlVnZEdobElIQnBjR1VnYVhNZ1luSnZhMlZ1WEc0Z0lDQWdaR1Z6ZEM1eVpXMXZkbVZNYVhOMFpXNWxjaWduWTJ4dmMyVW5MQ0J2Ym1Oc2IzTmxLVHRjYmlBZ0lDQmtaWE4wTG5KbGJXOTJaVXhwYzNSbGJtVnlLQ2RtYVc1cGMyZ25MQ0J2Ym1acGJtbHphQ2s3WEc0Z0lDQWdaR1Z6ZEM1eVpXMXZkbVZNYVhOMFpXNWxjaWduWkhKaGFXNG5MQ0J2Ym1SeVlXbHVLVHRjYmlBZ0lDQmtaWE4wTG5KbGJXOTJaVXhwYzNSbGJtVnlLQ2RsY25KdmNpY3NJRzl1WlhKeWIzSXBPMXh1SUNBZ0lHUmxjM1F1Y21WdGIzWmxUR2x6ZEdWdVpYSW9KM1Z1Y0dsd1pTY3NJRzl1ZFc1d2FYQmxLVHRjYmlBZ0lDQnpjbU11Y21WdGIzWmxUR2x6ZEdWdVpYSW9KMlZ1WkNjc0lHOXVaVzVrS1R0Y2JpQWdJQ0J6Y21NdWNtVnRiM1psVEdsemRHVnVaWElvSjJWdVpDY3NJR05zWldGdWRYQXBPMXh1SUNBZ0lITnlZeTV5WlcxdmRtVk1hWE4wWlc1bGNpZ25aR0YwWVNjc0lHOXVaR0YwWVNrN1hHNWNiaUFnSUNBdkx5QnBaaUIwYUdVZ2NtVmhaR1Z5SUdseklIZGhhWFJwYm1jZ1ptOXlJR0VnWkhKaGFXNGdaWFpsYm5RZ1puSnZiU0IwYUdselhHNGdJQ0FnTHk4Z2MzQmxZMmxtYVdNZ2QzSnBkR1Z5TENCMGFHVnVJR2wwSUhkdmRXeGtJR05oZFhObElHbDBJSFJ2SUc1bGRtVnlJSE4wWVhKMFhHNGdJQ0FnTHk4Z1pteHZkMmx1WnlCaFoyRnBiaTVjYmlBZ0lDQXZMeUJUYnl3Z2FXWWdkR2hwY3lCcGN5QmhkMkZwZEdsdVp5QmhJR1J5WVdsdUxDQjBhR1Z1SUhkbElHcDFjM1FnWTJGc2JDQnBkQ0J1YjNjdVhHNGdJQ0FnTHk4Z1NXWWdkMlVnWkc5dUozUWdhMjV2ZHl3Z2RHaGxiaUJoYzNOMWJXVWdkR2hoZENCM1pTQmhjbVVnZDJGcGRHbHVaeUJtYjNJZ2IyNWxMbHh1SUNBZ0lHbG1JQ2h6ZEdGMFpTNWhkMkZwZEVSeVlXbHVJQ1ltWEc0Z0lDQWdJQ0FnSUNnaFpHVnpkQzVmZDNKcGRHRmliR1ZUZEdGMFpTQjhmQ0JrWlhOMExsOTNjbWwwWVdKc1pWTjBZWFJsTG01bFpXUkVjbUZwYmlrcFhHNGdJQ0FnSUNCdmJtUnlZV2x1S0NrN1hHNGdJSDFjYmx4dUlDQnpjbU11YjI0b0oyUmhkR0VuTENCdmJtUmhkR0VwTzF4dUlDQm1kVzVqZEdsdmJpQnZibVJoZEdFb1kyaDFibXNwSUh0Y2JpQWdJQ0JrWldKMVp5Z25iMjVrWVhSaEp5azdYRzRnSUNBZ2RtRnlJSEpsZENBOUlHUmxjM1F1ZDNKcGRHVW9ZMmgxYm1zcE8xeHVJQ0FnSUdsbUlDaG1ZV3h6WlNBOVBUMGdjbVYwS1NCN1hHNGdJQ0FnSUNCa1pXSjFaeWduWm1Gc2MyVWdkM0pwZEdVZ2NtVnpjRzl1YzJVc0lIQmhkWE5sSnl4Y2JpQWdJQ0FnSUNBZ0lDQWdJSE55WXk1ZmNtVmhaR0ZpYkdWVGRHRjBaUzVoZDJGcGRFUnlZV2x1S1R0Y2JpQWdJQ0FnSUhOeVl5NWZjbVZoWkdGaWJHVlRkR0YwWlM1aGQyRnBkRVJ5WVdsdUt5czdYRzRnSUNBZ0lDQnpjbU11Y0dGMWMyVW9LVHRjYmlBZ0lDQjlYRzRnSUgxY2JseHVJQ0F2THlCcFppQjBhR1VnWkdWemRDQm9ZWE1nWVc0Z1pYSnliM0lzSUhSb1pXNGdjM1J2Y0NCd2FYQnBibWNnYVc1MGJ5QnBkQzVjYmlBZ0x5OGdhRzkzWlhabGNpd2daRzl1SjNRZ2MzVndjSEpsYzNNZ2RHaGxJSFJvY205M2FXNW5JR0psYUdGMmFXOXlJR1p2Y2lCMGFHbHpMbHh1SUNCbWRXNWpkR2x2YmlCdmJtVnljbTl5S0dWeUtTQjdYRzRnSUNBZ1pHVmlkV2NvSjI5dVpYSnliM0luTENCbGNpazdYRzRnSUNBZ2RXNXdhWEJsS0NrN1hHNGdJQ0FnWkdWemRDNXlaVzF2ZG1WTWFYTjBaVzVsY2lnblpYSnliM0luTENCdmJtVnljbTl5S1R0Y2JpQWdJQ0JwWmlBb1JVVXViR2x6ZEdWdVpYSkRiM1Z1ZENoa1pYTjBMQ0FuWlhKeWIzSW5LU0E5UFQwZ01DbGNiaUFnSUNBZ0lHUmxjM1F1WlcxcGRDZ25aWEp5YjNJbkxDQmxjaWs3WEc0Z0lIMWNiaUFnTHk4Z1ZHaHBjeUJwY3lCaElHSnlkWFJoYkd4NUlIVm5iSGtnYUdGamF5QjBieUJ0WVd0bElITjFjbVVnZEdoaGRDQnZkWElnWlhKeWIzSWdhR0Z1Wkd4bGNseHVJQ0F2THlCcGN5QmhkSFJoWTJobFpDQmlaV1p2Y21VZ1lXNTVJSFZ6WlhKc1lXNWtJRzl1WlhNdUlDQk9SVlpGVWlCRVR5QlVTRWxUTGx4dUlDQnBaaUFvSVdSbGMzUXVYMlYyWlc1MGN5QjhmQ0FoWkdWemRDNWZaWFpsYm5SekxtVnljbTl5S1Z4dUlDQWdJR1JsYzNRdWIyNG9KMlZ5Y205eUp5d2diMjVsY25KdmNpazdYRzRnSUdWc2MyVWdhV1lnS0dselFYSnlZWGtvWkdWemRDNWZaWFpsYm5SekxtVnljbTl5S1NsY2JpQWdJQ0JrWlhOMExsOWxkbVZ1ZEhNdVpYSnliM0l1ZFc1emFHbG1kQ2h2Ym1WeWNtOXlLVHRjYmlBZ1pXeHpaVnh1SUNBZ0lHUmxjM1F1WDJWMlpXNTBjeTVsY25KdmNpQTlJRnR2Ym1WeWNtOXlMQ0JrWlhOMExsOWxkbVZ1ZEhNdVpYSnliM0pkTzF4dVhHNWNibHh1SUNBdkx5QkNiM1JvSUdOc2IzTmxJR0Z1WkNCbWFXNXBjMmdnYzJodmRXeGtJSFJ5YVdkblpYSWdkVzV3YVhCbExDQmlkWFFnYjI1c2VTQnZibU5sTGx4dUlDQm1kVzVqZEdsdmJpQnZibU5zYjNObEtDa2dlMXh1SUNBZ0lHUmxjM1F1Y21WdGIzWmxUR2x6ZEdWdVpYSW9KMlpwYm1semFDY3NJRzl1Wm1sdWFYTm9LVHRjYmlBZ0lDQjFibkJwY0dVb0tUdGNiaUFnZlZ4dUlDQmtaWE4wTG05dVkyVW9KMk5zYjNObEp5d2diMjVqYkc5elpTazdYRzRnSUdaMWJtTjBhVzl1SUc5dVptbHVhWE5vS0NrZ2UxeHVJQ0FnSUdSbFluVm5LQ2R2Ym1acGJtbHphQ2NwTzF4dUlDQWdJR1JsYzNRdWNtVnRiM1psVEdsemRHVnVaWElvSjJOc2IzTmxKeXdnYjI1amJHOXpaU2s3WEc0Z0lDQWdkVzV3YVhCbEtDazdYRzRnSUgxY2JpQWdaR1Z6ZEM1dmJtTmxLQ2RtYVc1cGMyZ25MQ0J2Ym1acGJtbHphQ2s3WEc1Y2JpQWdablZ1WTNScGIyNGdkVzV3YVhCbEtDa2dlMXh1SUNBZ0lHUmxZblZuS0NkMWJuQnBjR1VuS1R0Y2JpQWdJQ0J6Y21NdWRXNXdhWEJsS0dSbGMzUXBPMXh1SUNCOVhHNWNiaUFnTHk4Z2RHVnNiQ0IwYUdVZ1pHVnpkQ0IwYUdGMElHbDBKM01nWW1WcGJtY2djR2x3WldRZ2RHOWNiaUFnWkdWemRDNWxiV2wwS0Nkd2FYQmxKeXdnYzNKaktUdGNibHh1SUNBdkx5QnpkR0Z5ZENCMGFHVWdabXh2ZHlCcFppQnBkQ0JvWVhOdUozUWdZbVZsYmlCemRHRnlkR1ZrSUdGc2NtVmhaSGt1WEc0Z0lHbG1JQ2doYzNSaGRHVXVabXh2ZDJsdVp5a2dlMXh1SUNBZ0lHUmxZblZuS0Nkd2FYQmxJSEpsYzNWdFpTY3BPMXh1SUNBZ0lITnlZeTV5WlhOMWJXVW9LVHRjYmlBZ2ZWeHVYRzRnSUhKbGRIVnliaUJrWlhOME8xeHVmVHRjYmx4dVpuVnVZM1JwYjI0Z2NHbHdaVTl1UkhKaGFXNG9jM0pqS1NCN1hHNGdJSEpsZEhWeWJpQm1kVzVqZEdsdmJpZ3BJSHRjYmlBZ0lDQjJZWElnYzNSaGRHVWdQU0J6Y21NdVgzSmxZV1JoWW14bFUzUmhkR1U3WEc0Z0lDQWdaR1ZpZFdjb0ozQnBjR1ZQYmtSeVlXbHVKeXdnYzNSaGRHVXVZWGRoYVhSRWNtRnBiaWs3WEc0Z0lDQWdhV1lnS0hOMFlYUmxMbUYzWVdsMFJISmhhVzRwWEc0Z0lDQWdJQ0J6ZEdGMFpTNWhkMkZwZEVSeVlXbHVMUzA3WEc0Z0lDQWdhV1lnS0hOMFlYUmxMbUYzWVdsMFJISmhhVzRnUFQwOUlEQWdKaVlnUlVVdWJHbHpkR1Z1WlhKRGIzVnVkQ2h6Y21Nc0lDZGtZWFJoSnlrcElIdGNiaUFnSUNBZ0lITjBZWFJsTG1ac2IzZHBibWNnUFNCMGNuVmxPMXh1SUNBZ0lDQWdabXh2ZHloemNtTXBPMXh1SUNBZ0lIMWNiaUFnZlR0Y2JuMWNibHh1WEc1U1pXRmtZV0pzWlM1d2NtOTBiM1I1Y0dVdWRXNXdhWEJsSUQwZ1puVnVZM1JwYjI0b1pHVnpkQ2tnZTF4dUlDQjJZWElnYzNSaGRHVWdQU0IwYUdsekxsOXlaV0ZrWVdKc1pWTjBZWFJsTzF4dVhHNGdJQzh2SUdsbUlIZGxKM0psSUc1dmRDQndhWEJwYm1jZ1lXNTVkMmhsY21Vc0lIUm9aVzRnWkc4Z2JtOTBhR2x1Wnk1Y2JpQWdhV1lnS0hOMFlYUmxMbkJwY0dWelEyOTFiblFnUFQwOUlEQXBYRzRnSUNBZ2NtVjBkWEp1SUhSb2FYTTdYRzVjYmlBZ0x5OGdhblZ6ZENCdmJtVWdaR1Z6ZEdsdVlYUnBiMjR1SUNCdGIzTjBJR052YlcxdmJpQmpZWE5sTGx4dUlDQnBaaUFvYzNSaGRHVXVjR2x3WlhORGIzVnVkQ0E5UFQwZ01Ta2dlMXh1SUNBZ0lDOHZJSEJoYzNObFpDQnBiaUJ2Ym1Vc0lHSjFkQ0JwZENkeklHNXZkQ0IwYUdVZ2NtbG5hSFFnYjI1bExseHVJQ0FnSUdsbUlDaGtaWE4wSUNZbUlHUmxjM1FnSVQwOUlITjBZWFJsTG5CcGNHVnpLVnh1SUNBZ0lDQWdjbVYwZFhKdUlIUm9hWE03WEc1Y2JpQWdJQ0JwWmlBb0lXUmxjM1FwWEc0Z0lDQWdJQ0JrWlhOMElEMGdjM1JoZEdVdWNHbHdaWE03WEc1Y2JpQWdJQ0F2THlCbmIzUWdZU0J0WVhSamFDNWNiaUFnSUNCemRHRjBaUzV3YVhCbGN5QTlJRzUxYkd3N1hHNGdJQ0FnYzNSaGRHVXVjR2x3WlhORGIzVnVkQ0E5SURBN1hHNGdJQ0FnYzNSaGRHVXVabXh2ZDJsdVp5QTlJR1poYkhObE8xeHVJQ0FnSUdsbUlDaGtaWE4wS1Z4dUlDQWdJQ0FnWkdWemRDNWxiV2wwS0NkMWJuQnBjR1VuTENCMGFHbHpLVHRjYmlBZ0lDQnlaWFIxY200Z2RHaHBjenRjYmlBZ2ZWeHVYRzRnSUM4dklITnNiM2NnWTJGelpTNGdiWFZzZEdsd2JHVWdjR2x3WlNCa1pYTjBhVzVoZEdsdmJuTXVYRzVjYmlBZ2FXWWdLQ0ZrWlhOMEtTQjdYRzRnSUNBZ0x5OGdjbVZ0YjNabElHRnNiQzVjYmlBZ0lDQjJZWElnWkdWemRITWdQU0J6ZEdGMFpTNXdhWEJsY3p0Y2JpQWdJQ0IyWVhJZ2JHVnVJRDBnYzNSaGRHVXVjR2x3WlhORGIzVnVkRHRjYmlBZ0lDQnpkR0YwWlM1d2FYQmxjeUE5SUc1MWJHdzdYRzRnSUNBZ2MzUmhkR1V1Y0dsd1pYTkRiM1Z1ZENBOUlEQTdYRzRnSUNBZ2MzUmhkR1V1Wm14dmQybHVaeUE5SUdaaGJITmxPMXh1WEc0Z0lDQWdabTl5SUNoMllYSWdhU0E5SURBN0lHa2dQQ0JzWlc0N0lHa3JLeWxjYmlBZ0lDQWdJR1JsYzNSelcybGRMbVZ0YVhRb0ozVnVjR2x3WlNjc0lIUm9hWE1wTzF4dUlDQWdJSEpsZEhWeWJpQjBhR2x6TzF4dUlDQjlYRzVjYmlBZ0x5OGdkSEo1SUhSdklHWnBibVFnZEdobElISnBaMmgwSUc5dVpTNWNiaUFnZG1GeUlHa2dQU0JwYm1SbGVFOW1LSE4wWVhSbExuQnBjR1Z6TENCa1pYTjBLVHRjYmlBZ2FXWWdLR2tnUFQwOUlDMHhLVnh1SUNBZ0lISmxkSFZ5YmlCMGFHbHpPMXh1WEc0Z0lITjBZWFJsTG5CcGNHVnpMbk53YkdsalpTaHBMQ0F4S1R0Y2JpQWdjM1JoZEdVdWNHbHdaWE5EYjNWdWRDQXRQU0F4TzF4dUlDQnBaaUFvYzNSaGRHVXVjR2x3WlhORGIzVnVkQ0E5UFQwZ01TbGNiaUFnSUNCemRHRjBaUzV3YVhCbGN5QTlJSE4wWVhSbExuQnBjR1Z6V3pCZE8xeHVYRzRnSUdSbGMzUXVaVzFwZENnbmRXNXdhWEJsSnl3Z2RHaHBjeWs3WEc1Y2JpQWdjbVYwZFhKdUlIUm9hWE03WEc1OU8xeHVYRzR2THlCelpYUWdkWEFnWkdGMFlTQmxkbVZ1ZEhNZ2FXWWdkR2hsZVNCaGNtVWdZWE5yWldRZ1ptOXlYRzR2THlCRmJuTjFjbVVnY21WaFpHRmliR1VnYkdsemRHVnVaWEp6SUdWMlpXNTBkV0ZzYkhrZ1oyVjBJSE52YldWMGFHbHVaMXh1VW1WaFpHRmliR1V1Y0hKdmRHOTBlWEJsTG05dUlEMGdablZ1WTNScGIyNG9aWFlzSUdadUtTQjdYRzRnSUhaaGNpQnlaWE1nUFNCVGRISmxZVzB1Y0hKdmRHOTBlWEJsTG05dUxtTmhiR3dvZEdocGN5d2daWFlzSUdadUtUdGNibHh1SUNBdkx5QkpaaUJzYVhOMFpXNXBibWNnZEc4Z1pHRjBZU3dnWVc1a0lHbDBJR2hoY3lCdWIzUWdaWGh3YkdsamFYUnNlU0JpWldWdUlIQmhkWE5sWkN4Y2JpQWdMeThnZEdobGJpQmpZV3hzSUhKbGMzVnRaU0IwYnlCemRHRnlkQ0IwYUdVZ1pteHZkeUJ2WmlCa1lYUmhJRzl1SUhSb1pTQnVaWGgwSUhScFkyc3VYRzRnSUdsbUlDaGxkaUE5UFQwZ0oyUmhkR0VuSUNZbUlHWmhiSE5sSUNFOVBTQjBhR2x6TGw5eVpXRmtZV0pzWlZOMFlYUmxMbVpzYjNkcGJtY3BJSHRjYmlBZ0lDQjBhR2x6TG5KbGMzVnRaU2dwTzF4dUlDQjlYRzVjYmlBZ2FXWWdLR1YySUQwOVBTQW5jbVZoWkdGaWJHVW5JQ1ltSUhSb2FYTXVjbVZoWkdGaWJHVXBJSHRjYmlBZ0lDQjJZWElnYzNSaGRHVWdQU0IwYUdsekxsOXlaV0ZrWVdKc1pWTjBZWFJsTzF4dUlDQWdJR2xtSUNnaGMzUmhkR1V1Y21WaFpHRmliR1ZNYVhOMFpXNXBibWNwSUh0Y2JpQWdJQ0FnSUhOMFlYUmxMbkpsWVdSaFlteGxUR2x6ZEdWdWFXNW5JRDBnZEhKMVpUdGNiaUFnSUNBZ0lITjBZWFJsTG1WdGFYUjBaV1JTWldGa1lXSnNaU0E5SUdaaGJITmxPMXh1SUNBZ0lDQWdjM1JoZEdVdWJtVmxaRkpsWVdSaFlteGxJRDBnZEhKMVpUdGNiaUFnSUNBZ0lHbG1JQ2doYzNSaGRHVXVjbVZoWkdsdVp5a2dlMXh1SUNBZ0lDQWdJQ0IyWVhJZ2MyVnNaaUE5SUhSb2FYTTdYRzRnSUNBZ0lDQWdJSEJ5YjJObGMzTXVibVY0ZEZScFkyc29ablZ1WTNScGIyNG9LU0I3WEc0Z0lDQWdJQ0FnSUNBZ1pHVmlkV2NvSjNKbFlXUmhZbXhsSUc1bGVIUjBhV05ySUhKbFlXUWdNQ2NwTzF4dUlDQWdJQ0FnSUNBZ0lITmxiR1l1Y21WaFpDZ3dLVHRjYmlBZ0lDQWdJQ0FnZlNrN1hHNGdJQ0FnSUNCOUlHVnNjMlVnYVdZZ0tITjBZWFJsTG14bGJtZDBhQ2tnZTF4dUlDQWdJQ0FnSUNCbGJXbDBVbVZoWkdGaWJHVW9kR2hwY3l3Z2MzUmhkR1VwTzF4dUlDQWdJQ0FnZlZ4dUlDQWdJSDFjYmlBZ2ZWeHVYRzRnSUhKbGRIVnliaUJ5WlhNN1hHNTlPMXh1VW1WaFpHRmliR1V1Y0hKdmRHOTBlWEJsTG1Ga1pFeHBjM1JsYm1WeUlEMGdVbVZoWkdGaWJHVXVjSEp2ZEc5MGVYQmxMbTl1TzF4dVhHNHZMeUJ3WVhWelpTZ3BJR0Z1WkNCeVpYTjFiV1VvS1NCaGNtVWdjbVZ0Ym1GdWRITWdiMllnZEdobElHeGxaMkZqZVNCeVpXRmtZV0pzWlNCemRISmxZVzBnUVZCSlhHNHZMeUJKWmlCMGFHVWdkWE5sY2lCMWMyVnpJSFJvWlcwc0lIUm9aVzRnYzNkcGRHTm9JR2x1ZEc4Z2IyeGtJRzF2WkdVdVhHNVNaV0ZrWVdKc1pTNXdjbTkwYjNSNWNHVXVjbVZ6ZFcxbElEMGdablZ1WTNScGIyNG9LU0I3WEc0Z0lIWmhjaUJ6ZEdGMFpTQTlJSFJvYVhNdVgzSmxZV1JoWW14bFUzUmhkR1U3WEc0Z0lHbG1JQ2doYzNSaGRHVXVabXh2ZDJsdVp5a2dlMXh1SUNBZ0lHUmxZblZuS0NkeVpYTjFiV1VuS1R0Y2JpQWdJQ0J6ZEdGMFpTNW1iRzkzYVc1bklEMGdkSEoxWlR0Y2JpQWdJQ0JwWmlBb0lYTjBZWFJsTG5KbFlXUnBibWNwSUh0Y2JpQWdJQ0FnSUdSbFluVm5LQ2R5WlhOMWJXVWdjbVZoWkNBd0p5azdYRzRnSUNBZ0lDQjBhR2x6TG5KbFlXUW9NQ2s3WEc0Z0lDQWdmVnh1SUNBZ0lISmxjM1Z0WlNoMGFHbHpMQ0J6ZEdGMFpTazdYRzRnSUgxY2JpQWdjbVYwZFhKdUlIUm9hWE03WEc1OU8xeHVYRzVtZFc1amRHbHZiaUJ5WlhOMWJXVW9jM1J5WldGdExDQnpkR0YwWlNrZ2UxeHVJQ0JwWmlBb0lYTjBZWFJsTG5KbGMzVnRaVk5qYUdWa2RXeGxaQ2tnZTF4dUlDQWdJSE4wWVhSbExuSmxjM1Z0WlZOamFHVmtkV3hsWkNBOUlIUnlkV1U3WEc0Z0lDQWdjSEp2WTJWemN5NXVaWGgwVkdsamF5aG1kVzVqZEdsdmJpZ3BJSHRjYmlBZ0lDQWdJSEpsYzNWdFpWOG9jM1J5WldGdExDQnpkR0YwWlNrN1hHNGdJQ0FnZlNrN1hHNGdJSDFjYm4xY2JseHVablZ1WTNScGIyNGdjbVZ6ZFcxbFh5aHpkSEpsWVcwc0lITjBZWFJsS1NCN1hHNGdJSE4wWVhSbExuSmxjM1Z0WlZOamFHVmtkV3hsWkNBOUlHWmhiSE5sTzF4dUlDQnpkSEpsWVcwdVpXMXBkQ2duY21WemRXMWxKeWs3WEc0Z0lHWnNiM2NvYzNSeVpXRnRLVHRjYmlBZ2FXWWdLSE4wWVhSbExtWnNiM2RwYm1jZ0ppWWdJWE4wWVhSbExuSmxZV1JwYm1jcFhHNGdJQ0FnYzNSeVpXRnRMbkpsWVdRb01DazdYRzU5WEc1Y2JsSmxZV1JoWW14bExuQnliM1J2ZEhsd1pTNXdZWFZ6WlNBOUlHWjFibU4wYVc5dUtDa2dlMXh1SUNCa1pXSjFaeWduWTJGc2JDQndZWFZ6WlNCbWJHOTNhVzVuUFNWcUp5d2dkR2hwY3k1ZmNtVmhaR0ZpYkdWVGRHRjBaUzVtYkc5M2FXNW5LVHRjYmlBZ2FXWWdLR1poYkhObElDRTlQU0IwYUdsekxsOXlaV0ZrWVdKc1pWTjBZWFJsTG1ac2IzZHBibWNwSUh0Y2JpQWdJQ0JrWldKMVp5Z25jR0YxYzJVbktUdGNiaUFnSUNCMGFHbHpMbDl5WldGa1lXSnNaVk4wWVhSbExtWnNiM2RwYm1jZ1BTQm1ZV3h6WlR0Y2JpQWdJQ0IwYUdsekxtVnRhWFFvSjNCaGRYTmxKeWs3WEc0Z0lIMWNiaUFnY21WMGRYSnVJSFJvYVhNN1hHNTlPMXh1WEc1bWRXNWpkR2x2YmlCbWJHOTNLSE4wY21WaGJTa2dlMXh1SUNCMllYSWdjM1JoZEdVZ1BTQnpkSEpsWVcwdVgzSmxZV1JoWW14bFUzUmhkR1U3WEc0Z0lHUmxZblZuS0NkbWJHOTNKeXdnYzNSaGRHVXVabXh2ZDJsdVp5azdYRzRnSUdsbUlDaHpkR0YwWlM1bWJHOTNhVzVuS1NCN1hHNGdJQ0FnWkc4Z2UxeHVJQ0FnSUNBZ2RtRnlJR05vZFc1cklEMGdjM1J5WldGdExuSmxZV1FvS1R0Y2JpQWdJQ0I5SUhkb2FXeGxJQ2h1ZFd4c0lDRTlQU0JqYUhWdWF5QW1KaUJ6ZEdGMFpTNW1iRzkzYVc1bktUdGNiaUFnZlZ4dWZWeHVYRzR2THlCM2NtRndJR0Z1SUc5c1pDMXpkSGxzWlNCemRISmxZVzBnWVhNZ2RHaGxJR0Z6ZVc1aklHUmhkR0VnYzI5MWNtTmxMbHh1THk4Z1ZHaHBjeUJwY3lBcWJtOTBLaUJ3WVhKMElHOW1JSFJvWlNCeVpXRmtZV0pzWlNCemRISmxZVzBnYVc1MFpYSm1ZV05sTGx4dUx5OGdTWFFnYVhNZ1lXNGdkV2RzZVNCMWJtWnZjblIxYm1GMFpTQnRaWE56SUc5bUlHaHBjM1J2Y25rdVhHNVNaV0ZrWVdKc1pTNXdjbTkwYjNSNWNHVXVkM0poY0NBOUlHWjFibU4wYVc5dUtITjBjbVZoYlNrZ2UxeHVJQ0IyWVhJZ2MzUmhkR1VnUFNCMGFHbHpMbDl5WldGa1lXSnNaVk4wWVhSbE8xeHVJQ0IyWVhJZ2NHRjFjMlZrSUQwZ1ptRnNjMlU3WEc1Y2JpQWdkbUZ5SUhObGJHWWdQU0IwYUdsek8xeHVJQ0J6ZEhKbFlXMHViMjRvSjJWdVpDY3NJR1oxYm1OMGFXOXVLQ2tnZTF4dUlDQWdJR1JsWW5WbktDZDNjbUZ3Y0dWa0lHVnVaQ2NwTzF4dUlDQWdJR2xtSUNoemRHRjBaUzVrWldOdlpHVnlJQ1ltSUNGemRHRjBaUzVsYm1SbFpDa2dlMXh1SUNBZ0lDQWdkbUZ5SUdOb2RXNXJJRDBnYzNSaGRHVXVaR1ZqYjJSbGNpNWxibVFvS1R0Y2JpQWdJQ0FnSUdsbUlDaGphSFZ1YXlBbUppQmphSFZ1YXk1c1pXNW5kR2dwWEc0Z0lDQWdJQ0FnSUhObGJHWXVjSFZ6YUNoamFIVnVheWs3WEc0Z0lDQWdmVnh1WEc0Z0lDQWdjMlZzWmk1d2RYTm9LRzUxYkd3cE8xeHVJQ0I5S1R0Y2JseHVJQ0J6ZEhKbFlXMHViMjRvSjJSaGRHRW5MQ0JtZFc1amRHbHZiaWhqYUhWdWF5a2dlMXh1SUNBZ0lHUmxZblZuS0NkM2NtRndjR1ZrSUdSaGRHRW5LVHRjYmlBZ0lDQnBaaUFvYzNSaGRHVXVaR1ZqYjJSbGNpbGNiaUFnSUNBZ0lHTm9kVzVySUQwZ2MzUmhkR1V1WkdWamIyUmxjaTUzY21sMFpTaGphSFZ1YXlrN1hHNGdJQ0FnYVdZZ0tDRmphSFZ1YXlCOGZDQWhjM1JoZEdVdWIySnFaV04wVFc5a1pTQW1KaUFoWTJoMWJtc3ViR1Z1WjNSb0tWeHVJQ0FnSUNBZ2NtVjBkWEp1TzF4dVhHNGdJQ0FnZG1GeUlISmxkQ0E5SUhObGJHWXVjSFZ6YUNoamFIVnVheWs3WEc0Z0lDQWdhV1lnS0NGeVpYUXBJSHRjYmlBZ0lDQWdJSEJoZFhObFpDQTlJSFJ5ZFdVN1hHNGdJQ0FnSUNCemRISmxZVzB1Y0dGMWMyVW9LVHRjYmlBZ0lDQjlYRzRnSUgwcE8xeHVYRzRnSUM4dklIQnliM2g1SUdGc2JDQjBhR1VnYjNSb1pYSWdiV1YwYUc5a2N5NWNiaUFnTHk4Z2FXMXdiM0owWVc1MElIZG9aVzRnZDNKaGNIQnBibWNnWm1sc2RHVnljeUJoYm1RZ1pIVndiR1Y0WlhNdVhHNGdJR1p2Y2lBb2RtRnlJR2tnYVc0Z2MzUnlaV0Z0S1NCN1hHNGdJQ0FnYVdZZ0tIVjBhV3d1YVhOR2RXNWpkR2x2YmloemRISmxZVzFiYVYwcElDWW1JSFYwYVd3dWFYTlZibVJsWm1sdVpXUW9kR2hwYzF0cFhTa3BJSHRjYmlBZ0lDQWdJSFJvYVhOYmFWMGdQU0JtZFc1amRHbHZiaWh0WlhSb2IyUXBJSHNnY21WMGRYSnVJR1oxYm1OMGFXOXVLQ2tnZTF4dUlDQWdJQ0FnSUNCeVpYUjFjbTRnYzNSeVpXRnRXMjFsZEdodlpGMHVZWEJ3Ykhrb2MzUnlaV0Z0TENCaGNtZDFiV1Z1ZEhNcE8xeHVJQ0FnSUNBZ2ZYMG9hU2s3WEc0Z0lDQWdmVnh1SUNCOVhHNWNiaUFnTHk4Z2NISnZlSGtnWTJWeWRHRnBiaUJwYlhCdmNuUmhiblFnWlhabGJuUnpMbHh1SUNCMllYSWdaWFpsYm5SeklEMGdXeWRsY25KdmNpY3NJQ2RqYkc5elpTY3NJQ2RrWlhOMGNtOTVKeXdnSjNCaGRYTmxKeXdnSjNKbGMzVnRaU2RkTzF4dUlDQm1iM0pGWVdOb0tHVjJaVzUwY3l3Z1puVnVZM1JwYjI0b1pYWXBJSHRjYmlBZ0lDQnpkSEpsWVcwdWIyNG9aWFlzSUhObGJHWXVaVzFwZEM1aWFXNWtLSE5sYkdZc0lHVjJLU2s3WEc0Z0lIMHBPMXh1WEc0Z0lDOHZJSGRvWlc0Z2QyVWdkSEo1SUhSdklHTnZibk4xYldVZ2MyOXRaU0J0YjNKbElHSjVkR1Z6TENCemFXMXdiSGtnZFc1d1lYVnpaU0IwYUdWY2JpQWdMeThnZFc1a1pYSnNlV2x1WnlCemRISmxZVzB1WEc0Z0lITmxiR1l1WDNKbFlXUWdQU0JtZFc1amRHbHZiaWh1S1NCN1hHNGdJQ0FnWkdWaWRXY29KM2R5WVhCd1pXUWdYM0psWVdRbkxDQnVLVHRjYmlBZ0lDQnBaaUFvY0dGMWMyVmtLU0I3WEc0Z0lDQWdJQ0J3WVhWelpXUWdQU0JtWVd4elpUdGNiaUFnSUNBZ0lITjBjbVZoYlM1eVpYTjFiV1VvS1R0Y2JpQWdJQ0I5WEc0Z0lIMDdYRzVjYmlBZ2NtVjBkWEp1SUhObGJHWTdYRzU5TzF4dVhHNWNibHh1THk4Z1pYaHdiM05sWkNCbWIzSWdkR1Z6ZEdsdVp5QndkWEp3YjNObGN5QnZibXg1TGx4dVVtVmhaR0ZpYkdVdVgyWnliMjFNYVhOMElEMGdabkp2YlV4cGMzUTdYRzVjYmk4dklGQnNkV05ySUc5bVppQnVJR0o1ZEdWeklHWnliMjBnWVc0Z1lYSnlZWGtnYjJZZ1luVm1abVZ5Y3k1Y2JpOHZJRXhsYm1kMGFDQnBjeUIwYUdVZ1kyOXRZbWx1WldRZ2JHVnVaM1JvY3lCdlppQmhiR3dnZEdobElHSjFabVpsY25NZ2FXNGdkR2hsSUd4cGMzUXVYRzVtZFc1amRHbHZiaUJtY205dFRHbHpkQ2h1TENCemRHRjBaU2tnZTF4dUlDQjJZWElnYkdsemRDQTlJSE4wWVhSbExtSjFabVpsY2p0Y2JpQWdkbUZ5SUd4bGJtZDBhQ0E5SUhOMFlYUmxMbXhsYm1kMGFEdGNiaUFnZG1GeUlITjBjbWx1WjAxdlpHVWdQU0FoSVhOMFlYUmxMbVJsWTI5a1pYSTdYRzRnSUhaaGNpQnZZbXBsWTNSTmIyUmxJRDBnSVNGemRHRjBaUzV2WW1wbFkzUk5iMlJsTzF4dUlDQjJZWElnY21WME8xeHVYRzRnSUM4dklHNXZkR2hwYm1jZ2FXNGdkR2hsSUd4cGMzUXNJR1JsWm1sdWFYUmxiSGtnWlcxd2RIa3VYRzRnSUdsbUlDaHNhWE4wTG14bGJtZDBhQ0E5UFQwZ01DbGNiaUFnSUNCeVpYUjFjbTRnYm5Wc2JEdGNibHh1SUNCcFppQW9iR1Z1WjNSb0lEMDlQU0F3S1Z4dUlDQWdJSEpsZENBOUlHNTFiR3c3WEc0Z0lHVnNjMlVnYVdZZ0tHOWlhbVZqZEUxdlpHVXBYRzRnSUNBZ2NtVjBJRDBnYkdsemRDNXphR2xtZENncE8xeHVJQ0JsYkhObElHbG1JQ2doYmlCOGZDQnVJRDQ5SUd4bGJtZDBhQ2tnZTF4dUlDQWdJQzh2SUhKbFlXUWdhWFFnWVd4c0xDQjBjblZ1WTJGMFpTQjBhR1VnWVhKeVlYa3VYRzRnSUNBZ2FXWWdLSE4wY21sdVowMXZaR1VwWEc0Z0lDQWdJQ0J5WlhRZ1BTQnNhWE4wTG1wdmFXNG9KeWNwTzF4dUlDQWdJR1ZzYzJWY2JpQWdJQ0FnSUhKbGRDQTlJRUoxWm1abGNpNWpiMjVqWVhRb2JHbHpkQ3dnYkdWdVozUm9LVHRjYmlBZ0lDQnNhWE4wTG14bGJtZDBhQ0E5SURBN1hHNGdJSDBnWld4elpTQjdYRzRnSUNBZ0x5OGdjbVZoWkNCcWRYTjBJSE52YldVZ2IyWWdhWFF1WEc0Z0lDQWdhV1lnS0c0Z1BDQnNhWE4wV3pCZExteGxibWQwYUNrZ2UxeHVJQ0FnSUNBZ0x5OGdhblZ6ZENCMFlXdGxJR0VnY0dGeWRDQnZaaUIwYUdVZ1ptbHljM1FnYkdsemRDQnBkR1Z0TGx4dUlDQWdJQ0FnTHk4Z2MyeHBZMlVnYVhNZ2RHaGxJSE5oYldVZ1ptOXlJR0oxWm1abGNuTWdZVzVrSUhOMGNtbHVaM011WEc0Z0lDQWdJQ0IyWVhJZ1luVm1JRDBnYkdsemRGc3dYVHRjYmlBZ0lDQWdJSEpsZENBOUlHSjFaaTV6YkdsalpTZ3dMQ0J1S1R0Y2JpQWdJQ0FnSUd4cGMzUmJNRjBnUFNCaWRXWXVjMnhwWTJVb2JpazdYRzRnSUNBZ2ZTQmxiSE5sSUdsbUlDaHVJRDA5UFNCc2FYTjBXekJkTG14bGJtZDBhQ2tnZTF4dUlDQWdJQ0FnTHk4Z1ptbHljM1FnYkdsemRDQnBjeUJoSUhCbGNtWmxZM1FnYldGMFkyaGNiaUFnSUNBZ0lISmxkQ0E5SUd4cGMzUXVjMmhwWm5Rb0tUdGNiaUFnSUNCOUlHVnNjMlVnZTF4dUlDQWdJQ0FnTHk4Z1kyOXRjR3hsZUNCallYTmxMbHh1SUNBZ0lDQWdMeThnZDJVZ2FHRjJaU0JsYm05MVoyZ2dkRzhnWTI5MlpYSWdhWFFzSUdKMWRDQnBkQ0J6Y0dGdWN5QndZWE4wSUhSb1pTQm1hWEp6ZENCaWRXWm1aWEl1WEc0Z0lDQWdJQ0JwWmlBb2MzUnlhVzVuVFc5a1pTbGNiaUFnSUNBZ0lDQWdjbVYwSUQwZ0p5YzdYRzRnSUNBZ0lDQmxiSE5sWEc0Z0lDQWdJQ0FnSUhKbGRDQTlJRzVsZHlCQ2RXWm1aWElvYmlrN1hHNWNiaUFnSUNBZ0lIWmhjaUJqSUQwZ01EdGNiaUFnSUNBZ0lHWnZjaUFvZG1GeUlHa2dQU0F3TENCc0lEMGdiR2x6ZEM1c1pXNW5kR2c3SUdrZ1BDQnNJQ1ltSUdNZ1BDQnVPeUJwS3lzcElIdGNiaUFnSUNBZ0lDQWdkbUZ5SUdKMVppQTlJR3hwYzNSYk1GMDdYRzRnSUNBZ0lDQWdJSFpoY2lCamNIa2dQU0JOWVhSb0xtMXBiaWh1SUMwZ1l5d2dZblZtTG14bGJtZDBhQ2s3WEc1Y2JpQWdJQ0FnSUNBZ2FXWWdLSE4wY21sdVowMXZaR1VwWEc0Z0lDQWdJQ0FnSUNBZ2NtVjBJQ3M5SUdKMVppNXpiR2xqWlNnd0xDQmpjSGtwTzF4dUlDQWdJQ0FnSUNCbGJITmxYRzRnSUNBZ0lDQWdJQ0FnWW5WbUxtTnZjSGtvY21WMExDQmpMQ0F3TENCamNIa3BPMXh1WEc0Z0lDQWdJQ0FnSUdsbUlDaGpjSGtnUENCaWRXWXViR1Z1WjNSb0tWeHVJQ0FnSUNBZ0lDQWdJR3hwYzNSYk1GMGdQU0JpZFdZdWMyeHBZMlVvWTNCNUtUdGNiaUFnSUNBZ0lDQWdaV3h6WlZ4dUlDQWdJQ0FnSUNBZ0lHeHBjM1F1YzJocFpuUW9LVHRjYmx4dUlDQWdJQ0FnSUNCaklDczlJR053ZVR0Y2JpQWdJQ0FnSUgxY2JpQWdJQ0I5WEc0Z0lIMWNibHh1SUNCeVpYUjFjbTRnY21WME8xeHVmVnh1WEc1bWRXNWpkR2x2YmlCbGJtUlNaV0ZrWVdKc1pTaHpkSEpsWVcwcElIdGNiaUFnZG1GeUlITjBZWFJsSUQwZ2MzUnlaV0Z0TGw5eVpXRmtZV0pzWlZOMFlYUmxPMXh1WEc0Z0lDOHZJRWxtSUhkbElHZGxkQ0JvWlhKbElHSmxabTl5WlNCamIyNXpkVzFwYm1jZ1lXeHNJSFJvWlNCaWVYUmxjeXdnZEdobGJpQjBhR0YwSUdseklHRmNiaUFnTHk4Z1luVm5JR2x1SUc1dlpHVXVJQ0JUYUc5MWJHUWdibVYyWlhJZ2FHRndjR1Z1TGx4dUlDQnBaaUFvYzNSaGRHVXViR1Z1WjNSb0lENGdNQ2xjYmlBZ0lDQjBhSEp2ZHlCdVpYY2dSWEp5YjNJb0oyVnVaRkpsWVdSaFlteGxJR05oYkd4bFpDQnZiaUJ1YjI0dFpXMXdkSGtnYzNSeVpXRnRKeWs3WEc1Y2JpQWdhV1lnS0NGemRHRjBaUzVsYm1SRmJXbDBkR1ZrS1NCN1hHNGdJQ0FnYzNSaGRHVXVaVzVrWldRZ1BTQjBjblZsTzF4dUlDQWdJSEJ5YjJObGMzTXVibVY0ZEZScFkyc29ablZ1WTNScGIyNG9LU0I3WEc0Z0lDQWdJQ0F2THlCRGFHVmpheUIwYUdGMElIZGxJR1JwWkc0bmRDQm5aWFFnYjI1bElHeGhjM1FnZFc1emFHbG1kQzVjYmlBZ0lDQWdJR2xtSUNnaGMzUmhkR1V1Wlc1a1JXMXBkSFJsWkNBbUppQnpkR0YwWlM1c1pXNW5kR2dnUFQwOUlEQXBJSHRjYmlBZ0lDQWdJQ0FnYzNSaGRHVXVaVzVrUlcxcGRIUmxaQ0E5SUhSeWRXVTdYRzRnSUNBZ0lDQWdJSE4wY21WaGJTNXlaV0ZrWVdKc1pTQTlJR1poYkhObE8xeHVJQ0FnSUNBZ0lDQnpkSEpsWVcwdVpXMXBkQ2duWlc1a0p5azdYRzRnSUNBZ0lDQjlYRzRnSUNBZ2ZTazdYRzRnSUgxY2JuMWNibHh1Wm5WdVkzUnBiMjRnWm05eVJXRmphQ0FvZUhNc0lHWXBJSHRjYmlBZ1ptOXlJQ2gyWVhJZ2FTQTlJREFzSUd3Z1BTQjRjeTVzWlc1bmRHZzdJR2tnUENCc095QnBLeXNwSUh0Y2JpQWdJQ0JtS0hoelcybGRMQ0JwS1R0Y2JpQWdmVnh1ZlZ4dVhHNW1kVzVqZEdsdmJpQnBibVJsZUU5bUlDaDRjeXdnZUNrZ2UxeHVJQ0JtYjNJZ0tIWmhjaUJwSUQwZ01Dd2diQ0E5SUhoekxteGxibWQwYURzZ2FTQThJR3c3SUdrckt5a2dlMXh1SUNBZ0lHbG1JQ2g0YzF0cFhTQTlQVDBnZUNrZ2NtVjBkWEp1SUdrN1hHNGdJSDFjYmlBZ2NtVjBkWEp1SUMweE8xeHVmVnh1SWwxOSIsIi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG5cbi8vIGEgdHJhbnNmb3JtIHN0cmVhbSBpcyBhIHJlYWRhYmxlL3dyaXRhYmxlIHN0cmVhbSB3aGVyZSB5b3UgZG9cbi8vIHNvbWV0aGluZyB3aXRoIHRoZSBkYXRhLiAgU29tZXRpbWVzIGl0J3MgY2FsbGVkIGEgXCJmaWx0ZXJcIixcbi8vIGJ1dCB0aGF0J3Mgbm90IGEgZ3JlYXQgbmFtZSBmb3IgaXQsIHNpbmNlIHRoYXQgaW1wbGllcyBhIHRoaW5nIHdoZXJlXG4vLyBzb21lIGJpdHMgcGFzcyB0aHJvdWdoLCBhbmQgb3RoZXJzIGFyZSBzaW1wbHkgaWdub3JlZC4gIChUaGF0IHdvdWxkXG4vLyBiZSBhIHZhbGlkIGV4YW1wbGUgb2YgYSB0cmFuc2Zvcm0sIG9mIGNvdXJzZS4pXG4vL1xuLy8gV2hpbGUgdGhlIG91dHB1dCBpcyBjYXVzYWxseSByZWxhdGVkIHRvIHRoZSBpbnB1dCwgaXQncyBub3QgYVxuLy8gbmVjZXNzYXJpbHkgc3ltbWV0cmljIG9yIHN5bmNocm9ub3VzIHRyYW5zZm9ybWF0aW9uLiAgRm9yIGV4YW1wbGUsXG4vLyBhIHpsaWIgc3RyZWFtIG1pZ2h0IHRha2UgbXVsdGlwbGUgcGxhaW4tdGV4dCB3cml0ZXMoKSwgYW5kIHRoZW5cbi8vIGVtaXQgYSBzaW5nbGUgY29tcHJlc3NlZCBjaHVuayBzb21lIHRpbWUgaW4gdGhlIGZ1dHVyZS5cbi8vXG4vLyBIZXJlJ3MgaG93IHRoaXMgd29ya3M6XG4vL1xuLy8gVGhlIFRyYW5zZm9ybSBzdHJlYW0gaGFzIGFsbCB0aGUgYXNwZWN0cyBvZiB0aGUgcmVhZGFibGUgYW5kIHdyaXRhYmxlXG4vLyBzdHJlYW0gY2xhc3Nlcy4gIFdoZW4geW91IHdyaXRlKGNodW5rKSwgdGhhdCBjYWxscyBfd3JpdGUoY2h1bmssY2IpXG4vLyBpbnRlcm5hbGx5LCBhbmQgcmV0dXJucyBmYWxzZSBpZiB0aGVyZSdzIGEgbG90IG9mIHBlbmRpbmcgd3JpdGVzXG4vLyBidWZmZXJlZCB1cC4gIFdoZW4geW91IGNhbGwgcmVhZCgpLCB0aGF0IGNhbGxzIF9yZWFkKG4pIHVudGlsXG4vLyB0aGVyZSdzIGVub3VnaCBwZW5kaW5nIHJlYWRhYmxlIGRhdGEgYnVmZmVyZWQgdXAuXG4vL1xuLy8gSW4gYSB0cmFuc2Zvcm0gc3RyZWFtLCB0aGUgd3JpdHRlbiBkYXRhIGlzIHBsYWNlZCBpbiBhIGJ1ZmZlci4gIFdoZW5cbi8vIF9yZWFkKG4pIGlzIGNhbGxlZCwgaXQgdHJhbnNmb3JtcyB0aGUgcXVldWVkIHVwIGRhdGEsIGNhbGxpbmcgdGhlXG4vLyBidWZmZXJlZCBfd3JpdGUgY2IncyBhcyBpdCBjb25zdW1lcyBjaHVua3MuICBJZiBjb25zdW1pbmcgYSBzaW5nbGVcbi8vIHdyaXR0ZW4gY2h1bmsgd291bGQgcmVzdWx0IGluIG11bHRpcGxlIG91dHB1dCBjaHVua3MsIHRoZW4gdGhlIGZpcnN0XG4vLyBvdXRwdXR0ZWQgYml0IGNhbGxzIHRoZSByZWFkY2IsIGFuZCBzdWJzZXF1ZW50IGNodW5rcyBqdXN0IGdvIGludG9cbi8vIHRoZSByZWFkIGJ1ZmZlciwgYW5kIHdpbGwgY2F1c2UgaXQgdG8gZW1pdCAncmVhZGFibGUnIGlmIG5lY2Vzc2FyeS5cbi8vXG4vLyBUaGlzIHdheSwgYmFjay1wcmVzc3VyZSBpcyBhY3R1YWxseSBkZXRlcm1pbmVkIGJ5IHRoZSByZWFkaW5nIHNpZGUsXG4vLyBzaW5jZSBfcmVhZCBoYXMgdG8gYmUgY2FsbGVkIHRvIHN0YXJ0IHByb2Nlc3NpbmcgYSBuZXcgY2h1bmsuICBIb3dldmVyLFxuLy8gYSBwYXRob2xvZ2ljYWwgaW5mbGF0ZSB0eXBlIG9mIHRyYW5zZm9ybSBjYW4gY2F1c2UgZXhjZXNzaXZlIGJ1ZmZlcmluZ1xuLy8gaGVyZS4gIEZvciBleGFtcGxlLCBpbWFnaW5lIGEgc3RyZWFtIHdoZXJlIGV2ZXJ5IGJ5dGUgb2YgaW5wdXQgaXNcbi8vIGludGVycHJldGVkIGFzIGFuIGludGVnZXIgZnJvbSAwLTI1NSwgYW5kIHRoZW4gcmVzdWx0cyBpbiB0aGF0IG1hbnlcbi8vIGJ5dGVzIG9mIG91dHB1dC4gIFdyaXRpbmcgdGhlIDQgYnl0ZXMge2ZmLGZmLGZmLGZmfSB3b3VsZCByZXN1bHQgaW5cbi8vIDFrYiBvZiBkYXRhIGJlaW5nIG91dHB1dC4gIEluIHRoaXMgY2FzZSwgeW91IGNvdWxkIHdyaXRlIGEgdmVyeSBzbWFsbFxuLy8gYW1vdW50IG9mIGlucHV0LCBhbmQgZW5kIHVwIHdpdGggYSB2ZXJ5IGxhcmdlIGFtb3VudCBvZiBvdXRwdXQuICBJblxuLy8gc3VjaCBhIHBhdGhvbG9naWNhbCBpbmZsYXRpbmcgbWVjaGFuaXNtLCB0aGVyZSdkIGJlIG5vIHdheSB0byB0ZWxsXG4vLyB0aGUgc3lzdGVtIHRvIHN0b3AgZG9pbmcgdGhlIHRyYW5zZm9ybS4gIEEgc2luZ2xlIDRNQiB3cml0ZSBjb3VsZFxuLy8gY2F1c2UgdGhlIHN5c3RlbSB0byBydW4gb3V0IG9mIG1lbW9yeS5cbi8vXG4vLyBIb3dldmVyLCBldmVuIGluIHN1Y2ggYSBwYXRob2xvZ2ljYWwgY2FzZSwgb25seSBhIHNpbmdsZSB3cml0dGVuIGNodW5rXG4vLyB3b3VsZCBiZSBjb25zdW1lZCwgYW5kIHRoZW4gdGhlIHJlc3Qgd291bGQgd2FpdCAodW4tdHJhbnNmb3JtZWQpIHVudGlsXG4vLyB0aGUgcmVzdWx0cyBvZiB0aGUgcHJldmlvdXMgdHJhbnNmb3JtZWQgY2h1bmsgd2VyZSBjb25zdW1lZC5cblxubW9kdWxlLmV4cG9ydHMgPSBUcmFuc2Zvcm07XG5cbnZhciBEdXBsZXggPSByZXF1aXJlKCcuL19zdHJlYW1fZHVwbGV4Jyk7XG5cbi8qPHJlcGxhY2VtZW50PiovXG52YXIgdXRpbCA9IHJlcXVpcmUoJ2NvcmUtdXRpbC1pcycpO1xudXRpbC5pbmhlcml0cyA9IHJlcXVpcmUoJ2luaGVyaXRzJyk7XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxudXRpbC5pbmhlcml0cyhUcmFuc2Zvcm0sIER1cGxleCk7XG5cblxuZnVuY3Rpb24gVHJhbnNmb3JtU3RhdGUob3B0aW9ucywgc3RyZWFtKSB7XG4gIHRoaXMuYWZ0ZXJUcmFuc2Zvcm0gPSBmdW5jdGlvbihlciwgZGF0YSkge1xuICAgIHJldHVybiBhZnRlclRyYW5zZm9ybShzdHJlYW0sIGVyLCBkYXRhKTtcbiAgfTtcblxuICB0aGlzLm5lZWRUcmFuc2Zvcm0gPSBmYWxzZTtcbiAgdGhpcy50cmFuc2Zvcm1pbmcgPSBmYWxzZTtcbiAgdGhpcy53cml0ZWNiID0gbnVsbDtcbiAgdGhpcy53cml0ZWNodW5rID0gbnVsbDtcbn1cblxuZnVuY3Rpb24gYWZ0ZXJUcmFuc2Zvcm0oc3RyZWFtLCBlciwgZGF0YSkge1xuICB2YXIgdHMgPSBzdHJlYW0uX3RyYW5zZm9ybVN0YXRlO1xuICB0cy50cmFuc2Zvcm1pbmcgPSBmYWxzZTtcblxuICB2YXIgY2IgPSB0cy53cml0ZWNiO1xuXG4gIGlmICghY2IpXG4gICAgcmV0dXJuIHN0cmVhbS5lbWl0KCdlcnJvcicsIG5ldyBFcnJvcignbm8gd3JpdGVjYiBpbiBUcmFuc2Zvcm0gY2xhc3MnKSk7XG5cbiAgdHMud3JpdGVjaHVuayA9IG51bGw7XG4gIHRzLndyaXRlY2IgPSBudWxsO1xuXG4gIGlmICghdXRpbC5pc051bGxPclVuZGVmaW5lZChkYXRhKSlcbiAgICBzdHJlYW0ucHVzaChkYXRhKTtcblxuICBpZiAoY2IpXG4gICAgY2IoZXIpO1xuXG4gIHZhciBycyA9IHN0cmVhbS5fcmVhZGFibGVTdGF0ZTtcbiAgcnMucmVhZGluZyA9IGZhbHNlO1xuICBpZiAocnMubmVlZFJlYWRhYmxlIHx8IHJzLmxlbmd0aCA8IHJzLmhpZ2hXYXRlck1hcmspIHtcbiAgICBzdHJlYW0uX3JlYWQocnMuaGlnaFdhdGVyTWFyayk7XG4gIH1cbn1cblxuXG5mdW5jdGlvbiBUcmFuc2Zvcm0ob3B0aW9ucykge1xuICBpZiAoISh0aGlzIGluc3RhbmNlb2YgVHJhbnNmb3JtKSlcbiAgICByZXR1cm4gbmV3IFRyYW5zZm9ybShvcHRpb25zKTtcblxuICBEdXBsZXguY2FsbCh0aGlzLCBvcHRpb25zKTtcblxuICB0aGlzLl90cmFuc2Zvcm1TdGF0ZSA9IG5ldyBUcmFuc2Zvcm1TdGF0ZShvcHRpb25zLCB0aGlzKTtcblxuICAvLyB3aGVuIHRoZSB3cml0YWJsZSBzaWRlIGZpbmlzaGVzLCB0aGVuIGZsdXNoIG91dCBhbnl0aGluZyByZW1haW5pbmcuXG4gIHZhciBzdHJlYW0gPSB0aGlzO1xuXG4gIC8vIHN0YXJ0IG91dCBhc2tpbmcgZm9yIGEgcmVhZGFibGUgZXZlbnQgb25jZSBkYXRhIGlzIHRyYW5zZm9ybWVkLlxuICB0aGlzLl9yZWFkYWJsZVN0YXRlLm5lZWRSZWFkYWJsZSA9IHRydWU7XG5cbiAgLy8gd2UgaGF2ZSBpbXBsZW1lbnRlZCB0aGUgX3JlYWQgbWV0aG9kLCBhbmQgZG9uZSB0aGUgb3RoZXIgdGhpbmdzXG4gIC8vIHRoYXQgUmVhZGFibGUgd2FudHMgYmVmb3JlIHRoZSBmaXJzdCBfcmVhZCBjYWxsLCBzbyB1bnNldCB0aGVcbiAgLy8gc3luYyBndWFyZCBmbGFnLlxuICB0aGlzLl9yZWFkYWJsZVN0YXRlLnN5bmMgPSBmYWxzZTtcblxuICB0aGlzLm9uY2UoJ3ByZWZpbmlzaCcsIGZ1bmN0aW9uKCkge1xuICAgIGlmICh1dGlsLmlzRnVuY3Rpb24odGhpcy5fZmx1c2gpKVxuICAgICAgdGhpcy5fZmx1c2goZnVuY3Rpb24oZXIpIHtcbiAgICAgICAgZG9uZShzdHJlYW0sIGVyKTtcbiAgICAgIH0pO1xuICAgIGVsc2VcbiAgICAgIGRvbmUoc3RyZWFtKTtcbiAgfSk7XG59XG5cblRyYW5zZm9ybS5wcm90b3R5cGUucHVzaCA9IGZ1bmN0aW9uKGNodW5rLCBlbmNvZGluZykge1xuICB0aGlzLl90cmFuc2Zvcm1TdGF0ZS5uZWVkVHJhbnNmb3JtID0gZmFsc2U7XG4gIHJldHVybiBEdXBsZXgucHJvdG90eXBlLnB1c2guY2FsbCh0aGlzLCBjaHVuaywgZW5jb2RpbmcpO1xufTtcblxuLy8gVGhpcyBpcyB0aGUgcGFydCB3aGVyZSB5b3UgZG8gc3R1ZmYhXG4vLyBvdmVycmlkZSB0aGlzIGZ1bmN0aW9uIGluIGltcGxlbWVudGF0aW9uIGNsYXNzZXMuXG4vLyAnY2h1bmsnIGlzIGFuIGlucHV0IGNodW5rLlxuLy9cbi8vIENhbGwgYHB1c2gobmV3Q2h1bmspYCB0byBwYXNzIGFsb25nIHRyYW5zZm9ybWVkIG91dHB1dFxuLy8gdG8gdGhlIHJlYWRhYmxlIHNpZGUuICBZb3UgbWF5IGNhbGwgJ3B1c2gnIHplcm8gb3IgbW9yZSB0aW1lcy5cbi8vXG4vLyBDYWxsIGBjYihlcnIpYCB3aGVuIHlvdSBhcmUgZG9uZSB3aXRoIHRoaXMgY2h1bmsuICBJZiB5b3UgcGFzc1xuLy8gYW4gZXJyb3IsIHRoZW4gdGhhdCdsbCBwdXQgdGhlIGh1cnQgb24gdGhlIHdob2xlIG9wZXJhdGlvbi4gIElmIHlvdVxuLy8gbmV2ZXIgY2FsbCBjYigpLCB0aGVuIHlvdSdsbCBuZXZlciBnZXQgYW5vdGhlciBjaHVuay5cblRyYW5zZm9ybS5wcm90b3R5cGUuX3RyYW5zZm9ybSA9IGZ1bmN0aW9uKGNodW5rLCBlbmNvZGluZywgY2IpIHtcbiAgdGhyb3cgbmV3IEVycm9yKCdub3QgaW1wbGVtZW50ZWQnKTtcbn07XG5cblRyYW5zZm9ybS5wcm90b3R5cGUuX3dyaXRlID0gZnVuY3Rpb24oY2h1bmssIGVuY29kaW5nLCBjYikge1xuICB2YXIgdHMgPSB0aGlzLl90cmFuc2Zvcm1TdGF0ZTtcbiAgdHMud3JpdGVjYiA9IGNiO1xuICB0cy53cml0ZWNodW5rID0gY2h1bms7XG4gIHRzLndyaXRlZW5jb2RpbmcgPSBlbmNvZGluZztcbiAgaWYgKCF0cy50cmFuc2Zvcm1pbmcpIHtcbiAgICB2YXIgcnMgPSB0aGlzLl9yZWFkYWJsZVN0YXRlO1xuICAgIGlmICh0cy5uZWVkVHJhbnNmb3JtIHx8XG4gICAgICAgIHJzLm5lZWRSZWFkYWJsZSB8fFxuICAgICAgICBycy5sZW5ndGggPCBycy5oaWdoV2F0ZXJNYXJrKVxuICAgICAgdGhpcy5fcmVhZChycy5oaWdoV2F0ZXJNYXJrKTtcbiAgfVxufTtcblxuLy8gRG9lc24ndCBtYXR0ZXIgd2hhdCB0aGUgYXJncyBhcmUgaGVyZS5cbi8vIF90cmFuc2Zvcm0gZG9lcyBhbGwgdGhlIHdvcmsuXG4vLyBUaGF0IHdlIGdvdCBoZXJlIG1lYW5zIHRoYXQgdGhlIHJlYWRhYmxlIHNpZGUgd2FudHMgbW9yZSBkYXRhLlxuVHJhbnNmb3JtLnByb3RvdHlwZS5fcmVhZCA9IGZ1bmN0aW9uKG4pIHtcbiAgdmFyIHRzID0gdGhpcy5fdHJhbnNmb3JtU3RhdGU7XG5cbiAgaWYgKCF1dGlsLmlzTnVsbCh0cy53cml0ZWNodW5rKSAmJiB0cy53cml0ZWNiICYmICF0cy50cmFuc2Zvcm1pbmcpIHtcbiAgICB0cy50cmFuc2Zvcm1pbmcgPSB0cnVlO1xuICAgIHRoaXMuX3RyYW5zZm9ybSh0cy53cml0ZWNodW5rLCB0cy53cml0ZWVuY29kaW5nLCB0cy5hZnRlclRyYW5zZm9ybSk7XG4gIH0gZWxzZSB7XG4gICAgLy8gbWFyayB0aGF0IHdlIG5lZWQgYSB0cmFuc2Zvcm0sIHNvIHRoYXQgYW55IGRhdGEgdGhhdCBjb21lcyBpblxuICAgIC8vIHdpbGwgZ2V0IHByb2Nlc3NlZCwgbm93IHRoYXQgd2UndmUgYXNrZWQgZm9yIGl0LlxuICAgIHRzLm5lZWRUcmFuc2Zvcm0gPSB0cnVlO1xuICB9XG59O1xuXG5cbmZ1bmN0aW9uIGRvbmUoc3RyZWFtLCBlcikge1xuICBpZiAoZXIpXG4gICAgcmV0dXJuIHN0cmVhbS5lbWl0KCdlcnJvcicsIGVyKTtcblxuICAvLyBpZiB0aGVyZSdzIG5vdGhpbmcgaW4gdGhlIHdyaXRlIGJ1ZmZlciwgdGhlbiB0aGF0IG1lYW5zXG4gIC8vIHRoYXQgbm90aGluZyBtb3JlIHdpbGwgZXZlciBiZSBwcm92aWRlZFxuICB2YXIgd3MgPSBzdHJlYW0uX3dyaXRhYmxlU3RhdGU7XG4gIHZhciB0cyA9IHN0cmVhbS5fdHJhbnNmb3JtU3RhdGU7XG5cbiAgaWYgKHdzLmxlbmd0aClcbiAgICB0aHJvdyBuZXcgRXJyb3IoJ2NhbGxpbmcgdHJhbnNmb3JtIGRvbmUgd2hlbiB3cy5sZW5ndGggIT0gMCcpO1xuXG4gIGlmICh0cy50cmFuc2Zvcm1pbmcpXG4gICAgdGhyb3cgbmV3IEVycm9yKCdjYWxsaW5nIHRyYW5zZm9ybSBkb25lIHdoZW4gc3RpbGwgdHJhbnNmb3JtaW5nJyk7XG5cbiAgcmV0dXJuIHN0cmVhbS5wdXNoKG51bGwpO1xufVxuIiwiKGZ1bmN0aW9uIChwcm9jZXNzKXtcbi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG4vLyBBIGJpdCBzaW1wbGVyIHRoYW4gcmVhZGFibGUgc3RyZWFtcy5cbi8vIEltcGxlbWVudCBhbiBhc3luYyAuX3dyaXRlKGNodW5rLCBjYiksIGFuZCBpdCdsbCBoYW5kbGUgYWxsXG4vLyB0aGUgZHJhaW4gZXZlbnQgZW1pc3Npb24gYW5kIGJ1ZmZlcmluZy5cblxubW9kdWxlLmV4cG9ydHMgPSBXcml0YWJsZTtcblxuLyo8cmVwbGFjZW1lbnQ+Ki9cbnZhciBCdWZmZXIgPSByZXF1aXJlKCdidWZmZXInKS5CdWZmZXI7XG4vKjwvcmVwbGFjZW1lbnQ+Ki9cblxuV3JpdGFibGUuV3JpdGFibGVTdGF0ZSA9IFdyaXRhYmxlU3RhdGU7XG5cblxuLyo8cmVwbGFjZW1lbnQ+Ki9cbnZhciB1dGlsID0gcmVxdWlyZSgnY29yZS11dGlsLWlzJyk7XG51dGlsLmluaGVyaXRzID0gcmVxdWlyZSgnaW5oZXJpdHMnKTtcbi8qPC9yZXBsYWNlbWVudD4qL1xuXG52YXIgU3RyZWFtID0gcmVxdWlyZSgnc3RyZWFtJyk7XG5cbnV0aWwuaW5oZXJpdHMoV3JpdGFibGUsIFN0cmVhbSk7XG5cbmZ1bmN0aW9uIFdyaXRlUmVxKGNodW5rLCBlbmNvZGluZywgY2IpIHtcbiAgdGhpcy5jaHVuayA9IGNodW5rO1xuICB0aGlzLmVuY29kaW5nID0gZW5jb2Rpbmc7XG4gIHRoaXMuY2FsbGJhY2sgPSBjYjtcbn1cblxuZnVuY3Rpb24gV3JpdGFibGVTdGF0ZShvcHRpb25zLCBzdHJlYW0pIHtcbiAgdmFyIER1cGxleCA9IHJlcXVpcmUoJy4vX3N0cmVhbV9kdXBsZXgnKTtcblxuICBvcHRpb25zID0gb3B0aW9ucyB8fCB7fTtcblxuICAvLyB0aGUgcG9pbnQgYXQgd2hpY2ggd3JpdGUoKSBzdGFydHMgcmV0dXJuaW5nIGZhbHNlXG4gIC8vIE5vdGU6IDAgaXMgYSB2YWxpZCB2YWx1ZSwgbWVhbnMgdGhhdCB3ZSBhbHdheXMgcmV0dXJuIGZhbHNlIGlmXG4gIC8vIHRoZSBlbnRpcmUgYnVmZmVyIGlzIG5vdCBmbHVzaGVkIGltbWVkaWF0ZWx5IG9uIHdyaXRlKClcbiAgdmFyIGh3bSA9IG9wdGlvbnMuaGlnaFdhdGVyTWFyaztcbiAgdmFyIGRlZmF1bHRId20gPSBvcHRpb25zLm9iamVjdE1vZGUgPyAxNiA6IDE2ICogMTAyNDtcbiAgdGhpcy5oaWdoV2F0ZXJNYXJrID0gKGh3bSB8fCBod20gPT09IDApID8gaHdtIDogZGVmYXVsdEh3bTtcblxuICAvLyBvYmplY3Qgc3RyZWFtIGZsYWcgdG8gaW5kaWNhdGUgd2hldGhlciBvciBub3QgdGhpcyBzdHJlYW1cbiAgLy8gY29udGFpbnMgYnVmZmVycyBvciBvYmplY3RzLlxuICB0aGlzLm9iamVjdE1vZGUgPSAhIW9wdGlvbnMub2JqZWN0TW9kZTtcblxuICBpZiAoc3RyZWFtIGluc3RhbmNlb2YgRHVwbGV4KVxuICAgIHRoaXMub2JqZWN0TW9kZSA9IHRoaXMub2JqZWN0TW9kZSB8fCAhIW9wdGlvbnMud3JpdGFibGVPYmplY3RNb2RlO1xuXG4gIC8vIGNhc3QgdG8gaW50cy5cbiAgdGhpcy5oaWdoV2F0ZXJNYXJrID0gfn50aGlzLmhpZ2hXYXRlck1hcms7XG5cbiAgdGhpcy5uZWVkRHJhaW4gPSBmYWxzZTtcbiAgLy8gYXQgdGhlIHN0YXJ0IG9mIGNhbGxpbmcgZW5kKClcbiAgdGhpcy5lbmRpbmcgPSBmYWxzZTtcbiAgLy8gd2hlbiBlbmQoKSBoYXMgYmVlbiBjYWxsZWQsIGFuZCByZXR1cm5lZFxuICB0aGlzLmVuZGVkID0gZmFsc2U7XG4gIC8vIHdoZW4gJ2ZpbmlzaCcgaXMgZW1pdHRlZFxuICB0aGlzLmZpbmlzaGVkID0gZmFsc2U7XG5cbiAgLy8gc2hvdWxkIHdlIGRlY29kZSBzdHJpbmdzIGludG8gYnVmZmVycyBiZWZvcmUgcGFzc2luZyB0byBfd3JpdGU/XG4gIC8vIHRoaXMgaXMgaGVyZSBzbyB0aGF0IHNvbWUgbm9kZS1jb3JlIHN0cmVhbXMgY2FuIG9wdGltaXplIHN0cmluZ1xuICAvLyBoYW5kbGluZyBhdCBhIGxvd2VyIGxldmVsLlxuICB2YXIgbm9EZWNvZGUgPSBvcHRpb25zLmRlY29kZVN0cmluZ3MgPT09IGZhbHNlO1xuICB0aGlzLmRlY29kZVN0cmluZ3MgPSAhbm9EZWNvZGU7XG5cbiAgLy8gQ3J5cHRvIGlzIGtpbmQgb2Ygb2xkIGFuZCBjcnVzdHkuICBIaXN0b3JpY2FsbHksIGl0cyBkZWZhdWx0IHN0cmluZ1xuICAvLyBlbmNvZGluZyBpcyAnYmluYXJ5JyBzbyB3ZSBoYXZlIHRvIG1ha2UgdGhpcyBjb25maWd1cmFibGUuXG4gIC8vIEV2ZXJ5dGhpbmcgZWxzZSBpbiB0aGUgdW5pdmVyc2UgdXNlcyAndXRmOCcsIHRob3VnaC5cbiAgdGhpcy5kZWZhdWx0RW5jb2RpbmcgPSBvcHRpb25zLmRlZmF1bHRFbmNvZGluZyB8fCAndXRmOCc7XG5cbiAgLy8gbm90IGFuIGFjdHVhbCBidWZmZXIgd2Uga2VlcCB0cmFjayBvZiwgYnV0IGEgbWVhc3VyZW1lbnRcbiAgLy8gb2YgaG93IG11Y2ggd2UncmUgd2FpdGluZyB0byBnZXQgcHVzaGVkIHRvIHNvbWUgdW5kZXJseWluZ1xuICAvLyBzb2NrZXQgb3IgZmlsZS5cbiAgdGhpcy5sZW5ndGggPSAwO1xuXG4gIC8vIGEgZmxhZyB0byBzZWUgd2hlbiB3ZSdyZSBpbiB0aGUgbWlkZGxlIG9mIGEgd3JpdGUuXG4gIHRoaXMud3JpdGluZyA9IGZhbHNlO1xuXG4gIC8vIHdoZW4gdHJ1ZSBhbGwgd3JpdGVzIHdpbGwgYmUgYnVmZmVyZWQgdW50aWwgLnVuY29yaygpIGNhbGxcbiAgdGhpcy5jb3JrZWQgPSAwO1xuXG4gIC8vIGEgZmxhZyB0byBiZSBhYmxlIHRvIHRlbGwgaWYgdGhlIG9ud3JpdGUgY2IgaXMgY2FsbGVkIGltbWVkaWF0ZWx5LFxuICAvLyBvciBvbiBhIGxhdGVyIHRpY2suICBXZSBzZXQgdGhpcyB0byB0cnVlIGF0IGZpcnN0LCBiZWNhdXNlIGFueVxuICAvLyBhY3Rpb25zIHRoYXQgc2hvdWxkbid0IGhhcHBlbiB1bnRpbCBcImxhdGVyXCIgc2hvdWxkIGdlbmVyYWxseSBhbHNvXG4gIC8vIG5vdCBoYXBwZW4gYmVmb3JlIHRoZSBmaXJzdCB3cml0ZSBjYWxsLlxuICB0aGlzLnN5bmMgPSB0cnVlO1xuXG4gIC8vIGEgZmxhZyB0byBrbm93IGlmIHdlJ3JlIHByb2Nlc3NpbmcgcHJldmlvdXNseSBidWZmZXJlZCBpdGVtcywgd2hpY2hcbiAgLy8gbWF5IGNhbGwgdGhlIF93cml0ZSgpIGNhbGxiYWNrIGluIHRoZSBzYW1lIHRpY2ssIHNvIHRoYXQgd2UgZG9uJ3RcbiAgLy8gZW5kIHVwIGluIGFuIG92ZXJsYXBwZWQgb253cml0ZSBzaXR1YXRpb24uXG4gIHRoaXMuYnVmZmVyUHJvY2Vzc2luZyA9IGZhbHNlO1xuXG4gIC8vIHRoZSBjYWxsYmFjayB0aGF0J3MgcGFzc2VkIHRvIF93cml0ZShjaHVuayxjYilcbiAgdGhpcy5vbndyaXRlID0gZnVuY3Rpb24oZXIpIHtcbiAgICBvbndyaXRlKHN0cmVhbSwgZXIpO1xuICB9O1xuXG4gIC8vIHRoZSBjYWxsYmFjayB0aGF0IHRoZSB1c2VyIHN1cHBsaWVzIHRvIHdyaXRlKGNodW5rLGVuY29kaW5nLGNiKVxuICB0aGlzLndyaXRlY2IgPSBudWxsO1xuXG4gIC8vIHRoZSBhbW91bnQgdGhhdCBpcyBiZWluZyB3cml0dGVuIHdoZW4gX3dyaXRlIGlzIGNhbGxlZC5cbiAgdGhpcy53cml0ZWxlbiA9IDA7XG5cbiAgdGhpcy5idWZmZXIgPSBbXTtcblxuICAvLyBudW1iZXIgb2YgcGVuZGluZyB1c2VyLXN1cHBsaWVkIHdyaXRlIGNhbGxiYWNrc1xuICAvLyB0aGlzIG11c3QgYmUgMCBiZWZvcmUgJ2ZpbmlzaCcgY2FuIGJlIGVtaXR0ZWRcbiAgdGhpcy5wZW5kaW5nY2IgPSAwO1xuXG4gIC8vIGVtaXQgcHJlZmluaXNoIGlmIHRoZSBvbmx5IHRoaW5nIHdlJ3JlIHdhaXRpbmcgZm9yIGlzIF93cml0ZSBjYnNcbiAgLy8gVGhpcyBpcyByZWxldmFudCBmb3Igc3luY2hyb25vdXMgVHJhbnNmb3JtIHN0cmVhbXNcbiAgdGhpcy5wcmVmaW5pc2hlZCA9IGZhbHNlO1xuXG4gIC8vIFRydWUgaWYgdGhlIGVycm9yIHdhcyBhbHJlYWR5IGVtaXR0ZWQgYW5kIHNob3VsZCBub3QgYmUgdGhyb3duIGFnYWluXG4gIHRoaXMuZXJyb3JFbWl0dGVkID0gZmFsc2U7XG59XG5cbmZ1bmN0aW9uIFdyaXRhYmxlKG9wdGlvbnMpIHtcbiAgdmFyIER1cGxleCA9IHJlcXVpcmUoJy4vX3N0cmVhbV9kdXBsZXgnKTtcblxuICAvLyBXcml0YWJsZSBjdG9yIGlzIGFwcGxpZWQgdG8gRHVwbGV4ZXMsIHRob3VnaCB0aGV5J3JlIG5vdFxuICAvLyBpbnN0YW5jZW9mIFdyaXRhYmxlLCB0aGV5J3JlIGluc3RhbmNlb2YgUmVhZGFibGUuXG4gIGlmICghKHRoaXMgaW5zdGFuY2VvZiBXcml0YWJsZSkgJiYgISh0aGlzIGluc3RhbmNlb2YgRHVwbGV4KSlcbiAgICByZXR1cm4gbmV3IFdyaXRhYmxlKG9wdGlvbnMpO1xuXG4gIHRoaXMuX3dyaXRhYmxlU3RhdGUgPSBuZXcgV3JpdGFibGVTdGF0ZShvcHRpb25zLCB0aGlzKTtcblxuICAvLyBsZWdhY3kuXG4gIHRoaXMud3JpdGFibGUgPSB0cnVlO1xuXG4gIFN0cmVhbS5jYWxsKHRoaXMpO1xufVxuXG4vLyBPdGhlcndpc2UgcGVvcGxlIGNhbiBwaXBlIFdyaXRhYmxlIHN0cmVhbXMsIHdoaWNoIGlzIGp1c3Qgd3JvbmcuXG5Xcml0YWJsZS5wcm90b3R5cGUucGlwZSA9IGZ1bmN0aW9uKCkge1xuICB0aGlzLmVtaXQoJ2Vycm9yJywgbmV3IEVycm9yKCdDYW5ub3QgcGlwZS4gTm90IHJlYWRhYmxlLicpKTtcbn07XG5cblxuZnVuY3Rpb24gd3JpdGVBZnRlckVuZChzdHJlYW0sIHN0YXRlLCBjYikge1xuICB2YXIgZXIgPSBuZXcgRXJyb3IoJ3dyaXRlIGFmdGVyIGVuZCcpO1xuICAvLyBUT0RPOiBkZWZlciBlcnJvciBldmVudHMgY29uc2lzdGVudGx5IGV2ZXJ5d2hlcmUsIG5vdCBqdXN0IHRoZSBjYlxuICBzdHJlYW0uZW1pdCgnZXJyb3InLCBlcik7XG4gIHByb2Nlc3MubmV4dFRpY2soZnVuY3Rpb24oKSB7XG4gICAgY2IoZXIpO1xuICB9KTtcbn1cblxuLy8gSWYgd2UgZ2V0IHNvbWV0aGluZyB0aGF0IGlzIG5vdCBhIGJ1ZmZlciwgc3RyaW5nLCBudWxsLCBvciB1bmRlZmluZWQsXG4vLyBhbmQgd2UncmUgbm90IGluIG9iamVjdE1vZGUsIHRoZW4gdGhhdCdzIGFuIGVycm9yLlxuLy8gT3RoZXJ3aXNlIHN0cmVhbSBjaHVua3MgYXJlIGFsbCBjb25zaWRlcmVkIHRvIGJlIG9mIGxlbmd0aD0xLCBhbmQgdGhlXG4vLyB3YXRlcm1hcmtzIGRldGVybWluZSBob3cgbWFueSBvYmplY3RzIHRvIGtlZXAgaW4gdGhlIGJ1ZmZlciwgcmF0aGVyIHRoYW5cbi8vIGhvdyBtYW55IGJ5dGVzIG9yIGNoYXJhY3RlcnMuXG5mdW5jdGlvbiB2YWxpZENodW5rKHN0cmVhbSwgc3RhdGUsIGNodW5rLCBjYikge1xuICB2YXIgdmFsaWQgPSB0cnVlO1xuICBpZiAoIXV0aWwuaXNCdWZmZXIoY2h1bmspICYmXG4gICAgICAhdXRpbC5pc1N0cmluZyhjaHVuaykgJiZcbiAgICAgICF1dGlsLmlzTnVsbE9yVW5kZWZpbmVkKGNodW5rKSAmJlxuICAgICAgIXN0YXRlLm9iamVjdE1vZGUpIHtcbiAgICB2YXIgZXIgPSBuZXcgVHlwZUVycm9yKCdJbnZhbGlkIG5vbi1zdHJpbmcvYnVmZmVyIGNodW5rJyk7XG4gICAgc3RyZWFtLmVtaXQoJ2Vycm9yJywgZXIpO1xuICAgIHByb2Nlc3MubmV4dFRpY2soZnVuY3Rpb24oKSB7XG4gICAgICBjYihlcik7XG4gICAgfSk7XG4gICAgdmFsaWQgPSBmYWxzZTtcbiAgfVxuICByZXR1cm4gdmFsaWQ7XG59XG5cbldyaXRhYmxlLnByb3RvdHlwZS53cml0ZSA9IGZ1bmN0aW9uKGNodW5rLCBlbmNvZGluZywgY2IpIHtcbiAgdmFyIHN0YXRlID0gdGhpcy5fd3JpdGFibGVTdGF0ZTtcbiAgdmFyIHJldCA9IGZhbHNlO1xuXG4gIGlmICh1dGlsLmlzRnVuY3Rpb24oZW5jb2RpbmcpKSB7XG4gICAgY2IgPSBlbmNvZGluZztcbiAgICBlbmNvZGluZyA9IG51bGw7XG4gIH1cblxuICBpZiAodXRpbC5pc0J1ZmZlcihjaHVuaykpXG4gICAgZW5jb2RpbmcgPSAnYnVmZmVyJztcbiAgZWxzZSBpZiAoIWVuY29kaW5nKVxuICAgIGVuY29kaW5nID0gc3RhdGUuZGVmYXVsdEVuY29kaW5nO1xuXG4gIGlmICghdXRpbC5pc0Z1bmN0aW9uKGNiKSlcbiAgICBjYiA9IGZ1bmN0aW9uKCkge307XG5cbiAgaWYgKHN0YXRlLmVuZGVkKVxuICAgIHdyaXRlQWZ0ZXJFbmQodGhpcywgc3RhdGUsIGNiKTtcbiAgZWxzZSBpZiAodmFsaWRDaHVuayh0aGlzLCBzdGF0ZSwgY2h1bmssIGNiKSkge1xuICAgIHN0YXRlLnBlbmRpbmdjYisrO1xuICAgIHJldCA9IHdyaXRlT3JCdWZmZXIodGhpcywgc3RhdGUsIGNodW5rLCBlbmNvZGluZywgY2IpO1xuICB9XG5cbiAgcmV0dXJuIHJldDtcbn07XG5cbldyaXRhYmxlLnByb3RvdHlwZS5jb3JrID0gZnVuY3Rpb24oKSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3dyaXRhYmxlU3RhdGU7XG5cbiAgc3RhdGUuY29ya2VkKys7XG59O1xuXG5Xcml0YWJsZS5wcm90b3R5cGUudW5jb3JrID0gZnVuY3Rpb24oKSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3dyaXRhYmxlU3RhdGU7XG5cbiAgaWYgKHN0YXRlLmNvcmtlZCkge1xuICAgIHN0YXRlLmNvcmtlZC0tO1xuXG4gICAgaWYgKCFzdGF0ZS53cml0aW5nICYmXG4gICAgICAgICFzdGF0ZS5jb3JrZWQgJiZcbiAgICAgICAgIXN0YXRlLmZpbmlzaGVkICYmXG4gICAgICAgICFzdGF0ZS5idWZmZXJQcm9jZXNzaW5nICYmXG4gICAgICAgIHN0YXRlLmJ1ZmZlci5sZW5ndGgpXG4gICAgICBjbGVhckJ1ZmZlcih0aGlzLCBzdGF0ZSk7XG4gIH1cbn07XG5cbmZ1bmN0aW9uIGRlY29kZUNodW5rKHN0YXRlLCBjaHVuaywgZW5jb2RpbmcpIHtcbiAgaWYgKCFzdGF0ZS5vYmplY3RNb2RlICYmXG4gICAgICBzdGF0ZS5kZWNvZGVTdHJpbmdzICE9PSBmYWxzZSAmJlxuICAgICAgdXRpbC5pc1N0cmluZyhjaHVuaykpIHtcbiAgICBjaHVuayA9IG5ldyBCdWZmZXIoY2h1bmssIGVuY29kaW5nKTtcbiAgfVxuICByZXR1cm4gY2h1bms7XG59XG5cbi8vIGlmIHdlJ3JlIGFscmVhZHkgd3JpdGluZyBzb21ldGhpbmcsIHRoZW4ganVzdCBwdXQgdGhpc1xuLy8gaW4gdGhlIHF1ZXVlLCBhbmQgd2FpdCBvdXIgdHVybi4gIE90aGVyd2lzZSwgY2FsbCBfd3JpdGVcbi8vIElmIHdlIHJldHVybiBmYWxzZSwgdGhlbiB3ZSBuZWVkIGEgZHJhaW4gZXZlbnQsIHNvIHNldCB0aGF0IGZsYWcuXG5mdW5jdGlvbiB3cml0ZU9yQnVmZmVyKHN0cmVhbSwgc3RhdGUsIGNodW5rLCBlbmNvZGluZywgY2IpIHtcbiAgY2h1bmsgPSBkZWNvZGVDaHVuayhzdGF0ZSwgY2h1bmssIGVuY29kaW5nKTtcbiAgaWYgKHV0aWwuaXNCdWZmZXIoY2h1bmspKVxuICAgIGVuY29kaW5nID0gJ2J1ZmZlcic7XG4gIHZhciBsZW4gPSBzdGF0ZS5vYmplY3RNb2RlID8gMSA6IGNodW5rLmxlbmd0aDtcblxuICBzdGF0ZS5sZW5ndGggKz0gbGVuO1xuXG4gIHZhciByZXQgPSBzdGF0ZS5sZW5ndGggPCBzdGF0ZS5oaWdoV2F0ZXJNYXJrO1xuICAvLyB3ZSBtdXN0IGVuc3VyZSB0aGF0IHByZXZpb3VzIG5lZWREcmFpbiB3aWxsIG5vdCBiZSByZXNldCB0byBmYWxzZS5cbiAgaWYgKCFyZXQpXG4gICAgc3RhdGUubmVlZERyYWluID0gdHJ1ZTtcblxuICBpZiAoc3RhdGUud3JpdGluZyB8fCBzdGF0ZS5jb3JrZWQpXG4gICAgc3RhdGUuYnVmZmVyLnB1c2gobmV3IFdyaXRlUmVxKGNodW5rLCBlbmNvZGluZywgY2IpKTtcbiAgZWxzZVxuICAgIGRvV3JpdGUoc3RyZWFtLCBzdGF0ZSwgZmFsc2UsIGxlbiwgY2h1bmssIGVuY29kaW5nLCBjYik7XG5cbiAgcmV0dXJuIHJldDtcbn1cblxuZnVuY3Rpb24gZG9Xcml0ZShzdHJlYW0sIHN0YXRlLCB3cml0ZXYsIGxlbiwgY2h1bmssIGVuY29kaW5nLCBjYikge1xuICBzdGF0ZS53cml0ZWxlbiA9IGxlbjtcbiAgc3RhdGUud3JpdGVjYiA9IGNiO1xuICBzdGF0ZS53cml0aW5nID0gdHJ1ZTtcbiAgc3RhdGUuc3luYyA9IHRydWU7XG4gIGlmICh3cml0ZXYpXG4gICAgc3RyZWFtLl93cml0ZXYoY2h1bmssIHN0YXRlLm9ud3JpdGUpO1xuICBlbHNlXG4gICAgc3RyZWFtLl93cml0ZShjaHVuaywgZW5jb2RpbmcsIHN0YXRlLm9ud3JpdGUpO1xuICBzdGF0ZS5zeW5jID0gZmFsc2U7XG59XG5cbmZ1bmN0aW9uIG9ud3JpdGVFcnJvcihzdHJlYW0sIHN0YXRlLCBzeW5jLCBlciwgY2IpIHtcbiAgaWYgKHN5bmMpXG4gICAgcHJvY2Vzcy5uZXh0VGljayhmdW5jdGlvbigpIHtcbiAgICAgIHN0YXRlLnBlbmRpbmdjYi0tO1xuICAgICAgY2IoZXIpO1xuICAgIH0pO1xuICBlbHNlIHtcbiAgICBzdGF0ZS5wZW5kaW5nY2ItLTtcbiAgICBjYihlcik7XG4gIH1cblxuICBzdHJlYW0uX3dyaXRhYmxlU3RhdGUuZXJyb3JFbWl0dGVkID0gdHJ1ZTtcbiAgc3RyZWFtLmVtaXQoJ2Vycm9yJywgZXIpO1xufVxuXG5mdW5jdGlvbiBvbndyaXRlU3RhdGVVcGRhdGUoc3RhdGUpIHtcbiAgc3RhdGUud3JpdGluZyA9IGZhbHNlO1xuICBzdGF0ZS53cml0ZWNiID0gbnVsbDtcbiAgc3RhdGUubGVuZ3RoIC09IHN0YXRlLndyaXRlbGVuO1xuICBzdGF0ZS53cml0ZWxlbiA9IDA7XG59XG5cbmZ1bmN0aW9uIG9ud3JpdGUoc3RyZWFtLCBlcikge1xuICB2YXIgc3RhdGUgPSBzdHJlYW0uX3dyaXRhYmxlU3RhdGU7XG4gIHZhciBzeW5jID0gc3RhdGUuc3luYztcbiAgdmFyIGNiID0gc3RhdGUud3JpdGVjYjtcblxuICBvbndyaXRlU3RhdGVVcGRhdGUoc3RhdGUpO1xuXG4gIGlmIChlcilcbiAgICBvbndyaXRlRXJyb3Ioc3RyZWFtLCBzdGF0ZSwgc3luYywgZXIsIGNiKTtcbiAgZWxzZSB7XG4gICAgLy8gQ2hlY2sgaWYgd2UncmUgYWN0dWFsbHkgcmVhZHkgdG8gZmluaXNoLCBidXQgZG9uJ3QgZW1pdCB5ZXRcbiAgICB2YXIgZmluaXNoZWQgPSBuZWVkRmluaXNoKHN0cmVhbSwgc3RhdGUpO1xuXG4gICAgaWYgKCFmaW5pc2hlZCAmJlxuICAgICAgICAhc3RhdGUuY29ya2VkICYmXG4gICAgICAgICFzdGF0ZS5idWZmZXJQcm9jZXNzaW5nICYmXG4gICAgICAgIHN0YXRlLmJ1ZmZlci5sZW5ndGgpIHtcbiAgICAgIGNsZWFyQnVmZmVyKHN0cmVhbSwgc3RhdGUpO1xuICAgIH1cblxuICAgIGlmIChzeW5jKSB7XG4gICAgICBwcm9jZXNzLm5leHRUaWNrKGZ1bmN0aW9uKCkge1xuICAgICAgICBhZnRlcldyaXRlKHN0cmVhbSwgc3RhdGUsIGZpbmlzaGVkLCBjYik7XG4gICAgICB9KTtcbiAgICB9IGVsc2Uge1xuICAgICAgYWZ0ZXJXcml0ZShzdHJlYW0sIHN0YXRlLCBmaW5pc2hlZCwgY2IpO1xuICAgIH1cbiAgfVxufVxuXG5mdW5jdGlvbiBhZnRlcldyaXRlKHN0cmVhbSwgc3RhdGUsIGZpbmlzaGVkLCBjYikge1xuICBpZiAoIWZpbmlzaGVkKVxuICAgIG9ud3JpdGVEcmFpbihzdHJlYW0sIHN0YXRlKTtcbiAgc3RhdGUucGVuZGluZ2NiLS07XG4gIGNiKCk7XG4gIGZpbmlzaE1heWJlKHN0cmVhbSwgc3RhdGUpO1xufVxuXG4vLyBNdXN0IGZvcmNlIGNhbGxiYWNrIHRvIGJlIGNhbGxlZCBvbiBuZXh0VGljaywgc28gdGhhdCB3ZSBkb24ndFxuLy8gZW1pdCAnZHJhaW4nIGJlZm9yZSB0aGUgd3JpdGUoKSBjb25zdW1lciBnZXRzIHRoZSAnZmFsc2UnIHJldHVyblxuLy8gdmFsdWUsIGFuZCBoYXMgYSBjaGFuY2UgdG8gYXR0YWNoIGEgJ2RyYWluJyBsaXN0ZW5lci5cbmZ1bmN0aW9uIG9ud3JpdGVEcmFpbihzdHJlYW0sIHN0YXRlKSB7XG4gIGlmIChzdGF0ZS5sZW5ndGggPT09IDAgJiYgc3RhdGUubmVlZERyYWluKSB7XG4gICAgc3RhdGUubmVlZERyYWluID0gZmFsc2U7XG4gICAgc3RyZWFtLmVtaXQoJ2RyYWluJyk7XG4gIH1cbn1cblxuXG4vLyBpZiB0aGVyZSdzIHNvbWV0aGluZyBpbiB0aGUgYnVmZmVyIHdhaXRpbmcsIHRoZW4gcHJvY2VzcyBpdFxuZnVuY3Rpb24gY2xlYXJCdWZmZXIoc3RyZWFtLCBzdGF0ZSkge1xuICBzdGF0ZS5idWZmZXJQcm9jZXNzaW5nID0gdHJ1ZTtcblxuICBpZiAoc3RyZWFtLl93cml0ZXYgJiYgc3RhdGUuYnVmZmVyLmxlbmd0aCA+IDEpIHtcbiAgICAvLyBGYXN0IGNhc2UsIHdyaXRlIGV2ZXJ5dGhpbmcgdXNpbmcgX3dyaXRldigpXG4gICAgdmFyIGNicyA9IFtdO1xuICAgIGZvciAodmFyIGMgPSAwOyBjIDwgc3RhdGUuYnVmZmVyLmxlbmd0aDsgYysrKVxuICAgICAgY2JzLnB1c2goc3RhdGUuYnVmZmVyW2NdLmNhbGxiYWNrKTtcblxuICAgIC8vIGNvdW50IHRoZSBvbmUgd2UgYXJlIGFkZGluZywgYXMgd2VsbC5cbiAgICAvLyBUT0RPKGlzYWFjcykgY2xlYW4gdGhpcyB1cFxuICAgIHN0YXRlLnBlbmRpbmdjYisrO1xuICAgIGRvV3JpdGUoc3RyZWFtLCBzdGF0ZSwgdHJ1ZSwgc3RhdGUubGVuZ3RoLCBzdGF0ZS5idWZmZXIsICcnLCBmdW5jdGlvbihlcnIpIHtcbiAgICAgIGZvciAodmFyIGkgPSAwOyBpIDwgY2JzLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgIHN0YXRlLnBlbmRpbmdjYi0tO1xuICAgICAgICBjYnNbaV0oZXJyKTtcbiAgICAgIH1cbiAgICB9KTtcblxuICAgIC8vIENsZWFyIGJ1ZmZlclxuICAgIHN0YXRlLmJ1ZmZlciA9IFtdO1xuICB9IGVsc2Uge1xuICAgIC8vIFNsb3cgY2FzZSwgd3JpdGUgY2h1bmtzIG9uZS1ieS1vbmVcbiAgICBmb3IgKHZhciBjID0gMDsgYyA8IHN0YXRlLmJ1ZmZlci5sZW5ndGg7IGMrKykge1xuICAgICAgdmFyIGVudHJ5ID0gc3RhdGUuYnVmZmVyW2NdO1xuICAgICAgdmFyIGNodW5rID0gZW50cnkuY2h1bms7XG4gICAgICB2YXIgZW5jb2RpbmcgPSBlbnRyeS5lbmNvZGluZztcbiAgICAgIHZhciBjYiA9IGVudHJ5LmNhbGxiYWNrO1xuICAgICAgdmFyIGxlbiA9IHN0YXRlLm9iamVjdE1vZGUgPyAxIDogY2h1bmsubGVuZ3RoO1xuXG4gICAgICBkb1dyaXRlKHN0cmVhbSwgc3RhdGUsIGZhbHNlLCBsZW4sIGNodW5rLCBlbmNvZGluZywgY2IpO1xuXG4gICAgICAvLyBpZiB3ZSBkaWRuJ3QgY2FsbCB0aGUgb253cml0ZSBpbW1lZGlhdGVseSwgdGhlblxuICAgICAgLy8gaXQgbWVhbnMgdGhhdCB3ZSBuZWVkIHRvIHdhaXQgdW50aWwgaXQgZG9lcy5cbiAgICAgIC8vIGFsc28sIHRoYXQgbWVhbnMgdGhhdCB0aGUgY2h1bmsgYW5kIGNiIGFyZSBjdXJyZW50bHlcbiAgICAgIC8vIGJlaW5nIHByb2Nlc3NlZCwgc28gbW92ZSB0aGUgYnVmZmVyIGNvdW50ZXIgcGFzdCB0aGVtLlxuICAgICAgaWYgKHN0YXRlLndyaXRpbmcpIHtcbiAgICAgICAgYysrO1xuICAgICAgICBicmVhaztcbiAgICAgIH1cbiAgICB9XG5cbiAgICBpZiAoYyA8IHN0YXRlLmJ1ZmZlci5sZW5ndGgpXG4gICAgICBzdGF0ZS5idWZmZXIgPSBzdGF0ZS5idWZmZXIuc2xpY2UoYyk7XG4gICAgZWxzZVxuICAgICAgc3RhdGUuYnVmZmVyLmxlbmd0aCA9IDA7XG4gIH1cblxuICBzdGF0ZS5idWZmZXJQcm9jZXNzaW5nID0gZmFsc2U7XG59XG5cbldyaXRhYmxlLnByb3RvdHlwZS5fd3JpdGUgPSBmdW5jdGlvbihjaHVuaywgZW5jb2RpbmcsIGNiKSB7XG4gIGNiKG5ldyBFcnJvcignbm90IGltcGxlbWVudGVkJykpO1xuXG59O1xuXG5Xcml0YWJsZS5wcm90b3R5cGUuX3dyaXRldiA9IG51bGw7XG5cbldyaXRhYmxlLnByb3RvdHlwZS5lbmQgPSBmdW5jdGlvbihjaHVuaywgZW5jb2RpbmcsIGNiKSB7XG4gIHZhciBzdGF0ZSA9IHRoaXMuX3dyaXRhYmxlU3RhdGU7XG5cbiAgaWYgKHV0aWwuaXNGdW5jdGlvbihjaHVuaykpIHtcbiAgICBjYiA9IGNodW5rO1xuICAgIGNodW5rID0gbnVsbDtcbiAgICBlbmNvZGluZyA9IG51bGw7XG4gIH0gZWxzZSBpZiAodXRpbC5pc0Z1bmN0aW9uKGVuY29kaW5nKSkge1xuICAgIGNiID0gZW5jb2Rpbmc7XG4gICAgZW5jb2RpbmcgPSBudWxsO1xuICB9XG5cbiAgaWYgKCF1dGlsLmlzTnVsbE9yVW5kZWZpbmVkKGNodW5rKSlcbiAgICB0aGlzLndyaXRlKGNodW5rLCBlbmNvZGluZyk7XG5cbiAgLy8gLmVuZCgpIGZ1bGx5IHVuY29ya3NcbiAgaWYgKHN0YXRlLmNvcmtlZCkge1xuICAgIHN0YXRlLmNvcmtlZCA9IDE7XG4gICAgdGhpcy51bmNvcmsoKTtcbiAgfVxuXG4gIC8vIGlnbm9yZSB1bm5lY2Vzc2FyeSBlbmQoKSBjYWxscy5cbiAgaWYgKCFzdGF0ZS5lbmRpbmcgJiYgIXN0YXRlLmZpbmlzaGVkKVxuICAgIGVuZFdyaXRhYmxlKHRoaXMsIHN0YXRlLCBjYik7XG59O1xuXG5cbmZ1bmN0aW9uIG5lZWRGaW5pc2goc3RyZWFtLCBzdGF0ZSkge1xuICByZXR1cm4gKHN0YXRlLmVuZGluZyAmJlxuICAgICAgICAgIHN0YXRlLmxlbmd0aCA9PT0gMCAmJlxuICAgICAgICAgICFzdGF0ZS5maW5pc2hlZCAmJlxuICAgICAgICAgICFzdGF0ZS53cml0aW5nKTtcbn1cblxuZnVuY3Rpb24gcHJlZmluaXNoKHN0cmVhbSwgc3RhdGUpIHtcbiAgaWYgKCFzdGF0ZS5wcmVmaW5pc2hlZCkge1xuICAgIHN0YXRlLnByZWZpbmlzaGVkID0gdHJ1ZTtcbiAgICBzdHJlYW0uZW1pdCgncHJlZmluaXNoJyk7XG4gIH1cbn1cblxuZnVuY3Rpb24gZmluaXNoTWF5YmUoc3RyZWFtLCBzdGF0ZSkge1xuICB2YXIgbmVlZCA9IG5lZWRGaW5pc2goc3RyZWFtLCBzdGF0ZSk7XG4gIGlmIChuZWVkKSB7XG4gICAgaWYgKHN0YXRlLnBlbmRpbmdjYiA9PT0gMCkge1xuICAgICAgcHJlZmluaXNoKHN0cmVhbSwgc3RhdGUpO1xuICAgICAgc3RhdGUuZmluaXNoZWQgPSB0cnVlO1xuICAgICAgc3RyZWFtLmVtaXQoJ2ZpbmlzaCcpO1xuICAgIH0gZWxzZVxuICAgICAgcHJlZmluaXNoKHN0cmVhbSwgc3RhdGUpO1xuICB9XG4gIHJldHVybiBuZWVkO1xufVxuXG5mdW5jdGlvbiBlbmRXcml0YWJsZShzdHJlYW0sIHN0YXRlLCBjYikge1xuICBzdGF0ZS5lbmRpbmcgPSB0cnVlO1xuICBmaW5pc2hNYXliZShzdHJlYW0sIHN0YXRlKTtcbiAgaWYgKGNiKSB7XG4gICAgaWYgKHN0YXRlLmZpbmlzaGVkKVxuICAgICAgcHJvY2Vzcy5uZXh0VGljayhjYik7XG4gICAgZWxzZVxuICAgICAgc3RyZWFtLm9uY2UoJ2ZpbmlzaCcsIGNiKTtcbiAgfVxuICBzdGF0ZS5lbmRlZCA9IHRydWU7XG59XG5cbn0pLmNhbGwodGhpcyxyZXF1aXJlKCdfcHJvY2VzcycpKVxuLy8jIHNvdXJjZU1hcHBpbmdVUkw9ZGF0YTphcHBsaWNhdGlvbi9qc29uO2NoYXJzZXQ6dXRmLTg7YmFzZTY0LGV5SjJaWEp6YVc5dUlqb3pMQ0p6YjNWeVkyVnpJanBiSW01dlpHVmZiVzlrZFd4bGN5OWljbTkzYzJWeWFXWjVMMjV2WkdWZmJXOWtkV3hsY3k5eVpXRmtZV0pzWlMxemRISmxZVzB2YkdsaUwxOXpkSEpsWVcxZmQzSnBkR0ZpYkdVdWFuTWlYU3dpYm1GdFpYTWlPbHRkTENKdFlYQndhVzVuY3lJNklqdEJRVUZCTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CSWl3aVptbHNaU0k2SW1kbGJtVnlZWFJsWkM1cWN5SXNJbk52ZFhKalpWSnZiM1FpT2lJaUxDSnpiM1Z5WTJWelEyOXVkR1Z1ZENJNld5SXZMeUJEYjNCNWNtbG5hSFFnU205NVpXNTBMQ0JKYm1NdUlHRnVaQ0J2ZEdobGNpQk9iMlJsSUdOdmJuUnlhV0oxZEc5eWN5NWNiaTh2WEc0dkx5QlFaWEp0YVhOemFXOXVJR2x6SUdobGNtVmllU0JuY21GdWRHVmtMQ0JtY21WbElHOW1JR05vWVhKblpTd2dkRzhnWVc1NUlIQmxjbk52YmlCdlluUmhhVzVwYm1jZ1lWeHVMeThnWTI5d2VTQnZaaUIwYUdseklITnZablIzWVhKbElHRnVaQ0JoYzNOdlkybGhkR1ZrSUdSdlkzVnRaVzUwWVhScGIyNGdabWxzWlhNZ0tIUm9aVnh1THk4Z1hDSlRiMlowZDJGeVpWd2lLU3dnZEc4Z1pHVmhiQ0JwYmlCMGFHVWdVMjltZEhkaGNtVWdkMmwwYUc5MWRDQnlaWE4wY21samRHbHZiaXdnYVc1amJIVmthVzVuWEc0dkx5QjNhWFJvYjNWMElHeHBiV2wwWVhScGIyNGdkR2hsSUhKcFoyaDBjeUIwYnlCMWMyVXNJR052Y0hrc0lHMXZaR2xtZVN3Z2JXVnlaMlVzSUhCMVlteHBjMmdzWEc0dkx5QmthWE4wY21saWRYUmxMQ0J6ZFdKc2FXTmxibk5sTENCaGJtUXZiM0lnYzJWc2JDQmpiM0JwWlhNZ2IyWWdkR2hsSUZOdlpuUjNZWEpsTENCaGJtUWdkRzhnY0dWeWJXbDBYRzR2THlCd1pYSnpiMjV6SUhSdklIZG9iMjBnZEdobElGTnZablIzWVhKbElHbHpJR1oxY201cGMyaGxaQ0IwYnlCa2J5QnpieXdnYzNWaWFtVmpkQ0IwYnlCMGFHVmNiaTh2SUdadmJHeHZkMmx1WnlCamIyNWthWFJwYjI1ek9seHVMeTljYmk4dklGUm9aU0JoWW05MlpTQmpiM0I1Y21sbmFIUWdibTkwYVdObElHRnVaQ0IwYUdseklIQmxjbTFwYzNOcGIyNGdibTkwYVdObElITm9ZV3hzSUdKbElHbHVZMngxWkdWa1hHNHZMeUJwYmlCaGJHd2dZMjl3YVdWeklHOXlJSE4xWW5OMFlXNTBhV0ZzSUhCdmNuUnBiMjV6SUc5bUlIUm9aU0JUYjJaMGQyRnlaUzVjYmk4dlhHNHZMeUJVU0VVZ1UwOUdWRmRCVWtVZ1NWTWdVRkpQVmtsRVJVUWdYQ0pCVXlCSlUxd2lMQ0JYU1ZSSVQxVlVJRmRCVWxKQlRsUlpJRTlHSUVGT1dTQkxTVTVFTENCRldGQlNSVk5UWEc0dkx5QlBVaUJKVFZCTVNVVkVMQ0JKVGtOTVZVUkpUa2NnUWxWVUlFNVBWQ0JNU1UxSlZFVkVJRlJQSUZSSVJTQlhRVkpTUVU1VVNVVlRJRTlHWEc0dkx5Qk5SVkpEU0VGT1ZFRkNTVXhKVkZrc0lFWkpWRTVGVTFNZ1JrOVNJRUVnVUVGU1ZFbERWVXhCVWlCUVZWSlFUMU5GSUVGT1JDQk9UMDVKVGtaU1NVNUhSVTFGVGxRdUlFbE9YRzR2THlCT1R5QkZWa1ZPVkNCVFNFRk1UQ0JVU0VVZ1FWVlVTRTlTVXlCUFVpQkRUMUJaVWtsSFNGUWdTRTlNUkVWU1V5QkNSU0JNU1VGQ1RFVWdSazlTSUVGT1dTQkRURUZKVFN4Y2JpOHZJRVJCVFVGSFJWTWdUMUlnVDFSSVJWSWdURWxCUWtsTVNWUlpMQ0JYU0VWVVNFVlNJRWxPSUVGT0lFRkRWRWxQVGlCUFJpQkRUMDVVVWtGRFZDd2dWRTlTVkNCUFVseHVMeThnVDFSSVJWSlhTVk5GTENCQlVrbFRTVTVISUVaU1QwMHNJRTlWVkNCUFJpQlBVaUJKVGlCRFQwNU9SVU5VU1U5T0lGZEpWRWdnVkVoRklGTlBSbFJYUVZKRklFOVNJRlJJUlZ4dUx5OGdWVk5GSUU5U0lFOVVTRVZTSUVSRlFVeEpUa2RUSUVsT0lGUklSU0JUVDBaVVYwRlNSUzVjYmx4dUx5OGdRU0JpYVhRZ2MybHRjR3hsY2lCMGFHRnVJSEpsWVdSaFlteGxJSE4wY21WaGJYTXVYRzR2THlCSmJYQnNaVzFsYm5RZ1lXNGdZWE41Ym1NZ0xsOTNjbWwwWlNoamFIVnVheXdnWTJJcExDQmhibVFnYVhRbmJHd2dhR0Z1Wkd4bElHRnNiRnh1THk4Z2RHaGxJR1J5WVdsdUlHVjJaVzUwSUdWdGFYTnphVzl1SUdGdVpDQmlkV1ptWlhKcGJtY3VYRzVjYm0xdlpIVnNaUzVsZUhCdmNuUnpJRDBnVjNKcGRHRmliR1U3WEc1Y2JpOHFQSEpsY0d4aFkyVnRaVzUwUGlvdlhHNTJZWElnUW5WbVptVnlJRDBnY21WeGRXbHlaU2duWW5WbVptVnlKeWt1UW5WbVptVnlPMXh1THlvOEwzSmxjR3hoWTJWdFpXNTBQaW92WEc1Y2JsZHlhWFJoWW14bExsZHlhWFJoWW14bFUzUmhkR1VnUFNCWGNtbDBZV0pzWlZOMFlYUmxPMXh1WEc1Y2JpOHFQSEpsY0d4aFkyVnRaVzUwUGlvdlhHNTJZWElnZFhScGJDQTlJSEpsY1hWcGNtVW9KMk52Y21VdGRYUnBiQzFwY3ljcE8xeHVkWFJwYkM1cGJtaGxjbWwwY3lBOUlISmxjWFZwY21Vb0oybHVhR1Z5YVhSekp5azdYRzR2S2p3dmNtVndiR0ZqWlcxbGJuUStLaTljYmx4dWRtRnlJRk4wY21WaGJTQTlJSEpsY1hWcGNtVW9KM04wY21WaGJTY3BPMXh1WEc1MWRHbHNMbWx1YUdWeWFYUnpLRmR5YVhSaFlteGxMQ0JUZEhKbFlXMHBPMXh1WEc1bWRXNWpkR2x2YmlCWGNtbDBaVkpsY1NoamFIVnVheXdnWlc1amIyUnBibWNzSUdOaUtTQjdYRzRnSUhSb2FYTXVZMmgxYm1zZ1BTQmphSFZ1YXp0Y2JpQWdkR2hwY3k1bGJtTnZaR2x1WnlBOUlHVnVZMjlrYVc1bk8xeHVJQ0IwYUdsekxtTmhiR3hpWVdOcklEMGdZMkk3WEc1OVhHNWNibVoxYm1OMGFXOXVJRmR5YVhSaFlteGxVM1JoZEdVb2IzQjBhVzl1Y3l3Z2MzUnlaV0Z0S1NCN1hHNGdJSFpoY2lCRWRYQnNaWGdnUFNCeVpYRjFhWEpsS0NjdUwxOXpkSEpsWVcxZlpIVndiR1Y0SnlrN1hHNWNiaUFnYjNCMGFXOXVjeUE5SUc5d2RHbHZibk1nZkh3Z2UzMDdYRzVjYmlBZ0x5OGdkR2hsSUhCdmFXNTBJR0YwSUhkb2FXTm9JSGR5YVhSbEtDa2djM1JoY25SeklISmxkSFZ5Ym1sdVp5Qm1ZV3h6WlZ4dUlDQXZMeUJPYjNSbE9pQXdJR2x6SUdFZ2RtRnNhV1FnZG1Gc2RXVXNJRzFsWVc1eklIUm9ZWFFnZDJVZ1lXeDNZWGx6SUhKbGRIVnliaUJtWVd4elpTQnBabHh1SUNBdkx5QjBhR1VnWlc1MGFYSmxJR0oxWm1abGNpQnBjeUJ1YjNRZ1pteDFjMmhsWkNCcGJXMWxaR2xoZEdWc2VTQnZiaUIzY21sMFpTZ3BYRzRnSUhaaGNpQm9kMjBnUFNCdmNIUnBiMjV6TG1ocFoyaFhZWFJsY2sxaGNtczdYRzRnSUhaaGNpQmtaV1poZFd4MFNIZHRJRDBnYjNCMGFXOXVjeTV2WW1wbFkzUk5iMlJsSUQ4Z01UWWdPaUF4TmlBcUlERXdNalE3WEc0Z0lIUm9hWE11YUdsbmFGZGhkR1Z5VFdGeWF5QTlJQ2hvZDIwZ2ZId2dhSGR0SUQwOVBTQXdLU0EvSUdoM2JTQTZJR1JsWm1GMWJIUklkMjA3WEc1Y2JpQWdMeThnYjJKcVpXTjBJSE4wY21WaGJTQm1iR0ZuSUhSdklHbHVaR2xqWVhSbElIZG9aWFJvWlhJZ2IzSWdibTkwSUhSb2FYTWdjM1J5WldGdFhHNGdJQzh2SUdOdmJuUmhhVzV6SUdKMVptWmxjbk1nYjNJZ2IySnFaV04wY3k1Y2JpQWdkR2hwY3k1dlltcGxZM1JOYjJSbElEMGdJU0Z2Y0hScGIyNXpMbTlpYW1WamRFMXZaR1U3WEc1Y2JpQWdhV1lnS0hOMGNtVmhiU0JwYm5OMFlXNWpaVzltSUVSMWNHeGxlQ2xjYmlBZ0lDQjBhR2x6TG05aWFtVmpkRTF2WkdVZ1BTQjBhR2x6TG05aWFtVmpkRTF2WkdVZ2ZId2dJU0Z2Y0hScGIyNXpMbmR5YVhSaFlteGxUMkpxWldOMFRXOWtaVHRjYmx4dUlDQXZMeUJqWVhOMElIUnZJR2x1ZEhNdVhHNGdJSFJvYVhNdWFHbG5hRmRoZEdWeVRXRnlheUE5SUg1K2RHaHBjeTVvYVdkb1YyRjBaWEpOWVhKck8xeHVYRzRnSUhSb2FYTXVibVZsWkVSeVlXbHVJRDBnWm1Gc2MyVTdYRzRnSUM4dklHRjBJSFJvWlNCemRHRnlkQ0J2WmlCallXeHNhVzVuSUdWdVpDZ3BYRzRnSUhSb2FYTXVaVzVrYVc1bklEMGdabUZzYzJVN1hHNGdJQzh2SUhkb1pXNGdaVzVrS0NrZ2FHRnpJR0psWlc0Z1kyRnNiR1ZrTENCaGJtUWdjbVYwZFhKdVpXUmNiaUFnZEdocGN5NWxibVJsWkNBOUlHWmhiSE5sTzF4dUlDQXZMeUIzYUdWdUlDZG1hVzVwYzJnbklHbHpJR1Z0YVhSMFpXUmNiaUFnZEdocGN5NW1hVzVwYzJobFpDQTlJR1poYkhObE8xeHVYRzRnSUM4dklITm9iM1ZzWkNCM1pTQmtaV052WkdVZ2MzUnlhVzVuY3lCcGJuUnZJR0oxWm1abGNuTWdZbVZtYjNKbElIQmhjM05wYm1jZ2RHOGdYM2R5YVhSbFAxeHVJQ0F2THlCMGFHbHpJR2x6SUdobGNtVWdjMjhnZEdoaGRDQnpiMjFsSUc1dlpHVXRZMjl5WlNCemRISmxZVzF6SUdOaGJpQnZjSFJwYldsNlpTQnpkSEpwYm1kY2JpQWdMeThnYUdGdVpHeHBibWNnWVhRZ1lTQnNiM2RsY2lCc1pYWmxiQzVjYmlBZ2RtRnlJRzV2UkdWamIyUmxJRDBnYjNCMGFXOXVjeTVrWldOdlpHVlRkSEpwYm1keklEMDlQU0JtWVd4elpUdGNiaUFnZEdocGN5NWtaV052WkdWVGRISnBibWR6SUQwZ0lXNXZSR1ZqYjJSbE8xeHVYRzRnSUM4dklFTnllWEIwYnlCcGN5QnJhVzVrSUc5bUlHOXNaQ0JoYm1RZ1kzSjFjM1I1TGlBZ1NHbHpkRzl5YVdOaGJHeDVMQ0JwZEhNZ1pHVm1ZWFZzZENCemRISnBibWRjYmlBZ0x5OGdaVzVqYjJScGJtY2dhWE1nSjJKcGJtRnllU2NnYzI4Z2QyVWdhR0YyWlNCMGJ5QnRZV3RsSUhSb2FYTWdZMjl1Wm1sbmRYSmhZbXhsTGx4dUlDQXZMeUJGZG1WeWVYUm9hVzVuSUdWc2MyVWdhVzRnZEdobElIVnVhWFpsY25ObElIVnpaWE1nSjNWMFpqZ25MQ0IwYUc5MVoyZ3VYRzRnSUhSb2FYTXVaR1ZtWVhWc2RFVnVZMjlrYVc1bklEMGdiM0IwYVc5dWN5NWtaV1poZFd4MFJXNWpiMlJwYm1jZ2ZId2dKM1YwWmpnbk8xeHVYRzRnSUM4dklHNXZkQ0JoYmlCaFkzUjFZV3dnWW5WbVptVnlJSGRsSUd0bFpYQWdkSEpoWTJzZ2IyWXNJR0oxZENCaElHMWxZWE4xY21WdFpXNTBYRzRnSUM4dklHOW1JR2h2ZHlCdGRXTm9JSGRsSjNKbElIZGhhWFJwYm1jZ2RHOGdaMlYwSUhCMWMyaGxaQ0IwYnlCemIyMWxJSFZ1WkdWeWJIbHBibWRjYmlBZ0x5OGdjMjlqYTJWMElHOXlJR1pwYkdVdVhHNGdJSFJvYVhNdWJHVnVaM1JvSUQwZ01EdGNibHh1SUNBdkx5QmhJR1pzWVdjZ2RHOGdjMlZsSUhkb1pXNGdkMlVuY21VZ2FXNGdkR2hsSUcxcFpHUnNaU0J2WmlCaElIZHlhWFJsTGx4dUlDQjBhR2x6TG5keWFYUnBibWNnUFNCbVlXeHpaVHRjYmx4dUlDQXZMeUIzYUdWdUlIUnlkV1VnWVd4c0lIZHlhWFJsY3lCM2FXeHNJR0psSUdKMVptWmxjbVZrSUhWdWRHbHNJQzUxYm1OdmNtc29LU0JqWVd4c1hHNGdJSFJvYVhNdVkyOXlhMlZrSUQwZ01EdGNibHh1SUNBdkx5QmhJR1pzWVdjZ2RHOGdZbVVnWVdKc1pTQjBieUIwWld4c0lHbG1JSFJvWlNCdmJuZHlhWFJsSUdOaUlHbHpJR05oYkd4bFpDQnBiVzFsWkdsaGRHVnNlU3hjYmlBZ0x5OGdiM0lnYjI0Z1lTQnNZWFJsY2lCMGFXTnJMaUFnVjJVZ2MyVjBJSFJvYVhNZ2RHOGdkSEoxWlNCaGRDQm1hWEp6ZEN3Z1ltVmpZWFZ6WlNCaGJubGNiaUFnTHk4Z1lXTjBhVzl1Y3lCMGFHRjBJSE5vYjNWc1pHNG5kQ0JvWVhCd1pXNGdkVzUwYVd3Z1hDSnNZWFJsY2x3aUlITm9iM1ZzWkNCblpXNWxjbUZzYkhrZ1lXeHpiMXh1SUNBdkx5QnViM1FnYUdGd2NHVnVJR0psWm05eVpTQjBhR1VnWm1seWMzUWdkM0pwZEdVZ1kyRnNiQzVjYmlBZ2RHaHBjeTV6ZVc1aklEMGdkSEoxWlR0Y2JseHVJQ0F2THlCaElHWnNZV2NnZEc4Z2EyNXZkeUJwWmlCM1pTZHlaU0J3Y205alpYTnphVzVuSUhCeVpYWnBiM1Z6YkhrZ1luVm1abVZ5WldRZ2FYUmxiWE1zSUhkb2FXTm9YRzRnSUM4dklHMWhlU0JqWVd4c0lIUm9aU0JmZDNKcGRHVW9LU0JqWVd4c1ltRmpheUJwYmlCMGFHVWdjMkZ0WlNCMGFXTnJMQ0J6YnlCMGFHRjBJSGRsSUdSdmJpZDBYRzRnSUM4dklHVnVaQ0IxY0NCcGJpQmhiaUJ2ZG1WeWJHRndjR1ZrSUc5dWQzSnBkR1VnYzJsMGRXRjBhVzl1TGx4dUlDQjBhR2x6TG1KMVptWmxjbEJ5YjJObGMzTnBibWNnUFNCbVlXeHpaVHRjYmx4dUlDQXZMeUIwYUdVZ1kyRnNiR0poWTJzZ2RHaGhkQ2R6SUhCaGMzTmxaQ0IwYnlCZmQzSnBkR1VvWTJoMWJtc3NZMklwWEc0Z0lIUm9hWE11YjI1M2NtbDBaU0E5SUdaMWJtTjBhVzl1S0dWeUtTQjdYRzRnSUNBZ2IyNTNjbWwwWlNoemRISmxZVzBzSUdWeUtUdGNiaUFnZlR0Y2JseHVJQ0F2THlCMGFHVWdZMkZzYkdKaFkyc2dkR2hoZENCMGFHVWdkWE5sY2lCemRYQndiR2xsY3lCMGJ5QjNjbWwwWlNoamFIVnVheXhsYm1OdlpHbHVaeXhqWWlsY2JpQWdkR2hwY3k1M2NtbDBaV05pSUQwZ2JuVnNiRHRjYmx4dUlDQXZMeUIwYUdVZ1lXMXZkVzUwSUhSb1lYUWdhWE1nWW1WcGJtY2dkM0pwZEhSbGJpQjNhR1Z1SUY5M2NtbDBaU0JwY3lCallXeHNaV1F1WEc0Z0lIUm9hWE11ZDNKcGRHVnNaVzRnUFNBd08xeHVYRzRnSUhSb2FYTXVZblZtWm1WeUlEMGdXMTA3WEc1Y2JpQWdMeThnYm5WdFltVnlJRzltSUhCbGJtUnBibWNnZFhObGNpMXpkWEJ3YkdsbFpDQjNjbWwwWlNCallXeHNZbUZqYTNOY2JpQWdMeThnZEdocGN5QnRkWE4wSUdKbElEQWdZbVZtYjNKbElDZG1hVzVwYzJnbklHTmhiaUJpWlNCbGJXbDBkR1ZrWEc0Z0lIUm9hWE11Y0dWdVpHbHVaMk5pSUQwZ01EdGNibHh1SUNBdkx5QmxiV2wwSUhCeVpXWnBibWx6YUNCcFppQjBhR1VnYjI1c2VTQjBhR2x1WnlCM1pTZHlaU0IzWVdsMGFXNW5JR1p2Y2lCcGN5QmZkM0pwZEdVZ1kySnpYRzRnSUM4dklGUm9hWE1nYVhNZ2NtVnNaWFpoYm5RZ1ptOXlJSE41Ym1Ob2NtOXViM1Z6SUZSeVlXNXpabTl5YlNCemRISmxZVzF6WEc0Z0lIUm9hWE11Y0hKbFptbHVhWE5vWldRZ1BTQm1ZV3h6WlR0Y2JseHVJQ0F2THlCVWNuVmxJR2xtSUhSb1pTQmxjbkp2Y2lCM1lYTWdZV3h5WldGa2VTQmxiV2wwZEdWa0lHRnVaQ0J6YUc5MWJHUWdibTkwSUdKbElIUm9jbTkzYmlCaFoyRnBibHh1SUNCMGFHbHpMbVZ5Y205eVJXMXBkSFJsWkNBOUlHWmhiSE5sTzF4dWZWeHVYRzVtZFc1amRHbHZiaUJYY21sMFlXSnNaU2h2Y0hScGIyNXpLU0I3WEc0Z0lIWmhjaUJFZFhCc1pYZ2dQU0J5WlhGMWFYSmxLQ2N1TDE5emRISmxZVzFmWkhWd2JHVjRKeWs3WEc1Y2JpQWdMeThnVjNKcGRHRmliR1VnWTNSdmNpQnBjeUJoY0hCc2FXVmtJSFJ2SUVSMWNHeGxlR1Z6TENCMGFHOTFaMmdnZEdobGVTZHlaU0J1YjNSY2JpQWdMeThnYVc1emRHRnVZMlZ2WmlCWGNtbDBZV0pzWlN3Z2RHaGxlU2R5WlNCcGJuTjBZVzVqWlc5bUlGSmxZV1JoWW14bExseHVJQ0JwWmlBb0lTaDBhR2x6SUdsdWMzUmhibU5sYjJZZ1YzSnBkR0ZpYkdVcElDWW1JQ0VvZEdocGN5QnBibk4wWVc1alpXOW1JRVIxY0d4bGVDa3BYRzRnSUNBZ2NtVjBkWEp1SUc1bGR5QlhjbWwwWVdKc1pTaHZjSFJwYjI1ektUdGNibHh1SUNCMGFHbHpMbDkzY21sMFlXSnNaVk4wWVhSbElEMGdibVYzSUZkeWFYUmhZbXhsVTNSaGRHVW9iM0IwYVc5dWN5d2dkR2hwY3lrN1hHNWNiaUFnTHk4Z2JHVm5ZV041TGx4dUlDQjBhR2x6TG5keWFYUmhZbXhsSUQwZ2RISjFaVHRjYmx4dUlDQlRkSEpsWVcwdVkyRnNiQ2gwYUdsektUdGNibjFjYmx4dUx5OGdUM1JvWlhKM2FYTmxJSEJsYjNCc1pTQmpZVzRnY0dsd1pTQlhjbWwwWVdKc1pTQnpkSEpsWVcxekxDQjNhR2xqYUNCcGN5QnFkWE4wSUhkeWIyNW5MbHh1VjNKcGRHRmliR1V1Y0hKdmRHOTBlWEJsTG5CcGNHVWdQU0JtZFc1amRHbHZiaWdwSUh0Y2JpQWdkR2hwY3k1bGJXbDBLQ2RsY25KdmNpY3NJRzVsZHlCRmNuSnZjaWduUTJGdWJtOTBJSEJwY0dVdUlFNXZkQ0J5WldGa1lXSnNaUzRuS1NrN1hHNTlPMXh1WEc1Y2JtWjFibU4wYVc5dUlIZHlhWFJsUVdaMFpYSkZibVFvYzNSeVpXRnRMQ0J6ZEdGMFpTd2dZMklwSUh0Y2JpQWdkbUZ5SUdWeUlEMGdibVYzSUVWeWNtOXlLQ2QzY21sMFpTQmhablJsY2lCbGJtUW5LVHRjYmlBZ0x5OGdWRTlFVHpvZ1pHVm1aWElnWlhKeWIzSWdaWFpsYm5SeklHTnZibk5wYzNSbGJuUnNlU0JsZG1WeWVYZG9aWEpsTENCdWIzUWdhblZ6ZENCMGFHVWdZMkpjYmlBZ2MzUnlaV0Z0TG1WdGFYUW9KMlZ5Y205eUp5d2daWElwTzF4dUlDQndjbTlqWlhOekxtNWxlSFJVYVdOcktHWjFibU4wYVc5dUtDa2dlMXh1SUNBZ0lHTmlLR1Z5S1R0Y2JpQWdmU2s3WEc1OVhHNWNiaTh2SUVsbUlIZGxJR2RsZENCemIyMWxkR2hwYm1jZ2RHaGhkQ0JwY3lCdWIzUWdZU0JpZFdabVpYSXNJSE4wY21sdVp5d2diblZzYkN3Z2IzSWdkVzVrWldacGJtVmtMRnh1THk4Z1lXNWtJSGRsSjNKbElHNXZkQ0JwYmlCdlltcGxZM1JOYjJSbExDQjBhR1Z1SUhSb1lYUW5jeUJoYmlCbGNuSnZjaTVjYmk4dklFOTBhR1Z5ZDJselpTQnpkSEpsWVcwZ1kyaDFibXR6SUdGeVpTQmhiR3dnWTI5dWMybGtaWEpsWkNCMGJ5QmlaU0J2WmlCc1pXNW5kR2c5TVN3Z1lXNWtJSFJvWlZ4dUx5OGdkMkYwWlhKdFlYSnJjeUJrWlhSbGNtMXBibVVnYUc5M0lHMWhibmtnYjJKcVpXTjBjeUIwYnlCclpXVndJR2x1SUhSb1pTQmlkV1ptWlhJc0lISmhkR2hsY2lCMGFHRnVYRzR2THlCb2IzY2diV0Z1ZVNCaWVYUmxjeUJ2Y2lCamFHRnlZV04wWlhKekxseHVablZ1WTNScGIyNGdkbUZzYVdSRGFIVnVheWh6ZEhKbFlXMHNJSE4wWVhSbExDQmphSFZ1YXl3Z1kySXBJSHRjYmlBZ2RtRnlJSFpoYkdsa0lEMGdkSEoxWlR0Y2JpQWdhV1lnS0NGMWRHbHNMbWx6UW5WbVptVnlLR05vZFc1cktTQW1KbHh1SUNBZ0lDQWdJWFYwYVd3dWFYTlRkSEpwYm1jb1kyaDFibXNwSUNZbVhHNGdJQ0FnSUNBaGRYUnBiQzVwYzA1MWJHeFBjbFZ1WkdWbWFXNWxaQ2hqYUhWdWF5a2dKaVpjYmlBZ0lDQWdJQ0Z6ZEdGMFpTNXZZbXBsWTNSTmIyUmxLU0I3WEc0Z0lDQWdkbUZ5SUdWeUlEMGdibVYzSUZSNWNHVkZjbkp2Y2lnblNXNTJZV3hwWkNCdWIyNHRjM1J5YVc1bkwySjFabVpsY2lCamFIVnVheWNwTzF4dUlDQWdJSE4wY21WaGJTNWxiV2wwS0NkbGNuSnZjaWNzSUdWeUtUdGNiaUFnSUNCd2NtOWpaWE56TG01bGVIUlVhV05yS0daMWJtTjBhVzl1S0NrZ2UxeHVJQ0FnSUNBZ1kySW9aWElwTzF4dUlDQWdJSDBwTzF4dUlDQWdJSFpoYkdsa0lEMGdabUZzYzJVN1hHNGdJSDFjYmlBZ2NtVjBkWEp1SUhaaGJHbGtPMXh1ZlZ4dVhHNVhjbWwwWVdKc1pTNXdjbTkwYjNSNWNHVXVkM0pwZEdVZ1BTQm1kVzVqZEdsdmJpaGphSFZ1YXl3Z1pXNWpiMlJwYm1jc0lHTmlLU0I3WEc0Z0lIWmhjaUJ6ZEdGMFpTQTlJSFJvYVhNdVgzZHlhWFJoWW14bFUzUmhkR1U3WEc0Z0lIWmhjaUJ5WlhRZ1BTQm1ZV3h6WlR0Y2JseHVJQ0JwWmlBb2RYUnBiQzVwYzBaMWJtTjBhVzl1S0dWdVkyOWthVzVuS1NrZ2UxeHVJQ0FnSUdOaUlEMGdaVzVqYjJScGJtYzdYRzRnSUNBZ1pXNWpiMlJwYm1jZ1BTQnVkV3hzTzF4dUlDQjlYRzVjYmlBZ2FXWWdLSFYwYVd3dWFYTkNkV1ptWlhJb1kyaDFibXNwS1Z4dUlDQWdJR1Z1WTI5a2FXNW5JRDBnSjJKMVptWmxjaWM3WEc0Z0lHVnNjMlVnYVdZZ0tDRmxibU52WkdsdVp5bGNiaUFnSUNCbGJtTnZaR2x1WnlBOUlITjBZWFJsTG1SbFptRjFiSFJGYm1OdlpHbHVaenRjYmx4dUlDQnBaaUFvSVhWMGFXd3VhWE5HZFc1amRHbHZiaWhqWWlrcFhHNGdJQ0FnWTJJZ1BTQm1kVzVqZEdsdmJpZ3BJSHQ5TzF4dVhHNGdJR2xtSUNoemRHRjBaUzVsYm1SbFpDbGNiaUFnSUNCM2NtbDBaVUZtZEdWeVJXNWtLSFJvYVhNc0lITjBZWFJsTENCallpazdYRzRnSUdWc2MyVWdhV1lnS0haaGJHbGtRMmgxYm1zb2RHaHBjeXdnYzNSaGRHVXNJR05vZFc1ckxDQmpZaWtwSUh0Y2JpQWdJQ0J6ZEdGMFpTNXdaVzVrYVc1blkySXJLenRjYmlBZ0lDQnlaWFFnUFNCM2NtbDBaVTl5UW5WbVptVnlLSFJvYVhNc0lITjBZWFJsTENCamFIVnVheXdnWlc1amIyUnBibWNzSUdOaUtUdGNiaUFnZlZ4dVhHNGdJSEpsZEhWeWJpQnlaWFE3WEc1OU8xeHVYRzVYY21sMFlXSnNaUzV3Y205MGIzUjVjR1V1WTI5eWF5QTlJR1oxYm1OMGFXOXVLQ2tnZTF4dUlDQjJZWElnYzNSaGRHVWdQU0IwYUdsekxsOTNjbWwwWVdKc1pWTjBZWFJsTzF4dVhHNGdJSE4wWVhSbExtTnZjbXRsWkNzck8xeHVmVHRjYmx4dVYzSnBkR0ZpYkdVdWNISnZkRzkwZVhCbExuVnVZMjl5YXlBOUlHWjFibU4wYVc5dUtDa2dlMXh1SUNCMllYSWdjM1JoZEdVZ1BTQjBhR2x6TGw5M2NtbDBZV0pzWlZOMFlYUmxPMXh1WEc0Z0lHbG1JQ2h6ZEdGMFpTNWpiM0pyWldRcElIdGNiaUFnSUNCemRHRjBaUzVqYjNKclpXUXRMVHRjYmx4dUlDQWdJR2xtSUNnaGMzUmhkR1V1ZDNKcGRHbHVaeUFtSmx4dUlDQWdJQ0FnSUNBaGMzUmhkR1V1WTI5eWEyVmtJQ1ltWEc0Z0lDQWdJQ0FnSUNGemRHRjBaUzVtYVc1cGMyaGxaQ0FtSmx4dUlDQWdJQ0FnSUNBaGMzUmhkR1V1WW5WbVptVnlVSEp2WTJWemMybHVaeUFtSmx4dUlDQWdJQ0FnSUNCemRHRjBaUzVpZFdabVpYSXViR1Z1WjNSb0tWeHVJQ0FnSUNBZ1kyeGxZWEpDZFdabVpYSW9kR2hwY3l3Z2MzUmhkR1VwTzF4dUlDQjlYRzU5TzF4dVhHNW1kVzVqZEdsdmJpQmtaV052WkdWRGFIVnVheWh6ZEdGMFpTd2dZMmgxYm1zc0lHVnVZMjlrYVc1bktTQjdYRzRnSUdsbUlDZ2hjM1JoZEdVdWIySnFaV04wVFc5a1pTQW1KbHh1SUNBZ0lDQWdjM1JoZEdVdVpHVmpiMlJsVTNSeWFXNW5jeUFoUFQwZ1ptRnNjMlVnSmlaY2JpQWdJQ0FnSUhWMGFXd3VhWE5UZEhKcGJtY29ZMmgxYm1zcEtTQjdYRzRnSUNBZ1kyaDFibXNnUFNCdVpYY2dRblZtWm1WeUtHTm9kVzVyTENCbGJtTnZaR2x1WnlrN1hHNGdJSDFjYmlBZ2NtVjBkWEp1SUdOb2RXNXJPMXh1ZlZ4dVhHNHZMeUJwWmlCM1pTZHlaU0JoYkhKbFlXUjVJSGR5YVhScGJtY2djMjl0WlhSb2FXNW5MQ0IwYUdWdUlHcDFjM1FnY0hWMElIUm9hWE5jYmk4dklHbHVJSFJvWlNCeGRXVjFaU3dnWVc1a0lIZGhhWFFnYjNWeUlIUjFjbTR1SUNCUGRHaGxjbmRwYzJVc0lHTmhiR3dnWDNkeWFYUmxYRzR2THlCSlppQjNaU0J5WlhSMWNtNGdabUZzYzJVc0lIUm9aVzRnZDJVZ2JtVmxaQ0JoSUdSeVlXbHVJR1YyWlc1MExDQnpieUJ6WlhRZ2RHaGhkQ0JtYkdGbkxseHVablZ1WTNScGIyNGdkM0pwZEdWUGNrSjFabVpsY2loemRISmxZVzBzSUhOMFlYUmxMQ0JqYUhWdWF5d2daVzVqYjJScGJtY3NJR05pS1NCN1hHNGdJR05vZFc1cklEMGdaR1ZqYjJSbFEyaDFibXNvYzNSaGRHVXNJR05vZFc1ckxDQmxibU52WkdsdVp5azdYRzRnSUdsbUlDaDFkR2xzTG1selFuVm1abVZ5S0dOb2RXNXJLU2xjYmlBZ0lDQmxibU52WkdsdVp5QTlJQ2RpZFdabVpYSW5PMXh1SUNCMllYSWdiR1Z1SUQwZ2MzUmhkR1V1YjJKcVpXTjBUVzlrWlNBL0lERWdPaUJqYUhWdWF5NXNaVzVuZEdnN1hHNWNiaUFnYzNSaGRHVXViR1Z1WjNSb0lDczlJR3hsYmp0Y2JseHVJQ0IyWVhJZ2NtVjBJRDBnYzNSaGRHVXViR1Z1WjNSb0lEd2djM1JoZEdVdWFHbG5hRmRoZEdWeVRXRnlhenRjYmlBZ0x5OGdkMlVnYlhWemRDQmxibk4xY21VZ2RHaGhkQ0J3Y21WMmFXOTFjeUJ1WldWa1JISmhhVzRnZDJsc2JDQnViM1FnWW1VZ2NtVnpaWFFnZEc4Z1ptRnNjMlV1WEc0Z0lHbG1JQ2doY21WMEtWeHVJQ0FnSUhOMFlYUmxMbTVsWldSRWNtRnBiaUE5SUhSeWRXVTdYRzVjYmlBZ2FXWWdLSE4wWVhSbExuZHlhWFJwYm1jZ2ZId2djM1JoZEdVdVkyOXlhMlZrS1Z4dUlDQWdJSE4wWVhSbExtSjFabVpsY2k1d2RYTm9LRzVsZHlCWGNtbDBaVkpsY1NoamFIVnVheXdnWlc1amIyUnBibWNzSUdOaUtTazdYRzRnSUdWc2MyVmNiaUFnSUNCa2IxZHlhWFJsS0hOMGNtVmhiU3dnYzNSaGRHVXNJR1poYkhObExDQnNaVzRzSUdOb2RXNXJMQ0JsYm1OdlpHbHVaeXdnWTJJcE8xeHVYRzRnSUhKbGRIVnliaUJ5WlhRN1hHNTlYRzVjYm1aMWJtTjBhVzl1SUdSdlYzSnBkR1VvYzNSeVpXRnRMQ0J6ZEdGMFpTd2dkM0pwZEdWMkxDQnNaVzRzSUdOb2RXNXJMQ0JsYm1OdlpHbHVaeXdnWTJJcElIdGNiaUFnYzNSaGRHVXVkM0pwZEdWc1pXNGdQU0JzWlc0N1hHNGdJSE4wWVhSbExuZHlhWFJsWTJJZ1BTQmpZanRjYmlBZ2MzUmhkR1V1ZDNKcGRHbHVaeUE5SUhSeWRXVTdYRzRnSUhOMFlYUmxMbk41Ym1NZ1BTQjBjblZsTzF4dUlDQnBaaUFvZDNKcGRHVjJLVnh1SUNBZ0lITjBjbVZoYlM1ZmQzSnBkR1YyS0dOb2RXNXJMQ0J6ZEdGMFpTNXZibmR5YVhSbEtUdGNiaUFnWld4elpWeHVJQ0FnSUhOMGNtVmhiUzVmZDNKcGRHVW9ZMmgxYm1zc0lHVnVZMjlrYVc1bkxDQnpkR0YwWlM1dmJuZHlhWFJsS1R0Y2JpQWdjM1JoZEdVdWMzbHVZeUE5SUdaaGJITmxPMXh1ZlZ4dVhHNW1kVzVqZEdsdmJpQnZibmR5YVhSbFJYSnliM0lvYzNSeVpXRnRMQ0J6ZEdGMFpTd2djM2x1WXl3Z1pYSXNJR05pS1NCN1hHNGdJR2xtSUNoemVXNWpLVnh1SUNBZ0lIQnliMk5sYzNNdWJtVjRkRlJwWTJzb1puVnVZM1JwYjI0b0tTQjdYRzRnSUNBZ0lDQnpkR0YwWlM1d1pXNWthVzVuWTJJdExUdGNiaUFnSUNBZ0lHTmlLR1Z5S1R0Y2JpQWdJQ0I5S1R0Y2JpQWdaV3h6WlNCN1hHNGdJQ0FnYzNSaGRHVXVjR1Z1WkdsdVoyTmlMUzA3WEc0Z0lDQWdZMklvWlhJcE8xeHVJQ0I5WEc1Y2JpQWdjM1J5WldGdExsOTNjbWwwWVdKc1pWTjBZWFJsTG1WeWNtOXlSVzFwZEhSbFpDQTlJSFJ5ZFdVN1hHNGdJSE4wY21WaGJTNWxiV2wwS0NkbGNuSnZjaWNzSUdWeUtUdGNibjFjYmx4dVpuVnVZM1JwYjI0Z2IyNTNjbWwwWlZOMFlYUmxWWEJrWVhSbEtITjBZWFJsS1NCN1hHNGdJSE4wWVhSbExuZHlhWFJwYm1jZ1BTQm1ZV3h6WlR0Y2JpQWdjM1JoZEdVdWQzSnBkR1ZqWWlBOUlHNTFiR3c3WEc0Z0lITjBZWFJsTG14bGJtZDBhQ0F0UFNCemRHRjBaUzUzY21sMFpXeGxianRjYmlBZ2MzUmhkR1V1ZDNKcGRHVnNaVzRnUFNBd08xeHVmVnh1WEc1bWRXNWpkR2x2YmlCdmJuZHlhWFJsS0hOMGNtVmhiU3dnWlhJcElIdGNiaUFnZG1GeUlITjBZWFJsSUQwZ2MzUnlaV0Z0TGw5M2NtbDBZV0pzWlZOMFlYUmxPMXh1SUNCMllYSWdjM2x1WXlBOUlITjBZWFJsTG5ONWJtTTdYRzRnSUhaaGNpQmpZaUE5SUhOMFlYUmxMbmR5YVhSbFkySTdYRzVjYmlBZ2IyNTNjbWwwWlZOMFlYUmxWWEJrWVhSbEtITjBZWFJsS1R0Y2JseHVJQ0JwWmlBb1pYSXBYRzRnSUNBZ2IyNTNjbWwwWlVWeWNtOXlLSE4wY21WaGJTd2djM1JoZEdVc0lITjVibU1zSUdWeUxDQmpZaWs3WEc0Z0lHVnNjMlVnZTF4dUlDQWdJQzh2SUVOb1pXTnJJR2xtSUhkbEozSmxJR0ZqZEhWaGJHeDVJSEpsWVdSNUlIUnZJR1pwYm1semFDd2dZblYwSUdSdmJpZDBJR1Z0YVhRZ2VXVjBYRzRnSUNBZ2RtRnlJR1pwYm1semFHVmtJRDBnYm1WbFpFWnBibWx6YUNoemRISmxZVzBzSUhOMFlYUmxLVHRjYmx4dUlDQWdJR2xtSUNnaFptbHVhWE5vWldRZ0ppWmNiaUFnSUNBZ0lDQWdJWE4wWVhSbExtTnZjbXRsWkNBbUpseHVJQ0FnSUNBZ0lDQWhjM1JoZEdVdVluVm1abVZ5VUhKdlkyVnpjMmx1WnlBbUpseHVJQ0FnSUNBZ0lDQnpkR0YwWlM1aWRXWm1aWEl1YkdWdVozUm9LU0I3WEc0Z0lDQWdJQ0JqYkdWaGNrSjFabVpsY2loemRISmxZVzBzSUhOMFlYUmxLVHRjYmlBZ0lDQjlYRzVjYmlBZ0lDQnBaaUFvYzNsdVl5a2dlMXh1SUNBZ0lDQWdjSEp2WTJWemN5NXVaWGgwVkdsamF5aG1kVzVqZEdsdmJpZ3BJSHRjYmlBZ0lDQWdJQ0FnWVdaMFpYSlhjbWwwWlNoemRISmxZVzBzSUhOMFlYUmxMQ0JtYVc1cGMyaGxaQ3dnWTJJcE8xeHVJQ0FnSUNBZ2ZTazdYRzRnSUNBZ2ZTQmxiSE5sSUh0Y2JpQWdJQ0FnSUdGbWRHVnlWM0pwZEdVb2MzUnlaV0Z0TENCemRHRjBaU3dnWm1sdWFYTm9aV1FzSUdOaUtUdGNiaUFnSUNCOVhHNGdJSDFjYm4xY2JseHVablZ1WTNScGIyNGdZV1owWlhKWGNtbDBaU2h6ZEhKbFlXMHNJSE4wWVhSbExDQm1hVzVwYzJobFpDd2dZMklwSUh0Y2JpQWdhV1lnS0NGbWFXNXBjMmhsWkNsY2JpQWdJQ0J2Ym5keWFYUmxSSEpoYVc0b2MzUnlaV0Z0TENCemRHRjBaU2s3WEc0Z0lITjBZWFJsTG5CbGJtUnBibWRqWWkwdE8xeHVJQ0JqWWlncE8xeHVJQ0JtYVc1cGMyaE5ZWGxpWlNoemRISmxZVzBzSUhOMFlYUmxLVHRjYm4xY2JseHVMeThnVFhWemRDQm1iM0pqWlNCallXeHNZbUZqYXlCMGJ5QmlaU0JqWVd4c1pXUWdiMjRnYm1WNGRGUnBZMnNzSUhOdklIUm9ZWFFnZDJVZ1pHOXVKM1JjYmk4dklHVnRhWFFnSjJSeVlXbHVKeUJpWldadmNtVWdkR2hsSUhkeWFYUmxLQ2tnWTI5dWMzVnRaWElnWjJWMGN5QjBhR1VnSjJaaGJITmxKeUJ5WlhSMWNtNWNiaTh2SUhaaGJIVmxMQ0JoYm1RZ2FHRnpJR0VnWTJoaGJtTmxJSFJ2SUdGMGRHRmphQ0JoSUNka2NtRnBiaWNnYkdsemRHVnVaWEl1WEc1bWRXNWpkR2x2YmlCdmJuZHlhWFJsUkhKaGFXNG9jM1J5WldGdExDQnpkR0YwWlNrZ2UxeHVJQ0JwWmlBb2MzUmhkR1V1YkdWdVozUm9JRDA5UFNBd0lDWW1JSE4wWVhSbExtNWxaV1JFY21GcGJpa2dlMXh1SUNBZ0lITjBZWFJsTG01bFpXUkVjbUZwYmlBOUlHWmhiSE5sTzF4dUlDQWdJSE4wY21WaGJTNWxiV2wwS0Nka2NtRnBiaWNwTzF4dUlDQjlYRzU5WEc1Y2JseHVMeThnYVdZZ2RHaGxjbVVuY3lCemIyMWxkR2hwYm1jZ2FXNGdkR2hsSUdKMVptWmxjaUIzWVdsMGFXNW5MQ0IwYUdWdUlIQnliMk5sYzNNZ2FYUmNibVoxYm1OMGFXOXVJR05zWldGeVFuVm1abVZ5S0hOMGNtVmhiU3dnYzNSaGRHVXBJSHRjYmlBZ2MzUmhkR1V1WW5WbVptVnlVSEp2WTJWemMybHVaeUE5SUhSeWRXVTdYRzVjYmlBZ2FXWWdLSE4wY21WaGJTNWZkM0pwZEdWMklDWW1JSE4wWVhSbExtSjFabVpsY2k1c1pXNW5kR2dnUGlBeEtTQjdYRzRnSUNBZ0x5OGdSbUZ6ZENCallYTmxMQ0IzY21sMFpTQmxkbVZ5ZVhSb2FXNW5JSFZ6YVc1bklGOTNjbWwwWlhZb0tWeHVJQ0FnSUhaaGNpQmpZbk1nUFNCYlhUdGNiaUFnSUNCbWIzSWdLSFpoY2lCaklEMGdNRHNnWXlBOElITjBZWFJsTG1KMVptWmxjaTVzWlc1bmRHZzdJR01yS3lsY2JpQWdJQ0FnSUdOaWN5NXdkWE5vS0hOMFlYUmxMbUoxWm1abGNsdGpYUzVqWVd4c1ltRmpheWs3WEc1Y2JpQWdJQ0F2THlCamIzVnVkQ0IwYUdVZ2IyNWxJSGRsSUdGeVpTQmhaR1JwYm1jc0lHRnpJSGRsYkd3dVhHNGdJQ0FnTHk4Z1ZFOUVUeWhwYzJGaFkzTXBJR05zWldGdUlIUm9hWE1nZFhCY2JpQWdJQ0J6ZEdGMFpTNXdaVzVrYVc1blkySXJLenRjYmlBZ0lDQmtiMWR5YVhSbEtITjBjbVZoYlN3Z2MzUmhkR1VzSUhSeWRXVXNJSE4wWVhSbExteGxibWQwYUN3Z2MzUmhkR1V1WW5WbVptVnlMQ0FuSnl3Z1puVnVZM1JwYjI0b1pYSnlLU0I3WEc0Z0lDQWdJQ0JtYjNJZ0tIWmhjaUJwSUQwZ01Ec2dhU0E4SUdOaWN5NXNaVzVuZEdnN0lHa3JLeWtnZTF4dUlDQWdJQ0FnSUNCemRHRjBaUzV3Wlc1a2FXNW5ZMkl0TFR0Y2JpQWdJQ0FnSUNBZ1kySnpXMmxkS0dWeWNpazdYRzRnSUNBZ0lDQjlYRzRnSUNBZ2ZTazdYRzVjYmlBZ0lDQXZMeUJEYkdWaGNpQmlkV1ptWlhKY2JpQWdJQ0J6ZEdGMFpTNWlkV1ptWlhJZ1BTQmJYVHRjYmlBZ2ZTQmxiSE5sSUh0Y2JpQWdJQ0F2THlCVGJHOTNJR05oYzJVc0lIZHlhWFJsSUdOb2RXNXJjeUJ2Ym1VdFlua3RiMjVsWEc0Z0lDQWdabTl5SUNoMllYSWdZeUE5SURBN0lHTWdQQ0J6ZEdGMFpTNWlkV1ptWlhJdWJHVnVaM1JvT3lCakt5c3BJSHRjYmlBZ0lDQWdJSFpoY2lCbGJuUnllU0E5SUhOMFlYUmxMbUoxWm1abGNsdGpYVHRjYmlBZ0lDQWdJSFpoY2lCamFIVnVheUE5SUdWdWRISjVMbU5vZFc1ck8xeHVJQ0FnSUNBZ2RtRnlJR1Z1WTI5a2FXNW5JRDBnWlc1MGNua3VaVzVqYjJScGJtYzdYRzRnSUNBZ0lDQjJZWElnWTJJZ1BTQmxiblJ5ZVM1allXeHNZbUZqYXp0Y2JpQWdJQ0FnSUhaaGNpQnNaVzRnUFNCemRHRjBaUzV2WW1wbFkzUk5iMlJsSUQ4Z01TQTZJR05vZFc1ckxteGxibWQwYUR0Y2JseHVJQ0FnSUNBZ1pHOVhjbWwwWlNoemRISmxZVzBzSUhOMFlYUmxMQ0JtWVd4elpTd2diR1Z1TENCamFIVnVheXdnWlc1amIyUnBibWNzSUdOaUtUdGNibHh1SUNBZ0lDQWdMeThnYVdZZ2QyVWdaR2xrYmlkMElHTmhiR3dnZEdobElHOXVkM0pwZEdVZ2FXMXRaV1JwWVhSbGJIa3NJSFJvWlc1Y2JpQWdJQ0FnSUM4dklHbDBJRzFsWVc1eklIUm9ZWFFnZDJVZ2JtVmxaQ0IwYnlCM1lXbDBJSFZ1ZEdsc0lHbDBJR1J2WlhNdVhHNGdJQ0FnSUNBdkx5QmhiSE52TENCMGFHRjBJRzFsWVc1eklIUm9ZWFFnZEdobElHTm9kVzVySUdGdVpDQmpZaUJoY21VZ1kzVnljbVZ1ZEd4NVhHNGdJQ0FnSUNBdkx5QmlaV2x1WnlCd2NtOWpaWE56WldRc0lITnZJRzF2ZG1VZ2RHaGxJR0oxWm1abGNpQmpiM1Z1ZEdWeUlIQmhjM1FnZEdobGJTNWNiaUFnSUNBZ0lHbG1JQ2h6ZEdGMFpTNTNjbWwwYVc1bktTQjdYRzRnSUNBZ0lDQWdJR01yS3p0Y2JpQWdJQ0FnSUNBZ1luSmxZV3M3WEc0Z0lDQWdJQ0I5WEc0Z0lDQWdmVnh1WEc0Z0lDQWdhV1lnS0dNZ1BDQnpkR0YwWlM1aWRXWm1aWEl1YkdWdVozUm9LVnh1SUNBZ0lDQWdjM1JoZEdVdVluVm1abVZ5SUQwZ2MzUmhkR1V1WW5WbVptVnlMbk5zYVdObEtHTXBPMXh1SUNBZ0lHVnNjMlZjYmlBZ0lDQWdJSE4wWVhSbExtSjFabVpsY2k1c1pXNW5kR2dnUFNBd08xeHVJQ0I5WEc1Y2JpQWdjM1JoZEdVdVluVm1abVZ5VUhKdlkyVnpjMmx1WnlBOUlHWmhiSE5sTzF4dWZWeHVYRzVYY21sMFlXSnNaUzV3Y205MGIzUjVjR1V1WDNkeWFYUmxJRDBnWm5WdVkzUnBiMjRvWTJoMWJtc3NJR1Z1WTI5a2FXNW5MQ0JqWWlrZ2UxeHVJQ0JqWWlodVpYY2dSWEp5YjNJb0oyNXZkQ0JwYlhCc1pXMWxiblJsWkNjcEtUdGNibHh1ZlR0Y2JseHVWM0pwZEdGaWJHVXVjSEp2ZEc5MGVYQmxMbDkzY21sMFpYWWdQU0J1ZFd4c08xeHVYRzVYY21sMFlXSnNaUzV3Y205MGIzUjVjR1V1Wlc1a0lEMGdablZ1WTNScGIyNG9ZMmgxYm1zc0lHVnVZMjlrYVc1bkxDQmpZaWtnZTF4dUlDQjJZWElnYzNSaGRHVWdQU0IwYUdsekxsOTNjbWwwWVdKc1pWTjBZWFJsTzF4dVhHNGdJR2xtSUNoMWRHbHNMbWx6Um5WdVkzUnBiMjRvWTJoMWJtc3BLU0I3WEc0Z0lDQWdZMklnUFNCamFIVnVhenRjYmlBZ0lDQmphSFZ1YXlBOUlHNTFiR3c3WEc0Z0lDQWdaVzVqYjJScGJtY2dQU0J1ZFd4c08xeHVJQ0I5SUdWc2MyVWdhV1lnS0hWMGFXd3VhWE5HZFc1amRHbHZiaWhsYm1OdlpHbHVaeWtwSUh0Y2JpQWdJQ0JqWWlBOUlHVnVZMjlrYVc1bk8xeHVJQ0FnSUdWdVkyOWthVzVuSUQwZ2JuVnNiRHRjYmlBZ2ZWeHVYRzRnSUdsbUlDZ2hkWFJwYkM1cGMwNTFiR3hQY2xWdVpHVm1hVzVsWkNoamFIVnVheWtwWEc0Z0lDQWdkR2hwY3k1M2NtbDBaU2hqYUhWdWF5d2daVzVqYjJScGJtY3BPMXh1WEc0Z0lDOHZJQzVsYm1Rb0tTQm1kV3hzZVNCMWJtTnZjbXR6WEc0Z0lHbG1JQ2h6ZEdGMFpTNWpiM0pyWldRcElIdGNiaUFnSUNCemRHRjBaUzVqYjNKclpXUWdQU0F4TzF4dUlDQWdJSFJvYVhNdWRXNWpiM0pyS0NrN1hHNGdJSDFjYmx4dUlDQXZMeUJwWjI1dmNtVWdkVzV1WldObGMzTmhjbmtnWlc1a0tDa2dZMkZzYkhNdVhHNGdJR2xtSUNnaGMzUmhkR1V1Wlc1a2FXNW5JQ1ltSUNGemRHRjBaUzVtYVc1cGMyaGxaQ2xjYmlBZ0lDQmxibVJYY21sMFlXSnNaU2gwYUdsekxDQnpkR0YwWlN3Z1kySXBPMXh1ZlR0Y2JseHVYRzVtZFc1amRHbHZiaUJ1WldWa1JtbHVhWE5vS0hOMGNtVmhiU3dnYzNSaGRHVXBJSHRjYmlBZ2NtVjBkWEp1SUNoemRHRjBaUzVsYm1ScGJtY2dKaVpjYmlBZ0lDQWdJQ0FnSUNCemRHRjBaUzVzWlc1bmRHZ2dQVDA5SURBZ0ppWmNiaUFnSUNBZ0lDQWdJQ0FoYzNSaGRHVXVabWx1YVhOb1pXUWdKaVpjYmlBZ0lDQWdJQ0FnSUNBaGMzUmhkR1V1ZDNKcGRHbHVaeWs3WEc1OVhHNWNibVoxYm1OMGFXOXVJSEJ5WldacGJtbHphQ2h6ZEhKbFlXMHNJSE4wWVhSbEtTQjdYRzRnSUdsbUlDZ2hjM1JoZEdVdWNISmxabWx1YVhOb1pXUXBJSHRjYmlBZ0lDQnpkR0YwWlM1d2NtVm1hVzVwYzJobFpDQTlJSFJ5ZFdVN1hHNGdJQ0FnYzNSeVpXRnRMbVZ0YVhRb0ozQnlaV1pwYm1semFDY3BPMXh1SUNCOVhHNTlYRzVjYm1aMWJtTjBhVzl1SUdacGJtbHphRTFoZVdKbEtITjBjbVZoYlN3Z2MzUmhkR1VwSUh0Y2JpQWdkbUZ5SUc1bFpXUWdQU0J1WldWa1JtbHVhWE5vS0hOMGNtVmhiU3dnYzNSaGRHVXBPMXh1SUNCcFppQW9ibVZsWkNrZ2UxeHVJQ0FnSUdsbUlDaHpkR0YwWlM1d1pXNWthVzVuWTJJZ1BUMDlJREFwSUh0Y2JpQWdJQ0FnSUhCeVpXWnBibWx6YUNoemRISmxZVzBzSUhOMFlYUmxLVHRjYmlBZ0lDQWdJSE4wWVhSbExtWnBibWx6YUdWa0lEMGdkSEoxWlR0Y2JpQWdJQ0FnSUhOMGNtVmhiUzVsYldsMEtDZG1hVzVwYzJnbktUdGNiaUFnSUNCOUlHVnNjMlZjYmlBZ0lDQWdJSEJ5WldacGJtbHphQ2h6ZEhKbFlXMHNJSE4wWVhSbEtUdGNiaUFnZlZ4dUlDQnlaWFIxY200Z2JtVmxaRHRjYm4xY2JseHVablZ1WTNScGIyNGdaVzVrVjNKcGRHRmliR1VvYzNSeVpXRnRMQ0J6ZEdGMFpTd2dZMklwSUh0Y2JpQWdjM1JoZEdVdVpXNWthVzVuSUQwZ2RISjFaVHRjYmlBZ1ptbHVhWE5vVFdGNVltVW9jM1J5WldGdExDQnpkR0YwWlNrN1hHNGdJR2xtSUNoallpa2dlMXh1SUNBZ0lHbG1JQ2h6ZEdGMFpTNW1hVzVwYzJobFpDbGNiaUFnSUNBZ0lIQnliMk5sYzNNdWJtVjRkRlJwWTJzb1kySXBPMXh1SUNBZ0lHVnNjMlZjYmlBZ0lDQWdJSE4wY21WaGJTNXZibU5sS0NkbWFXNXBjMmduTENCallpazdYRzRnSUgxY2JpQWdjM1JoZEdVdVpXNWtaV1FnUFNCMGNuVmxPMXh1ZlZ4dUlsMTkiLCIoZnVuY3Rpb24gKEJ1ZmZlcil7XG4vLyBDb3B5cmlnaHQgSm95ZW50LCBJbmMuIGFuZCBvdGhlciBOb2RlIGNvbnRyaWJ1dG9ycy5cbi8vXG4vLyBQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcgYVxuLy8gY29weSBvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZVxuLy8gXCJTb2Z0d2FyZVwiKSwgdG8gZGVhbCBpbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nXG4vLyB3aXRob3V0IGxpbWl0YXRpb24gdGhlIHJpZ2h0cyB0byB1c2UsIGNvcHksIG1vZGlmeSwgbWVyZ2UsIHB1Ymxpc2gsXG4vLyBkaXN0cmlidXRlLCBzdWJsaWNlbnNlLCBhbmQvb3Igc2VsbCBjb3BpZXMgb2YgdGhlIFNvZnR3YXJlLCBhbmQgdG8gcGVybWl0XG4vLyBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzIGZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGVcbi8vIGZvbGxvd2luZyBjb25kaXRpb25zOlxuLy9cbi8vIFRoZSBhYm92ZSBjb3B5cmlnaHQgbm90aWNlIGFuZCB0aGlzIHBlcm1pc3Npb24gbm90aWNlIHNoYWxsIGJlIGluY2x1ZGVkXG4vLyBpbiBhbGwgY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS5cbi8vXG4vLyBUSEUgU09GVFdBUkUgSVMgUFJPVklERUQgXCJBUyBJU1wiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTXG4vLyBPUiBJTVBMSUVELCBJTkNMVURJTkcgQlVUIE5PVCBMSU1JVEVEIFRPIFRIRSBXQVJSQU5USUVTIE9GXG4vLyBNRVJDSEFOVEFCSUxJVFksIEZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFORCBOT05JTkZSSU5HRU1FTlQuIElOXG4vLyBOTyBFVkVOVCBTSEFMTCBUSEUgQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSxcbi8vIERBTUFHRVMgT1IgT1RIRVIgTElBQklMSVRZLCBXSEVUSEVSIElOIEFOIEFDVElPTiBPRiBDT05UUkFDVCwgVE9SVCBPUlxuLy8gT1RIRVJXSVNFLCBBUklTSU5HIEZST00sIE9VVCBPRiBPUiBJTiBDT05ORUNUSU9OIFdJVEggVEhFIFNPRlRXQVJFIE9SIFRIRVxuLy8gVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRSBTT0ZUV0FSRS5cblxuLy8gTk9URTogVGhlc2UgdHlwZSBjaGVja2luZyBmdW5jdGlvbnMgaW50ZW50aW9uYWxseSBkb24ndCB1c2UgYGluc3RhbmNlb2ZgXG4vLyBiZWNhdXNlIGl0IGlzIGZyYWdpbGUgYW5kIGNhbiBiZSBlYXNpbHkgZmFrZWQgd2l0aCBgT2JqZWN0LmNyZWF0ZSgpYC5cblxuZnVuY3Rpb24gaXNBcnJheShhcmcpIHtcbiAgaWYgKEFycmF5LmlzQXJyYXkpIHtcbiAgICByZXR1cm4gQXJyYXkuaXNBcnJheShhcmcpO1xuICB9XG4gIHJldHVybiBvYmplY3RUb1N0cmluZyhhcmcpID09PSAnW29iamVjdCBBcnJheV0nO1xufVxuZXhwb3J0cy5pc0FycmF5ID0gaXNBcnJheTtcblxuZnVuY3Rpb24gaXNCb29sZWFuKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ2Jvb2xlYW4nO1xufVxuZXhwb3J0cy5pc0Jvb2xlYW4gPSBpc0Jvb2xlYW47XG5cbmZ1bmN0aW9uIGlzTnVsbChhcmcpIHtcbiAgcmV0dXJuIGFyZyA9PT0gbnVsbDtcbn1cbmV4cG9ydHMuaXNOdWxsID0gaXNOdWxsO1xuXG5mdW5jdGlvbiBpc051bGxPclVuZGVmaW5lZChhcmcpIHtcbiAgcmV0dXJuIGFyZyA9PSBudWxsO1xufVxuZXhwb3J0cy5pc051bGxPclVuZGVmaW5lZCA9IGlzTnVsbE9yVW5kZWZpbmVkO1xuXG5mdW5jdGlvbiBpc051bWJlcihhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09ICdudW1iZXInO1xufVxuZXhwb3J0cy5pc051bWJlciA9IGlzTnVtYmVyO1xuXG5mdW5jdGlvbiBpc1N0cmluZyhhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09ICdzdHJpbmcnO1xufVxuZXhwb3J0cy5pc1N0cmluZyA9IGlzU3RyaW5nO1xuXG5mdW5jdGlvbiBpc1N5bWJvbChhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09ICdzeW1ib2wnO1xufVxuZXhwb3J0cy5pc1N5bWJvbCA9IGlzU3ltYm9sO1xuXG5mdW5jdGlvbiBpc1VuZGVmaW5lZChhcmcpIHtcbiAgcmV0dXJuIGFyZyA9PT0gdm9pZCAwO1xufVxuZXhwb3J0cy5pc1VuZGVmaW5lZCA9IGlzVW5kZWZpbmVkO1xuXG5mdW5jdGlvbiBpc1JlZ0V4cChyZSkge1xuICByZXR1cm4gb2JqZWN0VG9TdHJpbmcocmUpID09PSAnW29iamVjdCBSZWdFeHBdJztcbn1cbmV4cG9ydHMuaXNSZWdFeHAgPSBpc1JlZ0V4cDtcblxuZnVuY3Rpb24gaXNPYmplY3QoYXJnKSB7XG4gIHJldHVybiB0eXBlb2YgYXJnID09PSAnb2JqZWN0JyAmJiBhcmcgIT09IG51bGw7XG59XG5leHBvcnRzLmlzT2JqZWN0ID0gaXNPYmplY3Q7XG5cbmZ1bmN0aW9uIGlzRGF0ZShkKSB7XG4gIHJldHVybiBvYmplY3RUb1N0cmluZyhkKSA9PT0gJ1tvYmplY3QgRGF0ZV0nO1xufVxuZXhwb3J0cy5pc0RhdGUgPSBpc0RhdGU7XG5cbmZ1bmN0aW9uIGlzRXJyb3IoZSkge1xuICByZXR1cm4gKG9iamVjdFRvU3RyaW5nKGUpID09PSAnW29iamVjdCBFcnJvcl0nIHx8IGUgaW5zdGFuY2VvZiBFcnJvcik7XG59XG5leHBvcnRzLmlzRXJyb3IgPSBpc0Vycm9yO1xuXG5mdW5jdGlvbiBpc0Z1bmN0aW9uKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ2Z1bmN0aW9uJztcbn1cbmV4cG9ydHMuaXNGdW5jdGlvbiA9IGlzRnVuY3Rpb247XG5cbmZ1bmN0aW9uIGlzUHJpbWl0aXZlKGFyZykge1xuICByZXR1cm4gYXJnID09PSBudWxsIHx8XG4gICAgICAgICB0eXBlb2YgYXJnID09PSAnYm9vbGVhbicgfHxcbiAgICAgICAgIHR5cGVvZiBhcmcgPT09ICdudW1iZXInIHx8XG4gICAgICAgICB0eXBlb2YgYXJnID09PSAnc3RyaW5nJyB8fFxuICAgICAgICAgdHlwZW9mIGFyZyA9PT0gJ3N5bWJvbCcgfHwgIC8vIEVTNiBzeW1ib2xcbiAgICAgICAgIHR5cGVvZiBhcmcgPT09ICd1bmRlZmluZWQnO1xufVxuZXhwb3J0cy5pc1ByaW1pdGl2ZSA9IGlzUHJpbWl0aXZlO1xuXG5leHBvcnRzLmlzQnVmZmVyID0gQnVmZmVyLmlzQnVmZmVyO1xuXG5mdW5jdGlvbiBvYmplY3RUb1N0cmluZyhvKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwobyk7XG59XG5cbn0pLmNhbGwodGhpcyx7XCJpc0J1ZmZlclwiOnJlcXVpcmUoXCIuLi8uLi8uLi8uLi9pbnNlcnQtbW9kdWxlLWdsb2JhbHMvbm9kZV9tb2R1bGVzL2lzLWJ1ZmZlci9pbmRleC5qc1wiKX0pXG4vLyMgc291cmNlTWFwcGluZ1VSTD1kYXRhOmFwcGxpY2F0aW9uL2pzb247Y2hhcnNldDp1dGYtODtiYXNlNjQsZXlKMlpYSnphVzl1SWpvekxDSnpiM1Z5WTJWeklqcGJJbTV2WkdWZmJXOWtkV3hsY3k5aWNtOTNjMlZ5YVdaNUwyNXZaR1ZmYlc5a2RXeGxjeTl5WldGa1lXSnNaUzF6ZEhKbFlXMHZibTlrWlY5dGIyUjFiR1Z6TDJOdmNtVXRkWFJwYkMxcGN5OXNhV0l2ZFhScGJDNXFjeUpkTENKdVlXMWxjeUk2VzEwc0ltMWhjSEJwYm1keklqb2lPMEZCUVVFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJJaXdpWm1sc1pTSTZJbWRsYm1WeVlYUmxaQzVxY3lJc0luTnZkWEpqWlZKdmIzUWlPaUlpTENKemIzVnlZMlZ6UTI5dWRHVnVkQ0k2V3lJdkx5QkRiM0I1Y21sbmFIUWdTbTk1Wlc1MExDQkpibU11SUdGdVpDQnZkR2hsY2lCT2IyUmxJR052Ym5SeWFXSjFkRzl5Y3k1Y2JpOHZYRzR2THlCUVpYSnRhWE56YVc5dUlHbHpJR2hsY21WaWVTQm5jbUZ1ZEdWa0xDQm1jbVZsSUc5bUlHTm9ZWEpuWlN3Z2RHOGdZVzU1SUhCbGNuTnZiaUJ2WW5SaGFXNXBibWNnWVZ4dUx5OGdZMjl3ZVNCdlppQjBhR2x6SUhOdlpuUjNZWEpsSUdGdVpDQmhjM052WTJsaGRHVmtJR1J2WTNWdFpXNTBZWFJwYjI0Z1ptbHNaWE1nS0hSb1pWeHVMeThnWENKVGIyWjBkMkZ5WlZ3aUtTd2dkRzhnWkdWaGJDQnBiaUIwYUdVZ1UyOW1kSGRoY21VZ2QybDBhRzkxZENCeVpYTjBjbWxqZEdsdmJpd2dhVzVqYkhWa2FXNW5YRzR2THlCM2FYUm9iM1YwSUd4cGJXbDBZWFJwYjI0Z2RHaGxJSEpwWjJoMGN5QjBieUIxYzJVc0lHTnZjSGtzSUcxdlpHbG1lU3dnYldWeVoyVXNJSEIxWW14cGMyZ3NYRzR2THlCa2FYTjBjbWxpZFhSbExDQnpkV0pzYVdObGJuTmxMQ0JoYm1RdmIzSWdjMlZzYkNCamIzQnBaWE1nYjJZZ2RHaGxJRk52Wm5SM1lYSmxMQ0JoYm1RZ2RHOGdjR1Z5YldsMFhHNHZMeUJ3WlhKemIyNXpJSFJ2SUhkb2IyMGdkR2hsSUZOdlpuUjNZWEpsSUdseklHWjFjbTVwYzJobFpDQjBieUJrYnlCemJ5d2djM1ZpYW1WamRDQjBieUIwYUdWY2JpOHZJR1p2Ykd4dmQybHVaeUJqYjI1a2FYUnBiMjV6T2x4dUx5OWNiaTh2SUZSb1pTQmhZbTkyWlNCamIzQjVjbWxuYUhRZ2JtOTBhV05sSUdGdVpDQjBhR2x6SUhCbGNtMXBjM05wYjI0Z2JtOTBhV05sSUhOb1lXeHNJR0psSUdsdVkyeDFaR1ZrWEc0dkx5QnBiaUJoYkd3Z1kyOXdhV1Z6SUc5eUlITjFZbk4wWVc1MGFXRnNJSEJ2Y25ScGIyNXpJRzltSUhSb1pTQlRiMlowZDJGeVpTNWNiaTh2WEc0dkx5QlVTRVVnVTA5R1ZGZEJVa1VnU1ZNZ1VGSlBWa2xFUlVRZ1hDSkJVeUJKVTF3aUxDQlhTVlJJVDFWVUlGZEJVbEpCVGxSWklFOUdJRUZPV1NCTFNVNUVMQ0JGV0ZCU1JWTlRYRzR2THlCUFVpQkpUVkJNU1VWRUxDQkpUa05NVlVSSlRrY2dRbFZVSUU1UFZDQk1TVTFKVkVWRUlGUlBJRlJJUlNCWFFWSlNRVTVVU1VWVElFOUdYRzR2THlCTlJWSkRTRUZPVkVGQ1NVeEpWRmtzSUVaSlZFNUZVMU1nUms5U0lFRWdVRUZTVkVsRFZVeEJVaUJRVlZKUVQxTkZJRUZPUkNCT1QwNUpUa1pTU1U1SFJVMUZUbFF1SUVsT1hHNHZMeUJPVHlCRlZrVk9WQ0JUU0VGTVRDQlVTRVVnUVZWVVNFOVNVeUJQVWlCRFQxQlpVa2xIU0ZRZ1NFOU1SRVZTVXlCQ1JTQk1TVUZDVEVVZ1JrOVNJRUZPV1NCRFRFRkpUU3hjYmk4dklFUkJUVUZIUlZNZ1QxSWdUMVJJUlZJZ1RFbEJRa2xNU1ZSWkxDQlhTRVZVU0VWU0lFbE9JRUZPSUVGRFZFbFBUaUJQUmlCRFQwNVVVa0ZEVkN3Z1ZFOVNWQ0JQVWx4dUx5OGdUMVJJUlZKWFNWTkZMQ0JCVWtsVFNVNUhJRVpTVDAwc0lFOVZWQ0JQUmlCUFVpQkpUaUJEVDA1T1JVTlVTVTlPSUZkSlZFZ2dWRWhGSUZOUFJsUlhRVkpGSUU5U0lGUklSVnh1THk4Z1ZWTkZJRTlTSUU5VVNFVlNJRVJGUVV4SlRrZFRJRWxPSUZSSVJTQlRUMFpVVjBGU1JTNWNibHh1THk4Z1RrOVVSVG9nVkdobGMyVWdkSGx3WlNCamFHVmphMmx1WnlCbWRXNWpkR2x2Ym5NZ2FXNTBaVzUwYVc5dVlXeHNlU0JrYjI0bmRDQjFjMlVnWUdsdWMzUmhibU5sYjJaZ1hHNHZMeUJpWldOaGRYTmxJR2wwSUdseklHWnlZV2RwYkdVZ1lXNWtJR05oYmlCaVpTQmxZWE5wYkhrZ1ptRnJaV1FnZDJsMGFDQmdUMkpxWldOMExtTnlaV0YwWlNncFlDNWNibHh1Wm5WdVkzUnBiMjRnYVhOQmNuSmhlU2hoY21jcElIdGNiaUFnYVdZZ0tFRnljbUY1TG1selFYSnlZWGtwSUh0Y2JpQWdJQ0J5WlhSMWNtNGdRWEp5WVhrdWFYTkJjbkpoZVNoaGNtY3BPMXh1SUNCOVhHNGdJSEpsZEhWeWJpQnZZbXBsWTNSVWIxTjBjbWx1WnloaGNtY3BJRDA5UFNBblcyOWlhbVZqZENCQmNuSmhlVjBuTzF4dWZWeHVaWGh3YjNKMGN5NXBjMEZ5Y21GNUlEMGdhWE5CY25KaGVUdGNibHh1Wm5WdVkzUnBiMjRnYVhOQ2IyOXNaV0Z1S0dGeVp5a2dlMXh1SUNCeVpYUjFjbTRnZEhsd1pXOW1JR0Z5WnlBOVBUMGdKMkp2YjJ4bFlXNG5PMXh1ZlZ4dVpYaHdiM0owY3k1cGMwSnZiMnhsWVc0Z1BTQnBjMEp2YjJ4bFlXNDdYRzVjYm1aMWJtTjBhVzl1SUdselRuVnNiQ2hoY21jcElIdGNiaUFnY21WMGRYSnVJR0Z5WnlBOVBUMGdiblZzYkR0Y2JuMWNibVY0Y0c5eWRITXVhWE5PZFd4c0lEMGdhWE5PZFd4c08xeHVYRzVtZFc1amRHbHZiaUJwYzA1MWJHeFBjbFZ1WkdWbWFXNWxaQ2hoY21jcElIdGNiaUFnY21WMGRYSnVJR0Z5WnlBOVBTQnVkV3hzTzF4dWZWeHVaWGh3YjNKMGN5NXBjMDUxYkd4UGNsVnVaR1ZtYVc1bFpDQTlJR2x6VG5Wc2JFOXlWVzVrWldacGJtVmtPMXh1WEc1bWRXNWpkR2x2YmlCcGMwNTFiV0psY2loaGNtY3BJSHRjYmlBZ2NtVjBkWEp1SUhSNWNHVnZaaUJoY21jZ1BUMDlJQ2R1ZFcxaVpYSW5PMXh1ZlZ4dVpYaHdiM0owY3k1cGMwNTFiV0psY2lBOUlHbHpUblZ0WW1WeU8xeHVYRzVtZFc1amRHbHZiaUJwYzFOMGNtbHVaeWhoY21jcElIdGNiaUFnY21WMGRYSnVJSFI1Y0dWdlppQmhjbWNnUFQwOUlDZHpkSEpwYm1jbk8xeHVmVnh1Wlhod2IzSjBjeTVwYzFOMGNtbHVaeUE5SUdselUzUnlhVzVuTzF4dVhHNW1kVzVqZEdsdmJpQnBjMU41YldKdmJDaGhjbWNwSUh0Y2JpQWdjbVYwZFhKdUlIUjVjR1Z2WmlCaGNtY2dQVDA5SUNkemVXMWliMnduTzF4dWZWeHVaWGh3YjNKMGN5NXBjMU41YldKdmJDQTlJR2x6VTNsdFltOXNPMXh1WEc1bWRXNWpkR2x2YmlCcGMxVnVaR1ZtYVc1bFpDaGhjbWNwSUh0Y2JpQWdjbVYwZFhKdUlHRnlaeUE5UFQwZ2RtOXBaQ0F3TzF4dWZWeHVaWGh3YjNKMGN5NXBjMVZ1WkdWbWFXNWxaQ0E5SUdselZXNWtaV1pwYm1Wa08xeHVYRzVtZFc1amRHbHZiaUJwYzFKbFowVjRjQ2h5WlNrZ2UxeHVJQ0J5WlhSMWNtNGdiMkpxWldOMFZHOVRkSEpwYm1jb2NtVXBJRDA5UFNBblcyOWlhbVZqZENCU1pXZEZlSEJkSnp0Y2JuMWNibVY0Y0c5eWRITXVhWE5TWldkRmVIQWdQU0JwYzFKbFowVjRjRHRjYmx4dVpuVnVZM1JwYjI0Z2FYTlBZbXBsWTNRb1lYSm5LU0I3WEc0Z0lISmxkSFZ5YmlCMGVYQmxiMllnWVhKbklEMDlQU0FuYjJKcVpXTjBKeUFtSmlCaGNtY2dJVDA5SUc1MWJHdzdYRzU5WEc1bGVIQnZjblJ6TG1selQySnFaV04wSUQwZ2FYTlBZbXBsWTNRN1hHNWNibVoxYm1OMGFXOXVJR2x6UkdGMFpTaGtLU0I3WEc0Z0lISmxkSFZ5YmlCdlltcGxZM1JVYjFOMGNtbHVaeWhrS1NBOVBUMGdKMXR2WW1wbFkzUWdSR0YwWlYwbk8xeHVmVnh1Wlhod2IzSjBjeTVwYzBSaGRHVWdQU0JwYzBSaGRHVTdYRzVjYm1aMWJtTjBhVzl1SUdselJYSnliM0lvWlNrZ2UxeHVJQ0J5WlhSMWNtNGdLRzlpYW1WamRGUnZVM1J5YVc1bktHVXBJRDA5UFNBblcyOWlhbVZqZENCRmNuSnZjbDBuSUh4OElHVWdhVzV6ZEdGdVkyVnZaaUJGY25KdmNpazdYRzU5WEc1bGVIQnZjblJ6TG1selJYSnliM0lnUFNCcGMwVnljbTl5TzF4dVhHNW1kVzVqZEdsdmJpQnBjMFoxYm1OMGFXOXVLR0Z5WnlrZ2UxeHVJQ0J5WlhSMWNtNGdkSGx3Wlc5bUlHRnlaeUE5UFQwZ0oyWjFibU4wYVc5dUp6dGNibjFjYm1WNGNHOXlkSE11YVhOR2RXNWpkR2x2YmlBOUlHbHpSblZ1WTNScGIyNDdYRzVjYm1aMWJtTjBhVzl1SUdselVISnBiV2wwYVhabEtHRnlaeWtnZTF4dUlDQnlaWFIxY200Z1lYSm5JRDA5UFNCdWRXeHNJSHg4WEc0Z0lDQWdJQ0FnSUNCMGVYQmxiMllnWVhKbklEMDlQU0FuWW05dmJHVmhiaWNnZkh4Y2JpQWdJQ0FnSUNBZ0lIUjVjR1Z2WmlCaGNtY2dQVDA5SUNkdWRXMWlaWEluSUh4OFhHNGdJQ0FnSUNBZ0lDQjBlWEJsYjJZZ1lYSm5JRDA5UFNBbmMzUnlhVzVuSnlCOGZGeHVJQ0FnSUNBZ0lDQWdkSGx3Wlc5bUlHRnlaeUE5UFQwZ0ozTjViV0p2YkNjZ2ZId2dJQzh2SUVWVE5pQnplVzFpYjJ4Y2JpQWdJQ0FnSUNBZ0lIUjVjR1Z2WmlCaGNtY2dQVDA5SUNkMWJtUmxabWx1WldRbk8xeHVmVnh1Wlhod2IzSjBjeTVwYzFCeWFXMXBkR2wyWlNBOUlHbHpVSEpwYldsMGFYWmxPMXh1WEc1bGVIQnZjblJ6TG1selFuVm1abVZ5SUQwZ1FuVm1abVZ5TG1selFuVm1abVZ5TzF4dVhHNW1kVzVqZEdsdmJpQnZZbXBsWTNSVWIxTjBjbWx1WnlodktTQjdYRzRnSUhKbGRIVnliaUJQWW1wbFkzUXVjSEp2ZEc5MGVYQmxMblJ2VTNSeWFXNW5MbU5oYkd3b2J5azdYRzU5WEc0aVhYMD0iLCJtb2R1bGUuZXhwb3J0cyA9IHJlcXVpcmUoXCIuL2xpYi9fc3RyZWFtX3Bhc3N0aHJvdWdoLmpzXCIpXG4iLCIoZnVuY3Rpb24gKHByb2Nlc3Mpe1xuZXhwb3J0cyA9IG1vZHVsZS5leHBvcnRzID0gcmVxdWlyZSgnLi9saWIvX3N0cmVhbV9yZWFkYWJsZS5qcycpO1xuZXhwb3J0cy5TdHJlYW0gPSByZXF1aXJlKCdzdHJlYW0nKTtcbmV4cG9ydHMuUmVhZGFibGUgPSBleHBvcnRzO1xuZXhwb3J0cy5Xcml0YWJsZSA9IHJlcXVpcmUoJy4vbGliL19zdHJlYW1fd3JpdGFibGUuanMnKTtcbmV4cG9ydHMuRHVwbGV4ID0gcmVxdWlyZSgnLi9saWIvX3N0cmVhbV9kdXBsZXguanMnKTtcbmV4cG9ydHMuVHJhbnNmb3JtID0gcmVxdWlyZSgnLi9saWIvX3N0cmVhbV90cmFuc2Zvcm0uanMnKTtcbmV4cG9ydHMuUGFzc1Rocm91Z2ggPSByZXF1aXJlKCcuL2xpYi9fc3RyZWFtX3Bhc3N0aHJvdWdoLmpzJyk7XG5pZiAoIXByb2Nlc3MuYnJvd3NlciAmJiBwcm9jZXNzLmVudi5SRUFEQUJMRV9TVFJFQU0gPT09ICdkaXNhYmxlJykge1xuICBtb2R1bGUuZXhwb3J0cyA9IHJlcXVpcmUoJ3N0cmVhbScpO1xufVxuXG59KS5jYWxsKHRoaXMscmVxdWlyZSgnX3Byb2Nlc3MnKSlcbi8vIyBzb3VyY2VNYXBwaW5nVVJMPWRhdGE6YXBwbGljYXRpb24vanNvbjtjaGFyc2V0OnV0Zi04O2Jhc2U2NCxleUoyWlhKemFXOXVJam96TENKemIzVnlZMlZ6SWpwYkltNXZaR1ZmYlc5a2RXeGxjeTlpY205M2MyVnlhV1o1TDI1dlpHVmZiVzlrZFd4bGN5OXlaV0ZrWVdKc1pTMXpkSEpsWVcwdmNtVmhaR0ZpYkdVdWFuTWlYU3dpYm1GdFpYTWlPbHRkTENKdFlYQndhVzVuY3lJNklqdEJRVUZCTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRWlMQ0ptYVd4bElqb2laMlZ1WlhKaGRHVmtMbXB6SWl3aWMyOTFjbU5sVW05dmRDSTZJaUlzSW5OdmRYSmpaWE5EYjI1MFpXNTBJanBiSW1WNGNHOXlkSE1nUFNCdGIyUjFiR1V1Wlhod2IzSjBjeUE5SUhKbGNYVnBjbVVvSnk0dmJHbGlMMTl6ZEhKbFlXMWZjbVZoWkdGaWJHVXVhbk1uS1R0Y2JtVjRjRzl5ZEhNdVUzUnlaV0Z0SUQwZ2NtVnhkV2x5WlNnbmMzUnlaV0Z0SnlrN1hHNWxlSEJ2Y25SekxsSmxZV1JoWW14bElEMGdaWGh3YjNKMGN6dGNibVY0Y0c5eWRITXVWM0pwZEdGaWJHVWdQU0J5WlhGMWFYSmxLQ2N1TDJ4cFlpOWZjM1J5WldGdFgzZHlhWFJoWW14bExtcHpKeWs3WEc1bGVIQnZjblJ6TGtSMWNHeGxlQ0E5SUhKbGNYVnBjbVVvSnk0dmJHbGlMMTl6ZEhKbFlXMWZaSFZ3YkdWNExtcHpKeWs3WEc1bGVIQnZjblJ6TGxSeVlXNXpabTl5YlNBOUlISmxjWFZwY21Vb0p5NHZiR2xpTDE5emRISmxZVzFmZEhKaGJuTm1iM0p0TG1wekp5azdYRzVsZUhCdmNuUnpMbEJoYzNOVWFISnZkV2RvSUQwZ2NtVnhkV2x5WlNnbkxpOXNhV0l2WDNOMGNtVmhiVjl3WVhOemRHaHliM1ZuYUM1cWN5Y3BPMXh1YVdZZ0tDRndjbTlqWlhOekxtSnliM2R6WlhJZ0ppWWdjSEp2WTJWemN5NWxibll1VWtWQlJFRkNURVZmVTFSU1JVRk5JRDA5UFNBblpHbHpZV0pzWlNjcElIdGNiaUFnYlc5a2RXeGxMbVY0Y0c5eWRITWdQU0J5WlhGMWFYSmxLQ2R6ZEhKbFlXMG5LVHRjYm4xY2JpSmRmUT09IiwibW9kdWxlLmV4cG9ydHMgPSByZXF1aXJlKFwiLi9saWIvX3N0cmVhbV90cmFuc2Zvcm0uanNcIilcbiIsIm1vZHVsZS5leHBvcnRzID0gcmVxdWlyZShcIi4vbGliL19zdHJlYW1fd3JpdGFibGUuanNcIilcbiIsIi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG5tb2R1bGUuZXhwb3J0cyA9IFN0cmVhbTtcblxudmFyIEVFID0gcmVxdWlyZSgnZXZlbnRzJykuRXZlbnRFbWl0dGVyO1xudmFyIGluaGVyaXRzID0gcmVxdWlyZSgnaW5oZXJpdHMnKTtcblxuaW5oZXJpdHMoU3RyZWFtLCBFRSk7XG5TdHJlYW0uUmVhZGFibGUgPSByZXF1aXJlKCdyZWFkYWJsZS1zdHJlYW0vcmVhZGFibGUuanMnKTtcblN0cmVhbS5Xcml0YWJsZSA9IHJlcXVpcmUoJ3JlYWRhYmxlLXN0cmVhbS93cml0YWJsZS5qcycpO1xuU3RyZWFtLkR1cGxleCA9IHJlcXVpcmUoJ3JlYWRhYmxlLXN0cmVhbS9kdXBsZXguanMnKTtcblN0cmVhbS5UcmFuc2Zvcm0gPSByZXF1aXJlKCdyZWFkYWJsZS1zdHJlYW0vdHJhbnNmb3JtLmpzJyk7XG5TdHJlYW0uUGFzc1Rocm91Z2ggPSByZXF1aXJlKCdyZWFkYWJsZS1zdHJlYW0vcGFzc3Rocm91Z2guanMnKTtcblxuLy8gQmFja3dhcmRzLWNvbXBhdCB3aXRoIG5vZGUgMC40LnhcblN0cmVhbS5TdHJlYW0gPSBTdHJlYW07XG5cblxuXG4vLyBvbGQtc3R5bGUgc3RyZWFtcy4gIE5vdGUgdGhhdCB0aGUgcGlwZSBtZXRob2QgKHRoZSBvbmx5IHJlbGV2YW50XG4vLyBwYXJ0IG9mIHRoaXMgY2xhc3MpIGlzIG92ZXJyaWRkZW4gaW4gdGhlIFJlYWRhYmxlIGNsYXNzLlxuXG5mdW5jdGlvbiBTdHJlYW0oKSB7XG4gIEVFLmNhbGwodGhpcyk7XG59XG5cblN0cmVhbS5wcm90b3R5cGUucGlwZSA9IGZ1bmN0aW9uKGRlc3QsIG9wdGlvbnMpIHtcbiAgdmFyIHNvdXJjZSA9IHRoaXM7XG5cbiAgZnVuY3Rpb24gb25kYXRhKGNodW5rKSB7XG4gICAgaWYgKGRlc3Qud3JpdGFibGUpIHtcbiAgICAgIGlmIChmYWxzZSA9PT0gZGVzdC53cml0ZShjaHVuaykgJiYgc291cmNlLnBhdXNlKSB7XG4gICAgICAgIHNvdXJjZS5wYXVzZSgpO1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIHNvdXJjZS5vbignZGF0YScsIG9uZGF0YSk7XG5cbiAgZnVuY3Rpb24gb25kcmFpbigpIHtcbiAgICBpZiAoc291cmNlLnJlYWRhYmxlICYmIHNvdXJjZS5yZXN1bWUpIHtcbiAgICAgIHNvdXJjZS5yZXN1bWUoKTtcbiAgICB9XG4gIH1cblxuICBkZXN0Lm9uKCdkcmFpbicsIG9uZHJhaW4pO1xuXG4gIC8vIElmIHRoZSAnZW5kJyBvcHRpb24gaXMgbm90IHN1cHBsaWVkLCBkZXN0LmVuZCgpIHdpbGwgYmUgY2FsbGVkIHdoZW5cbiAgLy8gc291cmNlIGdldHMgdGhlICdlbmQnIG9yICdjbG9zZScgZXZlbnRzLiAgT25seSBkZXN0LmVuZCgpIG9uY2UuXG4gIGlmICghZGVzdC5faXNTdGRpbyAmJiAoIW9wdGlvbnMgfHwgb3B0aW9ucy5lbmQgIT09IGZhbHNlKSkge1xuICAgIHNvdXJjZS5vbignZW5kJywgb25lbmQpO1xuICAgIHNvdXJjZS5vbignY2xvc2UnLCBvbmNsb3NlKTtcbiAgfVxuXG4gIHZhciBkaWRPbkVuZCA9IGZhbHNlO1xuICBmdW5jdGlvbiBvbmVuZCgpIHtcbiAgICBpZiAoZGlkT25FbmQpIHJldHVybjtcbiAgICBkaWRPbkVuZCA9IHRydWU7XG5cbiAgICBkZXN0LmVuZCgpO1xuICB9XG5cblxuICBmdW5jdGlvbiBvbmNsb3NlKCkge1xuICAgIGlmIChkaWRPbkVuZCkgcmV0dXJuO1xuICAgIGRpZE9uRW5kID0gdHJ1ZTtcblxuICAgIGlmICh0eXBlb2YgZGVzdC5kZXN0cm95ID09PSAnZnVuY3Rpb24nKSBkZXN0LmRlc3Ryb3koKTtcbiAgfVxuXG4gIC8vIGRvbid0IGxlYXZlIGRhbmdsaW5nIHBpcGVzIHdoZW4gdGhlcmUgYXJlIGVycm9ycy5cbiAgZnVuY3Rpb24gb25lcnJvcihlcikge1xuICAgIGNsZWFudXAoKTtcbiAgICBpZiAoRUUubGlzdGVuZXJDb3VudCh0aGlzLCAnZXJyb3InKSA9PT0gMCkge1xuICAgICAgdGhyb3cgZXI7IC8vIFVuaGFuZGxlZCBzdHJlYW0gZXJyb3IgaW4gcGlwZS5cbiAgICB9XG4gIH1cblxuICBzb3VyY2Uub24oJ2Vycm9yJywgb25lcnJvcik7XG4gIGRlc3Qub24oJ2Vycm9yJywgb25lcnJvcik7XG5cbiAgLy8gcmVtb3ZlIGFsbCB0aGUgZXZlbnQgbGlzdGVuZXJzIHRoYXQgd2VyZSBhZGRlZC5cbiAgZnVuY3Rpb24gY2xlYW51cCgpIHtcbiAgICBzb3VyY2UucmVtb3ZlTGlzdGVuZXIoJ2RhdGEnLCBvbmRhdGEpO1xuICAgIGRlc3QucmVtb3ZlTGlzdGVuZXIoJ2RyYWluJywgb25kcmFpbik7XG5cbiAgICBzb3VyY2UucmVtb3ZlTGlzdGVuZXIoJ2VuZCcsIG9uZW5kKTtcbiAgICBzb3VyY2UucmVtb3ZlTGlzdGVuZXIoJ2Nsb3NlJywgb25jbG9zZSk7XG5cbiAgICBzb3VyY2UucmVtb3ZlTGlzdGVuZXIoJ2Vycm9yJywgb25lcnJvcik7XG4gICAgZGVzdC5yZW1vdmVMaXN0ZW5lcignZXJyb3InLCBvbmVycm9yKTtcblxuICAgIHNvdXJjZS5yZW1vdmVMaXN0ZW5lcignZW5kJywgY2xlYW51cCk7XG4gICAgc291cmNlLnJlbW92ZUxpc3RlbmVyKCdjbG9zZScsIGNsZWFudXApO1xuXG4gICAgZGVzdC5yZW1vdmVMaXN0ZW5lcignY2xvc2UnLCBjbGVhbnVwKTtcbiAgfVxuXG4gIHNvdXJjZS5vbignZW5kJywgY2xlYW51cCk7XG4gIHNvdXJjZS5vbignY2xvc2UnLCBjbGVhbnVwKTtcblxuICBkZXN0Lm9uKCdjbG9zZScsIGNsZWFudXApO1xuXG4gIGRlc3QuZW1pdCgncGlwZScsIHNvdXJjZSk7XG5cbiAgLy8gQWxsb3cgZm9yIHVuaXgtbGlrZSB1c2FnZTogQS5waXBlKEIpLnBpcGUoQylcbiAgcmV0dXJuIGRlc3Q7XG59O1xuIiwiLy8gQ29weXJpZ2h0IEpveWVudCwgSW5jLiBhbmQgb3RoZXIgTm9kZSBjb250cmlidXRvcnMuXG4vL1xuLy8gUGVybWlzc2lvbiBpcyBoZXJlYnkgZ3JhbnRlZCwgZnJlZSBvZiBjaGFyZ2UsIHRvIGFueSBwZXJzb24gb2J0YWluaW5nIGFcbi8vIGNvcHkgb2YgdGhpcyBzb2Z0d2FyZSBhbmQgYXNzb2NpYXRlZCBkb2N1bWVudGF0aW9uIGZpbGVzICh0aGVcbi8vIFwiU29mdHdhcmVcIiksIHRvIGRlYWwgaW4gdGhlIFNvZnR3YXJlIHdpdGhvdXQgcmVzdHJpY3Rpb24sIGluY2x1ZGluZ1xuLy8gd2l0aG91dCBsaW1pdGF0aW9uIHRoZSByaWdodHMgdG8gdXNlLCBjb3B5LCBtb2RpZnksIG1lcmdlLCBwdWJsaXNoLFxuLy8gZGlzdHJpYnV0ZSwgc3VibGljZW5zZSwgYW5kL29yIHNlbGwgY29waWVzIG9mIHRoZSBTb2Z0d2FyZSwgYW5kIHRvIHBlcm1pdFxuLy8gcGVyc29ucyB0byB3aG9tIHRoZSBTb2Z0d2FyZSBpcyBmdXJuaXNoZWQgdG8gZG8gc28sIHN1YmplY3QgdG8gdGhlXG4vLyBmb2xsb3dpbmcgY29uZGl0aW9uczpcbi8vXG4vLyBUaGUgYWJvdmUgY29weXJpZ2h0IG5vdGljZSBhbmQgdGhpcyBwZXJtaXNzaW9uIG5vdGljZSBzaGFsbCBiZSBpbmNsdWRlZFxuLy8gaW4gYWxsIGNvcGllcyBvciBzdWJzdGFudGlhbCBwb3J0aW9ucyBvZiB0aGUgU29mdHdhcmUuXG4vL1xuLy8gVEhFIFNPRlRXQVJFIElTIFBST1ZJREVEIFwiQVMgSVNcIiwgV0lUSE9VVCBXQVJSQU5UWSBPRiBBTlkgS0lORCwgRVhQUkVTU1xuLy8gT1IgSU1QTElFRCwgSU5DTFVESU5HIEJVVCBOT1QgTElNSVRFRCBUTyBUSEUgV0FSUkFOVElFUyBPRlxuLy8gTUVSQ0hBTlRBQklMSVRZLCBGSVRORVNTIEZPUiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBTkQgTk9OSU5GUklOR0VNRU5ULiBJTlxuLy8gTk8gRVZFTlQgU0hBTEwgVEhFIEFVVEhPUlMgT1IgQ09QWVJJR0hUIEhPTERFUlMgQkUgTElBQkxFIEZPUiBBTlkgQ0xBSU0sXG4vLyBEQU1BR0VTIE9SIE9USEVSIExJQUJJTElUWSwgV0hFVEhFUiBJTiBBTiBBQ1RJT04gT0YgQ09OVFJBQ1QsIFRPUlQgT1Jcbi8vIE9USEVSV0lTRSwgQVJJU0lORyBGUk9NLCBPVVQgT0YgT1IgSU4gQ09OTkVDVElPTiBXSVRIIFRIRSBTT0ZUV0FSRSBPUiBUSEVcbi8vIFVTRSBPUiBPVEhFUiBERUFMSU5HUyBJTiBUSEUgU09GVFdBUkUuXG5cbnZhciBCdWZmZXIgPSByZXF1aXJlKCdidWZmZXInKS5CdWZmZXI7XG5cbnZhciBpc0J1ZmZlckVuY29kaW5nID0gQnVmZmVyLmlzRW5jb2RpbmdcbiAgfHwgZnVuY3Rpb24oZW5jb2RpbmcpIHtcbiAgICAgICBzd2l0Y2ggKGVuY29kaW5nICYmIGVuY29kaW5nLnRvTG93ZXJDYXNlKCkpIHtcbiAgICAgICAgIGNhc2UgJ2hleCc6IGNhc2UgJ3V0ZjgnOiBjYXNlICd1dGYtOCc6IGNhc2UgJ2FzY2lpJzogY2FzZSAnYmluYXJ5JzogY2FzZSAnYmFzZTY0JzogY2FzZSAndWNzMic6IGNhc2UgJ3Vjcy0yJzogY2FzZSAndXRmMTZsZSc6IGNhc2UgJ3V0Zi0xNmxlJzogY2FzZSAncmF3JzogcmV0dXJuIHRydWU7XG4gICAgICAgICBkZWZhdWx0OiByZXR1cm4gZmFsc2U7XG4gICAgICAgfVxuICAgICB9XG5cblxuZnVuY3Rpb24gYXNzZXJ0RW5jb2RpbmcoZW5jb2RpbmcpIHtcbiAgaWYgKGVuY29kaW5nICYmICFpc0J1ZmZlckVuY29kaW5nKGVuY29kaW5nKSkge1xuICAgIHRocm93IG5ldyBFcnJvcignVW5rbm93biBlbmNvZGluZzogJyArIGVuY29kaW5nKTtcbiAgfVxufVxuXG4vLyBTdHJpbmdEZWNvZGVyIHByb3ZpZGVzIGFuIGludGVyZmFjZSBmb3IgZWZmaWNpZW50bHkgc3BsaXR0aW5nIGEgc2VyaWVzIG9mXG4vLyBidWZmZXJzIGludG8gYSBzZXJpZXMgb2YgSlMgc3RyaW5ncyB3aXRob3V0IGJyZWFraW5nIGFwYXJ0IG11bHRpLWJ5dGVcbi8vIGNoYXJhY3RlcnMuIENFU1UtOCBpcyBoYW5kbGVkIGFzIHBhcnQgb2YgdGhlIFVURi04IGVuY29kaW5nLlxuLy9cbi8vIEBUT0RPIEhhbmRsaW5nIGFsbCBlbmNvZGluZ3MgaW5zaWRlIGEgc2luZ2xlIG9iamVjdCBtYWtlcyBpdCB2ZXJ5IGRpZmZpY3VsdFxuLy8gdG8gcmVhc29uIGFib3V0IHRoaXMgY29kZSwgc28gaXQgc2hvdWxkIGJlIHNwbGl0IHVwIGluIHRoZSBmdXR1cmUuXG4vLyBAVE9ETyBUaGVyZSBzaG91bGQgYmUgYSB1dGY4LXN0cmljdCBlbmNvZGluZyB0aGF0IHJlamVjdHMgaW52YWxpZCBVVEYtOCBjb2RlXG4vLyBwb2ludHMgYXMgdXNlZCBieSBDRVNVLTguXG52YXIgU3RyaW5nRGVjb2RlciA9IGV4cG9ydHMuU3RyaW5nRGVjb2RlciA9IGZ1bmN0aW9uKGVuY29kaW5nKSB7XG4gIHRoaXMuZW5jb2RpbmcgPSAoZW5jb2RpbmcgfHwgJ3V0ZjgnKS50b0xvd2VyQ2FzZSgpLnJlcGxhY2UoL1stX10vLCAnJyk7XG4gIGFzc2VydEVuY29kaW5nKGVuY29kaW5nKTtcbiAgc3dpdGNoICh0aGlzLmVuY29kaW5nKSB7XG4gICAgY2FzZSAndXRmOCc6XG4gICAgICAvLyBDRVNVLTggcmVwcmVzZW50cyBlYWNoIG9mIFN1cnJvZ2F0ZSBQYWlyIGJ5IDMtYnl0ZXNcbiAgICAgIHRoaXMuc3Vycm9nYXRlU2l6ZSA9IDM7XG4gICAgICBicmVhaztcbiAgICBjYXNlICd1Y3MyJzpcbiAgICBjYXNlICd1dGYxNmxlJzpcbiAgICAgIC8vIFVURi0xNiByZXByZXNlbnRzIGVhY2ggb2YgU3Vycm9nYXRlIFBhaXIgYnkgMi1ieXRlc1xuICAgICAgdGhpcy5zdXJyb2dhdGVTaXplID0gMjtcbiAgICAgIHRoaXMuZGV0ZWN0SW5jb21wbGV0ZUNoYXIgPSB1dGYxNkRldGVjdEluY29tcGxldGVDaGFyO1xuICAgICAgYnJlYWs7XG4gICAgY2FzZSAnYmFzZTY0JzpcbiAgICAgIC8vIEJhc2UtNjQgc3RvcmVzIDMgYnl0ZXMgaW4gNCBjaGFycywgYW5kIHBhZHMgdGhlIHJlbWFpbmRlci5cbiAgICAgIHRoaXMuc3Vycm9nYXRlU2l6ZSA9IDM7XG4gICAgICB0aGlzLmRldGVjdEluY29tcGxldGVDaGFyID0gYmFzZTY0RGV0ZWN0SW5jb21wbGV0ZUNoYXI7XG4gICAgICBicmVhaztcbiAgICBkZWZhdWx0OlxuICAgICAgdGhpcy53cml0ZSA9IHBhc3NUaHJvdWdoV3JpdGU7XG4gICAgICByZXR1cm47XG4gIH1cblxuICAvLyBFbm91Z2ggc3BhY2UgdG8gc3RvcmUgYWxsIGJ5dGVzIG9mIGEgc2luZ2xlIGNoYXJhY3Rlci4gVVRGLTggbmVlZHMgNFxuICAvLyBieXRlcywgYnV0IENFU1UtOCBtYXkgcmVxdWlyZSB1cCB0byA2ICgzIGJ5dGVzIHBlciBzdXJyb2dhdGUpLlxuICB0aGlzLmNoYXJCdWZmZXIgPSBuZXcgQnVmZmVyKDYpO1xuICAvLyBOdW1iZXIgb2YgYnl0ZXMgcmVjZWl2ZWQgZm9yIHRoZSBjdXJyZW50IGluY29tcGxldGUgbXVsdGktYnl0ZSBjaGFyYWN0ZXIuXG4gIHRoaXMuY2hhclJlY2VpdmVkID0gMDtcbiAgLy8gTnVtYmVyIG9mIGJ5dGVzIGV4cGVjdGVkIGZvciB0aGUgY3VycmVudCBpbmNvbXBsZXRlIG11bHRpLWJ5dGUgY2hhcmFjdGVyLlxuICB0aGlzLmNoYXJMZW5ndGggPSAwO1xufTtcblxuXG4vLyB3cml0ZSBkZWNvZGVzIHRoZSBnaXZlbiBidWZmZXIgYW5kIHJldHVybnMgaXQgYXMgSlMgc3RyaW5nIHRoYXQgaXNcbi8vIGd1YXJhbnRlZWQgdG8gbm90IGNvbnRhaW4gYW55IHBhcnRpYWwgbXVsdGktYnl0ZSBjaGFyYWN0ZXJzLiBBbnkgcGFydGlhbFxuLy8gY2hhcmFjdGVyIGZvdW5kIGF0IHRoZSBlbmQgb2YgdGhlIGJ1ZmZlciBpcyBidWZmZXJlZCB1cCwgYW5kIHdpbGwgYmVcbi8vIHJldHVybmVkIHdoZW4gY2FsbGluZyB3cml0ZSBhZ2FpbiB3aXRoIHRoZSByZW1haW5pbmcgYnl0ZXMuXG4vL1xuLy8gTm90ZTogQ29udmVydGluZyBhIEJ1ZmZlciBjb250YWluaW5nIGFuIG9ycGhhbiBzdXJyb2dhdGUgdG8gYSBTdHJpbmdcbi8vIGN1cnJlbnRseSB3b3JrcywgYnV0IGNvbnZlcnRpbmcgYSBTdHJpbmcgdG8gYSBCdWZmZXIgKHZpYSBgbmV3IEJ1ZmZlcmAsIG9yXG4vLyBCdWZmZXIjd3JpdGUpIHdpbGwgcmVwbGFjZSBpbmNvbXBsZXRlIHN1cnJvZ2F0ZXMgd2l0aCB0aGUgdW5pY29kZVxuLy8gcmVwbGFjZW1lbnQgY2hhcmFjdGVyLiBTZWUgaHR0cHM6Ly9jb2RlcmV2aWV3LmNocm9taXVtLm9yZy8xMjExNzMwMDkvIC5cblN0cmluZ0RlY29kZXIucHJvdG90eXBlLndyaXRlID0gZnVuY3Rpb24oYnVmZmVyKSB7XG4gIHZhciBjaGFyU3RyID0gJyc7XG4gIC8vIGlmIG91ciBsYXN0IHdyaXRlIGVuZGVkIHdpdGggYW4gaW5jb21wbGV0ZSBtdWx0aWJ5dGUgY2hhcmFjdGVyXG4gIHdoaWxlICh0aGlzLmNoYXJMZW5ndGgpIHtcbiAgICAvLyBkZXRlcm1pbmUgaG93IG1hbnkgcmVtYWluaW5nIGJ5dGVzIHRoaXMgYnVmZmVyIGhhcyB0byBvZmZlciBmb3IgdGhpcyBjaGFyXG4gICAgdmFyIGF2YWlsYWJsZSA9IChidWZmZXIubGVuZ3RoID49IHRoaXMuY2hhckxlbmd0aCAtIHRoaXMuY2hhclJlY2VpdmVkKSA/XG4gICAgICAgIHRoaXMuY2hhckxlbmd0aCAtIHRoaXMuY2hhclJlY2VpdmVkIDpcbiAgICAgICAgYnVmZmVyLmxlbmd0aDtcblxuICAgIC8vIGFkZCB0aGUgbmV3IGJ5dGVzIHRvIHRoZSBjaGFyIGJ1ZmZlclxuICAgIGJ1ZmZlci5jb3B5KHRoaXMuY2hhckJ1ZmZlciwgdGhpcy5jaGFyUmVjZWl2ZWQsIDAsIGF2YWlsYWJsZSk7XG4gICAgdGhpcy5jaGFyUmVjZWl2ZWQgKz0gYXZhaWxhYmxlO1xuXG4gICAgaWYgKHRoaXMuY2hhclJlY2VpdmVkIDwgdGhpcy5jaGFyTGVuZ3RoKSB7XG4gICAgICAvLyBzdGlsbCBub3QgZW5vdWdoIGNoYXJzIGluIHRoaXMgYnVmZmVyPyB3YWl0IGZvciBtb3JlIC4uLlxuICAgICAgcmV0dXJuICcnO1xuICAgIH1cblxuICAgIC8vIHJlbW92ZSBieXRlcyBiZWxvbmdpbmcgdG8gdGhlIGN1cnJlbnQgY2hhcmFjdGVyIGZyb20gdGhlIGJ1ZmZlclxuICAgIGJ1ZmZlciA9IGJ1ZmZlci5zbGljZShhdmFpbGFibGUsIGJ1ZmZlci5sZW5ndGgpO1xuXG4gICAgLy8gZ2V0IHRoZSBjaGFyYWN0ZXIgdGhhdCB3YXMgc3BsaXRcbiAgICBjaGFyU3RyID0gdGhpcy5jaGFyQnVmZmVyLnNsaWNlKDAsIHRoaXMuY2hhckxlbmd0aCkudG9TdHJpbmcodGhpcy5lbmNvZGluZyk7XG5cbiAgICAvLyBDRVNVLTg6IGxlYWQgc3Vycm9nYXRlIChEODAwLURCRkYpIGlzIGFsc28gdGhlIGluY29tcGxldGUgY2hhcmFjdGVyXG4gICAgdmFyIGNoYXJDb2RlID0gY2hhclN0ci5jaGFyQ29kZUF0KGNoYXJTdHIubGVuZ3RoIC0gMSk7XG4gICAgaWYgKGNoYXJDb2RlID49IDB4RDgwMCAmJiBjaGFyQ29kZSA8PSAweERCRkYpIHtcbiAgICAgIHRoaXMuY2hhckxlbmd0aCArPSB0aGlzLnN1cnJvZ2F0ZVNpemU7XG4gICAgICBjaGFyU3RyID0gJyc7XG4gICAgICBjb250aW51ZTtcbiAgICB9XG4gICAgdGhpcy5jaGFyUmVjZWl2ZWQgPSB0aGlzLmNoYXJMZW5ndGggPSAwO1xuXG4gICAgLy8gaWYgdGhlcmUgYXJlIG5vIG1vcmUgYnl0ZXMgaW4gdGhpcyBidWZmZXIsIGp1c3QgZW1pdCBvdXIgY2hhclxuICAgIGlmIChidWZmZXIubGVuZ3RoID09PSAwKSB7XG4gICAgICByZXR1cm4gY2hhclN0cjtcbiAgICB9XG4gICAgYnJlYWs7XG4gIH1cblxuICAvLyBkZXRlcm1pbmUgYW5kIHNldCBjaGFyTGVuZ3RoIC8gY2hhclJlY2VpdmVkXG4gIHRoaXMuZGV0ZWN0SW5jb21wbGV0ZUNoYXIoYnVmZmVyKTtcblxuICB2YXIgZW5kID0gYnVmZmVyLmxlbmd0aDtcbiAgaWYgKHRoaXMuY2hhckxlbmd0aCkge1xuICAgIC8vIGJ1ZmZlciB0aGUgaW5jb21wbGV0ZSBjaGFyYWN0ZXIgYnl0ZXMgd2UgZ290XG4gICAgYnVmZmVyLmNvcHkodGhpcy5jaGFyQnVmZmVyLCAwLCBidWZmZXIubGVuZ3RoIC0gdGhpcy5jaGFyUmVjZWl2ZWQsIGVuZCk7XG4gICAgZW5kIC09IHRoaXMuY2hhclJlY2VpdmVkO1xuICB9XG5cbiAgY2hhclN0ciArPSBidWZmZXIudG9TdHJpbmcodGhpcy5lbmNvZGluZywgMCwgZW5kKTtcblxuICB2YXIgZW5kID0gY2hhclN0ci5sZW5ndGggLSAxO1xuICB2YXIgY2hhckNvZGUgPSBjaGFyU3RyLmNoYXJDb2RlQXQoZW5kKTtcbiAgLy8gQ0VTVS04OiBsZWFkIHN1cnJvZ2F0ZSAoRDgwMC1EQkZGKSBpcyBhbHNvIHRoZSBpbmNvbXBsZXRlIGNoYXJhY3RlclxuICBpZiAoY2hhckNvZGUgPj0gMHhEODAwICYmIGNoYXJDb2RlIDw9IDB4REJGRikge1xuICAgIHZhciBzaXplID0gdGhpcy5zdXJyb2dhdGVTaXplO1xuICAgIHRoaXMuY2hhckxlbmd0aCArPSBzaXplO1xuICAgIHRoaXMuY2hhclJlY2VpdmVkICs9IHNpemU7XG4gICAgdGhpcy5jaGFyQnVmZmVyLmNvcHkodGhpcy5jaGFyQnVmZmVyLCBzaXplLCAwLCBzaXplKTtcbiAgICBidWZmZXIuY29weSh0aGlzLmNoYXJCdWZmZXIsIDAsIDAsIHNpemUpO1xuICAgIHJldHVybiBjaGFyU3RyLnN1YnN0cmluZygwLCBlbmQpO1xuICB9XG5cbiAgLy8gb3IganVzdCBlbWl0IHRoZSBjaGFyU3RyXG4gIHJldHVybiBjaGFyU3RyO1xufTtcblxuLy8gZGV0ZWN0SW5jb21wbGV0ZUNoYXIgZGV0ZXJtaW5lcyBpZiB0aGVyZSBpcyBhbiBpbmNvbXBsZXRlIFVURi04IGNoYXJhY3RlciBhdFxuLy8gdGhlIGVuZCBvZiB0aGUgZ2l2ZW4gYnVmZmVyLiBJZiBzbywgaXQgc2V0cyB0aGlzLmNoYXJMZW5ndGggdG8gdGhlIGJ5dGVcbi8vIGxlbmd0aCB0aGF0IGNoYXJhY3RlciwgYW5kIHNldHMgdGhpcy5jaGFyUmVjZWl2ZWQgdG8gdGhlIG51bWJlciBvZiBieXRlc1xuLy8gdGhhdCBhcmUgYXZhaWxhYmxlIGZvciB0aGlzIGNoYXJhY3Rlci5cblN0cmluZ0RlY29kZXIucHJvdG90eXBlLmRldGVjdEluY29tcGxldGVDaGFyID0gZnVuY3Rpb24oYnVmZmVyKSB7XG4gIC8vIGRldGVybWluZSBob3cgbWFueSBieXRlcyB3ZSBoYXZlIHRvIGNoZWNrIGF0IHRoZSBlbmQgb2YgdGhpcyBidWZmZXJcbiAgdmFyIGkgPSAoYnVmZmVyLmxlbmd0aCA+PSAzKSA/IDMgOiBidWZmZXIubGVuZ3RoO1xuXG4gIC8vIEZpZ3VyZSBvdXQgaWYgb25lIG9mIHRoZSBsYXN0IGkgYnl0ZXMgb2Ygb3VyIGJ1ZmZlciBhbm5vdW5jZXMgYW5cbiAgLy8gaW5jb21wbGV0ZSBjaGFyLlxuICBmb3IgKDsgaSA+IDA7IGktLSkge1xuICAgIHZhciBjID0gYnVmZmVyW2J1ZmZlci5sZW5ndGggLSBpXTtcblxuICAgIC8vIFNlZSBodHRwOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL1VURi04I0Rlc2NyaXB0aW9uXG5cbiAgICAvLyAxMTBYWFhYWFxuICAgIGlmIChpID09IDEgJiYgYyA+PiA1ID09IDB4MDYpIHtcbiAgICAgIHRoaXMuY2hhckxlbmd0aCA9IDI7XG4gICAgICBicmVhaztcbiAgICB9XG5cbiAgICAvLyAxMTEwWFhYWFxuICAgIGlmIChpIDw9IDIgJiYgYyA+PiA0ID09IDB4MEUpIHtcbiAgICAgIHRoaXMuY2hhckxlbmd0aCA9IDM7XG4gICAgICBicmVhaztcbiAgICB9XG5cbiAgICAvLyAxMTExMFhYWFxuICAgIGlmIChpIDw9IDMgJiYgYyA+PiAzID09IDB4MUUpIHtcbiAgICAgIHRoaXMuY2hhckxlbmd0aCA9IDQ7XG4gICAgICBicmVhaztcbiAgICB9XG4gIH1cbiAgdGhpcy5jaGFyUmVjZWl2ZWQgPSBpO1xufTtcblxuU3RyaW5nRGVjb2Rlci5wcm90b3R5cGUuZW5kID0gZnVuY3Rpb24oYnVmZmVyKSB7XG4gIHZhciByZXMgPSAnJztcbiAgaWYgKGJ1ZmZlciAmJiBidWZmZXIubGVuZ3RoKVxuICAgIHJlcyA9IHRoaXMud3JpdGUoYnVmZmVyKTtcblxuICBpZiAodGhpcy5jaGFyUmVjZWl2ZWQpIHtcbiAgICB2YXIgY3IgPSB0aGlzLmNoYXJSZWNlaXZlZDtcbiAgICB2YXIgYnVmID0gdGhpcy5jaGFyQnVmZmVyO1xuICAgIHZhciBlbmMgPSB0aGlzLmVuY29kaW5nO1xuICAgIHJlcyArPSBidWYuc2xpY2UoMCwgY3IpLnRvU3RyaW5nKGVuYyk7XG4gIH1cblxuICByZXR1cm4gcmVzO1xufTtcblxuZnVuY3Rpb24gcGFzc1Rocm91Z2hXcml0ZShidWZmZXIpIHtcbiAgcmV0dXJuIGJ1ZmZlci50b1N0cmluZyh0aGlzLmVuY29kaW5nKTtcbn1cblxuZnVuY3Rpb24gdXRmMTZEZXRlY3RJbmNvbXBsZXRlQ2hhcihidWZmZXIpIHtcbiAgdGhpcy5jaGFyUmVjZWl2ZWQgPSBidWZmZXIubGVuZ3RoICUgMjtcbiAgdGhpcy5jaGFyTGVuZ3RoID0gdGhpcy5jaGFyUmVjZWl2ZWQgPyAyIDogMDtcbn1cblxuZnVuY3Rpb24gYmFzZTY0RGV0ZWN0SW5jb21wbGV0ZUNoYXIoYnVmZmVyKSB7XG4gIHRoaXMuY2hhclJlY2VpdmVkID0gYnVmZmVyLmxlbmd0aCAlIDM7XG4gIHRoaXMuY2hhckxlbmd0aCA9IHRoaXMuY2hhclJlY2VpdmVkID8gMyA6IDA7XG59XG4iLCIvLyBDb3B5cmlnaHQgSm95ZW50LCBJbmMuIGFuZCBvdGhlciBOb2RlIGNvbnRyaWJ1dG9ycy5cbi8vXG4vLyBQZXJtaXNzaW9uIGlzIGhlcmVieSBncmFudGVkLCBmcmVlIG9mIGNoYXJnZSwgdG8gYW55IHBlcnNvbiBvYnRhaW5pbmcgYVxuLy8gY29weSBvZiB0aGlzIHNvZnR3YXJlIGFuZCBhc3NvY2lhdGVkIGRvY3VtZW50YXRpb24gZmlsZXMgKHRoZVxuLy8gXCJTb2Z0d2FyZVwiKSwgdG8gZGVhbCBpbiB0aGUgU29mdHdhcmUgd2l0aG91dCByZXN0cmljdGlvbiwgaW5jbHVkaW5nXG4vLyB3aXRob3V0IGxpbWl0YXRpb24gdGhlIHJpZ2h0cyB0byB1c2UsIGNvcHksIG1vZGlmeSwgbWVyZ2UsIHB1Ymxpc2gsXG4vLyBkaXN0cmlidXRlLCBzdWJsaWNlbnNlLCBhbmQvb3Igc2VsbCBjb3BpZXMgb2YgdGhlIFNvZnR3YXJlLCBhbmQgdG8gcGVybWl0XG4vLyBwZXJzb25zIHRvIHdob20gdGhlIFNvZnR3YXJlIGlzIGZ1cm5pc2hlZCB0byBkbyBzbywgc3ViamVjdCB0byB0aGVcbi8vIGZvbGxvd2luZyBjb25kaXRpb25zOlxuLy9cbi8vIFRoZSBhYm92ZSBjb3B5cmlnaHQgbm90aWNlIGFuZCB0aGlzIHBlcm1pc3Npb24gbm90aWNlIHNoYWxsIGJlIGluY2x1ZGVkXG4vLyBpbiBhbGwgY29waWVzIG9yIHN1YnN0YW50aWFsIHBvcnRpb25zIG9mIHRoZSBTb2Z0d2FyZS5cbi8vXG4vLyBUSEUgU09GVFdBUkUgSVMgUFJPVklERUQgXCJBUyBJU1wiLCBXSVRIT1VUIFdBUlJBTlRZIE9GIEFOWSBLSU5ELCBFWFBSRVNTXG4vLyBPUiBJTVBMSUVELCBJTkNMVURJTkcgQlVUIE5PVCBMSU1JVEVEIFRPIFRIRSBXQVJSQU5USUVTIE9GXG4vLyBNRVJDSEFOVEFCSUxJVFksIEZJVE5FU1MgRk9SIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFORCBOT05JTkZSSU5HRU1FTlQuIElOXG4vLyBOTyBFVkVOVCBTSEFMTCBUSEUgQVVUSE9SUyBPUiBDT1BZUklHSFQgSE9MREVSUyBCRSBMSUFCTEUgRk9SIEFOWSBDTEFJTSxcbi8vIERBTUFHRVMgT1IgT1RIRVIgTElBQklMSVRZLCBXSEVUSEVSIElOIEFOIEFDVElPTiBPRiBDT05UUkFDVCwgVE9SVCBPUlxuLy8gT1RIRVJXSVNFLCBBUklTSU5HIEZST00sIE9VVCBPRiBPUiBJTiBDT05ORUNUSU9OIFdJVEggVEhFIFNPRlRXQVJFIE9SIFRIRVxuLy8gVVNFIE9SIE9USEVSIERFQUxJTkdTIElOIFRIRSBTT0ZUV0FSRS5cblxudmFyIHB1bnljb2RlID0gcmVxdWlyZSgncHVueWNvZGUnKTtcblxuZXhwb3J0cy5wYXJzZSA9IHVybFBhcnNlO1xuZXhwb3J0cy5yZXNvbHZlID0gdXJsUmVzb2x2ZTtcbmV4cG9ydHMucmVzb2x2ZU9iamVjdCA9IHVybFJlc29sdmVPYmplY3Q7XG5leHBvcnRzLmZvcm1hdCA9IHVybEZvcm1hdDtcblxuZXhwb3J0cy5VcmwgPSBVcmw7XG5cbmZ1bmN0aW9uIFVybCgpIHtcbiAgdGhpcy5wcm90b2NvbCA9IG51bGw7XG4gIHRoaXMuc2xhc2hlcyA9IG51bGw7XG4gIHRoaXMuYXV0aCA9IG51bGw7XG4gIHRoaXMuaG9zdCA9IG51bGw7XG4gIHRoaXMucG9ydCA9IG51bGw7XG4gIHRoaXMuaG9zdG5hbWUgPSBudWxsO1xuICB0aGlzLmhhc2ggPSBudWxsO1xuICB0aGlzLnNlYXJjaCA9IG51bGw7XG4gIHRoaXMucXVlcnkgPSBudWxsO1xuICB0aGlzLnBhdGhuYW1lID0gbnVsbDtcbiAgdGhpcy5wYXRoID0gbnVsbDtcbiAgdGhpcy5ocmVmID0gbnVsbDtcbn1cblxuLy8gUmVmZXJlbmNlOiBSRkMgMzk4NiwgUkZDIDE4MDgsIFJGQyAyMzk2XG5cbi8vIGRlZmluZSB0aGVzZSBoZXJlIHNvIGF0IGxlYXN0IHRoZXkgb25seSBoYXZlIHRvIGJlXG4vLyBjb21waWxlZCBvbmNlIG9uIHRoZSBmaXJzdCBtb2R1bGUgbG9hZC5cbnZhciBwcm90b2NvbFBhdHRlcm4gPSAvXihbYS16MC05ListXSs6KS9pLFxuICAgIHBvcnRQYXR0ZXJuID0gLzpbMC05XSokLyxcblxuICAgIC8vIFJGQyAyMzk2OiBjaGFyYWN0ZXJzIHJlc2VydmVkIGZvciBkZWxpbWl0aW5nIFVSTHMuXG4gICAgLy8gV2UgYWN0dWFsbHkganVzdCBhdXRvLWVzY2FwZSB0aGVzZS5cbiAgICBkZWxpbXMgPSBbJzwnLCAnPicsICdcIicsICdgJywgJyAnLCAnXFxyJywgJ1xcbicsICdcXHQnXSxcblxuICAgIC8vIFJGQyAyMzk2OiBjaGFyYWN0ZXJzIG5vdCBhbGxvd2VkIGZvciB2YXJpb3VzIHJlYXNvbnMuXG4gICAgdW53aXNlID0gWyd7JywgJ30nLCAnfCcsICdcXFxcJywgJ14nLCAnYCddLmNvbmNhdChkZWxpbXMpLFxuXG4gICAgLy8gQWxsb3dlZCBieSBSRkNzLCBidXQgY2F1c2Ugb2YgWFNTIGF0dGFja3MuICBBbHdheXMgZXNjYXBlIHRoZXNlLlxuICAgIGF1dG9Fc2NhcGUgPSBbJ1xcJyddLmNvbmNhdCh1bndpc2UpLFxuICAgIC8vIENoYXJhY3RlcnMgdGhhdCBhcmUgbmV2ZXIgZXZlciBhbGxvd2VkIGluIGEgaG9zdG5hbWUuXG4gICAgLy8gTm90ZSB0aGF0IGFueSBpbnZhbGlkIGNoYXJzIGFyZSBhbHNvIGhhbmRsZWQsIGJ1dCB0aGVzZVxuICAgIC8vIGFyZSB0aGUgb25lcyB0aGF0IGFyZSAqZXhwZWN0ZWQqIHRvIGJlIHNlZW4sIHNvIHdlIGZhc3QtcGF0aFxuICAgIC8vIHRoZW0uXG4gICAgbm9uSG9zdENoYXJzID0gWyclJywgJy8nLCAnPycsICc7JywgJyMnXS5jb25jYXQoYXV0b0VzY2FwZSksXG4gICAgaG9zdEVuZGluZ0NoYXJzID0gWycvJywgJz8nLCAnIyddLFxuICAgIGhvc3RuYW1lTWF4TGVuID0gMjU1LFxuICAgIGhvc3RuYW1lUGFydFBhdHRlcm4gPSAvXlthLXowLTlBLVpfLV17MCw2M30kLyxcbiAgICBob3N0bmFtZVBhcnRTdGFydCA9IC9eKFthLXowLTlBLVpfLV17MCw2M30pKC4qKSQvLFxuICAgIC8vIHByb3RvY29scyB0aGF0IGNhbiBhbGxvdyBcInVuc2FmZVwiIGFuZCBcInVud2lzZVwiIGNoYXJzLlxuICAgIHVuc2FmZVByb3RvY29sID0ge1xuICAgICAgJ2phdmFzY3JpcHQnOiB0cnVlLFxuICAgICAgJ2phdmFzY3JpcHQ6JzogdHJ1ZVxuICAgIH0sXG4gICAgLy8gcHJvdG9jb2xzIHRoYXQgbmV2ZXIgaGF2ZSBhIGhvc3RuYW1lLlxuICAgIGhvc3RsZXNzUHJvdG9jb2wgPSB7XG4gICAgICAnamF2YXNjcmlwdCc6IHRydWUsXG4gICAgICAnamF2YXNjcmlwdDonOiB0cnVlXG4gICAgfSxcbiAgICAvLyBwcm90b2NvbHMgdGhhdCBhbHdheXMgY29udGFpbiBhIC8vIGJpdC5cbiAgICBzbGFzaGVkUHJvdG9jb2wgPSB7XG4gICAgICAnaHR0cCc6IHRydWUsXG4gICAgICAnaHR0cHMnOiB0cnVlLFxuICAgICAgJ2Z0cCc6IHRydWUsXG4gICAgICAnZ29waGVyJzogdHJ1ZSxcbiAgICAgICdmaWxlJzogdHJ1ZSxcbiAgICAgICdodHRwOic6IHRydWUsXG4gICAgICAnaHR0cHM6JzogdHJ1ZSxcbiAgICAgICdmdHA6JzogdHJ1ZSxcbiAgICAgICdnb3BoZXI6JzogdHJ1ZSxcbiAgICAgICdmaWxlOic6IHRydWVcbiAgICB9LFxuICAgIHF1ZXJ5c3RyaW5nID0gcmVxdWlyZSgncXVlcnlzdHJpbmcnKTtcblxuZnVuY3Rpb24gdXJsUGFyc2UodXJsLCBwYXJzZVF1ZXJ5U3RyaW5nLCBzbGFzaGVzRGVub3RlSG9zdCkge1xuICBpZiAodXJsICYmIGlzT2JqZWN0KHVybCkgJiYgdXJsIGluc3RhbmNlb2YgVXJsKSByZXR1cm4gdXJsO1xuXG4gIHZhciB1ID0gbmV3IFVybDtcbiAgdS5wYXJzZSh1cmwsIHBhcnNlUXVlcnlTdHJpbmcsIHNsYXNoZXNEZW5vdGVIb3N0KTtcbiAgcmV0dXJuIHU7XG59XG5cblVybC5wcm90b3R5cGUucGFyc2UgPSBmdW5jdGlvbih1cmwsIHBhcnNlUXVlcnlTdHJpbmcsIHNsYXNoZXNEZW5vdGVIb3N0KSB7XG4gIGlmICghaXNTdHJpbmcodXJsKSkge1xuICAgIHRocm93IG5ldyBUeXBlRXJyb3IoXCJQYXJhbWV0ZXIgJ3VybCcgbXVzdCBiZSBhIHN0cmluZywgbm90IFwiICsgdHlwZW9mIHVybCk7XG4gIH1cblxuICB2YXIgcmVzdCA9IHVybDtcblxuICAvLyB0cmltIGJlZm9yZSBwcm9jZWVkaW5nLlxuICAvLyBUaGlzIGlzIHRvIHN1cHBvcnQgcGFyc2Ugc3R1ZmYgbGlrZSBcIiAgaHR0cDovL2Zvby5jb20gIFxcblwiXG4gIHJlc3QgPSByZXN0LnRyaW0oKTtcblxuICB2YXIgcHJvdG8gPSBwcm90b2NvbFBhdHRlcm4uZXhlYyhyZXN0KTtcbiAgaWYgKHByb3RvKSB7XG4gICAgcHJvdG8gPSBwcm90b1swXTtcbiAgICB2YXIgbG93ZXJQcm90byA9IHByb3RvLnRvTG93ZXJDYXNlKCk7XG4gICAgdGhpcy5wcm90b2NvbCA9IGxvd2VyUHJvdG87XG4gICAgcmVzdCA9IHJlc3Quc3Vic3RyKHByb3RvLmxlbmd0aCk7XG4gIH1cblxuICAvLyBmaWd1cmUgb3V0IGlmIGl0J3MgZ290IGEgaG9zdFxuICAvLyB1c2VyQHNlcnZlciBpcyAqYWx3YXlzKiBpbnRlcnByZXRlZCBhcyBhIGhvc3RuYW1lLCBhbmQgdXJsXG4gIC8vIHJlc29sdXRpb24gd2lsbCB0cmVhdCAvL2Zvby9iYXIgYXMgaG9zdD1mb28scGF0aD1iYXIgYmVjYXVzZSB0aGF0J3NcbiAgLy8gaG93IHRoZSBicm93c2VyIHJlc29sdmVzIHJlbGF0aXZlIFVSTHMuXG4gIGlmIChzbGFzaGVzRGVub3RlSG9zdCB8fCBwcm90byB8fCByZXN0Lm1hdGNoKC9eXFwvXFwvW15AXFwvXStAW15AXFwvXSsvKSkge1xuICAgIHZhciBzbGFzaGVzID0gcmVzdC5zdWJzdHIoMCwgMikgPT09ICcvLyc7XG4gICAgaWYgKHNsYXNoZXMgJiYgIShwcm90byAmJiBob3N0bGVzc1Byb3RvY29sW3Byb3RvXSkpIHtcbiAgICAgIHJlc3QgPSByZXN0LnN1YnN0cigyKTtcbiAgICAgIHRoaXMuc2xhc2hlcyA9IHRydWU7XG4gICAgfVxuICB9XG5cbiAgaWYgKCFob3N0bGVzc1Byb3RvY29sW3Byb3RvXSAmJlxuICAgICAgKHNsYXNoZXMgfHwgKHByb3RvICYmICFzbGFzaGVkUHJvdG9jb2xbcHJvdG9dKSkpIHtcblxuICAgIC8vIHRoZXJlJ3MgYSBob3N0bmFtZS5cbiAgICAvLyB0aGUgZmlyc3QgaW5zdGFuY2Ugb2YgLywgPywgOywgb3IgIyBlbmRzIHRoZSBob3N0LlxuICAgIC8vXG4gICAgLy8gSWYgdGhlcmUgaXMgYW4gQCBpbiB0aGUgaG9zdG5hbWUsIHRoZW4gbm9uLWhvc3QgY2hhcnMgKmFyZSogYWxsb3dlZFxuICAgIC8vIHRvIHRoZSBsZWZ0IG9mIHRoZSBsYXN0IEAgc2lnbiwgdW5sZXNzIHNvbWUgaG9zdC1lbmRpbmcgY2hhcmFjdGVyXG4gICAgLy8gY29tZXMgKmJlZm9yZSogdGhlIEAtc2lnbi5cbiAgICAvLyBVUkxzIGFyZSBvYm5veGlvdXMuXG4gICAgLy9cbiAgICAvLyBleDpcbiAgICAvLyBodHRwOi8vYUBiQGMvID0+IHVzZXI6YUBiIGhvc3Q6Y1xuICAgIC8vIGh0dHA6Ly9hQGI/QGMgPT4gdXNlcjphIGhvc3Q6YyBwYXRoOi8/QGNcblxuICAgIC8vIHYwLjEyIFRPRE8oaXNhYWNzKTogVGhpcyBpcyBub3QgcXVpdGUgaG93IENocm9tZSBkb2VzIHRoaW5ncy5cbiAgICAvLyBSZXZpZXcgb3VyIHRlc3QgY2FzZSBhZ2FpbnN0IGJyb3dzZXJzIG1vcmUgY29tcHJlaGVuc2l2ZWx5LlxuXG4gICAgLy8gZmluZCB0aGUgZmlyc3QgaW5zdGFuY2Ugb2YgYW55IGhvc3RFbmRpbmdDaGFyc1xuICAgIHZhciBob3N0RW5kID0gLTE7XG4gICAgZm9yICh2YXIgaSA9IDA7IGkgPCBob3N0RW5kaW5nQ2hhcnMubGVuZ3RoOyBpKyspIHtcbiAgICAgIHZhciBoZWMgPSByZXN0LmluZGV4T2YoaG9zdEVuZGluZ0NoYXJzW2ldKTtcbiAgICAgIGlmIChoZWMgIT09IC0xICYmIChob3N0RW5kID09PSAtMSB8fCBoZWMgPCBob3N0RW5kKSlcbiAgICAgICAgaG9zdEVuZCA9IGhlYztcbiAgICB9XG5cbiAgICAvLyBhdCB0aGlzIHBvaW50LCBlaXRoZXIgd2UgaGF2ZSBhbiBleHBsaWNpdCBwb2ludCB3aGVyZSB0aGVcbiAgICAvLyBhdXRoIHBvcnRpb24gY2Fubm90IGdvIHBhc3QsIG9yIHRoZSBsYXN0IEAgY2hhciBpcyB0aGUgZGVjaWRlci5cbiAgICB2YXIgYXV0aCwgYXRTaWduO1xuICAgIGlmIChob3N0RW5kID09PSAtMSkge1xuICAgICAgLy8gYXRTaWduIGNhbiBiZSBhbnl3aGVyZS5cbiAgICAgIGF0U2lnbiA9IHJlc3QubGFzdEluZGV4T2YoJ0AnKTtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gYXRTaWduIG11c3QgYmUgaW4gYXV0aCBwb3J0aW9uLlxuICAgICAgLy8gaHR0cDovL2FAYi9jQGQgPT4gaG9zdDpiIGF1dGg6YSBwYXRoOi9jQGRcbiAgICAgIGF0U2lnbiA9IHJlc3QubGFzdEluZGV4T2YoJ0AnLCBob3N0RW5kKTtcbiAgICB9XG5cbiAgICAvLyBOb3cgd2UgaGF2ZSBhIHBvcnRpb24gd2hpY2ggaXMgZGVmaW5pdGVseSB0aGUgYXV0aC5cbiAgICAvLyBQdWxsIHRoYXQgb2ZmLlxuICAgIGlmIChhdFNpZ24gIT09IC0xKSB7XG4gICAgICBhdXRoID0gcmVzdC5zbGljZSgwLCBhdFNpZ24pO1xuICAgICAgcmVzdCA9IHJlc3Quc2xpY2UoYXRTaWduICsgMSk7XG4gICAgICB0aGlzLmF1dGggPSBkZWNvZGVVUklDb21wb25lbnQoYXV0aCk7XG4gICAgfVxuXG4gICAgLy8gdGhlIGhvc3QgaXMgdGhlIHJlbWFpbmluZyB0byB0aGUgbGVmdCBvZiB0aGUgZmlyc3Qgbm9uLWhvc3QgY2hhclxuICAgIGhvc3RFbmQgPSAtMTtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IG5vbkhvc3RDaGFycy5sZW5ndGg7IGkrKykge1xuICAgICAgdmFyIGhlYyA9IHJlc3QuaW5kZXhPZihub25Ib3N0Q2hhcnNbaV0pO1xuICAgICAgaWYgKGhlYyAhPT0gLTEgJiYgKGhvc3RFbmQgPT09IC0xIHx8IGhlYyA8IGhvc3RFbmQpKVxuICAgICAgICBob3N0RW5kID0gaGVjO1xuICAgIH1cbiAgICAvLyBpZiB3ZSBzdGlsbCBoYXZlIG5vdCBoaXQgaXQsIHRoZW4gdGhlIGVudGlyZSB0aGluZyBpcyBhIGhvc3QuXG4gICAgaWYgKGhvc3RFbmQgPT09IC0xKVxuICAgICAgaG9zdEVuZCA9IHJlc3QubGVuZ3RoO1xuXG4gICAgdGhpcy5ob3N0ID0gcmVzdC5zbGljZSgwLCBob3N0RW5kKTtcbiAgICByZXN0ID0gcmVzdC5zbGljZShob3N0RW5kKTtcblxuICAgIC8vIHB1bGwgb3V0IHBvcnQuXG4gICAgdGhpcy5wYXJzZUhvc3QoKTtcblxuICAgIC8vIHdlJ3ZlIGluZGljYXRlZCB0aGF0IHRoZXJlIGlzIGEgaG9zdG5hbWUsXG4gICAgLy8gc28gZXZlbiBpZiBpdCdzIGVtcHR5LCBpdCBoYXMgdG8gYmUgcHJlc2VudC5cbiAgICB0aGlzLmhvc3RuYW1lID0gdGhpcy5ob3N0bmFtZSB8fCAnJztcblxuICAgIC8vIGlmIGhvc3RuYW1lIGJlZ2lucyB3aXRoIFsgYW5kIGVuZHMgd2l0aCBdXG4gICAgLy8gYXNzdW1lIHRoYXQgaXQncyBhbiBJUHY2IGFkZHJlc3MuXG4gICAgdmFyIGlwdjZIb3N0bmFtZSA9IHRoaXMuaG9zdG5hbWVbMF0gPT09ICdbJyAmJlxuICAgICAgICB0aGlzLmhvc3RuYW1lW3RoaXMuaG9zdG5hbWUubGVuZ3RoIC0gMV0gPT09ICddJztcblxuICAgIC8vIHZhbGlkYXRlIGEgbGl0dGxlLlxuICAgIGlmICghaXB2Nkhvc3RuYW1lKSB7XG4gICAgICB2YXIgaG9zdHBhcnRzID0gdGhpcy5ob3N0bmFtZS5zcGxpdCgvXFwuLyk7XG4gICAgICBmb3IgKHZhciBpID0gMCwgbCA9IGhvc3RwYXJ0cy5sZW5ndGg7IGkgPCBsOyBpKyspIHtcbiAgICAgICAgdmFyIHBhcnQgPSBob3N0cGFydHNbaV07XG4gICAgICAgIGlmICghcGFydCkgY29udGludWU7XG4gICAgICAgIGlmICghcGFydC5tYXRjaChob3N0bmFtZVBhcnRQYXR0ZXJuKSkge1xuICAgICAgICAgIHZhciBuZXdwYXJ0ID0gJyc7XG4gICAgICAgICAgZm9yICh2YXIgaiA9IDAsIGsgPSBwYXJ0Lmxlbmd0aDsgaiA8IGs7IGorKykge1xuICAgICAgICAgICAgaWYgKHBhcnQuY2hhckNvZGVBdChqKSA+IDEyNykge1xuICAgICAgICAgICAgICAvLyB3ZSByZXBsYWNlIG5vbi1BU0NJSSBjaGFyIHdpdGggYSB0ZW1wb3JhcnkgcGxhY2Vob2xkZXJcbiAgICAgICAgICAgICAgLy8gd2UgbmVlZCB0aGlzIHRvIG1ha2Ugc3VyZSBzaXplIG9mIGhvc3RuYW1lIGlzIG5vdFxuICAgICAgICAgICAgICAvLyBicm9rZW4gYnkgcmVwbGFjaW5nIG5vbi1BU0NJSSBieSBub3RoaW5nXG4gICAgICAgICAgICAgIG5ld3BhcnQgKz0gJ3gnO1xuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgbmV3cGFydCArPSBwYXJ0W2pdO1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cbiAgICAgICAgICAvLyB3ZSB0ZXN0IGFnYWluIHdpdGggQVNDSUkgY2hhciBvbmx5XG4gICAgICAgICAgaWYgKCFuZXdwYXJ0Lm1hdGNoKGhvc3RuYW1lUGFydFBhdHRlcm4pKSB7XG4gICAgICAgICAgICB2YXIgdmFsaWRQYXJ0cyA9IGhvc3RwYXJ0cy5zbGljZSgwLCBpKTtcbiAgICAgICAgICAgIHZhciBub3RIb3N0ID0gaG9zdHBhcnRzLnNsaWNlKGkgKyAxKTtcbiAgICAgICAgICAgIHZhciBiaXQgPSBwYXJ0Lm1hdGNoKGhvc3RuYW1lUGFydFN0YXJ0KTtcbiAgICAgICAgICAgIGlmIChiaXQpIHtcbiAgICAgICAgICAgICAgdmFsaWRQYXJ0cy5wdXNoKGJpdFsxXSk7XG4gICAgICAgICAgICAgIG5vdEhvc3QudW5zaGlmdChiaXRbMl0pO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYgKG5vdEhvc3QubGVuZ3RoKSB7XG4gICAgICAgICAgICAgIHJlc3QgPSAnLycgKyBub3RIb3N0LmpvaW4oJy4nKSArIHJlc3Q7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICB0aGlzLmhvc3RuYW1lID0gdmFsaWRQYXJ0cy5qb2luKCcuJyk7XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG5cbiAgICBpZiAodGhpcy5ob3N0bmFtZS5sZW5ndGggPiBob3N0bmFtZU1heExlbikge1xuICAgICAgdGhpcy5ob3N0bmFtZSA9ICcnO1xuICAgIH0gZWxzZSB7XG4gICAgICAvLyBob3N0bmFtZXMgYXJlIGFsd2F5cyBsb3dlciBjYXNlLlxuICAgICAgdGhpcy5ob3N0bmFtZSA9IHRoaXMuaG9zdG5hbWUudG9Mb3dlckNhc2UoKTtcbiAgICB9XG5cbiAgICBpZiAoIWlwdjZIb3N0bmFtZSkge1xuICAgICAgLy8gSUROQSBTdXBwb3J0OiBSZXR1cm5zIGEgcHVueSBjb2RlZCByZXByZXNlbnRhdGlvbiBvZiBcImRvbWFpblwiLlxuICAgICAgLy8gSXQgb25seSBjb252ZXJ0cyB0aGUgcGFydCBvZiB0aGUgZG9tYWluIG5hbWUgdGhhdFxuICAgICAgLy8gaGFzIG5vbiBBU0NJSSBjaGFyYWN0ZXJzLiBJLmUuIGl0IGRvc2VudCBtYXR0ZXIgaWZcbiAgICAgIC8vIHlvdSBjYWxsIGl0IHdpdGggYSBkb21haW4gdGhhdCBhbHJlYWR5IGlzIGluIEFTQ0lJLlxuICAgICAgdmFyIGRvbWFpbkFycmF5ID0gdGhpcy5ob3N0bmFtZS5zcGxpdCgnLicpO1xuICAgICAgdmFyIG5ld091dCA9IFtdO1xuICAgICAgZm9yICh2YXIgaSA9IDA7IGkgPCBkb21haW5BcnJheS5sZW5ndGg7ICsraSkge1xuICAgICAgICB2YXIgcyA9IGRvbWFpbkFycmF5W2ldO1xuICAgICAgICBuZXdPdXQucHVzaChzLm1hdGNoKC9bXkEtWmEtejAtOV8tXS8pID9cbiAgICAgICAgICAgICd4bi0tJyArIHB1bnljb2RlLmVuY29kZShzKSA6IHMpO1xuICAgICAgfVxuICAgICAgdGhpcy5ob3N0bmFtZSA9IG5ld091dC5qb2luKCcuJyk7XG4gICAgfVxuXG4gICAgdmFyIHAgPSB0aGlzLnBvcnQgPyAnOicgKyB0aGlzLnBvcnQgOiAnJztcbiAgICB2YXIgaCA9IHRoaXMuaG9zdG5hbWUgfHwgJyc7XG4gICAgdGhpcy5ob3N0ID0gaCArIHA7XG4gICAgdGhpcy5ocmVmICs9IHRoaXMuaG9zdDtcblxuICAgIC8vIHN0cmlwIFsgYW5kIF0gZnJvbSB0aGUgaG9zdG5hbWVcbiAgICAvLyB0aGUgaG9zdCBmaWVsZCBzdGlsbCByZXRhaW5zIHRoZW0sIHRob3VnaFxuICAgIGlmIChpcHY2SG9zdG5hbWUpIHtcbiAgICAgIHRoaXMuaG9zdG5hbWUgPSB0aGlzLmhvc3RuYW1lLnN1YnN0cigxLCB0aGlzLmhvc3RuYW1lLmxlbmd0aCAtIDIpO1xuICAgICAgaWYgKHJlc3RbMF0gIT09ICcvJykge1xuICAgICAgICByZXN0ID0gJy8nICsgcmVzdDtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICAvLyBub3cgcmVzdCBpcyBzZXQgdG8gdGhlIHBvc3QtaG9zdCBzdHVmZi5cbiAgLy8gY2hvcCBvZmYgYW55IGRlbGltIGNoYXJzLlxuICBpZiAoIXVuc2FmZVByb3RvY29sW2xvd2VyUHJvdG9dKSB7XG5cbiAgICAvLyBGaXJzdCwgbWFrZSAxMDAlIHN1cmUgdGhhdCBhbnkgXCJhdXRvRXNjYXBlXCIgY2hhcnMgZ2V0XG4gICAgLy8gZXNjYXBlZCwgZXZlbiBpZiBlbmNvZGVVUklDb21wb25lbnQgZG9lc24ndCB0aGluayB0aGV5XG4gICAgLy8gbmVlZCB0byBiZS5cbiAgICBmb3IgKHZhciBpID0gMCwgbCA9IGF1dG9Fc2NhcGUubGVuZ3RoOyBpIDwgbDsgaSsrKSB7XG4gICAgICB2YXIgYWUgPSBhdXRvRXNjYXBlW2ldO1xuICAgICAgdmFyIGVzYyA9IGVuY29kZVVSSUNvbXBvbmVudChhZSk7XG4gICAgICBpZiAoZXNjID09PSBhZSkge1xuICAgICAgICBlc2MgPSBlc2NhcGUoYWUpO1xuICAgICAgfVxuICAgICAgcmVzdCA9IHJlc3Quc3BsaXQoYWUpLmpvaW4oZXNjKTtcbiAgICB9XG4gIH1cblxuXG4gIC8vIGNob3Agb2ZmIGZyb20gdGhlIHRhaWwgZmlyc3QuXG4gIHZhciBoYXNoID0gcmVzdC5pbmRleE9mKCcjJyk7XG4gIGlmIChoYXNoICE9PSAtMSkge1xuICAgIC8vIGdvdCBhIGZyYWdtZW50IHN0cmluZy5cbiAgICB0aGlzLmhhc2ggPSByZXN0LnN1YnN0cihoYXNoKTtcbiAgICByZXN0ID0gcmVzdC5zbGljZSgwLCBoYXNoKTtcbiAgfVxuICB2YXIgcW0gPSByZXN0LmluZGV4T2YoJz8nKTtcbiAgaWYgKHFtICE9PSAtMSkge1xuICAgIHRoaXMuc2VhcmNoID0gcmVzdC5zdWJzdHIocW0pO1xuICAgIHRoaXMucXVlcnkgPSByZXN0LnN1YnN0cihxbSArIDEpO1xuICAgIGlmIChwYXJzZVF1ZXJ5U3RyaW5nKSB7XG4gICAgICB0aGlzLnF1ZXJ5ID0gcXVlcnlzdHJpbmcucGFyc2UodGhpcy5xdWVyeSk7XG4gICAgfVxuICAgIHJlc3QgPSByZXN0LnNsaWNlKDAsIHFtKTtcbiAgfSBlbHNlIGlmIChwYXJzZVF1ZXJ5U3RyaW5nKSB7XG4gICAgLy8gbm8gcXVlcnkgc3RyaW5nLCBidXQgcGFyc2VRdWVyeVN0cmluZyBzdGlsbCByZXF1ZXN0ZWRcbiAgICB0aGlzLnNlYXJjaCA9ICcnO1xuICAgIHRoaXMucXVlcnkgPSB7fTtcbiAgfVxuICBpZiAocmVzdCkgdGhpcy5wYXRobmFtZSA9IHJlc3Q7XG4gIGlmIChzbGFzaGVkUHJvdG9jb2xbbG93ZXJQcm90b10gJiZcbiAgICAgIHRoaXMuaG9zdG5hbWUgJiYgIXRoaXMucGF0aG5hbWUpIHtcbiAgICB0aGlzLnBhdGhuYW1lID0gJy8nO1xuICB9XG5cbiAgLy90byBzdXBwb3J0IGh0dHAucmVxdWVzdFxuICBpZiAodGhpcy5wYXRobmFtZSB8fCB0aGlzLnNlYXJjaCkge1xuICAgIHZhciBwID0gdGhpcy5wYXRobmFtZSB8fCAnJztcbiAgICB2YXIgcyA9IHRoaXMuc2VhcmNoIHx8ICcnO1xuICAgIHRoaXMucGF0aCA9IHAgKyBzO1xuICB9XG5cbiAgLy8gZmluYWxseSwgcmVjb25zdHJ1Y3QgdGhlIGhyZWYgYmFzZWQgb24gd2hhdCBoYXMgYmVlbiB2YWxpZGF0ZWQuXG4gIHRoaXMuaHJlZiA9IHRoaXMuZm9ybWF0KCk7XG4gIHJldHVybiB0aGlzO1xufTtcblxuLy8gZm9ybWF0IGEgcGFyc2VkIG9iamVjdCBpbnRvIGEgdXJsIHN0cmluZ1xuZnVuY3Rpb24gdXJsRm9ybWF0KG9iaikge1xuICAvLyBlbnN1cmUgaXQncyBhbiBvYmplY3QsIGFuZCBub3QgYSBzdHJpbmcgdXJsLlxuICAvLyBJZiBpdCdzIGFuIG9iaiwgdGhpcyBpcyBhIG5vLW9wLlxuICAvLyB0aGlzIHdheSwgeW91IGNhbiBjYWxsIHVybF9mb3JtYXQoKSBvbiBzdHJpbmdzXG4gIC8vIHRvIGNsZWFuIHVwIHBvdGVudGlhbGx5IHdvbmt5IHVybHMuXG4gIGlmIChpc1N0cmluZyhvYmopKSBvYmogPSB1cmxQYXJzZShvYmopO1xuICBpZiAoIShvYmogaW5zdGFuY2VvZiBVcmwpKSByZXR1cm4gVXJsLnByb3RvdHlwZS5mb3JtYXQuY2FsbChvYmopO1xuICByZXR1cm4gb2JqLmZvcm1hdCgpO1xufVxuXG5VcmwucHJvdG90eXBlLmZvcm1hdCA9IGZ1bmN0aW9uKCkge1xuICB2YXIgYXV0aCA9IHRoaXMuYXV0aCB8fCAnJztcbiAgaWYgKGF1dGgpIHtcbiAgICBhdXRoID0gZW5jb2RlVVJJQ29tcG9uZW50KGF1dGgpO1xuICAgIGF1dGggPSBhdXRoLnJlcGxhY2UoLyUzQS9pLCAnOicpO1xuICAgIGF1dGggKz0gJ0AnO1xuICB9XG5cbiAgdmFyIHByb3RvY29sID0gdGhpcy5wcm90b2NvbCB8fCAnJyxcbiAgICAgIHBhdGhuYW1lID0gdGhpcy5wYXRobmFtZSB8fCAnJyxcbiAgICAgIGhhc2ggPSB0aGlzLmhhc2ggfHwgJycsXG4gICAgICBob3N0ID0gZmFsc2UsXG4gICAgICBxdWVyeSA9ICcnO1xuXG4gIGlmICh0aGlzLmhvc3QpIHtcbiAgICBob3N0ID0gYXV0aCArIHRoaXMuaG9zdDtcbiAgfSBlbHNlIGlmICh0aGlzLmhvc3RuYW1lKSB7XG4gICAgaG9zdCA9IGF1dGggKyAodGhpcy5ob3N0bmFtZS5pbmRleE9mKCc6JykgPT09IC0xID9cbiAgICAgICAgdGhpcy5ob3N0bmFtZSA6XG4gICAgICAgICdbJyArIHRoaXMuaG9zdG5hbWUgKyAnXScpO1xuICAgIGlmICh0aGlzLnBvcnQpIHtcbiAgICAgIGhvc3QgKz0gJzonICsgdGhpcy5wb3J0O1xuICAgIH1cbiAgfVxuXG4gIGlmICh0aGlzLnF1ZXJ5ICYmXG4gICAgICBpc09iamVjdCh0aGlzLnF1ZXJ5KSAmJlxuICAgICAgT2JqZWN0LmtleXModGhpcy5xdWVyeSkubGVuZ3RoKSB7XG4gICAgcXVlcnkgPSBxdWVyeXN0cmluZy5zdHJpbmdpZnkodGhpcy5xdWVyeSk7XG4gIH1cblxuICB2YXIgc2VhcmNoID0gdGhpcy5zZWFyY2ggfHwgKHF1ZXJ5ICYmICgnPycgKyBxdWVyeSkpIHx8ICcnO1xuXG4gIGlmIChwcm90b2NvbCAmJiBwcm90b2NvbC5zdWJzdHIoLTEpICE9PSAnOicpIHByb3RvY29sICs9ICc6JztcblxuICAvLyBvbmx5IHRoZSBzbGFzaGVkUHJvdG9jb2xzIGdldCB0aGUgLy8uICBOb3QgbWFpbHRvOiwgeG1wcDosIGV0Yy5cbiAgLy8gdW5sZXNzIHRoZXkgaGFkIHRoZW0gdG8gYmVnaW4gd2l0aC5cbiAgaWYgKHRoaXMuc2xhc2hlcyB8fFxuICAgICAgKCFwcm90b2NvbCB8fCBzbGFzaGVkUHJvdG9jb2xbcHJvdG9jb2xdKSAmJiBob3N0ICE9PSBmYWxzZSkge1xuICAgIGhvc3QgPSAnLy8nICsgKGhvc3QgfHwgJycpO1xuICAgIGlmIChwYXRobmFtZSAmJiBwYXRobmFtZS5jaGFyQXQoMCkgIT09ICcvJykgcGF0aG5hbWUgPSAnLycgKyBwYXRobmFtZTtcbiAgfSBlbHNlIGlmICghaG9zdCkge1xuICAgIGhvc3QgPSAnJztcbiAgfVxuXG4gIGlmIChoYXNoICYmIGhhc2guY2hhckF0KDApICE9PSAnIycpIGhhc2ggPSAnIycgKyBoYXNoO1xuICBpZiAoc2VhcmNoICYmIHNlYXJjaC5jaGFyQXQoMCkgIT09ICc/Jykgc2VhcmNoID0gJz8nICsgc2VhcmNoO1xuXG4gIHBhdGhuYW1lID0gcGF0aG5hbWUucmVwbGFjZSgvWz8jXS9nLCBmdW5jdGlvbihtYXRjaCkge1xuICAgIHJldHVybiBlbmNvZGVVUklDb21wb25lbnQobWF0Y2gpO1xuICB9KTtcbiAgc2VhcmNoID0gc2VhcmNoLnJlcGxhY2UoJyMnLCAnJTIzJyk7XG5cbiAgcmV0dXJuIHByb3RvY29sICsgaG9zdCArIHBhdGhuYW1lICsgc2VhcmNoICsgaGFzaDtcbn07XG5cbmZ1bmN0aW9uIHVybFJlc29sdmUoc291cmNlLCByZWxhdGl2ZSkge1xuICByZXR1cm4gdXJsUGFyc2Uoc291cmNlLCBmYWxzZSwgdHJ1ZSkucmVzb2x2ZShyZWxhdGl2ZSk7XG59XG5cblVybC5wcm90b3R5cGUucmVzb2x2ZSA9IGZ1bmN0aW9uKHJlbGF0aXZlKSB7XG4gIHJldHVybiB0aGlzLnJlc29sdmVPYmplY3QodXJsUGFyc2UocmVsYXRpdmUsIGZhbHNlLCB0cnVlKSkuZm9ybWF0KCk7XG59O1xuXG5mdW5jdGlvbiB1cmxSZXNvbHZlT2JqZWN0KHNvdXJjZSwgcmVsYXRpdmUpIHtcbiAgaWYgKCFzb3VyY2UpIHJldHVybiByZWxhdGl2ZTtcbiAgcmV0dXJuIHVybFBhcnNlKHNvdXJjZSwgZmFsc2UsIHRydWUpLnJlc29sdmVPYmplY3QocmVsYXRpdmUpO1xufVxuXG5VcmwucHJvdG90eXBlLnJlc29sdmVPYmplY3QgPSBmdW5jdGlvbihyZWxhdGl2ZSkge1xuICBpZiAoaXNTdHJpbmcocmVsYXRpdmUpKSB7XG4gICAgdmFyIHJlbCA9IG5ldyBVcmwoKTtcbiAgICByZWwucGFyc2UocmVsYXRpdmUsIGZhbHNlLCB0cnVlKTtcbiAgICByZWxhdGl2ZSA9IHJlbDtcbiAgfVxuXG4gIHZhciByZXN1bHQgPSBuZXcgVXJsKCk7XG4gIE9iamVjdC5rZXlzKHRoaXMpLmZvckVhY2goZnVuY3Rpb24oaykge1xuICAgIHJlc3VsdFtrXSA9IHRoaXNba107XG4gIH0sIHRoaXMpO1xuXG4gIC8vIGhhc2ggaXMgYWx3YXlzIG92ZXJyaWRkZW4sIG5vIG1hdHRlciB3aGF0LlxuICAvLyBldmVuIGhyZWY9XCJcIiB3aWxsIHJlbW92ZSBpdC5cbiAgcmVzdWx0Lmhhc2ggPSByZWxhdGl2ZS5oYXNoO1xuXG4gIC8vIGlmIHRoZSByZWxhdGl2ZSB1cmwgaXMgZW1wdHksIHRoZW4gdGhlcmUncyBub3RoaW5nIGxlZnQgdG8gZG8gaGVyZS5cbiAgaWYgKHJlbGF0aXZlLmhyZWYgPT09ICcnKSB7XG4gICAgcmVzdWx0LmhyZWYgPSByZXN1bHQuZm9ybWF0KCk7XG4gICAgcmV0dXJuIHJlc3VsdDtcbiAgfVxuXG4gIC8vIGhyZWZzIGxpa2UgLy9mb28vYmFyIGFsd2F5cyBjdXQgdG8gdGhlIHByb3RvY29sLlxuICBpZiAocmVsYXRpdmUuc2xhc2hlcyAmJiAhcmVsYXRpdmUucHJvdG9jb2wpIHtcbiAgICAvLyB0YWtlIGV2ZXJ5dGhpbmcgZXhjZXB0IHRoZSBwcm90b2NvbCBmcm9tIHJlbGF0aXZlXG4gICAgT2JqZWN0LmtleXMocmVsYXRpdmUpLmZvckVhY2goZnVuY3Rpb24oaykge1xuICAgICAgaWYgKGsgIT09ICdwcm90b2NvbCcpXG4gICAgICAgIHJlc3VsdFtrXSA9IHJlbGF0aXZlW2tdO1xuICAgIH0pO1xuXG4gICAgLy91cmxQYXJzZSBhcHBlbmRzIHRyYWlsaW5nIC8gdG8gdXJscyBsaWtlIGh0dHA6Ly93d3cuZXhhbXBsZS5jb21cbiAgICBpZiAoc2xhc2hlZFByb3RvY29sW3Jlc3VsdC5wcm90b2NvbF0gJiZcbiAgICAgICAgcmVzdWx0Lmhvc3RuYW1lICYmICFyZXN1bHQucGF0aG5hbWUpIHtcbiAgICAgIHJlc3VsdC5wYXRoID0gcmVzdWx0LnBhdGhuYW1lID0gJy8nO1xuICAgIH1cblxuICAgIHJlc3VsdC5ocmVmID0gcmVzdWx0LmZvcm1hdCgpO1xuICAgIHJldHVybiByZXN1bHQ7XG4gIH1cblxuICBpZiAocmVsYXRpdmUucHJvdG9jb2wgJiYgcmVsYXRpdmUucHJvdG9jb2wgIT09IHJlc3VsdC5wcm90b2NvbCkge1xuICAgIC8vIGlmIGl0J3MgYSBrbm93biB1cmwgcHJvdG9jb2wsIHRoZW4gY2hhbmdpbmdcbiAgICAvLyB0aGUgcHJvdG9jb2wgZG9lcyB3ZWlyZCB0aGluZ3NcbiAgICAvLyBmaXJzdCwgaWYgaXQncyBub3QgZmlsZTosIHRoZW4gd2UgTVVTVCBoYXZlIGEgaG9zdCxcbiAgICAvLyBhbmQgaWYgdGhlcmUgd2FzIGEgcGF0aFxuICAgIC8vIHRvIGJlZ2luIHdpdGgsIHRoZW4gd2UgTVVTVCBoYXZlIGEgcGF0aC5cbiAgICAvLyBpZiBpdCBpcyBmaWxlOiwgdGhlbiB0aGUgaG9zdCBpcyBkcm9wcGVkLFxuICAgIC8vIGJlY2F1c2UgdGhhdCdzIGtub3duIHRvIGJlIGhvc3RsZXNzLlxuICAgIC8vIGFueXRoaW5nIGVsc2UgaXMgYXNzdW1lZCB0byBiZSBhYnNvbHV0ZS5cbiAgICBpZiAoIXNsYXNoZWRQcm90b2NvbFtyZWxhdGl2ZS5wcm90b2NvbF0pIHtcbiAgICAgIE9iamVjdC5rZXlzKHJlbGF0aXZlKS5mb3JFYWNoKGZ1bmN0aW9uKGspIHtcbiAgICAgICAgcmVzdWx0W2tdID0gcmVsYXRpdmVba107XG4gICAgICB9KTtcbiAgICAgIHJlc3VsdC5ocmVmID0gcmVzdWx0LmZvcm1hdCgpO1xuICAgICAgcmV0dXJuIHJlc3VsdDtcbiAgICB9XG5cbiAgICByZXN1bHQucHJvdG9jb2wgPSByZWxhdGl2ZS5wcm90b2NvbDtcbiAgICBpZiAoIXJlbGF0aXZlLmhvc3QgJiYgIWhvc3RsZXNzUHJvdG9jb2xbcmVsYXRpdmUucHJvdG9jb2xdKSB7XG4gICAgICB2YXIgcmVsUGF0aCA9IChyZWxhdGl2ZS5wYXRobmFtZSB8fCAnJykuc3BsaXQoJy8nKTtcbiAgICAgIHdoaWxlIChyZWxQYXRoLmxlbmd0aCAmJiAhKHJlbGF0aXZlLmhvc3QgPSByZWxQYXRoLnNoaWZ0KCkpKTtcbiAgICAgIGlmICghcmVsYXRpdmUuaG9zdCkgcmVsYXRpdmUuaG9zdCA9ICcnO1xuICAgICAgaWYgKCFyZWxhdGl2ZS5ob3N0bmFtZSkgcmVsYXRpdmUuaG9zdG5hbWUgPSAnJztcbiAgICAgIGlmIChyZWxQYXRoWzBdICE9PSAnJykgcmVsUGF0aC51bnNoaWZ0KCcnKTtcbiAgICAgIGlmIChyZWxQYXRoLmxlbmd0aCA8IDIpIHJlbFBhdGgudW5zaGlmdCgnJyk7XG4gICAgICByZXN1bHQucGF0aG5hbWUgPSByZWxQYXRoLmpvaW4oJy8nKTtcbiAgICB9IGVsc2Uge1xuICAgICAgcmVzdWx0LnBhdGhuYW1lID0gcmVsYXRpdmUucGF0aG5hbWU7XG4gICAgfVxuICAgIHJlc3VsdC5zZWFyY2ggPSByZWxhdGl2ZS5zZWFyY2g7XG4gICAgcmVzdWx0LnF1ZXJ5ID0gcmVsYXRpdmUucXVlcnk7XG4gICAgcmVzdWx0Lmhvc3QgPSByZWxhdGl2ZS5ob3N0IHx8ICcnO1xuICAgIHJlc3VsdC5hdXRoID0gcmVsYXRpdmUuYXV0aDtcbiAgICByZXN1bHQuaG9zdG5hbWUgPSByZWxhdGl2ZS5ob3N0bmFtZSB8fCByZWxhdGl2ZS5ob3N0O1xuICAgIHJlc3VsdC5wb3J0ID0gcmVsYXRpdmUucG9ydDtcbiAgICAvLyB0byBzdXBwb3J0IGh0dHAucmVxdWVzdFxuICAgIGlmIChyZXN1bHQucGF0aG5hbWUgfHwgcmVzdWx0LnNlYXJjaCkge1xuICAgICAgdmFyIHAgPSByZXN1bHQucGF0aG5hbWUgfHwgJyc7XG4gICAgICB2YXIgcyA9IHJlc3VsdC5zZWFyY2ggfHwgJyc7XG4gICAgICByZXN1bHQucGF0aCA9IHAgKyBzO1xuICAgIH1cbiAgICByZXN1bHQuc2xhc2hlcyA9IHJlc3VsdC5zbGFzaGVzIHx8IHJlbGF0aXZlLnNsYXNoZXM7XG4gICAgcmVzdWx0LmhyZWYgPSByZXN1bHQuZm9ybWF0KCk7XG4gICAgcmV0dXJuIHJlc3VsdDtcbiAgfVxuXG4gIHZhciBpc1NvdXJjZUFicyA9IChyZXN1bHQucGF0aG5hbWUgJiYgcmVzdWx0LnBhdGhuYW1lLmNoYXJBdCgwKSA9PT0gJy8nKSxcbiAgICAgIGlzUmVsQWJzID0gKFxuICAgICAgICAgIHJlbGF0aXZlLmhvc3QgfHxcbiAgICAgICAgICByZWxhdGl2ZS5wYXRobmFtZSAmJiByZWxhdGl2ZS5wYXRobmFtZS5jaGFyQXQoMCkgPT09ICcvJ1xuICAgICAgKSxcbiAgICAgIG11c3RFbmRBYnMgPSAoaXNSZWxBYnMgfHwgaXNTb3VyY2VBYnMgfHxcbiAgICAgICAgICAgICAgICAgICAgKHJlc3VsdC5ob3N0ICYmIHJlbGF0aXZlLnBhdGhuYW1lKSksXG4gICAgICByZW1vdmVBbGxEb3RzID0gbXVzdEVuZEFicyxcbiAgICAgIHNyY1BhdGggPSByZXN1bHQucGF0aG5hbWUgJiYgcmVzdWx0LnBhdGhuYW1lLnNwbGl0KCcvJykgfHwgW10sXG4gICAgICByZWxQYXRoID0gcmVsYXRpdmUucGF0aG5hbWUgJiYgcmVsYXRpdmUucGF0aG5hbWUuc3BsaXQoJy8nKSB8fCBbXSxcbiAgICAgIHBzeWNob3RpYyA9IHJlc3VsdC5wcm90b2NvbCAmJiAhc2xhc2hlZFByb3RvY29sW3Jlc3VsdC5wcm90b2NvbF07XG5cbiAgLy8gaWYgdGhlIHVybCBpcyBhIG5vbi1zbGFzaGVkIHVybCwgdGhlbiByZWxhdGl2ZVxuICAvLyBsaW5rcyBsaWtlIC4uLy4uIHNob3VsZCBiZSBhYmxlXG4gIC8vIHRvIGNyYXdsIHVwIHRvIHRoZSBob3N0bmFtZSwgYXMgd2VsbC4gIFRoaXMgaXMgc3RyYW5nZS5cbiAgLy8gcmVzdWx0LnByb3RvY29sIGhhcyBhbHJlYWR5IGJlZW4gc2V0IGJ5IG5vdy5cbiAgLy8gTGF0ZXIgb24sIHB1dCB0aGUgZmlyc3QgcGF0aCBwYXJ0IGludG8gdGhlIGhvc3QgZmllbGQuXG4gIGlmIChwc3ljaG90aWMpIHtcbiAgICByZXN1bHQuaG9zdG5hbWUgPSAnJztcbiAgICByZXN1bHQucG9ydCA9IG51bGw7XG4gICAgaWYgKHJlc3VsdC5ob3N0KSB7XG4gICAgICBpZiAoc3JjUGF0aFswXSA9PT0gJycpIHNyY1BhdGhbMF0gPSByZXN1bHQuaG9zdDtcbiAgICAgIGVsc2Ugc3JjUGF0aC51bnNoaWZ0KHJlc3VsdC5ob3N0KTtcbiAgICB9XG4gICAgcmVzdWx0Lmhvc3QgPSAnJztcbiAgICBpZiAocmVsYXRpdmUucHJvdG9jb2wpIHtcbiAgICAgIHJlbGF0aXZlLmhvc3RuYW1lID0gbnVsbDtcbiAgICAgIHJlbGF0aXZlLnBvcnQgPSBudWxsO1xuICAgICAgaWYgKHJlbGF0aXZlLmhvc3QpIHtcbiAgICAgICAgaWYgKHJlbFBhdGhbMF0gPT09ICcnKSByZWxQYXRoWzBdID0gcmVsYXRpdmUuaG9zdDtcbiAgICAgICAgZWxzZSByZWxQYXRoLnVuc2hpZnQocmVsYXRpdmUuaG9zdCk7XG4gICAgICB9XG4gICAgICByZWxhdGl2ZS5ob3N0ID0gbnVsbDtcbiAgICB9XG4gICAgbXVzdEVuZEFicyA9IG11c3RFbmRBYnMgJiYgKHJlbFBhdGhbMF0gPT09ICcnIHx8IHNyY1BhdGhbMF0gPT09ICcnKTtcbiAgfVxuXG4gIGlmIChpc1JlbEFicykge1xuICAgIC8vIGl0J3MgYWJzb2x1dGUuXG4gICAgcmVzdWx0Lmhvc3QgPSAocmVsYXRpdmUuaG9zdCB8fCByZWxhdGl2ZS5ob3N0ID09PSAnJykgP1xuICAgICAgICAgICAgICAgICAgcmVsYXRpdmUuaG9zdCA6IHJlc3VsdC5ob3N0O1xuICAgIHJlc3VsdC5ob3N0bmFtZSA9IChyZWxhdGl2ZS5ob3N0bmFtZSB8fCByZWxhdGl2ZS5ob3N0bmFtZSA9PT0gJycpID9cbiAgICAgICAgICAgICAgICAgICAgICByZWxhdGl2ZS5ob3N0bmFtZSA6IHJlc3VsdC5ob3N0bmFtZTtcbiAgICByZXN1bHQuc2VhcmNoID0gcmVsYXRpdmUuc2VhcmNoO1xuICAgIHJlc3VsdC5xdWVyeSA9IHJlbGF0aXZlLnF1ZXJ5O1xuICAgIHNyY1BhdGggPSByZWxQYXRoO1xuICAgIC8vIGZhbGwgdGhyb3VnaCB0byB0aGUgZG90LWhhbmRsaW5nIGJlbG93LlxuICB9IGVsc2UgaWYgKHJlbFBhdGgubGVuZ3RoKSB7XG4gICAgLy8gaXQncyByZWxhdGl2ZVxuICAgIC8vIHRocm93IGF3YXkgdGhlIGV4aXN0aW5nIGZpbGUsIGFuZCB0YWtlIHRoZSBuZXcgcGF0aCBpbnN0ZWFkLlxuICAgIGlmICghc3JjUGF0aCkgc3JjUGF0aCA9IFtdO1xuICAgIHNyY1BhdGgucG9wKCk7XG4gICAgc3JjUGF0aCA9IHNyY1BhdGguY29uY2F0KHJlbFBhdGgpO1xuICAgIHJlc3VsdC5zZWFyY2ggPSByZWxhdGl2ZS5zZWFyY2g7XG4gICAgcmVzdWx0LnF1ZXJ5ID0gcmVsYXRpdmUucXVlcnk7XG4gIH0gZWxzZSBpZiAoIWlzTnVsbE9yVW5kZWZpbmVkKHJlbGF0aXZlLnNlYXJjaCkpIHtcbiAgICAvLyBqdXN0IHB1bGwgb3V0IHRoZSBzZWFyY2guXG4gICAgLy8gbGlrZSBocmVmPSc/Zm9vJy5cbiAgICAvLyBQdXQgdGhpcyBhZnRlciB0aGUgb3RoZXIgdHdvIGNhc2VzIGJlY2F1c2UgaXQgc2ltcGxpZmllcyB0aGUgYm9vbGVhbnNcbiAgICBpZiAocHN5Y2hvdGljKSB7XG4gICAgICByZXN1bHQuaG9zdG5hbWUgPSByZXN1bHQuaG9zdCA9IHNyY1BhdGguc2hpZnQoKTtcbiAgICAgIC8vb2NjYXRpb25hbHkgdGhlIGF1dGggY2FuIGdldCBzdHVjayBvbmx5IGluIGhvc3RcbiAgICAgIC8vdGhpcyBlc3BlY2lhbHkgaGFwcGVucyBpbiBjYXNlcyBsaWtlXG4gICAgICAvL3VybC5yZXNvbHZlT2JqZWN0KCdtYWlsdG86bG9jYWwxQGRvbWFpbjEnLCAnbG9jYWwyQGRvbWFpbjInKVxuICAgICAgdmFyIGF1dGhJbkhvc3QgPSByZXN1bHQuaG9zdCAmJiByZXN1bHQuaG9zdC5pbmRleE9mKCdAJykgPiAwID9cbiAgICAgICAgICAgICAgICAgICAgICAgcmVzdWx0Lmhvc3Quc3BsaXQoJ0AnKSA6IGZhbHNlO1xuICAgICAgaWYgKGF1dGhJbkhvc3QpIHtcbiAgICAgICAgcmVzdWx0LmF1dGggPSBhdXRoSW5Ib3N0LnNoaWZ0KCk7XG4gICAgICAgIHJlc3VsdC5ob3N0ID0gcmVzdWx0Lmhvc3RuYW1lID0gYXV0aEluSG9zdC5zaGlmdCgpO1xuICAgICAgfVxuICAgIH1cbiAgICByZXN1bHQuc2VhcmNoID0gcmVsYXRpdmUuc2VhcmNoO1xuICAgIHJlc3VsdC5xdWVyeSA9IHJlbGF0aXZlLnF1ZXJ5O1xuICAgIC8vdG8gc3VwcG9ydCBodHRwLnJlcXVlc3RcbiAgICBpZiAoIWlzTnVsbChyZXN1bHQucGF0aG5hbWUpIHx8ICFpc051bGwocmVzdWx0LnNlYXJjaCkpIHtcbiAgICAgIHJlc3VsdC5wYXRoID0gKHJlc3VsdC5wYXRobmFtZSA/IHJlc3VsdC5wYXRobmFtZSA6ICcnKSArXG4gICAgICAgICAgICAgICAgICAgIChyZXN1bHQuc2VhcmNoID8gcmVzdWx0LnNlYXJjaCA6ICcnKTtcbiAgICB9XG4gICAgcmVzdWx0LmhyZWYgPSByZXN1bHQuZm9ybWF0KCk7XG4gICAgcmV0dXJuIHJlc3VsdDtcbiAgfVxuXG4gIGlmICghc3JjUGF0aC5sZW5ndGgpIHtcbiAgICAvLyBubyBwYXRoIGF0IGFsbC4gIGVhc3kuXG4gICAgLy8gd2UndmUgYWxyZWFkeSBoYW5kbGVkIHRoZSBvdGhlciBzdHVmZiBhYm92ZS5cbiAgICByZXN1bHQucGF0aG5hbWUgPSBudWxsO1xuICAgIC8vdG8gc3VwcG9ydCBodHRwLnJlcXVlc3RcbiAgICBpZiAocmVzdWx0LnNlYXJjaCkge1xuICAgICAgcmVzdWx0LnBhdGggPSAnLycgKyByZXN1bHQuc2VhcmNoO1xuICAgIH0gZWxzZSB7XG4gICAgICByZXN1bHQucGF0aCA9IG51bGw7XG4gICAgfVxuICAgIHJlc3VsdC5ocmVmID0gcmVzdWx0LmZvcm1hdCgpO1xuICAgIHJldHVybiByZXN1bHQ7XG4gIH1cblxuICAvLyBpZiBhIHVybCBFTkRzIGluIC4gb3IgLi4sIHRoZW4gaXQgbXVzdCBnZXQgYSB0cmFpbGluZyBzbGFzaC5cbiAgLy8gaG93ZXZlciwgaWYgaXQgZW5kcyBpbiBhbnl0aGluZyBlbHNlIG5vbi1zbGFzaHksXG4gIC8vIHRoZW4gaXQgbXVzdCBOT1QgZ2V0IGEgdHJhaWxpbmcgc2xhc2guXG4gIHZhciBsYXN0ID0gc3JjUGF0aC5zbGljZSgtMSlbMF07XG4gIHZhciBoYXNUcmFpbGluZ1NsYXNoID0gKFxuICAgICAgKHJlc3VsdC5ob3N0IHx8IHJlbGF0aXZlLmhvc3QpICYmIChsYXN0ID09PSAnLicgfHwgbGFzdCA9PT0gJy4uJykgfHxcbiAgICAgIGxhc3QgPT09ICcnKTtcblxuICAvLyBzdHJpcCBzaW5nbGUgZG90cywgcmVzb2x2ZSBkb3VibGUgZG90cyB0byBwYXJlbnQgZGlyXG4gIC8vIGlmIHRoZSBwYXRoIHRyaWVzIHRvIGdvIGFib3ZlIHRoZSByb290LCBgdXBgIGVuZHMgdXAgPiAwXG4gIHZhciB1cCA9IDA7XG4gIGZvciAodmFyIGkgPSBzcmNQYXRoLmxlbmd0aDsgaSA+PSAwOyBpLS0pIHtcbiAgICBsYXN0ID0gc3JjUGF0aFtpXTtcbiAgICBpZiAobGFzdCA9PSAnLicpIHtcbiAgICAgIHNyY1BhdGguc3BsaWNlKGksIDEpO1xuICAgIH0gZWxzZSBpZiAobGFzdCA9PT0gJy4uJykge1xuICAgICAgc3JjUGF0aC5zcGxpY2UoaSwgMSk7XG4gICAgICB1cCsrO1xuICAgIH0gZWxzZSBpZiAodXApIHtcbiAgICAgIHNyY1BhdGguc3BsaWNlKGksIDEpO1xuICAgICAgdXAtLTtcbiAgICB9XG4gIH1cblxuICAvLyBpZiB0aGUgcGF0aCBpcyBhbGxvd2VkIHRvIGdvIGFib3ZlIHRoZSByb290LCByZXN0b3JlIGxlYWRpbmcgLi5zXG4gIGlmICghbXVzdEVuZEFicyAmJiAhcmVtb3ZlQWxsRG90cykge1xuICAgIGZvciAoOyB1cC0tOyB1cCkge1xuICAgICAgc3JjUGF0aC51bnNoaWZ0KCcuLicpO1xuICAgIH1cbiAgfVxuXG4gIGlmIChtdXN0RW5kQWJzICYmIHNyY1BhdGhbMF0gIT09ICcnICYmXG4gICAgICAoIXNyY1BhdGhbMF0gfHwgc3JjUGF0aFswXS5jaGFyQXQoMCkgIT09ICcvJykpIHtcbiAgICBzcmNQYXRoLnVuc2hpZnQoJycpO1xuICB9XG5cbiAgaWYgKGhhc1RyYWlsaW5nU2xhc2ggJiYgKHNyY1BhdGguam9pbignLycpLnN1YnN0cigtMSkgIT09ICcvJykpIHtcbiAgICBzcmNQYXRoLnB1c2goJycpO1xuICB9XG5cbiAgdmFyIGlzQWJzb2x1dGUgPSBzcmNQYXRoWzBdID09PSAnJyB8fFxuICAgICAgKHNyY1BhdGhbMF0gJiYgc3JjUGF0aFswXS5jaGFyQXQoMCkgPT09ICcvJyk7XG5cbiAgLy8gcHV0IHRoZSBob3N0IGJhY2tcbiAgaWYgKHBzeWNob3RpYykge1xuICAgIHJlc3VsdC5ob3N0bmFtZSA9IHJlc3VsdC5ob3N0ID0gaXNBYnNvbHV0ZSA/ICcnIDpcbiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIHNyY1BhdGgubGVuZ3RoID8gc3JjUGF0aC5zaGlmdCgpIDogJyc7XG4gICAgLy9vY2NhdGlvbmFseSB0aGUgYXV0aCBjYW4gZ2V0IHN0dWNrIG9ubHkgaW4gaG9zdFxuICAgIC8vdGhpcyBlc3BlY2lhbHkgaGFwcGVucyBpbiBjYXNlcyBsaWtlXG4gICAgLy91cmwucmVzb2x2ZU9iamVjdCgnbWFpbHRvOmxvY2FsMUBkb21haW4xJywgJ2xvY2FsMkBkb21haW4yJylcbiAgICB2YXIgYXV0aEluSG9zdCA9IHJlc3VsdC5ob3N0ICYmIHJlc3VsdC5ob3N0LmluZGV4T2YoJ0AnKSA+IDAgP1xuICAgICAgICAgICAgICAgICAgICAgcmVzdWx0Lmhvc3Quc3BsaXQoJ0AnKSA6IGZhbHNlO1xuICAgIGlmIChhdXRoSW5Ib3N0KSB7XG4gICAgICByZXN1bHQuYXV0aCA9IGF1dGhJbkhvc3Quc2hpZnQoKTtcbiAgICAgIHJlc3VsdC5ob3N0ID0gcmVzdWx0Lmhvc3RuYW1lID0gYXV0aEluSG9zdC5zaGlmdCgpO1xuICAgIH1cbiAgfVxuXG4gIG11c3RFbmRBYnMgPSBtdXN0RW5kQWJzIHx8IChyZXN1bHQuaG9zdCAmJiBzcmNQYXRoLmxlbmd0aCk7XG5cbiAgaWYgKG11c3RFbmRBYnMgJiYgIWlzQWJzb2x1dGUpIHtcbiAgICBzcmNQYXRoLnVuc2hpZnQoJycpO1xuICB9XG5cbiAgaWYgKCFzcmNQYXRoLmxlbmd0aCkge1xuICAgIHJlc3VsdC5wYXRobmFtZSA9IG51bGw7XG4gICAgcmVzdWx0LnBhdGggPSBudWxsO1xuICB9IGVsc2Uge1xuICAgIHJlc3VsdC5wYXRobmFtZSA9IHNyY1BhdGguam9pbignLycpO1xuICB9XG5cbiAgLy90byBzdXBwb3J0IHJlcXVlc3QuaHR0cFxuICBpZiAoIWlzTnVsbChyZXN1bHQucGF0aG5hbWUpIHx8ICFpc051bGwocmVzdWx0LnNlYXJjaCkpIHtcbiAgICByZXN1bHQucGF0aCA9IChyZXN1bHQucGF0aG5hbWUgPyByZXN1bHQucGF0aG5hbWUgOiAnJykgK1xuICAgICAgICAgICAgICAgICAgKHJlc3VsdC5zZWFyY2ggPyByZXN1bHQuc2VhcmNoIDogJycpO1xuICB9XG4gIHJlc3VsdC5hdXRoID0gcmVsYXRpdmUuYXV0aCB8fCByZXN1bHQuYXV0aDtcbiAgcmVzdWx0LnNsYXNoZXMgPSByZXN1bHQuc2xhc2hlcyB8fCByZWxhdGl2ZS5zbGFzaGVzO1xuICByZXN1bHQuaHJlZiA9IHJlc3VsdC5mb3JtYXQoKTtcbiAgcmV0dXJuIHJlc3VsdDtcbn07XG5cblVybC5wcm90b3R5cGUucGFyc2VIb3N0ID0gZnVuY3Rpb24oKSB7XG4gIHZhciBob3N0ID0gdGhpcy5ob3N0O1xuICB2YXIgcG9ydCA9IHBvcnRQYXR0ZXJuLmV4ZWMoaG9zdCk7XG4gIGlmIChwb3J0KSB7XG4gICAgcG9ydCA9IHBvcnRbMF07XG4gICAgaWYgKHBvcnQgIT09ICc6Jykge1xuICAgICAgdGhpcy5wb3J0ID0gcG9ydC5zdWJzdHIoMSk7XG4gICAgfVxuICAgIGhvc3QgPSBob3N0LnN1YnN0cigwLCBob3N0Lmxlbmd0aCAtIHBvcnQubGVuZ3RoKTtcbiAgfVxuICBpZiAoaG9zdCkgdGhpcy5ob3N0bmFtZSA9IGhvc3Q7XG59O1xuXG5mdW5jdGlvbiBpc1N0cmluZyhhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09IFwic3RyaW5nXCI7XG59XG5cbmZ1bmN0aW9uIGlzT2JqZWN0KGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ29iamVjdCcgJiYgYXJnICE9PSBudWxsO1xufVxuXG5mdW5jdGlvbiBpc051bGwoYXJnKSB7XG4gIHJldHVybiBhcmcgPT09IG51bGw7XG59XG5mdW5jdGlvbiBpc051bGxPclVuZGVmaW5lZChhcmcpIHtcbiAgcmV0dXJuICBhcmcgPT0gbnVsbDtcbn1cbiIsIm1vZHVsZS5leHBvcnRzID0gZnVuY3Rpb24gaXNCdWZmZXIoYXJnKSB7XG4gIHJldHVybiBhcmcgJiYgdHlwZW9mIGFyZyA9PT0gJ29iamVjdCdcbiAgICAmJiB0eXBlb2YgYXJnLmNvcHkgPT09ICdmdW5jdGlvbidcbiAgICAmJiB0eXBlb2YgYXJnLmZpbGwgPT09ICdmdW5jdGlvbidcbiAgICAmJiB0eXBlb2YgYXJnLnJlYWRVSW50OCA9PT0gJ2Z1bmN0aW9uJztcbn0iLCIoZnVuY3Rpb24gKHByb2Nlc3MsZ2xvYmFsKXtcbi8vIENvcHlyaWdodCBKb3llbnQsIEluYy4gYW5kIG90aGVyIE5vZGUgY29udHJpYnV0b3JzLlxuLy9cbi8vIFBlcm1pc3Npb24gaXMgaGVyZWJ5IGdyYW50ZWQsIGZyZWUgb2YgY2hhcmdlLCB0byBhbnkgcGVyc29uIG9idGFpbmluZyBhXG4vLyBjb3B5IG9mIHRoaXMgc29mdHdhcmUgYW5kIGFzc29jaWF0ZWQgZG9jdW1lbnRhdGlvbiBmaWxlcyAodGhlXG4vLyBcIlNvZnR3YXJlXCIpLCB0byBkZWFsIGluIHRoZSBTb2Z0d2FyZSB3aXRob3V0IHJlc3RyaWN0aW9uLCBpbmNsdWRpbmdcbi8vIHdpdGhvdXQgbGltaXRhdGlvbiB0aGUgcmlnaHRzIHRvIHVzZSwgY29weSwgbW9kaWZ5LCBtZXJnZSwgcHVibGlzaCxcbi8vIGRpc3RyaWJ1dGUsIHN1YmxpY2Vuc2UsIGFuZC9vciBzZWxsIGNvcGllcyBvZiB0aGUgU29mdHdhcmUsIGFuZCB0byBwZXJtaXRcbi8vIHBlcnNvbnMgdG8gd2hvbSB0aGUgU29mdHdhcmUgaXMgZnVybmlzaGVkIHRvIGRvIHNvLCBzdWJqZWN0IHRvIHRoZVxuLy8gZm9sbG93aW5nIGNvbmRpdGlvbnM6XG4vL1xuLy8gVGhlIGFib3ZlIGNvcHlyaWdodCBub3RpY2UgYW5kIHRoaXMgcGVybWlzc2lvbiBub3RpY2Ugc2hhbGwgYmUgaW5jbHVkZWRcbi8vIGluIGFsbCBjb3BpZXMgb3Igc3Vic3RhbnRpYWwgcG9ydGlvbnMgb2YgdGhlIFNvZnR3YXJlLlxuLy9cbi8vIFRIRSBTT0ZUV0FSRSBJUyBQUk9WSURFRCBcIkFTIElTXCIsIFdJVEhPVVQgV0FSUkFOVFkgT0YgQU5ZIEtJTkQsIEVYUFJFU1Ncbi8vIE9SIElNUExJRUQsIElOQ0xVRElORyBCVVQgTk9UIExJTUlURUQgVE8gVEhFIFdBUlJBTlRJRVMgT0Zcbi8vIE1FUkNIQU5UQUJJTElUWSwgRklUTkVTUyBGT1IgQSBQQVJUSUNVTEFSIFBVUlBPU0UgQU5EIE5PTklORlJJTkdFTUVOVC4gSU5cbi8vIE5PIEVWRU5UIFNIQUxMIFRIRSBBVVRIT1JTIE9SIENPUFlSSUdIVCBIT0xERVJTIEJFIExJQUJMRSBGT1IgQU5ZIENMQUlNLFxuLy8gREFNQUdFUyBPUiBPVEhFUiBMSUFCSUxJVFksIFdIRVRIRVIgSU4gQU4gQUNUSU9OIE9GIENPTlRSQUNULCBUT1JUIE9SXG4vLyBPVEhFUldJU0UsIEFSSVNJTkcgRlJPTSwgT1VUIE9GIE9SIElOIENPTk5FQ1RJT04gV0lUSCBUSEUgU09GVFdBUkUgT1IgVEhFXG4vLyBVU0UgT1IgT1RIRVIgREVBTElOR1MgSU4gVEhFIFNPRlRXQVJFLlxuXG52YXIgZm9ybWF0UmVnRXhwID0gLyVbc2RqJV0vZztcbmV4cG9ydHMuZm9ybWF0ID0gZnVuY3Rpb24oZikge1xuICBpZiAoIWlzU3RyaW5nKGYpKSB7XG4gICAgdmFyIG9iamVjdHMgPSBbXTtcbiAgICBmb3IgKHZhciBpID0gMDsgaSA8IGFyZ3VtZW50cy5sZW5ndGg7IGkrKykge1xuICAgICAgb2JqZWN0cy5wdXNoKGluc3BlY3QoYXJndW1lbnRzW2ldKSk7XG4gICAgfVxuICAgIHJldHVybiBvYmplY3RzLmpvaW4oJyAnKTtcbiAgfVxuXG4gIHZhciBpID0gMTtcbiAgdmFyIGFyZ3MgPSBhcmd1bWVudHM7XG4gIHZhciBsZW4gPSBhcmdzLmxlbmd0aDtcbiAgdmFyIHN0ciA9IFN0cmluZyhmKS5yZXBsYWNlKGZvcm1hdFJlZ0V4cCwgZnVuY3Rpb24oeCkge1xuICAgIGlmICh4ID09PSAnJSUnKSByZXR1cm4gJyUnO1xuICAgIGlmIChpID49IGxlbikgcmV0dXJuIHg7XG4gICAgc3dpdGNoICh4KSB7XG4gICAgICBjYXNlICclcyc6IHJldHVybiBTdHJpbmcoYXJnc1tpKytdKTtcbiAgICAgIGNhc2UgJyVkJzogcmV0dXJuIE51bWJlcihhcmdzW2krK10pO1xuICAgICAgY2FzZSAnJWonOlxuICAgICAgICB0cnkge1xuICAgICAgICAgIHJldHVybiBKU09OLnN0cmluZ2lmeShhcmdzW2krK10pO1xuICAgICAgICB9IGNhdGNoIChfKSB7XG4gICAgICAgICAgcmV0dXJuICdbQ2lyY3VsYXJdJztcbiAgICAgICAgfVxuICAgICAgZGVmYXVsdDpcbiAgICAgICAgcmV0dXJuIHg7XG4gICAgfVxuICB9KTtcbiAgZm9yICh2YXIgeCA9IGFyZ3NbaV07IGkgPCBsZW47IHggPSBhcmdzWysraV0pIHtcbiAgICBpZiAoaXNOdWxsKHgpIHx8ICFpc09iamVjdCh4KSkge1xuICAgICAgc3RyICs9ICcgJyArIHg7XG4gICAgfSBlbHNlIHtcbiAgICAgIHN0ciArPSAnICcgKyBpbnNwZWN0KHgpO1xuICAgIH1cbiAgfVxuICByZXR1cm4gc3RyO1xufTtcblxuXG4vLyBNYXJrIHRoYXQgYSBtZXRob2Qgc2hvdWxkIG5vdCBiZSB1c2VkLlxuLy8gUmV0dXJucyBhIG1vZGlmaWVkIGZ1bmN0aW9uIHdoaWNoIHdhcm5zIG9uY2UgYnkgZGVmYXVsdC5cbi8vIElmIC0tbm8tZGVwcmVjYXRpb24gaXMgc2V0LCB0aGVuIGl0IGlzIGEgbm8tb3AuXG5leHBvcnRzLmRlcHJlY2F0ZSA9IGZ1bmN0aW9uKGZuLCBtc2cpIHtcbiAgLy8gQWxsb3cgZm9yIGRlcHJlY2F0aW5nIHRoaW5ncyBpbiB0aGUgcHJvY2VzcyBvZiBzdGFydGluZyB1cC5cbiAgaWYgKGlzVW5kZWZpbmVkKGdsb2JhbC5wcm9jZXNzKSkge1xuICAgIHJldHVybiBmdW5jdGlvbigpIHtcbiAgICAgIHJldHVybiBleHBvcnRzLmRlcHJlY2F0ZShmbiwgbXNnKS5hcHBseSh0aGlzLCBhcmd1bWVudHMpO1xuICAgIH07XG4gIH1cblxuICBpZiAocHJvY2Vzcy5ub0RlcHJlY2F0aW9uID09PSB0cnVlKSB7XG4gICAgcmV0dXJuIGZuO1xuICB9XG5cbiAgdmFyIHdhcm5lZCA9IGZhbHNlO1xuICBmdW5jdGlvbiBkZXByZWNhdGVkKCkge1xuICAgIGlmICghd2FybmVkKSB7XG4gICAgICBpZiAocHJvY2Vzcy50aHJvd0RlcHJlY2F0aW9uKSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcihtc2cpO1xuICAgICAgfSBlbHNlIGlmIChwcm9jZXNzLnRyYWNlRGVwcmVjYXRpb24pIHtcbiAgICAgICAgY29uc29sZS50cmFjZShtc2cpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgY29uc29sZS5lcnJvcihtc2cpO1xuICAgICAgfVxuICAgICAgd2FybmVkID0gdHJ1ZTtcbiAgICB9XG4gICAgcmV0dXJuIGZuLmFwcGx5KHRoaXMsIGFyZ3VtZW50cyk7XG4gIH1cblxuICByZXR1cm4gZGVwcmVjYXRlZDtcbn07XG5cblxudmFyIGRlYnVncyA9IHt9O1xudmFyIGRlYnVnRW52aXJvbjtcbmV4cG9ydHMuZGVidWdsb2cgPSBmdW5jdGlvbihzZXQpIHtcbiAgaWYgKGlzVW5kZWZpbmVkKGRlYnVnRW52aXJvbikpXG4gICAgZGVidWdFbnZpcm9uID0gcHJvY2Vzcy5lbnYuTk9ERV9ERUJVRyB8fCAnJztcbiAgc2V0ID0gc2V0LnRvVXBwZXJDYXNlKCk7XG4gIGlmICghZGVidWdzW3NldF0pIHtcbiAgICBpZiAobmV3IFJlZ0V4cCgnXFxcXGInICsgc2V0ICsgJ1xcXFxiJywgJ2knKS50ZXN0KGRlYnVnRW52aXJvbikpIHtcbiAgICAgIHZhciBwaWQgPSBwcm9jZXNzLnBpZDtcbiAgICAgIGRlYnVnc1tzZXRdID0gZnVuY3Rpb24oKSB7XG4gICAgICAgIHZhciBtc2cgPSBleHBvcnRzLmZvcm1hdC5hcHBseShleHBvcnRzLCBhcmd1bWVudHMpO1xuICAgICAgICBjb25zb2xlLmVycm9yKCclcyAlZDogJXMnLCBzZXQsIHBpZCwgbXNnKTtcbiAgICAgIH07XG4gICAgfSBlbHNlIHtcbiAgICAgIGRlYnVnc1tzZXRdID0gZnVuY3Rpb24oKSB7fTtcbiAgICB9XG4gIH1cbiAgcmV0dXJuIGRlYnVnc1tzZXRdO1xufTtcblxuXG4vKipcbiAqIEVjaG9zIHRoZSB2YWx1ZSBvZiBhIHZhbHVlLiBUcnlzIHRvIHByaW50IHRoZSB2YWx1ZSBvdXRcbiAqIGluIHRoZSBiZXN0IHdheSBwb3NzaWJsZSBnaXZlbiB0aGUgZGlmZmVyZW50IHR5cGVzLlxuICpcbiAqIEBwYXJhbSB7T2JqZWN0fSBvYmogVGhlIG9iamVjdCB0byBwcmludCBvdXQuXG4gKiBAcGFyYW0ge09iamVjdH0gb3B0cyBPcHRpb25hbCBvcHRpb25zIG9iamVjdCB0aGF0IGFsdGVycyB0aGUgb3V0cHV0LlxuICovXG4vKiBsZWdhY3k6IG9iaiwgc2hvd0hpZGRlbiwgZGVwdGgsIGNvbG9ycyovXG5mdW5jdGlvbiBpbnNwZWN0KG9iaiwgb3B0cykge1xuICAvLyBkZWZhdWx0IG9wdGlvbnNcbiAgdmFyIGN0eCA9IHtcbiAgICBzZWVuOiBbXSxcbiAgICBzdHlsaXplOiBzdHlsaXplTm9Db2xvclxuICB9O1xuICAvLyBsZWdhY3kuLi5cbiAgaWYgKGFyZ3VtZW50cy5sZW5ndGggPj0gMykgY3R4LmRlcHRoID0gYXJndW1lbnRzWzJdO1xuICBpZiAoYXJndW1lbnRzLmxlbmd0aCA+PSA0KSBjdHguY29sb3JzID0gYXJndW1lbnRzWzNdO1xuICBpZiAoaXNCb29sZWFuKG9wdHMpKSB7XG4gICAgLy8gbGVnYWN5Li4uXG4gICAgY3R4LnNob3dIaWRkZW4gPSBvcHRzO1xuICB9IGVsc2UgaWYgKG9wdHMpIHtcbiAgICAvLyBnb3QgYW4gXCJvcHRpb25zXCIgb2JqZWN0XG4gICAgZXhwb3J0cy5fZXh0ZW5kKGN0eCwgb3B0cyk7XG4gIH1cbiAgLy8gc2V0IGRlZmF1bHQgb3B0aW9uc1xuICBpZiAoaXNVbmRlZmluZWQoY3R4LnNob3dIaWRkZW4pKSBjdHguc2hvd0hpZGRlbiA9IGZhbHNlO1xuICBpZiAoaXNVbmRlZmluZWQoY3R4LmRlcHRoKSkgY3R4LmRlcHRoID0gMjtcbiAgaWYgKGlzVW5kZWZpbmVkKGN0eC5jb2xvcnMpKSBjdHguY29sb3JzID0gZmFsc2U7XG4gIGlmIChpc1VuZGVmaW5lZChjdHguY3VzdG9tSW5zcGVjdCkpIGN0eC5jdXN0b21JbnNwZWN0ID0gdHJ1ZTtcbiAgaWYgKGN0eC5jb2xvcnMpIGN0eC5zdHlsaXplID0gc3R5bGl6ZVdpdGhDb2xvcjtcbiAgcmV0dXJuIGZvcm1hdFZhbHVlKGN0eCwgb2JqLCBjdHguZGVwdGgpO1xufVxuZXhwb3J0cy5pbnNwZWN0ID0gaW5zcGVjdDtcblxuXG4vLyBodHRwOi8vZW4ud2lraXBlZGlhLm9yZy93aWtpL0FOU0lfZXNjYXBlX2NvZGUjZ3JhcGhpY3Ncbmluc3BlY3QuY29sb3JzID0ge1xuICAnYm9sZCcgOiBbMSwgMjJdLFxuICAnaXRhbGljJyA6IFszLCAyM10sXG4gICd1bmRlcmxpbmUnIDogWzQsIDI0XSxcbiAgJ2ludmVyc2UnIDogWzcsIDI3XSxcbiAgJ3doaXRlJyA6IFszNywgMzldLFxuICAnZ3JleScgOiBbOTAsIDM5XSxcbiAgJ2JsYWNrJyA6IFszMCwgMzldLFxuICAnYmx1ZScgOiBbMzQsIDM5XSxcbiAgJ2N5YW4nIDogWzM2LCAzOV0sXG4gICdncmVlbicgOiBbMzIsIDM5XSxcbiAgJ21hZ2VudGEnIDogWzM1LCAzOV0sXG4gICdyZWQnIDogWzMxLCAzOV0sXG4gICd5ZWxsb3cnIDogWzMzLCAzOV1cbn07XG5cbi8vIERvbid0IHVzZSAnYmx1ZScgbm90IHZpc2libGUgb24gY21kLmV4ZVxuaW5zcGVjdC5zdHlsZXMgPSB7XG4gICdzcGVjaWFsJzogJ2N5YW4nLFxuICAnbnVtYmVyJzogJ3llbGxvdycsXG4gICdib29sZWFuJzogJ3llbGxvdycsXG4gICd1bmRlZmluZWQnOiAnZ3JleScsXG4gICdudWxsJzogJ2JvbGQnLFxuICAnc3RyaW5nJzogJ2dyZWVuJyxcbiAgJ2RhdGUnOiAnbWFnZW50YScsXG4gIC8vIFwibmFtZVwiOiBpbnRlbnRpb25hbGx5IG5vdCBzdHlsaW5nXG4gICdyZWdleHAnOiAncmVkJ1xufTtcblxuXG5mdW5jdGlvbiBzdHlsaXplV2l0aENvbG9yKHN0ciwgc3R5bGVUeXBlKSB7XG4gIHZhciBzdHlsZSA9IGluc3BlY3Quc3R5bGVzW3N0eWxlVHlwZV07XG5cbiAgaWYgKHN0eWxlKSB7XG4gICAgcmV0dXJuICdcXHUwMDFiWycgKyBpbnNwZWN0LmNvbG9yc1tzdHlsZV1bMF0gKyAnbScgKyBzdHIgK1xuICAgICAgICAgICAnXFx1MDAxYlsnICsgaW5zcGVjdC5jb2xvcnNbc3R5bGVdWzFdICsgJ20nO1xuICB9IGVsc2Uge1xuICAgIHJldHVybiBzdHI7XG4gIH1cbn1cblxuXG5mdW5jdGlvbiBzdHlsaXplTm9Db2xvcihzdHIsIHN0eWxlVHlwZSkge1xuICByZXR1cm4gc3RyO1xufVxuXG5cbmZ1bmN0aW9uIGFycmF5VG9IYXNoKGFycmF5KSB7XG4gIHZhciBoYXNoID0ge307XG5cbiAgYXJyYXkuZm9yRWFjaChmdW5jdGlvbih2YWwsIGlkeCkge1xuICAgIGhhc2hbdmFsXSA9IHRydWU7XG4gIH0pO1xuXG4gIHJldHVybiBoYXNoO1xufVxuXG5cbmZ1bmN0aW9uIGZvcm1hdFZhbHVlKGN0eCwgdmFsdWUsIHJlY3Vyc2VUaW1lcykge1xuICAvLyBQcm92aWRlIGEgaG9vayBmb3IgdXNlci1zcGVjaWZpZWQgaW5zcGVjdCBmdW5jdGlvbnMuXG4gIC8vIENoZWNrIHRoYXQgdmFsdWUgaXMgYW4gb2JqZWN0IHdpdGggYW4gaW5zcGVjdCBmdW5jdGlvbiBvbiBpdFxuICBpZiAoY3R4LmN1c3RvbUluc3BlY3QgJiZcbiAgICAgIHZhbHVlICYmXG4gICAgICBpc0Z1bmN0aW9uKHZhbHVlLmluc3BlY3QpICYmXG4gICAgICAvLyBGaWx0ZXIgb3V0IHRoZSB1dGlsIG1vZHVsZSwgaXQncyBpbnNwZWN0IGZ1bmN0aW9uIGlzIHNwZWNpYWxcbiAgICAgIHZhbHVlLmluc3BlY3QgIT09IGV4cG9ydHMuaW5zcGVjdCAmJlxuICAgICAgLy8gQWxzbyBmaWx0ZXIgb3V0IGFueSBwcm90b3R5cGUgb2JqZWN0cyB1c2luZyB0aGUgY2lyY3VsYXIgY2hlY2suXG4gICAgICAhKHZhbHVlLmNvbnN0cnVjdG9yICYmIHZhbHVlLmNvbnN0cnVjdG9yLnByb3RvdHlwZSA9PT0gdmFsdWUpKSB7XG4gICAgdmFyIHJldCA9IHZhbHVlLmluc3BlY3QocmVjdXJzZVRpbWVzLCBjdHgpO1xuICAgIGlmICghaXNTdHJpbmcocmV0KSkge1xuICAgICAgcmV0ID0gZm9ybWF0VmFsdWUoY3R4LCByZXQsIHJlY3Vyc2VUaW1lcyk7XG4gICAgfVxuICAgIHJldHVybiByZXQ7XG4gIH1cblxuICAvLyBQcmltaXRpdmUgdHlwZXMgY2Fubm90IGhhdmUgcHJvcGVydGllc1xuICB2YXIgcHJpbWl0aXZlID0gZm9ybWF0UHJpbWl0aXZlKGN0eCwgdmFsdWUpO1xuICBpZiAocHJpbWl0aXZlKSB7XG4gICAgcmV0dXJuIHByaW1pdGl2ZTtcbiAgfVxuXG4gIC8vIExvb2sgdXAgdGhlIGtleXMgb2YgdGhlIG9iamVjdC5cbiAgdmFyIGtleXMgPSBPYmplY3Qua2V5cyh2YWx1ZSk7XG4gIHZhciB2aXNpYmxlS2V5cyA9IGFycmF5VG9IYXNoKGtleXMpO1xuXG4gIGlmIChjdHguc2hvd0hpZGRlbikge1xuICAgIGtleXMgPSBPYmplY3QuZ2V0T3duUHJvcGVydHlOYW1lcyh2YWx1ZSk7XG4gIH1cblxuICAvLyBJRSBkb2Vzbid0IG1ha2UgZXJyb3IgZmllbGRzIG5vbi1lbnVtZXJhYmxlXG4gIC8vIGh0dHA6Ly9tc2RuLm1pY3Jvc29mdC5jb20vZW4tdXMvbGlicmFyeS9pZS9kd3c1MnNidCh2PXZzLjk0KS5hc3B4XG4gIGlmIChpc0Vycm9yKHZhbHVlKVxuICAgICAgJiYgKGtleXMuaW5kZXhPZignbWVzc2FnZScpID49IDAgfHwga2V5cy5pbmRleE9mKCdkZXNjcmlwdGlvbicpID49IDApKSB7XG4gICAgcmV0dXJuIGZvcm1hdEVycm9yKHZhbHVlKTtcbiAgfVxuXG4gIC8vIFNvbWUgdHlwZSBvZiBvYmplY3Qgd2l0aG91dCBwcm9wZXJ0aWVzIGNhbiBiZSBzaG9ydGN1dHRlZC5cbiAgaWYgKGtleXMubGVuZ3RoID09PSAwKSB7XG4gICAgaWYgKGlzRnVuY3Rpb24odmFsdWUpKSB7XG4gICAgICB2YXIgbmFtZSA9IHZhbHVlLm5hbWUgPyAnOiAnICsgdmFsdWUubmFtZSA6ICcnO1xuICAgICAgcmV0dXJuIGN0eC5zdHlsaXplKCdbRnVuY3Rpb24nICsgbmFtZSArICddJywgJ3NwZWNpYWwnKTtcbiAgICB9XG4gICAgaWYgKGlzUmVnRXhwKHZhbHVlKSkge1xuICAgICAgcmV0dXJuIGN0eC5zdHlsaXplKFJlZ0V4cC5wcm90b3R5cGUudG9TdHJpbmcuY2FsbCh2YWx1ZSksICdyZWdleHAnKTtcbiAgICB9XG4gICAgaWYgKGlzRGF0ZSh2YWx1ZSkpIHtcbiAgICAgIHJldHVybiBjdHguc3R5bGl6ZShEYXRlLnByb3RvdHlwZS50b1N0cmluZy5jYWxsKHZhbHVlKSwgJ2RhdGUnKTtcbiAgICB9XG4gICAgaWYgKGlzRXJyb3IodmFsdWUpKSB7XG4gICAgICByZXR1cm4gZm9ybWF0RXJyb3IodmFsdWUpO1xuICAgIH1cbiAgfVxuXG4gIHZhciBiYXNlID0gJycsIGFycmF5ID0gZmFsc2UsIGJyYWNlcyA9IFsneycsICd9J107XG5cbiAgLy8gTWFrZSBBcnJheSBzYXkgdGhhdCB0aGV5IGFyZSBBcnJheVxuICBpZiAoaXNBcnJheSh2YWx1ZSkpIHtcbiAgICBhcnJheSA9IHRydWU7XG4gICAgYnJhY2VzID0gWydbJywgJ10nXTtcbiAgfVxuXG4gIC8vIE1ha2UgZnVuY3Rpb25zIHNheSB0aGF0IHRoZXkgYXJlIGZ1bmN0aW9uc1xuICBpZiAoaXNGdW5jdGlvbih2YWx1ZSkpIHtcbiAgICB2YXIgbiA9IHZhbHVlLm5hbWUgPyAnOiAnICsgdmFsdWUubmFtZSA6ICcnO1xuICAgIGJhc2UgPSAnIFtGdW5jdGlvbicgKyBuICsgJ10nO1xuICB9XG5cbiAgLy8gTWFrZSBSZWdFeHBzIHNheSB0aGF0IHRoZXkgYXJlIFJlZ0V4cHNcbiAgaWYgKGlzUmVnRXhwKHZhbHVlKSkge1xuICAgIGJhc2UgPSAnICcgKyBSZWdFeHAucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwodmFsdWUpO1xuICB9XG5cbiAgLy8gTWFrZSBkYXRlcyB3aXRoIHByb3BlcnRpZXMgZmlyc3Qgc2F5IHRoZSBkYXRlXG4gIGlmIChpc0RhdGUodmFsdWUpKSB7XG4gICAgYmFzZSA9ICcgJyArIERhdGUucHJvdG90eXBlLnRvVVRDU3RyaW5nLmNhbGwodmFsdWUpO1xuICB9XG5cbiAgLy8gTWFrZSBlcnJvciB3aXRoIG1lc3NhZ2UgZmlyc3Qgc2F5IHRoZSBlcnJvclxuICBpZiAoaXNFcnJvcih2YWx1ZSkpIHtcbiAgICBiYXNlID0gJyAnICsgZm9ybWF0RXJyb3IodmFsdWUpO1xuICB9XG5cbiAgaWYgKGtleXMubGVuZ3RoID09PSAwICYmICghYXJyYXkgfHwgdmFsdWUubGVuZ3RoID09IDApKSB7XG4gICAgcmV0dXJuIGJyYWNlc1swXSArIGJhc2UgKyBicmFjZXNbMV07XG4gIH1cblxuICBpZiAocmVjdXJzZVRpbWVzIDwgMCkge1xuICAgIGlmIChpc1JlZ0V4cCh2YWx1ZSkpIHtcbiAgICAgIHJldHVybiBjdHguc3R5bGl6ZShSZWdFeHAucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwodmFsdWUpLCAncmVnZXhwJyk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHJldHVybiBjdHguc3R5bGl6ZSgnW09iamVjdF0nLCAnc3BlY2lhbCcpO1xuICAgIH1cbiAgfVxuXG4gIGN0eC5zZWVuLnB1c2godmFsdWUpO1xuXG4gIHZhciBvdXRwdXQ7XG4gIGlmIChhcnJheSkge1xuICAgIG91dHB1dCA9IGZvcm1hdEFycmF5KGN0eCwgdmFsdWUsIHJlY3Vyc2VUaW1lcywgdmlzaWJsZUtleXMsIGtleXMpO1xuICB9IGVsc2Uge1xuICAgIG91dHB1dCA9IGtleXMubWFwKGZ1bmN0aW9uKGtleSkge1xuICAgICAgcmV0dXJuIGZvcm1hdFByb3BlcnR5KGN0eCwgdmFsdWUsIHJlY3Vyc2VUaW1lcywgdmlzaWJsZUtleXMsIGtleSwgYXJyYXkpO1xuICAgIH0pO1xuICB9XG5cbiAgY3R4LnNlZW4ucG9wKCk7XG5cbiAgcmV0dXJuIHJlZHVjZVRvU2luZ2xlU3RyaW5nKG91dHB1dCwgYmFzZSwgYnJhY2VzKTtcbn1cblxuXG5mdW5jdGlvbiBmb3JtYXRQcmltaXRpdmUoY3R4LCB2YWx1ZSkge1xuICBpZiAoaXNVbmRlZmluZWQodmFsdWUpKVxuICAgIHJldHVybiBjdHguc3R5bGl6ZSgndW5kZWZpbmVkJywgJ3VuZGVmaW5lZCcpO1xuICBpZiAoaXNTdHJpbmcodmFsdWUpKSB7XG4gICAgdmFyIHNpbXBsZSA9ICdcXCcnICsgSlNPTi5zdHJpbmdpZnkodmFsdWUpLnJlcGxhY2UoL15cInxcIiQvZywgJycpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAucmVwbGFjZSgvJy9nLCBcIlxcXFwnXCIpXG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAucmVwbGFjZSgvXFxcXFwiL2csICdcIicpICsgJ1xcJyc7XG4gICAgcmV0dXJuIGN0eC5zdHlsaXplKHNpbXBsZSwgJ3N0cmluZycpO1xuICB9XG4gIGlmIChpc051bWJlcih2YWx1ZSkpXG4gICAgcmV0dXJuIGN0eC5zdHlsaXplKCcnICsgdmFsdWUsICdudW1iZXInKTtcbiAgaWYgKGlzQm9vbGVhbih2YWx1ZSkpXG4gICAgcmV0dXJuIGN0eC5zdHlsaXplKCcnICsgdmFsdWUsICdib29sZWFuJyk7XG4gIC8vIEZvciBzb21lIHJlYXNvbiB0eXBlb2YgbnVsbCBpcyBcIm9iamVjdFwiLCBzbyBzcGVjaWFsIGNhc2UgaGVyZS5cbiAgaWYgKGlzTnVsbCh2YWx1ZSkpXG4gICAgcmV0dXJuIGN0eC5zdHlsaXplKCdudWxsJywgJ251bGwnKTtcbn1cblxuXG5mdW5jdGlvbiBmb3JtYXRFcnJvcih2YWx1ZSkge1xuICByZXR1cm4gJ1snICsgRXJyb3IucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwodmFsdWUpICsgJ10nO1xufVxuXG5cbmZ1bmN0aW9uIGZvcm1hdEFycmF5KGN0eCwgdmFsdWUsIHJlY3Vyc2VUaW1lcywgdmlzaWJsZUtleXMsIGtleXMpIHtcbiAgdmFyIG91dHB1dCA9IFtdO1xuICBmb3IgKHZhciBpID0gMCwgbCA9IHZhbHVlLmxlbmd0aDsgaSA8IGw7ICsraSkge1xuICAgIGlmIChoYXNPd25Qcm9wZXJ0eSh2YWx1ZSwgU3RyaW5nKGkpKSkge1xuICAgICAgb3V0cHV0LnB1c2goZm9ybWF0UHJvcGVydHkoY3R4LCB2YWx1ZSwgcmVjdXJzZVRpbWVzLCB2aXNpYmxlS2V5cyxcbiAgICAgICAgICBTdHJpbmcoaSksIHRydWUpKTtcbiAgICB9IGVsc2Uge1xuICAgICAgb3V0cHV0LnB1c2goJycpO1xuICAgIH1cbiAgfVxuICBrZXlzLmZvckVhY2goZnVuY3Rpb24oa2V5KSB7XG4gICAgaWYgKCFrZXkubWF0Y2goL15cXGQrJC8pKSB7XG4gICAgICBvdXRwdXQucHVzaChmb3JtYXRQcm9wZXJ0eShjdHgsIHZhbHVlLCByZWN1cnNlVGltZXMsIHZpc2libGVLZXlzLFxuICAgICAgICAgIGtleSwgdHJ1ZSkpO1xuICAgIH1cbiAgfSk7XG4gIHJldHVybiBvdXRwdXQ7XG59XG5cblxuZnVuY3Rpb24gZm9ybWF0UHJvcGVydHkoY3R4LCB2YWx1ZSwgcmVjdXJzZVRpbWVzLCB2aXNpYmxlS2V5cywga2V5LCBhcnJheSkge1xuICB2YXIgbmFtZSwgc3RyLCBkZXNjO1xuICBkZXNjID0gT2JqZWN0LmdldE93blByb3BlcnR5RGVzY3JpcHRvcih2YWx1ZSwga2V5KSB8fCB7IHZhbHVlOiB2YWx1ZVtrZXldIH07XG4gIGlmIChkZXNjLmdldCkge1xuICAgIGlmIChkZXNjLnNldCkge1xuICAgICAgc3RyID0gY3R4LnN0eWxpemUoJ1tHZXR0ZXIvU2V0dGVyXScsICdzcGVjaWFsJyk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHN0ciA9IGN0eC5zdHlsaXplKCdbR2V0dGVyXScsICdzcGVjaWFsJyk7XG4gICAgfVxuICB9IGVsc2Uge1xuICAgIGlmIChkZXNjLnNldCkge1xuICAgICAgc3RyID0gY3R4LnN0eWxpemUoJ1tTZXR0ZXJdJywgJ3NwZWNpYWwnKTtcbiAgICB9XG4gIH1cbiAgaWYgKCFoYXNPd25Qcm9wZXJ0eSh2aXNpYmxlS2V5cywga2V5KSkge1xuICAgIG5hbWUgPSAnWycgKyBrZXkgKyAnXSc7XG4gIH1cbiAgaWYgKCFzdHIpIHtcbiAgICBpZiAoY3R4LnNlZW4uaW5kZXhPZihkZXNjLnZhbHVlKSA8IDApIHtcbiAgICAgIGlmIChpc051bGwocmVjdXJzZVRpbWVzKSkge1xuICAgICAgICBzdHIgPSBmb3JtYXRWYWx1ZShjdHgsIGRlc2MudmFsdWUsIG51bGwpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgc3RyID0gZm9ybWF0VmFsdWUoY3R4LCBkZXNjLnZhbHVlLCByZWN1cnNlVGltZXMgLSAxKTtcbiAgICAgIH1cbiAgICAgIGlmIChzdHIuaW5kZXhPZignXFxuJykgPiAtMSkge1xuICAgICAgICBpZiAoYXJyYXkpIHtcbiAgICAgICAgICBzdHIgPSBzdHIuc3BsaXQoJ1xcbicpLm1hcChmdW5jdGlvbihsaW5lKSB7XG4gICAgICAgICAgICByZXR1cm4gJyAgJyArIGxpbmU7XG4gICAgICAgICAgfSkuam9pbignXFxuJykuc3Vic3RyKDIpO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIHN0ciA9ICdcXG4nICsgc3RyLnNwbGl0KCdcXG4nKS5tYXAoZnVuY3Rpb24obGluZSkge1xuICAgICAgICAgICAgcmV0dXJuICcgICAnICsgbGluZTtcbiAgICAgICAgICB9KS5qb2luKCdcXG4nKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBzdHIgPSBjdHguc3R5bGl6ZSgnW0NpcmN1bGFyXScsICdzcGVjaWFsJyk7XG4gICAgfVxuICB9XG4gIGlmIChpc1VuZGVmaW5lZChuYW1lKSkge1xuICAgIGlmIChhcnJheSAmJiBrZXkubWF0Y2goL15cXGQrJC8pKSB7XG4gICAgICByZXR1cm4gc3RyO1xuICAgIH1cbiAgICBuYW1lID0gSlNPTi5zdHJpbmdpZnkoJycgKyBrZXkpO1xuICAgIGlmIChuYW1lLm1hdGNoKC9eXCIoW2EtekEtWl9dW2EtekEtWl8wLTldKilcIiQvKSkge1xuICAgICAgbmFtZSA9IG5hbWUuc3Vic3RyKDEsIG5hbWUubGVuZ3RoIC0gMik7XG4gICAgICBuYW1lID0gY3R4LnN0eWxpemUobmFtZSwgJ25hbWUnKTtcbiAgICB9IGVsc2Uge1xuICAgICAgbmFtZSA9IG5hbWUucmVwbGFjZSgvJy9nLCBcIlxcXFwnXCIpXG4gICAgICAgICAgICAgICAgIC5yZXBsYWNlKC9cXFxcXCIvZywgJ1wiJylcbiAgICAgICAgICAgICAgICAgLnJlcGxhY2UoLyheXCJ8XCIkKS9nLCBcIidcIik7XG4gICAgICBuYW1lID0gY3R4LnN0eWxpemUobmFtZSwgJ3N0cmluZycpO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiBuYW1lICsgJzogJyArIHN0cjtcbn1cblxuXG5mdW5jdGlvbiByZWR1Y2VUb1NpbmdsZVN0cmluZyhvdXRwdXQsIGJhc2UsIGJyYWNlcykge1xuICB2YXIgbnVtTGluZXNFc3QgPSAwO1xuICB2YXIgbGVuZ3RoID0gb3V0cHV0LnJlZHVjZShmdW5jdGlvbihwcmV2LCBjdXIpIHtcbiAgICBudW1MaW5lc0VzdCsrO1xuICAgIGlmIChjdXIuaW5kZXhPZignXFxuJykgPj0gMCkgbnVtTGluZXNFc3QrKztcbiAgICByZXR1cm4gcHJldiArIGN1ci5yZXBsYWNlKC9cXHUwMDFiXFxbXFxkXFxkP20vZywgJycpLmxlbmd0aCArIDE7XG4gIH0sIDApO1xuXG4gIGlmIChsZW5ndGggPiA2MCkge1xuICAgIHJldHVybiBicmFjZXNbMF0gK1xuICAgICAgICAgICAoYmFzZSA9PT0gJycgPyAnJyA6IGJhc2UgKyAnXFxuICcpICtcbiAgICAgICAgICAgJyAnICtcbiAgICAgICAgICAgb3V0cHV0LmpvaW4oJyxcXG4gICcpICtcbiAgICAgICAgICAgJyAnICtcbiAgICAgICAgICAgYnJhY2VzWzFdO1xuICB9XG5cbiAgcmV0dXJuIGJyYWNlc1swXSArIGJhc2UgKyAnICcgKyBvdXRwdXQuam9pbignLCAnKSArICcgJyArIGJyYWNlc1sxXTtcbn1cblxuXG4vLyBOT1RFOiBUaGVzZSB0eXBlIGNoZWNraW5nIGZ1bmN0aW9ucyBpbnRlbnRpb25hbGx5IGRvbid0IHVzZSBgaW5zdGFuY2VvZmBcbi8vIGJlY2F1c2UgaXQgaXMgZnJhZ2lsZSBhbmQgY2FuIGJlIGVhc2lseSBmYWtlZCB3aXRoIGBPYmplY3QuY3JlYXRlKClgLlxuZnVuY3Rpb24gaXNBcnJheShhcikge1xuICByZXR1cm4gQXJyYXkuaXNBcnJheShhcik7XG59XG5leHBvcnRzLmlzQXJyYXkgPSBpc0FycmF5O1xuXG5mdW5jdGlvbiBpc0Jvb2xlYW4oYXJnKSB7XG4gIHJldHVybiB0eXBlb2YgYXJnID09PSAnYm9vbGVhbic7XG59XG5leHBvcnRzLmlzQm9vbGVhbiA9IGlzQm9vbGVhbjtcblxuZnVuY3Rpb24gaXNOdWxsKGFyZykge1xuICByZXR1cm4gYXJnID09PSBudWxsO1xufVxuZXhwb3J0cy5pc051bGwgPSBpc051bGw7XG5cbmZ1bmN0aW9uIGlzTnVsbE9yVW5kZWZpbmVkKGFyZykge1xuICByZXR1cm4gYXJnID09IG51bGw7XG59XG5leHBvcnRzLmlzTnVsbE9yVW5kZWZpbmVkID0gaXNOdWxsT3JVbmRlZmluZWQ7XG5cbmZ1bmN0aW9uIGlzTnVtYmVyKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ251bWJlcic7XG59XG5leHBvcnRzLmlzTnVtYmVyID0gaXNOdW1iZXI7XG5cbmZ1bmN0aW9uIGlzU3RyaW5nKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ3N0cmluZyc7XG59XG5leHBvcnRzLmlzU3RyaW5nID0gaXNTdHJpbmc7XG5cbmZ1bmN0aW9uIGlzU3ltYm9sKGFyZykge1xuICByZXR1cm4gdHlwZW9mIGFyZyA9PT0gJ3N5bWJvbCc7XG59XG5leHBvcnRzLmlzU3ltYm9sID0gaXNTeW1ib2w7XG5cbmZ1bmN0aW9uIGlzVW5kZWZpbmVkKGFyZykge1xuICByZXR1cm4gYXJnID09PSB2b2lkIDA7XG59XG5leHBvcnRzLmlzVW5kZWZpbmVkID0gaXNVbmRlZmluZWQ7XG5cbmZ1bmN0aW9uIGlzUmVnRXhwKHJlKSB7XG4gIHJldHVybiBpc09iamVjdChyZSkgJiYgb2JqZWN0VG9TdHJpbmcocmUpID09PSAnW29iamVjdCBSZWdFeHBdJztcbn1cbmV4cG9ydHMuaXNSZWdFeHAgPSBpc1JlZ0V4cDtcblxuZnVuY3Rpb24gaXNPYmplY3QoYXJnKSB7XG4gIHJldHVybiB0eXBlb2YgYXJnID09PSAnb2JqZWN0JyAmJiBhcmcgIT09IG51bGw7XG59XG5leHBvcnRzLmlzT2JqZWN0ID0gaXNPYmplY3Q7XG5cbmZ1bmN0aW9uIGlzRGF0ZShkKSB7XG4gIHJldHVybiBpc09iamVjdChkKSAmJiBvYmplY3RUb1N0cmluZyhkKSA9PT0gJ1tvYmplY3QgRGF0ZV0nO1xufVxuZXhwb3J0cy5pc0RhdGUgPSBpc0RhdGU7XG5cbmZ1bmN0aW9uIGlzRXJyb3IoZSkge1xuICByZXR1cm4gaXNPYmplY3QoZSkgJiZcbiAgICAgIChvYmplY3RUb1N0cmluZyhlKSA9PT0gJ1tvYmplY3QgRXJyb3JdJyB8fCBlIGluc3RhbmNlb2YgRXJyb3IpO1xufVxuZXhwb3J0cy5pc0Vycm9yID0gaXNFcnJvcjtcblxuZnVuY3Rpb24gaXNGdW5jdGlvbihhcmcpIHtcbiAgcmV0dXJuIHR5cGVvZiBhcmcgPT09ICdmdW5jdGlvbic7XG59XG5leHBvcnRzLmlzRnVuY3Rpb24gPSBpc0Z1bmN0aW9uO1xuXG5mdW5jdGlvbiBpc1ByaW1pdGl2ZShhcmcpIHtcbiAgcmV0dXJuIGFyZyA9PT0gbnVsbCB8fFxuICAgICAgICAgdHlwZW9mIGFyZyA9PT0gJ2Jvb2xlYW4nIHx8XG4gICAgICAgICB0eXBlb2YgYXJnID09PSAnbnVtYmVyJyB8fFxuICAgICAgICAgdHlwZW9mIGFyZyA9PT0gJ3N0cmluZycgfHxcbiAgICAgICAgIHR5cGVvZiBhcmcgPT09ICdzeW1ib2wnIHx8ICAvLyBFUzYgc3ltYm9sXG4gICAgICAgICB0eXBlb2YgYXJnID09PSAndW5kZWZpbmVkJztcbn1cbmV4cG9ydHMuaXNQcmltaXRpdmUgPSBpc1ByaW1pdGl2ZTtcblxuZXhwb3J0cy5pc0J1ZmZlciA9IHJlcXVpcmUoJy4vc3VwcG9ydC9pc0J1ZmZlcicpO1xuXG5mdW5jdGlvbiBvYmplY3RUb1N0cmluZyhvKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLnRvU3RyaW5nLmNhbGwobyk7XG59XG5cblxuZnVuY3Rpb24gcGFkKG4pIHtcbiAgcmV0dXJuIG4gPCAxMCA/ICcwJyArIG4udG9TdHJpbmcoMTApIDogbi50b1N0cmluZygxMCk7XG59XG5cblxudmFyIG1vbnRocyA9IFsnSmFuJywgJ0ZlYicsICdNYXInLCAnQXByJywgJ01heScsICdKdW4nLCAnSnVsJywgJ0F1ZycsICdTZXAnLFxuICAgICAgICAgICAgICAnT2N0JywgJ05vdicsICdEZWMnXTtcblxuLy8gMjYgRmViIDE2OjE5OjM0XG5mdW5jdGlvbiB0aW1lc3RhbXAoKSB7XG4gIHZhciBkID0gbmV3IERhdGUoKTtcbiAgdmFyIHRpbWUgPSBbcGFkKGQuZ2V0SG91cnMoKSksXG4gICAgICAgICAgICAgIHBhZChkLmdldE1pbnV0ZXMoKSksXG4gICAgICAgICAgICAgIHBhZChkLmdldFNlY29uZHMoKSldLmpvaW4oJzonKTtcbiAgcmV0dXJuIFtkLmdldERhdGUoKSwgbW9udGhzW2QuZ2V0TW9udGgoKV0sIHRpbWVdLmpvaW4oJyAnKTtcbn1cblxuXG4vLyBsb2cgaXMganVzdCBhIHRoaW4gd3JhcHBlciB0byBjb25zb2xlLmxvZyB0aGF0IHByZXBlbmRzIGEgdGltZXN0YW1wXG5leHBvcnRzLmxvZyA9IGZ1bmN0aW9uKCkge1xuICBjb25zb2xlLmxvZygnJXMgLSAlcycsIHRpbWVzdGFtcCgpLCBleHBvcnRzLmZvcm1hdC5hcHBseShleHBvcnRzLCBhcmd1bWVudHMpKTtcbn07XG5cblxuLyoqXG4gKiBJbmhlcml0IHRoZSBwcm90b3R5cGUgbWV0aG9kcyBmcm9tIG9uZSBjb25zdHJ1Y3RvciBpbnRvIGFub3RoZXIuXG4gKlxuICogVGhlIEZ1bmN0aW9uLnByb3RvdHlwZS5pbmhlcml0cyBmcm9tIGxhbmcuanMgcmV3cml0dGVuIGFzIGEgc3RhbmRhbG9uZVxuICogZnVuY3Rpb24gKG5vdCBvbiBGdW5jdGlvbi5wcm90b3R5cGUpLiBOT1RFOiBJZiB0aGlzIGZpbGUgaXMgdG8gYmUgbG9hZGVkXG4gKiBkdXJpbmcgYm9vdHN0cmFwcGluZyB0aGlzIGZ1bmN0aW9uIG5lZWRzIHRvIGJlIHJld3JpdHRlbiB1c2luZyBzb21lIG5hdGl2ZVxuICogZnVuY3Rpb25zIGFzIHByb3RvdHlwZSBzZXR1cCB1c2luZyBub3JtYWwgSmF2YVNjcmlwdCBkb2VzIG5vdCB3b3JrIGFzXG4gKiBleHBlY3RlZCBkdXJpbmcgYm9vdHN0cmFwcGluZyAoc2VlIG1pcnJvci5qcyBpbiByMTE0OTAzKS5cbiAqXG4gKiBAcGFyYW0ge2Z1bmN0aW9ufSBjdG9yIENvbnN0cnVjdG9yIGZ1bmN0aW9uIHdoaWNoIG5lZWRzIHRvIGluaGVyaXQgdGhlXG4gKiAgICAgcHJvdG90eXBlLlxuICogQHBhcmFtIHtmdW5jdGlvbn0gc3VwZXJDdG9yIENvbnN0cnVjdG9yIGZ1bmN0aW9uIHRvIGluaGVyaXQgcHJvdG90eXBlIGZyb20uXG4gKi9cbmV4cG9ydHMuaW5oZXJpdHMgPSByZXF1aXJlKCdpbmhlcml0cycpO1xuXG5leHBvcnRzLl9leHRlbmQgPSBmdW5jdGlvbihvcmlnaW4sIGFkZCkge1xuICAvLyBEb24ndCBkbyBhbnl0aGluZyBpZiBhZGQgaXNuJ3QgYW4gb2JqZWN0XG4gIGlmICghYWRkIHx8ICFpc09iamVjdChhZGQpKSByZXR1cm4gb3JpZ2luO1xuXG4gIHZhciBrZXlzID0gT2JqZWN0LmtleXMoYWRkKTtcbiAgdmFyIGkgPSBrZXlzLmxlbmd0aDtcbiAgd2hpbGUgKGktLSkge1xuICAgIG9yaWdpbltrZXlzW2ldXSA9IGFkZFtrZXlzW2ldXTtcbiAgfVxuICByZXR1cm4gb3JpZ2luO1xufTtcblxuZnVuY3Rpb24gaGFzT3duUHJvcGVydHkob2JqLCBwcm9wKSB7XG4gIHJldHVybiBPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwob2JqLCBwcm9wKTtcbn1cblxufSkuY2FsbCh0aGlzLHJlcXVpcmUoJ19wcm9jZXNzJyksdHlwZW9mIGdsb2JhbCAhPT0gXCJ1bmRlZmluZWRcIiA/IGdsb2JhbCA6IHR5cGVvZiBzZWxmICE9PSBcInVuZGVmaW5lZFwiID8gc2VsZiA6IHR5cGVvZiB3aW5kb3cgIT09IFwidW5kZWZpbmVkXCIgPyB3aW5kb3cgOiB7fSlcbi8vIyBzb3VyY2VNYXBwaW5nVVJMPWRhdGE6YXBwbGljYXRpb24vanNvbjtjaGFyc2V0OnV0Zi04O2Jhc2U2NCxleUoyWlhKemFXOXVJam96TENKemIzVnlZMlZ6SWpwYkltNXZaR1ZmYlc5a2RXeGxjeTlpY205M2MyVnlhV1o1TDI1dlpHVmZiVzlrZFd4bGN5OTFkR2xzTDNWMGFXd3Vhbk1pWFN3aWJtRnRaWE1pT2x0ZExDSnRZWEJ3YVc1bmN5STZJanRCUVVGQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEU3UVVGRFFUdEJRVU5CTzBGQlEwRTdRVUZEUVR0QlFVTkJPMEZCUTBFN1FVRkRRVHRCUVVOQk8wRkJRMEVpTENKbWFXeGxJam9pWjJWdVpYSmhkR1ZrTG1weklpd2ljMjkxY21ObFVtOXZkQ0k2SWlJc0luTnZkWEpqWlhORGIyNTBaVzUwSWpwYklpOHZJRU52Y0hseWFXZG9kQ0JLYjNsbGJuUXNJRWx1WXk0Z1lXNWtJRzkwYUdWeUlFNXZaR1VnWTI5dWRISnBZblYwYjNKekxseHVMeTljYmk4dklGQmxjbTFwYzNOcGIyNGdhWE1nYUdWeVpXSjVJR2R5WVc1MFpXUXNJR1p5WldVZ2IyWWdZMmhoY21kbExDQjBieUJoYm5rZ2NHVnljMjl1SUc5aWRHRnBibWx1WnlCaFhHNHZMeUJqYjNCNUlHOW1JSFJvYVhNZ2MyOW1kSGRoY21VZ1lXNWtJR0Z6YzI5amFXRjBaV1FnWkc5amRXMWxiblJoZEdsdmJpQm1hV3hsY3lBb2RHaGxYRzR2THlCY0lsTnZablIzWVhKbFhDSXBMQ0IwYnlCa1pXRnNJR2x1SUhSb1pTQlRiMlowZDJGeVpTQjNhWFJvYjNWMElISmxjM1J5YVdOMGFXOXVMQ0JwYm1Oc2RXUnBibWRjYmk4dklIZHBkR2h2ZFhRZ2JHbHRhWFJoZEdsdmJpQjBhR1VnY21sbmFIUnpJSFJ2SUhWelpTd2dZMjl3ZVN3Z2JXOWthV1o1TENCdFpYSm5aU3dnY0hWaWJHbHphQ3hjYmk4dklHUnBjM1J5YVdKMWRHVXNJSE4xWW14cFkyVnVjMlVzSUdGdVpDOXZjaUJ6Wld4c0lHTnZjR2xsY3lCdlppQjBhR1VnVTI5bWRIZGhjbVVzSUdGdVpDQjBieUJ3WlhKdGFYUmNiaTh2SUhCbGNuTnZibk1nZEc4Z2QyaHZiU0IwYUdVZ1UyOW1kSGRoY21VZ2FYTWdablZ5Ym1semFHVmtJSFJ2SUdSdklITnZMQ0J6ZFdKcVpXTjBJSFJ2SUhSb1pWeHVMeThnWm05c2JHOTNhVzVuSUdOdmJtUnBkR2x2Ym5NNlhHNHZMMXh1THk4Z1ZHaGxJR0ZpYjNabElHTnZjSGx5YVdkb2RDQnViM1JwWTJVZ1lXNWtJSFJvYVhNZ2NHVnliV2x6YzJsdmJpQnViM1JwWTJVZ2MyaGhiR3dnWW1VZ2FXNWpiSFZrWldSY2JpOHZJR2x1SUdGc2JDQmpiM0JwWlhNZ2IzSWdjM1ZpYzNSaGJuUnBZV3dnY0c5eWRHbHZibk1nYjJZZ2RHaGxJRk52Wm5SM1lYSmxMbHh1THk5Y2JpOHZJRlJJUlNCVFQwWlVWMEZTUlNCSlV5QlFVazlXU1VSRlJDQmNJa0ZUSUVsVFhDSXNJRmRKVkVoUFZWUWdWMEZTVWtGT1ZGa2dUMFlnUVU1WklFdEpUa1FzSUVWWVVGSkZVMU5jYmk4dklFOVNJRWxOVUV4SlJVUXNJRWxPUTB4VlJFbE9SeUJDVlZRZ1RrOVVJRXhKVFVsVVJVUWdWRThnVkVoRklGZEJVbEpCVGxSSlJWTWdUMFpjYmk4dklFMUZVa05JUVU1VVFVSkpURWxVV1N3Z1JrbFVUa1ZUVXlCR1QxSWdRU0JRUVZKVVNVTlZURUZTSUZCVlVsQlBVMFVnUVU1RUlFNVBUa2xPUmxKSlRrZEZUVVZPVkM0Z1NVNWNiaTh2SUU1UElFVldSVTVVSUZOSVFVeE1JRlJJUlNCQlZWUklUMUpUSUU5U0lFTlBVRmxTU1VkSVZDQklUMHhFUlZKVElFSkZJRXhKUVVKTVJTQkdUMUlnUVU1WklFTk1RVWxOTEZ4dUx5OGdSRUZOUVVkRlV5QlBVaUJQVkVoRlVpQk1TVUZDU1V4SlZGa3NJRmRJUlZSSVJWSWdTVTRnUVU0Z1FVTlVTVTlPSUU5R0lFTlBUbFJTUVVOVUxDQlVUMUpVSUU5U1hHNHZMeUJQVkVoRlVsZEpVMFVzSUVGU1NWTkpUa2NnUmxKUFRTd2dUMVZVSUU5R0lFOVNJRWxPSUVOUFRrNUZRMVJKVDA0Z1YwbFVTQ0JVU0VVZ1UwOUdWRmRCVWtVZ1QxSWdWRWhGWEc0dkx5QlZVMFVnVDFJZ1QxUklSVklnUkVWQlRFbE9SMU1nU1U0Z1ZFaEZJRk5QUmxSWFFWSkZMbHh1WEc1MllYSWdabTl5YldGMFVtVm5SWGh3SUQwZ0x5VmJjMlJxSlYwdlp6dGNibVY0Y0c5eWRITXVabTl5YldGMElEMGdablZ1WTNScGIyNG9aaWtnZTF4dUlDQnBaaUFvSVdselUzUnlhVzVuS0dZcEtTQjdYRzRnSUNBZ2RtRnlJRzlpYW1WamRITWdQU0JiWFR0Y2JpQWdJQ0JtYjNJZ0tIWmhjaUJwSUQwZ01Ec2dhU0E4SUdGeVozVnRaVzUwY3k1c1pXNW5kR2c3SUdrckt5a2dlMXh1SUNBZ0lDQWdiMkpxWldOMGN5NXdkWE5vS0dsdWMzQmxZM1FvWVhKbmRXMWxiblJ6VzJsZEtTazdYRzRnSUNBZ2ZWeHVJQ0FnSUhKbGRIVnliaUJ2WW1wbFkzUnpMbXB2YVc0b0p5QW5LVHRjYmlBZ2ZWeHVYRzRnSUhaaGNpQnBJRDBnTVR0Y2JpQWdkbUZ5SUdGeVozTWdQU0JoY21kMWJXVnVkSE03WEc0Z0lIWmhjaUJzWlc0Z1BTQmhjbWR6TG14bGJtZDBhRHRjYmlBZ2RtRnlJSE4wY2lBOUlGTjBjbWx1WnlobUtTNXlaWEJzWVdObEtHWnZjbTFoZEZKbFowVjRjQ3dnWm5WdVkzUnBiMjRvZUNrZ2UxeHVJQ0FnSUdsbUlDaDRJRDA5UFNBbkpTVW5LU0J5WlhSMWNtNGdKeVVuTzF4dUlDQWdJR2xtSUNocElENDlJR3hsYmlrZ2NtVjBkWEp1SUhnN1hHNGdJQ0FnYzNkcGRHTm9JQ2g0S1NCN1hHNGdJQ0FnSUNCallYTmxJQ2NsY3ljNklISmxkSFZ5YmlCVGRISnBibWNvWVhKbmMxdHBLeXRkS1R0Y2JpQWdJQ0FnSUdOaGMyVWdKeVZrSnpvZ2NtVjBkWEp1SUU1MWJXSmxjaWhoY21kelcya3JLMTBwTzF4dUlDQWdJQ0FnWTJGelpTQW5KV29uT2x4dUlDQWdJQ0FnSUNCMGNua2dlMXh1SUNBZ0lDQWdJQ0FnSUhKbGRIVnliaUJLVTA5T0xuTjBjbWx1WjJsbWVTaGhjbWR6VzJrcksxMHBPMXh1SUNBZ0lDQWdJQ0I5SUdOaGRHTm9JQ2hmS1NCN1hHNGdJQ0FnSUNBZ0lDQWdjbVYwZFhKdUlDZGJRMmx5WTNWc1lYSmRKenRjYmlBZ0lDQWdJQ0FnZlZ4dUlDQWdJQ0FnWkdWbVlYVnNkRHBjYmlBZ0lDQWdJQ0FnY21WMGRYSnVJSGc3WEc0Z0lDQWdmVnh1SUNCOUtUdGNiaUFnWm05eUlDaDJZWElnZUNBOUlHRnlaM05iYVYwN0lHa2dQQ0JzWlc0N0lIZ2dQU0JoY21keld5c3JhVjBwSUh0Y2JpQWdJQ0JwWmlBb2FYTk9kV3hzS0hncElIeDhJQ0ZwYzA5aWFtVmpkQ2g0S1NrZ2UxeHVJQ0FnSUNBZ2MzUnlJQ3M5SUNjZ0p5QXJJSGc3WEc0Z0lDQWdmU0JsYkhObElIdGNiaUFnSUNBZ0lITjBjaUFyUFNBbklDY2dLeUJwYm5Od1pXTjBLSGdwTzF4dUlDQWdJSDFjYmlBZ2ZWeHVJQ0J5WlhSMWNtNGdjM1J5TzF4dWZUdGNibHh1WEc0dkx5Qk5ZWEpySUhSb1lYUWdZU0J0WlhSb2IyUWdjMmh2ZFd4a0lHNXZkQ0JpWlNCMWMyVmtMbHh1THk4Z1VtVjBkWEp1Y3lCaElHMXZaR2xtYVdWa0lHWjFibU4wYVc5dUlIZG9hV05vSUhkaGNtNXpJRzl1WTJVZ1lua2daR1ZtWVhWc2RDNWNiaTh2SUVsbUlDMHRibTh0WkdWd2NtVmpZWFJwYjI0Z2FYTWdjMlYwTENCMGFHVnVJR2wwSUdseklHRWdibTh0YjNBdVhHNWxlSEJ2Y25SekxtUmxjSEpsWTJGMFpTQTlJR1oxYm1OMGFXOXVLR1p1TENCdGMyY3BJSHRjYmlBZ0x5OGdRV3hzYjNjZ1ptOXlJR1JsY0hKbFkyRjBhVzVuSUhSb2FXNW5jeUJwYmlCMGFHVWdjSEp2WTJWemN5QnZaaUJ6ZEdGeWRHbHVaeUIxY0M1Y2JpQWdhV1lnS0dselZXNWtaV1pwYm1Wa0tHZHNiMkpoYkM1d2NtOWpaWE56S1NrZ2UxeHVJQ0FnSUhKbGRIVnliaUJtZFc1amRHbHZiaWdwSUh0Y2JpQWdJQ0FnSUhKbGRIVnliaUJsZUhCdmNuUnpMbVJsY0hKbFkyRjBaU2htYml3Z2JYTm5LUzVoY0hCc2VTaDBhR2x6TENCaGNtZDFiV1Z1ZEhNcE8xeHVJQ0FnSUgwN1hHNGdJSDFjYmx4dUlDQnBaaUFvY0hKdlkyVnpjeTV1YjBSbGNISmxZMkYwYVc5dUlEMDlQU0IwY25WbEtTQjdYRzRnSUNBZ2NtVjBkWEp1SUdadU8xeHVJQ0I5WEc1Y2JpQWdkbUZ5SUhkaGNtNWxaQ0E5SUdaaGJITmxPMXh1SUNCbWRXNWpkR2x2YmlCa1pYQnlaV05oZEdWa0tDa2dlMXh1SUNBZ0lHbG1JQ2doZDJGeWJtVmtLU0I3WEc0Z0lDQWdJQ0JwWmlBb2NISnZZMlZ6Y3k1MGFISnZkMFJsY0hKbFkyRjBhVzl1S1NCN1hHNGdJQ0FnSUNBZ0lIUm9jbTkzSUc1bGR5QkZjbkp2Y2lodGMyY3BPMXh1SUNBZ0lDQWdmU0JsYkhObElHbG1JQ2h3Y205alpYTnpMblJ5WVdObFJHVndjbVZqWVhScGIyNHBJSHRjYmlBZ0lDQWdJQ0FnWTI5dWMyOXNaUzUwY21GalpTaHRjMmNwTzF4dUlDQWdJQ0FnZlNCbGJITmxJSHRjYmlBZ0lDQWdJQ0FnWTI5dWMyOXNaUzVsY25KdmNpaHRjMmNwTzF4dUlDQWdJQ0FnZlZ4dUlDQWdJQ0FnZDJGeWJtVmtJRDBnZEhKMVpUdGNiaUFnSUNCOVhHNGdJQ0FnY21WMGRYSnVJR1p1TG1Gd2NHeDVLSFJvYVhNc0lHRnlaM1Z0Wlc1MGN5azdYRzRnSUgxY2JseHVJQ0J5WlhSMWNtNGdaR1Z3Y21WallYUmxaRHRjYm4wN1hHNWNibHh1ZG1GeUlHUmxZblZuY3lBOUlIdDlPMXh1ZG1GeUlHUmxZblZuUlc1MmFYSnZianRjYm1WNGNHOXlkSE11WkdWaWRXZHNiMmNnUFNCbWRXNWpkR2x2YmloelpYUXBJSHRjYmlBZ2FXWWdLR2x6Vlc1a1pXWnBibVZrS0dSbFluVm5SVzUyYVhKdmJpa3BYRzRnSUNBZ1pHVmlkV2RGYm5acGNtOXVJRDBnY0hKdlkyVnpjeTVsYm5ZdVRrOUVSVjlFUlVKVlJ5QjhmQ0FuSnp0Y2JpQWdjMlYwSUQwZ2MyVjBMblJ2VlhCd1pYSkRZWE5sS0NrN1hHNGdJR2xtSUNnaFpHVmlkV2R6VzNObGRGMHBJSHRjYmlBZ0lDQnBaaUFvYm1WM0lGSmxaMFY0Y0NnblhGeGNYR0luSUNzZ2MyVjBJQ3NnSjF4Y1hGeGlKeXdnSjJrbktTNTBaWE4wS0dSbFluVm5SVzUyYVhKdmJpa3BJSHRjYmlBZ0lDQWdJSFpoY2lCd2FXUWdQU0J3Y205alpYTnpMbkJwWkR0Y2JpQWdJQ0FnSUdSbFluVm5jMXR6WlhSZElEMGdablZ1WTNScGIyNG9LU0I3WEc0Z0lDQWdJQ0FnSUhaaGNpQnRjMmNnUFNCbGVIQnZjblJ6TG1admNtMWhkQzVoY0hCc2VTaGxlSEJ2Y25SekxDQmhjbWQxYldWdWRITXBPMXh1SUNBZ0lDQWdJQ0JqYjI1emIyeGxMbVZ5Y205eUtDY2xjeUFsWkRvZ0pYTW5MQ0J6WlhRc0lIQnBaQ3dnYlhObktUdGNiaUFnSUNBZ0lIMDdYRzRnSUNBZ2ZTQmxiSE5sSUh0Y2JpQWdJQ0FnSUdSbFluVm5jMXR6WlhSZElEMGdablZ1WTNScGIyNG9LU0I3ZlR0Y2JpQWdJQ0I5WEc0Z0lIMWNiaUFnY21WMGRYSnVJR1JsWW5WbmMxdHpaWFJkTzF4dWZUdGNibHh1WEc0dktpcGNiaUFxSUVWamFHOXpJSFJvWlNCMllXeDFaU0J2WmlCaElIWmhiSFZsTGlCVWNubHpJSFJ2SUhCeWFXNTBJSFJvWlNCMllXeDFaU0J2ZFhSY2JpQXFJR2x1SUhSb1pTQmlaWE4wSUhkaGVTQndiM056YVdKc1pTQm5hWFpsYmlCMGFHVWdaR2xtWm1WeVpXNTBJSFI1Y0dWekxseHVJQ3BjYmlBcUlFQndZWEpoYlNCN1QySnFaV04wZlNCdlltb2dWR2hsSUc5aWFtVmpkQ0IwYnlCd2NtbHVkQ0J2ZFhRdVhHNGdLaUJBY0dGeVlXMGdlMDlpYW1WamRIMGdiM0IwY3lCUGNIUnBiMjVoYkNCdmNIUnBiMjV6SUc5aWFtVmpkQ0IwYUdGMElHRnNkR1Z5Y3lCMGFHVWdiM1YwY0hWMExseHVJQ292WEc0dktpQnNaV2RoWTNrNklHOWlhaXdnYzJodmQwaHBaR1JsYml3Z1pHVndkR2dzSUdOdmJHOXljeW92WEc1bWRXNWpkR2x2YmlCcGJuTndaV04wS0c5aWFpd2diM0IwY3lrZ2UxeHVJQ0F2THlCa1pXWmhkV3gwSUc5d2RHbHZibk5jYmlBZ2RtRnlJR04wZUNBOUlIdGNiaUFnSUNCelpXVnVPaUJiWFN4Y2JpQWdJQ0J6ZEhsc2FYcGxPaUJ6ZEhsc2FYcGxUbTlEYjJ4dmNseHVJQ0I5TzF4dUlDQXZMeUJzWldkaFkza3VMaTVjYmlBZ2FXWWdLR0Z5WjNWdFpXNTBjeTVzWlc1bmRHZ2dQajBnTXlrZ1kzUjRMbVJsY0hSb0lEMGdZWEpuZFcxbGJuUnpXekpkTzF4dUlDQnBaaUFvWVhKbmRXMWxiblJ6TG14bGJtZDBhQ0ErUFNBMEtTQmpkSGd1WTI5c2IzSnpJRDBnWVhKbmRXMWxiblJ6V3pOZE8xeHVJQ0JwWmlBb2FYTkNiMjlzWldGdUtHOXdkSE1wS1NCN1hHNGdJQ0FnTHk4Z2JHVm5ZV041TGk0dVhHNGdJQ0FnWTNSNExuTm9iM2RJYVdSa1pXNGdQU0J2Y0hSek8xeHVJQ0I5SUdWc2MyVWdhV1lnS0c5d2RITXBJSHRjYmlBZ0lDQXZMeUJuYjNRZ1lXNGdYQ0p2Y0hScGIyNXpYQ0lnYjJKcVpXTjBYRzRnSUNBZ1pYaHdiM0owY3k1ZlpYaDBaVzVrS0dOMGVDd2diM0IwY3lrN1hHNGdJSDFjYmlBZ0x5OGdjMlYwSUdSbFptRjFiSFFnYjNCMGFXOXVjMXh1SUNCcFppQW9hWE5WYm1SbFptbHVaV1FvWTNSNExuTm9iM2RJYVdSa1pXNHBLU0JqZEhndWMyaHZkMGhwWkdSbGJpQTlJR1poYkhObE8xeHVJQ0JwWmlBb2FYTlZibVJsWm1sdVpXUW9ZM1I0TG1SbGNIUm9LU2tnWTNSNExtUmxjSFJvSUQwZ01qdGNiaUFnYVdZZ0tHbHpWVzVrWldacGJtVmtLR04wZUM1amIyeHZjbk1wS1NCamRIZ3VZMjlzYjNKeklEMGdabUZzYzJVN1hHNGdJR2xtSUNocGMxVnVaR1ZtYVc1bFpDaGpkSGd1WTNWemRHOXRTVzV6Y0dWamRDa3BJR04wZUM1amRYTjBiMjFKYm5Od1pXTjBJRDBnZEhKMVpUdGNiaUFnYVdZZ0tHTjBlQzVqYjJ4dmNuTXBJR04wZUM1emRIbHNhWHBsSUQwZ2MzUjViR2w2WlZkcGRHaERiMnh2Y2p0Y2JpQWdjbVYwZFhKdUlHWnZjbTFoZEZaaGJIVmxLR04wZUN3Z2IySnFMQ0JqZEhndVpHVndkR2dwTzF4dWZWeHVaWGh3YjNKMGN5NXBibk53WldOMElEMGdhVzV6Y0dWamREdGNibHh1WEc0dkx5Qm9kSFJ3T2k4dlpXNHVkMmxyYVhCbFpHbGhMbTl5Wnk5M2FXdHBMMEZPVTBsZlpYTmpZWEJsWDJOdlpHVWpaM0poY0docFkzTmNibWx1YzNCbFkzUXVZMjlzYjNKeklEMGdlMXh1SUNBblltOXNaQ2NnT2lCYk1Td2dNakpkTEZ4dUlDQW5hWFJoYkdsakp5QTZJRnN6TENBeU0xMHNYRzRnSUNkMWJtUmxjbXhwYm1VbklEb2dXelFzSURJMFhTeGNiaUFnSjJsdWRtVnljMlVuSURvZ1d6Y3NJREkzWFN4Y2JpQWdKM2RvYVhSbEp5QTZJRnN6Tnl3Z016bGRMRnh1SUNBblozSmxlU2NnT2lCYk9UQXNJRE01WFN4Y2JpQWdKMkpzWVdOckp5QTZJRnN6TUN3Z016bGRMRnh1SUNBbllteDFaU2NnT2lCYk16UXNJRE01WFN4Y2JpQWdKMk41WVc0bklEb2dXek0yTENBek9WMHNYRzRnSUNkbmNtVmxiaWNnT2lCYk16SXNJRE01WFN4Y2JpQWdKMjFoWjJWdWRHRW5JRG9nV3pNMUxDQXpPVjBzWEc0Z0lDZHlaV1FuSURvZ1d6TXhMQ0F6T1Ywc1hHNGdJQ2Q1Wld4c2IzY25JRG9nV3pNekxDQXpPVjFjYm4wN1hHNWNiaTh2SUVSdmJpZDBJSFZ6WlNBbllteDFaU2NnYm05MElIWnBjMmxpYkdVZ2IyNGdZMjFrTG1WNFpWeHVhVzV6Y0dWamRDNXpkSGxzWlhNZ1BTQjdYRzRnSUNkemNHVmphV0ZzSnpvZ0oyTjVZVzRuTEZ4dUlDQW5iblZ0WW1WeUp6b2dKM2xsYkd4dmR5Y3NYRzRnSUNkaWIyOXNaV0Z1SnpvZ0ozbGxiR3h2ZHljc1hHNGdJQ2QxYm1SbFptbHVaV1FuT2lBblozSmxlU2NzWEc0Z0lDZHVkV3hzSnpvZ0oySnZiR1FuTEZ4dUlDQW5jM1J5YVc1bkp6b2dKMmR5WldWdUp5eGNiaUFnSjJSaGRHVW5PaUFuYldGblpXNTBZU2NzWEc0Z0lDOHZJRndpYm1GdFpWd2lPaUJwYm5SbGJuUnBiMjVoYkd4NUlHNXZkQ0J6ZEhsc2FXNW5YRzRnSUNkeVpXZGxlSEFuT2lBbmNtVmtKMXh1ZlR0Y2JseHVYRzVtZFc1amRHbHZiaUJ6ZEhsc2FYcGxWMmwwYUVOdmJHOXlLSE4wY2l3Z2MzUjViR1ZVZVhCbEtTQjdYRzRnSUhaaGNpQnpkSGxzWlNBOUlHbHVjM0JsWTNRdWMzUjViR1Z6VzNOMGVXeGxWSGx3WlYwN1hHNWNiaUFnYVdZZ0tITjBlV3hsS1NCN1hHNGdJQ0FnY21WMGRYSnVJQ2RjWEhVd01ERmlXeWNnS3lCcGJuTndaV04wTG1OdmJHOXljMXR6ZEhsc1pWMWJNRjBnS3lBbmJTY2dLeUJ6ZEhJZ0sxeHVJQ0FnSUNBZ0lDQWdJQ0FuWEZ4MU1EQXhZbHNuSUNzZ2FXNXpjR1ZqZEM1amIyeHZjbk5iYzNSNWJHVmRXekZkSUNzZ0oyMG5PMXh1SUNCOUlHVnNjMlVnZTF4dUlDQWdJSEpsZEhWeWJpQnpkSEk3WEc0Z0lIMWNibjFjYmx4dVhHNW1kVzVqZEdsdmJpQnpkSGxzYVhwbFRtOURiMnh2Y2loemRISXNJSE4wZVd4bFZIbHdaU2tnZTF4dUlDQnlaWFIxY200Z2MzUnlPMXh1ZlZ4dVhHNWNibVoxYm1OMGFXOXVJR0Z5Y21GNVZHOUlZWE5vS0dGeWNtRjVLU0I3WEc0Z0lIWmhjaUJvWVhOb0lEMGdlMzA3WEc1Y2JpQWdZWEp5WVhrdVptOXlSV0ZqYUNobWRXNWpkR2x2YmloMllXd3NJR2xrZUNrZ2UxeHVJQ0FnSUdoaGMyaGJkbUZzWFNBOUlIUnlkV1U3WEc0Z0lIMHBPMXh1WEc0Z0lISmxkSFZ5YmlCb1lYTm9PMXh1ZlZ4dVhHNWNibVoxYm1OMGFXOXVJR1p2Y20xaGRGWmhiSFZsS0dOMGVDd2dkbUZzZFdVc0lISmxZM1Z5YzJWVWFXMWxjeWtnZTF4dUlDQXZMeUJRY205MmFXUmxJR0VnYUc5dmF5Qm1iM0lnZFhObGNpMXpjR1ZqYVdacFpXUWdhVzV6Y0dWamRDQm1kVzVqZEdsdmJuTXVYRzRnSUM4dklFTm9aV05ySUhSb1lYUWdkbUZzZFdVZ2FYTWdZVzRnYjJKcVpXTjBJSGRwZEdnZ1lXNGdhVzV6Y0dWamRDQm1kVzVqZEdsdmJpQnZiaUJwZEZ4dUlDQnBaaUFvWTNSNExtTjFjM1J2YlVsdWMzQmxZM1FnSmlaY2JpQWdJQ0FnSUhaaGJIVmxJQ1ltWEc0Z0lDQWdJQ0JwYzBaMWJtTjBhVzl1S0haaGJIVmxMbWx1YzNCbFkzUXBJQ1ltWEc0Z0lDQWdJQ0F2THlCR2FXeDBaWElnYjNWMElIUm9aU0IxZEdsc0lHMXZaSFZzWlN3Z2FYUW5jeUJwYm5Od1pXTjBJR1oxYm1OMGFXOXVJR2x6SUhOd1pXTnBZV3hjYmlBZ0lDQWdJSFpoYkhWbExtbHVjM0JsWTNRZ0lUMDlJR1Y0Y0c5eWRITXVhVzV6Y0dWamRDQW1KbHh1SUNBZ0lDQWdMeThnUVd4emJ5Qm1hV3gwWlhJZ2IzVjBJR0Z1ZVNCd2NtOTBiM1I1Y0dVZ2IySnFaV04wY3lCMWMybHVaeUIwYUdVZ1kybHlZM1ZzWVhJZ1kyaGxZMnN1WEc0Z0lDQWdJQ0FoS0haaGJIVmxMbU52Ym5OMGNuVmpkRzl5SUNZbUlIWmhiSFZsTG1OdmJuTjBjblZqZEc5eUxuQnliM1J2ZEhsd1pTQTlQVDBnZG1Gc2RXVXBLU0I3WEc0Z0lDQWdkbUZ5SUhKbGRDQTlJSFpoYkhWbExtbHVjM0JsWTNRb2NtVmpkWEp6WlZScGJXVnpMQ0JqZEhncE8xeHVJQ0FnSUdsbUlDZ2hhWE5UZEhKcGJtY29jbVYwS1NrZ2UxeHVJQ0FnSUNBZ2NtVjBJRDBnWm05eWJXRjBWbUZzZFdVb1kzUjRMQ0J5WlhRc0lISmxZM1Z5YzJWVWFXMWxjeWs3WEc0Z0lDQWdmVnh1SUNBZ0lISmxkSFZ5YmlCeVpYUTdYRzRnSUgxY2JseHVJQ0F2THlCUWNtbHRhWFJwZG1VZ2RIbHdaWE1nWTJGdWJtOTBJR2hoZG1VZ2NISnZjR1Z5ZEdsbGMxeHVJQ0IyWVhJZ2NISnBiV2wwYVhabElEMGdabTl5YldGMFVISnBiV2wwYVhabEtHTjBlQ3dnZG1Gc2RXVXBPMXh1SUNCcFppQW9jSEpwYldsMGFYWmxLU0I3WEc0Z0lDQWdjbVYwZFhKdUlIQnlhVzFwZEdsMlpUdGNiaUFnZlZ4dVhHNGdJQzh2SUV4dmIyc2dkWEFnZEdobElHdGxlWE1nYjJZZ2RHaGxJRzlpYW1WamRDNWNiaUFnZG1GeUlHdGxlWE1nUFNCUFltcGxZM1F1YTJWNWN5aDJZV3gxWlNrN1hHNGdJSFpoY2lCMmFYTnBZbXhsUzJWNWN5QTlJR0Z5Y21GNVZHOUlZWE5vS0d0bGVYTXBPMXh1WEc0Z0lHbG1JQ2hqZEhndWMyaHZkMGhwWkdSbGJpa2dlMXh1SUNBZ0lHdGxlWE1nUFNCUFltcGxZM1F1WjJWMFQzZHVVSEp2Y0dWeWRIbE9ZVzFsY3loMllXeDFaU2s3WEc0Z0lIMWNibHh1SUNBdkx5QkpSU0JrYjJWemJpZDBJRzFoYTJVZ1pYSnliM0lnWm1sbGJHUnpJRzV2YmkxbGJuVnRaWEpoWW14bFhHNGdJQzh2SUdoMGRIQTZMeTl0YzJSdUxtMXBZM0p2YzI5bWRDNWpiMjB2Wlc0dGRYTXZiR2xpY21GeWVTOXBaUzlrZDNjMU1uTmlkQ2gyUFhaekxqazBLUzVoYzNCNFhHNGdJR2xtSUNocGMwVnljbTl5S0haaGJIVmxLVnh1SUNBZ0lDQWdKaVlnS0d0bGVYTXVhVzVrWlhoUFppZ25iV1Z6YzJGblpTY3BJRDQ5SURBZ2ZId2dhMlY1Y3k1cGJtUmxlRTltS0Nka1pYTmpjbWx3ZEdsdmJpY3BJRDQ5SURBcEtTQjdYRzRnSUNBZ2NtVjBkWEp1SUdadmNtMWhkRVZ5Y205eUtIWmhiSFZsS1R0Y2JpQWdmVnh1WEc0Z0lDOHZJRk52YldVZ2RIbHdaU0J2WmlCdlltcGxZM1FnZDJsMGFHOTFkQ0J3Y205d1pYSjBhV1Z6SUdOaGJpQmlaU0J6YUc5eWRHTjFkSFJsWkM1Y2JpQWdhV1lnS0d0bGVYTXViR1Z1WjNSb0lEMDlQU0F3S1NCN1hHNGdJQ0FnYVdZZ0tHbHpSblZ1WTNScGIyNG9kbUZzZFdVcEtTQjdYRzRnSUNBZ0lDQjJZWElnYm1GdFpTQTlJSFpoYkhWbExtNWhiV1VnUHlBbk9pQW5JQ3NnZG1Gc2RXVXVibUZ0WlNBNklDY25PMXh1SUNBZ0lDQWdjbVYwZFhKdUlHTjBlQzV6ZEhsc2FYcGxLQ2RiUm5WdVkzUnBiMjRuSUNzZ2JtRnRaU0FySUNkZEp5d2dKM053WldOcFlXd25LVHRjYmlBZ0lDQjlYRzRnSUNBZ2FXWWdLR2x6VW1WblJYaHdLSFpoYkhWbEtTa2dlMXh1SUNBZ0lDQWdjbVYwZFhKdUlHTjBlQzV6ZEhsc2FYcGxLRkpsWjBWNGNDNXdjbTkwYjNSNWNHVXVkRzlUZEhKcGJtY3VZMkZzYkNoMllXeDFaU2tzSUNkeVpXZGxlSEFuS1R0Y2JpQWdJQ0I5WEc0Z0lDQWdhV1lnS0dselJHRjBaU2gyWVd4MVpTa3BJSHRjYmlBZ0lDQWdJSEpsZEhWeWJpQmpkSGd1YzNSNWJHbDZaU2hFWVhSbExuQnliM1J2ZEhsd1pTNTBiMU4wY21sdVp5NWpZV3hzS0haaGJIVmxLU3dnSjJSaGRHVW5LVHRjYmlBZ0lDQjlYRzRnSUNBZ2FXWWdLR2x6UlhKeWIzSW9kbUZzZFdVcEtTQjdYRzRnSUNBZ0lDQnlaWFIxY200Z1ptOXliV0YwUlhKeWIzSW9kbUZzZFdVcE8xeHVJQ0FnSUgxY2JpQWdmVnh1WEc0Z0lIWmhjaUJpWVhObElEMGdKeWNzSUdGeWNtRjVJRDBnWm1Gc2MyVXNJR0p5WVdObGN5QTlJRnNuZXljc0lDZDlKMTA3WEc1Y2JpQWdMeThnVFdGclpTQkJjbkpoZVNCellYa2dkR2hoZENCMGFHVjVJR0Z5WlNCQmNuSmhlVnh1SUNCcFppQW9hWE5CY25KaGVTaDJZV3gxWlNrcElIdGNiaUFnSUNCaGNuSmhlU0E5SUhSeWRXVTdYRzRnSUNBZ1luSmhZMlZ6SUQwZ1d5ZGJKeXdnSjEwblhUdGNiaUFnZlZ4dVhHNGdJQzh2SUUxaGEyVWdablZ1WTNScGIyNXpJSE5oZVNCMGFHRjBJSFJvWlhrZ1lYSmxJR1oxYm1OMGFXOXVjMXh1SUNCcFppQW9hWE5HZFc1amRHbHZiaWgyWVd4MVpTa3BJSHRjYmlBZ0lDQjJZWElnYmlBOUlIWmhiSFZsTG01aGJXVWdQeUFuT2lBbklDc2dkbUZzZFdVdWJtRnRaU0E2SUNjbk8xeHVJQ0FnSUdKaGMyVWdQU0FuSUZ0R2RXNWpkR2x2YmljZ0t5QnVJQ3NnSjEwbk8xeHVJQ0I5WEc1Y2JpQWdMeThnVFdGclpTQlNaV2RGZUhCeklITmhlU0IwYUdGMElIUm9aWGtnWVhKbElGSmxaMFY0Y0hOY2JpQWdhV1lnS0dselVtVm5SWGh3S0haaGJIVmxLU2tnZTF4dUlDQWdJR0poYzJVZ1BTQW5JQ2NnS3lCU1pXZEZlSEF1Y0hKdmRHOTBlWEJsTG5SdlUzUnlhVzVuTG1OaGJHd29kbUZzZFdVcE8xeHVJQ0I5WEc1Y2JpQWdMeThnVFdGclpTQmtZWFJsY3lCM2FYUm9JSEJ5YjNCbGNuUnBaWE1nWm1seWMzUWdjMkY1SUhSb1pTQmtZWFJsWEc0Z0lHbG1JQ2hwYzBSaGRHVW9kbUZzZFdVcEtTQjdYRzRnSUNBZ1ltRnpaU0E5SUNjZ0p5QXJJRVJoZEdVdWNISnZkRzkwZVhCbExuUnZWVlJEVTNSeWFXNW5MbU5oYkd3b2RtRnNkV1VwTzF4dUlDQjlYRzVjYmlBZ0x5OGdUV0ZyWlNCbGNuSnZjaUIzYVhSb0lHMWxjM05oWjJVZ1ptbHljM1FnYzJGNUlIUm9aU0JsY25KdmNseHVJQ0JwWmlBb2FYTkZjbkp2Y2loMllXeDFaU2twSUh0Y2JpQWdJQ0JpWVhObElEMGdKeUFuSUNzZ1ptOXliV0YwUlhKeWIzSW9kbUZzZFdVcE8xeHVJQ0I5WEc1Y2JpQWdhV1lnS0d0bGVYTXViR1Z1WjNSb0lEMDlQU0F3SUNZbUlDZ2hZWEp5WVhrZ2ZId2dkbUZzZFdVdWJHVnVaM1JvSUQwOUlEQXBLU0I3WEc0Z0lDQWdjbVYwZFhKdUlHSnlZV05sYzFzd1hTQXJJR0poYzJVZ0t5QmljbUZqWlhOYk1WMDdYRzRnSUgxY2JseHVJQ0JwWmlBb2NtVmpkWEp6WlZScGJXVnpJRHdnTUNrZ2UxeHVJQ0FnSUdsbUlDaHBjMUpsWjBWNGNDaDJZV3gxWlNrcElIdGNiaUFnSUNBZ0lISmxkSFZ5YmlCamRIZ3VjM1I1YkdsNlpTaFNaV2RGZUhBdWNISnZkRzkwZVhCbExuUnZVM1J5YVc1bkxtTmhiR3dvZG1Gc2RXVXBMQ0FuY21WblpYaHdKeWs3WEc0Z0lDQWdmU0JsYkhObElIdGNiaUFnSUNBZ0lISmxkSFZ5YmlCamRIZ3VjM1I1YkdsNlpTZ25XMDlpYW1WamRGMG5MQ0FuYzNCbFkybGhiQ2NwTzF4dUlDQWdJSDFjYmlBZ2ZWeHVYRzRnSUdOMGVDNXpaV1Z1TG5CMWMyZ29kbUZzZFdVcE8xeHVYRzRnSUhaaGNpQnZkWFJ3ZFhRN1hHNGdJR2xtSUNoaGNuSmhlU2tnZTF4dUlDQWdJRzkxZEhCMWRDQTlJR1p2Y20xaGRFRnljbUY1S0dOMGVDd2dkbUZzZFdVc0lISmxZM1Z5YzJWVWFXMWxjeXdnZG1semFXSnNaVXRsZVhNc0lHdGxlWE1wTzF4dUlDQjlJR1ZzYzJVZ2UxeHVJQ0FnSUc5MWRIQjFkQ0E5SUd0bGVYTXViV0Z3S0daMWJtTjBhVzl1S0d0bGVTa2dlMXh1SUNBZ0lDQWdjbVYwZFhKdUlHWnZjbTFoZEZCeWIzQmxjblI1S0dOMGVDd2dkbUZzZFdVc0lISmxZM1Z5YzJWVWFXMWxjeXdnZG1semFXSnNaVXRsZVhNc0lHdGxlU3dnWVhKeVlYa3BPMXh1SUNBZ0lIMHBPMXh1SUNCOVhHNWNiaUFnWTNSNExuTmxaVzR1Y0c5d0tDazdYRzVjYmlBZ2NtVjBkWEp1SUhKbFpIVmpaVlJ2VTJsdVoyeGxVM1J5YVc1bktHOTFkSEIxZEN3Z1ltRnpaU3dnWW5KaFkyVnpLVHRjYm4xY2JseHVYRzVtZFc1amRHbHZiaUJtYjNKdFlYUlFjbWx0YVhScGRtVW9ZM1I0TENCMllXeDFaU2tnZTF4dUlDQnBaaUFvYVhOVmJtUmxabWx1WldRb2RtRnNkV1VwS1Z4dUlDQWdJSEpsZEhWeWJpQmpkSGd1YzNSNWJHbDZaU2duZFc1a1pXWnBibVZrSnl3Z0ozVnVaR1ZtYVc1bFpDY3BPMXh1SUNCcFppQW9hWE5UZEhKcGJtY29kbUZzZFdVcEtTQjdYRzRnSUNBZ2RtRnlJSE5wYlhCc1pTQTlJQ2RjWENjbklDc2dTbE5QVGk1emRISnBibWRwWm5rb2RtRnNkV1VwTG5KbGNHeGhZMlVvTDE1Y0lueGNJaVF2Wnl3Z0p5Y3BYRzRnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0F1Y21Wd2JHRmpaU2d2Snk5bkxDQmNJbHhjWEZ3blhDSXBYRzRnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQ0F1Y21Wd2JHRmpaU2d2WEZ4Y1hGd2lMMmNzSUNkY0lpY3BJQ3NnSjF4Y0p5YzdYRzRnSUNBZ2NtVjBkWEp1SUdOMGVDNXpkSGxzYVhwbEtITnBiWEJzWlN3Z0ozTjBjbWx1WnljcE8xeHVJQ0I5WEc0Z0lHbG1JQ2hwYzA1MWJXSmxjaWgyWVd4MVpTa3BYRzRnSUNBZ2NtVjBkWEp1SUdOMGVDNXpkSGxzYVhwbEtDY25JQ3NnZG1Gc2RXVXNJQ2R1ZFcxaVpYSW5LVHRjYmlBZ2FXWWdLR2x6UW05dmJHVmhiaWgyWVd4MVpTa3BYRzRnSUNBZ2NtVjBkWEp1SUdOMGVDNXpkSGxzYVhwbEtDY25JQ3NnZG1Gc2RXVXNJQ2RpYjI5c1pXRnVKeWs3WEc0Z0lDOHZJRVp2Y2lCemIyMWxJSEpsWVhOdmJpQjBlWEJsYjJZZ2JuVnNiQ0JwY3lCY0ltOWlhbVZqZEZ3aUxDQnpieUJ6Y0dWamFXRnNJR05oYzJVZ2FHVnlaUzVjYmlBZ2FXWWdLR2x6VG5Wc2JDaDJZV3gxWlNrcFhHNGdJQ0FnY21WMGRYSnVJR04wZUM1emRIbHNhWHBsS0NkdWRXeHNKeXdnSjI1MWJHd25LVHRjYm4xY2JseHVYRzVtZFc1amRHbHZiaUJtYjNKdFlYUkZjbkp2Y2loMllXeDFaU2tnZTF4dUlDQnlaWFIxY200Z0oxc25JQ3NnUlhKeWIzSXVjSEp2ZEc5MGVYQmxMblJ2VTNSeWFXNW5MbU5oYkd3b2RtRnNkV1VwSUNzZ0oxMG5PMXh1ZlZ4dVhHNWNibVoxYm1OMGFXOXVJR1p2Y20xaGRFRnljbUY1S0dOMGVDd2dkbUZzZFdVc0lISmxZM1Z5YzJWVWFXMWxjeXdnZG1semFXSnNaVXRsZVhNc0lHdGxlWE1wSUh0Y2JpQWdkbUZ5SUc5MWRIQjFkQ0E5SUZ0ZE8xeHVJQ0JtYjNJZ0tIWmhjaUJwSUQwZ01Dd2diQ0E5SUhaaGJIVmxMbXhsYm1kMGFEc2dhU0E4SUd3N0lDc3JhU2tnZTF4dUlDQWdJR2xtSUNob1lYTlBkMjVRY205d1pYSjBlU2gyWVd4MVpTd2dVM1J5YVc1bktHa3BLU2tnZTF4dUlDQWdJQ0FnYjNWMGNIVjBMbkIxYzJnb1ptOXliV0YwVUhKdmNHVnlkSGtvWTNSNExDQjJZV3gxWlN3Z2NtVmpkWEp6WlZScGJXVnpMQ0IyYVhOcFlteGxTMlY1Y3l4Y2JpQWdJQ0FnSUNBZ0lDQlRkSEpwYm1jb2FTa3NJSFJ5ZFdVcEtUdGNiaUFnSUNCOUlHVnNjMlVnZTF4dUlDQWdJQ0FnYjNWMGNIVjBMbkIxYzJnb0p5Y3BPMXh1SUNBZ0lIMWNiaUFnZlZ4dUlDQnJaWGx6TG1admNrVmhZMmdvWm5WdVkzUnBiMjRvYTJWNUtTQjdYRzRnSUNBZ2FXWWdLQ0ZyWlhrdWJXRjBZMmdvTDE1Y1hHUXJKQzhwS1NCN1hHNGdJQ0FnSUNCdmRYUndkWFF1Y0hWemFDaG1iM0p0WVhSUWNtOXdaWEowZVNoamRIZ3NJSFpoYkhWbExDQnlaV04xY25ObFZHbHRaWE1zSUhacGMybGliR1ZMWlhsekxGeHVJQ0FnSUNBZ0lDQWdJR3RsZVN3Z2RISjFaU2twTzF4dUlDQWdJSDFjYmlBZ2ZTazdYRzRnSUhKbGRIVnliaUJ2ZFhSd2RYUTdYRzU5WEc1Y2JseHVablZ1WTNScGIyNGdabTl5YldGMFVISnZjR1Z5ZEhrb1kzUjRMQ0IyWVd4MVpTd2djbVZqZFhKelpWUnBiV1Z6TENCMmFYTnBZbXhsUzJWNWN5d2dhMlY1TENCaGNuSmhlU2tnZTF4dUlDQjJZWElnYm1GdFpTd2djM1J5TENCa1pYTmpPMXh1SUNCa1pYTmpJRDBnVDJKcVpXTjBMbWRsZEU5M2JsQnliM0JsY25SNVJHVnpZM0pwY0hSdmNpaDJZV3gxWlN3Z2EyVjVLU0I4ZkNCN0lIWmhiSFZsT2lCMllXeDFaVnRyWlhsZElIMDdYRzRnSUdsbUlDaGtaWE5qTG1kbGRDa2dlMXh1SUNBZ0lHbG1JQ2hrWlhOakxuTmxkQ2tnZTF4dUlDQWdJQ0FnYzNSeUlEMGdZM1I0TG5OMGVXeHBlbVVvSjF0SFpYUjBaWEl2VTJWMGRHVnlYU2NzSUNkemNHVmphV0ZzSnlrN1hHNGdJQ0FnZlNCbGJITmxJSHRjYmlBZ0lDQWdJSE4wY2lBOUlHTjBlQzV6ZEhsc2FYcGxLQ2RiUjJWMGRHVnlYU2NzSUNkemNHVmphV0ZzSnlrN1hHNGdJQ0FnZlZ4dUlDQjlJR1ZzYzJVZ2UxeHVJQ0FnSUdsbUlDaGtaWE5qTG5ObGRDa2dlMXh1SUNBZ0lDQWdjM1J5SUQwZ1kzUjRMbk4wZVd4cGVtVW9KMXRUWlhSMFpYSmRKeXdnSjNOd1pXTnBZV3duS1R0Y2JpQWdJQ0I5WEc0Z0lIMWNiaUFnYVdZZ0tDRm9ZWE5QZDI1UWNtOXdaWEowZVNoMmFYTnBZbXhsUzJWNWN5d2dhMlY1S1NrZ2UxeHVJQ0FnSUc1aGJXVWdQU0FuV3ljZ0t5QnJaWGtnS3lBblhTYzdYRzRnSUgxY2JpQWdhV1lnS0NGemRISXBJSHRjYmlBZ0lDQnBaaUFvWTNSNExuTmxaVzR1YVc1a1pYaFBaaWhrWlhOakxuWmhiSFZsS1NBOElEQXBJSHRjYmlBZ0lDQWdJR2xtSUNocGMwNTFiR3dvY21WamRYSnpaVlJwYldWektTa2dlMXh1SUNBZ0lDQWdJQ0J6ZEhJZ1BTQm1iM0p0WVhSV1lXeDFaU2hqZEhnc0lHUmxjMk11ZG1Gc2RXVXNJRzUxYkd3cE8xeHVJQ0FnSUNBZ2ZTQmxiSE5sSUh0Y2JpQWdJQ0FnSUNBZ2MzUnlJRDBnWm05eWJXRjBWbUZzZFdVb1kzUjRMQ0JrWlhOakxuWmhiSFZsTENCeVpXTjFjbk5sVkdsdFpYTWdMU0F4S1R0Y2JpQWdJQ0FnSUgxY2JpQWdJQ0FnSUdsbUlDaHpkSEl1YVc1a1pYaFBaaWduWEZ4dUp5a2dQaUF0TVNrZ2UxeHVJQ0FnSUNBZ0lDQnBaaUFvWVhKeVlYa3BJSHRjYmlBZ0lDQWdJQ0FnSUNCemRISWdQU0J6ZEhJdWMzQnNhWFFvSjF4Y2JpY3BMbTFoY0NobWRXNWpkR2x2Ymloc2FXNWxLU0I3WEc0Z0lDQWdJQ0FnSUNBZ0lDQnlaWFIxY200Z0p5QWdKeUFySUd4cGJtVTdYRzRnSUNBZ0lDQWdJQ0FnZlNrdWFtOXBiaWduWEZ4dUp5a3VjM1ZpYzNSeUtESXBPMXh1SUNBZ0lDQWdJQ0I5SUdWc2MyVWdlMXh1SUNBZ0lDQWdJQ0FnSUhOMGNpQTlJQ2RjWEc0bklDc2djM1J5TG5Od2JHbDBLQ2RjWEc0bktTNXRZWEFvWm5WdVkzUnBiMjRvYkdsdVpTa2dlMXh1SUNBZ0lDQWdJQ0FnSUNBZ2NtVjBkWEp1SUNjZ0lDQW5JQ3NnYkdsdVpUdGNiaUFnSUNBZ0lDQWdJQ0I5S1M1cWIybHVLQ2RjWEc0bktUdGNiaUFnSUNBZ0lDQWdmVnh1SUNBZ0lDQWdmVnh1SUNBZ0lIMGdaV3h6WlNCN1hHNGdJQ0FnSUNCemRISWdQU0JqZEhndWMzUjViR2w2WlNnblcwTnBjbU4xYkdGeVhTY3NJQ2R6Y0dWamFXRnNKeWs3WEc0Z0lDQWdmVnh1SUNCOVhHNGdJR2xtSUNocGMxVnVaR1ZtYVc1bFpDaHVZVzFsS1NrZ2UxeHVJQ0FnSUdsbUlDaGhjbkpoZVNBbUppQnJaWGt1YldGMFkyZ29MMTVjWEdRckpDOHBLU0I3WEc0Z0lDQWdJQ0J5WlhSMWNtNGdjM1J5TzF4dUlDQWdJSDFjYmlBZ0lDQnVZVzFsSUQwZ1NsTlBUaTV6ZEhKcGJtZHBabmtvSnljZ0t5QnJaWGtwTzF4dUlDQWdJR2xtSUNodVlXMWxMbTFoZEdOb0tDOWVYQ0lvVzJFdGVrRXRXbDlkVzJFdGVrRXRXbDh3TFRsZEtpbGNJaVF2S1NrZ2UxeHVJQ0FnSUNBZ2JtRnRaU0E5SUc1aGJXVXVjM1ZpYzNSeUtERXNJRzVoYldVdWJHVnVaM1JvSUMwZ01pazdYRzRnSUNBZ0lDQnVZVzFsSUQwZ1kzUjRMbk4wZVd4cGVtVW9ibUZ0WlN3Z0oyNWhiV1VuS1R0Y2JpQWdJQ0I5SUdWc2MyVWdlMXh1SUNBZ0lDQWdibUZ0WlNBOUlHNWhiV1V1Y21Wd2JHRmpaU2d2Snk5bkxDQmNJbHhjWEZ3blhDSXBYRzRnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdJQzV5WlhCc1lXTmxLQzljWEZ4Y1hDSXZaeXdnSjF3aUp5bGNiaUFnSUNBZ0lDQWdJQ0FnSUNBZ0lDQWdMbkpsY0d4aFkyVW9MeWhlWENKOFhDSWtLUzluTENCY0lpZGNJaWs3WEc0Z0lDQWdJQ0J1WVcxbElEMGdZM1I0TG5OMGVXeHBlbVVvYm1GdFpTd2dKM04wY21sdVp5Y3BPMXh1SUNBZ0lIMWNiaUFnZlZ4dVhHNGdJSEpsZEhWeWJpQnVZVzFsSUNzZ0p6b2dKeUFySUhOMGNqdGNibjFjYmx4dVhHNW1kVzVqZEdsdmJpQnlaV1IxWTJWVWIxTnBibWRzWlZOMGNtbHVaeWh2ZFhSd2RYUXNJR0poYzJVc0lHSnlZV05sY3lrZ2UxeHVJQ0IyWVhJZ2JuVnRUR2x1WlhORmMzUWdQU0F3TzF4dUlDQjJZWElnYkdWdVozUm9JRDBnYjNWMGNIVjBMbkpsWkhWalpTaG1kVzVqZEdsdmJpaHdjbVYyTENCamRYSXBJSHRjYmlBZ0lDQnVkVzFNYVc1bGMwVnpkQ3NyTzF4dUlDQWdJR2xtSUNoamRYSXVhVzVrWlhoUFppZ25YRnh1SnlrZ1BqMGdNQ2tnYm5WdFRHbHVaWE5GYzNRckt6dGNiaUFnSUNCeVpYUjFjbTRnY0hKbGRpQXJJR04xY2k1eVpYQnNZV05sS0M5Y1hIVXdNREZpWEZ4YlhGeGtYRnhrUDIwdlp5d2dKeWNwTG14bGJtZDBhQ0FySURFN1hHNGdJSDBzSURBcE8xeHVYRzRnSUdsbUlDaHNaVzVuZEdnZ1BpQTJNQ2tnZTF4dUlDQWdJSEpsZEhWeWJpQmljbUZqWlhOYk1GMGdLMXh1SUNBZ0lDQWdJQ0FnSUNBb1ltRnpaU0E5UFQwZ0p5Y2dQeUFuSnlBNklHSmhjMlVnS3lBblhGeHVJQ2NwSUN0Y2JpQWdJQ0FnSUNBZ0lDQWdKeUFuSUN0Y2JpQWdJQ0FnSUNBZ0lDQWdiM1YwY0hWMExtcHZhVzRvSnl4Y1hHNGdJQ2NwSUN0Y2JpQWdJQ0FnSUNBZ0lDQWdKeUFuSUN0Y2JpQWdJQ0FnSUNBZ0lDQWdZbkpoWTJWeld6RmRPMXh1SUNCOVhHNWNiaUFnY21WMGRYSnVJR0p5WVdObGMxc3dYU0FySUdKaGMyVWdLeUFuSUNjZ0t5QnZkWFJ3ZFhRdWFtOXBiaWduTENBbktTQXJJQ2NnSnlBcklHSnlZV05sYzFzeFhUdGNibjFjYmx4dVhHNHZMeUJPVDFSRk9pQlVhR1Z6WlNCMGVYQmxJR05vWldOcmFXNW5JR1oxYm1OMGFXOXVjeUJwYm5SbGJuUnBiMjVoYkd4NUlHUnZiaWQwSUhWelpTQmdhVzV6ZEdGdVkyVnZabUJjYmk4dklHSmxZMkYxYzJVZ2FYUWdhWE1nWm5KaFoybHNaU0JoYm1RZ1kyRnVJR0psSUdWaGMybHNlU0JtWVd0bFpDQjNhWFJvSUdCUFltcGxZM1F1WTNKbFlYUmxLQ2xnTGx4dVpuVnVZM1JwYjI0Z2FYTkJjbkpoZVNoaGNpa2dlMXh1SUNCeVpYUjFjbTRnUVhKeVlYa3VhWE5CY25KaGVTaGhjaWs3WEc1OVhHNWxlSEJ2Y25SekxtbHpRWEp5WVhrZ1BTQnBjMEZ5Y21GNU8xeHVYRzVtZFc1amRHbHZiaUJwYzBKdmIyeGxZVzRvWVhKbktTQjdYRzRnSUhKbGRIVnliaUIwZVhCbGIyWWdZWEpuSUQwOVBTQW5ZbTl2YkdWaGJpYzdYRzU5WEc1bGVIQnZjblJ6TG1selFtOXZiR1ZoYmlBOUlHbHpRbTl2YkdWaGJqdGNibHh1Wm5WdVkzUnBiMjRnYVhOT2RXeHNLR0Z5WnlrZ2UxeHVJQ0J5WlhSMWNtNGdZWEpuSUQwOVBTQnVkV3hzTzF4dWZWeHVaWGh3YjNKMGN5NXBjMDUxYkd3Z1BTQnBjMDUxYkd3N1hHNWNibVoxYm1OMGFXOXVJR2x6VG5Wc2JFOXlWVzVrWldacGJtVmtLR0Z5WnlrZ2UxeHVJQ0J5WlhSMWNtNGdZWEpuSUQwOUlHNTFiR3c3WEc1OVhHNWxlSEJ2Y25SekxtbHpUblZzYkU5eVZXNWtaV1pwYm1Wa0lEMGdhWE5PZFd4c1QzSlZibVJsWm1sdVpXUTdYRzVjYm1aMWJtTjBhVzl1SUdselRuVnRZbVZ5S0dGeVp5a2dlMXh1SUNCeVpYUjFjbTRnZEhsd1pXOW1JR0Z5WnlBOVBUMGdKMjUxYldKbGNpYzdYRzU5WEc1bGVIQnZjblJ6TG1selRuVnRZbVZ5SUQwZ2FYTk9kVzFpWlhJN1hHNWNibVoxYm1OMGFXOXVJR2x6VTNSeWFXNW5LR0Z5WnlrZ2UxeHVJQ0J5WlhSMWNtNGdkSGx3Wlc5bUlHRnlaeUE5UFQwZ0ozTjBjbWx1WnljN1hHNTlYRzVsZUhCdmNuUnpMbWx6VTNSeWFXNW5JRDBnYVhOVGRISnBibWM3WEc1Y2JtWjFibU4wYVc5dUlHbHpVM2x0WW05c0tHRnlaeWtnZTF4dUlDQnlaWFIxY200Z2RIbHdaVzltSUdGeVp5QTlQVDBnSjNONWJXSnZiQ2M3WEc1OVhHNWxlSEJ2Y25SekxtbHpVM2x0WW05c0lEMGdhWE5UZVcxaWIydzdYRzVjYm1aMWJtTjBhVzl1SUdselZXNWtaV1pwYm1Wa0tHRnlaeWtnZTF4dUlDQnlaWFIxY200Z1lYSm5JRDA5UFNCMmIybGtJREE3WEc1OVhHNWxlSEJ2Y25SekxtbHpWVzVrWldacGJtVmtJRDBnYVhOVmJtUmxabWx1WldRN1hHNWNibVoxYm1OMGFXOXVJR2x6VW1WblJYaHdLSEpsS1NCN1hHNGdJSEpsZEhWeWJpQnBjMDlpYW1WamRDaHlaU2tnSmlZZ2IySnFaV04wVkc5VGRISnBibWNvY21VcElEMDlQU0FuVzI5aWFtVmpkQ0JTWldkRmVIQmRKenRjYm4xY2JtVjRjRzl5ZEhNdWFYTlNaV2RGZUhBZ1BTQnBjMUpsWjBWNGNEdGNibHh1Wm5WdVkzUnBiMjRnYVhOUFltcGxZM1FvWVhKbktTQjdYRzRnSUhKbGRIVnliaUIwZVhCbGIyWWdZWEpuSUQwOVBTQW5iMkpxWldOMEp5QW1KaUJoY21jZ0lUMDlJRzUxYkd3N1hHNTlYRzVsZUhCdmNuUnpMbWx6VDJKcVpXTjBJRDBnYVhOUFltcGxZM1E3WEc1Y2JtWjFibU4wYVc5dUlHbHpSR0YwWlNoa0tTQjdYRzRnSUhKbGRIVnliaUJwYzA5aWFtVmpkQ2hrS1NBbUppQnZZbXBsWTNSVWIxTjBjbWx1Wnloa0tTQTlQVDBnSjF0dlltcGxZM1FnUkdGMFpWMG5PMXh1ZlZ4dVpYaHdiM0owY3k1cGMwUmhkR1VnUFNCcGMwUmhkR1U3WEc1Y2JtWjFibU4wYVc5dUlHbHpSWEp5YjNJb1pTa2dlMXh1SUNCeVpYUjFjbTRnYVhOUFltcGxZM1FvWlNrZ0ppWmNiaUFnSUNBZ0lDaHZZbXBsWTNSVWIxTjBjbWx1WnlobEtTQTlQVDBnSjF0dlltcGxZM1FnUlhKeWIzSmRKeUI4ZkNCbElHbHVjM1JoYm1ObGIyWWdSWEp5YjNJcE8xeHVmVnh1Wlhod2IzSjBjeTVwYzBWeWNtOXlJRDBnYVhORmNuSnZjanRjYmx4dVpuVnVZM1JwYjI0Z2FYTkdkVzVqZEdsdmJpaGhjbWNwSUh0Y2JpQWdjbVYwZFhKdUlIUjVjR1Z2WmlCaGNtY2dQVDA5SUNkbWRXNWpkR2x2YmljN1hHNTlYRzVsZUhCdmNuUnpMbWx6Um5WdVkzUnBiMjRnUFNCcGMwWjFibU4wYVc5dU8xeHVYRzVtZFc1amRHbHZiaUJwYzFCeWFXMXBkR2wyWlNoaGNtY3BJSHRjYmlBZ2NtVjBkWEp1SUdGeVp5QTlQVDBnYm5Wc2JDQjhmRnh1SUNBZ0lDQWdJQ0FnZEhsd1pXOW1JR0Z5WnlBOVBUMGdKMkp2YjJ4bFlXNG5JSHg4WEc0Z0lDQWdJQ0FnSUNCMGVYQmxiMllnWVhKbklEMDlQU0FuYm5WdFltVnlKeUI4ZkZ4dUlDQWdJQ0FnSUNBZ2RIbHdaVzltSUdGeVp5QTlQVDBnSjNOMGNtbHVaeWNnZkh4Y2JpQWdJQ0FnSUNBZ0lIUjVjR1Z2WmlCaGNtY2dQVDA5SUNkemVXMWliMnduSUh4OElDQXZMeUJGVXpZZ2MzbHRZbTlzWEc0Z0lDQWdJQ0FnSUNCMGVYQmxiMllnWVhKbklEMDlQU0FuZFc1a1pXWnBibVZrSnp0Y2JuMWNibVY0Y0c5eWRITXVhWE5RY21sdGFYUnBkbVVnUFNCcGMxQnlhVzFwZEdsMlpUdGNibHh1Wlhod2IzSjBjeTVwYzBKMVptWmxjaUE5SUhKbGNYVnBjbVVvSnk0dmMzVndjRzl5ZEM5cGMwSjFabVpsY2ljcE8xeHVYRzVtZFc1amRHbHZiaUJ2WW1wbFkzUlViMU4wY21sdVp5aHZLU0I3WEc0Z0lISmxkSFZ5YmlCUFltcGxZM1F1Y0hKdmRHOTBlWEJsTG5SdlUzUnlhVzVuTG1OaGJHd29ieWs3WEc1OVhHNWNibHh1Wm5WdVkzUnBiMjRnY0dGa0tHNHBJSHRjYmlBZ2NtVjBkWEp1SUc0Z1BDQXhNQ0EvSUNjd0p5QXJJRzR1ZEc5VGRISnBibWNvTVRBcElEb2diaTUwYjFOMGNtbHVaeWd4TUNrN1hHNTlYRzVjYmx4dWRtRnlJRzF2Ym5Sb2N5QTlJRnNuU21GdUp5d2dKMFpsWWljc0lDZE5ZWEluTENBblFYQnlKeXdnSjAxaGVTY3NJQ2RLZFc0bkxDQW5TblZzSnl3Z0owRjFaeWNzSUNkVFpYQW5MRnh1SUNBZ0lDQWdJQ0FnSUNBZ0lDQW5UMk4wSnl3Z0owNXZkaWNzSUNkRVpXTW5YVHRjYmx4dUx5OGdNallnUm1WaUlERTJPakU1T2pNMFhHNW1kVzVqZEdsdmJpQjBhVzFsYzNSaGJYQW9LU0I3WEc0Z0lIWmhjaUJrSUQwZ2JtVjNJRVJoZEdVb0tUdGNiaUFnZG1GeUlIUnBiV1VnUFNCYmNHRmtLR1F1WjJWMFNHOTFjbk1vS1Nrc1hHNGdJQ0FnSUNBZ0lDQWdJQ0FnSUhCaFpDaGtMbWRsZEUxcGJuVjBaWE1vS1Nrc1hHNGdJQ0FnSUNBZ0lDQWdJQ0FnSUhCaFpDaGtMbWRsZEZObFkyOXVaSE1vS1NsZExtcHZhVzRvSnpvbktUdGNiaUFnY21WMGRYSnVJRnRrTG1kbGRFUmhkR1VvS1N3Z2JXOXVkR2h6VzJRdVoyVjBUVzl1ZEdnb0tWMHNJSFJwYldWZExtcHZhVzRvSnlBbktUdGNibjFjYmx4dVhHNHZMeUJzYjJjZ2FYTWdhblZ6ZENCaElIUm9hVzRnZDNKaGNIQmxjaUIwYnlCamIyNXpiMnhsTG14dlp5QjBhR0YwSUhCeVpYQmxibVJ6SUdFZ2RHbHRaWE4wWVcxd1hHNWxlSEJ2Y25SekxteHZaeUE5SUdaMWJtTjBhVzl1S0NrZ2UxeHVJQ0JqYjI1emIyeGxMbXh2WnlnbkpYTWdMU0FsY3ljc0lIUnBiV1Z6ZEdGdGNDZ3BMQ0JsZUhCdmNuUnpMbVp2Y20xaGRDNWhjSEJzZVNobGVIQnZjblJ6TENCaGNtZDFiV1Z1ZEhNcEtUdGNibjA3WEc1Y2JseHVMeW9xWEc0Z0tpQkpibWhsY21sMElIUm9aU0J3Y205MGIzUjVjR1VnYldWMGFHOWtjeUJtY205dElHOXVaU0JqYjI1emRISjFZM1J2Y2lCcGJuUnZJR0Z1YjNSb1pYSXVYRzRnS2x4dUlDb2dWR2hsSUVaMWJtTjBhVzl1TG5CeWIzUnZkSGx3WlM1cGJtaGxjbWwwY3lCbWNtOXRJR3hoYm1jdWFuTWdjbVYzY21sMGRHVnVJR0Z6SUdFZ2MzUmhibVJoYkc5dVpWeHVJQ29nWm5WdVkzUnBiMjRnS0c1dmRDQnZiaUJHZFc1amRHbHZiaTV3Y205MGIzUjVjR1VwTGlCT1QxUkZPaUJKWmlCMGFHbHpJR1pwYkdVZ2FYTWdkRzhnWW1VZ2JHOWhaR1ZrWEc0Z0tpQmtkWEpwYm1jZ1ltOXZkSE4wY21Gd2NHbHVaeUIwYUdseklHWjFibU4wYVc5dUlHNWxaV1J6SUhSdklHSmxJSEpsZDNKcGRIUmxiaUIxYzJsdVp5QnpiMjFsSUc1aGRHbDJaVnh1SUNvZ1puVnVZM1JwYjI1eklHRnpJSEJ5YjNSdmRIbHdaU0J6WlhSMWNDQjFjMmx1WnlCdWIzSnRZV3dnU21GMllWTmpjbWx3ZENCa2IyVnpJRzV2ZENCM2IzSnJJR0Z6WEc0Z0tpQmxlSEJsWTNSbFpDQmtkWEpwYm1jZ1ltOXZkSE4wY21Gd2NHbHVaeUFvYzJWbElHMXBjbkp2Y2k1cWN5QnBiaUJ5TVRFME9UQXpLUzVjYmlBcVhHNGdLaUJBY0dGeVlXMGdlMloxYm1OMGFXOXVmU0JqZEc5eUlFTnZibk4wY25WamRHOXlJR1oxYm1OMGFXOXVJSGRvYVdOb0lHNWxaV1J6SUhSdklHbHVhR1Z5YVhRZ2RHaGxYRzRnS2lBZ0lDQWdjSEp2ZEc5MGVYQmxMbHh1SUNvZ1FIQmhjbUZ0SUh0bWRXNWpkR2x2Ym4wZ2MzVndaWEpEZEc5eUlFTnZibk4wY25WamRHOXlJR1oxYm1OMGFXOXVJSFJ2SUdsdWFHVnlhWFFnY0hKdmRHOTBlWEJsSUdaeWIyMHVYRzRnS2k5Y2JtVjRjRzl5ZEhNdWFXNW9aWEpwZEhNZ1BTQnlaWEYxYVhKbEtDZHBibWhsY21sMGN5Y3BPMXh1WEc1bGVIQnZjblJ6TGw5bGVIUmxibVFnUFNCbWRXNWpkR2x2YmlodmNtbG5hVzRzSUdGa1pDa2dlMXh1SUNBdkx5QkViMjRuZENCa2J5QmhibmwwYUdsdVp5QnBaaUJoWkdRZ2FYTnVKM1FnWVc0Z2IySnFaV04wWEc0Z0lHbG1JQ2doWVdSa0lIeDhJQ0ZwYzA5aWFtVmpkQ2hoWkdRcEtTQnlaWFIxY200Z2IzSnBaMmx1TzF4dVhHNGdJSFpoY2lCclpYbHpJRDBnVDJKcVpXTjBMbXRsZVhNb1lXUmtLVHRjYmlBZ2RtRnlJR2tnUFNCclpYbHpMbXhsYm1kMGFEdGNiaUFnZDJocGJHVWdLR2t0TFNrZ2UxeHVJQ0FnSUc5eWFXZHBibHRyWlhselcybGRYU0E5SUdGa1pGdHJaWGx6VzJsZFhUdGNiaUFnZlZ4dUlDQnlaWFIxY200Z2IzSnBaMmx1TzF4dWZUdGNibHh1Wm5WdVkzUnBiMjRnYUdGelQzZHVVSEp2Y0dWeWRIa29iMkpxTENCd2NtOXdLU0I3WEc0Z0lISmxkSFZ5YmlCUFltcGxZM1F1Y0hKdmRHOTBlWEJsTG1oaGMwOTNibEJ5YjNCbGNuUjVMbU5oYkd3b2IySnFMQ0J3Y205d0tUdGNibjFjYmlKZGZRPT0iXX0=
