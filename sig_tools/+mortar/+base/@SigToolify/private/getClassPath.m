function class_path = getClassPath(package_name, class_name)
% GETCLASSPATH(package_name, class_name) Path to class 
class_path = fullfile(mortarpath, ['+', strrep(package_name, '.', [filesep,'+'])],['@',class_name]);
end
