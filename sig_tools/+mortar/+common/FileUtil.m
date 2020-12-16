classdef FileUtil
    
    methods (Static=true)
        
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
        
        
        function ut = URIType(URI)
            % URIType Type of URI
            % UT = URIType(URI) Returns the type of URI as a string.
            % Can be 'http', 's3', 'fileuri' 'file'            
            if ~isempty(regexpi(URI, '^https?://'))
                ut = 'http';
            elseif ~isempty(regexpi(URI, '^s3?://'))
                ut = 's3';
            elseif ~isempty(regexpi(URI, '^file?://'))
                ut = 'fileuri';
            elseif mortar.common.FileUtil.isfile(URI, 'file')
                ut = 'file';
            else
                ut = '';
            end
        end
        
        function s = encodeURL(url)
            encodeURL URL encode paths of a string delimited by /
            tok = regexp(url, '(https?://)', 'tokens');
            if ~isempty(tok{1})
                prefix = tok{1}{1};
                suffix = strrep(url, prefix, '');
                disp(suffix)
                t2 = tokenize(suffix, '/');                
                for ii=2:numel(t2)
                    t2{ii} = urlencode(t2{ii});
                end
                encoded = print_dlm_line(t2, 'dlm', '/');
                s = strcat(prefix, encoded);
            else
                error('Expected input to start with pattern: https?://');
            end
        end
    end
    
end