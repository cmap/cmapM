function isfn = is_ds_field(ds, fn, dim)
% IS_DS_FIELD Check if metadata fields exist in a dataset.
%   TF = IS_DS_FIELD(DS, FN) Check if field(s) FN are present in the column
%   metadata of DS
%   TF = IS_DS_FIELD(DS, FN, DIM) Specify the dimension. Dim can be either 
%   {'column', 'row'} or [1, 2]

dim_str = get_dim2d(dim);

switch (dim_str)
    case 'row'
        isfn = ismember(fn, [{'rid'; '_id'}; ds.rhd]);        
    case 'column'
        isfn = ismember(fn, [{'cid'; '_id'}; ds.chd]);
        
end
end