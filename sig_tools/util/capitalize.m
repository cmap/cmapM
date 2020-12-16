function s = capitalize(s)
    if ischar(s)
        s = {s};
    end
    assert(iscell(s), 'Input should be a cell array of strings');
    s = cellfun(@(x) [upper(x(1)),x(2:end)], s, 'uniformoutput', false);
end