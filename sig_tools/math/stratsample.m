function [y, xidx, hn, nh] = stratsample(x, h, n, method, replace, c)
% STRATSAMPLE Stratified random sample, with or without replacement.
%   Y = STRATSAMPLE(X, H, N) returns Y as a vector of N values sampled
%   randomly using proportional stratification from the values in vector X.
%   H is a grouping variable defined as a vector or cell array of strings,
%   with the same length as X, that specifies the stratum that each value in
%   X belongs to.
%
%   [Y, XIDX, HN, NH] = STRATSAMPLE(X, H, N) also returns a list of indices
%   corresponding indices of X such that Y = X(XIDX), strata names HN, and
%   the number of values that were sampled in each stratum NH
%
%   Y = STRATSAMPLE(X, H, N, METHOD) uses the sampling strategy METHOD.
%   Choices are:
%       'proportional' - allocation of samples is proportional to size of
%                        each stratum. This is the default.
%       'neyman'       - allocation is proportional to Nh*Sh, where Sh is
%                        the std. deviation of stratum h, so that more
%                        samples are allocated to strata with large
%                        variances in addition to large sizes.
%       'optimal'      - allocation is proportional to the Nh*Sh/sqrt(Ch),
%                        where Ch is the cost associated with stratum h.
%                        More samples are allocated when the stratum
%                        accounts for a large part of the population, the
%                        variance within the stratum is large or the cost
%                        of sampling in the stratum is low.
%
%   Y = STRATSAMPLE(X, H, N, METHOD, REPLACE) sample with replacement if
%   REPLACE is true
%
%   Y = STRATSAMPLE(X, H, N, METHOD, REPLACE, C) specify the cost Ch for
%   each strata, only applies to the 'optimal' sampling method. Ch is a
%   numeric vector of the same length as X.
%
%   See also randsample
%
%   Reference: 
%   Sampling Design and Analysis, Sharon L. Lohr, 2nd Ed., Sec. 3, Pg. 73

if ~isvarexist('method')
    method = 'proportional';
end

if ~isvarexist('replace')
    replace = false;
end

if isequal(method, 'optimal') && ~isvarexist('c')
    error('Cost not specified for ''optimal'' sampling');
end

% total observations
N = length(x);
assert(isequal(length(x), length(h)));
[hn, hi] = getcls(h);
ng = length(hn);
% number of observations per stratum
Nh = accumarray(hi, ones(size(hi)));

% sample sizes for each stratum
switch(lower(method))
    case 'proportional'
        % proportional to the Nh
        nh = round(n*Nh/N);        
    case 'neyman'
        % proprtional to the Nh * Sh
        Sh = grpstats(x, hi, {@(x) std(x, 0, 1)});
        wt = Nh.*Sh;
        nh = round(n*wt/sum(wt));
    case 'optimal'
        % proportional to the Nh * Sh / sqrt(Ch)
        [~, ui] = unique(hi);
        Ch = c(ui);
        Sh = grpstats(x, hi, {@(x) std(x, 0, 1)});
        wt = Nh.*Sh./sqrt(Ch);
        nh = round(n*wt/sum(wt));
    case 'equal'
        nh = round(n/ng);
    otherwise
        error('Unknown method: %s, expected {''proportional'', ''neyman'', ''optimal''}', method)
end

tots = sum(nh);

% adjust the sample sizes per stratum to total the requested samples
if ~isequal(tots, n)
    [~, maxi] = max(nh);
    nh(maxi) = nh(maxi) + (n - tots);
    tots = n;
end

% Random sampling for each stratum
y = zeros(tots, 1);
start_idx = cumsum([0; nh(1:end-1)]);

for ii=1:ng
    this = hi == ii;
    this_idx = find(this);
    this_picks = randsample(this_idx, nh(ii), replace);
    
    y(start_idx(ii) + (1:nh(ii))) = x(this_picks);
    xidx(start_idx(ii) + (1:nh(ii))) = this_picks;
end

end