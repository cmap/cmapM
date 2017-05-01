% This script contains examples for reading .gct, .gctx, and .lxb files
% in MATLAB, and performing z-scoring for a data data set.
% For this script to run properly, run the script from its directory.

% read a .gct file
ds = parse_gct(fullfile(cmappath, 'resources/log_ybio_epsilon.gct'));

% read a .gctx file and inspect its contents
ds = parse_gctx(fullfile(cmappath, '../data/modzs_n272x978.gctx'));
disp(ds.mat(1:10,1:10))
disp(ds.rid(1:10))
disp(ds.cid(1:10))
disp(ds.rdesc(1:10,:))
disp(ds.cdesc(1:10,:))

% z-score a .gctx matrix
zs = robust_zscore(ds.mat);

% read an .lxb file
lxb = l1kt_parse_lxb(fullfile(cmappath, '../data/A10.lxb'));