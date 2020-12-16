function tf = isfile(fname, ftype)
% Test if argument is a file or folder.
% ISFILE(F) returns 1 if F is a file and 0 otherwise.
% ISFILE(F, FTYPE) specify if F should be a file, a directory
%   or either. Valid options for FTYPE are:
%       'filedir' checks for files or directories. The default.
%       'file' checks for only files.
%       'dir' check for only directories.
if nargin == 1
    ftype = 'filedir';
elseif nargin > 1
    ftype = lower(ftype);
else
    error('Common:FileUtil', 'Invalid inputs');
end

if iscell(fname)
    nf = length(fname);
    tf = false(nf, 1);
    for ii=1:nf
        tf(ii) = mortar.common.FileUtil.isfile(fname{ii}, ftype);
    end
elseif ischar(fname)
    % file or dir (default)
    tf = exist(fname, 'file') > 0;
    switch ftype
        case 'file'
            tf = tf & ~isdir(fname);
        case 'dir'
            tf = tf & isdir(fname);
    end
else
    tf = false;
end
end