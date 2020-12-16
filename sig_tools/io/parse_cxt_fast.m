function ds = parse_cxt_fast(fname)
% PARSE_CXT_FAST Parse CXT files (optimized for speed).
%   DS = PARSE_CXT_FAST(FNAME)
% See also: PARSE_CXT

if isfileexist(fname)
    try
        if ~isempty(regexpi(fname, '.gz$', 'once'))
            [status, lines] = system(sprintf('gzip -dc ''%s''', fname));
            assert(isequal(status,0), 'Error reading input: %s', lines);
        else
            fid = fopen(fname, 'rt');
            lines = textscan(fid, '%s', 'delimiter', '\n');
        end
        
        % read headers
        [hd, lastidx] = get_header(lines);
        
        % name check
        [~, f]=fileparts(fname);
        ext_name = regexprep(f,'\.CXT','','ignorecase');
        int_name = regexprep(hd.NAME,'\.CEL$','','ignorecase');
        int_name = regexprep(int_name,'\.CEL\.gz$','','ignorecase');
        if ~isequal(int_name, ext_name)
            disp(int_name);
            disp(ext_name);
            error('Name check error')
        end
        nr = str2double(hd.NUM_FEATURES);
        
        % column header line
        [colhd, nextpos] = textscan(lines(lastidx+1:end), '%s', 1, 'delimiter', '\n');
        tok = tokenize(colhd{1}, char(9), true);
        expidx = strcmpi('MAS5', tok{1});
        ridx = strcmpi('NAME', tok{1});
        rhidx = strcmpi('pcalls', tok{1});
        
        % read data
        if ~isempty(expidx)
            v = textscan(lines(lastidx+nextpos+1:end),...
                '%s %f %s', 'delimiter','\t', 'endofline', '\n');
            rid = v{ridx};
            rdesc = v{rhidx};
            mat = v{expidx};
        else
            error('MAS5 column not found')
        end
        
        ds = mkgctstruct(mat, 'rid', rid,...
            'rhd', {'pcalls'},...
            'rdesc', rdesc,...
            'cid', {ext_name},...
            'chd', {'array';'num_features'},...
            'cdesc', {hd.CHIP; hd.NUM_FEATURES});
    catch err
        disp(err.message)
        error('Error reading %s', fname)
    end
    
else
    error('File not found: %s', fname)
end

end

function [hd, lastidx] = get_header(lines)

[val, lastidx] = textscan(lines, '#%s', 'delimiter', '\t');
tok = tokenize(val{1}(2:end), ': ', true);
k = cellfun(@(x) x{1}, tok, 'uniformoutput', false);
v = cellfun(@(x) x{2}, tok, 'uniformoutput', false);
hd = cell2struct(v, k);

end
