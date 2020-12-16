function [y,ix] = filterSig(sig)
% FILTERSIG Filters signal prior to tag duo call
%    [y,ix] = filterSig(sig) removes data given a histogram bin
%    criteria. The criteria was determined empirically. This code
%    is called prior to fitmixture
%    Inputs: 
%       sig: an n by 1 vector
%    Outputs: 
%       y: The new signal, equal to or shorter than sig
%       ix: The indices of the values removed. 
%    Example: 
%       y = [randn(100,1)+8 ; rand(10,1)]; 
%
% see also fitmitxure

input = sig; 
expected = 2;
[n,x] = hist(sig,30); 
ix = cumsum(n)./length(sig); 
ix = find(ix >= 0.05); 
sig(sig < x(ix(1)) ) = [];

[n,x] = hist(sig,30);
x = [0,x] ; 
stacked = struct('data',[]);

for i = 1 : length(x)-1
    stacked(i).data = sig(sig >= x(i) & sig < x(i+1)); 
    
end
keep = find(n > expected);

y = [];

for i = 1 : length(keep)
    y = [y ; stacked(keep(i)).data(:)]; 
end
[~,ix] = setdiff(input,y); 

end