function ds_rec = getDataset(dataset_source, dataset_id)
% getDataset Read pre-canned dataset
% ds_rec = getDataset(src_file, ds_id)

ds_table = parse_record(dataset_source);
ds_idx = strcmp({ds_table.dataset_id}, dataset_id);
assert(any(ds_idx), 'Unknown dataset %s specified', dataset_id);
assert(isequal(nnz(ds_idx), 1), 'Multiple matching datasets');
ds_rec = ds_table(ds_idx);
end