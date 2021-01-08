function x = scale_matrix(x, cen, sc)
% SCALE_MATRIX scale and center a numeric matrix
%   Y = SCALE_MATRIX(X, C, S) Adjusts numeric matrix X based on centering
%   and scaling specified by C and S. C can be a logical value or a numeric
%   vector of length equal to the number of columns of X. S can be either a
%   logical value or a numeric vector of length equal to the number of
%   columns of X.
%
% The value of C determines how column centering is performed. If C is a
% numeric vector with length equal to the number of columns of X, then each
% column of X has the corresponding value from C subtracted from it. If C
% is true then centering is done by subtracting the column means (omitting
% NaNs) of X from their corresponding columns, and if center is false, no
% centering is done.
%
% The value of S determines how column scaling is performed (after
% centering). If S is a numeric vector with length equal to the number
% of columns of X, then each column of X is divided by the corresponding
% value from S. If S is true then scaling is done by dividing the
% (centered) columns of X by their standard deviations if center is TRUE,
% and the root mean square otherwise. If S is FALSE, no scaling is
% done.
%
% The root-mean-square for a (possibly centered) column is defined as,
%                   sqrt(nansum(x.^2, 1)./(n-1))
% where x is a vector of the non-missing values and n is the number of
% non-missing values. In the case center = TRUE, this is the same as the
% standard deviation, but in general it is not. (To scale by the standard
% deviations without centering, use SCALE_MATRIX(X, false, nanstd(X, 0, 1)).)
%
% This function mirrors the R scale function
% https://www.rdocumentation.org/packages/base/versions/3.4.3/topics/scale


narginchk(1, 3)
nin = nargin;
if nin < 2
    cen = true;
    sc = true;
elseif nin < 3
    sc = true;
end

[~, nc] = size(x);
do_center = false;
do_scale = false;

if islogical(cen) && all(cen)
    cen = nanmean(x, 1);
    do_center = true;
elseif ~islogical(cen)
    assert(isequal(length(cen), nc),...
        ['Expected CEN to be logical or a vector matching ',...
        'number of columns of X, got vector of length %d ',...
        'instead'], length(cen));
    do_center = true;
end
if do_center
    x = bsxfun(@minus, x, cen);
end

if islogical(sc) && all(sc)
    if isequal(cen, true)
        sc = nanstd(x, 0, 1);
    else
        % Root mean square
        sc = sqrt(nansum(x.^2, 1)./(sum(~isnan(x), 1)-1));
    end
    do_scale = true;
elseif ~islogical(sc)
    assert(isequal(length(sc), nc),...
        ['Expected SC to be logical or a vector matching ',...
        'number of columns of X, got vector of length %d ',...
        'instead'], length(sc));
    do_scale = true;
end
if do_scale
    x = bsxfun(@rdivide, x, sc);
end

end