% BMTKPATH Get location of BMTK library
function p = mortarpath

if exist('BMTKPATH','var')
    p = BMTKPATH;
else
    p = strrep(which(mfilename), sprintf('/util/%s.m',mfilename), '');
    
end
