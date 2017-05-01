function p = cmapmpath
% CMAPMPATH Get location of CMAPM library

p = getenv('CMAPMPATH');
if isempty(p)
   error('The CMAPMPATH environment variable is not set, use the setup_env script to set it')
end
end