function [n, v] = unwrap_groupcell(gpc, gpn)
% UNWRAP_GROUPCELL Unwrap a cell array of indices
%
% See GROUP2CELL

assert(isequal(numel(gpc), numel(gpn)),...
    'GPC and GPN should have the same dimensions')
assert(iscell(gpc), 'GPC should be a cell array');
gp_sz = cellfun(@numel, gpc);
idx = grpsize2idx(gp_sz);
n = gpn(idx);
v = cat(1, gpc{:});

end