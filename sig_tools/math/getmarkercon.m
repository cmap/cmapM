function [markers,consensus] = getmarkercon(trkmarkers,n,k)
% GETMARKERCON    Finds the marker rate across leave-one out iterations
%   [markers,consensus] = getmarkercon(trkmarkers,n,k) will find
%   the rate at which each biomarker is present across the
%   leave-one out iterations. The input to getmerkcon is the set of
%   k biomarkers from the n leave-one out validation runs, the
%   sample size, and the number of desired biomarkers k. 
%   Inputs: 
%       trkmarkers - is a 2-dimensional array (n by k). The first dimension
%       is the case where the ith sample is deleted. The second
%       dimension is the k biomarkers. 
%       n - the number of samples involved
%       k - the number of biomarkers desired
%   Outputs: 
%       markers - the k biomarkers which have the highest consensus
%       across the leave-one out validation runs
%       consensus - a score, i.e. proportion of cross validation
%       runs where the gene is found to be a biomarker, normalized
%       by the number of samples. 
%
%   Note: This is a subroutine called within conbiomarker. 
%   See also conbiomarker
% 
% Author: Brian Geier, Broad 2010

markers = unique(trkmarkers(:)); 
consensus = zeros(n,k); 
for i = 1 : n
    for j = 1 : k
        if any(markers(j) == trkmarkers(i,:))
            consensus(i,j) = 1; 
        end
    end
end
consensus = sum(consensus)/n; 
[~,ix] = sort(consensus,'descend'); 
markers = markers(ix(1:k)); 