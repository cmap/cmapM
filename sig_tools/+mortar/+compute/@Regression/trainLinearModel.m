function model = trainLinearModel(ds, predictors, model_type)


ds = parse_gctx(ds);
[numFeatures, numSamples] = size(ds.mat);        

% landmark genes
lmspace = parse_grp(predictors);
% landmark indices
[cmn, landmarkidx] = intersect(ds.rid, lmspace);
nlm = length(lmspace);
if ~isequal(length(cmn), length(lmspace))
    disp(setdiff(lmspace, cmn));
    error('Some landmarks not found in train set');
end

% indices of genes to be predicted
[depspace, dependentidx] = setdiff(ds.rid, lmspace);
ndep = length(depspace);
if isempty(dependentidx)
    error('No dependent features to predict!');
end

% if scaling predictors requested
scfactor=[];

%% regression
% train model
dbg(1, 'Training regression model [%s]: %d features (%d landmarks, %d dependents), %d samples\n', ...
    model_type, numFeatures, nlm, ndep, numSamples);
switch (model_type)
    % [DEFAULT] pseudoinverse with intercept
    case 'pinv_int'
        % design matrix [S x L+1]
        X = [ones(numSamples,1), ds.mat(landmarkidx,:)'];
        % [L+1 x D] = [ L+1 X S ] * [S x D]
        wt = pinv(X) * ds.mat(dependentidx,:)';
        % [S x D] = [S x L+1] * [L+1 x D]
        %              trp = X * wt;
    otherwise
        error('Unkown model type: %s', model_type)
end

%% TEMP WORKAROUND since infer_tool expects arg
arg = struct('res', ds.src,...
             'grp_landmark', sprintf('landmarks_n%d.grp', nlm),...
             'regtype', model_type);
         
model = struct('wt', wt', 'rn', {ds.rid(dependentidx)},...
    'cn', {ds.rid(landmarkidx)},...
    'arg',arg,'scfactor', scfactor);
     
end