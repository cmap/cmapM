function edit_(obj, varargin)
% edit_ Edit boilerplate files for a sig tool

nin = nargin;

opt = struct('FullClassName', '',...
    'PackageName', obj.SigToolPackage,...
    'ClassName', '',...
    'ToolName', '',...
    'Desc', '');

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
        reply = getInput(sprintf('Enter index of Sig Tool to edit [1-%d]:', nTools),...
            @validateToolIndex, nTools);
        idx = floor(str2double(reply));
        opt.ClassName = sigTools{idx};
        opt.FullClassName = sprintf('%s.%s', opt.PackageName, opt.ClassName);
        opt.ToolName = getToolName(opt.ClassName);        
    end             
end

% read the manifest
template_path = getTemplatePath;
manifest = parse_tbl(fullfile(template_path, 'manifest.txt'), 'outfmt', 'record');
[~, sigPath] = getOutputFiles(manifest, opt);
% open in Editor
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


