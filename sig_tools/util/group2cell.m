function [gpn, gpc, gpi, gpsz] = group2cell(x, gp)
% GROUP2CELL Group a vector or cell array 
% [GPN, GPC, GPI, GPSZ] = GROUP2CELL(X, GP) Groups elements of X based on
%   the grouping variable GP. Both X and GP should have the same
%   dimensions. Returns a list of unique groups GPN, a cell array of
%   elements of X that belong to a group GPC, a numeric grouping array GPI
%   with values corresponding to indices of GPN and the size of each group
%   GPSZ.
%   
assert(isequal(numel(x), numel(gp)),...
    'X and GP should have the same dimensions')
[gpn, gpi] = getcls(gp);
[~, isrt] = sort(gpi);
gpsz = accumarray(gpi, ones(size(gpi)));
gpc = mat2cell(x(isrt), gpsz, 1);

end