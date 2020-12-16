function [tsx, cost] = tsnePairwise(x, labels, no_dims, perplexity)
% tsnePairwise Compute tSNE on pairwise similarity or distance matrices.
% [TS, COST] = tsnePairwise(X) Compute tSNE on square-symmetric matrix X
% Assumes that the values of X are distances if the main diagonal is zero
% or alternatively similarities if the main diagonal is one.
%
% [TS, COST] = tsnePairwise(X, labels, no_dims, perplexity)

if ~exist('labels', 'var')
    labels = [];
end
if ~exist('no_dims', 'var') || isempty(no_dims)
    no_dims = 2;
end

if ~exist('perplexity', 'var') || isempty(perplexity)
    perplexity = 30;
end

% Infer similarity or distance using main diagonal
[is_similarity, is_distance, is_square, is_symmetric] = is_pairwise(x);
assert(is_square, 'Expected square matrix as input got [%d x %d]', size(x, 1), size(x, 2));

if is_similarity
    dbg(1, 'Input values are similarities, converting to distances')
    x = 1-x;
elseif is_distance
    dbg(1, 'Input values are distances, using as-is')
else
    error('Expected the main diagonal to be either 0 or 1 for distance or similarity respectively');
end

if ~is_symmetric
    % extract lower triangle and symmetricize
    dbg(1, 'Input matrix is not symmetric using lower triangle values')
    x = squareform(tri2vec(x, 1, false));
end

[tsx, cost] = tsne_d(x, labels, no_dims, perplexity, false);


end