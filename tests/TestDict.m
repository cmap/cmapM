classdef TestDict < matlab.unittest.TestCase
    
    properties
        key;
        value;
        d;
        tolerance = 1e-6;
    end
    
    methods(TestMethodSetup)
        function setUp(self) %#ok<*MANU>
            % Setup (called before each test)
            self.key = {'a', 'foo', 'bar', 'zog'};
            self.value = [1, 2, 10.5, 4];
            self.d = cmapm.containers.Dict(self.key, self.value);
        end
    end
    methods(TestMethodTeardown)
        function tearDown(self)
            % Called after each test
        end
    end
    methods(Test)
        
        function testCreate(self)
            % Create a dict and check length
            self.assertEqual(self.d.length, length(self.key), 'length mismatch');
            self.assertTrue(all(ismember(self.d.keys, self.key)), 'key mismatch');
        end
        
        function testCreateKeysOnly(self)
            locald = cmapm.containers.Dict(self.key);
            self.assertEqual(locald.length, length(self.key), 'length mismatch')
            self.assertTrue(all(ismember(locald.keys, self.key)), 'key mismatch');
        end
        
        function testValues(self)
            % Check if values are correct
            self.assertEqual(cell2mat(self.d.values(self.key)), ...
                self.value, 'AbsTol', self.tolerance, 'value mismatch');
        end
        
        function testKeys(self)
            % check if keys exist
            self.assertTrue(all(self.d.iskey(self.key)));
        end

        function testKeysUpper(self)
            % check if keys exist
            self.assertTrue(all(self.d.isKey(self.key)));
        end

        function testSortKeysOnValue(self)
            % Sort keys based on the values
            sk = self.d.sortKeysOnValue;
            [~, ord] = sort(self.value);
            expect = self.key(ord)';
            self.assertTrue(isequal(sk, expect));
        end

        function testSortKeysOnValueDirec(self)
            % Sort keys based on the values, specify direction
            sk = self.d.sortKeysOnValue('descend');
            [~, ord] = sort(self.value, 'descend');
            expect = self.key(ord)';
            self.assertTrue(isequal(sk, expect));
        end

        function testPop(self)
            % pop a key
            self.assertEqual(self.d.pop('foo'), 2)
            self.assertFalse(self.d.iskey('foo'))
        end
       
        function testClear(self)
            % remove all keys
            self.d.clear;
            self.assertTrue(self.d.isempty);
        end
        
        function testGetMultipleKeys(self)
            % Get multiple keys
            self.assertEqual(self.d.get(self.key), self.value(:),...
                'AbsTol', self.tolerance);            
        end
        
        function testGetSingleKey(self)
            % Get a single key
            self.assertEqual(self.d.get(self.key{1}), self.value(1),...
                'AbsTol', self.tolerance);
        end
        
        function testGetMisssing(self)
            % Try getting a missing key
            self.assertEqual(self.d.get('xyz'), nan);
        end
        
        function testGetMisssingDefault(self)
            % Try getting a missing key with specified default
            self.assertEqual(self.d.get('xyz', -666), -666);
        end
        
        function testUpdate(self)
            % Update values
            newkey = {'xyz', 'foo'};
            newval = {100, 200};
            self.d.update(newkey, newval);
            self.assertEqual(self.d.length, length(union(self.key, newkey)), 'length mismatch');
            self.assertEqual(self.d.get(newkey{1}), newval{1}, 'new key not inserted');
            self.assertEqual(self.d.get(newkey{2}), newval{2}, 'value not updated');
        end
        
        function testSubsRef(self)
            % Lookup a key
            self.assertEqual(self.d('foo'), 2);
        end
        
        % changed this behavior to return NaN if key is missing
%         function testSubsRefKeyError(self)
%             % Check if error is thrown if key is missing
%             e = MException('TestDict:test','');
%             try
%                 self.d('xyz')
%             catch e                
%             end
%             self.assertTrue(isequal(e.identifier, 'Dict:KeyError'));
%         end
        
        function testAddSingle(self)
            % Add an element 
            self.d.add('xyz', 1000);
            self.assertTrue(self.d.iskey('xyz'), 'Key not added');
            self.assertEqual(self.d('xyz'), 1000);
        end
        
        function testAddMulti(self)
            % Add elements
            k = {'xyz'; 'abc'; 'def'};
            v = {5; 10; 15};
            self.d.add(k, v);
            self.assertTrue(all(self.d.iskey(k)), 'Keys not added');
            self.assertEqual(self.d(k), cell2mat(v),...
                'AbsTol', self.tolerance);
        end
        
        function testSubsAssign(self)
            % Add elements using subscript notation
            k = {'xyz'; 'abc'; 'def'};
            v = {5; 10; 15};
            self.d(k) = v;
            self.assertTrue(all(self.d.iskey(k)), 'Keys not added');
            self.assertEqual(self.d(k), cell2mat(v),...
                'AbsTol', self.tolerance);
        end        
        
        function testCopy(self)
            d2 = self.d.copy;
            d2('foo') = 100;
            self.assertEqual(self.d('foo'), 2, 'AbsTol', self.tolerance);
            self.assertEqual(d2('foo'), 100, 'AbsTol', self.tolerance);
        end
        
        function testEmptyLookup(self)
            b = {'q', 'w', 'e'};
            isk = self.d.iskey(b);
            c = b(isk);
            self.assertTrue(isempty(self.d(c)))
        end
        
        function testMissingWithSingleValues(self)
            % Bugtest: type error when query contains missing keys with
            % valid keys that are single precision
            k = {'a', 'foo'};
            v = single(1:2);
            d2 = cmapm.containers.Dict(k, v);
            test_k = {'a','foo','not_there'};            
            expected = [single(1); single(2); single(nan)];
            isk = d2.isKey(test_k);
            self.assertEqual(isk(1:2), [true,true], 'not valid key');
            self.assertFalse(isk(3), 'not valid missing key');
            v = d2(test_k);
            self.assertEqual(v, expected, 'AbsTol', self.tolerance);
        end
        
        function testMissingWithCharValues(self)
            % Bugtest: type error when query contains missing keys with
            % valid keys that are of type char
            k = {'a', 'foo'};
            v = {'x', 'y'};
            d2 = cmapm.containers.Dict(k, v);
            test_k = {'a','foo','not_there'};            
            expected = {'x'; 'y'; NaN};
            isk = d2.isKey(test_k);
            self.assertEqual(isk(1:2), [true,true], 'not valid key');
            self.assertFalse(isk(3), 'not valid missing key');
            v = d2(test_k);
            self.assertEqual(v, expected, 'AbsTol', self.tolerance);
        end      
        
    end
end