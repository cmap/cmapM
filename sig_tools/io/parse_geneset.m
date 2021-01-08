function gs = parse_geneset(fname)
% PARSE_GENESET Read genesets from file.
%   GS = PARSE_GENESET(FNAME) 
% Supported file formats: GMT, GMX, GRP, TSV

if isfileexist(fname)
    [p,f,e] = fileparts(fname);
    switch lower(e)
        case '.gmt'
            gs = parse_gmt(fname);
        case '.gmx'
            gs = parse_gmx(fname);
        case '.grp'
            s = parse_grp(fname);
            gs = struct('entry', {s},...
                'head', f,...
                'desc', '',...
                'len', length(s));
        case '.txt'
            tbl = parse_tbl(fname);
            hd = fieldnames(tbl);
            gs = struct('entry', '',...
                    'head', hd,...
                    'desc', f,...
                    'len', length(tbl.(hd{1})));
            for ii=1:length(hd)
                gs(ii).entry = tbl.(hd{ii});
            end
        otherwise
            error('Unknown format: %s', fname)
    end
elseif isstruct(fname)
    assert(all(ismember({'head', 'desc', 'len', 'entry'}, fieldnames(fname))));
    gs = fname;
elseif iscell(fname)    
    s = parse_grp(fname);
    gs = struct('entry', {s},...
        'head', 'gene_set',...
        'desc', '',...
        'len', length(s));
else
    error('File not found: %s', fname);
end

end