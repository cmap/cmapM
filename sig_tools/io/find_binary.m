function [file_path, exit_code] = find_binary(file_name)
% FIND_BINARY Serach for binary file in path
%   [FP, EC] = FIND_BINARY(FILE_NAME)

[exit_code, file_path] = system(sprintf('which %s', file_name));
if exit_code == 0 
    file_path = str_deblank(file_path, 'both');
else
    file_path = '';
end

end