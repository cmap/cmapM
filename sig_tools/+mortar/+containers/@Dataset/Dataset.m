classdef Dataset
    %A Class for handling 2D annotated matrices.
        
    % Public properties
    properties
    end
    
    % Dependent properties
    properties(Dependent = true)
        size
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
            %Class constructor
            
            if isvarexist('src')
                switch(class(src))
                    case 'char'
                       obj = obj.parse(src);
                    otherwise
                        error('Invalid input')
                end
            else
                obj.ds = mkgctstruct;
            end
        end
        
        function obj = parse(obj, src)
            % Read dataset from file.
            if isfileexist(src)
                disp('parse stub')
            else
                error('File not found: %s', src);
            end
        end
        
        function obj = subset(obj, varargin)
            % Extract a subset of the data.
            disp('subset stub')
        end
        
        % Getters
        function sz = get.size(obj)
            % Size of data matrix [rows, columns]
            sz = size(obj.ds.mat);
        end
        
        function row_id = get.row_id(obj)
            % Row identifiers
            row_id = obj.ds.rid;
        end
        
        function row_id = get.col_id(obj)
            % Column identifiers
            row_id = obj.ds.rid;
        end
        
        function mat = get.matrix(obj)
            % Data matrix
            mat = obj.ds.mat;
        end
        
    end
    
end

