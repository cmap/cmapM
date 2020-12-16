function nel = insert(obj, idx, src)
% Insert elements at a given index.
% Returns the number of elements inserted
[seq, nel] = obj.parse_(src);
new = cell(obj.length + nel, 1);
new(1:idx-1) = obj.data_(1:idx-1);
new(idx+(0:nel-1)) = seq;
new(nel+idx:end) = obj.data_(idx:end);
obj.data_ = new;
end