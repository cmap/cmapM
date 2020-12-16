function checkArgs_(obj)
    args = obj.getArgs;
    assert(isds(args.ds) || mortar.common.FileUtil.isfile(args.ds, 'file'), ...
        'Invalid dataset provided or file not found');
    if isempty(args.rid) && ~strcmpi(args.row_space,'custom')
        assert(mortar.common.Spaces.probe_space.isKey(args.row_space), ...
        'Invalid row space: %s, Expected one of %s', args.row_space, ...
        print_dlm_line(mortar.common.Spaces.probe_space.keys, 'dlm', '|'));
    end
end