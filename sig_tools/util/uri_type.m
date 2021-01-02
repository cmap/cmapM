function ut = uri_type(URI)
% URI_TYPE Type of URI
% UT = URI_TYPE(URI) Returns the type of URI as a string. 
% Can be 'http', 's3', 'fileuri' 'file'

ut = mortar.common.FileUtil.URIType(URI);

end