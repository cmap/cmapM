function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;
assert(~isempty(args.ds), 'Dataset not specified');

if ~isempty(args.rid)   
    dbg(1, 'Using custom row_space provided')
    obj.setArg('row_space', 'custom');
end


end