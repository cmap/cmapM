classdef TestList < TestCase
    
    properties
        src_cell
        src_file
        src_list
    end
    
    methods
        function self = TestList(name)
            % Constructor
            self = self@TestCase(name);
        end
        
        function setUp(self)
            % Setup (called before each test)
            self.src_cell = {'a'; 'b'; 'c'; 'd'; 'b'; 'c'};
            self.src_file = fullfile(fileparts(mfilename('fullpath')), ...
                'sample01.grp');           
            self.src_list = mortar.containers.List(self.src_cell);
        end
        
        function tearDown(self)
            % Called after each test
        end        
        
        %% Creation and Parsing
        
        function testCreateEmptyList(self)
            % Create and test empty list
            out = mortar.containers.List();
            assert(out.isempty);
            assertEqual(out.length, 0)
            assert(isempty(out.asCell))
        end
        
        function testParseFromCellArray(self)
            % Parse list from a cell array
            assertEqual(self.src_list.asCell, self.src_cell);
        end
        
        function testParseFromNumericArray(self)
            % Parse list from a numeric array
            n = 1:2:10;
            listObj = mortar.containers.List(n);
            assertEqual(listObj.asCell, num2cell(n(:)));
        end
        
        function testParseFromList(self)
            % Parse list from another list object
            out = mortar.containers.List(self.src_list);
            assertEqual(self.src_cell, out.asCell);
        end
        
        function testParseFromFile(self)
            % parse list from a text file
            fid = fopen(self.src_file, 'rt');
            lines = textscan(fid, '%s', 'Delimiter', '\n', ...
                'CommentStyle', '#');
            fclose(fid);
            out = mortar.containers.List(self.src_file);
            
            assertEqual(lines{1}, out.asCell);
        end
        
        function testLengthProperty(self)
            % check the length property
            assertEqual(self.src_list.length, length(self.src_cell));
        end

        %% List modification        
        function testAppend(self)
            % Append items to a list
            more_items = {'x';'y';'z'};
            nel = self.src_list.append(more_items);
            assertEqual(self.src_list.asCell, [self.src_cell; more_items]);
            assertEqual(self.src_list.length, ...
                length(self.src_cell) + length(more_items), ...
                'length mismatch');
            assertEqual(nel, length(more_items), ...
                'Incorrect numel returned');
        end        
        
        function testInsert(self)
            % Insert items at index
            insert_items = {'x'; 'y'};
            nel = self.src_list.insert(3, insert_items);
            assertEqual(nel, length(insert_items), ...
                'Incorrect numel reported');
            assertEqual(self.src_list.asCell, ...
                [self.src_cell(1:2); insert_items; self.src_cell(3:end)]);
        end
        
        function testDelete(self)
            % delete items from list
            delete_index = [4,2];
            expect = self.src_cell;
            expect(delete_index) = [];
            nel = self.src_list.del(delete_index);
            assertEqual(self.src_list.asCell, expect);
            assertEqual(nel, length(delete_index));
        end
        
        function testPop(self)
            el = self.src_list.pop;
            assertEqual(el, self.src_cell{end});
        end
        
        function testPopEmpty(self)
            % Pop an empty list
            emptyList = mortar.containers.List;
            el = emptyList.pop;
            assertTrue(isempty(el));
        end
        
        %% find indices
        function testGetIndex(self)
            assertEqual(self.src_list.index('d'), 4);
            assertEqual(self.src_list.index('b'), [2;5]);
        end
        
        %% Indexing by parenthesis
        function testIndexByRange(self)  
            assertEqual(self.src_list(2:4).asCell, ...
                self.src_cell(2:4));
            assertEqual(self.src_list(2:4).length, 3, 'Length mismatch');
        end
        
        function testIndexByList(self)
            assertEqual(self.src_list([2,4,1]).asCell, ...
                self.src_cell([2,4,1]), 'Bad list indexing');
        end
        function testIndexByLogicalArray(self)
            assertEqual(self.src_list(logical([1,0,0,0,1])).asCell, ...
                self.src_cell([1,5]), 'Bad logical indexing');
        end
        function testIndexByColon(self)
            assertEqual(self.src_list(:).asCell, ...
                self.src_cell, 'Bad colon : indexing');
        end
        
        function testIndexByEnd(self)
            assertEqual(self.src_list(3:end).asCell, ...
                self.src_cell(3:end), 'Bad end indexing');
        end
        
        %% Indexing with braces
        function testBraceElement(self)
            assertEqual(self.src_list{4}, self.src_cell{4});            
        end
        
        function testBraceByEnd(self)
            assertEqual(self.src_list{end}, self.src_cell{end});
        end
        
        %% Set operations        
        function testIntersect(self)
            new = {'x';'b'; 'y'; 'a'; 'foo';'a'};
            expect = intersect(self.src_cell, new);
            nel = self.src_list.intersect(new);
            assertEqual(expect, self.src_list.asCell);
        end
        
        function testIntersectOrd(self)
            new = {'x';'b'; 'y'; 'a'};
            expect = {'b';'a'};
            nel = self.src_list.intersect(new, true);
            assertEqual(expect, self.src_list.asCell);
        end
        
        function testUnion(self)
            new = {'foo'; 'bar'; 'a'};
            expect = union(self.src_cell, new);
            nel = self.src_list.union(new);
            assertEqual(expect, self.src_list.asCell);
        end
        
        function testSetDiff(self)
            new = {'foo'; 'bar'; 'a'};
            expect = setdiff(self.src_cell, new);
            nel = self.src_list.setdiff(new);
            assertEqual(expect, self.src_list.asCell);
        end
        
        %% Sorting        
        function testSort(self)
            % Sort list in ascending order
            [expect, expect_idx] = sort(self.src_cell);
            [srt, srtidx] = self.src_list.sort;
            assertEqual(expect, self.src_list.asCell);
            assertEqual(expect, srt);
            assertEqual(expect_idx, srtidx);
        end
        
        function testSortDescend(self)
            % Sort in descending order
            [~, expect_idx] = sort(self.src_cell);
            expect_idx = expect_idx(end:-1:1);
            expect = self.src_cell(expect_idx);
            [srt, srtidx] = self.src_list.sort('descend');
            assertEqual(expect, self.src_list.asCell);
            assertEqual(expect, srt);
            assertEqual(expect_idx, srtidx);
        end
        
        function testSorted(self)
            % Return a sorted list without modifying the object
            [expect, expect_idx] = sort(self.src_cell);
            [srt, srtidx] = self.src_list.sorted;
            assertEqual(self.src_cell, self.src_list.asCell);
            assertEqual(expect, srt);
            assertEqual(expect_idx, srtidx);
        end
        
        function testReverse(self)
            % Reverse the list
            expect = self.src_cell(end:-1:1);
            rev = self.src_list.reverse;
            assertEqual(expect, self.src_list.asCell)
            assertEqual(expect, rev)
        end
        
        %% Copying
        function testCopyByValue(self)
            clone = self.src_list.copy;
            % objects have different handles
            assertTrue(all(self.src_list == clone))
            % Altering the copy does not alter the original
            clone.append({'foo'});
            assertTrue(all(self.src_list ~= clone))
        end
        
        function testCopyByReference(self)
            % objects have the same handle
            % and have the same values
            clone = self.src_list;            
            assertTrue(all(self.src_list == clone))
            % altering the copy alters the original
            clone.append({'foo'});
            assertTrue(all(self.src_list == clone))            
        end
        
        %% Assignment
        function testAssignment(self)
            idx = [2, 4];
            new_vals = {'foo';'bar'};
            self.src_list(idx) = new_vals;
            assertEqual(self.src_list(idx).asCell, new_vals);
        end
        
        %% Comparisons
        function testEquality(self)
            assertTrue(all(self.src_list == self.src_cell))
        end
        
        function testInequality(self)
            assertFalse(all(self.src_list ~= self.src_cell))
        end
        
        %% Grouping
        function testGroups(self)
            [gp, gpidx] = self.src_list.groups;
            [expect_idx, expect_gp] = grp2idx(self.src_list.asCell);
            assertEqual(expect_gp, gp);
            assertEqual(expect_idx, gpidx);
        end
        
        
        %% Dimensions
        function testLength(self)
            assertEqual(length(self.src_list), length(self.src_cell));
        end
        
        function testSize(self)
            assertEqual(size(self.src_list), [length(self.src_cell), 1]);
        end
        
        % Note overloading numel is hairy. So this test will fail
        % Also no real reason to overload it. Use length instead.
%         function testNumel(self)
%             assertEqual(numel(self.src_list), length(self.src_cell));
%         end
        
        %% Misc
        function testDuplicates(self)
            [dup, dupidx] = self.src_list.duplicates;
            assertEqual(dup, {'b'; 'c'});
            assertEqual(dupidx{1}, find(strcmp(self.src_cell, 'b')), ...
                'Incorrect index');
            assertEqual(dupidx{2}, find(strcmp(self.src_cell, 'c')), ...
                'Incorrect Index');
        end
        
    end
    
end