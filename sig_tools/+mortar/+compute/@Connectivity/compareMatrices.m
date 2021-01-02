function out_gct = compareMatrices(ds1_in, ds2_in, varargin)
% COMPAREMATRICES Compare two ds to each other using connectivity score.
% 
% N.B. Since connectivity score is assymmetric, the 2 results are simply averaged
% together. For example, the similarity of column 1 in ds1 to column 3 in
% ds2 is averaged together with the similarity of column 3 in ds2 to column
% 1 in ds1.
%
% Terminology: The matrix containing queries is the query matrix. The
% matrix that is being queried is the target matrix. For example, if we
% convert ds1 into a list of gene lists and query them against ds2, then ds1 is
% the query matrix and ds2 is the target matrix.
% 
% Note: The default query is along columns. However, this function allows
% you to query along rows. To do this, the cids must have overlap between ds1
% and ds2. This may require the user (ahead of time) to rename cids (e.g. to the
% entries in det_well).
%
% Inputs:
%     ds1_in (gct struct): size = m1 x n1
%     ds2_in (gct struct): size = m2 x n2
%     dim (string): dimension to operate on; choices = {'column', 'row'}
%     set_size (int): number of features to use in query set
%     is_weighted (bool): if true, computes a weighted score
%     es_tail (bool): specify two-tailed or one-tailed statistic. choices = {both, up, down}
% 
% Output:
%     out_gct (gct struct): size of matrix = n1 x n2; e.g. element 1, 3 is the
%         similarity of column 1 in ds1 against column 3 in ds2
% 
% Example usage:
%     ds1 = parse_gctx('some_file.gct');
%     ds2 = parse_gctx('some_other_file.gctx');
%     out_gct = compareMatrices(ds1, ds2, 'set_size', 50, 'dim', 'row');

import mortar.compute.Connectivity

%% Parse optional args
pnames = {
    '--dim';
    '--set_size';
    '--is_weighted';
    '--es_tail'};
dflts = {'column'; 100; true; 'both'};
config = struct('name', pnames, 'default', dflts);
args = mortar.common.ArgParse.getArgs(config, struct(), varargin{:});


%% Transpose matrices if operating on rows
if strcmpi(args.dim, 'column')
    % Assert that the ds1 and ds2 have rids in common
%     assert(~isempty(intersect(ds1_in.rid, ds2_in.rid)), ...
%         'The intersection of rids from ds1 and ds2 must not be empty.')
    ds1 = ds1_in;
    ds2 = ds2_in;
    
elseif strcmpi(args.dim, 'row')
    % Assert that the ds1 and ds2 have cids in common
%     assert(~isempty(intersect(ds1_in.cid, ds2_in.cid)), ...
%         'The intersection of cids from ds1 and ds2 must not be empty.')
    ds1 = transpose_gct(ds1_in);
    ds2 = transpose_gct(ds2_in);
    
else
    error('dim must be ''row'' or ''column''.')
end


%% Query ds1 against ds2 and ds2 against ds1
% Convert query matrix to genesets
[ds1_up, ds1_dn, tf1] = get_genesets(ds1, args.set_size, 'descend');
[ds2_up, ds2_dn, tf2] = get_genesets(ds2, args.set_size, 'descend');

% Convert target matrix to rank matrix
ds2_rank = score2rank(ds2, 'ignore_nan', true);
ds1_rank = score2rank(ds1, 'ignore_nan', true);

% max_rank is the number of rows in the target matrix
max_rank_queryA = size(ds2.mat, 1);
max_rank_queryB = size(ds1.mat, 1);

% Query ds1 against ds2
queryA_result = Connectivity.computeCmapScore(ds1_up, ds1_dn, ds2_rank, ...
    args.is_weighted, ds2, args.es_tail, max_rank_queryA);
                             
% Query ds2 against ds1
queryB_result = Connectivity.computeCmapScore(ds2_up, ds2_dn, ds1_rank, ...
    args.is_weighted, ds1, args.es_tail, max_rank_queryB);
                             
                             
%% Combine the results of the queries into an output gct
% Transpose queryA_result
transposed_queryA_gct = transpose_gct(queryA_result.cs);

% handle cases where some sets were not generated (e.g. due to size
% requirements)
if ~all(tf1) || ~all(tf2)
    dbg(1, 'Synchronizing dataset ids');
    cmn_rid = intersect(transposed_queryA_gct.rid, queryB_result.cs.rid, 'stable');
    cmn_cid = intersect(transposed_queryA_gct.cid, queryB_result.cs.cid, 'stable');
    transposed_queryA_gct = ds_slice(transposed_queryA_gct, 'rid', cmn_rid, 'cid', cmn_cid);
    queryB_result.cs = ds_slice(queryB_result.cs, 'rid', cmn_rid, 'cid', cmn_cid);
end
% Assert that rids and cids are now the same (except for case; for some
% reason, cids are capitalized in query output)
assert(all(strcmpi(transposed_queryA_gct.rid, queryB_result.cs.rid)), ...
    'rids of query results should be the same.')
assert(all(strcmpi(transposed_queryA_gct.cid, queryB_result.cs.cid)), ...
    'cids of query results should be the same.')

% Combine query results by averaging
out_mat = (transposed_queryA_gct.mat + queryB_result.cs.mat) / 2;

% Produce output gct (return fields unaffected by capitalization issues)
out_gct = mkgctstruct(out_mat, 'rid', queryB_result.cs.rid, ...
    'cid', transposed_queryA_gct.cid, 'cdesc', transposed_queryA_gct.cdesc, ...
    'chd', transposed_queryA_gct.chd, 'rdesc', queryB_result.cs.rdesc, ...
    'rhd', queryB_result.cs.rhd);

