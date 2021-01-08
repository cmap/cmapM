function [B, M, RE, CE, GE, RES] = bscore_matrix(X, plate_size, well_col_ord, min_mad)
% BSCORE_MATRIX Compute B-score on a matrix.
% X is a [RxC] matrix that represents an assay readout for one plate of
% data w/o duplicate well ids

well_col_ord = well_col_ord(:);

nr = plate_size(1);
nc = plate_size(2);
nwell = nr*nc;
% features and samples
[nf, ns] = size(X);
% Validate if well_col_ord is within bounds
assert(isequal(ns, length(well_col_ord)),...
    'Length of well vector must match the number of columns of X, Expected %d, got %d instead',...
     ns, length(well_col_ord));
assert(all(well_col_ord>=1 & well_col_ord <= nwell), 'Well Column Order out of bounds');

is_missing_well = ~ismember(well_col_ord, 1:nwell);

% Plate row and column coordinates
[wrow, wcol] = ind2sub(plate_size, well_col_ord);
% bscore
B = nan(nf, ns);
% plate MAD
M = nan(nf, 1);
% Row, column, grand effects and residuals
RE = nan(nf, nr);
CE = nan(nf, nc);
GE = nan(nf, 1);
RES = nan(nf, ns);

for ii=1:nf
    this_x = nan(plate_size);
    % values of feature ii according to plate layout
    this_x(well_col_ord) = X(ii, :);
    [b, m, re, ce, ge, res] = bscore(this_x, min_mad);
    B(ii, :) = b(well_col_ord);
    M(ii) = m;
    RE(ii, :) = re(:);
    CE(ii, :) = ce(:);
    GE(ii) = ge;
    RES(ii, :) = res(well_col_ord);
end

end