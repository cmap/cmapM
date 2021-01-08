function nel = parse(obj, src)
% Create a new list.
%
% obj.parse(SRC) SRC can be a 1D cell-array, numeric vector,
% file or another List object
% Returns number of elements added.

[obj.data_, nel] = obj.parse_(src);
end