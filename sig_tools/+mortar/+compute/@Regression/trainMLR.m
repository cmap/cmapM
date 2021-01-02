function model = trainMLR(varargin)
%Create MLR model from training data

validreg = {'pinv', 'pinv_int'};
valid_xform = {'none', 'log2', 'abs', 'pow2', 'zscore' };
PRECISION = 4;

pnames = {'ds', 'regtype', 'grp_landmark', ...
      'rid', 'cid','ridx', 'cidx', 'xform', 'precision'};
dflts = { '', 'pinv_int', '', '', '', [], [], 'none', PRECISION};

arg = parse_args(pnames, dflts, varargin{:});

if ~isvalidstr(arg.regtype, validreg)
    error('Invalide regtype: %s\n', arg.regtype);
end


if isstruct(arg.ds)
    ds = arg.ds;
    arg.ds = ds.src;
elseif isfileexist(arg.ds)
    ds = parse_gctx(arg.ds, 'rid', arg.rid, 'cid', arg.cid);
    ds = ds_slice(ds, 'ridx', arg.ridx, 'cidx', arg.cidx);
else
    error('ds: %s not found', arg.ds);
end

[~, numSamples] = size(ds.mat);

ds.mat = do_xform(ds.mat, arg.xform, valid_xform, true);

if iscell(arg.grp_landmark) || isfileexist(arg.grp_landmark)
    lmspace = parse_grp(arg.grp_landmark);
    
    [cmn, lmidx] = intersect_ord(ds.rid, lmspace);
    nlm = length(lmspace);
    if ~isequal(length(cmn), length(lmspace))
        disp(setdiff(lmspace, cmn));
        error('Some landmarks not found in dataset');
    end
    
    [depspace, depidx] = setdiff(ds.rid, lmspace);
    ndep = length(depspace);
    if isempty(depspace)
        error('No dependent features in dataset to predict');
    end
else
    error('Landmarks not specified');
end

fprintf('Training regression model [%s]: %d landmarks, %d dependents, %d samples\n', ...
        arg.regtype, nlm, ndep, numSamples );
    switch (arg.regtype)
        case 'pinv'
            %design matrix [S x L]
            X = ds.mat(lmidx,:)';
            %[L x D] = [L x S] * [S * D]
            wt = pinv(X) * ds.mat(depidx,:)';
        case 'pinv_int'
            % design matrix [S x L+1]
             X = [ones(numSamples,1), ds.mat(lmidx,:)'];
             % [L+1 x D] = [ L+1 X S ] * [S x D]             
             wt = pinv(X) * ds.mat(depidx,:)';
        otherwise
            error('Unknown model type: %s', arg.regtype);
    end

    scfactor = [];
    
    cn = ds.rid(lmidx);
    cn = ['int'; cn];
    
    model = struct('mat', wt', 'rn', {ds.rid(depidx)}, ...
        'cn', {cn}, 'arg', arg, 'scfactor', scfactor);
    
    fprintf('Model training complete.\n');
end