function x = nan_to_val(x, nanval)
% NAN_TO_VAL Replace NaNs with a scalar value
%   Y = NAN_TO_VAL(X, V) Replaces NaN values in X with the scalar V

assert(isscalar(nanval), 'Value should be a scalar');
assert(isnumeric(nanval), 'Value should be numeric');

if ~isnan(nanval)
    inan = isnan(x);
    x(inan) = nanval;
end
end
