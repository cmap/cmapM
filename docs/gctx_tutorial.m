%% Working with annotated matrices using the GCT and GCTX data formats in MATLAB
% Script used to generate this tutorial:
% <gctx_tutorial.m> 
%% Reading a GCT or GCTX file
% GCT and GCTx files can be read in the same way.
% We'll use the same two files throughout this tutorial.

gct_file_location = fullfile(cmapmpath, 'resources', 'example.gct');
gctx_file_location = fullfile(cmapmpath, 'resources', 'example.gctx');
ds1 = parse_gctx(gct_file_location);
ds2 = parse_gctx(gctx_file_location);

%% GCT data representation
% GCT and GCTx files are both represented in memory as structures.
disp(class(ds1));
disp(class(ds2));

%% Layout of the GCT structure
% The GCT structure comprises of the following fields:
%
% * mat : Numeric data matrix [RxC]
% * rid : Cell array of row ids
% * rhd : Cell array of row annotation fieldnames
% * rdict : Dictionary of row annotation fieldnames to indices
% * rdesc : Cell array of row annotations
% * cid : Cell array of column ids
% * chd : Cell array of column annotation fieldnames
% * cdict : Dictionary of column annotation fieldnames to indices
% * cdesc : Cell array of column annotations

disp(ds2);

%% For large files, it can be useful to read just the metadata
ds_with_only_meta = parse_gctx(gctx_file_location, 'annot_only', true);
disp(ds_with_only_meta);
% Note that the mat field is empty, but the metadata is the same as above

%% Extracting a subset of data from a GCTX file
% The GCTX format supports reading subsets of data from large files.

% Get row ids and column ids from ds_with_only_meta
my_rids = ds_with_only_meta.rid(3:5);
my_cids = ds_with_only_meta.cid(5);

% Use my_rids and my_cids to read a subset of the data
ds_subset = parse_gctx(gctx_file_location, 'rid', my_rids, 'cid', my_cids);

%% Working with metadata
% We provide several convenience functions to operate on the metadata in a
% dataset. 
%
% Note that while you can modify the attributes of a dataset object
% directly, it is not recommended since it could affect the integrity of
% the data structure.

%% List all available row metadata fields
row_fields = ds_subset.rhd;
col_fields = ds_subset.chd;

disp(row_fields);
disp(col_fields);
%% Read all row metadata into a structure
row_meta = gctmeta(ds_subset, 'row');
% display the first entry
disp(row_meta(1));

%% Annotate a dataset from a structure
new_meta = struct('rid', ds_subset.rid, 'new_field1', {'A';'B';'C'}, 'new_field2', {1;2;3});
ds_subset = annotate_ds(ds_subset, new_meta, 'dim', 'row');
% verify if the new fields have been added
assert(all(ismember({'new_field1', 'new_field2'}, ds_subset.rhd)));

%% Read contents of a metadata field
gene_symbol = ds_get_meta(ds_subset, 'row', 'pr_gene_symbol');
disp(gene_symbol);
%% Add metadata fields from cell arrays
ds_subset = ds_add_meta(ds_subset, 'row', 'new_field3', {'X';'Y';'Z'});
% verify if the new field has been added
assert(all(ismember({'new_field3'}, ds_subset.rhd)));

%% Remove metadata fields
ds_subset = ds_delete_meta(ds_subset, 'row', {'new_field1', 'new_field2', 'new_field3'});
% verify if the new fields have been removed
assert(all(~ismember({'new_field1', 'new_field2', 'new_field3'}, ds_subset.rhd)));
%% Merging GCT/x files
% You can merge 2 datasets together if they have compatible ids.
% i.e they have the same row ids but different column ids or vice versa
merged = merge_two(ds1, ds2);

% Confirm that the # of columns in merged is equal to the # of columns in ds1 plus the # of columns in ds2.
assert(isequal(size(merged.mat, 2), size(ds1.mat, 2) + size(ds2.mat, 2)))

%% Slicing GCT/x files
% Let's say you want to slice a GCT/x file to keep only "dp52" probes and
% only "DMSO" samples.
ds = parse_gctx(gctx_file_location);

% Get rids corresponding to dp52 probes.
beadset_ids = ds_get_meta(ds, 'row', 'pr_bset_id');
dp52_bool_array = strcmp('dp52', beadset_ids);
dp52_rids = ds.rid(dp52_bool_array);

% Get cids corresponding to DMSO samples.
pert_inames = ds_get_meta(ds, 'column', 'pert_iname');
dmso_bool_array = strcmp('DMSO', pert_inames);
dmso_cids = ds.cid(dmso_bool_array);

% Confirm that the dimensions of sliced is correct: 489 probes x 100 samples.
sliced = ds_slice(ds, 'rid', dp52_rids, 'cid', dmso_cids);
assert(isequal(size(sliced.mat), [length(dp52_rids), length(dmso_cids)]), 'Dimension mismatch');
disp(size(sliced.mat));

%% Transpose a GCT/x
transposed = transpose_gct(ds);
assert(isequal(size(ds.mat, 1), size(transposed.mat, 2)));
assert(isequal(size(ds.mat, 2), size(transposed.mat, 1)));
%% Writing GCT/x files
out_gct = mkgct('example_out.gct', ds);
out_gctx = mkgctx('example_out.gctx', ds);

% Note that the same dataset object can be written out as either a GCT or GCTx.
% Note also that for convenience the dimensions of the matrix is automatically appended to
% the filename, and the columns go first. 

%% Compute correlations
% Compute pairwise spearman correlations between columns of dataset
cc = ds_corr(ds);

% cc is a square and symmetric GCT structure
assert(isequal(size(cc.mat), [size(ds.mat, 2), size(ds.mat, 2)]), 'CC is not square');
assert(isequal(cc.mat, cc.mat'), 'CC is not symmetric');

% Examine its contents 
imagesc(cc.mat(1:20, 1:20));
colorbar
caxis([0.5, 1]);
axis square
title('Pairwise Spearman Correlation');

%% Clean-up
delete(out_gct)
delete(out_gctx)
