function [y, idx] = absmin(x, dim)
% ABSMIN Minimum absolute value
% Y = ABSMIN(X) Returns the element in X that has the smallest absolute
% value. For matrices, a row vector containing the smallest absolute values
% in each column.
%
% Y = ABSMIN(X, DIM) operates along dimension DIM.

if ~isvarexist('dim')    
    dim = 1;
    if isrowvector(x)
        dim = 2;
    end
end


[~, idx] = nanmin(abs(x), [], dim);
if isequal(dim,1)
    y = x(sub2ind(size(x),idx,1:size(x, 2)));
else
    y = x(sub2ind(size(x),(1:size(x, 1))',idx));
end

end