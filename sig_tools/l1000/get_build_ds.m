function ds = get_build_ds(build_id, row_space)
% GET_BUILD_DS Get build datasets
%   GET_BUILD_DS(BUILD_ID, ROW_SPACE)

build = parse_tbl(fullfile(mortarpath, 'resources/data_builds.txt'),...
    'outfmt', 'record', 'verbose', false);
bidx = find(strcmp(build_id, {build.build_id}));
assert(~isempty(bidx), 'Invalid build_id: %s', build_id);

ds.score = build(bidx).score;
rs_field = sprintf('rank_%s', row_space);
if isfield(build(bidx), rs_field)
    ds.rank = build(bidx).(rs_field);
else
    ds.rank = '';
end

end