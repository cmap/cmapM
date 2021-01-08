function yn = is1d(src)
% IS1D Check if input array is one-dimensional.

yn = isequal(length(src), numel(src));
end