classdef Dict < mortar.containers.Container
    % Dict A dictionary class
    %   Detailed explanation goes here
    
    % TODO
    % indexing
    % d = Dict({'a','b','c'}, {1,2,3});
    
    properties(Dependent = true)
        keys
        %length
        %isempty
    end
    
    properties(Access = private)
        %data_ = containers.Map;
        default_ = nan;
    end
    
    methods
        function obj = Dict(varargin)
            if nargin>0
                obj.parse(varargin{:});
            else
                obj.data_ = containers.Map;
            end
        end
        
        function obj =  parse(obj, varargin)
            obj.data_ = obj.parse_(varargin{:});
        end
        
        %% Creation and parsing
        function disp(obj)
            disp(obj.data_);
        end
        
        function save(obj)
        end
        
        %% Conversions
        
        function map = asMap(obj)
            map = obj.data_;
        end
        
        %% dimensions
        
        varargout = size(obj, dim);
        
        function sz = length(obj)
            % Return the number of items in the dictionary
            sz = length(obj.data_.keys);
        end        
        
        %% Setters and Getters
        function keys = get.keys(obj)
            % Return list of keys
            keys = obj.data_.keys';
        end
        
        function keys = sortKeysOnValue(obj, direc)
            % Sort keys based on values
            % sortKeysOnValue()
            % sortKeysOnValue(DIREC) sorts the values in the specified
            % direction.
            %   'ascend' Ascending order (default)
            %   'descend' Descending order
            
            if nargin < 2
                direc = 'ascend';
            end
            if mortar.common.Util.isNumericType(obj.data_.ValueType)
                [~, ord] = sort(cell2mat(obj.data_.values), direc);
            else
                [~, ord] = sort(obj.data_.values, direc);
            end
            keys = obj.keys(ord);
        end
        
        function v = values(obj, varargin)
            % Return a list of values in the dictionary
            if nargin==1
                v = obj.data_.values;
            else
                if ischar(varargin{1})
                    varargin{1}={varargin{1}};
                end
                v = obj.data_.values(varargin{1});
            end
        end
        
        function v = get(obj, k, varargin)
            % GET(K)
            % GET(K, D)
            % Return the value for K if it exists in the dictionary, else
            % return D which defaults to NaN.
            if nargin > 2
                d = varargin{1};
            else
                d = obj.default_;
            end
            if ~iscell(k)
                k = {k};
            end
            v = cell(length(k), 1);
            ik = obj.iskey(k);
            if any(ik)
                v(ik) = obj.data_.values(k(ik));
            end
            v(~ik) = {d};
            if mortar.common.Util.isNumericType(obj.data_.ValueType)
                v = cell2mat(v);
            end
        end
        
        function tf = isempty(obj)
            % Return True if the dictionary is empty.
            tf = obj.data_.isempty;
        end
        
        function tf = iskey(obj, k)
            % Test if key exists in the dictionary
            tf = obj.data_.isKey(k);
        end
        
        function tf = isKey(obj, k)
            % same as iskey but maintain for backward compatibility
            % Test if key exists in the dictionary
            tf = obj.data_.isKey(k);
        end
        
        function nk = add(obj, k, v)
            % Add elements to the dictionary
            if ischar(k)
                k = {k};
                v = {v};
            end            
            nk = length(k);
            assert(isequal(length(k), length(v)),...
                'Number of keys must match values');
            for ii=1:nk
                obj.data_(k{ii}) = v{ii};
            end            
        end
        
        function obj = subsasgn(obj, s, val)
            % Handle assignments
            switch s(1).type
                case '()'
                    obj.add(s(1).subs{1}, val);
                case '.'
                    obj = builtin('subsasgn', obj, s, val);
                    %error('List:subsasgn Not a supported subscripted assignment')
                case '{}'
                    error('List:subsasgn Not a supported subscripted assignment')
            end
        end
        %% Mutators        
        
        function status = clear(obj)
            % Remove all items from the dictionary
            obj.data_.remove(obj.data_.keys);
            status = 0;
        end
        
        function v = pop(obj, k, varargin)
            % Remove specified key from the dictionary and return its
            % value.
            % V = POP(K)
            % V = POP(K, D) Return D if key is not found
            
            if obj.iskey(k)
                v = obj.data_(k);
                obj.data_.remove(k);
            elseif nargin >2
                v = varargin{1};
            else
                error ('Key not found')
            end
        end
        
        %% Copy
        function newobj = copy(obj)
            % Return a copy of the dictionary
%             newobj = feval(class(obj), obj.data_);
            newobj = feval(class(obj), obj.data_.keys, obj.data_.values);
%             mobj=metaclass(obj.data_);
%             select = find(cellfun(@(cProp)(~cProp.Constant &&...
%                 ~cProp.Abstract &&...
%                 (~cProp.Dependent ||...
%                 (cProp.Dependent &&...
%                 ~isempty(cProp.SetMethod)))), mobj.Properties));
%             for ii=1:length(select)
%                 newobj.(mobj.Properties{ii}.Name) = obj.(mobj.Properties{ii}.Name);
%             end
        end
                
        function status = update(obj, varargin)
            newd = obj.parse_(varargin{:});
            newk = newd.keys();
            for ii=1:length(newd)
                obj.data_(newk{ii}) = newd(newk{ii});
            end            
            status = 0;
        end
        
        
%         function v = popitem(obj, k, d)
%             % Remove and return 
%             
%         end
        
    end
    
    methods(Access = private)
        
        tf = isprivate_(obj, s);
        
        function dict = parse_(obj, varargin)
            nin = nargin - 1;
            if isequal(nin, 1)
                if isa(varargin{1}, 'containers.Map')
                    dict = varargin{1};
                elseif isa(varargin{1}, 'mortar.containers.List')
                    dict = varargin{1}.asDict;
                elseif isa(varargin{1}, class(obj))
                    dict = varargin{1}.asMap;
                else
                    dict = containers.Map(varargin{1}, 1:length(varargin{1}));
                end
            elseif isequal(nin, 2)
                if isempty(varargin{1})
                    dict = containers.Map;
                else
                    dict = containers.Map(varargin{1}, varargin{2});
                end
            else
                error('Invalid input')
            end
        end
        
    end
end

