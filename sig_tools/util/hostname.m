function hn = hostname
% HOSTNAME Determine the name of the host computer
%   HN = HOSTNAME Returns the name of the host computer. Works
%   cross-platform.

hn = '';
if isunix && ~ismac
    hn = getenv('HOSTNAME');
elseif ismac
    [s,r]=system('hostname');
    if isequal(s, 0 )
        hn = deblank(r);
    end    
elseif ispc
    hn = getenv('COMPUTERNAME');
end
    
end