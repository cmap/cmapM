function li = toCell_(li)
if ischar(li) || isnumeric(li) || islogical(li)
    li = {li};
elseif ~iscell(li)
    error('Input should be a cell array or scalar');
end
end
