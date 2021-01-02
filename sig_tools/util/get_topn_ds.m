function [ds_top, iy] = get_topn_ds(ds, n, dim, direc, is_two_tailed)

[dim_str, dim_num]=get_dim2d(dim);

if isequal(dim_str, 'row')
    by_row = true;
else
    by_row = false;
end

[~, iy] = get_topn(ds.mat, n, dim_str, direc, is_two_tailed);
if by_row
    ds_top = ds_slice(ds, 'cidx', iy);
else
    ds_top = ds_slice(ds, 'ridx', iy);
end

end