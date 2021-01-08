function mn = best_n(x, n, dim, statfn)
% BEST_N Compute an aggregate statistic based on the top n values.
%   Y = BEST_N(X, N) Compare the mean of the top and bottom N largest
%   values of the matrix X and returns the mean that has maximum absolute
%   value.
%
%   Y = BEST_N(X, N, DIM) Calculates meand along dimentions DIM
%
%   Y = BEST_N(X, N, DIM, STATFN) applies the function STATFN instead of
%   the mean. STATFUN is a function that take a vector and a dimension as
%   inputs and return a scalar value.
%  
% Examples:
%   y = best_n(X, 3, 1) % computes the top-3 mean of columns of X
%   y = bestn(X, 3, 2, @median) % computes the top-3 median of rows of X

if ~isvarexist('dim')
    dim = 1;
else
    % just 2d for now
    assert(dim>0 && dim <3, 'Invalid dimensions');
end

if ~isvarexist('stat')
    statfn = @mean;   
end

[nr, nc] = size(x);


if isequal(dim, 1)
    if n>nr
        mn = nan(1, nc);
    else        
        [srtx, srti] = sort(x, dim, 'descend');
        max_x = statfn(srtx(1:n, :), dim);
        min_x = statfn(srtx(nr-n+1:nr, :), dim);
        mn = max_x(1, :);
        use_min = abs(max_x(1, :)) < abs(min_x(1, :));
        mn(use_min) = min_x(1, use_min);
    end
else    
    if n>nc
        mn = nan(nr, 1);
    else
        [srtx, srti] = sort(x, dim, 'descend');
        max_x = statfn(srtx(:, 1:n), dim);
        min_x = statfn(srtx(:, nr-n+1:nr), dim);
        mn = max_x(:, 1);
        use_min = abs(max_x(:, 1)) < abs(min_x(:, 2));
        mn(use_min) = min_x(use_min, 2);
    end
end

end