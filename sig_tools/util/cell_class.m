function c = cell_class(x)
% CELL_CLASS Return the class of each element in a cell array.
assert (iscell(x), 'X should be a cell array');
c = cellfun(@class, x, 'uniformoutput', false);
end