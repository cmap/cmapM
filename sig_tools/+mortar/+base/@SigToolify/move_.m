function move_(obj, varargin)
% edit_ Edit boilerplate files for a sig tool

nin = nargin;

opt = struct('FullClassName', '',...
    'PackageName', obj.SigToolPackage,...
    'ClassName', '',...
    'ToolName', '',...
    'Desc', '');

new = opt; 

if nin>=2
    assert(validateSigClass(varargin{1}), 'Invalid Sig ClassName');
    opt.ClassName = varargin{1};
    opt.FullClassName = sprintf('%s.%s', opt.PackageName, opt.ClassName);
    opt.ToolName = getToolName(opt.ClassName);
else
    % Interactive
    sigTools = obj.list_;
    nTools = numel(sigTools);
    if nTools
        obj.printList_;
        reply = getInput(sprintf('Enter index of Sig Tool to rename [1-%d]:', nTools),...
            @validateToolIndex, nTools);
        idx = floor(str2double(reply));
        opt.ClassName = sigTools{idx};
        opt.FullClassName = sprintf('%s.%s', opt.PackageName, opt.ClassName);
        opt.ToolName = getToolName(opt.ClassName);
        
        new.ClassName = getInput(sprintf('Enter new name of %s (must begin with Sig)\nExample: SigHClust\n>', opt.ClassName),...
                        @validateSigClass);
        new.FullClassName = sprintf('%s.%s', new.PackageName, new.ClassName);
        new.ToolName = getToolName(new.ClassName);
    end             
end

% read the manifest
template_path = getTemplatePath;
manifest = parse_tbl(fullfile(template_path, 'manifest.txt'), 'outfmt', 'record');
[~, sigPath] = getOutputFiles(manifest, opt);
[~, newPath] = getOutputFiles(manifest, new);
% open in Editor

%Make new Class Folder
class_path = getClassPath(opt.PackageName, opt.ClassName);
new_path = getClassPath(new.PackageName, new.ClassName);
if ~mortar.util.File.isfile(new_path, 'dir')
    mkdir(new_path);
end

%Move files to new Class with new name
for i=1:numel(sigPath)
    movefile(sigPath{i}, newPath{i})
end

%Delete old Class Folder
if mortar.util.File.isfile(class_path, 'dir')
    rmdir(class_path);
end




for ii=1:numel(sigPath)
    if ~matlab.desktop.editor.isOpen(sigPath{ii})
        doc = matlab.desktop.editor.openDocument(sigPath{ii});
    end
end

for ii=1:numel(sigPath)
    edit(sigPath{ii});
end

end

function tf = validateToolIndex(reply, n)
idx = floor(str2double(reply));
assert(idx>0 && idx <= n, 'Expected a value between 1 and %d', n)
tf = true;
end

function tf = validateSigClass(class_name)
% Class name should begin with Sig
assert(~isempty(regexp(class_name, '^Sig', 'once')),...
    'Class Name %s should begin with Sig', class_name);
tf = true;
end


