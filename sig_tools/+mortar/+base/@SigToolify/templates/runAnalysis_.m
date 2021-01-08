function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)
% Main function
% ADD CORE CODE BELOW
res = struct('args', args, 'output', '');
% res.output = parse_gctx(args.ds);

end
