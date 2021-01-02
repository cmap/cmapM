function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;
assert(~isempty(args.ds), 'Dataset not specified');
if ~isempty(args.rid)
    args.row_space = 'custom';
end
obj.setArgs(args);

end