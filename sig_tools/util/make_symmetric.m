function x = make_symmetric(x, symfun, nanval)
% MAKE_SYMMETRIC Symmetricize a square matrix
% MAKE_SYMMETRIC(DS, SYMFUN, NANVAL) returns a symmetric matrix from
% values in X by appyling the operation SYMFUN. NaN values in the
% output matrix are set to NANVAL. Valid values for SYMFUN are {'mean',
% 'max', 'min', 'absmax', 'absmin'}. 

[nr, nc] = size(x);
assert(isequal(nr, nc), 'Matrix should have the same rows and columns');

[ir, ic] = find(isnan(x));
x(sub2ind([nr, nc], ir, ic)) = x(sub2ind([nr, nc], ic, ir));

switch(symfun)
    case 'mean'
        x = 0.5*(x + x');
    case 'max'
        x = max(x, x');
    case 'min'
        x = min(x, x');
    case 'absmax'
        absx = abs(x);
        x = max(absx, absx');
    case 'absmin'
        absx = abs(x);
        x = min(absx, absx');
    otherwise
        error('unknown symfun : %s', symfun);
end
x = nan_to_val(x, nanval);
end