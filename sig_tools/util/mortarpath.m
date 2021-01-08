function p = mortarpath
% MORTARPATH Get location of Mortar library

if exist('MORTARPATH','var')
    p = MORTARPATH;
else
    p = strrep(which(mfilename), sprintf('%sutil%s%s.m',filesep, filesep, mfilename), '');    
end
end