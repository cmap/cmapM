function tf = ne(obj, obj2)
% NE Test two lists for inequality.

if nargin==2
    tf = ~obj.eq(obj2);
else
    tf = false;
end

end