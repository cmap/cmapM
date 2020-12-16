classdef TestTable < TestCase
    
    properties (Access = private)
        src_file
        src
        tbl
    end
    
    methods
        
        function self = TestTable (name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            % Setup (called before each test)            
            self.src_file = fullfile(fileparts(mfilename('fullpath')), ...
                'table01.txt');

            % test table
            self.tbl.id = (1:100)';
            self.tbl.value = 64 + mod(self.tbl.id-1, 26) + 1;
            self.tbl.name = cellstr(char(self.tbl.value));
                        
%             self.src = mortar.containers.Table(self.src_file);
        end
        
        function tearDown(self)
            % Called after each test
        end
        
        function testEmptyTable(self)
            tblobj = mortar.containers.Table();
            assertEqual(tblobj.size, [0, 0], 'Size not [0, 0]');
            assertTrue(isempty(tblobj.columns), 'Columns not empty');
            assertTrue(isempty(tblobj.rows), 'Rows not empty');
            assertTrue(isempty(tblobj), 'isempty method failed');
        end
        
        function testSize(self)
            tblobj = mortar.containers.Table(self.tbl);
            assertEqual(tblobj.size, [100, 3]);
            assertEqual(tblobj.size(1), 100);
            assertEqual(tblobj.size(2), 3);
        end
        
        function testParseCell(self)    
            % Parse cell array input
            data = [num2cell(self.tbl.id),...
                    num2cell(self.tbl.value),...
                    self.tbl.name];
            col_id = {'id', 'value', 'name'};
            tblobj = mortar.containers.Table(data, col_id);            
            assertEqual(tblobj.nrows, size(data, 1));
            assertEqual(tblobj.ncols, size(data, 2));                        
        end
        
        function testParseScalarStruct(self)
            % parse scalar struct
            tblobj = mortar.containers.Table(self.tbl);
            row_label = mortar.common.Util.genLabels(length(self.tbl.id),...
                '--zeropad', false, '--prefix','r');

            assertEqual(tblobj.nrows, length(self.tbl.id));
            assertEqual(tblobj.ncols, length(fieldnames(self.tbl)));
            assertEqual(tblobj.columns, fieldnames(self.tbl));
            assertEqual(tblobj.rows, row_label);
        end
        
        function testParseStructArray(self)
            % parse struct array
            sa = struct('id', num2cell(self.tbl.id),...
                        'value', num2cell(self.tbl.value),...
                        'name', self.tbl.name);
            row_label = mortar.common.Util.genLabels(length(sa),...
                        '--zeropad', false, '--prefix','r');
            tblobj = mortar.containers.Table(sa);
            assertEqual(tblobj.nrows, length(sa));
            assertEqual(tblobj.ncols, length(fieldnames(sa)));
            assertEqual(tblobj.columns, fieldnames(sa));
            assertEqual(tblobj.rows, row_label);
        end

        function testParseFile(self)
            % parse a text file
            sa = struct('id', num2cell(self.tbl.id),...
                'value', num2cell(self.tbl.value),...
                'name', self.tbl.name);
            row_label = mortar.common.Util.genLabels(length(sa),...
                '--zeropad', false, '--prefix','r');
            tblobj = mortar.containers.Table(self.src_file);
            assertEqual(tblobj.nrows, length(sa));
            assertEqual(tblobj.ncols, length(fieldnames(sa)));
            assertEqual(tblobj.columns, fieldnames(sa));
            assertEqual(tblobj.rows, row_label);
        end

        function testSelectColumnById(self)
            % select by column ids
            tblobj = mortar.containers.Table(self.tbl);
            ic = {'id'; 'name'};
            subtable = tblobj.icol(ic);
            assertEqual(subtable.columns, ic);
            assertEqual(tblobj.rows, subtable.rows);
        end        
        
        function testSelectColumnByIndex(self)
            % select columns by indices
            tblobj = mortar.containers.Table(self.tbl);
            ic = [3,2,1];            
            subtable = tblobj.icol(ic);
            assertEqual(subtable.columns, tblobj.columns(ic));
            assertEqual(tblobj.rows, subtable.rows);
        end

        function testSelectColumnByColon(self)
            % select columns using the ':' operator
            tblobj = mortar.containers.Table(self.tbl);            
            subtable = tblobj.icol(:);
            assertEqual(subtable.columns, tblobj.columns);
            assertEqual(tblobj.rows, subtable.rows);
        end

        function testSelectRowById(self)
            % select by row ids
            tblobj = mortar.containers.Table(self.tbl);
            row_idx = [1,2,10];
            row_id = tblobj.rows(row_idx);            
            subtable = tblobj.irow(row_id);
            assertEqual(subtable.rows, tblobj.rows(row_idx));
            assertEqual(tblobj.columns, subtable.columns);
        end
        
        function testSelectRowByIndex(self)
            % select row by indices
            tblobj = mortar.containers.Table(self.tbl);
            ir = [3,2,1];
            subtable = tblobj.irow(ir);
            assertEqual(subtable.rows, tblobj.rows(ir));
            assertEqual(tblobj.columns, subtable.columns);
        end
        
        function testSelectRowByColon(self)
            % select rows using the ':' operator
            tblobj = mortar.containers.Table(self.tbl);
            subtable = tblobj.irow(:);
            assertEqual(subtable.columns, tblobj.columns);
            assertEqual(tblobj.rows, subtable.rows);
        end
        
        function testSelectDirectByIndex(self)
            tblobj = mortar.containers.Table(self.tbl);
            ir = [3,2,1];
            subtable = tblobj(ir, :);
            assertEqual(subtable.rows, tblobj.rows(ir));
            assertEqual(tblobj.columns, subtable.columns);
        end
        
        function testSelectDirectById(self)
            tblobj = mortar.containers.Table(self.tbl);
            ic = {'id'; 'name'};
            subtable = tblobj(:, ic);
            assertEqual(subtable.columns, ic);
            assertEqual(tblobj.rows, subtable.rows);
        end
        
        function testEqObject(self)
            % element by element comparison
            tblobj = mortar.containers.Table(self.tbl);
            iseq = tblobj==tblobj;
            assertTrue(all(iseq(:)));
        end
        
        function testEqScalar(self)
            tblobj = mortar.containers.Table(self.tbl);
            assertTrue(tblobj(end, 1) == 100);            
        end

        function testEqVector(self)
            tblobj = mortar.containers.Table(self.tbl);
            assertTrue(all(tblobj(:,1) == self.tbl.id));
            assertTrue(all(self.tbl.id == tblobj(:,1)));
        end

        function testEqTblColumn(self)
            % assign another column
            tblobj = mortar.containers.Table(self.tbl);
            tblobj{1:5, 1} = tblobj(21:25, 2);
            assertTrue(all(tblobj(1:5,1) == tblobj(21:25,2)));            
        end
        
        function testIsequal(self)
            % isequal
            tblobj = mortar.containers.Table(self.tbl);
            assertTrue(isequal(tblobj, tblobj));
            assertTrue(isequal(tblobj(:,1), tblobj(:,1)));
            assertFalse(isequal(tblobj(:,1), tblobj(:,2)));
        end

        function testAssignBracesScalar(self)
            tblobj = mortar.containers.Table(self.tbl);
            tblobj{:, 1} = 100;
            assertTrue(all(tblobj(:,1)==100));
        end
        
        
        function testAssignParensOneColumn(self)
            % Assign a single column
            tblobj = mortar.containers.Table(self.tbl);
            tblobj(:, 1) = tblobj(:, 2);
            assertTrue(isequal(tblobj(:,1), tblobj(:, 2)));
        end
    end
    
end