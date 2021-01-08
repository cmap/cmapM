function res = apply_metric(ds1, varargin)

% APPLY_METRIC - computes a distance function on all pairs of columns of one or two input 
% gctx structs.  
%   res = apply_metric(ds, varargin) - returns an NxN matrix containing the metric
%       applied to all pairs of columns of gct struct ds
%   res = apply_metric(ds1, ds2, varargin) - returns a PxQ matrix containing the metric
%       applied to all pairs of P columns from ds1 and Q columns from ds2
% 
%   Parameters:
%   'metric'     Distance (or connectivity) function - currently supports spearman,
%                pearson, wtcslm, seuclidean, cosine
%   'dataname'   Label, identifier for the dataset
%   'outdir'     output directory
%   'gset_size'  Integer, number of genes to use for comparison

% This is hack
if or(nargin < 2, ischar(varargin{1}))
  ds2 = ds1;
else
  ds2 = varargin{1};
  varargin = varargin(2:end);
end

params = {'metric', ...
    'dataname', ...
    'outdir', ...
    'gset_size', ...
    'write'};
dflts = {'', ...
    '', ...
    '/cmap/projects/metric_analysis/results', ...
    50, ...
    0};
args = parse_args(params, dflts, varargin{:});

validate_data(ds1, ds2, args);

switch lower(args.metric)
  case 'spearman'
    t = apply_spearman(ds1, ds2, args);
  case 'pearson'
    t = apply_pearson(ds1, ds2, args);
  case 'wtcslm'
    t = apply_wtcslm(ds1, ds2, args);
    args.metric = sprintf('%s50', args.metric);
  case 'seuclidean'
    t = apply_seuclidean(ds1, ds2, args);
  case 'cosine'
    t = apply_cosine(ds1, ds2, args);
  otherwise
    error('Invalid metric parameter: specify which metric to use');
end

res.mat = t;
res.cid = ds1.cid;
res.rid = ds2.cid;
res.cdesc = ds1.cdesc;
res.chd = ds1.chd;

if args.write
  mkgctx(fullfile(args.outdir, args.dataname, sprintf('%s_%s.gctx', args.dataname, args.metric)), res);
end

end


function t = apply_spearman(ds1, ds2, args)
  t = fastcorr(ds1.mat, ds2.mat, 'type', 'Spearman');
end

function t = apply_pearson(ds1, ds2, args)
  t = fastcorr(ds1.mat, ds2.mat, 'type', 'Pearson');
end

function t = apply_wtcslm(ds1, ds2, args)
  sds = compute_cmap_score(ds1, ds2, 'metric', 'wtcs', 'es_tail', 'both', 'gset_size', args.gset_size);
  t = sds(:,:,3);
end

function t = apply_seuclidean(ds1, ds2, args)
  t = pdist2(ds1.mat', ds2.mat', 'seuclidean');
end

function t = apply_cosine(ds1, ds2, args)
  %amag = diag(diag(sqrt(a'*a)));
  %bmag = diag(diag(sqrt(b'*b)));
  t = 1 - pdist2(ds1.mat', ds2.mat', 'cosine');
end

function validate_data(ds1, ds2, args)
  if ~isequal(ds1.rid, ds2.rid)
    if ~setequal(ds1.rid, ds2.rid)
      error('Datasets do not have the same row spaces');
    else
      idx = match_vectors(ds1.rid, ds2.rid)
      ds2 = gctsubset(ds2, 'rsubset', idx);
    end
  end
end
