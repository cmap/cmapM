classdef List < mortar.containers.Container 
    % A class for handling 1-D lists.
    %
    % TODO:
    % - Add method freq / countof : number of occurrences    
    % - Add Iterator
    % - Add documentation
    %
    % Known Bugs:
    % - Set ops break for mixed data types.       
    % - numel does not work as desired, but overloading it makes Matlab
    % very unhappy.
    
    properties (Access = protected)
        % Store list as a cell array in data_
    end
    
    methods
        % Public methods
        % Note: To simplify code, all public methods _must_ return at least
        % one value.
        
        function obj = List(src)
            % Class constructor
            %
            % listObj = list() Creates an empty list object.
            % listObj = list(SRC) Creates a list object from SRC. SRC can
            % be a cell array, a new-line delimited text file or another
            % list object.
            
            if nargin>0
                obj.parse(src);
            end
        end
        
        % Method declarations
        %% Creation and Parsing
        nel = parse(obj, src);
        
        status = save(obj, tgt);
        
        disp(obj);
        
        %% Dimensions
        varargout = size(obj, dim);
        
        n = numel(obj, varargin);        
        
        %% Type conversion
        lst = asCell(obj);
        
        dict = asDict(obj);

        %% Copying
        new = copy(obj);
        
        new = copyGeneric(obj);

        %% Mutators
        nel = append(obj, new);
        
        nel = del(obj, idx);
        
        nel = insert(obj, idx, src);
        
        el = pop(obj);
        
        rev = reverse(obj);
        
        [srt, srtidx] = sort(obj, varargin);
        
        %% Set operations
        [cmn, ia, ib] = intersect(obj, other, isordered);
        
        [c,ia,ib] = intersectOrdered(a,b);
        
        [sd, ia] = setdiff(obj, other);
        
        [c, ia, ib] = setxor(obj, other);
        
        [uni, ia, ib] = union(obj, other);
        
        %% Comparisons
        tf = ne(obj, obj2);
        
        tf = eq(obj, obj2);

        %% Misc. Utils
        [dup, dup_idx, freq] = duplicates(obj);
        
        [gp, gpidx, gpfreq] = groups(obj);
        
        idx = index(obj, el);
        
        [srt, srtidx] = sorted(obj, direc);

        %% Indexing and Assignment
        varargout = subsref(obj, s);
        
        obj = subsasgn(obj, s, val);
        
        ind = end(obj, k, n);

        %% Setters and Getters
        function sz = length(obj)
            % Number of elements in the list
            sz = length(obj.data_);
        end
        
        function yn = isempty(obj)
            % Check if the list is empty
            yn = isempty(obj.data_);
        end
                         
    end % methods, public
    
    methods(Access = private)
        % Private methods
        % Note by convention private method names end in '_'
        
        function [seq, nel] = parse_(obj, src)
            % Internal parser
            if isempty(src)
                seq = {};               
            else
                if isa(src, class(obj))
                    seq = src.asCell;
                elseif isa(src, 'cell')
                    assert(mortar.common.Util.is1d(src), 'Expected 1D array');
                    seq = src(:);
                elseif isa(src, 'char')
                    seq = obj.parseFile_(src);
                elseif mortar.common.Util.isNumericType(class(src))
                    assert(mortar.common.Util.is1d(src), 'Expected 1D array');
                    seq = num2cell(src(:));
                else
                    error ('Invalid input')
                end
            end
            nel = length(seq);
        end           
        
        % Parse list from a text file
        list = parseFile_(obj, fname);

        function tf = isvalidIndex_(obj, idx)
            % Check if indices are valid and within bounds.
            % Valid indices are:
            % The colon ':' operator
            % 1D vector of non-zero integers
            % a logical array
            % The end operator is supported by overloading the end method
            tf = ~isempty(idx) && (...
                strcmp(idx, ':') || ...
                (all(idx <= obj.length & idx >0)) || ...
                islogical(idx) ...
                );
        end
        
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
        
    end % methods private
      
end % classdef

