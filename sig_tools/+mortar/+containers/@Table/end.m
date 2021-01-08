function ind = end(obj, k, n)
% Overload the end method for indexing.
% Returns index of last element in the list
if nargin==3 && k==1
    ind = obj.nrows;
elseif nargin==3 && k==2
    ind = obj.ncols;
else
    error('Invalid index');
end
end