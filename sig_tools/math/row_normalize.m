%ROW_NORMALIZE Normalize input matrix along rows
%   [NM,MU,SIGMA]= ROW_NORMALIZE(M) Performs row normalization on the input
%   matrix M. Each element in NM is computed as:
%   NM(i,j) = [M(i,j) - mean(M(i,:))] / std (M(i,:))
%   The row means (MU) and the standard deviations (SIGMA) are also returned.
%   NAN's in M are excluded when computing the mean and std. Standard
%   deviations of zero produce a warning (zeros are replaced by one). 

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

function [nm,mu,sigma] = row_normalize(m)

[nr,nc] = size(m);

%mean and std along rows, exclude nan's
mu=nanmean(m,2);
sigma = nanstd(m,0,2);

%check for zero stds
zsigma = (sigma==0);
% zsigma = (sigma<=0.01);

if (any(zsigma))
    sigma(zsigma) = 1;

    warning ('Zero std in input matrix in the following rows:');
    fprintf ('%d ',find(zsigma));
    fprintf('\n')
end

%row-normalized matrix
nm = (m-repmat(mu,1,nc)) ./ repmat(sigma,1,nc);


