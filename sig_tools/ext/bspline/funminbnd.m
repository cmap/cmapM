function [xf,fval] = funminbnd(fun,a,b,x0)
% Single-variable bounded nonlinear function minimization.
% This is an updated version of MatLab's fminbnd with excessive removals
% and slight extensions.
%
% Input arguments:
% fun:
%    handle of a single-variable function to minimize
% a:
%    lower bound
% b:
%    upper bound
% x0 (optional):
%    initial value
%
% See also: fminbnd

% Original coding by Duane Hanselman, University of Maine.
% Copyright 1984-2006 The MathWorks, Inc.

validateattributes(fun, {'function_handle'}, {'scalar'});
validateattributes(a, {'numeric'}, {'real','scalar'});
validateattributes(b, {'numeric'}, {'real','scalar'});
if nargin > 3
    validateattributes(x0, {'numeric'}, {'real','scalar'});
else
    x0 = [];
end

tol = 1e-4;    % tolarance
maxfun = 500;  % maximum number of function evaluations

% compute the starting point
seps = sqrt(eps);
c = 0.5*(3.0 - sqrt(5.0));
if ~isempty(x0)
    v = x0;
else
    v = a + c*(b-a);
end
w = v;
xf = v;
d = 0.0;
e = 0.0;
x = xf;
fx = fun(x);
evalcount = 1;  % number of function evaluations

fv = fx;
fw = fx;
xm = 0.5*(a+b);
tol1 = seps*abs(xf) + tol/3.0;
tol2 = 2.0*tol1;

% main loop
while abs(xf-xm) > tol2 - 0.5*(b-a)
    gs = 1;
    if abs(e) > tol1  % is a parabolic fit possible
        gs = 0;
        r = (xf-w)*(fx-fv);
        q = (xf-v)*(fx-fw);
        p = (xf-v)*q-(xf-w)*r;
        q = 2.0*(q-r);
        if q > 0.0
            p = -p;
        end
        q = abs(q);
        r = e;
        e = d;

        if abs(p) < abs(0.5*q*r) && p > q*(a-xf) && p < q*(b-xf)  % is the parabola acceptable
            % parabolic interpolation step
            d = p/q;
            x = xf+d;

            % f must not be evaluated too close to a or b
            if (x-a) < tol2 || (b-x) < tol2
                si = sign(xm-xf) + ((xm-xf) == 0);
                d = tol1*si;
            end
        else  % not acceptable, must do a golden section step
            gs = 1;
        end
    end
    if gs
        % a golden-section step is required
        if xf >= xm
            e = a-xf;
        else
            e = b-xf;
        end
        d = c*e;
    end

    % the function must not be evaluated too close to xf
    si = sign(d) + (d == 0);
    x = xf + si * max( abs(d), tol1 );
    fu = fun(x);
    evalcount = evalcount + 1;  % increment number of function evaluations

    % update a, b, v, w, x, xm, tol1, tol2
    if fu <= fx
        if x >= xf
            a = xf;
        else
            b = xf;
        end
        v = w;
        fv = fw;
        w = xf;
        fw = fx;
        xf = x;
        fx = fu;
    else  % fu > fx
        if x < xf
            a = x;
        else
            b = x;
        end
        if fu <= fw || w == xf
            v = w;
            fv = fw;
            w = x;
            fw = fu;
        elseif fu <= fv || v == xf || v == w
            v = x;
            fv = fu;
        end
    end
    xm = 0.5*(a+b);
    tol1 = seps*abs(xf) + tol/3.0;
    tol2 = 2.0*tol1;

    if evalcount >= maxfun
        fval = fx;
        return
    end
end
fval = fx;
