function nel = del(obj, idx)
% Delete elements from specified indices.
% Returns the number of elements deleted.
nel = obj.length;
obj.data_(idx) = [];
nel = nel - obj.length;
end