function pvalue = getpvalue(X,stat)
% GETPVALUE Returns the ECDF evaluation of the value stat in population X
%   GETPVALUE(X,stat) will evaluate the cumulative probability associated
%   with the value or values in stat given a population/distribution X.
%   This routine is often used for  returning pvalues between in an
%   observed test statistic and null distribution. 
% 
% Author: Brian Geier, Broad 2010
 

[f,x] = ecdf(X); 
[~,ix] = min(abs(x*ones(1,length(stat)) - ones(length(x),1)*stat(:)')); 
pvalue = f(ix); 