function delete_(obj, varargin)
% delete_ Delete boilerplate files for a sig tool

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
        reply = getInput(sprintf('Enter index of Sig Tool to delete [1-%d]:', nTools),...
            @validateToolIndex, nTools);
        idx = floor(str2double(reply));
        opt.ClassName = sigTools{idx};
        opt.FullClassName = sprintf('%s.%s', opt.PackageName, opt.ClassName);
        opt.ToolName = getToolName(opt.ClassName);        
    end             
end

yn = inputYes(sprintf('-*WARNING*- Do you really want to delete %s? (Y/N):', opt.ClassName));
if yn
    % read the manifest
    template_path = getTemplatePath;
    manifest = parse_tbl(fullfile(template_path, 'manifest.txt'), 'outfmt', 'record');
    [~, sigPath, classPath] = getOutputFiles(manifest, opt);
    
    % delete files
    for ii=1:numel(sigPath)
        if mortar.util.File.isfile(sigPath{ii})
            dbg(1, 'Deleting %s', sigPath{ii});
            delete(sigPath{ii});
        else
            dbg(1, 'Missing file, skipped: %s', sigPath{ii});
        end
    end
    % delete SigClass folder, along with any contents
    if mortar.util.File.isfile(classPath, 'dir')
        dbg(1, 'Deleting class folder: %s', classPath);
        rmdir(classPath, 's');
    end
end
end

function tf = validateToolIndex(reply, n)
idx = floor(str2double(reply));
assert(idx>0 && idx < n, 'Expected a value between 1 and %d', n)
tf = true;
end

function tf = validateSigClass(class_name)
% Class name should begin with Sig
assert(~isempty(regexp(class_name, '^Sig', 'once')),...
    'Class Name %s should begin with Sig', class_name);
tf = true;
end


