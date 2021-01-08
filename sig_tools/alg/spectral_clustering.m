function [idx, eigval, Y,V] = spectral_clustering(x, k, scale, q)
% SPECTRAL_CLUSTERING Perform spectral clustering.
%   IDX = SPECTRAL_CLUSTERING(X, K, SCALE, Q) partitions the points in the
%   N-by-P data matrix X into K clusters. SCALE specifies how fast the
%   affinity A(i,j) falls off with the distance between points i and j. 
%   
%   References: 
%
%   A. Ng, M. Jordan, and Y. Weiss. On spectral clustering:
%   Analysis and an algorithm. In Advances in Neural Information Processing
%   Systems 14: Proceedings of the 2001.
%   http://citeseer.ist.psu.edu/ng01spectral.html   
%
%   U. von Luxburg, A tutorial on spectral clustering.

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT

% affinity matrix
% a fully connected graph, using a gaussian similarity function
A = squareform(exp(-(pdist(x,'seuclidean')/(2*scale^2))));

% inverse of the diagonal matrix formed by row sums of A
Dinvsqrt = diag(sqrt(1./sum(A,2)));

% Construct normalized graph Laplacian
L = Dinvsqrt * A * Dinvsqrt;

% an alternative form of the Laplacian
% L = eye(size(Dinvsqrt)) - Dinvsqrt * A * Dinvsqrt;

% compute eigenvectors and eigen values of L
% Note: eigvectors should be ordered based on magnitude of eigval
[V, eigval] = eig(L);
[eigval, index]  = sort(diag(eigval), 'descend');

% keep largest q eigenvectors and normalize rows to have unit length
if (q>1)
    Y = bsxfun(@rdivide, V(:,index(1:q)), sqrt(sum(V(:,index(1:q)).^2, 2)) );
else
    Y = V(:,1);
end

% cluster rows of Y using kmeans
idx = kmeans(Y, k, 'emptyaction','drop');
