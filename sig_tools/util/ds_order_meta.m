function ds = ds_order_meta(ds, dim, field_order)
% DS_ORDER_META Reorder the metadata fields in a dataset 
% DS = DS_ORDER_META(DS, DIM, FIELD_ORDER) reorders the metadata fields of
% dataset DS according to the list FIELD_ORDER. The row or column metadata
% is specified by DIM
%
% Example:
%   % reorder the row meta-data fields of DS
%   DS_ORD = DS_ORDER(DS, 'row', {'pert_iname', 'cell_iname'})
%
% See also: ORDERAS

dim_str = get_dim2d(dim);
switch (dim_str)
    case 'row'
        [neworder, idx] = orderas(ds.rhd, field_order);
        ds.rdesc = ds.rdesc(:, idx);
        ds.rhd = neworder;
        ds.rdict = list2dict(neworder);
    case 'column'
        [neworder, idx] = orderas(ds.chd, field_order);
        ds.cdesc = ds.cdesc(:, idx);
        ds.chd = neworder;
        ds.cdict = list2dict(neworder);
end

end