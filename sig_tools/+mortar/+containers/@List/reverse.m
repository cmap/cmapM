function rev = reverse(obj)
% REVERSE Reverse the order of elements in the list
% REV = List.reverse Returns the reversed list.

obj.data_ = obj.data_(end:-1:1);
rev = obj.data_;

end