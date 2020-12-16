function [idx, val, gp_id, gp_sz] = group_select_index(x, gp, method)
[gp_id, gp_idx] = getcls(gp);
gp_sz = accumarray(gp_idx, ones(size(gp_idx)));
offsets = [0; cumsum(gp_sz(1:end-1))];
x = x(:);
nx = length(x);
assert(isequal(nx, length(gp_idx)), 'Dimension mismatch between x and gp');

switch(method)
    case 'min'
        [val, min_idx] = grpstats(x, gp_idx, {@nanmin, @imin});
        idx = offsets + min_idx;
        
    case 'max'
        [val, max_idx] = grpstats(x, gp_idx, {@nanmax, @imax});
        idx = offsets + max_idx;
        
    otherwise
        error('Unknown method: %s', method)
end


end