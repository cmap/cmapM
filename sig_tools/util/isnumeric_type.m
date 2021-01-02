function tf = isnumeric_type(x)
% ISNUMERIC_TYPE Test if input is numeric.

num_type = {'double', 'single', 'int8', ...
    'uint8', 'int16', 'uint16',...
    'int32', 'uint32', 'int64', ...
    'uint64', 'logical'};

if iscell(x)
    tf = cell2mat(cellfun(@(x) ismember(class(x), num_type), x,'uniformoutput', false));
else
    tf = ismember(class(x), num_type);
end

end