function nel = append(obj, new)
% Append elements to the end of the list
% Returns number of elements appended
[seq, nel] = obj.parse_(new);
obj.data_ = [obj.data_; seq];
end