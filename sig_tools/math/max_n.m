function mq = max_n(x, p1, p2, dim)
% MAX_QUANTILE Compute the maximum quantile
%   Y = MAX_QUANTILE(X, P1, P2) Compares percentiles P1 and P2 of the matrix X
%   and returns the percentile that has maximum absolute value. The
%   percentiles are specified using percentages, from 0 to 100.
%
%   Y = MAX_QUANTILE(X, P1, P2, DIM) Calculates percentiles along dimentions DIM
%  
% Examples:
%   y = max_quantile(X, 25, 75, 1) % computes the max quartile of columns of x

if ~isvarexist('dim')
    dim = 1;
else
    % just 2d for now
    assert(dim>0 && dim <3, 'Invalid dimensions');
end

p = prctile(x, [p1, p2], dim);
if isequal(dim, 1)
    mq = p(1, :);
    use_p2 = abs(p(1, :)) < abs(p(2, :));
    mq(use_p2) = p(2, use_p2);    
else    
    mq = p(:, 1);
    use_p2 = abs(p(:, 1)) < abs(p(:, 2));
    mq(use_p2) = p(use_p2, 2);
end



end