function [package_name, class_name] = classNameParts(full_class_name)
[~, package_name, class_name_ext] = fileparts(full_class_name);
class_name = strrep(class_name_ext, '.' ,'');
end
