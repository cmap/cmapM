function f = fscore(tpr, ppv, beta)
% FSCORE Compute the F-Score 
%   F = FSCORE(TPR, PPV, BETA) returns the F-score for TPR (recall) and PPV
%   (precision). TPR and PPV must be 1-dimensional vectors of equal length.
%   BETA is a real, positive scalar. F ranges [0, 1] with 1 implying
%   best classification (perfect precision and recall).
%
%  The F-score is a measure of accuracy of a binary classifier. It takes
%  into account both the True positive rate (recall) and Positive
%  predictive value (precision) of the classification. It is defined as the
%  harmonic mean of precision and recall:
%
%       F = (1 + BETA^2)*(TPR .* PPV)./(TPR + (BETA^2 * PPV))
%
% The parameter BETA specifies relative weighting of precision and recall.
% The following choices of BETA are commonly employed:
%
% Beta=1, F1 score, weighs both recall and precision equally.
% Beta=2, F2 score, weighs recall higher than precision (by placing more
%         emphasis on false negatives).
% Beta=0.5, F0.5 score, weighs recall lower than precision (by attenuating
%         the influence of false negatives).

is_tpr_1d = mortar.util.Array.is1d(tpr);
is_ppv_1d = mortar.util.Array.is1d(ppv);
assert(is_tpr_1d, 'TPR must be a 1D vector');
assert(is_ppv_1d, 'PPV must be a 1D vector');
assert(isequal(length(tpr), length(ppv)),...
    'Length of TPR and PPV must be the same');
assert(isreal(beta) & beta>0, 'Beta must be real positive');

betasq = beta^2;
f = (1 + betasq)*(tpr .* ppv)./(tpr + (betasq * ppv));

end