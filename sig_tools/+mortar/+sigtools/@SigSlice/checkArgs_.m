function checkArgs_(obj)
% sanity check the parameters
args = obj.getArgs;
assert(~isempty(args.ds), 'Dataset not specified');
% assert(~(isempty(args.cid) &  strcmpi(args.row_space, 'custom') & isempty(args.rid) & args.use_gctx),...
%      'Either Column ids or Row ids must be specified');
if isempty(args.rid) && ~strcmpi(args.row_space,'custom')
    assert(mortar.common.Spaces.probe_space.isKey(args.row_space),...
    'Invalid row space: %s, Expected one of %s', args.row_space,...
    print_dlm_line(mortar.common.Spaces.probe_space.keys, 'dlm', '|'));
end
end