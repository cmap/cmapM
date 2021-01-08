function [sed_cmd, is_gnu_sed] = get_sed_cmd
% GET_SED_CMD Search for SED command on the operating system
% [SED_CMD, IS_GNU_SED] = GET_SED_CMD() 

if ismac
    % see if GNU-Sed exists
    [is_gnu_sed, sed_cmd] = get_sed_path('gsed');
    if is_gnu_sed
        [status, result, is_valid_result] = check_sed(sed_cmd);
    else
        % fall back to native version
        is_gnu_sed = false;
        [found_sed, sed_cmd] = get_sed_path('sed');
        [status, result, is_valid_result] = check_sed(sed_cmd);
    end    
else
    [is_gnu_sed, sed_cmd] = get_sed_path('sed');
    % see if GNU-Sed exists
    [status, result, is_valid_result] = check_sed(sed_cmd);     
end

if ~is_valid_result
    sed_cmd = '';
    is_gnu_sed = false;
end

end

function [found_sed, sed_path] = get_sed_path(sed_cmd)
[status, result]=system(sprintf('which %s', sed_cmd));
found_sed = status == 0;
if found_sed
    sed_path = deblank(result);
else
    sed_path = '';
end

end

function [status, result, is_valid_result] = check_sed(sed_cmd)
[status, result] = system(sprintf('echo ''second\nthird''|%s ''1s/^/first\\\n/''', sed_cmd));
is_valid_result = strcmp(sprintf('first\nsecond\nthird\n'), result);
end