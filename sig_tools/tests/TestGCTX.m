classdef TestGCTX < matlab.unittest.TestCase    
    properties
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        assets = [];
    end
    
    methods(TestMethodSetup)
        function setup(testCase)
            % common init
            td = struct('infile', fullfile(testCase.asset_path, 'gctv13_01.gct'),...
                'outfile', fullfile(testCase.asset_path, 'test.gctx'),...
                'scratchfile', fullfile(testCase.asset_path, 'scratch.gctx'));
            if isfileexist(td.outfile)
                delete(td.outfile)
            end
            if isfileexist(td.scratchfile)
                delete(td.scratchfile)
            end
            dsin = parse_gct(td.infile, 'verbose', false);
            mkgctx(td.outfile, dsin, 'appenddim', false, 'verbose', false);            
            testCase.assets = td;
        end
    end
    
    methods(TestMethodTeardown)
        function teardown(testCase)
            td = testCase.assets;
            % common shutdown
            if isfileexist(td.outfile)
                delete(td.outfile)
            end
            if isfileexist(td.scratchfile)
                delete(td.scratchfile)
            end
        end
    end
       
    methods(Test)
        function testReadWrite(testCase)
            % Read a gct file, write as gctx, read the gctx
            % Compare for equivalence
            td = testCase.assets;
            dsin = parse_gct(td.infile, 'verbose', false);
            dsout = parse_gctx(td.outfile, 'verbose', false);
            
            % matrix
            testCase.verifyEqual(dsin.mat, dsout.mat, 'AbsTol', 1e-6)
            % row and column ids
            testCase.verifyEqual(dsin.rid, dsout.rid)
            testCase.verifyEqual(dsin.cid, dsout.cid)
            % row annotations
            for ii=1:length(dsin.rhd)
                disp(dsin.rhd{ii});
                c = unique(cellfun(@class, dsin.rdesc(:,ii), 'uniformoutput',false));
                if length(c)>1
                    c={'char'};
                end
                switch(c{1})
                    case 'char'
                        testCase.verifyEqual(dsin.rdesc(:,ii), dsout.rdesc(:,ii))
                    case {'single'}
                        testCase.verifyEqual(cell2mat(dsin.rdesc(:,ii)),...
                            single(cell2mat(dsout.rdesc(:,ii))),...
                            'absTol', 1e-3)
                    case {'double'}
                        testCase.verifyEqual(cell2mat(dsin.rdesc(:,ii)),...
                            double(cell2mat(dsout.rdesc(:,ii))),...
                            'absTol', 1e-3)                        
                end
            end
            % column annotations
            for ii=1:length(dsin.chd)
                disp(dsin.chd{ii});
                c = unique(cellfun(@class, dsin.cdesc(:,ii), 'uniformoutput',false));
                if length(c)>1
                    c={'char'};
                end
                switch(c{1})
                    case 'char'
                        testCase.verifyEqual(dsin.cdesc(:,ii),...
                            dsout.cdesc(:,ii))
                    case {'single'}
                        testCase.verifyEqual(cell2mat(dsin.cdesc(:,ii)),...
                            single(cell2mat(dsout.cdesc(:,ii))),...
                            'AbsTol', 1e-3)
                    case {'double'}
                        testCase.verifyEqual(cell2mat(dsin.cdesc(:,ii)),...
                            double(cell2mat(dsout.cdesc(:,ii))),...
                            'AbsTol', 1e-3)                        
                end
            end
            
        end
        
        function testReadRandomColumn(testCase)
            % Read and verify random columns from a gctx file
            td = testCase.assets;
            dsin = parse_gct(td.infile);
            ncol = size(dsin.mat,2);
            N = 10;
            pick = randsample(ncol, N);
            for ii=1:N
                dstmp = parse_gctx(td.outfile, 'cid', dsin.cid(pick(ii)));
                testCase.verifyEqual(dsin.cid(pick(ii)), dstmp.cid)
                testCase.verifyEqual(dsin.mat(:, pick(ii)), dstmp.mat)
            end
        end
        
        function testAppendColumn(testCase)
            % Append columns to dataset
            td = testCase.assets;
            dsin = parse_gct(td.infile);
            ncol = size(dsin.mat, 2);
            N = 10;
            for ii=1:N
                dstmp = gctextract_tool(dsin, 'cid', dsin.cid(ii));
                if isequal(ii, 1)
                    mkgctx(td.scratchfile, dstmp, 'appenddim', false, 'verbose', false);
                else
                    mkgctx(td.scratchfile, dstmp, 'insert', true, 'verbose', false);
                end
            end
            dsout = parse_gctx(td.scratchfile, 'verbose', false);
            testCase.verifyEqual(dsin.mat(:, 1:N), dsout.mat);
        end
        
        function testMatrixWithNA(testCase)
            dsfile = fullfile(testCase.asset_path, 'matrix_with_na.gct');
            ds = parse_gct(dsfile, 'has_missing_data', true);
            inan = isnan(ds.mat);
            nnan = sum(inan(:));
            testCase.verifyEqual(nnan, 3, 'Incorrect number of NaNs');
        end 
       
        function testMatrixAsDouble(testCase)
            td = testCase.assets;
            row_labels = gen_labels(10);
            col_labels = gen_labels(10);
            ds = mkgctstruct(rand(10),...
                    'rid', row_labels,...
                    'cid', col_labels);
            mkgctx(td.scratchfile, ds, 'matrix_class', 'double', 'appenddim', false);
            dsout = parse_gctx(td.scratchfile, 'verbose', false);
            testCase.verifyEqual(dsout.mat, ds.mat, 'AbsTol', eps);
        end
        
        function testIDCheck(testCase)
            td = testCase.assets;            
            row_labels = gen_labels(10);
            x = {'cid1'};
            col_labels = x(ones(10,1));
            ds = mkgctstruct(rand(10),...
                'rid', row_labels,...
                'cid', col_labels);
            write_failed = false;
            try
                mkgctx(td.scratchfile, ds,...
                    'matrix_class', 'double',...
                    'appenddim', false);
            catch e
                write_failed = true;
                % Force write
                mkgctx(td.scratchfile, ds,...
                       'matrix_class', 'double',...
                       'appenddim', false, 'checkid', false);
            end
            testCase.verifyTrue(write_failed, 'Write ID check issue');
            read_failed = false;
            try
                dsout = parse_gctx(td.scratchfile,...
                            'verbose', false);
            catch e
                read_failed = true;
                % Force read
                dsout = parse_gctx(td.scratchfile,...
                            'verbose', false, 'checkid', false);
            end
            testCase.verifyTrue(read_failed, 'Read ID check issue');
            testCase.verifyEqual(dsout.cid, ds.cid, 'CID mismatch');
        end
    end
end