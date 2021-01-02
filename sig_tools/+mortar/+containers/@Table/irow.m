function subtable = irow(obj, ir)
% Select rows

if obj.isValidIndex_(ir, 1)    
elseif obj.isValidId_(ir, 1)
    ir = obj.row_(ir);    
else
    error('Invalid row index');
end
subtable = feval(class(obj), obj.data_(ir, :), obj.columns, obj.rows(ir));
end