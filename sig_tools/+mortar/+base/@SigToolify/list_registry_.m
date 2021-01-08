function varargout = list_registry_(obj)
% list_registry_ List tool registry

prop = parse_jenkins_prop(obj.inventory_file);
if isfield(prop, 'sig_tool_list')
    inventory = prop.sig_tool_list;
else
    inventory = '';
end
if ~nargout
    dbg(1, 'Inventory:')
    for ii=1:length(inventory)
        dbg(1, '%d. %s', ii, inventory{ii});
    end
else
    varargout(1)=inventory;
end
end

