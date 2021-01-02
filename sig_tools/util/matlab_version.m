% MATLAB_VERSION matlab version string
%   V = MATLAB_vERSION returns the version number as a string.
%
% See also VERSION
%

% $Author: Rajiv Narayan [narayan@broadinstitute.org]
% $Date: Jul.01.2010 12:01:46 EDT
function matver = matlab_version
    v = version;
    
    %get the version number
    vn = sscanf(v,'%d.%d');
    
    %return version number as a string
    matver=sprintf('%d.%d',vn);
