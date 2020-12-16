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
