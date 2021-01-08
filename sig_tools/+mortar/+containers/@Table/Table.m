classdef Table < mortar.containers.Container
    %TABLE A container class for heterogenous 2-dimensional data.
    
    % design spec
    
    % Selection / Indexing and slicing
    %   Select column : tbl({'column_names'})
    %                   tbl.icol([ia, ib...])
    %
    %   Row slicing : tbl.row('row_name') 
    %                 or tbl.row([ia,ib...]) 
    %                 or tbl([])
    %                 tbl.irow([])
    %
    % Implementation
    %   Cell array + row dict + col dict
    
    % TODO
    % Assignment
    % row(s) 
    % t(:,i) = t2(:, j) = cell(n, 1) = List
    % column(s)
    % t(i, :) = t2(j, :) = cell(1, n) = List
    % both rows and columns
    % t(i, j) = t2(k, l) = cell(n, m) = List
    % Cell assignment
    % t{i, j} = v
    properties (Access = protected)
        ndims = 2
        row_ = mortar.containers.Dict
        col_ = mortar.containers.Dict
        % data_
    end
%     properties(GetAccess='public', SetAccess='private', Dependent=true)
%         Properties;
%     end
%     methods
%         function val = get.Properties(a), val = get(a); end
%     end
    methods        
        function obj = Table(varargin)
            % Initialize table object
            
            % inputs:
            % cell array: with optional row and column ids
            % struct: either scalar or array
            % another table
            
            if nargin > 0
                obj.parse_(varargin{:})
            end
        end                
                
        % Dimensions
        d = size(obj, dim)
        n = numel(obj, varargin);   
        % Length of largest dimension of container
        n = length(obj)
        
        % number of rows
        nrow = nrows(obj);
        
        % number of columns
        ncol = ncols(obj);
                
        % Test if container is empty
        tf = isempty(obj)
        
        % Parse
        function sz = parse(obj, src)
            [obj.data_, sz] = obj.parse_(src);
        end
        
        % display the contents of an object
        disp(obj)
        
        % save an object to specified target
        save(obj, tgt)

        % row labels
        r = rows(obj, tgt);
        % column labels
        c = columns(obj, tgt);
        
        %%% indexing and assignment
        subtable = icol(obj, c);
        subtable = irow(obj, r);
        subtable = ix(obj, r, c);
%         varargout = subsref(obj, s);
        % Selection
        %   Select column : tbl({'column_names'})
        %                   tbl.icol([ia, ib...])
        %
        %   Row slicing : tbl.row('row_name')
        %                 or tbl.row([ia,ib...])
        %                 or tbl([])
        %                 tbl.irow([])
        % reindex, reorder rows and columns
        % transpose the table
        t(obj);
        
        % operators
        tf = eq(obj1, obj2);
        tf = isequal(obj1, obj2);
        
        % convertors
        s = asStruct(obj);
    
    end   
    
    methods (Access=private)
        
        function lbl = genLabel_(obj, n, isrow)
            % helper to create row and column labels
            if isrow
                prefix = 'r';
            else
                prefix = 'c';
            end
            lbl = mortar.containers.Dict(...
                mortar.common.Util.genLabels(n, ...
                '--zeropad', false, '--prefix', prefix));
        end
        
        function [tbl, sz] = parse_(obj, varargin)
            % parse inputs
            nin = length(varargin);
            src = varargin{1};
            if ~isempty(src)
                switch class(src)
                    case 'char'
                        if mortar.common.FileUtil.isfile(src)
                            obj.parseFile_(src);
                        else
                            error('File not found: %s', src)
                        end                        
                    case 'cell'
                        obj.data_ = src;
                        [nr, nc] = size(src);
                        % column ids
                        if nin > 1
                            assert(isequal(length(varargin{2}), nc),...
                                'Column ids should match the number of columns in the table');
                            obj.col_ = mortar.containers.Dict(varargin{2});
                        else
                            obj.col_ = obj.genLabel_(nc, false);                         
                        end
                        % row ids
                        if nin > 2
                            assert(isequal(length(varargin{3}), nr),...
                                'Row id length should match the number of rows in the table')
                            obj.row_ = mortar.containers.Dict(varargin{3});
                        else
                            obj.row_ = obj.genLabel_(nr, true);
                        end                        
                    case 'struct'
                        nsrc = length(src);
                        fn = fieldnames(src);
                        nf = length(fn);
                        if isequal(nsrc, 1)
                            % scalar struct
                            nr = length(src.(fn{1}));
                            obj.data_ = cell(nr, nf);
                            for ii=1:nf                                
                                assert(mortar.common.Util.is1d(src.(fn{ii})),...
                                    'Expected 1D array');
                                
                                assert(isequal(length(src.(fn{ii})), nr),...
                                    'Invalid number of elements in field %s, expected %d found %d',...
                                    fn{ii}, nr, length(src.(fn{ii})));
                                % cast to List first
                                listObj = mortar.containers.List(src.(fn{ii}));
                                obj.data_(:, ii) = listObj.asCell();
                            end
                            obj.col_ = mortar.containers.Dict(fn);
                            obj.row_ = obj.genLabel_(nr, true);
                        else
                            % struct array
                            obj.data_ = cell(nsrc, nf);
                            for ii=1:nf
                                obj.data_(:, ii) = {src.(fn{ii})};
                            end
                            obj.col_ = mortar.containers.Dict(fn);
                            obj.row_ = obj.genLabel_(nsrc, true);
                        end                        
                    case {'mortar.containers.Dict', 'containers.Map'}
                        error('Table class input stub')                        
                    case class(obj)
                        error('Table class input stub')                        
                    otherwise
                        error('Unsupported input class: %s', class(src));
                end
            end
        end                        
        
        function tf = isValidIndex_(obj, idx, dim)
            % Check if indices are valid and within bounds.
            % Valid indices are:
            % The colon ':' operator
            % 1D vector of non-zero integers
            % a logical array
            % The end operator is supported by overloading the end method
            tf = ~iscell(idx) && ~isempty(idx) && (...
                (numel(idx)==1 && strcmp(idx, ':')) || ...
                (all(idx <= obj.size(dim) & idx >0)) || ...
                islogical(idx) ...
                );
        end
        
        function tf = isValidId_(obj, idx, dim)
            % Check if Ids are valid
            % Valid ids are:
            % The colon ':' operator
            % 1D cell array of ids
            if dim == 1
                tf = (ischar(idx) || iscell(idx)) && ~isempty(idx) && (...
                    (numel(idx)==1 && strcmp(idx, ':')) || ...
                    (all(obj.row_.iskey(idx))));
            else
                tf = (ischar(idx) || iscell(idx)) && ~isempty(idx) && (...
                    (numel(idx)==1 && strcmp(idx, ':')) || ...
                    (all(obj.col_.iskey(idx))));
            end
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
    end
   
end

