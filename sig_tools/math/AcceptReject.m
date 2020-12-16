function y = AcceptReject(fun,c,interval,n,params)
% ACCEPTREJECT A naive implementation of the Acceptance-Rejection
% RNG
%  y = AcceptReject(fun,c,interval,n,params) will sample random
%  values from the density function, proportional to fun, defined
%  on interval. Uses trivial uniform box approach
%
% see Gentle, J.E. Elements of Computational Statistics

max_iter = 5*n; 

tmp = rand(max_iter,2); 
u = tmp(:,1); 
y = tmp(:,2).*(interval(2)-interval(1)) + interval(1); 
majorizing_funciton = c/(interval(2)-interval(1)); 

y(u> ( fun(y,params)./majorizing_funciton) ) = [];