function [varargout] = subsref(obj, s)
% Overloaded subscripted reference handling.

    switch s(1).type
        
        case '()'
            % Table([i1,i2,...], [j1,j2,...] ) returns a Table object of the selection
            varargout = cell(max(nargout, 1), 1);
            
            if ~isempty(s(1).subs) && isequal(size(s(1).subs, 2), 2)
                ir = obj.ix_(s(1).subs{1}, 1);
                ic = obj.ix_(s(1).subs{2}, 2);
                varargout{1} = feval(class(obj), obj.data_(ir, ic),...
                    obj.columns(ic), obj.rows(ir));
            else
                error('Invalid index')
            end
            
            % handle additional references
            if length(s)>1
                out = run_builtin(varargout{1}, s(2:end), length(varargout));
                for ii=1:length(varargout)
                    varargout{ii} = out{ii};
                end
            end
            
        case '{}'
            % Table{i, j} returns the contents of the selection
            if ~isempty(s(1).subs) && isequal(size(s(1).subs, 2), 2)
                ir = obj.ix_(s(1).subs{1}, 1);
                ic = obj.ix_(s(1).subs{2}, 2);
                
                varargout = cell(1, nargout);
                if strcmp(ir, ':') || strcmp(ic, ':')
                    [varargout{1}] = obj.data_(ir, ic);
                else
                    [varargout{1}] = obj.data_(ir, ic);
                end
                
                
            else
                error('Invalid index')
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