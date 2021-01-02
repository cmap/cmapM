function log(fid, s, varargin)
% LOG Print a string.
% LOG(FID, S, arg1, arg2) prints S to console if FID is true. if S is a
% string, it is evaluated with optional arguments if provided. If S is an
% MException object, the stacktrace is printed. If FID is a string, outputs
% the message to a file specified by FID.
%   Examples:
%   log(1, 'file loaded: %s', 'foo.txt')
%   log('success.txt', 'file loaded: %s', 'foo.txt')
%   log(1, me)

if isa(s, 'MException')
    % Exception object provided, get stack trace
    str = getReport(s, 'extended');
    iserror = true;
else
    % assemble provided message
    str = feval(@sprintf, s, varargin{:});
    iserror = false;
end

if ischar(fid)
    % write to file
    fid = fopen(fid, 'wt');
    isfile = true;
elseif islogical(fid)
    fid = double(fid);
    isfile = false;
else
    isfile = false;
end

if fid > 0
    if iserror && ~isfile
        % standard error if error object
        fid = 2;
    end
    fprintf(fid, '-[%s]-: %s\n', datestr(now), str);
end
    
if isfile
    fclose(fid);    
end

end
