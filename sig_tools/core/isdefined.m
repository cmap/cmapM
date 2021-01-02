function status = isdefined(varname)
% ISDEFINED Test if a variable is defined.
%   ISDEFINED(VARNAME) Returns 1 if VARNAME is defined in the caller
%   workspace, 0 if not.

if isequal(nargin,1) && ischar(varname)
    status = evalin('caller', sprintf('exist(''%s'', ''var'')', varname));
end
end