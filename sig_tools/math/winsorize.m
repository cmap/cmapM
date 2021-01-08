function x = winsorize(x, plow, phigh, dim)
% WINSORIZE Apply winsorization to data to mitigate outliers.
% Y = WINSORIZE(X, PL, PH) Transforms X such that values exceeding the
% percentile values PL and PH are reset to those values.
% Y = WINSORIZE(X, PL, PH, DIM) operate on the specified dimension.

if ~isvarexist('dim')
    dim = 1;
end
assert(any(ismember(dim,[1,2])), 'Dimension must be 1 or 2');
q = prctile(x, [plow, phigh], dim);

if isequal(dim, 2)
    islow = bsxfun(@lt, x, q(:, 1));
    [ir_low,~] = find(islow);
    ishigh = bsxfun(@gt, x, q(:, 2));
    [ir_high,~] = find(ishigh);
    x(islow) = q(ir_low, 1);
    x(ishigh) = q(ir_high, 2);
else
    islow = bsxfun(@lt, x, q(1, :));
    [~, ic_low] = find(islow);
    ishigh = bsxfun(@gt, x, q(2, :));
    [~, ic_high] = find(ishigh);
    x(islow) = q(1, ic_low);
    x(ishigh) = q(2, ic_high);    
end

end