function ds = parse_dataset(fname)
% PARSE_DATASET Read dataset from file
%   DS = PARSE_DATASET(FNAME) 
% Supported file formats: GCT, GCTX, CSV, TSV

if isfileexist(fname)
    [~, ~, ext] = fileparts(fname);
    switch lower(ext)
        case {'.gct', '.gctx'}
            ds = parse_gctx(fname);
        case '.csv'
            ds = parse_csv2ds(fname);
        case {'.tsv', '.txt'}
            ds = parse_csv2ds(fname, 'delimiter', '\t');
        otherwise
            error('Unknown format: %s', fname)
    end
elseif isstruct(fname)
    assert(isds(fname), fieldnames(fname));
    ds = fname;
else
    error('File not found: %s', fname);
end

end