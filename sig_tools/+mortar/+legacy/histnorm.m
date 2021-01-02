function varargout = histnorm(X, varargin)
% HISTNORM Produces area- and height- normalized histograms.
%   HISTNORM(X) Plots an area-normalized histogram of the numeric vector X
%   with 10 bins.
%
%   HISTNORM(X, M) Uses M bins.
%
%   HISTNORM(X, NORMHEIGHT) Produces a height-normalized histogram if
%   NORMHEIGHT is true.
%
%   HISTNORM(X, M, NORMHEIGHT)
%
%   [N, C] = HISTNORM(...) Returns the bin counts and bin centers instead
%   of plotting the histogram.

error(nargchk(1, 3, nargin)); error(nargchk(0,2,nargout))
wrongclass = false;

if ~isnumeric(X)
    wrongclass = true;
end
if nargin == 1
    b = 10; 
    height = false;
elseif nargin == 2
    if isnumeric(varargin{1})
        b = varargin{1};
        height = false;
    elseif islogical(varargin{1})
        b = 10;
        height = varargin{1};
    else
        wrongclass = true;
    end
else
    if isnumeric(varargin{1}) && islogical(varargin{2})
        b = varargin{1};
        height = varargin{2};
    else
        wrongclass = true;
    end
end
if wrongclass
    error('Inputs are of incorrect class')
end

[h,C] = hist(X,b);

if height
    H = h / max(h);    
else
    w = C(2) - C(1);
    a = sum(h .* w);
    H = h ./ a;    
end

if ~nargout
    bar(C, H, 1)
elseif nargout == 1 
    varargout = {H};
elseif nargout == 2 
    varargout = {H C};
end

end

