function s2n = pearson_s2n(x)
% PEARSON_S2N Compute LSS values for a feature x
%   Input: 
%       x - a vector reponse
%   Output: 
%       s2n - The chi-squared statistic applied to x using 15% trimmed mean
% 
% Author: Brian Geier, Broad 2010
ct = trimmean(x,.15); 
s2n = (x-ct).^2./ct ; 