function m = getMeta(si, field)
    if isfield(si, field)
        m = {si.(field)};
    else
        m = cell(length(si), 1);
        m(:) = {''};
    end
end