function [reps, gp] = fdr_analyze_group(ds, varargin)

% [reps, gp] = fdr_analyze_group(ds, varargin)
% fdr_analyze_group takes a square similarity matrix - e.g. the output from introspect
% and group annotations and evaluates the reproducibility of the groups relative to the
% background.  This function is also called by functions like fdrgold.m
%
%   Parameters:
%     groupchd     - string, the name of the column in chd and cdesc on which to group
%     grouping     - cell, alternate to groupchd; a cell array with a grouping variable
%                    (string or numeric) of the same size as ds.cid.  For instance, this
%                    cell array could contain the pert_id of all the columns in ds
%     aggfunc      - string; the function to use when aggregating group similarities.  
%                    Supported: median (default), q75
%     pval_method  - string; the method by which to calculate significance of groups
%                    Supported: permute.  Analytical null planned (though harder to do).
%     mkfigs       - boolean, make summary figures.  True by default.
%     mkrpt        - generate text file of group summary (saves gp).  True by default.
%     dataname     - string specifying the identifier of the dataset for output files.
%                    'mydata' by default; example: 'a375_xpr002_cosine'
%     outdir       - string, path to directory in which output files are saved.  default: pwd

params = {'groupchd', ...
    'grouping', ...
    'aggfunc', ...
    'pval_method', ...
    'mkfigs', ...
    'mkrpt', ...
    'dataname', ...
    'outdir'};
dflts = {'', ...
    {}, ...
    'median', ...
    'permute', ...
    1, ...
    1, ...
    'mydata', ...
    '.'};
args = parse_args(params, dflts, varargin{:});

if ~isequal(ds.rid, ds.cid)
  error('RID and CID identifiers in dataset are not identical');
end

rankmat = rankorder(ds.mat, 'as_fraction', 1, 'direc', 'descend');
% test if matrix is symmetric, with high probability
symk = ds.mat(1:min(size(ds.mat,1), 500), 1:min(size(ds.mat,1), 500));
args.issym = ifelse(isequal(symk, symk'), 1, 0);

% Outputs of analyze_groups:
% reps - a struct with correlations of group pairs, ranks of group pairs, and q-values of individual pairs
% gp - a struct with summarizes by group - aggregate correlation, rank of agg w.r.t. permutation, and q-value
[reps, gp] = analyze_groups(ds, rankmat, args);

if args.mkfigs
  mkfigs(args, ds, rankmat, reps, gp);
end

if args.mkrpt
  mktbl(fullfile(args.outdir, sprintf('%s_grpstats_n=%d.txt', args.dataname, numel(gp.grp_id))), gp);
end

end


function [reps, grp] = analyze_groups(ds, rankmat, args)
  if ~isempty(args.groupchd)
  % grouping is one of the column headers
    [g.u, g.c, g.gx] = cellcount(ds.cdesc(:, cellstrfind(ds.chd, args.groupchd)));
  elseif ~isempty(args.grouping)
  % grouping is supplied as an array or cell array
    [g.u, g.c, g.gx] = cellcount(args.grouping);
  else
    error('No grouping supplied.  Specify grouping in args.grouping or as a column in ds.cdesc');
  end

  if args.issym
    gcorrs = cellfun(@(x) tri2vec(ds.mat(x,x)), g.gx, 'UniformOutput', 0);
    granks = cellfun(@(x) tri2vec(rankmat(x,x)), g.gx, 'UniformOutput', 0);
  else
    gcorrs = cellfun(@(x) vertcat(tri2vec(ds.mat(x,x)), tri2vec(ds.mat(x,x)')), g.gx, 'UniformOutput', 0);
    granks = cellfun(@(x) vertcat(tri2vec(rankmat(x,x)), tri2vec(rankmat(x,x)')), g.gx, 'UniformOutput', 0);
  end

  % Pairwise q-vqlues: what is the false discovery rate of any particular pair of group members?
  % Output is gqval, which is the same shape as granks.  Probably not so useful unaggregated.
  tq = fdr_calc(vertcat(granks{:}));
  gqval = mat2cell(tq, cellfun(@numel, granks), 1);

  % Compute aggregate statistics for each group
  grpagg = aggregate_perts(gcorrs, args);

  % Assign p-values at the group level; rank test statistics by the size of the group membership
  uc = unique(g.c);
  % k = 1 - no replicates
  ix = find(g.c == 1);
  grp_perm_rank(ix,1) = 1;
  grp_perm_effsize(ix,1) = 0;

  for k = find(uc > 1,1):numel(uc)
    nullix = arrayfun(@(x) randperm(size(ds.mat, 1), uc(k)), 1:1000, 'UniformOutput', 0);
    if args.issym
      nullcorrs = cellfun(@(x) tri2vec(ds.mat(x,x)), nullix, 'UniformOutput', 0);
    else
      nullcorrs = cellfun(@(x) vertcat(tri2vec(ds.mat(x,x)), tri2vec(ds.mat(x,x)')), nullix, 'UniformOutput', 0);
    end
    nullagg = aggregate_perts(nullcorrs, args);

    ix = find(g.c == uc(k));
    if isrow(grpagg)
      grpagg = grpagg';
    end
    if iscolumn(nullagg)
      nullagg = nullagg';
    end
    % Intuitively, I prefer arrayfun, but repmat seems to take about half the time
    grp_perm_rank(ix,1) = mean(repmat(grpagg(ix),1,numel(nullagg)) < repmat(nullagg, numel(ix), 1),2);
    grp_perm_effsize(ix,1) = (grpagg(ix) - mean(nullagg))/std(nullagg);
  end

  grpq = fdr_calc(grp_perm_rank);

  reps.grp_id = g.u;
  reps.corr = gcorrs;
  reps.rank = granks;
  reps.qval = gqval;

  grp.grp_id = g.u;
  grp.n_elements = g.c;
  grp.aggsim = grpagg;
  grp.rank = grp_perm_rank;
  grp.effsize = grp_perm_effsize;
  grp.qval = grpq;
end


function mkfigs(args, ds, rankmat, reps, gp)
  figure; hold on; grid on;
  set(gca, 'FontSize', 8);
  [hc,bins] = cumhist(vertcat(reps.rank{:}), 0:0.001:1);
  plot(bins,hc,'k','LineWidth',3);
  ylim([0 1]);
  xlabel('Columnwise rank of group pairs');
  ylabel('Cumulative Fraction');
  title({sprintf('CDF of ranks for pairwise similarities in %s', args.dataname); ...
      sprintf('N pairs = %d, N groups = %d, ds size = %d, q < 0.25: %0.3f', numel(vertcat(reps.rank{:})), ...
      numel(reps.rank), size(ds.mat, 1), mean(vertcat(reps.qval{:}) < 0.25))});
  print(gcf, '-dpng', '-r250', fullfile(args.outdir, sprintf('%s_rank_replicatepairs_n=%d_cdf.png', ...
      args.dataname, size(ds.mat, 1))));

  % Remove diagonal
  allcorrs = ds.mat; 
  allcorrs(1:size(allcorrs,1)+1:end) = [];
  if numel(allcorrs) > 100000
    allcorrs = allcorrs(randperm(numel(allcorrs), 100000));
  end

  clf; hold on; grid on;
  set(gca, 'FontSize', 8);
  [b,a] = ksdensity(vertcat(reps.corr{:}), 'bandwidth', 0.01);
  plot(a,b,'r','LineWidth',3);
  [b,a] = ksdensity(allcorrs, 'bandwidth', 0.01);
  plot(a,b,'k--','LineWidth',3);
  xlabel('Similarity');
  ylabel('Density');
  title({sprintf('PDF of similarities for all pairs of group members in %s', args.dataname); ...
      sprintf('N pairs = %d, N groups = %d, ds size = %d, q < 0.25: %0.3f', numel(vertcat(reps.rank{:})), ...
      numel(reps.rank), size(ds.mat, 1), mean(vertcat(reps.qval{:}) < 0.25))});
  print(gcf, '-dpng', '-r250', fullfile(args.outdir, sprintf('%s_sim_replicatepairs_n=%d_pdf.png', ... 
      args.dataname, size(ds.mat, 1))));

  clf; hold on; grid on;
  set(gca, 'FontSize', 8);
  [hc,bins] = cumhist(gp.qval, 0:0.001:1);
  plot(bins,hc,'Color', [0 0.75 0],'LineWidth',2.5);
  ylim([0 1]);
  xlabel(sprintf('Q-value relative to %s', ifelse(strcmpi(args.pval_method, 'permute'), 'permutation null', 'analytical null')));
  ylabel('Cumulative Fraction');
  title({sprintf('CDF of aggregate q-values of similarity of groups in %s', args.dataname); ...
    sprintf('N pairs = %d, N groups = %d, ds size = %d, aggregate func = %s', numel(vertcat(reps.rank{:})), ...
    numel(reps.rank), size(ds.mat, 1), args.aggfunc)});
  print(gcf, '-dpng', '-r250', fullfile(args.outdir, sprintf('%s_qvals_aggregate_bygroup_n=%d_cdf.png', ...
      args.dataname, size(ds.mat, 1))));
end

function grpagg = aggregate_perts(grpcorrs, args)
  switch args.aggfunc
    case 'median'
      grpagg = cellfun(@(x) median(x), grpcorrs);
    case 'q75'
      grpagg = cellfun(@(x) quantile(x, 0.75), grpcorrs);
    otherwise
      error('Unknown aggregation function');
  end
end
