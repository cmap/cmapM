function mk_annotated_gctx(dsfile, outfile, varargin)
% MK_ANNOTATED_GCTX(dsfile, outfile)
% uses the already existing parse_gctx, mkgctx and annotate_ds functions
% to read a slice out of dsfile, annotate the rows and columns, and then
% write a gctx file to outfile. Takes the same options as parse_gctx.
%
% MKGCT_H5 Save a GCT dataset in HDF5 format.
% MKGCT_H5(DSFILE, DS)
% Note: assumes data matrix is at single precision


pnames = {'rid', 'cid'};
dflts = {{}, {}};
args = parse_args(pnames, dflts, varargin{:});

% read in the gctx
ds = parse_gctx(dsfile, 'rid', args.rid, 'cid', args.cid);

% read in landmark probe symbols

% annotate the ds
% first get sig info for columns
cinfo = sig_info(args.cid);
tblfile = strcat(outfile, '.info');
mktbl(tblfile, cinfo)
ds = annotate_ds(ds, tblfile, 'dim', 'column', 'keyfield', 'sig_id');
ds = annotate_ds(ds, '/cmap/data/vdb/chip/affx_plus2_lm_epsilon_annot.chip', 'dim', 'row', 'keyfield', 'pr_id');
mkgctx(outfile, ds);