function [ordx, idx] = orderas(x, o)
% ORDERAS Order elements according to a pre-specified list
% ORD = ORDERAS(X, O)
% [ORD, IDX] = ORDERAS(X, O)

[~,~,idx] = intersect(o, x, 'stable');
all_idx = 1:numel(x);
all_idx(idx) = 0;
idx = [idx; find(all_idx)'];
ordx = x(idx);

end
