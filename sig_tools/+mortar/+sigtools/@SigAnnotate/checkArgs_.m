function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;
assert(~isempty(args.ds), 'Dataset not specified');
end