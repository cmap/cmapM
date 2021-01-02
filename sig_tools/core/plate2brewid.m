function pp = plate2brewid(p)
% Unique RNA plates without replicate info

if ischar(p)
    p = {p};
end
tok = tokenize(p, '_');
np = length(p);
nt = cellfun(@length, tok);
if all(nt>2)
    % WARNING: could match non-rep fields, e.g. a cell line thats starts with X[0-9]+
    rep_idx = cellfun(@(x) find(~cellfun(@isempty, regexp(x,'^X[0-9]+')), 1, 'first'), tok);    
    pp = cell(np, 1);
    for ii=1:np
        pp{ii} = print_dlm_line(tok{ii}(1:rep_idx(ii)-1), 'dlm', '_');
    end
%     pp = cellfun(@(x) print_dlm_line(x(1:3), 'dlm', '_'), tok, ...
%     'uniformoutput', false);    
else
    disp(p(nt<=2))
    error('Invalid Plate ID')
end