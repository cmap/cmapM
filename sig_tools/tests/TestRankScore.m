classdef TestRankScore < matlab.unittest.TestCase
    properties
        self_path = fileparts(mfilename('fullpath'));
        asset_path = fullfile(fileparts(mfilename('fullpath')),...
            'assets');
        tolerance = 1e-6;
        ds_score;
        ds_rank;
    end
    
    properties(TestParameter)
        agg_fun = cell2struct({'sum'; 'min'; 'max';...
                   'mean'; 'median'; 'std';...
                   'iqr'; 'sem'; 'absmax';...
                   'range'; 'numel'; 'mad';...
                   @(x, dim) max_quantile(x, 33, 67, dim)
                   },...
                   {'sum'; 'min'; 'max';...
                   'mean'; 'median'; 'std';...
                   'iqr'; 'sem'; 'absmax';...
                   'range'; 'numel'; 'mad';...
                   'max_quantile'
                   },...                   
                   1);
    end
    
    methods(TestMethodSetup)
        function createDataset(testCase)
            n = 100;
            rid = gen_labels(n);
            cid = gen_labels(n);         
            m = randn(n);
            % zero is an edge-case
            m(1:n+1:end) = 0;
            
            % test extreme ranks 
            r = rankorder(m);
            r(1:n+1:end) = 20000;
            
            testCase.ds_score = mkgctstruct(m, 'rid', rid, 'cid', cid);            
            testCase.ds_rank = score2rank(testCase.ds_score, 'direc', 'descend');
            testCase.ds_rank = mkgctstruct(r, 'rid', rid, 'cid', cid);            
            min_score = min(m(:));
            max_score= max(m(:));
            min_rank = min(r(:));
            max_rank= max(r(:));            
            dbg(1, 'Score Range: Min: %f, max: %f', min_score, max_score);
            dbg(1, 'Rank Range: Min: %d, max: %d', min_rank, max_rank);
        end
    end
    
    methods(TestMethodTeardown)
    end
    
    methods(Test)
        
        function testRankScore(testCase)
            ds_rore = mortar.compute.Connectivity.fuseRankScore(testCase.ds_score, testCase.ds_rank, 'double');
            [score, rank] = mortar.compute.Connectivity.defuseRankScore(ds_rore);
            [is_score_match, rmsd_score] = gctcomp(score, testCase.ds_score, 'tol', 1e-4);
            [is_rank_match, rmsd_rank] = gctcomp(rank, testCase.ds_rank, 'tol', 1e-4);
            dbg(1, 'RMSD score: %f', rmsd_score);
            dbg(1, 'RMSD rank: %f', rmsd_rank);
            testCase.assertTrue(is_score_match,...
                sprintf('Score mismatch RMSD:%f',rmsd_score));
            testCase.assertTrue(is_rank_match,...
                sprintf('Rank mismatch RMSD: %f', rmsd_rank));
        end
    end
end