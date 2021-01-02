% BMTKVER Version information for BMTK
%   BMTKVER displays current version information.
%   V = BMTKVER returns a structure containing the version information.

function varargout = mortarver

v = struct('Name', 'Broad Matlab Toolkit', ...
    'Version', '1.2',...
    'Release', 'Bonnaroo Buzz',...
    'Date', '20-Nov-2011');

if nargout>0
    varargout{1} = v;
else
    fprintf('%s Version %s (%s)\n', v.Name, v.Version, v.Release)
end
