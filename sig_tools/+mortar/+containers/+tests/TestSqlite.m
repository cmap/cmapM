classdef TestSqlite < TestCase
    
    properties
        table_struct
        sqlite_file = 'test_sqlite.sqlite';
        table_file = fullfile(fileparts(mfilename('fullpath')), 'table01.txt');
    end
    
    methods
        function self = TestSqlite(name)
            % Constructor
            self = self@TestCase(name);
        end
        
        function setUp(self) %#ok<*MANU>
            % Setup (called before each test)
            value = 64 + mod(0:99, 26)+1;
            name = cellstr(char(value)')';
            self.table_struct = struct('id', num2cell(1:100),...
                'value', num2cell(value),...
                'name', name);
        end
        
        function tearDown(self)
            % Called after each test
        end  
        
        %% Db operations
        
        function memdb = mkMemDb(self)
            memdb = mortar.containers.Sqlite(':memory:', false);            
        end
        
        function filedb = mkFileDb(self)
            if exist(self.sqlite_file,'file')>0
                delete(self.sqlite_file);
            end
            filedb = mortar.containers.Sqlite(self.sqlite_file, false);
        end
        
        function testCreateMemoryDb(self)
            % Create in memory database
            memdb = self.mkMemDb;
            assertEqual(memdb.dbfile, ':memory:');
        end
        
        function testCreateFileDb(self)
            % Create file db
            memdb = self.mkFileDb;
            assertEqual(memdb.dbfile, self.sqlite_file);
        end       
        
        function testCloseDb(self)
            % close db
            memdb = self.mkMemDb();
            assertTrue(memdb.isopen, 'Error creating');
            memdb.close;
            assertTrue(~memdb.isopen, 'Error closing');
        end        
        
        %% Table ops
        function testCreateTableFromStruct(self)
            % Create a table from a structure
            memdb = self.mkMemDb;
            memdb.create('sample', self.table_struct, 'id', true);
            result = memdb('select * from sample');
            assertTrue(memdb.istable('sample'), 'Table not found');
            assertEqual(fieldnames(self.table_struct), ...
                memdb.columns('sample'), 'Column mismatch');
            assertEqual({self.table_struct.id}, {result.id},...
                'ID mismatch');
            assertEqual({self.table_struct.value},{result.value},...
                'Value mismatch');
            assertEqual({self.table_struct.name},{result.name},...
                'Name mismatch');
        end
        
        function testCreateTableFromFile(self)
            % Create table from text file
            memdb = self.mkMemDb;
            memdb.createFromFile('sample', self.table_file, 'id');
            result = memdb('select * from sample');
            assertTrue(memdb.istable('sample'), 'Table not found');            
            assertEqual(fieldnames(self.table_struct), ...
                memdb.columns('sample'), 'Column mismatch');
            assertEqual({self.table_struct.id}, {result.id},...
                'ID mismatch');
            assertEqual({self.table_struct.value},{result.value},...
                'Value mismatch');
            assertEqual({self.table_struct.name},{result.name},...
                'Name mismatch');
        end
        
        function testDropTable(self)
            % delete a table
            memdb = self.mkMemDb();
            memdb.create('sample', self.table_struct, 'id', true);
            assertTrue(memdb.istable('sample'), 'table not created');
            memdb.drop('sample');
            assertFalse(memdb.istable('sample'), 'table not dropped');
        end
        
        function testAddColumn(self)
            % Add new columns to table
            newcols = {'newcol1', 'newcol2'};
            memdb = self.mkMemDb();
            memdb.create('sample', self.table_struct, 'id', true);
            memdb.addColumn('sample',newcols);
            assertTrue(all(memdb.iscolumn('sample', newcols)));
        end
        
        function testDeleteColumn(self)
            % Delete columns from table
            delcols = {'value', 'name'};
            memdb = self.mkMemDb();
            memdb.create('sample', self.table_struct, 'id', true);
            assertTrue(all(memdb.iscolumn('sample', delcols)), ...
                'column not in table');
            memdb.deleteColumn('sample', delcols);
            assertFalse(all(memdb.iscolumn('sample', delcols)), ...
                'columns not deleted');
        end
        
        function testGetNumRows(self)
            % Get number of rows in a table
            memdb = self.mkMemDb();
            memdb.create('sample', self.table_struct, 'id', true);
            assertEqual(memdb.numRows('sample'), length(self.table_struct));
        end
        % TODO
       
        % mutators
        % add columns
        % delete columns
        % IO functions
        % save to text file
    end
end