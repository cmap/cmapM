function out = cut(ca, pos, dlm, missing)
% CUT extract substrings from a delimited array of strings.
%   O = CUT(C, POS, DLM) splits the cell array of strings C by the
%   delimiter string DLM and returns the substrings specified by POS. Empty
%   strings are returned if the substring at a given POS does not exist.
%   O = CUT(C, POS, DLM, MISSVAL) use MISSVAL for missing values.

[nr, nc] = size(ca);
assert(isequal(nc, 1), 'One column expected, found %d', nc);
assert(all(pos>0), 'Position indices must be real positive integers');
tok = tokenize(ca, dlm);

try
    % assume no missing values
    if isequal(numel(pos), 1)
        out = cellfun(@(x) x{pos}, tok, 'uniformoutput', false);
    else
        out = cellfun(@(x) x(pos), tok, 'uniformoutput', false);
        out = cat(2, out{:})';
    end
catch
    % failed, try with missing values
    [nt, nl] = getcls(cellfun(@numel, tok));
    if ~isvarexist('missing')
        missing = {''};
    end
    if ~iscell(missing)
        missing = {missing};
    end
    out = missing(ones(nr, numel(pos)));
    
    for ii=1:length(nt)
        this = nl == ii;
        out_pos = pos<=nt(ii);
        this_pos = pos(out_pos);
        if ~isempty(this_pos)
            o = cellfun(@(x) x(this_pos), tok(this), 'uniformoutput', false);
            o = cat(2, o{:})';
            out(this, out_pos) = o;
        end
    end
end

end