function auc = auc_dose(log10d, zs, rectify_sign, do_norm, maxy)
% AUC_DOSE Compute area under dose data
% AUC = AUC_DOSE(LOGD, ZS, RECTIFY, DO_NORM, MAXY) Returns the integral
% under ZS for the log dose range LOGD. LOGD and ZS must be vectors of the
% same length, or LOGD must be a column vector and ZS an array whose first
% non-singleton dimension is length(LOGD). The values contributing to the area
% are determined by RECTIFY_SIGN. If RECTIFY_SIGN = 0 then all ZS values
% are used when computing the area. If RECTIFY_SIGN < 0 all positive ZS
% values are set to 0 and the area is computed using the negative values.
% If RECTIFY_SIGN > 0 only positive ZS values are used after setting
% negative values to 0. DO_NORM is a boolean variable if true normalizes
% the computed AUC by MAXY * (max(LOGD)-min(LOGD)). MAXY is a scalar value
% that is used if DO_NORM is true.

% apply rectification if requested
if rectify_sign<0
    % invert and rectify z-scores
    zs = clip(-zs, 0, inf);
elseif rectify_sign>0
    zs = clip(zs, 0, inf);
end

% scale factor for normalization
if do_norm
    % normalize by total area
    sc = maxy * (max(log10d) - min(log10d));
else
    % no normalization
    sc = 1;
end

auc = trapz(log10d, zs)/sc;

end