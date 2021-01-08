function c = setdiff_ord(a, b)
% SETDIFF Ordered Set difference between two sets.

c = a(~ismember(a, b));

end