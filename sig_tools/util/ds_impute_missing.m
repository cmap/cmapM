function ds = ds_impute_missing(ds, dim, miss_action, impute_fun)
% DS_IMPUTE_MISSING Impute missing data
%   DS = DS_IMPUTE_MISSING(DS, DIM, MISS_ACTION, IMPUTE_FUN) Handles
%   missing values (NaNs) in the data structure DS based on the action
%   specified by MISS_ACTION which can be:
%       'drop' : Drop columns with missing data if DIM is 1 or 'column' and
%                rows if DIM is 2 or 'row'
%       'impute' : Impute missing values using IMPUTE_FUN applied on DS
%                along dimension DIM
%       'fill' : Replace missing values with a constant value specified by
%               IMPUTE_FUN

[dim_str, dim_val] = get_dim2d(dim);
ds = parse_gctx(ds);
inan = isnan(ds.mat);
nnan = nnz(inan);
if nnan    
    dbg(1, 'Data has %d missing values', nnan);
    [ir, ic] = find(inan);
    
    if isequal(dim_str, 'row')
        % transpose so as to always operate on columns
        ds = transpose_gct(ds);
        tmp = ir;
        ir = ic;
        ic = tmp;
    end
    
    switch lower(miss_action)
        case 'drop'
            uniq_ic = unique(ic);
            dbg(1, 'Dropping %d %s(s) that have missing values', length(uniq_ic), dim_str);
            keep_cidx = setdiff(1:length(ds.cid), ic, 'stable');
            ds = ds_slice(ds, 'cidx', keep_cidx);
            
        case 'impute'
            uniq_ic = unique(ic);
            dbg(1, 'Imputing %d missing values in %d %s(s) using %s',...
                nnan, length(uniq_ic), dim_str, impute_fun);
            ds.mat = impute_missing(ds.mat, 'column', impute_fun);
            % drop any remaining columns that are nans
            ds = ds_impute_missing(ds, 'column', 'drop');
            
        case 'fill'
            assert(isnumeric(impute_fun) & isscalar(impute_fun),...
                'For fill action expect IMPUTE_FUN to be a numeric scalar, got class %s of length %d instead',...
                class(impute_fun), length(impute_fun));
            dbg(1, 'Replacing missing values with %g', impute_fun);
            ds = ds_nan_to_val(ds, impute_fun);
            
        otherwise
            error('Unknown action %s', miss_action);
    end
    
    % transpose if needed
    if isequal(dim_str, 'row')
        ds = transpose_gct(ds);
    end
else
    dbg(1, 'Data has no missing values');
end

end