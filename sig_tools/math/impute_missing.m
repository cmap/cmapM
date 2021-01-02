function x = impute_missing(x, dim, fun)
% IMPUTE_MISSING Impute missing values in a matrix
%   X = IMPUTE_MISSING(X, DIM, FUN) Replaces NaNs in matrix X with values
%   obtained by applies FUN on matrix X along dimension DIM

[dim_str, dim_val] = get_dim2d(dim);
inan = isnan(x);
if nnz(inan)
    hfun = aggregate_fun(fun);
    imputed_val = hfun(x, dim_val);
    [ir, ic] = find(inan);
    if isequal(dim_str, 'column')
        x(inan) = imputed_val(ic);
    else
        x(inan) = imputed_val(ir);
    end
end

end