function ie = isfileexist(fname, ftype)
% ISFILEEXIST Checks if file(s) or folder(s) exist.
%   IE = ISFILEEXIST(FN) Checks for files or directories named FN. FN can
%   be a chararcter string or a character cell array. IE is logical true
%   if the file(s) exist. If FN is a cell array, length(IE) = length(FN). 
%   IE = ISFILEEXIST(FN, FTYPE) specify if FN should be a file, a directory
%   or either. Valid options for FTYPE are:
%       'filedir' checks for files or directories. 
%       'file' checks for only files.
%       'dir' check for only directories.
%   See also EXIST

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:45 EDT

validtypes = {'file','dir','filedir'};
if exist('ftype', 'var')
    if ~isvalidstr(ftype, validtypes)
        error('Unknown type: %s', ftype)
    end
else
    ftype = 'filedir';
end
if iscell(fname)
    nf = length(fname);
    status = false(nf,1);
    for ii=1:nf
        status(ii) = isfileexist(fname{ii}, ftype);
%         if ~status(ii)
%             fprintf ('"%s" not found\n', fname{ii});
%         else
%             fprintf ('"%s" found\n', fname{ii});
%         end
    end
    ie = status;
elseif ischar(fname)  
    % file or dir (default)
    ie = exist(fname, 'file')>0;
    switch ftype                    
        case 'file'
            ie = ie & ~isdir(fname);
        case 'dir'
            ie = ie & isdir(fname);
    end
else
    ie = false;
end
