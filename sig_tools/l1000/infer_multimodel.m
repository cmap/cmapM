function [comboinf, stats] = infer_multimodel(ds, model, lm)

% read gct
if isstruct(ds)    
    dsfile = ds.src;
elseif isfileexist(ds)
    dsfile = ds;
    ds = parse_gctx(dsfile);
else
  error([toolName,':FileNotFound'], 'res: %s not found', ds)
end

if isstruct(model)    
    
elseif isfileexist(model)
    load(model);
    % if struct not named model, rename
    if ~isvarexist('model')
        mstruct = who('-file', model);
        eval(sprintf('model=%s', mstruct{1}))    
        clear (mstruct{1})
    end
else
  error([toolName,':FileNotFound'], 'res: %s not found', model)
end
nmodel = length(model);

%landmarks
lm = parse_grp(lm);
% % dependent features
% dep = setdiff(model(1).rn, lm);
nf = length(union(lm,model(1).rn));
ns = size(ds.mat,2);
%%
submat = zeros(nf, ns, nmodel);
for ii=1:nmodel
    fprintf ('--- Applying Model %d / %d ---\n', ii, nmodel);
    subinf = infer_tool('res', ds,...
        'model', model(ii));
    if isequal(ii, 1)
        comboinf = subinf;
        submat(:,:,ii) = subinf.mat;
%         dep = setdiff(subsinf.rid, lm);
    else
        
        [~,ridx] = intersect_ord(subinf.rid, comboinf.rid);
        submat(:,:,ii) = subinf.mat(ridx, :);
        comboinf.mat = comboinf.mat + subinf.mat(ridx, :);
    end    
end
comboinf.mat = comboinf.mat / nmodel;

%% fix landmarks

[~, lmidx] = intersect_ord(comboinf.rid, lm);
[~, lmidx2] = intersect_ord(ds.rid, lm);
%%
comboinf.mat(lmidx, :) = ds.mat(lmidx2,:);
stats.mu = mean(submat, 3);
stats.sigma = std(submat,0,3);
stats.cvar = 100*stats.sigma ./ abs(stats.mu);

% % also fix row annotations for landmarks
% if ~isempty(ds.rdesc)
%     comboinf.rdesc(lmidx,:) = ds.rdesc(lmidx2,:);
% end

end