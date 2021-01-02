function [varargout] = subsref(obj, s)
% Overloaded subscripted reference handling.


    switch s(1).type
        
        case '.'
            id = s(1).subs;
            if ischar(id) && isprop(obj, id)
                [varargout{1:nargout}] = get(obj, id);
            else
                error('mortar:common:Spaces:InvalidProperty', id)
            end
            
        otherwise
            % Return output of builtin subsref
            varargout = run_builtin(obj, s, nargout);
    end
end

function out = run_builtin(obj, s, nout)
% Execute builtin subsref after enforcing access rules.
out = cell(1, nout);
if obj.isprivate_(s)
    error('Error accessing property or method');
else
    if nout>0
        [out{:}] = builtin('subsref', obj, s);
    else
        builtin('subsref', obj, s)
    end
end
end