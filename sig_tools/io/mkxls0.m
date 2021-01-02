function mkxls
%Excel XLS
javaaddpath ('/home/rn/code/matlab/excel/jars/poi-3.7-20101029.jar')
%Excel XLSX
javaaddpath ('/home/rn/code/matlab/excel/jars/poi-ooxml-3.7-20101029.jar')
javaaddpath('/home/rn/code/matlab/excel/jars/xmlbeans-2.3.0.jar')
%optional ?
javaaddpath('/home/rn/code/matlab/excel/jars/poi-ooxml-schemas-3.7-20101029.jar')
javaaddpath('/home/rn/code/matlab/excel/jars/dom4j-1.6.1.jar')
javaaddpath('/home/rn/code/matlab/excel/jars/geronimo-stax-api_1.0_spec-1.0.jar')

fname = 'test.xls';
[~,~,e]= fileparts(fname);
switch (lower(e))
    case '.xlsx'
        wb = org.apache.poi.xssf.usermodel.XSSFWorkbook();        
    case '.xls'
        wb = org.apache.poi.hssf.usermodel.HSSFWorkbook();
    otherwise
        error('Unknown format');
end
% wb = org.apache.poi.hssf.usermodel.HSSFWorkbook();

s = wb.createSheet();
wb.setSheetName(0, 'test');
table_val = reshape(1:50, 10, 5);
table_hdr = strcat('COLUMN',regexp(num2str(1:5), '\s*', 'split'));
row_annot = strcat('ROW',regexp(num2str(1:10), '\s*', 'split'));
% write a column
write_column(s, 1, 0, row_annot);
% write the header
write_table(s, 0, 1, table_hdr);
%write the data matrix
write_table(s, 1, 1, table_val);

out = java.io.FileOutputStream(fname);
wb.write(out);
out.close();
end

function this_row = get_row(s, r)
this_row = s.getRow(r);
if isempty(this_row)
    this_row = s.createRow(r);
end
end

function this_row = write_row(s, r0, c0, row_val)
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
num_rows = size(table_val);
for r = r0+(0:num_rows-1)
    write_row(s, r, c0, table_val(r-r0+1, :));
end
end