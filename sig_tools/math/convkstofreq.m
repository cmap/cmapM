function [f,x] = convkstofreq(data)
% CONVKSTOFREQ Returns KS estimate as a frequency
%
%    Example: 
%      data = randn(1000,1) ;
%      [f,x] = convkstofreq(data); plot(x,f)
%      xlabel('Data'), ylabel('Frequency'), title('Gaussian
%      Distribution Estimate')
%
% Author: Brian Geier, Broad 2010

n = hist(data,30); 
[f,x] = ksdensity(data); 
f = (f/max(f))*(max(n)/length(data)); 

end