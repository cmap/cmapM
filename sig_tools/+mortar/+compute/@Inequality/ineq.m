function m = ineq(x, varargin)
% INEQ Compute inequality measures
% M = INEQ(X) returns the Gini coefficient of columns of X
%   M = INEQ(X, 'param1', value1,...) specify optional paramters
%   'dim' : valid 2d-dimension {1,2, 'row', 'column'}. dimension to operate
%           on. Default is 'column'
%   'type' : string, Inequality metric to use. choices ares:
%               'gini' : Gini coefficient 
%                        See https://en.wikipedia.org/wiki/Gini_coefficient
%               'atkinson' : Atkinson index
%                            See: https://en.wikipedia.org/wiki/Atkinson_index
%   'sample_correction' : boolean, apply correction for finite samples when
%                         computing Gini coefficients
%   'parameter' : scalar, parameter for each inequality metric. If empty or
%                not specified, the default parameter for each metric is
%                used. Default is empty
%
%
% Note: This is a Matlab port of gini from the R ineq package
% https://cran.r-project.org/web/packages/ineq/index.html

names = {'--dim', '--type', '--sample_correction',...
         '--parameter'};
dflts = {'column', 'gini', false, []};
choices = {{}, {'gini', 'atkinson', 'gini_lorenz', 'gini_weighted'}, {true, false}, {}};
config = struct('name', names, 'default', dflts, 'choices', choices);
opt = struct('prog', mfilename,...
    'desc', 'Inequality indices',...
    'undef_action', 'error');
args = mortar.common.ArgParse.getArgs(config, opt, varargin{:});

[dim_str, dim_val] = get_dim2d(args.dim);

y = sort(x, dim_val);
[nr, nc] = size(y);


if isequal(dim_str, 'column')    
    nnan = sum(isnan(y), 1);
    n = nr - nnan;
    nel = nr;
else
    y = y';
    nnan = sum(isnan(y), 1);
    n = nc - nnan;
    nel = nc;    
end

if args.sample_correction
    ncorr = n - 1;
else
    ncorr = n;
end

switch args.type
    case 'gini'
        % based on R's ineq package implementation
        % Nan friendly version
        m = ((2 * nansum(bsxfun(@times, y, (1:nel)'), 1)) ./ (ncorr .* nansum(y, 1)) - (n + 1)./ncorr)';        
        % m = 2./(nr*(nr-1)*mean(y, 1)) .* sum(bsxfun(@times, y, (1:nr)'), 1) - (nr+1)/(nr-1);
        %
        % m = sum(bsxfun(@times, y, (2*(1:nr)' - nr -1)), 1) ./ (nr^2 * mean(y, 1));
    case 'gini_lorenz'
        m = gini_index(y);        
    case 'atkinson'
        m = atkinson(y, args.parameter);
    otherwise
        error('Unknown metric %s', args.type);
end

end

function A = atkinson(x, aversion)
% Atkinson index 

% default aversion
if isempty(aversion)
    aversion = 0.5;
end

if (abs(aversion-1)<eps)
    % aversion = 1
    A = 1 - (exp(nanmean(log(x)))./nanmean(x))';
else
    %x = (x./nanmean(x)).^(1-aversion);
    x = bsxfun(@rdivide, x, nanmean(x)).^(1-aversion);
    A = 1 - nanmean(x)'.^(1/(1-aversion));
end
end

function gi = gini_index(x)
% Andrea's implementation that estimates the area under the Lorenz curve

nr = size(x,1);
z = sort(abs(x),1,'ascend');

x_pctfrac = (1:nr)'/nr;
y_pctfrac = bsxfun(@rdivide,z,max(z,[],1));

%area under Lorenz curve
B = trapz(x_pctfrac, y_pctfrac);

% Gini index
gi = 1 - 2*B;

end

