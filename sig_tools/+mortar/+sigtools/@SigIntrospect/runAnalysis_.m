function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)
% Main function
res = struct('args', args,...
    'introspect_result', '');
arg_cell = args2cell(args);
res.introspect_result = ...
    mortar.compute.Connectivity.runIntrospect(arg_cell{:});

end
