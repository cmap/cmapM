function result = subsref(obj, s)
% Handle subscripted reference

result = -1;
fall_through = true;

if isequal(length(s), 1) && isequal(s.type, '()') && iscell(s.subs) && ischar(s.subs{1})
    result = obj.run(s(1).subs);
    fall_through = false;
end

if fall_through
    if obj.isprivate_(s)
        error('Error accessing property or method');
    else
        result = builtin('subsref', obj, s);
    end
end
end