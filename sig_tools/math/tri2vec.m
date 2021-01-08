function [v, varargout] = tri2vec(m, k, ut)
% TRI2VEC Get elements from the upper or lower triangle of a matrix.
% V = TRI2VEC(M) returns the elements above the main diagonal of a matrix.
% V = TRI2VEC(M, K) returns elements above the Kth diagonal of M. K is 1 by
% default.  K = 0 is the main diagonal, K > 0 is above the main diagonal
% and K < 0 is below the main diagonal.
% V = TRI2VEC(M, K, ISUT) returns elements from the upper triangle of the
% matrix if UT is true (the default) or from the lower triangle if UT is
% false.
% [V, MIDX] = TRI2VEC(...) Returns linear indices of elements in matrix M
% that were selected
% [V, RIDX, CIDX] = TRI2VEC(...) Returns row and column subscripts of
% elements in M that were selected.
%
% If X is a symmetric matrix with zeros on the main diagonal, then use
% SQUAREFORM to reformat V to a square matrix:
%   X = SQUAREFORM(TRI2VEC(X, 1, false));

% See also TRIU, TRIL

if ~isvarexist('k')
    k = 1;
end

if ~isvarexist('ut')
    ut = true;
end

nout = nargout;

if ut
    % upper triangle
    select = triu(true(size(m)), k);    
else
    % lower triangle
    select = tril(true(size(m)), -k);
end
v = m(select);

% % to maintain compatibility with squareform, transpose and select the
% % opposite triangle.
% m = m';
% if ut
%     % upper triangle
%     select = tril(true(size(m)), -k);    
% else
%     % lower triangle
%     select = triu(true(size(m)), k);    
% end
% v = m(select);

if nout==2
    varargout(1) = {find(select)};
elseif nout>=3
    varargout = cell(2, 1);
    [varargout{1}, varargout{2}] = find(select);
end

end