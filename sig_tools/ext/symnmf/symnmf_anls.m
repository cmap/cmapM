function [H, iter, obj] = symnmf_anls(A, k, params)
%SYMNMF_ANLS ANLS algorithm for SymNMF
%   [H, iter, obj] = symnmf_anls(A, k, params) optimizes
%   the following formulation:
%
%   min_H f(H) = ||A - WH'||_F^2 + alpha * ||W-H||_F^2
%   subject to W >= 0, H >= 0
%
%   where A is a n*n symmetric matrix,
%         H is a n*k nonnegative matrix.
%         (typically, k << n)
%   'symnmf_anls' returns:
%       H: The low-rank n*k matrix used to approximate A.
%       iter: Number of iterations before termination.
%       obj: Objective value f(H) at the final solution H.
%            (is set to -1 when it is not actually computed)
%
%   The optional 'params' has the following fields:
%       Hinit: Initialization of H. To avoid H=0 returned as
%              solution, the default random 'Hinit' is
%                  2 * full(sqrt(mean(mean(A)) / k)) * rand(n, k)
%              to make sure that entries of 'Hinit' fall
%              into the interval [0, 2*sqrt(m/k)],
%              where 'm' is the average of all entries of A.
%              User-defined 'Hinit' should follow this rule.
%       maxiter: Maximum number of iteration allowed.
%                (default is 10000)
%       tol: The tolerance parameter 'mu' in the cited paper,
%            to determine convergence and terminate the algorithm.
%            (default is 1e-3)
%       alpha: The parameter for penalty term in the above
%              formulation. A negative 'alpha' means using
%                  alpha = max(max(A))^2;
%              in the algorithm. When alpha=0, this code is generally
%              faster and will adjust the final W, H to be the same
%              matrix; however, there is no theoretical guarantee
%              to converge with alpha=0 so far.
%              (default is -1)
%       computeobj: A boolean variable indicating whether the
%                   objective value f(H) at the final solution H
%                   will be computed.
%                   (default is true)
%       debug: There are 3 levels of debug information output.
%              debug=0: No output (default)
%              debug=1: Output the initial and final norms of projected gradient
%              debug=2: Output the norms of projected gradient
%                       in each iteration
%
%   In the context of graph clustering, 'A' is a symmetric matrix containing
%   similarity values between every pair of data points in a data set of size 'n'.
%   The output 'H' is a clustering indicator matrix, and clustering assignments
%   are indicated by the largest entry in each row of 'H'.
%

n = size(A, 1);
if n ~= size(A, 2)
    error('A must be a symmetric matrix!');
end

if ~exist('params', 'var')
    H = 2 * full(sqrt(mean(mean(A)) / k)) * rand(n, k);
    maxiter = 10000;
    tol = 1e-3;
    alpha = max(max(A))^2;
    computeobj = true;
    debug = 0;
else
    if isfield(params, 'Hinit')
        [n, kH] = size(params.Hinit);
        if n ~= size(A, 1)
            error('A and params.Hinit must have same number of rows!');
        end
        if kH ~= k
            error('params.Hinit must have k columns!');
        end
        H = params.Hinit;
    else
        H = 2 * full(sqrt(mean(mean(A)) / k)) * rand(n, k);
    end
    if isfield(params, 'maxiter')
        maxiter = params.maxiter;
    else
        maxiter = 10000;
    end
    if isfield(params, 'tol')
        tol = params.tol;
    else
        tol = 1e-3;
    end
    if isfield(params, 'alpha') & params.alpha >= 0
        alpha = params.alpha;
    else
        alpha = max(max(A))^2;
    end
    if isfield(params, 'computeobj')
        computeobj = params.computeobj;
    else
        computeobj = true;
    end
    if isfield(params, 'debug')
        debug = params.debug;
    else
        debug = 0;
    end
end

W = H;
I_k = alpha * eye(k);

left = H' * H;
right = A * H;
for iter = 1 : maxiter

    W = nnlsm_blockpivot(left + I_k, (right + alpha * H)', 1, W')';
    left = W' * W;
    right = A * W;
    H = nnlsm_blockpivot(left + I_k, (right + alpha * W)', 1, H')';
    tempW = sum(W, 2);
    tempH = sum(H, 2);
    temp = alpha * (H-W);
    gradH = H * left - right + temp;
    left = H' * H;
    right = A * H;
    gradW = W * left - right - temp;

    if iter == 1
        initgrad = sqrt(norm(gradW(gradW<=0|W>0))^2 + norm(gradH(gradH<=0|H>0))^2);
        if debug
            fprintf('init grad norm %g\n', initgrad);
        end
        continue;
    else
        projnorm = sqrt(norm(gradW(gradW<=0|W>0))^2 + norm(gradH(gradH<=0|H>0))^2);
    end
    if projnorm < tol * initgrad
        if debug
            fprintf('final grad norm %g\n', projnorm);
        end
        break;
    else
        if debug > 1
            fprintf('iter %d: grad norm %g\n', iter, projnorm);
        end
    end

end % for iter = 1 : maxiter

if alpha == 0
    norms_W = sum(W.^2) .^ 0.5;
    norms_H = sum(H.^2) .^ 0.5;
    norms = sqrt(norms_W .* norms_H);
    W = bsxfun(@times, W, norms./norms_W);
    H = bsxfun(@times, H, norms./norms_H);
end

if computeobj
    obj = norm(A, 'fro')^2 - 2 * trace(W' * (A*H)) + trace((W'*W) * (H'*H));
else
    obj = -1;
end

end % function
