function ut = URIType(URI)
% URI_TYPE Type of URI (Uniform resource identifier)
% UT = URI_TYPE(URI) Returns the type of URI as a string.
% Can be 'http', 's3', 'fileuri' 'file'
if ~isempty(regexpi(URI, '^https?://'))
    ut = 'http';
elseif ~isempty(regexpi(URI, '^s3?://'))
    ut = 's3';
elseif ~isempty(regexpi(URI, '^file?://'))
    ut = 'fileuri';
elseif cmapm.util.File.isfile(URI, 'file')
    ut = 'file';
else
    ut = '';
end
end