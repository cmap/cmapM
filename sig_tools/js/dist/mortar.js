(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({"./js/mortar.js":[function(require,module,exports){
/**
* @desc ```Javascript utility functions used by the Mortar Matlab library```
* @author Rajiv Narayan
* @copyright 2014 Connectivity Map, Broad Institute.
* @version 0.1
* @namespace Mortar
*/

var Mortar = (function ($) {
    var mortar = {};
    
    // URLs to support pages, keyed by HELPID
    var _help_url = {
      query_results : "http://support.lincscloud.org/hc/en-us/articles/202231633-Query-App-Results"
    };

    /**
    * @function updateHelpURL
    * @memberof Mortar#
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
    * @memberof Mortar#
    * @desc ```Parses raw dlm separated data and populates a 
    *  datatable with top connections to a query```
    */
    function dtQueryPreview(obj) {
        var table = Mortar.parseTable(obj.raw_data, '\t', true);
        var col = [];
        
        for (var i in table.header) {
           col.push({sTitle: table.header[i]});
        }

        $(obj.target).dataTable({
           aaData: table.data,
           aoColumns: col,
           aaSorting: [[table.header_lut[obj.sort_field],
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
    * @memberof Mortar#
    * @desc Populates Connection digest index    
    */
   function dtConnectionDigestIndex(obj) {
        table = Mortar.parseTable(obj.raw_data, '\t', true);
        col = [];
        for (var i in table.header) {
           col.push({sTitle: table.header[i]});
        }

        var aoColumnDefs = [];
        if (obj.link_source) {
          if ((typeof table.header_lut[obj.link_source] != "undefined") && 
              (typeof table.header_lut[obj.link_target] != "undefined")) {
              aoColumnDefs = [
              {targets: table.header_lut[obj.link_source], visible: false},
              {targets:table.header_lut[obj.link_target], 
                "render": function(data,type, row) { 
                    return '<a href='+obj.base_url+row[table.header_lut[obj.link_source]]+'>'+data + '</a>';
                    }
              }
              ];
            }
            else {
              console.log('Error inserting links:'+obj.link_source+'->'+obj.link_target);
            }
          }
        
        var dt = $(obj.target).dataTable({
           aaData: table.data,
           aoColumns: col,
           aoColumnDefs: aoColumnDefs,
           aaSorting: [[table.header_lut[obj.sort_field],
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
    * @memberof Mortar#
    * @desc Creates the connection digest report and data tables.
    */
    function dtConnectionDigest(obj) {
       // remap some field names
       fieldMap = {
        'pert_id': 'cmap_id',
        'pert_iname': 'cmap_iname',
        'mean_rankpt_2': 'score_best2',
        'mean_rankpt_4': 'score_best4',
        'mean_rankpt_6': 'score_best6',
       };

       // parse and split table by pert_type
       var table = Mortar.parseTable(obj.raw_data, '\t', true);        
       var split = splitTable(table, 'pert_type');
       // insert ranks
       for (var key in split){
          split[key] = insertColumnIndex(split[key], 'rank');
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
        
        // compound table
        var dt_cp = $(obj.target_cp).dataTable({
           aaData: split.trt_cp.data,
           aoColumns: columnNames,
           aoColumnDefs: aoColumnDefs,
           aaSorting: [[split.trt_cp.header_lut[obj.sort_field],
                obj.sort_order]],
           fnDrawCallback: dtConnectionDigestDrawCallback,                
           bJQueryUI: true, // jqui theme
           sDom: "RfrtiS", // infinite scrolling, reorder columns
           bAdjustWidth: false,
           bScrollCollapse: true,
           sScrollY: "450px", 
           sScrollX: true 
           });

        // CGS table
          var dt_cgs = $(obj.target_cgs).dataTable({
             fnRowCallback: function (nRow, aData) {
                  var decoration = $(obj.expression_checkbox).prop("checked")?"line-through":"none";
                  if (aData[split['trt_sh.cgs'].header_lut.is_expressed_4] != 1) {
                      $(nRow).css({'text-decoration':decoration});
                  }
              },
              aaData: split['trt_sh.cgs'].data,
              aoColumns: columnNames,
              aoColumnDefs: aoColumnDefs,
              aaSorting: [[split['trt_sh.cgs'].header_lut[obj.sort_field],
         obj.sort_order]],
              fnDrawCallback: dtConnectionDigestDrawCallback,                
              bJQueryUI: true, // jqui theme
              sDom: "RfrtiS", // infinite scrolling, reorder columns
              bAdjustWidth: false,
              bScrollCollapse: true,
              sScrollY: "450px", 
              sScrollX: true,
          });

        // gene expression checkbox        
        $(obj.expression_checkbox).change(function() { dt_cgs.fnDraw(); });        
        $(obj.expression_checkbox).prop('checked', true);

        // OE table
        var dt_oe = $(obj.target_oe).dataTable({
           aaData: split.trt_oe.data,
           aoColumns: columnNames,
           aoColumnDefs: aoColumnDefs,
           aaSorting: [[split.trt_oe.header_lut[obj.sort_field],
                obj.sort_order]],
           fnDrawCallback: dtConnectionDigestDrawCallback,                     
           bJQueryUI: true, // jqui theme
           sDom: "RfrtiS", // infinite scrolling, reorder columns
           bAdjustWidth: false,
           bScrollCollapse: true,
           sScrollY: "450px", 
           sScrollX: true 
           });
    }

    /** 
    * @function dtConnectionDigestDrawCallback
    * @memberof Mortar#
    * @desc Handles draw callbacks, custom ranking etc for the connection digest.
    */
    function dtConnectionDigestDrawCallback( oSettings ) {
      var oRanks = {};

        for ( var i=oSettings._iDisplayStart, iLen=oSettings._iDisplayLength ; i<iLen ; i++ ) {
      var idx = oSettings.aiDisplay[i];

      if(oSettings.bSorted){
          var bAscend = oSettings.aaSorting[0][1]=="asc";
          var iRows = oSettings.aiDisplayMaster.length;
          var aRank = new Array(iRows);
          for (var j=0; j<iRows; j++) {
        aRank[oSettings.aiDisplayMaster[j]] = bAscend ? iRows-j : j+1 ;
          }
          oRanks[oSettings.sTableId] = aRank;
      }     
      this.fnUpdate( oRanks[oSettings.sTableId][idx], oSettings.aiDisplay[i], 0, false, false );
        }
    }

    /** @class Filepart    
    * @property {string} path path
    * @property {string} name name
    * @property {string} ext extension
    */
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

    /**
     * ```Split a table by a given field.```
     * @function splitTable
     * @memberof Mortar#
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
    * @memberof Mortar#
    * @param {object} table Table object
    * @param {string} column_name Name of inserted column
    * @returns {Table} table Table object with inserted column
    */
    function insertColumnIndex(table, column_name) {
      for (i=0; i<table.data.length; i++) {
        table.data[i]=[i+1].concat(table.data[i]);
      }
      table.header = [column_name].concat(table.header);
      table.header_lut = list2Index(table.header);    
      return table;  
    }


  /**
      @class
      @name Table
      @property {Integer} nrow Number of rows
      @property {Integer} ncol Number of columns
      @property {Array.<string>} data Table content as an array of string arrays
      @property {Array} header Header names
      @property {Object} header_lut Lookup table of header names to column index
   */
    /**
     * ```Read table data delimited by dlm.```
     * @function parseTable
     * @memberof Mortar#
     * @param {string} raw data from an XHR call
     * @param {string} dlm delimiter. Default is '\t'
     * @param {boolean} has_header Expects that the first line is a header if true. Default is true
     * @returns {Table} Table object
    */

    function parseTable(raw, dlm, has_header) {      
      var i;
      dlm = pick(dlm, '\t');
      has_header = pick(has_header, true);
      var lines = parseList(raw);
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
      table.header_lut = list2Index(table.header);
    return table;
  }

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
    function list2Index(list) {
      var lut = {};
      var i;
      for (i = 0; i<list.length; i++) {
          lut[list[i]] = i;
      }
      return lut;
    }

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

  /**
   * @function pick
   * @memberof Mortar#
   * @desc ```Returns arg if defined else return def```
   * @param arg argument
   * @param def default
   * @returns value
   * 
   */
  function pick (arg, def) {
    return (typeof arg == 'undefined' ? def : arg);
  }

  /**
   * @function minimize
   * @memberof Mortar#
   * @desc ```Minimize element in HTML document```
   * @param {String} target Document selector of target element
   * 
   */
  function minimize(target){
    $(target).animate({opacity:0}, 500); 
    $(target).animate({height:0, width:0}, 500); 
  }
  
  /**
   * @function unhide
   * @memberof Mortar#
   * @desc ```Unhide element in HTML document```
   * @param {String} target Document selector of target element
   * 
   */
  function unhide(target){
    $(target).show();
    $(target).animate({opacity:1}, 500);
  }
  
  /**
   * @function hide
   * @memberof Mortar#
   * @desc ```Hide element in HTML document```
   * @param {String} target Document selector of target element
   * 
   */
  function hide(target){
    $(target).animate({opacity:0}, 1);
  }

  // Export methods and properties
  return {
        fileparts: fileparts,
        parseTable: parseTable,
        parseList: parseList,
        dtQueryPreview: dtQueryPreview,
        dtConnectionDigestIndex: dtConnectionDigestIndex,
        dtConnectionDigest: dtConnectionDigest,
        updateHelpURL: updateHelpURL,
        minimize: minimize,
        hide: hide,
        unhide: unhide
        };
})(jQuery);
},{}]},{},["./js/mortar.js"])
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIm5vZGVfbW9kdWxlcy9icm93c2VyaWZ5L25vZGVfbW9kdWxlcy9icm93c2VyLXBhY2svX3ByZWx1ZGUuanMiLCJqcy9tb3J0YXIuanMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUE7QUNBQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBO0FBQ0E7QUFDQTtBQUNBIiwiZmlsZSI6ImdlbmVyYXRlZC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzQ29udGVudCI6WyIoZnVuY3Rpb24gZSh0LG4scil7ZnVuY3Rpb24gcyhvLHUpe2lmKCFuW29dKXtpZighdFtvXSl7dmFyIGE9dHlwZW9mIHJlcXVpcmU9PVwiZnVuY3Rpb25cIiYmcmVxdWlyZTtpZighdSYmYSlyZXR1cm4gYShvLCEwKTtpZihpKXJldHVybiBpKG8sITApO3ZhciBmPW5ldyBFcnJvcihcIkNhbm5vdCBmaW5kIG1vZHVsZSAnXCIrbytcIidcIik7dGhyb3cgZi5jb2RlPVwiTU9EVUxFX05PVF9GT1VORFwiLGZ9dmFyIGw9bltvXT17ZXhwb3J0czp7fX07dFtvXVswXS5jYWxsKGwuZXhwb3J0cyxmdW5jdGlvbihlKXt2YXIgbj10W29dWzFdW2VdO3JldHVybiBzKG4/bjplKX0sbCxsLmV4cG9ydHMsZSx0LG4scil9cmV0dXJuIG5bb10uZXhwb3J0c312YXIgaT10eXBlb2YgcmVxdWlyZT09XCJmdW5jdGlvblwiJiZyZXF1aXJlO2Zvcih2YXIgbz0wO288ci5sZW5ndGg7bysrKXMocltvXSk7cmV0dXJuIHN9KSIsIi8qKlxuKiBAZGVzYyBgYGBKYXZhc2NyaXB0IHV0aWxpdHkgZnVuY3Rpb25zIHVzZWQgYnkgdGhlIE1vcnRhciBNYXRsYWIgbGlicmFyeWBgYFxuKiBAYXV0aG9yIFJhaml2IE5hcmF5YW5cbiogQGNvcHlyaWdodCAyMDE0IENvbm5lY3Rpdml0eSBNYXAsIEJyb2FkIEluc3RpdHV0ZS5cbiogQHZlcnNpb24gMC4xXG4qIEBuYW1lc3BhY2UgTW9ydGFyXG4qL1xuXG52YXIgTW9ydGFyID0gKGZ1bmN0aW9uICgkKSB7XG4gICAgdmFyIG1vcnRhciA9IHt9O1xuICAgIFxuICAgIC8vIFVSTHMgdG8gc3VwcG9ydCBwYWdlcywga2V5ZWQgYnkgSEVMUElEXG4gICAgdmFyIF9oZWxwX3VybCA9IHtcbiAgICAgIHF1ZXJ5X3Jlc3VsdHMgOiBcImh0dHA6Ly9zdXBwb3J0LmxpbmNzY2xvdWQub3JnL2hjL2VuLXVzL2FydGljbGVzLzIwMjIzMTYzMy1RdWVyeS1BcHAtUmVzdWx0c1wiXG4gICAgfTtcblxuICAgIC8qKlxuICAgICogQGZ1bmN0aW9uIHVwZGF0ZUhlbHBVUkxcbiAgICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAgKiBAZGVzYyBgYGBVcGRhdGVzIHN1cHBvcnQgaHlwZXJsaW5rKHMpIGluIGEgcGFnZS5gYGAgICAgXG4gICAgRXhwZWN0cyB0aGUgbGluayB0byBoYXZlIGEgY2xhc3NuYW1lICdoZWxwX3VybC1IRUxQSUQnIFxuICAgIHdoZXJlIEhFTFBJRCBpcyBhbiBpbnRlcm5hbCBpZGVudGlmaWVyIHRvIHRoZSBzdXBwb3J0IHBhZ2UuXG4gICAgKi8gXG4gICAgZnVuY3Rpb24gdXBkYXRlSGVscFVSTCgpe1xuICAgICAgJChcImFbY2xhc3NePWhlbHBfdXJsLV1cIikuZWFjaChmdW5jdGlvbigpIHtcbiAgICAgICAgdmFyIHVybF9uYW1lID0gdGhpcy5jbGFzc05hbWUucmVwbGFjZSgnaGVscF91cmwtJywnJyk7XG4gICAgICAgICQoJ2EuJyt0aGlzLmNsYXNzTmFtZSkucHJvcCgnaHJlZicsIF9oZWxwX3VybFt1cmxfbmFtZV0pOyAgXG4gICAgICB9KTsgXG4gICAgfVxuXG4gICAgLyoqIFxuICAgICogQGZ1bmN0aW9uIGR0UXVlcnlQcmV2aWV3XG4gICAgKiBAbWVtYmVyb2YgTW9ydGFyI1xuICAgICogQGRlc2MgYGBgUGFyc2VzIHJhdyBkbG0gc2VwYXJhdGVkIGRhdGEgYW5kIHBvcHVsYXRlcyBhIFxuICAgICogIGRhdGF0YWJsZSB3aXRoIHRvcCBjb25uZWN0aW9ucyB0byBhIHF1ZXJ5YGBgXG4gICAgKi9cbiAgICBmdW5jdGlvbiBkdFF1ZXJ5UHJldmlldyhvYmopIHtcbiAgICAgICAgdmFyIHRhYmxlID0gTW9ydGFyLnBhcnNlVGFibGUob2JqLnJhd19kYXRhLCAnXFx0JywgdHJ1ZSk7XG4gICAgICAgIHZhciBjb2wgPSBbXTtcbiAgICAgICAgXG4gICAgICAgIGZvciAodmFyIGkgaW4gdGFibGUuaGVhZGVyKSB7XG4gICAgICAgICAgIGNvbC5wdXNoKHtzVGl0bGU6IHRhYmxlLmhlYWRlcltpXX0pO1xuICAgICAgICB9XG5cbiAgICAgICAgJChvYmoudGFyZ2V0KS5kYXRhVGFibGUoe1xuICAgICAgICAgICBhYURhdGE6IHRhYmxlLmRhdGEsXG4gICAgICAgICAgIGFvQ29sdW1uczogY29sLFxuICAgICAgICAgICBhYVNvcnRpbmc6IFtbdGFibGUuaGVhZGVyX2x1dFtvYmouc29ydF9maWVsZF0sXG4gICAgICAgICAgICAgICAgb2JqLnNvcnRfb3JkZXJdXSxcbiAgICAgICAgICAgXCJiSlF1ZXJ5VUlcIiA6IHRydWUsIC8vIGpxdWkgdGhlbWVcbiAgICAgICAgICAgXCJzRG9tXCIgOiBcIlJmcnRpU1wiLCAvLyBpbmZpbml0ZSBzY3JvbGxpbmcsIHJlb3JkZXIgY29sdW1uc1xuICAgICAgICAgICBcImJTY3JvbGxDb2xsYXBzZVwiOiB0cnVlLFxuICAgICAgICAgICBcInNTY3JvbGxZXCI6IFwiNDUwcHhcIiwgXG4gICAgICAgICAgIFwic1Njcm9sbFhcIjogdHJ1ZSBcbiAgICAgICAgICAgfSk7XG4gICAgfVxuXG4gICAgLyoqIFxuICAgICogQGZ1bmN0aW9uIGR0Q29ubmVjdGlvbkRpZ2VzdEluZGV4XG4gICAgKiBAbWVtYmVyb2YgTW9ydGFyI1xuICAgICogQGRlc2MgUG9wdWxhdGVzIENvbm5lY3Rpb24gZGlnZXN0IGluZGV4ICAgIFxuICAgICovXG4gICBmdW5jdGlvbiBkdENvbm5lY3Rpb25EaWdlc3RJbmRleChvYmopIHtcbiAgICAgICAgdGFibGUgPSBNb3J0YXIucGFyc2VUYWJsZShvYmoucmF3X2RhdGEsICdcXHQnLCB0cnVlKTtcbiAgICAgICAgY29sID0gW107XG4gICAgICAgIGZvciAodmFyIGkgaW4gdGFibGUuaGVhZGVyKSB7XG4gICAgICAgICAgIGNvbC5wdXNoKHtzVGl0bGU6IHRhYmxlLmhlYWRlcltpXX0pO1xuICAgICAgICB9XG5cbiAgICAgICAgdmFyIGFvQ29sdW1uRGVmcyA9IFtdO1xuICAgICAgICBpZiAob2JqLmxpbmtfc291cmNlKSB7XG4gICAgICAgICAgaWYgKCh0eXBlb2YgdGFibGUuaGVhZGVyX2x1dFtvYmoubGlua19zb3VyY2VdICE9IFwidW5kZWZpbmVkXCIpICYmIFxuICAgICAgICAgICAgICAodHlwZW9mIHRhYmxlLmhlYWRlcl9sdXRbb2JqLmxpbmtfdGFyZ2V0XSAhPSBcInVuZGVmaW5lZFwiKSkge1xuICAgICAgICAgICAgICBhb0NvbHVtbkRlZnMgPSBbXG4gICAgICAgICAgICAgIHt0YXJnZXRzOiB0YWJsZS5oZWFkZXJfbHV0W29iai5saW5rX3NvdXJjZV0sIHZpc2libGU6IGZhbHNlfSxcbiAgICAgICAgICAgICAge3RhcmdldHM6dGFibGUuaGVhZGVyX2x1dFtvYmoubGlua190YXJnZXRdLCBcbiAgICAgICAgICAgICAgICBcInJlbmRlclwiOiBmdW5jdGlvbihkYXRhLHR5cGUsIHJvdykgeyBcbiAgICAgICAgICAgICAgICAgICAgcmV0dXJuICc8YSBocmVmPScrb2JqLmJhc2VfdXJsK3Jvd1t0YWJsZS5oZWFkZXJfbHV0W29iai5saW5rX3NvdXJjZV1dKyc+JytkYXRhICsgJzwvYT4nO1xuICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgXTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGVsc2Uge1xuICAgICAgICAgICAgICBjb25zb2xlLmxvZygnRXJyb3IgaW5zZXJ0aW5nIGxpbmtzOicrb2JqLmxpbmtfc291cmNlKyctPicrb2JqLmxpbmtfdGFyZ2V0KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG4gICAgICAgIFxuICAgICAgICB2YXIgZHQgPSAkKG9iai50YXJnZXQpLmRhdGFUYWJsZSh7XG4gICAgICAgICAgIGFhRGF0YTogdGFibGUuZGF0YSxcbiAgICAgICAgICAgYW9Db2x1bW5zOiBjb2wsXG4gICAgICAgICAgIGFvQ29sdW1uRGVmczogYW9Db2x1bW5EZWZzLFxuICAgICAgICAgICBhYVNvcnRpbmc6IFtbdGFibGUuaGVhZGVyX2x1dFtvYmouc29ydF9maWVsZF0sXG4gICAgICAgICAgICAgICAgb2JqLnNvcnRfb3JkZXJdXSxcbiAgICAgICAgICAgXCJiSlF1ZXJ5VUlcIiA6IHRydWUsIC8vIGpxdWkgdGhlbWVcbiAgICAgICAgICAgXCJzRG9tXCIgOiBcIlJmcnRpU1wiLCAvLyBpbmZpbml0ZSBzY3JvbGxpbmcsIHJlb3JkZXIgY29sdW1uc1xuICAgICAgICAgICBcImJBZGp1c3RXaWR0aFwiOiBmYWxzZSxcbiAgICAgICAgICAgXCJiU2Nyb2xsQ29sbGFwc2VcIjogdHJ1ZSxcbiAgICAgICAgICAgXCJzU2Nyb2xsWVwiOiBcIjQ1MHB4XCIsIFxuICAgICAgICAgICBcInNTY3JvbGxYXCI6IHRydWUgXG4gICAgICAgICAgIH0pO1xuICAgIH1cblxuICAgIC8qKiBcbiAgICAqIEBmdW5jdGlvbiBkdENvbm5lY3Rpb25EaWdlc3RcbiAgICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAgKiBAZGVzYyBDcmVhdGVzIHRoZSBjb25uZWN0aW9uIGRpZ2VzdCByZXBvcnQgYW5kIGRhdGEgdGFibGVzLlxuICAgICovXG4gICAgZnVuY3Rpb24gZHRDb25uZWN0aW9uRGlnZXN0KG9iaikge1xuICAgICAgIC8vIHJlbWFwIHNvbWUgZmllbGQgbmFtZXNcbiAgICAgICBmaWVsZE1hcCA9IHtcbiAgICAgICAgJ3BlcnRfaWQnOiAnY21hcF9pZCcsXG4gICAgICAgICdwZXJ0X2luYW1lJzogJ2NtYXBfaW5hbWUnLFxuICAgICAgICAnbWVhbl9yYW5rcHRfMic6ICdzY29yZV9iZXN0MicsXG4gICAgICAgICdtZWFuX3JhbmtwdF80JzogJ3Njb3JlX2Jlc3Q0JyxcbiAgICAgICAgJ21lYW5fcmFua3B0XzYnOiAnc2NvcmVfYmVzdDYnLFxuICAgICAgIH07XG5cbiAgICAgICAvLyBwYXJzZSBhbmQgc3BsaXQgdGFibGUgYnkgcGVydF90eXBlXG4gICAgICAgdmFyIHRhYmxlID0gTW9ydGFyLnBhcnNlVGFibGUob2JqLnJhd19kYXRhLCAnXFx0JywgdHJ1ZSk7ICAgICAgICBcbiAgICAgICB2YXIgc3BsaXQgPSBzcGxpdFRhYmxlKHRhYmxlLCAncGVydF90eXBlJyk7XG4gICAgICAgLy8gaW5zZXJ0IHJhbmtzXG4gICAgICAgZm9yICh2YXIga2V5IGluIHNwbGl0KXtcbiAgICAgICAgICBzcGxpdFtrZXldID0gaW5zZXJ0Q29sdW1uSW5kZXgoc3BsaXRba2V5XSwgJ3JhbmsnKTtcbiAgICAgICB9XG4gICAgICBcbiAgICAgIHZhciBjb2x1bW5OYW1lcyA9IFtdO1xuICAgICAgdmFyIGhlYWRlciA9IHNwbGl0LnRydF9jcC5oZWFkZXI7XG4gICAgICB2YXIgaGVhZGVyX2x1dCA9IHNwbGl0LnRydF9jcC5oZWFkZXJfbHV0O1xuXG4gICAgICBmb3IgKHZhciBpIGluIGhlYWRlcikge1xuICAgICAgICAgIGlmIChoZWFkZXJbaV0gPT09ICdyYW5rJykge1xuICAgICAgICAgICAgY29sdW1uTmFtZXMucHVzaCh7c1RpdGxlOiAnJywgc1R5cGU6J251bWVyaWMnfSk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGVsc2Uge1xuICAgICAgICAgICAgaWYgKGhlYWRlcltpXSBpbiBmaWVsZE1hcCkge1xuICAgICAgICAgICAgICBjb2x1bW5OYW1lcy5wdXNoKHtzVGl0bGU6IGZpZWxkTWFwW2hlYWRlcltpXV19KTsgIFxuICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgY29sdW1uTmFtZXMucHVzaCh7c1RpdGxlOiBoZWFkZXJbaV19KTsgIFxuICAgICAgICAgICAgfVxuICAgICAgICAgICAgXG4gICAgICAgICAgfVxuICAgICAgfVxuICAgICAgICAvLyBoYW5kbGUgc3BlY2lhbCBjb2x1bW5zXG4gICAgICAgdmFyIGFvQ29sdW1uRGVmcyA9IFtcbiAgICAgICAge3RhcmdldHM6IFtoZWFkZXJfbHV0LnBlcnRfdHlwZSxcbiAgICAgICAgICAgICAgICAgICBoZWFkZXJfbHV0LmlzX2V4cHJlc3NlZF80LFxuICAgICAgICAgICAgICAgICAgIGhlYWRlcl9sdXQuaXNfZXhwcmVzc2VkXzZcbiAgICAgICAgICAgICAgICAgIF0sXG4gICAgICAgICB2aXNpYmxlOiBmYWxzZVxuICAgICAgICB9LFxuICAgICAgICB7dGFyZ2V0czogW2hlYWRlcl9sdXQucmFua10sXG4gICAgICAgICAgc29ydGFibGU6IGZhbHNlfVxuICAgICAgICBdO1xuICAgICAgICBcbiAgICAgICAgLy8gY29tcG91bmQgdGFibGVcbiAgICAgICAgdmFyIGR0X2NwID0gJChvYmoudGFyZ2V0X2NwKS5kYXRhVGFibGUoe1xuICAgICAgICAgICBhYURhdGE6IHNwbGl0LnRydF9jcC5kYXRhLFxuICAgICAgICAgICBhb0NvbHVtbnM6IGNvbHVtbk5hbWVzLFxuICAgICAgICAgICBhb0NvbHVtbkRlZnM6IGFvQ29sdW1uRGVmcyxcbiAgICAgICAgICAgYWFTb3J0aW5nOiBbW3NwbGl0LnRydF9jcC5oZWFkZXJfbHV0W29iai5zb3J0X2ZpZWxkXSxcbiAgICAgICAgICAgICAgICBvYmouc29ydF9vcmRlcl1dLFxuICAgICAgICAgICBmbkRyYXdDYWxsYmFjazogZHRDb25uZWN0aW9uRGlnZXN0RHJhd0NhbGxiYWNrLCAgICAgICAgICAgICAgICBcbiAgICAgICAgICAgYkpRdWVyeVVJOiB0cnVlLCAvLyBqcXVpIHRoZW1lXG4gICAgICAgICAgIHNEb206IFwiUmZydGlTXCIsIC8vIGluZmluaXRlIHNjcm9sbGluZywgcmVvcmRlciBjb2x1bW5zXG4gICAgICAgICAgIGJBZGp1c3RXaWR0aDogZmFsc2UsXG4gICAgICAgICAgIGJTY3JvbGxDb2xsYXBzZTogdHJ1ZSxcbiAgICAgICAgICAgc1Njcm9sbFk6IFwiNDUwcHhcIiwgXG4gICAgICAgICAgIHNTY3JvbGxYOiB0cnVlIFxuICAgICAgICAgICB9KTtcblxuICAgICAgICAvLyBDR1MgdGFibGVcbiAgICAgICAgICB2YXIgZHRfY2dzID0gJChvYmoudGFyZ2V0X2NncykuZGF0YVRhYmxlKHtcbiAgICAgICAgICAgICBmblJvd0NhbGxiYWNrOiBmdW5jdGlvbiAoblJvdywgYURhdGEpIHtcbiAgICAgICAgICAgICAgICAgIHZhciBkZWNvcmF0aW9uID0gJChvYmouZXhwcmVzc2lvbl9jaGVja2JveCkucHJvcChcImNoZWNrZWRcIik/XCJsaW5lLXRocm91Z2hcIjpcIm5vbmVcIjtcbiAgICAgICAgICAgICAgICAgIGlmIChhRGF0YVtzcGxpdFsndHJ0X3NoLmNncyddLmhlYWRlcl9sdXQuaXNfZXhwcmVzc2VkXzRdICE9IDEpIHtcbiAgICAgICAgICAgICAgICAgICAgICAkKG5Sb3cpLmNzcyh7J3RleHQtZGVjb3JhdGlvbic6ZGVjb3JhdGlvbn0pO1xuICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICBhYURhdGE6IHNwbGl0Wyd0cnRfc2guY2dzJ10uZGF0YSxcbiAgICAgICAgICAgICAgYW9Db2x1bW5zOiBjb2x1bW5OYW1lcyxcbiAgICAgICAgICAgICAgYW9Db2x1bW5EZWZzOiBhb0NvbHVtbkRlZnMsXG4gICAgICAgICAgICAgIGFhU29ydGluZzogW1tzcGxpdFsndHJ0X3NoLmNncyddLmhlYWRlcl9sdXRbb2JqLnNvcnRfZmllbGRdLFxuICAgICAgICAgb2JqLnNvcnRfb3JkZXJdXSxcbiAgICAgICAgICAgICAgZm5EcmF3Q2FsbGJhY2s6IGR0Q29ubmVjdGlvbkRpZ2VzdERyYXdDYWxsYmFjaywgICAgICAgICAgICAgICAgXG4gICAgICAgICAgICAgIGJKUXVlcnlVSTogdHJ1ZSwgLy8ganF1aSB0aGVtZVxuICAgICAgICAgICAgICBzRG9tOiBcIlJmcnRpU1wiLCAvLyBpbmZpbml0ZSBzY3JvbGxpbmcsIHJlb3JkZXIgY29sdW1uc1xuICAgICAgICAgICAgICBiQWRqdXN0V2lkdGg6IGZhbHNlLFxuICAgICAgICAgICAgICBiU2Nyb2xsQ29sbGFwc2U6IHRydWUsXG4gICAgICAgICAgICAgIHNTY3JvbGxZOiBcIjQ1MHB4XCIsIFxuICAgICAgICAgICAgICBzU2Nyb2xsWDogdHJ1ZSxcbiAgICAgICAgICB9KTtcblxuICAgICAgICAvLyBnZW5lIGV4cHJlc3Npb24gY2hlY2tib3ggICAgICAgIFxuICAgICAgICAkKG9iai5leHByZXNzaW9uX2NoZWNrYm94KS5jaGFuZ2UoZnVuY3Rpb24oKSB7IGR0X2Nncy5mbkRyYXcoKTsgfSk7ICAgICAgICBcbiAgICAgICAgJChvYmouZXhwcmVzc2lvbl9jaGVja2JveCkucHJvcCgnY2hlY2tlZCcsIHRydWUpO1xuXG4gICAgICAgIC8vIE9FIHRhYmxlXG4gICAgICAgIHZhciBkdF9vZSA9ICQob2JqLnRhcmdldF9vZSkuZGF0YVRhYmxlKHtcbiAgICAgICAgICAgYWFEYXRhOiBzcGxpdC50cnRfb2UuZGF0YSxcbiAgICAgICAgICAgYW9Db2x1bW5zOiBjb2x1bW5OYW1lcyxcbiAgICAgICAgICAgYW9Db2x1bW5EZWZzOiBhb0NvbHVtbkRlZnMsXG4gICAgICAgICAgIGFhU29ydGluZzogW1tzcGxpdC50cnRfb2UuaGVhZGVyX2x1dFtvYmouc29ydF9maWVsZF0sXG4gICAgICAgICAgICAgICAgb2JqLnNvcnRfb3JkZXJdXSxcbiAgICAgICAgICAgZm5EcmF3Q2FsbGJhY2s6IGR0Q29ubmVjdGlvbkRpZ2VzdERyYXdDYWxsYmFjaywgICAgICAgICAgICAgICAgICAgICBcbiAgICAgICAgICAgYkpRdWVyeVVJOiB0cnVlLCAvLyBqcXVpIHRoZW1lXG4gICAgICAgICAgIHNEb206IFwiUmZydGlTXCIsIC8vIGluZmluaXRlIHNjcm9sbGluZywgcmVvcmRlciBjb2x1bW5zXG4gICAgICAgICAgIGJBZGp1c3RXaWR0aDogZmFsc2UsXG4gICAgICAgICAgIGJTY3JvbGxDb2xsYXBzZTogdHJ1ZSxcbiAgICAgICAgICAgc1Njcm9sbFk6IFwiNDUwcHhcIiwgXG4gICAgICAgICAgIHNTY3JvbGxYOiB0cnVlIFxuICAgICAgICAgICB9KTtcbiAgICB9XG5cbiAgICAvKiogXG4gICAgKiBAZnVuY3Rpb24gZHRDb25uZWN0aW9uRGlnZXN0RHJhd0NhbGxiYWNrXG4gICAgKiBAbWVtYmVyb2YgTW9ydGFyI1xuICAgICogQGRlc2MgSGFuZGxlcyBkcmF3IGNhbGxiYWNrcywgY3VzdG9tIHJhbmtpbmcgZXRjIGZvciB0aGUgY29ubmVjdGlvbiBkaWdlc3QuXG4gICAgKi9cbiAgICBmdW5jdGlvbiBkdENvbm5lY3Rpb25EaWdlc3REcmF3Q2FsbGJhY2soIG9TZXR0aW5ncyApIHtcbiAgICAgIHZhciBvUmFua3MgPSB7fTtcblxuICAgICAgICBmb3IgKCB2YXIgaT1vU2V0dGluZ3MuX2lEaXNwbGF5U3RhcnQsIGlMZW49b1NldHRpbmdzLl9pRGlzcGxheUxlbmd0aCA7IGk8aUxlbiA7IGkrKyApIHtcbiAgICAgIHZhciBpZHggPSBvU2V0dGluZ3MuYWlEaXNwbGF5W2ldO1xuXG4gICAgICBpZihvU2V0dGluZ3MuYlNvcnRlZCl7XG4gICAgICAgICAgdmFyIGJBc2NlbmQgPSBvU2V0dGluZ3MuYWFTb3J0aW5nWzBdWzFdPT1cImFzY1wiO1xuICAgICAgICAgIHZhciBpUm93cyA9IG9TZXR0aW5ncy5haURpc3BsYXlNYXN0ZXIubGVuZ3RoO1xuICAgICAgICAgIHZhciBhUmFuayA9IG5ldyBBcnJheShpUm93cyk7XG4gICAgICAgICAgZm9yICh2YXIgaj0wOyBqPGlSb3dzOyBqKyspIHtcbiAgICAgICAgYVJhbmtbb1NldHRpbmdzLmFpRGlzcGxheU1hc3RlcltqXV0gPSBiQXNjZW5kID8gaVJvd3MtaiA6IGorMSA7XG4gICAgICAgICAgfVxuICAgICAgICAgIG9SYW5rc1tvU2V0dGluZ3Muc1RhYmxlSWRdID0gYVJhbms7XG4gICAgICB9ICAgICBcbiAgICAgIHRoaXMuZm5VcGRhdGUoIG9SYW5rc1tvU2V0dGluZ3Muc1RhYmxlSWRdW2lkeF0sIG9TZXR0aW5ncy5haURpc3BsYXlbaV0sIDAsIGZhbHNlLCBmYWxzZSApO1xuICAgICAgICB9XG4gICAgfVxuXG4gICAgLyoqIEBjbGFzcyBGaWxlcGFydCAgICBcbiAgICAqIEBwcm9wZXJ0eSB7c3RyaW5nfSBwYXRoIHBhdGhcbiAgICAqIEBwcm9wZXJ0eSB7c3RyaW5nfSBuYW1lIG5hbWVcbiAgICAqIEBwcm9wZXJ0eSB7c3RyaW5nfSBleHQgZXh0ZW5zaW9uXG4gICAgKi9cbiAgICAvKiogXG4gICAgICogQGZ1bmN0aW9uIGZpbGVwYXJ0c1xuICAgICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAgICogQGRlc2MgU3BsaXQgYSBmaWxlbmFtZSBpbnRvIGNvbXBvbmVudHNcbiAgICAgKiBAcGFyYW0ge3N0cmluZ30gZmlsZW5hbWVcbiAgICAgKiBAcmV0dXJucyB7RmlsZXBhcnR9IEZpbGVwYXJ0IG9iamVjdFxuICAgICAqL1xuICAgIGZ1bmN0aW9uIGZpbGVwYXJ0cyhuYW1lKSB7XG4gICAgICAgdmFyIHAgPSAnJztcbiAgICAgICB2YXIgZiA9ICcnO1xuICAgICAgIHZhciBlID0gJyc7XG4gICAgICAgdmFyIHNsYXNoaWR4ID0gbmFtZS5sYXN0SW5kZXhPZignLycpO1xuICAgICAgIHZhciByZW0gPSBuYW1lO1xuICAgICAgIGlmIChzbGFzaGlkeCA+PSAwKSB7XG4gICAgICAgICAgIHAgPSBuYW1lLnN1YnN0cmluZygxLCBzbGFzaGlkeCk7XG4gICAgICAgICAgIHJlbSA9IG5hbWUuc3Vic3RyaW5nKHNsYXNoaWR4LCBuYW1lLmxlbmd0aCkudG9VcHBlckNhc2UoKTtcbiAgICAgICB9XG4gICAgICAgdmFyIGRvdGlkeCA9IHJlbS5sYXN0SW5kZXhPZignLicpO1xuICAgICAgIGlmIChkb3RpZHggPj0gMCApIHtcbiAgICAgICAgICAgZiA9IHJlbS5zdWJzdHJpbmcoMSwgZG90aWR4LTEpO1xuICAgICAgICAgICBlID0gZi5zdWJzdHJpbmcoZG90aWR4ICsgMSwgZi5sZW5ndGgpO1xuICAgICAgIH1cbiAgICAgICBlbHNlIHtcbiAgICAgICAgICAgZiA9IHJlbTtcbiAgICAgICB9XG4gICAgICAgcmV0dXJuIHtwYXRoIDogcCwgbmFtZSA6IGYsIGV4dCA6IGV9O1xuICAgIH1cblxuICAgIC8qKlxuICAgICAqIGBgYFNwbGl0IGEgdGFibGUgYnkgYSBnaXZlbiBmaWVsZC5gYGBcbiAgICAgKiBAZnVuY3Rpb24gc3BsaXRUYWJsZVxuICAgICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAgICogQHBhcmFtIHtvYmplY3R9IHRhYmxlIFRhYmxlIG9iamVjdCByZXR1cm5lZCBieSBwYXJzZVRhYmxlXG4gICAgICogQHBhcmFtIHtzdHJpbmd9IHNwbGl0X2J5IEZpZWxkbmFtZSB0byBzcGxpdCBieSAgICBcbiAgICAgKiBAcmV0dXJucyB7VGFibGV9IE9iamVjdCBvZiBUYWJsZSBvYmplY3RzXG4gICAgKi9cbiAgICBmdW5jdGlvbiBzcGxpdFRhYmxlKHRhYmxlLCBzcGxpdF9ieSkge1xuICAgICAgdmFyIHNwbGl0ID0ge307XG4gICAgICB2YXIgY2lkeCA9IHRhYmxlLmhlYWRlcl9sdXRbc3BsaXRfYnldO1xuICAgICAgdmFyIGk9MCwgcm93O1xuICAgICAgZm9yIChpPTA7IGk8dGFibGUuZGF0YS5sZW5ndGg7IGkrKykge1xuICAgICAgICByb3cgPSB0YWJsZS5kYXRhW2ldO1xuICAgICAgICBpZiAoc3BsaXRbcm93W2NpZHhdXT09PXVuZGVmaW5lZCkge1xuICAgICAgICAgIHNwbGl0W3Jvd1tjaWR4XV0gPSB7bnJvdzowLCBuY29sOjAsIGRhdGE6W10sIGhlYWRlcjpbXSwgaGVhZGVyX2x1dDpbXX07XG4gICAgICAgIH1cbiAgICAgICAgc3BsaXRbcm93W2NpZHhdXS5kYXRhLnB1c2gocm93KTtcbiAgICAgIH1cbiAgICAgIFxuICAgICAgZm9yICh2YXIga2V5IGluIHNwbGl0KXtcbiAgICAgICAgc3BsaXRba2V5XS5ucm93ID0gc3BsaXRba2V5XS5kYXRhLmxlbmd0aDtcbiAgICAgICAgc3BsaXRba2V5XS5uY29sID0gdGFibGUuZGF0YS5sZW5ndGg7XG4gICAgICAgIHNwbGl0W2tleV0uaGVhZGVyID0gdGFibGUuaGVhZGVyO1xuICAgICAgICBzcGxpdFtrZXldLmhlYWRlcl9sdXQgPSB0YWJsZS5oZWFkZXJfbHV0O1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gc3BsaXQ7XG4gICAgfVxuXG4gICAgLyoqIFxuICAgICogYGBgUHJlcGVuZHMgYW4gaW5kZXggY29sdW1uIHRvIGEgdGFibGVgYGBcbiAgICAqIEBmdW5jdGlvbiBpbnNlcnRDb2x1bW5JbmRleFxuICAgICogQG1lbWJlcm9mIE1vcnRhciNcbiAgICAqIEBwYXJhbSB7b2JqZWN0fSB0YWJsZSBUYWJsZSBvYmplY3RcbiAgICAqIEBwYXJhbSB7c3RyaW5nfSBjb2x1bW5fbmFtZSBOYW1lIG9mIGluc2VydGVkIGNvbHVtblxuICAgICogQHJldHVybnMge1RhYmxlfSB0YWJsZSBUYWJsZSBvYmplY3Qgd2l0aCBpbnNlcnRlZCBjb2x1bW5cbiAgICAqL1xuICAgIGZ1bmN0aW9uIGluc2VydENvbHVtbkluZGV4KHRhYmxlLCBjb2x1bW5fbmFtZSkge1xuICAgICAgZm9yIChpPTA7IGk8dGFibGUuZGF0YS5sZW5ndGg7IGkrKykge1xuICAgICAgICB0YWJsZS5kYXRhW2ldPVtpKzFdLmNvbmNhdCh0YWJsZS5kYXRhW2ldKTtcbiAgICAgIH1cbiAgICAgIHRhYmxlLmhlYWRlciA9IFtjb2x1bW5fbmFtZV0uY29uY2F0KHRhYmxlLmhlYWRlcik7XG4gICAgICB0YWJsZS5oZWFkZXJfbHV0ID0gbGlzdDJJbmRleCh0YWJsZS5oZWFkZXIpOyAgICBcbiAgICAgIHJldHVybiB0YWJsZTsgIFxuICAgIH1cblxuXG4gIC8qKlxuICAgICAgQGNsYXNzXG4gICAgICBAbmFtZSBUYWJsZVxuICAgICAgQHByb3BlcnR5IHtJbnRlZ2VyfSBucm93IE51bWJlciBvZiByb3dzXG4gICAgICBAcHJvcGVydHkge0ludGVnZXJ9IG5jb2wgTnVtYmVyIG9mIGNvbHVtbnNcbiAgICAgIEBwcm9wZXJ0eSB7QXJyYXkuPHN0cmluZz59IGRhdGEgVGFibGUgY29udGVudCBhcyBhbiBhcnJheSBvZiBzdHJpbmcgYXJyYXlzXG4gICAgICBAcHJvcGVydHkge0FycmF5fSBoZWFkZXIgSGVhZGVyIG5hbWVzXG4gICAgICBAcHJvcGVydHkge09iamVjdH0gaGVhZGVyX2x1dCBMb29rdXAgdGFibGUgb2YgaGVhZGVyIG5hbWVzIHRvIGNvbHVtbiBpbmRleFxuICAgKi9cbiAgICAvKipcbiAgICAgKiBgYGBSZWFkIHRhYmxlIGRhdGEgZGVsaW1pdGVkIGJ5IGRsbS5gYGBcbiAgICAgKiBAZnVuY3Rpb24gcGFyc2VUYWJsZVxuICAgICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAgICogQHBhcmFtIHtzdHJpbmd9IHJhdyBkYXRhIGZyb20gYW4gWEhSIGNhbGxcbiAgICAgKiBAcGFyYW0ge3N0cmluZ30gZGxtIGRlbGltaXRlci4gRGVmYXVsdCBpcyAnXFx0J1xuICAgICAqIEBwYXJhbSB7Ym9vbGVhbn0gaGFzX2hlYWRlciBFeHBlY3RzIHRoYXQgdGhlIGZpcnN0IGxpbmUgaXMgYSBoZWFkZXIgaWYgdHJ1ZS4gRGVmYXVsdCBpcyB0cnVlXG4gICAgICogQHJldHVybnMge1RhYmxlfSBUYWJsZSBvYmplY3RcbiAgICAqL1xuXG4gICAgZnVuY3Rpb24gcGFyc2VUYWJsZShyYXcsIGRsbSwgaGFzX2hlYWRlcikgeyAgICAgIFxuICAgICAgdmFyIGk7XG4gICAgICBkbG0gPSBwaWNrKGRsbSwgJ1xcdCcpO1xuICAgICAgaGFzX2hlYWRlciA9IHBpY2soaGFzX2hlYWRlciwgdHJ1ZSk7XG4gICAgICB2YXIgbGluZXMgPSBwYXJzZUxpc3QocmF3KTtcbiAgICAgIHZhciB0YWJsZSA9IHsnbnJvdyc6MCwgJ25jb2wnOjAsICdkYXRhJzpbXSwgJ2hlYWRlcic6W10sICdoZWFkZXJfbHV0JzpbXX07XG4gICAgICBmb3IgKGk9KGhhc19oZWFkZXIgPyAxIDogMCk7IGk8bGluZXMubGVuZ3RoOyBpKyspIHtcbiAgICAgICAgdGFibGUuZGF0YS5wdXNoKGxpbmVzW2ldLnNwbGl0KGRsbSkpO1xuICAgICAgfVxuICAgICAgdGFibGUubnJvdyA9IHRhYmxlLmRhdGEubGVuZ3RoO1xuICAgICAgdGFibGUubmNvbCA9IHRhYmxlLmRhdGFbMF0ubGVuZ3RoO1xuICAgICAgaWYgKGhhc19oZWFkZXIpIHtcbiAgICAgICAgdGFibGUuaGVhZGVyID0gbGluZXNbMF0uc3BsaXQoZGxtKTtcbiAgICAgIH1cbiAgICAgIGVsc2Uge1xuICAgICAgICBmb3IgKGk9MDsgaTx0YWJsZS5uY29sOyBpKyspe1xuICAgICAgICAgIHRhYmxlLmhlYWRlci5wdXNoKCdDT0xfJytpKTtcbiAgICAgICAgfSBcbiAgICAgIH1cbiAgICAgIHRhYmxlLmhlYWRlcl9sdXQgPSBsaXN0MkluZGV4KHRhYmxlLmhlYWRlcik7XG4gICAgcmV0dXJuIHRhYmxlO1xuICB9XG5cbiAgICAvKipcbiAgICAgKiBAZnVuY3Rpb24gbGlzdDJpbmRleFxuICAgICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAgICogQGRlc2MgYGBgR2VuZXJhdGUgbG9va3VwIHRhYmxlIGZvciBhbiBhcnJheSBvZiB2YWx1ZXMgdG8gdGhlaXIgemVyby1pbmRleGVkIHBvc2l0aW9uIFxuICAgICAqIGluIHRoZSBhcnJheS5gYGBcbiAgICAgKiBOb3RlOiBpbiB0aGUgY2FzZSBvZiBkdXBsaWNhdGUgdmFsdWVzLCB0aGUgaW5kZXggb2YgdGhlIGxhc3QgXG4gICAgICogb2NjdXJyZW5jZSBvZiB0aGUgZWxlbWVudCBpcyByZXR1cm5lZC5cbiAgICAgKiBAcGFyYW0ge0FycmF5fSBhcnJheSBvZiB2YWx1ZXMuXG4gICAgICogQHJldHVybnMge09iamVjdH0gb2JqZWN0IG9mIHZhbHVlcyB0byB6ZXJvLWJhc2VkIGFycmF5IGluZGljZXNcbiAgICAgKi9cbiAgICBmdW5jdGlvbiBsaXN0MkluZGV4KGxpc3QpIHtcbiAgICAgIHZhciBsdXQgPSB7fTtcbiAgICAgIHZhciBpO1xuICAgICAgZm9yIChpID0gMDsgaTxsaXN0Lmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgbHV0W2xpc3RbaV1dID0gaTtcbiAgICAgIH1cbiAgICAgIHJldHVybiBsdXQ7XG4gICAgfVxuXG4gICAgLyoqXG4gICAgICogQGZ1bmN0aW9uIHBhcnNlTGlzdFxuICAgICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAgICogQGRlc2MgYGBgUmVhZHMgbGluZXMgZnJvbSBzdHJpbmcgaW5wdXRgYGBcbiAgICAgKiBAcGFyYW0ge1N0cmluZ30gU3RyaW5nIHdpdGggbmV3bGluZXNcbiAgICAgKiBAcmV0dXJucyB7QXJyYXk8U3RyaW5nPn0gXG4gICAgICovXG4gICAgZnVuY3Rpb24gcGFyc2VMaXN0KHJhdykge1xuICAgICByYXcgPSByYXcucmVwbGFjZSgvKFxcclxcbnxcXG58XFxyKSsvZ2ksICdcXG4nKTtcbiAgICAgdmFyIGxpbmVzID0gcmF3LnNwbGl0KCdcXG4nKTtcbiAgICAgLy8gZHJvcCB0aGUgbGFzdCBlbXB0eSBsaW5lXG4gICAgIGlmIChsaW5lc1tsaW5lcy5sZW5ndGgtMV0gPT09IFwiXCIpIHtcbiAgICAgIGxpbmVzLnNwbGljZShsaW5lcy5sZW5ndGgtMSwgMSk7XG4gICAgIH1cbiAgICAgcmV0dXJuIGxpbmVzO1xuICAgIH1cblxuICAvKipcbiAgICogQGZ1bmN0aW9uIHBpY2tcbiAgICogQG1lbWJlcm9mIE1vcnRhciNcbiAgICogQGRlc2MgYGBgUmV0dXJucyBhcmcgaWYgZGVmaW5lZCBlbHNlIHJldHVybiBkZWZgYGBcbiAgICogQHBhcmFtIGFyZyBhcmd1bWVudFxuICAgKiBAcGFyYW0gZGVmIGRlZmF1bHRcbiAgICogQHJldHVybnMgdmFsdWVcbiAgICogXG4gICAqL1xuICBmdW5jdGlvbiBwaWNrIChhcmcsIGRlZikge1xuICAgIHJldHVybiAodHlwZW9mIGFyZyA9PSAndW5kZWZpbmVkJyA/IGRlZiA6IGFyZyk7XG4gIH1cblxuICAvKipcbiAgICogQGZ1bmN0aW9uIG1pbmltaXplXG4gICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAqIEBkZXNjIGBgYE1pbmltaXplIGVsZW1lbnQgaW4gSFRNTCBkb2N1bWVudGBgYFxuICAgKiBAcGFyYW0ge1N0cmluZ30gdGFyZ2V0IERvY3VtZW50IHNlbGVjdG9yIG9mIHRhcmdldCBlbGVtZW50XG4gICAqIFxuICAgKi9cbiAgZnVuY3Rpb24gbWluaW1pemUodGFyZ2V0KXtcbiAgICAkKHRhcmdldCkuYW5pbWF0ZSh7b3BhY2l0eTowfSwgNTAwKTsgXG4gICAgJCh0YXJnZXQpLmFuaW1hdGUoe2hlaWdodDowLCB3aWR0aDowfSwgNTAwKTsgXG4gIH1cbiAgXG4gIC8qKlxuICAgKiBAZnVuY3Rpb24gdW5oaWRlXG4gICAqIEBtZW1iZXJvZiBNb3J0YXIjXG4gICAqIEBkZXNjIGBgYFVuaGlkZSBlbGVtZW50IGluIEhUTUwgZG9jdW1lbnRgYGBcbiAgICogQHBhcmFtIHtTdHJpbmd9IHRhcmdldCBEb2N1bWVudCBzZWxlY3RvciBvZiB0YXJnZXQgZWxlbWVudFxuICAgKiBcbiAgICovXG4gIGZ1bmN0aW9uIHVuaGlkZSh0YXJnZXQpe1xuICAgICQodGFyZ2V0KS5zaG93KCk7XG4gICAgJCh0YXJnZXQpLmFuaW1hdGUoe29wYWNpdHk6MX0sIDUwMCk7XG4gIH1cbiAgXG4gIC8qKlxuICAgKiBAZnVuY3Rpb24gaGlkZVxuICAgKiBAbWVtYmVyb2YgTW9ydGFyI1xuICAgKiBAZGVzYyBgYGBIaWRlIGVsZW1lbnQgaW4gSFRNTCBkb2N1bWVudGBgYFxuICAgKiBAcGFyYW0ge1N0cmluZ30gdGFyZ2V0IERvY3VtZW50IHNlbGVjdG9yIG9mIHRhcmdldCBlbGVtZW50XG4gICAqIFxuICAgKi9cbiAgZnVuY3Rpb24gaGlkZSh0YXJnZXQpe1xuICAgICQodGFyZ2V0KS5hbmltYXRlKHtvcGFjaXR5OjB9LCAxKTtcbiAgfVxuXG4gIC8vIEV4cG9ydCBtZXRob2RzIGFuZCBwcm9wZXJ0aWVzXG4gIHJldHVybiB7XG4gICAgICAgIGZpbGVwYXJ0czogZmlsZXBhcnRzLFxuICAgICAgICBwYXJzZVRhYmxlOiBwYXJzZVRhYmxlLFxuICAgICAgICBwYXJzZUxpc3Q6IHBhcnNlTGlzdCxcbiAgICAgICAgZHRRdWVyeVByZXZpZXc6IGR0UXVlcnlQcmV2aWV3LFxuICAgICAgICBkdENvbm5lY3Rpb25EaWdlc3RJbmRleDogZHRDb25uZWN0aW9uRGlnZXN0SW5kZXgsXG4gICAgICAgIGR0Q29ubmVjdGlvbkRpZ2VzdDogZHRDb25uZWN0aW9uRGlnZXN0LFxuICAgICAgICB1cGRhdGVIZWxwVVJMOiB1cGRhdGVIZWxwVVJMLFxuICAgICAgICBtaW5pbWl6ZTogbWluaW1pemUsXG4gICAgICAgIGhpZGU6IGhpZGUsXG4gICAgICAgIHVuaGlkZTogdW5oaWRlXG4gICAgICAgIH07XG59KShqUXVlcnkpOyJdfQ==
