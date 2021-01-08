function s = asStruct(obj)
% convert table object to struct

s = cell2struct(obj.data_, obj.columns, 2);

end