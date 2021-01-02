classdef TestGetGeneSets < matlab.unittest.TestCase
    % Test suite for Get Genesets
    properties (Access = private)
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
                     'assets');
        result_path = tempname;
        assets;
    end
    
    
    methods (TestMethodSetup)
        function setUp(testCase)
            % Setup (called before each test)  
            test_file = fullfile(testCase.asset_path, 'gctv13_subset1.gctx');
            testCase.assets = struct('ds_file', test_file);
        end
    end
    
    methods(TestMethodTeardown)
        function tearDown(testCase)
            % Called after each test
        end
        
    end
    methods(Test)
        function testDefault(testCase)
            set_size = 50;
            ds = parse_gctx(testCase.assets.ds_file);
            id_lut = mortar.containers.Dict(ds.rid);
            [up, dn] = get_genesets(testCase.assets.ds_file, set_size, 'descend');
            testCase.verifyTrue(isstruct(up), 'Data type mismatch UP');
            testCase.verifyTrue(isstruct(dn), 'Data type mismatch DN');
            
            testCase.verifyEqual(length(up), 100, 'length mismatch UP')
            testCase.verifyEqual(length(dn), 100, 'length mismatch DN')
            % check set sizes
            testCase.verifyTrue(all(([up.len]'-set_size)<eps), 'set size mismatch UP')
            testCase.verifyTrue(all(([dn.len]'-set_size)<eps), 'set size mismatch DN')                   
            

            num_set = length(up);
            is_up_ok = false(num_set, 1);
            is_dn_ok = false(num_set, 1);
            is_disjoint = false(num_set, 1);
            for ii=1:num_set
                is_up_ok(ii) = all(id_lut.isKey(up(ii).entry));
                is_dn_ok(ii) = all(id_lut.isKey(dn(ii).entry));
                is_disjoint(ii) = isempty(intersect(up(ii).entry, dn(ii).entry));
            end
            testCase.verifyTrue(all(is_up_ok), 'Invalid entry membership UP');
            testCase.verifyTrue(all(is_dn_ok), 'Invalid entry membership DN');
            testCase.verifyTrue(all(is_disjoint), 'Some sets are not disjoint');

        end
        
        function testByRow(testCase)
            set_size = 50;
            ds = parse_gctx(testCase.assets.ds_file);
            id_lut = mortar.containers.Dict(ds.cid);
            [up, dn] = get_genesets(ds, set_size, 'descend','dim','row');
            testCase.verifyTrue(all(([up.len]'-set_size)<eps), 'set size mismatch UP')
            testCase.verifyTrue(all(([dn.len]'-set_size)<eps), 'set size mismatch DN')
            num_set = length(up);
            is_up_ok = false(num_set, 1);
            is_dn_ok = false(num_set, 1);
            is_disjoint = false(num_set, 1);            
            for ii=1:num_set
                is_up_ok(ii) = all(id_lut.isKey(up(ii).entry));
                is_dn_ok(ii) = all(id_lut.isKey(dn(ii).entry));
                is_disjoint(ii) = isempty(intersect(up(ii).entry, dn(ii).entry));
            end            
            testCase.verifyTrue(all(is_up_ok), 'Invalid entry membership UP');
            testCase.verifyTrue(all(is_dn_ok), 'Invalid entry membership DN');
            testCase.verifyTrue(all(is_disjoint), 'Some sets are not disjoint');
        end
        
        function testAltId(testCase)
            set_size = 50;
            ds = parse_gctx(testCase.assets.ds_file);
            [up, dn] = get_genesets(ds, set_size, 'descend','id_field','pr_gene_symbol');
        end
        
        function testEnforceSetSize(testCase)
            set_size = 50;
            ds = parse_gctx(testCase.assets.ds_file);
            failed = false;
            try
                [up, dn] = get_genesets(ds, set_size, 'descend','id_field','pr_analyte_id');
            catch e
                failed=true;
            end
            testCase.assertTrue(failed);
        end      
        
        
        function testInvalidSetSize(testCase)
            set_size = 600;
            ds = parse_gctx(testCase.assets.ds_file);
            failed = false;
            try
                [up, dn] = get_genesets(ds, set_size, 'descend',...
                            'id_field', 'pr_analyte_id',...
                            'enforce_set_size', false);
            catch e
                failed=true;
            end
            testCase.assertTrue(failed);
        end
    end
end