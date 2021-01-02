function new_(obj, varargin)
% new_ Create boilerplate files for a new sig tool.
% When invoked without arguments, will prompt the user for input.
% NEW_(FullClassName, Description) Uses provided arguments to genrate. 
% FullClassName is a fully qualified class name for beginning with mortar.
% For example mortar.compute.SigHClust 

nin = nargin;

opt = struct('FullClassName', '',...
    'PackageName', obj.SigToolPackage,...
    'ClassName', '',...
    'ToolName', '',...
    'Desc', '');

if nin>=3
    assert(validateSigClass(varargin{1}), 'Invalid ClassName');
    opt.ClassName = varargin{1};
    opt.FullClassName = sprintf('%s.%s', opt.PackageName, opt.ClassName);
    opt.ToolName = getToolName(opt.ClassName);    
    assert(validateDesc(varargin{2}), 'Invalid Description');
    opt.Desc = varargin{2};
else
    % Interactive
    opt.ClassName = getInput('Enter name of SigClass (must begin with Sig)\nExample: SigHClust\n>',...
                        @validateSigClass);
    opt.FullClassName = sprintf('%s.%s', opt.PackageName, opt.ClassName);
    opt.ToolName = getToolName(opt.ClassName);
    opt.Desc = getInput(sprintf('Brief description for %s\nExample: Cluster a dataset using hierarchical clustering\n>', opt.ClassName),...
                        @validateDesc);                
end
dbg(1, 'A Sig Tool will be created with following parameters:')
disp(opt);
yn = inputYes('Continue? (Y/N)');

if yn
    if classExists(opt.FullClassName)
        yn = inputYes('Class already exists, Overwrite? (Y/N)');
    end
    if yn
        createSigTool(opt);
        % edit files
        yn = inputYes('Edit boilerplate files? (Y/N)');
        if yn
            obj.edit_(opt.ClassName);
        else
            dbg(1, 'Skipped, you can edit the files anytime by typing:\ntoolify.edit(''%s'')', opt.ClassName);
        end
    else
        dbg(1, 'Skipped');
    end
end

end

function createSigTool(opt)
base_path = mortarpath;
class_path = getClassPath(opt.PackageName, opt.ClassName);
if ~mortar.util.File.isfile(class_path, 'dir')
    mkdir(class_path);
end

template_path = getTemplatePath;
manifest = parse_tbl(fullfile(template_path, 'manifest.txt'), 'outfmt', 'record');
[out_file, out_path] = getOutputFiles(manifest, opt);

% generate boilerplate
add_velocity_jar;

% Initialize Velocity
ve = org.apache.velocity.app.VelocityEngine();
ve.setProperty('file.resource.loader.path', template_path);
%ve.setProperty('velocimacro.library', 'global_macros.vm');
ve.init()
% Create a context and add data 
opt_hashmap = hashmap(fieldnames(opt), struct2cell(opt));
context = org.apache.velocity.VelocityContext();
context.put('opt', opt_hashmap);

[target_folder, imanifest] = getcls({manifest.target_folder});
nt = length(target_folder);
dbg(1, 'Generating boilerplate for %s', opt.ClassName);
for tt=1:nt
    this = find(imanifest==tt);
    nfile = nnz(this);
    dbg(1, '-| %s |-', upper(target_folder{tt}));
    for ii=1:nfile
        idx = this(ii);
%         if isequal(manifest(idx).target_folder, 'class')
%             out_path = fullfile(class_path, out_file{idx});
%         else
%             out_path = fullfile(base_path, manifest(idx).target_folder, out_file{idx});
%         end
        dbg(1, '%s', out_path{idx});
        tpl = ve.getTemplate(manifest(idx).template_file);
        
        fileWriter = java.io.OutputStreamWriter(...
            java.io.FileOutputStream(out_path{idx}));
        tpl.merge(context, fileWriter);
        fileWriter.close();
    end
end
end

function tf = validateDesc(desc)
assert(~isempty(desc), 'Cannot be empty');
tf = true;
end

function tf = classExists(full_class_name)
% Check if class already exists
try
    mc = meta.class.fromName(full_class_name);
    tf = ~isempty(mc);
catch e
    tf = false;
end
end

function tf = validateSigClass(class_name)

% % all valid package paths
% mp = meta.package.fromName('mortar.base');
% valid_package_names = {mp.ContainingPackage.PackageList.Name}';
% [package_name, class_name] = classNameParts(full_class_name);
% 
% % package should begin with mortar.
% assert(~isempty(regexp(package_name, '^mortar\.', 'once')),...
%     'Class name must begin with mortar.');
% 
% % package path should be valid
% assert(any(ismember(package_name, valid_package_names)),...
%     'Package name %s does not exist', package_name);

% SigClass name should begin with Sig
assert(~isempty(regexp(class_name, '^Sig', 'once')),...
    'Class Name %s should begin with Sig', class_name);
tf = true;
end


