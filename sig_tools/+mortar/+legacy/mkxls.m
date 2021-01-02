function mkxls(fname, tbl, varargin)
% MKXLS Create an Excel spreadsheet.
%   D = MKXLS(FNAME, TBL) Creates a new spreadsheet in FNAME. Supports both
%   .XLS and .XLSX formats. Selects the format based on the file extension.
%   TBL can be a cell array or a structure like the output of PARSE_TBL.
%
%   D = MKXLS(FNAME, TBL, name, value,...)
%
%   Options: 'wksheet': Worksheet to read. Can be numeric or a string.
%       Default is 0 which is the left-most spreadsheet.
%
%   Note: Requires jar files from the Apache POI Project. See
%   http://poi.apache.org

% TODO:
% Add sheets to workbook
% support for gct files

pnames = {'wksheet'};
dflts = {'0'};
args = parse_args(pnames, dflts, varargin{:});

% Apache POI
add_excel_jar
% jarlist = {'poi-3.7-20101029.jar',...
%     'poi-ooxml-3.7-20101029.jar',...
%     'poi-ooxml-schemas-3.7-20101029.jar',...
%     'dom4j-1.6.1.jar',...
%     'xmlbeans-2.3.0.jar'};
% jarpath = fullfile(mortarpath, 'ext/jars');
% addjar(jarlist, jarpath);

wk_is_idx = false;
if ~isnan(str2double(args.wksheet))
    wk_is_idx = true;
    args.wksheet=str2double(args.wksheet);
end

%create new wb
[wb, isxlsx] = xlsopen(fname);

% create a new sheet
if wk_is_idx
    sheet = wb.createSheet(sprintf('Sheet%d',args.wksheet+1));
else
    sheet = wb.createSheet(args.wksheet);
end
% wb.setSheetName(0, 'test');

% Write table data
if iscell(tbl)
    check_row_limit(size(tbl,2), isxlsx)
    % cell array
    write_table(sheet, 0, 0, tbl);
elseif isstruct(tbl)    
    % struct (e.g. output of parse_sin, parse_tbl)
    fn = fieldnames(tbl);
    check_row_limit(size(tbl.(fn{1}),2), isxlsx);
    % create header
    write_row(sheet, 0, 0, fn);
    % write columns
    for ii=1:length(fn);        
        write_column(sheet, 1, ii-1, tbl.(fn{ii}));
    end
elseif isgct(tbl)
    %TOADD GCT support
%     % column headers
%     write_table(sheet, 0, 0, tbl.cid)  
else
    error ('Unsupported table format')
end

% write data
out = java.io.FileOutputStream(fname);
wb.write(out);
out.close();

end

function yn = isgct(x)
% Check is struct has valid gct fields
reqfn = {'rid','cid','mat',...
    'rhd','rdesc','chd','cdesc'};
yn = false;
if isstruct(x)
    fn = fieldnames(x);
    yn = all(ismember(reqfn, fn));    
end
end

function [wb, isxlsx] = xlsopen(fname)
% Open XLS? file and return handle
[~,~,e]= fileparts(fname);
isxlsx = false;
switch (lower(e))
    case '.xlsx'
        wb = org.apache.poi.xssf.usermodel.XSSFWorkbook();        
        isxlsx = true;
    case '.xls'
        wb = org.apache.poi.hssf.usermodel.HSSFWorkbook();
    otherwise
        error('Unknown format');
end
% TODO: open existing file for upserts.
% xlsin=java.io.FileInputStream(fname);
% switch (lower(e))
%     case '.xlsx'
%         wb = org.apache.poi.xssf.usermodel.XSSFWorkbook(xlsin);
%     case '.xls'
%         wb = org.apache.poi.hssf.usermodel.HSSFWorkbook(xlsin);
%     otherwise
%         error('Unknown format');
% end
end

function this_row = get_row(s, r)
% Get handle to a row, Create a new one if it does not exist
this_row = s.getRow(r);
if isempty(this_row)
    this_row = s.createRow(r);
end
end

function this_row = write_row(s, r0, c0, row_val)
% Write a single row to a work sheet
num_cols = length(row_val);
this_row = get_row(s, r0);
for c=c0+(0:num_cols-1)
    this_cell =  this_row.createCell(c);
    if iscell(row_val)
        this_cell.setCellValue(row_val{c-c0+1});
    else
        this_cell.setCellValue(row_val(c-c0+1));
    end
end
end

function write_column(s, r0, c0, col_val)
% write a single column
num_rows = length(col_val);
for r=r0+(0:num_rows-1)
    this_row = get_row(s, r);
    this_cell =  this_row.createCell(c0);
    if iscell(col_val)
        this_cell.setCellValue(col_val{r-r0+1});
    else
        this_cell.setCellValue(col_val(r-r0+1));
    end
end
end
    
function write_table(s, r0, c0, table_val)
% Write a table of values
num_rows = size(table_val);
for r = r0+(0:num_rows-1)
    write_row(s, r, c0, table_val(r-r0+1, :));
end
end

function check_row_limit(numrows, isxlsx)
% Check if num rows is within range
if ~isxlsx && numrows > 65536
    error('Row limit exceeded of XLS [0...65535] found %d', numrows)
end    
end
