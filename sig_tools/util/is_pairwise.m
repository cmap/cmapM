function [is_similarity, is_distance, is_square, is_symmetric] = is_pairwise(x)
% IS_PAIRWISE Check if matrix is a pairwise similarity or distance matrix
% [is_similarity, is_distance, is_square, is_symmetric] = IS_PAIRWISE(X)

[nr, nc] = size(x);
% check if square
is_square = isequal(nr, nc);

if is_square    
    % check if symmetric
    is_symmetric = all(abs(tri2vec(x,1,true) - tri2vec(x',1,true))<eps);
    
    % check main diag = 1 or 0
    d = x(1:nr+1:end);
    is_similarity = all(abs(d-1)<eps);
    is_distance = all(abs(d)<eps);

else
    is_symmetric = false;
    is_similarity = false;
    is_distance = false;
end
end
