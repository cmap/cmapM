function u = username
% USERNAME Get username

if isunix
    u = getenv('USER');
else
    u = getenv('username');
end

% Try java if that didnt work
if isempty(u)
    u = char(java.lang.System.getProperty('user.name'));
end
    
end