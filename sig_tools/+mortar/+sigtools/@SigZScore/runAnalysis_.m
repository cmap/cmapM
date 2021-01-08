function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)
% Main function
% ADD CORE CODE BELOW
res = struct('args', args, 'output', '');
ds = parse_gctx(args.ds);
%working for dim 
[~,dimval] = get_dim2d(args.dim);
bkgspace = [];
if ~isempty(args.bkg_space)
    subset = parse_grp(args.bkg_space);
    if dimval == 1
        bkgspace = find(ismember(ds.rid, subset));
        notfound = find(~ismember(subset, ds.rid));
    else
        bkgspace = find(ismember(ds.cid, subset));
        notfound = find(~ismember(subset, ds.cid));
    end

    if ~isempty(notfound)   
        fprintf('The following entries were not found: %s. \n ', strjoin(subset(notfound), ', '));
    end
    assert( ~isempty(bkgspace), 'Given median space contains no appropriate ids.');
end

ds.mat = mortar.compute.L1kPipeline.zscore(ds.mat, dimval, ...
        '--bkg_space', bkgspace, ...
        '--estimate_prct', args.estimate_prct, ...
        '--min_var', args.min_var, ...
        '--var_adjustment', args.var_adjustment, ...
        '--zscore_method', args.zscore_method);

res.output = ds;
end
