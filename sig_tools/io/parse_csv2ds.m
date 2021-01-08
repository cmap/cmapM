function ds = parse_csv2ds(fname, row_id_field, matrix_start_field, varargin)
% PARSE_CSV2DS Parse dataset from CSV or TSV files
% ds = parse_csv2ds(fname, row_id_field, matrix_start_field, varargin)

config = struct('name', {'--delimiter'; '--has_header'},...
    'default', {''; true},...
    'help', {'value separator'; 'file has a header'});
opt = struct('prog', mfilename, 'desc', 'Parse dataset from CSV or TSV files');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});


if isfileexist(fname)    
    
    if isempty(args.delimiter)
        [p, f, ext] = fileparts(fname);
        switch (lower(ext))
            case {'.csv'}
                args.delimiter = ',';
            case {'.txt', '.tsv'}
                args.delimiter = '\t';
            otherwise
                error('Unsupported extension: %s', ext)
        end
    end
    
    hd = parse_header(fname);       
    row_id_index = get_field_index(hd, row_id_field);       
    matrix_start_index = get_field_index(hd, matrix_start_field);
    
    if ischar(matrix_start_field)
        matrix_start_index = find(strcmp(hd, matrix_start_field));
        assert(~isempty(matrix_start_field), 'matrix start field %s not found', matrix_start_field)
    elseif isnumeric(matrix_start_field)
        matrix_start_index = round(matrix_start_field);
        assert(matrix_start_index >0   && matrix_start_index <= length(hd),...
            'Numeirc matrix_start_field must range 1 to %d', length(hd))
    else
        error('matrix_start_field must be a string or numeric index');
    end
    matrix_range = matrix_start_index:length(hd);
    
    fmt_string = {'%s'};
    fmt_numeric = {'%f'};    
    fmt = print_dlm_line([fmt_string(ones(matrix_start_index-1,1)); fmt_numeric(length(matrix_range), 1)], 'dlm', '');
    
    %
    tbl = readtable(fname, 'Delimiter', args.delimiter,  'FileType', 'text', 'ReadVariableNames', true, 'Format', fmt);    
    ds = tbl2gct(table2struct(tbl), hd(matrix_range), row_id_field);
    
else
    error('File not found: %s', fname);
end

end

function index = get_field_index(hd, field)
if ischar(field)
    index = find(strcmp(hd, field));
    assert(~isempty(field), 'field %s not found', field)
elseif isnumeric(field)
    index = round(field);
    assert(index >0   && index <= length(hd),...
        'Numeric field must range 1 to %d', length(hd))
else
    error('field must be a string or numeric index');
end
end