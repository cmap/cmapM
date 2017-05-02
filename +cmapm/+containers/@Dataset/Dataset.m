classdef Dataset < cmapm.formats.Format
    % Dataset A class for handling 2D annotated matrices.
        
    % Public properties
    properties
    end
    
    % Dependent properties
    properties(Dependent = true)
        dim
        matrix
        row_id
        col_id
    end
    
    % Private Properties
    properties(Access = private)
        ds;
    end
        
    methods
        function obj = Dataset(src)
            % Class constructor
            nin = nargin;
            if nin
                obj = obj.parse(src);
            else
                obj.ds = mkgctstruct;
            end
        end
        
        function obj = parse(obj, src)
            % PARSE Read dataset from file.
            switch class(src)
                case 'char'
                    if exists(src, 'file')
                        disp('parse stub')
                    else
                        error('File not found: %s', src);
                    end
                case 'struct'
                otherwise
                    error('Unsupported input');            
            end
        end
        
        function obj = subset(obj, varargin)
            % Extract a subset of the data.
            disp('subset stub')
        end
        
        function obj = save(obj, varargin)
            % SAVE Save object
            disp('SAVE STUB');
        end
        
        function obj = disp(obj, varargin)
            % DISP display object
            disp('DISP stub');
        end
        
        function obj = isempty(obj, varargin)
            % DISP display object
            disp('DISP stub');
        end
        
        function obj = length(obj, varargin)
            % DISP display object
            disp('LENGTH stub');
        end
       
        function obj = size(obj, varargin)
            % DISP display object
            disp('LENGTH stub');
        end     
        
        %% Getters
        function sz = get.dim(obj)
            % Size of data matrix [rows, columns]
            sz = size(obj.ds.mat);
        end
        
        function row_id = get.row_id(obj)
            % Row identifiers
            row_id = obj.ds.rid;
        end
        
        function col_id = get.col_id(obj)
            % Column identifiers
            col_id = obj.ds.rid;
        end
        
        function mat = get.matrix(obj)
            % Data matrix
            mat = obj.ds.mat;
        end
        
    end
    
    
    methods(Access = private)
        % Private methods
        function parse_(obj, varargin)
        end
        
    end
    
end

