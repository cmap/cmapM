classdef TestCmapScore < matlab.unittest.TestCase
    % Test suite for CMap Connectivity score metrics
    properties (Access = private)
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        result_path = tempname;
    end
    
    
    methods (TestMethodSetup)
        function setUp(testCase)
            % Setup (called before each test)
            
        end
    end
    
    methods(TestMethodTeardown)
        function tearDown(testCase)
            % Called after each test
        end
    end
    methods(Test)
        function testCmapScoreWeighted(testCase)
            % use Connectivty.staticMethod() to call
            import mortar.compute.Connectivity
            
            % Connectivity score weighted
            p = testCase.asset_path;
            
            score_file = fullfile(p, ...
                'trichostatina_mcf7_10um_score.gct');
            full_rank_file = fullfile(p, ...
                'trichostatina_mcf7_10um_rank_full.gct');
            
            up_file = fullfile(p, 'HDAC_UP.grp');
            dn_file = fullfile(p, 'HDAC_DN.grp');
            
            ds_score = parse_gctx(score_file, 'verbose', false);
            ds_rank = parse_gctx(full_rank_file, 'verbose', false);
            max_rank = 22268;
            uptag = parse_geneset(up_file);
            dntag = parse_geneset(dn_file);
            isweighted = true;
            es_tail = 'both';
            res = Connectivity.computeCmapScore(uptag, dntag,...
                ds_rank, isweighted,...
                ds_score, es_tail,...
                max_rank);
            
            testCase.verifyEqual(res.cs.mat,  0.7733, 'AbsTol', 1e-4, 'Combined score mismatch');
            testCase.verifyEqual(res.cs_up.mat,  0.7449, 'AbsTol', 1e-4, 'UP score mismatch');
            testCase.verifyEqual(res.cs_dn.mat,  -0.8016, 'AbsTol', 1e-4, 'DOWN score mismatch');
        end
        
        function testCmapScoreUnWeighted(testCase)
            % use Connectivty.staticMethod() to call
            import mortar.compute.Connectivity
            
            % Connectivity score un-weighted
            p = testCase.asset_path;
            
            score_file = fullfile(p, ...
                'trichostatina_mcf7_10um_score.gct');
            full_rank_file = fullfile(p, ...
                'trichostatina_mcf7_10um_rank_full.gct');
            
            up_file = fullfile(p, 'HDAC_UP.grp');
            dn_file = fullfile(p, 'HDAC_DN.grp');
            
            ds_score = parse_gctx(score_file, 'verbose', false);
            ds_rank = parse_gctx(full_rank_file, 'verbose', false);
            max_rank = length(ds_rank.rid);
            uptag = parse_geneset(up_file);
            dntag = parse_geneset(dn_file);
            isweighted = false;
            es_tail = 'both';
            
            res = Connectivity.computeCmapScore(uptag, dntag,...
                ds_rank, isweighted,...
                ds_score, es_tail,...
                max_rank);
            
            testCase.verifyEqual(res.cs.mat,  0.5551, 'AbsTol', 1e-4,...
                'Combined score mismatch');
            testCase.verifyEqual(res.cs_up.mat,  0.5516, 'AbsTol', 1e-4,...
                'UP score mismatch');
            testCase.verifyEqual(res.cs_dn.mat,  -0.5585, 'AbsTol', 1e-4,...
                'DOWN score mismatch');
        end
        
        function testRunCmapQueryWeighted(testCase)
            % use Connectivty.staticMethod() to call
            import mortar.compute.Connectivity
            
            % Connectivity score weighted
            p = testCase.asset_path;
            
            score_file = fullfile(p, ...
                'trichostatina_mcf7_10um_score.gct');
            full_rank_file = fullfile(p, ...
                'trichostatina_mcf7_10um_rank_full.gct');
            up_file = fullfile(p, 'HDAC_UP.grp');
            dn_file = fullfile(p, 'HDAC_DN.grp');
            es_tail = 'both';
            
            res = Connectivity.runCmapQuery('--uptag', up_file,...
                '--dntag', dn_file,...
                '--rank', full_rank_file,...
                '--score', score_file,...
                '--es_tail', es_tail);
            
            testCase.verifyEqual(res.cs.mat,  0.7733, 'AbsTol', 1e-4, 'Combined score mismatch');
            testCase.verifyEqual(res.cs_up.mat,  0.7449, 'AbsTol', 1e-4, 'UP score mismatch');
            testCase.verifyEqual(res.cs_dn.mat,  -0.8016, 'AbsTol', 1e-4, 'DOWN score mismatch');
        end
                    
        function testRunCmapQueryWeightedRore(testCase)
            % use Connectivty.staticMethod() to call
            import mortar.compute.Connectivity
            
            % Connectivity score weighted
            p = testCase.asset_path;
            
%             rore_file = fullfile(p, ...
%                 'trichostatina_mcf7_10um_rore.gct');
%             ds_rore = parse_gct(rore_file, 'class', 'double');
            rore_file = fullfile(p, ...
                'trichostatina_mcf7_10um_rore.gctx');
            ds_rore = parse_gctx(rore_file, 'matrix_class', 'double');
            up_file = fullfile(p, 'HDAC_UP.grp');
            dn_file = fullfile(p, 'HDAC_DN.grp');
            es_tail = 'both';
            
            res = Connectivity.runCmapQuery('--up', up_file,...
                '--dn', dn_file,...
                '--rank_score', ds_rore,...
                '--es_tail', es_tail);
            
            testCase.verifyEqual(res.cs.mat,  0.7733, 'AbsTol', 1e4, 'Combined score mismatch');
            testCase.verifyEqual(res.cs_up.mat,  0.7449, 'AbsTol', 1e4, 'UP score mismatch');
            testCase.verifyEqual(res.cs_dn.mat,  -0.8016, 'AbsTol', 1e4, 'DOWN score mismatch');
        end
        function testRunCmapQueryWeightedRoreSingle(testCase)
            % use Connectivty.staticMethod() to call
            import mortar.compute.Connectivity
            
            % Connectivity score weighted
            p = testCase.asset_path;
            
            rore_file = fullfile(p, ...
                'trichostatina_mcf7_10um_rore.gctx');
            ds_rore = parse_gctx(rore_file, 'matrix_class', 'single');

            up_file = fullfile(p, 'HDAC_UP.grp');
            dn_file = fullfile(p, 'HDAC_DN.grp');
            es_tail = 'both';
            
            res = Connectivity.runCmapQuery('--up', up_file,...
                '--dn', dn_file,...
                '--rank_score', ds_rore,...
                '--es_tail', es_tail);
            
            testCase.verifyEqual(res.cs.mat,  0.7733, 'AbsTol', 1e4, 'Combined score mismatch');
            testCase.verifyEqual(res.cs_up.mat,  0.7449, 'AbsTol', 1e4, 'UP score mismatch');
            testCase.verifyEqual(res.cs_dn.mat,  -0.8016, 'AbsTol', 1e4, 'DOWN score mismatch');
        end        
        
    end
end