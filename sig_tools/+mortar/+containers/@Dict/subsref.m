function varargout = subsref(obj, s)
% Overloaded subscripted reference handling.

switch s(1).type
    case '()'
        % List([i,j...]) returns a List object of the selection
        varargout = cell(max(nargout, 1), 1);
        if ~isempty(s(1).subs)
            key = s(1).subs;            
            if isequal(length(key), 1)
                if isempty(key{1})
                    varargout{1} = '';
                else
                    varargout{1} = obj.get(key{1});
                    % msg = sprintf('Invalid key:%s', stringify(key{1}));
                    % ME = MException('Dict:KeyError', msg);
                    % throw (ME);
                end
            else
                error('Use the get method for multiple keys');
            end
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
        % List{i} returns the contents of the selection
        varargout = obj.data_(s(1).subs{1});
        
    otherwise
        % Return output of builtin subsref
        varargout = run_builtin(obj, s, nargout);
end

end

function out = run_builtin(obj, s, nout)
% Execute builtin subsref after enforcing access rules.
out = cell(max(nout, 1), 1);
if obj.isprivate_(s)
    error('Error accessing property or method');
else
    [out{:}] = builtin('subsref', obj, s);
end
end