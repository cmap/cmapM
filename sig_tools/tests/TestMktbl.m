classdef TestMktbl < matlab.unittest.TestCase
    % Tests for mktbl
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
    end
    methods(TestMethodSetup)

    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
                    
        function testLegacyIO(testCase)
            tableFile = fullfile(testCase.asset_path, 'column_meta_n371.txt');
            tbl = parse_tbl(tableFile);
            outPath = tempname;
            mktbl(outPath, tbl);
            res = parse_tbl(outPath);
            reqFields = fieldnames(tbl);
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Result fields dont match input');
            
            nfn = length(reqFields);
            for ii=1:nfn
               testCase.verifyEqual(numel(tbl.(reqFields{ii})), numel(res.(reqFields{ii})), strcat('Length mismatch for field:', reqFields{ii}) )
            end
        end
        
        function testSingletonArray(testCase)
            tbl = struct('id', 'id1', 'value', 10);
            outPath = tempname;
            mktbl(outPath, tbl);
            res = parse_record(outPath);
            reqFields = fieldnames(tbl);
            hasReq = isfield(res, reqFields);
            testCase.verifyTrue(all(hasReq), 'Result fields dont match input');
            
            nfn = length(reqFields);
            for ii=1:nfn
               testCase.verifyEqual(tbl.(reqFields{ii}), res.(reqFields{ii}), sprintf('Mismatch field %s', reqFields{ii}) );
            end
            
        end
                
    end 
end