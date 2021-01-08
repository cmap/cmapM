function px = lookupPercentile(v, p, x)
% lookupPercentile Lookup percentiles from a pre-computed lookup table
%   PX = lookupPercentile(V, P, X) Looks up the corresponding percentile of
%   X from the values specified by [V, P] value output by the function
%   computePercentileLookup 
%
% See also: computePercentileLookup

min_val = min(v);
max_val = max(v);

px = interp1(v, p, clip(x, min_val, max_val), 'linear');
                            
end