function [ds, pc1, pc1_scores] = project_pc1(ds, varargin)

% [ds, pc1, pc1_scores] = project_pc1(ds, varargin)
%   Remove the canonical first principal component from an input data set.  Reference
%   dataset is in /cmap/data/vdb/princomp/affogato_pcs_global_n978x978.gctx.  Input ds
%   is a gct struct of landmark z-scores.  Passing a path to the gctx file is also supported
%   but not recommended.
%   Arguments: 
%     use_ref - boolean, 1 by default.  Use a reference signature calculated on a global dataset (recommended)
%     zeromean - boolean, 0 by default.  Returns a dataset with mean 0 across all probesets 
%     globmean - boolean, 0 by default.  Returns a dataset with the mean across affogato subtracted.
%         Overrides zeromean, which is the local variant.  
%   Returns:
%     ds - the modified dataset with the first principal component removed
%     pc1 - the first principal component direction for anyone curious
%     pc1_scores - the magnitudes of the original signatures along the first principal component direction

pnames = {'use_ref', ...
   'zeromean', ...
   'globmean'};
dflts = {1, ...
    0, ...
    0};
args = parse_args(pnames, dflts, varargin{:});

if isstr(ds)
  lms = parse_grp('/cmap/data/vdb/spaces/lm_epsilon_n978.grp');
  ds = parse_gctx(ds, 'rid', lms);
end


if args.use_ref
  refds = parse_gctx('/cmap/data/vdb/princomp/affogato_pcs_global_n978x978.gctx', ...
      'rid', ds.rid, 'cid', {'affogato_pc001'});
  
  mumat = mean(ds.mat,2);
  mymat = ds.mat - repmat(mumat, 1, size(ds.mat,2));

  pc1_scores = ((refds.mat' * mymat)./sqrt(sum(mymat.^2)))';
  pc1 = refds;  

  mymat = mymat - refds.mat * (refds.mat' * mymat);
  
  if args.globmean
    refmean = parse_gctx('/cmap/data/vdb/princomp/affogato_means_global_n3x978.gctx', ...
      'rid', ds.rid, 'cid', {'Affogato Mean'});
    ds.mat = mymat + repmat(mumat - refmean.mat, 1, size(ds.mat, 2));
  elseif args.zeromean
    ds.mat = mymat;
  else
    ds.mat = mymat + repmat(mumat, 1, size(ds.mat, 2));
  end
  
else 
  [coeff, score, l, tsq, expl] = pca(ds.mat');
  pc1_scores = score(:,1);
  pc1 = mkgctstruct(coeff(:,1), 'rid', ds.rid, 'cid', {'PC1'});

  score(:,1) = 0;
  mumat = mean(ds.mat, 2);

  if args.globmean
    mymat = (score*coeff' + repmat(mumat' - refmean.mat', size(ds.mat, 2), 1))'; 
  elseif args.zeromean
    mymat = (score*coeff')';
  else
    mymat = (score*coeff' + repmat(mumat', size(ds.mat, 2), 1))';
  end

  ds.mat = mymat;
end

end
