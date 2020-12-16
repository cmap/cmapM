function subtable = icol(obj, ic)
% Select columns

if obj.isValidIndex_(ic, 2)    
elseif obj.isValidId_(ic, 2)
    ic = obj.col_(ic);    
else
    error('Invalid index');
end
subtable = feval(class(obj), obj.data_(:,ic), obj.columns(ic), obj.rows);
end