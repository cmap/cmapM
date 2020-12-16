function plotcis(y,L,U,spec)
% PLOTCIS   Plot raw confidence intervals as error limits 
%   PLOTCIS(y,L,U,spec) will plot the vector Y with upper and lower error
%   bars, L, U, where L and U are the lower and upper bounds of a 
%   confidence interval for each element in Y. 'spec' is an additional
%   parameter which specifies the line type, by default 'b'. 
% 
%   Example: 
%       y = randn(1000,10); x = randn(1000,1); ci = zeros(2,10); 
%       for i = 1 : 10
%           ci(:,i) = bootci(3000, @corr, y(:,i), x); 
%       end
%       plotcis(corr(x,y),ci(2,:),ci(1,:),'r')
% 
% Author: Brian Geier, Broad 2010

if nargin == 3
    spec ='b'; 
elseif nargin ~= 4
    error('At least y,L,U, must be specified'); 
end

L = abs(y-L); 
U = abs(y-U);

errorbar(1:length(y),y,L,U,spec)
xlim([0 length(y)])