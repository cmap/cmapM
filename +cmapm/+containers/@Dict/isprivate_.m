function tf = isprivate_(obj, s)
% check if referenced method or property is private
n = length(s);
tf = false;
public_properties = properties(obj);
public_methods = methods(obj);
for ii=1:n
    if isequal(s(ii).type, '.')
        if ~any(strcmp(s(ii).subs, public_properties)) && ...
                ~any(strcmp(s(ii).subs, public_methods))
            tf = true;
            break;
        end
    end
end
end