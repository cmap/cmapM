function [pval x K P] = fexact( varargin )
%FEXACT Fisher's exact test
%
% Fisher's exact test is a statistical test used to compare binary outcomes
% between two groups. For example, The number of positive and negative lab
% results in individuals with disease (cases) compared to healthy
% (controls). The test is applicable most of the time a 2x2 contingency
% table can be made. This table is referred to in the usage below
%       cases  controls
%  pos   a        c       K
%  neg   b        d       -
% total  N        -       M
%
% This function returns a pvalue against the hypothesis that the table or a
% more extreme table might have occured by chance
%
% usage
%   p = fexact(X,y)
%       fisher exact test for situations in which the raw data have not
%       been counted and placed. X is a MxP matrix of dichotomous variables
%       and y is a vector of dichotomous outcome variables
%       (disease/control). X and y must be in {0,1}
%
%  p = fexact(..., 'options', values)
%      options:
%      tail  l(eft)','r(ight)', 'b(oth)'
%            left tail tests a negative association. p( x<=a, M, K, N)
%            right tail tests a positive association. p( x<=b, M, K, M-N)
%            both (default) is either a positive or negative association.
%            this is the sum from the left and right tails of the
%            distribution including all x where p(x|M,K,N) is less than
%            or equal p(a|M,K,N).
%      perm  Q. Repeat entire set of tests Q*respz times with permuted y variables. 
%            The reported p-values are corrected for multiple tests by
%            interpolating into the emprical distribution of the minimum
%            p-value obtained from each round
%            To use this option the X and y calling convention must be used
%      repsz Used with the PERM option. specifies the number of replicates
%            to compute at one time (default=100). The larger the number
%            the faster the results, but the more memory required. This is
%            needed because permutation takes far too much memory to fully
%            vectorize. REPSZ controls the size that is vectorized each
%            loop.
%
%  [p a K C] = fexact(X,y);
%       also returns vector a. a(i) is the upper left square of the contingency
%       corresponding to the ith column of X crosstabulated by y. K is a
%       vector containing a+b for the ith column of X.
%       C is a lookup table for CDFs that can be used in subsequent calls
%       to fexact to further improve performance.
%       C( x(i)+1, K(i)+1) is the cdf for the tail specified in
%       options
%
%  p = fexact( a,M,K,N, options)
%      M and N are constants. a and K are P-vectors. No checks for valid
%      input are made.
%
%  p = fexact( a,M,K,N,C]
%      C is a lookup table that improve performance. Intended to be
%      used with permutation testing where 1000s of calls are made.
%      the option "tail" is ignored if C is provided, as it implies
%      whatever tail was used to generate them. 
%
% NOTES and LIMITATIONS:
%      This function is extremely fast when doing multiple tests and is
%      acceptable with a small number of tests. However, it uses large
%      tracks of memory. On my 2Gb home Intel Core2 Quad Core Vista machine
%      this function does 250,000 tests with 100 observations each in 0.10
%      seconds. I run out of memory when I do more
%
% example
%  x = unidrnd(2, 200, 1000)-1;
%  y = unidrnd(2,200,1)-1;
%  p = fexact( x, y );           % generates p-values for 1000 tests in x
%  p = fexact( x, y, 'perm', 10) % reports p-value relative to empirial cdf
%   

% Copyright 2009 Mike Boedigheimer
% Amgen Inc.
% Department of Computational Biology
% mboedigh@amgen.com

p = inputParser;
p.addRequired('A');
p.addOptional('y',[]);
p.addOptional('K',[]);
p.addOptional('N',[]);
p.addOptional('C',[]);
p.addOptional('tail', 'b', @(c)ismember( c, {'b','l','r'} ));
p.addOptional('perm',  0, @(x) isnumeric(x)&isscalar(x));
p.addOptional('repsz', 100, @(x) isnumeric(x)&isscalar(x));
p.parse(varargin{:});

P = p.Results.C;
if isempty(p.Results.N)     % using fexact(X,y,options)
    X = p.Results.A;
    y = p.Results.y;
    if (~islogical(y) && ~all( ismember( y, [0 1])) ) && ...
            (~islogical(X) && ~all( ismember( X(:), [0 1])) )
        error('linstats:fexact:InvalidArgument', 'X and y must be in (0,1)' );
    end
    y = logical(y);
    N = sum(y);           % number of cases
    M = length(y);
    K = sum(X,1)';
    x = X'*sparse(y);  % in unofficial testing using timeit. This was faster than sum(X(y==1,:))
    % and faster than sum(bsxfun(@eq,X,y))
else % using fexact( a,M,K,N ...)
    x = p.Results.A;
    M = p.Results.y;
    N = p.Results.N;
    K = p.Results.K;
end

switch p.Results.tail
    case 'l'; tail = -1;
    case 'r'; tail = 1;
    case 'b'; tail = 2;
end

if N==0 || N==M
    pval = ones(1,length(x));
    return;
end;

if isempty(P)
    P = getLookup( M,N,tail);
end

pval = P( sub2ind(size(P), x+1, K+1));


if p.Results.perm > 1
    [fx x] = doPerm(X,y,M,K,P,p.Results.perm,p.Results.repsz);
    pval   = interp1( x, fx, pval);
end

function [fx x] = doPerm(X,y,M,K,P,nperms,repsz)

pperm = ones(repsz,nperms);

% sub2ind was previously 85% of the execution time. 
% this method computes the index directly rather than
% computing x and then calliung sub2ind. It is much
% faster because it uses the fast multiple engine
% precompute K*nrows +1, then add x after it is calculated
X = [ K*size(P,1)+1 X' ]; 
B = ones(1,repsz);

for permi = 1:nperms
    % generate new random vector y, by shuffling the rows (do not change
    % the counts of M,K or M)
    [i i] = sort( randn(M,repsz) );
    pperm(:,permi) = min( P( X*[B;y(i)] ));
end

[fx x] = mecdf(pperm(:));


function P = getLookup( M, N, tail)

F = gammaln( 1:M+1);  % used to compute factorials. For small problems
% It is overkill to generate all factorials up
% to M, but it takes on .001 seconds to compute
% all of them to 1..10,001, so we can afford
% it. Memory-wise may be more of an issue, and
% a reason to

% lookup value for lnchoosek(a,b) in matrix L for all 1<=b<=a<=M
% to lookup log nchoosek(n,k) use L(n+1,k+1);
[k n ind] = tri2sqind(M);
L = zeros(M);
L(ind) = lnchoosek( n, k, F);
L = blkdiag(0,L');      % pad first row and col with 0s for n=0, k=0


%log p(x|M,N,K) = Q(K,x)+Q(M-K,N-x)-Q(M,N) where Q(n,k) = lnchoosek(n,k)

% create a lookup table for Log P
% to lookup log p(x,|M,N,K) use P(x+1,K+1);
P = spdiags(ones(N+1,M+1),0:M-N,N+1,M+1);
[Xind Kind] = find(P);
MKind = M-Kind+2;
NXind = N-Xind+2;

q = sub2ind(size(P),Xind,Kind);
P = nan(size(P));
P(q) = exp( L(sub2ind(size(L),Kind,Xind))    + ... Q(K,x)
    L(sub2ind(size(L),MKind,NXind))  + ... Q(M-K, N-x)
    -L(M+1,N+1));                     % ... Q(M,N)
if tail == -1
    P = cumsum(tril(P, M-N));
elseif tail == 1
    P = flipud(triu(P));
    P = cumsum(P);
    R = N-(-1:size(P,1)-2)';
    P = P(R,:);
else
    % This function has been tested against two reference algorithm using all M
    % and N up to 30. The reference algorithms differ in how they find the
    % find the tail on the other side of the distribution.
    [q r] = size(P);
    [P idx] = sort(P,1);     % sort order, called rank, will be transformed to rank below
    ties = [abs(diff(P)) < M*numel(P)*eps(P(1:end-1,:));
        zeros(1,r)];
    R = repmat( (1:q)',1,r);
    R(col2ind(idx)) = R+ties;
    P = cumsum(P,1);          % reuse P to store cumulative P
    P = P(col2ind(R));
end



function q = lnchoosek( n, k, f)
% LNCHOOSEK natural log of nchoosek
%
% usage
%       q = lnchoosek( n, k );
% usage
%       q =

q    = n-k;       % allocate space same size as n
i    = q>0;       % only compute for valid n and k

if nargin < 3
    % q is 0 when n = k because log nchoosek(a,a) = 1 for any a >= 0
    % otherwise it is given by ...
    q(i) = -log(q(i)) - betaln(k(i)+1,q(i));     % otherwise this is it
else
    q(i) =  f(n(i)+1) - f(k(i)+1) - f( q(i)+1 );
end

q(~i) = 0;


function i = col2ind(order,siz)
%col2ind converts column specific 1-based indices to element based indices
%i = col2ind(A, siz)
%   return i, a set of integer indices into a m x n matrix
%   A is a p x n set of column specific indices as you'd get from the second
%   output of sort
%   size is optional.
%        if present, P is set to SIZ(1), otherwise
%        P is set to the size of the first dimension of ORDER,
%
% example
%   [xsort order] = sort(x);
%   wrong = x(order);    % this isn't what you want
%   xsort = x(col2ind(order));   % this is

[m p] = size(order);
if nargin < 2
    q = m;
else
    q = siz(1);
end
oset = 0:q:(q*p-1);
i = order + repmat( oset, m, 1 );

function [i,j,k] = tri2sqind( m, k )
%TRI2SQIND subscript and linear indices for upper tri portion of matrix
%
% get indices into a square matrix for a vector representing a the upper
% triangular portion of a matrix such as those returned by pdist.
%
% [i,j,k] = tri2sqind( m, k )
%  If V is a hypothetical vector representing the upper triangular portion
%  of a matrix (not including the diagonal) and
%  M is the size of a square matrix and
%  K is an optional vector of indices into V then tri2sqind returns
%  (i,j) the subscripted indices into the equivalent square matrix.
%  K is an integer index into the equivalent square matrix
%
% Example
%  X = randn(5, 20);
%  Y = pdist(X, 'euclidean');
%  [i,j,k] = tri2sqind( 5 );
%  S = squareform(Y);
%  isequal( Y(:), S(k) );
%  Z = zeros(5);
%  Z(k) = Y;

max_k = m*(m-1)/2;

if ( nargin < 2 )
    k = (1:max_k)';
end;

if any( k > max_k )
    error('linstats:tri2sqind:InvalidArgument', 'ind2subl:Out of range subscript');
end;


i = floor(m+1/2-sqrt(m^2-m+1/4-2.*(k-1)));
j = k - (i-1).*(m-i/2)+i;
k = sub2ind( [m m], i, j );

function [fx x] = mecdf( y )
% MECDF my ECDF function to avoid dependendencies on stats toolbox
% assumes 0 <= y <= 1
% x always includes 0 and fx(x>1) = 1;
n = length(y);
[x i] = unique(sort(y));
fx = linspace( 0, 1, n+1 )';
fx = fx(i+1);
if x(1)>0
    x = [0;x];
    fx = [0;fx];
end

if x(end) < 1    % set up the maximum x value as Inf, so interp1 never fails 
    x  = [x;Inf];
    fx = [fx;1];
end



