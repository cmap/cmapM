%% Working with annotated matrices using the GCT and GCTX data formats in MATLAB
% Script used to generate this tutorial:
% <gctx_tutorial_v2.m> 
%% Reading a GCT or GCTX file
% GCT and GCTx files can be read in the same way.
% We'll use the same two files throughout this tutorial.

gct_file_location = fullfile(cmapmpath, 'resources', 'example.gct');
gctx_file_location = fullfile(cmapmpath, 'resources', 'example.gctx');
ds1 = cmapm.containers.DataMatrix(gct_file_location);
ds2 = cmapm.containers.DataMatrix(gctx_file_location);

%% DataMatrix objects
% GCT and GCTx files are both represented in memory as DataMatrix objects.
disp(class(ds1));
disp(class(ds2));

%% Layout of a DataMatrix object
% The DataMatrix object comprises of the following properties:
%
% * dim or size : A two-element integer array indicating the dimension
%          of the datamatrix
% * nrow : An integer indicating the number of rows in the
%          datamatrix
% * ncolumn : A integer indicating the number of columns in the
%             datamatrix
% * matrix : Numeric data matrix [RxC]
% * row_id : Cell array of row ids
% * column_id : Cell array of column ids

% Methods
% * row_names: Cell array of row annotation fieldnames
% * column_names : Cell array of column annotation fieldnames
% * d
disp(properties(ds1));
disp(ds1.size);

%% For large files, it can be useful to read just the metadata
ds_with_only_meta = cmapm.containers.DataMatrix(gctx_file_location, 'annot_only', true);

assert(isempty(ds_with_only_meta.matrix));
% Note that the matrix property is empty, but the metadata is the same as above
assert(isequal(ds_with_only_meta.row_names, ds2.row_names), 'Row name mismatch');
assert(isequal(ds_with_only_meta.column_names, ds2.column_names), 'Column name mismatch');
%% Extracting a subset of data from a GCTX file
% The GCTX format supports reading subsets of data from large files.

% Get row ids and column ids from ds_with_only_meta
my_rids = ds_with_only_meta.row_id(3:5);
my_cids = ds_with_only_meta.column_id(5);

% Use my_rids and my_cids to read a subset of the data
ds_subset = cmapm.containers.DataMatrix(gctx_file_location, 'rid', my_rids, 'cid', my_cids);

assert(isequal(ds_subset.row_id, my_rids), 'Row id mismatch');
assert(isequal(ds_subset.column_id, my_cids), 'Column id mismatch');

%% Working with metadata
% We provide several convenience functions to operate on the metadata in a
% dataset. 
%
% Note that while you can modify the attributes of a dataset object
% directly, it is not recommended since it could affect the integrity of
% the data structure.

%% List all available row metadata fields
row_fields = ds_subset.row_names;
col_fields = ds_subset.column_names;

disp(row_fields);
disp(col_fields);
%% Read all row metadata into a structure
row_meta = ds_subset.get_row_meta;
% display the first entry
disp(row_meta(1));

%% Annotate a dataset from a structure
new_meta = struct('rid', ds_subset.row_id, 'new_field1', {'A';'B';'C'}, 'new_field2', {1;2;3});
ds_subset.set_row_meta(new_meta);
% verify if the new fields have been added
assert(all(ismember({'new_field1', 'new_field2'}, ds_subset.row_names)));

%% Read contents of a metadata field
gene_symbol = ds_subset.get_row_field('pr_gene_symbol');
disp(gene_symbol);
%% Add metadata fields from cell arrays
ds_subset.set_row_meta('new_field3', {'X';'Y';'Z'});
% verify if the new field has been added
assert(all(ismember({'new_field3'}, ds_subset.row_names)));

%% Remove metadata fields
ds_subset.delete_row_meta({'new_field1', 'new_field2', 'new_field3'});
% verify if the new fields have been removed
assert(all(~ismember({'new_field1', 'new_field2', 'new_field3'}, ds_subset.row_names)));
%% Merging GCT/x files
% You can merge 2 datasets together if they have compatible ids.
% i.e they have the same row ids but different column ids or vice versa
merged = ds1.merge(ds2);

% Confirm that the # of columns in merged is equal to the # of columns in ds1 plus the # of columns in ds2.
assert(isequal(size(merged, 2), size(ds1, 2) + size(ds2, 2)))

%% Slicing GCT/x files
% Let's say you want to slice a GCT/x file to keep only "dp52" probes and
% only "DMSO" samples.
ds = cmapm.containers.DataMatrix(gctx_file_location);

% Get rids corresponding to dp52 probes.
beadset_ids = ds.get_row_field('pr_bset_id');
dp52_bool_array = strcmp('dp52', beadset_ids);
dp52_rids = ds.row_id(dp52_bool_array);

% Get cids corresponding to DMSO samples.
pert_inames = ds.get_column_field('pert_iname');
dmso_bool_array = strcmp('DMSO', pert_inames);
dmso_cids = ds.column_id(dmso_bool_array);

% Confirm that the dimensions of sliced is correct: 489 probes x 100 samples.
sliced = ds.slice('rid', dp52_rids, 'cid', dmso_cids);
assert(isequal(sliced.size, [length(dp52_rids), length(dmso_cids)]), 'Dimension mismatch');
disp(sliced.size);

%% Transpose a GCT/x
transposed = cmapm.Pipeline.ds_transpose(ds);
assert(isequal(size(ds.mat, 1), size(transposed.mat, 2)));
assert(isequal(size(ds.mat, 2), size(transposed.mat, 1)));
%% Writing GCT/x files
out_gct = ds.save('example_out.gct');
out_gctx = ds.save('example_out.gctx');

% Note that the same dataset object can be written out as either a GCT or GCTx.
% Note also that for convenience the dimensions of the matrix is automatically appended to
% the filename, and the columns go first. 

%% Compute correlations
% Compute pairwise spearman correlations between columns of dataset
cc = cmapm.Pipeline.ds_corr(ds);

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
