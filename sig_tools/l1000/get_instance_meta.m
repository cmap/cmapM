function meta = get_instance_meta(varargin)

pnames = {'brew', 'brew_path'};
dflts = {'', ''};
args = parse_args(pnames, dflts, varargin{:});
print_args(mfilename, 1, args);

% mapfile
brew_root = fullfile(args.brew_path, args.brew);

[~, map_file] = find_file(fullfile(brew_root, '*.map'));
assert(isequal(length(map_file), 1), 'Map file not found or not unique');
meta = parse_tbl(map_file{1}, 'outfmt', 'record');

% fields to keep
map_keep = parse_grp('/cmap/data/vdb/mongo/instance_fields.grp');

meta = rmfield(meta, setdiff(fieldnames(meta), map_keep));
% rename the id field to sig_id
meta = mvfield(meta, 'id', 'distil_id');

end