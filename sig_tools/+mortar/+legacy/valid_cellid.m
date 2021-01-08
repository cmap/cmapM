function vn = valid_cellid(n)
% VALID_CELLID Check cell name id.

% use valid var, apply fix if name begins with a number
vn = upper(validvar(n));
re = regexp(n, '^[0-9]');
if ~isempty(re)
    if iscell(re)
        isnumstart = ~cellfun(@isempty, re);
    else
        isnumstart = re;
    end
    vn(isnumstart) = regexprep(vn(isnumstart), '^N', '');
end

end