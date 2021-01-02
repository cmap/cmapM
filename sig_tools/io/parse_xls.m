function data = parse_xls(fname, varargin)
% PARSE_XLS Parse an Excel spreadsheet.
%   D = PARSE_XLS(FNAME) Reads the left-most spreadsheet from FNAME.
%   D = PARSE_XLS(FNAME, name, value,...)
%
%   Options:
%   'outfmt': Output format. Valid values are
%       {'raw','table','table_nohead'}. Default is table.
%   'wksheet': Worksheet to read. Can be numeric or a string. Default is 0
%       which is the left-most spreadsheet.
%   'ls': List all worksheets in the file. Returns a structure with the
%       name and index of each spreadsheet.
%   Requires jar files from the Apache POI Project. See http://poi.apache.org

% Sample code:
% http://svn.apache.org/repos/asf/poi/trunk/src/examples/src/org/apache/poi/hssf/usermodel/examples/HSSFReadWrite.java

pnames = {'wksheet', 'outfmt', 'ls', 'datefmt'};
dflts = {'0', 'table', false, 'mm/dd/yyyy'};
args = parse_args(pnames, dflts, varargin{:});

if isfileexist(fname)
    add_excel_jar;
%import org.apache.poi.ss.usermodel.DateUtil    
    if args.ls
        data = list_wksheet(fname);
    else
        wk_is_idx = false;
        if ~isnan(str2double(args.wksheet))
            wk_is_idx = true;
            args.wksheet=str2double(args.wksheet);
        end
        
        wb = xlsopen(fname);
        num_wks = wb.getNumberOfSheets;
        if wk_is_idx
            if args.wksheet < num_wks
                sheet = wb.getSheetAt(args.wksheet);
            else
                error('Sheet index (%d) is out of range (0..%d)', args.wksheet, num_wks)
            end
        else
            sheet = wb.getSheet(args.wksheet);
            if isempty(sheet)
                error('Invalid sheet name %s', args.wksheet)
            end
        end
        
        % Evaluator for formulae
        evaluator = wb.getCreationHelper.createFormulaEvaluator;
        nr = sheet.getPhysicalNumberOfRows;
        row1 = sheet.getRow(0);
        if ~isempty(row1)
            % Assume table nr x nc
            nc = row1.getPhysicalNumberOfCells;
            data = cell(nr, nc);
            fprintf('Table dimensions: %dx%d', nr, nc);
            for ii=1:nr
                row = sheet.getRow(ii-1);
                for jj=1:nc
                    thiscell = row.getCell(jj-1);
                    if ~isempty(thiscell)
                        % evaluate formula before extracting value
                        if isequal(thiscell.getCellType, thiscell.CELL_TYPE_FORMULA)
                            evaluator.evaluateInCell(thiscell);
                        end
                        data{ii, jj} = get_value(thiscell, args);
                    end
                end
            end
            if ~strcmpi('raw', args.outfmt)
                data = format_data(data, args.outfmt);
            end
        else
            %no data
            data = {};
        end
    end
else
    error('File not found %s', fname);
end
end

function value = get_value(thiscell, args)
% Get value from a cell. Handles Numeric, Date and String
switch (thiscell.getCellType())
    case thiscell.CELL_TYPE_NUMERIC
        if org.apache.poi.ss.usermodel.DateUtil.isCellDateFormatted(thiscell)
            % is a date
            if ~isempty(args.datefmt)
                cal = java.util.Calendar.getInstance;
                cal.setTime(thiscell.getDateCellValue);
                % convert to Matlab date vector
                % Note: cal.MONTH is zero-indexed
                dv = [cal.get(cal.YEAR), ...
                    cal.get(cal.MONTH) + 1, ...
                    cal.get(cal.DATE), ...
                    cal.get(cal.HOUR), ...
                    cal.get(cal.MINUTE), ...
                    cal.get(cal.SECOND)];
                % format date
                value = datestr(dv, args.datefmt);
            else
                % Excel format
                value = char(thiscell.getDateCellValue);
            end
        else
            % non-date numeric
            value = str2double(thiscell);
        end
    case thiscell.CELL_TYPE_STRING
        value = char(thiscell);
end
end

function wb = xlsopen(fname)
% Open XLS? file and return handle
xlsin=java.io.FileInputStream(fname);
[~,~,e]= fileparts(fname);
switch (lower(e))
    case '.xlsx'
        wb = org.apache.poi.xssf.usermodel.XSSFWorkbook(xlsin);
    case '.xls'
        wb = org.apache.poi.hssf.usermodel.HSSFWorkbook(xlsin);
    otherwise
        error('Unknown format');
end
end

function wks = list_wksheet(fname)
    wb = xlsopen(fname);
    num_wks = wb.getNumberOfSheets;
    wks = struct('idx', num2cell(0:num_wks-1), 'name','');
    for ii=0:num_wks-1
        wks(ii+1).name = char(wb.getSheetName(ii));
        fprintf('%d. %s\n', ii, wks(ii+1).name);
    end
end

function out = format_data(data, fmt)
switch(lower(fmt))
    case {'table','table_nohead'}
        nr = size(data, 1);
        if strcmpi('table', fmt)
            % table with header in first row
            if nr<2
                error('Table should have more than 1 row')
            end
            fn = lower(validvar(data(1, :)));
            st = 2;
        else
            % table with no header
            st = 1;
            fn = gen_labels(size(data,2), 'prefix', 'col');
        end
        for ii=1:length(fn)
            x = data(st:end, ii);
            x(cellfun(@isempty, x)) = {''};
            is_number = all(ismember((cellfun(@class, x, ...
                'uniformoutput',false)), {'double','single','logical'}));
            if is_number
                out.(fn{ii}) = cell2mat(x);
            else
                out.(fn{ii}) = x;
            end
        end        
    otherwise
        error('Unknown format %s', fmt)
end
end
