function [H, iter, obj] = symnmf_newton(A, k, params)
%SYMNMF_NEWTON Newton-like algorithm for Symmetric NMF (SymNMF)
%   [H, iter, obj] = symnmf_newton(A, k, params) optimizes
%   the following formulation:
%
%   min_H f(H) = ||A - HH'||_F^2 subject to H >= 0
%
%   where A is a n*n symmetric matrix,
%         H is a n*k nonnegative matrix.
%         (typically, k << n)
%   'symnmf_newton' returns:
%       H: The low-rank n*k matrix used to approximate A.
%       iter: Number of iterations before termination.
%       obj: Objective value f(H) at the final solution H.
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
%            (default is 1e-4)
%       sigma: The acceptance parameter 'sigma' in the cited paper,
%              to be used in the Armijo rule.
%              (default is 0.1)
%       beta: The reduction factor 'beta' in the cited paper,
%             to decrease the step size of gradient search.
%             (default is 0.1)
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
%   This function is developed in the following paper:
%       Da Kuang, Chris Ding, Haesun Park,
%       Symmetric Nonnegative Matrix Factorization for Graph Clustering,
%       The 12th SIAM International Conference on Data Mining (SDM '12), pp. 106--117.
%   Please cite this paper if you find this code useful.
%

n = size(A, 1);
if n ~= size(A, 2)
    error('A must be a symmetric matrix!');
end

if ~exist('params', 'var')
    H = 2 * full(sqrt(mean(mean(A)) / k)) * rand(n, k);
    maxiter = 10000;
    tol = 1e-4;
    sigma = 0.1;
    beta = 0.1;
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
        tol = 1e-4;
    end
    if isfield(params, 'sigma')
        sigma = params.sigma;
    else
        sigma = 0.1;
    end
    if isfield(params, 'beta')
        beta = params.beta;
    else
        beta = 0.1;
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

projnorm_idx = false(n, k);
R = cell(1, k);
p = zeros(1, k);
left = H'*H;
obj = norm(A, 'fro')^2 - 2 * trace(H' * (A*H)) + trace(left * left);
gradH = 4 * (H * (H'*H) - A*H);
initgrad = norm(gradH, 'fro');
if debug
    fprintf('init grad norm %g\n', initgrad);
end

for iter = 1 : maxiter

gradH = 4*(H*(H'*H) - A*H);
projnorm_idx_prev = projnorm_idx;
projnorm_idx = gradH<=eps | H>eps;
projnorm = norm(gradH(projnorm_idx));
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

if mod(iter, 100) == 0
    p = ones(1, k);
end
  
step = zeros(n, k);
hessian = cell(1, k);
temp = H*H' - A;

for i = 1 : k
    if ~isempty(find(projnorm_idx_prev(:, i) ~= projnorm_idx(:, i), 1))
        hessian{i} = hessian_blkdiag(temp, H, i, projnorm_idx);
        [R{i}, p(i)] = chol(hessian{i});
    end
    if p(i) > 0
        step(:, i) = gradH(:, i);
    else
        step_temp = R{i}' \ gradH(projnorm_idx(:, i), i);
        step_temp = R{i} \ step_temp;
        step_part = zeros(n, 1);
        step_part(projnorm_idx(:, i)) = step_temp;
        step_part(step_part > -eps & H(:, i) <= eps) = 0;
        if sum(gradH(:, i) .* step_part) / norm(gradH(:, i)) / norm(step_part) <= eps
            p(i) = 1;
            step(:, i) = gradH(:, i);
        else
            step(:, i) = step_part;
        end
    end
end

alpha_newton = 1;
Hn = max(H - alpha_newton * step, 0);
left = Hn'*Hn;
newobj = norm(A, 'fro')^2 - 2 * trace(Hn' * (A*Hn)) + trace(left * left);
if newobj - obj > sigma * sum(sum(gradH .* (Hn-H)))
    while true
        alpha_newton = alpha_newton * beta;
        Hn = max(H - alpha_newton * step, 0);
        left = Hn'*Hn;
        newobj = norm(A, 'fro')^2 - 2 * trace(Hn' * (A*Hn)) + trace(left * left);
        if newobj - obj <= sigma*sum(sum(gradH .* (Hn-H))),
            H = Hn;
            obj = newobj;
            break;
        end
    end
else
    H = Hn;
    obj = newobj;
end % if

end % for iter = 1 : maxiter

if computeobj == false
    obj = -1;
end

end % function

%----------------------------------------------------

function He = hessian_blkdiag(temp, H, idx, projnorm_idx)

[n, k] = size(H);
subset = find(projnorm_idx(:, idx) ~= 0); 
hidx = H(subset, idx);
eye0 = (H(:, idx)' * H(:, idx)) * eye(n);

He = 4 * (temp(subset, subset) + hidx * hidx' + eye0(subset, subset));

end % function
