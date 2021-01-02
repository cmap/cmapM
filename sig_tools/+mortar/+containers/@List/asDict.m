function dict = asDict(obj)
% Return list as a dictionary with list elements as keys and
% the indices as values. Note the list must be unique.
if ~obj.isempty
    dict = containers.Map(obj.data_, 1:obj.length);
else
    dict = {};
end
end