function j = weld(d, varargin)
% WELD concatenate cell arrays to a string.
%   J = WELD(D, C) concatenates cell array C of dimensions [NR, NC] to a
%   cell string array J of length NR 
%   J = WELD(D, C1, C2, ...) concatenates 1-d arrays C1, C2,... to a cell
%   array.

assert(ischar(d), 'delimiter should be a string');
nin=nargin;
npart = nin - 1;
d={d};
[nrow, ncol] = size(varargin{1});
dlm = d(ones(nrow, 1));
if ncol>1
    % cell matrix 
    j = varargin{1}(:, 1);
    for ii=2:ncol
        j = strcat(j, dlm, varargin{1}(:, ii));
    end
else
    for ii=2:npart
        assert(isequal(length(varargin{ii}), nrow), ...
            'All inputs should have the same number of rows');
    end    
    j = varargin{1};
    for ii=2:npart
        j = strcat(j, dlm, varargin{ii});
    end    
end

end