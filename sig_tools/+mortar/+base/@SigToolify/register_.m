function register_(obj, varargin)
% register_ Add tool to inventory

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
        reply = getInput(sprintf('Enter index of Sig Tool to register [1-%d]:', nTools),...
            @validateToolIndex, nTools);
        idx = floor(str2double(reply));
        opt.ClassName = sigTools{idx};
        opt.FullClassName = sprintf('%s.%s', opt.PackageName, opt.ClassName);
        opt.ToolName = getToolName(opt.ClassName);        
    end             
end

if ~isempty(opt.ToolName)
    prop = parse_jenkins_prop(obj.inventory_file);
    if isfield(prop, 'sig_tool_list')
        prop.sig_tool_list = union(prop.sig_tool_list, opt.ToolName,...
            'stable');
    else
        prop.sig_tool_list = opt.ToolName;
    end
    mk_jenkins_prop(obj.inventory_file, prop);
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


