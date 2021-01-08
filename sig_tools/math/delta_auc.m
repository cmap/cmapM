function zs = delta_auc(zs, veh_cidx, varargin)
% DELTA_AUC Compute differential area under the curve from zscores.
%   DAUC = DELTA_AUC(ZS, VEH_IDX) Returns the delta-AUC values for 
%   ZS is a gct structure, VEH_IDX are the column indices to use to compute
%   the median vehicle z-score. DAUC is a structure with the same
%   dimensions as ZS.
%
%   The delta-AUC for a row i and column j is computed as:
%
%       DAUC(i,j) = scale_factor * (F(ZS(i,j)) - F(ZS_vehicle_median(i)))
%
%   where F is the cumulative distribution function. The cumulative normal
%   with mean 0 and standard deviation 1 is used as default. The scale
%   factor is 10 by default. The DAUC values range from -scale_factor to
%   +scale_factor.
%
%   DAUC = DELTA_AUC(ZS, VEH_IDX, 'param1', value1, ...) Specify optional
%   parameter / value pairs:
%       'cdf':  String, Cumulative distribution function to use. Valid
%       options are {'normal', 'empirical'}. Default is 'normal' cumulative
%       normal distribution with mean 0 and standard deviation 1. If
%       'empirical' is specified, the empirical CDF is computed for each
%       row in ZS using the z-score values from all columns in ZS.
%
%       'scale_factor': scalar, factor used to scale the DAUC. Default is
%       10.

pnames = {'cdftype', 'scale_factor', 'mean', 'std'};
dflts = {'normal', 10, 0, 1};
args = parse_args(pnames, dflts, varargin{:});

[nr, nc] = size(zs.mat);

% threshold raw z-scores
zs.mat = clip(zs.mat, -10, 10);
% vehicle median
veh_med = median(zs.mat(:, veh_cidx), 2);

dbg(1, 'cdftype: %s', args.cdftype);
switch args.cdftype
    case 'normal'        
        zs.mat = args.scale_factor * ...
                    bsxfun(@minus, normcdf(zs.mat, args.mean, args.std),...
                    normcdf(veh_med, args.mean, args.std));
    case 'empirical'        
        % compute empirical cdf
        for ii=1:nr
            [f, x] = ecdf(zs.mat(ii, :));
            pp = interp1(x(2:end), f(2:end), [], 'pp');
            zs.mat(ii, :) = args.scale_factor * ...
                (ppval(pp, zs.mat(ii,:)') - ...
                ppval(pp, veh_med(ii)));
        end
    otherwise
        error('Unknown distribution:%s', args.cdftype)
end
    

end