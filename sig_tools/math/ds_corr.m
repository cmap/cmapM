function cc = ds_corr(ds, varargin)
% DS_CORR Compute pairwise correlations for a dataset.
%   CC = DS_CORR(DS) Compute spearman correlation. A Wrapper function
%   to fastcorr that returns a dataset instead of a matrix.
%   CC = DS_CORR(DS, 'type', 'pearson') Computes pearson instead.


% compute correlations within one dataset
if (nargin < 2) || (~isfileexist(varargin{1}) && ~isstruct(varargin{1}))
    corrXX = true;
    if isfileexist(ds)
        ds = parse_gctx(ds);
    end
    
% Both x and y given, compute the pairwise rank cross correlations
else
    ds2 = varargin{1};
    if isfileexist(ds2)
        ds2 = parse_gctx(ds2);
        % subset and order rows identically
        ds2 = ds_slice(ds2, 'rid', ds.rid);
    end    
    varargin = varargin(2:end);
    corrXX = false;
end

pnames = {'type', 'dim'};
dflts = {'spearman', 'column'};
args = parse_args(pnames, dflts, varargin{:});
dim_str = get_dim2d(args.dim);
if isequal(dim_str, 'row')
    dbg(1, 'Computing correlations for rows');
    ds = transpose_gct(ds);
    if ~corrXX
        ds2 = transpose_gct(ds2);
    end
end

%% Compute correlations
if corrXX
    cc = fastcorr(ds.mat, 'type', args.type);    
    cc = mkgctstruct(cc, 'cid', ds.cid, 'cdesc',ds.cdesc, 'chd', ds.chd,...
        'rid', ds.cid, 'rdesc', ds.cdesc, 'rhd', ds.chd);
else
    cc = fastcorr(ds.mat, ds2.mat, 'type', args.type);    
    cc = mkgctstruct(cc, 'cid', ds2.cid, 'cdesc',ds2.cdesc, 'chd', ds2.chd,...
        'rid', ds.cid, 'rdesc', ds.cdesc, 'rhd', ds.chd);    
end

end