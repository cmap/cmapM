classdef TestDict < TestCase
    
    properties
        key;
        value;
        d;
    end
    
    methods
        function self = TestDict(name)
            % Constructor
            self = self@TestCase(name);
        end
        
        function setUp(self) %#ok<*MANU>
            % Setup (called before each test)
            self.key = {'a', 'foo', 'bar', 'zog'};
            self.value = [1, 2, 10.5, 4];
            self.d = mortar.containers.Dict(self.key, self.value);
        end
        
        function tearDown(self)
            % Called after each test
        end  
        
        function testCreate(self)
            % Create a dict and check length
            assertEqual(self.d.length, length(self.key), 'length mismatch');
            assertTrue(all(ismember(self.d.keys, self.key)), 'key mismatch');
        end
        
        function testCreateKeysOnly(self)
            locald = mortar.containers.Dict(self.key);
            assertEqual(locald.length, length(self.key), 'length mismatch')
            assertTrue(all(ismember(locald.keys, self.key)), 'key mismatch');
        end
        
        function testValues(self)
            % Check if values are correct
            assertElementsAlmostEqual(cell2mat(self.d.values(self.key)), ...
                self.value, 'value mismatch');
        end
        
        function testKeys(self)
            % check if keys exist
            assertTrue(all(self.d.iskey(self.key)));
        end

        function testKeysUpper(self)
            % check if keys exist
            assertTrue(all(self.d.isKey(self.key)));
        end

        function testSortKeysOnValue(self)
            % Sort keys based on the values
            sk = self.d.sortKeysOnValue;
            [~, ord] = sort(self.value);
            expect = self.key(ord)';
            assertTrue(isequal(sk, expect));
        end

        function testSortKeysOnValueDirec(self)
            % Sort keys based on the values, specify direction
            sk = self.d.sortKeysOnValue('descend');
            [~, ord] = sort(self.value, 'descend');
            expect = self.key(ord)';
            assertTrue(isequal(sk, expect));
        end

        function testPop(self)
            % pop a key
            assertEqual(self.d.pop('foo'), 2)
            assertFalse(self.d.iskey('foo'))
        end
       
        function testClear(self)
            % remove all keys
            self.d.clear;
            assertTrue(self.d.isempty);
        end
        
        function testGetMultipleKeys(self)
            % Get multiple keys
            assertElementsAlmostEqual(self.d.get(self.key), self.value(:));            
        end
        
        function testGetSingleKey(self)
            % Get a single key
            assertElementsAlmostEqual(self.d.get(self.key{1}), self.value(1));
        end
        
        function testGetMisssing(self)
            % Try getting a missing key
            assertEqual(self.d.get('xyz'), nan);
        end
        
        function testGetMisssingDefault(self)
            % Try getting a missing key with specified default
            assertEqual(self.d.get('xyz', -666), -666);
        end
        
        function testUpdate(self)
            % Update values
            newkey = {'xyz', 'foo'};
            newval = {100, 200};
            self.d.update(newkey, newval);
            assertEqual(self.d.length, length(union(self.key, newkey)), 'length mismatch');
            assertEqual(self.d.get(newkey{1}), newval{1}, 'new key not inserted');
            assertEqual(self.d.get(newkey{2}), newval{2}, 'value not updated');
        end
        
        function testSubsRef(self)
            % Lookup a key
            assertEqual(self.d('foo'), 2);
        end
        
        % changed this behavior to return NaN if key is missing
%         function testSubsRefKeyError(self)
%             % Check if error is thrown if key is missing
%             e = MException('TestDict:test','');
%             try
%                 self.d('xyz')
%             catch e                
%             end
%             assertTrue(isequal(e.identifier, 'Dict:KeyError'));
%         end
        
        function testAddSingle(self)
            % Add an element 
            self.d.add('xyz', 1000);
            assertTrue(self.d.iskey('xyz'), 'Key not added');
            assertEqual(self.d('xyz'), 1000);
        end
        
        function testAddMulti(self)
            % Add elements
            k = {'xyz'; 'abc'; 'def'};
            v = {5; 10; 15};
            self.d.add(k, v);
            assertTrue(all(self.d.iskey(k)), 'Keys not added');
            assertElementsAlmostEqual(self.d(k), cell2mat(v));
        end
        
        function testSubsAssign(self)
            % Add elements using subscript notation
            k = {'xyz'; 'abc'; 'def'};
            v = {5; 10; 15};
            self.d(k) = v;
            assertTrue(all(self.d.iskey(k)), 'Keys not added');
            assertElementsAlmostEqual(self.d(k), cell2mat(v));
        end        
        
        function testCopy(self)
            d2 = self.d.copy;
            d2('foo') = 100;
            assertElementsAlmostEqual(self.d('foo'), 2);
            assertElementsAlmostEqual(d2('foo'), 100);
        end
        
        function testEmptyLookup(self)
            b = {'q', 'w', 'e'};
            isk = self.d.iskey(b);
            c = b(isk);
            assertTrue(isempty(self.d(c)))
        end
    end
end