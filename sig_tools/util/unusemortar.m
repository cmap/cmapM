% UNUSEMORTAR Remove Mortar from the Matlab search path.

cp = textscan(path, '%s', 'delimiter', pathsep);
currpath = cp{1};
keep = currpath(cellfun(@isempty, regexp(currpath, '/mortar')));
if ~isequal(length(keep), length(currpath))
    usepath = strcat(keep, pathsep);
    usepath = strcat(usepath{:});
    path(usepath);
end
