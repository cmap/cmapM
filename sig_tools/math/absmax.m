function [y, idx] = absmax(x, dim)
% ABSMAX Maximum absolute value
% Y = ABSMAX(X) Returns the element in X that has the largest absolute
% value. For matrices, a row vector containing the largest absolute values
% in each column.
%
% [Y, I] = ABSMAX(X) returns the row indices corresponding to X
%
% Y = ABSMAX(X, DIM) operates along dimension DIM.

if ~isvarexist('dim')    
    dim = 1;
    if isrowvector(x)
        dim = 2;
    end
end


[~, idx] = nanmax(abs(x), [], dim);
if isequal(dim,1)
    y = x(sub2ind(size(x),idx,1:size(x, 2)));
else
    y = x(sub2ind(size(x),(1:size(x, 1))',idx));
end

end