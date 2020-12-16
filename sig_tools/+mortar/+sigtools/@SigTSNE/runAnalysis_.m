function runAnalysis_(obj, varargin)
args = obj.getArgs;
obj.res_ = main(args);
end

function res = main(args)
argscell = args2cell(args);
res = mortar.compute.TSNE.runAnalysis(argscell{:});
end
