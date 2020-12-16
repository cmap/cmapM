function signal = computeS2N(x,y,fix_low)
% COMPUTES2N Computes the signal-to-noise ratio between populations x and y
%   signal = computeS2N(x,y,fix_low) will compute the signal to noise ratio
%   between the popultations found in x and y, where x and y are n by p
%   data matrices. The matrices x and y need not have the same sample size.
%   If fix_low = true, then the minimum standard deviation allowed per
%   population is 0.2 . Based upon A. Subramanian Java code
% 
% Author: Brian Geier, Broad 2010

if nargin ==2
    fix_low = true ; 
end

if fix_low
    
    signal = (mean(x) - mean(y))./(fixstd(x) + fixstd(y)); 
    
else
    
    signal = (mean(x) - mean(y))./(std(x) + std(y)); 
    
end

end

function s = fixstd(x)

min_stdev = 0.2; 

if min_stdev*mean(x) == 0
    minallowed = min_stdev ; 
else
    minallowed = min_stdev*mean(x); 
end

if minallowed < std(x)
    s = std(x); 
else
    s = min_stdev; 
end

end