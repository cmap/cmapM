function [f,x] = ks2freq(data)
% KS2FREQ Convert kernel estimate desnity curve to frequency
%   KS2FREQ will convert the density response to an observed frequency,
%   using a histogram estimate. 
%   Input: 
%       data: a vectory of type double
%   Outputs: 
%       A figure is drawn. The estimates x and f(x) are returned. 
% 
% see also ksdensity, hist

n = hist(data,30); 
[f,x] = ksdensity(data); 
f = (f/max(f))*(max(n)/length(data)); 
if nargout == 0
    figure
    plot(x,f)
    xlabel('x'); ylabel('Proportion of x')
end

end