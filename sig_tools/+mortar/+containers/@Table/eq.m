function tf = eq(obj1, obj2)
% test if two objects are equal

isobj1 = isa(obj1, 'mortar.containers.Table');
isobj2 = isa(obj2, 'mortar.containers.Table');

if ~isobj1
    obj1 = obj2cell(obj1, size(obj2));
end

if ~isobj2
    obj2 = obj2cell(obj2, size(obj1));
end

if isobj1 && isobj2
    tf = cellfun(@eq, obj1.data_, obj2.data_);
elseif isobj1
    tf = cellfun(@eq, obj1.data_, obj2);
elseif isobj2
    tf = cellfun(@eq, obj1, obj2.data_);
else
    error('mortar:containers:Table:UndefinedEq', 'UndefinedEq for specified inputs');
end

end


function obj1 = obj2cell(obj1, obj2size)
% replicate non-object to a cell of the required dimensions
if isscalar(obj1)
    if iscell(obj1)
        obj1 = repmat(obj1, obj2size);
    else
        obj1 = repmat({obj1}, obj2size);
    end
else
    assert(isequal(size(obj1), obj2size), 'dimension mismatch when comparing');
    if ~iscell(obj1)
        obj1 = num2cell(obj1);
    end
end
end