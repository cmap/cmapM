function varargout = mortarver
% MORTARVER Version information for MORTAR
%   MORTARVER displays current version information.
%   V = MORTARVER returns a structure containing the version information.

v = parse_param(fullfile(mortarpath, 'resources/mortar_release.txt'));

if nargout>0
    varargout{1} = v;
else
    fprintf('%s %s (%s)\n', v.Name, v.Version, v.Release)
end
