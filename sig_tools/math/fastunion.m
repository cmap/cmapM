function u = fastunion(x)
% FASTUNION Compute the union between sets.
%   S = FASTUNION(X) Computes the union between the rows of
%   a NxM binary matrix X. S is a NxN matrix where each element Sij is the
%   union between set i and set j.
%

if islogical(x)
    x = double(x);
elseif isnumeric(x)
    x = double(abs(x) > eps);
end

% number of sets
ns = size(x, 1);

% intersection
c = x * x';

% number of elements in a pair of sets,
% set zeros to one to handle empty sets causing DBZ
s = max(diag(c), 1) * ones(1, ns);

% union
u = s + s' - c;

end