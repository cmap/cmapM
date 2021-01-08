function res = pivot_table(tbl, row_fn, col_fn, val_fn)

tbl = parse_record(tbl);
%nrec = length(tbl);
[row_id, row_idx] = getcls({tbl.(row_fn)}');
[col_id, col_idx] = getcls({tbl.(col_fn)}');

nr = length(row_id);
nc = length(col_id);

if ischar(val_fn)
    val_fn = {val_fn};
end
nv = length(val_fn);
%row_lut = mortar.containers.Dict(row_id);
col_lut = mortar.containers.Dict(col_id);

for iv = 1:nv
    vals = {tbl.(val_fn{iv})}';
    t = cell(nr, nc);
    for ii=1:nr
        this_row = row_idx == ii;
        this_col = col_id(col_idx(this_row));
        %ir = row_lut(row_id(row_idx(this_row)));
        ic = col_lut(this_col);
        t(ii, ic) = vals(this_row);
    end
    res_fn = [{row_fn};strcat(val_fn{iv}, '_', col_id)];
    this_res = cell2struct([row_id, t], res_fn, 2);
    if iv>1
        res = join_table(res, this_res, row_fn, row_fn);
    else
        res = this_res;
    end
end
end