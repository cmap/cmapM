function [outText, status] = urltext(URI)
% URLTEXT read text from an HTTP or Amazon S3 object. 
%   S = URLTEXT(URI, OUTPATH) Reads the object specified by URI into a
%   string S
%
% Example: 
%   urlread('s3://data.lincscloud.org/index.html')
%   urlread('http://data.lincscloud.org.s3.amazonaws.com/index.html')

ut = uri_type(URI);

switch(ut)
    case 'file'
        outText = fileread(URI);
        status = 1;
    case {'http'}
        [outText, status] = urlread(mortar.util.File.encodeURL(URI));
    case {'fileuri'}
        [outText, status] = urlread(URI);
    case 's3'
        [outText, status] = mortar.containers.S3.read(URI);
    otherwise
        error('urltext:InvalidURI', 'Invalid URI type for %s', URI);
end

end
