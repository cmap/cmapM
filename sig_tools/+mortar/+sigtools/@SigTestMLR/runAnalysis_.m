function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)

% Main function
res = struct('args', args, 'output', '');

res.output = mortar.compute.Regression.testMLR('ds', args.ds, ...
    'model', args.model, ...
    'minval', args.minval, ...
    'maxval', args.maxval, ...
    'xform', args.xform);
end
