% DO_XFORM Apply transformation to data.
%   XM = DO_XFORM(M, XFORM)
%   Valid transformations are:
%   'abs' Absolute value
%   'log2' Base 2 Log transform
%   'log' Base e Log tranform
%   'pow2' Power of 2 transform
%   'exp'  Exponential transform
%   'zscore' Zscore transform
%   'none'

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT
function xm = do_xform(m, xform, varargin)

xm=[];
pnames = {'valid_xform', 'verbose'};
dflts = {{'abs','log2','log','pow2','exp','zscore','none'}, false};
args = parse_args(pnames, dflts, varargin{:});

%check if valid zform
xform=lower(xform);
if isempty (strcmp(xform, args.valid_xform))
    error ('Invalid transform specified: %s\n',xform);
end

if args.verbose
    fprintf ('Performing transformation: %s\n',xform);
end

switch(xform)
    case 'abs'
        xm=abs(m);
    case 'log2'
        xm=safe_log2(m);
    case 'log'
        xm=safe_log(m);
    case 'pow2'        
        xm=pow2(m);
    case 'exp'
        xm=exp(m);
    case 'zscore'
        xm=zscore(m);
    case 'none'
        xm=m;
end
