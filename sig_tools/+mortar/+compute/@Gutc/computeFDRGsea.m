function [qval, num, denom] = computeFDRGsea(ncs_all, is_null, ncs_q, apply_null_adjust, apply_smooth)
% computeFDRGsea Compute FDR q-values as in the GSEA paper (Sumbramanian A. et al. 2005).
% [qval, num, denom] = computeFDRGsea(ncs_all, is_null, ncs_q, apply_null_adjust, apply_smooth)
% ncs_all : 1d vector of normalized connectivity scores
% is_null : boolean vector of same size as ncs_all indicating null scores
% ncs_q : scores values to evaluate, if empty all ncs_all  is evaluated
% apply_null_adjust : linearly interpolate q-values for scores exceeding
% the null distribution
% apply_smooth : ensure q-values are monotonic with respect to the NCS scores
%
% Reference: See the Multiple Hypothesis Testing section in
% Subramanian, A. et al. Gene set enrichment analysis: a knowledge-based
% approach for interpreting genome-wide expression profiles. Proc. Natl.
% Acad. Sci. U. S. A. 102, 15545?15550 (2005)

assert(mortar.util.Array.is1d(ncs_all), 'NCS_ALL must be a 1d array');
assert(isequal(size(ncs_all), size(is_null)), 'IS_NULL must have same dimensions of NCS_ALL');
assert(islogical(is_null), 'IS_NULL must be boolean');
assert(isempty(ncs_q) || mortar.util.Array.is1d(ncs_q), 'ncs_q must be empty or a 1d array');
assert(isscalar(apply_null_adjust) && islogical(apply_null_adjust), 'APPLYNULL_ADJUST must be a boolean scalar');
assert(isscalar(apply_null_adjust) && islogical(apply_smooth), 'APPLY_SMOOTH must be a boolean, scalar');

if isempty(ncs_q)
    ncs_q = ncs_all;
end

is_pos = ncs_all > 0;
is_neg = ncs_all < 0;
is_pos_trt = is_pos & ~is_null;
is_pos_null = is_pos & is_null;
is_neg_trt = is_neg & ~is_null;
is_neg_null = is_neg & is_null;
is_pos_q = ncs_q > 0;
is_neg_q = ncs_q < 0;

qval = ones(size(ncs_q));
num = ones(size(ncs_q));
denom = ones(size(ncs_q));

if nnz(is_pos_trt)>2 && nnz(is_pos_null)>2
    % positive scores, use the right tail of the distribution
    [qval(is_pos_q), num(is_pos_q), denom(is_pos_q)] = fdr_core(ncs_all(is_pos_trt),...
        ncs_all(is_pos_null),...
        ncs_q(is_pos_q), true, apply_null_adjust, apply_smooth);
end
if nnz(is_neg_trt)>2 && nnz(is_neg_null)>2
    % negative scores, use the left tail
    [qval(is_neg_q), num(is_neg_q), denom(is_neg_q)] = fdr_core(ncs_all(is_neg_trt),...
        ncs_all(is_neg_null),...
        ncs_q(is_neg_q), false, apply_null_adjust, apply_smooth);
end

end

function [qval, num, denom] = fdr_core(x_trt, x_null, xq, use_right_tail, apply_null_adjust, apply_smooth)

% distributions of treatment and null scores
[f_trt, v_trt] = cdfcalc(x_trt);
[f_null, v_null] = cdfcalc(x_null);

% lookup quantiles of xq in both distributions
interp_method = 'pchip';
trt_quantile = interp1(v_trt, f_trt(1:end-1),...
    clip(xq, min(v_trt), max(v_trt)),...
    interp_method);
null_quantile = interp1(v_null, f_null(1:end-1),...
    clip(xq, min(v_null), max(v_null)),...
    interp_method);

% compute FDR q-values
if use_right_tail
    num = (1 - null_quantile);
    denom = (1 - trt_quantile) + eps;
    qval = clip(num ./ denom, eps, 1);    
else
    num = null_quantile;
    denom = trt_quantile + eps;
    qval = clip(num ./ denom, eps, 1);
    
end

% Adjust cases where treatment scores exceed the null distribution.
if apply_null_adjust
    qval = null_adjust(qval, xq, use_right_tail);
end

% Smooth q-values to be monotonic wrt to ncs
if apply_smooth
    qval = smooth_fdr(qval, xq, use_right_tail);
end
end

function qval = smooth_fdr(qval, ncs, use_right_tail)
% Smooth q-values to be monotonic wrt to ncs
if use_right_tail
    sort_order = 'ascend';
else
    sort_order = 'descend';
end
[~, srt_idx] = sort(ncs, sort_order);
nval = numel(qval);
qval_sort = qval(srt_idx);
last_q = qval_sort(1);
for ii=2:nval
    if (qval_sort(ii) < last_q)
        last_q = qval_sort(ii);
    end
    if (last_q < qval_sort(ii))
        qval(srt_idx(ii)) = last_q;
    end
end

end

function qval = null_adjust(qval, xq, use_right_tail)
% Adjust cases where treatment scores exceed the null distribution.
% In this region all the raw q-values are zero. 
if use_right_tail
    %edge_idx = xq > v_null(end);
    edge_idx = xq > xq(imin(qval));
    if any(edge_idx)
        [x0, min_idx] = min(xq(edge_idx));
        q_tmp = qval(edge_idx);
        y0 = q_tmp(min_idx);
        x1 = max(xq);
        y1 = eps;
        m = (y1 - y0) / (eps+(x1 - x0));
        c = -m*x1;
        to_fix = xq >= x0;
        qval(to_fix) = (m*xq(to_fix)+c);
    end
else
    %edge_idx = xq < v_null(1);
    edge_idx = xq < xq(imin(qval));
    if any(edge_idx)
        [x0, max_idx] = max(xq(edge_idx));
        q_tmp = qval(edge_idx);
        y0 = q_tmp(max_idx);
        x1 = min(xq);
        y1 = eps;
        m = (y1 - y0) / (eps+(x1 - x0));
        c = -m*x1;
        to_fix = xq <= x0;
        qval(to_fix) = (m*xq(to_fix)+c);
    end
end

end