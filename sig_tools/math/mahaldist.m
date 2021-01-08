function d2 = mahaldist(x,show)
% MAHALDIST     Computs mahal distance of the multivarte data
%   MAHALDIST(x,show) will compute the multivariate distance for each
%   observation with respect to the global mean and full covariance. As an
%   option, the QQ plot of the distances and their Chi2 quantiles can be
%   plotted to formally check multivariate normality, default is false. 
% 
%   Inputs: 
%       x : a matrix of multivariate observations, n by p
%       show : a logical indicator, true => output qqplot of distances
% 
%   Output: 
%       d2 : the mahal distance, i.e. (x-mu)*sinv*(x-mu)', of each
%       observation
%       Additionally, a qqplot of distances is outputted if show =1
% 
% Author: Brian Geier, Broad 2010

if nargin == 1
    show = 0; 
end

[n,p] = size(x); 

if p == 1
    d2 = ((x-mean(x)).^2)/var(x); 
    return
end

if p > 1000
    grab = randperm(p); 
    x = x(:,grab(1:1000)); 
    p = 1000;
end

if p > n
    if (n-10) >= p
        d2 = repmat(NaN,[size(x,1),1]); 
        return
    end
    grab = randperm(p); 
    x = x(:,grab(1:(n-10))); 
    p = n-10; 
end

tic
fprintf(1,'%s\n','Computing Population Covariance Inverse') ; 
s = pinv(cov(x)); 
% try 
%     s = inv(cov(x)); 
% catch EM
%     disp(EM)
%     s = pinv(cov(x)); 
% end
toc
tic
fprintf(1,'%s\n','Computing Distances'); 
d2 = diag((x - repmat(mean(x),[n,1]))*s*(x - repmat(mean(x),[n,1]))');  
toc

if show
    ix = 1 : length(d2); 
    plot(chi2inv((ix-1/2)./n,p),sort(d2),'.','MarkerSize',10)
    xlabel('Chi-Squared Quantile')
    ylabel('Ordered Mahal Distance')
    title('QQ Plot of Mahal vs. Chi-Squared')
    lsline
end