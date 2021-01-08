function rpt = quantile_info(n,q)
%rpt = quantile_info(n,q)
%
%Input
%   n: size of set. A positive integer
%   q: quantile. Must be a positive real in [0,1]
%
%Output
%   rpt: a struct with fields
%       low_rank: positive integer
%       low_weight: float in [0,1]
%       high_rank: integer
%       high_weight: float in [0,1]
%
%Returns information useful to understand how a quantile is computed using
%the quantile (or prctile) built in matlab functions. Given a set of numbers and a positive
%fraction q, quantile computes the q'th quantile of this set by linearly
%interpolating between the nearest values of the set. See the matlab help:
%
%http://www.mathworks.com/help/stats/quantiles-and-percentiles.html
%
%for more information. The quantile_info function returns the ranks and
%weights used in the quantile computation. 
%
%Eg: The .75 quantile of three numbers a < b < c is equal to .25*b + .75*c
%
%Thus rpt = quantile_info(3,.75)
%
%returns
%
%low_rank = 2
%low_weight = .25
%high_rank = 3
%high_weight = .75
%
%This signifies that quantile([a,b,c],.75) is computed as the weighted average
%between the second and third largest values in the set with weights .25
%and .75

assert(q >= 0 && q <= 1, 'q must be in [0,1]')
assert(isint(n) && n >= 1, 'n must be a positive integer')

x = ((1:n) - .5)/n;

if all(q >= x)
    %highest quantile
    low_rank = n;
    high_rank = n;
    high_weight = .5;
    low_weight = .5;
elseif all(q <= x)
    %lowest quantile
    low_rank = 1;
    high_rank = 1;
    high_weight = .5;
    low_weight = .5;
else
    %get ranks on either side of q
    low_rank = nnz(find(q > x));
    high_rank = low_rank + 1;

    %get weights
    high_weight = (q - x(low_rank))/(x(high_rank) - x(low_rank));
    low_weight = 1 - high_weight;
end

rpt.low_rank = low_rank;
rpt.high_rank = high_rank;
rpt.low_weight = low_weight;
rpt.high_weight = high_weight;

end

