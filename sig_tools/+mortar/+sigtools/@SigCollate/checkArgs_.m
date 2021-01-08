function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;
assert(~(isempty(args.files) & isempty(args.folders)),...
    'Either files or folders must be specified');
if isempty(args.rid) && ~isempty(args.row_space)
    assert(mortar.common.Spaces.probe_space.isKey(args.row_space),...
    'Invalid row space: %s, Expected one of %s', args.row_space,...
    print_dlm_line(mortar.common.Spaces.probe_space.keys, 'dlm', '|'));
end

end