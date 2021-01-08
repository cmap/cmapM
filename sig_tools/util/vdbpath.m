function [p, does_path_exist] = vdbpath
% VDBPATH Get location of virtual-db 
default_path = '/cmap/data/vdb';

p = getenv('VDBPATH');
if isempty(p)
    % fallback to default
    if (isdirexist(default_path))
        p = default_path;
    else
        error('The VDBPATH environment variable is not set, use the set_vdbpath script to set it');
    end
end

does_path_exist = isdirexist(p);
if ~does_path_exist
    warning('VDBPATH: %s not found', p)
end

end