function tf = isNumericType(t)
% Check if input matches a numeric type.
num_type = {'double', 'single', 'int8', ...
    'uint8', 'int16', 'uint16',...
    'int32', 'uint32', 'int64', ...
    'uint64', 'logical'};

if iscell(t)
    tf = cell2mat(cellfun(@(x) ismember(x, num_type),...
        t, 'uniformoutput', false));
else
    tf = ismember(t, num_type);
end
end