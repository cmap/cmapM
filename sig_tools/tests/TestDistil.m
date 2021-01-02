classdef TestDistil < matlab.unittest.TestCase
    properties
    end

    methods(Test)
        % When running distil, should include cdesc fields distil_tas and
        %   distil_ss_ngene. For those where there is only 1 replicate 
        %   (in this example well , distil_tas should be -666.
        function testDistilTasCalculation(testcase)
            fprintf('testDistilTasCalculation\n')
            
            gct_fullpath = fullfile(fileparts(mfilename('fullpath')), ...
                'assets','TestDistil','distil_gct_n6x978.gctx');

            gct = parse_gctx(gct_fullpath);
            distilled = distil(gct);
            tas_scores = ds_get_meta(distilled,'column','distil_tas');
            cc_q75_scores = str2double(ds_get_meta(distilled,'column','distil_cc_q75'));
            ss_ngene_scores = ds_get_meta(distilled,'column','distil_ss_ngene');
            nsample_count = ds_get_meta(distilled,'column','distil_nsample');
            single_rep_tas = tas_scores(nsample_count==1);

            
            comparisons_made = 0;
            for ii = 1:length(tas_scores)
                if(nsample_count(ii)>1)
                    comparisons_made = comparisons_made+1;
                    calculated_tas = mortar.compute.SigStrength.tas_ngene(ss_ngene_scores(ii), cc_q75_scores(ii), 1, true)
                    
                    testcase.verifyEqual(tas_scores(ii),calculated_tas.tas_gmean, ...
                        'AbsTol',0.001, ...
                        'distil: tas scores do not line up with geometric mean of cc_q75 and ss_ngene');
                end
            end
            testcase.verifyGreaterThanOrEqual(comparisons_made,1, ...
                'distil: never compared expected and actual tas');
            testcase.verifyNumElements(tas_scores,3, ...
                'distil: distil_tas column is not length 3');
            testcase.verifyNumElements(ss_ngene_scores,3, ...
                'distil: distil_ss_ngene column is not length 3');
            testcase.verifyEqual(single_rep_tas,-666, ...
                'distil: expected single rep instance to have -666 tas');
        end

        function testDistilBasicFunctioning(testCase)
            fprintf('testDistilBasicFunctioning\n')

            asset_dir = 'assets/TestDistil/testDistilBrew'
            wk_dir = fullfile(asset_dir, 'wkdir')

            if exist(wk_dir, 'file')
                delete(fullfile(wk_dir, '*'))
            else
                mkdir(wk_dir)
            end

            cid = cell(1,24);
            for ii = 1:24
                cid{ii} = ['cid' num2str(ii)];
            end

            g_file = fullfile(asset_dir, 'testDistilBrew_input_ds_n12x978.gctx')
            g = parse_gctx(g_file)

            g2 = g;
            g2.cid = cid(1:12);
            g3 = g;
            g3.cid = cid(13:24);
            
            all_g = ds_concatenate({g, g2, g3}, 'concat_direction', 'along-columns')

            my_varargin = cell(1,15);
            my_varargin(1:2) = {'out' 'assets/TestDistil/testDistilBrew/wkdir'};
            my_varargin(3:4) = {'group_by' 'rna_well'};
            my_varargin(5:6) = {'modz_metric' 'wt_avg'};
            my_varargin(7:14) = {'name' 'DOSVAL003_HCC515_24H' 'clip_low_wt' [1] 'clip_low_cc' [1] 'cid_prefix' 'DOSVAL003_HCC515_24H'};
            my_varargin(15:16) = {'use_gctx' [1]}

            [sig, perm_zs, perm_stat] = distil(all_g, my_varargin{:})

            testCase.verifyEqual(4, size(sig.mat, 2))
            testCase.verifyEqual(978, size(sig.mat, 1))
        end
    end
end
