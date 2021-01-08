classdef TestConnectivity < TestCase
    
    properties (Access = private)
    end
    
    methods
        
        function self = TestConnectivity(name)
            self = self@TestCase(name);
        end
        
        function setUp(self)
            % Setup (called before each test)            
            
        end
        
        function tearDown(self)
            % Called after each test
        end
        
        function testCmapScoreWeighted(self)
            % use Connectivty.staticMethod() to call
            import mortar.compute.Connectivity

            % Connectivity score weighted
            p = fileparts(mfilename('fullpath'));
            
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

            assertElementsAlmostEqual(res.cs.mat,  single(0.7733), 'Combined score mismatch');
            assertElementsAlmostEqual(res.cs_up.mat,  single(0.7449), 'UP score mismatch');
            assertElementsAlmostEqual(res.cs_dn.mat,  single(-0.8016), 'DOWN score mismatch');
        end
    
        function testCmapScoreUnWeighted(self)
            % use Connectivty.staticMethod() to call
            import mortar.compute.Connectivity

            % Connectivity score un-weighted
            p = fileparts(mfilename('fullpath'));
            
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
  
            assertElementsAlmostEqual(res.cs.mat,  single(0.5551),...
                                        'Combined score mismatch');
            assertElementsAlmostEqual(res.cs_up.mat,  single(0.5516),...
                                        'UP score mismatch');
            assertElementsAlmostEqual(res.cs_dn.mat,  single(-0.5585),...
                                        'DOWN score mismatch');
        end
        
        function testRunCmapQueryeWeighted(self)
            % use Connectivty.staticMethod() to call
            import mortar.compute.Connectivity

            % Connectivity score weighted
            p = fileparts(mfilename('fullpath'));
            
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

            assertElementsAlmostEqual(res.cs.mat,  single(0.7733), 'Combined score mismatch');
            assertElementsAlmostEqual(res.cs_up.mat,  single(0.7449), 'UP score mismatch');
            assertElementsAlmostEqual(res.cs_dn.mat,  single(-0.8016), 'DOWN score mismatch');
        end
        
        
        
    end
end