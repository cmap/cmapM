function tf = isequal(obj1, obj2)
% isequal(A,B) returns logical 1 (TRUE) if objects A and B are the same
%     size and contain the same values, and logical 0 (FALSE) otherwise.

tf = isequal(size(obj1), size(obj2)) && isequal(obj1.data_, obj2.data_);

end