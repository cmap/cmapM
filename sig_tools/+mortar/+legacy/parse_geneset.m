function gs = parse_geneset(fname)

if isfileexist(fname)
    [p,f,e] = fileparts(fname);
    switch lower(e)
        case '.gmt'
            gs = parse_gmt(fname);
        case '.gmx'
            gs = parse_gmx(fname);
        otherwise
            error('Unknown format: %s', fname)
    end
else
    error('File not found: %s', fname);
end

end