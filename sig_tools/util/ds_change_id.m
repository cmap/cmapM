function ds = ds_change_id(ds, dim, new_id, old_id_name)
% DS_CHANGE_ID Change id field of a dataset
% DS = DS_CHANGE_ID(DS, DIM, NEW_ID, OLD_ID_NAME)

[dim_str, dim_val] = get_dim2d(dim);
ds = parse_gctx(ds, 'checkid', false);
assert(ischar(old_id_name), 'Expected old_id_name to be a string');

if ischar(new_id)
    new_id = ds_get_meta(ds, dim_str, new_id, false, false);
elseif iscell(new_id)
    new_id = new_id(:);
    ds_len = size(ds.mat, 3-dim_val);
    assert(isequal(length(new_id), ds_len),...
        'Bad length of new_id, expected %d got %d',...
        ds_len, length(new_id));
end

if isnumeric(new_id)
   new_id = strrep(cellstr(num2str(new_id)),' ', '');
end

dup = duplicates(new_id);
if ~(isempty(dup))
    disp(dup)
    error('id field cannot have duplicate values');
end

old_id = ds_get_meta(ds, dim_str, '_id', false, false);
ds = ds_add_meta(ds, dim_str, old_id_name, old_id);
if isequal(dim_str, 'column')
    ds.cid = new_id;    
else
    ds.rid = new_id;
end

end