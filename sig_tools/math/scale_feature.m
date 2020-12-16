function y = scale_feature(x, method)
% SCALE_FEATURE Apply scaling to features
%   Y = SCALE_FEATURE(X, METHOD)
%    'zero_one' : Scale feature to range [0, 1] by applying 
%       y = (x - x_min)/(x_max - x_min)
%    'pm_one' : Scale feature to range [-1, 1] by applying 
%       y = 2*((x - x_min)/(x_max - x_min)) + 1

min_x = nanmin(x, [], 1);
max_x = nanmax(x, [], 1);

switch(method)
    case 'zero_one'
        % scale to [0,1]
        a = 0;
        b = 1;
    case 'pm_one'
        % scale to [-1, 1]
        a = -1;
        b = 1;
    otherwise
        error('Method:%s not supported', method)
end
y = (b-a)*bsxfun(@rdivide, bsxfun(@minus, x, min_x), max_x - min_x) + a;
end