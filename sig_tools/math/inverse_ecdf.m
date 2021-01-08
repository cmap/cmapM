function fq = inverse_ecdf(varargin)
% Compute inverse cumulative distribution for an empirical distribution
% FQ = INVERSE_ECDF(V, VQ) returns an array of values of the inverse
% cumulative distribution function for the empirical distribution specified
% by values V evaluated for values in VQ
% 
% FQ = INVERSE_ECDF(V, VQ, 'Param', 'Value',...) Specify optional
% parameters. See INVERSE_ECDF('help') for details
%
% Example:
% V = rand(1000, 1);
% VQ = [0.33, 0.75];
% FQ = INVERSE_ECDF(V, VQ)

config = struct('name', {'v', 'vq', '--interp_method'},...
                  'default', {[], [], 'linear'},...
                  'choices', {{},{},{'linear','nearest','next','previous','spline','pchip','cubic','vcubic'}},...
                  'help', {'values of distribution', 'values to evaluate', 'Interpolation method. See INTERP1 for details'});
opt = struct('prog', mfilename, 'desc', 'Compute the inverse empirical CDF');
[args, help_flag] = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

if ~help_flag
    [f, x] = cdfcalc(args.v);
    fq = interp1(x, f(1:end-1), args.vq, args.interp_method);
else
    fq = nan;
end
end