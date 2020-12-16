function argpath = getArgPath(mfname, mfclass)
% GETARGPATH return path to arguments file
% getArgPath(mfname, mfclass)
if isempty(mfclass)
    argpath = fullfile(mortarpath, 'resources', [mfname, '.arg']);
else
    argpath = fullfile(mortarpath, 'resources',...
        [mfclass, '.', mfname, '.arg']);
end
end