function x = roundn(x, n)
%ROUNDN  Round to multiple of 10^n
%
%   ROUNDN(X,N) rounds each element of X to the nearest multiple of 10^N.
%   N must be scalar, and integer-valued. For complex X, the imaginary
%   and real parts are rounded independently. For N = 0 ROUNDN gives the
%   same result as ROUND. That is, ROUNDN(X,0) == ROUND(X).
%
%   Examples
%   --------
%   % Round pi to the nearest hundredth
%   roundn(pi, -2)
%
%   % Round the equatorial radius of the Earth, 6378137 meters,
%   % to the nearest kilometer.
%   roundn(6378137, 3)
%
%  See also ROUND.

% Copyright 1996-2011 The MathWorks, Inc.
% $Revision: 1.1.6.5 $  $Date: 2011/02/26 17:40:48 $

% Validate inputs. (Both are required.)
error(nargchk(2, 2, nargin, 'struct'))
validateattributes(x, {'single', 'double', 'logical'}, {}, 'ROUNDN', 'X')
validateattributes(n, ...
    {'numeric'}, {'scalar', 'real', 'integer'}, 'ROUNDN', 'N')

if n < 0
    % Compute the inverse of the power of 10 to which input will be
    % rounded. Because n < 0, p will be greater than 1.
    p = 10 ^ -n;

    % Round x to the nearest multiple of 1/p.
    x = round(p * x) / p;
elseif n > 0
    % Compute the power of 10 to which input will be rounded. Because
    % n > 0, p will be greater than 1.
    p = 10 ^ n;
    
    % Round x to the nearest multiple of p.
    x = p * round(x / p);
else
    x = round(x);
end