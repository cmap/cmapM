function [out_file, out_path, class_path] = getOutputFiles(manifest, opt)
% GETOUTPUTFILES(manifest, opt) Generate output filenames based on template manifest
nf = length(manifest);
base_path = mortarpath;
class_path = getClassPath(opt.PackageName, opt.ClassName);
out_file = {manifest.template_file}';
out_path = {manifest.template_file}';


for ii=1:nf
    if ~isequal(manifest(ii).replace_string, 'na')
        out_file{ii} = regexprep(manifest(ii).template_file, '__.*__', opt.(manifest(ii).replace_string));
    end
    if isequal(manifest(ii).target_folder, 'class')
        out_path{ii} = fullfile(class_path, out_file{ii});
    else
        out_path{ii} = fullfile(base_path, manifest(ii).target_folder, out_file{ii});
    end
    
end
end