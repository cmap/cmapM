function [f_val, coord_label] = get_cdf_values(x, f, x_val)
% GET_CDF_VALUES lookup empirical CDF values 
%   [FV, S] = GET_CDF_VALUES(X, F, XV) X and F are outputs of the ECDF
%   function. XV is a vector of X values to lookup. FV are the ECDF values
%   corresponding to XV. S a cell array of strings with XV,FV cooordinates.

nuniq = length(unique(x));
if nuniq>1
    f_val = interp1(x(2:end), f(2:end), x_val);
else
    warning('ECDF has too few elements. Skipping intrapolation and setting to Max F')
    f_val = ones(size(x_val))*max(f);
end
coord_label = tokenize(sprintf('(%d, %2.2f)#',[x_val, f_val]'),'#');
coord_label = coord_label(1:end-1);
end