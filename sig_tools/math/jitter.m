function r = jitter(x, varargin)
% JITTER Add a small amount of noise to a numeric vector.

pnames = {'--factor'; '--amount'};
dflts = {1; nan};
help_str = {'scale factor'; 'Amount of jitter'};
config = struct('name', pnames,...
    'default', dflts,...
    'help', help_str);
opt = struct('prog', mfilename,...
             'desc', 'Add a small amount of noise to a numeric vector.');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

if isnan(args.amount)
    min_d = min(diff(x(:)));
    a = args.factor * min_d / 5;
elseif abs(args.amount-0)<eps
    z = max(x(:)) - min(x(:));
    a = args.factor * z / 50;
else
    a = args.amount;
end

sz = size(x);
r = x + a + 2*a*rand(sz);

end