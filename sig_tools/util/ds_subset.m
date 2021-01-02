function out_ds = ds_subset(ds,dim,field,to_include)
% out_ds = ds_subset(ds,dim,field,to_include)
% 
% Slice a dataset with respect to metadata
%
% Input
%       ds: a gct struct
%       dim: Either 'row' or 'column'
%       field: The metadata field to match on
%       to_include: The values of 'field' to keep in the new dataset
%
% Output
%       out_ds: a gct struct

    switch dim
        case 'column'
            assert(ismember(field,ds.chd),'field not included in metadata');
            good_idx = find(ismember(ds.cdesc(:,ds.cdict(field)),to_include));
            out_ds = ds_slice(ds, 'cidx', good_idx);
        case 'row'
            assert(ismember(field,ds.rhd),'field not included in metadata');
            good_idx = find(ismember(ds.rdesc(:,ds.rdict(field)),to_include));
            out_ds = ds_slice(ds, 'ridx', good_idx);
        otherwise
            error('Dimension must be either "row" or "column"');
    end
end
