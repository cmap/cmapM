function [out, reps, gp] = fdrgold(ds, varargin)

% [out, reps, gp] = fdrgold(ds, varargin) - takes a data of signatures with a known grouping structure - e.g. 
% replicates or signatures of similar function - and evaluates the statistical coherence of those groups 
% using a specified similarity function and comparing to a permutation null of other elements from the dataset
%
%     [out, reps, gp] = fdrgold(ds) - operates on a dataset loaded in memory or a specified gctx file path
%
%     [out, reps, gp] = fdrgold('CPC018_A375_6H', 'isplate', 1) - reads from zspc.gctx all the replicate level
%         instances and computes replicate similarity
%
% Parameters:
%   

pnames = {'flatpc1', ...
  'metric', ...
  'pertgroup', ...
  'grouping', ...
  'aggregate', ...
  'isplate', ...
  'mkfigs', ...
  'dataname', ...
  'outdir'};
dflts = {1, ...
  'spearman', ...
  {'pert_id'}, ...
  {}, ...
  'median', ...
  0, ...
  1, ...
  '', ...
  '.'};
args = parse_args(pnames, dflts, varargin{:});
args.lms = parse_grp('/cmap/data/vdb/spaces/lm_epsilon_n978.grp');

if ~exist(args.outdir)
  mkdir(args.outdir);
end

[ds, args] = get_data(ds, args);

[out, reps, gp] = analyze_reproducibility(ds, args);

end


function [ds, args] = get_data(ds, args)

if isstr(ds)
  if isempty(args.dataname)
    args.dataname = ds;
  end

  if args.isplate
   s = sig_info(sprintf('{"brew_prefix":"%s"}', ds), 'fields', {'sig_id', 'brew_prefix', 'distil_id'});
   sc = struct2cell(s)';
   % There are some ridiculous meta-signatures in the database; the query needs to be refined so that
   % only those signatures with that brew prefix identically are included
   sc = sc(cellstrfind(sc(:,2), ds),:);
   x = mongolist2cell(sc(:,3));
   ds = parse_gctx('/cmap/data/build/a2y13q1/zspc.gctx', 'rid', args.lms, 'cid', vertcat(x{:}));

   r = inst_info(ds.cid);  %unique(vertcat(x{:})));
   rc = struct2cell(r)';
   ds.cdesc = rc;
   ds.chd = fieldnames(r);
   ds.cdict = containers.Map(ds.chd, 1:numel(ds.chd));
  else
   ds = parse_gctx(ds, 'rid', args.lms);
  end
else
  if isempty(args.dataname)
    args.dataname = ds.src;
  end
end

if args.flatpc1
  ds = project_pc1(ds);
end
end


function [out, reps, gp] = analyze_reproducibility(ds, args)

dataid = sprintf('%s_%s_%s', args.dataname, ifelse(args.flatpc1, 'flatpc1', 'std'), args.metric);
simds = apply_metric(ds, 'metric', args.metric);
mycorrs = simds.mat;
%mycorrs = fastcorr(ds.mat, 'type', 'Spearman');

if ~isempty(args.grouping)
  if numel(args.grouping) ~= numel(ds.cid)
    error('Grouping does not have the same number of elements as dataset has columns');
  end
  gpid = args.grouping;
elseif numel(args.pertgroup) == 1
    gpid = ds.cdesc(:, ds.cdict(args.pertgroup{1}));
  else
    cix = find(ismember(ds.chd, args.pertgroup));
    gpid = arrayfun(@(x) cell2str(ds.cdesc(x,cix), 1:numel(ds.cid)), 'UniformOutput', 0);
end

[u,c,g] = cellcount(gpid);
[reps, gp] = fdr_analyze_group(simds, 'grouping', gpid, 'mkfigs', args.mkfigs, 'dataname', dataid, ...
    'aggfunc', args.aggregate, 'outdir', args.outdir);

out.pertlabel = gp.grp_id;
if isequal(u, gp.grp_id)
  out.count = c;
end
out.dataname = repmat({dataid}, size(gp.grp_id));
out.fdrgold_ds = repmat({dataid}, size(gp.grp_id));
out.(sprintf('%s_%s', args.metric, args.aggregate)) = gp.aggsim;
out.pval_vs_perm = gp.rank;
out.zs_vs_perm = gp.effsize;
out.qval = gp.qval;
out.fdrgold10 = gp.qval < 0.1;
out.fdrgold25 = gp.qval < 0.25;
mktbl(fullfile(args.outdir, sprintf('fdrgoldrpt_%s_%s_%s_%s.txt', args.dataname, ...
    args.metric, horzcat(args.pertgroup{:}), ifelse(args.flatpc1, 'fpc1', 'stddata'))), out);
end


function pertagg = aggregate_perts(pertcorrs, ds, args)
  switch args.aggregate
    case 'median'
      pertagg = cellfun(@(x) median(x), pertcorrs);
    case 'q75'
      pertagg = cellfun(@(x) quantile(x, 0.75), pertcorrs);
    otherwise
      error('Unknown aggregation function');
  end
end
