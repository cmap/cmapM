function obj = subsasgn(obj, s, val)

switch s(1).type
    case '()'
            obj.data_(s(1).subs{1}) = obj.parse_(val);
    case '.'
        obj = builtin('subsasgn', obj, s, val);
        %error('List:subsasgn Not a supported subscripted assignment')
    case '{}'
        obj.data_(s(1).subs{1}) = obj.parse_(val);
%         error('List:subsasgn Not a supported subscripted assignment')
end

end