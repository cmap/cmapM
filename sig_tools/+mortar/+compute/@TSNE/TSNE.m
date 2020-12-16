classdef TSNE
    % Tsne: Apply t-distributed stochastic neighbor embedding (t-SNE) to
    %       high dimensional datasets. t-SNE is a dimensionality reduction
    %       technique that is particularly well suited for visualization of
    %       high dimensional data in 2 or 3 dimensions.
    %
    % For details see http://homepage.tudelft.nl/19j49/t-SNE.html
    
    methods(Static)
        
        % Run the native/ simple implementation of t-SNE        
        [tsx, cost] = simpleTsne(x, labels, no_dims, initial_dims, perplexity);
        
        % t-SNE on pairwise distance or similarities
        [tsx, cost] = tsnePairwise(x, labels, no_dims, perplexity);
        
        % Run the C++ implementation of Barnes-Hut-SNE.
        [tsx, landmarks, cost] = fastTsne(x, initial_dims, perplexity, theta);
        
        % Core routine
        res = runAnalysis(varargin);
        
        % save tsne results
        saveResult(res, outpath);
        
    end
    
end
