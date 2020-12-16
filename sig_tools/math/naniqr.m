function y = naniqr(x,dim)
%NANIQR Inter quartile range, ignoring NaNs.

if nargin == 1
    dim = 1;
    
end
    y = diff(prctile(x, [25, 75], dim),[], dim);    
end
