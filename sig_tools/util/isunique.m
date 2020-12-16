function tf = isunique(x)
% ISUNIQUE Test if input has unique elements

tf = isequal(length(unique(x)), length(x));

end