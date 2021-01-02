function tf = isNumericType(t)
% isNumericType Check if input type matches a numeric type.
% TF = isNumericType(T) 

if iscell(t)
    tf = cell2mat(cellfun(@(x) ismember(x, mortar.util.DataType.NUMERIC_TYPES),...
        t, 'uniformoutput', false));
else
    tf = ismember(t, mortar.util.DataType.NUMERIC_TYPES);
end
end