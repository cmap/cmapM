function [bd, idose, delta_pct, dose_unit] = discretize_doses(d, dose_bins_um, tol_pct, idose_fmt)
% DISCRETIZE_DOSES Canonicalize raw treatment doses to specified bins
% [BD, IDOSE, E] = DISCRETIZE_DOSES(D, BINS, TOL, FMT) returns BD a
% discretized version of doses D, a vector of doses in micromolar units
% into BINS. TOL is the tolerance for relative error E expressed as a percentage
% i.e. E = 100 * abs(BD - D) / D. In cases where E > TOL the original dose
% value is retained in BD. FMT is the format string used to generate a cell
% string array IDOSE. 
%
% Example:
% pert_dose = [-666, 9.9, 2.4, 2.2, 1.0, nan]';
% bins = (exp(log(10)-((0:6)*log(4))))';
% [bd, idose, delta] = discretize_doses(pert_dose, bins, 10, '%2.4g');

d = d(:);
dose_bins_um = dose_bins_um(:);

% handle missing values
d = nan_to_val(d, -666);
% include placeholder dose for negative / nan values
dose_bins_um = union(dose_bins_um, -666, 'stable');

bd = discretize(d, dose_bins_um);

% relative error
delta_pct = 100 * abs(d - bd) ./ abs(d);
is_outside_tol = delta_pct > tol_pct;
bd(is_outside_tol) = d(is_outside_tol);

% generate cell strings
idose = num2cellstr(bd, 'fmt', idose_fmt);
is_pos_dose = bd>0;
idose(is_pos_dose) = strcat(idose(is_pos_dose), ' uM');
% set idose for negative doses to missing 
idose(~is_pos_dose) = {'-666'};
dose_unit = cell(size(idose));
dose_unit(is_pos_dose) = {'uM'};
dose_unit(~is_pos_dose) = {'-666'};

end