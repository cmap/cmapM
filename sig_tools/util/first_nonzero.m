function [FI, FJ] = first_nonzero(A)
% FIRST_NONZERO Find the first non-zero element in each column of a matrix
%   [FI, FJ] = FIRST_NONZERO(A) returns row and column indices
%   corresponding to the first non-zero entry in each column of matrix A.
%   The length of FI and FJ equal to the number of columns in A. FI is set
%   to NaN for columns with no non-zero elements.
% 
% Example:
% A = [0     0     1     0
%     1     0     1     0
%     1     1     1     0
%     1     1     1     0
%     1     1     1     0];
% [FI, FJ] = first_nonzero(A)

[nr, nc] = size(A);

% row and column indices of all non-zero elements
% append an extra row for columns with no non-zero elements
[I, J] = find([A; ones(1, nc)]);

% first occurrence of each column index
[FJ, uidx] = unique(J, 'first');

% row index of first non-nan element
FI = I(uidx);

% set row indices for "no non-zero" columns to nan
FI(FI>nr) = nan;

end