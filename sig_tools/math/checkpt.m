function [y,p] = checkpt(x1,x2)
% CHECKPT    Point-wise Mahal Distance and Chi2 probability
%   For vectors, x1 and x2, CHECKPT(x1,x2) is the multivariate generalized
%   distance, i.e. mahal distance, for every single point. Additionally,
%   the p value, given that x1 and x2 are elliptically distributed in a two
%   dimensional space, is outputted. 
% 
% Author: Brian Geier, Broad 2010

x = [x1(:) x2(:)]; 
sigma_val = cov(x); 
mu_val = mean(x); 
a = diag(sigma_val); 
sigma_inv = (1/det(sigma_val))*[ -1*a(2) sigma_val(1,2)  ; ...
    sigma_val(2,1) -1*a(1) ] ; % Simple shortcut for 2 x 2 matrix
y = (x-repmat(mu_val,[length(x1),1]))*sigma_inv*...
    (x-repmat(mu_val,[length(x1),1]))'; % generalized distance
y = abs(diag(y)); 
p = 1 - chi2cdf(y,length(mu_val) ) ;

end
