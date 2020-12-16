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