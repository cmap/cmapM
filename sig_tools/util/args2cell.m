function c = args2cell(args)
% Convert and argument structure to a cell array
%   C = ARGS2CELL(A) returns a cell array of size N=2*length(fieldnames(A)).

assert(isstruct(args) && isequal(length(args), 1));

c = cell(2*length(fieldnames(args)), 1);
c(1:2:end) = fieldnames(args);
c(2:2:end) = struct2cell(args);
end