function [ds_cell, ds_names] = parse_gct_list(gct_list, varargin)
% PARSE_GCT_LIST Read a list of gct(x) files into a cell array
%   [DS, DS_PATH] = PARSE_GCT_LIST(GCT_LIST) GCT_LIST is a cell array or GRP file containing 
%   filepaths to GCT or GCTX files to read. DS is a cell array of GCT
%   structures. DS_PATH is a cell array of file paths

gct_paths_cell = parse_grp(gct_list);
assert(~isempty(gct_paths_cell), 'GCT List is empty.')

% Parse each gct file and add to output cell array
num_ds = length(gct_paths_cell);
ds_cell = cell(num_ds, 1);
ds_names = cell(num_ds, 1);
for ii = 1:num_ds
    dbg(1, '# %d of %d', ii, num_ds)
    if (isds(gct_paths_cell{ii}))
        ds_cell{ii} = gct_paths_cell{ii};
    else
        ds_cell{ii} = parse_gctx(gct_paths_cell{ii}, varargin{:});
    end
    ds_names{ii} = ds_cell{ii}.src;
end

end
