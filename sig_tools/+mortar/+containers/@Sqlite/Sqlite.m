classdef Sqlite < handle
    % A wrapper class for handling sqlite database access.
    %
    % Sqlite(), Create an empty sql object.
    %
    % Sqlite(dbfile), Open a connection to dbfile. Use ':memory:'
    %   to open in-memory database.
    %
    % Sqlite(dbfile, isverbose), Specify verbosity (boolean).
    % Default is true.
    %
    % Sqlite(dbfile, isverbose, sync_mode), Specify synchronous
    %   flag. Options are {'OFF','NORMAL','FULL'}. Default is
    %   'OFF'.
    %
    % See: http://www.sqlite.org/pragma.html#pragma_synchronous
    % Example:
    %   sql = mortar.Sqlite(':memory:');
    %   tbl = struct('id', {'apples','oranges','peaches'}, 'price',...
    %   num2cell([0.99, 1.50, 0.75]), 'source', {'California','Florida','Georgia'})
    %   sql.create('fruit', tbl, 'id', true)
    %
    %   sql.columns('fruit')
    %   result = sql('select * from fruit where id = "apples"')
    %   result = sql('select * from fruit order by price desc', 'as_cell', true)
    
    % Author: Rajiv Narayan
    % Created: June 1, 2012
    
    % TODO:
    % Joins
    % Rename fields
    
    % Known Bugs:
    % Allow primary key to be deleted?
    
    
    % Public properties
    properties
        dbfile = '';
        verbose = true;
    end
    
    % Public dependent Properties
    properties(Dependent = true)
        tables
        isopen
    end
    
    % Private properties
    properties (Access = private)
        dbid = '';
        sync_mode = 'OFF';
    end
    
    % Constants
    properties (Constant = true, GetAccess = private)
        keywords = mortar.containers.Sqlite.getKeywords_;
        opt_param = {'as_cell', 'header'};
        opt_default = {false, true};
        mksqlite_bin = @mortar.ext.mksqlite.mksqlite;
    end
    
    % Public methods
    methods
        function obj = Sqlite(dbfile, isverbose, sync_mode)
            % Class Constructor
            if mortar.legacy.isvarexist('isverbose') && islogical(isverbose)
                obj.verbose = isverbose;
            end
            
            if mortar.legacy.isvarexist('sync_mode') && ismember(upper(sync_mode), {'OFF', 'NORMAL', 'FULL'})
                obj.sync_mode = upper(sync_mode);
            end
            
            if mortar.legacy.isvarexist('dbfile') && ischar(dbfile)
                obj = obj.open(dbfile);
            end
        end
        
        function delete(obj)
            % Class destructor, called before a object of the class is destroyed
            try
                obj.close();
            catch e
            end
        end
        
        %% DB operations
        % Connect to a database
        obj = open(obj, dbfile);
        
        % Close database
        obj = close(obj);

        % Run an SQL query
        result = run(obj, sql_query);
        
        % Create a table from a structure
        result = create(obj, table_name, table, primary_key, populate);
        
        % Create a new table from a text file
        result = createFromFile(obj, table_name, file_name, primary_key);
        
        % Insert rows into a table from a structure
        result = insert(obj, table_name, table);
        
        % Delete a table
        result = drop(obj, table_name);
        
        % Copy contents of an in-file db to the current database.
        result = clone(obj, otherdb);
        
        % Save current database to in-file db
        result = save(obj, out_file, overwrite);

        % Save a table to a text file
        result = saveTable(obj, table_name, out_file);

        % Add columns to a table        
        result = addColumn(obj, table_name, columns);

        % Delete columns from a table
        result = deleteColumn(obj, table_name, columns);

        %% Lookups, Setter and Getters
        % Get column names in a table
        col = columns(obj, table_name);

        % Get number of rows in a table
        n = numRows(obj, table_name);
        
        % Get schema of a table
        result = schema(obj, table_name);
        
        % Check if table(s) exists
        yn = istable(obj, table_name);
          
        % Check if column(s) exist in a table
        yn = iscolumn(obj, table_name, columns);

        %% Handle subscripted reference
        result = subsref(obj, s);

        %% Dependent methods
        function obj = set.verbose(obj, value)
            % Set verbosity
            % verbose = yn where yn is boolean.
            if ismember(value, [0, 1])
                obj.verbose = value;
            else
                error('Value must be boolean');
            end
        end
        
        function tables = get.tables(obj)
            % Get tables in current database
            tables = {};
            % the standard way
            % result = obj.run('SELECT name FROM sqlite_master WHERE type="table"');
            % Using mksqlite helper function
            result = obj.run('show tables');
            if ~isempty(result)
                tables = {result.tablename}';
            end
        end
        
        function tf = get.isopen(obj)
            % Check if database is open
            tf = ~isempty(obj.dbid);
        end
            
    end
    
    % Private methods
    methods (Access=private)
        
        % Check if referenced method or property is private
        yn = isprivate_(obj, s);

        % Check for valid SQL name and quote keywords
        name = validateName_(obj, name);

        % Infer SQL schema from matlab structure        
        schema = structToSchema_(obj, table_struct, primary_key);

        % Construct SQL string from schema
        sql = schemaToSql_(obj, table_name, schema);

        % Copy contents to a source from a target db.
        result = clone_(obj, otherdb, copytoself);

    end
    
    % Public static methods
    methods (Static)
        
        % Check if string is an SQL reserved word        
        yn = iskeyword(s);
        
    end
    
    % Private static methods
    methods (Static, Access = private)
        
        % SQL keywords to quoted equivalents
        kw_dict = getKeywords_;
        
        % Convert Matlab data type to Sqlite type
         dtype = getSqliteType_(matlab_type);
            
         % Validate a table name
        table_name = validateTableName_(table_name);           
        
        % Check if table_name is valid
        yn = isvalidTableName_(table_name);            
        
        % Convert list to cell
        li = toCell_(li);

    end % methods (Static)
    
end