function mq = min_quantile(x, p1, p2, dim)
% MIN_QUANTILE Compute the minimum quantile
%   Y = MIN_QUANTILE(X, P1, P2) Compares percentiles P1 and P2 of the matrix X
%   and returns the percentile that has minimum absolute value. The
%   percentiles are specified using percentages, from 0 to 100.
%
%   Y = MIN_QUANTILE(X, P1, P2, DIM) Calculates percentiles along dimentions DIM
%  
% Examples:
%   y = min_quantile(X, 25, 75, 1) % computes the min quartile of columns of x

if ~isvarexist('dim')
    dim = 1;
else
    % just 2d for now
    assert(dim>0 && dim <3, 'Invalid dimensions');
end

p = prctile(x, [p1, p2], dim);
if isequal(dim, 1)
    mq = p(1, :);
    use_p2 = abs(p(1, :)) > abs(p(2, :));
    mq(use_p2) = p(2, use_p2);    
else    
    mq = p(:, 1);
    use_p2 = abs(p(:, 1)) > abs(p(:, 2));
    mq(use_p2) = p(use_p2, 2);
end

end