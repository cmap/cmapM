function new = copy_generic(obj)
% This method acts as a copy constructor for all derived
% classes.
new = feval(class(obj)); % create new object of correct subclass.
mobj = metaclass(obj);
% Only copy properties which are
% * not dependent or dependent and have a SetMethod
% * not constant
% * not abstract
% * defined in this class or have public SetAccess - not
% sure whether this restriction is necessary
sel = cellfun(@(cProp) (~cProp.Constant && ...
    ~cProp.Abstract && ...
    (~cProp.Dependent || (cProp.Dependent && ~isempty(cProp.SetMethod)))), ...
    mobj.Properties);
for k = find(sel)
    new.(mobj.Properties{k}.Name) = obj.(mobj.Properties{k}.Name);
end
end