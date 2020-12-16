function ii = ix_(obj, idx, dim) 
% validate and lookup row or column indices
if obj.isValidIndex_(idx, dim)
       ii = idx;
elseif obj.isValidId_(idx, dim)
    if isequal(dim, 1)
        ii = obj.row_(idx);
    else
        ii = obj.col_(idx);
    end
end
end