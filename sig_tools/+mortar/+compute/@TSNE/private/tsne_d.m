function [ydata, cost] = tsne_d(D, labels, no_dims, perplexity, is_verbose)
%TSNE_D Performs symmetric t-SNE on the pairwise Euclidean distance matrix D
%
%   mappedX = tsne_d(D, labels, no_dims, perplexity, is_verbose)
%   mappedX = tsne_d(D, labels, initial_solution, perplexity, is_verbose)
%
% The function performs symmetric t-SNE on the NxN pairwise Euclidean 
% distance matrix D to construct an embedding with no_dims dimensions 
% (default = 2). An initial solution obtained from an other dimensionality 
% reduction technique may be specified in initial_solution. 
% The perplexity of the Gaussian kernel that is employed can be specified 
% through perplexity (default = 30). The labels of the data are not used 
% by t-SNE itself, however, they are used to color intermediate plots. 
% Please provide an empty labels matrix [] if you don't want to plot 
% results during the optimization.
% The data embedding is returned in mappedX.
%
%
% (C) Laurens van der Maaten, 2010
% University of California, San Diego


    if ~exist('labels', 'var')
        labels = [];
    end
    if ~exist('no_dims', 'var') || isempty(no_dims)
        no_dims = 2;
    end
    if ~exist('perplexity', 'var') || isempty(perplexity)
        perplexity = 30;
    end
    if ~exist('is_verbose', 'var') || isempty(is_verbose)
        is_verbose = true;
    end    
    % First check whether we already have an initial solution
    if numel(no_dims) > 1
        initial_solution = true;
        ydata = no_dims;
        no_dims = size(ydata, 2);
    else
        initial_solution = false;
    end
    
    % Compute joint probabilities
    D = D / max(D(:));                                                      % normalize distances
    P = d2p(D .^ 2, perplexity, 1e-5);                                      % compute affinities using fixed perplexity
    
    % Run t-SNE
    if initial_solution
        [ydata, cost] = tsne_p(P, labels, ydata, is_verbose);
    else
        [ydata, cost] = tsne_p(P, labels, no_dims, is_verbose);
    end
    