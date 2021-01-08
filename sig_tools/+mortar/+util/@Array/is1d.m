function yn = is1d(src)
% Check if input array is one-dimensional.
yn = isequal(length(src), numel(src));
end